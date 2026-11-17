function widget:GetInfo()
	return {
		name    = "Missile Silo UX",
		desc    = "Movable factory-queue-style strip for missile silos: per-type ready/queued/progress, hover range preview, click to fire/queue/unqueue. Aggregates all owned silos.",
		author  = "danfireman",
		date    = "2026",
		license = "GPLv2 or later",
		layer   = 0,
		enabled = true,
		-- Required to reach the full widgetHandler (customCommands); without it the
		-- handler is a restricted proxy. Same as gui_havens.lua / cmd_missile_silo.lua.
		handler = true,
	}
end

--------------------------------------------------------------------------------
-- Prefix for the widget's diagnostic echoes (missing unit defs etc.).
local MARKER = "[Missile Silo UX]"

--------------------------------------------------------------------------------
-- Settings (Settings/HUD Panels/Missile Silo). Both are plain bool options, so
-- epicMenu makes them hotkeyable by default (no noHotkey on either).
local SyncPanelVisibility  -- forward decl; defined in the visibility section below

options_path = 'Settings/HUD Panels/Missile Silo'
options_order = {'autoShow', 'showPanel'}
options = {
	autoShow = {
		name = 'Auto-show when a silo is built',
		type = 'bool',
		value = true,
		desc = 'Automatically show the panel the first time you own a missile silo.',
	},
	showPanel = {
		name = 'Show panel',
		type = 'bool',
		value = true,
		desc = 'Show or hide the missile silo panel. Also toggled by the top-left command bar button.',
		OnChange = function()
			if SyncPanelVisibility then SyncPanelVisibility() end
		end,
	},
}

--------------------------------------------------------------------------------
-- Missile types (data from zk-repo/units/*.lua weaponDefs).
--   range/aoe in elmos, cost in metal. `homing` (Zeno) tracks a clicked unit; like
--   force-fire, every type can also be fired at a ground point.
--   `ee` = weapon edgeEffectiveness (damage falloff toward the AoE edge; 1 = flat).
--   aoe/ee are refreshed from WeaponDefs at Initialize; these are fallbacks.
-- Display order: r3500 band first, then r6000 band.
local TYPES = {
	{ key = "tacnuke",      label = "Eos",      range = 3500, aoe = 192, ee = 0.4, cost = 600, homing = false, color = {1.00, 0.35, 0.25} },
	{ key = "empmissile",   label = "Shockley", range = 3500, aoe = 280, ee = 1.0, cost = 600, homing = false, color = {0.35, 0.55, 1.00} },
	{ key = "napalmmissile",label = "Inferno",  range = 3500, aoe = 512, ee = 0.4, cost = 500, homing = false, color = {1.00, 0.60, 0.15} },
	{ key = "seismic",      label = "Quake",    range = 6000, aoe = 640, ee = 0.4, cost = 400, homing = false, color = {0.45, 1.00, 0.35} },
	-- Zeno is homing (targets a unit) but still lays down a slow FIELD, so it has a
	-- real AoE (gui_aoe=320, gui_ee=0.1 in missileslow.lua) -- shown like force-fire.
	{ key = "missileslow",  label = "Zeno",     range = 6000, aoe = 320, ee = 0.1, cost = 400, homing = true,  color = {0.70, 0.40, 1.00} },
}
local NUM_TYPES = #TYPES
local typeByKey = {}
for i = 1, NUM_TYPES do typeByKey[TYPES[i].key] = TYPES[i] end

local SILO_NAME     = "staticmissilesilo"
local SILO_CAPACITY = 4        -- missile_silo_capacity in staticmissilesilo.lua
local SEARCH_RANGE  = 48       -- half-width of the rectangle scan around a silo (matches cmd_missile_silo)

-- Resolved in Initialize once UnitDefNames is available.
local siloDefID
local typeByDefID  = {}        -- [missileDefID] = TYPES entry
local missileDefID = {}        -- [typeKey] = missileDefID (negate for build cmd)

--------------------------------------------------------------------------------
-- Chili UI (built once WG.Chili is available).
local Chili, screen0
local window
local typeButtons = {}         -- [i] = { button=, prog=, count=, ready= }
local slotsBar, slotsLabel
local uiBuilt = false
local globalButtonRegistered = false

-- Factory-queue palette (from gui_chili_facpanel.lua).
local buttonColor = {0, 0, 0, 0.4}
local queueColor  = {1, 1, 1, 1}
local progColor   = {1, 0.9, 0, 0.6}

-- Layout (Chili client-area coords -- i.e. INSIDE the window's border padding, so a
-- child at x=0 sits just inside the frame). Matches the Cheat Sheet's skinned look.
local HEADER_H = 18
local SLOTS_H  = 16
local BTN      = 56
local GAP      = 3
-- Border inset drawn by the skinned window frame (left, top, right, bottom). Wide
-- enough that the main_window_small_tall 9-slice frame renders without its 40px corner
-- tiles overlapping (needs client width + left + right >= ~80).
local PADDING  = {14, 8, 14, 8}
local BTN_TOP  = HEADER_H + SLOTS_H
local CLIENT_W = BTN
local CLIENT_H = BTN_TOP + NUM_TYPES * BTN + (NUM_TYPES - 1) * GAP
local WIN_W    = CLIENT_W + PADDING[1] + PADDING[3]
local WIN_H    = CLIENT_H + PADDING[2] + PADDING[4]

-- Persisted window position (Chili coords).
local winX, winY = 12, 200

--------------------------------------------------------------------------------
-- State
local vsx, vsy = Spring.GetViewGeometry()
local myTeamID = Spring.GetMyTeamID()

local silos = {}               -- set: [siloUnitID] = true (owned silos)
local haveSilos = false
local prevHaveSilos = false          -- for the auto-show rising edge (no silos -> owns a silo)

-- Fire-mode is now a real engine command: one hidden custom command per missile type.
-- The engine's guihandler owns "which command is active" (mutual exclusion) and map/UI
-- hit-testing, so there is no hand-rolled armed flag or MousePress guard anymore.
local CMD_FIRE_BASE = 34990    -- widget-local command id block (34991..34995); consumed in CommandNotify
local typeCmdID   = {}         -- [typeKey] = cmdID   (resolved in Initialize)
local cmdIDToType = {}         -- [cmdID]   = TYPES entry
local reArmType   = nil        -- transient: re-activate this type's command next Update (sticky repeat-fire)

-- Aggregated production data, rebuilt on a throttle. Per typeKey:
--   ready (built, progress==1), building (progress<1), pending (queued), frontProgress
local agg = {}
local slotsUsed, slotsCap = 0, 0
-- siloInfo[siloID] = { x, z, ready={[t]={ids}}, building={[t]=n}, pending={[t]=n} }
local siloInfo = {}

--------------------------------------------------------------------------------
-- Speedups
local spGetUnitPosition     = Spring.GetUnitPosition
local spGetUnitHealth       = Spring.GetUnitHealth
local spGetUnitDefID        = Spring.GetUnitDefID
local spGetUnitRulesParam   = Spring.GetUnitRulesParam
local spGetUnitsInRectangle = Spring.GetUnitsInRectangle
local spGetFullBuildQueue   = Spring.GetFullBuildQueue
local spGiveOrderToUnit     = Spring.GiveOrderToUnit
local spGetMouseState       = Spring.GetMouseState
local spTraceScreenRay      = Spring.TraceScreenRay
local spGetGroundHeight     = Spring.GetGroundHeight
local spGetUnitAllyTeam     = Spring.GetUnitAllyTeam
local spGetMyAllyTeamID     = Spring.GetMyAllyTeamID

local glColor            = gl.Color
local glLineWidth        = gl.LineWidth
local glLineStipple      = gl.LineStipple
local glDrawGroundCircle = gl.DrawGroundCircle
local glDepthTest        = gl.DepthTest

local CMD_ATTACK    = CMD.ATTACK
local CMD_OPT_RIGHT = CMD.OPT_RIGHT

local floor = math.floor
local schar = string.char

-- Chili colour escape for a caption ("\255rgb").
local function CEsc(c)
	return schar(255, floor(c[1] * 255), floor(c[2] * 255), floor(c[3] * 255))
end

--------------------------------------------------------------------------------
-- Engine fire-command helpers (replace the old sticky `armedType` flag)
--------------------------------------------------------------------------------

-- The active fire type = whichever of our hidden fire-commands the guihandler currently
-- has active (or nil). The engine owns this state now.
local function ActiveFireType()
	local _, cmdID = Spring.GetActiveCommand()
	return cmdID and cmdIDToType[cmdID] or nil
end

-- Arm fire-mode for `key` by activating its command, exactly as the stock global
-- commands do (gui_chili_global_commands.lua:271): resolve the desc index, SetActiveCommand.
local function ActivateFireCommand(key)
	local cmdID = typeCmdID[key]
	if not cmdID then return end
	local index = Spring.GetCmdDescIndex(cmdID)
	if index then
		Spring.SetActiveCommand(index, 1, true, false, false, false, false, false)
	end
end

--------------------------------------------------------------------------------
-- Silo tracking
--------------------------------------------------------------------------------

local function AddSilo(unitID, unitDefID, unitTeam)
	if unitDefID == siloDefID and unitTeam == myTeamID then
		silos[unitID] = true
	end
end

function widget:UnitCreated(unitID, unitDefID, unitTeam)
	AddSilo(unitID, unitDefID, unitTeam)
end

function widget:UnitFinished(unitID, unitDefID, unitTeam)
	AddSilo(unitID, unitDefID, unitTeam)
end

function widget:UnitDestroyed(unitID)
	silos[unitID] = nil
end

function widget:UnitGiven(unitID, unitDefID, unitTeam)
	silos[unitID] = nil
	AddSilo(unitID, unitDefID, unitTeam)
end

function widget:UnitTaken(unitID)
	silos[unitID] = nil
end

--------------------------------------------------------------------------------
-- Aggregation
--------------------------------------------------------------------------------

-- GetFullBuildQueue returns an ordered list of {[unitDefID]=count} blocks.
local function AccumulateQueue(siloID, into)
	local q = spGetFullBuildQueue(siloID)
	if not q then return end
	for i = 1, #q do
		local block = q[i]
		if type(block) == "table" then
			for defID, count in pairs(block) do
				local t = typeByDefID[defID]
				if t then into[t.key] = (into[t.key] or 0) + count end
			end
		end
	end
end

local function Recompute()
	for i = 1, NUM_TYPES do
		local key = TYPES[i].key
		local a = agg[key]
		if not a then a = {}; agg[key] = a end
		a.ready, a.building, a.pending, a.frontProgress = 0, 0, 0, 0
	end
	slotsUsed, slotsCap = 0, 0
	siloInfo = {}

	for siloID in pairs(silos) do
		local sx, _, sz = spGetUnitPosition(siloID)
		if sx then
			slotsCap = slotsCap + SILO_CAPACITY
			-- `used` = missiles currently occupying this silo's pads (ready + building);
			-- SILO_CAPACITY - used is how many free build slots it has.
			local info = { x = sx, z = sz, used = 0, ready = {}, building = {}, pending = {} }
			siloInfo[siloID] = info

			-- Missiles physically on this silo's pads (built or building).
			local units = spGetUnitsInRectangle(sx - SEARCH_RANGE, sz - SEARCH_RANGE, sx + SEARCH_RANGE, sz + SEARCH_RANGE)
			for j = 1, #units do
				local mID = units[j]
				if spGetUnitRulesParam(mID, "missile_parentSilo") == siloID then
					local t = typeByDefID[spGetUnitDefID(mID)]
					if t then
						local key = t.key
						local a = agg[key]
						local progress = select(5, spGetUnitHealth(mID)) or 0
						slotsUsed = slotsUsed + 1
						info.used = info.used + 1
						if progress >= 1 then
							a.ready = a.ready + 1
							local lst = info.ready[key]
							if not lst then lst = {}; info.ready[key] = lst end
							lst[#lst + 1] = mID
						else
							a.building = a.building + 1
							info.building[key] = (info.building[key] or 0) + 1
							if progress > a.frontProgress then a.frontProgress = progress end
						end
					end
				end
			end

			-- Full build queue: for a factory this includes the order that is CURRENTLY
			-- building as a nanoframe (removed only when the missile finishes), so
			-- `pending` already counts the `building` nanoframes above -- do NOT re-add
			-- `building` to it, or in-progress missiles would be counted twice.
			AccumulateQueue(siloID, info.pending)
			for key, n in pairs(info.pending) do
				agg[key].pending = agg[key].pending + n
			end
		end
	end
end

--------------------------------------------------------------------------------
-- Targeting helpers
--------------------------------------------------------------------------------

-- Squared XZ distance -- shared engine utility (Spring.Utilities.Vector), not hand-rolled.
local Dist2 = Spring.Utilities.Vector.DistSq

-- Fire one ready missile of `t` from the nearest in-range silo to (tx,tz), preferring a
-- silo whose shot actually reaches the target over one whose vlaunch arc would slam into
-- terrain on the way (a hill between silo and target). The terrain-impact projection is
-- owned by the Attack AoE widget (WG.GetVlaunchTerrainImpact), so this filter matches the
-- depth line a player sees when force-firing the same missile.
local function FireType(t, tx, tz, targetUnitID)
	local key = t.key
	local rangeSq = t.range * t.range
	-- Target height for the terrain-impact test: a clicked unit's own height, else the
	-- ground at the target point.
	local ty
	if targetUnitID then
		ty = select(2, spGetUnitPosition(targetUnitID)) or spGetGroundHeight(tx, tz) or 0
	else
		ty = spGetGroundHeight(tx, tz) or 0
	end

	local getImpact = WG.GetVlaunchTerrainImpact
	local bestMissile, bestD             -- nearest silo whose shot reaches the target
	local blockedMissile, blockedD       -- nearest silo whose shot hits terrain (fallback)
	for siloID, info in pairs(siloInfo) do
		local lst = info.ready[key]
		if lst and #lst > 0 then
			local d = Dist2(info.x, info.z, tx, tz)
			if d <= rangeSq then
				local missile = lst[#lst]
				-- A ready missile whose trajectory is projected to hit terrain short of the
				-- target is only a fallback -- prefer any silo that can actually reach here.
				if getImpact and getImpact(missile, tx, ty, tz) then
					if not blockedD or d < blockedD then
						blockedD, blockedMissile = d, missile
					end
				elseif not bestD or d < bestD then
					bestD, bestMissile = d, missile
				end
			end
		end
	end
	-- Fall back to the nearest terrain-blocked silo when every in-range silo is blocked, so
	-- a fire click never silently no-ops (the projection is approximate, and a blocked shot
	-- still matches the old always-fire behaviour).
	local missile = bestMissile or blockedMissile
	if not missile then return false end
	-- Match force-fire (cmd_missile_silo.lua): a unit click tracks that unit; a ground
	-- click attacks the point. This holds for every type, including the homing Zeno --
	-- its weapon accepts a ground ATTACK, so ground-firing it is valid (it just lays its
	-- slow field there). Homing only decides whether a unit click gets unit-tracking.
	if targetUnitID then
		spGiveOrderToUnit(missile, CMD_ATTACK, { targetUnitID }, 0)
	else
		spGiveOrderToUnit(missile, CMD_ATTACK, { tx, ty, tz }, 0)
	end
	return true
end

-- Middle-click: queue one of `t` at the silo with the shortest build queue among
-- those covering the viewport centre; else the nearest silo that has a free build
-- slot (so the missile starts building at once rather than waiting in a queue); else
-- the nearest silo overall, so queueing never silently no-ops when every pad is full.
local function QueueType(t)
	local _, coords = spTraceScreenRay(vsx * 0.5, vsy * 0.5, true)
	local cx, cz
	if coords then cx, cz = coords[1], coords[3] end

	local rangeSq = t.range * t.range
	local bestCover, bestCoverLen
	local bestFree, bestFreeD        -- nearest silo with an empty pad (used < capacity)
	local bestNear, bestNearD        -- nearest silo overall (ultimate fallback)
	for siloID, info in pairs(siloInfo) do
		-- pending already includes building nanoframes (see Recompute), so it is the
		-- silo's full queue length for this type on its own.
		local qlen = info.pending[t.key] or 0
		if cx then
			local d = Dist2(info.x, info.z, cx, cz)
			if d <= rangeSq and (not bestCoverLen or qlen < bestCoverLen) then
				bestCoverLen, bestCover = qlen, siloID
			end
			if info.used < SILO_CAPACITY and (not bestFreeD or d < bestFreeD) then
				bestFreeD, bestFree = d, siloID
			end
			if not bestNearD or d < bestNearD then
				bestNearD, bestNear = d, siloID
			end
		elseif not bestCoverLen or qlen < bestCoverLen then
			bestCoverLen, bestCover = qlen, siloID
		end
	end

	local target = bestCover or bestFree or bestNear
	if target then
		-- No modifier queues exactly one; OPT_SHIFT would multiply the factory
		-- build order ×5 (Spring factory-queue semantics).
		spGiveOrderToUnit(target, -missileDefID[t.key], {}, 0)
		return true
	end
	return false
end

-- Right-click on button: unqueue one of `t`, preferring a not-yet-started (pending)
-- order, else a building nanoframe. RIGHT-option removes one from that silo's queue;
-- it never touches finished missiles (they are independent units, not queue entries).
local function UnqueueType(t)
	local target
	for siloID, info in pairs(siloInfo) do
		if (info.pending[t.key] or 0) > 0 then target = siloID; break end
	end
	if not target then
		for siloID, info in pairs(siloInfo) do
			if (info.building[t.key] or 0) > 0 then target = siloID; break end
		end
	end
	if target then
		spGiveOrderToUnit(target, -missileDefID[t.key], {}, CMD_OPT_RIGHT)
		return true
	end
	return false
end

--------------------------------------------------------------------------------
-- Chili panel
--------------------------------------------------------------------------------

-- Push aggregated data into the Chili controls.
local function UpdatePanel()
	if not uiBuilt then return end
	slotsBar:SetValue(slotsCap > 0 and slotsUsed / slotsCap or 0)
	slotsLabel:SetCaption(string.format("%d/%d", slotsUsed, slotsCap))

	local activeT = ActiveFireType()
	for i = 1, NUM_TYPES do
		local t = TYPES[i]
		local a = agg[t.key] or { ready = 0, building = 0, pending = 0, frontProgress = 0 }
		local tb = typeButtons[i]
		-- `pending` (the full build queue) already includes the building nanoframes,
		-- so it IS the total in-production (not-yet-ready) count on its own.
		local queued = a.pending
		tb.count:SetCaption(queued > 0 and tostring(queued) or "")
		tb.ready:SetCaption(a.ready > 0 and (CEsc(t.color) .. tostring(a.ready)) or "")
		tb.prog:SetValue(a.frontProgress or 0)

		local armed = (activeT == t)
		local bg = armed and { t.color[1], t.color[2], t.color[3], 1 }
			or ((queued > 0 or a.ready > 0) and queueColor or buttonColor)
		if tb.button.backgroundColor ~= bg then
			tb.button.backgroundColor = bg
			tb.button:Invalidate()
		end
	end
end

local function MakeTypeButton(t, i)
	local Button, Label, Image, Progressbar = Chili.Button, Chili.Label, Chili.Image, Chili.Progressbar
	local defID = missileDefID[t.key]
	local ud = UnitDefs and UnitDefs[defID]
	local frame = (WG and WG.GetBuildIconFrame and ud) and WG.GetBuildIconFrame(ud) or nil

	local prog = Progressbar:New{
		name = 'prog', value = 0, max = 1,
		x = 2, y = 2, right = 2, bottom = 2,
		color = progColor, backgroundColor = {1, 1, 1, 0.01},
		skin = nil, skinName = 'default',
	}
	local bp = Image:New{
		name = 'bp', file = "#" .. defID, file2 = frame,
		keepAspect = false, x = 0, y = 0, width = '100%', height = '100%',
		children = { prog },
	}
	local count = Label:New{
		name = 'count', autosize = false, width = '100%', height = '100%',
		align = 'right', valign = 'top', caption = '',
		objectOverrideFont = WG.GetFont(15),
	}
	local ready = Label:New{
		name = 'ready', autosize = false, width = '100%', height = '100%',
		align = 'left', valign = 'bottom', caption = '',
		objectOverrideFont = WG.GetFont(16),
	}

	local specs = "range " .. t.range
	if t.homing then specs = specs .. ", homing" end
	if t.aoe and t.aoe > 0 then specs = specs .. ", AoE " .. t.aoe end
	specs = specs .. ", " .. t.cost .. "m"
	local tip = t.label .. "  (" .. specs .. ")\n"
		.. "Left: aim & fire (click again, or when none ready, to build one)\n"
		.. "Middle: build one   Right: cancel one"

	local button = Button:New{
		name = "silotype_" .. t.key,
		x = 0, y = BTN_TOP + (i - 1) * (BTN + GAP), width = BTN, height = BTN,
		padding = {2, 2, 2, 2}, caption = '', tooltip = tip,
		backgroundColor = buttonColor,
		-- In Chili the FIRST child is frontmost; keep the labels above the icon.
		children = { count, ready, bp },
		OnMouseDown = { function(self, mx, my, mb)
			if mb == 1 then
				-- Left-click chooses the most useful action for the current state:
				--  * already armed (this type active) -> second click queues one (convenience)
				--  * nothing ready AND nothing queued -> queue one (arming would fire nothing)
				--  * otherwise -> arm fire-mode via this type's engine command, so the
				--    engine (guihandler) owns the armed state, command mutual-exclusion,
				--    and map/UI hit-testing.
				local a = agg[t.key]
				local ready   = a and a.ready or 0
				local pending = a and a.pending or 0
				if ActiveFireType() == t or (ready == 0 and pending == 0) then
					QueueType(t)
				else
					ActivateFireCommand(t.key)
				end
			elseif mb == 2 then
				QueueType(t)
			elseif mb == 3 then
				UnqueueType(t)
			end
			UpdatePanel()
			return self
		end },
	}

	typeButtons[i] = { button = button, prog = prog, count = count, ready = ready }
	return button
end

local function BuildUI()
	Chili = WG.Chili
	screen0 = Chili.Screen0
	local Window, Label, Progressbar = Chili.Window, Chili.Label, Chili.Progressbar

	-- Title styled like the Cheat Sheet header: outlined grey, standard font cache.
	local children = {
		Label:New{ x = 0, right = 0, y = 0, height = HEADER_H, autosize = false,
			align = 'center', valign = 'center', caption = "Silos",
			objectOverrideFont = WG.GetSpecialFont(14, "silo_title", {
				size = 14, outline = true, color = {0.8, 0.8, 0.8, 0.9},
				outlineWidth = 2, outlineWeight = 2,
			}),
		},
	}

	slotsBar = Progressbar:New{
		x = 0, y = HEADER_H, width = BTN, height = SLOTS_H - 2,
		value = 0, max = 1, color = {0.30, 0.55, 0.85, 0.85},
		backgroundColor = {0.12, 0.12, 0.14, 0.9}, skinName = 'default',
	}
	slotsLabel = Label:New{
		x = 0, y = HEADER_H, width = BTN, height = SLOTS_H, autosize = false,
		align = 'center', valign = 'center', caption = "0/0",
		objectOverrideFont = WG.GetFont(11),
	}
	children[#children + 1] = slotsBar
	children[#children + 1] = slotsLabel

	for i = 1, NUM_TYPES do
		children[#children + 1] = MakeTypeButton(TYPES[i], i)
	end

	-- Skinned window frame (border + background) matching the Cheat Sheet and the other
	-- standard ZK panels; main_window_small_tall suits this narrow vertical strip.
	window = Window:New{
		parent = screen0,
		classname = "main_window_small_tall",
		name = "missile_silo_ux",
		x = winX, y = winY, width = WIN_W, height = WIN_H,
		padding = PADDING,
		draggable = true, resizable = false,
		children = children,
	}
	uiBuilt = true
	window:SetVisibility(haveSilos and options.showPanel.value)
end

--------------------------------------------------------------------------------
-- Top-left command-bar toggle (like the Cheat Sheet button)
--------------------------------------------------------------------------------

function SyncPanelVisibility()
	if not uiBuilt then return end
	local shouldShow = haveSilos and options.showPanel.value
	if window.visible ~= shouldShow then
		window:SetVisibility(shouldShow)
	end
end

-- Drive the "Show panel" option from code (top-left button / auto-show), keeping the
-- settings checkbox in sync if the menu happens to be open, then apply visibility.
local function SetShowPanel(show)
	if options.showPanel.value ~= show then
		options.showPanel.value = show
		local chbox = options.showPanel.epic_reference    -- the Chili checkbox, if the menu is built
		if chbox then
			chbox.checked = show
			chbox:Invalidate()
		end
	end
	SyncPanelVisibility()           -- respond immediately, don't wait for the next GameFrame
end

local function TogglePanel()
	SetShowPanel(not options.showPanel.value)
end

-- Register a toggle button in the top-left GlobalCommandBar once the player owns a silo.
-- The bar has no remove function, so (like gui_chili_cheats.lua) we cache the button in a
-- WG field and reuse it across widget reloads instead of adding a duplicate.
local function EnsureGlobalButton()
	if globalButtonRegistered or not (WG and WG.GlobalCommandBar) then return end
	if WG.MissileSiloUX_global_button then          -- reload: reuse the existing slot
		WG.MissileSiloUX_global_button.OnClick = { function() TogglePanel() end }
		WG.MissileSiloUX_global_button:Show()
	else
		WG.MissileSiloUX_global_button = WG.GlobalCommandBar.AddCommand(
			"unitpics/tacnuke.png",      -- Eos build icon (auto-scaled to the ~25px button)
			"Missile Silos\n\nShow or hide the missile silo panel.",
			TogglePanel)
	end
	globalButtonRegistered = true
end

--------------------------------------------------------------------------------
-- World-space range/AoE preview (immediate-mode; Chili can't draw on the map)
--------------------------------------------------------------------------------

function widget:DrawWorld()
	if not haveSilos or not uiBuilt then return end

	-- Active type = the armed engine command, else the one hovered in the panel.
	local activeT = ActiveFireType()
	local key = activeT and activeT.key
	if not key then
		for i = 1, NUM_TYPES do
			if typeButtons[i].button.state.hovered then key = TYPES[i].key; break end
		end
	end
	if not key then return end
	local t = typeByKey[key]

	-- Per-silo range circles, drawn differently by whether THAT silo currently has a
	-- ready missile of this type to fire: a silo that can fire gets a solid, bright ring;
	-- one that cannot (empty or still building) gets a dim, dashed ring -- so the preview
	-- shows at a glance which silos a fire click would actually launch from.
	local r, g, b = t.color[1], t.color[2], t.color[3]
	glDepthTest(false)
	for _, info in pairs(siloInfo) do
		local lst = info.ready[key]
		if lst and #lst > 0 then
			glLineStipple(false)
			glLineWidth(2)
			glColor(r, g, b, 0.75)
		else
			glLineStipple(2, 0x5555)
			glLineWidth(1)
			glColor(r, g, b, 0.30)
		end
		glDrawGroundCircle(info.x, 0, info.z, t.range, 64)
	end
	glLineStipple(false)

	-- AoE preview at the cursor while armed. Zeno is homing but still lays down a slow
	-- FIELD, so it has a real AoE too -- show it exactly like force-firing via selection
	-- (gui_attack_aoe draws Zeno's gui_aoe at the target). Gated only on aoe > 0.
	-- Reuse the stock Attack AoE falloff renderer (exposed via WG) rather than
	-- duplicating it; the missile's colour makes the preview read as its type.
	if activeT == t and t.aoe and t.aoe > 0 and WG.DrawAoEPreview then
		local mx, my = spGetMouseState()
		local _, coords = spTraceScreenRay(mx, my, true)
		if coords then
			WG.DrawAoEPreview(coords[1], coords[2], coords[3], t.aoe, t.ee, t.color)
		end
	end

	glLineWidth(1)
	glColor(1, 1, 1, 1)
	glDepthTest(true)
end

--------------------------------------------------------------------------------
-- Engine fire commands (replaces the old MousePress/armedType input path)
--------------------------------------------------------------------------------

-- Register one hidden custom command per missile type. `hidden = true` keeps them out
-- of the integral command panel (gui_chili_integral_menu.lua HiddenCommand at :2166)
-- while they still live in the guihandler's list, so GetCmdDescIndex/SetActiveCommand
-- resolve them (the floating strip is the only UI that activates them). Registered
-- unconditionally like gui_havens' retreat zone -- selection-independent, so firing
-- never changes the unit selection. Every type takes a unit OR a ground point, matching
-- force-fire: even the homing Zeno can be fired at the ground (its weapon accepts a
-- ground ATTACK), so all commands are ICON_UNIT_OR_MAP.
function widget:CommandsChanged()
	if not siloDefID then return end
	local customCommands = widgetHandler.customCommands
	for i = 1, NUM_TYPES do
		local t = TYPES[i]
		customCommands[#customCommands + 1] = {
			id      = typeCmdID[t.key],
			type    = CMDTYPE.ICON_UNIT_OR_MAP,
			name    = t.label,
			action  = "missilesilo_fire_" .. t.key,
			tooltip = "Fire " .. t.label,
			cursor  = "Attack",
			hidden  = true,
			params  = {},
		}
	end
end

-- Fire happens here. The engine routed the click, so command mutual-exclusion and UI
-- hit-testing are already handled by the guihandler -- the entire hand-rolled guard class
-- (OverChiliUI/uiScale, GetActiveCommand deferral, MousePress) is gone. `params` is
-- {x,y,z} for a ground click or {unitID} for a unit click (all types are ICON_UNIT_OR_MAP).
function widget:CommandNotify(cmdID, params, options)
	local t = cmdIDToType[cmdID]
	if not t then return false end
	if params then
		if #params >= 3 then
			FireType(t, params[1], params[3], nil)
		elseif #params == 1 then
			local ux, _, uz = spGetUnitPosition(params[1])
			if ux then FireType(t, ux, uz, t.homing and params[1] or nil) end
		end
	end
	-- Keep fire-mode sticky for rapid repeat fire: the engine deactivates a command once
	-- it is issued, so re-arm it on the next Update. Right-click cancels natively (no
	-- CommandNotify fires), so a cancel correctly does NOT re-arm.
	reArmType = t.key
	return true
end

function widget:Update()
	if reArmType then
		local key = reArmType
		reArmType = nil
		if not ActiveFireType() then ActivateFireCommand(key) end
	end
end

--------------------------------------------------------------------------------
-- Lifecycle
--------------------------------------------------------------------------------

function widget:GameFrame(n)
	if n % 6 ~= 0 then return end
	haveSilos = next(silos) ~= nil
	if not uiBuilt then
		if WG and WG.Chili then BuildUI() else return end
	end
	if haveSilos then
		EnsureGlobalButton()        -- lazy: WG.GlobalCommandBar may initialize after us
		Recompute()
		UpdatePanel()
	end
	-- Auto-show on the rising edge (didn't own a silo -> now do), if enabled. Only on the
	-- transition, so a manual hide isn't undone every frame the player still owns a silo.
	if haveSilos and not prevHaveSilos and options.autoShow.value and not options.showPanel.value then
		SetShowPanel(true)
	end
	prevHaveSilos = haveSilos
	SyncPanelVisibility()
end

function widget:ViewResize(x, y)
	vsx, vsy = x, y
end

function widget:Initialize()
	siloDefID = UnitDefNames[SILO_NAME] and UnitDefNames[SILO_NAME].id
	if not siloDefID then
		Spring.Echo(MARKER .. " ERROR: staticmissilesilo UnitDef not found; disabling.")
		widgetHandler:RemoveWidget(self)
		return
	end
	for i = 1, NUM_TYPES do
		local t = TYPES[i]
		local cmdID = CMD_FIRE_BASE + i
		typeCmdID[t.key] = cmdID
		cmdIDToType[cmdID] = t
		local ud = UnitDefNames[t.key]
		if ud then
			typeByDefID[ud.id] = t
			missileDefID[t.key] = ud.id

			-- Pull authoritative AoE + edge-effectiveness from the missile's weapon so
			-- the preview matches the stock Attack AoE widget (and survives rebalances).
			local realUD = UnitDefs[ud.id]
			local weapons = realUD and realUD.weapons
			local wd = weapons and weapons[1] and WeaponDefs[weapons[1].weaponDef]
			if wd then
				local cp = wd.customParams or {}
				t.aoe = tonumber(cp.gui_aoe) or wd.damageAreaOfEffect or t.aoe
				t.ee  = tonumber(cp.gui_ee) or wd.edgeEffectiveness or t.ee
			end
		else
			Spring.Echo(MARKER .. " WARNING: missile UnitDef missing: " .. t.key)
		end
	end

	for _, unitID in ipairs(Spring.GetAllUnits()) do
		AddSilo(unitID, spGetUnitDefID(unitID), Spring.GetUnitTeam(unitID))
	end
	haveSilos = next(silos) ~= nil
	-- Seed the rising-edge tracker to the current state so a mid-game widget reload with a
	-- silo already present doesn't fire a spurious auto-show over a persisted manual hide.
	prevHaveSilos = haveSilos

	if WG and WG.Chili then BuildUI() end
	if haveSilos then
		Recompute()
		UpdatePanel()
	end
end

function widget:Shutdown()
	-- The GlobalCommandBar has no remove function; hide (not dispose) the cached button
	-- so a reload reuses the same slot rather than adding a duplicate.
	if WG.MissileSiloUX_global_button then WG.MissileSiloUX_global_button:Hide() end
	if window then window:Dispose() end
end

function widget:GetConfigData()
	if window then winX, winY = window.x, window.y end
	return { winX = winX, winY = winY }
end

function widget:SetConfigData(data)
	if data then
		if data.winX then winX = data.winX end
		if data.winY then winY = data.winY end
	end
end
