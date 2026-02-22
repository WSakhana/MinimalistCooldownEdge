-- Styler.lua – Style application, hooks, batch processing & nameplates (AceModule)
--
-- Uses AceHook for auto-unhook on disable and AceEvent for clean event lifecycle.

local MCE        = LibStub("AceAddon-3.0"):GetAddon("MinimalistCooldownEdge")
local Styler     = MCE:NewModule("Styler", "AceEvent-3.0", "AceHook-3.0")
local Classifier = MCE:GetModule("Classifier")

local pairs, ipairs, type, pcall, wipe = pairs, ipairs, type, pcall, wipe
local setmetatable = setmetatable
local C_Timer_After = C_Timer.After
local InCombatLockdown = InCombatLockdown
local EnumerateFrames  = EnumerateFrames

-- Session debug-log dedup (prevents FPS drain from repeated writes)
local logCache = {}

-- =========================================================================
-- CACHES  (weak-keyed → auto-collected with their frames)
-- =========================================================================

local trackedCooldowns = setmetatable({}, { __mode = "k" })
local styledCategory   = setmetatable({}, { __mode = "k" })

-- Anti-flicker: skip redundant API calls
local lastEdge  = setmetatable({}, { __mode = "k" })
local lastScale = setmetatable({}, { __mode = "k" })
local lastHide  = setmetatable({}, { __mode = "k" })

-- =========================================================================
-- BATCH PROCESSOR  (coalesces rapid hook fires into a single pass)
-- =========================================================================

local dirty, dirtyN, scheduled = {}, 0, false

local function Flush()
    scheduled = false
    if dirtyN == 0 then return end

    for frame, cat in pairs(dirty) do
        if frame and not MCE:IsForbidden(frame) then
            Styler:ApplyStyle(frame, cat ~= true and cat or nil)
        end
    end
    wipe(dirty)
    dirtyN = 0
end

function Styler:QueueUpdate(frame, forced)
    if not frame or MCE:IsForbidden(frame) then return end
    if Classifier:IsBlacklisted(frame) then return end

    -- Invalidate anti-flicker caches for this frame
    lastEdge[frame], lastScale[frame], lastHide[frame] = nil, nil, nil

    -- Already-classified frames: apply immediately (no flicker risk)
    if Classifier:IsCached(frame) then
        self:ApplyStyle(frame, forced)
        return
    end

    -- Unknown frames: defer to batch (first style → no existing visual to flicker)
    if not dirty[frame] then dirtyN = dirtyN + 1 end
    dirty[frame] = forced or true

    if not scheduled then
        scheduled = true
        C_Timer_After(0, Flush)
    end
end

-- =========================================================================
-- LIFECYCLE
-- =========================================================================

function Styler:OnEnable()
    self:SetupHooks()

    if C_NamePlate and C_NamePlate.GetNamePlateForUnit then
        self:RegisterEvent("NAME_PLATE_UNIT_ADDED")
        self:RegisterEvent("PLAYER_REGEN_DISABLED")
        self:RegisterEvent("PLAYER_REGEN_ENABLED")
        if InCombatLockdown() then self:PLAYER_REGEN_DISABLED() end
    end

    C_Timer_After(2, function() self:ForceUpdateAll(true) end)
    MCE:DebugPrint("Styler enabled.")
end

function Styler:OnDisable()
    if self.npTicker then
        self.npTicker:Cancel()
        self.npTicker = nil
    end
    -- AceEvent auto-unregisters events; AceHook auto-unhooks.
end

-- =========================================================================
-- INTERNAL HELPERS
-- =========================================================================

--- Debug log – deduplicated per session, writes to SavedVariables
local function LogStyle(frame, cat, ok)
    if not (MCE.db and MCE.db.profile and MCE.db.profile.debugMode) then return end
    if Classifier:IsBlacklisted(frame) then return end

    local name = frame:GetName() or "AnonymousFrame"
    local p    = frame:GetParent()
    local pn   = p and p:GetName() or "NoParent"
    local key  = pn .. " -> " .. name

    if logCache[key] then return end
    logCache[key] = true

    MinimalistCooldownEdge_DebugLog[key] = {
        frameName = name, parentName = pn, category = cat,
        objType = frame:GetObjectType(),
        timestamp = date("%Y-%m-%d %H:%M:%S"), success = ok,
    }
end

--- Charge-based abilities: prevent overlapping countdown numbers
--- between button.cooldown (main) and button.chargeCooldown.
local function HasActiveCharge(cd)
    local parent = cd:GetParent()
    if not parent then return false end
    if (parent.cooldown or parent.Cooldown) ~= cd then return false end
    local cc = parent.chargeCooldown or parent.ChargeCooldown
    return cc and cc ~= cd and not MCE:IsForbidden(cc)
        and cc.IsShown and cc:IsShown()
end

-- =========================================================================
-- STACK COUNT STYLING  (action bar only)
-- =========================================================================

function Styler:StyleStack(cd, cfg)
    if not cfg.stackEnabled then return end

    local parent = cd:GetParent()
    if not parent then return end

    local pn    = parent.GetName and parent:GetName()
    local count = parent.Count or (pn and _G[pn .. "Count"])

    if not count or not count.GetObjectType
    or count:GetObjectType() ~= "FontString"
    or MCE:IsForbidden(count) then return end

    count:SetFont(
        MCE.ResolveFontPath(cfg.stackFont),
        cfg.stackSize,
        MCE.NormalizeFontStyle(cfg.stackStyle))

    local sc = cfg.stackColor
    count:SetTextColor(sc.r, sc.g, sc.b, sc.a)
    count:ClearAllPoints()
    count:SetPoint(cfg.stackAnchor, parent, cfg.stackAnchor,
        cfg.stackOffsetX, cfg.stackOffsetY)

    if count.GetDrawLayer then count:SetDrawLayer("OVERLAY", 7) end
end

-- =========================================================================
-- STYLE APPLICATION
-- =========================================================================

function Styler:ApplyStyle(cd, forced)
    if MCE:IsForbidden(cd) or Classifier:IsBlacklisted(cd) then return end

    trackedCooldowns[cd] = true

    -- Override cached category when forced (e.g. "actionbar" from hooks)
    if forced and forced ~= "global" then
        Classifier:SetCategory(cd, forced)
        styledCategory[cd] = nil
    end

    if not (MCE.db and MCE.db.profile and MCE.db.profile.categories) then return end

    local cat = forced or Classifier:GetCategory(cd)

    -- Deferred aura classification (single retry, then fallback to global)
    if cat == "aura_pending" then
        Classifier:SetCategory(cd, nil)
        C_Timer_After(0.1, function()
            if cd and not MCE:IsForbidden(cd) then
                local retry = Classifier:ClassifyFrame(cd)
                Classifier:SetCategory(cd, retry == "aura_pending" and "global" or retry)
                self:ApplyStyle(cd)
            end
        end)
        return
    end

    if cat == "blacklist" then LogStyle(cd, "blacklist", false); return end

    local cfg = MCE.db.profile.categories[cat]
    if not cfg or not cfg.enabled then
        -- Disabled category: clear edge only if we previously set it
        if lastEdge[cd] ~= false and cd.SetDrawEdge then
            pcall(cd.SetDrawEdge, cd, false)
            lastEdge[cd] = false
        end
        LogStyle(cd, cat .. " (off)", false)
        return
    end

    LogStyle(cd, cat, true)

    -- Edge glow (change-detected to prevent flicker)
    if cd.SetDrawEdge and lastEdge[cd] ~= cfg.edgeEnabled then
        pcall(cd.SetDrawEdge, cd, cfg.edgeEnabled)
        lastEdge[cd] = cfg.edgeEnabled
    end
    if cfg.edgeEnabled and cd.SetEdgeScale and lastScale[cd] ~= cfg.edgeScale then
        pcall(cd.SetEdgeScale, cd, cfg.edgeScale)
        lastScale[cd] = cfg.edgeScale
    end

    -- Hide/show countdown numbers (change-detected)
    if cd.SetHideCountdownNumbers then
        local hide = cfg.hideCountdownNumbers
        if cat == "actionbar" and not hide and HasActiveCharge(cd) then
            hide = true
        end
        if lastHide[cd] ~= hide then
            pcall(cd.SetHideCountdownNumbers, cd, hide)
            lastHide[cd] = hide
        end
    end

    -- Skip full font restyle if category unchanged (prevents text flashing)
    if styledCategory[cd] == cat then return end
    styledCategory[cd] = cat

    if cat == "actionbar" then self:StyleStack(cd, cfg) end

    -- Font string styling & positioning
    if not cd.GetRegions then return end
    local n = cd.GetNumRegions and cd:GetNumRegions() or 0
    if n == 0 then return end

    local style = MCE.NormalizeFontStyle(cfg.fontStyle)
    local font  = MCE.ResolveFontPath(cfg.font)
    local regions = { cd:GetRegions() }

    for i = 1, n do
        local r = regions[i]
        if r:GetObjectType() == "FontString" and not MCE:IsForbidden(r) then
            r:SetFont(font, cfg.fontSize, style)
            if cfg.textColor then
                local tc = cfg.textColor
                r:SetTextColor(tc.r, tc.g, tc.b, tc.a)
            end
            if cfg.textAnchor then
                r:ClearAllPoints()
                r:SetPoint(cfg.textAnchor, cd, cfg.textAnchor,
                    cfg.textOffsetX, cfg.textOffsetY)
            end
        end
    end
end

-- =========================================================================
-- FORCE UPDATE
-- =========================================================================

function Styler:ForceUpdateAll(fullScan)
    MCE:DebugPrint("ForceUpdateAll (full=" .. tostring(fullScan) .. ")")

    Classifier:WipeCache()
    wipe(styledCategory)
    wipe(lastEdge)
    wipe(lastScale)
    wipe(lastHide)

    if fullScan or not self.scanned then
        self.scanned = true
        local f = EnumerateFrames()
        while f do
            if not MCE:IsForbidden(f) then
                if f:IsObjectType("Cooldown") then
                    self:QueueUpdate(f)
                elseif f.cooldown and type(f.cooldown) == "table"
                   and not MCE:IsForbidden(f.cooldown) then
                    self:QueueUpdate(f.cooldown)
                end
            end
            f = EnumerateFrames(f)
        end
        return
    end

    -- Incremental: only previously-tracked cooldowns
    for cd in pairs(trackedCooldowns) do
        if cd and cd.IsObjectType and cd:IsObjectType("Cooldown") then
            self:QueueUpdate(cd)
        end
    end
end

-- =========================================================================
-- HOOKS  (AceHook: auto-unhook on Disable)
-- =========================================================================

function Styler:SetupHooks()
    -- Primary hook: fires on every cooldown start/reset
    self:SecureHook("CooldownFrame_Set", function(f)
        if f and not MCE:IsForbidden(f) then self:QueueUpdate(f) end
    end)

    -- Action button specific hook (provides forced "actionbar" category)
    if ActionButton_UpdateCooldown then
        self:SecureHook("ActionButton_UpdateCooldown", function(btn)
            local cd = btn and (btn.cooldown or btn.Cooldown)
            if cd then self:QueueUpdate(cd, "actionbar") end
        end)
    end

    -- LibActionButton support (Bartender4, etc.)
    local LAB = LibStub("LibActionButton-1.0", true)
    if LAB then
        LAB:RegisterCallback("OnButtonUpdate", function(_, btn)
            if btn and btn.cooldown then
                self:QueueUpdate(btn.cooldown, "actionbar")
            end
        end)
    end
end

-- =========================================================================
-- NAMEPLATE EVENTS
-- =========================================================================

function Styler:NAME_PLATE_UNIT_ADDED(_, unit)
    local plate = C_NamePlate and C_NamePlate.GetNamePlateForUnit(unit)
    if not plate then return end

    C_Timer_After(0.05, function()
        if plate and not MCE:IsForbidden(plate) then
            self:ScanFrame(plate, "nameplate")
        end
    end)
end

function Styler:PLAYER_REGEN_DISABLED()
    if self.npTicker then return end
    self.npTicker = C_Timer.NewTicker(0.5, function()
        if not (C_NamePlate and C_NamePlate.GetNamePlates) then return end
        for _, p in ipairs(C_NamePlate.GetNamePlates() or {}) do
            if p and not MCE:IsForbidden(p) then
                self:ScanFrame(p, "nameplate")
            end
        end
    end)
end

function Styler:PLAYER_REGEN_ENABLED()
    if self.npTicker then
        self.npTicker:Cancel()
        self.npTicker = nil
    end
end

-- =========================================================================
-- RECURSIVE SCANNER
-- =========================================================================

--- Recursively scans a frame tree and queues all Cooldown children.
function Styler:ScanFrame(root, forced, maxDepth)
    maxDepth = maxDepth or 10

    local function scan(frame, depth)
        if not frame or depth > maxDepth or MCE:IsForbidden(frame) then return end

        if frame.IsObjectType and frame:IsObjectType("Cooldown") then
            self:QueueUpdate(frame, forced)
        elseif frame.cooldown and type(frame.cooldown) == "table"
           and not MCE:IsForbidden(frame.cooldown) then
            self:QueueUpdate(frame.cooldown, forced)
        end

        local n = frame.GetNumChildren and frame:GetNumChildren() or 0
        if n > 0 and frame.GetChildren then
            local children = { frame:GetChildren() }
            for i = 1, n do scan(children[i], depth + 1) end
        end
    end

    scan(root, 0)
end
