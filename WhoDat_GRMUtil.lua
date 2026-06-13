---@type string, WhoDat
local addonName, WhoDat = ...
local grmAddonName = "Guild_Roster_Manager"

---@class WhoDat
WhoDat = LibStub("AceAddon-3.0"):NewAddon(addonName, "AceConsole-3.0", "AceEvent-3.0")

---@class Locale
local L = LibStub("AceLocale-3.0"):GetLocale(addonName, true)

---Utility function for replacing placeholder tokens in a localized string with dynamic values
---@param template string
---@param tokens table
---@return string text
function WhoDat.ReplacePlaceholders(template, tokens)
    return (template:gsub("{(%w+)}", tokens))
end

---@class WhoDatGRMUtil
local GRMUtil = {}

---Indicates whether the GRM AddOn is loaded
---@return boolean loadingOrLoaded
---@return boolean loaded
function GRMUtil.IsGRMLoaded()
    if not C_AddOns then return false, false end
    return C_AddOns.IsAddOnLoaded(grmAddonName)
end

---Indicates whether GRM has been initialized
---@return boolean `true` if GRM has finished initialization, `false` otherwise
function GRMUtil.IsGRMInitialized()
    return select(2, GRMUtil.IsGRMLoaded()) and GRM_API and GRM_API.Initialized == true
end

---Returns a list of all characters associated with a character in GRM
---@param character string Name of the character to fetch main/alts for
---@return string[] 'List of character names associated with the provided character'
function GRMUtil.GetLinkedToons(character)
    -- Make sure the GRM AddOn is loaded before attempting any further action
    if not GRMUtil.IsGRMInitialized() then
        WhoDat:Print(L["GRM is not yet initialized. Please try again soon."])
        return {}
    end

    local searchResults = {}
    for _, result in ipairs(GRM_R.GetAllMembersAsArray(character:lower())) do
        if not tContains(searchResults, result.name) then
            tinsert(searchResults, result.name)
        end
        if result.mainName and not tContains(searchResults, result.mainName) then
            tinsert(searchResults, result.mainName)
        end
    end

    if #searchResults > 0 then
        local altGroupID = GRM_API.GetMember(searchResults[1]).altGroup
        -- GRM.GetAltGroup() returns named properties, but character data is indexed numerically, so we can iterate over ipairs to ignore the named properties
        for _, toon in ipairs(GRM.GetAltGroup(altGroupID)) do
            if not tContains(searchResults, toon.name) then
                tinsert(searchResults, toon.name)
            end
        end
    end

    -- Since we don't care about server name, we'll split each search result on the hyphen
    for idx, result in ipairs(searchResults) do
        searchResults[idx] = result:gmatch("([^%-]+)")()
    end

    return searchResults
end

function GRMUtil:CreateImportDialog()
    -- Main import dialog
    ---@class WhoDatGRMImport
    local dialog = CreateFrame("Frame", "WhoDatGRMImport", UIParent, "BasicFrameTemplate")
    dialog:SetPoint("CENTER")
    dialog:SetSize(400, 200)
    dialog.TitleText:SetText(L["WhoDat: GRM Import Tool"])
    dialog:SetFrameStrata("DIALOG")
    dialog:HookScript("OnHide", function(d)
        ---@cast d WhoDatGRMImport
        if d.CharInput and d.CharInput:HasFocus() then
            d.CharInput:ClearFocus()
        end
    end)
    dialog:Hide()
    -- Allows for closing the dialog when ESC is pressed
    tinsert(UISpecialFrames, dialog:GetName())

    local charInstructions = dialog:CreateFontString(nil, "OVERLAY", "GameTooltipText")
    charInstructions:SetPoint("TOPLEFT", dialog.TopBorder, "BOTTOMLEFT", 0, -10)
    charInstructions:SetPoint("TOPRIGHT", dialog.TopBorder, "BOTTOMRIGHT", 0, -10)
    charInstructions:SetText(L["Enter the name of a character in your guild to find alts or mains for"])
    charInstructions:SetJustifyH("CENTER")
    dialog.CharInstructions = charInstructions
    
    -- Character name input field
    local charInput = CreateFrame("EditBox", "CharacterInput", dialog, "InputBoxTemplate")
    charInput:SetPoint("TOP", charInstructions, "BOTTOM", 0, -5)
    charInput:SetSize(200, 20)
    charInput:SetAutoFocus(false)
    charInput:HookScript("OnEscapePressed", function(inp) inp:ClearFocus() end)
    charInput:HookScript("OnEnterPressed", function(inp) inp:ClearFocus() end)
    dialog.CharInput = charInput
    
    local nicknameInstructions = dialog:CreateFontString(nil, "OVERLAY", "GameTooltipText")
    nicknameInstructions:SetPoint("TOPLEFT", charInstructions, "BOTTOMLEFT", 0, -45)
    nicknameInstructions:SetPoint("TOPRIGHT", charInstructions, "BOTTOMRIGHT", 0, -45)
    nicknameInstructions:SetText(L["Enter a nickname for these characters"])
    nicknameInstructions:SetJustifyH("CENTER")
    dialog.NicknameInstructions = nicknameInstructions

    -- Nickname input field
    local nicknameInput = CreateFrame("EditBox", "NicknameInput", dialog, "InputBoxTemplate")
    nicknameInput:SetPoint("TOP", nicknameInstructions, "BOTTOM", 0, -5)
    nicknameInput:SetSize(200, 20)
    nicknameInput:SetAutoFocus(false)
    nicknameInput:HookScript("OnEscapePressed", function(inp) inp:ClearFocus() end)
    nicknameInput:HookScript("OnEnterPressed", function(inp) inp:ClearFocus() end)
    dialog.NicknameInput = nicknameInput

    ---Helper function for fetching import dialog input values
    ---@return string charInput
    ---@return string nicknameInput
    local function getInputValues()
        return charInput:GetText(), nicknameInput:GetText()
    end
    
    -- Confirmation button to import characters and update the database
    local confirmButton = CreateFrame("Button", nil, dialog, "UIPanelButtonTemplate")
    confirmButton:SetPoint("TOP", nicknameInput, "BOTTOM", 0, -15)
    confirmButton:SetWidth(100)
    confirmButton:SetText(L["Import"])
    confirmButton:Disable()
    confirmButton:HookScript("OnEnter", function()
        local character, nickname = getInputValues()
        GameTooltip:SetOwner(confirmButton, "ANCHOR_RIGHT")
        if not GRMUtil.IsGRMInitialized() then
            GameTooltip:SetText(L["GRM is not yet initialized. Please try again soon."])
            GameTooltip:Show()
            return
        end

        local linkedToons = GRMUtil.GetLinkedToons(character)
        if #linkedToons > 0 then
            GameTooltip:SetText(WhoDat.ReplacePlaceholders(L["{count} character(s) will be imported with nickname {nickname}"], {
                count = #linkedToons,
                nickname = LEGENDARY_ORANGE_COLOR:WrapTextInColorCode(nickname)
            }))
            GameTooltip:AddLine(" ")
            for _, toon in ipairs(linkedToons) do
                GameTooltip:AddLine(UNCOMMON_GREEN_COLOR:WrapTextInColorCode(toon))
            end
            GameTooltip:Show()
        end
    end)
    confirmButton:HookScript("OnLeave", function() GameTooltip:Hide() end)
    confirmButton:HookScript("OnClick", function()
        local character, nickname = getInputValues()
        local dbNicknames = WhoDat.db.profile.nicknames

        if not dbNicknames[nickname] then
            WhoDat:PrintDebugMsg("Adding new db nickname entry for", nickname)
            dbNicknames[nickname] = {}
        end

        local dbNicknameGroup = dbNicknames[nickname]
        for _, char in ipairs(GRMUtil.GetLinkedToons(character)) do
            if not dbNicknameGroup[char] then
                dbNicknameGroup[char] = true
            end
        end
        WhoDat:Print(L["GRM Import is complete"])
        WhoDat:BuildNicknameEntryList()
        dialog:Hide()
    end)
    dialog.ImportButton = confirmButton

    -- Toggle between the two inputs when Tab is pressed
    charInput:HookScript("OnTabPressed", function() nicknameInput:SetFocus() end)
    nicknameInput:HookScript("OnTabPressed", function() charInput:SetFocus() end)

    -- Determine whether the confirm button should be enabled or disabled based on input values
    local function handleInputChanged()
        local character, nickname = getInputValues()
        if strtrim(character) ~= "" and strtrim(nickname) ~= "" then
            confirmButton:Enable()
        else
            confirmButton:Disable()
        end
    end
    charInput:HookScript("OnTextChanged", function() handleInputChanged() end)
    nicknameInput:HookScript("OnTextChanged", function() handleInputChanged() end)

    -- Clears inputs when the dialog is closed
    dialog:HookScript("OnHide", function()
        charInput:SetText("")
        nicknameInput:SetText("")
    end)
end

function GRMUtil:OpenImportDialog()
    if not WhoDatGRMImport then
        self:CreateImportDialog()
        WhoDatGRMImport:Show()
    elseif not WhoDatGRMImport:IsShown() then
        WhoDatGRMImport:Show()
    end
end

WhoDat.GRMUtil = GRMUtil
