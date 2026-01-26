-- GUI.lua - Options Panel for MinimalistCooldownEdge

local addonName, addon = ...
addon.GUI = {}

-- Font options
local fontOptions = {
    ["Fonts\\FRIZQT__.TTF"] = "Friz Quadrata (Default)",
    ["Fonts\\ARIALN.TTF"] = "Arial Narrow",
    ["Fonts\\MORPHEUS.TTF"] = "Morpheus",
    ["Fonts\\skurri.ttf"] = "Skurri",
    ["Fonts\\2002.TTF"] = "2002",
    ["Fonts\\2002B.TTF"] = "2002 Bold",        
    ["Fonts\\FRIZQT___CYR.TTF"] = "Friz Quadrata Cyrillic",
}

local fontStyleOptions = {
    ["OUTLINE"] = "Outline",
    ["THICKOUTLINE"] = "Thick Outline",
    ["MONOCHROME"] = "Monochrome",
    ["NONE"] = "None",
}

-- Helper: Refresh visuals immediately when settings change
local function RefreshVisuals()
    -- We use the safe manual update method from Core.lua
    -- calling ActionBarController_UpdateAll here would cause Taint errors.
    if addon.ForceUpdateAll then
        addon:ForceUpdateAll()
    end
end

-- Create the options panel
function addon.GUI:CreateOptionsPanel()
    local panel = CreateFrame("Frame", "MinimalistCooldownEdgeOptions", UIParent)
    panel.name = "MinimalistCooldownEdge"
    
    -- Title
    local title = panel:CreateFontString(nil, "ARTWORK", "GameFontNormalLarge")
    title:SetPoint("TOPLEFT", 16, -16)
    title:SetText("|cff00ff00MinimalistCooldownEdge|r Configuration")
    
    -- Version
    local version = panel:CreateFontString(nil, "ARTWORK", "GameFontNormalSmall")
    version:SetPoint("TOPLEFT", title, "BOTTOMLEFT", 0, -8)
    version:SetText("Version 1.4 - Customize your cooldown appearance")
    
    local yOffset = -80
    
    -- === FONT SETTINGS ===
    local fontHeader = panel:CreateFontString(nil, "ARTWORK", "GameFontHighlight")
    fontHeader:SetPoint("TOPLEFT", 16, yOffset)
    fontHeader:SetText("|cffffd700Font Settings|r")
    yOffset = yOffset - 30
    
    -- Font Dropdown
    local fontLabel = panel:CreateFontString(nil, "ARTWORK", "GameFontNormal")
    fontLabel:SetPoint("TOPLEFT", 30, yOffset)
    fontLabel:SetText("Font:")
    
    local fontDropdown = CreateFrame("Frame", "MCE_FontDropdown", panel, "UIDropDownMenuTemplate")
    fontDropdown:SetPoint("TOPLEFT", 120, yOffset + 5)
    UIDropDownMenu_SetWidth(fontDropdown, 200)
    UIDropDownMenu_Initialize(fontDropdown, function(self, level)
        local info = UIDropDownMenu_CreateInfo()
        for path, name in pairs(fontOptions) do
            info.text = name
            info.value = path
            info.func = function()
                addon.Config:Set("font", path)
                UIDropDownMenu_SetSelectedValue(fontDropdown, path)
                RefreshVisuals()
            end
            info.checked = (addon.Config:Get("font") == path)
            UIDropDownMenu_AddButton(info)
        end
    end)
    UIDropDownMenu_SetSelectedValue(fontDropdown, addon.Config:Get("font"))
    UIDropDownMenu_SetText(fontDropdown, fontOptions[addon.Config:Get("font")] or "Custom")
    
    yOffset = yOffset - 40
    
    -- Font Size Slider
    local fontSizeLabel = panel:CreateFontString(nil, "ARTWORK", "GameFontNormal")
    fontSizeLabel:SetPoint("TOPLEFT", 30, yOffset)
    fontSizeLabel:SetText("Font Size:")
    
    local fontSizeSlider = CreateFrame("Slider", "MCE_FontSizeSlider", panel, "OptionsSliderTemplate")
    fontSizeSlider:SetPoint("TOPLEFT", 120, yOffset)
    fontSizeSlider:SetMinMaxValues(8, 36)
    fontSizeSlider:SetValue(addon.Config:Get("fontSize"))
    fontSizeSlider:SetValueStep(1)
    fontSizeSlider:SetObeyStepOnDrag(true)
    fontSizeSlider:SetWidth(200)
    _G[fontSizeSlider:GetName() .. 'Low']:SetText('8')
    _G[fontSizeSlider:GetName() .. 'High']:SetText('36')
    _G[fontSizeSlider:GetName() .. 'Text']:SetText(addon.Config:Get("fontSize"))
    fontSizeSlider:SetScript("OnValueChanged", function(self, value)
        value = math.floor(value + 0.5)
        _G[self:GetName() .. 'Text']:SetText(value)
        addon.Config:Set("fontSize", value)
        RefreshVisuals()
    end)
    
    yOffset = yOffset - 40
    
    -- Font Style Dropdown
    local fontStyleLabel = panel:CreateFontString(nil, "ARTWORK", "GameFontNormal")
    fontStyleLabel:SetPoint("TOPLEFT", 30, yOffset)
    fontStyleLabel:SetText("Font Style:")
    
    local fontStyleDropdown = CreateFrame("Frame", "MCE_FontStyleDropdown", panel, "UIDropDownMenuTemplate")
    fontStyleDropdown:SetPoint("TOPLEFT", 120, yOffset + 5)
    UIDropDownMenu_SetWidth(fontStyleDropdown, 200)
    UIDropDownMenu_Initialize(fontStyleDropdown, function(self, level)
        local info = UIDropDownMenu_CreateInfo()
        for value, name in pairs(fontStyleOptions) do
            info.text = name
            info.value = value
            info.func = function()
                local styleValue = (value == "NONE") and nil or value
                addon.Config:Set("fontStyle", styleValue)
                UIDropDownMenu_SetSelectedValue(fontStyleDropdown, value)
                RefreshVisuals()
            end
            local currentStyle = addon.Config:Get("fontStyle") or "NONE"
            info.checked = (currentStyle == value)
            UIDropDownMenu_AddButton(info)
        end
    end)
    local currentStyle = addon.Config:Get("fontStyle") or "NONE"
    UIDropDownMenu_SetSelectedValue(fontStyleDropdown, currentStyle)
    UIDropDownMenu_SetText(fontStyleDropdown, fontStyleOptions[currentStyle])
    
    yOffset = yOffset - 40
    
    -- Text Color Picker
    local textColorLabel = panel:CreateFontString(nil, "ARTWORK", "GameFontNormal")
    textColorLabel:SetPoint("TOPLEFT", 30, yOffset)
    textColorLabel:SetText("Text Color:")
    
    local textColorButton = CreateFrame("Button", "MCE_TextColorButton", panel)
    textColorButton:SetPoint("TOPLEFT", 120, yOffset - 5)
    textColorButton:SetSize(40, 20)
    
    local textColorTexture = textColorButton:CreateTexture(nil, "BACKGROUND")
    textColorTexture:SetAllPoints()
    local color = addon.Config:Get("textColor")
    textColorTexture:SetColorTexture(color.r or color[1], color.g or color[2], color.b or color[3], color.a or color[4])
    
    textColorButton:SetScript("OnClick", function()
        local color = addon.Config:Get("textColor")
        local r = color.r or color[1] or 1
        local g = color.g or color[2] or 0.8
        local b = color.b or color[3] or 0
        local a = color.a or color[4] or 1
        
        local info = {
            r = r,
            g = g,
            b = b,
            opacity = a,
            hasOpacity = true,
            swatchFunc = function()
                local nr, ng, nb = ColorPickerFrame:GetColorRGB()
                local na = ColorPickerFrame:GetColorAlpha()
                addon.Config:Set("textColor", { r = nr, g = ng, b = nb, a = na })
                textColorTexture:SetColorTexture(nr, ng, nb, na)
                RefreshVisuals()
            end,
            cancelFunc = function(previousValues)
                addon.Config:Set("textColor", { 
                    r = previousValues.r, 
                    g = previousValues.g, 
                    b = previousValues.b, 
                    a = previousValues.opacity 
                })
                textColorTexture:SetColorTexture(previousValues.r, previousValues.g, previousValues.b, previousValues.opacity)
                RefreshVisuals()
            end,
        }
        ColorPickerFrame:SetupColorPickerAndShow(info)
    end)
    
    yOffset = yOffset - 50
    
    -- === EDGE SETTINGS ===
    local edgeHeader = panel:CreateFontString(nil, "ARTWORK", "GameFontHighlight")
    edgeHeader:SetPoint("TOPLEFT", 16, yOffset)
    edgeHeader:SetText("|cffffd700Edge Settings|r")
    yOffset = yOffset - 30
    
    -- Enable Edge Checkbox
    local edgeCheckbox = CreateFrame("CheckButton", "MCE_EdgeCheckbox", panel, "UICheckButtonTemplate")
    edgeCheckbox:SetPoint("TOPLEFT", 30, yOffset)
    edgeCheckbox:SetChecked(addon.Config:Get("edgeEnabled"))
    edgeCheckbox.text = edgeCheckbox:CreateFontString(nil, "ARTWORK", "GameFontNormal")
    edgeCheckbox.text:SetPoint("LEFT", edgeCheckbox, "RIGHT", 5, 0)
    edgeCheckbox.text:SetText("Enable Cooldown Edge")
    edgeCheckbox:SetScript("OnClick", function(self)
        addon.Config:Set("edgeEnabled", self:GetChecked())
        RefreshVisuals()
    end)
    
    yOffset = yOffset - 30
    
    -- Edge Scale Slider
    local edgeScaleLabel = panel:CreateFontString(nil, "ARTWORK", "GameFontNormal")
    edgeScaleLabel:SetPoint("TOPLEFT", 30, yOffset)
    edgeScaleLabel:SetText("Edge Scale:")
    
    local edgeScaleSlider = CreateFrame("Slider", "MCE_EdgeScaleSlider", panel, "OptionsSliderTemplate")
    edgeScaleSlider:SetPoint("TOPLEFT", 120, yOffset)
    edgeScaleSlider:SetMinMaxValues(0.5, 2.0)
    edgeScaleSlider:SetValue(addon.Config:Get("edgeScale"))
    edgeScaleSlider:SetValueStep(0.1)
    edgeScaleSlider:SetObeyStepOnDrag(true)
    edgeScaleSlider:SetWidth(200)
    _G[edgeScaleSlider:GetName() .. 'Low']:SetText('0.5')
    _G[edgeScaleSlider:GetName() .. 'High']:SetText('2.0')
    _G[edgeScaleSlider:GetName() .. 'Text']:SetText(string.format("%.1f", addon.Config:Get("edgeScale")))
    edgeScaleSlider:SetScript("OnValueChanged", function(self, value)
        _G[self:GetName() .. 'Text']:SetText(string.format("%.1f", value))
        addon.Config:Set("edgeScale", value)
        RefreshVisuals()
    end)
    
    yOffset = yOffset - 50
    
    -- === BUTTONS ===
    local resetButton = CreateFrame("Button", "MCE_ResetButton", panel, "UIPanelButtonTemplate")
    resetButton:SetPoint("BOTTOMLEFT", 16, 16)
    resetButton:SetSize(120, 25)
    resetButton:SetText("Reset to Defaults")
    resetButton:SetScript("OnClick", function()
        StaticPopup_Show("MCE_CONFIRM_RESET")
    end)
    
    local reloadButton = CreateFrame("Button", "MCE_ReloadButton", panel, "UIPanelButtonTemplate")
    reloadButton:SetPoint("LEFT", resetButton, "RIGHT", 10, 0)
    reloadButton:SetSize(100, 25)
    reloadButton:SetText("Reload UI")
    reloadButton:SetScript("OnClick", function()
        ReloadUI()
    end)
    
    -- Register with Interface Options (Modern API)
    local category = Settings.RegisterCanvasLayoutCategory(panel, panel.name)
    Settings.RegisterAddOnCategory(category)
    addon.optionsCategory = category
    
    return panel
end

-- Static Popup for Reset Confirmation
StaticPopupDialogs["MCE_CONFIRM_RESET"] = {
    text = "Are you sure you want to reset all settings to default values?",
    button1 = "Yes",
    button2 = "No",
    OnAccept = function()
        addon.Config:Reset()
        ReloadUI()
    end,
    timeout = 0,
    whileDead = true,
    hideOnEscape = true,
    preferredIndex = 3,
}

-- Slash commands
SLASH_MINIMALISTCOOLDOWNEDGE1 = "/mce"
SLASH_MINIMALISTCOOLDOWNEDGE2 = "/minimalistcooldownedge"
SlashCmdList["MINIMALISTCOOLDOWNEDGE"] = function(msg)
    -- FIX: Check for combat before attempting to open UI
    if InCombatLockdown() then
        print("|cff00ff00MinimalistCooldownEdge:|r Cannot open settings while in combat.")
        return
    end
    
    Settings.OpenToCategory(addon.optionsCategory:GetID())
end

-- Initialize GUI on load
local function InitGUI()
    addon.GUI:CreateOptionsPanel()
    print("|cff00ff00MinimalistCooldownEdge:|r Type /mce to open settings.")
end

local eventFrame = CreateFrame("Frame")
eventFrame:RegisterEvent("ADDON_LOADED")
eventFrame:SetScript("OnEvent", function(self, event, loadedAddon)
    if loadedAddon == addonName then
        InitGUI()
        self:UnregisterEvent("ADDON_LOADED")
    end
end)