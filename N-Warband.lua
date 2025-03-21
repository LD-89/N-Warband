-- Initialize the addon with Ace3
local addon = LibStub("AceAddon-3.0"):NewAddon("N-Warband")
NWarbandMinimapButton = LibStub("LibDBIcon-1.0", true)

local dataLoaded = {}  -- Track which characters have been loaded this session
local isLoading = false
local loadQueue = {}
local currentCharKey = nil

-- Set up default database values
local defaults = {
    profile = {
        minimap = {
            hide = false,
        },
    },
    global = {
        characters = {}
    }
}

function addon:OnInitialize()
    -- Initialize DB through Ace3
    self.db = LibStub("AceDB-3.0"):New("NWarbandDB", defaults)

    -- Get current character key
    currentCharKey = UnitName("player") .. "-" .. GetRealmName()

    -- Queue all characters for loading except current one
    self:QueueCharactersForLoading()

    -- Current character is always updated immediately
    self:UpdateCurrentCharacterData()

    -- Start background loading
    self:RegisterEvent("PLAYER_REGEN_ENABLED", "ProcessLoadQueue")
    C_Timer.After(1, function() addon:ProcessLoadQueue() end)

    -- Set up the minimap button
    local LDB = LibStub("LibDataBroker-1.1"):NewDataObject("N-Warband", {
        type = "data source",
        text = "N-Warband",
        icon = "Interface\\AddOns\\N-Warband\\icon",
        OnClick = function(_, button)
            if button == "LeftButton" then
                addon:ToggleMainFrame()
            end
        end,
        OnTooltipShow = function(tooltip)
            tooltip:AddLine("N-Warband")
            tooltip:AddLine("Click to toggle the addon window", 1, 1, 1)
        end,
    })

    -- Register the minimap button
    NWarbandMinimapButton:Register("N-Warband", LDB, self.db.profile.minimap)
end

-- Queue characters for background loading
function addon:QueueCharactersForLoading()
    wipe(loadQueue)
    for charKey, _ in pairs(NWarbandDB.characters) do
        if charKey ~= currentCharKey and not dataLoaded[charKey] then
            table.insert(loadQueue, charKey)
        end
    end
end

-- Process the load queue in chunks during gameplay downtime
function addon:ProcessLoadQueue()
    if isLoading or #loadQueue == 0 then return end

    isLoading = true
    local startTime = GetTime()
    local processedCount = 0

    -- Process a few characters at a time (limit processing to 10ms)
    while #loadQueue > 0 and (GetTime() - startTime < 0.01) do
        local charKey = table.remove(loadQueue, 1)
        self:LoadCharacterData(charKey)
        dataLoaded[charKey] = true
        processedCount = processedCount + 1

        -- Process at most 5 characters per batch
        if processedCount >= 5 then break end
    end

    isLoading = false

    -- Continue processing if more characters remain
    if #loadQueue > 0 then
        C_Timer.After(0.5, function() addon:ProcessLoadQueue() end)
    end
end

-- Update current character data
function addon:UpdateCurrentCharacterData()
    local charInfo = {
        name = UnitName("player"),
        server = GetRealmName(),
        race = select(1, UnitRace("player")),
        class = select(1, UnitClass("player")),
        level = UnitLevel("player"),
        gold = GetMoney(),
        faction = UnitFactionGroup("player"),
        location = GetRealZoneText()
    }

    NWarbandDB.characters[currentCharKey] = charInfo
    dataLoaded[currentCharKey] = true
end

-- Create the main frame
local mainFrame = CreateFrame("Frame", "NWarbandMainFrame", UIParent, "BasicFrameTemplateWithInset")
mainFrame:SetSize(500, 350)
mainFrame:SetPoint("CENTER", UIParent, "CENTER", 0, 0)

-- Set the frame title
mainFrame.TitleBg:SetHeight(30)
mainFrame.title = mainFrame:CreateFontString(nil, "OVERLAY", "GameFontHighlight")
mainFrame.title:SetPoint("TOPLEFT", mainFrame.TitleBg, "TOPLEFT", 5, -3)
mainFrame.title:SetText("N-Warband")

-- Hide the frame initially
mainFrame:Hide()

function addon:OnInitialize()
end

-- Function to toggle the main frame visibility
function addon:ToggleMainFrame()
    if mainFrame:IsShown() then
        mainFrame:Hide()
    else
        mainFrame:Show()
    end
end

-- Character data collection
local function UpdateCharacterData()
    local charInfo = {
        name = UnitName("player"),
        server = GetRealmName(),
        level = UnitLevel("player"),
        gold = GetMoney(),
        race = UnitRace("player"),
        class = UnitClass("player"),
        faction = UnitFactionGroup("player"),
        logoutLocation = nil  -- Will be updated on logout
    }

    -- Get existing entry or create new
    local charKey = charInfo.name .. "-" .. charInfo.server
    addon.db.global.characters[charKey] = charInfo
end

-- Logout event handler
local function OnLogout()
    local _, instanceType = IsInInstance()
    local zoneText = GetRealZoneText()
    addon.db.global.characters[UnitName("player") .. "-" .. GetRealmName()].logoutLocation = zoneText
end

-- Example dropdown menu
local function CreateCharacterDropdown()
    local dropdown = UIDropDownMenu:Create("CharacterSelector", UIParent)
    UIDropDownMenu:SetInitialValue(dropdown, "Select Character")

    for key, char in pairs(addon.db.global.characters) do
        UIDropDownMenu:AddButton(dropdown, {
            text = char.name .. " (@ " .. char.server .. ")",
            value = char
        })
    end
end



-- Register events when the addon loads
addon:RegisterEvent("PLAYER_LOGIN", function()
    print("N-Warband successfully loaded!")
end)
addon:RegisterEvent("PLAYER_LOGIN", UpdateCharacterData)
addon:RegisterEvent("PLAYER_LOGOUT", OnLogout)
