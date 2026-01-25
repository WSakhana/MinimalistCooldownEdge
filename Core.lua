-- VISUAL CONFIGURATION
local MY_FONT = "Fonts\\FRIZQT__.ttf" -- Path to your font (ex: FRIZQT__, ARIALN, MORPHEUS)
local FONT_SIZE = 18                  -- Font size
local FONT_STYLE = "OUTLINE"          -- Style (OUTLINE, THICKOUTLINE, or nil)
local TEXT_COLOR = {1, 0.8, 0, 1}     -- Text color (Red, Green, Blue, Alpha) - Here: Golden

local function ApplyCustomStyle(self)
    if not self then return end

    -- 1. Swipe and Edge style
    self:SetDrawEdge(true)
    self:SetEdgeScale(1.2)
    self:SetSwipeColor(0, 0, 0, 0.8)
    
    -- 2. Cooldown Timer Text Style
    -- In 12.0, text is often accessed via GetRegions or internal objects
    local text = self:GetRegions() 
    if text and text:IsObjectType("FontString") then
        text:SetFont(MY_FONT, FONT_SIZE, FONT_STYLE)
        text:SetTextColor(unpack(TEXT_COLOR))
    end
end

-- Apply style as soon as cooldown is updated
hooksecurefunc("ActionButton_UpdateCooldown", function(self)
    if self.cooldown then
        -- Enable native Blizzard text if not already done
        self.cooldown:SetHideCountdownNumbers(false) 
        ApplyCustomStyle(self.cooldown)
    end
end)

print("|cff00ff00MinimalistCooldownEdge:|r Style and Font applied.")