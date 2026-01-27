-- GUI.lua - Options Panel with Polished Layout & Detailed Descriptions

local addonName, addon = ...
addon.GUI = {}

local currentCategory = "actionbar"
local tempDB = {} -- Temporary buffer for unsaved changes

local fontOptions = {
    ["Fonts\\FRIZQT__.TTF"] = "Friz Quadrata",
    ["Fonts\\ARIALN.TTF"] = "Arial Narrow",
    ["Fonts\\MORPHEUS.TTF"] = "Morpheus",
    ["Fonts\\skurri.ttf"] = "Skurri",
    ["Fonts\\2002.TTF"] = "2002",
}

local categoryLabels = {
    ["actionbar"] = "Action Bars (Spells)",
    ["nameplate"] = "Nameplates",
    ["unitframe"] = "Unit Frames",
    ["global"] = "CD Manager, Others & Global Settings"
}

local uiElements = {}

-- === RELOAD DIALOG ===
StaticPopupDialogs["MCE_CONFIRM_RELOAD"] = {
    text = "|cff00ff00MinimalistCooldownEdge|r\n\nChanges to Global Settings or disabling a category require a UI Reload to fully take effect.\n\nReload now?",
    button1 = "Reload",
    button2 = "Later",
    OnAccept = function() ReloadUI() end,
    timeout = 0,
    whileDead = true,
    hideOnEscape = true,
    preferredIndex = 3,
}

-- === TEMP DB MANAGEMENT ===

local function InitTempDB()
    if MinimalistCooldownEdgeDB then
        tempDB = addon.CopyTable(MinimalistCooldownEdgeDB)
    end
end

local function GetTemp(key)
    if tempDB[currentCategory] then
        return tempDB[currentCategory][key]
    end
end

local function SetTemp(key, value)
    if not tempDB[currentCategory] then tempDB[currentCategory] = {} end
    tempDB[currentCategory][key] = value
end

local function RequiresReload(oldDB, newDB)
    if not oldDB or not newDB then return false end

    -- 1. Check if ANY setting in 'global' category changed
    local oldGlobal = oldDB["global"]
    local newGlobal = newDB["global"]
    if oldGlobal and newGlobal then
        for k, v in pairs(newGlobal) do
            if type(v) ~= "table" and oldGlobal[k] ~= v then
                return true
            end
        end
    end

    -- 2. Check if ANY category was DISABLED (True -> False)
    for _, cat in ipairs(addon.Categories) do
        local oldCat = oldDB[cat]
        local newCat = newDB[cat]
        if oldCat and newCat then
            if oldCat.enabled == true and newCat.enabled == false then
                return true
            end
        end
    end

    return false
end

local function SaveChanges()
    if tempDB then
        -- Check requirement BEFORE overwriting the live DB
        local needReload = RequiresReload(MinimalistCooldownEdgeDB, tempDB)

        -- Commit Changes
        MinimalistCooldownEdgeDB = addon.CopyTable(tempDB)
        
        if needReload then
            StaticPopup_Show("MCE_CONFIRM_RELOAD")
            addon:ForceUpdateAll() 
        else
            addon:ForceUpdateAll()
            print("|cff00ff00MCE:|r Configuration Saved & Applied.")
        end
    end
end

local function ResetCurrentCategory()
    local defaults = addon.Config:GetDefaultStyle()
    tempDB[currentCategory] = addon.CopyTable(defaults)
    
    if currentCategory == "actionbar" then
        tempDB[currentCategory].enabled = true
    else
        tempDB[currentCategory].enabled = false
    end

    if currentCategory == "nameplate" or currentCategory == "unitframe" then 
        tempDB[currentCategory].fontSize = 12 
    end

    print("|cff00ff00MCE:|r Reset defaults for: " .. (categoryLabels[currentCategory] or currentCategory))
end

local function ResetAllCategories()
    local defaults = addon.Config:GetDefaultStyle()
    for _, cat in ipairs(addon.Categories) do
        tempDB[cat] = addon.CopyTable(defaults)
        
        if cat == "actionbar" then
            tempDB[cat].enabled = true
        else
            tempDB[cat].enabled = false
        end

        if cat == "nameplate" or cat == "unitframe" then 
            tempDB[cat].fontSize = 12 
        end
    end
    print("|cff00ff00MCE:|r All categories reset to defaults.")
end

-- === HELPER: CREATE VALUE LABEL ===
local function CreateValueLabel(slider, initialValue)
    local valText = slider:CreateFontString(nil, "ARTWORK", "GameFontHighlight")
    valText:SetPoint("LEFT", slider, "RIGHT", 10, 0)
    valText:SetText(initialValue)
    slider.ValText = valText
    return valText
end

-- === GUI UPDATE ===

local function UpdateGUIValues()
    -- Enable/Disable Category Checkbox
    uiElements.enabledCheckbox:SetChecked(GetTemp("enabled"))

    -- Font
    local currentFont = GetTemp("font") or "Fonts\\FRIZQT__.TTF"
    UIDropDownMenu_SetText(uiElements.fontDropdown, fontOptions[currentFont] or "Custom")
    
    -- Font Size
    local size = GetTemp("fontSize") or 18
    uiElements.fontSizeSlider:SetValue(size)
    if uiElements.fontSizeSlider.ValText then uiElements.fontSizeSlider.ValText:SetText(size) end
    
    -- Style
    local style = GetTemp("fontStyle") or "NONE"
    UIDropDownMenu_SetText(uiElements.fontStyleDropdown, style)
    
    -- Color
    local c = GetTemp("textColor") or {r=1, g=1, b=1, a=1}
    uiElements.textColorTexture:SetColorTexture(c.r, c.g, c.b, c.a)
    
    -- Edge
    uiElements.edgeCheckbox:SetChecked(GetTemp("edgeEnabled"))
    
    local scale = GetTemp("edgeScale") or 1.0
    uiElements.edgeScaleSlider:SetValue(scale)
    if uiElements.edgeScaleSlider.ValText then uiElements.edgeScaleSlider.ValText:SetText(string.format("%.1f", scale)) end

    -- Performance (Visible only if Global)
    if currentCategory == "global" then
        uiElements.globalHeader:Show()
        uiElements.scanDepthSlider:Show()
        uiElements.scanDesc:Show()
        local depth = GetTemp("scanDepth") or 10
        uiElements.scanDepthSlider:SetValue(depth)
        if uiElements.scanDepthSlider.ValText then uiElements.scanDepthSlider.ValText:SetText(depth) end
    else
        uiElements.globalHeader:Hide()
        uiElements.scanDepthSlider:Hide()
        uiElements.scanDesc:Hide()
    end
end

-- === CREATE PANEL ===

function addon.GUI:CreateOptionsPanel()
    InitTempDB()

    local panel = CreateFrame("Frame", "MinimalistCooldownEdgeOptions", UIParent)
    panel.name = "MinimalistCooldownEdge"
    
    -- TITLE UPDATED HERE
    local title = panel:CreateFontString(nil, "ARTWORK", "GameFontNormalLarge")
    title:SetPoint("TOPLEFT", 16, -16)
    title:SetText("|cff00ff00MinimalistCooldownEdge|r (v1.8)")

    local yOffset = -50 

    -- 1. CATEGORY SELECTOR
    local catLabel = panel:CreateFontString(nil, "ARTWORK", "GameFontHighlight")
    catLabel:SetPoint("TOPLEFT", 16, yOffset)
    catLabel:SetText("Editing Category:")
    
    local catDropdown = CreateFrame("Frame", "MCE_CategoryDropdown", panel, "UIDropDownMenuTemplate")
    catDropdown:SetPoint("LEFT", catLabel, "RIGHT", 10, -2)
    UIDropDownMenu_SetWidth(catDropdown, 250)
    UIDropDownMenu_Initialize(catDropdown, function(self, level)
        local info = UIDropDownMenu_CreateInfo()
        for _, catKey in ipairs(addon.Categories) do
            info.text = categoryLabels[catKey] or catKey
            info.value = catKey
            info.func = function()
                currentCategory = catKey
                UIDropDownMenu_SetSelectedValue(catDropdown, catKey)
                UpdateGUIValues()
            end
            info.checked = (currentCategory == catKey)
            UIDropDownMenu_AddButton(info)
        end
    end)
    UIDropDownMenu_SetSelectedValue(catDropdown, currentCategory)
    UIDropDownMenu_SetText(catDropdown, categoryLabels[currentCategory])
    
    yOffset = yOffset - 40 

    -- SEPARATOR LINE
    local line1 = panel:CreateTexture(nil, "ARTWORK")
    line1:SetHeight(1)
    line1:SetColorTexture(0.3, 0.3, 0.3, 0.5)
    line1:SetPoint("TOPLEFT", 10, yOffset)
    line1:SetPoint("TOPRIGHT", -10, yOffset)
    
    yOffset = yOffset - 20 
    
    local sectionCat = panel:CreateFontString(nil, "ARTWORK", "GameFontNormal")
    sectionCat:SetPoint("TOPLEFT", 16, yOffset)
    sectionCat:SetText("Category Parameters")
    
    yOffset = yOffset - 30

    -- ENABLE CATEGORY CHECKBOX
    local enableCb = CreateFrame("CheckButton", "MCE_EnableCategoryCheckbox", panel, "UICheckButtonTemplate")
    enableCb:SetPoint("TOPLEFT", 20, yOffset)
    uiElements.enabledCheckbox = enableCb
    _G[enableCb:GetName().."Text"]:SetText("|cffffd100Enable this Category|r")
    enableCb:SetScript("OnClick", function(self)
        SetTemp("enabled", self:GetChecked())
    end)

    yOffset = yOffset - 40

    -- FONT FACE
    local fontLabel = panel:CreateFontString(nil, "ARTWORK", "GameFontHighlightSmall")
    fontLabel:SetPoint("TOPLEFT", 20, yOffset)
    fontLabel:SetText("Font Face:")

    local fontDropdown = CreateFrame("Frame", "MCE_FontDropdown", panel, "UIDropDownMenuTemplate")
    fontDropdown:SetPoint("LEFT", fontLabel, "RIGHT", -5, -2)
    uiElements.fontDropdown = fontDropdown
    UIDropDownMenu_SetWidth(fontDropdown, 180)
    UIDropDownMenu_Initialize(fontDropdown, function(self, level)
        local info = UIDropDownMenu_CreateInfo()
        for path, name in pairs(fontOptions) do
            info.text = name
            info.value = path
            info.func = function()
                SetTemp("font", path)
                UIDropDownMenu_SetSelectedValue(fontDropdown, path)
            end
            info.checked = (GetTemp("font") == path)
            UIDropDownMenu_AddButton(info)
        end
    end)

    yOffset = yOffset - 50 

    -- === ROW: SIZE | STYLE | COLOR ===

    -- 1. FONT SIZE SLIDER
    local sizeSlider = CreateFrame("Slider", "MCE_FontSizeSlider", panel, "OptionsSliderTemplate")
    sizeSlider:SetPoint("TOPLEFT", 25, yOffset)
    uiElements.fontSizeSlider = sizeSlider
    sizeSlider:SetMinMaxValues(8, 36)
    sizeSlider:SetValueStep(1)
    sizeSlider:SetObeyStepOnDrag(true)
    _G[sizeSlider:GetName() .. 'Text']:SetText("") 
    _G[sizeSlider:GetName() .. 'Low']:SetText('8')
    _G[sizeSlider:GetName() .. 'High']:SetText('36')
    
    CreateValueLabel(sizeSlider, "18") 
    
    local sizeLabel = sizeSlider:CreateFontString(nil, "ARTWORK", "GameFontHighlightSmall")
    sizeLabel:SetPoint("BOTTOMLEFT", sizeSlider, "TOPLEFT", 0, 4) 
    sizeLabel:SetText("Font Size")

    sizeSlider:SetScript("OnValueChanged", function(self, value)
        value = math.floor(value + 0.5)
        if self.ValText then self.ValText:SetText(value) end
        SetTemp("fontSize", value)
    end)

    -- 2. FONT STYLE 
    local styleDropdown = CreateFrame("Frame", "MCE_FontStyleDropdown", panel, "UIDropDownMenuTemplate")
    styleDropdown:SetPoint("LEFT", sizeSlider, "RIGHT", 40, 2)
    uiElements.fontStyleDropdown = styleDropdown
    UIDropDownMenu_SetWidth(styleDropdown, 110)
    UIDropDownMenu_Initialize(styleDropdown, function(self, level)
        local info = UIDropDownMenu_CreateInfo()
        local styles = { "OUTLINE", "THICKOUTLINE", "MONOCHROME", "NONE" }
        for _, s in ipairs(styles) do
            info.text = s
            info.value = s
            info.func = function()
                local val = (s == "NONE") and nil or s
                SetTemp("fontStyle", val)
                UIDropDownMenu_SetSelectedValue(styleDropdown, s)
            end
            local curr = GetTemp("fontStyle") or "NONE"
            info.checked = (curr == s)
            UIDropDownMenu_AddButton(info)
        end
    end)
    
    local styleLabel = styleDropdown:CreateFontString(nil, "ARTWORK", "GameFontHighlightSmall")
    styleLabel:SetPoint("BOTTOMLEFT", styleDropdown, "TOPLEFT", 18, 5)
    styleLabel:SetText("Outline Style")

    -- 3. COLOR
    local colorButton = CreateFrame("Button", "MCE_ColorButton", panel)
    colorButton:SetPoint("LEFT", styleDropdown, "RIGHT", 15, 2)
    colorButton:SetSize(24, 24)
    colorButton:SetNormalTexture("Interface\\ChatFrame\\ChatFrameColorSwatch")
    
    local colTex = colorButton:CreateTexture(nil, "OVERLAY")
    colTex:SetPoint("CENTER")
    colTex:SetSize(14, 14)
    colTex:SetColorTexture(1,1,1,1)
    uiElements.textColorTexture = colTex
    
    local colorLabel = colorButton:CreateFontString(nil, "ARTWORK", "GameFontHighlightSmall")
    colorLabel:SetPoint("BOTTOM", colorButton, "TOP", 0, 5)
    colorLabel:SetText("Color")
    
    colorButton:SetScript("OnClick", function()
        local c = GetTemp("textColor") or {r=1,g=1,b=1,a=1}
        local info = {
            r = c.r, g = c.g, b = c.b, opacity = c.a, hasOpacity = true,
            swatchFunc = function()
                local r,g,b = ColorPickerFrame:GetColorRGB()
                local a = ColorPickerFrame:GetColorAlpha()
                SetTemp("textColor", {r=r,g=g,b=b,a=a})
                colTex:SetColorTexture(r,g,b,a)
            end
        }
        ColorPickerFrame:SetupColorPickerAndShow(info)
    end)
    
    yOffset = yOffset - 60 

    -- EDGE CHECKBOX
    local edgeCb = CreateFrame("CheckButton", "MCE_EdgeCheckbox", panel, "UICheckButtonTemplate")
    edgeCb:SetPoint("TOPLEFT", 20, yOffset)
    uiElements.edgeCheckbox = edgeCb
    _G[edgeCb:GetName().."Text"]:SetText("Enable Swipe Edge")
    edgeCb:SetScript("OnClick", function(self)
        SetTemp("edgeEnabled", self:GetChecked())
    end)
    
    -- EDGE SCALE SLIDER
    local scaleSlider = CreateFrame("Slider", "MCE_EdgeScaleSlider", panel, "OptionsSliderTemplate")
    scaleSlider:SetPoint("LEFT", edgeCb, "RIGHT", 180, 0)
    uiElements.edgeScaleSlider = scaleSlider
    scaleSlider:SetMinMaxValues(0.5, 2.0)
    scaleSlider:SetValueStep(0.1)
    scaleSlider:SetObeyStepOnDrag(true)
    _G[scaleSlider:GetName() .. 'Text']:SetText("") 
    _G[scaleSlider:GetName() .. 'Low']:SetText('0.5')
    _G[scaleSlider:GetName() .. 'High']:SetText('2.0')
    
    CreateValueLabel(scaleSlider, "1.0") 

    local scaleLabel = scaleSlider:CreateFontString(nil, "ARTWORK", "GameFontHighlightSmall")
    scaleLabel:SetPoint("BOTTOMLEFT", scaleSlider, "TOPLEFT", 0, 4)
    scaleLabel:SetText("Edge Scale")
    
    scaleSlider:SetScript("OnValueChanged", function(self, value)
        if self.ValText then self.ValText:SetText(string.format("%.1f", value)) end
        SetTemp("edgeScale", value)
    end)
    
    yOffset = yOffset - 50 

    -- GLOBAL HEADER
    local globalHeader = panel:CreateFontString(nil, "ARTWORK", "GameFontNormal")
    globalHeader:SetPoint("TOPLEFT", 16, yOffset)
    globalHeader:SetText("Global Addon Settings")
    uiElements.globalHeader = globalHeader
    
    yOffset = yOffset - 35 
    
    -- DEPTH SLIDER
    local scanSlider = CreateFrame("Slider", "MCE_ScanDepthSlider", panel, "OptionsSliderTemplate")
    scanSlider:SetPoint("TOPLEFT", 25, yOffset)
    uiElements.scanDepthSlider = scanSlider
    scanSlider:SetMinMaxValues(1, 20)
    scanSlider:SetValueStep(1)
    scanSlider:SetObeyStepOnDrag(true)
    _G[scanSlider:GetName() .. 'Text']:SetText("") 
    _G[scanSlider:GetName() .. 'Low']:SetText('1')
    _G[scanSlider:GetName() .. 'High']:SetText('20')
    
    CreateValueLabel(scanSlider, "10") 
    
    local scanLabel = scanSlider:CreateFontString(nil, "ARTWORK", "GameFontHighlightSmall")
    scanLabel:SetPoint("BOTTOMLEFT", scanSlider, "TOPLEFT", 0, 4)
    scanLabel:SetText("Heuristic Scan Depth (CPU)")
    
    -- DETAILED DESCRIPTION BELOW
    local scanDesc = panel:CreateFontString(nil, "ARTWORK", "GameFontNormalSmall")
    scanDesc:SetPoint("TOPLEFT", scanSlider, "BOTTOMLEFT", -5, -10)
    scanDesc:SetJustifyH("LEFT")
    scanDesc:SetSpacing(2)
    scanDesc:SetText(
        "|cffffd700Controls how deep the addon searches for parent frames.|r\n" ..
        "- |cff00ff00Low (1-10):|r Efficient. Sufficient for default UI and simple addons.\n" ..
        "- |cffff0000High (15-20):|r Required for heavy addons like |cff00ccffElvUI|r, |cff00ccffPlater|r or |cff00ccffVuhDo|r.\n" ..
        "  |cffaaaaaa(Warning: Low depth may fail to detect Nameplate buffs/debuffs.)|r"
    )
    uiElements.scanDesc = scanDesc
    
    scanSlider:SetScript("OnValueChanged", function(self, value)
        value = math.floor(value + 0.5)
        if self.ValText then self.ValText:SetText(value) end
        SetTemp("scanDepth", value)
    end)

    -- === FOOTER BUTTONS ===
    
    local saveBtn = CreateFrame("Button", nil, panel, "GameMenuButtonTemplate")
    saveBtn:SetPoint("BOTTOMRIGHT", -16, 16)
    saveBtn:SetSize(140, 30)
    saveBtn:SetText("Save & Apply")
    saveBtn:SetScript("OnClick", function()
        SaveChanges()
    end)
    
    local resetCatBtn = CreateFrame("Button", nil, panel, "GameMenuButtonTemplate")
    resetCatBtn:SetPoint("BOTTOMLEFT", 16, 16)
    resetCatBtn:SetSize(140, 30)
    resetCatBtn:SetText("Reset Category")
    resetCatBtn:SetScript("OnClick", function()
        ResetCurrentCategory()
        UpdateGUIValues()
    end)
    
    local resetAllBtn = CreateFrame("Button", nil, panel, "GameMenuButtonTemplate")
    resetAllBtn:SetPoint("LEFT", resetCatBtn, "RIGHT", 10, 0)
    resetAllBtn:SetSize(140, 30)
    resetAllBtn:SetText("Reset ALL")
    resetAllBtn:SetScript("OnClick", function()
        ResetAllCategories()
        UpdateGUIValues()
    end)

    -- Init
    panel:SetScript("OnShow", function()
        InitTempDB()
        UpdateGUIValues()
    end)

    local category = Settings.RegisterCanvasLayoutCategory(panel, panel.name)
    Settings.RegisterAddOnCategory(category)
    addon.optionsCategory = category
end

SLASH_MINIMALISTCOOLDOWNEDGE1 = "/mce"
SlashCmdList["MINIMALISTCOOLDOWNEDGE"] = function()
    if InCombatLockdown() then print("MCE: Combat Lock - Cannot open settings.") return end
    Settings.OpenToCategory(addon.optionsCategory:GetID())
end

local f = CreateFrame("Frame")
f:RegisterEvent("ADDON_LOADED")
f:SetScript("OnEvent", function(self, e, n)
    if n == addonName then addon.GUI:CreateOptionsPanel(); self:UnregisterAllEvents() end
end)