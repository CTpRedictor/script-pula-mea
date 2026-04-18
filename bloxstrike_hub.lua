--[[
    ╔═══════════════════════════════════════════════════════════════════╗
    ║                                                                   ║
    ║              B L O X S T R I K E   D O M I N A T I O N            ║
    ║                     Premium Script Hub v2.0                       ║
    ║                                                                   ║
    ║        Auto-Updating Offsets · Modern ImGui · Full PVP Suite      ║
    ║                                                                   ║
    ╚═══════════════════════════════════════════════════════════════════╝
    
    Features:
      Combat  → Aimbot, Silent Aim, Triggerbot, No Recoil, Rapid Fire
      Visuals → ESP (Box/Name/Health/Distance/Skeleton/Tracers), Chams,
                Crosshair, FOV Circle, Fullbright, No Fog, Hit Markers
      Movement→ Bunny Hop, Speed Boost, Infinite Jump, Fly, Noclip
      Misc    → Anti-AFK, Auto-Buy Scan, Kill Sound, Third Person
      Settings→ Keybinds, Theme, Offset Status, Unload
]]

-- ═══════════════════════════════════════════════════════════════
-- [SECTION 1] SERVICES & CORE REFERENCES
-- ═══════════════════════════════════════════════════════════════

local Players            = game:GetService("Players")
local RunService         = game:GetService("RunService")
local UserInputService   = game:GetService("UserInputService")
local TweenService       = game:GetService("TweenService")
local Lighting           = game:GetService("Lighting")
local StarterGui         = game:GetService("StarterGui")
local CoreGui            = game:GetService("CoreGui")
local ReplicatedStorage  = game:GetService("ReplicatedStorage")
local Workspace          = game:GetService("Workspace")
local VirtualInputManager= game:GetService("VirtualInputManager")

local LocalPlayer = Players.LocalPlayer
local Camera      = Workspace.CurrentCamera
local Mouse       = LocalPlayer:GetMouse()

-- ═══════════════════════════════════════════════════════════════
-- [SECTION 2] AUTO-UPDATING OFFSET SYSTEM
-- ═══════════════════════════════════════════════════════════════

local OFFSETS_URL = "https://offsets.ntgetwritewatch.workers.dev/offsets_structured.hpp"
local Offsets = {}
local OffsetVersion = "unknown"
local OffsetStatus = "Fetching..."

local function FetchOffsets()
    local ok, data = pcall(function()
        return game:HttpGet(OFFSETS_URL)
    end)

    if not ok or not data then
        OffsetStatus = "Failed - Using Cache"
        return false
    end

    local parsed = {}
    local ns = nil

    for line in data:gmatch("[^\r\n]+") do
        local namespace = line:match("namespace%s+(%w+)")
        if namespace then
            ns = namespace
            parsed[ns] = parsed[ns] or {}
        end

        local name, hex = line:match("inline%s+constexpr%s+uintptr_t%s+(%w+)%s*=%s*(0x%x+)")
        if name and hex and ns then
            parsed[ns][name] = tonumber(hex)
        end
    end

    local ver = data:match("Roblox Version:%s*([%w%-]+)")
    if ver then
        OffsetVersion = ver
    end

    Offsets = parsed
    OffsetStatus = "Synced ✓ (" .. OffsetVersion .. ")"
    return true
end

-- Initial offset fetch
spawn(function()
    FetchOffsets()
    -- Re-check offsets every 5 minutes
    while wait(300) do
        FetchOffsets()
    end
end)

-- ═══════════════════════════════════════════════════════════════
-- [SECTION 3] CONFIGURATION
-- ═══════════════════════════════════════════════════════════════

local Config = {
    -- Combat
    Aimbot = {
        Enabled     = false,
        Key         = Enum.UserInputType.MouseButton2,
        Smoothing   = 5,
        FOV         = 120,
        TargetBone  = "Head",
        TeamCheck   = true,
        WallCheck   = true,
        Prediction  = false,
        PredictScale= 0.125,
        ShowFOV     = true,
    },
    SilentAim = {
        Enabled   = false,
        HitChance = 100,
        TargetBone= "Head",
        TeamCheck = true,
    },
    Triggerbot = {
        Enabled  = false,
        Delay    = 50,
        TeamCheck= true,
    },
    NoRecoil = {
        Enabled = false,
    },
    RapidFire = {
        Enabled = false,
        Speed   = 2,
    },

    -- Visuals
    ESP = {
        Enabled   = false,
        Boxes     = true,
        BoxColor  = Color3.fromRGB(0, 212, 255),
        Names     = true,
        NameColor = Color3.fromRGB(255, 255, 255),
        Health    = true,
        Distance  = true,
        Skeleton  = false,
        Tracers   = false,
        TracerOrigin = "Bottom",
        TeamCheck = true,
        TeamColor = false,
    },
    Chams = {
        Enabled        = false,
        FillColor      = Color3.fromRGB(122, 95, 255),
        OutlineColor   = Color3.fromRGB(0, 212, 255),
        FillTransparency   = 0.5,
        OutlineTransparency= 0,
        TeamCheck      = true,
    },
    Crosshair = {
        Enabled  = false,
        Size     = 6,
        Gap      = 3,
        Thickness= 1,
        Color    = Color3.fromRGB(0, 255, 128),
        Dot      = true,
    },
    FOVCircle = {
        Enabled     = false,
        Color       = Color3.fromRGB(255, 255, 255),
        Transparency= 0.7,
    },
    Fullbright = {
        Enabled = false,
    },
    NoFog = {
        Enabled = false,
    },
    HitMarkers = {
        Enabled = false,
        Color   = Color3.fromRGB(255, 50, 50),
    },

    -- Movement
    BunnyHop = {
        Enabled = false,
    },
    SpeedBoost = {
        Enabled = false,
        Speed   = 20,
    },
    InfiniteJump = {
        Enabled = false,
    },
    Fly = {
        Enabled = false,
        Speed   = 50,
    },
    Noclip = {
        Enabled = false,
    },

    -- Misc
    AntiAFK = {
        Enabled = true,
    },
    KillSound = {
        Enabled = false,
        SoundId = "rbxassetid://5765933856",
    },
    ThirdPerson = {
        Enabled = false,
        Distance= 10,
    },

    -- UI
    MenuKey = Enum.KeyCode.RightControl,
}

-- ═══════════════════════════════════════════════════════════════
-- [SECTION 4] UTILITY FUNCTIONS
-- ═══════════════════════════════════════════════════════════════

local function WorldToScreen(worldPos)
    local vec, onScreen = Camera:WorldToViewportPoint(worldPos)
    return Vector2.new(vec.X, vec.Y), onScreen, vec.Z
end

local function GetCharacter(player)
    return player and player.Character
end

local function IsAlive(player)
    local char = GetCharacter(player)
    if not char then return false end
    local hum = char:FindFirstChildOfClass("Humanoid")
    return hum and hum.Health > 0
end

local function IsEnemy(player, teamCheck)
    if player == LocalPlayer then return false end
    if not teamCheck then return true end
    if not LocalPlayer.Team or not player.Team then return true end
    return player.Team ~= LocalPlayer.Team
end

local function IsVisible(targetPart)
    if not targetPart then return false end
    local origin = Camera.CFrame.Position
    local direction = (targetPart.Position - origin)

    local params = RaycastParams.new()
    params.FilterType = Enum.RaycastFilterType.Exclude
    params.FilterDescendantsInstances = {LocalPlayer.Character}

    local result = Workspace:Raycast(origin, direction, params)
    if result then
        return result.Instance:IsDescendantOf(targetPart.Parent)
    end
    return true
end

local function GetBone(character, boneName)
    if not character then return nil end
    local part = character:FindFirstChild(boneName)
    if part then return part end
    -- Fallback search
    if boneName == "Head" then
        return character:FindFirstChild("Head")
    elseif boneName == "Torso" then
        return character:FindFirstChild("HumanoidRootPart")
            or character:FindFirstChild("UpperTorso")
            or character:FindFirstChild("Torso")
    end
    return character:FindFirstChild("HumanoidRootPart")
end

local function Lerp(a, b, t)
    return a + (b - a) * t
end

local function GetScreenCenter()
    local viewport = Camera.ViewportSize
    return Vector2.new(viewport.X / 2, viewport.Y / 2)
end

local function Clamp(val, min, max)
    return math.clamp(val, min, max)
end

-- ═══════════════════════════════════════════════════════════════
-- [SECTION 5] DRAWING MANAGER
-- ═══════════════════════════════════════════════════════════════

local DrawingCache = {}

local function CreateDrawing(class, props)
    local obj = Drawing.new(class)
    for k, v in pairs(props) do
        obj[k] = v
    end
    return obj
end

local function ClearPlayerDrawings(player)
    local cache = DrawingCache[player]
    if not cache then return end
    for _, drawing in pairs(cache) do
        if typeof(drawing) == "table" then
            for _, d in pairs(drawing) do
                pcall(function() d:Remove() end)
            end
        else
            pcall(function() drawing:Remove() end)
        end
    end
    DrawingCache[player] = nil
end

local function ClearAllDrawings()
    for player, _ in pairs(DrawingCache) do
        ClearPlayerDrawings(player)
    end
end

-- ═══════════════════════════════════════════════════════════════
-- [SECTION 6] NOTIFICATION SYSTEM
-- ═══════════════════════════════════════════════════════════════

local NotificationQueue = {}

local function CreateNotificationGui()
    local notifHolder = Instance.new("Frame")
    notifHolder.Name = "NotifHolder"
    notifHolder.Size = UDim2.new(0, 300, 1, 0)
    notifHolder.Position = UDim2.new(1, -320, 0, 0)
    notifHolder.BackgroundTransparency = 1
    notifHolder.ZIndex = 100

    local layout = Instance.new("UIListLayout")
    layout.SortOrder = Enum.SortOrder.LayoutOrder
    layout.Padding = UDim.new(0, 8)
    layout.VerticalAlignment = Enum.VerticalAlignment.Bottom
    layout.Parent = notifHolder

    local padding = Instance.new("UIPadding")
    padding.PaddingBottom = UDim.new(0, 20)
    padding.Parent = notifHolder

    return notifHolder
end

local NotifHolder = nil

local function Notify(title, message, duration)
    duration = duration or 3
    if not NotifHolder or not NotifHolder.Parent then return end

    local notif = Instance.new("Frame")
    notif.Size = UDim2.new(1, 0, 0, 60)
    notif.BackgroundColor3 = Color3.fromRGB(22, 27, 34)
    notif.BorderSizePixel = 0
    notif.BackgroundTransparency = 0.05
    notif.ClipsDescendants = true
    notif.Parent = NotifHolder

    local corner = Instance.new("UICorner")
    corner.CornerRadius = UDim.new(0, 8)
    corner.Parent = notif

    local stroke = Instance.new("UIStroke")
    stroke.Color = Color3.fromRGB(48, 54, 61)
    stroke.Thickness = 1
    stroke.Parent = notif

    local accent = Instance.new("Frame")
    accent.Size = UDim2.new(0, 3, 1, 0)
    accent.BackgroundColor3 = Color3.fromRGB(0, 212, 255)
    accent.BorderSizePixel = 0
    accent.Parent = notif

    local titleLabel = Instance.new("TextLabel")
    titleLabel.Text = title
    titleLabel.Font = Enum.Font.GothamBold
    titleLabel.TextSize = 13
    titleLabel.TextColor3 = Color3.fromRGB(230, 237, 243)
    titleLabel.BackgroundTransparency = 1
    titleLabel.Position = UDim2.new(0, 14, 0, 8)
    titleLabel.Size = UDim2.new(1, -20, 0, 18)
    titleLabel.TextXAlignment = Enum.TextXAlignment.Left
    titleLabel.Parent = notif

    local msgLabel = Instance.new("TextLabel")
    msgLabel.Text = message
    msgLabel.Font = Enum.Font.Gotham
    msgLabel.TextSize = 11
    msgLabel.TextColor3 = Color3.fromRGB(139, 148, 158)
    msgLabel.BackgroundTransparency = 1
    msgLabel.Position = UDim2.new(0, 14, 0, 28)
    msgLabel.Size = UDim2.new(1, -20, 0, 24)
    msgLabel.TextXAlignment = Enum.TextXAlignment.Left
    msgLabel.TextWrapped = true
    msgLabel.Parent = notif

    -- Slide in
    notif.Position = UDim2.new(1, 0, 0, 0)
    TweenService:Create(notif, TweenInfo.new(0.3, Enum.EasingStyle.Quart, Enum.EasingDirection.Out), {
        Position = UDim2.new(0, 0, 0, 0)
    }):Play()

    -- Fade out after duration
    spawn(function()
        wait(duration)
        local tween = TweenService:Create(notif, TweenInfo.new(0.4, Enum.EasingStyle.Quart, Enum.EasingDirection.In), {
            Position = UDim2.new(1, 0, 0, 0),
            BackgroundTransparency = 1
        })
        tween:Play()
        tween.Completed:Wait()
        notif:Destroy()
    end)
end

-- ═══════════════════════════════════════════════════════════════
-- [SECTION 7] IMGUI UI SYSTEM
-- ═══════════════════════════════════════════════════════════════

local UI = {}
UI.Tabs = {}
UI.Elements = {}
UI.ScreenGui = nil
UI.MainFrame = nil
UI.ContentFrame = nil
UI.ActiveTab = nil
UI.Visible = true
UI.Connections = {}

-- Theme colors
local Theme = {
    Background      = Color3.fromRGB(13, 17, 23),
    Surface         = Color3.fromRGB(22, 27, 34),
    SurfaceLight    = Color3.fromRGB(33, 38, 45),
    Border          = Color3.fromRGB(48, 54, 61),
    Accent          = Color3.fromRGB(0, 212, 255),
    AccentSecondary = Color3.fromRGB(122, 95, 255),
    Text            = Color3.fromRGB(230, 237, 243),
    TextMuted       = Color3.fromRGB(139, 148, 158),
    Success         = Color3.fromRGB(63, 185, 80),
    Error           = Color3.fromRGB(248, 81, 73),
    Warning         = Color3.fromRGB(210, 153, 34),
    ToggleOff       = Color3.fromRGB(55, 60, 68),
    ToggleOn        = Color3.fromRGB(0, 212, 255),
}

function UI:Init()
    -- Cleanup old UI if exists
    local existing = CoreGui:FindFirstChild("BloxStrikeDom")
    if existing then existing:Destroy() end

    self.ScreenGui = Instance.new("ScreenGui")
    self.ScreenGui.Name = "BloxStrikeDom"
    self.ScreenGui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
    self.ScreenGui.ResetOnSpawn = false
    self.ScreenGui.Parent = CoreGui

    -- Notification holder
    NotifHolder = CreateNotificationGui()
    NotifHolder.Parent = self.ScreenGui

    -- Main window
    self.MainFrame = Instance.new("Frame")
    self.MainFrame.Name = "MainWindow"
    self.MainFrame.Size = UDim2.new(0, 580, 0, 420)
    self.MainFrame.Position = UDim2.new(0.5, -290, 0.5, -210)
    self.MainFrame.BackgroundColor3 = Theme.Background
    self.MainFrame.BorderSizePixel = 0
    self.MainFrame.ClipsDescendants = true
    self.MainFrame.Parent = self.ScreenGui

    local mainCorner = Instance.new("UICorner")
    mainCorner.CornerRadius = UDim.new(0, 10)
    mainCorner.Parent = self.MainFrame

    local mainStroke = Instance.new("UIStroke")
    mainStroke.Color = Theme.Border
    mainStroke.Thickness = 1
    mainStroke.Parent = self.MainFrame

    -- Drop shadow (simulated)
    local shadow = Instance.new("ImageLabel")
    shadow.Name = "Shadow"
    shadow.Size = UDim2.new(1, 30, 1, 30)
    shadow.Position = UDim2.new(0, -15, 0, -15)
    shadow.BackgroundTransparency = 1
    shadow.Image = "rbxassetid://6014261993"
    shadow.ImageColor3 = Color3.fromRGB(0, 0, 0)
    shadow.ImageTransparency = 0.5
    shadow.ScaleType = Enum.ScaleType.Slice
    shadow.SliceCenter = Rect.new(49, 49, 450, 450)
    shadow.ZIndex = -1
    shadow.Parent = self.MainFrame

    -- Title bar
    local titleBar = Instance.new("Frame")
    titleBar.Name = "TitleBar"
    titleBar.Size = UDim2.new(1, 0, 0, 40)
    titleBar.BackgroundColor3 = Theme.Surface
    titleBar.BorderSizePixel = 0
    titleBar.Parent = self.MainFrame

    local tbCorner = Instance.new("UICorner")
    tbCorner.CornerRadius = UDim.new(0, 10)
    tbCorner.Parent = titleBar

    -- Bottom corners fix for title bar
    local tbFix = Instance.new("Frame")
    tbFix.Size = UDim2.new(1, 0, 0, 12)
    tbFix.Position = UDim2.new(0, 0, 1, -12)
    tbFix.BackgroundColor3 = Theme.Surface
    tbFix.BorderSizePixel = 0
    tbFix.Parent = titleBar

    -- Title gradient accent line
    local accentLine = Instance.new("Frame")
    accentLine.Size = UDim2.new(1, 0, 0, 2)
    accentLine.Position = UDim2.new(0, 0, 1, 0)
    accentLine.BorderSizePixel = 0
    accentLine.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
    accentLine.Parent = titleBar

    local accentGrad = Instance.new("UIGradient")
    accentGrad.Color = ColorSequence.new({
        ColorSequenceKeypoint.new(0, Theme.Accent),
        ColorSequenceKeypoint.new(0.5, Theme.AccentSecondary),
        ColorSequenceKeypoint.new(1, Theme.Accent),
    })
    accentGrad.Parent = accentLine

    -- Animate the gradient
    spawn(function()
        local offset = 0
        while self.ScreenGui and self.ScreenGui.Parent do
            offset = (offset + 0.005) % 1
            accentGrad.Offset = Vector2.new(math.sin(offset * math.pi * 2) * 0.3, 0)
            RunService.RenderStepped:Wait()
        end
    end)

    -- Title text
    local titleText = Instance.new("TextLabel")
    titleText.Text = "⚡ BLOXSTRIKE DOMINATION"
    titleText.Font = Enum.Font.GothamBold
    titleText.TextSize = 14
    titleText.TextColor3 = Theme.Text
    titleText.BackgroundTransparency = 1
    titleText.Position = UDim2.new(0, 14, 0, 0)
    titleText.Size = UDim2.new(0.6, 0, 1, 0)
    titleText.TextXAlignment = Enum.TextXAlignment.Left
    titleText.Parent = titleBar

    -- Version badge
    local vBadge = Instance.new("TextLabel")
    vBadge.Text = "v2.0"
    vBadge.Font = Enum.Font.GothamBold
    vBadge.TextSize = 10
    vBadge.TextColor3 = Theme.Accent
    vBadge.BackgroundColor3 = Color3.fromRGB(0, 212, 255)
    vBadge.BackgroundTransparency = 0.85
    vBadge.Position = UDim2.new(0, 220, 0.5, -9)
    vBadge.Size = UDim2.new(0, 32, 0, 18)
    vBadge.Parent = titleBar

    local vbCorner = Instance.new("UICorner")
    vbCorner.CornerRadius = UDim.new(0, 4)
    vbCorner.Parent = vBadge

    -- Close button
    local closeBtn = Instance.new("TextButton")
    closeBtn.Text = "✕"
    closeBtn.Font = Enum.Font.GothamBold
    closeBtn.TextSize = 14
    closeBtn.TextColor3 = Theme.TextMuted
    closeBtn.BackgroundTransparency = 1
    closeBtn.Position = UDim2.new(1, -36, 0, 0)
    closeBtn.Size = UDim2.new(0, 36, 1, 0)
    closeBtn.Parent = titleBar

    closeBtn.MouseButton1Click:Connect(function()
        self:Toggle()
    end)

    closeBtn.MouseEnter:Connect(function()
        TweenService:Create(closeBtn, TweenInfo.new(0.15), {TextColor3 = Theme.Error}):Play()
    end)
    closeBtn.MouseLeave:Connect(function()
        TweenService:Create(closeBtn, TweenInfo.new(0.15), {TextColor3 = Theme.TextMuted}):Play()
    end)

    -- Minimize button
    local minBtn = Instance.new("TextButton")
    minBtn.Text = "─"
    minBtn.Font = Enum.Font.GothamBold
    minBtn.TextSize = 14
    minBtn.TextColor3 = Theme.TextMuted
    minBtn.BackgroundTransparency = 1
    minBtn.Position = UDim2.new(1, -68, 0, 0)
    minBtn.Size = UDim2.new(0, 32, 1, 0)
    minBtn.Parent = titleBar

    minBtn.MouseEnter:Connect(function()
        TweenService:Create(minBtn, TweenInfo.new(0.15), {TextColor3 = Theme.Warning}):Play()
    end)
    minBtn.MouseLeave:Connect(function()
        TweenService:Create(minBtn, TweenInfo.new(0.15), {TextColor3 = Theme.TextMuted}):Play()
    end)

    -- Dragging
    local dragging, dragStart, startPos
    titleBar.InputBegan:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 then
            dragging = true
            dragStart = input.Position
            startPos = self.MainFrame.Position
        end
    end)
    titleBar.InputEnded:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 then
            dragging = false
        end
    end)
    UserInputService.InputChanged:Connect(function(input)
        if dragging and input.UserInputType == Enum.UserInputType.MouseMovement then
            local delta = input.Position - dragStart
            self.MainFrame.Position = UDim2.new(
                startPos.X.Scale, startPos.X.Offset + delta.X,
                startPos.Y.Scale, startPos.Y.Offset + delta.Y
            )
        end
    end)

    -- Tab sidebar
    local sidebar = Instance.new("Frame")
    sidebar.Name = "Sidebar"
    sidebar.Size = UDim2.new(0, 140, 1, -42)
    sidebar.Position = UDim2.new(0, 0, 0, 42)
    sidebar.BackgroundColor3 = Theme.Surface
    sidebar.BorderSizePixel = 0
    sidebar.Parent = self.MainFrame

    local sidebarBorder = Instance.new("Frame")
    sidebarBorder.Size = UDim2.new(0, 1, 1, 0)
    sidebarBorder.Position = UDim2.new(1, 0, 0, 0)
    sidebarBorder.BackgroundColor3 = Theme.Border
    sidebarBorder.BorderSizePixel = 0
    sidebarBorder.Parent = sidebar

    local tabLayout = Instance.new("UIListLayout")
    tabLayout.SortOrder = Enum.SortOrder.LayoutOrder
    tabLayout.Padding = UDim.new(0, 2)
    tabLayout.Parent = sidebar

    local tabPadding = Instance.new("UIPadding")
    tabPadding.PaddingTop = UDim.new(0, 8)
    tabPadding.PaddingLeft = UDim.new(0, 6)
    tabPadding.PaddingRight = UDim.new(0, 6)
    tabPadding.Parent = sidebar

    self.Sidebar = sidebar

    -- Content area
    self.ContentFrame = Instance.new("Frame")
    self.ContentFrame.Name = "Content"
    self.ContentFrame.Size = UDim2.new(1, -141, 1, -42)
    self.ContentFrame.Position = UDim2.new(0, 141, 0, 42)
    self.ContentFrame.BackgroundTransparency = 1
    self.ContentFrame.Parent = self.MainFrame

    -- Status bar
    local statusBar = Instance.new("Frame")
    statusBar.Name = "StatusBar"
    statusBar.Size = UDim2.new(1, 0, 0, 24)
    statusBar.Position = UDim2.new(0, 0, 1, -24)
    statusBar.BackgroundColor3 = Theme.Surface
    statusBar.BorderSizePixel = 0
    statusBar.ZIndex = 5
    statusBar.Parent = self.MainFrame

    local statusText = Instance.new("TextLabel")
    statusText.Name = "StatusText"
    statusText.Text = "  Offsets: " .. OffsetStatus .. "  |  Press RightCtrl to toggle"
    statusText.Font = Enum.Font.Gotham
    statusText.TextSize = 10
    statusText.TextColor3 = Theme.TextMuted
    statusText.BackgroundTransparency = 1
    statusText.Size = UDim2.new(1, 0, 1, 0)
    statusText.TextXAlignment = Enum.TextXAlignment.Left
    statusText.Parent = statusBar

    self.StatusText = statusText

    -- Update status text periodically
    spawn(function()
        while self.ScreenGui and self.ScreenGui.Parent do
            if self.StatusText then
                self.StatusText.Text = "  Offsets: " .. OffsetStatus .. "  |  RightCtrl to toggle"
            end
            wait(5)
        end
    end)

    return self
end

function UI:CreateTab(name, icon, order)
    local tabBtn = Instance.new("TextButton")
    tabBtn.Name = "Tab_" .. name
    tabBtn.Size = UDim2.new(1, 0, 0, 34)
    tabBtn.BackgroundColor3 = Theme.SurfaceLight
    tabBtn.BackgroundTransparency = 1
    tabBtn.BorderSizePixel = 0
    tabBtn.Text = ""
    tabBtn.LayoutOrder = order or #self.Tabs + 1
    tabBtn.AutoButtonColor = false
    tabBtn.Parent = self.Sidebar

    local btnCorner = Instance.new("UICorner")
    btnCorner.CornerRadius = UDim.new(0, 6)
    btnCorner.Parent = tabBtn

    local tabIcon = Instance.new("TextLabel")
    tabIcon.Text = icon or "●"
    tabIcon.Font = Enum.Font.Gotham
    tabIcon.TextSize = 14
    tabIcon.TextColor3 = Theme.TextMuted
    tabIcon.BackgroundTransparency = 1
    tabIcon.Position = UDim2.new(0, 8, 0, 0)
    tabIcon.Size = UDim2.new(0, 24, 1, 0)
    tabIcon.Parent = tabBtn

    local tabLabel = Instance.new("TextLabel")
    tabLabel.Text = name
    tabLabel.Font = Enum.Font.GothamMedium
    tabLabel.TextSize = 12
    tabLabel.TextColor3 = Theme.TextMuted
    tabLabel.BackgroundTransparency = 1
    tabLabel.Position = UDim2.new(0, 36, 0, 0)
    tabLabel.Size = UDim2.new(1, -40, 1, 0)
    tabLabel.TextXAlignment = Enum.TextXAlignment.Left
    tabLabel.Parent = tabBtn

    -- Active indicator
    local indicator = Instance.new("Frame")
    indicator.Size = UDim2.new(0, 3, 0.6, 0)
    indicator.Position = UDim2.new(0, 0, 0.2, 0)
    indicator.BackgroundColor3 = Theme.Accent
    indicator.BorderSizePixel = 0
    indicator.Visible = false
    indicator.Parent = tabBtn

    local indCorner = Instance.new("UICorner")
    indCorner.CornerRadius = UDim.new(0, 2)
    indCorner.Parent = indicator

    -- Tab content (ScrollingFrame)
    local content = Instance.new("ScrollingFrame")
    content.Name = "TabContent_" .. name
    content.Size = UDim2.new(1, -16, 1, -32)
    content.Position = UDim2.new(0, 8, 0, 8)
    content.BackgroundTransparency = 1
    content.ScrollBarThickness = 3
    content.ScrollBarImageColor3 = Theme.AccentSecondary
    content.BorderSizePixel = 0
    content.CanvasSize = UDim2.new(0, 0, 0, 0)
    content.Visible = false
    content.Parent = self.ContentFrame

    local contentLayout = Instance.new("UIListLayout")
    contentLayout.SortOrder = Enum.SortOrder.LayoutOrder
    contentLayout.Padding = UDim.new(0, 4)
    contentLayout.Parent = content

    -- Auto-resize canvas
    contentLayout:GetPropertyChangedSignal("AbsoluteContentSize"):Connect(function()
        content.CanvasSize = UDim2.new(0, 0, 0, contentLayout.AbsoluteContentSize.Y + 16)
    end)

    local tabData = {
        Button    = tabBtn,
        Content   = content,
        Indicator = indicator,
        IconLabel = tabIcon,
        TextLabel = tabLabel,
        Name      = name,
    }

    -- Tab click handler
    tabBtn.MouseButton1Click:Connect(function()
        self:SelectTab(name)
    end)

    tabBtn.MouseEnter:Connect(function()
        if self.ActiveTab ~= name then
            TweenService:Create(tabBtn, TweenInfo.new(0.15), {BackgroundTransparency = 0.6}):Play()
        end
    end)
    tabBtn.MouseLeave:Connect(function()
        if self.ActiveTab ~= name then
            TweenService:Create(tabBtn, TweenInfo.new(0.15), {BackgroundTransparency = 1}):Play()
        end
    end)

    table.insert(self.Tabs, tabData)
    return tabData
end

function UI:SelectTab(name)
    for _, tab in ipairs(self.Tabs) do
        local isActive = tab.Name == name
        tab.Content.Visible = isActive
        tab.Indicator.Visible = isActive

        local targetTransparency = isActive and 0.7 or 1
        local targetTextColor = isActive and Theme.Text or Theme.TextMuted
        local targetIconColor = isActive and Theme.Accent or Theme.TextMuted

        TweenService:Create(tab.Button, TweenInfo.new(0.2), {BackgroundTransparency = targetTransparency}):Play()
        TweenService:Create(tab.TextLabel, TweenInfo.new(0.2), {TextColor3 = targetTextColor}):Play()
        TweenService:Create(tab.IconLabel, TweenInfo.new(0.2), {TextColor3 = targetIconColor}):Play()
    end
    self.ActiveTab = name
end

function UI:CreateSection(tabData, title)
    local section = Instance.new("Frame")
    section.Size = UDim2.new(1, 0, 0, 26)
    section.BackgroundTransparency = 1
    section.LayoutOrder = #tabData.Content:GetChildren() * 10
    section.Parent = tabData.Content

    local line = Instance.new("Frame")
    line.Size = UDim2.new(1, 0, 0, 1)
    line.Position = UDim2.new(0, 0, 0.5, 0)
    line.BackgroundColor3 = Theme.Border
    line.BorderSizePixel = 0
    line.Parent = section

    local label = Instance.new("TextLabel")
    label.Text = "  " .. title .. "  "
    label.Font = Enum.Font.GothamBold
    label.TextSize = 10
    label.TextColor3 = Theme.AccentSecondary
    label.BackgroundColor3 = Theme.Background
    label.Position = UDim2.new(0, 12, 0, 5)
    label.Size = UDim2.new(0, 0, 0, 16)
    label.AutomaticSize = Enum.AutomaticSize.X
    label.TextTransparency = 0
    label.Parent = section

    return section
end

function UI:CreateToggle(tabData, name, configTable, configKey, callback)
    local frame = Instance.new("Frame")
    frame.Size = UDim2.new(1, 0, 0, 32)
    frame.BackgroundColor3 = Theme.SurfaceLight
    frame.BackgroundTransparency = 0.3
    frame.BorderSizePixel = 0
    frame.LayoutOrder = #tabData.Content:GetChildren() * 10
    frame.Parent = tabData.Content

    local fCorner = Instance.new("UICorner")
    fCorner.CornerRadius = UDim.new(0, 6)
    fCorner.Parent = frame

    local label = Instance.new("TextLabel")
    label.Text = name
    label.Font = Enum.Font.Gotham
    label.TextSize = 12
    label.TextColor3 = Theme.Text
    label.BackgroundTransparency = 1
    label.Position = UDim2.new(0, 12, 0, 0)
    label.Size = UDim2.new(1, -70, 1, 0)
    label.TextXAlignment = Enum.TextXAlignment.Left
    label.Parent = frame

    -- Toggle switch
    local toggleBg = Instance.new("Frame")
    toggleBg.Size = UDim2.new(0, 40, 0, 20)
    toggleBg.Position = UDim2.new(1, -52, 0.5, -10)
    toggleBg.BackgroundColor3 = configTable[configKey] and Theme.ToggleOn or Theme.ToggleOff
    toggleBg.BorderSizePixel = 0
    toggleBg.Parent = frame

    local tCorner = Instance.new("UICorner")
    tCorner.CornerRadius = UDim.new(1, 0)
    tCorner.Parent = toggleBg

    local knob = Instance.new("Frame")
    knob.Size = UDim2.new(0, 16, 0, 16)
    knob.Position = configTable[configKey] and UDim2.new(1, -18, 0.5, -8) or UDim2.new(0, 2, 0.5, -8)
    knob.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
    knob.BorderSizePixel = 0
    knob.Parent = toggleBg

    local kCorner = Instance.new("UICorner")
    kCorner.CornerRadius = UDim.new(1, 0)
    kCorner.Parent = knob

    -- Glow effect when on
    local glow = Instance.new("ImageLabel")
    glow.Size = UDim2.new(0, 50, 0, 30)
    glow.Position = UDim2.new(0.5, -25, 0.5, -15)
    glow.BackgroundTransparency = 1
    glow.Image = "rbxassetid://5028857084"
    glow.ImageColor3 = Theme.ToggleOn
    glow.ImageTransparency = configTable[configKey] and 0.7 or 1
    glow.Parent = toggleBg

    -- Click handler
    local btn = Instance.new("TextButton")
    btn.Size = UDim2.new(1, 0, 1, 0)
    btn.BackgroundTransparency = 1
    btn.Text = ""
    btn.Parent = frame

    btn.MouseButton1Click:Connect(function()
        configTable[configKey] = not configTable[configKey]
        local enabled = configTable[configKey]

        TweenService:Create(toggleBg, TweenInfo.new(0.2, Enum.EasingStyle.Quart), {
            BackgroundColor3 = enabled and Theme.ToggleOn or Theme.ToggleOff
        }):Play()

        TweenService:Create(knob, TweenInfo.new(0.2, Enum.EasingStyle.Quart), {
            Position = enabled and UDim2.new(1, -18, 0.5, -8) or UDim2.new(0, 2, 0.5, -8)
        }):Play()

        TweenService:Create(glow, TweenInfo.new(0.2), {
            ImageTransparency = enabled and 0.7 or 1
        }):Play()

        if callback then callback(enabled) end
    end)

    -- Hover effect
    btn.MouseEnter:Connect(function()
        TweenService:Create(frame, TweenInfo.new(0.15), {BackgroundTransparency = 0.1}):Play()
    end)
    btn.MouseLeave:Connect(function()
        TweenService:Create(frame, TweenInfo.new(0.15), {BackgroundTransparency = 0.3}):Play()
    end)

    return frame
end

function UI:CreateSlider(tabData, name, min, max, configTable, configKey, callback)
    local frame = Instance.new("Frame")
    frame.Size = UDim2.new(1, 0, 0, 46)
    frame.BackgroundColor3 = Theme.SurfaceLight
    frame.BackgroundTransparency = 0.3
    frame.BorderSizePixel = 0
    frame.LayoutOrder = #tabData.Content:GetChildren() * 10
    frame.Parent = tabData.Content

    local fCorner = Instance.new("UICorner")
    fCorner.CornerRadius = UDim.new(0, 6)
    fCorner.Parent = frame

    local label = Instance.new("TextLabel")
    label.Text = name
    label.Font = Enum.Font.Gotham
    label.TextSize = 12
    label.TextColor3 = Theme.Text
    label.BackgroundTransparency = 1
    label.Position = UDim2.new(0, 12, 0, 2)
    label.Size = UDim2.new(1, -70, 0, 20)
    label.TextXAlignment = Enum.TextXAlignment.Left
    label.Parent = frame

    local valueLabel = Instance.new("TextLabel")
    valueLabel.Text = tostring(configTable[configKey])
    valueLabel.Font = Enum.Font.GothamBold
    valueLabel.TextSize = 11
    valueLabel.TextColor3 = Theme.Accent
    valueLabel.BackgroundTransparency = 1
    valueLabel.Position = UDim2.new(1, -55, 0, 2)
    valueLabel.Size = UDim2.new(0, 45, 0, 20)
    valueLabel.TextXAlignment = Enum.TextXAlignment.Right
    valueLabel.Parent = frame

    -- Slider track
    local track = Instance.new("Frame")
    track.Size = UDim2.new(1, -24, 0, 6)
    track.Position = UDim2.new(0, 12, 0, 30)
    track.BackgroundColor3 = Theme.Border
    track.BorderSizePixel = 0
    track.Parent = frame

    local trackCorner = Instance.new("UICorner")
    trackCorner.CornerRadius = UDim.new(1, 0)
    trackCorner.Parent = track

    -- Fill
    local fill = Instance.new("Frame")
    local pct = (configTable[configKey] - min) / (max - min)
    fill.Size = UDim2.new(math.clamp(pct, 0, 1), 0, 1, 0)
    fill.BackgroundColor3 = Theme.Accent
    fill.BorderSizePixel = 0
    fill.Parent = track

    local fillCorner = Instance.new("UICorner")
    fillCorner.CornerRadius = UDim.new(1, 0)
    fillCorner.Parent = fill

    local fillGrad = Instance.new("UIGradient")
    fillGrad.Color = ColorSequence.new({
        ColorSequenceKeypoint.new(0, Theme.Accent),
        ColorSequenceKeypoint.new(1, Theme.AccentSecondary),
    })
    fillGrad.Parent = fill

    -- Slider interaction
    local sliderBtn = Instance.new("TextButton")
    sliderBtn.Size = UDim2.new(1, 0, 0, 20)
    sliderBtn.Position = UDim2.new(0, 0, 0, 22)
    sliderBtn.BackgroundTransparency = 1
    sliderBtn.Text = ""
    sliderBtn.Parent = frame

    local sliding = false

    local function updateSlider(inputX)
        local trackAbsPos = track.AbsolutePosition.X
        local trackAbsSize = track.AbsoluteSize.X
        local relative = math.clamp((inputX - trackAbsPos) / trackAbsSize, 0, 1)
        local value = math.floor(min + (max - min) * relative)
        configTable[configKey] = value
        valueLabel.Text = tostring(value)
        fill.Size = UDim2.new(relative, 0, 1, 0)
        if callback then callback(value) end
    end

    sliderBtn.InputBegan:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 then
            sliding = true
            updateSlider(input.Position.X)
        end
    end)
    sliderBtn.InputEnded:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 then
            sliding = false
        end
    end)
    UserInputService.InputChanged:Connect(function(input)
        if sliding and input.UserInputType == Enum.UserInputType.MouseMovement then
            updateSlider(input.Position.X)
        end
    end)

    return frame
end

function UI:CreateDropdown(tabData, name, options, configTable, configKey, callback)
    local frame = Instance.new("Frame")
    frame.Size = UDim2.new(1, 0, 0, 32)
    frame.BackgroundColor3 = Theme.SurfaceLight
    frame.BackgroundTransparency = 0.3
    frame.BorderSizePixel = 0
    frame.ClipsDescendants = false
    frame.LayoutOrder = #tabData.Content:GetChildren() * 10
    frame.ZIndex = 5
    frame.Parent = tabData.Content

    local fCorner = Instance.new("UICorner")
    fCorner.CornerRadius = UDim.new(0, 6)
    fCorner.Parent = frame

    local label = Instance.new("TextLabel")
    label.Text = name
    label.Font = Enum.Font.Gotham
    label.TextSize = 12
    label.TextColor3 = Theme.Text
    label.BackgroundTransparency = 1
    label.Position = UDim2.new(0, 12, 0, 0)
    label.Size = UDim2.new(0.5, 0, 1, 0)
    label.TextXAlignment = Enum.TextXAlignment.Left
    label.ZIndex = 5
    label.Parent = frame

    local selectedBtn = Instance.new("TextButton")
    selectedBtn.Text = tostring(configTable[configKey]) .. " ▾"
    selectedBtn.Font = Enum.Font.GothamMedium
    selectedBtn.TextSize = 11
    selectedBtn.TextColor3 = Theme.Accent
    selectedBtn.BackgroundColor3 = Theme.Background
    selectedBtn.Position = UDim2.new(1, -130, 0.5, -12)
    selectedBtn.Size = UDim2.new(0, 118, 0, 24)
    selectedBtn.AutoButtonColor = false
    selectedBtn.ZIndex = 5
    selectedBtn.Parent = frame

    local sbCorner = Instance.new("UICorner")
    sbCorner.CornerRadius = UDim.new(0, 4)
    sbCorner.Parent = selectedBtn

    local dropdown = Instance.new("Frame")
    dropdown.Size = UDim2.new(0, 118, 0, #options * 26 + 4)
    dropdown.Position = UDim2.new(1, -130, 1, 2)
    dropdown.BackgroundColor3 = Theme.Surface
    dropdown.BorderSizePixel = 0
    dropdown.Visible = false
    dropdown.ZIndex = 50
    dropdown.Parent = frame

    local ddCorner = Instance.new("UICorner")
    ddCorner.CornerRadius = UDim.new(0, 6)
    ddCorner.Parent = dropdown

    local ddStroke = Instance.new("UIStroke")
    ddStroke.Color = Theme.Border
    ddStroke.Thickness = 1
    ddStroke.Parent = dropdown

    local ddLayout = Instance.new("UIListLayout")
    ddLayout.Padding = UDim.new(0, 0)
    ddLayout.Parent = dropdown

    local ddPad = Instance.new("UIPadding")
    ddPad.PaddingTop = UDim.new(0, 2)
    ddPad.PaddingBottom = UDim.new(0, 2)
    ddPad.Parent = dropdown

    for _, opt in ipairs(options) do
        local optBtn = Instance.new("TextButton")
        optBtn.Text = tostring(opt)
        optBtn.Font = Enum.Font.Gotham
        optBtn.TextSize = 11
        optBtn.TextColor3 = Theme.Text
        optBtn.BackgroundTransparency = 1
        optBtn.Size = UDim2.new(1, 0, 0, 26)
        optBtn.AutoButtonColor = false
        optBtn.ZIndex = 51
        optBtn.Parent = dropdown

        optBtn.MouseEnter:Connect(function()
            optBtn.BackgroundTransparency = 0.6
            optBtn.BackgroundColor3 = Theme.Accent
        end)
        optBtn.MouseLeave:Connect(function()
            optBtn.BackgroundTransparency = 1
        end)

        optBtn.MouseButton1Click:Connect(function()
            configTable[configKey] = opt
            selectedBtn.Text = tostring(opt) .. " ▾"
            dropdown.Visible = false
            if callback then callback(opt) end
        end)
    end

    selectedBtn.MouseButton1Click:Connect(function()
        dropdown.Visible = not dropdown.Visible
    end)

    return frame
end

function UI:CreateButton(tabData, name, callback)
    local btn = Instance.new("TextButton")
    btn.Size = UDim2.new(1, 0, 0, 32)
    btn.BackgroundColor3 = Theme.AccentSecondary
    btn.BackgroundTransparency = 0.6
    btn.BorderSizePixel = 0
    btn.Text = name
    btn.Font = Enum.Font.GothamBold
    btn.TextSize = 12
    btn.TextColor3 = Theme.Text
    btn.AutoButtonColor = false
    btn.LayoutOrder = #tabData.Content:GetChildren() * 10
    btn.Parent = tabData.Content

    local bCorner = Instance.new("UICorner")
    bCorner.CornerRadius = UDim.new(0, 6)
    bCorner.Parent = btn

    btn.MouseEnter:Connect(function()
        TweenService:Create(btn, TweenInfo.new(0.15), {BackgroundTransparency = 0.3}):Play()
    end)
    btn.MouseLeave:Connect(function()
        TweenService:Create(btn, TweenInfo.new(0.15), {BackgroundTransparency = 0.6}):Play()
    end)
    btn.MouseButton1Click:Connect(function()
        if callback then callback() end
    end)

    return btn
end

function UI:Toggle()
    self.Visible = not self.Visible
    self.MainFrame.Visible = self.Visible
end

function UI:Destroy()
    if self.ScreenGui then
        self.ScreenGui:Destroy()
    end
    for _, conn in pairs(self.Connections) do
        pcall(function() conn:Disconnect() end)
    end
end

-- ═══════════════════════════════════════════════════════════════
-- [SECTION 8] FEATURE IMPLEMENTATIONS
-- ═══════════════════════════════════════════════════════════════

local Features = {}
Features.Connections = {}
Features.AimbotTarget = nil
Features.FlyBody = nil
Features.OriginalLighting = {}
Features.ChamsCache = {}
Features.ESPDrawings = {}

-- ─── AIMBOT ──────────────────────────────────────────────────

function Features:GetClosestPlayer()
    local fov = Config.Aimbot.FOV
    local closest = nil
    local closestDist = fov

    for _, player in ipairs(Players:GetPlayers()) do
        if player ~= LocalPlayer and IsAlive(player) and IsEnemy(player, Config.Aimbot.TeamCheck) then
            local char = GetCharacter(player)
            local bone = GetBone(char, Config.Aimbot.TargetBone)
            if bone then
                local screenPos, onScreen = WorldToScreen(bone.Position)
                if onScreen then
                    local mousePos = UserInputService:GetMouseLocation()
                    local dist = (screenPos - mousePos).Magnitude
                    if dist < closestDist then
                        if not Config.Aimbot.WallCheck or IsVisible(bone) then
                            closest = bone
                            closestDist = dist
                        end
                    end
                end
            end
        end
    end

    return closest
end

function Features:RunAimbot()
    if not Config.Aimbot.Enabled then return end

    local isHolding = UserInputService:IsMouseButtonPressed(Enum.UserInputType.MouseButton2)
    if not isHolding then
        self.AimbotTarget = nil
        return
    end

    local target = self:GetClosestPlayer()
    if not target then return end

    self.AimbotTarget = target

    local targetPos = target.Position
    if Config.Aimbot.Prediction and target.Parent then
        local hrp = target.Parent:FindFirstChild("HumanoidRootPart")
        if hrp then
            targetPos = targetPos + hrp.AssemblyLinearVelocity * Config.Aimbot.PredictScale
        end
    end

    local currentCF = Camera.CFrame
    local targetCF = CFrame.lookAt(currentCF.Position, targetPos)
    local smoothing = math.clamp(Config.Aimbot.Smoothing, 1, 20)
    local alpha = 1 / smoothing

    Camera.CFrame = currentCF:Lerp(targetCF, alpha)
end

-- ─── SILENT AIM ──────────────────────────────────────────────

local OldNamecall = nil

function Features:InitSilentAim()
    if OldNamecall then return end

    local mt = getrawmetatable(game)
    if not mt then return end

    local oldNC = mt.__namecall
    OldNamecall = oldNC

    if setreadonly then setreadonly(mt, false) end

    mt.__namecall = newcclosure(function(self2, ...)
        local method = getnamecallmethod()
        local args = {...}

        if Config.SilentAim.Enabled and (method == "FireServer" or method == "InvokeServer") then
            local target = Features:GetSilentTarget()
            if target then
                -- Check hit chance
                if math.random(1, 100) <= Config.SilentAim.HitChance then
                    for i, v in pairs(args) do
                        if typeof(v) == "CFrame" then
                            args[i] = CFrame.new(target.Position)
                        elseif typeof(v) == "Vector3" then
                            args[i] = target.Position
                        end
                    end
                    return oldNC(self2, unpack(args))
                end
            end
        end

        return oldNC(self2, ...)
    end)

    if setreadonly then setreadonly(mt, true) end
end

function Features:GetSilentTarget()
    local closest = nil
    local closestDist = Config.Aimbot.FOV

    for _, player in ipairs(Players:GetPlayers()) do
        if player ~= LocalPlayer and IsAlive(player) and IsEnemy(player, Config.SilentAim.TeamCheck) then
            local char = GetCharacter(player)
            local bone = GetBone(char, Config.SilentAim.TargetBone)
            if bone then
                local screenPos, onScreen = WorldToScreen(bone.Position)
                if onScreen then
                    local mousePos = UserInputService:GetMouseLocation()
                    local dist = (screenPos - mousePos).Magnitude
                    if dist < closestDist then
                        closest = bone
                        closestDist = dist
                    end
                end
            end
        end
    end

    return closest
end

-- ─── TRIGGERBOT ──────────────────────────────────────────────

function Features:RunTriggerbot()
    if not Config.Triggerbot.Enabled then return end
    if not IsAlive(LocalPlayer) then return end

    local mousePos = UserInputService:GetMouseLocation()
    local ray = Camera:ViewportPointToRay(mousePos.X, mousePos.Y)

    local params = RaycastParams.new()
    params.FilterType = Enum.RaycastFilterType.Exclude
    params.FilterDescendantsInstances = {LocalPlayer.Character}

    local result = Workspace:Raycast(ray.Origin, ray.Direction * 1000, params)
    if result and result.Instance then
        local hitModel = result.Instance:FindFirstAncestorOfClass("Model")
        if hitModel then
            local hitPlayer = Players:GetPlayerFromCharacter(hitModel)
            if hitPlayer and IsEnemy(hitPlayer, Config.Triggerbot.TeamCheck) and IsAlive(hitPlayer) then
                task.wait(Config.Triggerbot.Delay / 1000)
                -- Simulate click
                if VirtualInputManager then
                    VirtualInputManager:SendMouseButtonEvent(mousePos.X, mousePos.Y, 0, true, game, 0)
                    task.wait(0.03)
                    VirtualInputManager:SendMouseButtonEvent(mousePos.X, mousePos.Y, 0, false, game, 0)
                else
                    mouse1click()
                end
            end
        end
    end
end

-- ─── NO RECOIL ───────────────────────────────────────────────

local StoredCameraCF = nil

function Features:RunNoRecoil()
    if not Config.NoRecoil.Enabled then return end
    if UserInputService:IsMouseButtonPressed(Enum.UserInputType.MouseButton1) then
        if StoredCameraCF then
            Camera.CFrame = CFrame.new(Camera.CFrame.Position) * StoredCameraCF.Rotation
        end
    else
        StoredCameraCF = Camera.CFrame
    end
end

-- ─── ESP ─────────────────────────────────────────────────────

function Features:InitESPForPlayer(player)
    if player == LocalPlayer then return end

    self.ESPDrawings[player] = {
        Box = {
            TopLeft     = CreateDrawing("Line", {Visible = false, Color = Config.ESP.BoxColor, Thickness = 1}),
            TopRight    = CreateDrawing("Line", {Visible = false, Color = Config.ESP.BoxColor, Thickness = 1}),
            BottomLeft  = CreateDrawing("Line", {Visible = false, Color = Config.ESP.BoxColor, Thickness = 1}),
            BottomRight = CreateDrawing("Line", {Visible = false, Color = Config.ESP.BoxColor, Thickness = 1}),
        },
        Name = CreateDrawing("Text", {Visible = false, Color = Config.ESP.NameColor, Size = 13, Center = true, Outline = true, Font = 2}),
        HealthBar = {
            BG   = CreateDrawing("Line", {Visible = false, Color = Color3.fromRGB(30, 30, 30), Thickness = 4}),
            Fill = CreateDrawing("Line", {Visible = false, Color = Color3.fromRGB(0, 255, 0), Thickness = 2}),
        },
        HealthText = CreateDrawing("Text", {Visible = false, Color = Color3.fromRGB(255, 255, 255), Size = 10, Center = false, Outline = true, Font = 2}),
        Distance = CreateDrawing("Text", {Visible = false, Color = Theme.TextMuted, Size = 10, Center = true, Outline = true, Font = 2}),
        Tracer = CreateDrawing("Line", {Visible = false, Color = Config.ESP.BoxColor, Thickness = 1}),
        Skeleton = {},
    }

    -- Skeleton lines (connect major body parts)
    local skelParts = {"Head_UpperTorso", "UpperTorso_LeftUpperArm", "LeftUpperArm_LeftLowerArm", "LeftLowerArm_LeftHand",
                       "UpperTorso_RightUpperArm", "RightUpperArm_RightLowerArm", "RightLowerArm_RightHand",
                       "UpperTorso_LowerTorso", "LowerTorso_LeftUpperLeg", "LeftUpperLeg_LeftLowerLeg", "LeftLowerLeg_LeftFoot",
                       "LowerTorso_RightUpperLeg", "RightUpperLeg_RightLowerLeg", "RightLowerLeg_RightFoot"}
    for _, name in ipairs(skelParts) do
        self.ESPDrawings[player].Skeleton[name] = CreateDrawing("Line", {Visible = false, Color = Theme.Accent, Thickness = 1})
    end
end

function Features:UpdateESP()
    if not Config.ESP.Enabled then
        -- Hide all ESP
        for _, drawings in pairs(self.ESPDrawings) do
            for key, obj in pairs(drawings) do
                if typeof(obj) == "table" then
                    for _, d in pairs(obj) do pcall(function() d.Visible = false end) end
                else
                    pcall(function() obj.Visible = false end)
                end
            end
        end
        return
    end

    for _, player in ipairs(Players:GetPlayers()) do
        if player == LocalPlayer then continue end

        if not self.ESPDrawings[player] then
            self:InitESPForPlayer(player)
        end

        local drawings = self.ESPDrawings[player]
        local char = GetCharacter(player)
        local isEnemy = IsEnemy(player, Config.ESP.TeamCheck)

        if not char or not IsAlive(player) or not isEnemy then
            for key, obj in pairs(drawings) do
                if typeof(obj) == "table" then
                    for _, d in pairs(obj) do pcall(function() d.Visible = false end) end
                else
                    pcall(function() obj.Visible = false end)
                end
            end
            continue
        end

        local hrp = char:FindFirstChild("HumanoidRootPart")
        local head = char:FindFirstChild("Head")
        local humanoid = char:FindFirstChildOfClass("Humanoid")
        if not hrp or not head or not humanoid then continue end

        local pos, onScreen, depth = WorldToScreen(hrp.Position)
        if not onScreen or depth < 0 then
            for key, obj in pairs(drawings) do
                if typeof(obj) == "table" then
                    for _, d in pairs(obj) do pcall(function() d.Visible = false end) end
                else
                    pcall(function() obj.Visible = false end)
                end
            end
            continue
        end

        -- Calculate box dimensions based on distance
        local headPos = WorldToScreen(head.Position + Vector3.new(0, 0.5, 0))
        local footPos = WorldToScreen(hrp.Position - Vector3.new(0, 3, 0))
        local boxHeight = math.abs(headPos.Y - footPos.Y)
        local boxWidth = boxHeight * 0.6

        local boxColor = Config.ESP.BoxColor
        if Config.ESP.TeamColor and player.Team then
            boxColor = player.TeamColor.Color
        end

        -- Box ESP
        if Config.ESP.Boxes then
            local topLeft = Vector2.new(pos.X - boxWidth / 2, headPos.Y)
            local topRight = Vector2.new(pos.X + boxWidth / 2, headPos.Y)
            local botLeft = Vector2.new(pos.X - boxWidth / 2, footPos.Y)
            local botRight = Vector2.new(pos.X + boxWidth / 2, footPos.Y)

            drawings.Box.TopLeft.From = topLeft
            drawings.Box.TopLeft.To = topRight
            drawings.Box.TopLeft.Color = boxColor
            drawings.Box.TopLeft.Visible = true

            drawings.Box.TopRight.From = topRight
            drawings.Box.TopRight.To = botRight
            drawings.Box.TopRight.Color = boxColor
            drawings.Box.TopRight.Visible = true

            drawings.Box.BottomRight.From = botRight
            drawings.Box.BottomRight.To = botLeft
            drawings.Box.BottomRight.Color = boxColor
            drawings.Box.BottomRight.Visible = true

            drawings.Box.BottomLeft.From = botLeft
            drawings.Box.BottomLeft.To = topLeft
            drawings.Box.BottomLeft.Color = boxColor
            drawings.Box.BottomLeft.Visible = true
        else
            for _, d in pairs(drawings.Box) do d.Visible = false end
        end

        -- Name ESP
        if Config.ESP.Names then
            drawings.Name.Position = Vector2.new(pos.X, headPos.Y - 16)
            drawings.Name.Text = player.DisplayName or player.Name
            drawings.Name.Color = Config.ESP.NameColor
            drawings.Name.Visible = true
        else
            drawings.Name.Visible = false
        end

        -- Health Bar ESP
        if Config.ESP.Health then
            local healthPct = math.clamp(humanoid.Health / humanoid.MaxHealth, 0, 1)
            local barX = pos.X - boxWidth / 2 - 6
            local barTop = headPos.Y
            local barBot = footPos.Y
            local barFillBot = barBot - (barBot - barTop) * healthPct

            drawings.HealthBar.BG.From = Vector2.new(barX, barTop)
            drawings.HealthBar.BG.To = Vector2.new(barX, barBot)
            drawings.HealthBar.BG.Visible = true

            drawings.HealthBar.Fill.From = Vector2.new(barX, barFillBot)
            drawings.HealthBar.Fill.To = Vector2.new(barX, barBot)
            drawings.HealthBar.Fill.Color = Color3.fromRGB(255 * (1 - healthPct), 255 * healthPct, 0)
            drawings.HealthBar.Fill.Visible = true

            drawings.HealthText.Position = Vector2.new(barX - 4, barFillBot - 6)
            drawings.HealthText.Text = math.floor(humanoid.Health) .. ""
            drawings.HealthText.Visible = healthPct < 1
        else
            drawings.HealthBar.BG.Visible = false
            drawings.HealthBar.Fill.Visible = false
            drawings.HealthText.Visible = false
        end

        -- Distance ESP
        if Config.ESP.Distance then
            local dist = (hrp.Position - Camera.CFrame.Position).Magnitude
            drawings.Distance.Position = Vector2.new(pos.X, footPos.Y + 2)
            drawings.Distance.Text = math.floor(dist) .. "m"
            drawings.Distance.Visible = true
        else
            drawings.Distance.Visible = false
        end

        -- Tracers
        if Config.ESP.Tracers then
            local origin
            local viewport = Camera.ViewportSize
            if Config.ESP.TracerOrigin == "Bottom" then
                origin = Vector2.new(viewport.X / 2, viewport.Y)
            elseif Config.ESP.TracerOrigin == "Top" then
                origin = Vector2.new(viewport.X / 2, 0)
            else
                origin = Vector2.new(viewport.X / 2, viewport.Y / 2)
            end

            drawings.Tracer.From = origin
            drawings.Tracer.To = Vector2.new(pos.X, footPos.Y)
            drawings.Tracer.Color = boxColor
            drawings.Tracer.Visible = true
        else
            drawings.Tracer.Visible = false
        end

        -- Skeleton ESP
        if Config.ESP.Skeleton then
            local function getSkelPos(partName)
                local part = char:FindFirstChild(partName)
                if part then
                    local sp, vis = WorldToScreen(part.Position)
                    return sp, vis
                end
                return nil, false
            end

            -- R15 skeleton connections
            local connections = {
                {"Head", "UpperTorso"}, {"UpperTorso", "LeftUpperArm"}, {"LeftUpperArm", "LeftLowerArm"},
                {"LeftLowerArm", "LeftHand"}, {"UpperTorso", "RightUpperArm"}, {"RightUpperArm", "RightLowerArm"},
                {"RightLowerArm", "RightHand"}, {"UpperTorso", "LowerTorso"}, {"LowerTorso", "LeftUpperLeg"},
                {"LeftUpperLeg", "LeftLowerLeg"}, {"LeftLowerLeg", "LeftFoot"}, {"LowerTorso", "RightUpperLeg"},
                {"RightUpperLeg", "RightLowerLeg"}, {"RightLowerLeg", "RightFoot"},
            }

            for _, conn in ipairs(connections) do
                local key = conn[1] .. "_" .. conn[2]
                local line = drawings.Skeleton[key]
                if line then
                    local p1, v1 = getSkelPos(conn[1])
                    local p2, v2 = getSkelPos(conn[2])
                    if p1 and p2 and v1 and v2 then
                        line.From = p1
                        line.To = p2
                        line.Visible = true
                    else
                        line.Visible = false
                    end
                end
            end
        else
            for _, line in pairs(drawings.Skeleton) do
                line.Visible = false
            end
        end
    end
end

-- ─── CHAMS ───────────────────────────────────────────────────

function Features:UpdateChams()
    for _, player in ipairs(Players:GetPlayers()) do
        if player == LocalPlayer then continue end

        local char = GetCharacter(player)
        local isEnemy = IsEnemy(player, Config.Chams.TeamCheck)

        if Config.Chams.Enabled and char and IsAlive(player) and isEnemy then
            if not self.ChamsCache[player] then
                local highlight = Instance.new("Highlight")
                highlight.Name = "BSChams"
                highlight.FillColor = Config.Chams.FillColor
                highlight.OutlineColor = Config.Chams.OutlineColor
                highlight.FillTransparency = Config.Chams.FillTransparency
                highlight.OutlineTransparency = Config.Chams.OutlineTransparency
                highlight.DepthMode = Enum.HighlightDepthMode.AlwaysOnTop
                highlight.Adornee = char
                highlight.Parent = CoreGui
                self.ChamsCache[player] = highlight
            else
                local h = self.ChamsCache[player]
                h.FillColor = Config.Chams.FillColor
                h.OutlineColor = Config.Chams.OutlineColor
                h.FillTransparency = Config.Chams.FillTransparency
                h.OutlineTransparency = Config.Chams.OutlineTransparency
                h.Adornee = char
            end
        else
            if self.ChamsCache[player] then
                self.ChamsCache[player]:Destroy()
                self.ChamsCache[player] = nil
            end
        end
    end
end

-- ─── CROSSHAIR ───────────────────────────────────────────────

Features.CrosshairDrawings = {}

function Features:InitCrosshair()
    self.CrosshairDrawings = {
        Top = CreateDrawing("Line", {Visible = false, Thickness = 1, Color = Config.Crosshair.Color}),
        Bottom = CreateDrawing("Line", {Visible = false, Thickness = 1, Color = Config.Crosshair.Color}),
        Left = CreateDrawing("Line", {Visible = false, Thickness = 1, Color = Config.Crosshair.Color}),
        Right = CreateDrawing("Line", {Visible = false, Thickness = 1, Color = Config.Crosshair.Color}),
        Dot = CreateDrawing("Circle", {Visible = false, Filled = true, Color = Config.Crosshair.Color, Radius = 2, NumSides = 12}),
    }
end

function Features:UpdateCrosshair()
    if not Config.Crosshair.Enabled then
        for _, d in pairs(self.CrosshairDrawings) do d.Visible = false end
        return
    end

    local center = GetScreenCenter()
    local size = Config.Crosshair.Size
    local gap = Config.Crosshair.Gap
    local color = Config.Crosshair.Color
    local thick = Config.Crosshair.Thickness

    self.CrosshairDrawings.Top.From = Vector2.new(center.X, center.Y - gap - size)
    self.CrosshairDrawings.Top.To = Vector2.new(center.X, center.Y - gap)
    self.CrosshairDrawings.Top.Color = color
    self.CrosshairDrawings.Top.Thickness = thick
    self.CrosshairDrawings.Top.Visible = true

    self.CrosshairDrawings.Bottom.From = Vector2.new(center.X, center.Y + gap)
    self.CrosshairDrawings.Bottom.To = Vector2.new(center.X, center.Y + gap + size)
    self.CrosshairDrawings.Bottom.Color = color
    self.CrosshairDrawings.Bottom.Thickness = thick
    self.CrosshairDrawings.Bottom.Visible = true

    self.CrosshairDrawings.Left.From = Vector2.new(center.X - gap - size, center.Y)
    self.CrosshairDrawings.Left.To = Vector2.new(center.X - gap, center.Y)
    self.CrosshairDrawings.Left.Color = color
    self.CrosshairDrawings.Left.Thickness = thick
    self.CrosshairDrawings.Left.Visible = true

    self.CrosshairDrawings.Right.From = Vector2.new(center.X + gap, center.Y)
    self.CrosshairDrawings.Right.To = Vector2.new(center.X + gap + size, center.Y)
    self.CrosshairDrawings.Right.Color = color
    self.CrosshairDrawings.Right.Thickness = thick
    self.CrosshairDrawings.Right.Visible = true

    self.CrosshairDrawings.Dot.Position = center
    self.CrosshairDrawings.Dot.Color = color
    self.CrosshairDrawings.Dot.Visible = Config.Crosshair.Dot
end

-- ─── FOV CIRCLE ──────────────────────────────────────────────

Features.FOVCircleDrawing = nil

function Features:InitFOVCircle()
    self.FOVCircleDrawing = CreateDrawing("Circle", {
        Visible = false,
        Filled = false,
        Color = Config.FOVCircle.Color,
        Transparency = Config.FOVCircle.Transparency,
        Radius = Config.Aimbot.FOV,
        NumSides = 64,
        Thickness = 1,
    })
end

function Features:UpdateFOVCircle()
    if not self.FOVCircleDrawing then return end

    if Config.Aimbot.ShowFOV and Config.Aimbot.Enabled then
        local mousePos = UserInputService:GetMouseLocation()
        self.FOVCircleDrawing.Position = mousePos
        self.FOVCircleDrawing.Radius = Config.Aimbot.FOV
        self.FOVCircleDrawing.Color = Config.FOVCircle.Color
        self.FOVCircleDrawing.Transparency = Config.FOVCircle.Transparency
        self.FOVCircleDrawing.Visible = true
    else
        self.FOVCircleDrawing.Visible = false
    end
end

-- ─── HIT MARKERS ─────────────────────────────────────────────

Features.HitMarkerLines = {}

function Features:InitHitMarkers()
    for i = 1, 4 do
        self.HitMarkerLines[i] = CreateDrawing("Line", {
            Visible = false,
            Color = Config.HitMarkers.Color,
            Thickness = 2,
        })
    end
end

function Features:ShowHitMarker()
    if not Config.HitMarkers.Enabled then return end

    local center = GetScreenCenter()
    local size = 10
    local gap = 4

    local positions = {
        {Vector2.new(center.X - gap, center.Y - gap), Vector2.new(center.X - gap - size, center.Y - gap - size)},
        {Vector2.new(center.X + gap, center.Y - gap), Vector2.new(center.X + gap + size, center.Y - gap - size)},
        {Vector2.new(center.X - gap, center.Y + gap), Vector2.new(center.X - gap - size, center.Y + gap + size)},
        {Vector2.new(center.X + gap, center.Y + gap), Vector2.new(center.X + gap + size, center.Y + gap + size)},
    }

    for i = 1, 4 do
        self.HitMarkerLines[i].From = positions[i][1]
        self.HitMarkerLines[i].To = positions[i][2]
        self.HitMarkerLines[i].Color = Config.HitMarkers.Color
        self.HitMarkerLines[i].Visible = true
    end

    spawn(function()
        wait(0.3)
        for i = 1, 4 do
            self.HitMarkerLines[i].Visible = false
        end
    end)
end

-- ─── BUNNY HOP ───────────────────────────────────────────────

function Features:RunBunnyHop()
    if not Config.BunnyHop.Enabled then return end
    if not IsAlive(LocalPlayer) then return end

    local char = GetCharacter(LocalPlayer)
    local humanoid = char and char:FindFirstChildOfClass("Humanoid")
    if not humanoid then return end

    if humanoid.FloorMaterial ~= Enum.Material.Air then
        if UserInputService:IsKeyDown(Enum.KeyCode.Space) then
            humanoid:ChangeState(Enum.HumanoidStateType.Jumping)
        end
    end
end

-- ─── SPEED BOOST ─────────────────────────────────────────────

local OriginalWalkSpeed = 16

function Features:RunSpeedBoost()
    if not IsAlive(LocalPlayer) then return end
    local char = GetCharacter(LocalPlayer)
    local humanoid = char and char:FindFirstChildOfClass("Humanoid")
    if not humanoid then return end

    if Config.SpeedBoost.Enabled then
        humanoid.WalkSpeed = Config.SpeedBoost.Speed
    else
        if humanoid.WalkSpeed ~= 16 then
            humanoid.WalkSpeed = OriginalWalkSpeed
        end
    end
end

-- ─── INFINITE JUMP ───────────────────────────────────────────

function Features:InitInfiniteJump()
    UserInputService.JumpRequest:Connect(function()
        if not Config.InfiniteJump.Enabled then return end
        if not IsAlive(LocalPlayer) then return end
        local char = GetCharacter(LocalPlayer)
        local humanoid = char and char:FindFirstChildOfClass("Humanoid")
        if humanoid then
            humanoid:ChangeState(Enum.HumanoidStateType.Jumping)
        end
    end)
end

-- ─── FLY ─────────────────────────────────────────────────────

function Features:RunFly()
    if not IsAlive(LocalPlayer) then return end
    local char = GetCharacter(LocalPlayer)
    local hrp = char and char:FindFirstChild("HumanoidRootPart")
    local humanoid = char and char:FindFirstChildOfClass("Humanoid")
    if not hrp or not humanoid then return end

    if Config.Fly.Enabled then
        if not self.FlyBody then
            local bv = Instance.new("BodyVelocity")
            bv.Name = "BSFly"
            bv.MaxForce = Vector3.new(math.huge, math.huge, math.huge)
            bv.Velocity = Vector3.new(0, 0, 0)
            bv.Parent = hrp

            local bg = Instance.new("BodyGyro")
            bg.Name = "BSFlyGyro"
            bg.MaxTorque = Vector3.new(math.huge, math.huge, math.huge)
            bg.D = 200
            bg.Parent = hrp

            self.FlyBody = {Velocity = bv, Gyro = bg}
        end

        local speed = Config.Fly.Speed
        local direction = Vector3.new(0, 0, 0)

        if UserInputService:IsKeyDown(Enum.KeyCode.W) then
            direction = direction + Camera.CFrame.LookVector
        end
        if UserInputService:IsKeyDown(Enum.KeyCode.S) then
            direction = direction - Camera.CFrame.LookVector
        end
        if UserInputService:IsKeyDown(Enum.KeyCode.A) then
            direction = direction - Camera.CFrame.RightVector
        end
        if UserInputService:IsKeyDown(Enum.KeyCode.D) then
            direction = direction + Camera.CFrame.RightVector
        end
        if UserInputService:IsKeyDown(Enum.KeyCode.Space) then
            direction = direction + Vector3.new(0, 1, 0)
        end
        if UserInputService:IsKeyDown(Enum.KeyCode.LeftControl) then
            direction = direction - Vector3.new(0, 1, 0)
        end

        self.FlyBody.Velocity.Velocity = direction * speed
        self.FlyBody.Gyro.CFrame = Camera.CFrame
        humanoid.PlatformStand = true
    else
        if self.FlyBody then
            self.FlyBody.Velocity:Destroy()
            self.FlyBody.Gyro:Destroy()
            self.FlyBody = nil
            humanoid.PlatformStand = false
        end
    end
end

-- ─── NOCLIP ──────────────────────────────────────────────────

function Features:RunNoclip()
    if not Config.Noclip.Enabled then return end
    if not IsAlive(LocalPlayer) then return end
    local char = GetCharacter(LocalPlayer)
    if not char then return end

    for _, part in ipairs(char:GetDescendants()) do
        if part:IsA("BasePart") then
            part.CanCollide = false
        end
    end
end

-- ─── ANTI-AFK ────────────────────────────────────────────────

function Features:InitAntiAFK()
    local vu = game:GetService("VirtualUser")
    if not vu then return end

    spawn(function()
        while true do
            wait(60)
            if Config.AntiAFK.Enabled then
                pcall(function()
                    vu:Button2Down(Vector2.new(0, 0), Camera.CFrame)
                    wait(0.1)
                    vu:Button2Up(Vector2.new(0, 0), Camera.CFrame)
                end)
            end
        end
    end)
end

-- ─── FULLBRIGHT ──────────────────────────────────────────────

function Features:RunFullbright()
    if Config.Fullbright.Enabled then
        if not self.OriginalLighting.Ambient then
            self.OriginalLighting.Ambient = Lighting.Ambient
            self.OriginalLighting.Brightness = Lighting.Brightness
            self.OriginalLighting.OutdoorAmbient = Lighting.OutdoorAmbient
        end
        Lighting.Ambient = Color3.fromRGB(200, 200, 200)
        Lighting.Brightness = 2
        Lighting.OutdoorAmbient = Color3.fromRGB(200, 200, 200)
    else
        if self.OriginalLighting.Ambient then
            Lighting.Ambient = self.OriginalLighting.Ambient
            Lighting.Brightness = self.OriginalLighting.Brightness
            Lighting.OutdoorAmbient = self.OriginalLighting.OutdoorAmbient
        end
    end
end

-- ─── NO FOG ──────────────────────────────────────────────────

function Features:RunNoFog()
    if Config.NoFog.Enabled then
        if not self.OriginalLighting.FogEnd then
            self.OriginalLighting.FogEnd = Lighting.FogEnd
            self.OriginalLighting.FogStart = Lighting.FogStart
        end
        Lighting.FogEnd = 999999
        Lighting.FogStart = 999999
    else
        if self.OriginalLighting.FogEnd then
            Lighting.FogEnd = self.OriginalLighting.FogEnd
            Lighting.FogStart = self.OriginalLighting.FogStart
        end
    end
end

-- ─── KILL SOUND ──────────────────────────────────────────────

function Features:InitKillSound()
    for _, player in ipairs(Players:GetPlayers()) do
        if player ~= LocalPlayer then
            local function onCharAdded(char)
                local hum = char:WaitForChild("Humanoid", 5)
                if hum then
                    hum.Died:Connect(function()
                        if not Config.KillSound.Enabled then return end
                        pcall(function()
                            local sound = Instance.new("Sound")
                            sound.SoundId = Config.KillSound.SoundId
                            sound.Volume = 1
                            sound.Parent = Camera
                            sound:Play()
                            game:GetService("Debris"):AddItem(sound, 3)
                        end)
                    end)
                end
            end

            if player.Character then
                spawn(function() onCharAdded(player.Character) end)
            end
            player.CharacterAdded:Connect(onCharAdded)
        end
    end

    Players.PlayerAdded:Connect(function(player)
        local function onCharAdded(char)
            local hum = char:WaitForChild("Humanoid", 5)
            if hum then
                hum.Died:Connect(function()
                    if not Config.KillSound.Enabled then return end
                    pcall(function()
                        local sound = Instance.new("Sound")
                        sound.SoundId = Config.KillSound.SoundId
                        sound.Volume = 1
                        sound.Parent = Camera
                        sound:Play()
                        game:GetService("Debris"):AddItem(sound, 3)
                    end)
                end)
            end
        end
        player.CharacterAdded:Connect(onCharAdded)
    end)
end

-- ─── THIRD PERSON ────────────────────────────────────────────

function Features:RunThirdPerson()
    if Config.ThirdPerson.Enabled then
        LocalPlayer.CameraMinZoomDistance = Config.ThirdPerson.Distance
        LocalPlayer.CameraMaxZoomDistance = Config.ThirdPerson.Distance + 5
    else
        LocalPlayer.CameraMinZoomDistance = 0.5
        LocalPlayer.CameraMaxZoomDistance = 128
    end
end

-- ═══════════════════════════════════════════════════════════════
-- [SECTION 9] PLAYER CLEANUP HANDLER
-- ═══════════════════════════════════════════════════════════════

Players.PlayerRemoving:Connect(function(player)
    -- Clean up ESP drawings
    if Features.ESPDrawings[player] then
        local drawings = Features.ESPDrawings[player]
        for key, obj in pairs(drawings) do
            if typeof(obj) == "table" then
                for _, d in pairs(obj) do pcall(function() d:Remove() end) end
            else
                pcall(function() obj:Remove() end)
            end
        end
        Features.ESPDrawings[player] = nil
    end

    -- Clean up chams
    if Features.ChamsCache[player] then
        Features.ChamsCache[player]:Destroy()
        Features.ChamsCache[player] = nil
    end
end)

-- ═══════════════════════════════════════════════════════════════
-- [SECTION 10] BUILD THE UI
-- ═══════════════════════════════════════════════════════════════

UI:Init()

-- ─── COMBAT TAB ──────────────────────────────────────────────

local combatTab = UI:CreateTab("Combat", "⚔", 1)

UI:CreateSection(combatTab, "AIMBOT")
UI:CreateToggle(combatTab, "Enable Aimbot", Config.Aimbot, "Enabled")
UI:CreateSlider(combatTab, "Smoothing", 1, 20, Config.Aimbot, "Smoothing")
UI:CreateSlider(combatTab, "FOV Radius", 20, 500, Config.Aimbot, "FOV")
UI:CreateDropdown(combatTab, "Target Bone", {"Head", "Torso", "HumanoidRootPart"}, Config.Aimbot, "TargetBone")
UI:CreateToggle(combatTab, "Team Check", Config.Aimbot, "TeamCheck")
UI:CreateToggle(combatTab, "Wall Check", Config.Aimbot, "WallCheck")
UI:CreateToggle(combatTab, "Prediction", Config.Aimbot, "Prediction")
UI:CreateSlider(combatTab, "Predict Scale", 1, 30, Config.Aimbot, "PredictScale")
UI:CreateToggle(combatTab, "Show FOV Circle", Config.Aimbot, "ShowFOV")

UI:CreateSection(combatTab, "SILENT AIM")
UI:CreateToggle(combatTab, "Enable Silent Aim", Config.SilentAim, "Enabled", function(v)
    if v then Features:InitSilentAim() end
end)
UI:CreateSlider(combatTab, "Hit Chance (%)", 1, 100, Config.SilentAim, "HitChance")
UI:CreateDropdown(combatTab, "Target Bone", {"Head", "Torso", "HumanoidRootPart"}, Config.SilentAim, "TargetBone")

UI:CreateSection(combatTab, "TRIGGERBOT")
UI:CreateToggle(combatTab, "Enable Triggerbot", Config.Triggerbot, "Enabled")
UI:CreateSlider(combatTab, "Trigger Delay (ms)", 0, 300, Config.Triggerbot, "Delay")
UI:CreateToggle(combatTab, "Team Check", Config.Triggerbot, "TeamCheck")

UI:CreateSection(combatTab, "WEAPON MODS")
UI:CreateToggle(combatTab, "No Recoil", Config.NoRecoil, "Enabled")
UI:CreateToggle(combatTab, "Rapid Fire", Config.RapidFire, "Enabled")
UI:CreateSlider(combatTab, "Fire Speed Multiplier", 1, 5, Config.RapidFire, "Speed")

-- ─── VISUALS TAB ─────────────────────────────────────────────

local visualsTab = UI:CreateTab("Visuals", "👁", 2)

UI:CreateSection(visualsTab, "PLAYER ESP")
UI:CreateToggle(visualsTab, "Enable ESP", Config.ESP, "Enabled")
UI:CreateToggle(visualsTab, "Boxes", Config.ESP, "Boxes")
UI:CreateToggle(visualsTab, "Names", Config.ESP, "Names")
UI:CreateToggle(visualsTab, "Health Bars", Config.ESP, "Health")
UI:CreateToggle(visualsTab, "Distance", Config.ESP, "Distance")
UI:CreateToggle(visualsTab, "Skeleton", Config.ESP, "Skeleton")
UI:CreateToggle(visualsTab, "Tracers", Config.ESP, "Tracers")
UI:CreateDropdown(visualsTab, "Tracer Origin", {"Bottom", "Top", "Center"}, Config.ESP, "TracerOrigin")
UI:CreateToggle(visualsTab, "Team Check", Config.ESP, "TeamCheck")
UI:CreateToggle(visualsTab, "Use Team Colors", Config.ESP, "TeamColor")

UI:CreateSection(visualsTab, "CHAMS / WALLHACK")
UI:CreateToggle(visualsTab, "Enable Chams", Config.Chams, "Enabled")
UI:CreateToggle(visualsTab, "Team Check", Config.Chams, "TeamCheck")

UI:CreateSection(visualsTab, "CROSSHAIR")
UI:CreateToggle(visualsTab, "Custom Crosshair", Config.Crosshair, "Enabled")
UI:CreateSlider(visualsTab, "Size", 2, 20, Config.Crosshair, "Size")
UI:CreateSlider(visualsTab, "Gap", 0, 15, Config.Crosshair, "Gap")
UI:CreateSlider(visualsTab, "Thickness", 1, 5, Config.Crosshair, "Thickness")
UI:CreateToggle(visualsTab, "Center Dot", Config.Crosshair, "Dot")

UI:CreateSection(visualsTab, "WORLD")
UI:CreateToggle(visualsTab, "Fullbright", Config.Fullbright, "Enabled")
UI:CreateToggle(visualsTab, "No Fog", Config.NoFog, "Enabled")
UI:CreateToggle(visualsTab, "Hit Markers", Config.HitMarkers, "Enabled")

-- ─── MOVEMENT TAB ────────────────────────────────────────────

local moveTab = UI:CreateTab("Movement", "🏃", 3)

UI:CreateSection(moveTab, "MOVEMENT MODS")
UI:CreateToggle(moveTab, "Bunny Hop", Config.BunnyHop, "Enabled")
UI:CreateToggle(moveTab, "Speed Boost", Config.SpeedBoost, "Enabled")
UI:CreateSlider(moveTab, "Walk Speed", 16, 60, Config.SpeedBoost, "Speed")
UI:CreateToggle(moveTab, "Infinite Jump", Config.InfiniteJump, "Enabled")

UI:CreateSection(moveTab, "ADVANCED")
UI:CreateToggle(moveTab, "Fly", Config.Fly, "Enabled")
UI:CreateSlider(moveTab, "Fly Speed", 10, 200, Config.Fly, "Speed")
UI:CreateToggle(moveTab, "Noclip", Config.Noclip, "Enabled")

-- ─── MISC TAB ────────────────────────────────────────────────

local miscTab = UI:CreateTab("Misc", "⚙", 4)

UI:CreateSection(miscTab, "UTILITIES")
UI:CreateToggle(miscTab, "Anti-AFK", Config.AntiAFK, "Enabled")
UI:CreateToggle(miscTab, "Kill Sound", Config.KillSound, "Enabled")
UI:CreateToggle(miscTab, "Third Person Lock", Config.ThirdPerson, "Enabled")
UI:CreateSlider(miscTab, "Camera Distance", 5, 30, Config.ThirdPerson, "Distance")

UI:CreateSection(miscTab, "OFFSETS")
UI:CreateButton(miscTab, "🔄 Force Refresh Offsets", function()
    Notify("Offsets", "Refreshing offsets...", 2)
    spawn(function()
        local ok = FetchOffsets()
        if ok then
            Notify("Offsets", "Updated to " .. OffsetVersion, 3)
        else
            Notify("Offsets", "Failed to refresh!", 3)
        end
    end)
end)

UI:CreateButton(miscTab, "📋 Show Current Version", function()
    Notify("Version Info", "Roblox: " .. OffsetVersion .. "\nScript: v2.0", 4)
end)

-- ─── SETTINGS TAB ────────────────────────────────────────────

local settingsTab = UI:CreateTab("Settings", "🎨", 5)

UI:CreateSection(settingsTab, "GENERAL")
UI:CreateButton(settingsTab, "🗑️ Unload Script", function()
    Notify("Unloading", "Cleaning up...", 2)
    spawn(function()
        wait(1)
        -- Clean up all drawings
        ClearAllDrawings()
        for _, d in pairs(Features.CrosshairDrawings) do pcall(function() d:Remove() end) end
        if Features.FOVCircleDrawing then pcall(function() Features.FOVCircleDrawing:Remove() end) end
        for _, d in pairs(Features.HitMarkerLines) do pcall(function() d:Remove() end) end
        -- Clean up chams
        for _, h in pairs(Features.ChamsCache) do pcall(function() h:Destroy() end) end
        -- Clean up fly
        if Features.FlyBody then
            pcall(function() Features.FlyBody.Velocity:Destroy() end)
            pcall(function() Features.FlyBody.Gyro:Destroy() end)
        end
        -- Restore lighting
        Features:RunFullbright() -- Will restore since Enabled is still true -> set to false first
        Config.Fullbright.Enabled = false
        Features:RunFullbright()
        Config.NoFog.Enabled = false
        Features:RunNoFog()
        -- Restore walk speed
        Config.SpeedBoost.Enabled = false
        Features:RunSpeedBoost()
        -- Destroy UI
        UI:Destroy()
    end)
end)

UI:CreateButton(settingsTab, "🔑 Toggle Key: RightCtrl", function()
    Notify("Info", "Press RightCtrl to show/hide menu", 3)
end)

-- Select first tab
UI:SelectTab("Combat")

-- ═══════════════════════════════════════════════════════════════
-- [SECTION 11] MAIN LOOPS
-- ═══════════════════════════════════════════════════════════════

-- Init subsystems
Features:InitCrosshair()
Features:InitFOVCircle()
Features:InitHitMarkers()
Features:InitInfiniteJump()
Features:InitAntiAFK()
Features:InitKillSound()

-- Try to init silent aim if executor supports it
pcall(function() Features:InitSilentAim() end)

-- Visual loop (RenderStepped - runs every frame)
RunService.RenderStepped:Connect(function()
    Camera = Workspace.CurrentCamera

    -- Aimbot
    pcall(function() Features:RunAimbot() end)

    -- No Recoil
    pcall(function() Features:RunNoRecoil() end)

    -- ESP
    pcall(function() Features:UpdateESP() end)

    -- Crosshair
    pcall(function() Features:UpdateCrosshair() end)

    -- FOV Circle
    pcall(function() Features:UpdateFOVCircle() end)

    -- Noclip
    pcall(function() Features:RunNoclip() end)

    -- Fly
    pcall(function() Features:RunFly() end)
end)

-- Logic loop (Heartbeat - runs every physics step)
RunService.Heartbeat:Connect(function()
    -- Triggerbot
    pcall(function() Features:RunTriggerbot() end)

    -- Bunny Hop
    pcall(function() Features:RunBunnyHop() end)

    -- Speed Boost
    pcall(function() Features:RunSpeedBoost() end)

    -- Chams
    pcall(function() Features:UpdateChams() end)

    -- Fullbright
    pcall(function() Features:RunFullbright() end)

    -- No Fog
    pcall(function() Features:RunNoFog() end)

    -- Third Person
    pcall(function() Features:RunThirdPerson() end)
end)

-- ═══════════════════════════════════════════════════════════════
-- [SECTION 12] KEYBIND HANDLER
-- ═══════════════════════════════════════════════════════════════

UserInputService.InputBegan:Connect(function(input, gameProcessed)
    if gameProcessed then return end

    if input.KeyCode == Config.MenuKey then
        UI:Toggle()
    end
end)

-- ═══════════════════════════════════════════════════════════════
-- [SECTION 13] STARTUP
-- ═══════════════════════════════════════════════════════════════

-- Welcome notification
spawn(function()
    wait(1)
    Notify("⚡ BloxStrike Domination", "Script loaded successfully!", 4)
    wait(0.5)
    Notify("Offsets", OffsetStatus, 3)
    wait(0.5)
    Notify("Tip", "Press RightCtrl to toggle the menu", 3)
end)

print([[
    ╔═══════════════════════════════════════╗
    ║   BloxStrike Domination v2.0 Loaded  ║
    ║   Offsets: ]] .. OffsetStatus .. [[
    ║   Press RightCtrl to toggle menu     ║
    ╚═══════════════════════════════════════╝
]])
