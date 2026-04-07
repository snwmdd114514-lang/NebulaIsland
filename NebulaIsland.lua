--[[
    Apple Dynamic Island & Control Center UI Library V14.0
    Author: Optimized Framework
]]

local AppleLib = {}
AppleLib.__index = AppleLib

local Players = game:GetService("Players")
local TweenService = game:GetService("TweenService")
local RunService = game:GetService("RunService")
local UserInputService = game:GetService("UserInputService")
local CoreGui = game:GetService("CoreGui")
local Lighting = game:GetService("Lighting")

local LocalPlayer = Players.LocalPlayer
local Mouse = LocalPlayer:GetMouse()

-- [工具函数]
local function create(className, properties)
    local inst = Instance.new(className)
    for k, v in pairs(properties or {}) do inst[k] = v end
    return inst
end

local function addCorner(parent, radius)
    create("UICorner", {CornerRadius = UDim.new(radius or 0, 8), Parent = parent})
end

-- [配置]
local Config = {
    IslandBaseWidth = 120,
    IslandBaseHeight = 35,
    TweenInfo = TweenInfo.new(0.4, Enum.EasingStyle.Exponential, Enum.EasingDirection.Out),
    Colors = {
        Main = Color3.fromRGB(0, 0, 0),
        Accent = Color3.fromRGB(52, 199, 89),
        Text = Color3.fromRGB(255, 255, 255),
        SecondaryText = Color3.fromRGB(180, 180, 180),
        Button = Color3.fromRGB(40, 40, 45)
    }
}

function AppleLib:Init(settings)
    local self = setmetatable({}, AppleLib)
    
    -- 根节点
    local guiParent = (gethui and gethui()) or CoreGui
    if guiParent:FindFirstChild("AppleDynamicIsland_Lib") then guiParent.AppleDynamicIsland_Lib:Destroy() end
    
    self.MainGui = create("ScreenGui", {
        Name = "AppleDynamicIsland_Lib",
        Parent = guiParent,
        ResetOnSpawn = false,
        IgnoreGuiInset = true
    })

    -- 模糊效果
    self.Blur = create("BlurEffect", {Parent = Lighting, Size = 0})
    
    -- [灵动岛组件]
    self.IslandStack = {}
    self.IslandContainer = create("Frame", {
        Name = "Island", Parent = self.MainGui,
        AnchorPoint = Vector2.new(0.5, 0), Position = UDim2.new(0.5, 0, 0, 10),
        Size = UDim2.new(0, Config.IslandBaseWidth, 0, Config.IslandBaseHeight),
        BackgroundColor3 = Config.Colors.Main, BackgroundTransparency = 0,
        ClipsDescendants = true, ZIndex = 100
    })
    addCorner(self.IslandContainer, 1)
    
    self.IslandContent = create("ScrollingFrame", {
        Parent = self.IslandContainer, Size = UDim2.new(1, 0, 1, 0),
        BackgroundTransparency = 1, CanvasSize = UDim2.new(0,0,0,0),
        ScrollBarThickness = 0
    })
    create("UIListLayout", {
        Parent = self.IslandContent, SortOrder = Enum.SortOrder.LayoutOrder,
        Padding = UDim.new(0, 5), HorizontalAlignment = Enum.HorizontalAlignment.Center
    })
    create("UIPadding", {Parent = self.IslandContent, PaddingTop = UDim.new(0, 8)})

    self.CameraHole = create("Frame", {
        Parent = self.IslandContainer, AnchorPoint = Vector2.new(1, 0.5),
        Position = UDim2.new(1, -15, 0, Config.IslandBaseHeight/2),
        Size = UDim2.new(0, 12, 0, 12), BackgroundColor3 = Color3.fromRGB(20, 20, 20), ZIndex = 101
    })
    addCorner(self.CameraHole, 1)

    -- [控制中心组件]
    self.DarkOverlay = create("TextButton", {
        Parent = self.MainGui, Size = UDim2.new(1, 0, 1, 0),
        BackgroundColor3 = Color3.fromRGB(0,0,0), BackgroundTransparency = 1,
        Text = "", AutoButtonColor = false, Visible = false
    })

    self.CCFrame = create("Frame", {
        Parent = self.MainGui, AnchorPoint = Vector2.new(0.5, 0.5),
        Position = UDim2.new(0.5, 0, 1.5, 0), Size = UDim2.new(0, 350, 0, 500),
        BackgroundColor3 = Color3.fromRGB(25, 25, 30), BackgroundTransparency = 0.1, ZIndex = 200
    })
    addCorner(self.CCFrame, 0.08)

    self.CCScroll = create("ScrollingFrame", {
        Parent = self.CCFrame, Size = UDim2.new(1, -20, 1, -40),
        Position = UDim2.new(0, 10, 0, 20), BackgroundTransparency = 1,
        CanvasSize = UDim2.new(0, 0, 0, 0), ScrollBarThickness = 2,
        ScrollBarImageColor3 = Color3.fromRGB(80, 80, 80)
    })
    create("UIListLayout", {Parent = self.CCScroll, SortOrder = Enum.SortOrder.LayoutOrder, Padding = UDim.new(0, 12)})

    -- 交互逻辑
    self:HandleInteractions()
    
    return self
end

-- [内部函数：刷新灵动岛大小]
function AppleLib:RecalculateIsland()
    local targetHeight = Config.IslandBaseHeight
    local targetWidth = Config.IslandBaseWidth
    
    if #self.IslandStack > 0 then
        local contentHeight = 16
        for _, item in ipairs(self.IslandStack) do
            contentHeight = contentHeight + item.Height + 5
            targetWidth = math.max(targetWidth, item.Width)
        end
        targetHeight = math.clamp(contentHeight, Config.IslandBaseHeight, 500)
    end
    
    TweenService:Create(self.IslandContainer, Config.TweenInfo, {
        Size = UDim2.new(0, targetWidth, 0, targetHeight)
    }):Play()
end

-- [公有函数：发送通知]
function AppleLib:Notify(data)
    local titleText = data.Title or "Notification"
    local descText = data.Content or ""
    local duration = data.Duration or 3
    local width = data.Width or 280
    local height = data.Height or 50

    local itemFrame = create("Frame", {
        Parent = self.IslandContent, Size = UDim2.new(0, width, 0, height),
        BackgroundTransparency = 1, ClipsDescendants = true
    })
    
    local icon = create("ImageLabel", {
        Parent = itemFrame, Position = UDim2.new(0, 15, 0.5, -15),
        Size = UDim2.new(0, 30, 0, 30), BackgroundTransparency = 1,
        Image = data.Icon or "rbxassetid://6031068421", ImageTransparency = 1
    })
    addCorner(icon, 0.3)

    local title = create("TextLabel", {
        Parent = itemFrame, Position = UDim2.new(0, 55, 0.2, 0),
        Size = UDim2.new(1, -70, 0, 20), BackgroundTransparency = 1,
        Text = titleText, TextColor3 = Config.Colors.Text,
        Font = Enum.Font.GothamBold, TextSize = 14, TextXAlignment = Enum.TextXAlignment.Left,
        TextTransparency = 1
    })

    local desc = create("TextLabel", {
        Parent = itemFrame, Position = UDim2.new(0, 55, 0.6, 0),
        Size = UDim2.new(1, -70, 0, 15), BackgroundTransparency = 1,
        Text = descText, TextColor3 = Config.Colors.SecondaryText,
        Font = Enum.Font.Gotham, TextSize = 12, TextXAlignment = Enum.TextXAlignment.Left,
        TextTransparency = 1
    })

    local entry = {Frame = itemFrame, Width = width, Height = height}
    table.insert(self.IslandStack, entry)
    self:RecalculateIsland()

    -- 入场动画
    TweenService:Create(icon, Config.TweenInfo, {ImageTransparency = 0}):Play()
    TweenService:Create(title, Config.TweenInfo, {TextTransparency = 0}):Play()
    TweenService:Create(desc, Config.TweenInfo, {TextTransparency = 0}):Play()

    task.delay(duration, function()
        TweenService:Create(icon, Config.TweenInfo, {ImageTransparency = 1}):Play()
        TweenService:Create(title, Config.TweenInfo, {TextTransparency = 1}):Play()
        TweenService:Create(desc, Config.TweenInfo, {TextTransparency = 1}):Play()
        task.wait(0.3)
        
        for i, v in ipairs(self.IslandStack) do
            if v == entry then table.remove(self.IslandStack, i) break end
        end
        
        local closeTween = TweenService:Create(itemFrame, Config.TweenInfo, {Size = UDim2.new(0, width, 0, 0)})
        closeTween:Play()
        closeTween.Completed:Connect(function() 
            itemFrame:Destroy() 
            self:RecalculateIsland()
        end)
    end)
end

-- [控制中心 Tab 管理]
function AppleLib:AddTab(name)
    local tabObj = {}
    
    local sectionFrame = create("Frame", {
        Parent = self.CCScroll, Size = UDim2.new(1, 0, 0, 30),
        BackgroundTransparency = 1
    })
    local title = create("TextLabel", {
        Parent = sectionFrame, Size = UDim2.new(1, 0, 1, 0),
        Text = name:upper(), TextColor3 = Color3.fromRGB(100, 100, 110),
        Font = Enum.Font.GothamBold, TextSize = 12, TextXAlignment = Enum.TextXAlignment.Left,
        BackgroundTransparency = 1
    })
    create("UIPadding", {Parent = sectionFrame, PaddingLeft = UDim.new(0, 5)})

    self.CCScroll.CanvasSize = UDim2.new(0, 0, 0, self.CCScroll.UIListLayout.AbsoluteContentSize.Y + 40)

    -- 组件函数：Toggle
    function tabObj:AddToggle(text, default, callback)
        local frame = create("Frame", {
            Parent = sectionFrame.Parent, Size = UDim2.new(1, 0, 0, 50),
            BackgroundColor3 = Config.Colors.Button, BackgroundTransparency = 0.3
        })
        addCorner(frame, 0.2)
        
        local label = create("TextLabel", {
            Parent = frame, Position = UDim2.new(0, 15, 0, 0), Size = UDim2.new(0.6, 0, 1, 0),
            BackgroundTransparency = 1, Text = text, TextColor3 = Config.Colors.Text,
            Font = Enum.Font.GothamSemibold, TextSize = 14, TextXAlignment = Enum.TextXAlignment.Left
        })

        local toggled = default
        local btn = create("TextButton", {
            Parent = frame, AnchorPoint = Vector2.new(1, 0.5), Position = UDim2.new(1, -15, 0.5, 0),
            Size = UDim2.new(0, 45, 0, 26), BackgroundColor3 = toggled and Config.Colors.Accent or Color3.fromRGB(70, 70, 75),
            Text = ""
        })
        addCorner(btn, 1)

        local knob = create("Frame", {
            Parent = btn, Position = UDim2.new(0, toggled and 21 or 2, 0.5, -11),
            Size = UDim2.new(0, 22, 0, 22), BackgroundColor3 = Color3.fromRGB(255, 255, 255)
        })
        addCorner(knob, 1)

        btn.MouseButton1Click:Connect(function()
            toggled = not toggled
            TweenService:Create(btn, Config.TweenInfo, {BackgroundColor3 = toggled and Config.Colors.Accent or Color3.fromRGB(70, 70, 75)}):Play()
            TweenService:Create(knob, Config.TweenInfo, {Position = UDim2.new(0, toggled and 21 or 2, 0.5, -11)}):Play()
            callback(toggled)
        end)
        
        sectionFrame.Parent.CanvasSize = UDim2.new(0, 0, 0, sectionFrame.Parent.UIListLayout.AbsoluteContentSize.Y + 20)
    end

    -- 组件函数：Slider
    function tabObj:AddSlider(text, min, max, default, callback)
        local frame = create("Frame", {
            Parent = sectionFrame.Parent, Size = UDim2.new(1, 0, 0, 65),
            BackgroundColor3 = Config.Colors.Button, BackgroundTransparency = 0.3
        })
        addCorner(frame, 0.2)

        local label = create("TextLabel", {
            Parent = frame, Position = UDim2.new(0, 15, 0, 10), Size = UDim2.new(1, -30, 0, 20),
            BackgroundTransparency = 1, Text = text, TextColor3 = Config.Colors.Text,
            Font = Enum.Font.GothamSemibold, TextSize = 14, TextXAlignment = Enum.TextXAlignment.Left
        })

        local valLabel = create("TextLabel", {
            Parent = frame, Position = UDim2.new(0, 15, 0, 10), Size = UDim2.new(1, -30, 0, 20),
            BackgroundTransparency = 1, Text = tostring(default), TextColor3 = Config.Colors.SecondaryText,
            Font = Enum.Font.Gotham, TextSize = 13, TextXAlignment = Enum.TextXAlignment.Right
        })

        local slideBg = create("Frame", {
            Parent = frame, Position = UDim2.new(0, 15, 0, 40), Size = UDim2.new(1, -30, 0, 6),
            BackgroundColor3 = Color3.fromRGB(60, 60, 65)
        })
        addCorner(slideBg, 1)

        local fill = create("Frame", {
            Parent = slideBg, Size = UDim2.new((default-min)/(max-min), 0, 1, 0),
            BackgroundColor3 = Config.Colors.Accent
        })
        addCorner(fill, 1)

        local dragging = false
        local function update(input)
            local pos = math.clamp((input.Position.X - slideBg.AbsolutePosition.X) / slideBg.AbsoluteSize.X, 0, 1)
            fill.Size = UDim2.new(pos, 0, 1, 0)
            local val = math.floor(min + (max - min) * pos)
            valLabel.Text = tostring(val)
            callback(val)
        end

        slideBg.InputBegan:Connect(function(input)
            if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
                dragging = true; update(input)
            end
        end)
        UserInputService.InputEnded:Connect(function(input)
            if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
                dragging = false
            end
        end)
        UserInputService.InputChanged:Connect(function(input)
            if dragging and (input.UserInputType == Enum.UserInputType.MouseMovement or input.UserInputType == Enum.UserInputType.Touch) then
                update(input)
            end
        end)

        sectionFrame.Parent.CanvasSize = UDim2.new(0, 0, 0, sectionFrame.Parent.UIListLayout.AbsoluteContentSize.Y + 20)
    end

    -- 组件函数：Button
    function tabObj:AddButton(text, callback)
        local btn = create("TextButton", {
            Parent = sectionFrame.Parent, Size = UDim2.new(1, 0, 0, 45),
            BackgroundColor3 = Config.Colors.Button, BackgroundTransparency = 0.3,
            Text = text, TextColor3 = Config.Colors.Text, Font = Enum.Font.GothamSemibold, TextSize = 14
        })
        addCorner(btn, 0.2)
        btn.MouseButton1Click:Connect(callback)
        
        sectionFrame.Parent.CanvasSize = UDim2.new(0, 0, 0, sectionFrame.Parent.UIListLayout.AbsoluteContentSize.Y + 20)
    end

    return tabObj
end

-- [内部：交互逻辑]
function AppleLib:HandleInteractions()
    local isOpen = false
    
    local function toggleCC(state)
        isOpen = state
        if isOpen then
            self.DarkOverlay.Visible = true
            TweenService:Create(self.Blur, Config.TweenInfo, {Size = 15}):Play()
            TweenService:Create(self.DarkOverlay, Config.TweenInfo, {BackgroundTransparency = 0.4}):Play()
            TweenService:Create(self.CCFrame, Config.TweenInfo, {Position = UDim2.new(0.5, 0, 0.5, 0)}):Play()
        else
            TweenService:Create(self.Blur, Config.TweenInfo, {Size = 0}):Play()
            TweenService:Create(self.DarkOverlay, Config.TweenInfo, {BackgroundTransparency = 1}):Play()
            TweenService:Create(self.CCFrame, Config.TweenInfo, {Position = UDim2.new(0.5, 0, 1.5, 0)}):Play()
            task.delay(0.4, function() if not isOpen then self.DarkOverlay.Visible = false end end)
        end
    end

    local islandBtn = create("TextButton", {
        Parent = self.IslandContainer, Size = UDim2.new(1, 0, 1, 0),
        BackgroundTransparency = 1, Text = "", ZIndex = 1000
    })

    islandBtn.MouseButton1Click:Connect(function()
        toggleCC(not isOpen)
    end)

    self.DarkOverlay.MouseButton1Click:Connect(function()
        toggleCC(false)
    end)
end

return AppleLib
