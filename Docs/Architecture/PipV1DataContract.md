# Pip v1 本地技术边界与数据契约

状态：已审查（2026-08-22），服务于 iOS 17+、watchOS 10+ 的 Pip v1 实现。

本文定义 v1 的本地事实数据、跨 target 读取边界、设备时区规则、完成统计、通知权限和 App Group 快照格式。本文不创建服务端、云资源、账户或同步服务。未在本文定义的字段、写入者或数据出口不属于 v1 实现。

## 1. 产品与技术边界

Pip v1 是无后端、无账户、无云同步的原生 SwiftUI 应用：

- iPhone App 是唯一业务写入者。它创建本地 SwiftData `ModelContainer`，保存会话、提醒槽位、日历统计和 streak，并在本地事务完成后生成 App Group 快照。
- SwiftData 使用本地配置：`groupContainer: .none`、`cloudKitDatabase: .none`。SwiftData 数据库不放入 App Group；App Group 只承载给其他 target 读取的快照文件。
- Watch App/Extension 不创建或持有 iPhone 的 SwiftData `ModelContext`，只读取 App Group 快照；Watch 的会话状态仅存在于 Watch 进程内存，完成后不写入任何 iPhone 统计或共享快照。
- Widget Extension 不创建 SwiftData 容器，只读取 App Group 快照；Widget 不启动会话、不修改业务数据。
- 通知是 iPhone 上的本地通知，使用 `UNCalendarNotificationTrigger`，不使用 APNs。
- 所有绝对时间持久化为 Swift `Date`；所有日期归属使用设备时区下 Gregorian calendar 的 `yyyy-MM-dd` 日期键。

以下能力不属于 Pip v1 的运行路径：

- 无后端、REST/API、HTTP、WebSocket、网络请求、远程配置或远程日志。
- 无账户、认证、登录、社交关系或跨设备同步；不使用 `WatchConnectivity`、CloudKit 或 iCloud 做数据传输。
- 无 HealthKit、StoreKit/IAP、订阅、广告或聊天 SDK。
- 无 Live Activity、ActivityKit、APNs 推送、锁屏 Widget 或可启动会话的 Widget 交互。

App Group 只是本机 target 之间的共享容器，不代表云同步、设备迁移或 Watch 与 iPhone 的业务数据同步。

## 2. 日期、时区与完成统计

### 2.1 日期类型与日期键

| 名称 | Swift 类型 | 约定 |
| --- | --- | --- |
| 绝对时间 | `Date` | 代表一个时间点；展示和本地通知组件按设备当前时区解释。JSON 中使用 ISO 8601 UTC 字符串。 |
| 设备日期键 | `String` | 使用 Gregorian calendar 和生成时的设备时区，格式固定为 `yyyy-MM-dd`，例如 `2026-08-21`；不得使用 UTC 日期或用户首选非 Gregorian calendar 代替。 |
| 提醒时间 | `hour` + `minute` + `weekdayMask` | 设备本地时间，不保存固定 UTC 偏移。 |

日期键生成器必须显式使用 Gregorian calendar，并将其 `timeZone` 设置为目标设备时区。完成时间、日历聚合、streak、快照 `deviceDayKey` 和首页今日计数必须使用同一规则。

设备时区变化后的处理规则：

1. 已完成记录的 `completionDayKey` 是完成时冻结的事实，不因之后的时区变化回写或搬移历史统计；`startDayKey` 同理。
2. 未来提醒按新设备时区重新计算和调度；提醒槽位仍表示新的设备本地小时、分钟和星期。
3. iPhone App 启动、回到前台、设置保存和检测到时区变化时，重新计算今日快照并重建受影响的通知。
4. 读取方发现快照 `deviceDayKey` 与当前设备日期键不一致时，不得把其中的 `todayCompletedCount`、`nextReminderAt` 或 `done` 状态当作今天的数据；在 iPhone 重新写入前显示安全空状态（今日 0、无下一提醒、静态状态 `idle` 或 `waiting`）。读取方不得自行回写快照。

### 2.2 完整会话与 completed-only 入账

一个完整会话由 8 个连续的 `lift 3 秒 → release 3 秒` 周期组成，v1 总有效引导时间固定为 48 秒。统计单位是完整会话，不是单个周期。

- 只有同一个 `SessionRecord.id` 的记录满足完整完成不变量并成功保存后，才允许产生一次入账。
- 会话离开 App、进入后台或主动退出时保存为 `paused`，保留已完成周期和可恢复位置；恢复后仍使用同一个 `id`。
- 用户放弃、取消或恢复上下文失效的会话保存为 `incomplete`；引擎的 `cancelled` 是运行时状态，不是持久化 `SessionStatus`。
- `paused` 和 `incomplete` 不进入今日完成次数、`CalendarDayStat` 正数或 streak。
- 会话跨越午夜时，按 `completedAt` 在完成瞬间的设备时区生成 `completionDayKey`，不按 `startDayKey` 入账。
- 重复保存、重复回前台、重复恢复或重复完成事件不能产生第二次入账；`SessionRecord.id` 是幂等键。
- Watch 的独立会话完成不写入 iPhone SwiftData、`CalendarDayStat`、`StreakState`、今日计数或 App Group 快照；v1 不提供 Watch 到 iPhone 的统计同步。

### 2.3 时区变化与统计事实

历史统计只能由已完成 `SessionRecord` 的冻结 `completionDayKey` 重建。时区变化不会把历史记录按新时区重新归类，也不会因为读取时的当前日期变化而创造完成记录。当前设备日期只影响“今日”投影和下一提醒。

## 3. SwiftData 模型契约

以下字段与现有模型逐一对应：`SessionRecord` 对外有 `PipSession` typealias；枚举以稳定字符串原始值持久化。所有保存入口必须在写入 SwiftData 前验证本节不变量。

### 3.1 `SessionRecord`（`PipSession` typealias）

一条记录代表一次完整 48 秒会话尝试。

| 字段 | 类型 | 必填/默认 | 语义与约束 |
| --- | --- | --- | --- |
| `id` | `UUID` | 必填 | 唯一主键，也是完成统计的幂等键。 |
| `statusRaw` | `String` | 必填，`paused` | 只允许 `paused`、`completed`、`incomplete`。未知原始值不得参与统计；读取时按不完整处理，iPhone 修复写入时才可改为 `incomplete`。 |
| `startedAt` | `Date` | 必填 | 首次开始时间点。 |
| `lastResumedAt` | `Date?` | 可选 | 最近一次从暂停恢复的时间点；首次开始尚未恢复时为 `nil`，暂停时保留，不得替代 `startedAt`。 |
| `completedAt` | `Date?` | `completed` 时必填 | 完成时间点；`paused`/`incomplete` 必须为 `nil`。 |
| `startDayKey` | `String` | 必填 | `startedAt` 按开始时设备 Gregorian calendar 和时区生成的冻结日期键，仅用于审计和展示。 |
| `completionDayKey` | `String?` | `completed` 时必填 | `completedAt` 按完成时设备 Gregorian calendar 和时区生成的冻结日期键；所有完成统计只使用它。 |
| `completedCycles` | `Int` | 必填，`0` | 已完整完成周期数，范围 `0...8`；完成时必须为 `8`。 |
| `activeSeconds` | `Int` | 必填，`0` | 累计有效引导秒数，范围 `0...48`；完成时必须为 `48`，不得以大于 48 的值代表完成。 |
| `pauseCount` | `Int` | 必填，`0` | 已发生暂停次数，不能为负数；每次持久化暂停只增加 1。 |
| `createdAt` | `Date` | 必填 | 记录创建时间点。 |
| `updatedAt` | `Date` | 必填 | 最近一次持久化变更时间点，必须不早于 `createdAt`。 |

完成状态不变量：`statusRaw == completed` 必须同时满足 `completedCycles == 8`、`activeSeconds == 48`、`completedAt != nil`、`completionDayKey != nil`，且日期键格式有效；其他状态必须没有 `completedAt` 和 `completionDayKey`。任何不满足不变量的记录都按未完成处理，不能猜测完成或计入统计。

### 3.2 `ReminderSlot`

提醒槽位是 iPhone 本地通知的配置源。v1 最多保存 3 个槽位；默认槽位为工作日 09:00、13:00、20:00。

| 字段 | 类型 | 必填/默认 | 语义与约束 |
| --- | --- | --- | --- |
| `id` | `UUID` | 必填 | 唯一主键；创建后保持不变。 |
| `slotKey` | `String` | 必填 | 本地唯一稳定标识，例如 `morning`、`afternoon`、`evening`；用于通知标识。 |
| `hour` | `Int` | 必填 | 设备本地小时，范围 `0...23`。 |
| `minute` | `Int` | 必填 | 设备本地分钟，范围 `0...59`。 |
| `weekdayMask` | `Int` | 必填 | 星期位掩码，bit 0 至 bit 6 依次表示周一至周日；有效范围 `1...127`。 |
| `isEnabled` | `Bool` | 必填，`true` | `false` 的槽位不得创建或保留有效重复通知。 |
| `timezoneIdentifierAtLastSchedule` | `String?` | 可选 | 最近一次调度使用的设备时区标识，仅用于检测变化，不是日期或统计来源。 |
| `updatedAt` | `Date` | 必填 | 最近一次编辑或调度状态变更时间点。 |

`id` 和 `slotKey` 均唯一；iPhone 保存配置时最多保留 3 个槽位，并拒绝无效小时、分钟、星期掩码或空 `slotKey`。每个启用星期对应一个重复通知请求，通知标识固定按 `Pip.Reminder.<slotKey>.weekday-<foundationWeekday>` 生成，其中 `foundationWeekday` 是系统 `DateComponents.weekday` 值（周日为 1，周一至周六为 2...7）。保存配置、权限变化、应用启动或检测到时区变化时，先撤销 Pip 自己的旧通知，再按当前设备时区和 `weekdayMask` 重建，不得无限累积历史通知。

### 3.3 `CalendarDayStat`

该模型是可重建的日历聚合，不是完成事实的唯一来源。

| 字段 | 类型 | 必填/默认 | 语义与约束 |
| --- | --- | --- | --- |
| `dayKey` | `String` | 必填，唯一 | Gregorian `yyyy-MM-dd`，对应完成会话的 `completionDayKey`。 |
| `completedSessionCount` | `Int` | 必填，`0` | 该日期具有有效完成不变量的不同 `SessionRecord.id` 数量；必须为非负数。 |
| `streakLengthEndingOnDay` | `Int` | 必填，`0` | 以该日为结束日的连续完成日期长度；当天计数为 0 时必须为 0。 |
| `updatedAt` | `Date` | 必填 | 最近一次聚合时间点。 |

没有完整会话的日期可以没有 `CalendarDayStat` 记录；若为了渲染创建空记录，两个统计字段都必须为 0。聚合必须从 `statusRaw == completed` 且满足全部完成不变量的会话按 `completionDayKey` 去重重建，不能从提醒次数、周期数或 Watch 会话推导。

### 3.4 `StreakState`

全局只保留一条本地 streak 汇总记录，`id` 固定为 `singleton`，只能由 iPhone 修改。

| 字段 | 类型 | 必填/默认 | 语义与约束 |
| --- | --- | --- | --- |
| `id` | `String` | 必填，`singleton` | 唯一固定主键。 |
| `currentStreakDays` | `Int` | 必填，`0` | 以 `lastCompletedDayKey` 为结束日的连续完成日期长度，不能为负数。 |
| `lastCompletedDayKey` | `String?` | 可选 | 最近一个至少有 1 个有效完整会话的日期键；无完成记录时为 `nil`。 |
| `calculationVersion` | `Int` | 必填，`1` | streak 算法版本；v1 只接受 1，升级时先迁移/重算再写入新版本。 |
| `updatedAt` | `Date` | 必填 | 最近一次重算时间点。 |

streak 按相邻 Gregorian 设备日期键判断，不按 24 小时秒数、提醒次数、周期数或 Watch 会话判断。同一天多次完成只占一个 streak 日，但增加该日的 `completedSessionCount`。删除、修复或导入本地记录后，iPhone 必须从有效完成会话集合完整重建日历和 streak，不能盲目递增。

## 4. App Group v1 版本化快照

### 4.1 用途、路径与所有权

App Group 标识固定为 `group.com.pip.app`，正式文件名固定为 `PipSnapshot.json`。快照是给 Widget 和 Watch 的只读投影，不是第二数据库，也不是跨设备同步格式。

- iPhone App 是唯一快照写入者；只有 iPhone 的业务协调层可以调用快照写入流程。
- Widget 和 Watch 只能调用读取流程，不得调用写入、替换、删除或修复流程；即使共享源码中存在 `PipSnapshotStore.write`，target 级代码也不得从 Widget/Watch 调用它。
- 生产运行必须使用 App Group 容器 URL。若 `containerURL(forSecurityApplicationGroupIdentifier:)` 不可用，不能静默改写到各 target 私有的 Application Support 并把它当作共享快照；测试可以注入临时 URL，生产应安全失败并等待下次写入。
- Watch 独立会话只存在于 Watch 内存；它不写快照、不写 iPhone SwiftData、不改通知配置，也不触发 iPhone 通知权限请求。

### 4.2 v1 JSON schema

外层 JSON 字段固定如下。Swift 模型中的 `Date`/`Date?` 在 JSON 线上编码为 ISO 8601 UTC `String`/`String?`。

```json
{
  "schemaVersion": 1,
  "deviceDayKey": "2026-08-21",
  "todayCompletedCount": 2,
  "currentStreakDays": 4,
  "nextReminderAt": "2026-08-21T13:00:00Z",
  "nextReminderSlotKey": "afternoon",
  "pipStaticState": "idle",
  "updatedAt": "2026-08-21T08:00:00Z"
}
```

| 字段 | Swift 类型 | JSON 类型 | 必填/默认 | 语义与约束 |
| --- | --- | --- | --- | --- |
| `schemaVersion` | `Int` | `number` | 必填，`1` | 快照格式版本，不是 SwiftData schema 版本；只能读取明确支持的版本。 |
| `deviceDayKey` | `String` | `string` | 必填 | 生成快照时的当前设备 Gregorian 日期键。 |
| `todayCompletedCount` | `Int` | `number` | 必填，`0` | `deviceDayKey` 当天有效完整会话的数量；不得包含暂停、未完成或 Watch 会话。 |
| `currentStreakDays` | `Int` | `number` | 必填，`0` | 与 iPhone `StreakState.currentStreakDays` 一致，不能为负数。 |
| `nextReminderAt` | `Date?` | `string | null` | 可选 | 当前设备时区下下一次启用提醒的绝对时间，线上以 ISO 8601 UTC 字符串表示；无下一提醒时为 `null`。 |
| `nextReminderSlotKey` | `String?` | `string | null` | 可选 | 与 `nextReminderAt` 成对出现；无下一提醒时必须为 `null`。 |
| `pipStaticState` | `PipStaticState` | `string` | 必填，`idle` | 只允许 `idle`、`waiting`、`done`；只表示静态投影，不包含动画帧或播放进度。 |
| `updatedAt` | `Date` | `string` | 必填 | 快照完成写入时间，线上以 ISO 8601 UTC 字符串表示。 |

快照对象还必须满足以下交叉不变量：

- `schemaVersion` 必须等于读取方支持的 v1 版本 1；版本 0、未来版本或任何其他未知版本都整体视为不支持。
- `todayCompletedCount >= 0`、`currentStreakDays >= 0`。
- `nextReminderAt` 与 `nextReminderSlotKey` 必须同时为 `nil`，或同时非 `nil` 且槽位键非空；不能只出现其中一个。
- `pipStaticState == done` 只能由 iPhone 在有效完成事件后的短反馈窗口写入；Widget/Watch 不得自行推断或升级为 `done`。
- `nextReminderAt` 必须由当前设备时区的下一次有效启用槽位计算；时区或槽位变化后由 iPhone 重建快照。

推荐静态状态映射：无可恢复会话且无完成反馈时为 `idle`；存在可恢复会话或等待下一次操作时为 `waiting`；有效完整会话刚完成且处于反馈窗口时为 `done`。反馈窗口结束后由 iPhone 写回 `idle` 或 `waiting`。

### 4.3 原子写入

iPhone 生成快照时必须按以下顺序执行：

1. 在同一份本地 SwiftData 事实数据上完成会话保存、日历聚合和 streak 重算，并成功保存本地事务。
2. 从保存后的事实数据构造完整 `PipSnapshot`；快照不是统计事实来源，UI 不得直接递增快照取代 SwiftData 写入。
3. 使用 ISO 8601 编码器把完整 JSON 写入正式文件同目录的唯一临时文件；临时文件写完并成功编码后，使用同目录替换操作（如 `replaceItemAt`）一次性替换正式文件。
4. 不得原地逐字段更新正式 JSON。替换失败时保留上一份完整快照，并清理临时文件。
5. 所有 iPhone 写入流程串行化；正式 target 同一时刻只允许一个 iPhone 写入者。正式文件替换成功后才可请求 Widget 刷新。

### 4.4 读取、版本降级与陈旧数据

Widget/Watch 读取方遇到文件不存在、App Group 不可读、JSON 损坏、必填字段缺失、日期键格式错误、日期无法按 ISO 8601 解码、数值为负数、交叉字段不一致、非法 `pipStaticState` 或 `schemaVersion != 1` 时，必须整体降级为安全空状态：当前设备日期键、今日 0、streak 0、无下一提醒、Pip `idle`。不得部分显示旧对象、猜测缺失字段、忽略版本号继续解析、修复后回写或删除正式文件。

若 JSON 合法但 `deviceDayKey` 不是读取时当前设备日期键，读取方不得把 `todayCompletedCount`、`nextReminderAt` 或 `done` 当作今天有效数据；在 iPhone 更新快照前使用今日 0、无下一提醒、`idle`/`waiting` 的安全显示。读取方仍可显示合法的历史 streak 投影，但不能把陈旧日期的计数冒充今日计数。

## 5. 本地通知与权限时机

- 只有 iPhone App 可以请求通知权限、创建或取消 Pip 通知；Widget 和 Watch 不请求本地通知权限。
- 权限请求的门槛是本地安装内第一次成功保存的有效完整 `SessionRecord`。首次启动、首次打开设置、首轮开始前、暂停、取消、`incomplete` 或 Watch 完成均不得触发 `UNUserNotificationCenter.requestAuthorization`。
- iPhone 在完成记录和统计本地事务成功后，才允许执行该权限请求；权限请求门槛按本地安装幂等，只自动请求一次。门槛标记存于 iPhone 私有本地偏好，不写入 App Group，也不作为业务统计字段。
- 用户授权后，按 `ReminderSlot` 的本地星期、小时和分钟创建重复 `UNCalendarNotificationTrigger`；将 bit 0...6 的周一至周日映射为系统 `DateComponents.weekday`，并使用当前设备时区解释组件。
- 用户拒绝后不自动反复弹窗；设置页只能提供系统 Settings 入口或符合系统状态的再次请求入口，不能绕过系统权限。
- 修改槽位、关闭槽位、权限变化、时区变化和应用重新安装后的本地首次调度都必须先取消 `Pip.Reminder.<slotKey>.weekday-<foundationWeekday>` 范围内的旧请求，再按最多 3 个有效槽位重建；实现可通过固定的 v1 槽位键与星期值枚举所有 Pip 自有标识。
- 通知正文只表达习惯提醒，不包含医疗疗效承诺；通知不依赖网络、账户或服务端。Focus、系统通知设置和节能策略由系统决定，Pip 不通过私有或额外推送通道绕过它们。

## 6. Entitlement 与 target 边界

| Target | 允许能力 | 禁止能力 |
| --- | --- | --- |
| iPhone App | 本地 SwiftData `ModelContainer`/`ModelContext` 读写；`group.com.pip.app` 读写 `PipSnapshot.json`；本地通知权限与 `UNCalendarNotificationTrigger`；本地触觉。 | 网络、REST/API、HTTP、WebSocket、APNs、CloudKit/iCloud、`WatchConnectivity`、HealthKit、账户/认证、StoreKit/IAP、广告、聊天 SDK、Live Activity/ActivityKit。 |
| Watch App/Extension | `group.com.pip.app` 只读；读取快照用于界面和 complication；独立内存会话、Watch 触觉和本地界面。 | 创建 SwiftData 容器；写共享快照；写 iPhone SwiftData、日历、streak 或通知配置；跨设备同步；网络、账户、CloudKit/iCloud、`WatchConnectivity`、HealthKit、IAP、广告、聊天 SDK、Live Activity/ActivityKit。 |
| Widget Extension | `group.com.pip.app` 只读；WidgetKit small Widget 时间线；读取静态 Pip 状态、今日次数和下一提醒。 | 创建 SwiftData 容器；写任何业务数据或快照；启动会话；请求通知权限；网络、APNs、CloudKit/iCloud、HealthKit、StoreKit/IAP、Live Activity/ActivityKit、广告或聊天 SDK；锁屏 Widget。 |

除 `group.com.pip.app` 外，v1 不新增共享容器或业务 entitlement。Provisioning 配置必须在需要读取的 target 间保持一致，但 target 的 capability 不得把 Watch/Widget 变成写入者。

## 7. 验收不变量

- 任何日历正数、今日正数或 streak 正数都能追溯到唯一的 `SessionRecord.id`，且该记录 `statusRaw == completed`、`completedCycles == 8`、`activeSeconds == 48`、`completedAt` 和 `completionDayKey` 均有效。
- `paused`、`incomplete`、未知状态或不满足完成不变量的记录永远不进入今日完成次数、`CalendarDayStat` 正数、`StreakState` 或 App Group 正数统计。
- `todayCompletedCount`、`CalendarDayStat` 当日计数和 iPhone 首页计数使用同一个 Gregorian 设备日期键；跨午夜按完成时间归属。
- `currentStreakDays` 只按有效完成日期键的连续天数计算；同日多次不增加天数，提醒次数、周期数和 Watch 完成不影响 streak。
- SwiftData 事实只由 iPhone 写入；App Group 快照只有 iPhone 写入，Widget/Watch 只读；正式快照写入是同目录原子替换，未知或非法 schema 整体降级。
- 首次完整会话成功落盘后才允许自动请求通知权限；首轮开始前和所有未完成路径都不请求。
- 没有任何 v1 功能要求服务器、REST/API、网络、账户/认证、CloudKit/iCloud、HealthKit、StoreKit/IAP、广告、聊天 SDK、WatchConnectivity、APNs、Live Activity 或 ActivityKit。
