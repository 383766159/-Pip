# Pip v1 技术交接文档

**文档状态：** 当前实现交接版，2026-08-23

**适用项目：** 当前仓库根目录（AppPiPi）

**读者：** 接手 Pip 项目的其他 AI、iOS/watchOS 工程师、QA 或发布负责人。

## 0. 先读结论

Pip v1 是一个纯本地原生 SwiftUI 应用，包含 iPhone App、Watch App/Extension 和 iOS small Widget。它没有后端、账户、网络、云同步、HealthKit、StoreKit/IAP、广告、Live Activity 或 APNs；iPhone 使用 SwiftData 保存业务事实，Watch 与 Widget 通过 App Group 读取只读快照。

当前最终证据如下：

- iOS `PipTests` 最终全量 **47/47 通过**。
- iOS Release 无签名构建通过。
- Widget Release 无签名构建通过。
- `PrivacyInfo.xcprivacy` 及相关 plist lint 通过。
- 禁止依赖/包管理器静态扫描通过。
- iPhone 17 Simulator 的浅色、深色和大字号布局截图通过，最终截图为 `1206x2622`。
- Watch generic build 当前**未验证**，原因是本机没有 watchOS 26.5 SDK。
- Start 点击、首次说明确认、倒计时、完整 48 秒完成态、真实通知授权/Focus、实体设备无障碍和 Widget 实际安装等运行时项目仍未独立验证。

不要把“iOS 自动化测试通过”写成“已经完成全部设备验收”。发布前仍需要 Watch SDK/设备、真实 iPhone 系统能力和 App Store Connect 外部配置。

### 0.1 资料的权威顺序

遇到描述冲突时按以下顺序判断：

1. `Pip/` 当前源代码：当前实际行为。
2. `PipTests/`：可重复的自动化行为契约。
3. [`Docs/Architecture/PipV1DataContract.md`](../Architecture/PipV1DataContract.md)：设计边界、数据字段和跨 target 契约。
4. [`QA/PipV1TestMatrix.md`](../../QA/PipV1TestMatrix.md)、[`QA/PipV1AcceptanceReport.md`](../../QA/PipV1AcceptanceReport.md)、[`QA/PipUIIntegrityReview.md`](../../QA/PipUIIntegrityReview.md)：验证证据和限制。
5. [`.openteams/plan.md`](../../.openteams/plan.md)：OpenTeams 执行节点状态。
6. 根目录 [`plan.md`](../../plan.md)：早期冻结的产品计划，不是当前实现状态，也不是测试报告。

## 1. 产品目标与范围

Pip 是一个轻量的每日习惯工具，使用 48 秒的 `lift → release` 节奏帮助用户完成一次短 session。产品文案以 Kegels 为主、pelvic floor 为解释，不作医疗疗效承诺。

### 1.1 v1 已冻结的边界

| 项目 | 约束 |
| --- | --- |
| 平台 | iOS 17+；watchOS 10+；Widget 为 iOS system small |
| UI | SwiftUI，英文界面，浅色/深色模式 |
| 数据 | 设备本地 SwiftData；无账号、无登录、无云同步 |
| 提醒 | 本地 `UNCalendarNotificationTrigger`；默认工作日 09:00、13:00、20:00 |
| 会话 | 3 秒 lift + 3 秒 release，重复 8 次，总有效时间 48 秒 |
| 统计 | 只有完整 session 才计入今日次数、日历和 streak |
| Watch | 独立会话；v1 不将 Watch 完成同步回 iPhone |
| Widget | 只读、`systemSmall`、不提供开始按钮/交互 AppIntent |
| 商店 | Health & Fitness、4+、目标价格 USD 0.99；具体 storefront 由发布方配置 |

### 1.2 明确不属于 v1 的能力

不要在没有重新评审范围的情况下加入以下能力：

- REST/API、HTTP、WebSocket、远程配置、远程日志或任何网络请求。
- 账户、认证、社交关系、跨设备同步、CloudKit、iCloud、`WatchConnectivity`。
- HealthKit、Workout 路径、StoreKit/IAP、订阅、广告或第三方分析 SDK。
- APNs、Live Activity、ActivityKit、锁屏 Widget 或可从 Widget 启动 session 的交互。
- 医疗诊断、治疗、疗效或康复承诺。

## 2. 技术栈与 target 架构

### 2.1 技术栈

- Swift 5.9
- SwiftUI
- SwiftData，`groupContainer: .none`、`cloudKitDatabase: .none`
- WidgetKit
- ClockKit complications
- UserNotifications
- XCTest
- Xcode / `xcodebuild` / `xcrun simctl`

### 2.2 Target 矩阵

| Target | Bundle ID | 最低系统 | 责任 | 写入权限 |
| --- | --- | --- | --- | --- |
| `Pip` | `com.rainanlin.pip` | iOS 17.0 | iPhone 主 App、SwiftData、会话、提醒、统计、快照写入 | 写 SwiftData；写 App Group snapshot；请求通知权限 |
| `PipWatch` | `com.rainanlin.pip.watchkitapp` | watchOS 10.0 | Watch 容器 | 不写 iPhone 数据 |
| `PipWatchExtension` | `com.rainanlin.pip.watchkitapp.extension` | watchOS 10.0 | Watch UI、独立会话、complications | 只读 App Group snapshot |
| `PipWidgetExtension` | `com.rainanlin.pip.widget` | iOS 17.0 | small Widget、时间线 | 只读 App Group snapshot |
| `PipTests` | `com.rainanlin.pip.tests` | iOS 17.0 | iOS/共享代码的 XCTest | 测试可注入临时 URL 和内存 SwiftData |

所有正式 target 使用同一个 App Group：`group.com.rainanlin.pip`。对应 entitlement 文件是：

- `Pip/Resources/Pip.entitlements`
- `Pip/Widget/Resources/PipWidget.entitlements`
- `Pip/Watch/Resources/PipWatchApp.entitlements`
- `Pip/Watch/Resources/PipWatchExtension.entitlements`

### 2.3 运行时数据流

```text
PipApp
  └─ LocalStore(ModelContainer)
       ├─ HomeViewModel ── SessionEngine
       │       └─ 完整完成
       │            ├─ SessionRecord(.completed)
       │            ├─ LocalStatsRebuilder
       │            │    ├─ CalendarDayStat
       │            │    └─ StreakState
       │            ├─ PipSnapshotStore.write(PipSnapshot.json)
       │            └─ NotificationCenter.pipSessionCompleted
       │                 └─ NotificationAuthorization
       │
       └─ ReminderSettingsViewModel ── ReminderScheduler
                                      └─ 本地 UNCalendarNotificationTrigger

App Group PipSnapshot.json
  ├─ PipWidgetSnapshotReader ── PipWidgetProvider ── WidgetKit small Widget
  └─ WatchSurfaceSnapshotReader ── Watch UI / ClockKit complications
```

关键原则：SwiftData 是业务事实来源；App Group JSON 只是给 Widget/Watch 的投影。Widget/Watch 不得把 snapshot 当作第二数据库，也不得回写或自行修复它。

## 3. 目录与模块职责

```text
Pip/
├─ Shared/
│  ├─ Exercise/       纯 Swift 会话引擎与配置
│  ├─ Models/         SwiftData 模型、日期键、snapshot DTO
│  ├─ Persistence/    SwiftData 容器、snapshot 原子读写、Widget reader
│  ├─ Stats/           从完成记录重建日历和 streak
│  └─ DesignSystem/   颜色、背景、动态主题 token
├─ iOS/
│  ├─ App/            App 入口和根视图
│  ├─ Home/           首页状态机、Pip 阶段、会话控制
│  ├─ Reminders/      通知授权、slot 编辑和调度
│  ├─ Calendar/       月历、日期计数、streak 展示
│  ├─ Settings/       设置、触感、隐私、可访问性
│  └─ Resources/      Pip SVG 帧与颜色资源
├─ Watch/
│  └─ Extension/     独立 Watch 会话、进度环、complications、snapshot reader
├─ Widget/            small Widget entry、provider、视图
└─ Resources/         App plist、entitlements、PrivacyInfo

PipTests/              47 个 XCTest
Docs/Architecture/      数据契约
Docs/Store/             商店文案与隐私政策草稿
QA/                     测试矩阵、验收报告、UI 完整性报告
.openteams/             OpenTeams 计划、spec、执行记录
```

## 4. 会话引擎与首页状态机

### 4.1 计时规则

`Pip/Shared/Exercise/SessionConfiguration.swift` 固定：

| 参数 | 值 |
| --- | ---: |
| `liftDuration` | 3 秒 |
| `releaseDuration` | 3 秒 |
| `repetitionCount` | 8 |
| `totalDuration` | 48 秒 |

`SessionEngine` 是无副作用、可显式 tick 的纯 Swift value type。它不依赖真实 `sleep`，测试可直接调用 `advance(by:)`。

### 4.2 引擎阶段

`SessionPhase`：

```text
idle
  └─ start() → lift(repetition: 1)
       ├─ 3 秒边界 → release(repetition: n)
       ├─ 3 秒边界且 n < 8 → lift(repetition: n + 1)
       └─ 第 8 次 release 完成 → completed

lift/release ── pause() → paused ── resume() → 原阶段
lift/release/paused ── cancel() → cancelled
```

引擎事件：

- `haptic(.lift)`：开始 lift 或进入下一轮 lift。
- `haptic(.release)`：lift 结束进入 release。
- `haptic(.success)`：第 8 轮完成。
- `.completed`：只在满足 `8 cycles + 48 activeSeconds` 时发出一次。

### 4.3 iPhone 首页

入口文件：

- `Pip/iOS/Home/HomeState.swift`：`idle / session / done`
- `Pip/iOS/Home/HomeViewModel.swift`：引擎、计时、持久化、快照和触感桥接
- `Pip/iOS/Home/HomeView.swift`：单屏 UI、导航和 scene 生命周期
- `Pip/iOS/Home/PipStage.swift`：`idle / lift / release / done`、帧索引和无障碍标题

行为：

1. 初次点击 Start 时写入 `Pip.Home.hasShownStartExplanation`，显示一次说明 Sheet。
2. 用户确认后进入 `.session`，开始 1 秒一 tick 的 `Task` 时钟。
3. 首页显示 TODAY 完成数、Pip 阶段、剩余秒数和 Pause/Resume/Cancel。
4. 离开页面或 scene 不 active 时调用 `pauseForLeaving()`，不刷新今日计数和 snapshot。
5. 取消只回到 idle，不写完成记录、不增加次数。
6. 只有引擎完成后才创建 `SessionRecord(.completed)`、重建统计、写 snapshot 并发出完成通知。
7. Reduce Motion 时使用静态帧/淡入淡出，但保留触感。
8. VoiceOver 文案包含阶段、剩余秒数和当前可用操作。

首页布局修复已集中在：

- `Pip/Resources/Info.plist`：`UILaunchScreen`、全屏 portrait 配置。
- `Pip/iOS/Home/HomeView.swift`：header 独立高度、剩余区域居中、紧凑高度响应式布局。
- `Pip/Shared/DesignSystem/PipTheme.swift`：`ink(for:)` 修复深色模式图标/标题对比度。

### 4.4 完成入账不变量

`SessionRecord.satisfiesCompletionInvariant` 要求：

```text
status == .completed
completedCycles == 8
activeSeconds == 48
completedAt != nil
completionDayKey 是合法 yyyy-MM-dd
```

任何不满足条件的记录都不能进入今日次数、日历或 streak。重复完成事件由 `HomeViewModel.didRecordCompletion` 防止重复入账。

### 4.5 重要实现差异：暂停持久化

数据契约为 `SessionRecord` 预留了 `paused`、`incomplete`、`lastResumedAt` 和 `pauseCount`，并描述了可恢复的本地会话边界；但当前 iPhone 运行路径中，`HomeViewModel.pauseSession()` / `pauseForLeaving()` 只暂停内存中的 `SessionEngine`，当前代码只有完成路径真正插入 `SessionRecord(.completed)`。

因此接手者必须区分：

- 已验证：离开时引擎暂停、继续 tick 不前进、今日计数和 snapshot 不刷新。
- 尚未实现为完整持久化路径：杀进程/重启后恢复暂停 session、写入 `paused`/`incomplete` 记录。

如果要补齐持久化恢复，必须同步更新数据契约、`HomeViewModel`、迁移策略和测试；不能只在 UI 增加一个恢复按钮。

## 5. 本地数据模型

完整字段契约见 [`Docs/Architecture/PipV1DataContract.md`](../Architecture/PipV1DataContract.md)。下面是接手开发必须保留的字段和不变量。

### 5.1 `SessionRecord` / `PipSession`

文件：`Pip/Shared/Models/SessionRecord.swift`

| 字段 | 类型 | 说明 |
| --- | --- | --- |
| `id` | `UUID` | 幂等主键；完成统计按它去重 |
| `statusRaw` | `String` | `paused`、`completed`、`incomplete` |
| `startedAt` / `lastResumedAt` | `Date` / `Date?` | 首次开始和最近恢复时间 |
| `completedAt` | `Date?` | 仅 completed 有值 |
| `startDayKey` / `completionDayKey` | `String` / `String?` | Gregorian `yyyy-MM-dd`；完成统计只看 completion key |
| `completedCycles` | `Int` | `0...8`；completed 必须为 8 |
| `activeSeconds` | `Int` | `0...48`；completed 必须为 48 |
| `pauseCount` | `Int` | 不得为负 |
| `createdAt` / `updatedAt` | `Date` | 更新时间不早于创建时间 |

未知 `statusRaw` 会按 `.incomplete` 处理；不满足完成不变量的记录不得被猜测为已完成。

### 5.2 `ReminderSlot`

文件：`Pip/Shared/Models/ReminderSlot.swift`

- 稳定键：`morning`、`afternoon`、`evening`。
- 默认：工作日 `09:00`、`13:00`、`20:00`。
- `hour` 为 `0...23`，`minute` 为 `0...59`，`weekdayMask` 为 `1...127`。
- bit 0...6 表示周一至周日；系统 `DateComponents.weekday` 则是周日 1、周一 2…周六 7。
- 最多三个有效 slot；保存时先撤销 Pip 自有通知再重建。

### 5.3 `CalendarDayStat` 与 `StreakState`

文件：`Pip/Shared/Models/CalendarDayStat.swift`、`Pip/Shared/Models/StreakState.swift`。

- `CalendarDayStat.dayKey` 唯一，保存某天完成 session 数和该日结束的 streak 长度。
- `StreakState.id` 固定为 `singleton`，保存当前 streak、最后完成日期和计算版本。
- 二者都是可重建聚合，不是完成事实的唯一来源。
- `LocalStatsRebuilder` 只从满足 completed invariant 的 `SessionRecord` 重建，并删除过期/重复聚合。
- 同一天多次完成增加当天 count，但只占一个 streak 日。
- 设备时区下的历史 `completionDayKey` 是冻结事实；时区变化不能重写历史日期归属。

### 5.4 `PipSnapshot`

文件：`Pip/Shared/Models/PipSnapshot.swift`。

App Group 文件名固定为 `PipSnapshot.json`，schema v1 示例：

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

约束：

- `schemaVersion` 必须为 1。
- 日期键必须是合法 Gregorian `yyyy-MM-dd`。
- `todayCompletedCount`、`currentStreakDays` 不得为负。
- `nextReminderAt` 和 `nextReminderSlotKey` 必须同时存在或同时为空。
- `pipStaticState` 只能是 `idle`、`waiting`、`done`。
- `Date` 在 JSON 中用 ISO 8601 编码。

`PipSnapshotStore.write` 在同目录写临时文件，再用替换/移动完成原子更新；App Group 不可用时抛出 `.unavailable`，不回退到 target 私有 Application Support。

读取方行为：

- `PipWidgetSnapshotReader` 对 missing、corrupt、unknown schema、expired、stale day 返回 `WidgetSurfaceSnapshot.empty(reason)`。
- `WatchSurfaceSnapshotReader` 对无效/过期/非当天 snapshot 返回 `nil`。
- Widget/Watch 不得回写、删除或修复正式 snapshot。
- 快照超过 24 小时或日期键不是当前设备日期时，不能把历史 count 冒充为今天。

## 6. 功能目录

### 6.1 首页和 Pip 动效

**入口：** `PipRootView → HomeView`

**核心文件：**

- `Pip/iOS/App/PipRootView.swift`
- `Pip/iOS/Home/HomeState.swift`
- `Pip/iOS/Home/HomeViewModel.swift`
- `Pip/iOS/Home/HomeView.swift`
- `Pip/iOS/Home/PipStage.swift`
- `Pip/iOS/Resources/Assets.xcassets/PipFrames/`

**测试：** `PipTests/HomeStateTests.swift`，9 项。

**当前能力：** idle/session/done、首次短说明、倒计时、暂停/继续/取消、完成反馈、今日次数、触感、Reduce Motion、VoiceOver、日历 push、设置 sheet。

**修改注意：** 不要在 `HomeView` 自行计算 streak；不要从 UI 直接递增 count；完成必须通过 `HomeViewModel.finishSession()` 的事实保存和重建流程。

### 6.2 本地提醒

**核心文件：**

- `Pip/iOS/Reminders/NotificationAuthorization.swift`
- `Pip/iOS/Reminders/ReminderScheduler.swift`
- `Pip/iOS/Reminders/ReminderSettingsViewModel.swift`
- `Pip/iOS/Reminders/ReminderSettingsView.swift`

**行为：**

- 首次完整 session 完成后由 `.pipSessionCompleted` 事件触发通知权限请求。
- 权限请求幂等标记保存在 iPhone `UserDefaults`。
- 设置页编辑三个时间、周末开关和启用状态。
- 调度使用 `UNCalendarNotificationTrigger`，稳定 identifier 为 `Pip.Reminder.<slotKey>.weekday-<foundationWeekday>`。
- 保存时取消 Pip 自有旧请求，再重建有效请求。
- 文案为 `Pip reminder` / `A short Kegel session is ready when you are.`。

**测试：** `PipTests/ReminderSchedulerTests.swift`，6 项。

**当前差异：** `ReminderScheduler` 能创建通知请求，但当前代码没有独立的“下一次提醒时间计算器”；`HomeViewModel.writeSnapshot` 只是沿用已有 snapshot 的 `nextReminderAt`/`nextReminderSlotKey`。因此 Widget/complication 的 “Next reminder” 可能为空，即使通知已经被调度。若要补齐，需要新增可测试的 next-reminder 计算和在设置/时区/应用启动/完成后重写 snapshot 的流程。

### 6.3 日历、今日次数和 streak

**核心文件：**

- `Pip/Shared/Stats/StreakCalculator.swift`
- `Pip/Shared/Stats/LocalStatsRebuilder.swift`
- `Pip/iOS/Calendar/CalendarViewModel.swift`
- `Pip/iOS/Calendar/CalendarView.swift`

**行为：** 月历显示每日完成数；点击日期显示当天 count、当天结束的 streak 和当前 streak。统计按冻结的 `completionDayKey` 聚合，不按提醒次数、周期数或 Watch 完成计算。

**测试：**

- `PipTests/StreakCalculatorTests.swift`，6 项：同日多次、连续日、断档、跨月、设备时区、冻结日期键。
- `PipTests/LocalStatsRebuilderTests.swift`，2 项：重建和删除陈旧聚合。
- `PipTests/HomeStateTests.swift` 覆盖完成后重建日历和 singleton streak。

### 6.4 Watch

**核心文件：**

- `Pip/Watch/Extension/PipWatchExtension.swift`
- `Pip/Watch/Extension/WatchSessionModel.swift`
- `Pip/Watch/Extension/WatchSurfaceSnapshot.swift`
- `Pip/Watch/Extension/PipWatchComplications.swift`

**行为：**

- Watch 自己持有 `SessionEngine`，独立运行 48 秒会话。
- UI 显示 snapshot 中的今日次数、环形进度、剩余秒数、Lift/Release、Start/Pause/Resume/Cancel。
- lift/release 使用 `.click`，完成使用 `.success`。
- complications 支持 `circularSmall`、`graphicCircular`、`graphicRectangular`。
- snapshot 不可读时显示 `Snapshot unavailable` 或安全空数据。

**测试：** `PipTests/WatchSessionTests.swift`，4 项；测试在 iPhone test run 中执行共享逻辑。

**范围限制：** Watch session 完成不会写 iPhone SwiftData、日历、streak、今日次数或 App Group snapshot；v1 不做 Watch→iPhone 统计同步。当前本机缺 watchOS 26.5 SDK，Watch target 没有完成 generic build 和运行时验证。

### 6.5 Widget

**核心文件：**

- `Pip/Widget/PipWidget.swift`
- `Pip/Widget/PipWidgetProvider.swift`
- `Pip/Widget/PipWidgetEntry.swift`
- `Pip/Shared/Persistence/PipWidgetSnapshotReader.swift`

**行为：**

- 只声明 `.systemSmall`。
- 显示 Pip、今日完成数、idle/waiting/done 状态和下一提醒；没有数据时显示 `No data yet`。
- 时间线每 15 分钟刷新一次。
- 点击 Widget 由系统打开 App；没有 start button、AppIntent、Live Activity 或 lock-screen Widget。
- 读取失败、未知 schema、过期、stale day、字段不完整时安全降级。

**测试：** `PipTests/WidgetSnapshotTests.swift`，5 项。

**未验证：** 实际把 Widget 加入 Home Screen、三种状态的视觉展示、点击打开行为和 stale-day 文案仍需在模拟器或设备上手工验证。

### 6.6 设置、隐私和可访问性

**核心文件：**

- `Pip/iOS/Settings/SettingsView.swift`
- `Pip/iOS/Settings/SettingsViewModel.swift`
- `Pip/iOS/Settings/PipPreferences.swift`
- `Pip/iOS/Settings/PrivacyView.swift`
- `Pip/iOS/Settings/AccessibilityView.swift`
- `Pip/iOS/Settings/AccessibilitySupport.swift`
- `Pip/Resources/PrivacyInfo.xcprivacy`

**行为：** 设置页入口包含提醒、触感开关、可访问性说明、隐私页、非医疗声明和版本号。触感默认开启，使用 `Pip.Preferences.hapticsEnabled` 保存。隐私页说明数据仅在设备上，不包含账户、云同步、分析、广告、IAP 或第三方分享。

`PrivacyInfo.xcprivacy` 声明：

- `NSPrivacyTracking = false`
- collected data types 为空
- UserDefaults API reason `CA92.1`

**测试：** `PipTests/SettingsTests.swift`，3 项；其中包含触感偏好、48 秒完成不变量和深色主题 ink 对比度回归。

**未验证：** 实体设备最大 Dynamic Type、VoiceOver、Reduce Motion、Dark Mode 和 Widget 无障碍仍需人工复验。

### 6.7 商店资料

现有材料：

- `Docs/Store/PipV1StoreCopy.md`
- `Docs/Store/PrivacyPolicy.md`
- `Docs/AppStore/EnglishStoreCopy.md`

文案要求：英文、以 Kegels 为主、解释 pelvic floor、不作医疗声称。隐私政策的公开 HTTPS URL、支持联系方式和 App Store Connect 实际配置仍未完成，不能把草稿当成可提交的发布资料。

## 7. 关键文件索引

| 目的 | 文件 |
| --- | --- |
| App 入口 | `Pip/iOS/App/PipApp.swift`, `Pip/iOS/App/PipRootView.swift` |
| SwiftData 容器 | `Pip/Shared/Persistence/LocalStore.swift` |
| 会话规则 | `Pip/Shared/Exercise/SessionConfiguration.swift`, `SessionPhase.swift`, `SessionEngine.swift` |
| 会话事实 | `Pip/Shared/Models/SessionRecord.swift` |
| Reminder 模型 | `Pip/Shared/Models/ReminderSlot.swift` |
| 日历/streak 模型 | `Pip/Shared/Models/CalendarDayStat.swift`, `StreakState.swift` |
| Snapshot DTO | `Pip/Shared/Models/PipSnapshot.swift` |
| Snapshot 原子读写 | `Pip/Shared/Persistence/PipSnapshotStore.swift` |
| Widget 安全读取 | `Pip/Shared/Persistence/PipWidgetSnapshotReader.swift` |
| 统计重建 | `Pip/Shared/Stats/LocalStatsRebuilder.swift`, `StreakCalculator.swift` |
| 首页 | `Pip/iOS/Home/` |
| 提醒 | `Pip/iOS/Reminders/` |
| 日历 | `Pip/iOS/Calendar/` |
| 设置/隐私 | `Pip/iOS/Settings/`, `Pip/Resources/PrivacyInfo.xcprivacy` |
| Watch | `Pip/Watch/Extension/` |
| Widget | `Pip/Widget/` |
| 自动化测试 | `PipTests/` |
| 产品/数据文档 | `plan.md`, `Docs/Architecture/PipV1DataContract.md` |
| QA 证据 | `QA/PipV1TestMatrix.md`, `QA/PipV1AcceptanceReport.md`, `QA/PipUIIntegrityReview.md` |

## 8. 构建、测试与静态检查

以下命令假设当前目录为仓库根目录，并使用本机 Xcode：

```bash
export DEVELOPER_DIR=/Applications/Xcode.app/Contents/Developer
```

### 8.1 查看工程 target

```bash
xcodebuild -list -project Pip.xcodeproj
```

应能看到 `Pip`、`PipWatch`、`PipWatchExtension`、`PipWidgetExtension` 和 `PipTests`。

### 8.2 iOS 全量测试

最终证据使用 iPhone 17 Simulator：

```bash
DEVELOPER_DIR=/Applications/Xcode.app/Contents/Developer \
xcodebuild -project Pip.xcodeproj \
  -scheme Pip \
  -destination 'platform=iOS Simulator,name=iPhone 17,OS=latest' \
  test
```

期望：`TEST SUCCEEDED`，当前最终结果为 47 tests、0 failures。

本次交接文档自检于 2026-08-23 重新执行成功，result bundle：
`<DerivedData>/Pip/Logs/Test/Test-Pip-2026.08.23_09-59-45-+0800.xcresult`

测试文件数量：

| 文件 | 项数 |
| --- | ---: |
| `HomeStateTests.swift` | 9 |
| `LocalStatsRebuilderTests.swift` | 2 |
| `PipPersistenceTests.swift` | 7 |
| `ReminderSchedulerTests.swift` | 6 |
| `SessionEngineTests.swift` | 5 |
| `SettingsTests.swift` | 3 |
| `StreakCalculatorTests.swift` | 6 |
| `WatchSessionTests.swift` | 4 |
| `WidgetSnapshotTests.swift` | 5 |
| **总计** | **47** |

旧 QA 文档中的 45/45、46/46 是主题修复前或 UI 修复前的历史结果；引用最终状态时统一使用 47/47。

### 8.3 Release 构建

```bash
DEVELOPER_DIR=/Applications/Xcode.app/Contents/Developer \
xcodebuild -project Pip.xcodeproj \
  -scheme Pip \
  -configuration Release \
  -destination 'generic/platform=iOS' \
  build CODE_SIGNING_ALLOWED=NO
```

```bash
DEVELOPER_DIR=/Applications/Xcode.app/Contents/Developer \
xcodebuild -project Pip.xcodeproj \
  -scheme PipWidgetExtension \
  -configuration Release \
  -destination 'generic/platform=iOS' \
  build CODE_SIGNING_ALLOWED=NO
```

### 8.4 Watch 构建

```bash
DEVELOPER_DIR=/Applications/Xcode.app/Contents/Developer \
xcodebuild -project Pip.xcodeproj \
  -scheme PipWatch \
  -configuration Release \
  -destination 'generic/platform=watchOS' \
  build CODE_SIGNING_ALLOWED=NO
```

当前环境预期会因为 `watchOS 26.5 is not installed` 返回失败/无 eligible destination。安装对应 SDK 后必须重新运行，并在实体 Watch 上复验触感、进度环和 complications。

### 8.5 plist 与隐私清单

```bash
for file in \
  Pip/Resources/Info.plist \
  Pip/Resources/PrivacyInfo.xcprivacy \
  Pip/Watch/Resources/Info.plist \
  Pip/Watch/Resources/PipWatchExtension-Info.plist \
  Pip/Widget/Resources/Info.plist
do
  plutil -lint "$file"
done
```

### 8.6 禁止依赖和包扫描

```bash
rg --files | rg '(^|/)(Package\.swift|Package\.resolved|Podfile|Podfile\.lock|Cartfile|Cartfile\.resolved|Carthage|Pods|Vendor|.*\.xcworkspace)$'
```

```bash
rg -n 'URLSession|NWConnection|CloudKit|CKContainer|HKHealthStore|HKWorkout|StoreKit|SKPayment|ActivityKit|WatchConnectivity|WCSession|UNPushNotificationTrigger|APNs' Pip Docs/Store
```

第二条扫描会命中“明确排除能力”的文档文本或测试说明时，需要人工区分文档引用和实现依赖；不能只看命中数量。

### 8.7 Simulator 截图

当前最终视觉证据路径：

- `/tmp/Pip-iPhone17-qa-reinstalled-after5s.png`
- `/tmp/Pip-iPhone17-layout-balanced-standard.png`
- `/tmp/Pip-iPhone17-final-ui-large.png`
- `/tmp/Pip-iPhone17-light-theme-fixed.png`
- `/tmp/Pip-iPhone17-dark-theme-fixed.png`

最终浅色/深色截图均为 `1206x2622`。它们证明冷启动页面全屏、header/Today/Pip/状态/Start 无重叠和深色 header 可读，但不证明 GUI 点击或完整会话流程。

## 9. 最终验证结果

| 检查项 | 当前结果 | 证据/限制 |
| --- | --- | --- |
| iOS XCTest | PASS | iPhone 17 Simulator，47/47；2026-08-23 自检 result bundle 见 §8.2 |
| iOS Release build | PASS | generic iOS，无签名 |
| Widget Release build | PASS | generic iOS，无签名 |
| plist / PrivacyInfo lint | PASS | 五份 plist/隐私清单 |
| 禁止依赖扫描 | PASS | 未发现实现层网络、账户、云、HealthKit、StoreKit 等依赖 |
| 首页冷启动布局 | PASS | clean install 截图，全屏无黑边/圆角 letterbox |
| 浅色/深色首页视觉 | PASS（Simulator） | 1206x2622 截图；实体设备未验证 |
| Start/首次说明/倒计时/完成态 GUI | NOT VERIFIED | 本机没有可用 GUI 注入路径；自动化状态测试不能替代点击证据 |
| 真实通知授权/拒绝/Focus | NOT VERIFIED | 需要受控 simulator 权限或实体 iPhone |
| VoiceOver、最大 Dynamic Type、Reduce Motion | 自动化/源码覆盖；设备 NOT VERIFIED | 需要设备手工矩阵 |
| Widget 添加、状态视觉、点击 | build/reader tests PASS；runtime NOT VERIFIED | 需要模拟器或实体设备手工验证 |
| Watch build/UI/haptic/complications | BLOCKED | 本机缺 watchOS 26.5 SDK，无实体 Watch |
| 隐私政策公开 URL/联系方式/App Store Connect | NOT VERIFIED | 需要发布方账号和外部托管 |

完整的逐项矩阵见 [`QA/PipV1TestMatrix.md`](../../QA/PipV1TestMatrix.md)。

## 10. 已知限制与后续工作

### 10.1 P0：发布前必须补齐

1. 在 Xcode 安装 watchOS 26.5 SDK，完成 `PipWatch` generic build。
2. 在配对实体 Watch 上验证独立 session、暂停/继续、触感、进度环和三类 complications。
3. 在干净实体 iPhone 上验证首次完整 session 后的通知授权、拒绝/重启、通知编辑、Focus 和设备时区变化。
4. 手工验证 Start、首次说明、至少 3 秒倒计时、48 秒完成态和完成后计数只加一次。
5. 验证最大 Dynamic Type、VoiceOver、Reduce Motion、Dark Mode 和 Widget 三种状态。
6. 托管隐私政策 HTTPS URL，补充支持联系方式，配置并复核 App Store Connect 价格、分类、年龄和 storefront。

### 10.2 P1：实现与契约对齐

1. **暂停持久化：** 如果产品仍要求跨进程恢复 paused session，需要真正写入 `SessionRecord(.paused)`，处理 `lastResumedAt`/`pauseCount`，取消时转为 `.incomplete`，并补充杀进程/恢复测试。
2. **下一提醒快照：** 新增以 `ReminderSlot + Calendar + TimeZone` 为输入的 next-reminder 计算器，在提醒保存、应用启动、回前台、时区变化和完成后更新 snapshot；补充 Widget/Watch 测试。
3. **通知与 snapshot 解耦审查：** 保证通知权限、通知重建和 snapshot 的更新时间不会互相覆盖旧字段。

### 10.3 有意保留的非目标

Watch 不写回 iPhone 统计是当前 v1 契约，不要在没有产品决策的情况下通过 `WatchConnectivity` 或共享数据库“顺手补上”。同样，不要为 Widget 增加交互启动或 Live Activity 来弥补 GUI 验证缺口。

## 11. 给其他 AI 的修改规范

### 11.1 修改前

1. 先读本文件、`Docs/Architecture/PipV1DataContract.md`、相关测试和 QA 报告。
2. 用 `rg` 找到真实调用方和 target membership；不要假设文件存在于计划描述中的旧路径。
3. 判断需求是“修复当前实现”、 “补齐契约差异”还是“新增 v1 以外能力”。跨边界需求先停在计划层。
4. 若修改数据字段、snapshot schema、完成规则或 target 写权限，先更新数据契约和测试设计。

### 11.2 修改中

- 会话完成必须经过 `SessionEngine` 的 48 秒不变量；不能从按钮直接增加今日次数。
- 统计必须从有效 completed `SessionRecord` 重建；不能从 snapshot、提醒次数或 Watch 读数累加。
- SwiftData 只由 iPhone App 的 `LocalStore` 持有；Widget/Watch 不能创建业务 ModelContainer。
- App Group 只使用 `group.com.rainanlin.pip/PipSnapshot.json`；不可回退到私有 Application Support 伪装成共享状态。
- Widget/Watch 只读 snapshot；遇到未知 schema、损坏、过期或 stale day 必须安全降级。
- 用户可见文案保持英文、Kegels/pelvic floor 词汇和非医疗定位；不要引入禁用词或疗效声称。
- 保持 `Pip/Resources/Info.plist` 的 portrait/full-screen/launch screen 配置和 `PipTheme.ink(for:)` 的深色对比度。

### 11.3 修改后

至少运行：

```bash
DEVELOPER_DIR=/Applications/Xcode.app/Contents/Developer \
xcodebuild -project Pip.xcodeproj \
  -scheme Pip \
  -destination 'platform=iOS Simulator,name=iPhone 17,OS=latest' \
  test
```

并根据影响范围运行 Widget/Watch build、plist lint、禁区扫描和相关专项测试。报告必须区分：

- 自动化通过；
- 源码覆盖但设备未验证；
- 环境阻塞；
- 外部发布条件未完成。

不能把“命令没跑”或“Watch SDK 缺失”写成通过。

### 11.4 OpenTeams 协作

- 工作流计划以 `.openteams/plan.md` 为准，只有 coordinator 修改该文件。
- 任务级写作/实现计划放在 `.openteams/plans/`。
- 代码结果写入工作区文件；群消息只发送摘要、路径和验证结果。
- 新增或修改功能后，必须同步对应测试、QA 证据和本交接文档中的限制。

## 12. 新 AI 接手清单

```text
[ ] 阅读本文件和 Docs/Architecture/PipV1DataContract.md
[ ] 运行 rg --files，确认当前文件边界
[ ] 运行 iOS 47/47 全量测试，建立基线
[ ] 确认目标是修复、契约对齐还是新增范围
[ ] 为每个行为修改先写/更新 XCTest
[ ] 保持 iPhone 写入、Watch/Widget 只读边界
[ ] 运行受影响 target 的 build/lint/静态扫描
[ ] 更新 QA 报告和 .openteams/plan.md 状态
[ ] 只在有实际设备/系统/账号证据时宣称发布就绪
```

### 12.1 当前最安全的第一步

如果没有新的产品决策，优先处理 P1 的两个实现差异：暂停 session 持久化和 next-reminder snapshot 计算；处理前先决定是否要把它们纳入 v1。若只是准备发布，则先完成 P0 的 Watch、真实 iPhone、Widget 和 App Store Connect 验证，不要扩大产品范围。
