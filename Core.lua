-- Core.lua - Main functionality using Ace3

local _, addon = ...
local MCE = LibStub("AceAddon-3.0"):NewAddon(addon, "MinimalistCooldownEdge", "AceConsole-3.0", "AceEvent-3.0", "AceHook-3.0")
local L = LibStub("AceLocale-3.0"):GetLocale("MinimalistCooldownEdge")

-- === UPVALUE LOCALS (Performance) ===
local pairs, ipairs, type, next = pairs, ipairs, type, next
local pcall, setmetatable, wipe = pcall, setmetatable, wipe
local strfind = string.find
local C_Timer_After = C_Timer.After
local InCombatLockdown = InCombatLockdown
local EnumerateFrames = EnumerateFrames
local hooksecurefunc = hooksecurefunc
local UIParent = UIParent
local GetTime = GetTime

-- === DEBUG / LOGGING SYSTEM ===
-- Initialisation de la table globale si elle n'existe pas
MinimalistCooldownEdge_DebugLog = MinimalistCooldownEdge_DebugLog or {}

-- Cache de session pour éviter de spammer le fichier d'écriture à chaque frame (performance)
local sessionLogCache = {}
local IsBlacklistedFrame

function MCE:DebugPrint(message)
    if not (self.db and self.db.profile and self.db.profile.debugMode) then return end
    self:Print("|cffffaa00[Debug]|r " .. tostring(message))
end

function MCE:LogStyleApplication(frame, category, success)
    if not frame then return end
    if not (self.db and self.db.profile and self.db.profile.debugMode) then return end
    if IsBlacklistedFrame(frame) then return end

    -- On crée un identifiant unique pour la frame
    local frameName = frame:GetName() or "AnonymousFrame"
    local parent = frame:GetParent()
    local parentName = parent and parent:GetName() or "NoParent"
    
    -- Clé unique : Parent -> Frame
    local key = parentName .. " -> " .. frameName
    
    -- Si on a déjà logué cette frame dans cette session, on ignore (pour ne pas tuer les FPS)
    if sessionLogCache[key] then return end
    sessionLogCache[key] = true

    -- Enregistrement dans la variable sauvegardée
    MinimalistCooldownEdge_DebugLog[key] = {
        frameName = frameName,
        parentName = parentName,
        category = category,
        objType = frame:GetObjectType(),
        timestamp = date("%Y-%m-%d %H:%M:%S"),
        success = success, -- Est-ce que le style a été appliqué ou bloqué ?
        scanDepth = MCE.db and MCE.db.profile and MCE.db.profile.scanDepth or nil -- Pour voir si la profondeur influe
    }
end

-- === BLACKLIST (Centralized frame matcher) ===
-- Add your ignore cases here.
local BLACKLIST_NAME_CONTAINS = {
    "Glider", "Party", "Compact",
    "Raid", "VuhDo", "Grid",
    "LossOfControlFrame",
    "ContainerFrameCombinedBagsCooldown",
}

-- Exact relation keys: "ParentName -> FrameName"
local BLACKLIST_EXACT_PAIRS = {
    -- Character Slots
    ["CharacterBackSlot -> CharacterBackSlotCooldown"] = true,
    ["CharacterShirtSlot -> CharacterShirtSlotCooldown"] = true,
    ["CharacterMainHandSlot -> CharacterMainHandSlotCooldown"] = true,
    ["CharacterLegsSlot -> CharacterLegsSlotCooldown"] = true,
    ["CharacterFinger0Slot -> CharacterFinger0SlotCooldown"] = true,
    ["CharacterHeadSlot -> CharacterHeadSlotCooldown"] = true,
    ["CharacterFeetSlot -> CharacterFeetSlotCooldown"] = true,
    ["CharacterShoulderSlot -> CharacterShoulderSlotCooldown"] = true,
    ["CharacterWristSlot -> CharacterWristSlotCooldown"] = true,
    ["CharacterHandsSlot -> CharacterHandsSlotCooldown"] = true,
    ["CharacterTabardSlot -> CharacterTabardSlotCooldown"] = true,
    ["CharacterSecondaryHandSlot -> CharacterSecondaryHandSlotCooldown"] = true,
    ["CharacterFinger1Slot -> CharacterFinger1SlotCooldown"] = true,
    ["CharacterWaistSlot -> CharacterWaistSlotCooldown"] = true,
    ["CharacterChestSlot -> CharacterChestSlotCooldown"] = true,
    ["CharacterNeckSlot -> CharacterNeckSlotCooldown"] = true,
    ["CharacterTrinket1Slot -> CharacterTrinket1SlotCooldown"] = true,
    ["CharacterTrinket0Slot -> CharacterTrinket0SlotCooldown"] = true,
}

-- === CACHES (Weak-keyed to auto-collect garbage) ===
local categoryCache     = setmetatable({}, { __mode = "k" })
local trackedCooldowns  = setmetatable({}, { __mode = "k" })
local styledCategory    = setmetatable({}, { __mode = "k" })

-- Anti-flicker: track last-applied API values per frame to skip redundant calls
local lastAppliedEdge      = setmetatable({}, { __mode = "k" })
local lastAppliedEdgeScale = setmetatable({}, { __mode = "k" })
local lastAppliedHideNums  = setmetatable({}, { __mode = "k" })

-- Batched style queue: coalesces rapid hook fires within the same frame
-- into a single style-application pass, eliminating visual flickering.
local dirtyFrames = {}
local dirtyCount = 0
local batchTimerScheduled = false

local hooksInstalled = false

-- === SAFE FORBIDDEN CHECK ===
-- Must use a closure inside pcall because indexing a "secret table"
-- (tainted frame) itself throws; we can't pre-resolve frame.IsForbidden.
local function IsForbiddenFrame(frame)
    if not frame then return true end
    local ok, forbidden = pcall(function() return frame:IsForbidden() end)
    return not ok or forbidden
end

IsBlacklistedFrame = function(frame, knownFrameName)
    if not frame then return false end

    local frameName = knownFrameName or (frame.GetName and frame:GetName()) or "AnonymousFrame"
    local parent = frame.GetParent and frame:GetParent() or nil
    local parentName = parent and parent.GetName and parent:GetName() or "NoParent"

    if BLACKLIST_EXACT_PAIRS[parentName .. " -> " .. frameName] then
        return true
    end

    for _, key in ipairs(BLACKLIST_NAME_CONTAINS) do
        if strfind(frameName, key, 1, true) or strfind(parentName, key, 1, true) then
            return true
        end
    end

    return false
end

local function IsNameplateContext(name, objType, unit)
    return objType == "NamePlate"
        or strfind(name, "NamePlate", 1, true)
        or strfind(name, "Plater", 1, true)
        or strfind(name, "Kui", 1, true)
        or (unit and strfind(unit, "nameplate", 1, true))
end

-- === FONT STYLE NORMALIZER ===
-- WoW API expects "" not "NONE"; centralise the conversion.
local function NormalizeFontStyle(style)
    if not style or style == "NONE" then return "" end
    return style
end

-- === FONT RESOLVER ===
-- Resolves font paths; handles "GAMEDEFAULT" by using WoW's native font.
local function ResolveFontPath(fontPath)
    if fontPath == "GAMEDEFAULT" then
        return GameFontNormal:GetFont()
    end
    return fontPath
end

-- === BATCHED STYLE PROCESSOR ===
-- Coalesces multiple hook fires within the same frame into a single
-- style-application pass, preventing visual flickering caused by
-- rapid sequential SetDrawEdge / SetFont / SetHideCountdownNumbers calls.
local function ProcessDirtyFrames()
    batchTimerScheduled = false
    if dirtyCount == 0 then return end

    for frame, forcedCategory in pairs(dirtyFrames) do
        if frame and not IsForbiddenFrame(frame) then
            MCE:ApplyStyle(frame, forcedCategory ~= true and forcedCategory or nil)
        end
    end

    wipe(dirtyFrames)
    dirtyCount = 0
end

local function QueueStyleUpdate(frame, forcedCategory)
    if not frame or IsForbiddenFrame(frame) then return end
    if IsBlacklistedFrame(frame) then return end

    lastAppliedEdge[frame] = nil
    lastAppliedEdgeScale[frame] = nil
    lastAppliedHideNums[frame] = nil

    if categoryCache[frame] then
        MCE:ApplyStyle(frame, forcedCategory)
        return
    end

    -- Unknown frames: defer to batch processor for classification.
    -- No existing style to flicker since they haven't been styled yet.
    if not dirtyFrames[frame] then
        dirtyCount = dirtyCount + 1
    end
    dirtyFrames[frame] = forcedCategory or true

    if not batchTimerScheduled then
        batchTimerScheduled = true
        C_Timer_After(0, ProcessDirtyFrames)
    end
end

-- === ACE ADDON LIFECYCLE ===
function MCE:OnInitialize()
    self.db = LibStub("AceDB-3.0"):New("MinimalistCooldownEdgeDB_v2", self.defaults, true)

    LibStub("AceConfig-3.0"):RegisterOptionsTable("MinimalistCooldownEdge", self.GetOptions)
    self.optionsFrame = LibStub("AceConfigDialog-3.0"):AddToBlizOptions("MinimalistCooldownEdge", "MinimalistCooldownEdge")

    self:RegisterChatCommand("mce", "SlashCommand")
    self:RegisterChatCommand("minice", "SlashCommand")
    self:RegisterChatCommand("minimalistcooldownedge", "SlashCommand")

    self:DebugPrint("Addon initialized.")
end

function MCE:OnEnable()
    self:SetupHooks()
    self:RegisterEvent("PLAYER_ENTERING_WORLD")
    self:DebugPrint("Addon enabled.")

    if C_NamePlate and C_NamePlate.GetNamePlateForUnit then
        self:RegisterEvent("NAME_PLATE_UNIT_ADDED")
        self:RegisterEvent("PLAYER_REGEN_DISABLED")
        self:RegisterEvent("PLAYER_REGEN_ENABLED")

        if InCombatLockdown() then
            self:PLAYER_REGEN_DISABLED()
        end
    end

    C_Timer_After(2, function()
        self:DebugPrint("Initial full scan scheduled on enable.")
        self:ForceUpdateAll(true)
    end)
end

function MCE:OnDisable()
    if self.nameplateTicker then
        self.nameplateTicker:Cancel()
        self.nameplateTicker = nil
    end

    self:UnregisterEvent("NAME_PLATE_UNIT_ADDED")
    self:UnregisterEvent("PLAYER_REGEN_DISABLED")
    self:UnregisterEvent("PLAYER_REGEN_ENABLED")
    self:UnregisterEvent("PLAYER_ENTERING_WORLD")
    self:DebugPrint("Addon disabled.")
end

function MCE:SlashCommand(input)
    local cmd = input and input:match("^%s*(%S+)")
    if cmd and cmd:lower() == "debug" then
        if not (self.db and self.db.profile) then return end

        self.db.profile.debugMode = not self.db.profile.debugMode

        if self.db.profile.debugMode then
            self:Print("Debug mode enabled.")
            self:DebugPrint("Debug logging active.")
        else
            self:Print("Debug mode disabled.")
        end
        return
    end

    if InCombatLockdown() then
        self:Print(L["Cannot open options in combat."])
        return
    end
    LibStub("AceConfigDialog-3.0"):Open("MinimalistCooldownEdge")
end

function MCE:PLAYER_ENTERING_WORLD(_, isInitialLogin, isReloadingUi)
    if isInitialLogin then
        self:DebugPrint("PLAYER_ENTERING_WORLD (initial login).")
    elseif isReloadingUi then
        self:DebugPrint("PLAYER_ENTERING_WORLD (UI reload).")
    else
        self:DebugPrint("PLAYER_ENTERING_WORLD (zone/world transition).")
    end
end

-- === DETECTION LOGIC ===
-- Single-pass frame classifier. Builds the ancestry chain once, then
-- classifies by scanning through it in priority order.
-- Replaces the old dual-walk approach (IsNameplateChain + GetCooldownCategory)
-- which walked the hierarchy twice and caused redundant work.
function MCE:ClassifyFrame(cooldownFrame)
    local current = cooldownFrame:GetParent()
    if not current then return "global" end

    local maxDepth = (self.db and self.db.profile and self.db.profile.scanDepth) or 10
    local extendedLimit = maxDepth + 30

    -- Phase 1: Build ancestry chain once (single allocation, reused for all checks)
    local chain = {}
    local chainLen = 0
    local node = current
    while node and node ~= UIParent and chainLen < extendedLimit do
        chainLen = chainLen + 1
        chain[chainLen] = node
        node = node:GetParent()
    end
    local reachedUIParent = (node == UIParent)

    -- Phase 2: Fast early-out for aura buttons (buff/debuff on player frame vs nameplate)
    local parentName = current:GetName() or ""
    if strfind(parentName, "BuffButton", 1, true)
    or strfind(parentName, "DebuffButton", 1, true)
    or strfind(parentName, "TempEnchant", 1, true) then
        -- Walk the pre-built chain looking for nameplate ancestors
        for i = 1, chainLen do
            local n = chain[i]
            local name = n:GetName() or ""
            if IsNameplateContext(name, n:GetObjectType(), n.unit) then
                return "nameplate"
            end
        end
        -- Reached UIParent → definitively a player buff/debuff
        if reachedUIParent then return "global" end
        -- Chain still building (hierarchy incomplete) → defer
        return "aura_pending"
    end

    -- Phase 3: General classification within configured scan depth
    local limit = chainLen < maxDepth and chainLen or maxDepth
    for i = 1, limit do
        local frame = chain[i]
        local name = frame:GetName() or ""
        local objType = frame:GetObjectType()

        -- Blacklist check (exact pair + name-contains patterns)
        if IsBlacklistedFrame(frame, name) then return "blacklist" end

        -- Nameplate detection
        if IsNameplateContext(name, objType, frame.unit) then return "nameplate" end

        -- Unit frame detection
        if strfind(name, "PlayerFrame", 1, true)
        or strfind(name, "TargetFrame", 1, true)
        or strfind(name, "FocusFrame", 1, true)
        or strfind(name, "ElvUF", 1, true)
        or strfind(name, "SUF", 1, true) then
            return "unitframe"
        end

        -- Action bar detection (skip "Aura" false positives)
        if (frame.action and type(frame.action) == "number")
        or (frame.GetAttribute and frame:GetAttribute("type"))
        or strfind(name, "Action", 1, true)
        or strfind(name, "MultiBar", 1, true)
        or strfind(name, "BT4", 1, true)
        or strfind(name, "Dominos", 1, true) then
            if not strfind(name, "Aura", 1, true) then
                return "actionbar"
            end
        end
    end

    -- Phase 4: Extended nameplate check beyond configured depth
    -- Nameplates can be deeply nested in addon UIs (Plater, KuiNameplates, etc.)
    for i = limit + 1, chainLen do
        local frame = chain[i]
        local name = frame:GetName() or ""
        if IsNameplateContext(name, frame:GetObjectType(), frame.unit) then
            return "nameplate"
        end
    end

    return "global"
end

function MCE:GetCooldownCategory(cooldownFrame)
    local cached = categoryCache[cooldownFrame]
    if cached then return cached end

    local category = self:ClassifyFrame(cooldownFrame)

    -- Cache definitive results; "aura_pending" is retried in ApplyStyle
    if category ~= "aura_pending" then
        categoryCache[cooldownFrame] = category
    end

    return category
end

-- === STACK COUNT STYLING ===
function MCE:StyleStackCount(cooldownFrame, config, category)
    if category ~= "actionbar" or not config.stackEnabled then return end

    local parent = cooldownFrame:GetParent()
    if not parent then return end

    local parentName  = parent.GetName and parent:GetName()
    local countRegion = parent.Count or (parentName and _G[parentName .. "Count"])

    if not countRegion or not countRegion.GetObjectType then return end
    if countRegion:GetObjectType() ~= "FontString" then return end
    if IsForbiddenFrame(countRegion) then return end

    local resolvedStackFont = ResolveFontPath(config.stackFont)
    countRegion:SetFont(resolvedStackFont, config.stackSize, NormalizeFontStyle(config.stackStyle))
    local sc = config.stackColor
    countRegion:SetTextColor(sc.r, sc.g, sc.b, sc.a)
    countRegion:ClearAllPoints()
    countRegion:SetPoint(config.stackAnchor, parent, config.stackAnchor, config.stackOffsetX, config.stackOffsetY)
    if countRegion.GetDrawLayer then
        countRegion:SetDrawLayer("OVERLAY", 7)
    end
end

-- === STYLE APPLICATION ===
-- Main entry point called from the batch processor (ProcessDirtyFrames).
-- Uses change-detection on edge/countdown APIs to prevent visual flicker:
-- SetDrawEdge, SetEdgeScale, SetHideCountdownNumbers are only called when
-- their value actually differs from the last-applied value.
function MCE:ApplyStyle(cdFrame, forcedCategory)
    if IsForbiddenFrame(cdFrame) then return end
    if IsBlacklistedFrame(cdFrame) then return end

    trackedCooldowns[cdFrame] = true

    -- Override cached category when a specific one is forced (e.g., "actionbar" from hooks)
    if forcedCategory and forcedCategory ~= "global" then
        if categoryCache[cdFrame] ~= forcedCategory then
            categoryCache[cdFrame] = forcedCategory
            styledCategory[cdFrame] = nil
        end
    end

    -- Guard: DB must be ready
    if not self.db or not self.db.profile or not self.db.profile.categories then return end

    local category = forcedCategory or self:GetCooldownCategory(cdFrame)

    -- Handle deferred aura classification (single retry, then fallback to global)
    if category == "aura_pending" then
        categoryCache[cdFrame] = nil
        C_Timer_After(0.1, function()
            if cdFrame and not IsForbiddenFrame(cdFrame) then
                local retryCategory = self:ClassifyFrame(cdFrame)
                if retryCategory == "aura_pending" then
                    retryCategory = "global"
                end
                categoryCache[cdFrame] = retryCategory
                self:ApplyStyle(cdFrame)
            end
        end)
        return
    end

    if category == "blacklist" then
        self:LogStyleApplication(cdFrame, "blacklist", false)
        return
    end

    local config = self.db.profile.categories[category]
    if not config or not config.enabled then
        -- Disabled category: clear edge only if we previously set it (anti-flicker)
        if lastAppliedEdge[cdFrame] ~= false then
            if cdFrame.SetDrawEdge then
                pcall(cdFrame.SetDrawEdge, cdFrame, false)
            end
            lastAppliedEdge[cdFrame] = false
        end
        self:LogStyleApplication(cdFrame, category .. " (Disabled)", false)
        return
    end

    self:LogStyleApplication(cdFrame, category, true)

    -- === Edge glow — only call API when value actually changed ===
    if cdFrame.SetDrawEdge then
        if lastAppliedEdge[cdFrame] ~= config.edgeEnabled then
            pcall(cdFrame.SetDrawEdge, cdFrame, config.edgeEnabled)
            lastAppliedEdge[cdFrame] = config.edgeEnabled
        end
        if config.edgeEnabled and cdFrame.SetEdgeScale then
            if lastAppliedEdgeScale[cdFrame] ~= config.edgeScale then
                pcall(cdFrame.SetEdgeScale, cdFrame, config.edgeScale)
                lastAppliedEdgeScale[cdFrame] = config.edgeScale
            end
        end
    end

    -- === Hide/show countdown numbers — only call API when value changed ===
    if cdFrame.SetHideCountdownNumbers then
        if lastAppliedHideNums[cdFrame] ~= config.hideCountdownNumbers then
            pcall(cdFrame.SetHideCountdownNumbers, cdFrame, config.hideCountdownNumbers)
            lastAppliedHideNums[cdFrame] = config.hideCountdownNumbers
        end
    end

    -- Skip full font re-style if category hasn't changed (prevents text flashing)
    if styledCategory[cdFrame] == category then
        return
    end
    styledCategory[cdFrame] = category

    -- Stack counts (action bar only)
    self:StyleStackCount(cdFrame, config, category)

    -- Font string styling & positioning
    if not cdFrame.GetRegions then return end

    local numRegions = cdFrame.GetNumRegions and cdFrame:GetNumRegions() or 0
    if numRegions == 0 then return end

    local fontStyle = NormalizeFontStyle(config.fontStyle)
    local resolvedFont = ResolveFontPath(config.font)
    local regions   = { cdFrame:GetRegions() }
    for i = 1, numRegions do
        local region = regions[i]
        if region:GetObjectType() == "FontString" and not IsForbiddenFrame(region) then
            region:SetFont(resolvedFont, config.fontSize, fontStyle)
            if config.textColor then
                local tc = config.textColor
                region:SetTextColor(tc.r, tc.g, tc.b, tc.a)
            end
            if config.textAnchor then
                region:ClearAllPoints()
                region:SetPoint(config.textAnchor, cdFrame, config.textAnchor, config.textOffsetX, config.textOffsetY)
            end
        end
    end
end

-- === FORCE UPDATE ===
function MCE:ForceUpdateAll(fullScan)
    self:DebugPrint("ForceUpdateAll called (fullScan=" .. tostring(fullScan) .. ").")

    -- Clear all caches so everything gets a fresh pass
    wipe(categoryCache)
    wipe(styledCategory)
    wipe(lastAppliedEdge)
    wipe(lastAppliedEdgeScale)
    wipe(lastAppliedHideNums)

    if fullScan or not self.fullScanDone then
        self.fullScanDone = true
        local frame = EnumerateFrames()
        while frame do
            if not IsForbiddenFrame(frame) then
                if frame:IsObjectType("Cooldown") then
                    QueueStyleUpdate(frame)
                elseif frame.cooldown and type(frame.cooldown) == "table" then
                    if not IsForbiddenFrame(frame.cooldown) then
                        QueueStyleUpdate(frame.cooldown)
                    end
                end
            end
            frame = EnumerateFrames(frame)
        end
        return
    end

    -- Incremental: only update previously tracked cooldowns
    for cd in pairs(trackedCooldowns) do
        if cd and cd.IsObjectType and cd:IsObjectType("Cooldown") then
            QueueStyleUpdate(cd)
        end
    end
end

-- === NAMEPLATE EVENTS ===
function MCE:NAME_PLATE_UNIT_ADDED(_, unit)
    local plate = C_NamePlate and C_NamePlate.GetNamePlateForUnit(unit)
    if plate then
        -- Single deferred call (batch processor coalesces any rapid follow-ups)
        C_Timer_After(0.05, function()
            if plate and not IsForbiddenFrame(plate) then
                self:StyleCooldownsInFrame(plate, "nameplate", 10)
            end
        end)
    end
end

function MCE:RefreshVisibleNameplates()
    if not (C_NamePlate and C_NamePlate.GetNamePlates) then return end

    for _, plate in ipairs(C_NamePlate.GetNamePlates() or {}) do
        if plate and not IsForbiddenFrame(plate) then
            self:StyleCooldownsInFrame(plate, "nameplate", 10)
        end
    end
end

function MCE:PLAYER_REGEN_DISABLED()
    if self.nameplateTicker then return end

    -- Slightly longer interval to reduce combat CPU overhead
    self.nameplateTicker = C_Timer.NewTicker(0.5, function()
        self:RefreshVisibleNameplates()
    end)
end

function MCE:PLAYER_REGEN_ENABLED()
    if self.nameplateTicker then
        self.nameplateTicker:Cancel()
        self.nameplateTicker = nil
    end
end

-- === HOOKS ===
-- All hooks now queue frames into the batch processor instead of
-- applying styles directly. This eliminates flickering caused by
-- rapid sequential hook fires (e.g., GCD triggers CooldownFrame_Set
-- multiple times per frame).
function MCE:SetupHooks()
    if hooksInstalled then return end
    hooksInstalled = true

    -- Primary hook: fires on every cooldown start/reset
    hooksecurefunc("CooldownFrame_Set", function(f)
        if not f or IsForbiddenFrame(f) then return end
        QueueStyleUpdate(f)
    end)

    -- Action button specific hook (provides forced "actionbar" category)
    if ActionButton_UpdateCooldown then
        hooksecurefunc("ActionButton_UpdateCooldown", function(button)
            local cd = button and (button.cooldown or button.Cooldown)
            if cd then
                QueueStyleUpdate(cd, "actionbar")
            end
        end)
    end

    -- LibActionButton support (Bartender4, etc.)
    local LAB = LibStub("LibActionButton-1.0", true)
    if LAB then
        LAB:RegisterCallback("OnButtonUpdate", function(_, button)
            if button and button.cooldown then
                QueueStyleUpdate(button.cooldown, "actionbar")
            end
        end)
    end
end

-- === SCOPED SCANNING ===
-- Recursively scans a frame tree and queues all Cooldown frames found
-- for batch style processing. Used primarily for nameplate scanning.
function MCE:StyleCooldownsInFrame(rootFrame, forcedCategory, maxDepth)
    if not rootFrame then return end
    maxDepth = maxDepth or 5

    local function scan(frame, depth)
        if not frame or depth > maxDepth then return end
        if IsForbiddenFrame(frame) then return end

        if frame.IsObjectType and frame:IsObjectType("Cooldown") then
            QueueStyleUpdate(frame, forcedCategory)
        elseif frame.cooldown and type(frame.cooldown) == "table" then
            if not IsForbiddenFrame(frame.cooldown) then
                QueueStyleUpdate(frame.cooldown, forcedCategory)
            end
        end

        local childCount = frame.GetNumChildren and frame:GetNumChildren() or 0
        if childCount > 0 and frame.GetChildren then
            local children = { frame:GetChildren() }
            for i = 1, childCount do
                scan(children[i], depth + 1)
            end
        end
    end

    scan(rootFrame, 0)
end