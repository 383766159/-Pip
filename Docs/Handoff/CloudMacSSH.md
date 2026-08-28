# 本机 SSH → 云 Mac 拉 GitHub、编译、开模拟器

可以。Windows 本机不编译；云 Mac 当构建机。GitHub 是唯一同步点。

```text
本机 Windows                 GitHub                    云 Mac
  改代码 / git push   →   383766159/-Pip   →   ssh 进去 git pull
                                                 xcodebuild
                                                 Simulator 运行 Pip
```

SSH 只能发命令。模拟器窗口在 Mac 桌面上，本机要看画面请用屏幕共享，或把截图 `scp` 回来。

## 1. 云 Mac 一次性准备

用有桌面登录的账号（不要用纯无界面用户）：

1. 安装 Xcode，打开一次，同意许可。
2. Xcode → Settings → Platforms，装好 iOS Simulator runtime。
3. 终端执行：

```bash
sudo xcode-select -s /Applications/Xcode.app/Contents/Developer
sudo xcodebuild -license accept
xcodebuild -runFirstLaunch
```

4. 打开「系统设置 → 通用 → 共享」：
   - 远程登录（SSH）打开
   - 屏幕共享打开（用来看 Simulator）
5. 给这台 Mac 配 GitHub 权限（仓库是 private）：
   - 推荐：在 Mac 上 `ssh-keygen`，把公钥加到 GitHub Deploy keys 或你的 SSH keys
6. 克隆一次：

```bash
cd ~
git clone git@github.com:383766159/-Pip.git Pip
cd Pip
```

路径可改；本机脚本默认 `~/Pip`。

7. 保持这个 macOS 用户已登录图形界面。SSH 启动 Simulator 依赖桌面会话。

## 2. 本机日常用法

在 PowerShell 里（把主机名和用户换成你的云 Mac）：

```powershell
# 拉最新代码、编译、装到模拟器并启动
.\AppPiPi\scripts\ssh-sim.ps1 -MacHost 云Mac的IP或域名 -MacUser 你的Mac用户名

# 跑 XCTest
.\AppPiPi\scripts\ssh-sim.ps1 -MacHost 云Mac -MacUser 你 -Action test

# 截一张模拟器图（文件在 Mac 的 /tmp/pip-sim.png）
.\AppPiPi\scripts\ssh-sim.ps1 -MacHost 云Mac -MacUser 你 -Action shot
scp 你@云Mac:/tmp/pip-sim.png .
```

或直接 SSH：

```bash
ssh 你@云Mac 'cd ~/Pip && bash scripts/sim-run.sh'
ssh 你@云Mac 'cd ~/Pip && bash scripts/sim-test.sh'
ssh 你@云Mac 'cd ~/Pip && bash scripts/sim-shot.sh'
```

已经 pull 过、只想重编：

```bash
ssh 你@云Mac 'cd ~/Pip && PIP_SKIP_PULL=1 bash scripts/sim-run.sh'
```

指定机型（默认自动挑可用的新 iPhone）：

```bash
ssh 你@云Mac 'cd ~/Pip && PIP_SIM_DEVICE="iPhone 16" bash scripts/sim-run.sh'
```

## 3. 怎么看模拟器

| 方式 | 适合 |
| --- | --- |
| 屏幕共享 / VNC / Jump Desktop / RustDesk | 要看动画、点按钮 |
| `sim-shot.sh` + `scp` | 只要一张静图 |
| 只看 SSH 日志 | 只确认编译、启动成功 |

Windows 连屏幕共享：

```text
mstsc 不能直接连 macOS。
用：Win + R → 打开 `vnc://云MacIP`
或任意 VNC 客户端，连 Mac 的屏幕共享端口（5900）。
更稳：先 SSH 隧道再连本地 5900：
  ssh -L 5900:127.0.0.1:5900 你@云Mac
  然后 VNC 连 127.0.0.1:5900
```

## 4. 脚本做什么

| 文件 | 作用 |
| --- | --- |
| `scripts/sim-run.sh` | `git pull --ff-only` → 启动 Simulator → Debug 编译 → 安装 `com.rainanlin.pip` → launch |
| `scripts/sim-test.sh` | pull 后跑 `Pip` scheme 的 XCTest |
| `scripts/sim-shot.sh` | 截当前 Simulator |
| `scripts/ssh-sim.ps1` | 本机一条命令 SSH 过去执行上面三个动作 |

产物写在仓库的 `build/DerivedData/`，已被 `.gitignore` 忽略。

## 5. 常见卡住

| 现象 | 处理 |
| --- | --- |
| `xcode-select` / no Xcode | 按 §1 装 Xcode 并 `xcode-select -s` |
| No available iPhone simulator | Xcode → Platforms 安装 iOS runtime |
| `Unable to boot` / Simulator 闪退 | Mac 上要有图形登录；用同一用户 SSH |
| `Permission denied (publickey)` 拉 GitHub | Mac 的 SSH key 加入 GitHub |
| `working tree is dirty` | 不要在云 Mac 上改代码；`git status` 后 reset/stash |
| `non-fast-forward` | 云 Mac 不要独立提交；只 pull |
| 编译过、画面还是旧的 | 脚本会 `simctl install` 当前产物；仍旧则 `xcrun simctl uninstall booted com.rainanlin.pip` 再跑 |
| Watch 构建失败 | 与这套 iPhone 模拟器流程无关；Watch 需要对应 SDK |

## 6. 建议的分工

- **本机**：改 Swift / 资源，`git push origin master`
- **云 Mac**：只跑脚本，不手改代码
- **看 UI**：屏幕共享盯 Simulator；看布局可用截图

第一次建议：本机 push 后，SSH 跑 `sim-run.sh`，同时打开屏幕共享确认 Pip 出现在模拟器上。
