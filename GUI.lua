-- GUI.lua - Options Panel

local addonName, addon = ...
addon.GUI = {}

local currentCategory = "actionbar"

local fontOptions = {
    ["Fonts\\FRIZQT__.TTF"] = "Friz Quadrata",
    ["Fonts\\ARIALN.TTF"] = "Arial Narrow",
    ["Fonts\\MORPHEUS.TTF"] = "Morpheus",
    ["Fonts\\skurri.ttf"] = "Skurri",
    ["Fonts\\2002.TTF"] = "2002",
}

-- Mise à jour des labels : "Others" inclut maintenant explicitemnet les auras
local categoryLabels = {
    ["actionbar"] = "Action Bars (Spells)",
    ["nameplate"] = "Nameplates",
    ["unitframe"] = "Unit Frames",
    ["global"] = "Others (Auras, Items, Bags...)"
}

local uiElements = {}

local function RefreshVisuals()
    if addon.ForceUpdateAll then addon:ForceUpdateAll() end
end

local function UpdateGUIValues()
    UIDropDownMenu_SetText(uiElements.fontDropdown, fontOptions[addon.Config:Get("font", currentCategory)] or "Custom")
    uiElements.fontSizeSlider:SetValue(addon.Config:Get("fontSize", currentCategory))
    _G[uiElements.fontSizeSlider:GetName() .. 'Text']:SetText(addon.Config:Get("fontSize", currentCategory))
    
    local style = addon.Config:Get("fontStyle", currentCategory) or "NONE"
    UIDropDownMenu_SetText(uiElements.fontStyleDropdown, style)
    
    local c = addon.Config:Get("textColor", currentCategory)
    uiElements.textColorTexture:SetColorTexture(c.r, c.g, c.b, c.a)
    
    uiElements.edgeCheckbox:SetChecked(addon.Config:Get("edgeEnabled", currentCategory))
    
    uiElements.edgeScaleSlider:SetValue(addon.Config:Get("edgeScale", currentCategory))
    _G[uiElements.edgeScaleSlider:GetName() .. 'Text']:SetText(string.format("%.1f", addon.Config:Get("edgeScale", currentCategory)))
end

function addon.GUI:CreateOptionsPanel()
    local panel = CreateFrame("Frame", "MinimalistCooldownEdgeOptions", UIParent)
    panel.name = "MinimalistCooldownEdge"
    
    local title = panel:CreateFontString(nil, "ARTWORK", "GameFontNormalLarge")
    title:SetPoint("TOPLEFT", 16, -16)
    title:SetText("|cff00ff00MinimalistCooldownEdge|r (v1.5)")

    local yOffset = -50

    -- CATEGORY SELECTOR
    local catLabel = panel:CreateFontString(nil, "ARTWORK", "GameFontHighlight")
    catLabel:SetPoint("TOPLEFT", 16, yOffset)
    catLabel:SetText("Select Category:")
    
    local catDropdown = CreateFrame("Frame", "MCE_CategoryDropdown", panel, "UIDropDownMenuTemplate")
    catDropdown:SetPoint("LEFT", catLabel, "RIGHT", 10, -2)
    UIDropDownMenu_SetWidth(catDropdown, 200)
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
    
    yOffset = yOffset - 50
    
    -- FONT
    local fontHeader = panel:CreateFontString(nil, "ARTWORK", "GameFontHighlight")
    fontHeader:SetPoint("TOPLEFT", 16, yOffset)
    fontHeader:SetText("|cffffd700Typography|r")
    yOffset = yOffset - 30
    
    local fontDropdown = CreateFrame("Frame", "MCE_FontDropdown", panel, "UIDropDownMenuTemplate")
    fontDropdown:SetPoint("TOPLEFT", 20, yOffset)
    uiElements.fontDropdown = fontDropdown
    UIDropDownMenu_SetWidth(fontDropdown, 200)
    UIDropDownMenu_Initialize(fontDropdown, function(self, level)
        local info = UIDropDownMenu_CreateInfo()
        for path, name in pairs(fontOptions) do
            info.text = name
            info.value = path
            info.func = function()
                addon.Config:Set("font", path, currentCategory)
                UIDropDownMenu_SetSelectedValue(fontDropdown, path)
                RefreshVisuals()
            end
            info.checked = (addon.Config:Get("font", currentCategory) == path)
            UIDropDownMenu_AddButton(info)
        end
    end)
    
    yOffset = yOffset - 40
    
    -- SIZE
    local fontSizeSlider = CreateFrame("Slider", "MCE_FontSizeSlider", panel, "OptionsSliderTemplate")
    fontSizeSlider:SetPoint("TOPLEFT", 35, yOffset)
    uiElements.fontSizeSlider = fontSizeSlider
    fontSizeSlider:SetMinMaxValues(8, 36)
    fontSizeSlider:SetValueStep(1)
    fontSizeSlider:SetObeyStepOnDrag(true)
    _G[fontSizeSlider:GetName() .. 'Low']:SetText('8')
    _G[fontSizeSlider:GetName() .. 'High']:SetText('36')
    fontSizeSlider:SetScript("OnValueChanged", function(self, value)
        value = math.floor(value + 0.5)
        _G[self:GetName() .. 'Text']:SetText(value)
        addon.Config:Set("fontSize", value, currentCategory)
        RefreshVisuals()
    end)
    
    yOffset = yOffset - 40
    
    -- STYLE
    local fontStyleDropdown = CreateFrame("Frame", "MCE_FontStyleDropdown", panel, "UIDropDownMenuTemplate")
    fontStyleDropdown:SetPoint("TOPLEFT", 20, yOffset)
    uiElements.fontStyleDropdown = fontStyleDropdown
    UIDropDownMenu_SetWidth(fontStyleDropdown, 200)
    UIDropDownMenu_Initialize(fontStyleDropdown, function(self, level)
        local info = UIDropDownMenu_CreateInfo()
        local styles = { "OUTLINE", "THICKOUTLINE", "MONOCHROME", "NONE" }
        for _, s in ipairs(styles) do
            info.text = s
            info.value = s
            info.func = function()
                local val = (s == "NONE") and nil or s
                addon.Config:Set("fontStyle", val, currentCategory)
                UIDropDownMenu_SetSelectedValue(fontStyleDropdown, s)
                RefreshVisuals()
            end
            local curr = addon.Config:Get("fontStyle", currentCategory) or "NONE"
            info.checked = (curr == s)
            UIDropDownMenu_AddButton(info)
        end
    end)

    -- COLOR
    local colorButton = CreateFrame("Button", "MCE_ColorButton", panel)
    colorButton:SetPoint("LEFT", fontStyleDropdown, "RIGHT", 10, 2)
    colorButton:SetSize(25, 25)
    local colTex = colorButton:CreateTexture(nil, "BACKGROUND")
    colTex:SetAllPoints()
    colTex:SetColorTexture(1,1,1,1)
    uiElements.textColorTexture = colTex
    
    colorButton:SetScript("OnClick", function()
        local c = addon.Config:Get("textColor", currentCategory)
        local info = {
            r = c.r, g = c.g, b = c.b, opacity = c.a, hasOpacity = true,
            swatchFunc = function()
                local r,g,b = ColorPickerFrame:GetColorRGB()
                local a = ColorPickerFrame:GetColorAlpha()
                addon.Config:Set("textColor", {r=r,g=g,b=b,a=a}, currentCategory)
                colTex:SetColorTexture(r,g,b,a)
                RefreshVisuals()
            end
        }
        ColorPickerFrame:SetupColorPickerAndShow(info)
    end)
    
    yOffset = yOffset - 60
    
    -- EDGE
    local edgeHeader = panel:CreateFontString(nil, "ARTWORK", "GameFontHighlight")
    edgeHeader:SetPoint("TOPLEFT", 16, yOffset)
    edgeHeader:SetText("|cffffd700Swipe & Edge|r")
    yOffset = yOffset - 30

    local edgeCb = CreateFrame("CheckButton", "MCE_EdgeCheckbox", panel, "UICheckButtonTemplate")
    edgeCb:SetPoint("TOPLEFT", 30, yOffset)
    uiElements.edgeCheckbox = edgeCb
    _G[edgeCb:GetName().."Text"]:SetText("Enable Edge Texture")
    edgeCb:SetScript("OnClick", function(self)
        addon.Config:Set("edgeEnabled", self:GetChecked(), currentCategory)
        RefreshVisuals()
    end)
    
    yOffset = yOffset - 40
    
    local scaleSlider = CreateFrame("Slider", "MCE_EdgeScaleSlider", panel, "OptionsSliderTemplate")
    scaleSlider:SetPoint("TOPLEFT", 35, yOffset)
    uiElements.edgeScaleSlider = scaleSlider
    scaleSlider:SetMinMaxValues(0.5, 2.0)
    scaleSlider:SetValueStep(0.1)
    scaleSlider:SetObeyStepOnDrag(true)
    _G[scaleSlider:GetName() .. 'Low']:SetText('0.5')
    _G[scaleSlider:GetName() .. 'High']:SetText('2.0')
    scaleSlider:SetScript("OnValueChanged", function(self, value)
        _G[self:GetName() .. 'Text']:SetText(string.format("%.1f", value))
        addon.Config:Set("edgeScale", value, currentCategory)
        RefreshVisuals()
    end)

    UpdateGUIValues()

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