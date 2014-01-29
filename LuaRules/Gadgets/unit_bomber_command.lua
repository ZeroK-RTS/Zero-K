------------------------------------------------------------------------------
-- HOW IT WORKS:
-- 	After firing, set ammo to 0 and look for a pad
--	Find first combat order and queue rearm order before it
--	If bomber idle and out of ammo (UnitIdle), give it rearm order
-- 	When bomber is in range of airpad (GameFrame), call GG.SendBomberToPad(bomberID, padID, padPiece)
--
--	See also: scripts/bombers.lua
--------------------------------------------------------------------------------
--------------------------------------------------------------------------------
-- TODO:
-- Handle planes waiting around if no airpads exist at all - send to pad once one is built
--------------------------------------------------------------------------------

function gadget:GetInfo()
  return {
    name      = "Aircraft Command",
    desc      = "Handles aircraft repair/rearm",
    author    = "xponen, KingRaptor",
    date      = "29 January 2014, 22 Jan 2011",
    license   = "GNU LGPL, v2.1 or later",
    layer     = 0,
    enabled   = true  --  loaded by default?
  }
end

--------------------------------------------------------------------------------
-- speedups
--------------------------------------------------------------------------------
local spGetUnitTeam		= Spring.GetUnitTeam
local spGetUnitAllyTeam	= Spring.GetUnitAllyTeam
local spGetUnitDefID	= Spring.GetUnitDefID
local spGetUnitIsDead	= Spring.GetUnitIsDead
local spGetUnitRulesParam	= Spring.GetUnitRulesParam

include "LuaRules/Configs/customcmds.h.lua"

local airpadDefs = {
	[UnitDefNames["factoryplane"].id] = {
		mobile = false, 
		cap = 1, 
		padPieceName={"land"}
	},
	[UnitDefNames["armasp"].id] = {
		mobile = false, 
		cap = 4, 
		padPieceName={"land1","land2","land3","land4"}
	},
	[UnitDefNames["armcarry"].id] = {
		mobile = true, 
		cap = 9, 
		padPieceName={"landpad1","landpad2","landpad3","landpad4","landpad5","landpad6","landpad7","landpad8","landpad9"}
	},
}

local bomberDefs = {}

if (gadgetHandler:IsSyncedCode()) then
--------------------------------------------------------------------------------
-- SYNCED
--------------------------------------------------------------------------------
local spGiveOrderToUnit = Spring.GiveOrderToUnit
local spGetUnitFuel		= Spring.GetUnitFuel
local spGetUnitsInBox	= Spring.GetUnitsInBox
local spGetUnitPieceMap = Spring.GetUnitPieceMap
local spGetUnitPosition = Spring.GetUnitPosition
local spGetUnitPiecePosition = Spring.GetUnitPiecePosition 
local spGetUnitVectors = Spring.GetUnitVectors

--------------------------------------------------------------------------------
-- config
--------------------------------------------------------------------------------
local combatCommands = {	-- commands that require ammo to execute
	[CMD.ATTACK] = true,
	[CMD.AREA_ATTACK] = true,
	[CMD.FIGHT] = true,
	[CMD.PATROL] = true,
	[CMD.GUARD] = true,
	[CMD.MANUALFIRE] = true,
}

local padRadius = 700 -- land if pad is within this range

--------------------------------------------------------------------------------
--------------------------------------------------------------------------------

local rearmCMD = {
    id      = CMD_REARM,
    name    = "Rearm",
    action  = "rearm",
	cursor  = 'Repair',
    type    = CMDTYPE.ICON_UNIT,
	tooltip = "Select an airpad to return to for rearm",
	hidden	= true,
}

local findPadCMD = {
    id      = CMD_FIND_PAD,
    name    = "Rearm",
    action  = "find_pad",
	cursor  = 'Repair',
    type    = CMDTYPE.ICON,
	tooltip = "Search for nearest available airpad to return to for rearm",
	hidden	= false,
}

local airpadsData = {}	-- stores data
local airpadsPerAllyteam = {}	-- [allyTeam] = {[pad1ID] = unitDefID1, [pad2ID] = unitDefID2, ..}
local bomberUnitIDs = {}
local bomberToPad = {}	-- [bomberID] = detination pad ID
local bomberToPad = {}
local bomberLanding = {} -- [bomberID] = true
local boolBomberDefs = {}
local rearmRequest = {} -- [bomberID] = true	(used to avoid recursion in UnitIdle)
local rearmRemove = {}

_G.airpadsData = airpadsData

function gadget:Initialize()
	for i=1,#UnitDefs do
		if UnitDefs[i].canFly then
			bomberDefs[i] = {}
			boolBomberDefs[i] = true
		end
	end
	local allyteams = Spring.GetAllyTeamList()
	for i=1,#allyteams do
		airpadsPerAllyteam[allyteams[i]] = {}
	end
	local unitList = Spring.GetAllUnits()
	for i=1,#(unitList) do
		local ud = spGetUnitDefID(unitList[i])
		local team = spGetUnitTeam(unitList[i])
		gadget:UnitCreated(unitList[i], ud, team)
		gadget:UnitFinished(unitList[i], ud, team)
	end
end

local function MakeOptsWithShift(cmdOpt)
	local opts = {"shift"} -- appending
	if (cmdOpt.alt)   then opts[#opts+1] = "alt"   end
	if (cmdOpt.ctrl)  then opts[#opts+1] = "ctrl"  end
	if (cmdOpt.right) then opts[#opts+1] = "right" end
	return opts
end

--[[
local function InsertCommandAfter(unitID, afterCmd, cmdID, params, opts)
	-- workaround for STOP not clearing attack order due to auto-attack
	-- we set it to hold fire temporarily, revert once commands have been reset
	local queue = Spring.GetUnitCommands(unitID)
	local firestate = Spring.GetUnitStates(unitID).firestate
	spGiveOrderToUnit(unitID, CMD.FIRE_STATE, {0}, {})
	spGiveOrderToUnit(unitID, CMD.STOP, {}, {})
	if queue then
		opts = opts or {}
		local i = 1
		local toInsert = nil
		local commands = #queue
		while i <= commands do
			
			if toInsert then
				spGiveOrderToUnit(unitID, cmdID, params, MakeOptsWithShift(opts))
				toInsert = false
			else
				local cmd = queue[i]
				spGiveOrderToUnit(unitID, cmd.id, cmd.params, MakeOptsWithShift(cmd.options))
				if cmd.id == afterCmd and toInsert == nil then
					toInsert = true
				end
				i = i + 1
			end
			--local cq = Spring.GetUnitCommands(unitID) for i = 1, #cq do Spring.Echo(cq[i].id) end
		end
		if toInsert then
			spGiveOrderToUnit(unitID, cmdID, params, MakeOptsWithShift(opts))
		end
	end
	spGiveOrderToUnit(unitID, CMD.FIRE_STATE, {firestate}, {})
end
--]]

local function InsertCommand(unitID, index, cmdID, params, opts)
	-- workaround for STOP not clearing attack order due to auto-attack
	-- we set it to hold fire temporarily, revert once commands have been reset
	local queue = Spring.GetUnitCommands(unitID)
	local firestate = Spring.GetUnitStates(unitID).firestate
	spGiveOrderToUnit(unitID, CMD.FIRE_STATE, {0}, {})
	spGiveOrderToUnit(unitID, CMD.STOP, {}, {})
	if queue then
		opts = opts or {}
		local i = 1
		local toInsert = (index >= 0)
		local commands = #queue
		while i <= commands do
			if i-1 == index and toInsert then
				spGiveOrderToUnit(unitID, cmdID, params, MakeOptsWithShift(opts))
				toInsert = false
			else
				local cmd = queue[i]
				spGiveOrderToUnit(unitID, cmd.id, cmd.params, MakeOptsWithShift(cmd.options))
				i = i + 1
			end
			--local cq = Spring.GetUnitCommands(unitID) for i = 1, #cq do Spring.Echo(cq[i].id) end
		end
		if toInsert or index < 0 then
			spGiveOrderToUnit(unitID, cmdID, params, MakeOptsWithShift(opts))
		end
	end
	spGiveOrderToUnit(unitID, CMD.FIRE_STATE, {firestate}, {})
end
GG.InsertCommand = InsertCommand

local function RefreshEmptyPad(airpadID,airpadDefID)
	if airpadDefs[airpadDefID] then
		local piecesList = spGetUnitPieceMap(airpadID)
		local padPieceName = airpadDefs[airpadDefID].padPieceName
		local ux,uy,uz = spGetUnitPosition(airpadID)
		local front, top, right = spGetUnitVectors(airpadID)
		airpadsData[airpadID].emptySpot = {}
		for i=1, airpadDefs[airpadDefID].cap do
			local padName = padPieceName[i]
			local pieceNum = piecesList[padName]
			local x,y,z = spGetUnitPiecePosition(airpadID, pieceNum)
			local offX = front[1]*z + top[1]*y + right[1]*x
			local offY = front[2]*z + top[2]*y + right[2]*x
			local offZ = front[3]*z + top[3]*y + right[3]*x
			local uxx,uyy,uzz = ux+offX, uy+offY, uz+offZ
			local somethingOnThePad = spGetUnitsInBox(uxx-20,uyy-20,uzz-20, uxx+20,uyy+20,uzz+20)
			local unit1 = somethingOnThePad[1]
			local unit2 = somethingOnThePad[2]
			if (#somethingOnThePad == 1 and unit1== airpadID) or 
			(#somethingOnThePad == 0) then
				airpadsData[airpadID].emptySpot[#airpadsData[airpadID].emptySpot+1] = pieceNum; --Spring.MarkerAddPoint(uxx,uyy,uzz, "O")
			end
		end
	end
end

local function RefreshEmptyspot_minusBomberLanding()
	for allyTeam in pairs(airpadsPerAllyteam) do --all airpads
		for airpadID,airpadUnitDefID in pairs (airpadsPerAllyteam[allyTeam]) do
			RefreshEmptyPad(airpadID,airpadUnitDefID)
		end
	end
	for bomberID,padpiece_padID in pairs(bomberLanding) do --airplane about to land
		local bomberAirpadID = padpiece_padID[2]
		for i=1, #airpadsData[bomberAirpadID].emptySpot do
			local padPiece = padpiece_padID[1]
			if airpadsData[bomberAirpadID].emptySpot[i]== padPiece then
				table.remove(airpadsData[bomberAirpadID].emptySpot,i)
				break
			end
		end
	end
end
local function FindNearestAirpad(unitID, team)
	--Spring.Echo(unitID.." checking for closest pad")
	local allyTeam = spGetUnitAllyTeam(unitID)
	local freePads = {}
	local freePadCount = 0
	if not airpadsPerAllyteam[allyTeam] then
		return
	end
	-- first go through all the pads to see which ones are unbooked
	for airpadID,airpadDefID in pairs(airpadsPerAllyteam[allyTeam]) do
		if not spGetUnitIsDead(airpadID) and 
		(airpadsData[airpadID].reservations.count < airpadsData[airpadID].cap) then
			freePads[airpadID] = true
			freePadCount = freePadCount + 1
		end
	end
	-- if no free pads, just use all of them
	if freePadCount == 0 then
		--Spring.Echo("No free pads, directing to closest one")
		freePads = airpadsPerAllyteam[allyTeam]
	end
	
	local minDist = 999999
	local closestPad
	for airpadID in pairs(freePads) do
		local excessReservation = math.max(0, airpadsData[airpadID].reservations.count - airpadsData[airpadID].cap)
		local dist = Spring.GetUnitSeparation(unitID, airpadID, true) or minDist
		dist = dist + 200*excessReservation
		if (dist < minDist) then
			minDist = dist
			closestPad = airpadID
		end
	end
	return closestPad
end

local function RequestRearm(unitID, team, forceNow)
	team = team or spGetUnitTeam(unitID)
	if spGetUnitRulesParam(unitID, "noammo") ~= 1 then
		local health, maxHealth = Spring.GetUnitHealth(unitID)
		if health and maxHealth and health > maxHealth - 1 then
			return
		end
	end
	--Spring.Echo(unitID.." requesting rearm")
	local queue = Spring.GetUnitCommands(unitID) or {}
	local index = #queue + 1
	for i=1, #queue do
		if combatCommands[queue[i].id] then
			index = i-1
			break
		elseif queue[i].id == CMD_REARM or queue[i].id == CMD_FIND_PAD then	-- already have manually set rearm point, we have nothing left to do here
			return
		end
	end
	if forceNow then
		index = 0
	end
	local targetPad = FindNearestAirpad(unitID, team)
	if targetPad then
		--Spring.Echo(unitID.." directed to airpad "..targetPad)
		InsertCommand(unitID, index, CMD_REARM, {targetPad})
		--spGiveOrderToUnit(unitID, CMD.INSERT, {index, CMD_REARM, 0, targetPad}, {"alt"})
		return targetPad
	end
end
GG.RequestRearm = RequestRearm

function gadget:UnitCreated(unitID, unitDefID, team)
	if bomberDefs[unitDefID] then
		Spring.InsertUnitCmdDesc(unitID, 400, rearmCMD)
		Spring.InsertUnitCmdDesc(unitID, 401, findPadCMD)
		bomberUnitIDs[unitID] = true
	end
	--[[
	local id = Spring.FindUnitCmdDesc(unitID, CMD.WAIT)
	local desc = Spring.GetUnitCmdDescs(unitID, id, id)
	for i,v in ipairs(desc) do
		if type(v) == "table" then
			for a,b in pairs(v) do
				Spring.Echo(a,b)
			end
		end
	end
	]]--
end

function gadget:UnitFinished(unitID, unitDefID, team)
	if airpadDefs[unitDefID] then
		--Spring.Echo("Adding unit "..unitID.." to airpad list")
		local allyTeam = spGetUnitAllyTeam(unitID)
		airpadsData[unitID] = Spring.Utilities.CopyTable(airpadDefs[unitDefID], true)
		airpadsData[unitID].reservations = {count = 0, units = {}}
		airpadsData[unitID].emptySpot = {}
		airpadsPerAllyteam[allyTeam][unitID] = unitDefID
	end
end

-- we don't need the airpad for now, free up a slot
local function CancelAirpadReservation(unitID)
	local targetPad = bomberToPad[unitID]
	if not targetPad then return end
	
	if GG.LandAborted then
		Spring.Echo("GG.LandAborted()")
		GG.LandAborted(unitID)
		spGiveOrderToUnit(unitID,CMD.WAIT, {}, {})
		spGiveOrderToUnit(unitID,CMD.WAIT, {}, {})
	end
	
	--Spring.Echo("Clearing reservation by "..unitID.." at pad "..targetPad)
	bomberToPad[unitID] = nil
	if not airpadsData[targetPad] then return end
	local reservations = airpadsData[targetPad].reservations
	if reservations.units[unitID] then
		reservations.units[unitID] = nil
		reservations.count = math.max(reservations.count - 1, 0)
	end
end

function gadget:UnitDestroyed(unitID, unitDefID, team)
	if airpadsData[unitID] then
		local allyTeam = spGetUnitAllyTeam(unitID)
		--Spring.Echo("Removing unit "..unitID.." from airpad list")
		airpadsPerAllyteam[allyTeam][unitID] = nil
		for bomberID in pairs(airpadsData[unitID].reservations.units) do
			CancelAirpadReservation(bomberID)	-- send anyone who was going here elsewhere
		end
		airpadsData[unitID] = nil
	elseif bomberDefs[unitDefID] then
		CancelAirpadReservation(unitID)
		bomberUnitIDs[unitID] = nil
		bomberLanding[unitID] = nil
	end
end

function gadget:UnitTaken(unitID, unitDefID, oldTeam, newTeam)
	gadget:UnitDestroyed(unitID, unitDefID, oldteam)
	gadget:UnitFinished(unitID, unitDefID, newTeam)
	gadget:UnitCreated(unitID, unitDefID, newTeam)
end

function gadget:GameFrame(n)
	-- track proximity to bombers
	if n%10 == 0 then
		for bomberID in pairs(rearmRequest) do
			RequestRearm(bomberID, nil, true)
		end
		rearmRequest = {}
		local airpadRefreshEmptyspot = nil;
		for bomberID, padID in pairs(bomberToPad) do
			local queue = Spring.GetUnitCommands(bomberID, 1)
			if (queue and queue[1] and queue[1].id == CMD_REARM) and (Spring.GetUnitSeparation(bomberID, padID, true) < padRadius) then
				if not airpadRefreshEmptyspot then
					RefreshEmptyspot_minusBomberLanding() --initialize empty pad count once
					airpadRefreshEmptyspot = true
				end
				local spotCount = #airpadsData[padID].emptySpot
				if spotCount>0 then
					local padPiece = airpadsData[padID].emptySpot[spotCount]
					table.remove(airpadsData[padID].emptySpot) --remove used spot
					if Spring.GetUnitStates(bomberID)["repeat"] then 
						InsertCommand(bomberID, 99999, CMD_REARM, {targetPad})
					end
					if GG.SendBomberToPad then
						GG.SendBomberToPad(bomberID, padID, padPiece)
					end
					spGiveOrderToUnit(bomberID,CMD.WAIT, {}, {})
					spGiveOrderToUnit(bomberID,CMD.WAIT, {}, {})
					bomberToPad[bomberID] = nil
					bomberLanding[bomberID] = {padPiece,padID}
					Spring.SetUnitRulesParam(bomberID, "noammo", 2)	-- refuelling
				end
			end
		end
		
		for unitID in pairs(bomberUnitIDs) do -- CommandFallback doesn't seem to activate for inbuilt commands!!!
			if spGetUnitRulesParam(unitID, "noammo") == 1 then
				local queue = Spring.GetUnitCommands(unitID, 1)
				if queue and #queue > 0 and combatCommands[queue[1].id] then
					RequestRearm(unitID, nil, true)
				end
			end
		end
	end
end

function GG.LandComplete(bomberID)
	Spring.Echo("GG.LandComplete()")
	bomberLanding[bomberID] = nil
	CancelAirpadReservation(bomberID)
	Spring.SetUnitRulesParam(bomberID, "noammo", 0)	-- ready to go
	spGiveOrderToUnit(bomberID,CMD.WAIT, {}, {})
	spGiveOrderToUnit(bomberID,CMD.WAIT, {}, {})
	bomberMaybeJiggling[bomberID] = nil
	rearmRemove[bomberID] = true --remove current RE-ARM command
end

function gadget:UnitIdle(unitID, unitDefID, team)
	if bomberDefs[unitDefID] and spGetUnitRulesParam(unitID, "noammo") == 1 then
		rearmRequest[unitID] = true
	end
end

--[[
function gadget:UnitCmdDone(unitID, unitDefID, team, cmdID, cmdTag)
	if bomberDefs[unitDefID] then RequestRearm(unitID) end
end
]]--

function gadget:CommandFallback(unitID, unitDefID, unitTeam, cmdID, cmdParams, cmdOptions)
	if cmdID == CMD_REARM then	-- return to pad
		if spGetUnitRulesParam(unitID, "noammo") == 2 then
			return true, true -- attempting to rearm while already rearming, abort
		end
		if rearmRemove[unitID] then
			rearmRemove[unitID] = nil
			return true, true
		end
		if bomberLanding[unitID] then
			return true, false --keep command while landing
		end
		--Spring.Echo("Returning to base")
		local targetPad = cmdParams[1]
		if not airpadsData[targetPad] then
			return true, true	-- trying to land on an unregistered (probably under construction) pad, abort
		end
		bomberToPad[unitID] = targetPad
		if not airpadsData[targetPad] then return false end
		local reservations = airpadsData[targetPad].reservations
		if not reservations.units[unitID] then
			reservations.units[unitID] = true
			reservations.count = reservations.count + 1
		end
		local x, y, z = Spring.GetUnitPosition(targetPad)
		Spring.SetUnitMoveGoal(unitID, x, y, z)
		return true, false	-- command used, don't remove
	elseif cmdID == CMD_FIND_PAD then
		rearmRequest[unitID] = true
		return true, true	-- command used, remove
	end
	return false -- command not used
end

function gadget:AllowCommand_GetWantedCommand()
	return true
end

function gadget:AllowCommand_GetWantedUnitDefID()
	return boolBomberDefs
end

function gadget:AllowCommand(unitID, unitDefID, unitTeam, cmdID, cmdParams, cmdOptions)
	if spGetUnitRulesParam(unitID, "noammo") ~= 1 then
		local health, maxHealth = Spring.GetUnitHealth(unitID)
		if ((cmdID == CMD_REARM or cmdID == CMD_FIND_PAD) and not cmdOptions.shift and health > maxHealth - 1) then -- don't allow rearming unless damaged or need ammo
			return false 
		end	
	else
		if combatCommands[cmdID] and not bomberDefs[unitDefID].noAutoRearm then	-- trying to fight without ammo, go get ammo first!
			rearmRequest[unitID] = true
		end
	end
	if bomberToPad[unitID] or bomberLanding[unitID] then
		if cmdID ~= CMD_REARM and not cmdOptions.shift then
			CancelAirpadReservation(unitID)
		end
	end
	return true
end

-- not worth the system resources until bombers using reverse built pads is fixed for real
--[[
function gadget:AllowUnitBuildStep(builderID, teamID, unitID, unitDefID, step) 
	if step < 0 and airpadsData[unitID] and select(5,Spring.GetUnitHealth(unitID)) == 1 then
		gadget:UnitDestroyed(unitID, unitDefID, teamID)
	end
	return true
end
]]--

else
--------------------------------------------------------------------------------
-- UNSYNCED
--------------------------------------------------------------------------------
local airpadsData = SYNCED.airpadsData
local spGetUnitAllyTeam = Spring.GetUnitAllyTeam
local spGetLocalTeamID = Spring.GetLocalTeamID
local spAreTeamsAllied = Spring.AreTeamsAllied
local spGetSpectatingState = Spring.GetSpectatingState
local spValidUnitID = Spring.ValidUnitID

function gadget:DefaultCommand(type, targetID)
	if (type == 'unit') then
		local targetTeam = spGetUnitTeam(targetID)
		local selfTeam = spGetLocalTeamID()
		if not (spAreTeamsAllied(targetTeam, selfTeam)) then
			return
		end

		local selUnits = Spring.GetSelectedUnits()
		if (not selUnits[1]) then
			return  -- no selected units
		end

		local unitID, unitDefID
		for i = 1, #selUnits do
			unitID    = selUnits[i]
			unitDefID = spGetUnitDefID(unitID)
			if bomberDefs[unitDefID] and airpadsData[targetID] then
				return CMD_REARM
			end
		end
		return
	end
end

--[[ widget
local noAmmoTexture = 'LuaUI/Images/noammo.png'

local function DrawUnitFunc(yshift)
	gl.Translate(0,yshift,0)
	gl.Billboard()
	gl.TexRect(-10, -10, 10, 10)
end

local phase = 0

function gadget:DrawWorld()
	if Spring.IsGUIHidden() then return end
	local myAllyID = Spring.GetMyAllyTeamID()
	local isSpec, fullView = spGetSpectatingState()

	gl.Texture(noAmmoTexture)
	local units = Spring.GetVisibleUnits()
	for i=1,#units do
		local id = units[i]
		if spValidUnitID(id) and bomberDefs[spGetUnitDefID(id)] and ((isSpec and fullView) or spGetUnitAllyTeam(id) == myAllyID) then
			local ammoState = spGetUnitRulesParam(id, "noammo") or 0
			if (ammoState ~= 0)  then
				gl.DrawFuncAtUnit(id, false, DrawUnitFunc, UnitDefs[spGetUnitDefID(id)].height + 30)
			end
		end
	end
	gl.Texture("")
end
--]]
function gadget:Initialize()
	gadgetHandler:RegisterCMDID(CMD_REARM)
	Spring.SetCustomCommandDrawData(CMD_REARM, "Repair", {0, 1, 1, 0.7})
	Spring.SetCustomCommandDrawData(CMD_FIND_PAD, "Guard", {0, 1, 1, 0.7})
end

end