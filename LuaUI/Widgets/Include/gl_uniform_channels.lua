
-----------------------------------------------------------------
-- Units
-----------------------------------------------------------------

local gameSpeed = Game.gameSpeed

local minReloadTime = 0.1 -- floor for picking a unit's primary (slowest) weapon; the visible "show timer" cutoff is the reloadThreshold option in the widget

unitParalyzeChannel = 1
unitDisarmChannel = 2
unitSlowChannel = 3
-- slot 4 reserved: gfx_paralyze_effect writes combined para/disarm/slow/fire bitmask here
unitShieldChannel = 5
unitSelectednessChannel = 6 -- highlight/selectedness; pushed via WG.SetUnitHighlight and folded into the updater's block write (cus reads userDefined[1].z)
unitBuildChannel = 7
unitGooChannel = 8           -- Goo / Morph (mutually exclusive per unit)
unitMorphChannel = 8
unitPrimaryReloadChannel = 9  -- primary weapon / script reload / captureReload / reammo (mutually exclusive per unit)
unitPrimaryCountChannel = 10  -- burst ammo missing count (0 = no bar for non-burst units)
unitSecondaryReloadChannel = 11  -- dgun / teleport / heat / speed / stockpile (mutually exclusive per unit)
unitSecondaryCountChannel = 12   -- stockpile / burst-secondary missing count (0 = no bar)
unitCaptureChannel = 13
unitMovementChannel = 14     -- jump / movement-type ability / movement-type dgun (mutually exclusive per unit)
unitStateCountChannel = 15   -- packed: state-count bits 0-3 (overlay row centering) + isSelected bit 4; pushed via WG.SetUnitStateCount / WG.SetUnitSelected
unitHealthChannel = 20 -- reads engine-native health/maxHealth from the uniform buffer

-- Bit-pack descriptor: channel id -> {float, bitOffset, bitWidth}. width 0 = whole float (passthrough =
-- current behavior). Single source of truth for the updater's packing and the shader's readField (the
-- shader's PACK_* const arrays are generated from this via buildChannelPackDefines). Channels migrate to
-- packed slots one at a time; foundation = all passthrough (float = channel, width 0), zero behavior change.
-- entry = {float, bitOffset, bitWidth, type}. type: 0 = raw passthrough, 1 = status (12-bit int decoded
-- to the old <=1 magnitude / >1 = 1+seconds semantics so downstream consumers are unchanged).
channelPack = {}
for c = 0, 15 do channelPack[c] = { c, 0, 0, 0 } end
channelPack[unitParalyzeChannel] = { 1, 0, 12, 1 }  -- float 1 low,  status
channelPack[unitDisarmChannel]   = { 1, 12, 12, 1 } -- float 1 high, status
channelPack[unitSlowChannel]     = { 2, 0, 12, 1 }  -- float 2 low,  status
channelPack[unitCaptureChannel]  = { 2, 12, 7, 2 }  -- float 2, percent (0-100 -> 0-1); frees floats 3 & 13
-- shield (gauge) and morph/goo (frame-based duration, rate-measured ETA like build) are ABILITIES -> they
-- go through the ability-slot step, not fixed channels. Left passthrough here.
-- Ability slots: 5 generic 12-bit slots. Reuse the old reload/count/movement channel ids (9/10/11/12/14)
-- as the slot ids; remap them to physical floats 9,10,11 (2 slots per float, slot 5 alone in 11). raw
-- extraction -- the bar's BARTYPE (gauge/modular/count) drives the decode, since the type is per-unit.
abilitySlotChannel = { 9, 10, 11, 12, 14 }
channelPack[9]  = { 9, 0, 12, 0 }   -- slot 1: float 9 low
channelPack[10] = { 9, 12, 12, 0 }  -- slot 2: float 9 high
channelPack[11] = { 10, 0, 12, 0 }  -- slot 3: float 10 low
channelPack[12] = { 10, 12, 12, 0 } -- slot 4: float 10 high
channelPack[14] = { 11, 0, 12, 0 }  -- slot 5: float 11 low

function buildChannelPackDefines()
	local f, o, w, t = {}, {}, {}, {}
	for c = 0, 15 do
		f[#f + 1] = channelPack[c][1]
		o[#o + 1] = channelPack[c][2]
		w[#w + 1] = channelPack[c][3]
		t[#t + 1] = channelPack[c][4]
	end
	return table.concat(f, ","), table.concat(o, ","), table.concat(w, ","), table.concat(t, ",")
end

-----------------------------------------------------------------
-- Features
-----------------------------------------------------------------

featureHealthChannel = 1
featureResurrectChannel = 2
featureReclaimChannel = 3

unitDefIgnore = {} -- commanders!
unitDefHasShield = {} -- value is shield max power
unitDefCanStockpile = {} -- 0/1?
unitDefPrimaryReload = {} -- value is max reload time
unitDefHeights = {} -- maps unitDefs to height
unitDefPrimaryWeapon = {} -- the index for reloadable weapon on unitdef weapons (slowest = primary)
unitDefWeapons = {} -- ordered list {index, reload, class, color} of distinct reloadable weapons, slowest first
unitDefExtraWeapons = {} -- for pure multi-weapon units: weapons 2..4 assigned to extra ability channels
unitDefHasAbility = {}
unitDefAbilityIsMovement = {} -- true if unit's ability is movement-type (e.g., Swift's Sprint)
unitDefScriptReload = {}
unitDefBurstCount = {} -- for units with script_burst customParam (Picket, Hacksaw, etc.)
unitDefDgun = {}
unitDefDgunReload = {}
unitDefDgunIsMovement = {} -- true if unit's dgun is movement-type (goes to ch6 instead of ch11)
unitDefHasGoo = {}
unitDefGooFrames = {} -- nominal (full-metal) frames to replicate, for the goo gauge's smooth countdown
unitDefHasJump = {}            -- number of jump charges (>=1; truthy when the unit can jump)
unitDefJumpReloadFrames = {}   -- frames to recharge ONE jump charge (jump_reload seconds * 30)
unitDefHasHeat = {}
unitDefHasSpeed = {}
unitDefHasReammo = {}
unitDefReammoFrames = {} -- nominal rearm time (frames) for the reammo gauge's smooth on-pad countdown
unitDefHasCaptureReload = {}
unitDefHasTeleport = {}
unitDefWeaponIcon = {}  -- primary weapon's reload-badge icon (customParams.icon image path; nil = none drawn)
unitDefWeaponColor = {} -- {r,g,b} beam/projectile color of the classified weapon, for tinting its reload bar
unitDefIsComm = {} -- true for dynamic commanders (weapons assigned at runtime, not in the unitDef)

-- Beams render far brighter than their raw rgbColor (additive glow/bloom), so normalize to full
-- value + a vibrance boost so e.g. (0.3,0,0.4) reads as bright saturated purple. Shared by the
-- per-unitDef scan below and by the widget for per-unit commander weapons. Returns {r,g,b} or nil.
local WEAPON_COLOR_VIBRANCE = 1.5
function getNormalizedWeaponColor(visuals)
	if not (visuals and visuals.colorR) then return nil end
	local r, g, b = visuals.colorR, visuals.colorG, visuals.colorB
	local m = math.max(r, g, b, 0.001)
	return {
		math.min(1, r / m * WEAPON_COLOR_VIBRANCE),
		math.min(1, g / m * WEAPON_COLOR_VIBRANCE),
		math.min(1, b / m * WEAPON_COLOR_VIBRANCE),
	}
end

-- Walk through unitdefs for the stuff we need:
for udefID, unitDef in pairs(UnitDefs) do
        if unitDef.customParams and unitDef.customParams.nohealthbars then
                unitDefIgnore[udefID] = true
        end --ignore debug units

        -- SHIELDS
        local shieldDefID = unitDef.shieldWeaponDef
        local shieldPower = ((shieldDefID) and (WeaponDefs[shieldDefID].shieldPower)) or (-1)
        if shieldPower > 1 then unitDefHasShield[udefID] = shieldPower end

        local isDynamic = false

        if unitDef.customParams and unitDef.customParams.dynamic_comm then
                isDynamic = true
                unitDefIsComm[udefID] = true
        end
        if not isDynamic then -- TODO if isDynamic then return end
                local weapons = unitDef.weapons
                local seenWeaponDef = {} -- dedup by weaponDef: synced dual/triple barrels share one timer
                local weaponList = {}

                for i = 1, #weapons do
                        local wdid = weapons[i].weaponDef
                        local WeaponDef = WeaponDefs[wdid]

                        if not WeaponDef then

                        -- DGUN
                        elseif WeaponDef.manualFire then
                                unitDefDgun[udefID] = i
                                unitDefDgunReload[udefID] = WeaponDef.reload

                        -- CAPTURE RELOAD
                        elseif WeaponDef.customParams and WeaponDef.customParams.post_capture_reload then
                                unitDefHasCaptureReload[udefID] = tonumber(WeaponDef.customParams.post_capture_reload)

                        -- Skip "hidden" weapons (jump-landing crater, walk/takeoff effects, etc.): they're
                        -- effects of other abilities, not player-tracked weapons, and shouldn't eat an
                        -- ability slot (e.g. the Detriment's LANDING was starving its jump gauges).
                        elseif WeaponDef.customParams and WeaponDef.customParams.hidden then

                        -- RELOAD: collect distinct reloadable weapons (one entry per weaponDef).
                        elseif WeaponDef.reload and WeaponDef.reload >= minReloadTime and not seenWeaponDef[wdid] then
                                seenWeaponDef[wdid] = true
                                weaponList[#weaponList + 1] = {
                                        index = i,
                                        reload = WeaponDef.reload,
                                        color = getNormalizedWeaponColor(WeaponDef.visuals),
                                        icon = WeaponDef.customParams and WeaponDef.customParams.icon, -- reload-badge icon (image path); nil = none drawn
                                }
                        end

                end

                -- Slowest weapon first; the slowest stays the "primary" (ch9), matching old behavior.
                table.sort(weaponList, function(a, b) return a.reload > b.reload end)
                if weaponList[1] then
                        unitDefWeapons[udefID] = weaponList
                        unitDefPrimaryWeapon[udefID] = weaponList[1].index
                        unitDefPrimaryReload[udefID] = weaponList[1].reload
                        unitDefWeaponColor[udefID] = weaponList[1].color -- tint the reload badge with the primary's beam color
                        unitDefWeaponIcon[udefID] = weaponList[1].icon   -- primary weapon's reload-badge icon (or nil)
                end

                -- SPECIAL ABILITY
                if unitDef.customParams and unitDef.customParams.specialreloadtime then
                        unitDefHasAbility[udefID] = unitDef.customParams.specialreloadtime
                        unitDefAbilityIsMovement[udefID] = true -- all current abilities are movement-type (e.g., Swift Sprint)
                end

                -- SCRIPT RELOAD
                if unitDef.customParams and unitDef.customParams.script_reload then
                        unitDefScriptReload[udefID] = tonumber(unitDef.customParams.script_reload) * gameSpeed
                end

                -- BURST COUNT (for script-based burst weapons like Picket, Hacksaw)
                if unitDef.customParams and unitDef.customParams.script_burst then
                        unitDefBurstCount[udefID] = tonumber(unitDef.customParams.script_burst)
                end

                -- GOO. Nominal (full-metal) replication time in frames = (cost/drain)*UPDATE_FREQUENCY(30),
                -- so the overlay can count the gauge down smoothly "as if it had metal" instead of inferring
                -- a jumpy rate. (grey_goo_defs.lua: drain is applied every 30 frames.)
                if unitDef.customParams and unitDef.customParams.grey_goo then
                        unitDefHasGoo[udefID] = 1
                        local cost = tonumber(unitDef.customParams.grey_goo_cost)
                        local drain = tonumber(unitDef.customParams.grey_goo_drain)
                        unitDefGooFrames[udefID] = (cost and drain and drain > 0) and (cost / drain * 30) or 1
                end

                -- HEAT
                if unitDef.customParams and unitDef.customParams.heat_initial then
                        unitDefHasHeat[udefID] = 1
                end

                -- SPEED
                if unitDef.customParams and unitDef.customParams.speed_bar then
                        unitDefHasSpeed[udefID] = 1
                end

                -- REAMMO (rearm time in frames, for the overlay's smooth countdown on the pad)
                if unitDef.customParams and unitDef.customParams.reammoseconds then
                        unitDefHasReammo[udefID] = 1
                        unitDefReammoFrames[udefID] = (tonumber(unitDef.customParams.reammoseconds) or 1) * 30
                end

                -- STOCKPILE
                if unitDef.canStockpile then
                        unitDefCanStockpile[udefID] = unitDef.canStockpile
                end

                -- TELEPORT
                if unitDef.customParams and (unitDef.customParams.teleporter_throughput or unitDef.customParams.teleporter_is_beacon) then
                        unitDefHasTeleport[udefID] = 1
                end
        end

        -- JUMP (jump_charges separate badges; each recharges in jump_reload seconds)
        if unitDef.customParams and unitDef.customParams.canjump then
                unitDefHasJump[udefID] = tonumber(unitDef.customParams.jump_charges) or 1
                unitDefJumpReloadFrames[udefID] = (tonumber(unitDef.customParams.jump_reload) or 0) * 30
        end
end

-- MULTI-WEAPON: a unit whose only ability-pool usage is weapons (no dgun / burst / stockpile /
-- teleport / heat / speed / reammo / captureReload / scriptReload) shows every distinct weapon's
-- cooldown. The slowest stays the primary (ch9); the next ones (slowest first) fill the otherwise
-- unused ch10/11/12. Units with a special ability keep just their primary weapon (the special owns
-- the other channels), matching old behavior -- multi-weapon and specials don't co-occur in practice.
local extraWeaponChannels = { unitPrimaryCountChannel, unitSecondaryReloadChannel, unitSecondaryCountChannel } -- ch10,11,12
for udefID, weaponList in pairs(unitDefWeapons) do
        local hasOtherAbility = unitDefBurstCount[udefID] or unitDefDgun[udefID] or unitDefCanStockpile[udefID]
                or unitDefHasTeleport[udefID] or unitDefHasHeat[udefID] or unitDefHasSpeed[udefID]
                or unitDefHasReammo[udefID] or unitDefHasCaptureReload[udefID] or unitDefScriptReload[udefID]
        if (not hasOtherAbility) and #weaponList > 1 then
                local extras = {}
                for n = 2, math.min(#weaponList, #extraWeaponChannels + 1) do
                        extras[#extras + 1] = {
                                channel = extraWeaponChannels[n - 1],
                                index   = weaponList[n].index,
                                reload  = weaponList[n].reload,
                                color   = weaponList[n].color,
                                icon    = weaponList[n].icon,
                        }
                end
                unitDefExtraWeapons[udefID] = extras
        end
end

-- ABILITY-SLOT ASSIGNMENT (the new generic-slot model; ADDITIVE — nothing reads this yet, so the fixed-
-- channel rendering below is untouched until the updater + overlay switch over). Ordered list per
-- unitDef that BOTH sides will walk identically: updater encodes each slot's value, overlay creates each
-- slot's bar (bartype/range/color from `kind`). Priority order below; past ABILITY_SLOTS_N it's dropped.
-- Reads full per-unitDef flags (runs before the budget guard clears overflow for the old 4-ch model).
-- NOTE: priority order is a tunable decision; morph is runtime (assigned when a unit starts morphing,
-- not per-unitDef) and is handled separately at that point.
local ABILITY_SLOTS_N = 5
unitDefAbilitySlots = {}
for udefID, unitDef in pairs(UnitDefs) do
        if not unitDefIgnore[udefID] then
                local slots = {}
                local function add(entry)
                        if #slots < ABILITY_SLOTS_N then slots[#slots + 1] = entry end
                end

                -- WEAPONS (comm = runtime-assigned weapon; burst = one slot per projectile; else distinct
                -- weapons slowest-first). scriptReload-only units (no static weapon) also get a slot.
                if unitDefIsComm[udefID] then
                        -- Dynamic comms can equip two weapons (comm_weapon_id_1/_2); give each a slot. The
                        -- second only renders a bar at runtime if that weapon is actually equipped.
                        add({ kind = "commReload", commWeapon = 1 })
                        add({ kind = "commReload", commWeapon = 2 })
                elseif unitDefBurstCount[udefID] then
                        for i = 1, unitDefBurstCount[udefID] do add({ kind = "burst", index = i }) end
                elseif unitDefWeapons[udefID] then
                        for _, w in ipairs(unitDefWeapons[udefID]) do
                                add({ kind = "reload", weapon = w.index, reload = w.reload, class = w.class, color = w.color })
                        end
                elseif unitDefScriptReload[udefID] then
                        add({ kind = "scriptReload" })
                end
                -- DGUN (non-movement)
                if unitDefDgun[udefID] and not unitDefDgunIsMovement[udefID] then
                        add({ kind = "dgun", reload = unitDefDgunReload[udefID] })
                end
                -- SHIELD (gauge) -- defensive, kept above the minor gauges
                if unitDefHasShield[udefID] then add({ kind = "shield" }) end
                -- STOCKPILE (progress + count = 2 slots)
                if unitDefCanStockpile[udefID] then
                        add({ kind = "stockProg" })
                        add({ kind = "stockCnt" })
                end
                -- MOVEMENT (jump / movement-type dgun / movement-type special)
                if unitDefHasJump[udefID] then
                        add({ kind = "jump" })
                elseif unitDefDgun[udefID] and unitDefDgunIsMovement[udefID] then
                        add({ kind = "moveDgun", reload = unitDefDgunReload[udefID] })
                elseif unitDefAbilityIsMovement[udefID] then
                        add({ kind = "moveAbility" })
                end
                -- MINOR GAUGES / cooldowns
                if unitDefHasTeleport[udefID] then add({ kind = "teleport" }) end
                if unitDefHasHeat[udefID] then add({ kind = "heat" }) end
                if unitDefHasSpeed[udefID] then add({ kind = "speed" }) end
                if unitDefHasReammo[udefID] then add({ kind = "reammo" }) end
                if unitDefHasCaptureReload[udefID] then add({ kind = "captureReload", reload = unitDefHasCaptureReload[udefID] }) end
                if unitDefHasGoo[udefID] then add({ kind = "goo" }) end

                unitDefAbilitySlots[udefID] = slots
        end
end

-- Ability KIND registry: render mode + value encoding for the generic slots. Both sides read this.
--   render: how the shader draws it -- "duration" (modular countdown bar+badge), "gauge" (0-1 level
--           badge), "count" (integer), "rateETA" (build-style ETA badge, morph).
--   enc:    how the updater encodes the 12-bit slot value -- "modular" (target frame mod 4096),
--           "percent" (0-100), "int" (count), "rateETA" (build-style bands).
-- Presentation (color/icon/exact bartype bits, layout zone) is taken from the existing barTypeMap at
-- bar-creation; this table is only the new render/enc info.
abilityKinds = {
        reload        = { render = "duration", enc = "modular" },
        commReload    = { render = "duration", enc = "modular" },
        scriptReload  = { render = "duration", enc = "modular" },
        burst         = { render = "gauge",    enc = "percent" }, -- per-projectile load fraction (0-1)
        morphProg     = { render = "duration", enc = "modular" },
        dgun          = { render = "duration", enc = "modular" },
        moveDgun      = { render = "duration", enc = "modular" },
        jump          = { render = "duration", enc = "modular" },
        moveAbility   = { render = "duration", enc = "modular" },
        reammo        = { render = "duration", enc = "modular" },
        captureReload = { render = "duration", enc = "modular" },
        stockProg     = { render = "duration", enc = "modular" },
        shield        = { render = "gauge",    enc = "percent" },
        heat          = { render = "gauge",    enc = "percent" },
        speed         = { render = "gauge",    enc = "percent" },
        teleport      = { render = "gauge",    enc = "percent" },
        stockCnt      = { render = "count",    enc = "int" },
        goo           = { render = "gauge",    enc = "percent" },
        morph         = { render = "rateETA",  enc = "rateETA" }, -- runtime-assigned
}

-- ABILITY SLOT BUDGET GUARD
-- The 4 dynamic ability channels (ch9-12) hold: weapons (primary + multi-weapon extras, or burst at
-- one slot per projectile), dgun, stockpile (progress + count = 2), teleport, heat, speed, reammo,
-- captureReload. Walk them in priority order (weapons first); anything past the 4th is ignored -- its
-- tracking flag is cleared so it never silently overflows -- and named in a warning. Shield (ch5),
-- movement/jump (ch14) and the transient statuses (paralyze/disarm/slow/build/capture) have their own
-- fixed channels and are NOT part of this pool.
local ABILITY_SLOTS = 4
for udefID, unitDef in pairs(UnitDefs) do
        if not unitDefIgnore[udefID] then
                -- weapon channels actually used: burst (N), else primary + assigned multi-weapon extras.
                local weaponSlots = unitDefBurstCount[udefID]
                        or (unitDefExtraWeapons[udefID] and (#unitDefExtraWeapons[udefID] + 1))
                        or (unitDefPrimaryWeapon[udefID] and 1) or 0
                -- {slot cost, label, clear-fn} in priority order; weapons have no clear-fn (never dropped)
                local pool = {
                        {weaponSlots, "weapon"},
                        {(unitDefDgun[udefID] and not unitDefDgunIsMovement[udefID]) and 1 or 0, "dgun",
                                function() unitDefDgun[udefID] = nil; unitDefDgunReload[udefID] = nil end},
                        {unitDefCanStockpile[udefID] and 2 or 0, "stockpile",
                                function() unitDefCanStockpile[udefID] = nil end},
                        {unitDefHasTeleport[udefID] and 1 or 0, "teleport",
                                function() unitDefHasTeleport[udefID] = nil end},
                        {unitDefHasHeat[udefID] and 1 or 0, "heat",
                                function() unitDefHasHeat[udefID] = nil end},
                        {unitDefHasSpeed[udefID] and 1 or 0, "speed",
                                function() unitDefHasSpeed[udefID] = nil end},
                        {unitDefHasReammo[udefID] and 1 or 0, "reammo",
                                function() unitDefHasReammo[udefID] = nil end},
                        {unitDefHasCaptureReload[udefID] and 1 or 0, "captureReload",
                                function() unitDefHasCaptureReload[udefID] = nil end},
                }
                local used, dropped = 0, nil
                for i = 1, #pool do
                        local cost, label, clear = pool[i][1], pool[i][2], pool[i][3]
                        if cost > 0 then
                                if used + cost <= ABILITY_SLOTS then
                                        used = used + cost
                                elseif clear then
                                        clear()
                                        dropped = dropped and (dropped .. ", " .. label) or label
                                end
                        end
                end
                if dropped then
                        Spring.Echo("[Unit Overlay] ability-slot overflow on " .. tostring(unitDef.name or udefID) ..
                                " (>" .. ABILITY_SLOTS .. " slots): ignoring " .. dropped)
                end
        end
end
