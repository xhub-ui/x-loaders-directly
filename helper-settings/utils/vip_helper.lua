--[[ 
    XuKrost Hub - VIP Helper Module 
    Filename: vip_helper.lua
]]

local HttpService = game:GetService("HttpService")
local VIPHelper = {}

-- =================================================================
-- :: KONFIGURASI LINK DATA VIP (EDIT DISINI) ::
-- Masukkan link RAW daftar user kamu di dalam tanda kutip di bawah ini
-- =================================================================
local VIP_DATA_URLS = {
    -- Masukkan Link untuk file .json
    ["json"] = "https://raw.githubusercontent.com/username/repo/main/vip_user.json",
    
    -- Masukkan Link untuk file .txt
    ["txt"]  = "https://raw.githubusercontent.com/xhub-ui/x-loaders-directly/main/main-settings/direct-url-settings/vip_users.txt"
}
-- =================================================================

local function parseJSON(data, userId)
    local success, decoded = pcall(function() return HttpService:JSONDecode(data) end)
    if success and type(decoded) == "table" then
        for _, id in pairs(decoded) do
            if tonumber(id) == userId then return true end
        end
    end
    return false
end

local function parseTXT(data, userId)
    -- Pattern "%d+" menangkap angka saja (mengabaikan koma, spasi, enter)
    for idStr in string.gmatch(data, "%d+") do
        if tonumber(idStr) == userId then return true end
    end
    return false
end

-- Fungsi yang akan dipanggil oleh Main Script
function VIPHelper.CheckIsVIP(player, mode)
    -- 1. Validasi Mode
    mode = string.lower(mode or "json")
    local targetUrl = VIP_DATA_URLS[mode]

    if not targetUrl or targetUrl == "" then
        warn("VIP Helper: Mode '"..tostring(mode).."' tidak ditemukan atau URL kosong.")
        return false
    end

    -- 2. Ambil Data
    local success, response = pcall(function()
        return game:HttpGet(targetUrl, true)
    end)

    if not success then
        warn("VIP Helper: Gagal mengambil data dari URL.")
        return false
    end

    -- 3. Cek ID berdasarkan Mode
    local userId = player.UserId
    if mode == "json" then
        return parseJSON(response, userId)
    elseif mode == "txt" then
        return parseTXT(response, userId)
    end

    return false
end

return VIPHelper