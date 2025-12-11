-- Script: Name Animation System with VIP Status
local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local HttpService = game:GetService("HttpService")
local LocalPlayer = Players.LocalPlayer

local activeConnection = nil
local vipStatusChecked = false
local isVIP = false

-- Fungsi untuk cek status VIP
local function checkVIPStatus()
    local userId = tostring(LocalPlayer.UserId)
    local vipUrl = "https://raw.githubusercontent.com/xhub-ui/x-loaders/refs/heads/main/loader/redirects/vip-system/vip-users.txt"
    
    -- Update status menjadi loading
    _G.VIPStatus = "Loading..."
    
    local success, result = pcall(function()
        return game:HttpGet(vipUrl)
    end)
    
    if success then
        -- Split hasil menjadi table user IDs
        local vipUsers = {}
        for line in result:gmatch("[^\r\n]+") do
            vipUsers[line:gsub("%s+", "")] = true
        end
        
        -- Cek apakah user ID ada dalam daftar VIP
        if vipUsers[userId] then
            _G.VIPStatus = "VIP User"
            isVIP = true
            return true
        else
            _G.VIPStatus = "Free User"
            isVIP = false
            return false
        end
    else
        _G.VIPStatus = "Error Checking VIP"
        isVIP = false
        return false
    end
end

-- Fungsi untuk hapus nama asli dari karakter lokal dan mencegah kemunculan kembali
local function removeOriginalNameTags(character)
    -- Hapus semua BillboardGui yang bukan custom kita
    for _, descendant in ipairs(character:GetDescendants()) do
        if descendant:IsA("BillboardGui") and descendant.Name ~= "CustomBillboard" then
            descendant:Destroy()
        end
    end
    
    -- Nonaktifkan sistem nama default humanoid
    local humanoid = character:FindFirstChildOfClass("Humanoid")
    if humanoid then
        humanoid.DisplayDistanceType = Enum.HumanoidDisplayDistanceType.None
        humanoid.NameDisplayDistance = 0
        
        -- Monitor terus menerus untuk mencegah nama default muncul kembali
        local nameMonitorConnection
        nameMonitorConnection = RunService.Heartbeat:Connect(function()
            if not character or not character.Parent then
                nameMonitorConnection:Disconnect()
                return
            end
            
            -- Pastikan setting nama tetap nonaktif
            if humanoid.DisplayDistanceType ~= Enum.HumanoidDisplayDistanceType.None then
                humanoid.DisplayDistanceType = Enum.HumanoidDisplayDistanceType.None
            end
            
            if humanoid.NameDisplayDistance > 0 then
                humanoid.NameDisplayDistance = 0
            end
            
            -- Hapus BillboardGui baru yang mungkin dibuat ulang oleh game
            for _, descendant in ipairs(character:GetDescendants()) do
                if descendant:IsA("BillboardGui") and descendant.Name ~= "CustomBillboard" then
                    descendant:Destroy()
                end
            end
        end)
        
        -- Cleanup connection ketika karakter dihancurkan
        character.Destroying:Connect(function()
            if nameMonitorConnection then
                nameMonitorConnection:Disconnect()
            end
        end)
    end
end

-- Fungsi untuk reset nama (hapus fake name)
local function resetName()
    if activeConnection then
        activeConnection:Disconnect()
        activeConnection = nil
    end
    
    if LocalPlayer.Character then
        local head = LocalPlayer.Character:FindFirstChild("Head")
        if head then
            local customBillboard = head:FindFirstChild("CustomBillboard")
            if customBillboard then
                customBillboard:Destroy()
            end
        end
        
        local humanoid = LocalPlayer.Character:FindFirstChildOfClass("Humanoid")
        if humanoid then
            humanoid.DisplayDistanceType = Enum.HumanoidDisplayDistanceType.Viewer
            humanoid.NameDisplayDistance = 100
            humanoid.DisplayName = LocalPlayer.DisplayName
        end
    end
end

-- Fungsi untuk membuat title animasi dengan status VIP
local function createTitle(character)
    local head = character:WaitForChild("Head", 5)
    local humanoid = character:FindFirstChildOfClass("Humanoid")
    if not (head and humanoid) then return end

    -- Sembunyikan nama default secara permanen
    humanoid.DisplayDistanceType = Enum.HumanoidDisplayDistanceType.None
    humanoid.NameDisplayDistance = 0
    humanoid.DisplayName = ""

    -- Tunggu sedikit untuk memastikan semua GUI original sudah ter-load
    task.wait(0.2)
    
    -- Hapus GUI nama asli secara agresif
    removeOriginalNameTags(character)

    -- Hapus title lama jika ada
    local existingTitle = head:FindFirstChild("CustomBillboard")
    if existingTitle then
        existingTitle:Destroy()
    end

    -- Create BillboardGui dengan nama yang konsisten
    local billboard = Instance.new("BillboardGui")
    billboard.Name = "CustomBillboard"
    billboard.Adornee = head
    billboard.Size = UDim2.new(0, 400, 0, 30) -- Increased size for VIP status
    billboard.StudsOffset = Vector3.new(0, 2, 0)
    billboard.AlwaysOnTop = true
    billboard.MaxDistance = 150
    billboard.Enabled = true
    billboard.Parent = head
    
    -- Create UIGradient for animated gradient
    local gradient = Instance.new("UIGradient")
    gradient.Name = "AnimatedGradient"
    gradient.Rotation = 0
    
    -- Main TextLabel
    local textLabel = Instance.new("TextLabel")
    textLabel.Size = UDim2.new(1, 0, 0.5, 0)
	textLabel.Position = UDim2.new(0, 0, 0, 0)
    textLabel.BackgroundTransparency = 1
    textLabel.Text = "dsc.gg/xukrost-hub"
    textLabel.TextColor3 = Color3.new(1, 1, 1)
    textLabel.TextScaled = true
    textLabel.Font = Enum.Font.GothamBold
    textLabel.TextStrokeTransparency = 0.5
    textLabel.TextStrokeColor3 = Color3.new(0, 0, 0)
    textLabel.ZIndex = 2
    textLabel.Parent = billboard
    
    -- VIP Status TextLabel
    local statusLabel = Instance.new("TextLabel")
    statusLabel.Size = UDim2.new(1, 0, 0.3, 0)
    statusLabel.Position = UDim2.new(0, 0, 0.5, 6)
    statusLabel.BackgroundTransparency = 1
    statusLabel.Text = "Player Status: " .. (_G.VIPStatus or "Checking...")
    statusLabel.TextColor3 = isVIP and Color3.fromRGB(0, 255, 0) or Color3.fromRGB(255, 255, 255)
    statusLabel.TextScaled = true
    statusLabel.Font = Enum.Font.Gotham
    statusLabel.TextStrokeTransparency = 0.5
    statusLabel.TextStrokeColor3 = Color3.new(0, 0, 0)
    statusLabel.ZIndex = 2
    statusLabel.Parent = billboard
    
    -- Apply gradient to main text
    gradient.Parent = textLabel
    
    -- Animation variables
    local time = 0
    local animationSpeed = 1.7
    
    -- Color sequence for gradient
    local colorSequence = ColorSequence.new({
        ColorSequenceKeypoint.new(0, Color3.fromRGB(0, 0, 0)),
        ColorSequenceKeypoint.new(0.3, isVIP and Color3.fromRGB(255, 215, 0) or Color3.fromRGB(148, 0, 211)),
        ColorSequenceKeypoint.new(0.7, isVIP and Color3.fromRGB(255, 165, 0) or Color3.fromRGB(30, 144, 255)),
        ColorSequenceKeypoint.new(1, Color3.fromRGB(0, 0, 0))
    })
    
    -- Connection for animation
    local connection
    connection = RunService.Heartbeat:Connect(function(deltaTime)
        if not billboard or not billboard.Parent then
            connection:Disconnect()
            return
        end
        
        time = time + deltaTime * animationSpeed
        gradient.Offset = Vector2.new(math.cos(time) * 0.5, math.sin(time) * 0.3)
        gradient.Rotation = math.sin(time * 0.5) * 15
        gradient.Color = colorSequence
        textLabel.TextScaled = true
        
        -- Update status text dengan animasi loading jika masih checking
        if not vipStatusChecked then
            local loadingTexts = {"Loading...", "Detecting user id", "User id status found"}
            local loadingIndex = math.floor((time * 2) % 3) + 1
            statusLabel.Text = "Player Status: " .. loadingTexts[loadingIndex]
        else
            statusLabel.Text = "Player Status: " .. _G.VIPStatus
            statusLabel.TextColor3 = isVIP and Color3.fromRGB(0, 255, 0) or Color3.fromRGB(255, 255, 255)
        end
    end)
    
    -- Clean up connection when billboard is destroyed
    billboard.Destroying:Connect(function()
        if connection then
            connection:Disconnect()
        end
    end)
end

-- Fungsi untuk mengubah display name
local function changeDisplayName()
    local success, error = pcall(function()
        LocalPlayer.DisplayName = "dsc.gg/xukrost-hub"
    end)
    
    if not success then
        warn("Failed to change display name: " .. error)
    end
end

-- Fungsi untuk menghapus ScreenGui
local function removeScreenGui()
    local playerGui = LocalPlayer:FindFirstChild("PlayerGui")
    if playerGui then
        local nameChangerGUI = playerGui:FindFirstChild("NameChangerGUI")
        if nameChangerGUI then
            nameChangerGUI:Destroy()
        end
    end
end

-- Main execution function
local function executeScript()
    -- Check if script should run
    if not _G["Setting"] or not _G["Setting"]["Tittle Exs"] then
        print("Script execution disabled in settings")
        return
    end
    
    -- Set initial VIP status
    _G.VIPStatus = "Loading..."
    vipStatusChecked = false
    
    -- Panggil fungsi untuk menghapus ScreenGui
    removeScreenGui()

    -- Ubah display name
    changeDisplayName()

    -- Check VIP status secara asynchronous
    spawn(function()
        checkVIPStatus()
        vipStatusChecked = true
        
        -- Update title jika karakter sudah ada
        if LocalPlayer.Character then
            createTitle(LocalPlayer.Character)
        end
    end)

    -- Auto apply to character
    LocalPlayer.CharacterAdded:Connect(function(char)
        task.wait(0.5)
        createTitle(char)
    end)

    -- Handle respawning
    LocalPlayer.CharacterAppearanceLoaded:Connect(function(character)
        task.wait(0.5)
        createTitle(character)
    end)

    if LocalPlayer.Character then
        createTitle(LocalPlayer.Character)
    end

    print("Script successfully loaded and executed!")
    print("VIP Status: " .. (_G.VIPStatus or "Unknown"))
end

-- Run the script
executeScript()