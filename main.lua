-- XuKrost Hub | Enhanced Edition v4.7 (Config System Update)
-- Updated by AI Assistant

-- Services
local Players = game:GetService("Players")
local TweenService = game:GetService("TweenService")
local StarterGui = game:GetService("StarterGui")
local UserInputService = game:GetService("UserInputService")
local HttpService = game:GetService("HttpService")
local RunService = game:GetService("RunService")
local CoreGui = game:GetService("CoreGui")
local Lighting = game:GetService("Lighting")
local VirtualInputManager = game:GetService("VirtualInputManager")
local Workspace = game:GetService("Workspace")
local GuiService = game:GetService("GuiService")

local player = Players.LocalPlayer
local mouse = player:GetMouse()

-- CONFIG
local HubName = "XuKrost Hub"
local CreatorText = "noirexe"
local Version = "v4.8 Updated"

-- URL Configurations
local VIP_MODULE_URL = "https://raw.githubusercontent.com/xhub-ui/x-loaders-directly/refs/heads/main/helper-settings/utils/vip_helper.lua" 
local KEY_LIST_URL = "https://raw.githubusercontent.com/xhub-ui/x-loaders-directly/refs/heads/main/main-settings/direct-url-settings/key.txt"
local HELPER_URL = "https://raw.githubusercontent.com/xhub-ui/x-loaders-directly/refs/heads/main/helper-settings/utils/helper.lua" 

-- :: VIP SETTINGS ::
local VIP_MODE = "txt" -- Select Mode: "json" or "txt" 

-- Variables
local isVIP = false
local keyAuthorized = false
local infJumpEnabled = false
local afkEnabled = false

-- :: STATE MANAGEMENT (NEW) ::
local CurrentConfig = {
    UI = {
        Position = {X = 0.5, Y = 0.5}, -- Scale
        Theme = {R = 65, G = 120, B = 200},
        LastTab = "Main Scripts"
    },
    Features = {
        AntiAFK = false,
        InfJump = false,
        WalkSpeed = 16,
        JumpPower = 50,
        RTXPreset = nil
    }
}

-- Theme System Variables
local ThemeObjects = {} 
local RainbowConnection = nil
local UI_COLOR = Color3.fromRGB(65, 120, 200) 
local BG_COLOR = Color3.fromRGB(20, 20, 25) 
local SIDEBAR_COLOR = Color3.fromRGB(30, 30, 35)
local CARD_COLOR = Color3.fromRGB(35, 35, 40)
local TEXT_COLOR = Color3.fromRGB(240, 240, 240)
local SEPARATOR_COLOR = Color3.fromRGB(50, 50, 60)

-- Utility Functions

-- :: THEME REGISTRY SYSTEM ::
local function RegisterTheme(instance, property)
    table.insert(ThemeObjects, {Object = instance, Property = property})
    if instance and instance[property] then
        instance[property] = UI_COLOR
    end
end

local function UpdateAllTheme(newColor)
    UI_COLOR = newColor
    -- Update Config State
    CurrentConfig.UI.Theme.R = math.floor(newColor.R * 255)
    CurrentConfig.UI.Theme.G = math.floor(newColor.G * 255)
    CurrentConfig.UI.Theme.B = math.floor(newColor.B * 255)
    
    for _, item in pairs(ThemeObjects) do
        if item.Object then
            pcall(function()
                item.Object[item.Property] = newColor
            end)
        end
    end
end
-- :::::::::::::::::::::::::::

local function notify(title, text, duration)
    StarterGui:SetCore("SendNotification", {
        Title = title, Text = text, Icon = "rbxassetid://127523276881123", Duration = duration or 3
    })
end

local function httpGet(url)
    local ok, res = pcall(function() return game:HttpGet(url, true) end)
    if ok and res then return true, res end
    return false, "Connection Error"
end

local function copyToClipboard(text)
    local success = pcall(function() setclipboard(text) end)
    return success
end

local function makeDraggable(frame)
    local dragging, dragInput, dragStart, startPos
    frame.InputBegan:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
            dragging = true
            dragStart = input.Position
            startPos = frame.Position
            input.Changed:Connect(function()
                if input.UserInputState == Enum.UserInputState.End then 
                    dragging = false 
                    -- Save Position to Config State on Drag End
                    CurrentConfig.UI.Position.X = frame.Position.X.Scale
                    CurrentConfig.UI.Position.Y = frame.Position.Y.Scale
                end
            end)
        end
    end)
    frame.InputChanged:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseMovement or input.UserInputType == Enum.UserInputType.Touch then
            dragInput = input
        end
    end)
    UserInputService.InputChanged:Connect(function(input)
        if input == dragInput and dragging then
            local delta = input.Position - dragStart
            TweenService:Create(frame, TweenInfo.new(0.1), {Position = UDim2.new(startPos.X.Scale, startPos.X.Offset + delta.X, startPos.Y.Scale, startPos.Y.Offset + delta.Y)}):Play()
        end
    end)
end

local function createCorner(parent, radius)
    local corner = Instance.new("UICorner", parent)
    corner.CornerRadius = UDim.new(0, radius or 6)
    return corner
end

local function createStroke(parent, color, thickness)
    local stroke = Instance.new("UIStroke", parent)
    stroke.Color = color or Color3.fromRGB(60,60,60)
    stroke.Thickness = thickness or 1
    return stroke
end

local function createGradient(parent, c1, c2)
    local grad = Instance.new("UIGradient", parent)
    grad.Color = ColorSequence.new{
        ColorSequenceKeypoint.new(0, c1 or Color3.fromRGB(45, 45, 55)),
        ColorSequenceKeypoint.new(1, c2 or Color3.fromRGB(35, 35, 40))
    }
    grad.Rotation = 45
    return grad
end

-- DATE HELPER FUNCTIONS
local function getCurrentDate()
    local currentTime = os.date("*t")
    return string.format("%02d/%02d/%04d", currentTime.day, currentTime.month, currentTime.year)
end

local function getCurrentTime()
    return os.date("%X")
end

-- --- SYSTEM CHECKS (Updated) ---
local function checkVIP()
    local success, Module = pcall(function()
        return loadstring(game:HttpGet(VIP_MODULE_URL))()
    end)

    if success and Module and Module.CheckIsVIP then
        return Module.CheckIsVIP(player, VIP_MODE)
    else
        warn("Gagal memuat VIP Module. Cek URL VIP_MODULE_URL.")
    end
    
    return false
end

local function checkKey(inputKey)
    local success, data = pcall(function() return game:HttpGet(KEY_LIST_URL, true) end)
    if success then
        for line in data:gmatch("[^\r\n]+") do
            if line:gsub("%s+", "") == inputKey:gsub("%s+", "") then return true end
        end
    end
    return false
end

-- --- INFINITE JUMP LOGIC ---
UserInputService.JumpRequest:Connect(function()
    if infJumpEnabled and player.Character and player.Character:FindFirstChild("Humanoid") then
        player.Character.Humanoid:ChangeState("Jumping")
    end
end)

-- --- ACRYLIC BLUR MANIPULATION ---
local GlobalBlur = Instance.new("BlurEffect")
GlobalBlur.Name = "XuKrostBlur"
GlobalBlur.Size = 0
GlobalBlur.Parent = Lighting

local function ToggleBlur(state)
    TweenService:Create(GlobalBlur, TweenInfo.new(0.5), {Size = state and 20 or 0}):Play()
end

-- --- GUI CONSTRUCTION ---

if game.CoreGui:FindFirstChild("XuKrostHub_UI") then
    game.CoreGui.XuKrostHub_UI:Destroy()
end

for _, v in pairs(Lighting:GetChildren()) do
    if v.Name == "XuKrostBlur" and v ~= GlobalBlur then v:Destroy() end
end

local ScreenGui = Instance.new("ScreenGui")
ScreenGui.Name = "XuKrostHub_UI"
ScreenGui.Parent = game.CoreGui
ScreenGui.ResetOnSpawn = false
ScreenGui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling

-- :: KEY SYSTEM GUI ::
local function spawnKeySystem(onSuccess)
    ToggleBlur(true)
    local KeyFrame = Instance.new("Frame", ScreenGui)
    KeyFrame.Size = UDim2.fromOffset(320, 180)
    KeyFrame.Position = UDim2.fromScale(0.5, 0.5)
    KeyFrame.AnchorPoint = Vector2.new(0.5, 0.5)
    KeyFrame.BackgroundColor3 = BG_COLOR
    KeyFrame.BackgroundTransparency = 0.1
    createCorner(KeyFrame, 10)
    local ksStroke = createStroke(KeyFrame, UI_COLOR, 2)
    RegisterTheme(ksStroke, "Color") 
    makeDraggable(KeyFrame)

    local Title = Instance.new("TextLabel", KeyFrame)
    Title.Size = UDim2.new(1, 0, 0, 40)
    Title.BackgroundTransparency = 1
    Title.Text = "SECURITY CHECK"
    Title.Font = Enum.Font.GothamBold
    Title.TextColor3 = UI_COLOR
    RegisterTheme(Title, "TextColor3") 
    Title.TextSize = 16

    local InputBox = Instance.new("TextBox", KeyFrame)
    InputBox.Size = UDim2.new(0.8, 0, 0, 35)
    InputBox.Position = UDim2.new(0.1, 0, 0.35, 0)
    InputBox.BackgroundColor3 = SIDEBAR_COLOR
    InputBox.PlaceholderText = "Enter Key Here..."
    InputBox.Text = ""
    InputBox.TextColor3 = TEXT_COLOR
    InputBox.Font = Enum.Font.Gotham
    InputBox.TextSize = 12
    createCorner(InputBox, 6)

    local SubmitBtn = Instance.new("TextButton", KeyFrame)
    SubmitBtn.Size = UDim2.new(0.35, 0, 0, 30)
    SubmitBtn.Position = UDim2.new(0.1, 0, 0.65, 0)
    SubmitBtn.BackgroundColor3 = Color3.fromRGB(46, 139, 87)
    SubmitBtn.Text = "SUBMIT"
    SubmitBtn.TextColor3 = Color3.new(1,1,1)
    SubmitBtn.Font = Enum.Font.GothamBold
    SubmitBtn.TextSize = 12
    createCorner(SubmitBtn, 6)

    local GetKeyBtn = Instance.new("TextButton", KeyFrame)
    GetKeyBtn.Size = UDim2.new(0.35, 0, 0, 30)
    GetKeyBtn.Position = UDim2.new(0.55, 0, 0.65, 0)
    GetKeyBtn.BackgroundColor3 = Color3.fromRGB(100, 100, 100)
    GetKeyBtn.Text = "GET KEY"
    GetKeyBtn.TextColor3 = Color3.new(1,1,1)
    GetKeyBtn.Font = Enum.Font.GothamBold
    GetKeyBtn.TextSize = 12
    createCorner(GetKeyBtn, 6)

    local StatusTxt = Instance.new("TextLabel", KeyFrame)
    StatusTxt.Size = UDim2.new(1, 0, 0, 20)
    StatusTxt.Position = UDim2.new(0, 0, 0.85, 0)
    StatusTxt.BackgroundTransparency = 1
    StatusTxt.Text = ""
    StatusTxt.Font = Enum.Font.Gotham
    StatusTxt.TextSize = 10
    StatusTxt.TextColor3 = Color3.fromRGB(255, 100, 100)

    GetKeyBtn.MouseButton1Click:Connect(function()
        copyToClipboard("https://discord.gg/RpYcMdzzwd") 
        StatusTxt.Text = "Link copied to clipboard!"
        StatusTxt.TextColor3 = Color3.fromRGB(255, 255, 0)
    end)

    SubmitBtn.MouseButton1Click:Connect(function()
        StatusTxt.Text = "Checking..."
        task.wait(0.5)
        if checkKey(InputBox.Text) then
            StatusTxt.Text = "Success!"
            StatusTxt.TextColor3 = Color3.fromRGB(100, 255, 100)
            task.wait(0.5)
            KeyFrame:Destroy()
            onSuccess()
        else
            StatusTxt.Text = "Invalid Key"
            StatusTxt.TextColor3 = Color3.fromRGB(255, 50, 50)
        end
    end)
end

-- :: MAIN HUB GUI ::
local function spawnMainHub()
    ToggleBlur(true)
    
    -- =================================================================
    -- :: INTEGRATED NETRO RTX LOGIC (Hidden from Global Scope) ::
    -- =================================================================
    
    local function clearWeatherEffects()
        local rainFolder = Workspace:FindFirstChild("NetroRain")
        if rainFolder then rainFolder:Destroy() end
        
        local snowFolder = Workspace:FindFirstChild("NetroSnow")
        if snowFolder then snowFolder:Destroy() end
        
        for _, sound in pairs(Workspace:GetDescendants()) do
            if sound:IsA("Sound") and (sound.Name == "RainSound" or sound.Name == "SnowSound") then
                sound:Stop()
                sound:Destroy()
            end
        end
    end

    local function createRainEffect()
        clearWeatherEffects()
        task.wait(0.1)
        
        local rainFolder = Instance.new("Folder", Workspace)
        rainFolder.Name = "NetroRain"
        
        for i = 1, 15 do
            local rainPart = Instance.new("Part", rainFolder)
            rainPart.Name = "RainEmitter" .. i
            rainPart.Size = Vector3.new(1, 1, 1)
            rainPart.Transparency = 1
            rainPart.CanCollide = false
            rainPart.Anchored = true
            
            local angle = (i - 1) * (360 / 15)
            local radius = 80
            local offsetX = math.cos(math.rad(angle)) * radius
            local offsetZ = math.sin(math.rad(angle)) * radius
            
            task.spawn(function()
                while rainPart and rainPart.Parent do
                    if player.Character and player.Character:FindFirstChild("HumanoidRootPart") then
                        local playerPos = player.Character.HumanoidRootPart.Position
                        rainPart.Position = playerPos + Vector3.new(offsetX, 100, offsetZ)
                    end
                    task.wait(0.5)
                end
            end)
            
            local rainParticle = Instance.new("ParticleEmitter", rainPart)
            rainParticle.Texture = "rbxasset://textures/particles/smoke_main.dds"
            rainParticle.Rate = 300
            rainParticle.Lifetime = NumberRange.new(3, 4)
            rainParticle.Speed = NumberRange.new(80, 100)
            rainParticle.Transparency = NumberSequence.new({NumberSequenceKeypoint.new(0, 0.3), NumberSequenceKeypoint.new(1, 0.8)})
            rainParticle.Color = ColorSequence.new(Color3.new(0.7, 0.8, 1))
            rainParticle.Acceleration = Vector3.new(0, -100, 0)
            rainParticle.EmissionDirection = Enum.NormalId.Bottom
        end
        
        local rainSound = Instance.new("Sound", rainFolder)
        rainSound.Name = "RainSound"
        rainSound.SoundId = "rbxassetid://3634328841"
        rainSound.Volume = 0.3
        rainSound.Looped = true
        rainSound:Play()
    end

    local function createSnowEffect()
        clearWeatherEffects()
        task.wait(0.1)
        
        local snowFolder = Instance.new("Folder", Workspace)
        snowFolder.Name = "NetroSnow"
        
        for i = 1, 12 do
            local snowPart = Instance.new("Part", snowFolder)
            snowPart.Name = "SnowEmitter" .. i
            snowPart.Size = Vector3.new(1, 1, 1)
            snowPart.Transparency = 1
            snowPart.CanCollide = false
            snowPart.Anchored = true
            
            local angle = (i - 1) * (360 / 12)
            local radius = 70
            local offsetX = math.cos(math.rad(angle)) * radius
            local offsetZ = math.sin(math.rad(angle)) * radius
            
            task.spawn(function()
                while snowPart and snowPart.Parent do
                    if player.Character and player.Character:FindFirstChild("HumanoidRootPart") then
                        local playerPos = player.Character.HumanoidRootPart.Position
                        snowPart.Position = playerPos + Vector3.new(offsetX, 80, offsetZ)
                    end
                    task.wait(0.5)
                end
            end)
            
            local snowParticle = Instance.new("ParticleEmitter", snowPart)
            snowParticle.Texture = "rbxasset://textures/particles/sparkles_main.dds"
            snowParticle.Rate = 150
            snowParticle.Lifetime = NumberRange.new(8, 12)
            snowParticle.Speed = NumberRange.new(5, 10)
            snowParticle.Size = NumberSequence.new({NumberSequenceKeypoint.new(0, 0.3), NumberSequenceKeypoint.new(1, 0.2)})
            snowParticle.Transparency = NumberSequence.new({NumberSequenceKeypoint.new(0, 0.1), NumberSequenceKeypoint.new(1, 1)})
            snowParticle.Acceleration = Vector3.new(math.random(-5, 5), -8, math.random(-5, 5))
            snowParticle.EmissionDirection = Enum.NormalId.Bottom
        end
    end

    local function applyRTXEffects()
        Lighting.Technology = Enum.Technology.ShadowMap
        Lighting.GlobalShadows = true
        
        -- Clean existing RTX
        for _, child in pairs(Lighting:GetChildren()) do
            if child:IsA("BloomEffect") or child:IsA("ColorCorrectionEffect") or 
               child:IsA("SunRaysEffect") or child:IsA("DepthOfFieldEffect") or child:IsA("Atmosphere") then
                child:Destroy()
            end
        end

        local atmosphere = Instance.new("Atmosphere", Lighting)
        atmosphere.Density = 0.35
        atmosphere.Offset = 0.25
        atmosphere.Color = Color3.new(0.8, 0.85, 0.95)
        atmosphere.Decay = Color3.new(0.4, 0.5, 0.75)
        atmosphere.Glare = 0.2
        atmosphere.Haze = 1.8
        
        local bloom = Instance.new("BloomEffect", Lighting)
        bloom.Intensity = 0.6
        bloom.Size = 48
        bloom.Threshold = 0.7
        
        local colorCorrect = Instance.new("ColorCorrectionEffect", Lighting)
        colorCorrect.Saturation = 0.25
        colorCorrect.Contrast = 0.1
        colorCorrect.Brightness = 0.05
        colorCorrect.TintColor = Color3.new(1.02, 1.01, 1.0)
        
        local sunRays = Instance.new("SunRaysEffect", Lighting)
        sunRays.Intensity = 0.3
        sunRays.Spread = 0.5
        
        -- Depth of Field (No Player Blur)
        local depthOfField = Instance.new("DepthOfFieldEffect", Lighting)
        depthOfField.FarIntensity = 0.03
        depthOfField.FocusDistance = 150
        depthOfField.InFocusRadius = 80
        depthOfField.NearIntensity = 0
        
        task.spawn(function()
            while task.wait(0.5) do
                if player.Character and player.Character:FindFirstChild("HumanoidRootPart") and depthOfField.Parent then
                    local camera = Workspace.CurrentCamera
                    if camera then
                        local dist = (player.Character.HumanoidRootPart.Position - camera.CFrame.Position).Magnitude
                        depthOfField.FocusDistance = math.max(dist + 20, 50)
                    end
                end
            end
        end)
    end

    local function enhancePartsWithRTX()
        task.spawn(function()
            for _, obj in pairs(Workspace:GetDescendants()) do
                if obj:IsA("BasePart") then
                    if obj.Material == Enum.Material.Plastic then
                        obj.Material = Enum.Material.SmoothPlastic
                    end
                    if obj.Material == Enum.Material.Metal or obj.Material == Enum.Material.CorrodedMetal then
                        obj.Reflectance = math.min(obj.Reflectance + 0.2, 0.6)
                    end
                end
            end
        end)
    end

    local weatherPresets = {
        {name = "Moonlight", color = Color3.new(0.2, 0.3, 0.8), time = "23:00:00", sky = {bk="8139676647", dn="8139676988", ft="8139677111", lf="8139677359", rt="8139677253", up="8139677437"}},
        {name = "Sunrise", color = Color3.new(1, 0.7, 0.3), time = "06:30:00", sky = {bk="150939022", dn="150939038", ft="150939047", lf="150939056", rt="150939063", up="150939082"}},
        {name = "Sunset", color = Color3.new(1, 0.4, 0.2), time = "18:30:00", sky = {bk="323493360", dn="323493429", ft="323493571", lf="323493688", rt="323493752", up="323493871"}},
        {name = "Storm", color = Color3.new(0.3, 0.3, 0.4), time = "14:00:00", effect = createRainEffect, sky = {bk="570557620", dn="570557669", ft="570557718", lf="570557786", rt="570557848", up="570557895"}},
        {name = "Clear Day", color = Color3.new(0.5, 0.7, 1), time = "12:00:00", sky = {bk="271042516", dn="271077243", ft="271042556", lf="271042310", rt="271042467", up="271077958"}},
        {name = "Ocean Blue", color = Color3.new(0.2, 0.6, 1), time = "14:00:00", sky = {bk="153695414", dn="153695352", ft="153695457", lf="153695518", rt="153695549", up="153695581"}},
        {name = "Winter", color = Color3.new(0.7, 0.9, 1), time = "11:00:00", effect = createSnowEffect, sky = {bk="8139676647", dn="8139676988", ft="8139677111", lf="8139677359", rt="8139677253", up="8139677437"}},
        {name = "Nebula", color = Color3.new(0.8, 0.4, 1), time = "22:00:00", sky = {bk="159454299", dn="159454296", ft="159454293", lf="159454286", rt="159454300", up="159454288"}}
    }

    local function SetWeather(preset)
        clearWeatherEffects()
        Lighting.TimeOfDay = preset.time
        CurrentConfig.Features.RTXPreset = preset.name -- Save to Config
        
        if Lighting:FindFirstChild("Sky") then Lighting.Sky:Destroy() end
        
        local sky = Instance.new("Sky", Lighting)
        sky.Name = "Sky"
        sky.SkyboxBk = "rbxassetid://" .. preset.sky.bk
        sky.SkyboxDn = "rbxassetid://" .. preset.sky.dn
        sky.SkyboxFt = "rbxassetid://" .. preset.sky.ft
        sky.SkyboxLf = "rbxassetid://" .. preset.sky.lf
        sky.SkyboxRt = "rbxassetid://" .. preset.sky.rt
        sky.SkyboxUp = "rbxassetid://" .. preset.sky.up
        sky.CelestialBodiesShown = true

        if preset.effect then
            task.wait(0.2)
            preset.effect()
        end

        applyRTXEffects()
        enhancePartsWithRTX()
        notify("RTX Manager", preset.name .. " mode applied!", 2)
    end
    -- =================================================================

    local MainFrame = Instance.new("Frame", ScreenGui)
    MainFrame.Name = "MainFrame"
    MainFrame.Size = UDim2.fromOffset(550, 350)
    MainFrame.Position = UDim2.fromScale(0.5, 0.5)
    MainFrame.AnchorPoint = Vector2.new(0.5, 0.5)
    MainFrame.BackgroundColor3 = BG_COLOR
    MainFrame.BackgroundTransparency = 0.25 
    MainFrame.ClipsDescendants = true
    createCorner(MainFrame, 10)
    createStroke(MainFrame, Color3.fromRGB(40,40,40), 1)
    makeDraggable(MainFrame)

    local Shadow = Instance.new("ImageLabel", MainFrame)
    Shadow.ZIndex = -1
    Shadow.Position = UDim2.new(0, -15, 0, -15)
    Shadow.Size = UDim2.new(1, 30, 1, 30)
    Shadow.BackgroundTransparency = 1
    Shadow.Image = "rbxassetid://5554236805"
    Shadow.ImageColor3 = Color3.new(0,0,0)
    Shadow.ScaleType = Enum.ScaleType.Slice
    Shadow.SliceCenter = Rect.new(23,23,277,277)
    Shadow.ImageTransparency = 0.5

    -- Sidebar
    local Sidebar = Instance.new("Frame", MainFrame)
    Sidebar.Size = UDim2.new(0, 140, 1, 0)
    Sidebar.BackgroundColor3 = SIDEBAR_COLOR
    Sidebar.BackgroundTransparency = 0.3
    Sidebar.BorderSizePixel = 0

    local TabContainer = Instance.new("Frame", Sidebar)
    TabContainer.Size = UDim2.new(1, 0, 1, -55) 
    TabContainer.BackgroundTransparency = 1
    
    local SidebarList = Instance.new("UIListLayout", TabContainer)
    SidebarList.SortOrder = Enum.SortOrder.LayoutOrder
    SidebarList.Padding = UDim.new(0, 5)
    
    local SidebarPadding = Instance.new("UIPadding", TabContainer)
    SidebarPadding.PaddingTop = UDim.new(0, 50)
    SidebarPadding.PaddingLeft = UDim.new(0, 10)

    -- Profile Footer
    local ProfileFooter = Instance.new("Frame", Sidebar)
    ProfileFooter.Size = UDim2.new(1, 0, 0, 50)
    ProfileFooter.Position = UDim2.new(0, 0, 1, -50)
    ProfileFooter.BackgroundColor3 = Color3.fromRGB(25, 25, 30)
    ProfileFooter.BackgroundTransparency = 0.5
    
    local FooterSep = Instance.new("Frame", ProfileFooter)
    FooterSep.Size = UDim2.new(1, 0, 0, 1)
    FooterSep.Position = UDim2.new(0, 0, 0, 0)
    FooterSep.BackgroundColor3 = SEPARATOR_COLOR
    FooterSep.BorderSizePixel = 0
    FooterSep.BackgroundTransparency = 0.5

    local AvatarImg = Instance.new("ImageLabel", ProfileFooter)
    AvatarImg.Size = UDim2.new(0, 32, 0, 32)
    AvatarImg.Position = UDim2.new(0, 10, 0.5, 0)
    AvatarImg.AnchorPoint = Vector2.new(0, 0.5)
    AvatarImg.BackgroundColor3 = Color3.fromRGB(40,40,40)
    AvatarImg.BackgroundTransparency = 1
    createCorner(AvatarImg, 100) 
    local avStroke = createStroke(AvatarImg, UI_COLOR, 1) 
    RegisterTheme(avStroke, "Color")
    
    task.spawn(function()
        local content = Players:GetUserThumbnailAsync(player.UserId, Enum.ThumbnailType.HeadShot, Enum.ThumbnailSize.Size48x48)
        AvatarImg.Image = content
    end)

    local DispName = Instance.new("TextLabel", ProfileFooter)
    DispName.Size = UDim2.new(1, -50, 0, 16)
    DispName.Position = UDim2.new(0, 50, 0.3, 0)
    DispName.AnchorPoint = Vector2.new(0, 0.5)
    DispName.BackgroundTransparency = 1
    DispName.Text = player.DisplayName
    DispName.TextColor3 = Color3.new(1,1,1)
    DispName.Font = Enum.Font.GothamBold
    DispName.TextSize = 11
    DispName.TextXAlignment = Enum.TextXAlignment.Left
    DispName.TextTruncate = Enum.TextTruncate.AtEnd

    local UserIdLbl = Instance.new("TextLabel", ProfileFooter)
    UserIdLbl.Size = UDim2.new(1, -50, 0, 14)
    UserIdLbl.Position = UDim2.new(0, 50, 0.65, 0)
    UserIdLbl.AnchorPoint = Vector2.new(0, 0.5)
    UserIdLbl.BackgroundTransparency = 1
    UserIdLbl.Text = "ID: " .. player.UserId
    UserIdLbl.TextColor3 = Color3.fromRGB(150, 150, 150)
    UserIdLbl.Font = Enum.Font.Code
    UserIdLbl.TextSize = 9
    UserIdLbl.TextXAlignment = Enum.TextXAlignment.Left

    -- Title Frame
    local TitleFrame = Instance.new("Frame", MainFrame)
    TitleFrame.Size = UDim2.new(1, 0, 0, 40)
    TitleFrame.BackgroundTransparency = 1
    TitleFrame.ZIndex = 2
    
    local TitleLabel = Instance.new("TextLabel", TitleFrame)
    TitleLabel.Position = UDim2.new(0, 15, 0, 0)
    TitleLabel.Size = UDim2.new(0, 125, 1, 0)
    TitleLabel.BackgroundTransparency = 1
    TitleLabel.Text = HubName
    TitleLabel.Font = Enum.Font.GothamBlack
    TitleLabel.TextXAlignment = Enum.TextXAlignment.Left
    TitleLabel.TextSize = 16
    TitleLabel.TextColor3 = UI_COLOR
    RegisterTheme(TitleLabel, "TextColor3") 

    local VerLabel = Instance.new("TextLabel", TitleFrame)
    VerLabel.Position = UDim2.new(0, 155, 0, 2)
    VerLabel.Size = UDim2.new(0, 100, 1, 0)
    VerLabel.BackgroundTransparency = 1
    VerLabel.Text = Version
    VerLabel.Font = Enum.Font.Code
    VerLabel.TextXAlignment = Enum.TextXAlignment.Left
    VerLabel.TextSize = 10
    VerLabel.TextColor3 = Color3.fromRGB(150,150,150)

    -- SEPARATORS
    local SepH = Instance.new("Frame", MainFrame)
    SepH.Size = UDim2.new(1, 0, 0, 1)
    SepH.Position = UDim2.new(0, 0, 0, 40)
    SepH.BackgroundColor3 = SEPARATOR_COLOR
    SepH.BackgroundTransparency = 0.5
    SepH.BorderSizePixel = 0
    SepH.ZIndex = 3

    local SepV = Instance.new("Frame", TitleFrame)
    SepV.Size = UDim2.new(0, 1, 0, 24)
    SepV.Position = UDim2.new(0, 140, 0.5, 0)
    SepV.AnchorPoint = Vector2.new(0.5, 0.5)
    SepV.BackgroundColor3 = SEPARATOR_COLOR
    SepV.BackgroundTransparency = 0.5
    SepV.BorderSizePixel = 0

    -- Controls
    local ControlFrame = Instance.new("Frame", TitleFrame)
    ControlFrame.Size = UDim2.new(0, 60, 1, 0)
    ControlFrame.Position = UDim2.new(1, -65, 0, 0)
    ControlFrame.BackgroundTransparency = 1

    local function createControlBtn(text, color, pos)
        local btn = Instance.new("TextButton", ControlFrame)
        btn.Size = UDim2.new(0, 25, 0, 25)
        btn.Position = pos
        btn.AnchorPoint = Vector2.new(0, 0.5)
        btn.BackgroundColor3 = color
        btn.Text = text
        btn.TextColor3 = Color3.new(1,1,1)
        btn.Font = Enum.Font.GothamBold
        btn.TextSize = 14
        createCorner(btn, 4)
        return btn
    end

    local MinBtn = createControlBtn("-", Color3.fromRGB(60,60,80), UDim2.new(0,0,0.5,0))
    local CloseBtn = createControlBtn("X", Color3.fromRGB(180,60,60), UDim2.new(0,30,0.5,0))

    -- Bubble
    local Bubble = Instance.new("TextButton", ScreenGui)
    Bubble.Size = UDim2.fromOffset(50, 50)
    Bubble.Position = UDim2.new(0.1, 0, 0.1, 0)
    Bubble.BackgroundColor3 = UI_COLOR
    Bubble.Text = "XH"
    Bubble.TextColor3 = Color3.new(1,1,1)
    Bubble.Font = Enum.Font.GothamBlack
    Bubble.TextSize = 18
    Bubble.Visible = false
    createCorner(Bubble, 25)
    createStroke(Bubble, Color3.new(1,1,1), 2)
    RegisterTheme(Bubble, "BackgroundColor3") 
    makeDraggable(Bubble)

    -- [MODAL: CONFIRMATION]
    local ConfirmOverlay = Instance.new("Frame", ScreenGui)
    ConfirmOverlay.Name = "ConfirmationOverlay"
    ConfirmOverlay.Size = UDim2.fromScale(1, 1)
    ConfirmOverlay.BackgroundColor3 = Color3.new(0,0,0)
    ConfirmOverlay.BackgroundTransparency = 0.6
    ConfirmOverlay.Visible = false
    ConfirmOverlay.ZIndex = 100 
    ConfirmOverlay.Active = true 

    local ConfirmFrame = Instance.new("Frame", ConfirmOverlay)
    ConfirmFrame.Size = UDim2.fromOffset(300, 140)
    ConfirmFrame.Position = UDim2.fromScale(0.5, 0.5)
    ConfirmFrame.AnchorPoint = Vector2.new(0.5, 0.5)
    ConfirmFrame.BackgroundColor3 = BG_COLOR
    createCorner(ConfirmFrame, 12)
    local cmStroke = createStroke(ConfirmFrame, UI_COLOR, 2)
    RegisterTheme(cmStroke, "Color")

    local ConfirmTitle = Instance.new("TextLabel", ConfirmFrame)
    ConfirmTitle.Size = UDim2.new(1, 0, 0, 40)
    ConfirmTitle.BackgroundTransparency = 1
    ConfirmTitle.Text = "EXIT CONFIRMATION"
    ConfirmTitle.Font = Enum.Font.GothamBlack
    ConfirmTitle.TextSize = 16
    ConfirmTitle.TextColor3 = Color3.new(1,1,1)

    local ConfirmDesc = Instance.new("TextLabel", ConfirmFrame)
    ConfirmDesc.Size = UDim2.new(1, -20, 0, 40)
    ConfirmDesc.Position = UDim2.new(0, 10, 0, 40)
    ConfirmDesc.BackgroundTransparency = 1
    ConfirmDesc.Text = "Are you sure you want to close the hub? You will need to re-execute it."
    ConfirmDesc.Font = Enum.Font.Gotham
    ConfirmDesc.TextSize = 12
    ConfirmDesc.TextColor3 = Color3.fromRGB(200,200,200)
    ConfirmDesc.TextWrapped = true

    local BtnContainer = Instance.new("Frame", ConfirmFrame)
    BtnContainer.Size = UDim2.new(1, -20, 0, 35)
    BtnContainer.Position = UDim2.new(0, 10, 1, -45)
    BtnContainer.BackgroundTransparency = 1

    local NoBtn = Instance.new("TextButton", BtnContainer)
    NoBtn.Size = UDim2.new(0.48, 0, 1, 0)
    NoBtn.BackgroundColor3 = Color3.fromRGB(50, 50, 55)
    NoBtn.Text = "No"
    NoBtn.TextColor3 = Color3.new(1,1,1)
    NoBtn.Font = Enum.Font.GothamBold
    NoBtn.TextSize = 12
    createCorner(NoBtn, 6)

    local YesBtn = Instance.new("TextButton", BtnContainer)
    YesBtn.Size = UDim2.new(0.48, 0, 1, 0)
    YesBtn.Position = UDim2.new(0.52, 0, 0, 0)
    YesBtn.BackgroundColor3 = UI_COLOR
    YesBtn.Text = "Yes"
    YesBtn.TextColor3 = Color3.new(1,1,1)
    YesBtn.Font = Enum.Font.GothamBold
    YesBtn.TextSize = 12
    createCorner(YesBtn, 6)
    RegisterTheme(YesBtn, "BackgroundColor3")

    NoBtn.MouseButton1Click:Connect(function() ConfirmOverlay.Visible = false end)
    YesBtn.MouseButton1Click:Connect(function()
        ToggleBlur(false)
        GlobalBlur:Destroy()
        clearWeatherEffects() -- Clean RTX
        afkEnabled = false
        if RainbowConnection then RainbowConnection:Disconnect() end
        ScreenGui:Destroy()
    end)

    -- [MODAL: THEME SETTINGS]
    local ThemeOverlay = Instance.new("Frame", ScreenGui)
    ThemeOverlay.Name = "ThemeOverlay"
    ThemeOverlay.Size = UDim2.fromScale(1, 1)
    ThemeOverlay.BackgroundColor3 = Color3.new(0,0,0)
    ThemeOverlay.BackgroundTransparency = 0.6
    ThemeOverlay.Visible = false
    ThemeOverlay.ZIndex = 101 -- Higher than everything
    ThemeOverlay.Active = true

    local ThemeFrame = Instance.new("Frame", ThemeOverlay)
    ThemeFrame.Size = UDim2.fromOffset(320, 240)
    ThemeFrame.Position = UDim2.fromScale(0.5, 0.5)
    ThemeFrame.AnchorPoint = Vector2.new(0.5, 0.5)
    ThemeFrame.BackgroundColor3 = BG_COLOR
    createCorner(ThemeFrame, 12)
    local tmStroke = createStroke(ThemeFrame, UI_COLOR, 2)
    RegisterTheme(tmStroke, "Color")

    local ThemeHdr = Instance.new("TextLabel", ThemeFrame)
    ThemeHdr.Size = UDim2.new(1, 0, 0, 40)
    ThemeHdr.BackgroundTransparency = 1
    ThemeHdr.Text = "CUSTOMIZE THEME"
    ThemeHdr.Font = Enum.Font.GothamBlack
    ThemeHdr.TextSize = 16
    ThemeHdr.TextColor3 = Color3.new(1,1,1)

    local ThemeClose = Instance.new("TextButton", ThemeFrame)
    ThemeClose.Size = UDim2.new(0, 30, 0, 30)
    ThemeClose.Position = UDim2.new(1, -35, 0, 5)
    ThemeClose.BackgroundColor3 = Color3.fromRGB(50,50,60)
    ThemeClose.Text = "X"
    ThemeClose.TextColor3 = Color3.new(1,1,1)
    ThemeClose.Font = Enum.Font.GothamBold
    createCorner(ThemeClose, 6)

    ThemeClose.MouseButton1Click:Connect(function() ThemeOverlay.Visible = false end)

    -- Sliders Container
    local SlidersCont = Instance.new("Frame", ThemeFrame)
    SlidersCont.Size = UDim2.new(1, -20, 1, -50)
    SlidersCont.Position = UDim2.new(0, 10, 0, 45)
    SlidersCont.BackgroundTransparency = 1

    -- Helper to make sliders inside modal
    local function CreateColorSlider(parent, label, yPos, colorComp, callback)
        local lbl = Instance.new("TextLabel", parent)
        lbl.Position = UDim2.new(0, 5, 0, yPos)
        lbl.Size = UDim2.new(0, 20, 0, 20)
        lbl.BackgroundTransparency = 1
        lbl.Text = label
        lbl.TextColor3 = Color3.fromRGB(200,200,200)
        lbl.Font = Enum.Font.GothamBold
        lbl.TextSize = 12

        local sliderBg = Instance.new("Frame", parent)
        sliderBg.Size = UDim2.new(1, -40, 0, 6)
        sliderBg.Position = UDim2.new(0, 30, 0, yPos + 7)
        sliderBg.BackgroundColor3 = Color3.fromRGB(50,50,60)
        createCorner(sliderBg, 3)

        local fill = Instance.new("Frame", sliderBg)
        fill.Size = UDim2.new(colorComp/255, 0, 1, 0)
        fill.BackgroundColor3 = UI_COLOR
        createCorner(fill, 3)
        RegisterTheme(fill, "BackgroundColor3")

        local btn = Instance.new("TextButton", sliderBg)
        btn.Size = UDim2.new(1,0,1,0)
        btn.BackgroundTransparency = 1
        btn.Text = ""

        local dragging = false
        btn.MouseButton1Down:Connect(function() dragging = true end)
        UserInputService.InputEnded:Connect(function(input)
            if input.UserInputType == Enum.UserInputType.MouseButton1 then dragging = false end
        end)

        UserInputService.InputChanged:Connect(function(input)
            if dragging and input.UserInputType == Enum.UserInputType.MouseMovement then
                local relativeX = math.clamp(input.Position.X - sliderBg.AbsolutePosition.X, 0, sliderBg.AbsoluteSize.X)
                local scale = relativeX / sliderBg.AbsoluteSize.X
                fill.Size = UDim2.new(scale, 0, 1, 0)
                callback(scale * 255)
            end
        end)
    end

    local r, g, b = UI_COLOR.R*255, UI_COLOR.G*255, UI_COLOR.B*255

    local function updateFromSliders()
        local newColor = Color3.fromRGB(r, g, b)
        UpdateAllTheme(newColor)
        if RainbowConnection then RainbowConnection:Disconnect() RainbowConnection = nil end
    end

    CreateColorSlider(SlidersCont, "R", 10, r, function(val) r = val; updateFromSliders() end)
    CreateColorSlider(SlidersCont, "G", 40, g, function(val) g = val; updateFromSliders() end)
    CreateColorSlider(SlidersCont, "B", 70, b, function(val) b = val; updateFromSliders() end)

    -- Presets
    local PresetContainer = Instance.new("Frame", SlidersCont)
    PresetContainer.Size = UDim2.new(1, 0, 0, 30)
    PresetContainer.Position = UDim2.new(0, 0, 0, 110)
    PresetContainer.BackgroundTransparency = 1
    
    local function createPresetBtn(color, xPos)
        local btn = Instance.new("TextButton", PresetContainer)
        btn.Size = UDim2.new(0, 25, 0, 25)
        btn.Position = UDim2.new(0, xPos, 0, 0)
        btn.BackgroundColor3 = color
        btn.Text = ""
        createCorner(btn, 12)
        createStroke(btn, Color3.fromRGB(100,100,100), 1)
        
        btn.MouseButton1Click:Connect(function()
            if RainbowConnection then RainbowConnection:Disconnect() RainbowConnection = nil end
            r, g, b = color.R*255, color.G*255, color.B*255
            UpdateAllTheme(color)
        end)
    end

    createPresetBtn(Color3.fromRGB(65, 120, 200), 10)  -- Blue
    createPresetBtn(Color3.fromRGB(200, 65, 65), 45)   -- Red
    createPresetBtn(Color3.fromRGB(65, 200, 100), 80)  -- Green
    createPresetBtn(Color3.fromRGB(150, 65, 200), 115) -- Purple

    -- Rainbow Toggle
    local RainbowBtn = Instance.new("TextButton", PresetContainer)
    RainbowBtn.Size = UDim2.new(0, 100, 0, 25)
    RainbowBtn.Position = UDim2.new(1, -100, 0, 0)
    RainbowBtn.BackgroundColor3 = Color3.fromRGB(50,50,60)
    RainbowBtn.Text = "Rainbow Mode"
    RainbowBtn.TextColor3 = Color3.new(1,1,1)
    RainbowBtn.Font = Enum.Font.GothamBold
    RainbowBtn.TextSize = 11
    createCorner(RainbowBtn, 6)

    RainbowBtn.MouseButton1Click:Connect(function()
        if RainbowConnection then 
            RainbowConnection:Disconnect()
            RainbowConnection = nil
            notify("Theme", "Rainbow Mode Disabled", 1)
        else
            notify("Theme", "Rainbow Mode Enabled", 1)
            local hue = 0
            RainbowConnection = RunService.Heartbeat:Connect(function()
                hue = hue + 0.002
                if hue > 1 then hue = 0 end
                local col = Color3.fromHSV(hue, 0.8, 1)
                UpdateAllTheme(col)
            end)
        end
    end)

    -- Logic Window Controls
    MinBtn.MouseButton1Click:Connect(function()
        MainFrame.Visible = false
        Bubble.Visible = true
        ToggleBlur(false)
    end)
    Bubble.MouseButton1Click:Connect(function()
        Bubble.Visible = false
        MainFrame.Visible = true
        ToggleBlur(true)
    end)
    CloseBtn.MouseButton1Click:Connect(function()
        ConfirmOverlay.Visible = true
    end)

    -- Container
    local Container = Instance.new("Frame", MainFrame)
    Container.Size = UDim2.new(1, -150, 1, -50)
    Container.Position = UDim2.new(0, 145, 0, 45)
    Container.BackgroundTransparency = 1

    local TabContents = {}

    local function SwitchTab(tabName)
        for name, frame in pairs(TabContents) do
            frame.Visible = (name == tabName)
        end
        CurrentConfig.UI.LastTab = tabName -- Save to Config
    end

    local function CreateTabButton(name)
        local btn = Instance.new("TextButton", TabContainer)
        btn.Size = UDim2.new(0, 120, 0, 30)
        btn.BackgroundTransparency = 1
        btn.Text = name
        btn.TextColor3 = Color3.fromRGB(180, 180, 180)
        btn.Font = Enum.Font.GothamSemibold
        btn.TextSize = 12
        btn.TextXAlignment = Enum.TextXAlignment.Left
        
        local ind = Instance.new("Frame", btn)
        ind.Size = UDim2.new(0, 3, 0.6, 0)
        ind.Position = UDim2.new(0, -5, 0.2, 0)
        ind.BackgroundColor3 = UI_COLOR
        ind.BackgroundTransparency = 1
        createCorner(ind, 2)
        RegisterTheme(ind, "BackgroundColor3") 

        btn.MouseButton1Click:Connect(function()
            SwitchTab(name)
            for _, child in pairs(TabContainer:GetChildren()) do
                if child:IsA("TextButton") then
                    child.TextColor3 = Color3.fromRGB(180, 180, 180)
                    child.Font = Enum.Font.GothamSemibold
                    child:FindFirstChild("Frame").BackgroundTransparency = 1
                end
            end
            btn.TextColor3 = Color3.new(1,1,1)
            btn.Font = Enum.Font.GothamBold
            ind.BackgroundTransparency = 0
        end)
    end

    local function CreatePage(name)
        local page = Instance.new("ScrollingFrame", Container)
        page.Size = UDim2.new(1, 0, 1, 0)
        page.BackgroundTransparency = 1
        page.ScrollBarThickness = 2
        page.ScrollBarImageColor3 = UI_COLOR
        page.Visible = false
        page.AutomaticCanvasSize = Enum.AutomaticSize.Y
        page.CanvasSize = UDim2.new(0,0,0,0)
        RegisterTheme(page, "ScrollBarImageColor3") 
        
        local layout = Instance.new("UIListLayout", page)
        layout.Padding = UDim.new(0, 8)
        layout.SortOrder = Enum.SortOrder.LayoutOrder
        
        local padding = Instance.new("UIPadding", page)
        padding.PaddingTop = UDim.new(0, 5)
        padding.PaddingLeft = UDim.new(0, 5)
        padding.PaddingBottom = UDim.new(0, 10)
        
        TabContents[name] = page
        CreateTabButton(name)
        return page
    end

    -- ===================================
    -- :: TAB 1: PLAYER INFO (COMPACT) ::
    -- ===================================
    local PageInfo = CreatePage("Player Info")
    
    -- Profile Card
    local ProfileCard = Instance.new("Frame", PageInfo)
    ProfileCard.Size = UDim2.new(0.95, 0, 0, 85)
    ProfileCard.BackgroundColor3 = CARD_COLOR
    ProfileCard.BackgroundTransparency = 0.2
    createCorner(ProfileCard, 8)
    createStroke(ProfileCard, Color3.fromRGB(60, 60, 70), 1)
    createGradient(ProfileCard)

    local InfoContainer = Instance.new("Frame", ProfileCard)
    InfoContainer.Size = UDim2.new(1, -30, 1, -20)
    InfoContainer.Position = UDim2.new(0, 15, 0, 15)
    InfoContainer.BackgroundTransparency = 1

    local InfoLayout = Instance.new("UIListLayout", InfoContainer)
    InfoLayout.SortOrder = Enum.SortOrder.LayoutOrder
    InfoLayout.Padding = UDim.new(0, 2)

    local function addTextLine(text, size, font, color, layoutOrder, parent)
        local lbl = Instance.new("TextLabel", parent)
        lbl.Size = UDim2.new(1, 0, 0, size + 4)
        lbl.BackgroundTransparency = 1
        lbl.Text = text
        lbl.TextSize = size
        lbl.Font = font
        lbl.TextColor3 = color
        lbl.TextXAlignment = Enum.TextXAlignment.Left
        lbl.LayoutOrder = layoutOrder
        return lbl
    end

    addTextLine("Username: @" .. player.Name, 14, Enum.Font.GothamBold, Color3.new(1,1,1), 1, InfoContainer)

    local IdRow = Instance.new("Frame", InfoContainer)
    IdRow.Size = UDim2.new(1, 0, 0, 24)
    IdRow.BackgroundTransparency = 1
    IdRow.LayoutOrder = 2

    local IdLayout = Instance.new("UIListLayout", IdRow)
    IdLayout.FillDirection = Enum.FillDirection.Horizontal
    IdLayout.SortOrder = Enum.SortOrder.LayoutOrder
    IdLayout.Padding = UDim.new(0, 8)
    IdLayout.VerticalAlignment = Enum.VerticalAlignment.Center

    local IdLabel = Instance.new("TextLabel", IdRow)
    IdLabel.AutomaticSize = Enum.AutomaticSize.X
    IdLabel.Size = UDim2.new(0, 0, 1, 0)
    IdLabel.BackgroundTransparency = 1
    IdLabel.Text = "ID: " .. player.UserId
    IdLabel.TextSize = 11
    IdLabel.Font = Enum.Font.Code
    IdLabel.TextColor3 = Color3.fromRGB(150,150,150)
    IdLabel.LayoutOrder = 1

    local CopyBtn = Instance.new("TextButton", IdRow)
    CopyBtn.Size = UDim2.new(0, 45, 0, 20)
    CopyBtn.BackgroundColor3 = Color3.fromRGB(60,60,70)
    CopyBtn.Text = "Copy"
    CopyBtn.Font = Enum.Font.GothamBold
    CopyBtn.TextSize = 10
    CopyBtn.TextColor3 = Color3.new(1,1,1)
    CopyBtn.LayoutOrder = 3
    createCorner(CopyBtn, 4)
    createStroke(CopyBtn, Color3.fromRGB(90,90,100), 1)

    CopyBtn.MouseButton1Click:Connect(function()
        copyToClipboard(tostring(player.UserId))
        local oldText = CopyBtn.Text
        CopyBtn.Text = "Copied"
        CopyBtn.BackgroundColor3 = Color3.fromRGB(50, 150, 50)
        task.wait(1)
        CopyBtn.Text = oldText
        CopyBtn.BackgroundColor3 = Color3.fromRGB(60,60,70)
    end)

    -- Stats Row (Smaller Size)
    local StatsRow = Instance.new("Frame", PageInfo)
    StatsRow.Size = UDim2.new(0.95, 0, 0, 55) 
    StatsRow.BackgroundTransparency = 1
    
    local StatsLayout = Instance.new("UIListLayout", StatsRow)
    StatsLayout.FillDirection = Enum.FillDirection.Horizontal
    StatsLayout.Padding = UDim.new(0.04, 0)
    StatsLayout.HorizontalAlignment = Enum.HorizontalAlignment.Left

    local function createMiniCard(title, valueText, valueColor, isTimeCard)
        local card = Instance.new("Frame", StatsRow)
        card.Size = UDim2.new(0.48, 0, 1, 0)
        card.BackgroundColor3 = CARD_COLOR
        card.BackgroundTransparency = 0.2
        createCorner(card, 8)
        createStroke(card, Color3.fromRGB(60,60,70), 1)
        createGradient(card)

        local t = Instance.new("TextLabel", card)
        t.Size = UDim2.new(1, -20, 0, 15)
        t.Position = UDim2.new(0, 10, 0, 5)
        t.BackgroundTransparency = 1
        t.Text = title
        t.Font = Enum.Font.GothamBold
        t.TextSize = 9
        t.TextColor3 = Color3.fromRGB(150,150,150)
        t.TextXAlignment = Enum.TextXAlignment.Left

        local v = Instance.new("TextLabel", card)
        v.Size = UDim2.new(1, -20, 0, 20)
        v.Position = UDim2.new(0, 10, 0.4, 0)
        v.BackgroundTransparency = 1
        v.Text = valueText
        v.Font = Enum.Font.GothamBold
        v.TextSize = 14
        v.TextColor3 = valueColor
        v.TextXAlignment = Enum.TextXAlignment.Left
        
        if isTimeCard then
            RegisterTheme(v, "TextColor3")
            -- Modifikasi Layout: Date (Kiri) dan Time (Kanan)
            v.Size = UDim2.new(0.5, -10, 0, 20)
            v.Position = UDim2.new(0.5, 5, 0.4, 0) -- Pindah ke kanan
            v.TextXAlignment = Enum.TextXAlignment.Right

            local d = Instance.new("TextLabel", card)
            d.Name = "DateLabel"
            d.Size = UDim2.new(0.5, -10, 0, 20)
            d.Position = UDim2.new(0, 10, 0.4, 0) -- Pindah ke kiri
            d.BackgroundTransparency = 1
            d.Text = getCurrentDate()
            d.Font = Enum.Font.Code
            d.TextSize = 11 -- Sedikit lebih kecil agar muat
            d.TextColor3 = Color3.fromRGB(200,200,200)
            d.TextXAlignment = Enum.TextXAlignment.Left
        end

        return v
    end

    local statusVal = isVIP and "VIP MEMBER" or "FREE USER"
    local statusCol = isVIP and Color3.fromRGB(255, 215, 0) or Color3.fromRGB(200, 200, 200)
    createMiniCard("ACCOUNT", statusVal, statusCol, false)

    local timeLabel = createMiniCard("LOCAL TIME", "00:00:00", UI_COLOR, true)
    local dateLabel = timeLabel.Parent:FindFirstChild("DateLabel")

    task.spawn(function()
        while MainFrame.Parent do
            timeLabel.Text = getCurrentTime()
            if dateLabel then dateLabel.Text = getCurrentDate() end
            task.wait(1)
        end
    end)

    local MarketingCard = Instance.new("Frame", PageInfo)
    MarketingCard.Size = UDim2.new(0.95, 0, 0, 115) 
    MarketingCard.BackgroundColor3 = CARD_COLOR
    MarketingCard.BackgroundTransparency = 0.2
    createCorner(MarketingCard, 8)
    local mStroke = createStroke(MarketingCard, UI_COLOR, 1)
    RegisterTheme(mStroke, "Color")

    local MIcon = Instance.new("ImageLabel", MarketingCard)
    MIcon.Size = UDim2.new(0, 25, 0, 25)
    MIcon.Position = UDim2.new(0, 10, 0, 10)
    MIcon.BackgroundTransparency = 1
    MIcon.Image = "rbxassetid://3926305904"
    MIcon.ImageColor3 = Color3.fromRGB(255, 215, 0)

    local MTitle = Instance.new("TextLabel", MarketingCard)
    MTitle.Size = UDim2.new(1, -50, 0, 25)
    MTitle.Position = UDim2.new(0, 40, 0, 10)
    MTitle.BackgroundTransparency = 1
    MTitle.Text = "UNLOCK VIP POWER"
    MTitle.TextColor3 = Color3.fromRGB(255, 215, 0)
    MTitle.Font = Enum.Font.GothamBlack
    MTitle.TextSize = 14
    MTitle.TextXAlignment = Enum.TextXAlignment.Left

    local MDesc = Instance.new("TextLabel", MarketingCard)
    MDesc.Size = UDim2.new(1, -20, 0, 40)
    MDesc.Position = UDim2.new(0, 10, 0, 35)
    MDesc.BackgroundTransparency = 1
    MDesc.Text = "Get exclusive access to premium scripts, faster updates, and priority support. Upgrade now to dominate the game!"
    MDesc.TextColor3 = Color3.fromRGB(200, 200, 200)
    MDesc.Font = Enum.Font.Gotham
    MDesc.TextSize = 11
    MDesc.TextWrapped = true
    MDesc.TextXAlignment = Enum.TextXAlignment.Left
    MDesc.TextYAlignment = Enum.TextYAlignment.Top

    local UpgradeBtn = Instance.new("TextButton", MarketingCard)
    UpgradeBtn.Size = UDim2.new(1, -20, 0, 30)
    UpgradeBtn.Position = UDim2.new(0, 10, 1, -40)
    UpgradeBtn.BackgroundColor3 = UI_COLOR
    UpgradeBtn.Text = "Upgrade to VIP Script"
    UpgradeBtn.TextColor3 = Color3.new(1,1,1)
    UpgradeBtn.Font = Enum.Font.GothamBold
    UpgradeBtn.TextSize = 12
    createCorner(UpgradeBtn, 6)
    RegisterTheme(UpgradeBtn, "BackgroundColor3")

    UpgradeBtn.MouseEnter:Connect(function()
        TweenService:Create(UpgradeBtn, TweenInfo.new(0.2), {Transparency = 0.2}):Play()
    end)
    UpgradeBtn.MouseLeave:Connect(function()
        TweenService:Create(UpgradeBtn, TweenInfo.new(0.2), {Transparency = 0}):Play()
    end)

    UpgradeBtn.MouseButton1Click:Connect(function()
        setclipboard("https://discord.gg/RpYcMdzzwd") 
        notify("VIP Upgrade", "Purchase link copied to clipboard!", 3)
        UpgradeBtn.Text = "Link Copied!"
        task.wait(1)
        UpgradeBtn.Text = "Upgrade to VIP Script"
    end)


    -- ===================================
    -- :: TAB 2: MAIN SCRIPTS (MODULAR UPDATED) ::
    -- ===================================
    local PageScripts = CreatePage("Main Scripts")
    
    -- INJECT HELPER MODUL DISINI
    local success, Helper = pcall(function()
        return loadstring(game:HttpGet(HELPER_URL))()
    end)
    
    if success and Helper then
        task.spawn(function()
            Helper.BuildMainTab(PageScripts, isVIP)
        end)
    else
        local errFrame = Instance.new("Frame", PageScripts)
        errFrame.Size = UDim2.new(0.95, 0, 0, 60)
        errFrame.BackgroundColor3 = Color3.fromRGB(45, 20, 20)
        createCorner(errFrame, 8)
        
        local errLbl = Instance.new("TextLabel", errFrame)
        errLbl.Size = UDim2.new(1, 0, 1, 0)
        errLbl.BackgroundTransparency = 1
        errLbl.Text = "Failed to load Helper Module.\nPlease check your internet connection."
        errLbl.TextColor3 = Color3.fromRGB(255, 100, 100)
        errLbl.Font = Enum.Font.GothamBold
        errLbl.TextSize = 12
        warn("XuKrost Hub Error: " .. tostring(Helper))
    end
    
    -- ===================================
    -- :: TAB 3: TP MANAGER (MODAL UPDATE) ::
    -- ===================================
    local PageTP = CreatePage("TP Manager")
    
    local TPLayout = Instance.new("UIListLayout", PageTP)
    TPLayout.SortOrder = Enum.SortOrder.LayoutOrder
    TPLayout.Padding = UDim.new(0, 10)

    -- :: LOGIC VARIABLES ::
    local teleportLocations = {}
    local LocationScrollList = nil 
    local activePresetFile = nil 

    -- Status Log
    local ConsoleCard = Instance.new("Frame", PageTP)
    ConsoleCard.Size = UDim2.new(0.95, 0, 0, 25)
    ConsoleCard.BackgroundTransparency = 1
    ConsoleCard.LayoutOrder = 99 

    local consoleOutput = Instance.new("TextLabel", ConsoleCard)
    consoleOutput.Size = UDim2.new(1, 0, 1, 0)
    consoleOutput.BackgroundTransparency = 1
    consoleOutput.Text = "> System Ready"
    consoleOutput.TextColor3 = Color3.fromRGB(120, 120, 120)
    consoleOutput.Font = Enum.Font.Code
    consoleOutput.TextSize = 10
    consoleOutput.TextXAlignment = Enum.TextXAlignment.Left

    local function appendToConsole(msg)
        consoleOutput.Text = "> " .. msg
        TweenService:Create(consoleOutput, TweenInfo.new(0.2), {TextColor3 = UI_COLOR}):Play()
        task.wait(0.2)
        TweenService:Create(consoleOutput, TweenInfo.new(0.5), {TextColor3 = Color3.fromRGB(120, 120, 120)}):Play()
    end

    local function getCurrentPosition()
        if player.Character and player.Character:FindFirstChild("HumanoidRootPart") then
            local cf = player.Character.HumanoidRootPart.CFrame
            return { x = cf.Position.X, y = cf.Position.Y, z = cf.Position.Z }
        end
        return nil
    end

    local function teleportTo(posData)
        if player.Character and player.Character:FindFirstChild("HumanoidRootPart") then
            player.Character.HumanoidRootPart.CFrame = CFrame.new(posData.x, posData.y + 2, posData.z)
        end
    end

    -- :: MODAL UI CONSTRUCTION ::
    local ModalOverlay = Instance.new("Frame", ScreenGui)
    ModalOverlay.Name = "TP_Modal_Overlay"
    ModalOverlay.Size = UDim2.fromScale(1, 1)
    ModalOverlay.BackgroundColor3 = Color3.new(0,0,0)
    ModalOverlay.BackgroundTransparency = 0.6
    ModalOverlay.Visible = false
    ModalOverlay.ZIndex = 200

    local function createModalFrame(height, title)
        local frame = Instance.new("Frame", ModalOverlay)
        frame.Size = UDim2.fromOffset(280, height)
        frame.Position = UDim2.fromScale(0.5, 0.5)
        frame.AnchorPoint = Vector2.new(0.5, 0.5)
        frame.BackgroundColor3 = BG_COLOR
        frame.Visible = false
        createCorner(frame, 10)
        local stroke = createStroke(frame, UI_COLOR, 2)
        RegisterTheme(stroke, "Color")

        local lbl = Instance.new("TextLabel", frame)
        lbl.Size = UDim2.new(1, 0, 0, 35)
        lbl.BackgroundTransparency = 1
        lbl.Text = title
        lbl.Font = Enum.Font.GothamBlack
        lbl.TextSize = 14
        lbl.TextColor3 = Color3.new(1,1,1)
        
        local close = Instance.new("TextButton", frame)
        close.Size = UDim2.new(0, 30, 0, 30)
        close.Position = UDim2.new(1, -35, 0, 2)
        close.BackgroundColor3 = Color3.fromRGB(150, 60, 60)
        close.Text = "X"
        close.TextColor3 = Color3.new(1,1,1)
        createCorner(close, 4)
        
        close.MouseButton1Click:Connect(function()
            frame.Visible = false
            ModalOverlay.Visible = false
        end)

        return frame
    end

    -- [MODAL 1: SAVE PRESET]
    local SaveModal = createModalFrame(160, "SAVE PRESET")
    
    local SaveInputInfo = Instance.new("TextLabel", SaveModal)
    SaveInputInfo.Size = UDim2.new(1, 0, 0, 20)
    SaveInputInfo.Position = UDim2.new(0, 0, 0, 40)
    SaveInputInfo.BackgroundTransparency = 1
    SaveInputInfo.Text = "Enter Name (Max 12 chars, A-Z, 0-9)"
    SaveInputInfo.TextColor3 = Color3.fromRGB(150,150,150)
    SaveInputInfo.Font = Enum.Font.Gotham
    SaveInputInfo.TextSize = 10

    local SaveInputBox = Instance.new("TextBox", SaveModal)
    SaveInputBox.Size = UDim2.new(0.8, 0, 0, 35)
    SaveInputBox.Position = UDim2.new(0.1, 0, 0, 65)
    SaveInputBox.BackgroundColor3 = Color3.fromRGB(40,40,45)
    SaveInputBox.Text = ""
    SaveInputBox.PlaceholderText = "Preset Name..."
    SaveInputBox.TextColor3 = Color3.new(1,1,1)
    SaveInputBox.Font = Enum.Font.GothamBold
    SaveInputBox.TextSize = 12
    createCorner(SaveInputBox, 6)
    createStroke(SaveInputBox, Color3.fromRGB(60,60,70), 1)

    -- Filter Input Logic (Max 12 Char & Alphanumeric)
    SaveInputBox:GetPropertyChangedSignal("Text"):Connect(function()
        local txt = SaveInputBox.Text
        local clean = txt:gsub("[^%w]", "") -- Hapus simbol
        if #clean > 12 then clean = clean:sub(1, 12) end
        if SaveInputBox.Text ~= clean then
            SaveInputBox.Text = clean
        end
    end)

    local SaveConfirmBtn = Instance.new("TextButton", SaveModal)
    SaveConfirmBtn.Size = UDim2.new(0.6, 0, 0, 30)
    SaveConfirmBtn.Position = UDim2.new(0.2, 0, 0, 115)
    SaveConfirmBtn.BackgroundColor3 = UI_COLOR
    SaveConfirmBtn.Text = "SAVE PRESET"
    SaveConfirmBtn.TextColor3 = Color3.new(1,1,1)
    SaveConfirmBtn.Font = Enum.Font.GothamBold
    SaveConfirmBtn.TextSize = 11
    createCorner(SaveConfirmBtn, 6)
    RegisterTheme(SaveConfirmBtn, "BackgroundColor3")

    -- [MODAL 2: LOAD PRESET]
    local LoadModal = createModalFrame(250, "LOAD PRESET")

    local FileListFrame = Instance.new("ScrollingFrame", LoadModal)
    FileListFrame.Size = UDim2.new(0.9, 0, 0, 140)
    FileListFrame.Position = UDim2.new(0.05, 0, 0, 45)
    FileListFrame.BackgroundColor3 = Color3.fromRGB(30,30,35)
    FileListFrame.ScrollBarThickness = 4
    createCorner(FileListFrame, 6)
    
    local FileListLayout = Instance.new("UIListLayout", FileListFrame)
    FileListLayout.Padding = UDim.new(0, 5)
    FileListLayout.SortOrder = Enum.SortOrder.LayoutOrder
    
    local FileListPadding = Instance.new("UIPadding", FileListFrame)
    FileListPadding.PaddingTop = UDim.new(0, 5)
    FileListPadding.PaddingLeft = UDim.new(0, 5)

    local LoadConfirmBtn = Instance.new("TextButton", LoadModal)
    LoadConfirmBtn.Size = UDim2.new(0.6, 0, 0, 30)
    LoadConfirmBtn.Position = UDim2.new(0.2, 0, 0, 200)
    LoadConfirmBtn.BackgroundColor3 = Color3.fromRGB(50,50,50) -- Disabled color initially
    LoadConfirmBtn.Text = "LOAD SELECTED"
    LoadConfirmBtn.TextColor3 = Color3.fromRGB(150,150,150)
    LoadConfirmBtn.Font = Enum.Font.GothamBold
    LoadConfirmBtn.TextSize = 11
    LoadConfirmBtn.AutoButtonColor = false
    createCorner(LoadConfirmBtn, 6)

    -- :: PAGE CONTENT ::

    -- 1. CREATOR CARD
    local CreatorCard = Instance.new("Frame", PageTP)
    CreatorCard.Size = UDim2.new(0.95, 0, 0, 85)
    CreatorCard.BackgroundColor3 = CARD_COLOR
    CreatorCard.BackgroundTransparency = 0.2
    CreatorCard.LayoutOrder = 1
    createCorner(CreatorCard, 8)
    local ccStroke = createStroke(CreatorCard, UI_COLOR, 1)
    RegisterTheme(ccStroke, "Color")

    local CreatorTitle = Instance.new("TextLabel", CreatorCard)
    CreatorTitle.Size = UDim2.new(1, -20, 0, 25)
    CreatorTitle.Position = UDim2.new(0, 10, 0, 5)
    CreatorTitle.BackgroundTransparency = 1
    CreatorTitle.Text = "CREATE NEW WAYPOINT"
    CreatorTitle.Font = Enum.Font.GothamBold
    CreatorTitle.TextSize = 10
    CreatorTitle.TextColor3 = Color3.fromRGB(150, 150, 150)
    CreatorTitle.TextXAlignment = Enum.TextXAlignment.Left

    local InputBg = Instance.new("Frame", CreatorCard)
    InputBg.Size = UDim2.new(0.65, -15, 0, 35)
    InputBg.Position = UDim2.new(0, 10, 0, 35)
    InputBg.BackgroundColor3 = Color3.fromRGB(25, 25, 30)
    createCorner(InputBg, 6)
    createStroke(InputBg, Color3.fromRGB(50, 50, 60), 1)

    local NameInput = Instance.new("TextBox", InputBg)
    NameInput.Size = UDim2.new(1, -10, 1, 0)
    NameInput.Position = UDim2.new(0, 10, 0, 0)
    NameInput.BackgroundTransparency = 1
    NameInput.Text = ""
    NameInput.PlaceholderText = "Location Name..."
    NameInput.TextColor3 = Color3.new(1,1,1)
    NameInput.Font = Enum.Font.Gotham
    NameInput.TextSize = 12
    NameInput.TextXAlignment = Enum.TextXAlignment.Left

    local SaveLocBtn = Instance.new("TextButton", CreatorCard)
    SaveLocBtn.Size = UDim2.new(0.35, -5, 0, 35)
    SaveLocBtn.Position = UDim2.new(0.65, 5, 0, 35)
    SaveLocBtn.BackgroundColor3 = UI_COLOR
    SaveLocBtn.Text = "ADD"
    SaveLocBtn.TextColor3 = Color3.new(1,1,1)
    SaveLocBtn.Font = Enum.Font.GothamBold
    SaveLocBtn.TextSize = 12
    createCorner(SaveLocBtn, 6)
    RegisterTheme(SaveLocBtn, "BackgroundColor3")

    -- 2. TOOLS CARD
    local ToolsCard = Instance.new("Frame", PageTP)
    ToolsCard.Size = UDim2.new(0.95, 0, 0, 80)
    ToolsCard.BackgroundColor3 = CARD_COLOR
    ToolsCard.BackgroundTransparency = 0.2
    ToolsCard.LayoutOrder = 2
    createCorner(ToolsCard, 8)
    createStroke(ToolsCard, Color3.fromRGB(60, 60, 70), 1)

    local ToolsTitle = Instance.new("TextLabel", ToolsCard)
    ToolsTitle.Size = UDim2.new(1, -20, 0, 25)
    ToolsTitle.Position = UDim2.new(0, 10, 0, 5)
    ToolsTitle.BackgroundTransparency = 1
    ToolsTitle.Text = "PRESET MANAGER (VIP)"
    ToolsTitle.Font = Enum.Font.GothamBold
    ToolsTitle.TextSize = 10
    ToolsTitle.TextColor3 = isVIP and Color3.fromRGB(255, 215, 0) or Color3.fromRGB(100, 100, 100)
    ToolsTitle.TextXAlignment = Enum.TextXAlignment.Left

    local function createToolBtn(text, color, pos, size, callback)
        local btn = Instance.new("TextButton", ToolsCard)
        btn.Size = size
        btn.Position = pos
        btn.BackgroundColor3 = color
        btn.Text = text
        btn.TextColor3 = Color3.new(1,1,1)
        btn.Font = Enum.Font.GothamBold
        btn.TextSize = 10
        createCorner(btn, 6)
        
        if not isVIP and text ~= "Clear List" then
            btn.BackgroundColor3 = Color3.fromRGB(50,50,50)
            btn.TextColor3 = Color3.fromRGB(100,100,100)
            btn.Text = "LOCKED"
            btn.AutoButtonColor = false
        end

        btn.MouseButton1Click:Connect(function()
            if (not isVIP and text ~= "Clear List") then 
                notify("VIP Only", "This feature requires VIP.", 2)
                return 
            end
            callback()
        end)
    end

    -- BUTTON: SAVE PRESET
    createToolBtn("Save Preset", Color3.fromRGB(70, 120, 80), UDim2.new(0, 10, 0, 35), UDim2.new(0.3, 0, 0, 30), function()
        if not next(teleportLocations) then appendToConsole("No locations to save") return end
        ModalOverlay.Visible = true
        SaveModal.Visible = true
        SaveInputBox.Text = ""
    end)

    -- BUTTON: LOAD PRESET
    createToolBtn("Load Preset", Color3.fromRGB(70, 80, 120), UDim2.new(0.32, 10, 0, 35), UDim2.new(0.3, 0, 0, 30), function()
        -- Reset List
        for _, v in pairs(FileListFrame:GetChildren()) do if v:IsA("TextButton") then v:Destroy() end end
        activePresetFile = nil
        LoadConfirmBtn.BackgroundColor3 = Color3.fromRGB(50,50,50)
        LoadConfirmBtn.TextColor3 = Color3.fromRGB(150,150,150)
        
        -- Get Files (Standard Executor support: listfiles)
        local files = {}
        if listfiles then
             pcall(function() files = listfiles("") end) -- Root folder usually
        end

        local found = false
        for _, file in pairs(files) do
            if file:find("XuKrost_Preset_") and file:find(".json") then
                found = true
                -- Clean name
                local cleanName = file:match("XuKrost_Preset_(.-)%.json") or file
                
                local fileBtn = Instance.new("TextButton", FileListFrame)
                fileBtn.Size = UDim2.new(1, -5, 0, 25)
                fileBtn.BackgroundColor3 = Color3.fromRGB(45,45,50)
                fileBtn.Text = cleanName
                fileBtn.TextColor3 = Color3.fromRGB(200,200,200)
                fileBtn.Font = Enum.Font.Gotham
                fileBtn.TextSize = 11
                createCorner(fileBtn, 4)

                fileBtn.MouseButton1Click:Connect(function()
                    -- Highlight Selection
                    for _, b in pairs(FileListFrame:GetChildren()) do
                        if b:IsA("TextButton") then b.BackgroundColor3 = Color3.fromRGB(45,45,50) end
                    end
                    fileBtn.BackgroundColor3 = UI_COLOR
                    activePresetFile = file
                    
                    -- Enable Load Button
                    LoadConfirmBtn.BackgroundColor3 = UI_COLOR
                    LoadConfirmBtn.TextColor3 = Color3.new(1,1,1)
                    RegisterTheme(LoadConfirmBtn, "BackgroundColor3")
                    LoadConfirmBtn.AutoButtonColor = true
                end)
            end
        end

        if not found then
            local empty = Instance.new("TextLabel", FileListFrame)
            empty.Size = UDim2.new(1,0,1,0)
            empty.BackgroundTransparency = 1
            empty.Text = "No Presets Found"
            empty.TextColor3 = Color3.fromRGB(100,100,100)
        end

        FileListFrame.CanvasSize = UDim2.new(0,0,0, FileListLayout.AbsoluteContentSize.Y)
        ModalOverlay.Visible = true
        LoadModal.Visible = true
    end)

    -- BUTTON: CLEAR LIST
    createToolBtn("Clear List", Color3.fromRGB(150, 60, 60), UDim2.new(0.64, 10, 0, 35), UDim2.new(0.3, 0, 0, 30), function()
        teleportLocations = {}
        -- Refresh List Function Call (Defined below)
        for _, child in pairs(LocationScrollList:GetChildren()) do if child:IsA("Frame") then child:Destroy() end end
        appendToConsole("All locations cleared.")
    end)

    -- 3. LIST CONTAINER
    local ListContainer = Instance.new("Frame", PageTP)
    ListContainer.Size = UDim2.new(0.95, 0, 0, 180)
    ListContainer.BackgroundColor3 = CARD_COLOR
    ListContainer.BackgroundTransparency = 0.4
    ListContainer.LayoutOrder = 3
    createCorner(ListContainer, 8)
    createStroke(ListContainer, Color3.fromRGB(60, 60, 70), 1)

    local ListLabel = Instance.new("TextLabel", ListContainer)
    ListLabel.Size = UDim2.new(1, -20, 0, 25)
    ListLabel.Position = UDim2.new(0, 10, 0, 0)
    ListLabel.BackgroundTransparency = 1
    ListLabel.Text = "WAYPOINTS"
    ListLabel.Font = Enum.Font.GothamBold
    ListLabel.TextSize = 10
    ListLabel.TextColor3 = Color3.fromRGB(200, 200, 200)
    ListLabel.TextXAlignment = Enum.TextXAlignment.Left

    LocationScrollList = Instance.new("ScrollingFrame", ListContainer)
    LocationScrollList.Size = UDim2.new(1, -10, 1, -30)
    LocationScrollList.Position = UDim2.new(0, 5, 0, 25)
    LocationScrollList.BackgroundTransparency = 1
    LocationScrollList.BorderSizePixel = 0
    LocationScrollList.ScrollBarThickness = 4
    LocationScrollList.ScrollBarImageColor3 = UI_COLOR
    RegisterTheme(LocationScrollList, "ScrollBarImageColor3")

    local ListLayout = Instance.new("UIListLayout", LocationScrollList)
    ListLayout.SortOrder = Enum.SortOrder.LayoutOrder
    ListLayout.Padding = UDim.new(0, 5)

    -- :: FUNCTIONS IMPLEMENTATION ::

    local function RefreshList()
        for _, child in pairs(LocationScrollList:GetChildren()) do
            if child:IsA("Frame") then child:Destroy() end
        end

        local count = 0
        for name, pos in pairs(teleportLocations) do
            count = count + 1
            local Item = Instance.new("Frame", LocationScrollList)
            Item.Size = UDim2.new(1, -5, 0, 35)
            Item.BackgroundColor3 = Color3.fromRGB(45, 45, 50)
            createCorner(Item, 6)

            local NameLbl = Instance.new("TextLabel", Item)
            NameLbl.Size = UDim2.new(0.6, 0, 1, 0)
            NameLbl.Position = UDim2.new(0, 10, 0, 0)
            NameLbl.BackgroundTransparency = 1
            NameLbl.Text = name
            NameLbl.TextColor3 = Color3.new(1,1,1)
            NameLbl.Font = Enum.Font.GothamSemibold
            NameLbl.TextSize = 11
            NameLbl.TextXAlignment = Enum.TextXAlignment.Left

            local TPBtn = Instance.new("TextButton", Item)
            TPBtn.Size = UDim2.new(0, 40, 0, 20)
            TPBtn.Position = UDim2.new(1, -70, 0.5, 0)
            TPBtn.AnchorPoint = Vector2.new(0, 0.5)
            TPBtn.BackgroundColor3 = UI_COLOR
            TPBtn.Text = "TP"
            TPBtn.TextColor3 = Color3.new(1,1,1)
            TPBtn.Font = Enum.Font.GothamBold
            TPBtn.TextSize = 9
            createCorner(TPBtn, 3)
            RegisterTheme(TPBtn, "BackgroundColor3")

            local DelBtn = Instance.new("TextButton", Item)
            DelBtn.Size = UDim2.new(0, 20, 0, 20)
            DelBtn.Position = UDim2.new(1, -25, 0.5, 0)
            DelBtn.AnchorPoint = Vector2.new(0, 0.5)
            DelBtn.BackgroundColor3 = Color3.fromRGB(200, 60, 60)
            DelBtn.Text = "X"
            DelBtn.TextColor3 = Color3.new(1,1,1)
            createCorner(DelBtn, 3)

            TPBtn.MouseButton1Click:Connect(function()
                teleportTo(pos)
                appendToConsole("Teleported: " .. name)
            end)

            DelBtn.MouseButton1Click:Connect(function()
                teleportLocations[name] = nil
                RefreshList()
            end)
        end
        LocationScrollList.CanvasSize = UDim2.new(0, 0, 0, count * 40)
    end

    -- Logic: Save Location to List (RAM)
    SaveLocBtn.MouseButton1Click:Connect(function()
        local name = NameInput.Text
        if name:gsub(" ", "") == "" then
            notify("Error", "Enter a name", 2)
            return
        end
        if teleportLocations[name] then
            notify("Error", "Name exists", 2)
            return
        end
        local pos = getCurrentPosition()
        if pos then
            teleportLocations[name] = pos
            RefreshList()
            NameInput.Text = ""
            appendToConsole("Waypoint Added: " .. name)
        end
    end)

    -- Logic: Save Preset (File) - From Modal
    SaveConfirmBtn.MouseButton1Click:Connect(function()
        local filename = "XuKrost_Preset_" .. SaveInputBox.Text .. ".json"
        if writefile then
            pcall(function()
                writefile(filename, HttpService:JSONEncode(teleportLocations))
            end)
            appendToConsole("Saved: " .. SaveInputBox.Text)
            notify("System", "Preset Saved!", 2)
        else
            notify("Error", "Executor not supported", 2)
        end
        SaveModal.Visible = false
        ModalOverlay.Visible = false
    end)

    -- Logic: Load Preset (File) - From Modal
    LoadConfirmBtn.MouseButton1Click:Connect(function()
        if activePresetFile and readfile and isfile(activePresetFile) then
            local s, data = pcall(function() return readfile(activePresetFile) end)
            if s and data then
                local decoded = HttpService:JSONDecode(data)
                if decoded then
                    teleportLocations = decoded
                    RefreshList()
                    appendToConsole("Loaded: " .. activePresetFile)
                end
            end
        end
        LoadModal.Visible = false
        ModalOverlay.Visible = false
    end)

    -- ===============================================
    -- :: TAB 4: MISC (MERGED WITH TOOLS & RTX) ::
    -- ===============================================
    local PageMisc = CreatePage("Misc")

    -- 1. DROPDOWN MOVEMENT
    local function createDropdown(name, contentSize)
        local container = Instance.new("Frame", PageMisc)
        container.Size = UDim2.new(0.95, 0, 0, 35) 
        container.BackgroundColor3 = CARD_COLOR
        container.BackgroundTransparency = 0.2
        container.ClipsDescendants = true
        createCorner(container, 6)
        createStroke(container, Color3.fromRGB(60,60,70), 1)
        
        local headerBtn = Instance.new("TextButton", container)
        headerBtn.Size = UDim2.new(1, 0, 0, 35)
        headerBtn.BackgroundTransparency = 1
        headerBtn.Text = "  " .. name
        headerBtn.TextColor3 = Color3.new(1,1,1)
        headerBtn.Font = Enum.Font.GothamBold
        headerBtn.TextSize = 12
        headerBtn.TextXAlignment = Enum.TextXAlignment.Left

        local icon = Instance.new("TextLabel", headerBtn)
        icon.Size = UDim2.new(0, 30, 1, 0)
        icon.Position = UDim2.new(1, -30, 0, 0)
        icon.BackgroundTransparency = 1
        icon.Text = "v"
        icon.TextColor3 = Color3.fromRGB(150,150,150)
        icon.Font = Enum.Font.GothamBold
        
        local content = Instance.new("Frame", container)
        content.Size = UDim2.new(1, -10, 0, contentSize)
        content.Position = UDim2.new(0, 5, 0, 40)
        content.BackgroundTransparency = 1
        
        local isOpen = false
        headerBtn.MouseButton1Click:Connect(function()
            isOpen = not isOpen
            icon.Text = isOpen and "^" or "v"
            TweenService:Create(container, TweenInfo.new(0.3, Enum.EasingStyle.Quad), {
                Size = UDim2.new(0.95, 0, 0, isOpen and (contentSize + 45) or 35)
            }):Play()
        end)
        
        return content
    end

    local moveContent = createDropdown("Movement Controls", 110)
    
    local function createInputRow(parent, labelText, defaultVal, yPos, callback)
        local lbl = Instance.new("TextLabel", parent)
        lbl.Position = UDim2.new(0, 0, 0, yPos)
        lbl.Size = UDim2.new(0.5, 0, 0, 25)
        lbl.BackgroundTransparency = 1
        lbl.Text = labelText
        lbl.TextColor3 = Color3.fromRGB(200,200,200)
        lbl.Font = Enum.Font.Gotham
        lbl.TextXAlignment = Enum.TextXAlignment.Left
        lbl.TextSize = 11

        local input = Instance.new("TextBox", parent)
        input.Name = "Input_"..labelText -- Naming for restoration
        input.Size = UDim2.new(0, 40, 0, 25)
        input.Position = UDim2.new(0.5, 0, 0, yPos)
        input.BackgroundColor3 = Color3.fromRGB(50,50,55)
        input.Text = defaultVal
        input.TextColor3 = Color3.new(1,1,1)
        createCorner(input, 4)

        local btn = Instance.new("TextButton", parent)
        btn.Size = UDim2.new(0.3, 0, 0, 25)
        btn.Position = UDim2.new(0.7, -5, 0, yPos)
        btn.BackgroundColor3 = UI_COLOR
        btn.Text = "SET"
        btn.TextColor3 = Color3.new(1,1,1)
        btn.Font = Enum.Font.GothamBold
        btn.TextSize = 10
        createCorner(btn, 4)
        RegisterTheme(btn, "BackgroundColor3")

        btn.MouseButton1Click:Connect(function()
            callback(tonumber(input.Text))
        end)
    end

    createInputRow(moveContent, "WalkSpeed", "16", 0, function(val)
        if player.Character and player.Character:FindFirstChild("Humanoid") then
            player.Character.Humanoid.WalkSpeed = val or 16
            CurrentConfig.Features.WalkSpeed = val or 16 -- Save State
        end
    end)

    createInputRow(moveContent, "JumpPower", "50", 35, function(val)
        if player.Character and player.Character:FindFirstChild("Humanoid") then
            player.Character.Humanoid.UseJumpPower = true
            player.Character.Humanoid.JumpPower = val or 50
            CurrentConfig.Features.JumpPower = val or 50 -- Save State
        end
    end)

    local infLabel = Instance.new("TextLabel", moveContent)
    infLabel.Position = UDim2.new(0, 0, 0, 75)
    infLabel.Size = UDim2.new(0.7, 0, 0, 25)
    infLabel.BackgroundTransparency = 1
    infLabel.Text = "Infinite Jump"
    infLabel.TextColor3 = Color3.fromRGB(200,200,200)
    infLabel.Font = Enum.Font.Gotham
    infLabel.TextXAlignment = Enum.TextXAlignment.Left
    infLabel.TextSize = 11

    local infToggle = Instance.new("TextButton", moveContent)
    infToggle.Size = UDim2.new(0, 50, 0, 25)
    infToggle.Position = UDim2.new(1, -55, 0, 75)
    infToggle.BackgroundColor3 = Color3.fromRGB(60,60,60)
    infToggle.Text = "OFF"
    infToggle.TextColor3 = Color3.fromRGB(200,200,200)
    infToggle.Font = Enum.Font.GothamBold
    infToggle.TextSize = 10
    createCorner(infToggle, 12)

    local function ToggleInfJumpUI(state)
        infJumpEnabled = state
        CurrentConfig.Features.InfJump = state -- Save State
        if infJumpEnabled then
            infToggle.BackgroundColor3 = UI_COLOR
            infToggle.Text = "ON"
            infToggle.TextColor3 = Color3.new(1,1,1)
            RegisterTheme(infToggle, "BackgroundColor3")
        else
            infToggle.BackgroundColor3 = Color3.fromRGB(60,60,60)
            infToggle.Text = "OFF"
            infToggle.TextColor3 = Color3.fromRGB(200,200,200)
        end
    end

    infToggle.MouseButton1Click:Connect(function()
        ToggleInfJumpUI(not infJumpEnabled)
    end)

    -- 2. RTX & WEATHER DROPDOWN (NEW INTEGRATION)
    local rtxContentSize = (#weatherPresets * 40) + 10
    local rtxContent = createDropdown("RTX Graphics & Weather", rtxContentSize)
    
    local rtxScroll = Instance.new("ScrollingFrame", rtxContent)
    rtxScroll.Size = UDim2.new(1, 0, 1, 0)
    rtxScroll.BackgroundTransparency = 1
    rtxScroll.BorderSizePixel = 0
    rtxScroll.ScrollBarThickness = 2
    rtxScroll.CanvasSize = UDim2.new(0, 0, 0, rtxContentSize)
    
    local rtxLayout = Instance.new("UIListLayout", rtxScroll)
    rtxLayout.Padding = UDim.new(0, 5)
    
    for i, preset in ipairs(weatherPresets) do
        local btn = Instance.new("TextButton", rtxScroll)
        btn.Size = UDim2.new(1, -10, 0, 35)
        btn.BackgroundColor3 = CARD_COLOR
        btn.Text = ""
        createCorner(btn, 6)
        
        -- Color Indicator
        local ind = Instance.new("Frame", btn)
        ind.Size = UDim2.new(0, 4, 1, 0)
        ind.BackgroundColor3 = preset.color
        createCorner(ind, 2)
        
        local title = Instance.new("TextLabel", btn)
        title.Size = UDim2.new(1, -20, 1, 0)
        title.Position = UDim2.new(0, 15, 0, 0)
        title.BackgroundTransparency = 1
        title.Text = preset.name
        title.TextColor3 = Color3.new(1,1,1)
        title.Font = Enum.Font.GothamSemibold
        title.TextSize = 11
        title.TextXAlignment = Enum.TextXAlignment.Left
        
        btn.MouseButton1Click:Connect(function()
            SetWeather(preset)
        end)
    end

    -- 3. INF YIELD BUTTON
    local yieldBtn = Instance.new("TextButton", PageMisc)
    yieldBtn.Size = UDim2.new(0.95, 0, 0, 40)
    yieldBtn.BackgroundColor3 = CARD_COLOR
    yieldBtn.BackgroundTransparency = 0.2
    yieldBtn.Text = ""
    yieldBtn.AutoButtonColor = true
    createCorner(yieldBtn, 6)
    createStroke(yieldBtn, Color3.fromRGB(80, 80, 90), 1)

    local yieldIcon = Instance.new("ImageLabel", yieldBtn)
    yieldIcon.Size = UDim2.new(0, 20, 0, 20)
    yieldIcon.Position = UDim2.new(0, 10, 0.5, 0)
    yieldIcon.AnchorPoint = Vector2.new(0, 0.5)
    yieldIcon.BackgroundTransparency = 1
    yieldIcon.Image = "rbxassetid://13845014801"
    yieldIcon.ImageColor3 = Color3.fromRGB(100, 200, 255)

    local yieldTitle = Instance.new("TextLabel", yieldBtn)
    yieldTitle.Size = UDim2.new(0, 150, 1, 0)
    yieldTitle.Position = UDim2.new(0, 40, 0, 0)
    yieldTitle.BackgroundTransparency = 1
    yieldTitle.Text = "Infinite Yield (Tools)"
    yieldTitle.TextColor3 = Color3.new(1,1,1)
    yieldTitle.Font = Enum.Font.GothamBold
    yieldTitle.TextSize = 12
    yieldTitle.TextXAlignment = Enum.TextXAlignment.Left

    local yieldAction = Instance.new("TextLabel", yieldBtn)
    yieldAction.Size = UDim2.new(0, 60, 0, 20)
    yieldAction.Position = UDim2.new(1, -70, 0.5, 0)
    yieldAction.AnchorPoint = Vector2.new(0, 0.5)
    yieldAction.BackgroundColor3 = Color3.fromRGB(40, 140, 80)
    yieldAction.Text = "EXECUTE"
    yieldAction.TextColor3 = Color3.new(1,1,1)
    yieldAction.Font = Enum.Font.GothamBold
    yieldAction.TextSize = 9
    createCorner(yieldAction, 4)

    yieldBtn.MouseButton1Click:Connect(function()
        notify("Tool", "Injecting Infinite Yield...", 2)
        local s, e = pcall(function() 
            loadstring(game:HttpGet("https://raw.githubusercontent.com/edgeiy/infiniteyield/master/source"))() 
        end)
        if s then
            yieldAction.Text = "ACTIVE"
            yieldAction.BackgroundColor3 = Color3.fromRGB(60,60,60)
        else
            notify("Error", "Failed to load Inf yield", 3)
        end
    end)

    -- 4. ANTI-AFK
    local afkBtn = Instance.new("TextButton", PageMisc)
    afkBtn.Size = UDim2.new(0.95, 0, 0, 40)
    afkBtn.BackgroundColor3 = CARD_COLOR
    afkBtn.BackgroundTransparency = 0.2
    afkBtn.Text = ""
    afkBtn.AutoButtonColor = true
    createCorner(afkBtn, 6)
    createStroke(afkBtn, Color3.fromRGB(80, 80, 90), 1)

    local afkIcon = Instance.new("ImageLabel", afkBtn)
    afkIcon.Size = UDim2.new(0, 20, 0, 20)
    afkIcon.Position = UDim2.new(0, 10, 0.5, 0)
    afkIcon.AnchorPoint = Vector2.new(0, 0.5)
    afkIcon.BackgroundTransparency = 1
    afkIcon.Image = "rbxassetid://11326665726"
    afkIcon.ImageColor3 = Color3.fromRGB(100, 255, 150)

    local afkTitle = Instance.new("TextLabel", afkBtn)
    afkTitle.Size = UDim2.new(0, 150, 1, 0)
    afkTitle.Position = UDim2.new(0, 40, 0, 0)
    afkTitle.BackgroundTransparency = 1
    afkTitle.Text = "Anti-AFK System"
    afkTitle.TextColor3 = Color3.new(1,1,1)
    afkTitle.Font = Enum.Font.GothamBold
    afkTitle.TextSize = 12
    afkTitle.TextXAlignment = Enum.TextXAlignment.Left

    local afkStatus = Instance.new("TextLabel", afkBtn)
    afkStatus.Size = UDim2.new(0, 60, 0, 20)
    afkStatus.Position = UDim2.new(1, -70, 0.5, 0)
    afkStatus.AnchorPoint = Vector2.new(0, 0.5)
    afkStatus.BackgroundColor3 = Color3.fromRGB(60, 60, 60)
    afkStatus.Text = "OFF"
    afkStatus.TextColor3 = Color3.fromRGB(200, 200, 200)
    afkStatus.Font = Enum.Font.GothamBold
    afkStatus.TextSize = 9
    createCorner(afkStatus, 4)
    RegisterTheme(afkStatus, "BackgroundColor3")

    local function toggleAntiAfk(state)
        afkEnabled = state
        CurrentConfig.Features.AntiAFK = state -- Save State
        
        if afkEnabled then
            afkStatus.Text = "ACTIVE"
            afkStatus.TextColor3 = Color3.new(1,1,1)
            afkStatus.BackgroundColor3 = UI_COLOR
            notify("System", "Anti-AFK Started!", 2)

            task.spawn(function()
                local interval = 120
                local clickCount = 5
                
                while afkEnabled do
                    task.wait(interval)
                    if not afkEnabled then break end
                    
                    pcall(function()
                        notify("Anti-AFK", "Performing action...", 1)
                        local camera = Workspace.CurrentCamera
                        local viewportSize = camera.ViewportSize
                        local guiInset = GuiService:GetGuiInset()
                        local centerX = viewportSize.X / 2
                        local centerY = (viewportSize.Y / 2) + guiInset.Y
                        
                        for i = 1, clickCount do
                            if not afkEnabled then break end
                            VirtualInputManager:SendMouseButtonEvent(centerX, centerY, 0, true, game, 1)
                            task.wait(0.05)
                            VirtualInputManager:SendMouseButtonEvent(centerX, centerY, 0, false, game, 1)
                            task.wait(0.5)
                        end
                    end)
                end
            end)
        else
            afkStatus.Text = "OFF"
            afkStatus.TextColor3 = Color3.fromRGB(200, 200, 200)
            afkStatus.BackgroundColor3 = Color3.fromRGB(60, 60, 60)
            notify("System", "Anti-AFK Stopped.", 2)
        end
    end

    afkBtn.MouseButton1Click:Connect(function()
        toggleAntiAfk(not afkEnabled)
    end)

    -- Separator
    local settingSep = Instance.new("Frame", PageMisc)
    settingSep.Size = UDim2.new(0.95, 0, 0, 2)
    settingSep.BackgroundColor3 = Color3.fromRGB(60,60,70)
    settingSep.BorderSizePixel = 0
    -- [NOTE] THEME BUTTON REMOVED FROM MISC, MOVED TO SETTINGS UI BELOW

    -- ===================================
    -- :: TAB 5: SETTINGS UI (NEW) ::
    -- ===================================
    local PageSettings = CreatePage("Settings UI")

    -- 1. THEME CARD (Moved from Misc)
    local ThemeCard = Instance.new("Frame", PageSettings)
    ThemeCard.Size = UDim2.new(0.95, 0, 0, 80) -- Bigger card
    ThemeCard.BackgroundColor3 = CARD_COLOR
    ThemeCard.BackgroundTransparency = 0.2
    createCorner(ThemeCard, 8)
    local tcStroke = createStroke(ThemeCard, UI_COLOR, 1)
    RegisterTheme(tcStroke, "Color")

    local ThemeTitle = Instance.new("TextLabel", ThemeCard)
    ThemeTitle.Size = UDim2.new(1, -20, 0, 25)
    ThemeTitle.Position = UDim2.new(0, 15, 0, 5)
    ThemeTitle.BackgroundTransparency = 1
    ThemeTitle.Text = "INTERFACE THEME"
    ThemeTitle.TextColor3 = Color3.fromRGB(150, 150, 150)
    ThemeTitle.Font = Enum.Font.GothamBold
    ThemeTitle.TextSize = 10
    ThemeTitle.TextXAlignment = Enum.TextXAlignment.Left

    local ThemeDesc = Instance.new("TextLabel", ThemeCard)
    ThemeDesc.Size = UDim2.new(1, -20, 0, 20)
    ThemeDesc.Position = UDim2.new(0, 15, 0, 25)
    ThemeDesc.BackgroundTransparency = 1
    ThemeDesc.Text = "Customize the menu accent color and style."
    ThemeDesc.TextColor3 = Color3.new(1,1,1)
    ThemeDesc.Font = Enum.Font.Gotham
    ThemeDesc.TextSize = 12
    ThemeDesc.TextXAlignment = Enum.TextXAlignment.Left

    local OpenThemeBtn = Instance.new("TextButton", ThemeCard)
    OpenThemeBtn.Size = UDim2.new(0, 120, 0, 30)
    OpenThemeBtn.Position = UDim2.new(1, -135, 0.5, 0)
    OpenThemeBtn.AnchorPoint = Vector2.new(0, 0.5)
    OpenThemeBtn.BackgroundColor3 = UI_COLOR
    OpenThemeBtn.Text = "Open Config"
    OpenThemeBtn.TextColor3 = Color3.new(1,1,1)
    OpenThemeBtn.Font = Enum.Font.GothamBold
    OpenThemeBtn.TextSize = 11
    createCorner(OpenThemeBtn, 6)
    RegisterTheme(OpenThemeBtn, "BackgroundColor3")

    OpenThemeBtn.MouseButton1Click:Connect(function()
        ThemeOverlay.Visible = true -- Open Modal
    end)

    -- 2. UI CONFIG SETTINGS CARD (NEW)
    local ConfigCard = Instance.new("Frame", PageSettings)
    ConfigCard.Size = UDim2.new(0.95, 0, 0, 120) -- Slightly Taller for Dropdown
    ConfigCard.Position = UDim2.new(0, 0, 0, 90) -- Below Theme Card
    ConfigCard.BackgroundColor3 = CARD_COLOR
    ConfigCard.BackgroundTransparency = 0.2
    createCorner(ConfigCard, 8)
    createStroke(ConfigCard, Color3.fromRGB(60,60,70), 1)

    local ConfigTitle = Instance.new("TextLabel", ConfigCard)
    ConfigTitle.Size = UDim2.new(1, -20, 0, 25)
    ConfigTitle.Position = UDim2.new(0, 15, 0, 5)
    ConfigTitle.BackgroundTransparency = 1
    ConfigTitle.Text = "UI CONFIG SETTINGS"
    ConfigTitle.TextColor3 = Color3.fromRGB(150, 150, 150)
    ConfigTitle.Font = Enum.Font.GothamBold
    ConfigTitle.TextSize = 10
    ConfigTitle.TextXAlignment = Enum.TextXAlignment.Left

    -- Save Button
    local SaveConfigBtn = Instance.new("TextButton", ConfigCard)
    SaveConfigBtn.Size = UDim2.new(0.4, 0, 0, 30)
    SaveConfigBtn.Position = UDim2.new(0, 15, 0, 35)
    SaveConfigBtn.BackgroundColor3 = UI_COLOR
    SaveConfigBtn.Text = "Save Config"
    SaveConfigBtn.TextColor3 = Color3.new(1,1,1)
    SaveConfigBtn.Font = Enum.Font.GothamBold
    SaveConfigBtn.TextSize = 11
    createCorner(SaveConfigBtn, 6)
    RegisterTheme(SaveConfigBtn, "BackgroundColor3")

    -- Dropdown Container
    local DropdownContainer = Instance.new("Frame", ConfigCard)
    DropdownContainer.Size = UDim2.new(0.5, 0, 0, 30)
    DropdownContainer.Position = UDim2.new(0.45, 0, 0, 35)
    DropdownContainer.BackgroundColor3 = Color3.fromRGB(25, 25, 30)
    createCorner(DropdownContainer, 6)
    createStroke(DropdownContainer, Color3.fromRGB(60, 60, 70), 1)

    local SelectedFileLabel = Instance.new("TextLabel", DropdownContainer)
    SelectedFileLabel.Size = UDim2.new(0.8, 0, 1, 0)
    SelectedFileLabel.Position = UDim2.new(0, 5, 0, 0)
    SelectedFileLabel.BackgroundTransparency = 1
    SelectedFileLabel.Text = "Select Config..."
    SelectedFileLabel.TextColor3 = Color3.fromRGB(200, 200, 200)
    SelectedFileLabel.Font = Enum.Font.Gotham
    SelectedFileLabel.TextSize = 10
    SelectedFileLabel.TextXAlignment = Enum.TextXAlignment.Left
    SelectedFileLabel.TextTruncate = Enum.TextTruncate.AtEnd

    local DropdownBtn = Instance.new("TextButton", DropdownContainer)
    DropdownBtn.Size = UDim2.new(1, 0, 1, 0)
    DropdownBtn.BackgroundTransparency = 1
    DropdownBtn.Text = ""
    
    local DropArrow = Instance.new("TextLabel", DropdownContainer)
    DropArrow.Size = UDim2.new(0, 20, 1, 0)
    DropArrow.Position = UDim2.new(1, -20, 0, 0)
    DropArrow.BackgroundTransparency = 1
    DropArrow.Text = "v"
    DropArrow.TextColor3 = Color3.fromRGB(150, 150, 150)
    DropArrow.Font = Enum.Font.GothamBold
    DropArrow.TextSize = 10

    -- Dropdown List (Hidden by default)
    local ConfigListFrame = Instance.new("ScrollingFrame", ScreenGui) -- Parent to ScreenGui to overlay everything
    ConfigListFrame.Name = "ConfigDropdownList"
    ConfigListFrame.Size = UDim2.new(0, 0, 0, 0) -- Animated later
    ConfigListFrame.BackgroundColor3 = Color3.fromRGB(30, 30, 35)
    ConfigListFrame.Visible = false
    ConfigListFrame.ZIndex = 150
    ConfigListFrame.ClipsDescendants = true
    ConfigListFrame.ScrollBarThickness = 2
    createCorner(ConfigListFrame, 6)
    createStroke(ConfigListFrame, UI_COLOR, 1)

    local ConfigListLayout = Instance.new("UIListLayout", ConfigListFrame)
    ConfigListLayout.SortOrder = Enum.SortOrder.LayoutOrder
    ConfigListLayout.Padding = UDim.new(0, 2)

    -- Load Button
    local LoadConfigBtn = Instance.new("TextButton", ConfigCard)
    LoadConfigBtn.Size = UDim2.new(0.94, 0, 0, 30)
    LoadConfigBtn.Position = UDim2.new(0, 15, 0, 75)
    LoadConfigBtn.BackgroundColor3 = Color3.fromRGB(50, 50, 50) -- Disabled state
    LoadConfigBtn.Text = "LOAD"
    LoadConfigBtn.TextColor3 = Color3.fromRGB(150, 150, 150)
    LoadConfigBtn.Font = Enum.Font.GothamBold
    LoadConfigBtn.TextSize = 11
    LoadConfigBtn.AutoButtonColor = false
    createCorner(LoadConfigBtn, 6)

    -- MODAL: SAVE CONFIG (Pop Up)
    local ConfigSaveModal = Instance.new("Frame", ScreenGui)
    ConfigSaveModal.Name = "ConfigSaveModal"
    ConfigSaveModal.Size = UDim2.fromOffset(280, 160)
    ConfigSaveModal.Position = UDim2.fromScale(0.5, 0.5)
    ConfigSaveModal.AnchorPoint = Vector2.new(0.5, 0.5)
    ConfigSaveModal.BackgroundColor3 = BG_COLOR
    ConfigSaveModal.Visible = false
    ConfigSaveModal.ZIndex = 200
    createCorner(ConfigSaveModal, 10)
    local csmStroke = createStroke(ConfigSaveModal, UI_COLOR, 2)
    RegisterTheme(csmStroke, "Color")

    local CSMTitle = Instance.new("TextLabel", ConfigSaveModal)
    CSMTitle.Size = UDim2.new(1, 0, 0, 35)
    CSMTitle.BackgroundTransparency = 1
    CSMTitle.Text = "SAVE YOUR UI CONFIG"
    CSMTitle.Font = Enum.Font.GothamBlack
    CSMTitle.TextSize = 14
    CSMTitle.TextColor3 = Color3.new(1,1,1)

    local CSMClose = Instance.new("TextButton", ConfigSaveModal)
    CSMClose.Size = UDim2.new(0, 30, 0, 30)
    CSMClose.Position = UDim2.new(1, -35, 0, 2)
    CSMClose.BackgroundColor3 = Color3.fromRGB(150, 60, 60)
    CSMClose.Text = "X"
    CSMClose.TextColor3 = Color3.new(1,1,1)
    createCorner(CSMClose, 4)

    CSMClose.MouseButton1Click:Connect(function() ConfigSaveModal.Visible = false; ToggleBlur(true) end) -- Keep blur if main UI is open

    local CSMInput = Instance.new("TextBox", ConfigSaveModal)
    CSMInput.Size = UDim2.new(0.8, 0, 0, 35)
    CSMInput.Position = UDim2.new(0.1, 0, 0, 55)
    CSMInput.BackgroundColor3 = Color3.fromRGB(40,40,45)
    CSMInput.PlaceholderText = "Config Name (Max 12)..."
    CSMInput.Text = ""
    CSMInput.TextColor3 = Color3.new(1,1,1)
    CSMInput.Font = Enum.Font.Gotham
    createCorner(CSMInput, 6)
    
    CSMInput:GetPropertyChangedSignal("Text"):Connect(function()
        local txt = CSMInput.Text
        local clean = txt:gsub("[^%w]", "") -- Alphanumeric only
        if #clean > 12 then clean = clean:sub(1, 12) end
        if CSMInput.Text ~= clean then CSMInput.Text = clean end
    end)

    local CSMSaveBtn = Instance.new("TextButton", ConfigSaveModal)
    CSMSaveBtn.Size = UDim2.new(0.6, 0, 0, 30)
    CSMSaveBtn.Position = UDim2.new(0.2, 0, 0, 110)
    CSMSaveBtn.BackgroundColor3 = UI_COLOR
    CSMSaveBtn.Text = "SAVE"
    CSMSaveBtn.TextColor3 = Color3.new(1,1,1)
    CSMSaveBtn.Font = Enum.Font.GothamBold
    createCorner(CSMSaveBtn, 6)
    RegisterTheme(CSMSaveBtn, "BackgroundColor3")

    -- LOGIC: CONFIG FUNCTIONS

    local function ApplyConfig(data)
        if not data then return end
        
        -- 1. Apply UI Theme
        if data.UI and data.UI.Theme then
            local c = data.UI.Theme
            UpdateAllTheme(Color3.fromRGB(c.R, c.G, c.B))
        end

        -- 2. Apply UI Position
        if data.UI and data.UI.Position then
            MainFrame.Position = UDim2.fromScale(data.UI.Position.X, data.UI.Position.Y)
        end

        -- 3. Apply Features
        if data.Features then
            -- Anti AFK
            if data.Features.AntiAFK ~= afkEnabled then
                toggleAntiAfk(data.Features.AntiAFK)
            end
            
            -- Inf Jump
            if data.Features.InfJump ~= infJumpEnabled then
                ToggleInfJumpUI(data.Features.InfJump)
            end

            -- WalkSpeed & JumpPower
            if data.Features.WalkSpeed then
                -- Update input box text
                local input = moveContent:FindFirstChild("Input_WalkSpeed")
                if input then input.Text = tostring(data.Features.WalkSpeed) end
                if player.Character and player.Character:FindFirstChild("Humanoid") then
                    player.Character.Humanoid.WalkSpeed = data.Features.WalkSpeed
                end
                CurrentConfig.Features.WalkSpeed = data.Features.WalkSpeed
            end
             if data.Features.JumpPower then
                local input = moveContent:FindFirstChild("Input_JumpPower")
                if input then input.Text = tostring(data.Features.JumpPower) end
                 if player.Character and player.Character:FindFirstChild("Humanoid") then
                    player.Character.Humanoid.UseJumpPower = true
                    player.Character.Humanoid.JumpPower = data.Features.JumpPower
                end
                CurrentConfig.Features.JumpPower = data.Features.JumpPower
            end
            
            -- RTX Preset
            if data.Features.RTXPreset then
                for _, preset in ipairs(weatherPresets) do
                    if preset.name == data.Features.RTXPreset then
                        SetWeather(preset)
                        break
                    end
                end
            end
        end

        -- 4. Switch Tab
        if data.UI and data.UI.LastTab then
             SwitchTab(data.UI.LastTab)
        end
        
        notify("Config", "Configuration Loaded!", 2)
    end

    local selectedConfigFile = nil

    SaveConfigBtn.MouseButton1Click:Connect(function()
        ConfigSaveModal.Visible = true
        CSMInput.Text = ""
    end)

    CSMSaveBtn.MouseButton1Click:Connect(function()
        if CSMInput.Text == "" then return end
        local fileName = "XuKrost_Config_" .. CSMInput.Text .. ".json"
        
        -- Update Current Config Data before saving
        CurrentConfig.UI.LastTab = CurrentConfig.UI.LastTab or "Settings UI"
        
        if writefile then
            local encoded = HttpService:JSONEncode(CurrentConfig)
            writefile(fileName, encoded)
            notify("Config", "Saved as " .. CSMInput.Text, 2)
            ConfigSaveModal.Visible = false
        else
            notify("Error", "Executor does not support writefile", 3)
        end
    end)

    local isDropdownOpen = false
    DropdownBtn.MouseButton1Click:Connect(function()
        isDropdownOpen = not isDropdownOpen
        
        if isDropdownOpen then
            -- Position list relative to dropdown button absolute position
            local absPos = DropdownContainer.AbsolutePosition
            local absSize = DropdownContainer.AbsoluteSize
            ConfigListFrame.Position = UDim2.fromOffset(absPos.X, absPos.Y + absSize.Y + 5)
            ConfigListFrame.Size = UDim2.fromOffset(absSize.X, 0)
            ConfigListFrame.Visible = true
            
            -- Populate List
            for _, child in pairs(ConfigListFrame:GetChildren()) do
                if child:IsA("TextButton") then child:Destroy() end
            end
            
            local files = {}
            if listfiles then
                pcall(function() files = listfiles("") end)
            end
            
            local count = 0
            for _, file in pairs(files) do
                if file:find("XuKrost_Config_") and file:find(".json") then
                    count = count + 1
                    local cleanName = file:match("XuKrost_Config_(.-)%.json") or file
                    
                    local btn = Instance.new("TextButton", ConfigListFrame)
                    btn.Size = UDim2.new(1, 0, 0, 25)
                    btn.BackgroundColor3 = Color3.fromRGB(40,40,45)
                    btn.Text = cleanName
                    btn.TextColor3 = Color3.fromRGB(200,200,200)
                    btn.Font = Enum.Font.Gotham
                    btn.TextSize = 10
                    
                    btn.MouseButton1Click:Connect(function()
                        selectedConfigFile = file
                        SelectedFileLabel.Text = cleanName
                        isDropdownOpen = false
                        ConfigListFrame.Visible = false
                        
                        -- Enable Load Button
                        LoadConfigBtn.BackgroundColor3 = UI_COLOR
                        LoadConfigBtn.TextColor3 = Color3.new(1,1,1)
                        RegisterTheme(LoadConfigBtn, "BackgroundColor3")
                        LoadConfigBtn.AutoButtonColor = true
                    end)
                end
            end
            
            ConfigListFrame.CanvasSize = UDim2.new(0,0,0, count * 27)
            TweenService:Create(ConfigListFrame, TweenInfo.new(0.2), {Size = UDim2.fromOffset(absSize.X, 100)}):Play()
        else
            ConfigListFrame.Visible = false
        end
    end)

    LoadConfigBtn.MouseButton1Click:Connect(function()
        if selectedConfigFile and readfile and isfile(selectedConfigFile) then
            local success, content = pcall(function() return readfile(selectedConfigFile) end)
            if success and content then
                local data = HttpService:JSONDecode(content)
                ApplyConfig(data)
            else
                notify("Error", "Failed to read file", 2)
            end
        end
    end)


    -- =========================================
    -- :: TAB 6: CREDITS ::
    -- =========================================
    local PageCredits = CreatePage("Credits")
    
    local function createCreditCard(height)
        local card = Instance.new("Frame", PageCredits)
        card.Size = UDim2.new(0.95, 0, 0, height)
        card.BackgroundColor3 = CARD_COLOR
        card.BackgroundTransparency = 0.2
        createCorner(card, 8)
        createStroke(card, Color3.fromRGB(60,60,70), 1)
        createGradient(card)
        return card
    end

    local DevCard = createCreditCard(60)
    
    local DevTitle = Instance.new("TextLabel", DevCard)
    DevTitle.Position = UDim2.new(0, 15, 0, 10)
    DevTitle.Size = UDim2.new(1, -30, 0, 15)
    DevTitle.BackgroundTransparency = 1
    DevTitle.Text = "Lead Developer"
    DevTitle.TextColor3 = Color3.fromRGB(150, 150, 150)
    DevTitle.Font = Enum.Font.GothamBold
    DevTitle.TextSize = 10
    DevTitle.TextXAlignment = Enum.TextXAlignment.Left

    local DevName = Instance.new("TextLabel", DevCard)
    DevName.Position = UDim2.new(0, 15, 0, 25)
    DevName.Size = UDim2.new(1, -30, 0, 25)
    DevName.BackgroundTransparency = 1
    DevName.Text = CreatorText
    DevName.TextColor3 = Color3.new(1,1,1)
    DevName.Font = Enum.Font.GothamBlack
    DevName.TextSize = 16
    DevName.TextXAlignment = Enum.TextXAlignment.Left

    local InfoCard = createCreditCard(80)
    
    local InfoTitle = Instance.new("TextLabel", InfoCard)
    InfoTitle.Position = UDim2.new(0, 15, 0, 10)
    InfoTitle.Size = UDim2.new(1, -30, 0, 15)
    InfoTitle.BackgroundTransparency = 1
    InfoTitle.Text = "Hub Information"
    InfoTitle.TextColor3 = Color3.fromRGB(150, 150, 150)
    InfoTitle.Font = Enum.Font.GothamBold
    InfoTitle.TextSize = 10
    InfoTitle.TextXAlignment = Enum.TextXAlignment.Left

    local InfoVer = Instance.new("TextLabel", InfoCard)
    InfoVer.Position = UDim2.new(0, 15, 0, 30)
    InfoVer.Size = UDim2.new(1, -30, 0, 20)
    InfoVer.BackgroundTransparency = 1
    InfoVer.Text = "Version: " .. Version
    InfoVer.TextColor3 = UI_COLOR
    RegisterTheme(InfoVer, "TextColor3")
    InfoVer.Font = Enum.Font.Code
    InfoVer.TextSize = 12
    InfoVer.TextXAlignment = Enum.TextXAlignment.Left

    local InfoDesc = Instance.new("TextLabel", InfoCard)
    InfoDesc.Position = UDim2.new(0, 15, 0, 50)
    InfoDesc.Size = UDim2.new(1, -30, 0, 20)
    InfoDesc.BackgroundTransparency = 1
    InfoDesc.Text = "A simple yet powerful script hub."
    InfoDesc.TextColor3 = Color3.fromRGB(200,200,220)
    InfoDesc.Font = Enum.Font.Gotham
    InfoDesc.TextSize = 11
    InfoDesc.TextXAlignment = Enum.TextXAlignment.Left

    local DiscordBtn = Instance.new("TextButton", PageCredits)
    DiscordBtn.Size = UDim2.new(0.95, 0, 0, 45)
    DiscordBtn.BackgroundColor3 = Color3.fromRGB(88, 101, 242)
    DiscordBtn.Text = ""
    DiscordBtn.AutoButtonColor = true
    createCorner(DiscordBtn, 8)
    
    local DiscIcon = Instance.new("ImageLabel", DiscordBtn)
    DiscIcon.Size = UDim2.fromOffset(25, 25)
    DiscIcon.Position = UDim2.new(0, 15, 0.5, 0)
    DiscIcon.AnchorPoint = Vector2.new(0, 0.5)
    DiscIcon.BackgroundTransparency = 1
    DiscIcon.Image = "rbxassetid://10057262016"
    
    local DiscText = Instance.new("TextLabel", DiscordBtn)
    DiscText.Size = UDim2.new(0, 100, 1, 0)
    DiscText.Position = UDim2.new(0, 50, 0, 0)
    DiscText.BackgroundTransparency = 1
    DiscText.Text = "Join Community"
    DiscText.TextColor3 = Color3.new(1,1,1)
    DiscText.Font = Enum.Font.GothamBold
    DiscText.TextSize = 14
    DiscText.TextXAlignment = Enum.TextXAlignment.Left

    local DiscSub = Instance.new("TextLabel", DiscordBtn)
    DiscSub.Size = UDim2.new(0, 100, 1, 0)
    DiscSub.Position = UDim2.new(1, -115, 0, 0)
    DiscSub.BackgroundTransparency = 1
    DiscSub.Text = "Click to Copy"
    DiscSub.TextColor3 = Color3.fromRGB(200,200,220)
    DiscSub.Font = Enum.Font.Gotham
    DiscSub.TextSize = 10
    DiscSub.TextXAlignment = Enum.TextXAlignment.Right

    DiscordBtn.MouseButton1Click:Connect(function()
        setclipboard("https://discord.gg/RpYcMdzzwd")
        notify("Discord", "Invite link copied!", 3)
        DiscSub.Text = "Copied!"
        wait(1)
        DiscSub.Text = "Click to Copy"
    end)

    local Footer = Instance.new("TextLabel", PageCredits)
    Footer.Size = UDim2.new(0.95, 0, 0, 20)
    Footer.BackgroundTransparency = 1
    Footer.Text = "© 2024 XuKrost Hub. All rights reserved."
    Footer.TextColor3 = Color3.fromRGB(100, 100, 100)
    Footer.Font = Enum.Font.Gotham
    Footer.TextSize = 10

    SwitchTab("Main Scripts") -- Default Tab
end

-- --- INITIALIZATION ---

notify(HubName, "Loading resources...", 2)
isVIP = checkVIP()

if isVIP then
    notify("VIP System", "Welcome back, VIP User!", 4)
    spawnMainHub()
else
    spawnKeySystem(function()
        keyAuthorized = true
        notify("System", "Key Authorized. Loading Hub...", 2)
        spawnMainHub()
    end)
end
