--[[
    Apple Dynamic Island UI Library - Fixed Layering & Hierarchy
    按照指定 API 格式封装：
    AppleLib.ControlCenterVisible = bool
    AppleLib.ShowAlert({"标题", "状态", "图标"})
    AppleLib.Config.a/b/c = 数值
    AppleLib.Enabled = bool
]]

local AppleLib = {
    Enabled = true,
    _CCVisible = false,
    Config = {
        a = 35,  -- Height
        b = 120, -- Width
        c = 0,   -- Transparency
        CornerRadius = 1
    }
}

local Players = game:GetService("Players")
local TweenService = game:GetService("TweenService")
local UserInputService = game:GetService("UserInputService")
local CoreGui = game:GetService("CoreGui")
local Lighting = game:GetService("Lighting")

local guiParent = (gethui and gethui()) or CoreGui

-- 内部配置
local TweenInfoBase = TweenInfo.new(0.35, Enum.EasingStyle.Exponential, Enum.EasingDirection.Out)
local TweenInfoBounce = TweenInfo.new(0.5, Enum.EasingStyle.Back, Enum.EasingDirection.Out)
local ActiveAlertStack = {}
local CurrentState = "Idle"

local function create(className, properties)
    local inst = Instance.new(className)
    for k, v in pairs(properties or {}) do inst[k] = v end
    return inst
end

-- ========================================================================
-- [核心渲染层层级修复]
-- ========================================================================

local MainGui = create("ScreenGui", { 
    Name = "AppleDynamicIsland_Lib", 
    Parent = guiParent, 
    ZIndexBehavior = Enum.ZIndexBehavior.Global, -- 关键：使用全局层级管理
    IgnoreGuiInset = true 
})

local BackgroundBlur = create("BlurEffect", { Name = "ADI_Blur", Parent = Lighting, Size = 0 })
local DarkOverlay = create("TextButton", { 
    Parent = MainGui, Size = UDim2.new(1, 0, 1, 0), 
    BackgroundColor3 = Color3.new(0,0,0), BackgroundTransparency = 1, 
    Text = "", AutoButtonColor = false, Visible = false, ZIndex = 10 
})

-- 1. 灵动岛本体 (层级设为 100)
local IslandContainer = create("Frame", { 
    Name = "Island", Parent = MainGui, 
    AnchorPoint = Vector2.new(0.5, 0), Position = UDim2.new(0.5, 0, 0, 10), 
    Size = UDim2.new(0, 120, 0, 35), BackgroundColor3 = Color3.new(0,0,0), 
    ClipsDescendants = true, ZIndex = 100 
})
local IslandCorner = create("UICorner", { CornerRadius = UDim.new(1, 0), Parent = IslandContainer })
local IslandScale = create("UIScale", { Parent = IslandContainer })

-- 2. 装饰层 (摄像头孔)
local CameraHole = create("Frame", { 
    Parent = IslandContainer, AnchorPoint = Vector2.new(1, 0.5), 
    Position = UDim2.new(1, -15, 0.5, 0), Size = UDim2.new(0, 12, 0, 12), 
    BackgroundColor3 = Color3.fromRGB(15,15,15), ZIndex = 101 
})
create("UICorner", { CornerRadius = UDim.new(1, 0), Parent = CameraHole })

-- 3. 通知内容容器 (层级必须最高，设为 110)
local AlertStackContainer = create("ScrollingFrame", { 
    Parent = IslandContainer, Size = UDim2.new(1, 0, 1, 0), 
    BackgroundTransparency = 1, CanvasSize = UDim2.new(0,0,0,0), 
    ScrollBarThickness = 0, ClipsDescendants = false, ZIndex = 110 
})
create("UIListLayout", { Parent = AlertStackContainer, HorizontalAlignment = "Center", Padding = UDim.new(0, 5) })
create("UIPadding", { Parent = AlertStackContainer, PaddingTop = UDim.new(0, 8) })

-- 4. 控制中心 (层级设为 500)
local CC_Container = create("Frame", { 
    Name = "ControlCenter", Parent = MainGui, AnchorPoint = Vector2.new(0.5, 0.5), 
    Position = UDim2.new(0.5, 0, 1.5, 0), Size = UDim2.new(0, 340, 0, 560), 
    BackgroundTransparency = 1, ZIndex = 500 
})

-- ========================================================================
-- [内部逻辑]
-- ========================================================================

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

-- [API] 发送消息提示
function AppleLib.ShowAlert(data)
    local titleText = data[1] or "Notice"
    local stateText = data[2] or ""
    local iconId = data[3] or "rbxassetid://10664292213"
    
    CurrentState = "Alerting"
    local alertFrame = create("Frame", { 
        Parent = AlertStackContainer, Size = UDim2.new(1, 0, 0, 45), 
        BackgroundTransparency = 1, ClipsDescendants = true, ZIndex = 115 
    })
    
    local icon = create("ImageLabel", { Parent = alertFrame, Position = UDim2.new(0, 15, 0.5, -15), Size = UDim2.new(0, 30, 0, 30), BackgroundTransparency = 1, Image = iconId, ImageTransparency = 1, ZIndex = 116 })
    create("UICorner", {CornerRadius = UDim.new(0.2, 0), Parent = icon})
    
    local t = create("TextLabel", { Parent = alertFrame, Position = UDim2.new(0, 55, 0.5, -18), Size = UDim2.new(1, -70, 0, 20), BackgroundTransparency = 1, Text = titleText, TextColor3 = Color3.new(1,1,1), Font = "GothamBold", TextSize = 14, TextXAlignment = "Left", TextTransparency = 1, ZIndex = 116 })
    local d = create("TextLabel", { Parent = alertFrame, Position = UDim2.new(0, 55, 0.5, 2), Size = UDim2.new(1, -70, 0, 15), BackgroundTransparency = 1, Text = stateText, TextColor3 = Color3.fromRGB(180,180,180), Font = "Gotham", TextSize = 12, TextXAlignment = "Left", TextTransparency = 1, ZIndex = 116 })

    table.insert(ActiveAlertStack, { Frame = alertFrame, Width = 260, Height = 45 })
    RecalculateIslandSize()

    -- 延迟淡入，确保在灵动岛展开后显示，防止被盖住
    task.delay(0.1, function()
        TweenService:Create(icon, TweenInfoBase, { ImageTransparency = 0 }):Play()
        TweenService:Create(t, TweenInfoBase, { TextTransparency = 0 }):Play()
        TweenService:Create(d, TweenInfoBase, { TextTransparency = 0 }):Play()
    end)

    task.delay(3, function()
        if not alertFrame.Parent then return end
        TweenService:Create(icon, TweenInfoFast, { ImageTransparency = 1 }):Play()
        TweenService:Create(t, TweenInfoFast, { TextTransparency = 1 }):Play()
        TweenService:Create(d, TweenInfoFast, { TextTransparency = 1 }):Play()
        task.wait(0.2)
        TweenService:Create(alertFrame, TweenInfoFast, { Size = UDim2.new(1, 0, 0, 0) }):Play()
        for i, v in ipairs(ActiveAlertStack) do if v.Frame == alertFrame then table.remove(ActiveAlertStack, i) break end end
        task.wait(0.2)
        alertFrame:Destroy()
        if #ActiveAlertStack == 0 then CurrentState = "Idle" UpdateIslandBase() else RecalculateIslandSize() end
    end)
end

-- 控制中心显示/隐藏
local function ToggleCC(state)
    AppleLib._CCVisible = state
    if state then
        DarkOverlay.Visible = true
        TweenService:Create(BackgroundBlur, TweenInfo.new(0.4), {Size = 10}):Play()
        TweenService:Create(DarkOverlay, TweenInfo.new(0.4), {BackgroundTransparency = 0.35}):Play()
        TweenService:Create(CC_Container, TweenInfo.new(0.5, Enum.EasingStyle.Exponential), { Position = UDim2.new(0.5, 0, 0.5, 0) }):Play()
    else
        TweenService:Create(BackgroundBlur, TweenInfo.new(0.3), {Size = 0}):Play()
        TweenService:Create(DarkOverlay, TweenInfo.new(0.3), {BackgroundTransparency = 1}):Play()
        TweenService:Create(CC_Container, TweenInfo.new(0.4, Enum.EasingStyle.Back, Enum.EasingDirection.In), { Position = UDim2.new(0.5, 0, 1.5, 0) }):Play()
        task.delay(0.4, function() if not AppleLib._CCVisible then DarkOverlay.Visible = false end end)
    end
end

-- 元表绑定实现对象化属性调用
setmetatable(AppleLib, {
    __newindex = function(t, k, v)
        if k == "ControlCenterVisible" then ToggleCC(v) 
        elseif k == "Enabled" then rawset(t, k, v)
        else rawset(t, k, v) end
    end,
    __index = function(t, k)
        if k == "ControlCenterVisible" then return t._CCVisible end
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
-- [UI 组件工厂]
-- ========================================================================
local function createModule(size, pos)
    local f = create("Frame", { Parent = CC_Container, Size = size, Position = pos, BackgroundColor3 = Color3.fromRGB(30, 30, 35), BackgroundTransparency = 0.25, ZIndex = 510 })
    create("UICorner", { CornerRadius = UDim.new(0.15, 0), Parent = f })
    return f
end

local ToggleBox = createModule(UDim2.new(1, -24, 0, 200), UDim2.new(0, 12, 0, 340))
create("UIListLayout", { Parent = ToggleBox, SortOrder = "LayoutOrder" })

function AppleLib:AddToggle(text, default, callback)
    local frame = create("Frame", { Parent = ToggleBox, Size = UDim2.new(1, 0, 0, 50), BackgroundTransparency = 1, ZIndex = 520 })
    create("TextLabel", { Parent = frame, Position = UDim2.new(0, 15, 0, 0), Size = UDim2.new(0.6, 0, 1, 0), BackgroundTransparency = 1, Text = text, TextColor3 = Color3.new(0.9,0.9,0.9), Font = "GothamSemibold", TextSize = 14, TextXAlignment = "Left", ZIndex = 521 })
    
    local toggleBg = create("TextButton", { Parent = frame, AnchorPoint = Vector2.new(1, 0.5), Position = UDim2.new(1, -15, 0.5, 0), Size = UDim2.new(0, 50, 0, 30), BackgroundColor3 = default and Color3.fromRGB(52, 199, 89) or Color3.fromRGB(80, 80, 85), Text = "", AutoButtonColor = false, ZIndex = 521 })
    create("UICorner", {CornerRadius = UDim.new(1, 0), Parent = toggleBg})
    
    local knob = create("Frame", { Parent = toggleBg, Position = UDim2.new(0, default and 22 or 2, 0.5, -13), Size = UDim2.new(0, 26, 0, 26), BackgroundColor3 = Color3.new(1,1,1), ZIndex = 522 })
    create("UICorner", {CornerRadius = UDim.new(1, 0), Parent = knob})
    
    local state = default
    toggleBg.MouseButton1Click:Connect(function()
        state = not state
        TweenService:Create(toggleBg, TweenInfo.new(0.25), {BackgroundColor3 = state and Color3.fromRGB(52, 199, 89) or Color3.fromRGB(80, 80, 85)}):Play()
        TweenService:Create(knob, TweenInfo.new(0.3, Enum.EasingStyle.Back), {Position = UDim2.new(0, state and 22 or 2, 0.5, -13)}):Play()
        AppleLib.ShowAlert({text, state and "已开启" or "已关闭", "rbxassetid://10664292213"})
        callback(state)
    end)
end

-- 基础交互监听
InteractionButton = create("TextButton", { Parent = IslandContainer, Size = UDim2.new(1, 0, 1, 0), BackgroundTransparency = 1, Text = "", ZIndex = 1000 })
InteractionButton.MouseButton1Click:Connect(function()
    if AppleLib.Enabled then
        AppleLib.ControlCenterVisible = not AppleLib.ControlCenterVisible
    end
end)
DarkOverlay.MouseButton1Click:Connect(function() AppleLib.ControlCenterVisible = false end)

-- 初始化外观
UpdateIslandBase()

-- ========================================================================
-- [示例调用代码]
-- ========================================================================

-- 1. 功能属性
AppleLib.Enabled = true -- 允许点击打开灵动岛
AppleLib.Config.a = 35  -- 高度
AppleLib.Config.b = 130 -- 宽度
AppleLib.Config.c = 0   -- 透明度

-- 2. 添加开关到菜单
AppleLib:AddToggle("飞行模式 (Fly)", false, function(s) print("Fly Mode:", s) end)
AppleLib:AddToggle("无敌模式 (God)", false, function(s) print("God Mode:", s) end)

-- 3. 发送堆叠通知测试 (现在不会被遮挡)
AppleLib.ShowAlert({"系统消息", "脚本加载成功", "rbxassetid://6031068420"})
task.wait(0.5)
AppleLib.ShowAlert({"网络连接", "已连接到服务器", "rbxassetid://10664292213"})

return AppleLib
