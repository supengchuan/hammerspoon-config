# 蓝牙睡眠供电策略设计

## 目标

仅在 Mac 使用电池或处于离线供电状态时，于系统睡眠前关闭蓝牙；接通电源时保持蓝牙状态不变。

## 行为

`modules/system_events.lua` 在收到 `systemWillSleep` 时读取 `hs.battery.powerSourceType()`：

- `Battery Power`：调用 `bluetooth.setEnabled(false)`。
- `Off Line`：调用 `bluetooth.setEnabled(false)`。
- `AC Power`：不调用蓝牙开关。

在 `systemDidWake` 时继续无条件调用 `bluetooth.setEnabled(true)`，不改变现有快捷键或媒体暂停行为。

## 验证

扩展系统事件测试，分别模拟三种供电状态，验证只有电池和离线状态触发关闭；再运行现有蓝牙测试及 Lua 语法检查。
