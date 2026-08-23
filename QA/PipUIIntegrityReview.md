# Pip iOS UI Integrity Review

**验证日期:** 2026-08-22
**验证角色:** QA，独立复验
**范围:** iOS 首页上下黑边、窗口/根视图尺寸、首页可见元素、Info.plist 与 Xcode 工程设置。
**约束:** 未修改产品代码，未修改 `.openteams/plan.md`。
**最终版本复验:** 当前工作区 `HomeView` 的 `header + 主内容居中` 布局，iPhone 17 Simulator `content_size=large`。

## 结论

当前构建没有确认到产品代码层面的全屏 UI 阻塞。指定截图 `/tmp/Pip-iPhone17-foreground.png` 确实存在上下黑边，但将本轮 Debug 产物重新安装到同一 iPhone 17 Simulator 后，冷启动等待 5 秒的 `/tmp/Pip-iPhone17-qa-reinstalled-after5s.png` 已全屏显示；因此原截图更符合旧安装包或模拟器残留窗口状态，而不是 `HomeView` 持续把根视图裁成小窗口。

旧截图仍应作为环境复现记录保留：如果验收流程只执行 `launch` 而不重新安装当前构建，可能误把旧窗口状态报告为产品 UI 缺陷。

## 最终布局复验（当前工作区）

本轮读取并复验的是当前 `Pip/iOS/Home/HomeView.swift`，不是旧版本。当前实现将 header 独立放在顶部（`HomeView.swift:28-38`），将 Today、Pip、状态和操作按钮放入主内容容器，并在剩余高度内居中（`HomeView.swift:40-52`）。紧凑高度分支当前为 `spacing=16`、`pipSize=144`、`headerHeight=56`；正常高度分支为 `spacing=24`、`pipSize=220`、`headerHeight=64`（`HomeView.swift:222-237`）。

执行的标准字号和安装/截图步骤：

```bash
DEVELOPER_DIR=/Applications/Xcode.app/Contents/Developer \
  xcrun simctl ui 8DDD783C-51C9-490A-A6C7-F7466067E382 content_size large
DEVELOPER_DIR=/Applications/Xcode.app/Contents/Developer \
  xcrun simctl install 8DDD783C-51C9-490A-A6C7-F7466067E382 \
  /tmp/Pip-final-ui-tests/Build/Products/Debug-iphonesimulator/Pip.app
DEVELOPER_DIR=/Applications/Xcode.app/Contents/Developer \
  xcrun simctl terminate 8DDD783C-51C9-490A-A6C7-F7466067E382 com.pip.app
DEVELOPER_DIR=/Applications/Xcode.app/Contents/Developer \
  xcrun simctl launch 8DDD783C-51C9-490A-A6C7-F7466067E382 com.pip.app
sleep 5
DEVELOPER_DIR=/Applications/Xcode.app/Contents/Developer \
  xcrun simctl io 8DDD783C-51C9-490A-A6C7-F7466067E382 screenshot \
  /tmp/Pip-iPhone17-final-ui-large.png
```

结果：`content_size` 查询返回 `large`；截图为 `1206 x 2622`，全屏无上下黑边。header 的 Pip、Calendar、Settings 位于顶部区域；Today/0/completed sessions、Pip 图像、Ready/Ready when you are、Start 按顺序显示，元素间没有视觉重叠或裁切。主内容在 header 下方的剩余区域内居中，顶部留白与按钮下方留白均有意且连续，整体分布合理；截图中的黑色 Dynamic Island 属于系统状态区域，不是 App 黑边。

这次是视觉布局复验，未将 Start 点击、首次说明、倒计时或完成态交互列为通过；当前环境仍没有可用 GUI 注入路径。

## 复现记录

### 原始黑边复现

设备为 `iPhone 17`，UDID `8DDD783C-51C9-490A-A6C7-F7466067E382`，iOS Simulator `26.5`，屏幕为 `1206 x 2622`。在已有安装包上执行：

```bash
DEVELOPER_DIR=/Applications/Xcode.app/Contents/Developer \
  xcrun simctl terminate 8DDD783C-51C9-490A-A6C7-F7466067E382 com.pip.app
DEVELOPER_DIR=/Applications/Xcode.app/Contents/Developer \
  xcrun simctl launch 8DDD783C-51C9-490A-A6C7-F7466067E382 com.pip.app
sleep 5
DEVELOPER_DIR=/Applications/Xcode.app/Contents/Developer \
  xcrun simctl io 8DDD783C-51C9-490A-A6C7-F7466067E382 screenshot /tmp/Pip-iPhone17-qa-launch-after5s.png
```

结果：截图出现约 1206 x 1800 px 的浅色圆角 App 窗口，上方和下方为黑色区域；黑色区域不属于 `PipTheme.background`，也不是 Home 内容被裁切后的背景。截图中的首页内容仍完整可见，但被压缩到窗口高度内。

### 重新安装后的复验

使用本轮测试生成的当前 Debug 产物重新安装，再终止、启动并截图：

```bash
DEVELOPER_DIR=/Applications/Xcode.app/Contents/Developer \
  xcrun simctl install 8DDD783C-51C9-490A-A6C7-F7466067E382 \
  /tmp/Pip-qa-ui-integrity-tests/Build/Products/Debug-iphonesimulator/Pip.app
DEVELOPER_DIR=/Applications/Xcode.app/Contents/Developer \
  xcrun simctl terminate 8DDD783C-51C9-490A-A6C7-F7466067E382 com.pip.app
DEVELOPER_DIR=/Applications/Xcode.app/Contents/Developer \
  xcrun simctl launch 8DDD783C-51C9-490A-A6C7-F7466067E382 com.pip.app
sleep 5
DEVELOPER_DIR=/Applications/Xcode.app/Contents/Developer \
  xcrun simctl io 8DDD783C-51C9-490A-A6C7-F7466067E382 screenshot \
  /tmp/Pip-iPhone17-qa-reinstalled-after5s.png
```

结果：当前构建全屏覆盖 `1206 x 2622`，没有上下黑边；`Pip`、Calendar、Settings、TODAY、0、completed sessions、Pip 图像、Ready、Ready when you are 和 Start 均可见。

跨设备对照中，当前构建安装到 `iPhone 17 Pro` 后，等待启动完成的截图 `/tmp/Pip-iPhone17Pro-qa-launch-after3s.png` 与 `/tmp/Pip-iPhone17Pro-qa-launch-after-relaunch.png` 也全屏显示。这进一步支持旧截图是安装/窗口状态问题，而非稳定的 SwiftUI 根视图问题。

## 根因判断与影响

### 根因判断

证据支持的根因是：`/tmp/Pip-iPhone17-foreground.png` 采集时使用了旧的已安装 App 或其残留的模拟器窗口几何状态；重新安装当前 Debug 包后同一设备恢复全屏。当前无法仅通过仓库源码确定 CoreSimulator 为何保留该窗口状态，因此不将其归因于某个产品 API 或建议改动 `HomeView`。

源码和构建产物没有发现主动制造该窗口的设置：

- `Pip/iOS/App/PipApp.swift:30-35` 使用标准 SwiftUI `WindowGroup` 和 `modelContainer`。
- `Pip/iOS/Home/HomeView.swift:28-56` 使用 `NavigationStack`、`GeometryReader` 和垂直 `ScrollView`；header 与主内容分离，背景明确调用 `.ignoresSafeArea()`。
- `Pip/iOS/Home/HomeView.swift:222-237` 仅按可用高度选择布局；当前紧凑分支使用 spacing `16`、Pip `144`、header `56`，主内容仍在剩余高度内居中，不会创建黑色窗口。
- 当前构建产物 `Info.plist` 含 `UIRequiresFullScreen=true`、竖屏方向和 `UIDeviceFamily=[1,2]`；没有发现场景 manifest、窗口默认尺寸或可调整窗口声明。
- `Pip/Resources/Info.plist:35-39` 的 `UILaunchScreen` 仅指定 `LaunchBackground`，不会解释启动完成后仍存在的上下黑区。

### 影响

- 若使用旧安装包/残留窗口状态，首页会显示在非全屏圆角窗口内，视觉上像上下黑边，且会触发 HomeView 的 compact 分支，降低 Pip 图像和纵向间距。
- 重新安装当前构建后，黑边阻塞未复现，首页可见性通过。
- 本次没有 GUI 注入权限，因此没有把 Start、首次说明、Pause/Cancel、倒计时和完成态列为通过；视觉可见不等于交互通过。

## 通过项

### 静态检查

- `plutil -lint Pip/Resources/Info.plist Pip/Resources/PrivacyInfo.xcprivacy Pip/Widget/Resources/Info.plist Pip/Watch/Resources/Info.plist Pip/Watch/Resources/PipWatchExtension-Info.plist`：全部 `OK`。
- 工程设置检查：iOS deployment target `17.0`，iOS 与 Simulator 平台均配置，竖屏方向已声明，`UIRequiresFullScreen=true` 已进入当前构建产物。
- 依赖/禁区静态扫描：未发现 SwiftPM、CocoaPods、Carthage 或 Workspace 依赖，也未发现网络、分析、HealthKit、StoreKit、WatchConnectivity、ActivityKit 或跟踪 API 实现命中；唯一相关文本命中是 PrivacyView 的说明文案。

### 构建与自动化

- iOS Debug 测试：初版复验 **46/46 PASS**；最终主题修复后 **47/47 PASS**，结果包：`/tmp/Pip-final-dark-tests/Logs/Test/Test-Pip-2026.08.22_14-49-04-+0800.xcresult`。
- iOS Release generic build：**PASS**；产物存在于 `/tmp/Pip-qa-ui-integrity-release/Build/Products/Release-iphoneos/Pip.app`。
- Widget Release generic iOS build：**PASS**；产物存在于 `/tmp/Pip-qa-ui-integrity-widget/Build/Products/Release-iphoneos/PipWidgetExtension.appex`。
- iPhone 17 当前 Debug 包重新安装后全屏首页截图：**PASS**。
- iPhone 17 Pro 当前 Debug 包启动后的全屏首页截图：**PASS**。
- 当前最终 `header + 主内容居中` 布局在 iPhone 17、`content_size=large` 下全屏且无重叠：**PASS**；截图：`/tmp/Pip-iPhone17-final-ui-large.png`。

## 未验证项

- Start 点击、首次说明 sheet 确认、48 秒倒计时、Pause/Resume、Cancel 和完成态无法用当前环境的 GUI 注入权限独立执行。
- 仅复验了标准 `large` 字号；更大的 Accessibility Dynamic Type 档位仍未完成视觉验收。
- 真实设备的通知授权、Focus、触觉反馈、VoiceOver、最大 Dynamic Type、Reduce Motion、Widget 运行时和实体设备 Dark Mode 未完成；模拟器 light/dark 视觉验证已通过。
- Watch generic build：**BLOCKED**，命令返回 `watchOS 26.5 is not installed`，因此未进行 Watch UI 验证。
- App Store 发布配置、隐私政策公开 HTTPS 地址和支持联系方式未验证。

## 明确建议

1. 当前最终构建已包含启动屏、响应式首页和暗色高对比 header；后续不需要继续为本次旧安装窗口状态修改 `HomeView` 或窗口配置。
2. 将“安装当前构建 -> terminate -> launch -> 等待启动完成 -> screenshot”作为模拟器 UI 验收前置步骤，避免复用旧安装包或旧窗口状态。
3. 若干净重装后仍出现黑边，记录设备 UDID、iOS runtime、Xcode 版本、安装包路径和截图，再用同一构建在另一台 iPhone Simulator 与实体 iPhone 对照；届时再评估是否为 CoreSimulator/Xcode 运行时回归。
4. 后续交互验收应使用可操作的 GUI 路径或人工操作模拟器，不要以当前静态截图替代交互通过。

## 最终状态更新

当前代码已增加 `PipTheme.ink(for:)`，HomeView header 使用 colorScheme-aware ink。light/dark clean install 模拟器截图分别为 `/tmp/Pip-iPhone17-light-theme-fixed.png` 和 `/tmp/Pip-iPhone17-dark-theme-fixed.png`，均为 `1206 x 2622`；两种主题下 header 均可读且无重叠，Dark Mode 本轮模拟器视觉验证：**PASS**。全量 iOS 测试 **47/47 PASS**，iOS Release 与 Widget Release build **PASS**。

实体设备、最大 Dynamic Type、Start/首次说明/倒计时/完成态 GUI 交互、真实通知/Focus/触觉/VoiceOver，以及 Watch SDK/设备仍未验证；这些不因本轮模拟器 Dark Mode 通过而改变。
