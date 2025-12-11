-- logger.lua
-- Updated for XuKrost Hub v4.8
-- Added rconsole support & fixed case sensitivity

local Logger = {}
local StarterGui = game:GetService("StarterGui")
local TestService = game:GetService("TestService") -- Untuk print berwarna di F9 console

-- Configuration
local ICON_ID = "rbxassetid://127523276881123" 

-- Fungsi Internal: Print ke Console Executor (Hitam) jika didukung
local function internalPrint(text, colorCode)
    if rconsoleprint then
        -- Format warna untuk rconsole (tergantung executor, biasanya support '@@BLUE@@')
        rconsoleprint(text .. "\n")
    else
        -- Fallback ke Roblox Console
        if colorCode == "Error" then
            warn(text)
        elseif colorCode == "Info" then
            TestService:Message(text) -- Teks Biru
        else
            print(text)
        end
    end
end

function Logger.Notify(title, text, duration)
    pcall(function()
        StarterGui:SetCore("SendNotification", {
            Title = title,
            Text = text,
            Icon = ICON_ID,
            Duration = duration or 3
        })
    end)
end

function Logger.Log(logType, msg)
    -- Normalisasi input (biar "load", "Load", "LOADED" terbaca sama)
    local mode = string.lower(logType or "info")
    
    local prefix = "[INFO]"
    
    if mode == "success" then
        prefix = "[SUCCESS]"
        internalPrint("✅ " .. prefix .. " " .. msg, "Info")
        Logger.Notify("System", msg, 3)
        
    elseif mode == "error" or mode == "fail" then
        prefix = "[ERROR]"
        internalPrint("⛔ " .. prefix .. " " .. msg, "Error")
        Logger.Notify("Error", msg, 5)
        
    elseif mode == "warn" or mode == "warning" then
        prefix = "[WARN]"
        internalPrint("⚠️ " .. prefix .. " " .. msg, "Error")
        Logger.Notify("Warning", msg, 4)
        
    elseif mode == "load" or mode == "loaded" then
        prefix = "[LOAD]"
        internalPrint("⏳ " .. prefix .. " " .. msg, "Info")
        Logger.Notify("Loader", msg, 2)
        
    else
        -- Default Info
        internalPrint("ℹ️ " .. prefix .. " " .. msg, "Normal")
        -- Opsional: Info biasa tidak perlu notifikasi layar agar tidak spam
        -- Logger.Notify("Info", msg, 2) 
    end
end

return Logger
