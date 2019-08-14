-- $Id$
function widget:GetInfo()
	return {
		name = "Auto Repair",
		desc = "v0.8 Makes repairing units that are ordered into battle with combat units repair the combat units when they get damaged",
		author = "thesleepless",
		date = "Dec 29, 2008",
		license = "Public Domain",
		layer = 1,
		enabled = false
	}
end
--[[
Changelog:
	v0.8 KingRaptor:
		- use GameFrame() % 30 instead of Update()
	v0.7 CarRepairer:
		- Fixed so units don't autorepair if they are busy with something else.
		- Added leash so that builders return to where they were sitting when they began autorepairing if they stray too far.
		- Other small code fixes.
--]]
VFS.Include("LuaRules/Configs/customcmds.h.lua")

local repairUnits = {}
local idleRepairUnits = {}
local unitsToRepair = {}
local myTeam = nil
local leashLength = 300
local repairingUnits = {}

local spGetUnitDefID = Spring.GetUnitDefID
local spGetFullBuildQueue = Spring.GetFullBuildQueue
local spGetUnitHealth = Spring.GetUnitHealth
local spGetCommandQueue = Spring.GetCommandQueue
local spGetTeamUnits = Spring.GetTeamUnits
local spGiveOrderToUnit = Spring.GiveOrderToUnit
local spGetUnitPosition = Spring.GetUnitPosition
local spGetSelectedUnits = Spring.GetSelectedUnits

local function isIdleRepairer(unitID)
	local udef = spGetUnitDefID(unitID)
	local ud = UnitDefs[udef]
	if not ud.canRepair then
		return false
	end
	local _, _, _, _, buildProg = spGetUnitHealth(unitID)
	if buildProg < 1 then
		return false
	end
	
	return spGetCommandQueue(unitID, 0) == 0
end

local function findMyRepairUnits()
	local units = spGetTeamUnits(myTeam)
	local nRepairUnits = 0
	for k,unitID in pairs(units) do
		local ud = UnitDefs[spGetUnitDefID(unitID)]
		if(ud ~= nil and ud.canRepair and ud.canMove) then
			repairUnits[unitID] = true
			if(isIdleRepairer(unitID)) then
				idleRepairUnits[unitID] = true
			end
			nRepairUnits = nRepairUnits + 1
		end
	end
end

local function findMyDamagedUnits()
	local units = spGetTeamUnits(myTeam)
	for k,unitID in pairs(units) do
		local hp, maxhp, paradam, cap, build = spGetUnitHealth(unitID)
		if((hp and maxhp) and hp < maxhp) then
			unitsToRepair[unitID] = true
		end
	end
end

local function repairNearestDamagedUnit(repairUnitID)
	-- find the nearest damaged unit
	local posx, posy, posz = spGetUnitPosition(repairUnitID)
	if not posx then return end
	local closestDist = nil
	local closestDamagedUnit = nil
	for damagedUnitID, val in pairs(unitsToRepair) do
		-- can't repair self
		if(repairUnitID ~= damagedUnitID) then
			-- check they're still damaged
			local hp, maxhp, paradam, cap, build = spGetUnitHealth(damagedUnitID)
			if(not (hp and maxhp) or hp >= maxhp) then
				unitsToRepair[damagedUnitID] = nil
			else
				local uposx, uposy, uposz = spGetUnitPosition(damagedUnitID)
				-- get 2D distance between unit and repairUnit
				local dist = math.sqrt(math.pow(posx - uposx,2) + math.pow(posz - uposz,2))
				local ud = UnitDefs[spGetUnitDefID(repairUnitID)]
				if(dist < ud.buildDistance * 2.0 and (closestDist == nil or dist < closestDist)) then
					closestDist = dist
					closestDamagedUnit = damagedUnitID
				end
			end
		end
	end
	if(closestDamagedUnit) then
		repairingUnits[repairUnitID] = {posx, posy, posz}
		spGiveOrderToUnit(repairUnitID, CMD.INSERT, { 0, CMD.REPAIR, 0, closestDamagedUnit}, CMD.OPT_ALT )
		idleRepairUnits[repairUnitID] = nil
	end
end

local function distSqr(x1,y1,z1, x2, y2, z2)
	return (x2-x1)*(x2-x1) + (z2-z1)*(z2-z1)
end

function widget:Initialize()
	 if (Spring.GetSpectatingState() or Spring.IsReplay()) and (not Spring.IsCheatingEnabled()) then
		widgetHandler:RemoveWidget()
		return true
	end
	myTeam = Spring.GetMyTeamID()
	-- find all repair units and add them to repairUnits
	findMyRepairUnits()
	findMyDamagedUnits()
end

function widget:UnitCreated(unitID, unitDefID, unitTeam)
	local ud = UnitDefs[unitDefID]
	if(ud ~= nil and ud.canRepair) then
		repairUnits[unitID] = true
	end
end

function widget:UnitDestroyed(unitID, unitDefID, unitTeam)
	repairUnits[unitID] = nil
	unitsToRepair[unitID] = nil
end

function widget:CommandNotify(cmdID, cmdParams, cmdOptions)
	local selectedUnits = spGetSelectedUnits()
	for _, unitID in ipairs(selectedUnits) do
		repairingUnits[unitID] = nil
	end
end

function widget:GameFrame(n)
	if n%30 < 0.1 then
		for unitID, f in pairs(idleRepairUnits) do
			repairNearestDamagedUnit(unitID)
		end
		for unitID, pos in pairs(repairingUnits) do
			local posx, posy, posz = spGetUnitPosition(unitID)
			if posx then
				if distSqr(pos[1], pos[2], pos[3], posx, posy, posz) > leashLength*leashLength then
					spGiveOrderToUnit(unitID, CMD_RAW_MOVE, pos, 0)
				end
			end
		end
	end
end

function widget:UnitCmdDone(unitID, unitDefID, unitTeam, cmdID, cmdTag)
	if(repairUnits[unitID] == nil) then
		return true
	end
	if(isIdleRepairer(unitID)) then
		idleRepairUnits[unitID] = true
	else
		idleRepairUnits[unitID] = nil
	end
	return true
end

function widget:UnitDamaged(unitID, unitDefID, unitTeam, damage, paralyzer)
	if(paralyzer) then
		-- can't repair paralyzer damage...
		return
	end
	if(unitTeam ~= myTeam) then
		-- don't care about other team's units
		return
	end
	local hp, maxhp = spGetUnitHealth(unitID)
	if(hp and maxhp and hp < maxhp) then
		unitsToRepair[unitID] = true
	end
end

