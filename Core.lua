-- Core.lua – Addon skeleton, shared utilities, and database defaults

local addonName, addon = ...
local MCE = LibStub("AceAddon-3.0"):NewAddon(addon, "MinimalistCooldownEdge",
    "AceConsole-3.0")
local L = LibStub("AceLocale-3.0"):GetLocale("MinimalistCooldownEdge")

local pcall = pcall

-- =========================================================================
-- SHARED UTILITIES  (used across all modules)
-- =========================================================================

--- Safe forbidden-frame check (pcall guards tainted frames).
function MCE:IsForbidden(frame)
    if not frame then return true end
    local ok, val = pcall(function() return frame:IsForbidden() end)
    return not ok or val
end

--- WoW API expects "" not "NONE" for font outline flags.
function MCE.NormalizeFontStyle(style)
    return (not style or style == "NONE") and "" or style
end

--- Resolves "GAMEDEFAULT" to WoW's native font path.
function MCE.ResolveFontPath(path)
    return path == "GAMEDEFAULT" and GameFontNormal:GetFont() or path
end

-- =========================================================================
-- DEBUG
-- =========================================================================

MinimalistCooldownEdge_DebugLog = MinimalistCooldownEdge_DebugLog or {}

function MCE:DebugPrint(msg)
    if self.db and self.db.profile and self.db.profile.debugMode then
        self:Print("|cffffaa00[Debug]|r " .. tostring(msg))
    end
end

-- =========================================================================
-- DATABASE DEFAULTS
-- =========================================================================

local function CategoryDefaults(enabled, fontSize)
    return {
        enabled = enabled,
        font = "GAMEDEFAULT", fontSize = fontSize or 18, fontStyle = "OUTLINE",
        textColor = { r = 1, g = 0.8, b = 0, a = 1 },
        textAnchor = "CENTER", textOffsetX = 0, textOffsetY = 0,
        hideCountdownNumbers = false,
        edgeEnabled = true, edgeScale = 1.4,
        stackEnabled = true,
        stackFont = "GAMEDEFAULT", stackSize = 16, stackStyle = "OUTLINE",
        stackColor = { r = 1, g = 1, b = 1, a = 1 },
        stackAnchor = "BOTTOMRIGHT", stackOffsetX = -3, stackOffsetY = 3,
    }
end

MCE.defaults = {
    profile = {
        debugMode = false,
        categories = {
            actionbar = CategoryDefaults(true,  18),
            nameplate = CategoryDefaults(false, 12),
            unitframe = CategoryDefaults(false, 12),
            global    = CategoryDefaults(false, 18),
        },
    },
}

-- =========================================================================
-- ACE LIFECYCLE
-- =========================================================================

function MCE:OnInitialize()
    self.db = LibStub("AceDB-3.0"):New("MinimalistCooldownEdgeDB_v2", self.defaults, true)

    LibStub("AceConfig-3.0"):RegisterOptionsTable(addonName, self.GetOptions)
    self.optionsFrame = LibStub("AceConfigDialog-3.0"):AddToBlizOptions(addonName, addonName)

    self:RegisterChatCommand("mce", "SlashCommand")
    self:RegisterChatCommand("minice", "SlashCommand")
    self:RegisterChatCommand("minimalistcooldownedge", "SlashCommand")
end

function MCE:SlashCommand(input)
    local cmd = input and input:match("^%s*(%S+)")

    if cmd and cmd:lower() == "debug" then
        if not (self.db and self.db.profile) then return end
        self.db.profile.debugMode = not self.db.profile.debugMode
        self:Print(self.db.profile.debugMode and "Debug mode enabled." or "Debug mode disabled.")
        return
    end

    if InCombatLockdown() then
        self:Print(L["Cannot open options in combat."])
        return
    end
    LibStub("AceConfigDialog-3.0"):Open(addonName)
end

--- Public API – delegates to Styler module.
function MCE:ForceUpdateAll(fullScan)
    self:GetModule("Styler"):ForceUpdateAll(fullScan)
end
