function widget:GetInfo()
	return {
		name      = "Missile Silo Commands",
		desc      = "Okay, take a nap. THEN FIRE ZE MISSILES!",
		author    = "Histidine",
		date      = "2018-05-12",
		license   = "GNU GPL, v2 or later",
		layer     = 0,
		enabled   = true,
		--alwaysStart = true,
		handler   = true,
	}
end

--------------------------------------------------------------------------------
--------------------------------------------------------------------------------

VFS.Include("LuaRules/Configs/customcmds.h.lua")

local siloDefID = UnitDefNames.staticmissilesilo.id
local missileDefIDs = {}
local missileNames = {"tacnuke", "seismic", "empmissile", "napalmmissile"}

for i=1,#missileNames do
  if UnitDefNames[missileNames[i]] then
	missileDefIDs[UnitDefNames[missileNames[i]].id] = true
  end
end

local selectMissilesCmdDesc = {
	id      = CMD_SELECT_MISSILES,
	type    = CMDTYPE.ICON,
	name    = 'Select Missiles',
	action  = 'selectmissiles',
	tooltip = "Select this silo's missiles.",
	texture = "LuaUI/Images/Commands/Bold/missile.png",
	params  = {}
}

local SEARCH_RANGE = 48
--local FIRE_INTERVAL = 90	-- gameframes
local UPDATE_INTERVAL = 10
local EMPTY_TABLE = {}

--------------------------------------------------------------------------------
--------------------------------------------------------------------------------
local silos = {}	-- [unitID] = frames before next shot allowed

local function GetMissiles(siloID, justOne)
	local missiles = {}
	local count = 0
	local oldest, oldestFrame = nil, 999999
	
	local x, y, z = Spring.GetUnitPosition(siloID)
	local units = Spring.GetUnitsInRectangle(x - SEARCH_RANGE, z - SEARCH_RANGE, x + SEARCH_RANGE, z + SEARCH_RANGE)
	
	for i=1,#units do
		local unitID = units[i]
		local buildProgress = select(5, Spring.GetUnitHealth(unitID))
		if Spring.GetUnitRulesParam(unitID, "missile_parentSilo") == siloID
			and Spring.GetUnitRulesParam(unitID, "do_not_save") ~= 1 then	-- not already launched
			if justOne and buildProgress == 1 then
				local spawnedFrame = Spring.GetUnitRulesParam(unitID, "missile_spawnedFrame") or 999998
				if spawnedFrame < oldestFrame then
					oldest = unitID
					oldestFrame = spawnedFrame
				end
			end
			
			missiles[#missiles + 1] = unitID
			count = count + 1
		end
	end
	
	if justOne then
		return oldest
	end
	return missiles, count
end

local function IsWaiting(unitID)
	local cmd = Spring.GetFactoryCommands(unitID, 1)[1]
	return cmd and cmd.id == CMD.WAIT
end

local function RemoveAttackCommandIfFirst(unitID)
	local states = Spring.GetUnitStates(unitID) or EMPTY_TABLE
	local rpt = states["repeat"]
	
	local cmd = Spring.GetCommandQueue(unitID, 1)[1]
	if (not cmd) or (cmd.id ~= CMD.ATTACK) then
		return
	end
	
	Spring.GiveOrderToUnit(unitID, CMD.REMOVE, {cmd.tag}, 0)
	if rpt then
		Spring.GiveOrderToUnit(unitID, CMD.ATTACK, cmd.params, CMD.OPT_SHIFT)
	end
end

local function FireOneMissileAtSiloTarget(siloID, cmdParams)
	if not siloID then
		return
	end
	
	if IsWaiting(siloID) then
		return
	end
	
	local missile = GetMissiles(siloID, true)
	if not missile then
		return
	end
	
	Spring.GiveOrderToUnit(missile, CMD.ATTACK, cmdParams, 0)
	--silos[siloID] = FIRE_INTERVAL
	
	RemoveAttackCommandIfFirst(siloID)
end

local function FireMissileCheck(siloID)
	if not siloID then
		return
	end
	
	local cmd = Spring.GetCommandQueue(siloID, 1)[1]
	if (not cmd) or (cmd.id ~= CMD.ATTACK) then
		return
	end
	
	FireOneMissileAtSiloTarget(siloID, cmd.params)
end

--------------------------------------------------------------------------------
--------------------------------------------------------------------------------
function widget:UnitFromFactory(unitID, unitDefID, unitTeam, factID, factDefID, userOrders)
	if silos[factID] then
		RemoveAttackCommandIfFirst(factID)	-- missile launched fresh from silo
	end
end

--[[
function widget:UnitCommand(unitID, unitDefID, teamID, cmdID, cmdParams, cmdOptions)
	if cmdID == CMD.ATTACK then
		--FireOneMissileAtSiloTarget(unitID, cmdParams)
	end
end
]]--

function widget:CommandNotify(cmdID, params, options)
	if cmdID ~= CMD_SELECT_MISSILES then
		return false
	end
	
	local selected = Spring.GetSelectedUnitsSorted()
	if not selected[siloDefID] then
		return true
	end
	
	local toSelect = toSelect or {}
	for i=1,#selected[siloDefID] do
		local unitID = selected[siloDefID][i]
		local x, y, z = Spring.GetUnitPosition(unitID)
		local missiles = GetMissiles(unitID)
		for i=1,#missiles do
			toSelect[#toSelect + 1] = missiles[i]
		end
	end
	if #toSelect > 0 then
		local alt, ctrl, meta, shift = Spring.GetModKeyState()
		Spring.SelectUnitArray(toSelect, shift)
	end
	
	return true
end

-- add missile selection command
function widget:CommandsChanged()
	local selectedUnits = Spring.GetSelectedUnits()
	local unitID = selectedUnits and selectedUnits[1]
	local unitDefID = unitID and Spring.GetUnitDefID(unitID)
	if unitDefID == siloDefID then
	  local customCommands = widgetHandler.customCommands
	  table.insert(customCommands, selectMissilesCmdDesc)
	end
end

function widget:UnitCreated(unitID, unitDefID, unitTeam)
	if unitDefID == siloDefID and unitTeam == Spring.GetMyTeamID() then
		silos[unitID] = true	--0
	end
end

function widget:UnitDestroyed(unitID, unitDefID, unitTeam)
	silos[unitID] = nil
end

function widget:UnitGiven(unitID, unitDefID, unitTeam, oldTeam)
	silos[unitID] = nil
	widget:UnitCreated(unitID, unitDefID, unitTeam)
end

function widget:GameFrame(n)
	if n % UPDATE_INTERVAL == 7 then
		for unitID, timer in pairs(silos) do
			--if timer > 0 then
			--	timer = timer - UPDATE_INTERVAL
			--	silos[unitID] = timer
			--end
			--if timer <= 0 then
				FireMissileCheck(unitID)
			--end
		end
	end
end

function widget:Initialize()
	for i,unitID in ipairs(Spring.GetAllUnits()) do
		local unitDefID = Spring.GetUnitDefID(unitID)
		local unitTeam = Spring.GetUnitTeam(unitID)
		widget:UnitCreated(unitID, unitDefID, unitTeam)
	end
end

--------------------------------------------------------------------------------
--------------------------------------------------------------------------------
