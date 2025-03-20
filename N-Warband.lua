-- Initialize the addon with Ace3
local addon = LibStub("AceAddon-3.0"):NewAddon("N-Warband")
NWarbandMinimapButton = LibStub("LibDBIcon-1.0", true)

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
    -- Initialize the database
    self.db = LibStub("AceDB-3.0"):New("NWarbandDB", defaults, true)

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
