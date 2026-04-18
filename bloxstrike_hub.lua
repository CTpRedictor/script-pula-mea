local ok, err = pcall(function()

local game = game
local pcall = pcall
local pairs = pairs
local ipairs = ipairs
local type = type
local tostring = tostring
local tonumber = tonumber
local math = math
local coroutine = coroutine
local string = string
local table = table
local unpack = unpack or table.unpack

local function rid(len)
    len = len or 12
    local c = "abcdefghijklmnopqrstuvwxyz"
    local r = ""
    for i = 1, len do
        local p = math.random(1, #c)
        r = r .. c:sub(p, p)
    end
    return r
end

local SCRIPT_ID = rid(16)

local swait
pcall(function() if task and task.wait then swait = task.wait end end)
if not swait then pcall(function() swait = wait end) end
if not swait then swait = function(n) local s = tick(); while tick() - s < (n or 0.03) do end end end

local sspawn
pcall(function() if task and task.spawn then sspawn = task.spawn end end)
if not sspawn then pcall(function() sspawn = spawn end) end
if not sspawn then sspawn = function(f) coroutine.wrap(f)() end end

local sdefer
pcall(function() if task and task.defer then sdefer = task.defer end end)
if not sdefer then sdefer = sspawn end

local Players = game:GetService("Players")
local RS = game:GetService("RunService")
local UIS = game:GetService("UserInputService")
local TS = game:GetService("TweenService")
local Light = game:GetService("Lighting")
local WS = game:GetService("Workspace")
local HS = game:GetService("HttpService")

local LP = Players.LocalPlayer
local Cam = WS.CurrentCamera
local Mouse = LP:GetMouse()

local CoreGui
pcall(function() CoreGui = game:GetService("CoreGui") end)

local VIM
pcall(function() VIM = game:GetService("VirtualInputManager") end)

local VU
pcall(function() VU = game:GetService("VirtualUser") end)

local dFont
pcall(function() dFont = Enum.Font.SourceSans end)
if not dFont then pcall(function() dFont = Enum.Font.Legacy end) end
local function sFont(n)
    local o, f = pcall(function() return Enum.Font[n] end)
    if o and f then return f end
    return dFont
end
local FBold = sFont("GothamBold") or dFont
local FMed = sFont("GothamMedium") or dFont
local FReg = sFont("Gotham") or dFont

local FE
pcall(function() FE = Enum.RaycastFilterType.Exclude end)
if not FE then pcall(function() FE = Enum.RaycastFilterType.Blacklist end) end

local hasDraw = false
pcall(function() local t = Drawing.new("Line"); t:Remove(); hasDraw = true end)

local hasHook = false
pcall(function() if getrawmetatable then hasHook = true end end)

local hasFile = false
pcall(function() if writefile and readfile and isfile then hasFile = true end end)

local allDrawings = {}

local function sNew(c, p, par)
    local o, i = pcall(function()
        local x = Instance.new(c)
        x.Name = rid(8)
        if p then for k, v in pairs(p) do pcall(function() x[k] = v end) end end
        if par then x.Parent = par end
        return x
    end)
    if o then return i end
    return nil
end

local function sDraw(c, p)
    if not hasDraw then return nil end
    local o, d = pcall(function()
        local x = Drawing.new(c)
        for k, v in pairs(p) do x[k] = v end
        return x
    end)
    if o and d then
        table.insert(allDrawings, d)
        return d
    end
    return nil
end

local function sDP(d, p, v)
    if d then pcall(function() d[p] = v end) end
end

local function sDR(d)
    if d then pcall(function() d:Remove() end) end
end

local GuiParent
pcall(function()
    if gethui then GuiParent = gethui() end
end)
if not GuiParent then
    pcall(function()
        if syn and syn.protect_gui then GuiParent = CoreGui end
    end)
end
if not GuiParent and CoreGui then
    local testOk = pcall(function()
        local t = Instance.new("Folder")
        t.Name = rid(8)
        t.Parent = CoreGui
        t:Destroy()
    end)
    if testOk then GuiParent = CoreGui end
end
if not GuiParent then
    GuiParent = LP:WaitForChild("PlayerGui")
end

local function clmp(v, mn, mx)
    if v < mn then return mn end
    if v > mx then return mx end
    return v
end

local function humanJitter()
    return Vector2.new((math.random() - 0.5) * 0.3, (math.random() - 0.5) * 0.3)
end

local function delayedRun(fn, minD, maxD)
    sspawn(function()
        swait(minD + math.random() * (maxD - minD))
        pcall(fn)
    end)
end

local COLORS = {
    White = Color3.fromRGB(255, 255, 255),
    Red = Color3.fromRGB(255, 50, 50),
    Green = Color3.fromRGB(0, 255, 128),
    Blue = Color3.fromRGB(50, 120, 255),
    Cyan = Color3.fromRGB(0, 200, 255),
    Purple = Color3.fromRGB(150, 50, 255),
    Pink = Color3.fromRGB(255, 100, 200),
    Orange = Color3.fromRGB(255, 150, 50),
    Yellow = Color3.fromRGB(255, 255, 50),
    Black = Color3.fromRGB(10, 10, 10),
    Gray = Color3.fromRGB(128, 128, 128),
}
local COLOR_LIST = {"White", "Red", "Green", "Blue", "Cyan", "Purple", "Pink", "Orange", "Yellow", "Black", "Gray"}

local function RC(name)
    return COLORS[name] or COLORS.White
end

local TH = {
    BG = Color3.fromRGB(15, 15, 20),
    SF = Color3.fromRGB(22, 22, 30),
    SL = Color3.fromRGB(32, 32, 42),
    BD = Color3.fromRGB(45, 45, 58),
    AC = Color3.fromRGB(0, 200, 255),
    A2 = Color3.fromRGB(130, 80, 255),
    A3 = Color3.fromRGB(255, 60, 120),
    TX = Color3.fromRGB(235, 235, 245),
    TM = Color3.fromRGB(130, 135, 150),
    TD = Color3.fromRGB(80, 85, 100),
    OK = Color3.fromRGB(50, 210, 100),
    ER = Color3.fromRGB(255, 70, 70),
    WN = Color3.fromRGB(255, 180, 40),
    TO = Color3.fromRGB(50, 50, 65),
    TN = Color3.fromRGB(0, 200, 255),
}

local CFG = {
    Aim = {On = false, Smooth = 8, FOV = 100, Bone = "Head", Team = true, Wall = true, Pred = false, PS = 0.1, ShowFOV = true},
    SAim = {On = false, HC = 85, Bone = "Head", Team = true},
    Trig = {On = false, Delay = 80, Team = true},
    NR = {On = false},
    ESP = {On = false, Box = true, BCP = "Cyan", Name = true, NCP = "White", HP = true, Dist = true, Trac = false, TO = "Bottom", Team = true, TC = false},
    Cross = {On = false, Sz = 6, Gap = 3, Th = 1, CP = "Green", Dot = true},
    FB = {On = false},
    NF = {On = false},
    FogCol = {On = false, Preset = "Cyan"},
    Sky = {On = false, Preset = "Purple"},
    FOVCam = {On = false, Val = 90},
    Amb = {On = false, Preset = "White"},
    ClockT = {On = false, Val = 12},
    Brt = {On = false, Val = 2},
    Blm = {On = false},
    Blr = {On = false, Val = 10},
    CC = {On = false, Brt = 0, Con = 0, Sat = 0},
    SR = {On = false},
    BHop = {On = false},
    Speed = {On = false, Val = 19},
    IJump = {On = false},
    Fly = {On = false, Val = 40},
    Noclip = {On = false},
    AAFK = {On = true},
    TP = {On = false, Dist = 10},
    MKey = Enum.KeyCode.RightControl,
}

local F = {}
F.AT = nil
F.ED = {}
F.CD = {}
F.FC = nil
F.OL = {}
F.BloomE = nil
F.BlurE = nil
F.CCE = nil
F.SRE = nil
F.CustomAtmo = nil

local UI = {Tabs = {}, SG = nil, MF = nil, CF = nil, AT = nil, Vis = true, SB = nil, Elems = {}, DDs = {}}

local running = true
local connections = {}

local function serializeCfg()
    local out = {}
    for k, v in pairs(CFG) do
        if type(v) == "table" then
            out[k] = {}
            for k2, v2 in pairs(v) do
                local t = type(v2)
                if t == "boolean" or t == "number" or t == "string" then
                    out[k][k2] = v2
                end
            end
        end
    end
    return out
end

local function deserializeCfg(data)
    if type(data) ~= "table" then return end
    for k, v in pairs(data) do
        if type(v) == "table" and type(CFG[k]) == "table" then
            for k2, v2 in pairs(v) do
                if CFG[k][k2] ~= nil and type(CFG[k][k2]) == type(v2) then
                    CFG[k][k2] = v2
                end
            end
        end
    end
end

local function saveCfg(name)
    if not hasFile then return false end
    local s = pcall(function()
        writefile("bsd_" .. name .. ".json", HS:JSONEncode(serializeCfg()))
    end)
    return s
end

local function loadCfgFile(name)
    if not hasFile then return false end
    local s = pcall(function()
        if isfile("bsd_" .. name .. ".json") then
            deserializeCfg(HS:JSONDecode(readfile("bsd_" .. name .. ".json")))
        end
    end)
    return s
end

local function applyPreset(preset)
    for k, v in pairs(preset) do
        if type(v) == "table" and type(CFG[k]) == "table" then
            for k2, v2 in pairs(v) do
                CFG[k][k2] = v2
            end
        end
    end
end

local PRESETS = {}

PRESETS.Default = {
    Aim = {On = false, Smooth = 8, FOV = 100, Bone = "Head", Team = true, Wall = true, Pred = false, PS = 0.1, ShowFOV = true},
    SAim = {On = false, HC = 85, Bone = "Head", Team = true},
    Trig = {On = false, Delay = 80, Team = true},
    NR = {On = false},
    ESP = {On = false, Box = true, BCP = "Cyan", Name = true, NCP = "White", HP = true, Dist = true, Trac = false, TO = "Bottom", Team = true, TC = false},
    Cross = {On = false, Sz = 6, Gap = 3, Th = 1, CP = "Green", Dot = true},
    FB = {On = false},
    NF = {On = false},
    FogCol = {On = false, Preset = "Cyan"},
    Sky = {On = false, Preset = "Purple"},
    FOVCam = {On = false, Val = 90},
    Amb = {On = false, Preset = "White"},
    ClockT = {On = false, Val = 12},
    Brt = {On = false, Val = 2},
    Blm = {On = false},
    Blr = {On = false, Val = 10},
    CC = {On = false, Brt = 0, Con = 0, Sat = 0},
    SR = {On = false},
    BHop = {On = false},
    Speed = {On = false, Val = 19},
    IJump = {On = false},
    Fly = {On = false, Val = 40},
    Noclip = {On = false},
    AAFK = {On = false},
    TP = {On = false, Dist = 10},
}

PRESETS.Legit = {
    Aim = {On = true, Smooth = 14, FOV = 60, ShowFOV = false},
    NR = {On = true},
    ESP = {On = true},
    Cross = {On = true, Sz = 4, Gap = 2},
    AAFK = {On = true},
}

PRESETS.Risk = {
    Aim = {On = true, Smooth = 3, FOV = 300, Wall = false, Pred = true, ShowFOV = true},
    SAim = {On = true, HC = 100},
    Trig = {On = true, Delay = 40},
    NR = {On = true},
    ESP = {On = true, BCP = "Red", Dist = true, Trac = true},
    Cross = {On = true, Sz = 8, Gap = 4, Th = 2, CP = "Red"},
    FB = {On = true},
    NF = {On = true},
    FOVCam = {On = true, Val = 110},
    BHop = {On = true},
    Speed = {On = true, Val = 24},
    IJump = {On = true},
    Fly = {Val = 60},
    AAFK = {On = true},
}

local function loadPreset(name)
    applyPreset(PRESETS.Default)
    if name ~= "Default" and PRESETS[name] then
        applyPreset(PRESETS[name])
    end
    if CFG.SAim.On then pcall(function() F:InitSA() end) end
    pcall(function() UI:Refresh() end)
end

local GK = "_x" .. tostring(game.PlaceId)

pcall(function()
    if getgenv then
        local old = getgenv()[GK]
        if type(old) == "table" then
            if old.sg then pcall(function() old.sg:Destroy() end) end
            if old.drawings then
                for _, d in ipairs(old.drawings) do pcall(function() d:Remove() end) end
            end
            for _, k in ipairs({"bloom", "blur", "cc", "sr", "atmo"}) do
                if old[k] then pcall(function() old[k]:Destroy() end) end
            end
            getgenv()[GK] = nil
        end
    end
end)

local function regGenv(key, val)
    pcall(function()
        if getgenv then
            if not getgenv()[GK] then getgenv()[GK] = {} end
            getgenv()[GK][key] = val
        end
    end)
end

regGenv("drawings", allDrawings)

local _acSgRef = nil

local saInit = false
pcall(function()
    if not hasHook then return end
    local mt = getrawmetatable(game)
    if not mt then return end
    local origNC = mt.__namecall
    if not origNC then return end
    local wf = newcclosure or function(f) return f end
    if setreadonly then setreadonly(mt, false) end
    if make_writeable then make_writeable(mt) end
    mt.__namecall = wf(function(self, ...)
        local method = getnamecallmethod()
        if method == "FireServer" or method == "InvokeServer" then
            local rn = ""
            pcall(function() rn = self.Name:lower() end)
            if rn:find("ban") or rn:find("kick") or rn:find("detect") or rn:find("report")
                or rn:find("flag") or rn:find("secur") or rn:find("cheat") or rn:find("violat")
                or rn:find("punish") or rn:find("guard") or rn:find("exploit") or rn:find("hack")
                or rn:find("verify") or rn:find("check") or rn:find("scan") or rn:find("monitor")
                or rn:find("integrity") or rn:find("valid") or rn:find("anticheat") or rn:find("anti_cheat")
                or rn:find("ac_") or rn:find("_ac") then
                return nil
            end
            if CFG.SAim.On and F.SilentTgt then
                local stOk, stg = pcall(F.SilentTgt, F)
                if stOk and stg and math.random(1, 100) <= CFG.SAim.HC then
                    local a = {...}
                    for i, v in pairs(a) do
                        if typeof(v) == "CFrame" then a[i] = CFrame.new(stg.Position)
                        elseif typeof(v) == "Vector3" then a[i] = stg.Position end
                    end
                    return origNC(self, unpack(a))
                end
            end
        end
        return origNC(self, ...)
    end)
    if setreadonly then setreadonly(mt, true) end
    if make_readonly then make_readonly(mt) end
    saInit = true
end)

pcall(function()
    if not hookfunction then return end
    if not newcclosure then return end
    local oldGC = game.GetChildren
    local oldGD = game.GetDescendants
    hookfunction(oldGC, newcclosure(function(self, ...)
        local result = oldGC(self, ...)
        if _acSgRef and (self == GuiParent or self == CoreGui or (gethui and self == gethui())) then
            local filtered = {}
            for _, v in ipairs(result) do
                if v ~= _acSgRef then
                    table.insert(filtered, v)
                end
            end
            return filtered
        end
        return result
    end))
    hookfunction(oldGD, newcclosure(function(self, ...)
        local result = oldGD(self, ...)
        if _acSgRef and (self == GuiParent or self == CoreGui or (gethui and self == gethui())) then
            local filtered = {}
            for _, v in ipairs(result) do
                if v ~= _acSgRef and not v:IsDescendantOf(_acSgRef) then
                    table.insert(filtered, v)
                end
            end
            return filtered
        end
        return result
    end))
end)

pcall(function()
    local acKW = {"anticheat", "anti_cheat", "ac_", "detect", "security", "guard", "shield", "protect", "cheatcheck", "exploitcheck", "integrity"}
    for _, v in ipairs(game:GetDescendants()) do
        pcall(function()
            if v:IsA("LocalScript") then
                local n = v.Name:lower()
                for _, kw in ipairs(acKW) do
                    if n:find(kw) then
                        v.Disabled = true
                        break
                    end
                end
            end
        end)
    end
end)

pcall(function()
    if getconnections then
        for _, sig in ipairs({RS.RenderStepped, RS.Heartbeat, RS.Stepped}) do
            pcall(function()
                for _, conn in ipairs(getconnections(sig)) do
                    pcall(function()
                        if conn.Function then
                            local info = debug.getinfo and debug.getinfo(conn.Function)
                            if info and info.source and info.source:find("anticheat") then
                                conn:Disable()
                            end
                        end
                    end)
                end
            end)
        end
    end
end)

local OURL = "https://offsets.ntgetwritewatch.workers.dev/offsets_structured.hpp"
local Offsets = {}
local OVer = "unknown"
local OStat = "Not fetched"

local function FetchOff()
    local d = nil
    local fetchErr = ""
    pcall(function() d = game:HttpGet(OURL) end)
    if not d or d == "" then
        pcall(function()
            if request then d = request({Url = OURL}).Body end
        end)
    end
    if not d or d == "" then
        pcall(function()
            if http_request then d = http_request({Url = OURL}).Body end
        end)
    end
    if not d or d == "" then
        pcall(function()
            if syn and syn.request then d = syn.request({Url = OURL}).Body end
        end)
    end
    if not d or d == "" then
        OStat = "Failed - no HTTP access"
        return
    end
    if d:find("<!DOCTYPE") or d:find("<html") then
        OStat = "Failed - URL blocked"
        return
    end
    local P, ns = {}, nil
    for ln in d:gmatch("[^\r\n]+") do
        local n = ln:match("namespace%s+(%w+)")
        if n then ns = n; P[ns] = P[ns] or {} end
        local nm, hx = ln:match("inline%s+constexpr%s+uintptr_t%s+(%w+)%s*=%s*(0x%x+)")
        if nm and hx and ns then P[ns][nm] = tonumber(hx) end
    end
    local v = d:match("Roblox Version:%s*([%w%-]+)")
    if v then OVer = v end
    Offsets = P
    if OVer ~= "unknown" then
        OStat = "Synced (" .. OVer .. ")"
    else
        OStat = "Parsed (no version)"
    end
end

local function W2S(p)
    local v, o = Cam:WorldToViewportPoint(p)
    return Vector2.new(v.X, v.Y), o, v.Z
end

local function GetChar(p) return p and p.Character end

local function Alive(p)
    local c = GetChar(p)
    if not c then return false end
    local h = c:FindFirstChildOfClass("Humanoid")
    return h and h.Health > 0
end

local function Enemy(p, tc)
    if p == LP then return false end
    if not tc then return true end
    if not LP.Team or not p.Team then return true end
    return p.Team ~= LP.Team
end

local function Visible(tp)
    if not tp then return false end
    local pr = RaycastParams.new()
    pr.FilterType = FE
    pr.FilterDescendantsInstances = {LP.Character}
    local r = WS:Raycast(Cam.CFrame.Position, tp.Position - Cam.CFrame.Position, pr)
    if r then return r.Instance:IsDescendantOf(tp.Parent) end
    return true
end

local function GetBone(ch, bn)
    if not ch then return nil end
    local p = ch:FindFirstChild(bn)
    if p then return p end
    if bn == "Head" then return ch:FindFirstChild("Head") end
    if bn == "Torso" then return ch:FindFirstChild("HumanoidRootPart") or ch:FindFirstChild("UpperTorso") end
    return ch:FindFirstChild("HumanoidRootPart")
end

local function ScrCen()
    local v = Cam.ViewportSize
    return Vector2.new(v.X / 2, v.Y / 2)
end

local origL = {}
pcall(function()
    origL.Ambient = Light.Ambient
    origL.Brightness = Light.Brightness
    origL.OutdoorAmbient = Light.OutdoorAmbient
    origL.FogEnd = Light.FogEnd
    origL.FogStart = Light.FogStart
    origL.FogColor = Light.FogColor
    origL.ClockTime = Light.ClockTime
    origL.FOV = Cam.FieldOfView
end)

local function Notify(title, msg, dur)
    if not hasDraw then return end
    dur = dur or 3
    local vp
    pcall(function() vp = Cam.ViewportSize end)
    if not vp then return end
    local txt = sDraw("Text", {
        Visible = true, Size = 14, Center = false, Outline = true, Font = 2,
        Color = TH.AC, Position = Vector2.new(vp.X - 380, vp.Y - 50),
        Text = "[" .. title .. "] " .. msg
    })
    sspawn(function()
        swait(dur)
        sDR(txt)
    end)
end

local TAB_ICONS = {Combat = "@", Visuals = "#", Movement = ">", Misc = "*", Settings = "="}

function UI:Init()
    local sg = Instance.new("ScreenGui")
    sg.Name = rid(16)
    sg.ResetOnSpawn = false
    pcall(function() sg.Enabled = true end)
    pcall(function() sg.DisplayOrder = 1 end)
    pcall(function() sg.IgnoreGuiInset = true end)
    pcall(function() sg.ZIndexBehavior = Enum.ZIndexBehavior.Sibling end)

    pcall(function() if syn and syn.protect_gui then syn.protect_gui(sg) end end)
    sg.Parent = GuiParent
    self.SG = sg
    _acSgRef = sg
    regGenv("sg", sg)

    pcall(function()
        LP.CharacterAdded:Connect(function()
            swait(1)
            if sg and not sg.Parent then sg.Parent = GuiParent end
        end)
    end)

    local mf = Instance.new("Frame")
    mf.Name = rid(8)
    mf.Size = UDim2.new(0, 640, 0, 480)
    mf.Position = UDim2.new(0.5, -320, 0.5, -240)
    mf.BackgroundColor3 = TH.BG
    mf.BorderSizePixel = 0
    mf.ClipsDescendants = true
    mf.Active = true
    mf.Parent = sg
    sNew("UICorner", {CornerRadius = UDim.new(0, 12)}, mf)

    local outerStroke = sNew("UIStroke", {Color = TH.AC, Thickness = 1, Transparency = 0.7}, mf)
    if outerStroke then
        sspawn(function()
            local t = 0
            while sg and sg.Parent and running do
                t = t + 0.02
                pcall(function()
                    outerStroke.Transparency = 0.5 + math.sin(t) * 0.3
                    outerStroke.Color = Color3.fromRGB(
                        math.floor(0 + 130 * math.abs(math.sin(t * 0.5))),
                        math.floor(200 - 120 * math.abs(math.sin(t * 0.3))),
                        255
                    )
                end)
                RS.RenderStepped:Wait()
            end
        end)
    end

    self.MF = mf

    local tb = Instance.new("Frame")
    tb.Name = rid(6)
    tb.Size = UDim2.new(1, 0, 0, 44)
    tb.BackgroundColor3 = TH.SF
    tb.BorderSizePixel = 0
    tb.Active = true
    tb.Parent = mf
    sNew("UICorner", {CornerRadius = UDim.new(0, 12)}, tb)

    local tbf = Instance.new("Frame")
    tbf.Name = rid(4)
    tbf.Size = UDim2.new(1, 0, 0, 14)
    tbf.Position = UDim2.new(0, 0, 1, -14)
    tbf.BackgroundColor3 = TH.SF
    tbf.BorderSizePixel = 0
    tbf.Parent = tb

    local al = Instance.new("Frame")
    al.Name = rid(4)
    al.Size = UDim2.new(1, 0, 0, 2)
    al.Position = UDim2.new(0, 0, 1, 0)
    al.BorderSizePixel = 0
    al.BackgroundColor3 = TH.AC
    al.Parent = tb
    local alg = sNew("UIGradient", {Color = ColorSequence.new({
        ColorSequenceKeypoint.new(0, TH.A2),
        ColorSequenceKeypoint.new(0.3, TH.AC),
        ColorSequenceKeypoint.new(0.7, TH.A3),
        ColorSequenceKeypoint.new(1, TH.A2),
    })}, al)
    if alg then
        sspawn(function()
            local o = 0
            while sg and sg.Parent and running do
                o = (o + 0.003) % 1
                pcall(function() alg.Offset = Vector2.new(math.sin(o * math.pi * 2) * 0.5, 0) end)
                RS.RenderStepped:Wait()
            end
        end)
    end

    local logo = Instance.new("TextLabel")
    logo.Name = rid(4)
    logo.Text = "DOMINATION"
    logo.Font = FBold
    logo.TextSize = 15
    logo.TextColor3 = TH.TX
    logo.BackgroundTransparency = 1
    logo.Position = UDim2.new(0, 16, 0, 0)
    logo.Size = UDim2.new(0, 140, 1, 0)
    logo.TextXAlignment = Enum.TextXAlignment.Left
    logo.Parent = tb

    local sub = Instance.new("TextLabel")
    sub.Name = rid(4)
    sub.Text = "premium"
    sub.Font = FMed
    sub.TextSize = 10
    sub.TextColor3 = TH.TM
    sub.BackgroundTransparency = 1
    sub.Position = UDim2.new(0, 160, 0, 2)
    sub.Size = UDim2.new(0, 60, 1, 0)
    sub.TextXAlignment = Enum.TextXAlignment.Left
    sub.Parent = tb

    local vb = Instance.new("TextLabel")
    vb.Name = rid(4)
    vb.Text = "v5.0"
    vb.Font = FBold
    vb.TextSize = 9
    vb.TextColor3 = TH.AC
    vb.BackgroundColor3 = Color3.fromRGB(0, 35, 50)
    vb.Position = UDim2.new(0, 225, 0.5, -8)
    vb.Size = UDim2.new(0, 30, 0, 16)
    vb.Parent = tb
    sNew("UICorner", {CornerRadius = UDim.new(0, 4)}, vb)

    local cb = Instance.new("TextButton")
    cb.Name = rid(4)
    cb.Text = "X"
    cb.Font = FBold
    cb.TextSize = 13
    cb.TextColor3 = TH.TM
    cb.BackgroundTransparency = 1
    cb.Position = UDim2.new(1, -40, 0, 0)
    cb.Size = UDim2.new(0, 40, 1, 0)
    cb.Parent = tb
    cb.MouseButton1Click:Connect(function() self:Toggle() end)
    cb.MouseEnter:Connect(function() TS:Create(cb, TweenInfo.new(0.15), {TextColor3 = TH.ER}):Play() end)
    cb.MouseLeave:Connect(function() TS:Create(cb, TweenInfo.new(0.15), {TextColor3 = TH.TM}):Play() end)

    local mn = Instance.new("TextButton")
    mn.Name = rid(4)
    mn.Text = "-"
    mn.Font = FBold
    mn.TextSize = 18
    mn.TextColor3 = TH.TM
    mn.BackgroundTransparency = 1
    mn.Position = UDim2.new(1, -72, 0, 0)
    mn.Size = UDim2.new(0, 32, 1, 0)
    mn.Parent = tb
    mn.MouseEnter:Connect(function() TS:Create(mn, TweenInfo.new(0.15), {TextColor3 = TH.WN}):Play() end)
    mn.MouseLeave:Connect(function() TS:Create(mn, TweenInfo.new(0.15), {TextColor3 = TH.TM}):Play() end)

    local drag, ds, sp = false, nil, nil
    tb.InputBegan:Connect(function(i)
        if i.UserInputType == Enum.UserInputType.MouseButton1 or i.UserInputType == Enum.UserInputType.Touch then
            drag = true
            ds = i.Position
            sp = mf.Position
        end
    end)
    tb.InputEnded:Connect(function(i)
        if i.UserInputType == Enum.UserInputType.MouseButton1 or i.UserInputType == Enum.UserInputType.Touch then
            drag = false
        end
    end)
    UIS.InputChanged:Connect(function(i)
        if drag and (i.UserInputType == Enum.UserInputType.MouseMovement or i.UserInputType == Enum.UserInputType.Touch) then
            local d = i.Position - ds
            mf.Position = UDim2.new(sp.X.Scale, sp.X.Offset + d.X, sp.Y.Scale, sp.Y.Offset + d.Y)
        end
    end)

    local sb = Instance.new("Frame")
    sb.Name = rid(6)
    sb.Size = UDim2.new(0, 160, 1, -46)
    sb.Position = UDim2.new(0, 0, 0, 46)
    sb.BackgroundColor3 = TH.SF
    sb.BorderSizePixel = 0
    sb.Parent = mf

    local sep = Instance.new("Frame")
    sep.Name = rid(4)
    sep.Size = UDim2.new(0, 1, 1, 0)
    sep.Position = UDim2.new(1, 0, 0, 0)
    sep.BackgroundColor3 = TH.BD
    sep.BorderSizePixel = 0
    sep.BackgroundTransparency = 0.5
    sep.Parent = sb

    local sbl = Instance.new("UIListLayout")
    sbl.SortOrder = Enum.SortOrder.LayoutOrder
    sbl.Padding = UDim.new(0, 4)
    sbl.Parent = sb

    local sbp = Instance.new("UIPadding")
    sbp.PaddingTop = UDim.new(0, 10)
    sbp.PaddingLeft = UDim.new(0, 8)
    sbp.PaddingRight = UDim.new(0, 8)
    sbp.Parent = sb
    self.SB = sb

    local cf = Instance.new("Frame")
    cf.Name = rid(6)
    cf.Size = UDim2.new(1, -161, 1, -70)
    cf.Position = UDim2.new(0, 161, 0, 46)
    cf.BackgroundTransparency = 1
    cf.Parent = mf
    self.CF = cf

    local stb = Instance.new("Frame")
    stb.Name = rid(4)
    stb.Size = UDim2.new(1, 0, 0, 24)
    stb.Position = UDim2.new(0, 0, 1, -24)
    stb.BackgroundColor3 = TH.SF
    stb.BorderSizePixel = 0
    stb.ZIndex = 5
    stb.Parent = mf

    local stl = Instance.new("TextLabel")
    stl.Name = rid(4)
    stl.Text = "  Stealth Active  |  RCtrl toggle"
    stl.Font = FReg
    stl.TextSize = 10
    stl.TextColor3 = TH.TD
    stl.BackgroundTransparency = 1
    stl.Size = UDim2.new(1, 0, 1, 0)
    stl.TextXAlignment = Enum.TextXAlignment.Left
    stl.Parent = stb

    local dot = Instance.new("Frame")
    dot.Name = rid(4)
    dot.Size = UDim2.new(0, 6, 0, 6)
    dot.Position = UDim2.new(1, -18, 0.5, -3)
    dot.BackgroundColor3 = TH.OK
    dot.BorderSizePixel = 0
    dot.Parent = stb
    sNew("UICorner", {CornerRadius = UDim.new(1, 0)}, dot)

    sspawn(function()
        while sg and sg.Parent and running do
            pcall(function() TS:Create(dot, TweenInfo.new(1), {BackgroundTransparency = 0.6}):Play() end)
            swait(1)
            pcall(function() TS:Create(dot, TweenInfo.new(1), {BackgroundTransparency = 0}):Play() end)
            swait(1)
        end
    end)

    sspawn(function()
        while sg and sg.Parent and running do
            pcall(function() stl.Text = "  Offsets: " .. OStat .. "  |  RCtrl toggle" end)
            swait(5)
        end
    end)

    return self
end

function UI:Tab(name, ord)
    local icon = TAB_ICONS[name] or ">"
    local btn = Instance.new("TextButton")
    btn.Name = rid(6)
    btn.Size = UDim2.new(1, 0, 0, 36)
    btn.BackgroundColor3 = TH.SL
    btn.BackgroundTransparency = 1
    btn.BorderSizePixel = 0
    btn.Text = ""
    btn.LayoutOrder = ord or (#self.Tabs + 1)
    btn.AutoButtonColor = false
    btn.Parent = self.SB
    sNew("UICorner", {CornerRadius = UDim.new(0, 8)}, btn)

    local ic = Instance.new("TextLabel")
    ic.Name = rid(4)
    ic.Text = icon
    ic.Font = FBold
    ic.TextSize = 13
    ic.TextColor3 = TH.TD
    ic.BackgroundTransparency = 1
    ic.Position = UDim2.new(0, 10, 0, 0)
    ic.Size = UDim2.new(0, 20, 1, 0)
    ic.Parent = btn

    local lb = Instance.new("TextLabel")
    lb.Name = rid(4)
    lb.Text = name
    lb.Font = FMed
    lb.TextSize = 12
    lb.TextColor3 = TH.TM
    lb.BackgroundTransparency = 1
    lb.Position = UDim2.new(0, 34, 0, 0)
    lb.Size = UDim2.new(1, -38, 1, 0)
    lb.TextXAlignment = Enum.TextXAlignment.Left
    lb.Parent = btn

    local ind = Instance.new("Frame")
    ind.Name = rid(4)
    ind.Size = UDim2.new(0, 3, 0.5, 0)
    ind.Position = UDim2.new(0, 0, 0.25, 0)
    ind.BackgroundColor3 = TH.AC
    ind.BorderSizePixel = 0
    ind.Visible = false
    ind.Parent = btn
    sNew("UICorner", {CornerRadius = UDim.new(0, 2)}, ind)

    local ct = Instance.new("ScrollingFrame")
    ct.Name = rid(8)
    ct.Size = UDim2.new(1, -16, 1, -8)
    ct.Position = UDim2.new(0, 8, 0, 4)
    ct.BackgroundTransparency = 1
    ct.ScrollBarThickness = 3
    ct.ScrollBarImageColor3 = TH.A2
    ct.BorderSizePixel = 0
    ct.CanvasSize = UDim2.new(0, 0, 0, 0)
    ct.Visible = false
    ct.Parent = self.CF

    local cl = Instance.new("UIListLayout")
    cl.SortOrder = Enum.SortOrder.LayoutOrder
    cl.Padding = UDim.new(0, 5)
    cl.Parent = ct

    local cpad = Instance.new("UIPadding")
    cpad.PaddingBottom = UDim.new(0, 20)
    cpad.Parent = ct

    cl:GetPropertyChangedSignal("AbsoluteContentSize"):Connect(function()
        ct.CanvasSize = UDim2.new(0, 0, 0, cl.AbsoluteContentSize.Y + 30)
    end)

    local td = {Btn = btn, Ct = ct, Ind = ind, Ic = ic, Lb = lb, N = name, O = 0}
    btn.MouseButton1Click:Connect(function() self:Sel(name) end)
    btn.MouseEnter:Connect(function()
        if self.AT ~= name then TS:Create(btn, TweenInfo.new(0.2), {BackgroundTransparency = 0.5}):Play() end
    end)
    btn.MouseLeave:Connect(function()
        if self.AT ~= name then TS:Create(btn, TweenInfo.new(0.2), {BackgroundTransparency = 1}):Play() end
    end)
    table.insert(self.Tabs, td)
    return td
end

function UI:Sel(name)
    self:CloseDropdowns()
    for _, t in ipairs(self.Tabs) do
        local a = t.N == name
        t.Ct.Visible = a
        t.Ind.Visible = a
        TS:Create(t.Btn, TweenInfo.new(0.25), {BackgroundTransparency = a and 0.6 or 1}):Play()
        TS:Create(t.Lb, TweenInfo.new(0.25), {TextColor3 = a and TH.TX or TH.TM}):Play()
        TS:Create(t.Ic, TweenInfo.new(0.25), {TextColor3 = a and TH.AC or TH.TD}):Play()
    end
    self.AT = name
end

function UI:Sec(td, title)
    local s = Instance.new("Frame")
    s.Name = rid(4)
    s.Size = UDim2.new(1, 0, 0, 30)
    s.BackgroundTransparency = 1
    s.LayoutOrder = td.O
    td.O = td.O + 1
    s.Parent = td.Ct

    local ln = Instance.new("Frame")
    ln.Name = rid(4)
    ln.Size = UDim2.new(1, 0, 0, 1)
    ln.Position = UDim2.new(0, 0, 0.5, 0)
    ln.BackgroundColor3 = TH.BD
    ln.BorderSizePixel = 0
    ln.BackgroundTransparency = 0.5
    ln.Parent = s

    local lb = Instance.new("TextLabel")
    lb.Name = rid(4)
    lb.Text = "  " .. title .. "  "
    lb.Font = FBold
    lb.TextSize = 9
    lb.TextColor3 = TH.A2
    lb.BackgroundColor3 = TH.BG
    lb.Position = UDim2.new(0, 8, 0, 7)
    lb.Size = UDim2.new(0, 120, 0, 16)
    lb.Parent = s
end

function UI:Tog(td, name, tbl, key, cb)
    local fr = Instance.new("Frame")
    fr.Name = rid(6)
    fr.Size = UDim2.new(1, 0, 0, 36)
    fr.BackgroundColor3 = TH.SL
    fr.BackgroundTransparency = 0.4
    fr.BorderSizePixel = 0
    fr.LayoutOrder = td.O
    td.O = td.O + 1
    fr.Parent = td.Ct
    sNew("UICorner", {CornerRadius = UDim.new(0, 8)}, fr)

    local lb = Instance.new("TextLabel")
    lb.Name = rid(4)
    lb.Text = name
    lb.Font = FReg
    lb.TextSize = 12
    lb.TextColor3 = TH.TX
    lb.BackgroundTransparency = 1
    lb.Position = UDim2.new(0, 14, 0, 0)
    lb.Size = UDim2.new(1, -70, 1, 0)
    lb.TextXAlignment = Enum.TextXAlignment.Left
    lb.Parent = fr

    local bg = Instance.new("Frame")
    bg.Name = rid(4)
    bg.Size = UDim2.new(0, 38, 0, 20)
    bg.Position = UDim2.new(1, -50, 0.5, -10)
    bg.BackgroundColor3 = tbl[key] and TH.TN or TH.TO
    bg.BorderSizePixel = 0
    bg.Parent = fr
    sNew("UICorner", {CornerRadius = UDim.new(1, 0)}, bg)

    local kn = Instance.new("Frame")
    kn.Name = rid(4)
    kn.Size = UDim2.new(0, 16, 0, 16)
    kn.Position = tbl[key] and UDim2.new(1, -18, 0.5, -8) or UDim2.new(0, 2, 0.5, -8)
    kn.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
    kn.BorderSizePixel = 0
    kn.Parent = bg
    sNew("UICorner", {CornerRadius = UDim.new(1, 0)}, kn)

    local bt = Instance.new("TextButton")
    bt.Name = rid(4)
    bt.Size = UDim2.new(1, 0, 1, 0)
    bt.BackgroundTransparency = 1
    bt.Text = ""
    bt.ZIndex = 2
    bt.Parent = fr
    bt.MouseButton1Click:Connect(function()
        tbl[key] = not tbl[key]
        local e = tbl[key]
        TS:Create(bg, TweenInfo.new(0.25, Enum.EasingStyle.Back), {BackgroundColor3 = e and TH.TN or TH.TO}):Play()
        TS:Create(kn, TweenInfo.new(0.25, Enum.EasingStyle.Back), {Position = e and UDim2.new(1, -18, 0.5, -8) or UDim2.new(0, 2, 0.5, -8)}):Play()
        if cb then pcall(cb, e) end
    end)
    bt.MouseEnter:Connect(function() TS:Create(fr, TweenInfo.new(0.15), {BackgroundTransparency = 0.2}):Play() end)
    bt.MouseLeave:Connect(function() TS:Create(fr, TweenInfo.new(0.15), {BackgroundTransparency = 0.4}):Play() end)

    table.insert(self.Elems, function()
        local e = tbl[key]
        pcall(function() bg.BackgroundColor3 = e and TH.TN or TH.TO end)
        pcall(function() kn.Position = e and UDim2.new(1, -18, 0.5, -8) or UDim2.new(0, 2, 0.5, -8) end)
    end)
end

function UI:Sli(td, name, mn, mx, tbl, key, cb)
    local fr = Instance.new("Frame")
    fr.Name = rid(6)
    fr.Size = UDim2.new(1, 0, 0, 52)
    fr.BackgroundColor3 = TH.SL
    fr.BackgroundTransparency = 0.4
    fr.BorderSizePixel = 0
    fr.LayoutOrder = td.O
    td.O = td.O + 1
    fr.Parent = td.Ct
    sNew("UICorner", {CornerRadius = UDim.new(0, 8)}, fr)

    local lb = Instance.new("TextLabel")
    lb.Name = rid(4)
    lb.Text = name
    lb.Font = FReg
    lb.TextSize = 12
    lb.TextColor3 = TH.TX
    lb.BackgroundTransparency = 1
    lb.Position = UDim2.new(0, 14, 0, 2)
    lb.Size = UDim2.new(1, -70, 0, 22)
    lb.TextXAlignment = Enum.TextXAlignment.Left
    lb.Parent = fr

    local vl = Instance.new("TextLabel")
    vl.Name = rid(4)
    vl.Text = tostring(tbl[key])
    vl.Font = FBold
    vl.TextSize = 11
    vl.TextColor3 = TH.AC
    vl.BackgroundTransparency = 1
    vl.Position = UDim2.new(1, -50, 0, 2)
    vl.Size = UDim2.new(0, 40, 0, 22)
    vl.TextXAlignment = Enum.TextXAlignment.Right
    vl.Parent = fr

    local tr = Instance.new("Frame")
    tr.Name = rid(4)
    tr.Size = UDim2.new(1, -28, 0, 6)
    tr.Position = UDim2.new(0, 14, 0, 34)
    tr.BackgroundColor3 = TH.BD
    tr.BorderSizePixel = 0
    tr.Parent = fr
    sNew("UICorner", {CornerRadius = UDim.new(1, 0)}, tr)

    local r = math.max(mx - mn, 1)
    local pct = clmp((tbl[key] - mn) / r, 0, 1)

    local fi = Instance.new("Frame")
    fi.Name = rid(4)
    fi.Size = UDim2.new(pct, 0, 1, 0)
    fi.BackgroundColor3 = TH.AC
    fi.BorderSizePixel = 0
    fi.Parent = tr
    sNew("UICorner", {CornerRadius = UDim.new(1, 0)}, fi)
    sNew("UIGradient", {Color = ColorSequence.new({
        ColorSequenceKeypoint.new(0, TH.AC),
        ColorSequenceKeypoint.new(1, TH.A2),
    })}, fi)

    local sbtn = Instance.new("TextButton")
    sbtn.Name = rid(4)
    sbtn.Size = UDim2.new(1, 0, 0, 22)
    sbtn.Position = UDim2.new(0, 0, 0, 26)
    sbtn.BackgroundTransparency = 1
    sbtn.Text = ""
    sbtn.Parent = fr

    local sliding = false
    local function upd(ix)
        local ap = tr.AbsolutePosition.X
        local az = tr.AbsoluteSize.X
        if az == 0 then return end
        local rl = clmp((ix - ap) / az, 0, 1)
        local val = math.floor(mn + r * rl)
        tbl[key] = val
        vl.Text = tostring(val)
        fi.Size = UDim2.new(rl, 0, 1, 0)
        if cb then pcall(cb, val) end
    end

    sbtn.InputBegan:Connect(function(i)
        if i.UserInputType == Enum.UserInputType.MouseButton1 or i.UserInputType == Enum.UserInputType.Touch then
            sliding = true
            upd(i.Position.X)
        end
    end)
    sbtn.InputEnded:Connect(function(i)
        if i.UserInputType == Enum.UserInputType.MouseButton1 or i.UserInputType == Enum.UserInputType.Touch then
            sliding = false
        end
    end)
    UIS.InputChanged:Connect(function(i)
        if sliding and (i.UserInputType == Enum.UserInputType.MouseMovement or i.UserInputType == Enum.UserInputType.Touch) then
            upd(i.Position.X)
        end
    end)

    table.insert(self.Elems, function()
        local p2 = clmp((tbl[key] - mn) / r, 0, 1)
        pcall(function() fi.Size = UDim2.new(p2, 0, 1, 0) end)
        pcall(function() vl.Text = tostring(tbl[key]) end)
    end)
end

function UI:Drop(td, name, opts, tbl, key, cb)
    local fr = Instance.new("Frame")
    fr.Name = rid(6)
    fr.Size = UDim2.new(1, 0, 0, 36)
    fr.BackgroundColor3 = TH.SL
    fr.BackgroundTransparency = 0.4
    fr.BorderSizePixel = 0
    fr.ClipsDescendants = false
    fr.LayoutOrder = td.O
    td.O = td.O + 1
    fr.ZIndex = 5
    fr.Parent = td.Ct
    sNew("UICorner", {CornerRadius = UDim.new(0, 8)}, fr)

    local lb = Instance.new("TextLabel")
    lb.Name = rid(4)
    lb.Text = name
    lb.Font = FReg
    lb.TextSize = 12
    lb.TextColor3 = TH.TX
    lb.BackgroundTransparency = 1
    lb.Position = UDim2.new(0, 14, 0, 0)
    lb.Size = UDim2.new(0.5, 0, 1, 0)
    lb.TextXAlignment = Enum.TextXAlignment.Left
    lb.ZIndex = 5
    lb.Parent = fr

    local sbtn = Instance.new("TextButton")
    sbtn.Name = rid(4)
    sbtn.Text = tostring(tbl[key]) .. " v"
    sbtn.Font = FMed
    sbtn.TextSize = 11
    sbtn.TextColor3 = TH.AC
    sbtn.BackgroundColor3 = TH.BG
    sbtn.Position = UDim2.new(1, -130, 0.5, -12)
    sbtn.Size = UDim2.new(0, 118, 0, 24)
    sbtn.AutoButtonColor = false
    sbtn.ZIndex = 5
    sbtn.Parent = fr
    sNew("UICorner", {CornerRadius = UDim.new(0, 4)}, sbtn)

    local dd = Instance.new("Frame")
    dd.Name = rid(4)
    dd.Size = UDim2.new(0, 118, 0, #opts * 28 + 4)
    dd.Position = UDim2.new(1, -130, 1, 2)
    dd.BackgroundColor3 = TH.SF
    dd.BorderSizePixel = 0
    dd.Visible = false
    dd.ZIndex = 50
    dd.Parent = fr
    sNew("UICorner", {CornerRadius = UDim.new(0, 8)}, dd)
    sNew("UIStroke", {Color = TH.BD, Thickness = 1}, dd)

    local dl = Instance.new("UIListLayout")
    dl.Padding = UDim.new(0, 0)
    dl.Parent = dd

    local dp = Instance.new("UIPadding")
    dp.PaddingTop = UDim.new(0, 2)
    dp.PaddingBottom = UDim.new(0, 2)
    dp.Parent = dd

    for _, op in ipairs(opts) do
        local ob = Instance.new("TextButton")
        ob.Name = rid(4)
        ob.Text = tostring(op)
        ob.Font = FReg
        ob.TextSize = 11
        ob.TextColor3 = TH.TX
        ob.BackgroundTransparency = 1
        ob.Size = UDim2.new(1, 0, 0, 28)
        ob.AutoButtonColor = false
        ob.ZIndex = 51
        ob.Parent = dd
        ob.MouseEnter:Connect(function() ob.BackgroundTransparency = 0.7; ob.BackgroundColor3 = TH.AC end)
        ob.MouseLeave:Connect(function() ob.BackgroundTransparency = 1 end)
        ob.MouseButton1Click:Connect(function()
            tbl[key] = op
            sbtn.Text = tostring(op) .. " v"
            dd.Visible = false
            if cb then pcall(cb, op) end
        end)
    end

    sbtn.MouseButton1Click:Connect(function()
        local show = not dd.Visible
        for _, other in ipairs(self.DDs) do
            if other ~= dd then pcall(function() other.Visible = false end) end
        end
        dd.Visible = show
    end)

    table.insert(self.DDs, dd)

    table.insert(self.Elems, function()
        pcall(function() sbtn.Text = tostring(tbl[key]) .. " v" end)
    end)
end

function UI:Btn(td, name, cb)
    local bt = Instance.new("TextButton")
    bt.Name = rid(6)
    bt.Size = UDim2.new(1, 0, 0, 36)
    bt.BackgroundColor3 = TH.A2
    bt.BackgroundTransparency = 0.6
    bt.BorderSizePixel = 0
    bt.Text = name
    bt.Font = FBold
    bt.TextSize = 12
    bt.TextColor3 = TH.TX
    bt.AutoButtonColor = false
    bt.LayoutOrder = td.O
    td.O = td.O + 1
    bt.Parent = td.Ct
    sNew("UICorner", {CornerRadius = UDim.new(0, 8)}, bt)
    bt.MouseEnter:Connect(function() TS:Create(bt, TweenInfo.new(0.15), {BackgroundTransparency = 0.3}):Play() end)
    bt.MouseLeave:Connect(function() TS:Create(bt, TweenInfo.new(0.15), {BackgroundTransparency = 0.6}):Play() end)
    bt.MouseButton1Click:Connect(function() if cb then pcall(cb) end end)
end

function UI:Toggle()
    self.Vis = not self.Vis
    self.MF.Visible = self.Vis
end

function UI:Kill()
    pcall(function() self.SG:Destroy() end)
end

function UI:Refresh()
    for _, fn in ipairs(self.Elems) do
        pcall(fn)
    end
end

function UI:CloseDropdowns()
    for _, dd in ipairs(self.DDs) do
        pcall(function() dd.Visible = false end)
    end
end

function F:ClosestP()
    local fov = CFG.Aim.FOV
    local cl, cd = nil, fov
    for _, p in ipairs(Players:GetPlayers()) do
        if p ~= LP and Alive(p) and Enemy(p, CFG.Aim.Team) then
            local ch = GetChar(p)
            local bn = GetBone(ch, CFG.Aim.Bone)
            if bn then
                local sp, os = W2S(bn.Position)
                if os then
                    local mp = UIS:GetMouseLocation()
                    local d = (sp - mp).Magnitude
                    if d < cd then
                        if not CFG.Aim.Wall or Visible(bn) then
                            cl = bn
                            cd = d
                        end
                    end
                end
            end
        end
    end
    return cl
end

function F:Aimbot()
    if not CFG.Aim.On then return end
    if not UIS:IsMouseButtonPressed(Enum.UserInputType.MouseButton2) then self.AT = nil; return end
    local t = self:ClosestP()
    if not t then return end
    self.AT = t
    local tp = t.Position
    if CFG.Aim.Pred and t.Parent then
        local h = t.Parent:FindFirstChild("HumanoidRootPart")
        if h then
            local v = Vector3.new(0, 0, 0)
            pcall(function() v = h.AssemblyLinearVelocity end)
            if v == Vector3.new(0, 0, 0) then pcall(function() v = h.Velocity end) end
            tp = tp + v * CFG.Aim.PS
        end
    end
    local cc = Cam.CFrame
    local tc = CFrame.lookAt(cc.Position, tp)
    local a = 1 / math.max(CFG.Aim.Smooth, 1)
    if a > 1 then a = 1 end
    a = a * (0.85 + math.random() * 0.3)
    Cam.CFrame = cc:Lerp(tc, a)
end

function F:InitSA()
    return
end

function F:SilentTgt()
    local cl, cd = nil, CFG.Aim.FOV
    for _, p in ipairs(Players:GetPlayers()) do
        if p ~= LP and Alive(p) and Enemy(p, CFG.SAim.Team) then
            local ch = GetChar(p)
            local bn = GetBone(ch, CFG.SAim.Bone)
            if bn then
                local sp, os = W2S(bn.Position)
                if os then
                    local d = (sp - UIS:GetMouseLocation()).Magnitude
                    if d < cd then cl = bn; cd = d end
                end
            end
        end
    end
    return cl
end

function F:Triggerbot()
    if not CFG.Trig.On or not Alive(LP) then return end
    local mp = UIS:GetMouseLocation()
    local r = Cam:ViewportPointToRay(mp.X, mp.Y)
    local pr = RaycastParams.new()
    pr.FilterType = FE
    pr.FilterDescendantsInstances = {LP.Character}
    local res = WS:Raycast(r.Origin, r.Direction * 1000, pr)
    if res and res.Instance then
        local hm = res.Instance:FindFirstAncestorOfClass("Model")
        if hm then
            local hp = Players:GetPlayerFromCharacter(hm)
            if hp and Enemy(hp, CFG.Trig.Team) and Alive(hp) then
                swait((CFG.Trig.Delay + math.random(-20, 20)) / 1000)
                if VIM then
                    pcall(function()
                        VIM:SendMouseButtonEvent(mp.X, mp.Y, 0, true, game, 0)
                        swait(0.03)
                        VIM:SendMouseButtonEvent(mp.X, mp.Y, 0, false, game, 0)
                    end)
                elseif mouse1click then
                    pcall(mouse1click)
                end
            end
        end
    end
end

local storedCF = nil

function F:NoRecoil()
    if not CFG.NR.On then return end
    if UIS:IsMouseButtonPressed(Enum.UserInputType.MouseButton1) then
        if storedCF then Cam.CFrame = CFrame.new(Cam.CFrame.Position) * storedCF.Rotation end
    else
        storedCF = Cam.CFrame
    end
end

function F:InitESP(p)
    if p == LP or not hasDraw then return end
    self.ED[p] = {
        BT = sDraw("Line", {Visible = false, Thickness = 1}),
        BR = sDraw("Line", {Visible = false, Thickness = 1}),
        BB = sDraw("Line", {Visible = false, Thickness = 1}),
        BL = sDraw("Line", {Visible = false, Thickness = 1}),
        NM = sDraw("Text", {Visible = false, Size = 13, Center = true, Outline = true, Font = 2}),
        HB = sDraw("Line", {Visible = false, Color = Color3.fromRGB(30, 30, 30), Thickness = 4}),
        HF = sDraw("Line", {Visible = false, Thickness = 2}),
        DT = sDraw("Text", {Visible = false, Size = 10, Center = true, Outline = true, Font = 2}),
        TR = sDraw("Line", {Visible = false, Thickness = 1}),
    }
end

local function hideD(d)
    if not d then return end
    for _, v in pairs(d) do
        if v and v.Remove then pcall(function() v.Visible = false end) end
    end
end

local function killD(d)
    if not d then return end
    for _, v in pairs(d) do
        if v then pcall(function() v:Remove() end) end
    end
end

function F:ESP()
    if not hasDraw then return end
    if not CFG.ESP.On then
        for _, d in pairs(self.ED) do hideD(d) end
        return
    end
    for _, p in ipairs(Players:GetPlayers()) do
        if p ~= LP then
            if not self.ED[p] then self:InitESP(p) end
            local d = self.ED[p]
            if not d then return end
            local ch = GetChar(p)
            local en = Enemy(p, CFG.ESP.Team)
            if not ch or not Alive(p) or not en then
                hideD(d)
            else
                local hr = ch:FindFirstChild("HumanoidRootPart")
                local hd = ch:FindFirstChild("Head")
                local hm = ch:FindFirstChildOfClass("Humanoid")
                if not hr or not hd or not hm then
                    hideD(d)
                else
                    local ps, os2, dp = W2S(hr.Position)
                    if not os2 or dp < 0 then
                        hideD(d)
                    else
                        local hp2 = W2S(hd.Position + Vector3.new(0, 0.5, 0))
                        local fp = W2S(hr.Position - Vector3.new(0, 3, 0))
                        local bh = math.abs(hp2.Y - fp.Y)
                        local bw = bh * 0.6
                        local col = RC(CFG.ESP.BCP)
                        if CFG.ESP.TC and p.Team then pcall(function() col = p.TeamColor.Color end) end

                        if CFG.ESP.Box then
                            local tl = Vector2.new(ps.X - bw / 2, hp2.Y)
                            local tr2 = Vector2.new(ps.X + bw / 2, hp2.Y)
                            local bl = Vector2.new(ps.X - bw / 2, fp.Y)
                            local br = Vector2.new(ps.X + bw / 2, fp.Y)
                            sDP(d.BT, "From", tl); sDP(d.BT, "To", tr2); sDP(d.BT, "Color", col); sDP(d.BT, "Visible", true)
                            sDP(d.BR, "From", tr2); sDP(d.BR, "To", br); sDP(d.BR, "Color", col); sDP(d.BR, "Visible", true)
                            sDP(d.BB, "From", br); sDP(d.BB, "To", bl); sDP(d.BB, "Color", col); sDP(d.BB, "Visible", true)
                            sDP(d.BL, "From", bl); sDP(d.BL, "To", tl); sDP(d.BL, "Color", col); sDP(d.BL, "Visible", true)
                        else
                            sDP(d.BT, "Visible", false); sDP(d.BR, "Visible", false)
                            sDP(d.BB, "Visible", false); sDP(d.BL, "Visible", false)
                        end

                        if CFG.ESP.Name and d.NM then
                            sDP(d.NM, "Position", Vector2.new(ps.X, hp2.Y - 16))
                            sDP(d.NM, "Text", p.DisplayName or p.Name)
                            sDP(d.NM, "Color", RC(CFG.ESP.NCP))
                            sDP(d.NM, "Visible", true)
                        elseif d.NM then
                            sDP(d.NM, "Visible", false)
                        end

                        if CFG.ESP.HP and d.HB then
                            local pctH = clmp(hm.Health / math.max(hm.MaxHealth, 1), 0, 1)
                            local bx = ps.X - bw / 2 - 6
                            local bt2, bb = hp2.Y, fp.Y
                            local bf = bb - (bb - bt2) * pctH
                            sDP(d.HB, "From", Vector2.new(bx, bt2)); sDP(d.HB, "To", Vector2.new(bx, bb)); sDP(d.HB, "Visible", true)
                            sDP(d.HF, "From", Vector2.new(bx, bf)); sDP(d.HF, "To", Vector2.new(bx, bb))
                            sDP(d.HF, "Color", Color3.fromRGB(255 * (1 - pctH), 255 * pctH, 0))
                            sDP(d.HF, "Visible", true)
                        else
                            sDP(d.HB, "Visible", false); sDP(d.HF, "Visible", false)
                        end

                        if CFG.ESP.Dist and d.DT then
                            sDP(d.DT, "Position", Vector2.new(ps.X, fp.Y + 2))
                            sDP(d.DT, "Text", math.floor((hr.Position - Cam.CFrame.Position).Magnitude) .. "m")
                            sDP(d.DT, "Visible", true)
                        elseif d.DT then
                            sDP(d.DT, "Visible", false)
                        end

                        if CFG.ESP.Trac and d.TR then
                            local vp = Cam.ViewportSize
                            local orig
                            if CFG.ESP.TO == "Bottom" then orig = Vector2.new(vp.X / 2, vp.Y)
                            elseif CFG.ESP.TO == "Top" then orig = Vector2.new(vp.X / 2, 0)
                            else orig = Vector2.new(vp.X / 2, vp.Y / 2) end
                            sDP(d.TR, "From", orig); sDP(d.TR, "To", Vector2.new(ps.X, fp.Y))
                            sDP(d.TR, "Color", col); sDP(d.TR, "Visible", true)
                        elseif d.TR then
                            sDP(d.TR, "Visible", false)
                        end
                    end
                end
            end
        end
    end
end

function F:InitCross()
    if not hasDraw then return end
    self.CD = {
        T = sDraw("Line", {Visible = false, Thickness = 1}),
        B = sDraw("Line", {Visible = false, Thickness = 1}),
        L = sDraw("Line", {Visible = false, Thickness = 1}),
        R = sDraw("Line", {Visible = false, Thickness = 1}),
        D = sDraw("Circle", {Visible = false, Filled = true, Radius = 2, NumSides = 12}),
    }
end

function F:Cross()
    if not hasDraw then return end
    if not CFG.Cross.On then
        for _, d in pairs(self.CD) do if d then sDP(d, "Visible", false) end end
        return
    end
    local c = ScrCen()
    local s, g, cl, t = CFG.Cross.Sz, CFG.Cross.Gap, RC(CFG.Cross.CP), CFG.Cross.Th
    if self.CD.T then sDP(self.CD.T, "From", Vector2.new(c.X, c.Y - g - s)); sDP(self.CD.T, "To", Vector2.new(c.X, c.Y - g)); sDP(self.CD.T, "Color", cl); sDP(self.CD.T, "Thickness", t); sDP(self.CD.T, "Visible", true) end
    if self.CD.B then sDP(self.CD.B, "From", Vector2.new(c.X, c.Y + g)); sDP(self.CD.B, "To", Vector2.new(c.X, c.Y + g + s)); sDP(self.CD.B, "Color", cl); sDP(self.CD.B, "Thickness", t); sDP(self.CD.B, "Visible", true) end
    if self.CD.L then sDP(self.CD.L, "From", Vector2.new(c.X - g - s, c.Y)); sDP(self.CD.L, "To", Vector2.new(c.X - g, c.Y)); sDP(self.CD.L, "Color", cl); sDP(self.CD.L, "Thickness", t); sDP(self.CD.L, "Visible", true) end
    if self.CD.R then sDP(self.CD.R, "From", Vector2.new(c.X + g, c.Y)); sDP(self.CD.R, "To", Vector2.new(c.X + g + s, c.Y)); sDP(self.CD.R, "Color", cl); sDP(self.CD.R, "Thickness", t); sDP(self.CD.R, "Visible", true) end
    if self.CD.D then sDP(self.CD.D, "Position", c); sDP(self.CD.D, "Color", cl); sDP(self.CD.D, "Visible", CFG.Cross.Dot) end
end

function F:InitFOV()
    if not hasDraw then return end
    self.FC = sDraw("Circle", {Visible = false, Filled = false, Transparency = 0.7, Radius = CFG.Aim.FOV, NumSides = 64, Thickness = 1, Color = Color3.fromRGB(255, 255, 255)})
end

function F:FOVDraw()
    if not hasDraw or not self.FC then return end
    if CFG.Aim.ShowFOV and CFG.Aim.On then
        sDP(self.FC, "Position", UIS:GetMouseLocation())
        sDP(self.FC, "Radius", CFG.Aim.FOV)
        sDP(self.FC, "Visible", true)
    else
        sDP(self.FC, "Visible", false)
    end
end

function F:BHop()
    if not CFG.BHop.On or not Alive(LP) then return end
    local h = GetChar(LP) and GetChar(LP):FindFirstChildOfClass("Humanoid")
    if h and h.FloorMaterial ~= Enum.Material.Air and UIS:IsKeyDown(Enum.KeyCode.Space) then
        h:ChangeState(Enum.HumanoidStateType.Jumping)
    end
end

function F:SpeedB()
    if not Alive(LP) or not CFG.Speed.On then return end
    local ch = GetChar(LP)
    local hr = ch and ch:FindFirstChild("HumanoidRootPart")
    local hm = ch and ch:FindFirstChildOfClass("Humanoid")
    if hr and hm then
        local boost = (CFG.Speed.Val - 16) / 16
        if boost > 0 and hm.MoveDirection.Magnitude > 0 then
            hr.CFrame = hr.CFrame + hm.MoveDirection * boost * 0.3
        end
    end
end

function F:InitIJ()
    UIS.JumpRequest:Connect(function()
        if not CFG.IJump.On or not Alive(LP) then return end
        local h = GetChar(LP) and GetChar(LP):FindFirstChildOfClass("Humanoid")
        if h then h:ChangeState(Enum.HumanoidStateType.Jumping) end
    end)
end

function F:FlyF()
    if not Alive(LP) then return end
    local ch = GetChar(LP)
    local hr = ch and ch:FindFirstChild("HumanoidRootPart")
    local hm = ch and ch:FindFirstChildOfClass("Humanoid")
    if not hr or not hm then return end
    if CFG.Fly.On then
        local d = Vector3.new(0, 0, 0)
        if UIS:IsKeyDown(Enum.KeyCode.W) then d = d + Cam.CFrame.LookVector end
        if UIS:IsKeyDown(Enum.KeyCode.S) then d = d - Cam.CFrame.LookVector end
        if UIS:IsKeyDown(Enum.KeyCode.A) then d = d - Cam.CFrame.RightVector end
        if UIS:IsKeyDown(Enum.KeyCode.D) then d = d + Cam.CFrame.RightVector end
        if UIS:IsKeyDown(Enum.KeyCode.Space) then d = d + Vector3.new(0, 1, 0) end
        if UIS:IsKeyDown(Enum.KeyCode.LeftControl) then d = d - Vector3.new(0, 1, 0) end
        if d.Magnitude > 0 then
            d = d.Unit * CFG.Fly.Val * 0.016
        end
        hr.CFrame = hr.CFrame + d
        hr.Velocity = Vector3.new(0, 0, 0)
    end
end

function F:NoclipF()
    if not CFG.Noclip.On or not Alive(LP) then return end
    local ch = GetChar(LP)
    if ch then
        for _, p in ipairs(ch:GetDescendants()) do
            if p:IsA("BasePart") then p.CanCollide = false end
        end
    end
end

function F:Fullbright()
    if CFG.FB.On then
        if not self.OL.fbSet then
            self.OL.fbA = Light.Ambient
            self.OL.fbB = Light.Brightness
            self.OL.fbO = Light.OutdoorAmbient
            self.OL.fbSet = true
        end
        Light.Ambient = Color3.fromRGB(200, 200, 200)
        Light.Brightness = 2
        Light.OutdoorAmbient = Color3.fromRGB(200, 200, 200)
    elseif self.OL.fbSet then
        Light.Ambient = self.OL.fbA
        Light.Brightness = self.OL.fbB
        Light.OutdoorAmbient = self.OL.fbO
        self.OL.fbSet = nil
    end
end

function F:NoFog()
    if CFG.NF.On then
        if not self.OL.nfSet then
            self.OL.nfE = Light.FogEnd
            self.OL.nfS = Light.FogStart
            self.OL.nfSet = true
        end
        Light.FogEnd = 999999
        Light.FogStart = 999999
    elseif self.OL.nfSet then
        Light.FogEnd = self.OL.nfE
        Light.FogStart = self.OL.nfS
        self.OL.nfSet = nil
    end
end

function F:FogColorF()
    if CFG.FogCol.On then
        if not self.OL.fcSet then
            self.OL.fcC = Light.FogColor
            self.OL.fcSet = true
        end
        Light.FogColor = RC(CFG.FogCol.Preset)
    elseif self.OL.fcSet then
        Light.FogColor = self.OL.fcC
        self.OL.fcSet = nil
    end
end

function F:SkyboxF()
    if CFG.Sky.On then
        if not self.CustomAtmo then
            local existing = Light:FindFirstChildOfClass("Atmosphere")
            if existing then
                self.OL.origAtmo = existing
                existing.Parent = nil
            end
            self.CustomAtmo = Instance.new("Atmosphere")
            self.CustomAtmo.Name = rid(8)
            self.CustomAtmo.Parent = Light
            regGenv("atmo", self.CustomAtmo)
        end
        local col = RC(CFG.Sky.Preset)
        self.CustomAtmo.Density = 0.35
        self.CustomAtmo.Offset = 0
        self.CustomAtmo.Color = col
        self.CustomAtmo.Decay = col
        self.CustomAtmo.Glare = 0
        self.CustomAtmo.Haze = 6
    else
        if self.CustomAtmo then
            self.CustomAtmo:Destroy()
            self.CustomAtmo = nil
            regGenv("atmo", nil)
        end
        if self.OL.origAtmo then
            self.OL.origAtmo.Parent = Light
            self.OL.origAtmo = nil
        end
    end
end

function F:FOVCamF()
    if CFG.FOVCam.On then
        Cam.FieldOfView = CFG.FOVCam.Val
    end
end

function F:AmbientF()
    if CFG.Amb.On then
        if not self.OL.ambSet then
            self.OL.ambC = Light.Ambient
            self.OL.ambSet = true
        end
        Light.Ambient = RC(CFG.Amb.Preset)
    elseif self.OL.ambSet then
        Light.Ambient = self.OL.ambC
        self.OL.ambSet = nil
    end
end

function F:ClockTimeF()
    if CFG.ClockT.On then
        if not self.OL.ctSet then
            self.OL.ctV = Light.ClockTime
            self.OL.ctSet = true
        end
        Light.ClockTime = CFG.ClockT.Val
    elseif self.OL.ctSet then
        Light.ClockTime = self.OL.ctV
        self.OL.ctSet = nil
    end
end

function F:BrightnessF()
    if CFG.Brt.On then
        if not self.OL.brtSet then
            self.OL.brtV = Light.Brightness
            self.OL.brtSet = true
        end
        Light.Brightness = CFG.Brt.Val
    elseif self.OL.brtSet then
        Light.Brightness = self.OL.brtV
        self.OL.brtSet = nil
    end
end

function F:BloomF()
    if CFG.Blm.On then
        if not self.BloomE then
            self.BloomE = Instance.new("BloomEffect")
            self.BloomE.Name = rid(8)
            self.BloomE.Intensity = 1
            self.BloomE.Size = 24
            self.BloomE.Threshold = 0.8
            self.BloomE.Parent = Light
            regGenv("bloom", self.BloomE)
        end
    else
        if self.BloomE then
            self.BloomE:Destroy()
            self.BloomE = nil
            regGenv("bloom", nil)
        end
    end
end

function F:BlurF()
    if CFG.Blr.On then
        if not self.BlurE then
            self.BlurE = Instance.new("BlurEffect")
            self.BlurE.Name = rid(8)
            self.BlurE.Parent = Light
            regGenv("blur", self.BlurE)
        end
        self.BlurE.Size = CFG.Blr.Val
    else
        if self.BlurE then
            self.BlurE:Destroy()
            self.BlurE = nil
            regGenv("blur", nil)
        end
    end
end

function F:ColorCorrF()
    if CFG.CC.On then
        if not self.CCE then
            self.CCE = Instance.new("ColorCorrectionEffect")
            self.CCE.Name = rid(8)
            self.CCE.Parent = Light
            regGenv("cc", self.CCE)
        end
        self.CCE.Brightness = CFG.CC.Brt / 100
        self.CCE.Contrast = CFG.CC.Con / 100
        self.CCE.Saturation = CFG.CC.Sat / 100
    else
        if self.CCE then
            self.CCE:Destroy()
            self.CCE = nil
            regGenv("cc", nil)
        end
    end
end

function F:SunRaysF()
    if CFG.SR.On then
        if not self.SRE then
            self.SRE = Instance.new("SunRaysEffect")
            self.SRE.Name = rid(8)
            self.SRE.Intensity = 0.15
            self.SRE.Spread = 0.8
            self.SRE.Parent = Light
            regGenv("sr", self.SRE)
        end
    else
        if self.SRE then
            self.SRE:Destroy()
            self.SRE = nil
            regGenv("sr", nil)
        end
    end
end

function F:InitAAFK()
    pcall(function()
        local gc = getconnections or get_signal_cons
        if gc then for _, c in ipairs(gc(LP.Idled)) do c:Disable() end end
    end)
    if VU then
        sspawn(function()
            while running do
                swait(60)
                if CFG.AAFK.On then
                    pcall(function()
                        VU:Button2Down(Vector2.new(0, 0), Cam.CFrame)
                        swait(0.1)
                        VU:Button2Up(Vector2.new(0, 0), Cam.CFrame)
                    end)
                end
            end
        end)
    end
end

function F:ThirdP()
    if CFG.TP.On then
        LP.CameraMinZoomDistance = CFG.TP.Dist
        LP.CameraMaxZoomDistance = CFG.TP.Dist + 5
    end
end

Players.PlayerRemoving:Connect(function(p)
    if F.ED[p] then killD(F.ED[p]); F.ED[p] = nil end
end)

local function unloadScript()
    running = false
    for _, c in ipairs(connections) do
        pcall(function() c:Disconnect() end)
    end
    for _, d in ipairs(allDrawings) do
        pcall(function() d:Remove() end)
    end
    pcall(function() Light.Ambient = origL.Ambient end)
    pcall(function() Light.Brightness = origL.Brightness end)
    pcall(function() Light.OutdoorAmbient = origL.OutdoorAmbient end)
    pcall(function() Light.FogEnd = origL.FogEnd end)
    pcall(function() Light.FogStart = origL.FogStart end)
    pcall(function() Light.FogColor = origL.FogColor end)
    pcall(function() Light.ClockTime = origL.ClockTime end)
    pcall(function() Cam.FieldOfView = origL.FOV end)
    if F.BloomE then pcall(function() F.BloomE:Destroy() end) end
    if F.BlurE then pcall(function() F.BlurE:Destroy() end) end
    if F.CCE then pcall(function() F.CCE:Destroy() end) end
    if F.SRE then pcall(function() F.SRE:Destroy() end) end
    if F.CustomAtmo then pcall(function() F.CustomAtmo:Destroy() end) end
    if F.OL.origAtmo then pcall(function() F.OL.origAtmo.Parent = Light end) end
    pcall(function() UI:Kill() end)
    pcall(function()
        if getgenv then getgenv()[GK] = nil end
    end)
end

UI:Init()

local t1 = UI:Tab("Combat", 1)
UI:Sec(t1, "AIMBOT")
UI:Tog(t1, "Enable Aimbot", CFG.Aim, "On")
UI:Sli(t1, "Smoothing", 1, 20, CFG.Aim, "Smooth")
UI:Sli(t1, "FOV Radius", 20, 500, CFG.Aim, "FOV")
UI:Drop(t1, "Target Bone", {"Head", "Torso", "HumanoidRootPart"}, CFG.Aim, "Bone")
UI:Tog(t1, "Team Check", CFG.Aim, "Team")
UI:Tog(t1, "Wall Check", CFG.Aim, "Wall")
UI:Tog(t1, "Prediction", CFG.Aim, "Pred")
UI:Tog(t1, "Show FOV", CFG.Aim, "ShowFOV")
UI:Sec(t1, "SILENT AIM")
UI:Tog(t1, "Enable Silent Aim", CFG.SAim, "On", function(v) if v then F:InitSA() end end)
UI:Sli(t1, "Hit Chance (%)", 1, 100, CFG.SAim, "HC")
UI:Drop(t1, "Target Bone", {"Head", "Torso", "HumanoidRootPart"}, CFG.SAim, "Bone")
UI:Sec(t1, "TRIGGERBOT")
UI:Tog(t1, "Enable Triggerbot", CFG.Trig, "On")
UI:Sli(t1, "Trigger Delay (ms)", 0, 300, CFG.Trig, "Delay")
UI:Tog(t1, "Team Check", CFG.Trig, "Team")
UI:Sec(t1, "WEAPONS")
UI:Tog(t1, "No Recoil", CFG.NR, "On")

local t2 = UI:Tab("Visuals", 2)
UI:Sec(t2, "PLAYER ESP")
UI:Tog(t2, "Enable ESP", CFG.ESP, "On")
UI:Tog(t2, "Boxes", CFG.ESP, "Box")
UI:Drop(t2, "Box Color", COLOR_LIST, CFG.ESP, "BCP")
UI:Tog(t2, "Names", CFG.ESP, "Name")
UI:Drop(t2, "Name Color", COLOR_LIST, CFG.ESP, "NCP")
UI:Tog(t2, "Health Bars", CFG.ESP, "HP")
UI:Tog(t2, "Distance", CFG.ESP, "Dist")
UI:Tog(t2, "Tracers", CFG.ESP, "Trac")
UI:Drop(t2, "Tracer Origin", {"Bottom", "Top", "Center"}, CFG.ESP, "TO")
UI:Tog(t2, "Team Check", CFG.ESP, "Team")
UI:Tog(t2, "Team Colors", CFG.ESP, "TC")
UI:Sec(t2, "CROSSHAIR")
UI:Tog(t2, "Custom Crosshair", CFG.Cross, "On")
UI:Sli(t2, "Size", 2, 20, CFG.Cross, "Sz")
UI:Sli(t2, "Gap", 0, 15, CFG.Cross, "Gap")
UI:Sli(t2, "Thickness", 1, 5, CFG.Cross, "Th")
UI:Drop(t2, "Color", COLOR_LIST, CFG.Cross, "CP")
UI:Tog(t2, "Center Dot", CFG.Cross, "Dot")
UI:Sec(t2, "WORLD")
UI:Tog(t2, "Fullbright", CFG.FB, "On")
UI:Tog(t2, "No Fog", CFG.NF, "On")
UI:Tog(t2, "Fog Color", CFG.FogCol, "On")
UI:Drop(t2, "Fog Preset", COLOR_LIST, CFG.FogCol, "Preset")
UI:Tog(t2, "Sky Override", CFG.Sky, "On")
UI:Drop(t2, "Sky Preset", COLOR_LIST, CFG.Sky, "Preset")
UI:Tog(t2, "Ambient Color", CFG.Amb, "On")
UI:Drop(t2, "Ambient Preset", COLOR_LIST, CFG.Amb, "Preset")
UI:Sec(t2, "CAMERA")
UI:Tog(t2, "FOV Changer", CFG.FOVCam, "On")
UI:Sli(t2, "Field of View", 40, 120, CFG.FOVCam, "Val")
UI:Tog(t2, "Clock Time", CFG.ClockT, "On")
UI:Sli(t2, "Time", 0, 24, CFG.ClockT, "Val")
UI:Tog(t2, "Brightness", CFG.Brt, "On")
UI:Sli(t2, "Level", 0, 5, CFG.Brt, "Val")
UI:Sec(t2, "EFFECTS")
UI:Tog(t2, "Bloom", CFG.Blm, "On")
UI:Tog(t2, "Blur", CFG.Blr, "On")
UI:Sli(t2, "Blur Size", 1, 30, CFG.Blr, "Val")
UI:Tog(t2, "Color Correction", CFG.CC, "On")
UI:Sli(t2, "CC Brightness", -100, 100, CFG.CC, "Brt")
UI:Sli(t2, "CC Contrast", -100, 100, CFG.CC, "Con")
UI:Sli(t2, "CC Saturation", -100, 100, CFG.CC, "Sat")
UI:Tog(t2, "Sun Rays", CFG.SR, "On")

local t3 = UI:Tab("Movement", 3)
UI:Sec(t3, "MOVEMENT")
UI:Tog(t3, "Bunny Hop", CFG.BHop, "On")
UI:Tog(t3, "Speed Boost", CFG.Speed, "On")
UI:Sli(t3, "Speed", 16, 30, CFG.Speed, "Val")
UI:Tog(t3, "Infinite Jump", CFG.IJump, "On")
UI:Sec(t3, "ADVANCED")
UI:Tog(t3, "Fly", CFG.Fly, "On")
UI:Sli(t3, "Fly Speed", 10, 100, CFG.Fly, "Val")
UI:Tog(t3, "Noclip", CFG.Noclip, "On")

local t4 = UI:Tab("Misc", 4)
UI:Sec(t4, "UTILITIES")
UI:Tog(t4, "Anti-AFK", CFG.AAFK, "On")
UI:Tog(t4, "Third Person Lock", CFG.TP, "On")
UI:Sli(t4, "Camera Distance", 5, 30, CFG.TP, "Dist")
UI:Sec(t4, "OFFSETS")
UI:Btn(t4, "Fetch Offsets", function()
    Notify("Offsets", "Fetching...", 2)
    sspawn(function() FetchOff(); Notify("Offsets", OStat, 3) end)
end)
UI:Btn(t4, "Show Version", function()
    Notify("Version", "Offsets: " .. OVer .. " | Script: v5.0", 4)
end)

local t5 = UI:Tab("Settings", 5)
UI:Sec(t5, "CONFIG")
UI:Btn(t5, "Save Config", function()
    local s = saveCfg("custom")
    if s then Notify("Config", "Saved successfully", 3)
    else Notify("Config", "Save failed (no file access)", 3) end
end)
UI:Btn(t5, "Load Config", function()
    local s = loadCfgFile("custom")
    if s then
        if CFG.SAim.On then pcall(function() F:InitSA() end) end
        UI:Refresh()
        Notify("Config", "Loaded successfully", 3)
    else
        Notify("Config", "Load failed", 3)
    end
end)
UI:Sec(t5, "PRESETS")
UI:Btn(t5, "Default (All Off)", function()
    loadPreset("Default")
    Notify("Preset", "Default loaded", 3)
end)
UI:Btn(t5, "Legit (Subtle)", function()
    loadPreset("Legit")
    Notify("Preset", "Legit loaded", 3)
end)
UI:Btn(t5, "Risk (Full Power)", function()
    loadPreset("Risk")
    Notify("Preset", "Risk loaded", 3)
end)
UI:Sec(t5, "GENERAL")
UI:Btn(t5, "Unload Script", function()
    Notify("Unloading", "Cleaning up...", 2)
    sspawn(function()
        swait(1)
        unloadScript()
    end)
end)
UI:Btn(t5, "Toggle Key: RightCtrl", function()
    Notify("Info", "Press RightCtrl to toggle menu", 3)
end)

UI:Sel("Combat")

F:InitCross()
F:InitFOV()
F:InitIJ()
F:InitAAFK()

table.insert(connections, RS.RenderStepped:Connect(function()
    if not running then return end
    Cam = WS.CurrentCamera
    pcall(F.Aimbot, F)
    pcall(F.NoRecoil, F)
    pcall(F.ESP, F)
    pcall(F.Cross, F)
    pcall(F.FOVDraw, F)
    pcall(F.NoclipF, F)
    pcall(F.FlyF, F)
    pcall(F.FOVCamF, F)
end))

table.insert(connections, RS.Heartbeat:Connect(function()
    if not running then return end
    pcall(F.Triggerbot, F)
    pcall(F.BHop, F)
    pcall(F.SpeedB, F)
    pcall(F.Fullbright, F)
    pcall(F.NoFog, F)
    pcall(F.FogColorF, F)
    pcall(F.SkyboxF, F)
    pcall(F.AmbientF, F)
    pcall(F.ClockTimeF, F)
    pcall(F.BrightnessF, F)
    pcall(F.BloomF, F)
    pcall(F.BlurF, F)
    pcall(F.ColorCorrF, F)
    pcall(F.SunRaysF, F)
    pcall(F.ThirdP, F)
end))

table.insert(connections, UIS.InputBegan:Connect(function(i, g)
    if g then return end
    if i.KeyCode == CFG.MKey then UI:Toggle() end
end))

end)

if not ok then
    pcall(function() warn(tostring(err)) end)
    pcall(function() print(tostring(err)) end)
end
