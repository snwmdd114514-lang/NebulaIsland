--[[
    ===========================================================================
    Apple Dynamic Island UI Library V13.1 (Wrapper Edition)
    ===========================================================================
]]

local AppleLib = {}
AppleLib.__index = AppleLib

-- 服务
local Players = game:GetService("Players")
local TweenService = game:GetService("TweenService")
local UserInputService = game:GetService("UserInputService")
local CoreGui = game:GetService("CoreGui")
local Lighting = game:GetService("Lighting")

local LocalPlayer = Players.LocalPlayer
local guiParent = (gethui and gethui()) or CoreGui

-- 配置与状态
local IslandConfig = {
    BaseWidth = 120, BaseHeight = 35, YOffset = 10,
    BackgroundColor = Color3.fromRGB(0, 0, 0),
    Transparency = 0, CornerRadius = 1,
    TweenInfoBase = TweenInfo.new(0.35, Enum.EasingStyle.Exponential, Enum.EasingDirection.Out),
    TweenInfoBounce = TweenInfo.new(0.5, Enum.EasingStyle.Back, Enum.EasingDirection.Out, 0, false, 0),
    TweenInfoFast = TweenInfo.new(0.2, Enum.EasingStyle.Sine, Enum.EasingDirection.Out),
    CurrentState = "Idle",
    ActiveAlertStack = {}
}

-- 内部工具函数
local function create(className, properties)
    local inst = Instance.new(className)
    for k, v in pairs(properties or {}) do inst[k] = v end
    return inst
end

local function addCorner(parent, radius)
    return create("UICorner", {CornerRadius = UDim.new(radius or 1, 0), Parent = parent})
end

-- 初始化基础 UI
local MainGui = create("ScreenGui", {
    Name = "AppleDynamicIsland_Lib", Parent = guiParent, ResetOnSpawn = false, IgnoreGuiInset = true
})

local BackgroundBlur = create("BlurEffect", { Name = "ADI_Blur", Parent = Lighting, Size = 0 })

local DarkOverlay = create("TextButton", {
    Parent = MainGui, Size = UDim2.new(1, 0, 1, 0), BackgroundColor3 = Color3.fromRGB(0, 0, 0), 
    BackgroundTransparency = 1, Text = "", AutoButtonColor = false, Visible = false 
})

-- 灵动岛本体
local IslandContainer = create("Frame", {
    Name = "Island", Parent = MainGui, AnchorPoint = Vector2.new(0.5, 0),
    Position = UDim2.new(0.5, 0, 0, IslandConfig.YOffset), Size = UDim2.new(0, IslandConfig.BaseWidth, 0, IslandConfig.BaseHeight),
    BackgroundColor3 = IslandConfig.BackgroundColor, ClipsDescendants = true, ZIndex = 100
})
local IslandCorner = addCorner(IslandContainer, IslandConfig.CornerRadius)
local IslandScale = create("UIScale", {Parent = IslandContainer, Scale = 1})

local CameraHole = create("Frame", {
    Parent = IslandContainer, AnchorPoint = Vector2.new(1, 0.5), Position = UDim2.new(1, -15, 0.5, 0), 
    Size = UDim2.new(0, 12, 0, 12), BackgroundColor3 = Color3.fromRGB(15, 15, 15), ZIndex = 102
})
addCorner(CameraHole, 1)

local ContentFrame = create("Frame", { Parent = IslandContainer, Size = UDim2.new(1, 0, 1, 0), BackgroundTransparency = 1, ZIndex = 103 })

local AlertStackContainer = create("ScrollingFrame", {
    Parent = ContentFrame, Size = UDim2.new(1, 0, 1, 0), BackgroundTransparency = 1, 
    CanvasSize = UDim2.new(0, 0, 0, 0), ScrollBarThickness = 0, ClipsDescendants = false
})
create("UIListLayout", { Parent = AlertStackContainer, HorizontalAlignment = "Center", Padding = UDim.new(0, 5) })
create("UIPadding", { Parent = AlertStackContainer, PaddingTop = UDim.new(0, 8), PaddingBottom = UDim.new(0, 8) })

-- 控制中心基础
local CC_Container = create("Frame", {
    Name = "ControlCenter", Parent = MainGui, AnchorPoint = Vector2.new(0.5, 0.5),
    Position = UDim2.new(0.5, 0, 1.5, 0), Size = UDim2.new(0, 340, 0, 560), BackgroundTransparency = 1, ZIndex = 10
})

-- ========================================================================
-- [库核心功能实现]
-- ========================================================================

function AppleLib:UpdateVisuals()
    TweenService:Create(IslandContainer, IslandConfig.TweenInfoBase, { 
        Size = (IslandConfig.CurrentState == "Idle") and UDim2.new(0, IslandConfig.BaseWidth, 0, IslandConfig.BaseHeight) or IslandContainer.Size,
        BackgroundTransparency = IslandConfig.Transparency
    }):Play()
    IslandCorner.CornerRadius = UDim.new(IslandConfig.CornerRadius, 0)
end

function AppleLib:RecalculateIslandSize()
    local stack = IslandConfig.ActiveAlertStack
    if #stack == 0 then return end
    local totalHeight = 16
    local maxWidth = IslandConfig.BaseWidth
    for _, alert in ipairs(stack) do
        totalHeight = totalHeight + alert.Height + 5
        if alert.Width > maxWidth then maxWidth = alert.Width end
    end
    totalHeight = totalHeight - 5
    TweenService:Create(IslandContainer, IslandConfig.TweenInfoBounce, { Size = UDim2.new(0, maxWidth, 0, math.clamp(totalHeight, IslandConfig.BaseHeight, 600)) }):Play()
    TweenService:Create(CameraHole, IslandConfig.TweenInfoBounce, { Position = UDim2.new(1, -15, 0, IslandConfig.BaseHeight / 2) }):Play()
end

-- [API] 显示通知
function AppleLib:ShowAlert(params)
    IslandConfig.CurrentState = "Alerting"
    local height = params.Height or 45
    local alertFrame = create("Frame", { Parent = AlertStackContainer, Size = UDim2.new(1, 0, 0, height), BackgroundTransparency = 1, ClipsDescendants = true })
    
    local icon = create("ImageLabel", {
        Parent = alertFrame, AnchorPoint = Vector2.new(0, 0.5), Position = UDim2.new(0, 15, 0.5, 0),
        Size = UDim2.new(0, params.IconSize or 30, 0, params.IconSize or 30), BackgroundTransparency = 1,
        Image = params.Icon or "", ImageColor3 = params.Color or Color3.new(1,1,1), ImageTransparency = 1
    })
    addCorner(icon, 0.2)

    local title = create("TextLabel", {
        Parent = alertFrame, Position = UDim2.new(0, 65, 0, height/2 - 10), Size = UDim2.new(1, -110, 0, 20),
        BackgroundTransparency = 1, Text = params.Title or "Notification", TextColor3 = Color3.new(1,1,1),
        Font = "GothamBold", TextSize = 15, TextXAlignment = "Left", TextTransparency = 1
    })

    local desc = create("TextLabel", {
        Parent = alertFrame, Position = UDim2.new(0, 65, 0, height/2 + 5), Size = UDim2.new(1, -110, 0, 15),
        BackgroundTransparency = 1, Text = params.Desc or "", TextColor3 = Color3.fromRGB(180,180,180),
        Font = "Gotham", TextSize = 13, TextXAlignment = "Left", TextTransparency = 1
    })

    local data = { Frame = alertFrame, Width = params.Width or 240, Height = height }
    table.insert(IslandConfig.ActiveAlertStack, data)
    self:RecalculateIslandSize()

    TweenService:Create(icon, IslandConfig.TweenInfoBase, {ImageTransparency = 0}):Play()
    TweenService:Create(title, IslandConfig.TweenInfoBase, {TextTransparency = 0}):Play()
    if params.Desc ~= "" then TweenService:Create(desc, IslandConfig.TweenInfoBase, {TextTransparency = 0}):Play() end

    task.delay(params.Duration or 2.5, function()
        if not alertFrame.Parent then return end
        TweenService:Create(alertFrame, IslandConfig.TweenInfoFast, {Size = UDim2.new(1, 0, 0, 0)}):Play()
        for i, v in ipairs(IslandConfig.ActiveAlertStack) do if v.Frame == alertFrame then table.remove(IslandConfig.ActiveAlertStack, i) break end end
        task.wait(0.2)
        alertFrame:Destroy()
        if #IslandConfig.ActiveAlertStack == 0 then
            IslandConfig.CurrentState = "Idle"
            self:UpdateVisuals()
        else
            self:RecalculateIslandSize()
        end
    end)
end

-- [API] 切换控制中心显示
local isMenuOpen = false
function AppleLib:SetControlCenterVisible(state)
    isMenuOpen = state
    if isMenuOpen then
        DarkOverlay.Visible = true 
        TweenService:Create(BackgroundBlur, TweenInfo.new(0.4), {Size = 10}):Play()
        TweenService:Create(DarkOverlay, TweenInfo.new(0.4), {BackgroundTransparency = 0.35}):Play()
        TweenService:Create(CC_Container, TweenInfo.new(0.5, Enum.EasingStyle.Exponential, Enum.EasingDirection.Out), { Position = UDim2.new(0.5, 0, 0.5, 0) }):Play()
    else
        TweenService:Create(BackgroundBlur, TweenInfo.new(0.3), {Size = 0}):Play()
        TweenService:Create(DarkOverlay, TweenInfo.new(0.3), {BackgroundTransparency = 1}):Play()
        TweenService:Create(CC_Container, TweenInfo.new(0.4, Enum.EasingStyle.Back, Enum.EasingDirection.In), { Position = UDim2.new(0.5, 0, 1.5, 0) }):Play()
        task.delay(0.3, function() if not isMenuOpen then DarkOverlay.Visible = false end end)
    end
end

-- ========================================================================
-- [控制中心组件工厂]
-- ========================================================================

local function createModule(size, pos)
    local frame = create("Frame", { Parent = CC_Container, Size = size, Position = pos, BackgroundColor3 = Color3.fromRGB(30, 30, 35), BackgroundTransparency = 0.25 })
    addCorner(frame, 0.15)
    return frame
end

-- 原生滑块
local function createSlider(parent, isVertical, size, pos, iconText, min, max, default, callback)
    local slider = createModule(size, pos)
    slider.Parent = parent
    local fill = create("Frame", { Parent = slider, BackgroundColor3 = Color3.new(1,1,1), BackgroundTransparency = 0.1 })
    addCorner(fill, 0.15)
    local iconLabel = create("TextLabel", { Parent = slider, BackgroundTransparency = 1, Text = iconText, TextColor3 = Color3.fromRGB(150, 150, 150), Font = "GothamBold", TextSize = 20, ZIndex = 2, Size = UDim2.new(1,0,1,0)})
    
    local function update(input)
        local per = isVertical and 1 - math.clamp((input.Position.Y - slider.AbsolutePosition.Y) / slider.AbsoluteSize.Y, 0, 1) or math.clamp((input.Position.X - slider.AbsolutePosition.X) / slider.AbsoluteSize.X, 0, 1)
        fill.Size = isVertical and UDim2.new(1, 0, per, 0) or UDim2.new(per, 0, 1, 0)
        fill.Position = isVertical and UDim2.new(0,0,1-per,0) or UDim2.new(0,0,0,0)
        callback(min + (max - min) * per)
    end

    local dragging = false
    slider.InputBegan:Connect(function(i) if i.UserInputType == Enum.UserInputType.MouseButton1 or i.UserInputType == Enum.UserInputType.Touch then dragging = true update(i) end end)
    UserInputService.InputChanged:Connect(function(i) if dragging and (i.UserInputType == Enum.UserInputType.MouseMovement or i.UserInputType == Enum.UserInputType.Touch) then update(i) end end)
    UserInputService.InputEnded:Connect(function(i) if i.UserInputType == Enum.UserInputType.MouseButton1 or i.UserInputType == Enum.UserInputType.Touch then dragging = false end end)
    
    -- 设置初始位置
    local startPer = (default - min) / (max - min)
    fill.Size = isVertical and UDim2.new(1, 0, startPer, 0) or UDim2.new(startPer, 0, 1, 0)
    fill.Position = isVertical and UDim2.new(0,0,1-startPer,0) or UDim2.new(0,0,0,0)
end

-- [API] 添加开关
local ToggleBox = createModule(UDim2.new(1, -24, 0, 150), UDim2.new(0, 12, 0, 395))
local ToggleList = create("UIListLayout", { Parent = ToggleBox, SortOrder = "LayoutOrder" })

function AppleLib:AddToggle(text, default, callback)
    local frame = create("Frame", { Parent = ToggleBox, Size = UDim2.new(1, 0, 0, 50), BackgroundTransparency = 1 })
    create("TextLabel", { Parent = frame, Position = UDim2.new(0, 15, 0, 0), Size = UDim2.new(0.6, 0, 1, 0), BackgroundTransparency = 1, Text = text, TextColor3 = Color3.new(0.9,0.9,0.9), Font = "GothamSemibold", TextSize = 14, TextXAlignment = "Left" })
    
    local toggleBg = create("TextButton", { Parent = frame, AnchorPoint = Vector2.new(1, 0.5), Position = UDim2.new(1, -15, 0.5, 0), Size = UDim2.new(0, 50, 0, 30), BackgroundColor3 = default and Color3.fromRGB(52, 199, 89) or Color3.fromRGB(80, 80, 85), Text = "", AutoButtonColor = false })
    addCorner(toggleBg, 1)
    local knob = create("Frame", { Parent = toggleBg, AnchorPoint = Vector2.new(0, 0.5), Position = UDim2.new(0, default and 22 or 2, 0.5, 0), Size = UDim2.new(0, 26, 0, 26), BackgroundColor3 = Color3.new(1,1,1) })
    addCorner(knob, 1)
    
    local state = default
    toggleBg.MouseButton1Click:Connect(function()
        state = not state
        TweenService:Create(toggleBg, TweenInfo.new(0.25), {BackgroundColor3 = state and Color3.fromRGB(52, 199, 89) or Color3.fromRGB(80, 80, 85)}):Play()
        TweenService:Create(knob, TweenInfo.new(0.3, Enum.EasingStyle.Back), {Position = UDim2.new(0, state and 22 or 2, 0.5, 0)}):Play()
        
        self:ShowAlert({ Title = text, Desc = state and "状态: 开启" or "状态: 关闭", Color = state and Color3.new(0,1,0) or Color3.new(1,0,0), Width = 260 })
        callback(state)
    end)
    -- 添加分割线
    create("Frame", {Parent = ToggleBox, Size = UDim2.new(1, 0, 0, 1), BackgroundColor3 = Color3.fromRGB(60,60,65), BorderSizePixel = 0})
end

-- ========================================================================
-- [初始化默认组件]
-- ========================================================================

-- 交互逻辑
local InteractionButton = create("TextButton", { Parent = IslandContainer, Size = UDim2.new(1, 0, 1, 0), BackgroundTransparency = 1, Text = "", ZIndex = 1000 })
InteractionButton.InputBegan:Connect(function(i) if i.UserInputType == Enum.UserInputType.MouseButton1 or i.UserInputType == Enum.UserInputType.Touch then TweenService:Create(IslandScale, TweenInfo.new(0.15), {Scale = 0.92}):Play() end end)
InteractionButton.InputEnded:Connect(function(i) if i.UserInputType == Enum.UserInputType.MouseButton1 or i.UserInputType == Enum.UserInputType.Touch then
    TweenService:Create(IslandScale, IslandConfig.TweenInfoBounce, {Scale = 1}):Play()
    AppleLib:SetControlCenterVisible(not isMenuOpen)
end end)
DarkOverlay.MouseButton1Click:Connect(function() AppleLib:SetControlCenterVisible(false) end)

-- 默认滑块 (控制岛屿宽度/高度)
createSlider(CC_Container, true, UDim2.new(0, 70, 0, 150), UDim2.new(0, 12, 0, 176), "↔", 50, 350, IslandConfig.BaseWidth, function(v) IslandConfig.BaseWidth = v AppleLib:UpdateVisuals() end)
createSlider(CC_Container, true, UDim2.new(0, 70, 0, 150), UDim2.new(0, 94, 0, 176), "↕", 20, 80, IslandConfig.BaseHeight, function(v) IslandConfig.BaseHeight = v AppleLib:UpdateVisuals() end)
createSlider(CC_Container, false, UDim2.new(1, -24, 0, 45), UDim2.new(0, 12, 0, 338), "👁 透明度", 0, 1, 0, function(v) IslandConfig.Transparency = v AppleLib:UpdateVisuals() end)

-- 启动动画
IslandContainer.Size = UDim2.new(0, 0, 0, IslandConfig.BaseHeight)
task.wait(0.2)
TweenService:Create(IslandContainer, TweenInfo.new(0.8, Enum.EasingStyle.Back), { Size = UDim2.new(0, IslandConfig.BaseWidth, 0, IslandConfig.BaseHeight) }):Play()

return AppleLib
