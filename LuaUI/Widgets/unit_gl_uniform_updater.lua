function widget:GetInfo()
   return {
      name      = "Unit gl uniform updater",
      desc      = "Maintains unit and feature GL uniforms",
      author    = "Amnykon",
      date      = "Jan 2025",
      license   = "GNU GPL v2 or later",
      layer     = -100,
      enabled   = true
   }
end

local ceil = math.ceil
local updateCount = 0

-----------------------------------------------------------------
-- Units
-----------------------------------------------------------------

local empDecline = 1 / Game.paralyzeDeclineRate
local gameSpeed = Game.gameSpeed
local paralyzeOnMaxHealth = Game.paralyzeOnMaxHealth

-- Spent silo missiles set paralyze to a 99999999 sentinel (scripts/cruisemissile.lua) to freeze the
-- now-hidden, off-map unit. Real units never approach this, so treat it as "no bar" rather than max EMP.
local maxRealPara = 1e7
local myAllyTeamID = Spring.GetMyAllyTeamID()

-- Slow: MAX_SLOW_FACTOR (the 50% cap) is published by unit_timeslow.lua as a game rules param.
-- slowState above the cap = "overslow" (pinned at max while the excess decays). The excess decays
-- at DEGRADE_FACTOR = 0.04 slowState/second (LuaRules/Configs/timeslow_defs.lua), so the time still
-- locked at max = (slowState - cap) / 0.04 seconds.
local maxSlowFactor = Spring.GetGameRulesParam("MAX_SLOW_FACTOR") or 0.5
local slowDecayPerSecond = 0.04


local includeDir = "LuaUI/Widgets/Include/"
VFS.Include(includeDir.."gl_uniform_channels.lua")

local GetUnitDefID            = Spring.GetUnitDefID
local GetUnitIsStunned        = Spring.GetUnitIsStunned
local GetUnitHealth           = Spring.GetUnitHealth
local GetUnitWeaponState      = Spring.GetUnitWeaponState
local GetUnitShieldState      = Spring.GetUnitShieldState
local GetUnitStockpile        = Spring.GetUnitStockpile
local GetUnitRulesParam       = Spring.GetUnitRulesParam
local glSetUnitBufferUniforms = gl.SetUnitBufferUniforms

local unitUpdateRate = 10
local units = {}
local unitsCount = 0
local unitPosition = {}
local currentUnit = 1

-- Status channels (paralyze/disarm) pack into 12-bit fields: 1-100 = magnitude (value*100), 100+secs =
-- locked-at-max duration. Mirrors the old float semantics (<=1 magnitude, >1 = 1+seconds), which the
-- shader's readField status-decode reproduces, so downstream consumers are unchanged.
local mfloor = math.floor
-- Status (paralyze/disarm/slow) field: 0-100 = magnitude (charging), >=200 = locked at max, storing the
-- effect-END frame (mod 3895, +200 offset) so the duration badge counts down SMOOTHLY on the GPU instead
-- of stepping a whole second at the round-robin rate. (v-1 = seconds of lock remaining.) The magnitude
-- bar that shares this channel just clamps the big value to a full bar, so it's unaffected.
local STATUS_LOCK_BASE = 200
local STATUS_LOCK_MOD = 3895 -- 200 + 3895 = 4095 (12-bit cap); covers ~130s of lock
local function encodeStatus(v, gameFrame)
	if v <= 0 then return 0 end
	if v <= 1 then return mfloor(v * 100 + 0.5) end
	return STATUS_LOCK_BASE + (mfloor(gameFrame + (v - 1) * gameSpeed) % STATUS_LOCK_MOD)
end

-- Encode one ability slot into a 12-bit int per its kind: modular = ready-frame mod 4096; percent =
-- 0-100; int = count. (morph is runtime-assigned, handled separately.) Folds the old per-ability value
-- computations under one switch; the bar's BARTYPE drives the shader decode.
local mmin = math.min
local function pct100(v) return mfloor((v < 0 and 0 or (v > 1 and 1 or v)) * 100 + 0.5) end
-- Modular cooldown: store the ready-frame mod 4096; a ready/past frame stores 0 (bar hides, no aliasing).
local function modFrame(frame, now) return (frame and frame > now) and (frame % 4096) or 0 end
-- Jump: ONE value drives every charge badge -- the frame the LAST charge finishes. The Detriment's
-- 3*reload can exceed the 4096-frame modular window, so it's stored at 1/8 frame resolution (the shader
-- decode in UnitOverlayGL4 must use the same JUMP_FRAME_SCALE). 0 = fully charged (all badges full; a
-- single-charge unit's badge hides). Recomputed from the live jumpReload each visit so it self-corrects.
local JUMP_FRAME_SCALE = 8

local RATE_ETA_MAX_SECS = 256
local morphRateLast, reammoRateLast, stockRateLast, gooRateLast = {}, {}, {}, {}

-- Pausable ETA (morph / reammo / stockpile / goo): SMOOTH while advancing, truly FROZEN (no creep) when stopped.
-- While progress is advancing it stores an absolute completion frame (>= PAUSE_FRAME_BASE) so the shader
-- counts it down smoothly at the observed (metal-fed) rate; while stopped it stores a STATIC seconds band
-- (2+secs, time-independent) so the needle holds still instead of drifting. The /2 scale must match the
-- shader decode. Used for goo (Puppy replication next to metal).
local PAUSE_FRAME_SCALE = 2
local PAUSE_FRAME_BASE = 2048
local PAUSE_GRACE = 60 -- frames of no observed progress before freezing (bridges the source's update steps)

local function frameModeBand(completionFrame)
	return PAUSE_FRAME_BASE + mfloor(completionFrame / PAUSE_FRAME_SCALE) % PAUSE_FRAME_BASE
end
local function staticBand(remFrames)
	local secs = mfloor(remFrames / gameSpeed + 0.5)
	if secs > RATE_ETA_MAX_SECS then secs = RATE_ETA_MAX_SECS elseif secs < 0 then secs = 0 end
	return 2 + secs
end

-- nominalFrames: full-rate frames to complete (e.g. goo's cost/drain) = count "as if it had metal". The
-- needle ONLY moves while progress is actually advancing (a grace window bridges the source's update
-- steps and the overlay's round-robin); the first visit never counts (it could be a just-out-of-ammo
-- bomber). When stopped (flying back, disabled/unpowered pad, out of resources) the remaining is held
-- static, captured once so it doesn't creep. When omitted, the rate is inferred from progress deltas.
-- forceShow: show the badge even at prog == 0 (caller already gated visibility, e.g. bomber needs rearm).
local function pausableETABand(store, unitID, prog, gameFrame, nominalFrames, forceShow)
	if prog >= 1 then store[unitID] = nil; return 0 end -- complete -> hidden
	if not forceShow and prog <= 0 then store[unitID] = nil; return 0 end -- inactive -> hidden
	local last = store[unitID]
	if nominalFrames then
		local completion, progFrame
		if last and prog > last.prog then -- real, observed progress -> (re)anchor and mark working
			completion = gameFrame + (1 - prog) * nominalFrames
			progFrame = gameFrame
		elseif last then -- no progress this visit: keep the anchor and the last-progress timestamp
			completion = last.completion
			progFrame = last.progFrame
		else -- first visit: anchor, but DON'T mark progress (so a just-stopped/idle badge stays frozen)
			completion = gameFrame + (1 - prog) * nominalFrames
		end
		if progFrame and (gameFrame - progFrame <= PAUSE_GRACE) then -- recently advancing -> gauge moves
			store[unitID] = { prog = prog, completion = completion, progFrame = progFrame }
			return frameModeBand(completion)
		end
		-- stopped: hold the remaining it had reached (captured once so it doesn't creep down)
		local frozenVal = (last and last.frozenVal) or staticBand(completion - gameFrame)
		store[unitID] = { prog = prog, completion = completion, progFrame = progFrame, frozenVal = frozenVal }
		return frozenVal
	end
	-- Inferred-rate path (morph / stockpile): no known nominal time.
	local rate = (last and last.rate) or 0
	local advancing = last and prog > last.prog
	if advancing then
		local inst = (prog - last.prog) / (gameFrame - last.frame)
		rate = (rate > 0) and (rate * 0.7 + inst * 0.3) or inst -- don't EMA up from a zero seed
	end
	store[unitID] = { prog = prog, frame = gameFrame, rate = rate }
	if rate <= 1e-7 then return 1 end -- no rate known yet -> grey constant (brief)
	local framesLeft = (1 - prog) / rate
	if advancing and framesLeft < PAUSE_FRAME_BASE * PAUSE_FRAME_SCALE then
		return frameModeBand(gameFrame + framesLeft)
	end
	return staticBand(framesLeft)
end

local function encodeAbility(entry, unitID, unitDefID, gameFrame)
	local kind = entry.kind
	if kind == "reload" then
		local _, _, rf = GetUnitWeaponState(unitID, entry.weapon)
		return modFrame(rf, gameFrame)
	elseif kind == "commReload" then
		local wn = GetUnitRulesParam(unitID, "comm_weapon_num_" .. (entry.commWeapon or 1))
		if not wn or wn == 0 then return 0 end
		local _, _, rf = GetUnitWeaponState(unitID, wn)
		return modFrame(rf, gameFrame)
	elseif kind == "scriptReload" then
		return modFrame(GetUnitRulesParam(unitID, "scriptReloadFrame"), gameFrame)
	elseif kind == "dgun" or kind == "moveDgun" then
		local _, _, rf = GetUnitWeaponState(unitID, unitDefDgun[unitDefID])
		return modFrame(rf, gameFrame)
	elseif kind == "captureReload" then
		return modFrame(GetUnitRulesParam(unitID, "captureRechargeFrame"), gameFrame)
	elseif kind == "burst" then
		local scriptLoaded = mfloor(GetUnitRulesParam(unitID, "scriptLoaded") or unitDefBurstCount[unitDefID])
		local i = entry.index
		if i <= scriptLoaded then return 100 end
		if i == scriptLoaded + 1 then
			local rf = GetUnitRulesParam(unitID, "scriptReloadFrame") or 0
			if rf <= 0 then return 0 end
			local remaining = math.max(0, rf - gameFrame)
			return pct100(1.0 - remaining / (unitDefScriptReload[unitDefID] or 1))
		end
		return 0
	elseif kind == "shield" then
		local on, power = GetUnitShieldState(unitID)
		if on == false then power = 0 end
		return pct100(1 - (power or 0) / unitDefHasShield[unitDefID])
	elseif kind == "heat" then return pct100(GetUnitRulesParam(unitID, "heat_bar") or 0)
	elseif kind == "speed" then return pct100(GetUnitRulesParam(unitID, "speed_bar") or 0)
	elseif kind == "teleport" then
		-- Frame-based: store the completion frame (teleportend); the badge counts down to it. Not
		-- teleporting -> teleportend is -1 -> modFrame returns 0 -> badge hidden.
		return modFrame(GetUnitRulesParam(unitID, "teleportend"), gameFrame)
	elseif kind == "reammo" then
		-- noammo decides VISIBILITY: 1 = out of ammo (flying back), 2 = at the pad -> show the badge;
		-- 0/nil = armed, 3 = repairing (ammo done) -> hidden. COUNTING is driven by reammoProgress actually
		-- advancing, so it stays frozen while flying back or on a disabled/unpowered pad.
		local noammo = GetUnitRulesParam(unitID, "noammo")
		if noammo ~= 1 and noammo ~= 2 then reammoRateLast[unitID] = nil; return 0 end -- clear so a re-drop starts fresh
		return pausableETABand(reammoRateLast, unitID, GetUnitRulesParam(unitID, "reammoProgress") or 0,
			gameFrame, unitDefReammoFrames[unitDefID], true)
	elseif kind == "stockProg" then
		-- Frame-based rate-ETA to the next missile (stalls when resource-starved). The ready count is
		-- the co-located stockpilecount glyph.
		local _, _, sb = GetUnitStockpile(unitID)
		local ud = UnitDefs[unitDefID]
		if ud.customParams and ud.customParams.stockpiletime then sb = GetUnitRulesParam(unitID, "gadgetStockpile") end
		return pausableETABand(stockRateLast, unitID, sb or 0, gameFrame)
	elseif kind == "stockCnt" then
		return mmin(GetUnitStockpile(unitID) or 0, 4095)
	elseif kind == "jump" then
		local jr = GetUnitRulesParam(unitID, "jumpReload") or 0
		local charges = unitDefHasJump[unitDefID] or 1
		local remaining = charges - jr
		if remaining <= 0 then return 0 end -- fully charged sentinel: all badges full (or single hides)
		local targetFrame = gameFrame + remaining * (unitDefJumpReloadFrames[unitDefID] or 1)
		local v = mfloor(targetFrame / JUMP_FRAME_SCALE) % 4096
		return (v == 0) and 1 or v -- keep 0 reserved for "fully charged" while still recharging
	elseif kind == "moveAbility" then
		-- Frame-based: specialReloadRemaining is a 0..1 fraction (1 = just used). Convert to a ready-frame
		-- now + remaining*duration (specialreloadtime, frames). 0 = ready -> hidden.
		local rem = GetUnitRulesParam(unitID, "specialReloadRemaining") or 0
		if rem <= 0 then return 0 end
		return modFrame(gameFrame + rem * (tonumber(unitDefHasAbility[unitDefID]) or 1), gameFrame)
	elseif kind == "goo" then return pausableETABand(gooRateLast, unitID, GetUnitRulesParam(unitID, "gooState") or 0, gameFrame, unitDefGooFrames[unitDefID])
	end
	return 0
end

local unitUniform = {0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0} -- channels 1-14
local writeBuf11 = {0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0} -- block write covers floats 1-11 only: float 12 is gadget cloak (must not clobber), floats 13-14 are unread (their channels map to floats 2/11)
local unitMorphProgress = {}
local unitHighlight = {} -- per-unit highlight/selectedness value (slot 6), pushed via WG.SetUnitHighlight
local unitParalyzeFX = {} -- gfx_paralyze fullscreen-effect value (float 4), pushed via WG.SetUnitParalyzeFX
local unitStateCount = {} -- centered-state count (float 2, bits 19-22)
local unitSelected = {}   -- isSelected (float 2, bit 23)
local unitFloat2Base = {} -- slow+capture packed (float 2 low 19 bits), cached so event write-throughs re-pack

function updateUnit(unitID, unitDefID)
	for i = 1, 14 do unitUniform[i] = 0 end

	local health, maxHealth, paralyzeDamage, capture, build = GetUnitHealth(unitID)
	paralyzeDamage = GetUnitRulesParam(unitID, "real_para") or paralyzeDamage or 0

	if (not maxHealth) or (maxHealth < 1) then maxHealth = 1 end
	if not build then build = 1 end

	local empHP = (not paralyzeOnMaxHealth) and health or maxHealth
	local emp = paralyzeDamage / empHP

	--// BUILD / RECLAIM (ch7): construction progress bar (0..1). buildProgress is < 1 while a nanoframe
	-- is being built or a finished unit is being reclaimed (it falls back from 1), and exactly 1 when
	-- finished/idle. So < 1 means "under construction or being reclaimed" -> show the fill; 1 -> hidden.
	local buildVal = 0
	if build < 1 then
		buildVal = math.max(build, 0.02) -- floor so a freshly-placed nanoframe is still visible
	end
	unitUniform[unitBuildChannel] = buildVal

	--// PARALYZE (ch1)
	local stunned = GetUnitIsStunned(unitID)
	stunned = stunned and paralyzeDamage >= empHP
	if paralyzeDamage >= maxRealPara then
		emp = 0 -- spent silo missile sentinel, not real paralyze
	elseif stunned then
		emp = (paralyzeDamage - empHP) / (maxHealth * empDecline) + 1
	elseif emp > 1 then
		emp = 1
	end
	unitUniform[unitParalyzeChannel] = emp

	--// CAPTURE (ch4)
	unitUniform[unitCaptureChannel] = capture or 0

	--// DISARM (ch2)
	local gameFrame = Spring.GetGameFrame()
	local disarmFrame = GetUnitRulesParam(unitID, "disarmframe")
	if disarmFrame and disarmFrame ~= -1 and disarmFrame > gameFrame then
		local disarmProp = (disarmFrame - gameFrame) / 1200
		if disarmProp < 1 then
			if disarmProp > emp + 0.014 then -- 16 gameframes of emp buffer
				unitUniform[unitDisarmChannel] = disarmProp
			end
		else
			unitUniform[unitDisarmChannel] = (disarmFrame - gameFrame - 1200) / gameSpeed + 1
		end
	end

	--// SLOW (ch3)
	-- Below the cap: magnitude bar (the 50% cap reads as a full bar). Above the cap (overslow):
	-- value > 1 pins the bar at max and the overflow carries the "locked at max" seconds, for a
	-- separate duration badge -- the same single-channel scheme as paralyze/disarm.
	local slowState = GetUnitRulesParam(unitID, "slowState") or 0
	if slowState > maxSlowFactor then
		unitUniform[unitSlowChannel] = (slowState - maxSlowFactor) / slowDecayPerSecond + 1
	else
		unitUniform[unitSlowChannel] = slowState / maxSlowFactor
	end

	-- (Ability values are computed in the ABILITY SLOTS walk below via encodeAbility; the old per-ability
	-- fixed-channel writes -- primary/burst/secondary reloads, multi-weapon extras, movement, shield,
	-- goo/morph -- were removed in favor of the slot model. morph runtime-slot wiring still TODO.)

	--// ABILITY SLOTS: walk the per-unitDef assignment; pack each slot into its float (slots 1,2->float 9;
	-- 3,4->float 10; 5->float 11). Sole source of ability slot values (old fixed writes removed).
	-- Frees floats 5,8,12,14.
	local abSlots = unitDefAbilitySlots[unitDefID]
	local s1, s2, s3, s4, s5 = 0, 0, 0, 0, 0
	if abSlots then
		if abSlots[1] then s1 = encodeAbility(abSlots[1], unitID, unitDefID, gameFrame) end
		if abSlots[2] then s2 = encodeAbility(abSlots[2], unitID, unitDefID, gameFrame) end
		if abSlots[3] then s3 = encodeAbility(abSlots[3], unitID, unitDefID, gameFrame) end
		if abSlots[4] then s4 = encodeAbility(abSlots[4], unitID, unitDefID, gameFrame) end
		if abSlots[5] then s5 = encodeAbility(abSlots[5], unitID, unitDefID, gameFrame) end
	end
	unitUniform[9]  = s1 + s2 * 4096
	unitUniform[10] = s3 + s4 * 4096
	unitUniform[11] = s5
	unitUniform[5]  = 0
	unitUniform[8]  = pausableETABand(morphRateLast, unitID, unitMorphProgress[unitID] or 0, gameFrame)  -- morph pausable-ETA band on float 8
	-- float 12 = gadget cloak (not written here), float 14 unread (channel 14 -> float 11): both outside the 1-11 block write

	-- Pack paralyze+disarm into float 1, slow+capture into float 2 (frees floats 3, 13).
	-- (shield is an ability -> handled in the ability-slot step; morph is pushed to float 8 above.)
	local slowEnc = encodeStatus(unitUniform[unitSlowChannel], gameFrame)
	local captureEnc = mfloor(unitUniform[unitCaptureChannel] * 100 + 0.5)
	unitUniform[1] = encodeStatus(unitUniform[1], gameFrame) + encodeStatus(unitUniform[2], gameFrame) * 4096
	local f2base = slowEnc + captureEnc * 4096
	unitFloat2Base[unitID] = f2base -- so writeStateFlags can re-pack float 2 on state/selection events
	unitUniform[2] = f2base + (unitStateCount[unitID] or 0) * 524288 + (unitSelected[unitID] and 8388608 or 0)
	unitUniform[unitSlowChannel] = 0      -- float 3 freed
	unitUniform[unitCaptureChannel] = 0   -- float 13 freed
	-- Fold in the externally-pushed highlight (slot 6) and gfx_paralyze effect value (float 4) so the
	-- block write preserves them instead of zeroing those slots.
	unitUniform[unitSelectednessChannel] = unitHighlight[unitID] or 0
	unitUniform[4] = unitParalyzeFX[unitID] or 0
	for i = 1, 11 do writeBuf11[i] = unitUniform[i] end
	glSetUnitBufferUniforms(unitID, writeBuf11, 1)  -- floats 1-11 only; float 12 (cloak) and 13-15 left to the gadget / unread
end

function updateUnits()
	local nextBlock = currentUnit + unitUpdateRate - 1
	if nextBlock > unitsCount then
		nextBlock = unitsCount
	end
	for i = currentUnit, nextBlock do
		local unitID = units[i]
		if Spring.ValidUnitID(unitID) then
			updateUnit(unitID, GetUnitDefID(unitID))
		end
	end
	currentUnit = nextBlock + 1
	if currentUnit > unitsCount then
		currentUnit = 1
	end
end

function addUnit(unitID, unitDefID)
	if unitPosition[unitID] ~= nil then return end
	unitsCount = unitsCount + 1
	units[unitsCount] = unitID
	unitPosition[unitID] = unitsCount
	updateUnit(unitID, unitDefID)
end

function removeUnit(unitID)
	local position = unitPosition[unitID]
	if position == nil then return end
	local lastUnit = units[unitsCount]
	units[position] = lastUnit
	unitPosition[lastUnit] = position
	units[unitsCount] = nil
	unitPosition[unitID] = nil
	unitsCount = unitsCount - 1
	unitHighlight[unitID] = nil
	unitStateCount[unitID] = nil
	unitSelected[unitID] = nil
	unitFloat2Base[unitID] = nil
	unitParalyzeFX[unitID] = nil
end

function resetUnits()
	units = {}
	unitsCount = 0
	unitPosition = {}
	currentUnit = 1
	unitMorphProgress = {}
	unitHighlight = {}
	unitStateCount = {}
	unitSelected = {}
	unitFloat2Base = {}
	unitParalyzeFX = {}

	local spec, fullview = Spring.GetSpectatingState()
	local allUnits = Spring.GetAllUnits()
	for i = 1, #allUnits do
		local unitID = allUnits[i]
		if fullview or Spring.GetUnitLosState(unitID, myAllyTeamID).los then
			addUnit(unitID, GetUnitDefID(unitID))
		end
	end
end

function widget:VisibleUnitAdded(unitID, unitDefID, unitTeam)
	addUnit(unitID, unitDefID)
end

function widget:VisibleUnitRemoved(unitID)
	removeUnit(unitID)
end

function widget:PlayerChanged(playerID)
	myAllyTeamID = Spring.GetMyAllyTeamID()
	resetUnits()
end

function widget:VisibleUnitsChanged(visibleUnits, numVisibleUnits)
	resetUnits()
end

function initUnits()
	resetUnits()
end

-----------------------------------------------------------------
-- Features
-----------------------------------------------------------------

local GetVisibleFeatures        = Spring.GetVisibleFeatures
local GetFeatureDefID           = Spring.GetFeatureDefID
local GetFeatureHealth          = Spring.GetFeatureHealth
local GetFeatureResources       = Spring.GetFeatureResources
local glSetFeatureBufferUniforms = gl.SetFeatureBufferUniforms

local trackedFeatures = {}
for i = 1, #FeatureDefs do
	trackedFeatures[i] = FeatureDefs[i].destructable and FeatureDefs[i].drawTypeString == "model"
end

local features = {}
local featureUpdateRate = 200.0

local featureUniform = {0, 0, 0}
function updateFeature(featureID)
	local health, maxHealth, resurrect = GetFeatureHealth(featureID)
	local _, _, _, _, reclaim = GetFeatureResources(featureID)
	featureUniform[featureHealthChannel]    = (health or 0) / (maxHealth or 1)

	-- Resurrect ("raise") progress bar (0..1) as the wreck is raised; 0 = not being raised -> hidden.
	resurrect = resurrect or 0
	featureUniform[featureResurrectChannel] = (resurrect > 0) and math.max(resurrect, 0.02) or 0
	featureUniform[featureReclaimChannel]   = reclaim or 0
	glSetFeatureBufferUniforms(featureID, featureUniform, 1)
end

function addFeature(featureID, defID)
	features[featureID] = defID
	updateFeature(featureID)
	for _, callback in pairs(WG.GlUnionUpdaterAddFeatureCallbacks) do
		callback(featureID)
	end
end

function removeFeature(featureID)
	features[featureID] = nil
	for _, callback in pairs(WG.GlUnionUpdaterRemoveFeatureCallbacks) do
		callback(featureID)
	end
end

function updateFeatures()
	local visibleFeatures = GetVisibleFeatures(-1, nil, false, false)
	local removedFeatures = {}

	local updatePercent = ceil(#visibleFeatures / featureUpdateRate)
	for featureID, _ in pairs(features) do
		removedFeatures[featureID] = true
	end

	local cnt = #visibleFeatures
	for i = 1, cnt do
		local featureID = visibleFeatures[i]
		local featureDefID = GetFeatureDefID(featureID) or -1
		if trackedFeatures[featureDefID] then
			if removedFeatures[featureID] then
				if updatePercent < 2 or (updateCount + featureID) % updatePercent == 0 then
					updateFeature(featureID)
				end
				removedFeatures[featureID] = nil
			else
				addFeature(featureID, featureDefID)
			end
		end
	end

	for featureID, val in pairs(removedFeatures) do
		if val then
			removeFeature(featureID)
		end
	end
end

-----------------------------------------------------------------
-- Highlight (selectedness, slot unitSelectednessChannel)
-- The updater owns the GL write so it stays the sole writer of the channel; callers express intent
-- (highlight this unit/feature) and never see the slot number. Keeps highlight from colliding with
-- the per-frame block write that previously zeroed slot 6.
-----------------------------------------------------------------

local highlightCache = {0}

local function setUnitHighlight(unitID, value)
	value = value or 0
	unitHighlight[unitID] = (value ~= 0) and value or nil
	-- Write through now so a hover is instant; updateUnit folds the stored value into later passes.
	if Spring.ValidUnitID(unitID) then
		highlightCache[1] = value
		glSetUnitBufferUniforms(unitID, highlightCache, unitSelectednessChannel)
	end
end

local function setFeatureHighlight(featureID, value)
	-- No store needed: the feature block write only covers slots 1-3, so slot 6 is never clobbered.
	if Spring.ValidFeatureID(featureID) then
		highlightCache[1] = value or 0
		glSetFeatureBufferUniforms(featureID, highlightCache, unitSelectednessChannel)
	end
end

-- gfx_paralyze pushes its fullscreen-effect value here (instead of writing float 4 directly); stored and
-- folded into the block write so it isn't clobbered. gfx keeps its own linger/draw-list state machine.
local function setUnitParalyzeFX(unitID, value)
	value = value or 0
	unitParalyzeFX[unitID] = (value ~= 0) and value or nil
	if Spring.ValidUnitID(unitID) then
		highlightCache[1] = value
		glSetUnitBufferUniforms(unitID, highlightCache, 4) -- write-through; updateUnit re-folds it each pass
	end
end

-- Float 2 packs slow+capture (low 19 bits, round-robin) + state-count (bits 19-22) + isSelected (bit 23),
-- both event-driven. The round-robin block write folds in the stores; these event write-throughs re-pack
-- from the cached slow+capture base (unitFloat2Base) + the stores. (float 15 is now free.)
local stateFlagsCache = {0}

local function writeStateFlags(unitID)
	if Spring.ValidUnitID(unitID) then
		-- Re-pack float 2 from the cached slow+capture base + the event-driven state-count/isSelected.
		stateFlagsCache[1] = (unitFloat2Base[unitID] or 0) + (unitStateCount[unitID] or 0) * 524288 + (unitSelected[unitID] and 8388608 or 0)
		glSetUnitBufferUniforms(unitID, stateFlagsCache, 2)
	end
end

local function setUnitStateCount(unitID, count)
	count = count or 0
	if count > 15 then count = 15 end -- 4-bit field
	unitStateCount[unitID] = (count ~= 0) and count or nil
	writeStateFlags(unitID)
end

local function setUnitSelected(unitID, selected)
	unitSelected[unitID] = selected and true or nil
	writeStateFlags(unitID)
end

-----------------------------------------------------------------
-- Widget
-----------------------------------------------------------------

local selectedSet = {}
function widget:SelectionChanged(selectedUnits)
	local newSet = {}
	for i = 1, #selectedUnits do newSet[selectedUnits[i]] = true end
	for unitID in pairs(selectedSet) do
		if not newSet[unitID] then setUnitSelected(unitID, false) end
	end
	for unitID in pairs(newSet) do
		if not selectedSet[unitID] then setUnitSelected(unitID, true) end
	end
	selectedSet = newSet
end

function widget:Update()
	updateCount = updateCount + 1
	updateUnits()
	updateFeatures()
end

function widget:Initialize()
	WG.GlUnionUpdaterAddFeatureCallbacks = WG.GlUnionUpdaterAddFeatureCallbacks or {}
	WG.GlUnionUpdaterRemoveFeatureCallbacks = WG.GlUnionUpdaterRemoveFeatureCallbacks or {}

	WG.SetUnitHighlight = setUnitHighlight
	WG.SetFeatureHighlight = setFeatureHighlight
	WG.SetUnitStateCount = setUnitStateCount
	WG.SetUnitSelected = setUnitSelected
	WG.SetUnitParalyzeFX = setUnitParalyzeFX

	WG.MorphUpdateCallbacks = WG.MorphUpdateCallbacks or {}
	WG.MorphStartCallbacks  = WG.MorphStartCallbacks  or {}
	WG.MorphStopCallbacks   = WG.MorphStopCallbacks   or {}

	local widgetName = widget:GetInfo().name
	WG.MorphUpdateCallbacks[widgetName] = function(morphTable)
		for unitID, morph in pairs(morphTable) do
			unitMorphProgress[unitID] = morph.progress
		end
	end
	WG.MorphStopCallbacks[widgetName] = function(unitID)
		unitMorphProgress[unitID] = nil
	end

	initUnits()
end

function widget:Shutdown()
	local widgetName = widget:GetInfo().name
	WG.MorphUpdateCallbacks[widgetName] = nil
	WG.MorphStopCallbacks[widgetName]   = nil
end
