-- Initialize the addon with Ace3
local addon = LibStub("AceAddon-3.0"):NewAddon("N-Warband")
NWarbandMinimapButton = LibStub("LibDBIcon-1.0", true)

-- Set up default database values
local defaults = {
    profile = {
        minimap = {
            hide = false,
        },
    }
}

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

-- Register events when the addon loads
addon:RegisterEvent("PLAYER_LOGIN", function()
    print("N-Warband successfully loaded!")
end)
