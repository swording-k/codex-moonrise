# 配置「重启 Codex，并播放开屏动画」

这套配置就是演示视频中使用的启动入口。只需要 macOS 自带的「快捷指令」和已经安装的 Codex Moonrise。

[返回项目首页](../README.md) · [下载 Moonrise](https://github.com/swording-k/codex-moonrise/releases/latest) · [视频拍摄脚本](../docs/video-guide.md)

## 已经配置，但动画后只剩桌面？

先更新到 [v2.0.1 或更新版](https://github.com/swording-k/codex-moonrise/releases/latest)，用新应用替换「应用程序」里的旧版，快捷指令仍然保持原来的三个操作。旧版只尝试激活进程，没有确保重新打开窗口，新版已修正该交接逻辑。

如果新版仍提示交接失败，可查看 `~/Library/Logs/CodexMoonrise/launcher.log` 中的失败原因，不要额外添加“打开 ChatGPT”来掩盖问题。

## 先选你要的行为

| 想要的效果 | 应该点击哪个入口 |
| --- | --- |
| 没打开就启动，已经打开就回到原窗口；播放动画 | Codex Moonrise.app |
| 没打开就启动，已经打开就退出重开；播放动画 | 按本教程配置的快捷指令 |
| 按客户端原来的方式直接打开 | 原来的 Codex / ChatGPT.app |

**快捷指令是日常入口，Moonrise 是动画启动器，Codex / ChatGPT 是真正的客户端。**可以给快捷指令起一个熟悉的名字、选一个喜欢的图标；名字和图标不会改变背后的工作流。

## 第一步：安装动画启动器

1. 从 [Releases](https://github.com/swording-k/codex-moonrise/releases/latest) 下载 `Codex-Moonrise-macOS-universal.zip`。
2. 解压，把 **Codex Moonrise.app** 拖进 **应用程序**。
3. 先单独打开一次 Moonrise，确认这台 Mac 上可以播放并交接到真实客户端。

需要已经安装 bundle ID 为 `com.openai.codex` 的客户端。某些发行版的应用名显示为 **ChatGPT**；选择的是你实际使用的那一个。其他 bundle ID 的独立 ChatGPT 应用不在此版本的识别范围内。

## 第二步：新建三个操作

打开系统「快捷指令」，新建一个快捷指令，命名为 **重启 Codex · 动画启动**（名称可自定）。依次添加以下操作：

| 顺序 | 操作 | 要设置的内容 |
| --- | --- | --- |
| 1 | **退出 App** | 选择真正的 **Codex / ChatGPT** 客户端 |
| 2 | **等待** | 设置为 **3 秒** |
| 3 | **打开 App** | 选择 **Codex Moonrise** |

```text
退出 App：真正的 Codex / ChatGPT
        ↓
等待：3 秒
        ↓
打开 App：Codex Moonrise
        ↓
14 秒开屏动画
        ↓
真实 Codex / ChatGPT 客户端
```

最后一步必须选择 **Codex Moonrise**，不是再选择真正的 ChatGPT；否则就会绕过动画。不要在最后额外添加「打开 ChatGPT」操作，客户端交接由 Moonrise 完成。

不需要 AppleScript、Shell 脚本、强制结束进程，也不需要修改官方应用。如果「退出 App」显示有“强制退出”之类的可选设置，保留正常退出方式；如果客户端显示保存或退出确认，先处理该确认再继续。

Codex 尚未运行时，退出步骤没有运行中的客户端需要关闭；后续等待和启动步骤照常执行。

### 已经有重启快捷指令？只改最后一步

如果现有流程是「退出 ChatGPT → 等待 3 秒 → 打开 ChatGPT」，保留前两步，**把最后一步的应用改成 Codex Moonrise**即可。原快捷指令的名字、图标、键盘快捷键和桌面组件关联都可以保留。

## 第三步：放到常用入口

在快捷指令资料库选中这个快捷指令，使用菜单 **文件 → 添加到程序坞**。以后点击 Dock 中的这个图标即可。

如果桌面上已经有指向这个快捷指令的组件或入口，保持使用原入口。不要通过访达移动真正的客户端来“替换”它。

快捷指令的图标与名称可以自定义；直接点击官方应用原图标的行为保持原样。

## 配好之后核对

1. 重新打开快捷指令编辑器，确认顺序仍然是「退出客户端 → 等待 3 秒 → 打开 Codex Moonrise」。
2. 在你准备好重启时运行它：如果 Codex 已打开，应先退出，再出现动画，最后客户端重新打开。
3. 客户端未打开时再运行一次，应出现动画并打开客户端。
4. 动画期间按 **Esc** 可跳过动画；右下角的配色切换与 **1 / 2 / 3** 快捷键仍然有效。

**重启入口会实际退出当前客户端。**录制演示时先结束正在进行的任务；只想看动画并回到现有窗口时，直接打开 Moonrise。

## 常见问题

### 为什么还是没动画？

检查第三个操作是不是选成了真正的 ChatGPT。应当选择 **Codex Moonrise**；并确认启动器位于「应用程序」中。

### 应用列表里找不到 Moonrise？

先安装到「应用程序」并打开一次，再重新进入「打开 App」操作的应用选择器搜索 `Moonrise`。

### 为什么退出后还等 3 秒？

给客户端留出退出时间，沿用原有重启工作流。它是固定等待，不是“客户端完全退出”的检测器。如果你的客户端退出较慢，可把等待调长；如果出现退出确认，需要先完成确认。此流程不使用强制结束进程。

### 这样会修改官方客户端吗？

不会。快捷指令负责正常退出和选择启动入口，Moonrise 负责动画和应用交接。它不会让原客户端图标自动拦截到动画，也不是把动画注入官方应用内部。

### 能直接导入 .shortcut 吗？

目前以本页的三个系统操作作为可复现配置。此版本**没有附带已验证可导入的 `.shortcut` 文件**，请按步骤创建，或改你已有的快捷指令。

macOS 给他人导出快捷指令时需要 Apple / iCloud 验证。在公开导出尚未完成验证前，仓库不会把未验证文件标成“一键导入”。

## 验证范围

作者本机已在系统快捷指令编辑器中，将原有重启快捷指令的最后一步改为 **打开 Codex Moonrise**并保存，前两步为退出 ChatGPT、等待 3 秒。Moonrise 的播放与运行中客户端交接已实测。

快捷指令整体的退出重开流程尚未在当前活跃聊天中触发端到端验收。上面的核对步骤提供给安装者在自己的设备上完成；不要把编辑器配置完成等同于每个系统版本都经过完整重启验收。

## English quick setup

Install **Codex Moonrise.app** in Applications. Create a shortcut containing exactly these three actions:

1. **Quit App** → the actual Codex / ChatGPT client (`com.openai.codex`).
2. **Wait** → 3 seconds.
3. **Open App** → **Codex Moonrise**.

Choose **File → Add to Dock** for a single-click entry. An existing restart shortcut only needs its final Open App target changed to Moonrise. The official application is unchanged. Use ordinary Moonrise launch if you want to reuse the current client rather than restart it.
