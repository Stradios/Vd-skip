local addonName = "Vd-skip"
local frame = CreateFrame("Frame")

-- Default settings
local defaults = {
    skipVendors = true,
    skipFlightMasters = true,
    skipEmptyQuests = true,
    debugMode = false
}

-- Initialize or upgrade settings
local function InitSettings()
    if type(VdSkipDB) ~= "table" then
        VdSkipDB = CopyTable(defaults)
    else
        -- Add any new default settings
        for k,v in pairs(defaults) do
            if VdSkipDB[k] == nil then
                VdSkipDB[k] = v
            end
        end
    end
end

-- Debug printing
local function DebugPrint(...)
    if VdSkipDB.debugMode then
        print("|cff33ff99Vd-skip Debug:|r", ...)
    end
end

-- Check if NPC has any quests
local function HasQuests()
    return GetNumGossipAvailableQuests() > 0 or GetNumGossipActiveQuests() > 0
end

-- Main event handler
frame:SetScript("OnEvent", function(self, event, ...)
    if event == "ADDON_LOADED" and ... == addonName then
        InitSettings()
        self:RegisterEvent("GOSSIP_SHOW")
        self:RegisterEvent("QUEST_GREETING")
        self:RegisterEvent("MERCHANT_SHOW")
        self:RegisterEvent("TAXIMAP_OPENED")
        DebugPrint("Addon loaded")
        return
    end

    if event == "GOSSIP_SHOW" then
        DebugPrint("Gossip shown")

        if HasQuests() then
            DebugPrint("NPC has quests - not skipping")
            return
        end

        local options = { GetGossipOptions() }
        for i = 1, #options, 2 do
            local text = options[i]
            local type = options[i + 1]
            DebugPrint("Option:", text, "Type:", type)

            if VdSkipDB.skipFlightMasters and type == "taxi" then
                DebugPrint("Selecting flight master option")
                return SelectGossipOption((i + 1) / 2)
            elseif VdSkipDB.skipVendors and type == "vendor" then
                DebugPrint("Selecting vendor option")
                return SelectGossipOption((i + 1) / 2)
            end
        end

    elseif event == "QUEST_GREETING" and VdSkipDB.skipEmptyQuests then
        DebugPrint("Quest greeting shown")
        if GetNumActiveQuests() == 0 and GetNumAvailableQuests() == 0 then
            DebugPrint("No quests - closing")
            CloseQuest()
        end

    elseif (event == "MERCHANT_SHOW" or event == "TAXIMAP_OPENED") and GossipFrame:IsShown() then
        DebugPrint("Merchant/Taxi opened - closing gossip")
        CloseGossip()
    end
end)

frame:RegisterEvent("ADDON_LOADED")

-- Slash commands
SLASH_VDSKIP1 = "/vdskip"
SlashCmdList["VDSKIP"] = function(input)
    input = input and strlower(strtrim(input)) or ""

    if input == "vendors" then
        VdSkipDB.skipVendors = not VdSkipDB.skipVendors
        print(format("Vd-skip: Vendor skipping %s", VdSkipDB.skipVendors and "|cff00ff00enabled|r" or "|cffff0000disabled|r"))
    elseif input == "flight" then
        VdSkipDB.skipFlightMasters = not VdSkipDB.skipFlightMasters
        print(format("Vd-skip: Flight master skipping %s", VdSkipDB.skipFlightMasters and "|cff00ff00enabled|r" or "|cffff0000disabled|r"))
    elseif input == "quests" then
        VdSkipDB.skipEmptyQuests = not VdSkipDB.skipEmptyQuests
        print(format("Vd-skip: Empty quest skipping %s", VdSkipDB.skipEmptyQuests and "|cff00ff00enabled|r" or "|cffff0000disabled|r"))
    elseif input == "debug" then
        VdSkipDB.debugMode = not VdSkipDB.debugMode
        print(format("Vd-skip: Debug mode %s", VdSkipDB.debugMode and "|cff00ff00enabled|r" or "|cffff0000disabled|r"))
    else
        print("Vd-skip commands:")
        print("|cffffff00/vdskip vendors|r - Toggle vendor skipping")
        print("|cffffff00/vdskip flight|r - Toggle flight master skipping")
        print("|cffffff00/vdskip quests|r - Toggle empty quest greeting skipping")
        print("|cffffff00/vdskip debug|r - Toggle debug messages")
        print("Current status:")
        print(format("  Vendor skipping: %s", VdSkipDB.skipVendors and "|cff00ff00ON|r" or "|cffff0000OFF|r"))
        print(format("  Flight master skipping: %s", VdSkipDB.skipFlightMasters and "|cff00ff00ON|r" or "|cffff0000OFF|r"))
        print(format("  Empty quest skipping: %s", VdSkipDB.skipEmptyQuests and "|cff00ff00ON|r" or "|cffff0000OFF|r"))
    end
end
