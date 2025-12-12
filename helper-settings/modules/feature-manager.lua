-- feature-manager.lua
-- Combined & Updated for XuKrost Hub
-- Includes: Audio Engine + Optimized Teleport & Execution Logic

local FeatureManager = {}

-- [[ SERVICES ]] --
local TweenService = game:GetService("TweenService")
local RunService = game:GetService("RunService")
local TeleportService = game:GetService("TeleportService")
local Players = game:GetService("Players")
local HttpService = game:GetService("HttpService")
local SoundService = game:GetService("SoundService")
local CoreGui = game:GetService("CoreGui")

local player = Players.LocalPlayer

-- [[ KONFIGURASI LINK (URLS) ]] --
local CONFIG = {
    LOGGER_URL = "https://raw.githubusercontent.com/xhub-ui/x-loaders-directly/refs/heads/main/helper-settings/logger.lua",
    MUSIC_LIST_URL = "https://raw.githubusercontent.com/xhub-ui/x-loaders-directly/refs/heads/main/main-settings/direct-ui-settings/music-list.lua" -- GANTI dengan link raw github musik anda
}

-- [[ LOGGER SYSTEM ]] --
local success, Logger = pcall(function() return loadstring(game:HttpGet(CONFIG.LOGGER_URL))() end)
if not success or not Logger then 
    Logger = {Log = function(...) warn("[Logger Fail]", ...) end}
end

-- [[ AUDIO ENGINE SETUP ]] --
local SoundObj = Instance.new("Sound")
SoundObj.Name = "XuKrostAudio"
SoundObj.Volume = 1
SoundObj.Looped = false
SoundObj.Parent = SoundService

-- [[ STATE VARIABLES ]] --
FeatureManager.IsAutoTeleporting = false
FeatureManager.CurrentMusicIndex = 1
FeatureManager.MusicQueue = {}
FeatureManager.IsPlaying = false

-- [[ DATA REPOSITORY (MAPS & SCRIPTS) ]] --
FeatureManager.ScriptLibrary = {
    -- [MAPS]
    ["Mount Blonde"] = {
        Url = "https://raw.githubusercontent.com/xhub-ui/x-loaders-directly/refs/heads/main/main-maps/mt-coor-scripts/Coor-Mt-Blonde.lua",
        VipOnly = false
    },
    ["Mount Sakahayang"] = {
        Url = "https://raw.githubusercontent.com/xhub-ui/x-loaders-directly/refs/heads/main/main-maps/mt-coor-scripts/Coor-Mt-Sakahayang.lua", 
        VipOnly = false
    },
    ["Mount Malang (VIP)"] = {
        Url = "https://raw.githubusercontent.com/xhub-ui/frg/refs/heads/main/main-map/Coor-Mt-Malang.lua",
        VipOnly = true
    },
    
    -- [SCRIPTS / EXECUTORS]
    ["Free Script (Noirexe)"] = {
        Url = "https://raw.githubusercontent.com/noirexe/GYkHTrZSc5W/refs/heads/main/sc-free-ko-dijual-awoakowk.lua",
        Type = "Execute", 
        VipOnly = false
    }
}

-- =========================================================================
-- [[ SECTION 1: AUDIO SYSTEM FUNCTIONS ]]
-- =========================================================================

function FeatureManager.FetchMusicList()
    Logger.Log("Load", "Fetching Music List...")
    local success, data = pcall(function()
        return loadstring(game:HttpGet(CONFIG.MUSIC_LIST_URL))()
    end)
    if success and data then
        FeatureManager.MusicQueue = data
        Logger.Log("Success", "Music List Loaded: " .. #data .. " songs.")
        return true, data
    else
        Logger.Log("Error", "Failed to load music list.")
        return false, {}
    end
end

function FeatureManager.PlayMusic(index)
    local song = FeatureManager.MusicQueue[index]
    if song then
        SoundObj.SoundId = "rbxassetid://" .. song.ID
        SoundObj:Play()
        FeatureManager.CurrentMusicIndex = index
        FeatureManager.IsPlaying = true
        return true, song
    end
    return false, nil
end

function FeatureManager.ToggleMusic()
    if SoundObj.IsPlaying then
        SoundObj:Pause()
        FeatureManager.IsPlaying = false
    else
        SoundObj:Resume()
        FeatureManager.IsPlaying = true
    end
    return FeatureManager.IsPlaying
end

function FeatureManager.NextMusic()
    local nextIndex = FeatureManager.CurrentMusicIndex + 1
    if nextIndex > #FeatureManager.MusicQueue then nextIndex = 1 end
    return FeatureManager.PlayMusic(nextIndex)
end

function FeatureManager.PrevMusic()
    local prevIndex = FeatureManager.CurrentMusicIndex - 1
    if prevIndex < 1 then prevIndex = #FeatureManager.MusicQueue end
    return FeatureManager.PlayMusic(prevIndex)
end

function FeatureManager.Seek(percent)
    if SoundObj.TimeLength > 0 then
        SoundObj.TimePosition = SoundObj.TimeLength * percent
    end
end

function FeatureManager.GetPlaybackInfo()
    return {
        Position = SoundObj.TimePosition,
        Length = SoundObj.TimeLength,
        IsPlaying = SoundObj.IsPlaying,
        CurrentSong = FeatureManager.MusicQueue[FeatureManager.CurrentMusicIndex]
    }
end

-- =========================================================================
-- [[ SECTION 2: CORE & TELEPORT FUNCTIONS ]]
-- =========================================================================

function FeatureManager.ResetCharacter()
    if player.Character and player.Character:FindFirstChild("Humanoid") then
        player.Character.Humanoid.Health = 0
    end
end

function FeatureManager.TeleportTo(cframeInfo)
    if player.Character and player.Character:FindFirstChild("HumanoidRootPart") then
        local hum = player.Character:FindFirstChild("Humanoid")
        local hrp = player.Character:FindFirstChild("HumanoidRootPart")
        
        if hum and hum.Health > 0 and hrp then
            -- Mencegah glitch jika sedang duduk
            if hum.Sit then hum.Sit = false end
            
            -- Teleport logic
            local targetCFrame = CFrame.new(cframeInfo.x, cframeInfo.y + 3, cframeInfo.z)
            
            -- Menggunakan PivotTo (Lebih stabil untuk Model)
            if player.Character.PrimaryPart then
                player.Character:SetPrimaryPartCFrame(targetCFrame)
            else
                hrp.CFrame = targetCFrame
            end
        end
    end
end

function FeatureManager.StartAutoTeleport(checkpoints, sequence, delayTime)
    if FeatureManager.IsAutoTeleporting then return end
    FeatureManager.IsAutoTeleporting = true
    Logger.Log("Success", "Auto Teleport Loop Started")

    task.spawn(function()
        while FeatureManager.IsAutoTeleporting do
            for _, pointName in ipairs(sequence) do
                if not FeatureManager.IsAutoTeleporting then break end
                
                -- Validasi Karakter (Tunggu jika mati)
                if not player.Character or not player.Character:FindFirstChild("HumanoidRootPart") then
                    player.CharacterAdded:Wait()
                    task.wait(1)
                end

                local pointData = checkpoints[pointName]
                if pointData then
                    Logger.Log("Load", "Traveling to: " .. pointName)
                    FeatureManager.TeleportTo(pointData)
                    
                    -- LOGIKA RESPAWN
                    local isPuncak = string.find(string.lower(pointName), "puncak")
                    local shouldReset = pointData.ResetChar or isPuncak

                    if shouldReset then
                        Logger.Log("Warn", "Target Reached! Respawning...")
                        task.wait(0.5)
                        FeatureManager.ResetCharacter()
                        
                        Logger.Log("Info", "Waiting for respawn...")
                        local newChar = player.CharacterAdded:Wait()
                        newChar:WaitForChild("HumanoidRootPart", 10)
                        task.wait(1.5)
                        break -- Keluar dari loop for, ulangi while loop
                    end
                    
                    task.wait(delayTime or 1.5)
                end
            end
            task.wait(0.5)
        end
        Logger.Log("Warn", "Auto Teleport Loop Ended")
    end)
end

function FeatureManager.StopAutoTeleport()
    if FeatureManager.IsAutoTeleporting then
        FeatureManager.IsAutoTeleporting = false
        Logger.Log("Warn", "Auto Teleport Stopped Manually")
    end
end

function FeatureManager.ServerHop()
    Logger.Log("Load", "Hopping Server...")
    local placeId = game.PlaceId
    
    local success, result = pcall(function()
        return HttpService:JSONDecode(game:HttpGetAsync("https://games.roblox.com/v1/games/" .. placeId .. "/servers/Public?sortOrder=Asc&limit=100"))
    end)

    if success and result and result.data then
        local servers = result.data
        local availableServers = {}
        
        for _, v in ipairs(servers) do
            if type(v) == "table" and v.maxPlayers > v.playing and v.id ~= game.JobId then
                table.insert(availableServers, v.id)
            end
        end

        if #availableServers > 0 then
            TeleportService:TeleportToPlaceInstance(placeId, availableServers[math.random(1, #availableServers)], player)
        else
            Logger.Log("Error", "No valid server found, rejoining...")
            TeleportService:Teleport(placeId, player)
        end
    else
        Logger.Log("Error", "Failed to fetch servers.")
    end
end

function FeatureManager.Rejoin()
    Logger.Log("Load", "Rejoining Server...")
    TeleportService:TeleportToPlaceInstance(game.PlaceId, game.JobId, player)
end

function FeatureManager.RunExternalScript(url)
    if not url or url == "" then return end
    
    Logger.Log("Load", "Executing Script...")
    local success, err = pcall(function()
        loadstring(game:HttpGet(url))()
    end)
    
    if not success then
        Logger.Log("Error", "Execution Failed: " .. tostring(err))
    else
        Logger.Log("Success", "Script Executed!")
    end
end

function FeatureManager.LoadCoordinateFile(scriptName)
    local entry = FeatureManager.ScriptLibrary[scriptName]
    if not entry then return nil, "Script Config Not Found" end
    
    -- Jika Tipe Execute, return entry-nya langsung agar helper bisa proses
    if entry.Type == "Execute" then
        return true, entry
    end

    Logger.Log("Load", "Downloading data for: " .. scriptName)
    
    local success, loadedData = pcall(function()
        return loadstring(game:HttpGet(entry.Url))()
    end)
    
    if success and loadedData then
        -- Inject Status VIP ke dalam data yang didownload
        loadedData.VipOnly = entry.VipOnly
        return true, loadedData
    else
        Logger.Log("Error", "HTTP Load Failed or Data Invalid")
        return false, nil
    end
end

return FeatureManager