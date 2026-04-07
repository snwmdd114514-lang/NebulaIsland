--[[
    Apple Dynamic Island & Control Center UI Library
    修复了第1行可能的格式错误，封装为指定函数调用格式
]]

local AppleLib = {
    Enabled = true, -- 控制灵动岛是否能被点击打开
    _ControlCenterVisible = false,
    Config = {
        a = 35,  -- BaseHeight (高度)
        b = 120, -- BaseWidth (宽度)
        c = 0,   -- Transparency (透明度)
        CornerRadius = 1
    }
}

-- 系统服务
local Players = game:GetService("Players")
local TweenService = game:GetService("TweenService")
local UserInputService = game:GetService("UserInputService")
local CoreGui = game:GetService("CoreGui")
local Lighting = game:GetService("Lighting")

local LocalPlayer = Players.LocalPlayer
local guiParent = (gethui and gethui()) or CoreGui

-- 内部配置
local TweenInfoBase = TweenInfo.new(0.35, Enum.EasingStyle.Exponential, Enum.EasingDirection.Out)
local TweenInfoBounce = TweenInfo.new(0.5, Enum.EasingStyle.Back, Enum.EasingDirection.Out)
local TweenInfoFast = TweenInfo.new(0.2, Enum.EasingStyle.Sine)
local ActiveAlertStack = {}
local CurrentState = "Idle"

-- 工具函数
local function create(className, properties)
    local inst = Instance.new(className)
    for k, v in pairs(properties or {}) do inst[k] = v end
    return inst
end

local function addCorner(parent, radius)
    return create("UICorner", {CornerRadius = UDim.new(radius or 1, 0), Parent = parent})
end

-- ========================================================================
-- [UI 构建]
-- ========================================================================
local MainGui = create("ScreenGui", { Name = "AppleDynamicIsland_Lib", Parent = guiParent, ResetOnSpawn = false, IgnoreGuiInset = true })
local BackgroundBlur = create("BlurEffect", { Name = "ADI_Blur", Parent = Lighting, Size = 0 })
local DarkOverlay = create("TextButton", { Parent = MainGui, Size = UDim2.new(1, 0, 1, 0), BackgroundColor3 = Color3.new(0,0,0), BackgroundTransparency = 1, Text = "", AutoButtonColor = false, Visible = false })

-- 灵动岛
local IslandContainer = create("Frame", { Name = "Island", Parent = MainGui, AnchorPoint = Vector2.new(0.5, 0), Position = UDim2.new(0.5, 0, 0, 10), Size = UDim2.new(0, 120, 0, 35), BackgroundColor3 = Color3.new(0,0,0), ClipsDescendants = true, ZIndex = 100 })
local IslandCorner = addCorner(IslandContainer, 1)
local IslandScale = create("UIScale", {Parent = IslandContainer, Scale = 1})
local CameraHole = create("Frame", { Parent = IslandContainer, AnchorPoint = Vector2.new(1, 0.5), Position = UDim2.new(1, -15, 0.5, 0), Size = UDim2.new(0, 12, 0, 12), BackgroundColor3 = Color3.fromRGB(15,15,15), ZIndex = 102 })
addCorner(CameraHole, 1)

local ContentFrame = create("Frame", { Parent = IslandContainer, Size = UDim2.new(1, 0, 1, 0), BackgroundTransparency = 1, ZIndex = 103 })
local AlertStackContainer = create("ScrollingFrame", { Parent = ContentFrame, Size = UDim2.new(1, 0, 1, 0), BackgroundTransparency = 1, CanvasSize = UDim2.new(0,0,0,0), ScrollBarThickness = 0, ClipsDescendants = false })
create("UIListLayout", { Parent = AlertStackContainer, HorizontalAlignment = "Center", Padding = UDim.new(0, 5) })
create("UIPadding", { Parent = AlertStackContainer, PaddingTop = UDim.new(0, 8) })

-- 控制中心
local CC_Container = create("Frame", { Name = "ControlCenter", Parent = MainGui, AnchorPoint = Vector2.new(0.5, 0.5), Position = UDim2.new(0.5, 0, 1.5, 0), Size = UDim2.new(0, 340, 0, 560), BackgroundTransparency = 1, ZIndex = 10 })

-- ========================================================================
-- [核心逻辑封装]
-- ========================================================================

-- 更新灵动岛基础外观
local function UpdateIslandBase()
    if CurrentState == "Idle" then
        TweenService:Create(IslandContainer, TweenInfoBase, { 
            Size = UDim2.new(0, AppleLib.Config.b, 0, AppleLib.Config.a),
            BackgroundTransparency = AppleLib.Config.c
        }):Play()
    else
        TweenService:Create(IslandContainer, TweenInfoBase, { BackgroundTransparency = AppleLib.Config.c }):Play()
    end
    IslandCorner.CornerRadius = UDim.new(AppleLib.Config.CornerRadius, 0)
end

-- 重新计算堆栈高度
local function RecalculateIslandSize()
    if #ActiveAlertStack == 0 then return end
    local totalHeight = 16
    local maxWidth = AppleLib.Config.b
    for _, alert in ipairs(ActiveAlertStack) do
        totalHeight = totalHeight + alert.Height + 5
        if alert.Width > maxWidth then maxWidth = alert.Width end
    end
    TweenService:Create(IslandContainer, TweenInfoBounce, { Size = UDim2.new(0, maxWidth, 0, totalHeight) }):Play()
    TweenService:Create(CameraHole, TweenInfoBounce, { Position = UDim2.new(1, -15, 0, AppleLib.Config.a / 2) }):Play()
end

-- [API] 发送消息提示: ShowAlert({"标题", "状态", "图标ID"})
function AppleLib.ShowAlert(data)
    local titleText = data[1] or "Notice"
    local stateText = data[2] or ""
    local iconId = data[3] or "rbxassetid://10664292213"
    
    CurrentState = "Alerting"
    local alertFrame = create("Frame", { Parent = AlertStackContainer, Size = UDim2.new(1, 0, 0, 45), BackgroundTransparency = 1, ClipsDescendants = true })
    local icon = create("ImageLabel", { Parent = alertFrame, Position = UDim2.new(0, 15, 0.5, -15), Size = UDim2.new(0, 30, 0, 30), BackgroundTransparency = 1, Image = iconId, ImageTransparency = 1 })
    addCorner(icon, 0.2)
    local t = create("TextLabel", { Parent = alertFrame, Position = UDim2.new(0, 55, 0.5, -18), Size = UDim2.new(1, -70, 0, 20), BackgroundTransparency = 1, Text = titleText, TextColor3 = Color3.new(1,1,1), Font = "GothamBold", TextSize = 14, TextXAlignment = "Left", TextTransparency = 1 })
    local d = create("TextLabel", { Parent = alertFrame, Position = UDim2.new(0, 55, 0.5, 2), Size = UDim2.new(1, -70, 0, 15), BackgroundTransparency = 1, Text = stateText, TextColor3 = Color3.fromRGB(180,180,180), Font = "Gotham", TextSize = 12, TextXAlignment = "Left", TextTransparency = 1 })

    table.insert(ActiveAlertStack, { Frame = alertFrame, Width = 260, Height = 45 })
    RecalculateIslandSize()

    TweenService:Create(icon, TweenInfoBase, { ImageTransparency = 0 }):Play()
    TweenService:Create(t, TweenInfoBase, { TextTransparency = 0 }):Play()
    TweenService:Create(d, TweenInfoBase, { TextTransparency = 0 }):Play()

    task.delay(3, function()
        if not alertFrame.Parent then return end
        TweenService:Create(alertFrame, TweenInfoFast, { Size = UDim2.new(1, 0, 0, 0) }):Play()
        for i, v in ipairs(ActiveAlertStack) do if v.Frame == alertFrame then table.remove(ActiveAlertStack, i) break end end
        task.wait(0.2)
        alertFrame:Destroy()
        if #ActiveAlertStack == 0 then CurrentState = "Idle" UpdateIslandBase() else RecalculateIslandSize() end
    end)
end

-- 控制中心开关逻辑
local function ToggleControlCenter(state)
    AppleLib._ControlCenterVisible = state
    if state then
        DarkOverlay.Visible = true
        TweenService:Create(BackgroundBlur, TweenInfo.new(0.4), {Size = 10}):Play()
        TweenService:Create(DarkOverlay, TweenInfo.new(0.4), {BackgroundTransparency = 0.35}):Play()
        TweenService:Create(CC_Container, TweenInfo.new(0.5, Enum.EasingStyle.Exponential, Enum.EasingDirection.Out), { Position = UDim2.new(0.5, 0, 0.5, 0) }):Play()
    else
        TweenService:Create(BackgroundBlur, TweenInfo.new(0.3), {Size = 0}):Play()
        TweenService:Create(DarkOverlay, TweenInfo.new(0.3), {BackgroundTransparency = 1}):Play()
        TweenService:Create(CC_Container, TweenInfo.new(0.4, Enum.EasingStyle.Back, Enum.EasingDirection.In), { Position = UDim2.new(0.5, 0, 1.5, 0) }):Play()
        task.delay(0.4, function() if not AppleLib._ControlCenterVisible then DarkOverlay.Visible = false end end)
    end
end

-- 元表劫持，实现 xxx.ControlCenterVisible = bool 和 xxx.Config 的属性监听
setmetatable(AppleLib, {
    __newindex = function(t, k, v)
        if k == "ControlCenterVisible" then ToggleControlCenter(v) end
        rawset(t, k, v)
    end,
    __index = function(t, k)
        if k == "ControlCenterVisible" then return t._ControlCenterVisible end
        return rawget(t, k)
    end
})

setmetatable(AppleLib.Config, {
    __newindex = function(t, k, v)
        rawset(t, k, v)
        UpdateIslandBase()
    end
})

-- ========================================================================
-- [组件工厂]
-- ========================================================================
local function createModule(size, pos)
    local f = create("Frame", { Parent = CC_Container, Size = size, Position = pos, BackgroundColor3 = Color3.fromRGB(30, 30, 35), BackgroundTransparency = 0.25 })
    addCorner(f, 0.15)
    return f
end

-- 开关组件
local ToggleBox = createModule(UDim2.new(1, -24, 0, 150), UDim2.new(0, 12, 0, 395))
create("UIListLayout", { Parent = ToggleBox, SortOrder = "LayoutOrder" })

function AppleLib:AddToggle(text, default, callback)
    local frame = create("Frame", { Parent = ToggleBox, Size = UDim2.new(1, 0, 0, 50), BackgroundTransparency = 1 })
    create("TextLabel", { Parent = frame, Position = UDim2.new(0, 15, 0, 0), Size = UDim2.new(0.6, 0, 1, 0), BackgroundTransparency = 1, Text = text, TextColor3 = Color3.new(0.9,0.9,0.9), Font = "GothamSemibold", TextSize = 14, TextXAlignment = "Left" })
    local toggleBg = create("TextButton", { Parent = frame, AnchorPoint = Vector2.new(1, 0.5), Position = UDim2.new(1, -15, 0.5, 0), Size = UDim2.new(0, 50, 0, 30), BackgroundColor3 = default and Color3.fromRGB(52, 199, 89) or Color3.fromRGB(80, 80, 85), Text = "", AutoButtonColor = false })
    addCorner(toggleBg, 1)
    local knob = create("Frame", { Parent = toggleBg, Position = UDim2.new(0, default and 22 or 2, 0.5, -13), Size = UDim2.new(0, 26, 0, 26), BackgroundColor3 = Color3.new(1,1,1) })
    addCorner(knob, 1)
    
    local state = default
    toggleBg.MouseButton1Click:Connect(function()
        state = not state
        TweenService:Create(toggleBg, TweenInfo.new(0.25), {BackgroundColor3 = state and Color3.fromRGB(52, 199, 89) or Color3.fromRGB(80, 80, 85)}):Play()
        TweenService:Create(knob, TweenInfo.new(0.3, Enum.EasingStyle.Back), {Position = UDim2.new(0, state and 22 or 2, 0.5, -13)}):Play()
        AppleLib.ShowAlert({text, state and "已开启" or "已关闭", "rbxassetid://10664292213"})
        callback(state)
    end)
    create("Frame", {Parent = ToggleBox, Size = UDim2.new(1, 0, 0, 1), BackgroundColor3 = Color3.fromRGB(60,60,65), BorderSizePixel = 0})
end

-- ========================================================================
-- [基础交互]
-- ========================================================================
local InteractionButton = create("TextButton", { Parent = IslandContainer, Size = UDim2.new(1, 0, 1, 0), BackgroundTransparency = 1, Text = "", ZIndex = 1000 })
InteractionButton.MouseButton1Click:Connect(function()
    if AppleLib.Enabled then
        AppleLib.ControlCenterVisible = not AppleLib.ControlCenterVisible
    end
end)
DarkOverlay.MouseButton1Click:Connect(function() AppleLib.ControlCenterVisible = false end)

-- 初始化外观
UpdateIslandBase()

-- ========================================================================
-- [使用示例] (你可以直接删除这部分或参考它调用)
-- ========================================================================

-- 1. 添加功能
AppleLib:AddToggle("飞行模式 (Fly)", false, function(s) print("Fly:", s) end)
AppleLib:AddToggle("自动瞄准 (Aimbot)", false, function(s) print("Aimbot:", s) end)

-- 2. 修改配置 (测试 API)
AppleLib.Config.a = 35  -- 高度
AppleLib.Config.b = 130 -- 宽度
AppleLib.Config.c = 0.1 -- 透明度

-- 3. 发送消息
AppleLib.ShowAlert({"库加载成功", "当前版本 V13.1", "rbxassetid://6031068420"})

return AppleLib
