--[[
    ╔═══════════════════════════════════════════════════════════════════╗
    ║                                                                   ║
    ║              B L O X S T R I K E   D O M I N A T I O N            ║
    ║                     Premium Script Hub v2.2                       ║
    ║                                                                   ║
    ║        Auto-Updating Offsets · Modern ImGui · Full PVP Suite      ║
    ║         Cross-Executor Compatible (Synapse/Fluxus/KRNL/etc)       ║
    ║                                                                   ║
    ╚═══════════════════════════════════════════════════════════════════╝
]]

-- ═══════════════════════════════════════════════════════════════
-- [SECTION 0] CROSS-EXECUTOR COMPATIBILITY LAYER
-- Everything here is wrapped in pcall to prevent ANY crash
-- ═══════════════════════════════════════════════════════════════

-- Safe wait/spawn (using pcall to guarantee these exist)
local safeWait = wait
pcall(function()
    if task and task.wait then safeWait = task.wait end
end)

local safeSpawn = spawn
pcall(function()
    if task and task.spawn then safeSpawn = task.spawn end
end)

-- Drawing API check
local HAS_DRAWING = false
pcall(function()
    local test = Drawing.new("Line")
    test:Remove()
    HAS_DRAWING = true
end)

-- gethui check (safe)
local HAS_GETHUI = false
pcall(function()
    if gethui then HAS_GETHUI = true end
end)

-- Synapse check (safe)
local HAS_PROTECT = false
pcall(function()
    if syn and syn.protect_gui then HAS_PROTECT = true end
end)

-- Hookmetamethod check (safe)
local HAS_HOOKMT = false
pcall(function()
    if getrawmetatable then HAS_HOOKMT = true end
end)

-- Safe font resolver
local function safeFont(name, fallback)
    local ok, f = pcall(function() return Enum.Font[name] end)
    if ok and f then return f end
    return fallback or Enum.Font.SourceSans
end

local Fonts = {
    Bold    = safeFont("GothamBold", Enum.Font.SourceSansBold),
    Medium  = safeFont("GothamMedium", Enum.Font.SourceSans),
    Regular = safeFont("Gotham", Enum.Font.SourceSans),
}

-- Safe RaycastFilterType
local FilterExclude = Enum.RaycastFilterType.Blacklist
pcall(function()
    if Enum.RaycastFilterType.Exclude then
        FilterExclude = Enum.RaycastFilterType.Exclude
    end
end)

-- Safe instance creation
local function safeNew(className, props, parent)
    local ok, inst = pcall(function()
        local i = Instance.new(className)
        if props then
            for k, v in pairs(props) do
                pcall(function() i[k] = v end)
            end
        end
        if parent then
            i.Parent = parent
        end
        return i
    end)
    if ok then return inst end
    return nil
end

-- ═══════════════════════════════════════════════════════════════
-- MAIN SCRIPT WRAPPED IN XPCALL FOR ERROR REPORTING
-- ═══════════════════════════════════════════════════════════════

local mainOk, mainErr = xpcall(function()

-- ═══════════════════════════════════════════════════════════════
-- [SECTION 1] SERVICES & CORE REFERENCES
-- ═══════════════════════════════════════════════════════════════

local Players            = game:GetService("Players")
local RunService         = game:GetService("RunService")
local UserInputService   = game:GetService("UserInputService")
local TweenService       = game:GetService("TweenService")
local Lighting           = game:GetService("Lighting")
local CoreGui            = game:GetService("CoreGui")
local Workspace          = game:GetService("Workspace")

local LocalPlayer = Players.LocalPlayer
local Camera      = Workspace.CurrentCamera
local Mouse       = LocalPlayer:GetMouse()

-- VirtualInputManager (optional)
local VIM = nil
pcall(function() VIM = game:GetService("VirtualInputManager") end)

-- VirtualUser (optional, for anti-afk)
local VirtualUser = nil
pcall(function() VirtualUser = game:GetService("VirtualUser") end)

-- ═══════════════════════════════════════════════════════════════
-- [SECTION 1.5] GUI PARENT RESOLUTION
-- ═══════════════════════════════════════════════════════════════

local GuiParent = nil

-- Method 1: gethui()
if HAS_GETHUI then
    pcall(function() GuiParent = gethui() end)
end

-- Method 2: CoreGui (with optional protection)
if not GuiParent then
    local ok = pcall(function()
        local testGui = Instance.new("ScreenGui")
        testGui.Name = "BSTest_" .. math.random(100000, 999999)
        if HAS_PROTECT then
            pcall(function() syn.protect_gui(testGui) end)
        end
        testGui.Parent = CoreGui
        testGui:Destroy()
    end)
    if ok then
        GuiParent = CoreGui
    end
end

-- Method 3: PlayerGui fallback
if not GuiParent then
    GuiParent = LocalPlayer:WaitForChild("PlayerGui")
end

-- ═══════════════════════════════════════════════════════════════
-- [SECTION 2] AUTO-UPDATING OFFSET SYSTEM
-- ═══════════════════════════════════════════════════════════════

local OFFSETS_URL = "https://offsets.ntgetwritewatch.workers.dev/offsets_structured.hpp"
local Offsets = {}
local OffsetVersion = "unknown"
local OffsetStatus = "Fetching..."

local function FetchOffsets()
    local ok, data = pcall(function()
        -- Try multiple HTTP methods
        if syn and syn.request then
            return syn.request({Url = OFFSETS_URL}).Body
        end
        if request then
            return request({Url = OFFSETS_URL}).Body
        end
        if http_request then
            return http_request({Url = OFFSETS_URL}).Body
        end
        return game:HttpGet(OFFSETS_URL)
    end)

    if not ok or not data then
        OffsetStatus = "Failed"
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
    if ver then OffsetVersion = ver end

    Offsets = parsed
    OffsetStatus = "Synced (" .. OffsetVersion .. ")"
    return true
end

safeSpawn(function()
    FetchOffsets()
    while true do
        safeWait(300)
        FetchOffsets()
    end
end)

-- ═══════════════════════════════════════════════════════════════
-- [SECTION 3] CONFIGURATION
-- ═══════════════════════════════════════════════════════════════

local Config = {
    Aimbot = {
        Enabled      = false,
        Smoothing    = 5,
        FOV          = 120,
        TargetBone   = "Head",
        TeamCheck    = true,
        WallCheck    = true,
        Prediction   = false,
        PredictScale = 0.125,
        ShowFOV      = true,
    },
    SilentAim = {
        Enabled    = false,
        HitChance  = 100,
        TargetBone = "Head",
        TeamCheck  = true,
    },
    Triggerbot = {
        Enabled   = false,
        Delay     = 50,
        TeamCheck = true,
    },
    NoRecoil  = { Enabled = false },
    RapidFire = { Enabled = false, Speed = 2 },

    ESP = {
        Enabled      = false,
        Boxes        = true,
        BoxColor     = Color3.fromRGB(0, 212, 255),
        Names        = true,
        NameColor    = Color3.fromRGB(255, 255, 255),
        Health       = true,
        Distance     = true,
        Skeleton     = false,
        Tracers      = false,
        TracerOrigin = "Bottom",
        TeamCheck    = true,
        TeamColor    = false,
    },
    Chams = {
        Enabled             = false,
        FillColor           = Color3.fromRGB(122, 95, 255),
        OutlineColor        = Color3.fromRGB(0, 212, 255),
        FillTransparency    = 0.5,
        OutlineTransparency = 0,
        TeamCheck           = true,
    },
    Crosshair = {
        Enabled   = false,
        Size      = 6,
        Gap       = 3,
        Thickness = 1,
        Color     = Color3.fromRGB(0, 255, 128),
        Dot       = true,
    },
    FOVCircle = {
        Enabled      = false,
        Color        = Color3.fromRGB(255, 255, 255),
        Transparency = 0.7,
    },
    Fullbright  = { Enabled = false },
    NoFog       = { Enabled = false },
    HitMarkers  = { Enabled = false, Color = Color3.fromRGB(255, 50, 50) },

    BunnyHop     = { Enabled = false },
    SpeedBoost   = { Enabled = false, Speed = 20 },
    InfiniteJump = { Enabled = false },
    Fly          = { Enabled = false, Speed = 50 },
    Noclip       = { Enabled = false },

    AntiAFK      = { Enabled = true },
    KillSound    = { Enabled = false, SoundId = "rbxassetid://5765933856" },
    ThirdPerson  = { Enabled = false, Distance = 10 },

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
    params.FilterType = FilterExclude
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
    if boneName == "Head" then
        return character:FindFirstChild("Head")
    elseif boneName == "Torso" then
        return character:FindFirstChild("HumanoidRootPart")
            or character:FindFirstChild("UpperTorso")
            or character:FindFirstChild("Torso")
    end
    return character:FindFirstChild("HumanoidRootPart")
end

local function GetScreenCenter()
    local vp = Camera.ViewportSize
    return Vector2.new(vp.X / 2, vp.Y / 2)
end

-- ═══════════════════════════════════════════════════════════════
-- [SECTION 5] DRAWING MANAGER
-- ═══════════════════════════════════════════════════════════════

local function CreateDrawing(class, props)
    if not HAS_DRAWING then return nil end
    local ok, obj = pcall(function()
        local d = Drawing.new(class)
        for k, v in pairs(props) do d[k] = v end
        return d
    end)
    if ok then return obj end
    return nil
end

local function SafeDP(drawing, prop, value)
    if not drawing then return end
    pcall(function() drawing[prop] = value end)
end

local function SafeDR(drawing)
    if not drawing then return end
    pcall(function() drawing:Remove() end)
end

-- ═══════════════════════════════════════════════════════════════
-- [SECTION 6] NOTIFICATION SYSTEM
-- ═══════════════════════════════════════════════════════════════

local NotifHolder = nil

local function CreateNotifHolder(parent)
    local holder = Instance.new("Frame")
    holder.Name = "NotifHolder"
    holder.Size = UDim2.new(0, 300, 1, 0)
    holder.Position = UDim2.new(1, -320, 0, 0)
    holder.BackgroundTransparency = 1
    holder.ZIndex = 100
    holder.Parent = parent

    local layout = Instance.new("UIListLayout")
    layout.SortOrder = Enum.SortOrder.LayoutOrder
    layout.Padding = UDim.new(0, 8)
    layout.VerticalAlignment = Enum.VerticalAlignment.Bottom
    layout.Parent = holder

    local pad = Instance.new("UIPadding")
    pad.PaddingBottom = UDim.new(0, 20)
    pad.Parent = holder

    return holder
end

local function Notify(title, message, duration)
    duration = duration or 3
    if not NotifHolder or not NotifHolder.Parent then return end
    pcall(function()
        local n = Instance.new("Frame")
        n.Size = UDim2.new(1, 0, 0, 60)
        n.BackgroundColor3 = Color3.fromRGB(22, 27, 34)
        n.BorderSizePixel = 0
        n.BackgroundTransparency = 0.05
        n.ClipsDescendants = true
        n.Parent = NotifHolder

        safeNew("UICorner", {CornerRadius = UDim.new(0, 8)}, n)
        safeNew("UIStroke", {Color = Color3.fromRGB(48, 54, 61), Thickness = 1}, n)

        local bar = Instance.new("Frame")
        bar.Size = UDim2.new(0, 3, 1, 0)
        bar.BackgroundColor3 = Color3.fromRGB(0, 212, 255)
        bar.BorderSizePixel = 0
        bar.Parent = n

        local tl = Instance.new("TextLabel")
        tl.Text = title
        tl.Font = Fonts.Bold
        tl.TextSize = 13
        tl.TextColor3 = Color3.fromRGB(230, 237, 243)
        tl.BackgroundTransparency = 1
        tl.Position = UDim2.new(0, 14, 0, 8)
        tl.Size = UDim2.new(1, -20, 0, 18)
        tl.TextXAlignment = Enum.TextXAlignment.Left
        tl.Parent = n

        local ml = Instance.new("TextLabel")
        ml.Text = message
        ml.Font = Fonts.Regular
        ml.TextSize = 11
        ml.TextColor3 = Color3.fromRGB(139, 148, 158)
        ml.BackgroundTransparency = 1
        ml.Position = UDim2.new(0, 14, 0, 28)
        ml.Size = UDim2.new(1, -20, 0, 24)
        ml.TextXAlignment = Enum.TextXAlignment.Left
        ml.TextWrapped = true
        ml.Parent = n

        n.Position = UDim2.new(1, 0, 0, 0)
        TweenService:Create(n, TweenInfo.new(0.3, Enum.EasingStyle.Quart, Enum.EasingDirection.Out), {
            Position = UDim2.new(0, 0, 0, 0)
        }):Play()

        safeSpawn(function()
            safeWait(duration)
            local tw = TweenService:Create(n, TweenInfo.new(0.4, Enum.EasingStyle.Quart, Enum.EasingDirection.In), {
                Position = UDim2.new(1, 0, 0, 0), BackgroundTransparency = 1
            })
            tw:Play()
            tw.Completed:Wait()
            n:Destroy()
        end)
    end)
end

-- ═══════════════════════════════════════════════════════════════
-- [SECTION 7] IMGUI UI SYSTEM
-- ═══════════════════════════════════════════════════════════════

local UI = {}
UI.Tabs = {}
UI.ScreenGui = nil
UI.MainFrame = nil
UI.ContentFrame = nil
UI.ActiveTab = nil
UI.Visible = true

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
    pcall(function()
        if GuiParent:FindFirstChild("BloxStrikeDom") then
            GuiParent:FindFirstChild("BloxStrikeDom"):Destroy()
        end
    end)
    pcall(function()
        if CoreGui:FindFirstChild("BloxStrikeDom") then
            CoreGui:FindFirstChild("BloxStrikeDom"):Destroy()
        end
    end)

    self.ScreenGui = Instance.new("ScreenGui")
    self.ScreenGui.Name = "BloxStrikeDom"
    self.ScreenGui.ResetOnSpawn = false
    pcall(function() self.ScreenGui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling end)

    if HAS_PROTECT then
        pcall(function() syn.protect_gui(self.ScreenGui) end)
    end

    self.ScreenGui.Parent = GuiParent

    NotifHolder = CreateNotifHolder(self.ScreenGui)

    -- Main Window
    self.MainFrame = Instance.new("Frame")
    self.MainFrame.Name = "MainWindow"
    self.MainFrame.Size = UDim2.new(0, 580, 0, 420)
    self.MainFrame.Position = UDim2.new(0.5, -290, 0.5, -210)
    self.MainFrame.BackgroundColor3 = Theme.Background
    self.MainFrame.BorderSizePixel = 0
    self.MainFrame.ClipsDescendants = true
    self.MainFrame.Active = true
    self.MainFrame.Parent = self.ScreenGui

    safeNew("UICorner", {CornerRadius = UDim.new(0, 10)}, self.MainFrame)
    safeNew("UIStroke", {Color = Theme.Border, Thickness = 1}, self.MainFrame)

    -- Title Bar
    local titleBar = Instance.new("Frame")
    titleBar.Name = "TitleBar"
    titleBar.Size = UDim2.new(1, 0, 0, 40)
    titleBar.BackgroundColor3 = Theme.Surface
    titleBar.BorderSizePixel = 0
    titleBar.Active = true
    titleBar.Parent = self.MainFrame
    safeNew("UICorner", {CornerRadius = UDim.new(0, 10)}, titleBar)

    local tbFix = Instance.new("Frame")
    tbFix.Size = UDim2.new(1, 0, 0, 12)
    tbFix.Position = UDim2.new(0, 0, 1, -12)
    tbFix.BackgroundColor3 = Theme.Surface
    tbFix.BorderSizePixel = 0
    tbFix.Parent = titleBar

    -- Accent line
    local accentLine = Instance.new("Frame")
    accentLine.Size = UDim2.new(1, 0, 0, 2)
    accentLine.Position = UDim2.new(0, 0, 1, 0)
    accentLine.BorderSizePixel = 0
    accentLine.BackgroundColor3 = Theme.Accent
    accentLine.Parent = titleBar

    local accentGrad = safeNew("UIGradient", {
        Color = ColorSequence.new({
            ColorSequenceKeypoint.new(0, Theme.Accent),
            ColorSequenceKeypoint.new(0.5, Theme.AccentSecondary),
            ColorSequenceKeypoint.new(1, Theme.Accent),
        })
    }, accentLine)

    if accentGrad then
        safeSpawn(function()
            local off = 0
            while self.ScreenGui and self.ScreenGui.Parent do
                off = (off + 0.005) % 1
                pcall(function()
                    accentGrad.Offset = Vector2.new(math.sin(off * math.pi * 2) * 0.3, 0)
                end)
                RunService.RenderStepped:Wait()
            end
        end)
    end

    -- Title
    local titleText = Instance.new("TextLabel")
    titleText.Text = "BLOXSTRIKE DOMINATION"
    titleText.Font = Fonts.Bold
    titleText.TextSize = 14
    titleText.TextColor3 = Theme.Text
    titleText.BackgroundTransparency = 1
    titleText.Position = UDim2.new(0, 14, 0, 0)
    titleText.Size = UDim2.new(0.6, 0, 1, 0)
    titleText.TextXAlignment = Enum.TextXAlignment.Left
    titleText.Parent = titleBar

    local vBadge = Instance.new("TextLabel")
    vBadge.Text = "v2.2"
    vBadge.Font = Fonts.Bold
    vBadge.TextSize = 10
    vBadge.TextColor3 = Theme.Accent
    vBadge.BackgroundColor3 = Color3.fromRGB(0, 40, 50)
    vBadge.Position = UDim2.new(0, 210, 0.5, -9)
    vBadge.Size = UDim2.new(0, 32, 0, 18)
    vBadge.Parent = titleBar
    safeNew("UICorner", {CornerRadius = UDim.new(0, 4)}, vBadge)

    -- Close
    local closeBtn = Instance.new("TextButton")
    closeBtn.Text = "X"
    closeBtn.Font = Fonts.Bold
    closeBtn.TextSize = 14
    closeBtn.TextColor3 = Theme.TextMuted
    closeBtn.BackgroundTransparency = 1
    closeBtn.Position = UDim2.new(1, -36, 0, 0)
    closeBtn.Size = UDim2.new(0, 36, 1, 0)
    closeBtn.Parent = titleBar
    closeBtn.MouseButton1Click:Connect(function() self:Toggle() end)
    closeBtn.MouseEnter:Connect(function()
        TweenService:Create(closeBtn, TweenInfo.new(0.15), {TextColor3 = Theme.Error}):Play()
    end)
    closeBtn.MouseLeave:Connect(function()
        TweenService:Create(closeBtn, TweenInfo.new(0.15), {TextColor3 = Theme.TextMuted}):Play()
    end)

    -- Minimize
    local minBtn = Instance.new("TextButton")
    minBtn.Text = "-"
    minBtn.Font = Fonts.Bold
    minBtn.TextSize = 18
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
    local dragging = false
    local dragStart, startPos

    titleBar.InputBegan:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1
        or input.UserInputType == Enum.UserInputType.Touch then
            dragging = true
            dragStart = input.Position
            startPos = self.MainFrame.Position
        end
    end)
    titleBar.InputEnded:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1
        or input.UserInputType == Enum.UserInputType.Touch then
            dragging = false
        end
    end)
    UserInputService.InputChanged:Connect(function(input)
        if dragging and (input.UserInputType == Enum.UserInputType.MouseMovement
                         or input.UserInputType == Enum.UserInputType.Touch) then
            local delta = input.Position - dragStart
            self.MainFrame.Position = UDim2.new(
                startPos.X.Scale, startPos.X.Offset + delta.X,
                startPos.Y.Scale, startPos.Y.Offset + delta.Y
            )
        end
    end)

    -- Sidebar
    local sidebar = Instance.new("Frame")
    sidebar.Name = "Sidebar"
    sidebar.Size = UDim2.new(0, 140, 1, -42)
    sidebar.Position = UDim2.new(0, 0, 0, 42)
    sidebar.BackgroundColor3 = Theme.Surface
    sidebar.BorderSizePixel = 0
    sidebar.Parent = self.MainFrame

    local sb = Instance.new("Frame")
    sb.Size = UDim2.new(0, 1, 1, 0)
    sb.Position = UDim2.new(1, 0, 0, 0)
    sb.BackgroundColor3 = Theme.Border
    sb.BorderSizePixel = 0
    sb.Parent = sidebar

    local tl = Instance.new("UIListLayout")
    tl.SortOrder = Enum.SortOrder.LayoutOrder
    tl.Padding = UDim.new(0, 2)
    tl.Parent = sidebar

    local tp = Instance.new("UIPadding")
    tp.PaddingTop = UDim.new(0, 8)
    tp.PaddingLeft = UDim.new(0, 6)
    tp.PaddingRight = UDim.new(0, 6)
    tp.Parent = sidebar

    self.Sidebar = sidebar

    -- Content Area
    self.ContentFrame = Instance.new("Frame")
    self.ContentFrame.Name = "Content"
    self.ContentFrame.Size = UDim2.new(1, -141, 1, -66)
    self.ContentFrame.Position = UDim2.new(0, 141, 0, 42)
    self.ContentFrame.BackgroundTransparency = 1
    self.ContentFrame.Parent = self.MainFrame

    -- Status Bar
    local statusBar = Instance.new("Frame")
    statusBar.Size = UDim2.new(1, 0, 0, 24)
    statusBar.Position = UDim2.new(0, 0, 1, -24)
    statusBar.BackgroundColor3 = Theme.Surface
    statusBar.BorderSizePixel = 0
    statusBar.ZIndex = 5
    statusBar.Parent = self.MainFrame

    local statusText = Instance.new("TextLabel")
    statusText.Text = "  Offsets: " .. OffsetStatus .. "  |  RightCtrl to toggle"
    statusText.Font = Fonts.Regular
    statusText.TextSize = 10
    statusText.TextColor3 = Theme.TextMuted
    statusText.BackgroundTransparency = 1
    statusText.Size = UDim2.new(1, 0, 1, 0)
    statusText.TextXAlignment = Enum.TextXAlignment.Left
    statusText.Parent = statusBar
    self.StatusText = statusText

    safeSpawn(function()
        while self.ScreenGui and self.ScreenGui.Parent do
            pcall(function()
                self.StatusText.Text = "  Offsets: " .. OffsetStatus .. "  |  RightCtrl to toggle"
            end)
            safeWait(5)
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
    tabBtn.LayoutOrder = order or (#self.Tabs + 1)
    tabBtn.AutoButtonColor = false
    tabBtn.Parent = self.Sidebar
    safeNew("UICorner", {CornerRadius = UDim.new(0, 6)}, tabBtn)

    local tabIcon = Instance.new("TextLabel")
    tabIcon.Text = icon or ">"
    tabIcon.Font = Fonts.Regular
    tabIcon.TextSize = 14
    tabIcon.TextColor3 = Theme.TextMuted
    tabIcon.BackgroundTransparency = 1
    tabIcon.Position = UDim2.new(0, 8, 0, 0)
    tabIcon.Size = UDim2.new(0, 24, 1, 0)
    tabIcon.Parent = tabBtn

    local tabLabel = Instance.new("TextLabel")
    tabLabel.Text = name
    tabLabel.Font = Fonts.Medium
    tabLabel.TextSize = 12
    tabLabel.TextColor3 = Theme.TextMuted
    tabLabel.BackgroundTransparency = 1
    tabLabel.Position = UDim2.new(0, 36, 0, 0)
    tabLabel.Size = UDim2.new(1, -40, 1, 0)
    tabLabel.TextXAlignment = Enum.TextXAlignment.Left
    tabLabel.Parent = tabBtn

    local indicator = Instance.new("Frame")
    indicator.Size = UDim2.new(0, 3, 0.6, 0)
    indicator.Position = UDim2.new(0, 0, 0.2, 0)
    indicator.BackgroundColor3 = Theme.Accent
    indicator.BorderSizePixel = 0
    indicator.Visible = false
    indicator.Parent = tabBtn
    safeNew("UICorner", {CornerRadius = UDim.new(0, 2)}, indicator)

    local content = Instance.new("ScrollingFrame")
    content.Name = "TC_" .. name
    content.Size = UDim2.new(1, -16, 1, -8)
    content.Position = UDim2.new(0, 8, 0, 4)
    content.BackgroundTransparency = 1
    content.ScrollBarThickness = 3
    content.ScrollBarImageColor3 = Theme.AccentSecondary
    content.BorderSizePixel = 0
    content.CanvasSize = UDim2.new(0, 0, 0, 0)
    content.Visible = false
    content.Parent = self.ContentFrame

    local cl = Instance.new("UIListLayout")
    cl.SortOrder = Enum.SortOrder.LayoutOrder
    cl.Padding = UDim.new(0, 4)
    cl.Parent = content

    cl:GetPropertyChangedSignal("AbsoluteContentSize"):Connect(function()
        content.CanvasSize = UDim2.new(0, 0, 0, cl.AbsoluteContentSize.Y + 16)
    end)

    local tabData = {
        Button = tabBtn, Content = content, Indicator = indicator,
        IconLabel = tabIcon, TextLabel = tabLabel, Name = name, Order = 0,
    }

    tabBtn.MouseButton1Click:Connect(function() self:SelectTab(name) end)
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
        local isActive = (tab.Name == name)
        tab.Content.Visible = isActive
        tab.Indicator.Visible = isActive
        TweenService:Create(tab.Button, TweenInfo.new(0.2), {BackgroundTransparency = isActive and 0.7 or 1}):Play()
        TweenService:Create(tab.TextLabel, TweenInfo.new(0.2), {TextColor3 = isActive and Theme.Text or Theme.TextMuted}):Play()
        TweenService:Create(tab.IconLabel, TweenInfo.new(0.2), {TextColor3 = isActive and Theme.Accent or Theme.TextMuted}):Play()
    end
    self.ActiveTab = name
end

function UI:CreateSection(tabData, title)
    local sec = Instance.new("Frame")
    sec.Size = UDim2.new(1, 0, 0, 26)
    sec.BackgroundTransparency = 1
    sec.LayoutOrder = tabData.Order
    tabData.Order = tabData.Order + 1
    sec.Parent = tabData.Content

    local ln = Instance.new("Frame")
    ln.Size = UDim2.new(1, 0, 0, 1)
    ln.Position = UDim2.new(0, 0, 0.5, 0)
    ln.BackgroundColor3 = Theme.Border
    ln.BorderSizePixel = 0
    ln.Parent = sec

    local lb = Instance.new("TextLabel")
    lb.Text = "  " .. title .. "  "
    lb.Font = Fonts.Bold
    lb.TextSize = 10
    lb.TextColor3 = Theme.AccentSecondary
    lb.BackgroundColor3 = Theme.Background
    lb.Position = UDim2.new(0, 12, 0, 5)
    lb.Size = UDim2.new(0, 100, 0, 16)
    lb.Parent = sec
end

function UI:CreateToggle(tabData, name, configTable, configKey, callback)
    local frame = Instance.new("Frame")
    frame.Size = UDim2.new(1, 0, 0, 32)
    frame.BackgroundColor3 = Theme.SurfaceLight
    frame.BackgroundTransparency = 0.3
    frame.BorderSizePixel = 0
    frame.LayoutOrder = tabData.Order
    tabData.Order = tabData.Order + 1
    frame.Parent = tabData.Content
    safeNew("UICorner", {CornerRadius = UDim.new(0, 6)}, frame)

    local label = Instance.new("TextLabel")
    label.Text = name
    label.Font = Fonts.Regular
    label.TextSize = 12
    label.TextColor3 = Theme.Text
    label.BackgroundTransparency = 1
    label.Position = UDim2.new(0, 12, 0, 0)
    label.Size = UDim2.new(1, -70, 1, 0)
    label.TextXAlignment = Enum.TextXAlignment.Left
    label.Parent = frame

    local toggleBg = Instance.new("Frame")
    toggleBg.Size = UDim2.new(0, 40, 0, 20)
    toggleBg.Position = UDim2.new(1, -52, 0.5, -10)
    toggleBg.BackgroundColor3 = configTable[configKey] and Theme.ToggleOn or Theme.ToggleOff
    toggleBg.BorderSizePixel = 0
    toggleBg.Parent = frame
    safeNew("UICorner", {CornerRadius = UDim.new(1, 0)}, toggleBg)

    local knob = Instance.new("Frame")
    knob.Size = UDim2.new(0, 16, 0, 16)
    knob.Position = configTable[configKey] and UDim2.new(1, -18, 0.5, -8) or UDim2.new(0, 2, 0.5, -8)
    knob.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
    knob.BorderSizePixel = 0
    knob.Parent = toggleBg
    safeNew("UICorner", {CornerRadius = UDim.new(1, 0)}, knob)

    local btn = Instance.new("TextButton")
    btn.Size = UDim2.new(1, 0, 1, 0)
    btn.BackgroundTransparency = 1
    btn.Text = ""
    btn.ZIndex = 2
    btn.Parent = frame

    btn.MouseButton1Click:Connect(function()
        configTable[configKey] = not configTable[configKey]
        local en = configTable[configKey]
        TweenService:Create(toggleBg, TweenInfo.new(0.2, Enum.EasingStyle.Quart), {
            BackgroundColor3 = en and Theme.ToggleOn or Theme.ToggleOff
        }):Play()
        TweenService:Create(knob, TweenInfo.new(0.2, Enum.EasingStyle.Quart), {
            Position = en and UDim2.new(1, -18, 0.5, -8) or UDim2.new(0, 2, 0.5, -8)
        }):Play()
        if callback then pcall(callback, en) end
    end)

    btn.MouseEnter:Connect(function()
        TweenService:Create(frame, TweenInfo.new(0.15), {BackgroundTransparency = 0.1}):Play()
    end)
    btn.MouseLeave:Connect(function()
        TweenService:Create(frame, TweenInfo.new(0.15), {BackgroundTransparency = 0.3}):Play()
    end)
end

function UI:CreateSlider(tabData, name, min, max, configTable, configKey, callback)
    local frame = Instance.new("Frame")
    frame.Size = UDim2.new(1, 0, 0, 46)
    frame.BackgroundColor3 = Theme.SurfaceLight
    frame.BackgroundTransparency = 0.3
    frame.BorderSizePixel = 0
    frame.LayoutOrder = tabData.Order
    tabData.Order = tabData.Order + 1
    frame.Parent = tabData.Content
    safeNew("UICorner", {CornerRadius = UDim.new(0, 6)}, frame)

    local label = Instance.new("TextLabel")
    label.Text = name
    label.Font = Fonts.Regular
    label.TextSize = 12
    label.TextColor3 = Theme.Text
    label.BackgroundTransparency = 1
    label.Position = UDim2.new(0, 12, 0, 2)
    label.Size = UDim2.new(1, -70, 0, 20)
    label.TextXAlignment = Enum.TextXAlignment.Left
    label.Parent = frame

    local vl = Instance.new("TextLabel")
    vl.Text = tostring(configTable[configKey])
    vl.Font = Fonts.Bold
    vl.TextSize = 11
    vl.TextColor3 = Theme.Accent
    vl.BackgroundTransparency = 1
    vl.Position = UDim2.new(1, -55, 0, 2)
    vl.Size = UDim2.new(0, 45, 0, 20)
    vl.TextXAlignment = Enum.TextXAlignment.Right
    vl.Parent = frame

    local track = Instance.new("Frame")
    track.Size = UDim2.new(1, -24, 0, 6)
    track.Position = UDim2.new(0, 12, 0, 30)
    track.BackgroundColor3 = Theme.Border
    track.BorderSizePixel = 0
    track.Parent = frame
    safeNew("UICorner", {CornerRadius = UDim.new(1, 0)}, track)

    local pct = math.clamp((configTable[configKey] - min) / math.max(max - min, 1), 0, 1)
    local fill = Instance.new("Frame")
    fill.Size = UDim2.new(pct, 0, 1, 0)
    fill.BackgroundColor3 = Theme.Accent
    fill.BorderSizePixel = 0
    fill.Parent = track
    safeNew("UICorner", {CornerRadius = UDim.new(1, 0)}, fill)
    safeNew("UIGradient", {
        Color = ColorSequence.new({
            ColorSequenceKeypoint.new(0, Theme.Accent),
            ColorSequenceKeypoint.new(1, Theme.AccentSecondary),
        })
    }, fill)

    local sliderBtn = Instance.new("TextButton")
    sliderBtn.Size = UDim2.new(1, 0, 0, 20)
    sliderBtn.Position = UDim2.new(0, 0, 0, 22)
    sliderBtn.BackgroundTransparency = 1
    sliderBtn.Text = ""
    sliderBtn.Parent = frame

    local sliding = false
    local function updateSlider(inputX)
        local aPos = track.AbsolutePosition.X
        local aSize = track.AbsoluteSize.X
        if aSize == 0 then return end
        local rel = math.clamp((inputX - aPos) / aSize, 0, 1)
        local val = math.floor(min + (max - min) * rel)
        configTable[configKey] = val
        vl.Text = tostring(val)
        fill.Size = UDim2.new(rel, 0, 1, 0)
        if callback then pcall(callback, val) end
    end

    sliderBtn.InputBegan:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1
        or input.UserInputType == Enum.UserInputType.Touch then
            sliding = true
            updateSlider(input.Position.X)
        end
    end)
    sliderBtn.InputEnded:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1
        or input.UserInputType == Enum.UserInputType.Touch then
            sliding = false
        end
    end)
    UserInputService.InputChanged:Connect(function(input)
        if sliding and (input.UserInputType == Enum.UserInputType.MouseMovement
                        or input.UserInputType == Enum.UserInputType.Touch) then
            updateSlider(input.Position.X)
        end
    end)
end

function UI:CreateDropdown(tabData, name, options, configTable, configKey, callback)
    local frame = Instance.new("Frame")
    frame.Size = UDim2.new(1, 0, 0, 32)
    frame.BackgroundColor3 = Theme.SurfaceLight
    frame.BackgroundTransparency = 0.3
    frame.BorderSizePixel = 0
    frame.ClipsDescendants = false
    frame.LayoutOrder = tabData.Order
    tabData.Order = tabData.Order + 1
    frame.ZIndex = 5
    frame.Parent = tabData.Content
    safeNew("UICorner", {CornerRadius = UDim.new(0, 6)}, frame)

    local label = Instance.new("TextLabel")
    label.Text = name
    label.Font = Fonts.Regular
    label.TextSize = 12
    label.TextColor3 = Theme.Text
    label.BackgroundTransparency = 1
    label.Position = UDim2.new(0, 12, 0, 0)
    label.Size = UDim2.new(0.5, 0, 1, 0)
    label.TextXAlignment = Enum.TextXAlignment.Left
    label.ZIndex = 5
    label.Parent = frame

    local selBtn = Instance.new("TextButton")
    selBtn.Text = tostring(configTable[configKey]) .. " v"
    selBtn.Font = Fonts.Medium
    selBtn.TextSize = 11
    selBtn.TextColor3 = Theme.Accent
    selBtn.BackgroundColor3 = Theme.Background
    selBtn.Position = UDim2.new(1, -130, 0.5, -12)
    selBtn.Size = UDim2.new(0, 118, 0, 24)
    selBtn.AutoButtonColor = false
    selBtn.ZIndex = 5
    selBtn.Parent = frame
    safeNew("UICorner", {CornerRadius = UDim.new(0, 4)}, selBtn)

    local dd = Instance.new("Frame")
    dd.Size = UDim2.new(0, 118, 0, #options * 26 + 4)
    dd.Position = UDim2.new(1, -130, 1, 2)
    dd.BackgroundColor3 = Theme.Surface
    dd.BorderSizePixel = 0
    dd.Visible = false
    dd.ZIndex = 50
    dd.Parent = frame
    safeNew("UICorner", {CornerRadius = UDim.new(0, 6)}, dd)
    safeNew("UIStroke", {Color = Theme.Border, Thickness = 1}, dd)

    local ddl = Instance.new("UIListLayout")
    ddl.Padding = UDim.new(0, 0)
    ddl.Parent = dd
    local ddp = Instance.new("UIPadding")
    ddp.PaddingTop = UDim.new(0, 2)
    ddp.PaddingBottom = UDim.new(0, 2)
    ddp.Parent = dd

    for _, opt in ipairs(options) do
        local ob = Instance.new("TextButton")
        ob.Text = tostring(opt)
        ob.Font = Fonts.Regular
        ob.TextSize = 11
        ob.TextColor3 = Theme.Text
        ob.BackgroundTransparency = 1
        ob.Size = UDim2.new(1, 0, 0, 26)
        ob.AutoButtonColor = false
        ob.ZIndex = 51
        ob.Parent = dd
        ob.MouseEnter:Connect(function() ob.BackgroundTransparency = 0.6; ob.BackgroundColor3 = Theme.Accent end)
        ob.MouseLeave:Connect(function() ob.BackgroundTransparency = 1 end)
        ob.MouseButton1Click:Connect(function()
            configTable[configKey] = opt
            selBtn.Text = tostring(opt) .. " v"
            dd.Visible = false
            if callback then pcall(callback, opt) end
        end)
    end

    selBtn.MouseButton1Click:Connect(function() dd.Visible = not dd.Visible end)
end

function UI:CreateButton(tabData, name, callback)
    local btn = Instance.new("TextButton")
    btn.Size = UDim2.new(1, 0, 0, 32)
    btn.BackgroundColor3 = Theme.AccentSecondary
    btn.BackgroundTransparency = 0.6
    btn.BorderSizePixel = 0
    btn.Text = name
    btn.Font = Fonts.Bold
    btn.TextSize = 12
    btn.TextColor3 = Theme.Text
    btn.AutoButtonColor = false
    btn.LayoutOrder = tabData.Order
    tabData.Order = tabData.Order + 1
    btn.Parent = tabData.Content
    safeNew("UICorner", {CornerRadius = UDim.new(0, 6)}, btn)

    btn.MouseEnter:Connect(function()
        TweenService:Create(btn, TweenInfo.new(0.15), {BackgroundTransparency = 0.3}):Play()
    end)
    btn.MouseLeave:Connect(function()
        TweenService:Create(btn, TweenInfo.new(0.15), {BackgroundTransparency = 0.6}):Play()
    end)
    btn.MouseButton1Click:Connect(function()
        if callback then pcall(callback) end
    end)
end

function UI:Toggle()
    self.Visible = not self.Visible
    self.MainFrame.Visible = self.Visible
end

function UI:Destroy()
    pcall(function() self.ScreenGui:Destroy() end)
end

-- ═══════════════════════════════════════════════════════════════
-- [SECTION 8] FEATURE IMPLEMENTATIONS
-- ═══════════════════════════════════════════════════════════════

local Features = {}
Features.AimbotTarget = nil
Features.FlyBody = nil
Features.OriginalLighting = {}
Features.ChamsCache = {}
Features.ESPDrawings = {}
Features.CrosshairDrawings = {}
Features.FOVCircleDrawing = nil
Features.HitMarkerLines = {}

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
                local sp, onScreen = WorldToScreen(bone.Position)
                if onScreen then
                    local mp = UserInputService:GetMouseLocation()
                    local dist = (sp - mp).Magnitude
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
    if not isHolding then self.AimbotTarget = nil; return end
    local target = self:GetClosestPlayer()
    if not target then return end
    self.AimbotTarget = target
    local targetPos = target.Position
    if Config.Aimbot.Prediction and target.Parent then
        local hrp = target.Parent:FindFirstChild("HumanoidRootPart")
        if hrp then
            local vel = Vector3.new(0, 0, 0)
            pcall(function() vel = hrp.AssemblyLinearVelocity end)
            if vel == Vector3.new(0, 0, 0) then pcall(function() vel = hrp.Velocity end) end
            targetPos = targetPos + vel * Config.Aimbot.PredictScale
        end
    end
    local currentCF = Camera.CFrame
    local targetCF = CFrame.lookAt(currentCF.Position, targetPos)
    local alpha = 1 / math.clamp(Config.Aimbot.Smoothing, 1, 20)
    Camera.CFrame = currentCF:Lerp(targetCF, alpha)
end

-- ─── SILENT AIM ──────────────────────────────────────────────

local SilentAimInit = false

function Features:InitSilentAim()
    if SilentAimInit then return end
    if not HAS_HOOKMT then return end
    pcall(function()
        local mt = getrawmetatable(game)
        local oldNC = mt.__namecall
        if setreadonly then setreadonly(mt, false) end
        if make_writeable then make_writeable(mt) end
        mt.__namecall = newcclosure(function(self2, ...)
            local method = getnamecallmethod()
            local args = {...}
            if Config.SilentAim.Enabled and (method == "FireServer" or method == "InvokeServer") then
                local tgt = Features:GetSilentTarget()
                if tgt and math.random(1, 100) <= Config.SilentAim.HitChance then
                    for i, v in pairs(args) do
                        if typeof(v) == "CFrame" then args[i] = CFrame.new(tgt.Position)
                        elseif typeof(v) == "Vector3" then args[i] = tgt.Position end
                    end
                    return oldNC(self2, unpack(args))
                end
            end
            return oldNC(self2, ...)
        end)
        if setreadonly then setreadonly(mt, true) end
        if make_readonly then make_readonly(mt) end
        SilentAimInit = true
    end)
end

function Features:GetSilentTarget()
    local closest, closestDist = nil, Config.Aimbot.FOV
    for _, player in ipairs(Players:GetPlayers()) do
        if player ~= LocalPlayer and IsAlive(player) and IsEnemy(player, Config.SilentAim.TeamCheck) then
            local char = GetCharacter(player)
            local bone = GetBone(char, Config.SilentAim.TargetBone)
            if bone then
                local sp, onScreen = WorldToScreen(bone.Position)
                if onScreen then
                    local dist = (sp - UserInputService:GetMouseLocation()).Magnitude
                    if dist < closestDist then closest = bone; closestDist = dist end
                end
            end
        end
    end
    return closest
end

-- ─── TRIGGERBOT ──────────────────────────────────────────────

function Features:RunTriggerbot()
    if not Config.Triggerbot.Enabled or not IsAlive(LocalPlayer) then return end
    local mp = UserInputService:GetMouseLocation()
    local ray = Camera:ViewportPointToRay(mp.X, mp.Y)
    local params = RaycastParams.new()
    params.FilterType = FilterExclude
    params.FilterDescendantsInstances = {LocalPlayer.Character}
    local result = Workspace:Raycast(ray.Origin, ray.Direction * 1000, params)
    if result and result.Instance then
        local hitModel = result.Instance:FindFirstAncestorOfClass("Model")
        if hitModel then
            local hitPlayer = Players:GetPlayerFromCharacter(hitModel)
            if hitPlayer and IsEnemy(hitPlayer, Config.Triggerbot.TeamCheck) and IsAlive(hitPlayer) then
                safeWait(Config.Triggerbot.Delay / 1000)
                if VIM then
                    pcall(function()
                        VIM:SendMouseButtonEvent(mp.X, mp.Y, 0, true, game, 0)
                        safeWait(0.03)
                        VIM:SendMouseButtonEvent(mp.X, mp.Y, 0, false, game, 0)
                    end)
                elseif mouse1click then
                    pcall(mouse1click)
                end
            end
        end
    end
end

-- ─── NO RECOIL ───────────────────────────────────────────────

local StoredCamCF = nil
function Features:RunNoRecoil()
    if not Config.NoRecoil.Enabled then return end
    if UserInputService:IsMouseButtonPressed(Enum.UserInputType.MouseButton1) then
        if StoredCamCF then Camera.CFrame = CFrame.new(Camera.CFrame.Position) * StoredCamCF.Rotation end
    else
        StoredCamCF = Camera.CFrame
    end
end

-- ─── ESP ─────────────────────────────────────────────────────

function Features:InitESP(player)
    if player == LocalPlayer or not HAS_DRAWING then return end
    self.ESPDrawings[player] = {
        BoxT  = CreateDrawing("Line", {Visible=false, Color=Config.ESP.BoxColor, Thickness=1}),
        BoxR  = CreateDrawing("Line", {Visible=false, Color=Config.ESP.BoxColor, Thickness=1}),
        BoxB  = CreateDrawing("Line", {Visible=false, Color=Config.ESP.BoxColor, Thickness=1}),
        BoxL  = CreateDrawing("Line", {Visible=false, Color=Config.ESP.BoxColor, Thickness=1}),
        Name  = CreateDrawing("Text", {Visible=false, Color=Config.ESP.NameColor, Size=13, Center=true, Outline=true, Font=2}),
        HpBG  = CreateDrawing("Line", {Visible=false, Color=Color3.fromRGB(30,30,30), Thickness=4}),
        HpFill= CreateDrawing("Line", {Visible=false, Color=Color3.fromRGB(0,255,0), Thickness=2}),
        HpTxt = CreateDrawing("Text", {Visible=false, Color=Color3.fromRGB(255,255,255), Size=10, Center=false, Outline=true, Font=2}),
        Dist  = CreateDrawing("Text", {Visible=false, Color=Color3.fromRGB(139,148,158), Size=10, Center=true, Outline=true, Font=2}),
        Tracer= CreateDrawing("Line", {Visible=false, Color=Config.ESP.BoxColor, Thickness=1}),
        Skel  = {},
    }
    local skelKeys = {
        "Head_UpperTorso","UpperTorso_LeftUpperArm","LeftUpperArm_LeftLowerArm","LeftLowerArm_LeftHand",
        "UpperTorso_RightUpperArm","RightUpperArm_RightLowerArm","RightLowerArm_RightHand",
        "UpperTorso_LowerTorso","LowerTorso_LeftUpperLeg","LeftUpperLeg_LeftLowerLeg","LeftLowerLeg_LeftFoot",
        "LowerTorso_RightUpperLeg","RightUpperLeg_RightLowerLeg","RightLowerLeg_RightFoot"
    }
    for _, k in ipairs(skelKeys) do
        self.ESPDrawings[player].Skel[k] = CreateDrawing("Line", {Visible=false, Color=Theme.Accent, Thickness=1})
    end
end

local function HideESP(d)
    if not d then return end
    for k, v in pairs(d) do
        if type(v) == "table" and not (v.Remove) then
            for _, sub in pairs(v) do if sub then pcall(function() sub.Visible = false end) end end
        elseif v and v.Remove then pcall(function() v.Visible = false end) end
    end
end

local function RemoveESP(d)
    if not d then return end
    for k, v in pairs(d) do
        if type(v) == "table" and not (v.Remove) then
            for _, sub in pairs(v) do SafeDR(sub) end
        else SafeDR(v) end
    end
end

function Features:UpdateESP()
    if not HAS_DRAWING then return end
    if not Config.ESP.Enabled then
        for _, d in pairs(self.ESPDrawings) do HideESP(d) end
        return
    end
    for _, player in ipairs(Players:GetPlayers()) do
        if player ~= LocalPlayer then
            if not self.ESPDrawings[player] then self:InitESP(player) end
            local d = self.ESPDrawings[player]
            if d then
                local char = GetCharacter(player)
                local isEn = IsEnemy(player, Config.ESP.TeamCheck)
                if not char or not IsAlive(player) or not isEn then
                    HideESP(d)
                else
                    local hrp = char:FindFirstChild("HumanoidRootPart")
                    local head = char:FindFirstChild("Head")
                    local hum = char:FindFirstChildOfClass("Humanoid")
                    if not hrp or not head or not hum then HideESP(d)
                    else
                        local pos, onScr, depth = WorldToScreen(hrp.Position)
                        if not onScr or depth < 0 then HideESP(d)
                        else
                            local hp = WorldToScreen(head.Position + Vector3.new(0,0.5,0))
                            local fp = WorldToScreen(hrp.Position - Vector3.new(0,3,0))
                            local bh = math.abs(hp.Y - fp.Y)
                            local bw = bh * 0.6
                            local col = Config.ESP.BoxColor
                            if Config.ESP.TeamColor and player.Team then pcall(function() col = player.TeamColor.Color end) end

                            if Config.ESP.Boxes then
                                local tl = Vector2.new(pos.X-bw/2, hp.Y)
                                local tr = Vector2.new(pos.X+bw/2, hp.Y)
                                local bl = Vector2.new(pos.X-bw/2, fp.Y)
                                local br = Vector2.new(pos.X+bw/2, fp.Y)
                                SafeDP(d.BoxT,"From",tl) SafeDP(d.BoxT,"To",tr) SafeDP(d.BoxT,"Color",col) SafeDP(d.BoxT,"Visible",true)
                                SafeDP(d.BoxR,"From",tr) SafeDP(d.BoxR,"To",br) SafeDP(d.BoxR,"Color",col) SafeDP(d.BoxR,"Visible",true)
                                SafeDP(d.BoxB,"From",br) SafeDP(d.BoxB,"To",bl) SafeDP(d.BoxB,"Color",col) SafeDP(d.BoxB,"Visible",true)
                                SafeDP(d.BoxL,"From",bl) SafeDP(d.BoxL,"To",tl) SafeDP(d.BoxL,"Color",col) SafeDP(d.BoxL,"Visible",true)
                            else
                                SafeDP(d.BoxT,"Visible",false) SafeDP(d.BoxR,"Visible",false)
                                SafeDP(d.BoxB,"Visible",false) SafeDP(d.BoxL,"Visible",false)
                            end

                            if Config.ESP.Names and d.Name then
                                SafeDP(d.Name,"Position",Vector2.new(pos.X,hp.Y-16))
                                SafeDP(d.Name,"Text",player.DisplayName or player.Name)
                                SafeDP(d.Name,"Color",Config.ESP.NameColor)
                                SafeDP(d.Name,"Visible",true)
                            elseif d.Name then SafeDP(d.Name,"Visible",false) end

                            if Config.ESP.Health and d.HpBG then
                                local pct = math.clamp(hum.Health/hum.MaxHealth,0,1)
                                local bx = pos.X-bw/2-6
                                local bt,bb = hp.Y,fp.Y
                                local bf = bb-(bb-bt)*pct
                                SafeDP(d.HpBG,"From",Vector2.new(bx,bt)) SafeDP(d.HpBG,"To",Vector2.new(bx,bb)) SafeDP(d.HpBG,"Visible",true)
                                SafeDP(d.HpFill,"From",Vector2.new(bx,bf)) SafeDP(d.HpFill,"To",Vector2.new(bx,bb))
                                SafeDP(d.HpFill,"Color",Color3.fromRGB(255*(1-pct),255*pct,0)) SafeDP(d.HpFill,"Visible",true)
                                SafeDP(d.HpTxt,"Position",Vector2.new(bx-4,bf-6))
                                SafeDP(d.HpTxt,"Text",tostring(math.floor(hum.Health))) SafeDP(d.HpTxt,"Visible",pct<1)
                            else
                                SafeDP(d.HpBG,"Visible",false) SafeDP(d.HpFill,"Visible",false) SafeDP(d.HpTxt,"Visible",false)
                            end

                            if Config.ESP.Distance and d.Dist then
                                SafeDP(d.Dist,"Position",Vector2.new(pos.X,fp.Y+2))
                                SafeDP(d.Dist,"Text",math.floor((hrp.Position-Camera.CFrame.Position).Magnitude).."m")
                                SafeDP(d.Dist,"Visible",true)
                            elseif d.Dist then SafeDP(d.Dist,"Visible",false) end

                            if Config.ESP.Tracers and d.Tracer then
                                local vp = Camera.ViewportSize
                                local orig
                                if Config.ESP.TracerOrigin == "Bottom" then orig = Vector2.new(vp.X/2,vp.Y)
                                elseif Config.ESP.TracerOrigin == "Top" then orig = Vector2.new(vp.X/2,0)
                                else orig = Vector2.new(vp.X/2,vp.Y/2) end
                                SafeDP(d.Tracer,"From",orig) SafeDP(d.Tracer,"To",Vector2.new(pos.X,fp.Y))
                                SafeDP(d.Tracer,"Color",col) SafeDP(d.Tracer,"Visible",true)
                            elseif d.Tracer then SafeDP(d.Tracer,"Visible",false) end

                            if Config.ESP.Skeleton and d.Skel then
                                local conns = {{"Head","UpperTorso"},{"UpperTorso","LeftUpperArm"},{"LeftUpperArm","LeftLowerArm"},
                                    {"LeftLowerArm","LeftHand"},{"UpperTorso","RightUpperArm"},{"RightUpperArm","RightLowerArm"},
                                    {"RightLowerArm","RightHand"},{"UpperTorso","LowerTorso"},{"LowerTorso","LeftUpperLeg"},
                                    {"LeftUpperLeg","LeftLowerLeg"},{"LeftLowerLeg","LeftFoot"},{"LowerTorso","RightUpperLeg"},
                                    {"RightUpperLeg","RightLowerLeg"},{"RightLowerLeg","RightFoot"}}
                                for _, c in ipairs(conns) do
                                    local key = c[1].."_"..c[2]
                                    local ln = d.Skel[key]
                                    if ln then
                                        local p1,p2 = char:FindFirstChild(c[1]), char:FindFirstChild(c[2])
                                        if p1 and p2 then
                                            local s1,v1 = WorldToScreen(p1.Position)
                                            local s2,v2 = WorldToScreen(p2.Position)
                                            if v1 and v2 then
                                                SafeDP(ln,"From",s1) SafeDP(ln,"To",s2) SafeDP(ln,"Visible",true)
                                            else SafeDP(ln,"Visible",false) end
                                        else SafeDP(ln,"Visible",false) end
                                    end
                                end
                            elseif d.Skel then
                                for _, ln in pairs(d.Skel) do if ln then SafeDP(ln,"Visible",false) end end
                            end
                        end
                    end
                end
            end
        end
    end
end

-- ─── CHAMS ───────────────────────────────────────────────────

function Features:UpdateChams()
    for _, player in ipairs(Players:GetPlayers()) do
        if player ~= LocalPlayer then
            local char = GetCharacter(player)
            local isEn = IsEnemy(player, Config.Chams.TeamCheck)
            if Config.Chams.Enabled and char and IsAlive(player) and isEn then
                if not self.ChamsCache[player] then
                    pcall(function()
                        local h = Instance.new("Highlight")
                        h.Name = "BSChams"
                        h.FillColor = Config.Chams.FillColor
                        h.OutlineColor = Config.Chams.OutlineColor
                        h.FillTransparency = Config.Chams.FillTransparency
                        h.OutlineTransparency = Config.Chams.OutlineTransparency
                        h.DepthMode = Enum.HighlightDepthMode.AlwaysOnTop
                        h.Adornee = char
                        h.Parent = char
                        self.ChamsCache[player] = h
                    end)
                else
                    pcall(function()
                        local h = self.ChamsCache[player]
                        h.FillColor = Config.Chams.FillColor
                        h.OutlineColor = Config.Chams.OutlineColor
                        h.Adornee = char
                    end)
                end
            else
                if self.ChamsCache[player] then
                    pcall(function() self.ChamsCache[player]:Destroy() end)
                    self.ChamsCache[player] = nil
                end
            end
        end
    end
end

-- ─── CROSSHAIR ───────────────────────────────────────────────

function Features:InitCrosshair()
    if not HAS_DRAWING then return end
    self.CrosshairDrawings = {
        T = CreateDrawing("Line",{Visible=false,Thickness=1,Color=Config.Crosshair.Color}),
        B = CreateDrawing("Line",{Visible=false,Thickness=1,Color=Config.Crosshair.Color}),
        L = CreateDrawing("Line",{Visible=false,Thickness=1,Color=Config.Crosshair.Color}),
        R = CreateDrawing("Line",{Visible=false,Thickness=1,Color=Config.Crosshair.Color}),
        D = CreateDrawing("Circle",{Visible=false,Filled=true,Color=Config.Crosshair.Color,Radius=2,NumSides=12}),
    }
end

function Features:UpdateCrosshair()
    if not HAS_DRAWING then return end
    if not Config.Crosshair.Enabled then
        for _, d in pairs(self.CrosshairDrawings) do if d then SafeDP(d,"Visible",false) end end
        return
    end
    local c = GetScreenCenter()
    local s,g,col,t = Config.Crosshair.Size, Config.Crosshair.Gap, Config.Crosshair.Color, Config.Crosshair.Thickness
    if self.CrosshairDrawings.T then
        SafeDP(self.CrosshairDrawings.T,"From",Vector2.new(c.X,c.Y-g-s)) SafeDP(self.CrosshairDrawings.T,"To",Vector2.new(c.X,c.Y-g))
        SafeDP(self.CrosshairDrawings.T,"Color",col) SafeDP(self.CrosshairDrawings.T,"Thickness",t) SafeDP(self.CrosshairDrawings.T,"Visible",true)
    end
    if self.CrosshairDrawings.B then
        SafeDP(self.CrosshairDrawings.B,"From",Vector2.new(c.X,c.Y+g)) SafeDP(self.CrosshairDrawings.B,"To",Vector2.new(c.X,c.Y+g+s))
        SafeDP(self.CrosshairDrawings.B,"Color",col) SafeDP(self.CrosshairDrawings.B,"Thickness",t) SafeDP(self.CrosshairDrawings.B,"Visible",true)
    end
    if self.CrosshairDrawings.L then
        SafeDP(self.CrosshairDrawings.L,"From",Vector2.new(c.X-g-s,c.Y)) SafeDP(self.CrosshairDrawings.L,"To",Vector2.new(c.X-g,c.Y))
        SafeDP(self.CrosshairDrawings.L,"Color",col) SafeDP(self.CrosshairDrawings.L,"Thickness",t) SafeDP(self.CrosshairDrawings.L,"Visible",true)
    end
    if self.CrosshairDrawings.R then
        SafeDP(self.CrosshairDrawings.R,"From",Vector2.new(c.X+g,c.Y)) SafeDP(self.CrosshairDrawings.R,"To",Vector2.new(c.X+g+s,c.Y))
        SafeDP(self.CrosshairDrawings.R,"Color",col) SafeDP(self.CrosshairDrawings.R,"Thickness",t) SafeDP(self.CrosshairDrawings.R,"Visible",true)
    end
    if self.CrosshairDrawings.D then
        SafeDP(self.CrosshairDrawings.D,"Position",c) SafeDP(self.CrosshairDrawings.D,"Color",col)
        SafeDP(self.CrosshairDrawings.D,"Visible",Config.Crosshair.Dot)
    end
end

-- ─── FOV CIRCLE ──────────────────────────────────────────────

function Features:InitFOVCircle()
    if not HAS_DRAWING then return end
    self.FOVCircleDrawing = CreateDrawing("Circle", {
        Visible=false,Filled=false,Color=Config.FOVCircle.Color,
        Transparency=Config.FOVCircle.Transparency,Radius=Config.Aimbot.FOV,NumSides=64,Thickness=1
    })
end

function Features:UpdateFOVCircle()
    if not HAS_DRAWING or not self.FOVCircleDrawing then return end
    if Config.Aimbot.ShowFOV and Config.Aimbot.Enabled then
        SafeDP(self.FOVCircleDrawing,"Position",UserInputService:GetMouseLocation())
        SafeDP(self.FOVCircleDrawing,"Radius",Config.Aimbot.FOV)
        SafeDP(self.FOVCircleDrawing,"Visible",true)
    else
        SafeDP(self.FOVCircleDrawing,"Visible",false)
    end
end

-- ─── MOVEMENT ────────────────────────────────────────────────

function Features:RunBunnyHop()
    if not Config.BunnyHop.Enabled or not IsAlive(LocalPlayer) then return end
    local hum = GetCharacter(LocalPlayer) and GetCharacter(LocalPlayer):FindFirstChildOfClass("Humanoid")
    if hum and hum.FloorMaterial ~= Enum.Material.Air and UserInputService:IsKeyDown(Enum.KeyCode.Space) then
        hum:ChangeState(Enum.HumanoidStateType.Jumping)
    end
end

function Features:RunSpeedBoost()
    if not IsAlive(LocalPlayer) then return end
    local hum = GetCharacter(LocalPlayer) and GetCharacter(LocalPlayer):FindFirstChildOfClass("Humanoid")
    if hum and Config.SpeedBoost.Enabled then hum.WalkSpeed = Config.SpeedBoost.Speed end
end

function Features:InitInfiniteJump()
    UserInputService.JumpRequest:Connect(function()
        if not Config.InfiniteJump.Enabled or not IsAlive(LocalPlayer) then return end
        local hum = GetCharacter(LocalPlayer) and GetCharacter(LocalPlayer):FindFirstChildOfClass("Humanoid")
        if hum then hum:ChangeState(Enum.HumanoidStateType.Jumping) end
    end)
end

function Features:RunFly()
    if not IsAlive(LocalPlayer) then return end
    local char = GetCharacter(LocalPlayer)
    local hrp = char and char:FindFirstChild("HumanoidRootPart")
    local hum = char and char:FindFirstChildOfClass("Humanoid")
    if not hrp or not hum then return end

    if Config.Fly.Enabled then
        if not self.FlyBody then
            pcall(function()
                local bv = Instance.new("BodyVelocity")
                bv.Name = "BSFly"; bv.MaxForce = Vector3.new(9e9,9e9,9e9); bv.Velocity = Vector3.new(0,0,0); bv.Parent = hrp
                local bg = Instance.new("BodyGyro")
                bg.Name = "BSGyro"; bg.MaxTorque = Vector3.new(9e9,9e9,9e9); bg.D = 200; bg.Parent = hrp
                self.FlyBody = {V = bv, G = bg}
            end)
        end
        if self.FlyBody then
            local dir = Vector3.new(0,0,0)
            if UserInputService:IsKeyDown(Enum.KeyCode.W) then dir = dir + Camera.CFrame.LookVector end
            if UserInputService:IsKeyDown(Enum.KeyCode.S) then dir = dir - Camera.CFrame.LookVector end
            if UserInputService:IsKeyDown(Enum.KeyCode.A) then dir = dir - Camera.CFrame.RightVector end
            if UserInputService:IsKeyDown(Enum.KeyCode.D) then dir = dir + Camera.CFrame.RightVector end
            if UserInputService:IsKeyDown(Enum.KeyCode.Space) then dir = dir + Vector3.new(0,1,0) end
            if UserInputService:IsKeyDown(Enum.KeyCode.LeftControl) then dir = dir - Vector3.new(0,1,0) end
            pcall(function() self.FlyBody.V.Velocity = dir * Config.Fly.Speed; self.FlyBody.G.CFrame = Camera.CFrame end)
            hum.PlatformStand = true
        end
    else
        if self.FlyBody then
            pcall(function() self.FlyBody.V:Destroy() end)
            pcall(function() self.FlyBody.G:Destroy() end)
            self.FlyBody = nil
            hum.PlatformStand = false
        end
    end
end

function Features:RunNoclip()
    if not Config.Noclip.Enabled or not IsAlive(LocalPlayer) then return end
    local char = GetCharacter(LocalPlayer)
    if char then for _, p in ipairs(char:GetDescendants()) do if p:IsA("BasePart") then p.CanCollide = false end end end
end

-- ─── MISC ────────────────────────────────────────────────────

function Features:InitAntiAFK()
    pcall(function()
        local gc = getconnections or get_signal_cons
        if gc then for _, c in ipairs(gc(LocalPlayer.Idled)) do c:Disable() end end
    end)
    if VirtualUser then
        safeSpawn(function()
            while true do
                safeWait(60)
                if Config.AntiAFK.Enabled then
                    pcall(function() VirtualUser:Button2Down(Vector2.new(0,0), Camera.CFrame); safeWait(0.1); VirtualUser:Button2Up(Vector2.new(0,0), Camera.CFrame) end)
                end
            end
        end)
    end
end

function Features:RunFullbright()
    if Config.Fullbright.Enabled then
        if not self.OriginalLighting.Ambient then
            self.OriginalLighting.Ambient = Lighting.Ambient
            self.OriginalLighting.Brightness = Lighting.Brightness
            self.OriginalLighting.OutdoorAmbient = Lighting.OutdoorAmbient
        end
        Lighting.Ambient = Color3.fromRGB(200,200,200)
        Lighting.Brightness = 2
        Lighting.OutdoorAmbient = Color3.fromRGB(200,200,200)
    elseif self.OriginalLighting.Ambient then
        Lighting.Ambient = self.OriginalLighting.Ambient
        Lighting.Brightness = self.OriginalLighting.Brightness
        Lighting.OutdoorAmbient = self.OriginalLighting.OutdoorAmbient
    end
end

function Features:RunNoFog()
    if Config.NoFog.Enabled then
        if not self.OriginalLighting.FogEnd then
            self.OriginalLighting.FogEnd = Lighting.FogEnd
            self.OriginalLighting.FogStart = Lighting.FogStart
        end
        Lighting.FogEnd = 999999; Lighting.FogStart = 999999
    elseif self.OriginalLighting.FogEnd then
        Lighting.FogEnd = self.OriginalLighting.FogEnd
        Lighting.FogStart = self.OriginalLighting.FogStart
    end
end

function Features:InitKillSound()
    local function hook(p)
        pcall(function()
            local function onChar(ch)
                local h = ch:WaitForChild("Humanoid",5)
                if h then h.Died:Connect(function()
                    if Config.KillSound.Enabled then
                        pcall(function()
                            local s = Instance.new("Sound"); s.SoundId = Config.KillSound.SoundId; s.Volume = 1; s.Parent = Camera; s:Play()
                            game:GetService("Debris"):AddItem(s,3)
                        end)
                    end
                end) end
            end
            if p.Character then safeSpawn(function() onChar(p.Character) end) end
            p.CharacterAdded:Connect(onChar)
        end)
    end
    for _, p in ipairs(Players:GetPlayers()) do if p ~= LocalPlayer then hook(p) end end
    Players.PlayerAdded:Connect(function(p) hook(p) end)
end

function Features:RunThirdPerson()
    if Config.ThirdPerson.Enabled then
        LocalPlayer.CameraMinZoomDistance = Config.ThirdPerson.Distance
        LocalPlayer.CameraMaxZoomDistance = Config.ThirdPerson.Distance + 5
    end
end

-- ═══════════════════════════════════════════════════════════════
-- [SECTION 9] PLAYER CLEANUP
-- ═══════════════════════════════════════════════════════════════

Players.PlayerRemoving:Connect(function(player)
    if Features.ESPDrawings[player] then RemoveESP(Features.ESPDrawings[player]); Features.ESPDrawings[player] = nil end
    if Features.ChamsCache[player] then pcall(function() Features.ChamsCache[player]:Destroy() end); Features.ChamsCache[player] = nil end
end)

-- ═══════════════════════════════════════════════════════════════
-- [SECTION 10] BUILD UI
-- ═══════════════════════════════════════════════════════════════

UI:Init()

local combatTab = UI:CreateTab("Combat", "[+]", 1)
UI:CreateSection(combatTab, "AIMBOT")
UI:CreateToggle(combatTab, "Enable Aimbot", Config.Aimbot, "Enabled")
UI:CreateSlider(combatTab, "Smoothing", 1, 20, Config.Aimbot, "Smoothing")
UI:CreateSlider(combatTab, "FOV Radius", 20, 500, Config.Aimbot, "FOV")
UI:CreateDropdown(combatTab, "Target Bone", {"Head","Torso","HumanoidRootPart"}, Config.Aimbot, "TargetBone")
UI:CreateToggle(combatTab, "Team Check", Config.Aimbot, "TeamCheck")
UI:CreateToggle(combatTab, "Wall Check", Config.Aimbot, "WallCheck")
UI:CreateToggle(combatTab, "Prediction", Config.Aimbot, "Prediction")
UI:CreateToggle(combatTab, "Show FOV Circle", Config.Aimbot, "ShowFOV")
UI:CreateSection(combatTab, "SILENT AIM")
UI:CreateToggle(combatTab, "Enable Silent Aim", Config.SilentAim, "Enabled", function(v) if v then Features:InitSilentAim() end end)
UI:CreateSlider(combatTab, "Hit Chance (%)", 1, 100, Config.SilentAim, "HitChance")
UI:CreateDropdown(combatTab, "Target Bone", {"Head","Torso","HumanoidRootPart"}, Config.SilentAim, "TargetBone")
UI:CreateSection(combatTab, "TRIGGERBOT")
UI:CreateToggle(combatTab, "Enable Triggerbot", Config.Triggerbot, "Enabled")
UI:CreateSlider(combatTab, "Trigger Delay (ms)", 0, 300, Config.Triggerbot, "Delay")
UI:CreateToggle(combatTab, "Team Check", Config.Triggerbot, "TeamCheck")
UI:CreateSection(combatTab, "WEAPON MODS")
UI:CreateToggle(combatTab, "No Recoil", Config.NoRecoil, "Enabled")

local visualsTab = UI:CreateTab("Visuals", "[o]", 2)
UI:CreateSection(visualsTab, "PLAYER ESP")
UI:CreateToggle(visualsTab, "Enable ESP", Config.ESP, "Enabled")
UI:CreateToggle(visualsTab, "Boxes", Config.ESP, "Boxes")
UI:CreateToggle(visualsTab, "Names", Config.ESP, "Names")
UI:CreateToggle(visualsTab, "Health Bars", Config.ESP, "Health")
UI:CreateToggle(visualsTab, "Distance", Config.ESP, "Distance")
UI:CreateToggle(visualsTab, "Skeleton", Config.ESP, "Skeleton")
UI:CreateToggle(visualsTab, "Tracers", Config.ESP, "Tracers")
UI:CreateDropdown(visualsTab, "Tracer Origin", {"Bottom","Top","Center"}, Config.ESP, "TracerOrigin")
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

local moveTab = UI:CreateTab("Movement", "[>]", 3)
UI:CreateSection(moveTab, "MOVEMENT MODS")
UI:CreateToggle(moveTab, "Bunny Hop", Config.BunnyHop, "Enabled")
UI:CreateToggle(moveTab, "Speed Boost", Config.SpeedBoost, "Enabled")
UI:CreateSlider(moveTab, "Walk Speed", 16, 60, Config.SpeedBoost, "Speed")
UI:CreateToggle(moveTab, "Infinite Jump", Config.InfiniteJump, "Enabled")
UI:CreateSection(moveTab, "ADVANCED")
UI:CreateToggle(moveTab, "Fly", Config.Fly, "Enabled")
UI:CreateSlider(moveTab, "Fly Speed", 10, 200, Config.Fly, "Speed")
UI:CreateToggle(moveTab, "Noclip", Config.Noclip, "Enabled")

local miscTab = UI:CreateTab("Misc", "[*]", 4)
UI:CreateSection(miscTab, "UTILITIES")
UI:CreateToggle(miscTab, "Anti-AFK", Config.AntiAFK, "Enabled")
UI:CreateToggle(miscTab, "Kill Sound", Config.KillSound, "Enabled")
UI:CreateToggle(miscTab, "Third Person Lock", Config.ThirdPerson, "Enabled")
UI:CreateSlider(miscTab, "Camera Distance", 5, 30, Config.ThirdPerson, "Distance")
UI:CreateSection(miscTab, "OFFSETS")
UI:CreateButton(miscTab, "Force Refresh Offsets", function()
    Notify("Offsets", "Refreshing...", 2)
    safeSpawn(function()
        local ok = FetchOffsets()
        Notify("Offsets", ok and ("Updated: " .. OffsetVersion) or "Refresh failed!", 3)
    end)
end)
UI:CreateButton(miscTab, "Show Offset Version", function()
    Notify("Version", "Roblox: " .. OffsetVersion .. " | Script: v2.2", 4)
end)

local settingsTab = UI:CreateTab("Settings", "[=]", 5)
UI:CreateSection(settingsTab, "GENERAL")
UI:CreateButton(settingsTab, "Unload Script", function()
    Notify("Unloading", "Cleaning up...", 2)
    safeSpawn(function()
        safeWait(1)
        for _, d in pairs(Features.ESPDrawings) do RemoveESP(d) end
        for _, d in pairs(Features.CrosshairDrawings) do SafeDR(d) end
        SafeDR(Features.FOVCircleDrawing)
        for _, h in pairs(Features.ChamsCache) do pcall(function() h:Destroy() end) end
        if Features.FlyBody then pcall(function() Features.FlyBody.V:Destroy() end); pcall(function() Features.FlyBody.G:Destroy() end) end
        Config.Fullbright.Enabled = false; Features:RunFullbright()
        Config.NoFog.Enabled = false; Features:RunNoFog()
        UI:Destroy()
    end)
end)
UI:CreateButton(settingsTab, "Toggle Key: RightCtrl", function()
    Notify("Info", "Press RightCtrl to show/hide the menu", 3)
end)

UI:SelectTab("Combat")

-- ═══════════════════════════════════════════════════════════════
-- [SECTION 11] MAIN LOOPS
-- ═══════════════════════════════════════════════════════════════

Features:InitCrosshair()
Features:InitFOVCircle()
Features:InitInfiniteJump()
Features:InitAntiAFK()
Features:InitKillSound()
pcall(function() Features:InitSilentAim() end)

RunService.RenderStepped:Connect(function()
    Camera = Workspace.CurrentCamera
    pcall(function() Features:RunAimbot() end)
    pcall(function() Features:RunNoRecoil() end)
    pcall(function() Features:UpdateESP() end)
    pcall(function() Features:UpdateCrosshair() end)
    pcall(function() Features:UpdateFOVCircle() end)
    pcall(function() Features:RunNoclip() end)
    pcall(function() Features:RunFly() end)
end)

RunService.Heartbeat:Connect(function()
    pcall(function() Features:RunTriggerbot() end)
    pcall(function() Features:RunBunnyHop() end)
    pcall(function() Features:RunSpeedBoost() end)
    pcall(function() Features:UpdateChams() end)
    pcall(function() Features:RunFullbright() end)
    pcall(function() Features:RunNoFog() end)
    pcall(function() Features:RunThirdPerson() end)
end)

-- ═══════════════════════════════════════════════════════════════
-- [SECTION 12] KEYBIND + STARTUP
-- ═══════════════════════════════════════════════════════════════

UserInputService.InputBegan:Connect(function(input, gpe)
    if gpe then return end
    if input.KeyCode == Config.MenuKey then UI:Toggle() end
end)

safeSpawn(function()
    safeWait(1)
    Notify("BloxStrike Domination", "v2.2 loaded!", 4)
    safeWait(0.5)
    Notify("Offsets", OffsetStatus, 3)
    safeWait(0.5)
    Notify("Tip", "Press RightCtrl to toggle menu", 3)
end)

print("[BloxStrike Domination] v2.2 Loaded")
print("[BloxStrike Domination] GUI -> " .. tostring(GuiParent))
print("[BloxStrike Domination] Drawing: " .. tostring(HAS_DRAWING))
print("[BloxStrike Domination] Offsets: " .. OffsetStatus)

end, function(err)
    -- ERROR HANDLER — prints the actual error to console
    warn("[BloxStrike Domination] FATAL ERROR:")
    warn(tostring(err))
    warn(debug.traceback())
end)

if not mainOk then
    warn("[BloxStrike Domination] Script failed to initialize. Check errors above.")
end
