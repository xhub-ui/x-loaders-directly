-- helper.lua
-- Updated for XuKrost Hub v4.8 (VIP & Safety Update)

local Helper = {}

-- [[ KONFIGURASI LINK ]] --
local LOGGER_URL = "https://raw.githubusercontent.com/xhub-ui/x-loaders-directly/refs/heads/main/helper-settings/logger.lua" 
local FEATURE_URL = "https://raw.githubusercontent.com/xhub-ui/x-loaders-directly/refs/heads/main/helper-settings/modules/feature-manager.lua" 

-- [[ SAFETY LOADING DEPENDENCIES ]] --
local function safeLoad(url)
    local success, result = pcall(function() return game:HttpGet(url) end)
    if success then
        local func, err = loadstring(result)
        if func then return func() else warn("Syntax Error in loaded script: " .. url) end
    else
        warn("Failed to download: " .. url)
    end
    return nil
end

local Logger = safeLoad(LOGGER_URL) or {Log = function(...) print(...) end} -- Fallback dummy
local FeatureManager = safeLoad(FEATURE_URL) or { -- Fallback dummy to prevent crash
    ScriptLibrary = {}, 
    LoadCoordinateFile = function() return false end,
    StopAutoTeleport = function() end
}

-- [[ THEME CONSTANTS ]] --
-- Disarankan samakan warna ini dengan Main Script Anda
local UI_COLOR = Color3.fromRGB(65, 120, 200) 
local CARD_COLOR = Color3.fromRGB(35, 35, 40)
local INPUT_BG = Color3.fromRGB(25, 25, 30)
local STROKE_COLOR = Color3.fromRGB(60, 60, 70)
local TEXT_COLOR = Color3.fromRGB(240, 240, 240)
local TEXT_DIM = Color3.fromRGB(150, 150, 150)
local RUN_BTN_COLOR = Color3.fromRGB(46, 139, 87)

-- [[ UTILITY FUNCTIONS ]] --
local function createCorner(parent, radius)
    local corner = Instance.new("UICorner", parent)
    corner.CornerRadius = UDim.new(0, radius or 6)
    return corner
end

local function createStroke(parent, color, thickness)
    local stroke = Instance.new("UIStroke", parent)
    stroke.Color = color or STROKE_COLOR
    stroke.Thickness = thickness or 1
    return stroke
end

-- [[ MAIN BUILD FUNCTION ]] --
function Helper.BuildMainTab(ParentFrame, isPlayerVip)
    -- 1. Safety & Cleanup
    if FeatureManager.StopAutoTeleport then
        FeatureManager.StopAutoTeleport() -- Matikan loop lama jika tab di-refresh
    end

    -- 2. Reset UI
    for _, v in pairs(ParentFrame:GetChildren()) do
        if v:IsA("Frame") or v:IsA("ScrollingFrame") or v:IsA("UIListLayout") or v:IsA("UIPadding") or v:IsA("TextLabel") then 
            v:Destroy() 
        end
    end
    
    -- Setup Layout
    local Layout = Instance.new("UIListLayout", ParentFrame)
    Layout.SortOrder = Enum.SortOrder.LayoutOrder
    Layout.Padding = UDim.new(0, 8)
    
    local Padding = Instance.new("UIPadding", ParentFrame)
    Padding.PaddingTop = UDim.new(0, 5)
    Padding.PaddingLeft = UDim.new(0, 5)
    Padding.PaddingRight = UDim.new(0, 5)
    Padding.PaddingBottom = UDim.new(0, 35) -- Extra padding for bottom tools

    -- 3. DATA PREPARATION
    local mapNames = {}
    if FeatureManager.ScriptLibrary then
        for name, _ in pairs(FeatureManager.ScriptLibrary) do
            table.insert(mapNames, name)
        end
        table.sort(mapNames) 
    end

    local DropdownItems = {} 
    local ExecuteItems = {}  

    for _, name in ipairs(mapNames) do
        local success, data = FeatureManager.LoadCoordinateFile(name)
        if success and data then
            if data.Type == "Execute" then
                table.insert(ExecuteItems, {name = name, data = data})
            else
                table.insert(DropdownItems, {name = name, data = data})
            end
        end
    end

    -- ==========================================================
    -- SECTION 1: EXECUTE SCRIPTS
    -- ==========================================================
    if #ExecuteItems > 0 then
        local ExecTitle = Instance.new("TextLabel", ParentFrame)
        ExecTitle.Size = UDim2.new(1, 0, 0, 20)
        ExecTitle.BackgroundTransparency = 1
        ExecTitle.Text = "AVAILABLE SCRIPTS"
        ExecTitle.TextColor3 = TEXT_DIM
        ExecTitle.Font = Enum.Font.GothamBold
        ExecTitle.TextSize = 10
        ExecTitle.TextXAlignment = Enum.TextXAlignment.Left
        ExecTitle.LayoutOrder = 1

        for _, item in ipairs(ExecuteItems) do
            local name = item.name
            local data = item.data
            -- VIP Logic: Check if script is VIP Only AND Player is NOT VIP
            local isVipLocked = (data.VipOnly == true and not isPlayerVip)

            local ScriptCard = Instance.new("Frame", ParentFrame)
            ScriptCard.Size = UDim2.new(1, -5, 0, 40)
            ScriptCard.BackgroundColor3 = CARD_COLOR
            ScriptCard.BackgroundTransparency = 0.2
            ScriptCard.LayoutOrder = 2
            createCorner(ScriptCard, 6)
            createStroke(ScriptCard, STROKE_COLOR, 1)

            local NameLbl = Instance.new("TextLabel", ScriptCard)
            NameLbl.Size = UDim2.new(0.65, -10, 1, 0)
            NameLbl.Position = UDim2.new(0, 10, 0, 0)
            NameLbl.BackgroundTransparency = 1
            NameLbl.Text = name
            NameLbl.TextColor3 = TEXT_COLOR
            NameLbl.Font = Enum.Font.GothamSemibold
            NameLbl.TextSize = 12
            NameLbl.TextXAlignment = Enum.TextXAlignment.Left
            NameLbl.TextTruncate = Enum.TextTruncate.AtEnd

            local RunBtn = Instance.new("TextButton", ScriptCard)
            RunBtn.Size = UDim2.new(0, 80, 0, 24)
            RunBtn.Position = UDim2.new(1, -90, 0.5, 0)
            RunBtn.AnchorPoint = Vector2.new(0, 0.5)
            RunBtn.Font = Enum.Font.GothamBold
            RunBtn.TextSize = 10
            createCorner(RunBtn, 4)

            if isVipLocked then
                RunBtn.Text = "LOCKED"
                RunBtn.BackgroundColor3 = Color3.fromRGB(50, 50, 50)
                RunBtn.TextColor3 = Color3.fromRGB(100, 100, 100)
                RunBtn.AutoButtonColor = false
                
                local lockIcon = Instance.new("TextLabel", ScriptCard)
                lockIcon.Text = "🔒"
                lockIcon.Size = UDim2.new(0, 20, 1, 0)
                lockIcon.Position = UDim2.new(1, -115, 0, 0)
                lockIcon.BackgroundTransparency = 1
                lockIcon.TextSize = 12
            else
                RunBtn.Text = "RUN"
                RunBtn.BackgroundColor3 = UI_COLOR 
                RunBtn.TextColor3 = Color3.new(1,1,1)
                
                RunBtn.MouseButton1Click:Connect(function()
                    if FeatureManager.RunExternalScript then
                        FeatureManager.RunExternalScript(data.Url)
                        local oldText = RunBtn.Text
                        RunBtn.Text = "..."
                        RunBtn.BackgroundColor3 = RUN_BTN_COLOR
                        task.wait(1)
                        RunBtn.Text = oldText
                        RunBtn.BackgroundColor3 = UI_COLOR
                    end
                end)
            end
        end
        
        local Sep = Instance.new("Frame", ParentFrame)
        Sep.Size = UDim2.new(1, -10, 0, 1)
        Sep.BackgroundColor3 = STROKE_COLOR
        Sep.BorderSizePixel = 0
        Sep.LayoutOrder = 3
    end

    -- ==========================================================
    -- SECTION 2: MAPS (DROPDOWN)
    -- ==========================================================
    if #DropdownItems > 0 then
        local MapHeader = Instance.new("Frame", ParentFrame)
        MapHeader.Size = UDim2.new(1, -5, 0, 40)
        MapHeader.BackgroundColor3 = CARD_COLOR
        MapHeader.BackgroundTransparency = 0.2
        MapHeader.LayoutOrder = 4
        createCorner(MapHeader, 8)
        createStroke(MapHeader, STROKE_COLOR, 1)

        local DropdownBtn = Instance.new("TextButton", MapHeader)
        DropdownBtn.Size = UDim2.new(1, -10, 1, 0)
        DropdownBtn.Position = UDim2.new(0, 10, 0, 0)
        DropdownBtn.BackgroundTransparency = 1
        DropdownBtn.Text = "Select Map / Waypoint"
        DropdownBtn.TextColor3 = TEXT_COLOR
        DropdownBtn.Font = Enum.Font.GothamBold
        DropdownBtn.TextSize = 12
        DropdownBtn.TextXAlignment = Enum.TextXAlignment.Left

        local DropIcon = Instance.new("TextLabel", DropdownBtn)
        DropIcon.Size = UDim2.new(0, 20, 1, 0)
        DropIcon.Position = UDim2.new(1, -20, 0, 0)
        DropIcon.BackgroundTransparency = 1
        DropIcon.Text = "v"
        DropIcon.TextColor3 = TEXT_DIM
        DropIcon.Font = Enum.Font.GothamBold
        DropIcon.TextSize = 12

        local MapListContainer = Instance.new("Frame", ParentFrame)
        MapListContainer.Size = UDim2.new(1, -5, 0, 0)
        MapListContainer.BackgroundColor3 = INPUT_BG
        MapListContainer.BackgroundTransparency = 0.5
        MapListContainer.AutomaticSize = Enum.AutomaticSize.Y
        MapListContainer.LayoutOrder = 5
        MapListContainer.Visible = false
        MapListContainer.ClipsDescendants = true
        createCorner(MapListContainer, 8)
        createStroke(MapListContainer, UI_COLOR, 1)

        local MapListLayout = Instance.new("UIListLayout", MapListContainer)
        MapListLayout.SortOrder = Enum.SortOrder.LayoutOrder
        MapListLayout.Padding = UDim.new(0, 2)
        local MapPadding = Instance.new("UIPadding", MapListContainer)
        MapPadding.PaddingTop = UDim.new(0, 5)
        MapPadding.PaddingBottom = UDim.new(0, 5)
        MapPadding.PaddingLeft = UDim.new(0, 5)
        MapPadding.PaddingRight = UDim.new(0, 5)

        local ControlContainer = Instance.new("Frame", ParentFrame)
        ControlContainer.Size = UDim2.new(1, -5, 0, 0)
        ControlContainer.BackgroundTransparency = 1
        ControlContainer.LayoutOrder = 6
        ControlContainer.AutomaticSize = Enum.AutomaticSize.Y
        ControlContainer.Visible = true 
        local ControlLayout = Instance.new("UIListLayout", ControlContainer)

        for _, item in ipairs(DropdownItems) do
            local name = item.name
            local MapItemBtn = Instance.new("TextButton", MapListContainer)
            MapItemBtn.Size = UDim2.new(1, 0, 0, 30)
            MapItemBtn.BackgroundColor3 = Color3.fromRGB(40, 40, 45)
            MapItemBtn.BackgroundTransparency = 1
            MapItemBtn.Text = "  " .. name
            MapItemBtn.TextColor3 = TEXT_DIM
            MapItemBtn.Font = Enum.Font.Gotham
            MapItemBtn.TextSize = 11
            MapItemBtn.TextXAlignment = Enum.TextXAlignment.Left
            createCorner(MapItemBtn, 4)

            MapItemBtn.MouseButton1Click:Connect(function()
                -- Stop loop saat ganti map
                if FeatureManager.StopAutoTeleport then FeatureManager.StopAutoTeleport() end
                
                Helper.LoadMapUI(ControlContainer, name, isPlayerVip)
                DropdownBtn.Text = "Selected: " .. name
                DropIcon.Text = "v"
                MapListContainer.Visible = false
                ControlContainer.Visible = true 
            end)
        end

        DropdownBtn.MouseButton1Click:Connect(function()
            local isOpening = not MapListContainer.Visible
            MapListContainer.Visible = isOpening
            DropIcon.Text = isOpening and "^" or "v"
            ControlContainer.Visible = not isOpening
        end)
    end

    -- 4. Footer Tools
    Helper.CreateGlobalTools(ParentFrame)
end

function Helper.LoadMapUI(Container, ScriptName, isVip)
    for _, v in pairs(Container:GetChildren()) do 
        if v:IsA("Frame") or v:IsA("TextButton") or v:IsA("TextLabel") then v:Destroy() end 
    end

    local success, data = FeatureManager.LoadCoordinateFile(ScriptName)
    if not success or not data then return end

    -- VIP Lock UI
    if data.VipOnly == true and not isVip then
        local LockFrame = Instance.new("Frame", Container)
        LockFrame.Size = UDim2.new(1, 0, 0, 40)
        LockFrame.BackgroundColor3 = Color3.fromRGB(40, 20, 20)
        createCorner(LockFrame, 6)
        createStroke(LockFrame, Color3.fromRGB(150, 50, 50), 1)

        local LockLabel = Instance.new("TextLabel", LockFrame)
        LockLabel.Size = UDim2.new(1, 0, 1, 0)
        LockLabel.BackgroundTransparency = 1
        LockLabel.Text = "🔒 VIP ACCESS ONLY"
        LockLabel.TextColor3 = Color3.fromRGB(255, 100, 100)
        LockLabel.Font = Enum.Font.GothamBold
        LockLabel.TextSize = 12
        return
    end

    Logger.Log("Loaded", "Map: " .. ScriptName)

    -- Config Card
    local ConfigCard = Instance.new("Frame", Container)
    ConfigCard.Size = UDim2.new(1, 0, 0, 95)
    ConfigCard.BackgroundColor3 = CARD_COLOR
    ConfigCard.BackgroundTransparency = 0.2
    createCorner(ConfigCard, 8)
    createStroke(ConfigCard, STROKE_COLOR, 1)

    local DelayLabel = Instance.new("TextLabel", ConfigCard)
    DelayLabel.Size = UDim2.new(0.4, 0, 0, 30)
    DelayLabel.Position = UDim2.new(0, 10, 0, 10)
    DelayLabel.BackgroundTransparency = 1
    DelayLabel.Text = "TP Delay (s):"
    DelayLabel.TextColor3 = TEXT_DIM
    DelayLabel.Font = Enum.Font.Gotham
    DelayLabel.TextSize = 11
    DelayLabel.TextXAlignment = Enum.TextXAlignment.Left

    local DelayBox = Instance.new("TextBox", ConfigCard)
    DelayBox.Size = UDim2.new(0.3, 0, 0, 25)
    DelayBox.Position = UDim2.new(0.35, 0, 0, 12)
    DelayBox.BackgroundColor3 = INPUT_BG
    DelayBox.Text = "1.5"
    DelayBox.TextColor3 = TEXT_COLOR
    createCorner(DelayBox, 4)
    createStroke(DelayBox, STROKE_COLOR, 1)

    local SetDelayBtn = Instance.new("TextButton", ConfigCard)
    SetDelayBtn.Size = UDim2.new(0.25, 0, 0, 25)
    SetDelayBtn.Position = UDim2.new(0.7, 0, 0, 12)
    SetDelayBtn.BackgroundColor3 = UI_COLOR
    SetDelayBtn.Text = "SET"
    SetDelayBtn.TextColor3 = Color3.new(1,1,1)
    SetDelayBtn.Font = Enum.Font.GothamBold
    SetDelayBtn.TextSize = 10
    createCorner(SetDelayBtn, 4)

    local StartBtn = Instance.new("TextButton", ConfigCard)
    StartBtn.Size = UDim2.new(0.45, 0, 0, 30)
    StartBtn.Position = UDim2.new(0, 10, 0, 50)
    StartBtn.BackgroundColor3 = RUN_BTN_COLOR
    StartBtn.Text = "START LOOP"
    StartBtn.TextColor3 = Color3.new(1,1,1)
    StartBtn.Font = Enum.Font.GothamBold
    StartBtn.TextSize = 11
    createCorner(StartBtn, 6)

    local StopBtn = Instance.new("TextButton", ConfigCard)
    StopBtn.Size = UDim2.new(0.45, 0, 0, 30)
    StopBtn.Position = UDim2.new(0.5, 0, 0, 50)
    StopBtn.BackgroundColor3 = Color3.fromRGB(160, 50, 50)
    StopBtn.Text = "STOP"
    StopBtn.TextColor3 = Color3.new(1,1,1)
    StopBtn.Font = Enum.Font.GothamBold
    StopBtn.TextSize = 11
    createCorner(StopBtn, 6)

    SetDelayBtn.MouseButton1Click:Connect(function()
        SetDelayBtn.Text = "OK"
        wait(1)
        SetDelayBtn.Text = "SET"
    end)

    StartBtn.MouseButton1Click:Connect(function()
        if FeatureManager.StartAutoTeleport then
            FeatureManager.StartAutoTeleport(data.CheckPoints, data.Sequence, tonumber(DelayBox.Text) or 1.5)
        end
    end)

    StopBtn.MouseButton1Click:Connect(function()
        if FeatureManager.StopAutoTeleport then FeatureManager.StopAutoTeleport() end
    end)

    -- Manual Grid
    local ManualGrid = Instance.new("Frame", Container)
    ManualGrid.Size = UDim2.new(1, 0, 0, 0)
    ManualGrid.AutomaticSize = Enum.AutomaticSize.Y
    ManualGrid.BackgroundTransparency = 1
    
    local UIGrid = Instance.new("UIGridLayout", ManualGrid)
    UIGrid.CellSize = UDim2.new(0.31, 0, 0, 25)
    UIGrid.CellPadding = UDim2.new(0.03, 0, 0.03, 0)

    if data.Sequence then
        for _, name in ipairs(data.Sequence) do
            local btn = Instance.new("TextButton", ManualGrid)
            btn.BackgroundColor3 = INPUT_BG
            btn.Text = name
            btn.TextColor3 = TEXT_COLOR
            btn.Font = Enum.Font.Gotham
            btn.TextSize = 9
            createCorner(btn, 4)
            createStroke(btn, STROKE_COLOR, 1)

            btn.MouseButton1Click:Connect(function()
                local coords = data.CheckPoints and data.CheckPoints[name]
                if coords and FeatureManager.TeleportTo then
                    FeatureManager.TeleportTo(coords)
                end
            end)
        end
    end
end

function Helper.CreateGlobalTools(ParentFrame)
    local ToolsFrame = Instance.new("Frame", ParentFrame)
    ToolsFrame.Size = UDim2.new(1, -5, 0, 35)
    ToolsFrame.BackgroundColor3 = Color3.fromRGB(0,0,0)
    ToolsFrame.BackgroundTransparency = 1
    ToolsFrame.LayoutOrder = 99
    
    local HopBtn = Instance.new("TextButton", ToolsFrame)
    HopBtn.Size = UDim2.new(0.48, 0, 1, 0)
    HopBtn.BackgroundColor3 = Color3.fromRGB(50, 50, 60)
    HopBtn.Text = "Server Hop"
    HopBtn.TextColor3 = TEXT_COLOR
    HopBtn.Font = Enum.Font.GothamBold
    HopBtn.TextSize = 11
    createCorner(HopBtn, 6)
    createStroke(HopBtn, STROKE_COLOR, 1)
    
    local RejoinBtn = Instance.new("TextButton", ToolsFrame)
    RejoinBtn.Size = UDim2.new(0.48, 0, 1, 0)
    RejoinBtn.Position = UDim2.new(0.52, 0, 0, 0)
    RejoinBtn.BackgroundColor3 = Color3.fromRGB(50, 50, 60)
    RejoinBtn.Text = "Rejoin Server"
    RejoinBtn.TextColor3 = TEXT_COLOR
    RejoinBtn.Font = Enum.Font.GothamBold
    RejoinBtn.TextSize = 11
    createCorner(RejoinBtn, 6)
    createStroke(RejoinBtn, STROKE_COLOR, 1)

    HopBtn.MouseButton1Click:Connect(function() if FeatureManager.ServerHop then FeatureManager.ServerHop() end end)
    RejoinBtn.MouseButton1Click:Connect(function() if FeatureManager.Rejoin then FeatureManager.Rejoin() end end)
end

return Helper
