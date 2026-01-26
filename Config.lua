-- Config.lua - Gestion de configuration Multi-Catégories

local addonName, addon = ...
addon.Config = {}

-- Définition des catégories supportées
-- "auras" a été supprimé, elles utiliseront maintenant "global"
addon.Categories = {
    "actionbar", -- Barres d'action
    "nameplate", -- Barres de vie ennemies
    "unitframe", -- Cadres de joueur/cible/groupe
    "global"     -- TOUT le reste (y compris Auras, Buffs, Debuffs, Sacs, etc.)
}

-- Style par défaut
local defaultStyle = {
    font = "Fonts\\FRIZQT__.TTF",
    fontSize = 18,
    fontStyle = "OUTLINE",
    textColor = { r = 1, g = 0.8, b = 0, a = 1 },
    edgeEnabled = true,
    edgeScale = 1.0,
    hideCountdownNumbers = false,
}

local function CopyTable(src, dest)
    if not dest then dest = {} end
    for k, v in pairs(src) do
        if type(v) == "table" then
            dest[k] = CopyTable(v, dest[k])
        else
            dest[k] = v
        end
    end
    return dest
end

function addon.Config:Initialize()
    if not MinimalistCooldownEdgeDB then
        MinimalistCooldownEdgeDB = {}
    end
    
    for _, cat in ipairs(addon.Categories) do
        if not MinimalistCooldownEdgeDB[cat] then
            MinimalistCooldownEdgeDB[cat] = CopyTable(defaultStyle)
            -- Petite variation par défaut pour aider à la distinction
            if cat == "nameplate" then MinimalistCooldownEdgeDB[cat].fontSize = 12 end
        else
            for k, v in pairs(defaultStyle) do
                if MinimalistCooldownEdgeDB[cat][k] == nil then
                    MinimalistCooldownEdgeDB[cat][k] = v
                end
            end
        end
    end
end

function addon.Config:Get(key, category)
    category = category or "global"
    -- Si la catégorie demandée n'existe pas (ex: ancienne config 'auras'), on force 'global'
    if not MinimalistCooldownEdgeDB[category] then category = "global" end
    
    if MinimalistCooldownEdgeDB and MinimalistCooldownEdgeDB[category] then
        return MinimalistCooldownEdgeDB[category][key]
    end
    return defaultStyle[key]
end

function addon.Config:Set(key, value, category)
    if not MinimalistCooldownEdgeDB then MinimalistCooldownEdgeDB = {} end
    category = category or "global"
    
    if not MinimalistCooldownEdgeDB[category] then
        MinimalistCooldownEdgeDB[category] = CopyTable(defaultStyle)
    end
    
    MinimalistCooldownEdgeDB[category][key] = value
end

function addon.Config:Reset()
    MinimalistCooldownEdgeDB = {}
    self:Initialize()
end