# Hammerspoon Config

一套用于 macOS 的个人 [Hammerspoon](https://www.hammerspoon.org/) 自动化配置。

它提供常用窗口操作、鼠标定位提示、WezTerm 快捷启动，并在锁屏或睡眠时暂停 QQ 音乐。Lua 配置变更后会自动重新加载。

## 前置条件

- macOS
- 已安装 [Hammerspoon](https://www.hammerspoon.org/)
- 已在“系统设置 → 隐私与安全性 → 辅助功能”中允许 Hammerspoon 控制电脑

## 使用

将配置克隆到 Hammerspoon 默认目录并启动（或重新加载）Hammerspoon：

```sh
git clone https://github.com/supengchuan/hammerspoon-config.git ~/.hammerspoon
```

若 `~/.hammerspoon` 已存在，请先备份原有配置，或将本仓库内容合并进去。首次启动 Hammerspoon 后，菜单栏会显示提示 “Hammerspoon config loaded”。之后修改任意 `.lua` 文件会自动生效。

## 快捷键

| 快捷键 | 功能 |
| --- | --- |
| `Ctrl + Cmd + M` | 在鼠标当前位置显示红色动画圆环 |
| `Ctrl + Cmd + N` | 将当前窗口移至下一块屏幕 |
| `Ctrl + Return` | 最大化当前窗口（保留菜单栏与 Dock 区域） |
| `Ctrl + Cmd + Return` | 切换当前窗口的全屏状态 |
| `Ctrl + Cmd + T` | 启动或切换到 WezTerm；已聚焦 WezTerm 时新建窗口 |

## 自动行为

- 锁屏、会话失活或系统睡眠时，自动暂停正在运行的 QQ 音乐。
- 同一次锁屏产生的重复系统事件会被去重，避免重复执行暂停操作。
