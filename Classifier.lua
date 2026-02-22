-- Classifier.lua – Frame classification & blacklist (AceModule)
--
-- Determines which category (actionbar / nameplate / unitframe / global)
-- a Cooldown frame belongs to, so the Styler can apply the right config.

local MCE = LibStub("AceAddon-3.0"):GetAddon("MinimalistCooldownEdge")
local Classifier = MCE:NewModule("Classifier")

local strfind, ipairs, type = string.find, ipairs, type
local setmetatable, wipe = setmetatable, wipe
local UIParent = UIParent

local SCAN_DEPTH = 10

-- Weak-keyed cache: auto-collected when frames are garbage-collected
local categoryCache = setmetatable({}, { __mode = "k" })

-- =========================================================================
-- BLACKLIST DATA
-- =========================================================================

local BLACKLIST_NAMES = {
    "Glider", "Party", "Compact", "Raid", "VuhDo", "Grid",
    "LossOfControlFrame", "ContainerFrameCombinedBagsCooldown",
}

-- Character equipment slots – generated to avoid 18 manual entries
local BLACKLIST_PAIRS = {}
for _, slot in ipairs({
    "Back", "Shirt", "MainHand", "Legs", "Finger0", "Head", "Feet",
    "Shoulder", "Wrist", "Hands", "Tabard", "SecondaryHand",
    "Finger1", "Waist", "Chest", "Neck", "Trinket1", "Trinket0",
}) do
    local base = "Character" .. slot .. "Slot"
    BLACKLIST_PAIRS[base .. " -> " .. base .. "Cooldown"] = true
end

-- =========================================================================
-- PATTERN HELPERS
-- =========================================================================

local function IsNameplateContext(name, objType, unit)
    return objType == "NamePlate"
        or strfind(name, "NamePlate", 1, true)
        or strfind(name, "Plater",    1, true)
        or strfind(name, "Kui",       1, true)
        or (unit and strfind(unit, "nameplate", 1, true))
end

--- Détection rapide des frames générées par MiniCC (incluant le mode Test)
--- MiniCC injects DesiredIconSize/FontScale on anonymous nameplate cooldowns.
local function IsMiniCCFrame(frame)
    if not frame then return false end
    
    -- 1. Duck-typing : Empreinte digitale unique de MiniCC
    if frame.DesiredIconSize and frame.FontScale then
        -- 2. Vérification de la hiérarchie interne de MiniCC (Layer -> Slot -> Container)
        -- Les frames de MiniCC sont anonymes, GetName() doit retourner nil
        local layer = frame:GetParent()
        if layer and not layer:GetName() then
            local slot = layer:GetParent()
            if slot and not slot:GetName() then
                local container = slot:GetParent()
                if container and not container:GetName() then
                    return true
                end
            end
        end
    end
    return false
end

-- =========================================================================
-- PUBLIC API
-- =========================================================================

function Classifier:IsBlacklisted(frame, knownName)
    if not frame then return false end
    if IsMiniCCFrame(frame) then return true end

    local name   = knownName or (frame.GetName and frame:GetName()) or "AnonymousFrame"
    local parent = frame.GetParent and frame:GetParent()
    local pName  = parent and parent.GetName and parent:GetName() or "NoParent"

    if BLACKLIST_PAIRS[pName .. " -> " .. name] then return true end

    for _, key in ipairs(BLACKLIST_NAMES) do
        if strfind(name, key, 1, true) or strfind(pName, key, 1, true) then
            return true
        end
    end
    return false
end

--- Single-pass frame classifier. Builds the ancestry chain once, then
--- classifies by priority: blacklist > nameplate > unitframe > actionbar > global.
function Classifier:ClassifyFrame(cdFrame)
    local current = cdFrame:GetParent()
    if not current then return "global" end

    -- Build ancestry chain once
    local chain, chainLen = {}, 0
    local node = current
    while node and node ~= UIParent and chainLen < SCAN_DEPTH + 30 do
        chainLen = chainLen + 1
        chain[chainLen] = node
        node = node:GetParent()
    end
    local reachedUI = (node == UIParent)

    -- Fast early-out: aura buttons (buff/debuff on player frame vs nameplate)
    local pName = current:GetName() or ""
    if strfind(pName, "BuffButton",  1, true)
    or strfind(pName, "DebuffButton", 1, true)
    or strfind(pName, "TempEnchant",  1, true) then
        for i = 1, chainLen do
            local n = chain[i]
            if IsNameplateContext(n:GetName() or "", n:GetObjectType(), n.unit) then
                return "nameplate"
            end
        end
        return reachedUI and "global" or "aura_pending"
    end

    -- General classification within configured depth
    local limit = chainLen < SCAN_DEPTH and chainLen or SCAN_DEPTH
    for i = 1, limit do
        local f    = chain[i]
        local name = f:GetName() or ""
        local ot   = f:GetObjectType()

        if self:IsBlacklisted(f, name) then return "blacklist" end
        if IsNameplateContext(name, ot, f.unit) then return "nameplate" end

        if strfind(name, "PlayerFrame", 1, true)
        or strfind(name, "TargetFrame", 1, true)
        or strfind(name, "FocusFrame",  1, true)
        or strfind(name, "ElvUF",       1, true)
        or strfind(name, "SUF",         1, true) then
            return "unitframe"
        end

        if ((f.action and type(f.action) == "number")
         or (f.GetAttribute and f:GetAttribute("type"))
         or strfind(name, "Action",  1, true)
         or strfind(name, "MultiBar", 1, true)
         or strfind(name, "BT4",     1, true)
         or strfind(name, "Dominos", 1, true))
        and not strfind(name, "Aura", 1, true) then
            return "actionbar"
        end
    end

    -- Extended nameplate check (deeply-nested addon UIs: Plater, Kui, etc.)
    for i = limit + 1, chainLen do
        local f = chain[i]
        if IsNameplateContext(f:GetName() or "", f:GetObjectType(), f.unit) then
            return "nameplate"
        end
    end

    return "global"
end

function Classifier:GetCategory(frame)
    local cached = categoryCache[frame]
    if cached then return cached end

    local cat = self:ClassifyFrame(frame)
    if cat ~= "aura_pending" then
        categoryCache[frame] = cat
    end
    return cat
end

function Classifier:IsCached(frame)
    return categoryCache[frame] ~= nil
end

function Classifier:SetCategory(frame, cat)
    categoryCache[frame] = cat
end

function Classifier:WipeCache()
    wipe(categoryCache)
end
