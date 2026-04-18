-- Services loader
local ok, err = pcall(function()

local game = game
local pcall = pcall
local pairs = pairs
local ipairs = ipairs
local type = type
local tostring = tostring
local math = math
local coroutine = coroutine
local string = string
local table = table
local unpack = unpack or table.unpack

-- Random ID generator (anti-detection: no recognizable names)
local function rid(len)
    len = len or 12
    local c = "abcdefghijklmnopqrstuvwxyz"
    local r = ""
    for i=1,len do local p=math.random(1,#c); r=r..c:sub(p,p) end
    return r
end

local SCRIPT_ID = rid(16)

-- Safe wait/spawn
local swait = nil
pcall(function() if task and task.wait then swait = task.wait end end)
if not swait then pcall(function() swait = wait end) end
if not swait then swait = function(n) local s=tick();while tick()-s<(n or 0.03) do end end end

local sspawn = nil
pcall(function() if task and task.spawn then sspawn = task.spawn end end)
if not sspawn then pcall(function() sspawn = spawn end) end
if not sspawn then sspawn = function(f) coroutine.wrap(f)() end end

-- Services
local Players = game:GetService("Players")
local RS = game:GetService("RunService")
local UIS = game:GetService("UserInputService")
local TS = game:GetService("TweenService")
local Light = game:GetService("Lighting")
local WS = game:GetService("Workspace")

local LP = Players.LocalPlayer
local Cam = WS.CurrentCamera
local Mouse = LP:GetMouse()

local CoreGui = nil
pcall(function() CoreGui = game:GetService("CoreGui") end)

local VIM = nil
pcall(function() VIM = game:GetService("VirtualInputManager") end)

local VU = nil
pcall(function() VU = game:GetService("VirtualUser") end)

-- Fonts
local dFont = nil
pcall(function() dFont = Enum.Font.SourceSans end)
if not dFont then pcall(function() dFont = Enum.Font.Legacy end) end
local function sFont(n) local o,f=pcall(function() return Enum.Font[n] end); if o and f then return f end; return dFont end
local FB = sFont("GothamBold") or dFont
local FM = sFont("GothamMedium") or dFont
local FR = sFont("Gotham") or dFont

-- Raycast filter
local FE = nil
pcall(function() FE = Enum.RaycastFilterType.Exclude end)
if not FE then pcall(function() FE = Enum.RaycastFilterType.Blacklist end) end

-- Drawing check
local hasDraw = false
pcall(function() local t=Drawing.new("Line");t:Remove();hasDraw=true end)

-- Hook check
local hasHook = false
pcall(function() if getrawmetatable then hasHook=true end end)

-- Safe Instance.new with random naming
local function sNew(c,p,par)
    local o,i = pcall(function()
        local x = Instance.new(c)
        x.Name = rid(8) -- Anti-detection: random name
        if p then for k,v in pairs(p) do pcall(function() x[k]=v end) end end
        if par then x.Parent=par end
        return x
    end)
    if o then return i end; return nil
end

-- Safe Drawing
local function sDraw(c,p)
    if not hasDraw then return nil end
    local o,d = pcall(function() local x=Drawing.new(c); for k,v in pairs(p) do x[k]=v end; return x end)
    if o then return d end; return nil
end
local function sDP(d,p,v) if d then pcall(function() d[p]=v end) end end
local function sDR(d) if d then pcall(function() d:Remove() end) end end

-- ============================================================
-- ANTI-DETECTION: GUI PARENT
-- Priority: gethui() > syn.protect + CoreGui > PlayerGui
-- gethui() is INVISIBLE to game scripts (best for anti-cheat)
-- ============================================================
local GuiParent = nil

-- Method 1: gethui() - completely hidden from game scripts
pcall(function()
    if gethui then
        GuiParent = gethui()
    end
end)

-- Method 2: Synapse protect + CoreGui
if not GuiParent then
    pcall(function()
        if syn and syn.protect_gui then
            GuiParent = CoreGui
        end
    end)
end

-- Method 3: CoreGui direct
if not GuiParent and CoreGui then
    local testOk = pcall(function()
        local t = Instance.new("Folder")
        t.Name = rid(8)
        t.Parent = CoreGui
        t:Destroy()
    end)
    if testOk then GuiParent = CoreGui end
end

-- Method 4: PlayerGui fallback
if not GuiParent then
    GuiParent = LP:WaitForChild("PlayerGui")
end

-- ============================================================
-- ANTI-DETECTION: Stealth utilities
-- ============================================================

-- Clamp without math.clamp (some envs don't have it)
local function clmp(v,mn,mx) if v<mn then return mn end; if v>mx then return mx end; return v end

-- Human-like jitter for aimbot (anti-detection)
local function humanJitter()
    return Vector2.new(
        (math.random()-0.5) * 0.3,
        (math.random()-0.5) * 0.3
    )
end

-- Delayed action (anti-detection: don't do things instantly)
local function delayedRun(fn, minDelay, maxDelay)
    sspawn(function()
        swait(minDelay + math.random() * (maxDelay - minDelay))
        pcall(fn)
    end)
end

-- ============================================================
-- THEME (Premium dark with cyan/purple accents)
-- ============================================================
local TH = {
    BG  = Color3.fromRGB(15,15,20),
    SF  = Color3.fromRGB(22,22,30),
    SL  = Color3.fromRGB(32,32,42),
    BD  = Color3.fromRGB(45,45,58),
    AC  = Color3.fromRGB(0,200,255),
    A2  = Color3.fromRGB(130,80,255),
    A3  = Color3.fromRGB(255,60,120),
    TX  = Color3.fromRGB(235,235,245),
    TM  = Color3.fromRGB(130,135,150),
    TD  = Color3.fromRGB(80,85,100),
    OK  = Color3.fromRGB(50,210,100),
    ER  = Color3.fromRGB(255,70,70),
    WN  = Color3.fromRGB(255,180,40),
    TO  = Color3.fromRGB(50,50,65),
    TN  = Color3.fromRGB(0,200,255),
}

-- ============================================================
-- CONFIG
-- ============================================================
local CFG = {
    Aim = {On=false,Smooth=8,FOV=100,Bone="Head",Team=true,Wall=true,Pred=false,PS=0.1,ShowFOV=true},
    SAim = {On=false,HC=85,Bone="Head",Team=true},
    Trig = {On=false,Delay=80,Team=true},
    NR = {On=false},
    ESP = {On=false,Box=true,BC=Color3.fromRGB(0,200,255),Name=true,NC=Color3.fromRGB(255,255,255),
           HP=true,Dist=true,Skel=false,Trac=false,TO="Bottom",Team=true,TC=false},
    Cross = {On=false,Sz=6,Gap=3,Th=1,Col=Color3.fromRGB(0,255,128),Dot=true},
    FB = {On=false},
    NF = {On=false},
    BHop = {On=false},
    Speed = {On=false,Val=19}, -- Keep close to default 16 (anti-detect)
    IJump = {On=false},
    Fly = {On=false,Val=40},
    Noclip = {On=false},
    AAFK = {On=true},
    TP = {On=false,Dist=10},
    MKey = Enum.KeyCode.RightControl,
}

-- ============================================================
-- OFFSETS (auto-updating)
-- ============================================================
local OURL = "https://offsets.ntgetwritewatch.workers.dev/offsets_structured.hpp"
local Offsets = {}
local OVer = "unknown"
local OStat = "Fetching..."

local function FetchOff()
    local o,d = pcall(function()
        if syn and syn.request then return syn.request({Url=OURL}).Body end
        if request then return request({Url=OURL}).Body end
        if http_request then return http_request({Url=OURL}).Body end
        return game:HttpGet(OURL)
    end)
    if not o or not d then OStat="Failed"; return end
    local P,ns = {},nil
    for ln in d:gmatch("[^\r\n]+") do
        local n = ln:match("namespace%s+(%w+)")
        if n then ns=n; P[ns]=P[ns] or {} end
        local nm,hx = ln:match("inline%s+constexpr%s+uintptr_t%s+(%w+)%s*=%s*(0x%x+)")
        if nm and hx and ns then P[ns][nm]=tonumber(hx) end
    end
    local v = d:match("Roblox Version:%s*([%w%-]+)")
    if v then OVer=v end
    Offsets=P; OStat="Synced ("..OVer..")"
end

-- Delayed offset fetch (anti-detect: don't HTTP immediately)
delayedRun(function()
    FetchOff()
    sspawn(function() while true do swait(300); FetchOff() end end)
end, 2, 4)

-- ============================================================
-- UTILITIES
-- ============================================================
local function W2S(p) local v,o=Cam:WorldToViewportPoint(p); return Vector2.new(v.X,v.Y),o,v.Z end
local function GetChar(p) return p and p.Character end
local function Alive(p) local c=GetChar(p); if not c then return false end; local h=c:FindFirstChildOfClass("Humanoid"); return h and h.Health>0 end
local function Enemy(p,tc) if p==LP then return false end; if not tc then return true end; if not LP.Team or not p.Team then return true end; return p.Team~=LP.Team end

local function Visible(tp)
    if not tp then return false end
    local pr=RaycastParams.new(); pr.FilterType=FE; pr.FilterDescendantsInstances={LP.Character}
    local r=WS:Raycast(Cam.CFrame.Position,tp.Position-Cam.CFrame.Position,pr)
    if r then return r.Instance:IsDescendantOf(tp.Parent) end; return true
end

local function GetBone(ch,bn)
    if not ch then return nil end; local p=ch:FindFirstChild(bn); if p then return p end
    if bn=="Head" then return ch:FindFirstChild("Head") end
    if bn=="Torso" then return ch:FindFirstChild("HumanoidRootPart") or ch:FindFirstChild("UpperTorso") end
    return ch:FindFirstChild("HumanoidRootPart")
end

local function ScrCen() local v=Cam.ViewportSize; return Vector2.new(v.X/2,v.Y/2) end

-- ============================================================
-- NOTIFICATION (Minimal, clean)
-- ============================================================
local NHolder = nil

local function MakeNHolder(par)
    local h=Instance.new("Frame"); h.Name=rid(6); h.Size=UDim2.new(0,320,1,0); h.Position=UDim2.new(1,-340,0,0)
    h.BackgroundTransparency=1; h.ZIndex=100; h.Parent=par
    local l=Instance.new("UIListLayout"); l.SortOrder=Enum.SortOrder.LayoutOrder; l.Padding=UDim.new(0,8)
    l.VerticalAlignment=Enum.VerticalAlignment.Bottom; l.Parent=h
    local p=Instance.new("UIPadding"); p.PaddingBottom=UDim.new(0,20); p.Parent=h
    return h
end

local function Notify(t,m,dur)
    dur=dur or 3; if not NHolder or not NHolder.Parent then return end
    pcall(function()
        local n=Instance.new("Frame"); n.Name=rid(6); n.Size=UDim2.new(1,0,0,64); n.BackgroundColor3=TH.SF
        n.BorderSizePixel=0; n.BackgroundTransparency=0.02; n.ClipsDescendants=true; n.Parent=NHolder
        sNew("UICorner",{CornerRadius=UDim.new(0,10)},n)
        sNew("UIStroke",{Color=TH.BD,Thickness=1,Transparency=0.5},n)

        -- Accent bar with gradient
        local b=Instance.new("Frame"); b.Name=rid(4); b.Size=UDim2.new(0,3,1,-8); b.Position=UDim2.new(0,4,0,4)
        b.BackgroundColor3=TH.AC; b.BorderSizePixel=0; b.Parent=n
        sNew("UICorner",{CornerRadius=UDim.new(0,2)},b)

        local tl=Instance.new("TextLabel"); tl.Name=rid(4); tl.Text=t; tl.Font=FB; tl.TextSize=13; tl.TextColor3=TH.TX
        tl.BackgroundTransparency=1; tl.Position=UDim2.new(0,16,0,10); tl.Size=UDim2.new(1,-24,0,18)
        tl.TextXAlignment=Enum.TextXAlignment.Left; tl.Parent=n
        local ml=Instance.new("TextLabel"); ml.Name=rid(4); ml.Text=m; ml.Font=FR; ml.TextSize=11; ml.TextColor3=TH.TM
        ml.BackgroundTransparency=1; ml.Position=UDim2.new(0,16,0,30); ml.Size=UDim2.new(1,-24,0,24)
        ml.TextXAlignment=Enum.TextXAlignment.Left; ml.TextWrapped=true; ml.Parent=n

        n.Position=UDim2.new(1,20,0,0)
        TS:Create(n,TweenInfo.new(0.35,Enum.EasingStyle.Back,Enum.EasingDirection.Out),{Position=UDim2.new(0,0,0,0)}):Play()
        sspawn(function() swait(dur)
            TS:Create(n,TweenInfo.new(0.3,Enum.EasingStyle.Quart,Enum.EasingDirection.In),{Position=UDim2.new(1,20,0,0),BackgroundTransparency=1}):Play()
            swait(0.35); n:Destroy()
        end)
    end)
end

-- ============================================================
-- PREMIUM UI SYSTEM
-- ============================================================
local UI = {Tabs={},SG=nil,MF=nil,CF=nil,AT=nil,Vis=true,SB=nil}

function UI:Init()
    -- Cleanup old (search all possible parents)
    pcall(function() for _,g in ipairs(LP:WaitForChild("PlayerGui"):GetChildren()) do
        if g:IsA("ScreenGui") and g:FindFirstChild("_bsdom") then g:Destroy() end end end)
    pcall(function() if CoreGui then for _,g in ipairs(CoreGui:GetChildren()) do
        if g:IsA("ScreenGui") and g:FindFirstChild("_bsdom") then g:Destroy() end end end end)
    pcall(function() if gethui then for _,g in ipairs(gethui():GetChildren()) do
        if g:IsA("ScreenGui") and g:FindFirstChild("_bsdom") then g:Destroy() end end end end)

    local sg=Instance.new("ScreenGui"); sg.Name=rid(16) -- Random name (anti-detect)
    sg.ResetOnSpawn=false
    pcall(function() sg.Enabled=true end)
    pcall(function() sg.DisplayOrder=math.random(50,150) end) -- Not suspiciously high
    pcall(function() sg.IgnoreGuiInset=true end)
    pcall(function() sg.ZIndexBehavior=Enum.ZIndexBehavior.Sibling end)

    -- Hidden marker for cleanup (not obvious name)
    local marker = Instance.new("BoolValue"); marker.Name="_bsdom"; marker.Parent=sg

    -- Protect GUI
    pcall(function() if syn and syn.protect_gui then syn.protect_gui(sg) end end)

    sg.Parent = GuiParent
    self.SG = sg

    pcall(function() LP.CharacterAdded:Connect(function() swait(1);if sg and not sg.Parent then sg.Parent=GuiParent end end) end)

    NHolder = MakeNHolder(sg)

    -- ---- MAIN WINDOW ----
    local mf=Instance.new("Frame"); mf.Name=rid(8); mf.Size=UDim2.new(0,600,0,440)
    mf.Position=UDim2.new(0.5,-300,0.5,-220); mf.BackgroundColor3=TH.BG; mf.BorderSizePixel=0
    mf.ClipsDescendants=true; mf.Active=true; mf.Parent=sg
    sNew("UICorner",{CornerRadius=UDim.new(0,12)},mf)

    -- Outer glow stroke
    local outerStroke = sNew("UIStroke",{Color=TH.AC,Thickness=1,Transparency=0.7},mf)

    -- Animated glow
    if outerStroke then
        sspawn(function()
            local t=0
            while sg and sg.Parent do
                t=t+0.02
                pcall(function()
                    local pulse = 0.5 + math.sin(t) * 0.3
                    outerStroke.Transparency = pulse
                    outerStroke.Color = Color3.fromRGB(
                        math.floor(0 + 130 * math.abs(math.sin(t*0.5))),
                        math.floor(200 - 120 * math.abs(math.sin(t*0.3))),
                        255
                    )
                end)
                RS.RenderStepped:Wait()
            end
        end)
    end

    self.MF = mf

    -- ---- TITLE BAR ----
    local tb=Instance.new("Frame"); tb.Name=rid(6); tb.Size=UDim2.new(1,0,0,44);tb.BackgroundColor3=TH.SF
    tb.BorderSizePixel=0; tb.Active=true; tb.Parent=mf
    sNew("UICorner",{CornerRadius=UDim.new(0,12)},tb)
    -- Fix bottom corners
    local tbf=Instance.new("Frame"); tbf.Name=rid(4); tbf.Size=UDim2.new(1,0,0,14); tbf.Position=UDim2.new(0,0,1,-14)
    tbf.BackgroundColor3=TH.SF; tbf.BorderSizePixel=0; tbf.Parent=tb

    -- Gradient accent line
    local al=Instance.new("Frame"); al.Name=rid(4); al.Size=UDim2.new(1,0,0,2); al.Position=UDim2.new(0,0,1,0)
    al.BorderSizePixel=0; al.BackgroundColor3=TH.AC; al.Parent=tb
    local alg=sNew("UIGradient",{Color=ColorSequence.new({
        ColorSequenceKeypoint.new(0,TH.A2),
        ColorSequenceKeypoint.new(0.3,TH.AC),
        ColorSequenceKeypoint.new(0.7,TH.A3),
        ColorSequenceKeypoint.new(1,TH.A2),
    })},al)
    -- Animate gradient
    if alg then sspawn(function() local o=0; while sg and sg.Parent do o=(o+0.003)%1
        pcall(function() alg.Offset=Vector2.new(math.sin(o*math.pi*2)*0.5,0) end); RS.RenderStepped:Wait() end end) end

    -- Logo/Title
    local logo=Instance.new("TextLabel"); logo.Name=rid(4); logo.Text="DOMINATION"; logo.Font=FB; logo.TextSize=15
    logo.TextColor3=TH.TX; logo.BackgroundTransparency=1; logo.Position=UDim2.new(0,16,0,0); logo.Size=UDim2.new(0,140,1,0)
    logo.TextXAlignment=Enum.TextXAlignment.Left; logo.Parent=tb

    -- Subtitle
    local sub=Instance.new("TextLabel"); sub.Name=rid(4); sub.Text="premium"; sub.Font=FM; sub.TextSize=10
    sub.TextColor3=TH.TM; sub.BackgroundTransparency=1; sub.Position=UDim2.new(0,160,0,2); sub.Size=UDim2.new(0,60,1,0)
    sub.TextXAlignment=Enum.TextXAlignment.Left; sub.Parent=tb

    -- Version badge
    local vb=Instance.new("TextLabel"); vb.Name=rid(4); vb.Text="v4.0"; vb.Font=FB; vb.TextSize=9; vb.TextColor3=TH.AC
    vb.BackgroundColor3=Color3.fromRGB(0,35,50); vb.Position=UDim2.new(0,220,0.5,-8); vb.Size=UDim2.new(0,30,0,16); vb.Parent=tb
    sNew("UICorner",{CornerRadius=UDim.new(0,4)},vb)

    -- Close
    local cb=Instance.new("TextButton"); cb.Name=rid(4); cb.Text="X"; cb.Font=FB; cb.TextSize=13; cb.TextColor3=TH.TM
    cb.BackgroundTransparency=1; cb.Position=UDim2.new(1,-40,0,0); cb.Size=UDim2.new(0,40,1,0); cb.Parent=tb
    cb.MouseButton1Click:Connect(function() self:Toggle() end)
    cb.MouseEnter:Connect(function() TS:Create(cb,TweenInfo.new(0.15),{TextColor3=TH.ER}):Play() end)
    cb.MouseLeave:Connect(function() TS:Create(cb,TweenInfo.new(0.15),{TextColor3=TH.TM}):Play() end)

    -- Minimize
    local mn=Instance.new("TextButton"); mn.Name=rid(4); mn.Text="-"; mn.Font=FB; mn.TextSize=18; mn.TextColor3=TH.TM
    mn.BackgroundTransparency=1; mn.Position=UDim2.new(1,-72,0,0); mn.Size=UDim2.new(0,32,1,0); mn.Parent=tb
    mn.MouseEnter:Connect(function() TS:Create(mn,TweenInfo.new(0.15),{TextColor3=TH.WN}):Play() end)
    mn.MouseLeave:Connect(function() TS:Create(mn,TweenInfo.new(0.15),{TextColor3=TH.TM}):Play() end)

    -- Dragging
    local drag,ds,sp = false,nil,nil
    tb.InputBegan:Connect(function(i) if i.UserInputType==Enum.UserInputType.MouseButton1 or i.UserInputType==Enum.UserInputType.Touch then drag=true;ds=i.Position;sp=mf.Position end end)
    tb.InputEnded:Connect(function(i) if i.UserInputType==Enum.UserInputType.MouseButton1 or i.UserInputType==Enum.UserInputType.Touch then drag=false end end)
    UIS.InputChanged:Connect(function(i) if drag and (i.UserInputType==Enum.UserInputType.MouseMovement or i.UserInputType==Enum.UserInputType.Touch) then
        local d=i.Position-ds; mf.Position=UDim2.new(sp.X.Scale,sp.X.Offset+d.X,sp.Y.Scale,sp.Y.Offset+d.Y) end end)

    -- ---- SIDEBAR ----
    local sb=Instance.new("Frame"); sb.Name=rid(6); sb.Size=UDim2.new(0,148,1,-46); sb.Position=UDim2.new(0,0,0,46)
    sb.BackgroundColor3=TH.SF; sb.BorderSizePixel=0; sb.Parent=mf
    -- Separator
    local sep=Instance.new("Frame"); sep.Name=rid(4); sep.Size=UDim2.new(0,1,1,0); sep.Position=UDim2.new(1,0,0,0)
    sep.BackgroundColor3=TH.BD; sep.BorderSizePixel=0; sep.BackgroundTransparency=0.5; sep.Parent=sb
    local sbl=Instance.new("UIListLayout"); sbl.SortOrder=Enum.SortOrder.LayoutOrder; sbl.Padding=UDim.new(0,2); sbl.Parent=sb
    local sbp=Instance.new("UIPadding"); sbp.PaddingTop=UDim.new(0,10); sbp.PaddingLeft=UDim.new(0,8); sbp.PaddingRight=UDim.new(0,8); sbp.Parent=sb
    self.SB = sb

    -- ---- CONTENT ----
    local cf=Instance.new("Frame"); cf.Name=rid(6); cf.Size=UDim2.new(1,-149,1,-70); cf.Position=UDim2.new(0,149,0,46)
    cf.BackgroundTransparency=1; cf.Parent=mf
    self.CF = cf

    -- ---- STATUS BAR ----
    local stb=Instance.new("Frame"); stb.Name=rid(4); stb.Size=UDim2.new(1,0,0,24); stb.Position=UDim2.new(0,0,1,-24)
    stb.BackgroundColor3=TH.SF; stb.BorderSizePixel=0; stb.ZIndex=5; stb.Parent=mf
    local stl=Instance.new("TextLabel"); stl.Name=rid(4); stl.Text="  Stealth Active  |  RCtrl toggle"
    stl.Font=FR; stl.TextSize=10; stl.TextColor3=TH.TD; stl.BackgroundTransparency=1
    stl.Size=UDim2.new(1,0,1,0); stl.TextXAlignment=Enum.TextXAlignment.Left; stl.Parent=stb

    -- Status dot (pulsing green = stealth active)
    local dot=Instance.new("Frame"); dot.Name=rid(4); dot.Size=UDim2.new(0,6,0,6); dot.Position=UDim2.new(1,-18,0.5,-3)
    dot.BackgroundColor3=TH.OK; dot.BorderSizePixel=0; dot.Parent=stb
    sNew("UICorner",{CornerRadius=UDim.new(1,0)},dot)
    sspawn(function() while sg and sg.Parent do
        pcall(function() TS:Create(dot,TweenInfo.new(1),{BackgroundTransparency=0.6}):Play() end); swait(1)
        pcall(function() TS:Create(dot,TweenInfo.new(1),{BackgroundTransparency=0}):Play() end); swait(1)
    end end)

    sspawn(function() while sg and sg.Parent do pcall(function() stl.Text="  Offsets: "..OStat.."  |  RCtrl toggle" end); swait(5) end end)

    return self
end

-- Tab icons using text symbols
local TAB_ICONS = {Combat="@",Visuals="#",Movement=">",Misc="*",Settings="="}

function UI:Tab(name,ord)
    local icon = TAB_ICONS[name] or ">"
    local btn=Instance.new("TextButton"); btn.Name=rid(6); btn.Size=UDim2.new(1,0,0,36)
    btn.BackgroundColor3=TH.SL; btn.BackgroundTransparency=1; btn.BorderSizePixel=0; btn.Text=""
    btn.LayoutOrder=ord or (#self.Tabs+1); btn.AutoButtonColor=false; btn.Parent=self.SB
    sNew("UICorner",{CornerRadius=UDim.new(0,8)},btn)

    local ic=Instance.new("TextLabel"); ic.Name=rid(4); ic.Text=icon; ic.Font=FB; ic.TextSize=13; ic.TextColor3=TH.TD
    ic.BackgroundTransparency=1; ic.Position=UDim2.new(0,10,0,0); ic.Size=UDim2.new(0,20,1,0); ic.Parent=btn
    local lb=Instance.new("TextLabel"); lb.Name=rid(4); lb.Text=name; lb.Font=FM; lb.TextSize=12; lb.TextColor3=TH.TM
    lb.BackgroundTransparency=1; lb.Position=UDim2.new(0,34,0,0); lb.Size=UDim2.new(1,-38,1,0)
    lb.TextXAlignment=Enum.TextXAlignment.Left; lb.Parent=btn

    -- Active indicator (left bar)
    local ind=Instance.new("Frame"); ind.Name=rid(4); ind.Size=UDim2.new(0,3,0.5,0); ind.Position=UDim2.new(0,0,0.25,0)
    ind.BackgroundColor3=TH.AC; ind.BorderSizePixel=0; ind.Visible=false; ind.Parent=btn
    sNew("UICorner",{CornerRadius=UDim.new(0,2)},ind)

    -- Content scroll
    local ct=Instance.new("ScrollingFrame"); ct.Name=rid(8); ct.Size=UDim2.new(1,-16,1,-8); ct.Position=UDim2.new(0,8,0,4)
    ct.BackgroundTransparency=1; ct.ScrollBarThickness=3; ct.ScrollBarImageColor3=TH.A2
    ct.BorderSizePixel=0; ct.CanvasSize=UDim2.new(0,0,0,0); ct.Visible=false; ct.Parent=self.CF
    local cl=Instance.new("UIListLayout"); cl.SortOrder=Enum.SortOrder.LayoutOrder; cl.Padding=UDim.new(0,4); cl.Parent=ct
    cl:GetPropertyChangedSignal("AbsoluteContentSize"):Connect(function() ct.CanvasSize=UDim2.new(0,0,0,cl.AbsoluteContentSize.Y+16) end)

    local td={Btn=btn,Ct=ct,Ind=ind,Ic=ic,Lb=lb,N=name,O=0}
    btn.MouseButton1Click:Connect(function() self:Sel(name) end)
    btn.MouseEnter:Connect(function() if self.AT~=name then TS:Create(btn,TweenInfo.new(0.2),{BackgroundTransparency=0.5}):Play() end end)
    btn.MouseLeave:Connect(function() if self.AT~=name then TS:Create(btn,TweenInfo.new(0.2),{BackgroundTransparency=1}):Play() end end)
    table.insert(self.Tabs,td); return td
end

function UI:Sel(name)
    for _,t in ipairs(self.Tabs) do
        local a=t.N==name; t.Ct.Visible=a; t.Ind.Visible=a
        TS:Create(t.Btn,TweenInfo.new(0.25),{BackgroundTransparency=a and 0.6 or 1}):Play()
        TS:Create(t.Lb,TweenInfo.new(0.25),{TextColor3=a and TH.TX or TH.TM}):Play()
        TS:Create(t.Ic,TweenInfo.new(0.25),{TextColor3=a and TH.AC or TH.TD}):Play()
    end; self.AT=name
end

function UI:Sec(td,title)
    local s=Instance.new("Frame"); s.Name=rid(4); s.Size=UDim2.new(1,0,0,28); s.BackgroundTransparency=1
    s.LayoutOrder=td.O; td.O=td.O+1; s.Parent=td.Ct
    local ln=Instance.new("Frame"); ln.Name=rid(4); ln.Size=UDim2.new(1,0,0,1); ln.Position=UDim2.new(0,0,0.5,0)
    ln.BackgroundColor3=TH.BD; ln.BorderSizePixel=0; ln.BackgroundTransparency=0.5; ln.Parent=s
    local lb=Instance.new("TextLabel"); lb.Name=rid(4); lb.Text="  "..title.."  "; lb.Font=FB; lb.TextSize=9
    lb.TextColor3=TH.A2; lb.BackgroundColor3=TH.BG; lb.Position=UDim2.new(0,8,0,6); lb.Size=UDim2.new(0,110,0,16); lb.Parent=s
end

function UI:Tog(td,name,tbl,key,cb)
    local fr=Instance.new("Frame"); fr.Name=rid(6); fr.Size=UDim2.new(1,0,0,34); fr.BackgroundColor3=TH.SL
    fr.BackgroundTransparency=0.4; fr.BorderSizePixel=0; fr.LayoutOrder=td.O; td.O=td.O+1; fr.Parent=td.Ct
    sNew("UICorner",{CornerRadius=UDim.new(0,8)},fr)
    local lb=Instance.new("TextLabel"); lb.Name=rid(4); lb.Text=name; lb.Font=FR; lb.TextSize=12; lb.TextColor3=TH.TX
    lb.BackgroundTransparency=1; lb.Position=UDim2.new(0,14,0,0); lb.Size=UDim2.new(1,-70,1,0)
    lb.TextXAlignment=Enum.TextXAlignment.Left; lb.Parent=fr
    local bg=Instance.new("Frame"); bg.Name=rid(4); bg.Size=UDim2.new(0,38,0,20); bg.Position=UDim2.new(1,-50,0.5,-10)
    bg.BackgroundColor3=tbl[key] and TH.TN or TH.TO; bg.BorderSizePixel=0; bg.Parent=fr
    sNew("UICorner",{CornerRadius=UDim.new(1,0)},bg)
    local kn=Instance.new("Frame"); kn.Name=rid(4); kn.Size=UDim2.new(0,16,0,16)
    kn.Position=tbl[key] and UDim2.new(1,-18,0.5,-8) or UDim2.new(0,2,0.5,-8)
    kn.BackgroundColor3=Color3.fromRGB(255,255,255); kn.BorderSizePixel=0; kn.Parent=bg
    sNew("UICorner",{CornerRadius=UDim.new(1,0)},kn)
    local bt=Instance.new("TextButton"); bt.Name=rid(4); bt.Size=UDim2.new(1,0,1,0); bt.BackgroundTransparency=1
    bt.Text=""; bt.ZIndex=2; bt.Parent=fr
    bt.MouseButton1Click:Connect(function()
        tbl[key]=not tbl[key]; local e=tbl[key]
        TS:Create(bg,TweenInfo.new(0.25,Enum.EasingStyle.Back),{BackgroundColor3=e and TH.TN or TH.TO}):Play()
        TS:Create(kn,TweenInfo.new(0.25,Enum.EasingStyle.Back),{Position=e and UDim2.new(1,-18,0.5,-8) or UDim2.new(0,2,0.5,-8)}):Play()
        if cb then pcall(cb,e) end
    end)
    bt.MouseEnter:Connect(function() TS:Create(fr,TweenInfo.new(0.15),{BackgroundTransparency=0.2}):Play() end)
    bt.MouseLeave:Connect(function() TS:Create(fr,TweenInfo.new(0.15),{BackgroundTransparency=0.4}):Play() end)
end

function UI:Sli(td,name,mn,mx,tbl,key,cb)
    local fr=Instance.new("Frame"); fr.Name=rid(6); fr.Size=UDim2.new(1,0,0,48); fr.BackgroundColor3=TH.SL
    fr.BackgroundTransparency=0.4; fr.BorderSizePixel=0; fr.LayoutOrder=td.O; td.O=td.O+1; fr.Parent=td.Ct
    sNew("UICorner",{CornerRadius=UDim.new(0,8)},fr)
    local lb=Instance.new("TextLabel"); lb.Name=rid(4); lb.Text=name; lb.Font=FR; lb.TextSize=12; lb.TextColor3=TH.TX
    lb.BackgroundTransparency=1; lb.Position=UDim2.new(0,14,0,2); lb.Size=UDim2.new(1,-70,0,20)
    lb.TextXAlignment=Enum.TextXAlignment.Left; lb.Parent=fr
    local vl=Instance.new("TextLabel"); vl.Name=rid(4); vl.Text=tostring(tbl[key]); vl.Font=FB; vl.TextSize=11; vl.TextColor3=TH.AC
    vl.BackgroundTransparency=1; vl.Position=UDim2.new(1,-50,0,2); vl.Size=UDim2.new(0,40,0,20)
    vl.TextXAlignment=Enum.TextXAlignment.Right; vl.Parent=fr
    local tr=Instance.new("Frame"); tr.Name=rid(4); tr.Size=UDim2.new(1,-28,0,6); tr.Position=UDim2.new(0,14,0,32)
    tr.BackgroundColor3=TH.BD; tr.BorderSizePixel=0; tr.Parent=fr
    sNew("UICorner",{CornerRadius=UDim.new(1,0)},tr)
    local r=math.max(mx-mn,1); local pct=clmp((tbl[key]-mn)/r,0,1)
    local fi=Instance.new("Frame"); fi.Name=rid(4); fi.Size=UDim2.new(pct,0,1,0); fi.BackgroundColor3=TH.AC; fi.BorderSizePixel=0; fi.Parent=tr
    sNew("UICorner",{CornerRadius=UDim.new(1,0)},fi)
    sNew("UIGradient",{Color=ColorSequence.new({ColorSequenceKeypoint.new(0,TH.AC),ColorSequenceKeypoint.new(1,TH.A2)})},fi)
    local sb=Instance.new("TextButton"); sb.Name=rid(4); sb.Size=UDim2.new(1,0,0,20); sb.Position=UDim2.new(0,0,0,24)
    sb.BackgroundTransparency=1; sb.Text=""; sb.Parent=fr
    local sliding=false
    local function upd(ix) local ap=tr.AbsolutePosition.X;local az=tr.AbsoluteSize.X;if az==0 then return end
        local rl=clmp((ix-ap)/az,0,1); local val=math.floor(mn+r*rl); tbl[key]=val;vl.Text=tostring(val);fi.Size=UDim2.new(rl,0,1,0)
        if cb then pcall(cb,val) end end
    sb.InputBegan:Connect(function(i) if i.UserInputType==Enum.UserInputType.MouseButton1 or i.UserInputType==Enum.UserInputType.Touch then sliding=true;upd(i.Position.X) end end)
    sb.InputEnded:Connect(function(i) if i.UserInputType==Enum.UserInputType.MouseButton1 or i.UserInputType==Enum.UserInputType.Touch then sliding=false end end)
    UIS.InputChanged:Connect(function(i) if sliding and (i.UserInputType==Enum.UserInputType.MouseMovement or i.UserInputType==Enum.UserInputType.Touch) then upd(i.Position.X) end end)
end

function UI:Drop(td,name,opts,tbl,key,cb)
    local fr=Instance.new("Frame"); fr.Name=rid(6); fr.Size=UDim2.new(1,0,0,34); fr.BackgroundColor3=TH.SL
    fr.BackgroundTransparency=0.4; fr.BorderSizePixel=0; fr.ClipsDescendants=false; fr.LayoutOrder=td.O
    td.O=td.O+1; fr.ZIndex=5; fr.Parent=td.Ct
    sNew("UICorner",{CornerRadius=UDim.new(0,8)},fr)
    local lb=Instance.new("TextLabel"); lb.Name=rid(4); lb.Text=name; lb.Font=FR; lb.TextSize=12; lb.TextColor3=TH.TX
    lb.BackgroundTransparency=1; lb.Position=UDim2.new(0,14,0,0); lb.Size=UDim2.new(0.5,0,1,0)
    lb.TextXAlignment=Enum.TextXAlignment.Left; lb.ZIndex=5; lb.Parent=fr
    local sb=Instance.new("TextButton"); sb.Name=rid(4); sb.Text=tostring(tbl[key]).." v"; sb.Font=FM; sb.TextSize=11
    sb.TextColor3=TH.AC; sb.BackgroundColor3=TH.BG; sb.Position=UDim2.new(1,-130,0.5,-12)
    sb.Size=UDim2.new(0,118,0,24); sb.AutoButtonColor=false; sb.ZIndex=5; sb.Parent=fr
    sNew("UICorner",{CornerRadius=UDim.new(0,4)},sb)
    local dd=Instance.new("Frame"); dd.Name=rid(4); dd.Size=UDim2.new(0,118,0,#opts*28+4); dd.Position=UDim2.new(1,-130,1,2)
    dd.BackgroundColor3=TH.SF; dd.BorderSizePixel=0; dd.Visible=false; dd.ZIndex=50; dd.Parent=fr
    sNew("UICorner",{CornerRadius=UDim.new(0,8)},dd); sNew("UIStroke",{Color=TH.BD,Thickness=1},dd)
    local dl=Instance.new("UIListLayout"); dl.Padding=UDim.new(0,0); dl.Parent=dd
    local dp=Instance.new("UIPadding"); dp.PaddingTop=UDim.new(0,2); dp.PaddingBottom=UDim.new(0,2); dp.Parent=dd
    for _,op in ipairs(opts) do
        local ob=Instance.new("TextButton"); ob.Name=rid(4); ob.Text=tostring(op); ob.Font=FR; ob.TextSize=11; ob.TextColor3=TH.TX
        ob.BackgroundTransparency=1; ob.Size=UDim2.new(1,0,0,28); ob.AutoButtonColor=false; ob.ZIndex=51; ob.Parent=dd
        ob.MouseEnter:Connect(function() ob.BackgroundTransparency=0.7;ob.BackgroundColor3=TH.AC end)
        ob.MouseLeave:Connect(function() ob.BackgroundTransparency=1 end)
        ob.MouseButton1Click:Connect(function() tbl[key]=op;sb.Text=tostring(op).." v";dd.Visible=false;if cb then pcall(cb,op) end end)
    end; sb.MouseButton1Click:Connect(function() dd.Visible=not dd.Visible end)
end

function UI:Btn(td,name,cb)
    local bt=Instance.new("TextButton"); bt.Name=rid(6); bt.Size=UDim2.new(1,0,0,34); bt.BackgroundColor3=TH.A2
    bt.BackgroundTransparency=0.6; bt.BorderSizePixel=0; bt.Text=name; bt.Font=FB; bt.TextSize=12
    bt.TextColor3=TH.TX; bt.AutoButtonColor=false; bt.LayoutOrder=td.O; td.O=td.O+1; bt.Parent=td.Ct
    sNew("UICorner",{CornerRadius=UDim.new(0,8)},bt)
    bt.MouseEnter:Connect(function() TS:Create(bt,TweenInfo.new(0.15),{BackgroundTransparency=0.3}):Play() end)
    bt.MouseLeave:Connect(function() TS:Create(bt,TweenInfo.new(0.15),{BackgroundTransparency=0.6}):Play() end)
    bt.MouseButton1Click:Connect(function() if cb then pcall(cb) end end)
end

function UI:Toggle() self.Vis=not self.Vis; self.MF.Visible=self.Vis end
function UI:Kill() pcall(function() self.SG:Destroy() end) end

-- ============================================================
-- FEATURES (Anti-Detection Optimized)
-- ============================================================
local F = {}
F.AT=nil; F.FB2=nil; F.OL={}; F.ED={}; F.CD={}; F.FC=nil

-- AIMBOT (with human jitter)
function F:ClosestP()
    local fov=CFG.Aim.FOV; local cl,cd=nil,fov
    for _,p in ipairs(Players:GetPlayers()) do
        if p~=LP and Alive(p) and Enemy(p,CFG.Aim.Team) then
            local ch=GetChar(p); local bn=GetBone(ch,CFG.Aim.Bone)
            if bn then local sp,os=W2S(bn.Position)
                if os then local mp=UIS:GetMouseLocation(); local d=(sp-mp).Magnitude
                    if d<cd then if not CFG.Aim.Wall or Visible(bn) then cl=bn;cd=d end end end end end end
    return cl
end

function F:Aimbot()
    if not CFG.Aim.On then return end
    if not UIS:IsMouseButtonPressed(Enum.UserInputType.MouseButton2) then self.AT=nil; return end
    local t=self:ClosestP(); if not t then return end
    self.AT=t; local tp=t.Position
    if CFG.Aim.Pred and t.Parent then
        local h=t.Parent:FindFirstChild("HumanoidRootPart")
        if h then local v=Vector3.new(0,0,0); pcall(function() v=h.AssemblyLinearVelocity end)
            if v==Vector3.new(0,0,0) then pcall(function() v=h.Velocity end) end
            tp=tp+v*CFG.Aim.PS end end
    -- Anti-detect: add human-like micro-jitter
    local jit = humanJitter()
    local cc=Cam.CFrame; local tc=CFrame.lookAt(cc.Position,tp)
    local a=1/math.max(CFG.Aim.Smooth,1); if a>1 then a=1 end
    -- Anti-detect: slightly random alpha for natural feel
    a = a * (0.85 + math.random() * 0.3)
    Cam.CFrame=cc:Lerp(tc,a)
end

-- SILENT AIM
local saInit=false
function F:InitSA()
    if saInit or not hasHook then return end
    pcall(function()
        local mt=getrawmetatable(game); local on=mt.__namecall
        if setreadonly then setreadonly(mt,false) end
        if make_writeable then make_writeable(mt) end
        local wf=newcclosure or function(f) return f end
        mt.__namecall=wf(function(s,...)
            local m=getnamecallmethod(); local a={...}
            if CFG.SAim.On and (m=="FireServer" or m=="InvokeServer") then
                local tg=F:SilentTgt()
                if tg and math.random(1,100)<=CFG.SAim.HC then
                    for i,v in pairs(a) do
                        if typeof(v)=="CFrame" then a[i]=CFrame.new(tg.Position)
                        elseif typeof(v)=="Vector3" then a[i]=tg.Position end
                    end; return on(s,unpack(a)) end end
            return on(s,...) end)
        if setreadonly then setreadonly(mt,true) end
        if make_readonly then make_readonly(mt) end; saInit=true
    end)
end

function F:SilentTgt()
    local cl,cd=nil,CFG.Aim.FOV
    for _,p in ipairs(Players:GetPlayers()) do
        if p~=LP and Alive(p) and Enemy(p,CFG.SAim.Team) then
            local ch=GetChar(p); local bn=GetBone(ch,CFG.SAim.Bone)
            if bn then local sp,os=W2S(bn.Position)
                if os then local d=(sp-UIS:GetMouseLocation()).Magnitude;if d<cd then cl=bn;cd=d end end end end end
    return cl
end

-- TRIGGERBOT (with randomized delay for anti-detect)
function F:Triggerbot()
    if not CFG.Trig.On or not Alive(LP) then return end
    local mp=UIS:GetMouseLocation(); local r=Cam:ViewportPointToRay(mp.X,mp.Y)
    local pr=RaycastParams.new(); pr.FilterType=FE; pr.FilterDescendantsInstances={LP.Character}
    local res=WS:Raycast(r.Origin,r.Direction*1000,pr)
    if res and res.Instance then local hm=res.Instance:FindFirstAncestorOfClass("Model")
        if hm then local hp=Players:GetPlayerFromCharacter(hm)
            if hp and Enemy(hp,CFG.Trig.Team) and Alive(hp) then
                -- Anti-detect: randomize delay slightly
                swait((CFG.Trig.Delay + math.random(-20,20))/1000)
                if VIM then pcall(function() VIM:SendMouseButtonEvent(mp.X,mp.Y,0,true,game,0);swait(0.03);VIM:SendMouseButtonEvent(mp.X,mp.Y,0,false,game,0) end)
                elseif mouse1click then pcall(mouse1click) end end end end
end

-- NO RECOIL
local storedCF=nil
function F:NoRecoil()
    if not CFG.NR.On then return end
    if UIS:IsMouseButtonPressed(Enum.UserInputType.MouseButton1) then
        if storedCF then Cam.CFrame=CFrame.new(Cam.CFrame.Position)*storedCF.Rotation end
    else storedCF=Cam.CFrame end
end

-- ESP (Drawing API only - invisible to anti-cheat)
function F:InitESP(p)
    if p==LP or not hasDraw then return end
    self.ED[p]={
        BT=sDraw("Line",{Visible=false,Thickness=1}),BR=sDraw("Line",{Visible=false,Thickness=1}),
        BB=sDraw("Line",{Visible=false,Thickness=1}),BL=sDraw("Line",{Visible=false,Thickness=1}),
        NM=sDraw("Text",{Visible=false,Size=13,Center=true,Outline=true,Font=2}),
        HB=sDraw("Line",{Visible=false,Color=Color3.fromRGB(30,30,30),Thickness=4}),
        HF=sDraw("Line",{Visible=false,Thickness=2}),
        DT=sDraw("Text",{Visible=false,Size=10,Center=true,Outline=true,Font=2}),
        TR=sDraw("Line",{Visible=false,Thickness=1}),
    }
end

local function hideD(d) if not d then return end; for _,v in pairs(d) do if v and v.Remove then pcall(function() v.Visible=false end) end end end
local function killD(d) if not d then return end; for _,v in pairs(d) do if v then pcall(function() v:Remove() end) end end end

function F:ESP()
    if not hasDraw then return end
    if not CFG.ESP.On then for _,d in pairs(self.ED) do hideD(d) end; return end
    for _,p in ipairs(Players:GetPlayers()) do
        if p~=LP then
            if not self.ED[p] then self:InitESP(p) end; local d=self.ED[p]; if not d then return end
            local ch=GetChar(p); local en=Enemy(p,CFG.ESP.Team)
            if not ch or not Alive(p) or not en then hideD(d)
            else
                local hr=ch:FindFirstChild("HumanoidRootPart"); local hd=ch:FindFirstChild("Head")
                local hm=ch:FindFirstChildOfClass("Humanoid")
                if not hr or not hd or not hm then hideD(d)
                else
                    local ps,os2,dp=W2S(hr.Position)
                    if not os2 or dp<0 then hideD(d)
                    else
                        local hp2=W2S(hd.Position+Vector3.new(0,0.5,0)); local fp=W2S(hr.Position-Vector3.new(0,3,0))
                        local bh=math.abs(hp2.Y-fp.Y); local bw=bh*0.6
                        local col=CFG.ESP.BC
                        if CFG.ESP.TC and p.Team then pcall(function() col=p.TeamColor.Color end) end
                        if CFG.ESP.Box then
                            local tl=Vector2.new(ps.X-bw/2,hp2.Y);local tr2=Vector2.new(ps.X+bw/2,hp2.Y)
                            local bl=Vector2.new(ps.X-bw/2,fp.Y);local br=Vector2.new(ps.X+bw/2,fp.Y)
                            sDP(d.BT,"From",tl);sDP(d.BT,"To",tr2);sDP(d.BT,"Color",col);sDP(d.BT,"Visible",true)
                            sDP(d.BR,"From",tr2);sDP(d.BR,"To",br);sDP(d.BR,"Color",col);sDP(d.BR,"Visible",true)
                            sDP(d.BB,"From",br);sDP(d.BB,"To",bl);sDP(d.BB,"Color",col);sDP(d.BB,"Visible",true)
                            sDP(d.BL,"From",bl);sDP(d.BL,"To",tl);sDP(d.BL,"Color",col);sDP(d.BL,"Visible",true)
                        else sDP(d.BT,"Visible",false);sDP(d.BR,"Visible",false);sDP(d.BB,"Visible",false);sDP(d.BL,"Visible",false) end
                        if CFG.ESP.Name and d.NM then sDP(d.NM,"Position",Vector2.new(ps.X,hp2.Y-16));sDP(d.NM,"Text",p.DisplayName or p.Name)
                            sDP(d.NM,"Color",CFG.ESP.NC);sDP(d.NM,"Visible",true) elseif d.NM then sDP(d.NM,"Visible",false) end
                        if CFG.ESP.HP and d.HB then
                            local pct=clmp(hm.Health/math.max(hm.MaxHealth,1),0,1); local bx=ps.X-bw/2-6
                            local bt2,bb=hp2.Y,fp.Y; local bf=bb-(bb-bt2)*pct
                            sDP(d.HB,"From",Vector2.new(bx,bt2));sDP(d.HB,"To",Vector2.new(bx,bb));sDP(d.HB,"Visible",true)
                            sDP(d.HF,"From",Vector2.new(bx,bf));sDP(d.HF,"To",Vector2.new(bx,bb))
                            sDP(d.HF,"Color",Color3.fromRGB(255*(1-pct),255*pct,0));sDP(d.HF,"Visible",true)
                        else sDP(d.HB,"Visible",false);sDP(d.HF,"Visible",false) end
                        if CFG.ESP.Dist and d.DT then sDP(d.DT,"Position",Vector2.new(ps.X,fp.Y+2))
                            sDP(d.DT,"Text",math.floor((hr.Position-Cam.CFrame.Position).Magnitude).."m");sDP(d.DT,"Visible",true)
                        elseif d.DT then sDP(d.DT,"Visible",false) end
                        if CFG.ESP.Trac and d.TR then local vp=Cam.ViewportSize; local orig
                            if CFG.ESP.TO=="Bottom" then orig=Vector2.new(vp.X/2,vp.Y) elseif CFG.ESP.TO=="Top" then orig=Vector2.new(vp.X/2,0)
                            else orig=Vector2.new(vp.X/2,vp.Y/2) end
                            sDP(d.TR,"From",orig);sDP(d.TR,"To",Vector2.new(ps.X,fp.Y));sDP(d.TR,"Color",col);sDP(d.TR,"Visible",true)
                        elseif d.TR then sDP(d.TR,"Visible",false) end
                    end end end end end
end

-- CROSSHAIR
function F:InitCross()
    if not hasDraw then return end
    self.CD={T=sDraw("Line",{Visible=false,Thickness=1}),B=sDraw("Line",{Visible=false,Thickness=1}),
        L=sDraw("Line",{Visible=false,Thickness=1}),R=sDraw("Line",{Visible=false,Thickness=1}),
        D=sDraw("Circle",{Visible=false,Filled=true,Radius=2,NumSides=12})}
end

function F:Cross()
    if not hasDraw then return end
    if not CFG.Cross.On then for _,d in pairs(self.CD) do if d then sDP(d,"Visible",false) end end; return end
    local c=ScrCen();local s,g,cl,t=CFG.Cross.Sz,CFG.Cross.Gap,CFG.Cross.Col,CFG.Cross.Th
    if self.CD.T then sDP(self.CD.T,"From",Vector2.new(c.X,c.Y-g-s));sDP(self.CD.T,"To",Vector2.new(c.X,c.Y-g));sDP(self.CD.T,"Color",cl);sDP(self.CD.T,"Thickness",t);sDP(self.CD.T,"Visible",true) end
    if self.CD.B then sDP(self.CD.B,"From",Vector2.new(c.X,c.Y+g));sDP(self.CD.B,"To",Vector2.new(c.X,c.Y+g+s));sDP(self.CD.B,"Color",cl);sDP(self.CD.B,"Thickness",t);sDP(self.CD.B,"Visible",true) end
    if self.CD.L then sDP(self.CD.L,"From",Vector2.new(c.X-g-s,c.Y));sDP(self.CD.L,"To",Vector2.new(c.X-g,c.Y));sDP(self.CD.L,"Color",cl);sDP(self.CD.L,"Thickness",t);sDP(self.CD.L,"Visible",true) end
    if self.CD.R then sDP(self.CD.R,"From",Vector2.new(c.X+g,c.Y));sDP(self.CD.R,"To",Vector2.new(c.X+g+s,c.Y));sDP(self.CD.R,"Color",cl);sDP(self.CD.R,"Thickness",t);sDP(self.CD.R,"Visible",true) end
    if self.CD.D then sDP(self.CD.D,"Position",c);sDP(self.CD.D,"Color",cl);sDP(self.CD.D,"Visible",CFG.Cross.Dot) end
end

-- FOV CIRCLE
function F:InitFOV()
    if not hasDraw then return end
    self.FC=sDraw("Circle",{Visible=false,Filled=false,Transparency=0.7,Radius=CFG.Aim.FOV,NumSides=64,Thickness=1,Color=Color3.fromRGB(255,255,255)})
end

function F:FOV()
    if not hasDraw or not self.FC then return end
    if CFG.Aim.ShowFOV and CFG.Aim.On then sDP(self.FC,"Position",UIS:GetMouseLocation());sDP(self.FC,"Radius",CFG.Aim.FOV);sDP(self.FC,"Visible",true)
    else sDP(self.FC,"Visible",false) end
end

-- MOVEMENT (Anti-detect: CFrame-based, no body movers)
function F:BHop()
    if not CFG.BHop.On or not Alive(LP) then return end
    local h=GetChar(LP) and GetChar(LP):FindFirstChildOfClass("Humanoid")
    if h and h.FloorMaterial~=Enum.Material.Air and UIS:IsKeyDown(Enum.KeyCode.Space) then h:ChangeState(Enum.HumanoidStateType.Jumping) end
end

function F:SpeedB()
    if not Alive(LP) or not CFG.Speed.On then return end
    -- Anti-detect: use CFrame-based speed boost instead of WalkSpeed
    local ch=GetChar(LP); local hr=ch and ch:FindFirstChild("HumanoidRootPart")
    local hm=ch and ch:FindFirstChildOfClass("Humanoid")
    if hr and hm then
        -- Small speed increase is less detectable
        local boost = (CFG.Speed.Val - 16) / 16
        if boost > 0 and hm.MoveDirection.Magnitude > 0 then
            hr.CFrame = hr.CFrame + hm.MoveDirection * boost * 0.3
        end
    end
end

function F:InitIJ()
    UIS.JumpRequest:Connect(function()
        if not CFG.IJump.On or not Alive(LP) then return end
        local h=GetChar(LP) and GetChar(LP):FindFirstChildOfClass("Humanoid")
        if h then h:ChangeState(Enum.HumanoidStateType.Jumping) end
    end)
end

-- FLY (Anti-detect: CFrame-based, no BodyVelocity)
function F:FlyF()
    if not Alive(LP) then return end
    local ch=GetChar(LP); local hr=ch and ch:FindFirstChild("HumanoidRootPart")
    local hm=ch and ch:FindFirstChildOfClass("Humanoid")
    if not hr or not hm then return end
    if CFG.Fly.On then
        local d=Vector3.new(0,0,0)
        if UIS:IsKeyDown(Enum.KeyCode.W) then d=d+Cam.CFrame.LookVector end
        if UIS:IsKeyDown(Enum.KeyCode.S) then d=d-Cam.CFrame.LookVector end
        if UIS:IsKeyDown(Enum.KeyCode.A) then d=d-Cam.CFrame.RightVector end
        if UIS:IsKeyDown(Enum.KeyCode.D) then d=d+Cam.CFrame.RightVector end
        if UIS:IsKeyDown(Enum.KeyCode.Space) then d=d+Vector3.new(0,1,0) end
        if UIS:IsKeyDown(Enum.KeyCode.LeftControl) then d=d-Vector3.new(0,1,0) end
        -- Anti-detect: CFrame teleport instead of BodyVelocity
        if d.Magnitude > 0 then
            d = d.Unit * CFG.Fly.Val * 0.016 -- per-frame movement
        end
        hr.CFrame = hr.CFrame + d
        hr.Velocity = Vector3.new(0,0,0) -- prevent falling
    end
end

function F:NoclipF()
    if not CFG.Noclip.On or not Alive(LP) then return end
    local ch=GetChar(LP); if ch then for _,p in ipairs(ch:GetDescendants()) do if p:IsA("BasePart") then p.CanCollide=false end end end
end

-- MISC
function F:InitAAFK()
    pcall(function() local gc=getconnections or get_signal_cons; if gc then for _,c in ipairs(gc(LP.Idled)) do c:Disable() end end end)
    if VU then sspawn(function() while true do swait(60); if CFG.AAFK.On then pcall(function()
        VU:Button2Down(Vector2.new(0,0),Cam.CFrame);swait(0.1);VU:Button2Up(Vector2.new(0,0),Cam.CFrame) end) end end end) end
end

function F:Fullbright()
    if CFG.FB.On then
        if not self.OL.A then self.OL.A=Light.Ambient;self.OL.B=Light.Brightness;self.OL.O=Light.OutdoorAmbient end
        Light.Ambient=Color3.fromRGB(200,200,200);Light.Brightness=2;Light.OutdoorAmbient=Color3.fromRGB(200,200,200)
    elseif self.OL.A then Light.Ambient=self.OL.A;Light.Brightness=self.OL.B;Light.OutdoorAmbient=self.OL.O end
end

function F:NoFog()
    if CFG.NF.On then
        if not self.OL.FE then self.OL.FE=Light.FogEnd;self.OL.FS=Light.FogStart end
        Light.FogEnd=999999;Light.FogStart=999999
    elseif self.OL.FE then Light.FogEnd=self.OL.FE;Light.FogStart=self.OL.FS end
end

function F:ThirdP()
    if CFG.TP.On then LP.CameraMinZoomDistance=CFG.TP.Dist;LP.CameraMaxZoomDistance=CFG.TP.Dist+5 end
end

-- Player cleanup
Players.PlayerRemoving:Connect(function(p)
    if F.ED[p] then killD(F.ED[p]);F.ED[p]=nil end
end)

-- ============================================================
-- BUILD UI
-- ============================================================
UI:Init()

local t1=UI:Tab("Combat",1)
UI:Sec(t1,"AIMBOT")
UI:Tog(t1,"Enable Aimbot",CFG.Aim,"On")
UI:Sli(t1,"Smoothing",1,20,CFG.Aim,"Smooth")
UI:Sli(t1,"FOV Radius",20,500,CFG.Aim,"FOV")
UI:Drop(t1,"Target Bone",{"Head","Torso","HumanoidRootPart"},CFG.Aim,"Bone")
UI:Tog(t1,"Team Check",CFG.Aim,"Team")
UI:Tog(t1,"Wall Check",CFG.Aim,"Wall")
UI:Tog(t1,"Prediction",CFG.Aim,"Pred")
UI:Tog(t1,"Show FOV",CFG.Aim,"ShowFOV")
UI:Sec(t1,"SILENT AIM")
UI:Tog(t1,"Enable Silent Aim",CFG.SAim,"On",function(v) if v then F:InitSA() end end)
UI:Sli(t1,"Hit Chance (%)",1,100,CFG.SAim,"HC")
UI:Drop(t1,"Target Bone",{"Head","Torso","HumanoidRootPart"},CFG.SAim,"Bone")
UI:Sec(t1,"TRIGGERBOT")
UI:Tog(t1,"Enable Triggerbot",CFG.Trig,"On")
UI:Sli(t1,"Trigger Delay (ms)",0,300,CFG.Trig,"Delay")
UI:Tog(t1,"Team Check",CFG.Trig,"Team")
UI:Sec(t1,"WEAPONS")
UI:Tog(t1,"No Recoil",CFG.NR,"On")

local t2=UI:Tab("Visuals",2)
UI:Sec(t2,"PLAYER ESP")
UI:Tog(t2,"Enable ESP",CFG.ESP,"On")
UI:Tog(t2,"Boxes",CFG.ESP,"Box")
UI:Tog(t2,"Names",CFG.ESP,"Name")
UI:Tog(t2,"Health Bars",CFG.ESP,"HP")
UI:Tog(t2,"Distance",CFG.ESP,"Dist")
UI:Tog(t2,"Tracers",CFG.ESP,"Trac")
UI:Drop(t2,"Tracer Origin",{"Bottom","Top","Center"},CFG.ESP,"TO")
UI:Tog(t2,"Team Check",CFG.ESP,"Team")
UI:Tog(t2,"Team Colors",CFG.ESP,"TC")
UI:Sec(t2,"CROSSHAIR")
UI:Tog(t2,"Custom Crosshair",CFG.Cross,"On")
UI:Sli(t2,"Size",2,20,CFG.Cross,"Sz")
UI:Sli(t2,"Gap",0,15,CFG.Cross,"Gap")
UI:Sli(t2,"Thickness",1,5,CFG.Cross,"Th")
UI:Tog(t2,"Center Dot",CFG.Cross,"Dot")
UI:Sec(t2,"WORLD")
UI:Tog(t2,"Fullbright",CFG.FB,"On")
UI:Tog(t2,"No Fog",CFG.NF,"On")

local t3=UI:Tab("Movement",3)
UI:Sec(t3,"MOVEMENT")
UI:Tog(t3,"Bunny Hop",CFG.BHop,"On")
UI:Tog(t3,"Speed Boost",CFG.Speed,"On")
UI:Sli(t3,"Speed",16,30,CFG.Speed,"Val") -- Lower max = less detectable
UI:Tog(t3,"Infinite Jump",CFG.IJump,"On")
UI:Sec(t3,"ADVANCED")
UI:Tog(t3,"Fly",CFG.Fly,"On")
UI:Sli(t3,"Fly Speed",10,100,CFG.Fly,"Val")
UI:Tog(t3,"Noclip",CFG.Noclip,"On")

local t4=UI:Tab("Misc",4)
UI:Sec(t4,"UTILITIES")
UI:Tog(t4,"Anti-AFK",CFG.AAFK,"On")
UI:Tog(t4,"Third Person Lock",CFG.TP,"On")
UI:Sli(t4,"Camera Distance",5,30,CFG.TP,"Dist")
UI:Sec(t4,"OFFSETS")
UI:Btn(t4,"Refresh Offsets",function()
    Notify("Offsets","Refreshing...",2); sspawn(function() FetchOff(); Notify("Offsets",OStat,3) end) end)
UI:Btn(t4,"Show Version",function() Notify("Version","Offsets: "..OVer.." | Script: v4.0",4) end)

local t5=UI:Tab("Settings",5)
UI:Sec(t5,"GENERAL")
UI:Btn(t5,"Unload Script",function()
    Notify("Unloading","Cleaning up...",2)
    sspawn(function() swait(1)
        for _,d in pairs(F.ED) do killD(d) end; for _,d in pairs(F.CD) do sDR(d) end; sDR(F.FC)
        CFG.FB.On=false;F:Fullbright();CFG.NF.On=false;F:NoFog(); UI:Kill()
    end) end)
UI:Btn(t5,"Toggle: RightCtrl",function() Notify("Info","Press RightCtrl to toggle",3) end)

UI:Sel("Combat")

-- ============================================================
-- MAIN LOOPS
-- ============================================================
F:InitCross(); F:InitFOV(); F:InitIJ(); F:InitAAFK()
pcall(function() F:InitSA() end)

RS.RenderStepped:Connect(function()
    Cam=WS.CurrentCamera
    pcall(function() F:Aimbot() end)
    pcall(function() F:NoRecoil() end)
    pcall(function() F:ESP() end)
    pcall(function() F:Cross() end)
    pcall(function() F:FOV() end)
    pcall(function() F:NoclipF() end)
    pcall(function() F:FlyF() end)
end)

RS.Heartbeat:Connect(function()
    pcall(function() F:Triggerbot() end)
    pcall(function() F:BHop() end)
    pcall(function() F:SpeedB() end)
    pcall(function() F:Fullbright() end)
    pcall(function() F:NoFog() end)
    pcall(function() F:ThirdP() end)
end)

UIS.InputBegan:Connect(function(i,g) if g then return end; if i.KeyCode==CFG.MKey then UI:Toggle() end end)

-- Delayed startup notifications (anti-detect: don't announce immediately)
delayedRun(function()
    Notify("Domination","v4.0 loaded - stealth active",4)
    swait(0.5); Notify("Offsets",OStat,3)
    swait(0.5); Notify("Tip","RightCtrl to toggle",3)
end, 1.5, 3)

end)

if not ok then
    pcall(function() warn("[ERR] "..tostring(err)) end)
    pcall(function() print("[ERR] "..tostring(err)) end)
end
