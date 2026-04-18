--[[
    ╔═══════════════════════════════════════════════════════════════════╗
    ║                                                                   ║
    ║              B L O X S T R I K E   D O M I N A T I O N            ║
    ║                     Premium Script Hub v2.1                       ║
    ║                                                                   ║
    ║        Auto-Updating Offsets · Modern ImGui · Full PVP Suite      ║
    ║         Cross-Executor Compatible (Synapse/Fluxus/KRNL/etc)       ║
    ║                                                                   ║
    ╚═══════════════════════════════════════════════════════════════════╝
]]

-- ═══════════════════════════════════════════════════════════════
-- [SECTION 0] CROSS-EXECUTOR COMPATIBILITY LAYER
-- ═══════════════════════════════════════════════════════════════

-- Safe wait that works on all executors
local safeWait = task and task.wait or wait
local safeSpawn = task and task.spawn or spawn
local safeDelay = task and task.delay or delay

-- Executor detection
local IS_SYNAPSE   = (syn ~= nil)
local IS_KRNL      = (KRNL_LOADED ~= nil) or (getexecutorname and getexecutorname():lower():find("krnl"))
local HAS_GETHUI   = (typeof(gethui) == "function")
local HAS_PROTECT  = (IS_SYNAPSE and syn.protect_gui ~= nil)
local HAS_HOOKMT   = (typeof(getrawmetatable) == "function")

-- Drawing API check
local HAS_DRAWING = false
pcall(function()
    local test = Drawing.new("Line")
    test:Remove()
    HAS_DRAWING = true
end)

-- Safe font resolver (some executors lack newer Roblox fonts)
local function safeFont(name)
    local ok, f = pcall(function() return Enum.Font[name] end)
    if ok and f then return f end
    return Enum.Font.SourceSans
end

local Fonts = {
    Bold    = safeFont("GothamBold"),
    Medium  = safeFont("GothamMedium"),
    Regular = safeFont("Gotham"),
}

-- Safe RaycastFilterType (older executors use Blacklist/Whitelist, newer use Exclude/Include)
local FilterExclude
do
    local ok, val = pcall(function() return Enum.RaycastFilterType.Exclude end)
    if ok and val then
        FilterExclude = val
    else
        FilterExclude = Enum.RaycastFilterType.Blacklist
    end
end

-- Safe instance creation (won't crash if instance type doesn't exist)
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

local LocalPlayer = Players.LocalPlayer
local Camera      = Workspace.CurrentCamera
local Mouse       = LocalPlayer:GetMouse()

-- VirtualInputManager (not available on all executors)
local VIM = nil
pcall(function() VIM = game:GetService("VirtualInputManager") end)

-- VirtualUser for anti-afk
local VirtualUser = nil
pcall(function() VirtualUser = game:GetService("VirtualUser") end)

-- ═══════════════════════════════════════════════════════════════
-- [SECTION 1.5] GUI PARENT RESOLUTION
-- Cross-executor compatible GUI hosting
-- Priority: gethui() > syn.protect_gui + CoreGui > CoreGui > PlayerGui
-- ═══════════════════════════════════════════════════════════════

local GuiParent

-- Method 1: gethui() — works on most modern executors (Synapse V3, Script-Ware, Wave, etc.)
if HAS_GETHUI then
    GuiParent = gethui()
end

-- Method 2: Try CoreGui directly (some executors allow it)
if not GuiParent then
    local ok = pcall(function()
        local testGui = Instance.new("ScreenGui")
        testGui.Name = "BSTestGui"
        if HAS_PROTECT then
            syn.protect_gui(testGui)
        end
        testGui.Parent = CoreGui
        testGui:Destroy()
    end)
    if ok then
        GuiParent = CoreGui
    end
end

-- Method 3: Fallback to PlayerGui
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
        -- Try multiple HTTP methods for cross-executor compat
        if syn and syn.request then
            return syn.request({Url = OFFSETS_URL}).Body
        elseif http and http.request then
            return http.request({Url = OFFSETS_URL}).Body
        elseif request then
            return request({Url = OFFSETS_URL}).Body
        elseif game.HttpGet then
            return game:HttpGet(OFFSETS_URL)
        end
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
    if ver then
        OffsetVersion = ver
    end

    Offsets = parsed
    OffsetStatus = "Synced (" .. OffsetVersion .. ")"
    return true
end

-- Initial fetch + auto-refresh loop
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
    NoRecoil = { Enabled = false },
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
    local viewport = Camera.ViewportSize
    return Vector2.new(viewport.X / 2, viewport.Y / 2)
end

-- ═══════════════════════════════════════════════════════════════
-- [SECTION 5] DRAWING MANAGER
-- ═══════════════════════════════════════════════════════════════

local function CreateDrawing(class, props)
    if not HAS_DRAWING then return nil end
    local ok, obj = pcall(function()
        local d = Drawing.new(class)
        for k, v in pairs(props) do
            d[k] = v
        end
        return d
    end)
    if ok then return obj end
    return nil
end

local function SafeDrawingProp(drawing, prop, value)
    if not drawing then return end
    pcall(function() drawing[prop] = value end)
end

local function SafeDrawingRemove(drawing)
    if not drawing then return end
    pcall(function() drawing:Remove() end)
end

-- ═══════════════════════════════════════════════════════════════
-- [SECTION 6] NOTIFICATION SYSTEM
-- ═══════════════════════════════════════════════════════════════

local NotifHolder = nil

local function CreateNotificationHolder(parent)
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

    local padding = Instance.new("UIPadding")
    padding.PaddingBottom = UDim.new(0, 20)
    padding.Parent = holder

    return holder
end

local function Notify(title, message, duration)
    duration = duration or 3
    if not NotifHolder or not NotifHolder.Parent then return end

    pcall(function()
        local notif = Instance.new("Frame")
        notif.Size = UDim2.new(1, 0, 0, 60)
        notif.BackgroundColor3 = Color3.fromRGB(22, 27, 34)
        notif.BorderSizePixel = 0
        notif.BackgroundTransparency = 0.05
        notif.ClipsDescendants = true
        notif.Parent = NotifHolder

        safeNew("UICorner", {CornerRadius = UDim.new(0, 8)}, notif)
        safeNew("UIStroke", {Color = Color3.fromRGB(48, 54, 61), Thickness = 1}, notif)

        local accent = Instance.new("Frame")
        accent.Size = UDim2.new(0, 3, 1, 0)
        accent.BackgroundColor3 = Color3.fromRGB(0, 212, 255)
        accent.BorderSizePixel = 0
        accent.Parent = notif

        local titleLabel = Instance.new("TextLabel")
        titleLabel.Text = title
        titleLabel.Font = Fonts.Bold
        titleLabel.TextSize = 13
        titleLabel.TextColor3 = Color3.fromRGB(230, 237, 243)
        titleLabel.BackgroundTransparency = 1
        titleLabel.Position = UDim2.new(0, 14, 0, 8)
        titleLabel.Size = UDim2.new(1, -20, 0, 18)
        titleLabel.TextXAlignment = Enum.TextXAlignment.Left
        titleLabel.Parent = notif

        local msgLabel = Instance.new("TextLabel")
        msgLabel.Text = message
        msgLabel.Font = Fonts.Regular
        msgLabel.TextSize = 11
        msgLabel.TextColor3 = Color3.fromRGB(139, 148, 158)
        msgLabel.BackgroundTransparency = 1
        msgLabel.Position = UDim2.new(0, 14, 0, 28)
        msgLabel.Size = UDim2.new(1, -20, 0, 24)
        msgLabel.TextXAlignment = Enum.TextXAlignment.Left
        msgLabel.TextWrapped = true
        msgLabel.Parent = notif

        notif.Position = UDim2.new(1, 0, 0, 0)
        TweenService:Create(notif, TweenInfo.new(0.3, Enum.EasingStyle.Quart, Enum.EasingDirection.Out), {
            Position = UDim2.new(0, 0, 0, 0)
        }):Play()

        safeSpawn(function()
            safeWait(duration)
            local tween = TweenService:Create(notif, TweenInfo.new(0.4, Enum.EasingStyle.Quart, Enum.EasingDirection.In), {
                Position = UDim2.new(1, 0, 0, 0),
                BackgroundTransparency = 1
            })
            tween:Play()
            tween.Completed:Wait()
            notif:Destroy()
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
UI.Connections = {}

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
    -- Kill any previous instance
    pcall(function()
        if GuiParent:FindFirstChild("BloxStrikeDom") then
            GuiParent:FindFirstChild("BloxStrikeDom"):Destroy()
        end
    end)
    -- Also check CoreGui and PlayerGui in case of leftover
    pcall(function()
        if CoreGui:FindFirstChild("BloxStrikeDom") then
            CoreGui:FindFirstChild("BloxStrikeDom"):Destroy()
        end
    end)
    pcall(function()
        local pg = LocalPlayer:FindFirstChild("PlayerGui")
        if pg and pg:FindFirstChild("BloxStrikeDom") then
            pg:FindFirstChild("BloxStrikeDom"):Destroy()
        end
    end)

    -- Create ScreenGui
    self.ScreenGui = Instance.new("ScreenGui")
    self.ScreenGui.Name = "BloxStrikeDom"
    self.ScreenGui.ResetOnSpawn = false
    pcall(function() self.ScreenGui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling end)

    -- Protect GUI if Synapse
    if HAS_PROTECT then
        pcall(function() syn.protect_gui(self.ScreenGui) end)
    end

    -- Parent the GUI
    self.ScreenGui.Parent = GuiParent

    -- Notification holder
    NotifHolder = CreateNotificationHolder(self.ScreenGui)

    -- ─── MAIN WINDOW ────────────────────────────────────────
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

    -- ─── TITLE BAR ───────────────────────────────────────────
    local titleBar = Instance.new("Frame")
    titleBar.Name = "TitleBar"
    titleBar.Size = UDim2.new(1, 0, 0, 40)
    titleBar.BackgroundColor3 = Theme.Surface
    titleBar.BorderSizePixel = 0
    titleBar.Active = true
    titleBar.Parent = self.MainFrame

    safeNew("UICorner", {CornerRadius = UDim.new(0, 10)}, titleBar)

    -- Fix bottom corners of title bar
    local tbFix = Instance.new("Frame")
    tbFix.Size = UDim2.new(1, 0, 0, 12)
    tbFix.Position = UDim2.new(0, 0, 1, -12)
    tbFix.BackgroundColor3 = Theme.Surface
    tbFix.BorderSizePixel = 0
    tbFix.Parent = titleBar

    -- Accent gradient line under title
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

    -- Animated gradient
    if accentGrad then
        safeSpawn(function()
            local offset = 0
            while self.ScreenGui and self.ScreenGui.Parent do
                offset = (offset + 0.005) % 1
                pcall(function()
                    accentGrad.Offset = Vector2.new(math.sin(offset * math.pi * 2) * 0.3, 0)
                end)
                RunService.RenderStepped:Wait()
            end
        end)
    end

    -- Title text
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

    -- Version badge
    local vBadge = Instance.new("TextLabel")
    vBadge.Text = "v2.1"
    vBadge.Font = Fonts.Bold
    vBadge.TextSize = 10
    vBadge.TextColor3 = Theme.Accent
    vBadge.BackgroundColor3 = Color3.fromRGB(0, 40, 50)
    vBadge.Position = UDim2.new(0, 210, 0.5, -9)
    vBadge.Size = UDim2.new(0, 32, 0, 18)
    vBadge.Parent = titleBar
    safeNew("UICorner", {CornerRadius = UDim.new(0, 4)}, vBadge)

    -- Close button
    local closeBtn = Instance.new("TextButton")
    closeBtn.Text = "X"
    closeBtn.Font = Fonts.Bold
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

    -- ─── DRAGGING ────────────────────────────────────────────
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

    -- ─── SIDEBAR ─────────────────────────────────────────────
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

    -- ─── CONTENT AREA ────────────────────────────────────────
    self.ContentFrame = Instance.new("Frame")
    self.ContentFrame.Name = "Content"
    self.ContentFrame.Size = UDim2.new(1, -141, 1, -66)
    self.ContentFrame.Position = UDim2.new(0, 141, 0, 42)
    self.ContentFrame.BackgroundTransparency = 1
    self.ContentFrame.Parent = self.MainFrame

    -- ─── STATUS BAR ──────────────────────────────────────────
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
    tabBtn.LayoutOrder = order or #self.Tabs + 1
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

    -- Active indicator bar
    local indicator = Instance.new("Frame")
    indicator.Size = UDim2.new(0, 3, 0.6, 0)
    indicator.Position = UDim2.new(0, 0, 0.2, 0)
    indicator.BackgroundColor3 = Theme.Accent
    indicator.BorderSizePixel = 0
    indicator.Visible = false
    indicator.Parent = tabBtn

    safeNew("UICorner", {CornerRadius = UDim.new(0, 2)}, indicator)

    -- Tab content (ScrollingFrame)
    local content = Instance.new("ScrollingFrame")
    content.Name = "TabContent_" .. name
    content.Size = UDim2.new(1, -16, 1, -8)
    content.Position = UDim2.new(0, 8, 0, 4)
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
        Order     = 0,
    }

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
        local isActive = (tab.Name == name)
        tab.Content.Visible = isActive
        tab.Indicator.Visible = isActive

        local targetBgTrans = isActive and 0.7 or 1
        local targetText    = isActive and Theme.Text or Theme.TextMuted
        local targetIcon    = isActive and Theme.Accent or Theme.TextMuted

        TweenService:Create(tab.Button, TweenInfo.new(0.2), {BackgroundTransparency = targetBgTrans}):Play()
        TweenService:Create(tab.TextLabel, TweenInfo.new(0.2), {TextColor3 = targetText}):Play()
        TweenService:Create(tab.IconLabel, TweenInfo.new(0.2), {TextColor3 = targetIcon}):Play()
    end
    self.ActiveTab = name
end

function UI:CreateSection(tabData, title)
    local section = Instance.new("Frame")
    section.Size = UDim2.new(1, 0, 0, 26)
    section.BackgroundTransparency = 1
    section.LayoutOrder = tabData.Order
    tabData.Order = tabData.Order + 1
    section.Parent = tabData.Content

    local line = Instance.new("Frame")
    line.Size = UDim2.new(1, 0, 0, 1)
    line.Position = UDim2.new(0, 0, 0.5, 0)
    line.BackgroundColor3 = Theme.Border
    line.BorderSizePixel = 0
    line.Parent = section

    local label = Instance.new("TextLabel")
    label.Text = "  " .. title .. "  "
    label.Font = Fonts.Bold
    label.TextSize = 10
    label.TextColor3 = Theme.AccentSecondary
    label.BackgroundColor3 = Theme.Background
    label.Position = UDim2.new(0, 12, 0, 5)
    label.Size = UDim2.new(0, label.TextBounds and label.TextBounds.X + 12 or 100, 0, 16)
    label.Parent = section

    return section
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

    -- Toggle background
    local toggleBg = Instance.new("Frame")
    toggleBg.Size = UDim2.new(0, 40, 0, 20)
    toggleBg.Position = UDim2.new(1, -52, 0.5, -10)
    toggleBg.BackgroundColor3 = configTable[configKey] and Theme.ToggleOn or Theme.ToggleOff
    toggleBg.BorderSizePixel = 0
    toggleBg.Parent = frame

    safeNew("UICorner", {CornerRadius = UDim.new(1, 0)}, toggleBg)

    -- Knob
    local knob = Instance.new("Frame")
    knob.Size = UDim2.new(0, 16, 0, 16)
    knob.Position = configTable[configKey] and UDim2.new(1, -18, 0.5, -8) or UDim2.new(0, 2, 0.5, -8)
    knob.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
    knob.BorderSizePixel = 0
    knob.Parent = toggleBg

    safeNew("UICorner", {CornerRadius = UDim.new(1, 0)}, knob)

    -- Clickable area
    local btn = Instance.new("TextButton")
    btn.Size = UDim2.new(1, 0, 1, 0)
    btn.BackgroundTransparency = 1
    btn.Text = ""
    btn.ZIndex = 2
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

        if callback then
            pcall(callback, enabled)
        end
    end)

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

    local valueLabel = Instance.new("TextLabel")
    valueLabel.Text = tostring(configTable[configKey])
    valueLabel.Font = Fonts.Bold
    valueLabel.TextSize = 11
    valueLabel.TextColor3 = Theme.Accent
    valueLabel.BackgroundTransparency = 1
    valueLabel.Position = UDim2.new(1, -55, 0, 2)
    valueLabel.Size = UDim2.new(0, 45, 0, 20)
    valueLabel.TextXAlignment = Enum.TextXAlignment.Right
    valueLabel.Parent = frame

    -- Track
    local track = Instance.new("Frame")
    track.Size = UDim2.new(1, -24, 0, 6)
    track.Position = UDim2.new(0, 12, 0, 30)
    track.BackgroundColor3 = Theme.Border
    track.BorderSizePixel = 0
    track.Parent = frame

    safeNew("UICorner", {CornerRadius = UDim.new(1, 0)}, track)

    -- Fill
    local pct = math.clamp((configTable[configKey] - min) / (max - min), 0, 1)
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

    -- Interaction
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
        if trackAbsSize == 0 then return end
        local relative = math.clamp((inputX - trackAbsPos) / trackAbsSize, 0, 1)
        local value = math.floor(min + (max - min) * relative)
        configTable[configKey] = value
        valueLabel.Text = tostring(value)
        fill.Size = UDim2.new(relative, 0, 1, 0)
        if callback then pcall(callback, value) end
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

    return frame
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

    local selectedBtn = Instance.new("TextButton")
    selectedBtn.Text = tostring(configTable[configKey]) .. " v"
    selectedBtn.Font = Fonts.Medium
    selectedBtn.TextSize = 11
    selectedBtn.TextColor3 = Theme.Accent
    selectedBtn.BackgroundColor3 = Theme.Background
    selectedBtn.Position = UDim2.new(1, -130, 0.5, -12)
    selectedBtn.Size = UDim2.new(0, 118, 0, 24)
    selectedBtn.AutoButtonColor = false
    selectedBtn.ZIndex = 5
    selectedBtn.Parent = frame

    safeNew("UICorner", {CornerRadius = UDim.new(0, 4)}, selectedBtn)

    local dropdown = Instance.new("Frame")
    dropdown.Size = UDim2.new(0, 118, 0, #options * 26 + 4)
    dropdown.Position = UDim2.new(1, -130, 1, 2)
    dropdown.BackgroundColor3 = Theme.Surface
    dropdown.BorderSizePixel = 0
    dropdown.Visible = false
    dropdown.ZIndex = 50
    dropdown.Parent = frame

    safeNew("UICorner", {CornerRadius = UDim.new(0, 6)}, dropdown)
    safeNew("UIStroke", {Color = Theme.Border, Thickness = 1}, dropdown)

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
        optBtn.Font = Fonts.Regular
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
            selectedBtn.Text = tostring(opt) .. " v"
            dropdown.Visible = false
            if callback then pcall(callback, opt) end
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

    return btn
end

function UI:Toggle()
    self.Visible = not self.Visible
    self.MainFrame.Visible = self.Visible
end

function UI:Destroy()
    if self.ScreenGui then
        pcall(function() self.ScreenGui:Destroy() end)
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
            local vel = Vector3.new(0, 0, 0)
            pcall(function() vel = hrp.AssemblyLinearVelocity end)
            if vel == Vector3.new(0, 0, 0) then
                pcall(function() vel = hrp.Velocity end)
            end
            targetPos = targetPos + vel * Config.Aimbot.PredictScale
        end
    end

    local currentCF = Camera.CFrame
    local targetCF = CFrame.lookAt(currentCF.Position, targetPos)
    local smoothing = math.clamp(Config.Aimbot.Smoothing, 1, 20)
    local alpha = 1 / smoothing

    Camera.CFrame = currentCF:Lerp(targetCF, alpha)
end

-- ─── SILENT AIM ──────────────────────────────────────────────

local SilentAimInitialized = false

function Features:InitSilentAim()
    if SilentAimInitialized then return end
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
                local target = Features:GetSilentTarget()
                if target then
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
        if make_readonly then make_readonly(mt) end

        SilentAimInitialized = true
    end)
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
    local unitRay = Camera:ViewportPointToRay(mousePos.X, mousePos.Y)

    local params = RaycastParams.new()
    params.FilterType = FilterExclude
    params.FilterDescendantsInstances = {LocalPlayer.Character}

    local result = Workspace:Raycast(unitRay.Origin, unitRay.Direction * 1000, params)
    if result and result.Instance then
        local hitModel = result.Instance:FindFirstAncestorOfClass("Model")
        if hitModel then
            local hitPlayer = Players:GetPlayerFromCharacter(hitModel)
            if hitPlayer and IsEnemy(hitPlayer, Config.Triggerbot.TeamCheck) and IsAlive(hitPlayer) then
                safeWait(Config.Triggerbot.Delay / 1000)
                -- Try multiple click methods for compatibility
                if VIM then
                    pcall(function()
                        VIM:SendMouseButtonEvent(mousePos.X, mousePos.Y, 0, true, game, 0)
                        safeWait(0.03)
                        VIM:SendMouseButtonEvent(mousePos.X, mousePos.Y, 0, false, game, 0)
                    end)
                elseif mouse1click then
                    pcall(mouse1click)
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
    if not HAS_DRAWING then return end

    self.ESPDrawings[player] = {
        Box = {
            Top    = CreateDrawing("Line", {Visible = false, Color = Config.ESP.BoxColor, Thickness = 1}),
            Right  = CreateDrawing("Line", {Visible = false, Color = Config.ESP.BoxColor, Thickness = 1}),
            Bottom = CreateDrawing("Line", {Visible = false, Color = Config.ESP.BoxColor, Thickness = 1}),
            Left   = CreateDrawing("Line", {Visible = false, Color = Config.ESP.BoxColor, Thickness = 1}),
        },
        Name = CreateDrawing("Text", {Visible = false, Color = Config.ESP.NameColor, Size = 13, Center = true, Outline = true, Font = 2}),
        HealthBG   = CreateDrawing("Line", {Visible = false, Color = Color3.fromRGB(30, 30, 30), Thickness = 4}),
        HealthFill = CreateDrawing("Line", {Visible = false, Color = Color3.fromRGB(0, 255, 0), Thickness = 2}),
        HealthText = CreateDrawing("Text", {Visible = false, Color = Color3.fromRGB(255, 255, 255), Size = 10, Center = false, Outline = true, Font = 2}),
        DistText   = CreateDrawing("Text", {Visible = false, Color = Color3.fromRGB(139, 148, 158), Size = 10, Center = true, Outline = true, Font = 2}),
        Tracer     = CreateDrawing("Line", {Visible = false, Color = Config.ESP.BoxColor, Thickness = 1}),
        Skeleton   = {},
    }

    local skelConns = {
        "Head_UpperTorso", "UpperTorso_LeftUpperArm", "LeftUpperArm_LeftLowerArm", "LeftLowerArm_LeftHand",
        "UpperTorso_RightUpperArm", "RightUpperArm_RightLowerArm", "RightLowerArm_RightHand",
        "UpperTorso_LowerTorso", "LowerTorso_LeftUpperLeg", "LeftUpperLeg_LeftLowerLeg", "LeftLowerLeg_LeftFoot",
        "LowerTorso_RightUpperLeg", "RightUpperLeg_RightLowerLeg", "RightLowerLeg_RightFoot"
    }
    for _, key in ipairs(skelConns) do
        self.ESPDrawings[player].Skeleton[key] = CreateDrawing("Line", {Visible = false, Color = Theme.Accent, Thickness = 1})
    end
end

local function HideAllESP(drawings)
    if not drawings then return end
    for key, obj in pairs(drawings) do
        if type(obj) == "table" and not obj.Remove then
            for _, d in pairs(obj) do
                if d then pcall(function() d.Visible = false end) end
            end
        elseif obj and obj.Remove then
            pcall(function() obj.Visible = false end)
        end
    end
end

local function RemoveAllESP(drawings)
    if not drawings then return end
    for key, obj in pairs(drawings) do
        if type(obj) == "table" and not obj.Remove then
            for _, d in pairs(obj) do
                SafeDrawingRemove(d)
            end
        elseif obj then
            SafeDrawingRemove(obj)
        end
    end
end

function Features:UpdateESP()
    if not HAS_DRAWING then return end

    if not Config.ESP.Enabled then
        for _, drawings in pairs(self.ESPDrawings) do
            HideAllESP(drawings)
        end
        return
    end

    for _, player in ipairs(Players:GetPlayers()) do
        if player == LocalPlayer then
            -- skip self
        else
            if not self.ESPDrawings[player] then
                self:InitESPForPlayer(player)
            end

            local drawings = self.ESPDrawings[player]
            if not drawings then
                -- skip if drawing creation failed
            else
                local char = GetCharacter(player)
                local isEnemy = IsEnemy(player, Config.ESP.TeamCheck)

                if not char or not IsAlive(player) or not isEnemy then
                    HideAllESP(drawings)
                else
                    local hrp = char:FindFirstChild("HumanoidRootPart")
                    local head = char:FindFirstChild("Head")
                    local humanoid = char:FindFirstChildOfClass("Humanoid")

                    if not hrp or not head or not humanoid then
                        HideAllESP(drawings)
                    else
                        local pos, onScreen, depth = WorldToScreen(hrp.Position)

                        if not onScreen or depth < 0 then
                            HideAllESP(drawings)
                        else
                            local headPos = WorldToScreen(head.Position + Vector3.new(0, 0.5, 0))
                            local footPos = WorldToScreen(hrp.Position - Vector3.new(0, 3, 0))
                            local boxHeight = math.abs(headPos.Y - footPos.Y)
                            local boxWidth = boxHeight * 0.6

                            local boxColor = Config.ESP.BoxColor
                            if Config.ESP.TeamColor and player.Team then
                                pcall(function() boxColor = player.TeamColor.Color end)
                            end

                            -- Box
                            if Config.ESP.Boxes and drawings.Box.Top then
                                local tl = Vector2.new(pos.X - boxWidth/2, headPos.Y)
                                local tr = Vector2.new(pos.X + boxWidth/2, headPos.Y)
                                local bl = Vector2.new(pos.X - boxWidth/2, footPos.Y)
                                local br = Vector2.new(pos.X + boxWidth/2, footPos.Y)

                                SafeDrawingProp(drawings.Box.Top, "From", tl)
                                SafeDrawingProp(drawings.Box.Top, "To", tr)
                                SafeDrawingProp(drawings.Box.Top, "Color", boxColor)
                                SafeDrawingProp(drawings.Box.Top, "Visible", true)

                                SafeDrawingProp(drawings.Box.Right, "From", tr)
                                SafeDrawingProp(drawings.Box.Right, "To", br)
                                SafeDrawingProp(drawings.Box.Right, "Color", boxColor)
                                SafeDrawingProp(drawings.Box.Right, "Visible", true)

                                SafeDrawingProp(drawings.Box.Bottom, "From", br)
                                SafeDrawingProp(drawings.Box.Bottom, "To", bl)
                                SafeDrawingProp(drawings.Box.Bottom, "Color", boxColor)
                                SafeDrawingProp(drawings.Box.Bottom, "Visible", true)

                                SafeDrawingProp(drawings.Box.Left, "From", bl)
                                SafeDrawingProp(drawings.Box.Left, "To", tl)
                                SafeDrawingProp(drawings.Box.Left, "Color", boxColor)
                                SafeDrawingProp(drawings.Box.Left, "Visible", true)
                            else
                                for _, d in pairs(drawings.Box) do
                                    if d then SafeDrawingProp(d, "Visible", false) end
                                end
                            end

                            -- Name
                            if Config.ESP.Names and drawings.Name then
                                SafeDrawingProp(drawings.Name, "Position", Vector2.new(pos.X, headPos.Y - 16))
                                SafeDrawingProp(drawings.Name, "Text", player.DisplayName or player.Name)
                                SafeDrawingProp(drawings.Name, "Color", Config.ESP.NameColor)
                                SafeDrawingProp(drawings.Name, "Visible", true)
                            elseif drawings.Name then
                                SafeDrawingProp(drawings.Name, "Visible", false)
                            end

                            -- Health Bar
                            if Config.ESP.Health and drawings.HealthBG then
                                local hpPct = math.clamp(humanoid.Health / humanoid.MaxHealth, 0, 1)
                                local barX = pos.X - boxWidth/2 - 6
                                local barTop = headPos.Y
                                local barBot = footPos.Y
                                local barFillBot = barBot - (barBot - barTop) * hpPct

                                SafeDrawingProp(drawings.HealthBG, "From", Vector2.new(barX, barTop))
                                SafeDrawingProp(drawings.HealthBG, "To", Vector2.new(barX, barBot))
                                SafeDrawingProp(drawings.HealthBG, "Visible", true)

                                SafeDrawingProp(drawings.HealthFill, "From", Vector2.new(barX, barFillBot))
                                SafeDrawingProp(drawings.HealthFill, "To", Vector2.new(barX, barBot))
                                SafeDrawingProp(drawings.HealthFill, "Color", Color3.fromRGB(255*(1-hpPct), 255*hpPct, 0))
                                SafeDrawingProp(drawings.HealthFill, "Visible", true)

                                SafeDrawingProp(drawings.HealthText, "Position", Vector2.new(barX - 4, barFillBot - 6))
                                SafeDrawingProp(drawings.HealthText, "Text", tostring(math.floor(humanoid.Health)))
                                SafeDrawingProp(drawings.HealthText, "Visible", hpPct < 1)
                            else
                                if drawings.HealthBG then SafeDrawingProp(drawings.HealthBG, "Visible", false) end
                                if drawings.HealthFill then SafeDrawingProp(drawings.HealthFill, "Visible", false) end
                                if drawings.HealthText then SafeDrawingProp(drawings.HealthText, "Visible", false) end
                            end

                            -- Distance
                            if Config.ESP.Distance and drawings.DistText then
                                local dist = (hrp.Position - Camera.CFrame.Position).Magnitude
                                SafeDrawingProp(drawings.DistText, "Position", Vector2.new(pos.X, footPos.Y + 2))
                                SafeDrawingProp(drawings.DistText, "Text", math.floor(dist) .. "m")
                                SafeDrawingProp(drawings.DistText, "Visible", true)
                            elseif drawings.DistText then
                                SafeDrawingProp(drawings.DistText, "Visible", false)
                            end

                            -- Tracers
                            if Config.ESP.Tracers and drawings.Tracer then
                                local origin
                                local vp = Camera.ViewportSize
                                if Config.ESP.TracerOrigin == "Bottom" then
                                    origin = Vector2.new(vp.X/2, vp.Y)
                                elseif Config.ESP.TracerOrigin == "Top" then
                                    origin = Vector2.new(vp.X/2, 0)
                                else
                                    origin = Vector2.new(vp.X/2, vp.Y/2)
                                end
                                SafeDrawingProp(drawings.Tracer, "From", origin)
                                SafeDrawingProp(drawings.Tracer, "To", Vector2.new(pos.X, footPos.Y))
                                SafeDrawingProp(drawings.Tracer, "Color", boxColor)
                                SafeDrawingProp(drawings.Tracer, "Visible", true)
                            elseif drawings.Tracer then
                                SafeDrawingProp(drawings.Tracer, "Visible", false)
                            end

                            -- Skeleton
                            if Config.ESP.Skeleton and drawings.Skeleton then
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
                                        local p1 = char:FindFirstChild(conn[1])
                                        local p2 = char:FindFirstChild(conn[2])
                                        if p1 and p2 then
                                            local s1, v1 = WorldToScreen(p1.Position)
                                            local s2, v2 = WorldToScreen(p2.Position)
                                            if v1 and v2 then
                                                SafeDrawingProp(line, "From", s1)
                                                SafeDrawingProp(line, "To", s2)
                                                SafeDrawingProp(line, "Visible", true)
                                            else
                                                SafeDrawingProp(line, "Visible", false)
                                            end
                                        else
                                            SafeDrawingProp(line, "Visible", false)
                                        end
                                    end
                                end
                            else
                                if drawings.Skeleton then
                                    for _, line in pairs(drawings.Skeleton) do
                                        if line then SafeDrawingProp(line, "Visible", false) end
                                    end
                                end
                            end
                        end -- onscreen check
                    end -- hrp/head/humanoid check
                end -- alive/enemy check
            end -- drawings exist check
        end -- not localplayer
    end -- player loop
end

-- ─── CHAMS ───────────────────────────────────────────────────

function Features:UpdateChams()
    for _, player in ipairs(Players:GetPlayers()) do
        if player ~= LocalPlayer then
            local char = GetCharacter(player)
            local isEnemy = IsEnemy(player, Config.Chams.TeamCheck)

            if Config.Chams.Enabled and char and IsAlive(player) and isEnemy then
                if not self.ChamsCache[player] then
                    pcall(function()
                        local highlight = Instance.new("Highlight")
                        highlight.Name = "BSChams"
                        highlight.FillColor = Config.Chams.FillColor
                        highlight.OutlineColor = Config.Chams.OutlineColor
                        highlight.FillTransparency = Config.Chams.FillTransparency
                        highlight.OutlineTransparency = Config.Chams.OutlineTransparency
                        highlight.DepthMode = Enum.HighlightDepthMode.AlwaysOnTop
                        highlight.Adornee = char
                        highlight.Parent = char
                        self.ChamsCache[player] = highlight
                    end)
                else
                    pcall(function()
                        local h = self.ChamsCache[player]
                        h.FillColor = Config.Chams.FillColor
                        h.OutlineColor = Config.Chams.OutlineColor
                        h.FillTransparency = Config.Chams.FillTransparency
                        h.OutlineTransparency = Config.Chams.OutlineTransparency
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

Features.CrosshairDrawings = {}

function Features:InitCrosshair()
    if not HAS_DRAWING then return end
    self.CrosshairDrawings = {
        Top    = CreateDrawing("Line", {Visible = false, Thickness = 1, Color = Config.Crosshair.Color}),
        Bottom = CreateDrawing("Line", {Visible = false, Thickness = 1, Color = Config.Crosshair.Color}),
        Left   = CreateDrawing("Line", {Visible = false, Thickness = 1, Color = Config.Crosshair.Color}),
        Right  = CreateDrawing("Line", {Visible = false, Thickness = 1, Color = Config.Crosshair.Color}),
        Dot    = CreateDrawing("Circle", {Visible = false, Filled = true, Color = Config.Crosshair.Color, Radius = 2, NumSides = 12}),
    }
end

function Features:UpdateCrosshair()
    if not HAS_DRAWING then return end
    if not Config.Crosshair.Enabled then
        for _, d in pairs(self.CrosshairDrawings) do
            if d then SafeDrawingProp(d, "Visible", false) end
        end
        return
    end

    local c = GetScreenCenter()
    local s = Config.Crosshair.Size
    local g = Config.Crosshair.Gap
    local col = Config.Crosshair.Color
    local t = Config.Crosshair.Thickness

    if self.CrosshairDrawings.Top then
        SafeDrawingProp(self.CrosshairDrawings.Top, "From", Vector2.new(c.X, c.Y - g - s))
        SafeDrawingProp(self.CrosshairDrawings.Top, "To", Vector2.new(c.X, c.Y - g))
        SafeDrawingProp(self.CrosshairDrawings.Top, "Color", col)
        SafeDrawingProp(self.CrosshairDrawings.Top, "Thickness", t)
        SafeDrawingProp(self.CrosshairDrawings.Top, "Visible", true)
    end
    if self.CrosshairDrawings.Bottom then
        SafeDrawingProp(self.CrosshairDrawings.Bottom, "From", Vector2.new(c.X, c.Y + g))
        SafeDrawingProp(self.CrosshairDrawings.Bottom, "To", Vector2.new(c.X, c.Y + g + s))
        SafeDrawingProp(self.CrosshairDrawings.Bottom, "Color", col)
        SafeDrawingProp(self.CrosshairDrawings.Bottom, "Thickness", t)
        SafeDrawingProp(self.CrosshairDrawings.Bottom, "Visible", true)
    end
    if self.CrosshairDrawings.Left then
        SafeDrawingProp(self.CrosshairDrawings.Left, "From", Vector2.new(c.X - g - s, c.Y))
        SafeDrawingProp(self.CrosshairDrawings.Left, "To", Vector2.new(c.X - g, c.Y))
        SafeDrawingProp(self.CrosshairDrawings.Left, "Color", col)
        SafeDrawingProp(self.CrosshairDrawings.Left, "Thickness", t)
        SafeDrawingProp(self.CrosshairDrawings.Left, "Visible", true)
    end
    if self.CrosshairDrawings.Right then
        SafeDrawingProp(self.CrosshairDrawings.Right, "From", Vector2.new(c.X + g, c.Y))
        SafeDrawingProp(self.CrosshairDrawings.Right, "To", Vector2.new(c.X + g + s, c.Y))
        SafeDrawingProp(self.CrosshairDrawings.Right, "Color", col)
        SafeDrawingProp(self.CrosshairDrawings.Right, "Thickness", t)
        SafeDrawingProp(self.CrosshairDrawings.Right, "Visible", true)
    end
    if self.CrosshairDrawings.Dot then
        SafeDrawingProp(self.CrosshairDrawings.Dot, "Position", c)
        SafeDrawingProp(self.CrosshairDrawings.Dot, "Color", col)
        SafeDrawingProp(self.CrosshairDrawings.Dot, "Visible", Config.Crosshair.Dot)
    end
end

-- ─── FOV CIRCLE ──────────────────────────────────────────────

Features.FOVCircleDrawing = nil

function Features:InitFOVCircle()
    if not HAS_DRAWING then return end
    self.FOVCircleDrawing = CreateDrawing("Circle", {
        Visible = false, Filled = false, Color = Config.FOVCircle.Color,
        Transparency = Config.FOVCircle.Transparency, Radius = Config.Aimbot.FOV,
        NumSides = 64, Thickness = 1,
    })
end

function Features:UpdateFOVCircle()
    if not HAS_DRAWING or not self.FOVCircleDrawing then return end
    if Config.Aimbot.ShowFOV and Config.Aimbot.Enabled then
        local mp = UserInputService:GetMouseLocation()
        SafeDrawingProp(self.FOVCircleDrawing, "Position", mp)
        SafeDrawingProp(self.FOVCircleDrawing, "Radius", Config.Aimbot.FOV)
        SafeDrawingProp(self.FOVCircleDrawing, "Color", Config.FOVCircle.Color)
        SafeDrawingProp(self.FOVCircleDrawing, "Transparency", Config.FOVCircle.Transparency)
        SafeDrawingProp(self.FOVCircleDrawing, "Visible", true)
    else
        SafeDrawingProp(self.FOVCircleDrawing, "Visible", false)
    end
end

-- ─── HIT MARKERS ─────────────────────────────────────────────

Features.HitMarkerLines = {}

function Features:InitHitMarkers()
    if not HAS_DRAWING then return end
    for i = 1, 4 do
        self.HitMarkerLines[i] = CreateDrawing("Line", {Visible = false, Color = Config.HitMarkers.Color, Thickness = 2})
    end
end

function Features:ShowHitMarker()
    if not Config.HitMarkers.Enabled or not HAS_DRAWING then return end
    local center = GetScreenCenter()
    local sz, gp = 10, 4
    local positions = {
        {Vector2.new(center.X-gp, center.Y-gp), Vector2.new(center.X-gp-sz, center.Y-gp-sz)},
        {Vector2.new(center.X+gp, center.Y-gp), Vector2.new(center.X+gp+sz, center.Y-gp-sz)},
        {Vector2.new(center.X-gp, center.Y+gp), Vector2.new(center.X-gp-sz, center.Y+gp+sz)},
        {Vector2.new(center.X+gp, center.Y+gp), Vector2.new(center.X+gp+sz, center.Y+gp+sz)},
    }
    for i = 1, 4 do
        if self.HitMarkerLines[i] then
            SafeDrawingProp(self.HitMarkerLines[i], "From", positions[i][1])
            SafeDrawingProp(self.HitMarkerLines[i], "To", positions[i][2])
            SafeDrawingProp(self.HitMarkerLines[i], "Color", Config.HitMarkers.Color)
            SafeDrawingProp(self.HitMarkerLines[i], "Visible", true)
        end
    end
    safeSpawn(function()
        safeWait(0.3)
        for i = 1, 4 do
            if self.HitMarkerLines[i] then SafeDrawingProp(self.HitMarkerLines[i], "Visible", false) end
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
            pcall(function()
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
            end)
        end

        if self.FlyBody then
            local speed = Config.Fly.Speed
            local dir = Vector3.new(0, 0, 0)

            if UserInputService:IsKeyDown(Enum.KeyCode.W) then dir = dir + Camera.CFrame.LookVector end
            if UserInputService:IsKeyDown(Enum.KeyCode.S) then dir = dir - Camera.CFrame.LookVector end
            if UserInputService:IsKeyDown(Enum.KeyCode.A) then dir = dir - Camera.CFrame.RightVector end
            if UserInputService:IsKeyDown(Enum.KeyCode.D) then dir = dir + Camera.CFrame.RightVector end
            if UserInputService:IsKeyDown(Enum.KeyCode.Space) then dir = dir + Vector3.new(0, 1, 0) end
            if UserInputService:IsKeyDown(Enum.KeyCode.LeftControl) then dir = dir - Vector3.new(0, 1, 0) end

            pcall(function()
                self.FlyBody.Velocity.Velocity = dir * speed
                self.FlyBody.Gyro.CFrame = Camera.CFrame
            end)
            humanoid.PlatformStand = true
        end
    else
        if self.FlyBody then
            pcall(function() self.FlyBody.Velocity:Destroy() end)
            pcall(function() self.FlyBody.Gyro:Destroy() end)
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
    -- Method 1: VirtualUser
    if VirtualUser then
        safeSpawn(function()
            while true do
                safeWait(60)
                if Config.AntiAFK.Enabled then
                    pcall(function()
                        VirtualUser:Button2Down(Vector2.new(0, 0), Camera.CFrame)
                        safeWait(0.1)
                        VirtualUser:Button2Up(Vector2.new(0, 0), Camera.CFrame)
                    end)
                end
            end
        end)
    end

    -- Method 2: Disconnect the idle connection
    pcall(function()
        local gc = getconnections or get_signal_cons
        if gc then
            for _, conn in ipairs(gc(LocalPlayer.Idled)) do
                conn:Disable()
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
    local function hookCharacter(player)
        pcall(function()
            local function onChar(char)
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
            if player.Character then safeSpawn(function() onChar(player.Character) end) end
            player.CharacterAdded:Connect(onChar)
        end)
    end

    for _, p in ipairs(Players:GetPlayers()) do
        if p ~= LocalPlayer then hookCharacter(p) end
    end
    Players.PlayerAdded:Connect(function(p) hookCharacter(p) end)
end

-- ─── THIRD PERSON ────────────────────────────────────────────

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
    if Features.ESPDrawings[player] then
        RemoveAllESP(Features.ESPDrawings[player])
        Features.ESPDrawings[player] = nil
    end
    if Features.ChamsCache[player] then
        pcall(function() Features.ChamsCache[player]:Destroy() end)
        Features.ChamsCache[player] = nil
    end
end)

-- ═══════════════════════════════════════════════════════════════
-- [SECTION 10] BUILD THE UI
-- ═══════════════════════════════════════════════════════════════

UI:Init()

-- ─── COMBAT TAB ──────────────────────────────────────────────
local combatTab = UI:CreateTab("Combat", "[+]", 1)

UI:CreateSection(combatTab, "AIMBOT")
UI:CreateToggle(combatTab, "Enable Aimbot", Config.Aimbot, "Enabled")
UI:CreateSlider(combatTab, "Smoothing", 1, 20, Config.Aimbot, "Smoothing")
UI:CreateSlider(combatTab, "FOV Radius", 20, 500, Config.Aimbot, "FOV")
UI:CreateDropdown(combatTab, "Target Bone", {"Head", "Torso", "HumanoidRootPart"}, Config.Aimbot, "TargetBone")
UI:CreateToggle(combatTab, "Team Check", Config.Aimbot, "TeamCheck")
UI:CreateToggle(combatTab, "Wall Check", Config.Aimbot, "WallCheck")
UI:CreateToggle(combatTab, "Prediction", Config.Aimbot, "Prediction")
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
UI:CreateSlider(combatTab, "Fire Speed Multi", 1, 5, Config.RapidFire, "Speed")

-- ─── VISUALS TAB ─────────────────────────────────────────────
local visualsTab = UI:CreateTab("Visuals", "[o]", 2)

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

-- ─── MISC TAB ────────────────────────────────────────────────
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
        if ok then
            Notify("Offsets", "Updated: " .. OffsetVersion, 3)
        else
            Notify("Offsets", "Refresh failed!", 3)
        end
    end)
end)

UI:CreateButton(miscTab, "Show Offset Version", function()
    Notify("Version", "Roblox: " .. OffsetVersion .. " | Script: v2.1", 4)
end)

-- ─── SETTINGS TAB ────────────────────────────────────────────
local settingsTab = UI:CreateTab("Settings", "[=]", 5)

UI:CreateSection(settingsTab, "GENERAL")
UI:CreateButton(settingsTab, "Unload Script", function()
    Notify("Unloading", "Cleaning up...", 2)
    safeSpawn(function()
        safeWait(1)
        -- Clean drawings
        for _, drawings in pairs(Features.ESPDrawings) do
            RemoveAllESP(drawings)
        end
        for _, d in pairs(Features.CrosshairDrawings) do SafeDrawingRemove(d) end
        SafeDrawingRemove(Features.FOVCircleDrawing)
        for _, d in pairs(Features.HitMarkerLines) do SafeDrawingRemove(d) end
        -- Clean chams
        for _, h in pairs(Features.ChamsCache) do pcall(function() h:Destroy() end) end
        -- Clean fly
        if Features.FlyBody then
            pcall(function() Features.FlyBody.Velocity:Destroy() end)
            pcall(function() Features.FlyBody.Gyro:Destroy() end)
        end
        -- Restore lighting
        Config.Fullbright.Enabled = false
        Features:RunFullbright()
        Config.NoFog.Enabled = false
        Features:RunNoFog()
        -- Destroy UI
        UI:Destroy()
    end)
end)

UI:CreateButton(settingsTab, "Toggle Key: RightCtrl", function()
    Notify("Info", "Press RightCtrl to show/hide the menu", 3)
end)

-- Select first tab
UI:SelectTab("Combat")

-- ═══════════════════════════════════════════════════════════════
-- [SECTION 11] MAIN LOOPS
-- ═══════════════════════════════════════════════════════════════

Features:InitCrosshair()
Features:InitFOVCircle()
Features:InitHitMarkers()
Features:InitInfiniteJump()
Features:InitAntiAFK()
Features:InitKillSound()
pcall(function() Features:InitSilentAim() end)

-- Render loop (every frame)
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

-- Logic loop (physics step)
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

safeSpawn(function()
    safeWait(1)
    Notify("BloxStrike Domination", "v2.1 loaded successfully!", 4)
    safeWait(0.5)
    Notify("Offsets", OffsetStatus, 3)
    safeWait(0.5)
    Notify("Tip", "Press RightCtrl to toggle menu", 3)
end)

print("[BloxStrike Domination] v2.1 Loaded | Offsets: " .. OffsetStatus)
print("[BloxStrike Domination] GUI Parent: " .. tostring(GuiParent))
print("[BloxStrike Domination] Drawing API: " .. tostring(HAS_DRAWING))
print("[BloxStrike Domination] Press RightCtrl to toggle menu")
