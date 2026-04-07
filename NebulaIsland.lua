--[[
    Apple Dynamic Island & Control Center V14.0 (Final Repair)
    核心修复：
    1. 修复第3行及加载逻辑 Bug。
    2. 完美保留 V13.1 所有原生动画、堆叠逻辑和毛玻璃。
    3. 严格遵循自定义 API 格式。
]]

local AppleLib = {
    Enabled = true,
    _CCVisible = false,
    Config = {
        a = 35, -- Height
        b = 120, -- Width
        c = 0, -- Transparency
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

-- ========================================================================
-- [核心动画配置 - 1:1 保留 V13.1]
-- ========================================================================
local T_Base = TweenInfo.new(0.35, Enum.EasingStyle.Exponential, Enum.EasingDirection.Out)
local T_Bounce = TweenInfo.new(0.5, Enum.EasingStyle.Back, Enum.EasingDirection.Out)
local T_Fast = TweenInfo.new(0.2, Enum.EasingStyle.Sine, Enum.EasingDirection.Out)

local ActiveAlertStack = {}
local CurrentState = "Idle"

local function create(className, properties)
    local inst = Instance.new(className)
    for k, v in pairs(properties or {}) do inst[k] = v end
    return inst
end

-- ========================================================================
-- [UI 构建 - 1:1 保留 V13.1 样式]
-- ========================================================================
local MainGui = create("ScreenGui", { Name = "AppleLib_V14", Parent = guiParent, ResetOnSpawn = false, ZIndexBehavior = Enum.ZIndexBehavior.Global, IgnoreGuiInset = true })
local BackgroundBlur = create("BlurEffect", { Name = "ADI_Blur", Parent = Lighting, Size = 0 })
local DarkOverlay = create("TextButton", { Parent = MainGui, Size = UDim2.new(1, 0, 1, 0), BackgroundColor3 = Color3.new(0,0,0), BackgroundTransparency = 1, Text = "", AutoButtonColor = false, ZIndex = 500, Visible = false })

-- 灵动岛
local IslandContainer = create("Frame", { Name = "Island", Parent = MainGui, AnchorPoint = Vector2.new(0.5, 0), Position = UDim2.new(0.5, 0, 0, 10), Size = UDim2.new(0, 120, 0, 35), BackgroundColor3 = Color3.new(0,0,0), ClipsDescendants = true, ZIndex = 1000 })
local IslandCorner = create("UICorner", { CornerRadius = UDim.new(1, 0), Parent = IslandContainer })
local IslandScale = create("UIScale", { Parent = IslandContainer, Scale = 1 })

local CameraHole = create("Frame", { Parent = IslandContainer, AnchorPoint = Vector2.new(1, 0.5), Position = UDim2.new(1, -15, 0.5, 0), Size = UDim2.new(0, 12, 0, 12), BackgroundColor3 = Color3.fromRGB(15,15,15), ZIndex = 1002 })
create("UICorner", { CornerRadius = UDim.new(1, 0), Parent = CameraHole })

-- 内容层
local ContentFrame = create("Frame", { Parent = IslandContainer, Size = UDim2.new(1, 0, 1, 0), BackgroundTransparency = 1, ZIndex = 1003 })
local AlertStackContainer = create("ScrollingFrame", { Parent = ContentFrame, Size = UDim2.new(1, 0, 1, 0), BackgroundTransparency = 1, CanvasSize = UDim2.new(0,0,0,0), ScrollBarThickness = 0, ClipsDescendants = false, ZIndex = 1005 })
create("UIListLayout", { Parent = AlertStackContainer, HorizontalAlignment = Enum.HorizontalAlignment.Center, Padding = UDim.new(0, 5) })
create("UIPadding", { Parent = AlertStackContainer, PaddingTop = UDim.new(0, 8), PaddingBottom = UDim.new(0, 8) })

-- 控制中心
local CC_Container = create("Frame", { Name = "ControlCenter", Parent = MainGui, AnchorPoint = Vector2.new(0.5, 0.5), Position = UDim2.new(0.5, 0, 1.5, 0), Size = UDim2.new(0, 340, 0, 560), BackgroundTransparency = 1, ZIndex = 2000 })

-- ========================================================================
-- [核心功能逻辑 - 修复属性拦截]
-- ========================================================================

local function UpdateIslandBase()
    if CurrentState == "Idle" then
        TweenService:Create(IslandContainer, T_Base, { 
            Size = UDim2.new(0, AppleLib.Config.b, 0, AppleLib.Config.a),
            BackgroundTransparency = AppleLib.Config.c
        }):Play()
    else
        TweenService:Create(IslandContainer, T_Base, { BackgroundTransparency = AppleLib.Config.c }):Play()
    end
    IslandCorner.CornerRadius = UDim.new(AppleLib.Config.CornerRadius, 0)
end

local function RecalculateIslandSize()
    if #ActiveAlertStack == 0 then return end
    local totalHeight = 16
    local maxWidth = AppleLib.Config.b
    for _, alert in ipairs(ActiveAlertStack) do
        totalHeight = totalHeight + alert.Height + 5
        if alert.Width > maxWidth then maxWidth = alert.Width end
    end
    TweenService:Create(IslandContainer, T_Bounce, { Size = UDim2.new(0, maxWidth, 0, totalHeight) }):Play()
    TweenService:Create(CameraHole, T_Bounce, { Position = UDim2.new(1, -15, 0, AppleLib.Config.a / 2) }):Play()
end

-- [API] 消息提示
function AppleLib.ShowAlert(data)
    CurrentState = "Alerting"
    local alertFrame = create("Frame", { Parent = AlertStackContainer, Size = UDim2.new(1, 0, 0, 45), BackgroundTransparency = 1, ClipsDescendants = true, ZIndex = 1010 })
    local icon = create("ImageLabel", { Parent = alertFrame, Position = UDim2.new(0, 15, 0.5, -15), Size = UDim2.new(0, 30, 0, 30), BackgroundTransparency = 1, Image = data[3] or "", ImageTransparency = 1, ZIndex = 1011 })
    create("UICorner", {CornerRadius = UDim.new(0.2, 0), Parent = icon})
    local title = create("TextLabel", { Parent = alertFrame, Position = UDim2.new(0, 55, 0.5, -18), Size = UDim2.new(1, -70, 0, 20), BackgroundTransparency = 1, Text = data[1] or "", TextColor3 = Color3.new(1,1,1), Font = Enum.Font.GothamBold, TextSize = 14, TextXAlignment = "Left", TextTransparency = 1, ZIndex = 1011 })
    local desc = create("TextLabel", { Parent = alertFrame, Position = UDim2.new(0, 55, 0.5, 2), Size = UDim2.new(1, -70, 0, 15), BackgroundTransparency = 1, Text = data[2] or "", TextColor3 = Color3.fromRGB(180,180,180), Font = Enum.Font.Gotham, TextSize = 12, TextXAlignment = "Left", TextTransparency = 1, ZIndex = 1011 })

    table.insert(ActiveAlertStack, { Frame = alertFrame, Width = 260, Height = 45 })
    RecalculateIslandSize()

    task.delay(0.1, function()
        TweenService:Create(icon, T_Base, {ImageTransparency = 0}):Play()
        TweenService:Create(title, T_Base, {TextTransparency = 0}):Play()
        TweenService:Create(desc, T_Base, {TextTransparency = 0}):Play()
    end)

    task.delay(3, function()
        if not alertFrame.Parent then return end
        TweenService:Create(icon, T_Fast, {ImageTransparency = 1}):Play()
        TweenService:Create(title, T_Fast, {TextTransparency = 1}):Play()
        TweenService:Create(desc, T_Fast, {TextTransparency = 1}):Play()
        task.wait(0.2)
        TweenService:Create(alertFrame, T_Fast, {Size = UDim2.new(1, 0, 0, 0)}):Play()
        for i, v in ipairs(ActiveAlertStack) do if v.Frame == alertFrame then table.remove(ActiveAlertStack, i) break end end
        task.wait(0.2)
        alertFrame:Destroy()
        if #ActiveAlertStack == 0 then CurrentState = "Idle" UpdateIslandBase() else RecalculateIslandSize() end
    end)
end

-- [API] 快速通知
function AppleLib.Banner(title, content, icon)
    AppleLib.ShowAlert({title, content, icon})
end

-- [控制中心开关动画]
local function SetCCVisible(state)
    AppleLib._CCVisible = state
    if state then
        DarkOverlay.Visible = true
        TweenService:Create(BackgroundBlur, TweenInfo.new(0.4), {Size = 10}):Play()
        TweenService:Create(DarkOverlay, TweenInfo.new(0.4), {BackgroundTransparency = 0.35}):Play()
        TweenService:Create(CC_Container, T_Base, { Position = UDim2.new(0.5, 0, 0.5, 0) }):Play()
    else
        TweenService:Create(BackgroundBlur, TweenInfo.new(0.3), {Size = 0}):Play()
        TweenService:Create(DarkOverlay, TweenInfo.new(0.3), {BackgroundTransparency = 1}):Play()
        TweenService:Create(CC_Container, TweenInfo.new(0.4, Enum.EasingStyle.Back, Enum.EasingDirection.In), { Position = UDim2.new(0.5, 0, 1.5, 0) }):Play()
        task.delay(0.4, function() if not AppleLib._CCVisible then DarkOverlay.Visible = false end end)
    end
end

-- ========================================================================
-- [元表劫持 - 核心修复点]
-- ========================================================================
setmetatable(AppleLib.Config, {
    __newindex = function(t, k, v)
        rawset(t, k, v)
        UpdateIslandBase()
    end
})

setmetatable(AppleLib, {
    __newindex = function(t, k, v)
        if k == "ControlCenterVisible" then SetCCVisible(v)
        else rawset(t, k, v) end
    end,
    __index = function(t, k)
        if k == "ControlCenterVisible" then return t._CCVisible end
        return rawget(t, k)
    end
})

-- ========================================================================
-- [控制中心 UI 组件 - 1:1 保留 V13.1 开关逻辑]
-- ========================================================================
local function createModule(size, pos)
    local f = create("Frame", { Parent = CC_Container, Size = size, Position = pos, BackgroundColor3 = Color3.fromRGB(30, 30, 35), BackgroundTransparency = 0.25, ZIndex = 2010 })
    create("UICorner", { CornerRadius = UDim.new(0.15, 0), Parent = f })
    return f
end

local ToggleBox = createModule(UDim2.new(1, -24, 0, 200), UDim2.new(0, 12, 0, 340))
create("UIListLayout", { Parent = ToggleBox, SortOrder = "LayoutOrder" })

function AppleLib:AddToggle(text, default, callback)
    local frame = create("Frame", { Parent = ToggleBox, Size = UDim2.new(1, 0, 0, 50), BackgroundTransparency = 1, ZIndex = 2020 })
    create("TextLabel", { Parent = frame, Position = UDim2.new(0, 15, 0, 0), Size = UDim2.new(0.6, 0, 1, 0), BackgroundTransparency = 1, Text = text, TextColor3 = Color3.new(0.9,0.9,0.9), Font = "GothamSemibold", TextSize = 14, TextXAlignment = "Left", ZIndex = 2021 })
    
    local toggleBg = create("TextButton", { Parent = frame, AnchorPoint = Vector2.new(1, 0.5), Position = UDim2.new(1, -15, 0.5, 0), Size = UDim2.new(0, 50, 0, 30), BackgroundColor3 = default and Color3.fromRGB(52, 199, 89) or Color3.fromRGB(80, 80, 85), Text = "", AutoButtonColor = false, ZIndex = 2021 })
    create("UICorner", {CornerRadius = UDim.new(1, 0), Parent = toggleBg})
    
    local knob = create("Frame", { Parent = toggleBg, Position = UDim2.new(0, default and 22 or 2, 0.5, -13), Size = UDim2.new(0, 26, 0, 26), BackgroundColor3 = Color3.new(1,1,1), ZIndex = 2022 })
    create("UICorner", {CornerRadius = UDim.new(1, 0), Parent = knob})
    
    local state = default
    toggleBg.MouseButton1Click:Connect(function()
        state = not state
        TweenService:Create(toggleBg, T_Fast, {BackgroundColor3 = state and Color3.fromRGB(52, 199, 89) or Color3.fromRGB(80, 80, 85)}):Play()
        TweenService:Create(knob, TweenInfo.new(0.35, Enum.EasingStyle.Back), {Position = UDim2.new(0, state and 22 or 2, 0.5, -13)}):Play()
        AppleLib.Banner(text, state and "已开启" or "已关闭", "rbxassetid://10664292213")
        callback(state)
    end)
    create("Frame", {Parent = ToggleBox, Size = UDim2.new(1, 0, 0, 1), BackgroundColor3 = Color3.fromRGB(60,60,65), BorderSizePixel = 0})
end

-- ========================================================================
-- [交互监听]
-- ========================================================================
DarkOverlay.MouseButton1Click:Connect(function() AppleLib.ControlCenterVisible = false end)

local InteractionButton = create("TextButton", { Parent = IslandContainer, Size = UDim2.new(1, 0, 1, 0), BackgroundTransparency = 1, Text = "", ZIndex = 1100 })
InteractionButton.InputBegan:Connect(function(input)
    if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
        TweenService:Create(IslandScale, T_Fast, {Scale = 0.92}):Play()
    end
end)
InteractionButton.InputEnded:Connect(function(input)
    if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
        TweenService:Create(IslandScale, T_Bounce, {Scale = 1}):Play()
        if AppleLib.Enabled then AppleLib.ControlCenterVisible = not AppleLib.ControlCenterVisible end
    end
end)

-- 初始启动
UpdateIslandBase()

return AppleLib
