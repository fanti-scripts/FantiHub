local Players = game:GetService("Players")
local Player = Players.LocalPlayer
local Mouse = Player:GetMouse()
local UserInputService = game:GetService("UserInputService")
local RunService = game:GetService("RunService")
local Camera = workspace.CurrentCamera

local ScreenGui = Instance.new("ScreenGui")
ScreenGui.Name = "FantiHubGUI"
ScreenGui.ResetOnSpawn = false
ScreenGui.Parent = Player:WaitForChild("PlayerGui")

local espEnabled = false
local aimbotEnabled = false
local statsEnabled = false
local espConnections = {}
local playerColors = {}
local heartbeatConnection = nil
local characterAddedConnections = {}

local StatsSettings = {ShowFPS = true, ShowPlayers = true}
local AimbotSettings = {FOV = 300, Smoothness = 0.3, AimPart = "HumanoidRootPart", OnlyGun = true, ShowFOV = true}

local function CreateCorner(obj, r)
    local c = Instance.new("UICorner")
    c.CornerRadius = UDim.new(0, r or 8)
    c.Parent = obj
end

local function CreateBtn(text, pos, parent, size)
    local b = Instance.new("TextButton")
    b.Size = size or UDim2.new(0, 90, 0, 30)
    b.Position = pos or UDim2.new(0, 5, 0, 5)
    b.BackgroundColor3 = Color3.fromRGB(60,60,60)
    b.BackgroundTransparency = 0.3
    b.Text = text
    b.TextColor3 = Color3.fromRGB(255,255,255)
    b.TextSize = 13
    b.Font = Enum.Font.GothamBold
    CreateCorner(b, 6)
    b.Parent = parent
    return b
end

-- ===== FOV КРУГ (ТОЧНО ПО ЦЕНТРУ) =====
local FOVContainer = Instance.new("Frame")
FOVContainer.Size = UDim2.new(1,0,1,0)
FOVContainer.BackgroundTransparency = 1
FOVContainer.Parent = ScreenGui

local FOVCircle = Instance.new("Frame")
FOVCircle.Size = UDim2.new(0, AimbotSettings.FOV*2, 0, AimbotSettings.FOV*2)
FOVCircle.Position = UDim2.new(0.5, -AimbotSettings.FOV, 0.5, -AimbotSettings.FOV)
FOVCircle.BackgroundColor3 = Color3.fromRGB(255, 215, 0)
FOVCircle.BackgroundTransparency = 0.7
FOVCircle.BorderSizePixel = 2
FOVCircle.BorderColor3 = Color3.fromRGB(255, 215, 0)
FOVCircle.Visible = false
FOVCircle.Parent = FOVContainer
CreateCorner(FOVCircle, 999)

local FOVFill = Instance.new("Frame")
FOVFill.Size = UDim2.new(1,-4,1,-4)
FOVFill.Position = UDim2.new(0,2,0,2)
FOVFill.BackgroundColor3 = Color3.fromRGB(255, 215, 0)
FOVFill.BackgroundTransparency = 0.85
FOVFill.Parent = FOVCircle
CreateCorner(FOVFill, 999)

local function updateFOV()
    local show = aimbotEnabled and AimbotSettings.ShowFOV
    FOVCircle.Visible = show
    FOVFill.Visible = show
    if show then
        FOVCircle.Size = UDim2.new(0, AimbotSettings.FOV*2, 0, AimbotSettings.FOV*2)
        FOVCircle.Position = UDim2.new(0.5, -AimbotSettings.FOV, 0.5, -AimbotSettings.FOV)
    end
end

-- ===== STATS FRAME (СЛЕВА СВЕРХУ + ПЕРЕТАСКИВАНИЕ) =====
local StatsFrame = Instance.new("Frame")
StatsFrame.Size = UDim2.new(0, 180, 0, 55)
StatsFrame.Position = UDim2.new(0.02, 0, 0.08, 0)
StatsFrame.BackgroundColor3 = Color3.fromRGB(15,15,25)
StatsFrame.BackgroundTransparency = 0.3
StatsFrame.BorderSizePixel = 1
StatsFrame.BorderColor3 = Color3.fromRGB(255,215,0)
StatsFrame.Visible = false
StatsFrame.Parent = ScreenGui
CreateCorner(StatsFrame, 8)

local STitle = Instance.new("TextLabel")
STitle.Size = UDim2.new(1,0,0,18)
STitle.BackgroundTransparency = 1
STitle.Text = "⚡ Stats"
STitle.TextColor3 = Color3.fromRGB(255,215,0)
STitle.TextSize = 12
STitle.Font = Enum.Font.GothamBold
STitle.TextXAlignment = Enum.TextXAlignment.Center
STitle.Parent = StatsFrame

local SFPS = Instance.new("TextLabel")
SFPS.Size = UDim2.new(1,0,0,18)
SFPS.Position = UDim2.new(0,5,0,20)
SFPS.BackgroundTransparency = 1
SFPS.Text = "FPS: 0"
SFPS.TextColor3 = Color3.fromRGB(0,255,0)
SFPS.TextSize = 14
SFPS.Font = Enum.Font.GothamBold
SFPS.TextXAlignment = Enum.TextXAlignment.Left
SFPS.Parent = StatsFrame

local SPlayers = Instance.new("TextLabel")
SPlayers.Size = UDim2.new(1,0,0,18)
SPlayers.Position = UDim2.new(0,5,0,38)
SPlayers.BackgroundTransparency = 1
SPlayers.Text = "Players: 0"
SPlayers.TextColor3 = Color3.fromRGB(0,200,255)
SPlayers.TextSize = 14
SPlayers.Font = Enum.Font.GothamBold
SPlayers.TextXAlignment = Enum.TextXAlignment.Left
SPlayers.Parent = StatsFrame

-- Перетаскивание StatsFrame
local statsDrag = {isDragging = false, start = nil, startPos = nil}
STitle.InputBegan:Connect(function(i)
    if i.UserInputType == Enum.UserInputType.MouseButton1 then
        statsDrag.isDragging = true
        statsDrag.start = i.Position
        statsDrag.startPos = StatsFrame.Position
        StatsFrame.ZIndex = 120
    end
end)
STitle.InputEnded:Connect(function()
    statsDrag.isDragging = false
    StatsFrame.ZIndex = 100
end)
UserInputService.InputChanged:Connect(function(i)
    if statsDrag.isDragging and i.UserInputType == Enum.UserInputType.MouseMovement then
        local d = i.Position - statsDrag.start
        local vx, vy = Camera.ViewportSize.X or 1920, Camera.ViewportSize.Y or 1080
        local nx = math.max(0, math.min(1-180/vx, (statsDrag.startPos.X.Scale*vx + statsDrag.startPos.X.Offset + d.X)/vx))
        local ny = math.max(0, math.min(1-55/vy, (statsDrag.startPos.Y.Scale*vy + statsDrag.startPos.Y.Offset + d.Y)/vy))
        StatsFrame.Position = UDim2.new(nx,0,ny,0)
    end
end)

-- ===== STATS SELECT =====
local StatsSelect = Instance.new("Frame")
StatsSelect.Size = UDim2.new(0,150,0,60)
StatsSelect.Position = UDim2.new(0.5,-75,0.5,-30)
StatsSelect.BackgroundColor3 = Color3.fromRGB(20,20,30)
StatsSelect.BackgroundTransparency = 0.2
StatsSelect.BorderSizePixel = 1
StatsSelect.BorderColor3 = Color3.fromRGB(255,215,0)
StatsSelect.Visible = false
StatsSelect.Parent = ScreenGui
CreateCorner(StatsSelect, 8)

local function MakeToggle(txt, y, key)
    local b = CreateBtn(txt, UDim2.new(0.05,0,y,0), StatsSelect, UDim2.new(0.9,0,0,22))
    b.MouseButton1Click:Connect(function()
        StatsSettings[key] = not StatsSettings[key]
        b.Text = StatsSettings[key] and "☑ "..txt:gsub("☑ ",""):gsub("☐ ","") or "☐ "..txt:gsub("☑ ",""):gsub("☐ ","")
    end)
end
MakeToggle("☑ FPS", 0.08, "ShowFPS")
MakeToggle("☑ Players", 0.42, "ShowPlayers")

-- ===== FOV SLIDER =====
local FOVSlider = Instance.new("Frame")
FOVSlider.Size = UDim2.new(0,220,0,80)
FOVSlider.Position = UDim2.new(0.5,-110,0.5,-40)
FOVSlider.BackgroundColor3 = Color3.fromRGB(20,20,30)
FOVSlider.BackgroundTransparency = 0.2
FOVSlider.BorderSizePixel = 1
FOVSlider.BorderColor3 = Color3.fromRGB(255,215,0)
FOVSlider.Visible = false
FOVSlider.Parent = ScreenGui
CreateCorner(FOVSlider, 12)

local SliderLabel = Instance.new("TextLabel")
SliderLabel.Size = UDim2.new(1,-20,0,25)
SliderLabel.Position = UDim2.new(0,10,0,5)
SliderLabel.BackgroundTransparency = 1
SliderLabel.Text = "FOV: 300"
SliderLabel.TextColor3 = Color3.fromRGB(255,255,255)
SliderLabel.TextSize = 14
SliderLabel.Font = Enum.Font.GothamBold
SliderLabel.TextXAlignment = Enum.TextXAlignment.Left
SliderLabel.Parent = FOVSlider

local SliderTrack = Instance.new("Frame")
SliderTrack.Size = UDim2.new(0.9,0,0,4)
SliderTrack.Position = UDim2.new(0.05,0,0.45,0)
SliderTrack.BackgroundColor3 = Color3.fromRGB(60,60,80)
SliderTrack.Parent = FOVSlider

local SliderFill = Instance.new("Frame")
SliderFill.Size = UDim2.new((AimbotSettings.FOV-50)/450,0,1,0)
SliderFill.BackgroundColor3 = Color3.fromRGB(255,215,0)
SliderFill.Parent = SliderTrack

local SliderThumb = Instance.new("ImageButton")
SliderThumb.Size = UDim2.new(0,16,0,16)
SliderThumb.Position = UDim2.new((AimbotSettings.FOV-50)/450,-8,0.5,-8)
SliderThumb.BackgroundColor3 = Color3.fromRGB(255,215,0)
SliderThumb.Image = ""
SliderThumb.Parent = SliderTrack
CreateCorner(SliderThumb, 999)

local FOVVal = Instance.new("TextLabel")
FOVVal.Size = UDim2.new(0,50,0,20)
FOVVal.Position = UDim2.new(0.5,-25,0.8,0)
FOVVal.BackgroundTransparency = 1
FOVVal.Text = AimbotSettings.FOV
FOVVal.TextColor3 = Color3.fromRGB(255,215,0)
FOVVal.TextSize = 14
FOVVal.Font = Enum.Font.GothamBold
FOVVal.Parent = FOVSlider

local ShowFOVBtn = CreateBtn("☑ Show FOV", UDim2.new(0.05,0,0.7,0), FOVSlider, UDim2.new(0.9,0,0,25))

local isSliding = false
SliderThumb.InputBegan:Connect(function(i)
    if i.UserInputType == Enum.UserInputType.MouseButton1 then isSliding = true end
end)
SliderThumb.InputEnded:Connect(function(i)
    if i.UserInputType == Enum.UserInputType.MouseButton1 then isSliding = false end
end)
UserInputService.InputChanged:Connect(function(i)
    if isSliding and i.UserInputType == Enum.UserInputType.MouseMovement then
        local p = math.max(0, math.min(1, (i.Position.X - SliderTrack.AbsolutePosition.X) / SliderTrack.AbsoluteSize.X))
        local f = math.max(50, math.min(500, math.round(50 + p*450)))
        AimbotSettings.FOV = f
        SliderFill.Size = UDim2.new(p,0,1,0)
        SliderThumb.Position = UDim2.new(p,-8,0.5,-8)
        SliderLabel.Text = "FOV: "..f
        FOVVal.Text = f
        updateFOV()
    end
end)
ShowFOVBtn.MouseButton1Click:Connect(function()
    AimbotSettings.ShowFOV = not AimbotSettings.ShowFOV
    ShowFOVBtn.Text = AimbotSettings.ShowFOV and "☑ Show FOV" or "☐ Show FOV"
    updateFOV()
end)

local function updateStats()
    if not statsEnabled then return end
    if StatsSettings.ShowFPS then
        local fps = math.floor(1/RunService.RenderStepped:Wait())
        SFPS.Text = "FPS: "..fps
        SFPS.TextColor3 = fps>=60 and Color3.fromRGB(0,255,0) or fps>=30 and Color3.fromRGB(255,255,0) or Color3.fromRGB(255,0,0)
    end
    if StatsSettings.ShowPlayers then
        SPlayers.Text = "Players: "..#Players:GetPlayers().."/"..Players.MaxPlayers
    end
end
RunService.RenderStepped:Connect(function() if statsEnabled then updateStats() end end)

-- ===== MAIN BUTTON =====
local OpenBtn = Instance.new("ImageButton")
OpenBtn.Size = UDim2.new(0,50,0,50)
OpenBtn.Position = UDim2.new(0.02,0,0.02,0)
OpenBtn.BackgroundColor3 = Color3.fromRGB(80,80,80)
OpenBtn.BackgroundTransparency = 0.2
OpenBtn.BorderSizePixel = 1
OpenBtn.BorderColor3 = Color3.fromRGB(255,215,0)
OpenBtn.Parent = ScreenGui
CreateCorner(OpenBtn, 12)

local Grad = Instance.new("UIGradient")
Grad.Color = ColorSequence.new({
    ColorSequenceKeypoint.new(0, Color3.fromRGB(120,50,255)),
    ColorSequenceKeypoint.new(0.5, Color3.fromRGB(50,120,255)),
    ColorSequenceKeypoint.new(1, Color3.fromRGB(120,50,255))
})
Grad.Rotation = 45
Grad.Parent = OpenBtn

local OText = Instance.new("TextLabel")
OText.Size = UDim2.new(1,0,1,0)
OText.BackgroundTransparency = 1
OText.Text = "Fanti"
OText.TextColor3 = Color3.fromRGB(255,255,255)
OText.TextSize = 14
OText.Font = Enum.Font.GothamBold
OText.TextWrapped = true
OText.Parent = OpenBtn

-- ===== MAIN MENU =====
local MainFrame = Instance.new("Frame")
MainFrame.Size = UDim2.new(0,480,0,420)
MainFrame.Position = UDim2.new(0.5,-240,0.5,-210)
MainFrame.BackgroundColor3 = Color3.fromRGB(18,18,22)
MainFrame.BackgroundTransparency = 0.15
MainFrame.BorderSizePixel = 1
MainFrame.BorderColor3 = Color3.fromRGB(255,215,0)
MainFrame.Visible = false
MainFrame.Parent = ScreenGui
CreateCorner(MainFrame, 32)

local MFrameGrad = Instance.new("UIGradient")
MFrameGrad.Color = ColorSequence.new({
    ColorSequenceKeypoint.new(0, Color3.fromRGB(18,18,22)),
    ColorSequenceKeypoint.new(0.5, Color3.fromRGB(25,25,30)),
    ColorSequenceKeypoint.new(1, Color3.fromRGB(18,18,22))
})
MFrameGrad.Parent = MainFrame

local Header = Instance.new("Frame")
Header.Size = UDim2.new(1,-40,0,50)
Header.Position = UDim2.new(0,20,0,15)
Header.BackgroundTransparency = 1
Header.Parent = MainFrame

local Logo = Instance.new("Frame")
Logo.Size = UDim2.new(0,36,0,36)
Logo.Position = UDim2.new(0,0,0,7)
Logo.BackgroundColor3 = Color3.fromRGB(255,215,0)
Logo.BackgroundTransparency = 0.7
Logo.BorderSizePixel = 1
Logo.BorderColor3 = Color3.fromRGB(255,215,0)
Logo.Parent = Header
CreateCorner(Logo, 12)

local LogoText = Instance.new("TextLabel")
LogoText.Size = UDim2.new(1,0,1,0)
LogoText.BackgroundTransparency = 1
LogoText.Text = "✦"
LogoText.TextColor3 = Color3.fromRGB(245,215,66)
LogoText.TextSize = 18
LogoText.Font = Enum.Font.GothamBold
LogoText.TextWrapped = true
LogoText.Parent = Logo

local Title = Instance.new("TextLabel")
Title.Size = UDim2.new(0,120,0,25)
Title.Position = UDim2.new(0,50,0,12)
Title.BackgroundTransparency = 1
Title.Text = "Fanti Hub"
Title.TextColor3 = Color3.fromRGB(245,215,66)
Title.TextSize = 20
Title.Font = Enum.Font.GothamBold
Title.TextXAlignment = Enum.TextXAlignment.Left
Title.Parent = Header

local Div = Instance.new("Frame")
Div.Size = UDim2.new(1,-40,0,1)
Div.Position = UDim2.new(0,20,0,70)
Div.BackgroundColor3 = Color3.fromRGB(255,215,0)
Div.BackgroundTransparency = 0.7
Div.Parent = MainFrame

local Content = Instance.new("Frame")
Content.Size = UDim2.new(1,-40,0,240)
Content.Position = UDim2.new(0,20,0,85)
Content.BackgroundTransparency = 1
Content.Parent = MainFrame

local Greeting = Instance.new("TextLabel")
Greeting.Size = UDim2.new(1,0,0,25)
Greeting.BackgroundTransparency = 1
Greeting.Text = "Добро пожаловать в Fanti Hub"
Greeting.TextColor3 = Color3.fromRGB(255,255,255)
Greeting.TextTransparency = 0.2
Greeting.TextSize = 14
Greeting.Font = Enum.Font.Gotham
Greeting.TextXAlignment = Enum.TextXAlignment.Left
Greeting.Parent = Content

local Grid = Instance.new("Frame")
Grid.Size = UDim2.new(1,0,0,200)
Grid.Position = UDim2.new(0,0,0,30)
Grid.BackgroundTransparency = 1
Grid.Parent = Content

local function MakeMainBtn(label, x, y, w, h, color)
    local b = Instance.new("TextButton")
    b.Size = UDim2.new(0,w or 200,0,h or 50)
    b.Position = UDim2.new(0,x or 0,0,y or 0)
    b.BackgroundColor3 = color or Color3.fromRGB(60,60,60)
    b.BackgroundTransparency = 0.3
    b.BorderSizePixel = 1
    b.BorderColor3 = Color3.fromRGB(255,255,255)
    b.Text = label
    b.TextColor3 = Color3.fromRGB(255,255,255)
    b.TextSize = 14
    b.Font = Enum.Font.GothamBold
    b.Parent = Grid
    CreateCorner(b, 12)
    return b
end

local AimbotBtn = MakeMainBtn("Aimbot", 0, 0, 200, 55)
local ESPBtn = MakeMainBtn("ESP", 210, 0, 200, 55)
local StatsBtn = MakeMainBtn("Stats", 0, 65, 200, 55)
local ResetBtn = MakeMainBtn("Reset Role", 210, 65, 200, 55)
local UnloadBtn = MakeMainBtn("UNLOAD CHEAT", 140, 135, 200, 55, Color3.fromRGB(200,0,0))
UnloadBtn.BorderColor3 = Color3.fromRGB(255,0,0)

local Footer = Instance.new("Frame")
Footer.Size = UDim2.new(1,-40,0,35)
Footer.Position = UDim2.new(0,20,0,340)
Footer.BackgroundTransparency = 1
Footer.Parent = MainFrame

local FDiv = Instance.new("Frame")
FDiv.Size = UDim2.new(1,0,0,1)
FDiv.BackgroundColor3 = Color3.fromRGB(255,255,255)
FDiv.BackgroundTransparency = 0.7
FDiv.Parent = Footer

local FText1 = Instance.new("TextLabel")
FText1.Size = UDim2.new(0,150,0,25)
FText1.Position = UDim2.new(0,0,0,8)
FText1.BackgroundTransparency = 1
FText1.Text = "© 2026 Fanti Hub"
FText1.TextColor3 = Color3.fromRGB(255,255,255)
FText1.TextTransparency = 0.6
FText1.TextSize = 11
FText1.Font = Enum.Font.Gotham
FText1.TextXAlignment = Enum.TextXAlignment.Left
FText1.Parent = Footer

local FText2 = Instance.new("TextLabel")
FText2.Size = UDim2.new(0,150,0,25)
FText2.Position = UDim2.new(1,-150,0,8)
FText2.BackgroundTransparency = 1
FText2.Text = "Xeno Injector"
FText2.TextColor3 = Color3.fromRGB(255,215,0)
FText2.TextTransparency = 0.6
FText2.TextSize = 11
FText2.Font = Enum.Font.Gotham
FText2.TextXAlignment = Enum.TextXAlignment.Right
FText2.Parent = Footer

-- ===== FUNCTIONS =====
local function hasGun()
    if not Player.Character then return false end
    for _,t in pairs(Player.Character:GetChildren()) do
        if t:IsA("Tool") and (t.Name=="Gun" or t.Name=="Revolver" or t.Name=="Pistol") then return true end
    end
    return false
end

local function getClosest()
    if not Player.Character or not Mouse then return nil end
    local closest, closestDist = nil, AimbotSettings.FOV
    for _,p in pairs(Players:GetPlayers()) do
        if p~=Player and p.Character and p.Character:FindFirstChild(AimbotSettings.AimPart) then
            local sp,on = Camera:WorldToScreenPoint(p.Character[AimbotSettings.AimPart].Position)
            if on then
                local d = (Vector2.new(Mouse.X,Mouse.Y)-Vector2.new(sp.X,sp.Y)).Magnitude
                if d<closestDist then closest, closestDist = p, d end
            end
        end
    end
    return closest
end

RunService.RenderStepped:Connect(function()
    if not aimbotEnabled or (AimbotSettings.OnlyGun and not hasGun()) or not Player.Character then return end
    local t = getClosest()
    if t and t.Character and t.Character:FindFirstChild(AimbotSettings.AimPart) then
        local targetPos = t.Character[AimbotSettings.AimPart].Position
        local newCFrame = CFrame.new(Camera.CFrame.Position, targetPos)
        Camera.CFrame = Camera.CFrame:Lerp(newCFrame, AimbotSettings.Smoothness)
    end
end)

local function CheckWeapon(p)
    if not p or not p.Character then return end
    local t = p.Character:FindFirstChildOfClass("Tool") or p.Backpack:FindFirstChildOfClass("Tool")
    if t then
        local n = t.Name:lower()
        if n:find("knife") or n:find("нож") then
            playerColors[p] = "Murderer"
        elseif n:find("gun") or n:find("pistol") or n:find("пистолет") or n:find("revolver") then
            playerColors[p] = "Sheriff"
        elseif not playerColors[p] then
            playerColors[p] = "Innocent"
        end
    elseif not playerColors[p] then
        playerColors[p] = "Innocent"
    end
    local h = p.Character:FindFirstChild("FantiESP")
    if h then
        local c = playerColors[p]
        h.FillColor = c=="Innocent" and Color3.fromRGB(0,255,0) or c=="Sheriff" and Color3.fromRGB(0,0,255) or Color3.fromRGB(255,0,0)
    end
end

local function CreateESP(p)
    if p==Player or not p.Character then return end
    if not playerColors[p] then playerColors[p] = "Innocent" end
    local h = Instance.new("Highlight")
    h.Name = "FantiESP"
    h.FillColor = Color3.fromRGB(0,255,0)
    h.OutlineColor = Color3.fromRGB(255,255,255)
    h.FillTransparency = 0.5
    h.OutlineTransparency = 0
    h.Parent = p.Character
    CheckWeapon(p)
    return h
end

local function RemoveAllESP()
    for _,p in pairs(Players:GetPlayers()) do
        if p.Character then
            local h = p.Character:FindFirstChild("FantiESP")
            if h then h:Destroy() end
        end
    end
end

local function ClearAllConnections()
    for _,v in pairs(espConnections) do pcall(function() v:Disconnect() end) end
    espConnections = {}
    playerColors = {}
    if heartbeatConnection then heartbeatConnection:Disconnect(); heartbeatConnection=nil end
    for _,c in pairs(characterAddedConnections) do c:Disconnect() end
    characterAddedConnections = {}
end

local function SetupPlayerESP(p)
    if p==Player then return end
    local function onCharAdded(c)
        if espEnabled then
            local h = c:FindFirstChild("FantiESP")
            if not h then
                h = CreateESP(p)
                if h then table.insert(espConnections, h) end
            end
            CheckWeapon(p)
        end
    end
    if p.Character then onCharAdded(p.Character) end
    table.insert(characterAddedConnections, p.CharacterAdded:Connect(onCharAdded))
end

-- ===== HANDLERS =====
AimbotBtn.MouseButton1Click:Connect(function()
    aimbotEnabled = not aimbotEnabled
    AimbotBtn.BackgroundColor3 = aimbotEnabled and Color3.fromRGB(0,200,0) or Color3.fromRGB(60,60,60)
    AimbotBtn.BorderColor3 = aimbotEnabled and Color3.fromRGB(0,255,0) or Color3.fromRGB(255,255,255)
    updateFOV()
end)

AimbotBtn.MouseButton2Click:Connect(function()
    FOVSlider.Visible = not FOVSlider.Visible
    if FOVSlider.Visible then
        local pos = AimbotBtn.AbsolutePosition
        local size = AimbotBtn.AbsoluteSize
        FOVSlider.Position = UDim2.new(0, pos.X+size.X/2-110, 0, pos.Y+size.Y+5)
        local p = (AimbotSettings.FOV-50)/450
        SliderFill.Size = UDim2.new(p,0,1,0)
        SliderThumb.Position = UDim2.new(p,-8,0.5,-8)
        SliderLabel.Text = "FOV: "..AimbotSettings.FOV
        FOVVal.Text = AimbotSettings.FOV
        ShowFOVBtn.Text = AimbotSettings.ShowFOV and "☑ Show FOV" or "☐ Show FOV"
    end
end)

ESPBtn.MouseButton1Click:Connect(function()
    espEnabled = not espEnabled
    ESPBtn.BackgroundColor3 = espEnabled and Color3.fromRGB(0,200,0) or Color3.fromRGB(60,60,60)
    ESPBtn.BorderColor3 = espEnabled and Color3.fromRGB(0,255,0) or Color3.fromRGB(255,255,255)
    if espEnabled then
        playerColors = {}
        for _,p in pairs(Players:GetPlayers()) do SetupPlayerESP(p) end
        table.insert(espConnections, Players.PlayerAdded:Connect(SetupPlayerESP))
        table.insert(espConnections, Players.PlayerRemoving:Connect(function(p)
            if p.Character then
                local h = p.Character:FindFirstChild("FantiESP")
                if h then h:Destroy() end
            end
            playerColors[p] = nil
        end))
        if heartbeatConnection then heartbeatConnection:Disconnect(); heartbeatConnection=nil end
        heartbeatConnection = RunService.Heartbeat:Connect(function()
            if espEnabled then
                for _,p in pairs(Players:GetPlayers()) do
                    if p~=Player and p.Character then
                        if not p.Character:FindFirstChild("FantiESP") then
                            local h = CreateESP(p)
                            if h then table.insert(espConnections, h) end
                        end
                        CheckWeapon(p)
                    end
                end
            end
        end)
    else
        ClearAllConnections()
        RemoveAllESP()
    end
end)

StatsBtn.MouseButton1Click:Connect(function()
    statsEnabled = not statsEnabled
    StatsBtn.BackgroundColor3 = statsEnabled and Color3.fromRGB(0,200,0) or Color3.fromRGB(60,60,60)
    StatsBtn.BorderColor3 = statsEnabled and Color3.fromRGB(0,255,0) or Color3.fromRGB(255,255,255)
    StatsFrame.Visible = statsEnabled
end)

StatsBtn.MouseButton2Click:Connect(function()
    StatsSelect.Visible = not StatsSelect.Visible
    if StatsSelect.Visible then
        local pos = StatsBtn.AbsolutePosition
        local size = StatsBtn.AbsoluteSize
        StatsSelect.Position = UDim2.new(0, pos.X+size.X/2-75, 0, pos.Y+size.Y+5)
    end
end)

ResetBtn.MouseButton1Click:Connect(function()
    if espEnabled then
        for _,p in pairs(Players:GetPlayers()) do
            if p~=Player and p.Character then
                playerColors[p] = "Innocent"
                local h = p.Character:FindFirstChild("FantiESP")
                if h then h.FillColor = Color3.fromRGB(0,255,0) end
            end
        end
    end
    ResetBtn.BackgroundColor3 = Color3.fromRGB(0,200,0)
    ResetBtn.BorderColor3 = Color3.fromRGB(0,255,0)
    task.wait(0.2)
    ResetBtn.BackgroundColor3 = Color3.fromRGB(60,60,60)
    ResetBtn.BorderColor3 = Color3.fromRGB(255,255,255)
end)

UnloadBtn.MouseButton1Click:Connect(function()
    if espEnabled then
        ClearAllConnections()
        RemoveAllESP()
    end
    ScreenGui:Destroy()
end)

local function ToggleMenu()
    MainFrame.Visible = not MainFrame.Visible
end

OpenBtn.MouseButton1Click:Connect(ToggleMenu)
UserInputService.InputBegan:Connect(function(i)
    if i.KeyCode == Enum.KeyCode.RightShift then ToggleMenu() end
end)

-- ===== DRAGGING =====
local dragData = {isDragging=false, start=nil, startPos=nil}
OpenBtn.InputBegan:Connect(function(i)
    if i.UserInputType == Enum.UserInputType.MouseButton1 then
        dragData.isDragging = true
        dragData.start = i.Position
        dragData.startPos = OpenBtn.Position
    end
end)
OpenBtn.InputEnded:Connect(function() dragData.isDragging = false end)
UserInputService.InputChanged:Connect(function(i)
    if dragData.isDragging and i.UserInputType == Enum.UserInputType.MouseMovement then
        local d = i.Position - dragData.start
        local vx, vy = Camera.ViewportSize.X or 1920, Camera.ViewportSize.Y or 1080
        local nx = math.max(0, math.min(1-50/vx, (dragData.startPos.X.Scale*vx + dragData.startPos.X.Offset + d.X)/vx))
        local ny = math.max(0, math.min(1-50/vy, (dragData.startPos.Y.Scale*vy + dragData.startPos.Y.Offset + d.Y)/vy))
        OpenBtn.Position = UDim2.new(nx,0,ny,0)
    end
end)

local menuDrag = {isDragging=false, start=nil, startPos=nil}
MainFrame.InputBegan:Connect(function(i)
    if i.UserInputType == Enum.UserInputType.MouseButton1 and i.Position.Y > 0 and i.Position.Y < 70 then
        menuDrag.isDragging = true
        menuDrag.start = i.Position
        menuDrag.startPos = MainFrame.Position
    end
end)
MainFrame.InputEnded:Connect(function() menuDrag.isDragging = false end)
UserInputService.InputChanged:Connect(function(i)
    if menuDrag.isDragging and i.UserInputType == Enum.UserInputType.MouseMovement then
        local d = i.Position - menuDrag.start
        local vx, vy = Camera.ViewportSize.X or 1920, Camera.ViewportSize.Y or 1080
        local nx = math.max(0, math.min(1-480/vx, (menuDrag.startPos.X.Scale*vx + menuDrag.startPos.X.Offset + d.X)/vx))
        local ny = math.max(0, math.min(1-420/vy, (menuDrag.startPos.Y.Scale*vy + menuDrag.startPos.Y.Offset + d.Y)/vy))
        MainFrame.Position = UDim2.new(nx,0,ny,0)
    end
end)

print("FantiHub loaded! Press Right Shift to toggle menu")