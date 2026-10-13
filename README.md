# Hammerspoon Config

一套用于 macOS 的个人 [Hammerspoon](https://www.hammerspoon.org/) 自动化配置。

它提供常用窗口操作、鼠标定位提示、WezTerm 快捷启动和蓝牙手动控制，并在锁屏或睡眠时暂停 QQ
音乐。接通电源时，它还会阻止显示器因用户空闲而进入睡眠；切换到电池供电后立即恢复系统默认行
为。

## 前置条件

- macOS
- 已安装 [Hammerspoon](https://www.hammerspoon.org/)
- 已在“系统设置 → 隐私与安全性 → 辅助功能”中允许 Hammerspoon 控制电脑
- 已安装 `blueutil`；本配置固定从 `/opt/homebrew/bin/blueutil` 调用它（Apple Silicon Homebrew
  路径）

安装并验证 `blueutil`：

```sh
brew install blueutil
test -x /opt/homebrew/bin/blueutil
/opt/homebrew/bin/blueutil --power
```

最后一条命令应输出 `0` 或 `1`，分别表示蓝牙关闭或开启。若 Homebrew 或 `blueutil` 位于其他路径，
请将 `modules/bluetooth.lua` 中的可执行文件路径改为实际绝对路径。

## 使用

将配置克隆到 Hammerspoon 默认目录并启动（或重新加载）Hammerspoon：

```sh
git clone https://github.com/supengchuan/hammerspoon-config.git ~/.hammerspoon
```

若 `~/.hammerspoon` 已存在，请先备份原有配置，或将本仓库内容合并进去。首次启动 Hammerspoon
后，菜单栏会显示提示 “Hammerspoon config loaded”。修改 `.lua` 文件后，请使用 Hammerspoon 的
“Reload Config” 重新加载配置。

## 功能开关

菜单栏中的 `HS` 菜单可以即时启用或停用以下功能，无需修改 `init.lua` 或重新加载配置：

- 快捷键
- 锁屏或睡眠时暂停音乐
- 显示器常亮

勾选状态会保存在 Hammerspoon 设置中，并在重新加载或重启后恢复。首次运行时，快捷键和暂停音乐
默认开启，显示器常亮默认关闭。

## 快捷键

以下快捷键在 `HS → 快捷键` 开启时生效：

| 快捷键                | 功能                                            |
| --------------------- | ----------------------------------------------- |
| `Ctrl + Cmd + M`      | 在鼠标当前位置显示红色动画圆环                  |
| `Ctrl + Cmd + B`      | 切换蓝牙开关                                    |
| `Ctrl + Cmd + N`      | 将当前窗口移至下一块屏幕                        |
| `Ctrl + Return`       | 最大化当前窗口（保留菜单栏与 Dock 区域）        |
| `Ctrl + Cmd + Return` | 切换当前窗口的全屏状态                          |
| `Ctrl + Cmd + T`      | 启动或切换到 WezTerm；已聚焦 WezTerm 时新建窗口 |

## 自动行为

- 开启“显示器常亮”后，接通电源时阻止显示器因用户空闲而进入睡眠；使用电池或离线供电时不干预
  系统休眠策略。
- 开启“显示器常亮”后，锁屏 10 秒会撤销常亮并请求熄屏；若提前解锁则取消熄屏，解锁后仅在接通
  电源时恢复常亮。
- 开启“锁屏或睡眠时暂停音乐”后，锁屏、会话失活或系统睡眠时自动暂停正在运行的 QQ 音乐。
- 同一次锁屏产生的重复系统事件会被去重，避免重复执行暂停操作。
- 睡眠时的蓝牙开关策略由 SleepWatcher 管理，不属于本 Hammerspoon 配置的职责。
