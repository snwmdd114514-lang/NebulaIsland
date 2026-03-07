# NebulaIsland UI API

本文档整理了 **NebulaIsland** 提供的主要 API 方法，示例均为 Roblox Lua，便于在仓库 README 或手机浏览器查看。

---

## 1️⃣ Window 相关

<details>
<summary>CreateWindow(options)</summary>

创建一个新的窗口。

**参数表：**

| 字段 | 类型 | 描述 |
|------|------|------|
| Name | string | 窗口名称 |
| Subtitle | string | 窗口副标题 |
| Icon | number | Roblox 资源 ID，用作图标 |
| LoadingSettings | table | 加载界面设置 `{Title, Subtitle}` |
| FileSettings | table | 文件配置 `{ConfigFolder}` |

**示例：**

```lua
local window = NebulaIsland:CreateWindow({
    Name = "NebulaIsland UI",
    Subtitle = "v1.0",
    Icon = 1234567890,
    LoadingSettings = {
        Title = "欢迎",
        Subtitle = "NebulaIsland UI"
    },
    FileSettings = {
        ConfigFolder = "MyConfigs"
    }
})
## 2️⃣ Tab & TabSection

### CreateTabSection(name)

创建一个标签页区域（可分组 Tab）。

```lua
local section = window:CreateTabSection("主功能")
```

### CreateTab(options, key)

创建单个 Tab。

| 字段      | 类型     | 描述                      |
| ------- | ------ | ----------------------- |
| Name    | string | Tab 名称                  |
| Icon    | string | 图标名称，可用 NebulaIcons API |
| Columns | number | 列数，布局使用                 |

**示例：**

```lua
local tab = section:CreateTab({
    Name = "战斗",
    Icon = NebulaIcons:GetIcon('sword', 'Material'),
    Columns = 2
}, "INDEX")
```

---

## 3️⃣ Groupbox

### CreateGroupbox(options, key)

在 Tab 内创建分组容器。

| 字段     | 类型     | 描述   |
| ------ | ------ | ---- |
| Name   | string | 分组名称 |
| Column | number | 所在列  |

**示例：**

```lua
local group = tab:CreateGroupbox({
    Name = "主要设置",
    Column = 1
}, "INDEX")
```

---

## 4️⃣ 控件 API

### Button

```lua
group:CreateButton({
    Name = "点击执行",
    CenterContent = true,
    Style = 1,
    Icon = NebulaIcons:GetIcon('check', 'Material'),
    Callback = function()
        print("按钮被点击！")
    end
}, "INDEX")
```

### Paragraph

```lua
group:CreateParagraph({
    Name = "信息说明",
    Content = "这里可以放置文本描述。"
}, "INDEX")
```

### PromptDialog

```lua
local dialog = window:PromptDialog({
    Name = "公告",
    Content = "这是一个提示框",
    Type = 1,
    Actions = {
        Primary = {
            Name = "确认",
            Icon = NebulaIcons:GetIcon("check", "Material"),
            Callback = function()
                print("点击确认")
            end
        },
        {
            Name = "取消",
            Callback = function()
                print("点击取消")
            end
        }
    }
})
```

---

## 5️⃣ NebulaIcons

### 获取图标

```lua
local icon = NebulaIcons:GetIcon('directions_run', 'Material')
```

---

## 6️⃣ 高级 API

### Loader(assetId, duration)

加载指定资源，用于启动动画或特效。

```lua
local loader = Compkiller:Loader("rbxassetid://97914301936069", 2.5)
loader:yield()
```

