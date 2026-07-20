# 蓝牙控制设计

## 目标

在系统睡眠时关闭蓝牙、系统唤醒时打开蓝牙，并用 `Ctrl + Cmd + B` 手动切换蓝牙状态。

## 方案

新增 `modules/bluetooth.lua`，唯一负责调用已安装的 `/opt/homebrew/bin/blueutil`：

- `isOn()` 读取蓝牙总开关状态。
- `setEnabled(enabled)` 开启或关闭蓝牙，并在命令失败时记录错误。
- `toggle()` 读取当前状态后反转，并显示结果提示。

`modules/system_events.lua` 在 `systemWillSleep` 调用 `setEnabled(false)`，在
`systemDidWake` 调用 `setEnabled(true)`。该行为按需求无条件开启：即使用户在睡前手动关闭蓝牙，唤醒后仍会打开。

`modules/hotkeys.lua` 绑定 `Ctrl + Cmd + B` 到 `toggle()`。

## 失败处理与验证

如果 `blueutil` 不存在、无法执行或返回异常状态，模块记录 Hammerspoon 日志，快捷键不显示成功提示。
通过对命令执行器的替身测试覆盖状态解析、开关命令和切换逻辑；再用 Lua 语法检查验证配置可加载。
