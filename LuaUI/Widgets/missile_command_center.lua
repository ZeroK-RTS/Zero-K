--------------------------------------------------------------------------------
--------------------------------------------------------------------------------

function widget:GetInfo()
	return {
		name      = "Missile Command Center",
		desc      = "Adds missile launch commands and previews where each shot will land, marking terrain that blocks it.",
		author    = "Amnykon",
		date      = "2021-07-30",
		license   = "GNU GPL, v2 or later",
		layer     = 0,
		handler   = true,
		enabled   = true,
	}
end

function widget:Initialize()
	WG.missileActiveIcons = {}
end

options_path = 'Settings/HUD Panels/Missile Launcher'
options_order = {'combineEosScylla'}
options = {
	combineEosScylla = {
		name = 'Combine Eos and Scylla',
		desc = 'Show Eos (silo tactical nuke) and Scylla (submarine tactical nuke) as a single Launch button instead of two.',
		type = 'bool',
		value = false,
		noHotkey = true,
	},
}

--------------------------------------------------------------------------------
--------------------------------------------------------------------------------

local glVertex      = gl.Vertex
local glPushAttrib  = gl.PushAttrib
local glLineStipple = gl.LineStipple
local glDepthTest   = gl.DepthTest
local glLineWidth   = gl.LineWidth
local glColor       = gl.Color
local glBeginEnd    = gl.BeginEnd
local glPopAttrib   = gl.PopAttrib
local glPopMatrix   = gl.PopMatrix
local glPushMatrix  = gl.PushMatrix
local glScale       = gl.Scale
local glTranslate   = gl.Translate
local glDrawGroundCircle = gl.DrawGroundCircle
local GL_LINE_LOOP  = GL.LINE_LOOP

local circleDivs           = 64

local PI                     = math.pi
local cos                    = math.cos
local sin                    = math.sin

local aoeColor             = {1, 0, 0, 1}
local floor                  = math.floor

local pulse_timmer = Spring.GetTimer()
local function getPulse()
	local time = Spring.DiffTimers(Spring.GetTimer(), pulse_timmer)
	return 1 - (time - floor(time))
end

local function UnitCircleVertices()
	for i = 1, circleDivs do
		local theta = 2 * PI * i / circleDivs
		glVertex(cos(theta), 0, sin(theta))
	end
end

local function DrawCircle(x, y, z, radius)
	glPushMatrix()
	glTranslate(x, y, z)
	glScale(radius, radius, radius)
	glBeginEnd(GL_LINE_LOOP, UnitCircleVertices)
	glPopMatrix()
end

-- Blast footprint at the impact point. Reuses the Attack AoE widget's falloff
-- renderer (via WG) so the launch preview and the stock force-fire preview draw an
-- identical ring stack; the pulse is passed through as an overall-alpha multiplier.
local function drawBlastRadius(tx, ty, tz, weaponDef)
	if not (WG.AttackAoE and WG.AttackAoE.DrawAoEPreview) then return end
	WG.AttackAoE.DrawAoEPreview(tx, ty, tz, weaponDef.damageAreaOfEffect, weaponDef.edgeEffectiveness, aoeColor, getPulse())
end

-- Faint ring at the intended target, drawn when the shot is blocked so it is
-- clear the impact ring has been relocated short of where the player aimed.
local function drawGhostTarget(tx, ty, tz, weaponDef)
	glLineWidth(1)
	glColor(1, 1, 1, 0.25)
	DrawCircle(tx, ty, tz, weaponDef.damageAreaOfEffect)
	glColor(1, 1, 1, 1)
end

local function drawLine(x1, y1, z1, x2, y2, z2)
	glPushAttrib(GL.LINE_BITS)
	glLineStipple("springdefault")
	glDepthTest(false)
	glLineWidth(1)
	glColor(1, 0, 0, 1)
	glBeginEnd(GL.LINES, function()
		glVertex(x1, y1, z1)
		glVertex(x2, y2, z2)
	end)

	glColor(1, 1, 1, 1)
	glLineStipple(false)
	glPopAttrib()
end

--------------------------------------------------------------------------------
--------------------------------------------------------------------------------

local function getMouseTargetPosition()
	local mx, my = Spring.GetMouseState()
	local mouseTargetType, mouseTarget = Spring.TraceScreenRay(mx, my, false, true, false, true)

	if (mouseTargetType == "ground") then
		return mouseTarget[1], mouseTarget[2], mouseTarget[3], true
	elseif (mouseTargetType == "unit") then
		return Spring.GetUnitPosition(mouseTarget)
	elseif (mouseTargetType == "feature") then
		local _, coords = Spring.TraceScreenRay(mx, my, true, true, false, true)
		if coords and coords[3] then
			return coords[1], coords[2], coords[3], true
		else
			return Spring.GetFeaturePosition(mouseTarget)
		end
	else
		return nil
	end
end

-- Squared XZ distance -- shared engine utility rather than a hand-rolled copy.
local DistSq = Spring.Utilities.Vector.DistSq

--------------------------------------------------------------------------------
--------------------------------------------------------------------------------

local function missile_class()
	local self = {}

	self.cmdType = CMDTYPE.ICON_MAP

	function self:getOrderableUnits()
		local teamUnits = Spring.GetTeamUnits(Spring.GetMyTeamID()) or {}
		local units = {}

		for _, unitID in ipairs(teamUnits) do
			if self:canGiveOrder(unitID) then
				 units[#units + 1] = unitID
			 end
		 end

		return units
	 end

	function self:getNumberOfQueueLaunches(unit)
		local unitDefID = Spring.GetUnitDefID(unit)
		if not unitDefID then return 0 end

		local unitType = self.launchableTypes[unitDefID]
		if not unitType then return 0 end

		local numStockpiled = unitType.getStockpile(unit)
		if not numStockpiled or numStockpiled == 0 then return 0 end

		local cmdQueue = Spring.GetUnitCommands(unit, 100)
		if not cmdQueue then return 0 end

		local numQueued = 0
		for _, cmd in ipairs(cmdQueue) do
			if cmd and cmd.id == unitType.launchCmd then numQueued = numQueued + 1 end
		end

		return numQueued
	end

	function self:getCount()
		local count = 0
		for _, unit in ipairs(self:getOrderableUnits()) do
			if not Spring.GetUnitIsDead(unit) then
				local unitDefID = Spring.GetUnitDefID(unit)
				if unitDefID then
					local type = self.launchableTypes[unitDefID]
					if type then
						local stockpile = type.getStockpile(unit)
						if stockpile then
							count = count + stockpile - self:getNumberOfQueueLaunches(unit)
						end
					end
				end
			end
		end
		return count
	end

	function self:getMaxBuildProgress()
		local maxProgress = 0
		local allUnits = Spring.GetTeamUnits(Spring.GetMyTeamID()) or {}

		for _, unitID in ipairs(allUnits) do
			if not Spring.GetUnitIsDead(unitID) then
				local unitDefID = Spring.GetUnitDefID(unitID)
				if unitDefID and self.launchableTypes[unitDefID] then
					-- Silo-built missiles exist as nanoframes while under construction.
					local _, _, _, _, buildProgress = Spring.GetUnitHealth(unitID)
					if buildProgress and buildProgress < 1 then
						maxProgress = math.max(maxProgress, buildProgress)
					else
						-- Stockpiling weapons (Trinity, Reef, subtac) report progress toward
						-- the next missile via the "gadgetStockpile" rules param. Zero-K
						-- reimplements stockpiling in a gadget, so the engine's
						-- GetUnitStockpile build percent is pinned to 1 and unusable here.
						local stockpileProgress = Spring.GetUnitRulesParam(unitID, "gadgetStockpile")
						if stockpileProgress and stockpileProgress > 0 and stockpileProgress < 1 then
							maxProgress = math.max(maxProgress, stockpileProgress)
						end
					end
				end
			end
		end
		return maxProgress
	end

	function self:canGiveOrder(unit)
		local _, _, _, _, build = Spring.GetUnitHealth(unit)
		local type = self.launchableTypes[Spring.GetUnitDefID(unit)]
		if not type then return false end

		local count = type.getStockpile(unit)
				- self:getNumberOfQueueLaunches(unit)

		return build == 1 and count ~= 0
	end

	-- Whether this launcher's vlaunch arc is projected to slam into terrain (a hill in
	-- the way) short of the aim point, using the same trajectory model the Attack AoE
	-- widget draws. Non-vlaunch weapons report nil (never blocked), so this is a no-op
	-- for them. Fire origin is computed like drawWorld/Attack AoE so the three agree.
	function self:isShotBlocked(unit, params)
		if not (WG.AttackAoE and WG.AttackAoE.GetVlaunchImpact) then return false end

		local unitDefID = Spring.GetUnitDefID(unit)
		local type = self.launchableTypes[unitDefID]
		if not type then return false end

		local unitDef = UnitDefs[unitDefID]
		local weapon = unitDef and unitDef.weapons and unitDef.weapons[type.weaponId]
		if not weapon then return false end

		local _, _, _, ux, uy, uz = Spring.GetUnitPosition(unit, true)
		if not ux then return false end
		if unitDef.isImmobile then
			uy = uy + Spring.GetUnitRadius(unit)
		end

		local ty = Spring.GetGroundHeight(params.x, params.z) or 0
		local hx = WG.AttackAoE.GetVlaunchImpact(weapon.weaponDef, ux, uy, uz, params.x, ty, params.z)
		return hx ~= nil
	end

	function self:preferredUnit(unit1, unit2, params)
		local unit2x, _, unit2z = Spring.GetUnitPosition(unit2)
		if not unit2x then return unit1 end

		local type2 = self.launchableTypes[Spring.GetUnitDefID(unit2)]
		if not type2 then return unit1 end

		local unit2Dist = DistSq(params.x, params.z, unit2x, unit2z)
		local weaponDef2 = WeaponDefs[UnitDefs[Spring.GetUnitDefID(unit2)].weapons[type2.weaponId].weaponDef]
		if not weaponDef2 then return unit1 end

		local range = weaponDef2.range

		if unit2Dist > range * range then return unit1 end

		if not unit1 then return unit2 end

		local type1 = self.launchableTypes[Spring.GetUnitDefID(unit1)]
		if not type1 then return unit2 end

		local weaponDef1 = WeaponDefs[UnitDefs[Spring.GetUnitDefID(unit1)].weapons[type1.weaponId].weaponDef]
		if not weaponDef1 then return unit2 end

		-- A shot that actually lands outranks everything else, including an explicit
		-- selection: firing a silo whose arc slams into terrain short of the target is
		-- always a bad experience (the preview even shows the missile coming from there).
		-- If every candidate is blocked this tier is a wash and we fall through, so a
		-- launch is still issued (never silently no-ops).
		local blocked1 = self:isShotBlocked(unit1, params)
		local blocked2 = self:isShotBlocked(unit2, params)

		if blocked1 and not blocked2 then
			return unit2
		elseif blocked2 and not blocked1 then
			return unit1
		end

		local unit1Silo = Spring.GetUnitRulesParam(unit1, "missile_parentSilo")
		local unit1Selected = params.selectedUnits[unit1] or (unit1Silo and params.selectedUnits[unit1Silo])

		local unit2Silo = Spring.GetUnitRulesParam(unit2, "missile_parentSilo")
		local unit2Selected = params.selectedUnits[unit2] or (unit2Silo and params.selectedUnits[unit2Silo])

		if unit1Selected and not unit2Selected then
			return unit1
		elseif unit2Selected and not unit1Selected then
			return unit2
		end

		local queueDelta = self:getNumberOfQueueLaunches(unit1) - self:getNumberOfQueueLaunches(unit2)

		if queueDelta > 0 then
			return unit2
		elseif queueDelta < 0 then
			return unit1
		end

		local _, reloaded1, _ = Spring.GetUnitWeaponState(unit1, type1.weaponId)
		local _, reloaded2, _ = Spring.GetUnitWeaponState(unit2, type2.weaponId)

		if reloaded1 and not reloaded2 then
			return unit1
		elseif not reloaded1 and reloaded2 then
			return unit2
		end

		local unit1x, _, unit1z = Spring.GetUnitPosition(unit1)
		local unit1Dist = DistSq(params.x, params.z, unit1x, unit1z)

		local unit2x, _, unit2z = Spring.GetUnitPosition(unit2)
		local unit2Dist = DistSq(params.x, params.z, unit2x, unit2z)

		if unit1Dist < unit2Dist then
				return unit1
		end

		if unit2Dist < unit1Dist then
				return unit2
		end

		return unit1
	end


	function self:getPreferredUnit(params)
		local units = self:getOrderableUnits()

		params.selectedUnits = {}
		for _, unit in ipairs(Spring.GetSelectedUnits() or {}) do
			params.selectedUnits[unit] = true
		end

		local preferredUnit

		for _, unitID in ipairs(units) do
			if self:canGiveOrder(unitID) then
				 preferredUnit = self:preferredUnit(preferredUnit, unitID, params)
			end
		end

		return preferredUnit
	end

	function self:commandsChanged()
		local customCommands = widgetHandler.customCommands

		-- All fields must be present and valid, or the engine logs
		-- "GetLuaCmdDescList() bad entry" for the descriptor. name is also used by
		-- the integral menu to draw the stockpile count.
		customCommands[#customCommands+1] = {
			id       = self.cmd,
			type     = self.cmdType,
			name     = self.displayName or "",
			cursor   = 'Attack',
			action   = "missile_" .. self.name,
			texture  = "LuaUI/Images/commands/Bold/missile.png",
			tooltip  = "Launch missile.",
			disabled = self.disabled or false,
			hidden   = self.hidden or false,
			params   = {},
		}
	end

	function self:commandNotify(cmdID, cmdParams, cmdOptions)
		if cmdID == self.cmd then
			local x,y,z
			if #cmdParams == 1 then
				x,y,z = Spring.GetUnitPosition(cmdParams[1])
			else
				x,y,z = cmdParams[1], cmdParams[2], cmdParams[3]
			end
			local unit = self:getPreferredUnit{x = x, z = z}
			if not unit then return true end
			local unitType = self.launchableTypes[Spring.GetUnitDefID(unit)]
			if not unitType then return true end

			-- Insert after any launches already queued but before other orders (e.g.
			-- moves), so multiple shift-clicks fire in click order and still launch
			-- before the unit moves away.
			local insertPos = 0
			local cmdQueue = Spring.GetUnitCommands(unit, 100)
			if cmdQueue then
				for i = 1, #cmdQueue do
					if cmdQueue[i].id == unitType.launchCmd then
						insertPos = i
					else
						break
					end
				end
			end
			Spring.GiveOrderToUnit(unit, CMD.INSERT, {insertPos, unitType.launchCmd, CMD.OPT_SHIFT, unpack(cmdParams)}, CMD.OPT_ALT)
			return true
		end
	end

	function self:action(x, y, mouse)
		if self:getCount() == 0 then return end

		local cmdIndex = Spring.GetCmdDescIndex(self.cmd)
		if not cmdIndex then return end

		local left, right = true, false
		local alt, ctrl, meta, shift = Spring.GetModKeyState()
		Spring.SetActiveCommand(cmdIndex, 1, left, right, alt, ctrl, meta, shift)
	end

	-- Called only when this command is the active one (see widget:DrawWorld).
	function self:drawWorld()
		local mx, my, mz = getMouseTargetPosition()
		if not mx or not mz then return end
		local unit = self:getPreferredUnit{x = mx, z = mz}
		if not unit then return end

		local unitDefID = Spring.GetUnitDefID(unit)
		if not unitDefID then return end

		local unitType = self.launchableTypes[unitDefID]
		if not unitType then return end

		local unitDef = UnitDefs[unitDefID]
		if not unitDef or not unitDef.weapons then return end

		-- Fire origin computed the same way as the Attack AoE widget (aim midpoint,
		-- plus unit radius for immobile launchers) so both previews agree.
		local _, _, _, ux, uy, uz = Spring.GetUnitPosition(unit, true)
		if not ux then return end
		if unitDef.isImmobile then
			uy = uy + Spring.GetUnitRadius(unit)
		end

		local weapon = unitDef.weapons[unitType.weaponId]
		if not weapon then return end

		local weaponDef = WeaponDefs[weapon.weaponDef]
		if not weaponDef then return end

		local dist = DistSq(mx, mz, ux, uz)
		local range = weaponDef.range
		if dist > range * range then return end

		-- Relocate the impact to any terrain that blocks the shot, using the same
		-- trajectory model the Attack AoE widget uses when the missile is selected
		-- directly, so the two previews always agree.
		local ix, iy, iz = mx, my, mz
		local blocked = false
		if WG.AttackAoE and WG.AttackAoE.GetVlaunchImpact then
			local hx, hy, hz = WG.AttackAoE.GetVlaunchImpact(weapon.weaponDef, ux, uy, uz, mx, my, mz)
			if hx then
				ix, iy, iz, blocked = hx, hy, hz, true
			end
		end

		if blocked then
			drawGhostTarget(mx, my, mz, weaponDef)
		end
		drawBlastRadius(ix, iy, iz, weaponDef)
		drawLine(ux, uy, uz, ix, iy, iz)
	end


	return self
end

-- Silo-launched missiles (tacnuke, seismic, empmissile, napalmmissile,
-- missileslow) sit as a unit parked on their silo pad; one counts as stockpiled
-- while it exists and is still next to its silo.
local function siloMissileStockpile(unit)
	if Spring.GetUnitIsDead(unit) then return 0 end

	local silo = Spring.GetUnitRulesParam(unit, "missile_parentSilo")
	if not silo or Spring.GetUnitIsDead(silo) then return 0 end

	local x1, _, z1 = Spring.GetUnitPosition(silo)
	local x2, _, z2 = Spring.GetUnitPosition(unit)

	if not x1 or not x2 then return 0 end

	-- A missile counts as stockpiled only while it still sits on its silo's pad.
	if DistSq(x1, z1, x2, z2) > 600 then return 0 end

	return 1
end

--------------------------------------------------------------------------------
-- Controllers, built from the shared missile config (Configs/missile_config.lua)
-- so the missile types live in one data table instead of duplicated classes.
--------------------------------------------------------------------------------
local missileConfig = include("Configs/missile_config.lua")

local launchCmdByName = { ATTACK = CMD.ATTACK, MANUALFIRE = CMD.MANUALFIRE }
local stockpileByName = {
	silo = siloMissileStockpile,
	engine = function(unit) return Spring.GetUnitStockpile(unit) end,
}

-- Active launchableTypes for a config entry, honouring the Combine Eos and Scylla
-- option (launch entries flagged scope = "combine"/"separate").
local function buildLaunchableTypes(cfg, combined)
	local types = {}
	for _, l in ipairs(cfg.launch) do
		local active = true
		if l.scope == "combine" then
			active = combined
		elseif l.scope == "separate" then
			active = not combined
		end
		if active then
			local ud = UnitDefNames[l.unit]
			if ud then
				types[ud.id] = {
					launchCmd = launchCmdByName[l.cmd] or CMD.ATTACK,
					weaponId = l.weaponId,
					getStockpile = l.stockpile and stockpileByName[l.stockpile],
				}
			end
		end
	end
	return types
end

-- Zenith is a meteor controller, not a stockpiled missile: no count, "progress" is
-- meteors controlled / max (300), attacking rains meteors and we stop it after 3s for a
-- controlled burst. With several Zeniths the fullest is shown and preferred.
local pendingStops = {}             -- {unitID, frame}: stop each Zenith 3s after it attacks
local ZENITH_STOP_DELAY_FRAMES = 90 -- 3 seconds at 30 sim fps

local function zenithMeteors(unit)
	return Spring.GetUnitRulesParam(unit, "meteorsControlled") or 0
end

local function zenithMeteorsMax(unit)
	return Spring.GetUnitRulesParam(unit, "meteorsControlledMax") or 300
end

local function applyZenithBehaviour(self)
	self.hideCount = true

	function self:canGiveOrder(unit)
		if Spring.GetUnitIsDead(unit) then return false end
		if not self.launchableTypes[Spring.GetUnitDefID(unit)] then return false end
		local _, _, _, _, build = Spring.GetUnitHealth(unit)
		return build == 1
	end

	function self:getCount()   -- availability only; hideCount blanks the number
		local n = 0
		for _ in ipairs(self:getOrderableUnits()) do n = n + 1 end
		return n
	end

	function self:getMaxBuildProgress()   -- meteors of the fullest Zenith over its max
		local best = 0
		for _, unit in ipairs(self:getOrderableUnits()) do
			local ratio = zenithMeteors(unit) / zenithMeteorsMax(unit)
			if ratio > best then best = ratio end
		end
		return best
	end

	-- Prefer the Zenith controlling the most meteors; break ties by proximity.
	function self:preferredUnit(unit1, unit2, params)
		if not self:canGiveOrder(unit2) then return unit1 end
		if not unit1 then return unit2 end
		local m1, m2 = zenithMeteors(unit1), zenithMeteors(unit2)
		if m2 > m1 then return unit2 end
		if m1 > m2 then return unit1 end
		local u1x, _, u1z = Spring.GetUnitPosition(unit1)
		local u2x, _, u2z = Spring.GetUnitPosition(unit2)
		if not u1x then return unit2 end
		if not u2x then return unit1 end
		if DistSq(params.x, params.z, u2x, u2z) < DistSq(params.x, params.z, u1x, u1z) then
			return unit2
		end
		return unit1
	end

	-- Attack the target, then stop after 3s (a controlled meteor burst).
	function self:commandNotify(cmdID, cmdParams, cmdOptions)
		if cmdID ~= self.cmd then return end
		local x, y, z
		if #cmdParams == 1 then
			x, y, z = Spring.GetUnitPosition(cmdParams[1])
		else
			x, y, z = cmdParams[1], cmdParams[2], cmdParams[3]
		end
		if not x then return true end
		local unit = self:getPreferredUnit{x = x, z = z}
		if not unit then return true end
		Spring.GiveOrderToUnit(unit, CMD.ATTACK, {x, y, z}, 0)
		pendingStops[#pendingStops + 1] = {unitID = unit, frame = Spring.GetGameFrame() + ZENITH_STOP_DELAY_FRAMES}
		return true
	end

	function self:drawWorld()   -- no launch-arc preview for the meteor barrage
	end
end

-- Build one controller from a config entry.
local function buildController(cfg)
	local self = missile_class()
	self.key = cfg.key
	self.name = cfg.unit
	self.cmd = cfg.cmd
	self.cmdType = CMDTYPE[cfg.cmdType or "ICON_MAP"]
	self.config = cfg
	self.controllerScope = cfg.controllerScope
	self.launchableTypes = buildLaunchableTypes(cfg, false)

	if cfg.zenith then
		applyZenithBehaviour(self)
	end

	if cfg.siloBuild then
		local ud = UnitDefNames[cfg.siloBuild]
		self.siloBuilt = true
		self.buildDefID = ud and ud.id
		local realUD = self.buildDefID and UnitDefs[self.buildDefID]
		local weapon = realUD and realUD.weapons and realUD.weapons[1]
		local wd = weapon and WeaponDefs[weapon.weaponDef]
		self.buildRange = wd and wd.range
	end

	local unitDef = UnitDefNames[cfg.unit]
	self.iconTexture = unitDef and ("#" .. unitDef.id) or nil

	return self
end

local commands = {}          -- [key] = controller
local orderedCommands = {}   -- display order (from config)
for _, cfg in ipairs(missileConfig) do
	local controller = buildController(cfg)
	commands[cfg.key] = controller
	orderedCommands[#orderedCommands + 1] = controller
end

-- Arm the launch command of the first ready missile type, in badge order (used by
-- the core selector's launch button so a click immediately readies a shot). Only a
-- type with something ready to fire is picked; if nothing is ready, nothing is armed
-- (action() also guards on getCount, so a not-ready type is never selected).
WG.SelectDefaultMissile = function()
	for _, command in ipairs(orderedCommands) do
		if command:getCount() > 0 then
			command:action()
			return true
		end
	end
	return false
end

-- Unit defs whose creation/completion/destruction can change the launchable set
-- (the silo missiles and the units that hold them). Used to refresh immediately
-- on the relevant unit events instead of waiting for the next poll, so the
-- launch button appears promptly when a missile starts building.
local relevantUnitDefs = {}
for _, cfg in ipairs(missileConfig) do
	for _, l in ipairs(cfg.launch) do
		local ud = UnitDefNames[l.unit]
		if ud then relevantUnitDefs[ud.id] = true end
	end
end

local UPDATE_FREQUENCY = 0.25
local timer = UPDATE_FREQUENCY + 1
local wasEmptySelection = false

-- The launch command to re-arm on the next frame. The engine deactivates a command
-- once its order is issued (unless shift is held), so after firing we re-select it to
-- keep launch mode sticky -- but only while nothing else has taken over, so switching
-- to another command or closing the tab (both of which change the active command)
-- ends it naturally.
local reArmCmd = false

-- cmdID -> controller lookup, plus shift-edge state, used to keep launch mode sticky
-- across a shift-release (see Update). The engine keeps a shift-issued command active
-- only while shift is held and drops it on release; we re-arm it so releasing shift
-- behaves like the sticky no-shift fire.
local commandByCmd = {}
for _, command in pairs(commands) do
	commandByCmd[command.cmd] = command
end
local wasShift = false
local prevActiveMissileCommand = false

-- Tracks the Combine Eos and Scylla option so launchableTypes and the Scylla button's
-- visibility are rebuilt only when it changes (see refreshCombine in Update).
local lastCombined = nil

--------------------------------------------------------------------------------
-- Building missiles from the launch buttons
--------------------------------------------------------------------------------
-- The silo-built types can also be produced from the launcher: left-click the button
-- to arm the type as normal, then Alt+click the map to build one at the nearest silo
-- instead of launching. Plain left-click on the map still launches. Build is on Alt,
-- never plain left-click, so a missile finishing the instant you click can never turn
-- an intended build into an accidental launch.
local SILO_NAME = "staticmissilesilo"
local siloDefID = UnitDefNames[SILO_NAME] and UnitDefNames[SILO_NAME].id
local siloIconTexture = siloDefID and ("#" .. siloDefID)
local SILO_CAPACITY = 4   -- missile_silo_capacity in staticmissilesilo.lua
local SILO_SEARCH = 48    -- half-width of the pad scan (matches cmd_missile_silo)

local function getMyTeamSilos()
	local silos = {}
	if siloDefID then
		for _, unitID in ipairs(Spring.GetTeamUnits(Spring.GetMyTeamID()) or {}) do
			if Spring.GetUnitDefID(unitID) == siloDefID then
				silos[#silos + 1] = unitID
			end
		end
	end
	return silos
end

-- Missiles that have finished building on this silo's pads (build progress complete).
-- These occupy a pad and are not in the build queue any more.
local function siloFinishedCount(siloID, sx, sz)
	local finished = 0
	for _, mID in ipairs(Spring.GetUnitsInRectangle(sx - SILO_SEARCH, sz - SILO_SEARCH, sx + SILO_SEARCH, sz + SILO_SEARCH) or {}) do
		if Spring.GetUnitRulesParam(mID, "missile_parentSilo") == siloID then
			local _, _, _, _, buildProgress = Spring.GetUnitHealth(mID)
			if buildProgress and buildProgress >= 1 then
				finished = finished + 1
			end
		end
	end
	return finished
end

-- Total missiles queued at a silo (the currently building one plus anything waiting).
local function siloBuildQueueLength(siloID)
	local queue = Spring.GetFullBuildQueue(siloID)
	local n = 0
	if queue then
		for i = 1, #queue do
			local block = queue[i]
			if type(block) == "table" then
				for _, count in pairs(block) do
					n = n + count
				end
			end
		end
	end
	return n
end

-- Pick the nearest silo (to the Alt-click, else the screen centre) that still has spare
-- capacity: finished missiles on pads plus everything queued must be below the silo's
-- capacity. Returns siloID, sx, sz, or nil when every silo is full -- so a build is never
-- queued past capacity (which would produce a stuck, unusable missile).
local function chooseBuildSilo(refX, refZ)
	local cx, cz = refX, refZ
	if not cx then
		local vsx, vsy = Spring.GetViewGeometry()
		local _, coords = Spring.TraceScreenRay(vsx * 0.5, vsy * 0.5, true)
		cx, cz = coords and coords[1], coords and coords[3]
	end

	local bestSilo, bestD, bestX, bestZ
	for _, siloID in ipairs(getMyTeamSilos()) do
		local sx, _, sz = Spring.GetUnitPosition(siloID)
		if sx then
			local committed = siloFinishedCount(siloID, sx, sz) + siloBuildQueueLength(siloID)
			if committed < SILO_CAPACITY then
				local d = cx and ((sx - cx) * (sx - cx) + (sz - cz) * (sz - cz)) or 0
				if not bestD or d < bestD then
					bestSilo, bestD, bestX, bestZ = siloID, d, sx, sz
				end
			end
		end
	end
	return bestSilo, bestX, bestZ
end

-- Build one missile of this type at a silo near (refX, refZ) -- the Alt-click point,
-- so clicking near a silo builds there.
local function buildMissile(command, refX, refZ)
	if not (command.siloBuilt and command.buildDefID) then return end
	local silo = chooseBuildSilo(refX, refZ)
	if silo then
		-- No modifier queues exactly one; OPT_SHIFT would multiply the order x5.
		Spring.GiveOrderToUnit(silo, -command.buildDefID, {}, 0)
	end
end

-- True if the click that issued the armed launch is a build (Alt held), not a launch.
local function isBuildClick(cmdOptions)
	return cmdOptions and cmdOptions.alt
end

-- While a silo-built launch is armed and Alt is held, preview which silo will build the
-- missile (the one nearest the cursor) and that missile's range, so the player sees
-- where an Alt-click will produce it and how far it reaches.
local function drawBuildPreview()
	local _, activeCmd = Spring.GetActiveCommand()
	local command = activeCmd and commandByCmd[activeCmd]
	if not (command and command.siloBuilt) then return end
	local alt = Spring.GetModKeyState()
	if not alt then return end

	local mx, _, mz = getMouseTargetPosition()
	if not mx then return end

	local _, sx, sz = chooseBuildSilo(mx, mz)
	if not (sx and command.buildRange) then return end

	local sy = Spring.GetGroundHeight(sx, sz) or 0
	glDepthTest(false)
	glColor(0.3, 1, 0.3, 0.8)
	glLineWidth(2)
	glDrawGroundCircle(sx, sy, sz, 90, 32)                  -- the building silo
	glColor(0.3, 1, 0.3, 0.5)
	glLineWidth(1.5)
	glDrawGroundCircle(sx, sy, sz, command.buildRange, 64)  -- the missile's range
	glColor(1, 1, 1, 1)
	glLineWidth(1)
	glDepthTest(true)
end

--------------------------------------------------------------------------------
--------------------------------------------------------------------------------

function widget:CommandsChanged()
	for _, command in pairs(commands) do
		command:commandsChanged()
	end
end

-- Rebuild launchableTypes and Scylla's visibility when the Combine option changes.
local function refreshCombine()
	local combined = options.combineEosScylla.value
	if combined == lastCombined then
		return
	end
	lastCombined = combined
	for _, command in ipairs(orderedCommands) do
		command.launchableTypes = buildLaunchableTypes(command.config, combined)
		-- The Scylla button (separate-only) is hidden while Eos and Scylla are combined.
		command.hidden = (command.controllerScope == "separate" and combined)
	end
	-- Re-register commands so the descriptor hidden flags update.
	Spring.ForceLayoutUpdate()
end

function widget:Update(dt)
	refreshCombine()

	-- Stop each Zenith 3s after its attack order so a meteor barrage is a controlled
	-- burst. Checked every frame against the sim clock (so it is unaffected by pause).
	if pendingStops[1] then
		local frame = Spring.GetGameFrame()
		for i = #pendingStops, 1, -1 do
			if frame >= pendingStops[i].frame then
				if not Spring.GetUnitIsDead(pendingStops[i].unitID) then
					Spring.GiveOrderToUnit(pendingStops[i].unitID, CMD.STOP, {}, 0)
				end
				table.remove(pendingStops, i)
			end
		end
	end

	-- Keep launch mode sticky after a shot: re-arm the fired command unless something
	-- else is now active (the player switched command, or the tab closed and cleared
	-- it). Runs every frame, before the poll throttle, so there is no cursor flicker.
	if reArmCmd then
		local command = reArmCmd
		reArmCmd = false
		local _, activeCmd = Spring.GetActiveCommand()
		-- Re-arm if nothing else took over and the type is still usable: it has a missile
		-- ready to launch, or (silo-built) a silo exists so more can be Alt-built. Firing
		-- the last one of a launch-only type deselects naturally. This only fires after a
		-- deliberate launch (or shift-release), so it is kept even with units selected --
		-- the auto-arm-on-open is guarded separately in SelectDefaultMissile.
		local usable = command:getCount() > 0 or (command.siloBuilt and #getMyTeamSilos() > 0)
		if not activeCmd and usable then
			local cmdIndex = Spring.GetCmdDescIndex(command.cmd)
			if cmdIndex then
				local alt, ctrl, meta, shift = Spring.GetModKeyState()
				Spring.SetActiveCommand(cmdIndex, 1, true, false, alt, ctrl, meta, shift)
			end
		end
	end

	-- On the shift down->up edge, if a launch command was the active one, schedule a
	-- re-arm for next frame. The engine drops a shift-issued command when shift is
	-- released; re-arming keeps launch mode sticky. The re-arm above no-ops if the
	-- command is in fact still active (only shift was released, no shift-fire), so this
	-- only takes effect when the release actually deselected it.
	local _, activeCmd = Spring.GetActiveCommand()
	local activeMissileCommand = activeCmd and commandByCmd[activeCmd] or false
	local shift = select(4, Spring.GetModKeyState())
	if wasShift and not shift then
		local held = activeMissileCommand or prevActiveMissileCommand
		if held then
			reArmCmd = held
		end
	end
	prevActiveMissileCommand = activeMissileCommand
	wasShift = shift

	timer = timer + dt
	if timer < UPDATE_FREQUENCY then
		return
	end
	timer = 0

	local changed = false
	local activeIcons = {}

	-- Show the silo-built types (and thus the launcher) whenever a silo exists, even
	-- with no missiles, so the launcher can be used to build them.
	local hasSilo = (#getMyTeamSilos() > 0)

	for _, command in ipairs(orderedCommands) do
		local count = command:getCount()
		local buildProgress = command:getMaxBuildProgress()

		-- Only show a type when it has something ready or building. (When there is nothing
		-- to show at all, the silo icon is added below so the launcher still appears.)
		local include = (count >= 1 or buildProgress > 0)
		if command.iconTexture and include then
			-- Zenith carries no count (hideCount); its progress is meteors / max.
			local displayCount = command.hideCount and 0 or count
			activeIcons[#activeIcons + 1] = {icon = command.iconTexture, count = displayCount, progress = buildProgress}
		end

		-- Count string shown on the button (e.g. "x3"), empty when none stockpiled or
		-- when the type hides its count (Zenith). Drawn by the integral menu via the
		-- command's name field (see DRAW_NAME_COMMANDS / commandDisplayConfig.drawName).
		local displayName = ""
		if count > 0 and not command.hideCount then
			displayName = "x" .. count
		end

		-- Factory-style build progress bar on the button.
		if WG.IntegralMenu and WG.IntegralMenu.SetCommandProgress then
			WG.IntegralMenu.SetCommandProgress(command.cmd, buildProgress)
		end

		-- Keep silo-built types enabled while a silo exists so the type can be armed with
		-- nothing ready (a disabled button cannot be clicked), then Alt-clicked to build.
		local disabled = (count == 0) and not (command.siloBuilt and hasSilo)
		if command.displayName ~= displayName or command.disabled ~= disabled then
			command.displayName = displayName
			command.disabled = disabled
			changed = true
		end
	end

	-- Nothing ready or building, but a silo exists: show the silo itself so the launcher
	-- stays visible (and hints you can build missiles there). No count, no progress.
	if #activeIcons == 0 and hasSilo and siloIconTexture then
		activeIcons[1] = {icon = siloIconTexture, count = 0, progress = 0, isSilo = true}
	end

	-- Export active-missile icons for the tab badge.
	WG.missileActiveIcons = activeIcons

	-- The integral menu only re-reads custom commands on CommandsChanged, which
	-- the command menu pipeline does not run on its own while nothing is selected.
	-- Force a rebuild when the shown count/progress changed, or once when the
	-- selection first becomes empty, so the missiles tab stays available.
	local emptySelection = (Spring.GetSelectedUnitsCount() == 0)
	if changed or (emptySelection and not wasEmptySelection) then
		Spring.ForceLayoutUpdate()
	end
	wasEmptySelection = emptySelection
end

-- Run the next Update on the following frame rather than waiting out the poll
-- interval, so unit changes are reflected right away.
local function refreshSoon()
	timer = UPDATE_FREQUENCY
end

function widget:UnitCreated(unitID, unitDefID, unitTeam)
	if unitTeam == Spring.GetMyTeamID() and relevantUnitDefs[unitDefID] then
		refreshSoon()
	end
end

function widget:UnitFinished(unitID, unitDefID, unitTeam)
	if unitTeam == Spring.GetMyTeamID() and relevantUnitDefs[unitDefID] then
		refreshSoon()
	end
end

function widget:UnitDestroyed(unitID, unitDefID, unitTeam)
	if unitTeam == Spring.GetMyTeamID() and relevantUnitDefs[unitDefID] then
		refreshSoon()
	end
end

function widget:CommandNotify(cmdID, cmdParams, cmdOptions)
	-- Alt+click on the map with a silo-built type armed builds one (at the silo nearest
	-- the click) instead of launching. Keeps the type armed so you can keep building.
	local command = commandByCmd[cmdID]
	if command and command.siloBuilt and isBuildClick(cmdOptions) then
		local x, z
		if #cmdParams >= 3 then
			x, z = cmdParams[1], cmdParams[3]
		elseif #cmdParams == 1 then
			local ux, _, uz = Spring.GetUnitPosition(cmdParams[1])
			x, z = ux, uz
		end
		buildMissile(command, x, z)
		reArmCmd = command
		return true
	end

	-- Single table lookup instead of scanning every controller (the per-controller
	-- gate was just `cmdID == self.cmd`).
	if command and command:commandNotify(cmdID, cmdParams, cmdOptions) then
		-- Re-arm this launch command next frame so firing stays sticky without shift.
		reArmCmd = command
		return true
	end
end

-- Selecting units dismisses the launcher: stop the sticky re-arm and drop any armed
-- launch command, so the player's clicks act on their units instead of firing. Pressing
-- the launch selector and firing do not change the selection, so they are unaffected.
function widget:SelectionChanged(selectedUnits)
	if selectedUnits and #selectedUnits > 0 then
		reArmCmd = false
		local _, activeCmd = Spring.GetActiveCommand()
		if activeCmd and commandByCmd[activeCmd] then
			Spring.SetActiveCommand(nil)
		end
	end
end

-- Fully close the launcher: stop the sticky re-arm, drop any armed launch command,
-- and close the tab. Exposed so the core-selector launch button can toggle it closed.
local function dismissLauncher()
	reArmCmd = false
	local _, activeCmd = Spring.GetActiveCommand()
	if activeCmd and commandByCmd[activeCmd] then
		Spring.SetActiveCommand(nil)
	end
	if WG.IntegralMenu and WG.IntegralMenu.CloseHiddenTab then
		WG.IntegralMenu.CloseHiddenTab()
	end
end
WG.DismissLauncher = dismissLauncher

-- Right-click while the launcher is open closes it (and consumes the click, so it acts
-- purely as "close the launcher" rather than also issuing an order).
function widget:MousePress(mx, my, button)
	if button == 3 and WG.IntegralMenu and WG.IntegralMenu.IsHiddenTabOpen
			and WG.IntegralMenu.IsHiddenTabOpen("missiles") then
		dismissLauncher()
		return true
	end
	return false
end


function widget:DrawWorld()
	-- Only the active command draws its preview; look it up once instead of scanning
	-- every controller and calling GetActiveCommand in each.
	local _, activeCmd = Spring.GetActiveCommand()
	local command = activeCmd and commandByCmd[activeCmd]
	if command then
		command:drawWorld()
	end
	drawBuildPreview()
end

