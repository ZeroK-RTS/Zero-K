-- $Id: unit_morph.lua 4651 2009-05-23 17:04:46Z carrepairer $
--------------------------------------------------------------------------------
--------------------------------------------------------------------------------
--
--	file:   unit_morph.lua
--	brief:  Adds unit morphing command
--	author: Dave Rodgers (improved by jK, Licho and aegis)
--
--	Copyright (C) 2007.
--	Licensed under the terms of the GNU GPL, v2 or later.
--
--------------------------------------------------------------------------------
--------------------------------------------------------------------------------

function gadget:GetInfo()
	return {
		name     = "UnitMorph",
		desc     = "Adds unit morphing",
		author   = "trepan (improved by jK, Licho, aegis, CarRepairer, Aquanim)",
		date     = "Jan, 2008",
		license  = "GNU GPL, v2 or later",
		layer    = -1, --must start after unit_priority.lua gadget to use GG.AddMiscPriority()
		enabled  = true
	}
end

include("LuaRules/Configs/customcmds.h.lua")

local SAVE_FILE = "Gadgets/unit_morph.lua"
local emptyTable = {} -- for speedups
--------------------------------------------------------------------------------
--------------------------------------------------------------------------------
--
-- Interface with other gadgets:
--
--
-- During Initialize() this morph gadget creates a global table, GG.MorphInfo, from which you can read:
--
-- GG.MorphInfo[unitDefId] -- nil if for units that can't morph, otherwise a table, of key=destinationUnitDefId, value=morphCmdId
--
-- GG.MorphInfo["MAX_MORPH"] -- the number of morph handled
--
-- GG.MorphInfo["CMD_MORPH_BASE_ID"] -- The CMD ID of the generic morph command
-- GG.MorphInfo["CMD_MORPH_BASE_ID"]+1 -- The CMD ID of the first specific morph command
-- GG.MorphInfo["CMD_MORPH_BASE_ID"]+GG.MorphInfo["MAX_MORPH"] -- The CMD ID of the last specific morph command
--
-- GG.MorphInfo["CMD_MORPH_STOP_BASE_ID"] -- The CMD ID of the generic morph stop command
-- GG.MorphInfo["CMD_MORPH_STOP_BASE_ID"]+1 -- The CMD ID of the first specific morph stop command
-- GG.MorphInfo["CMD_MORPH_STOP_BASE_ID"]+GG.MorphInfo["MAX_MORPH"] -- The CMD ID of the last specific morph stop command
--
-- Thus other gadgets can know which morphing commands are available
-- Then they can simply issue:
--	Spring.GiveOrderToUnit(u,genericMorphCmdID,{}, 0)
-- or Spring.GiveOrderToUnit(u,genericMorphCmdID,{targetUnitDefId}, 0)
-- or Spring.GiveOrderToUnit(u,specificMorphCmdID,{}, 0)
--
-- where:
-- genericMorphCmdID is the same unique value, no matter what is the source unit or target unit
-- specificMorphCmdID is a different value for each source<->target morphing pair
--

--[[ Sample codes that could be used in other gadgets:

	-- Morph unit u
	Spring.GiveOrderToUnit(u,31210,{}, 0)

	-- Morph unit u into a supertank:
	local otherDefId=UnitDefNames["supertank"].id
	Spring.GiveOrderToUnit(u,31210,{otherDefId}, 0)

	-- In place of writing 31210 you could use a morphCmdID that you'd read with:
	local morphCmdID=(GG.MorphInfo or {})["CMD_MORPH_BASE_ID"]
	if not morphCmdID then
		Spring.Echo("Error! Can't find Morph Cmd ID!"")
		return
	end

	-- Print all the morphing possibilities:
	for src,morph in pairs(GG.MorphInfo) do
		if type(src) == "number" then
			local txt=UnitDefs[src].name.." may morph into "
			for dst,cmd in pairs(morph) do
			txt=txt..UnitDefs[src].name.." with CMD "..cmd
			end
			Spring.Echo(txt)
		end
	end

]]--

local MAX_MORPH = 0 -- Set in morph defs

--------------------------------------------------------------------------------
--	COMMON
--------------------------------------------------------------------------------

local function isFactory(UnitDefID)
	return UnitDefs[UnitDefID].isFactory or false
end

local function isFinished(UnitID)
	local _,_,_,_,buildProgress = Spring.GetUnitHealth(UnitID)
	return (buildProgress == nil) or (buildProgress >= 1)
end

local function HeadingToFacing(heading)
	return math.floor((heading + 8192) / 16384) % 4
end

--------------------------------------------------------------------------------
--------------------------------------------------------------------------------

if (gadgetHandler:IsSyncedCode()) then
--------------------------------------------------------------------------------
--	SYNCED
--------------------------------------------------------------------------------

include("LuaRules/colors.h.lua")
local spGetUnitPosition = Spring.GetUnitPosition

--------------------------------------------------------------------------------
--------------------------------------------------------------------------------

local stopPenalty = 0.667
local freeMorph = false

local PRIVATE = {private = true}

--------------------------------------------------------------------------------
--------------------------------------------------------------------------------

local morphDefs	= {} --// make it global in Initialize()
local extraUnitMorphDefs = {} -- stores mainly planetwars morphs
local hostName = nil -- planetwars hostname
local PWUnits = {} -- planetwars units
local morphUnits = {} --// make it global in Initialize(); needs save/load
local reqDefIDs	= {} --// all possible unitDefID's, which are used as a requirement for a morph
local morphToStart = {} -- morphs to start next frame

GG.wasMorphedTo = {} -- when a unit finishes morphing, a mapping of old unitID to new unitID is recorded here prior to old unit destruction

local morphCmdDesc = {
	--id	 = CMD_MORPH, -- added by the calling function because there is now more than one option
	type   = CMDTYPE.ICON,
	name   = 'Morph',
	cursor = 'Morph',	-- add with LuaUI?
	action = 'morph',
}

local stopUpgradeCmdDesc = {
	id      = CMD_UPGRADE_STOP,
	type    = CMDTYPE.ICON,
	name    = "",
	action  = 'upgradecommstop',
	cursor  = 'Morph',
	tooltip	= 'Stop commander upgrade.',
}

--------------------------------------------------------------------------------
--------------------------------------------------------------------------------
--------------------------------------------------------------------------------

local function AddMorphCmdDesc(unitID, unitDefID, teamID, morphDef, teamTech)
	if GG.Unlocks and not GG.Unlocks.GetIsUnitUnlocked(teamID, morphDef.into) then
		return
	end
	
	morphCmdDesc.tooltip = morphDef.tooltip
	
	GG.AddMiscPriorityUnit(unitID)
	if morphDef.texture then
		morphCmdDesc.texture = "LuaRules/Images/Morph/".. morphDef.texture
		morphCmdDesc.name = ''
	else
		morphCmdDesc.texture = "#" .. morphDef.into	 --//only works with a patched layout.lua or the TweakedLayout widget!
	end

	morphCmdDesc.id = morphDef.cmd

	local cmdDescID = Spring.FindUnitCmdDesc(unitID, morphDef.cmd)
	if (cmdDescID) then
		Spring.EditUnitCmdDesc(unitID, cmdDescID, morphCmdDesc)
	else
		Spring.InsertUnitCmdDesc(unitID, morphCmdDesc)
	end

	morphCmdDesc.tooltip = nil
	morphCmdDesc.texture = nil
	morphCmdDesc.text = nil
end

--------------------------------------------------------------------------------
--------------------------------------------------------------------------------
-- This function is terrible. The data structure of commands does not lend itself to a fundamentally nicer system though.

local unitTargetCommand = {
	[CMD.GUARD] = true,
	[CMD_ORBIT] = true,
}

local singleParamUnitTargetCommand = {
	[CMD.REPAIR] = true,
	[CMD.ATTACK] = true,
}

local function ReAssignAssists(newUnit,oldUnit)
	local allUnits = Spring.GetAllUnits(newUnit)
	for i = 1, #allUnits do
		local unitID = allUnits[i]
		
		if GG.GetUnitTarget(unitID) == oldUnit then
			GG.SetUnitTarget(unitID, newUnit)
		end
		
		local cmds = Spring.GetCommandQueue(unitID, -1)
		for j = 1, #cmds do
			local cmd = cmds[j]
			local params = cmd.params
			if (unitTargetCommand[cmd.id] or (singleParamUnitTargetCommand[cmd.id] and #params == 1)) and (params[1] == oldUnit) then
				params[1] = newUnit
				local opts = (cmd.options.meta and CMD.OPT_META or 0) + (cmd.options.ctrl and CMD.OPT_CTRL or 0) + (cmd.options.alt and CMD.OPT_ALT or 0)
				Spring.GiveOrderToUnit(unitID, CMD.INSERT, {cmd.tag, cmd.id, opts, params[1], params[2], params[3]}, 0)
				Spring.GiveOrderToUnit(unitID, CMD.REMOVE, {cmd.tag}, 0)
			end
		end
	end
end

--------------------------------------------------------------------------------
--------------------------------------------------------------------------------

local function GetMorphRate(unitID)
	return (Spring.GetUnitRulesParam(unitID,"baseSpeedMult") or 1)
end

local function StartMorph(unitID, unitDefID, teamID, morphDef)
	-- do not allow morph for unfinsihed units
	if not isFinished(unitID) then
		return false
	end
	
	-- do not allow morph for units being transported which are not combat morphs
	if Spring.GetUnitTransporter(unitID) and not morphDef.combatMorph then
		return false
	end
	
	Spring.SetUnitRulesParam(unitID, "morphing", 1)

	if not morphDef.combatMorph then
		Spring.SetUnitRulesParam(unitID, "morphDisable", 1)
		GG.UpdateUnitAttributes(unitID)
		local env = Spring.UnitScript.GetScriptEnv(unitID)
		if env and env.script.StopMoving then
			Spring.UnitScript.CallAsUnit(unitID,env.script.StopMoving, hx, hy, hz)
		end
	end

	morphUnits[unitID] = {
		def = morphDef,
		progress = 0.0,
		increment = morphDef.increment,
		morphID = morphID,
		teamID = teamID,
		combatMorph = morphDef.combatMorph,
		morphRate = 0.0,
	}
	
	if morphDef.cmd then
		local cmdDescID = Spring.FindUnitCmdDesc(unitID, morphDef.cmd)
		if (cmdDescID) then
			Spring.EditUnitCmdDesc(unitID, cmdDescID, {id = morphDef.stopCmd, name = RedStr .. "Stop"})
		end
	elseif morphDef.stopCmd == CMD_UPGRADE_STOP then
		Spring.InsertUnitCmdDesc(unitID, stopUpgradeCmdDesc)
	end

	SendToUnsynced("unit_morph_start", unitID, unitDefID, morphDef.cmd)
	
	local newMorphRate = GetMorphRate(unitID)
	GG.StartMiscPriorityResourcing(unitID, (newMorphRate*morphDef.metal/morphDef.time), nil, 2) --is using unit_priority.lua gadget to handle morph priority. Note: use metal per second as buildspeed (like regular constructor), modified for slow
	morphUnits[unitID].morphRate = newMorphRate
	return true
end

function gadget:UnitTaken(unitID, unitDefID, oldTeamID, newTeamID)
	local morphData = morphUnits[unitID]
	if not morphData then
		return
	end
	GG.StopMiscPriorityResourcing(unitID, 2)
	morphData.teamID = newTeamID
	GG.StartMiscPriorityResourcing(unitID, (morphData.def.metal / morphData.def.time), false, 2)
end

local function StopMorph(unitID, morphData)
	GG.StopMiscPriorityResourcing(unitID, 2) --is using unit_priority.lua gadget to handle morph priority.
	morphUnits[unitID] = nil
	if not morphData.combatMorph then
		Spring.SetUnitRulesParam(unitID, "morphDisable", 0)
		GG.UpdateUnitAttributes(unitID)
	end
	Spring.SetUnitRulesParam(unitID, "morphing", 0)
	local scale = morphData.progress * stopPenalty
	local unitDefID = Spring.GetUnitDefID(unitID)

	Spring.SetUnitResourcing(unitID,"e", UnitDefs[unitDefID].energyMake)
	local usedMetal	= morphData.def.metal	* scale
	Spring.AddUnitResource(unitID, 'metal',	usedMetal)
	--local usedEnergy = morphData.def.energy * scale
	--Spring.AddUnitResource(unitID, 'energy', usedEnergy)

	SendToUnsynced("unit_morph_stop", unitID)

	if morphData.def.cmd then
		local cmdDescID = Spring.FindUnitCmdDesc(unitID, morphData.def.stopCmd)
		if (cmdDescID) then
			Spring.EditUnitCmdDesc(unitID, cmdDescID, {id = morphData.def.cmd, name = morphCmdDesc.name})
		end
	elseif morphData.def.stopCmd == CMD_UPGRADE_STOP then
		local cmdDescID = Spring.FindUnitCmdDesc(unitID, CMD_UPGRADE_STOP)
		if cmdDescID then
			Spring.RemoveUnitCmdDesc(unitID, cmdDescID)
		end
	end
end

local function CreateMorphedToUnit(defName, x, y, z, face, unitTeam, isBeingBuilt, upgradeDef)
	if upgradeDef and GG.Upgrades_CreateUpgradedUnit then
		return GG.Upgrades_CreateUpgradedUnit(defName, x, y, z, face, unitTeam, isBeingBuilt, upgradeDef)
	else
		return Spring.CreateUnit(defName, x, y, z, face, unitTeam, isBeingBuilt)
	end
end

local function FinishMorph(unitID, morphData)
	local udDst = UnitDefs[morphData.def.into]
	local unitDefID = Spring.GetUnitDefID(unitID)
	local ud = UnitDefs[unitDefID]
	local defName = udDst.name
	local unitTeam = morphData.teamID
	-- copy dominatrix stuff
	local originTeam, originAllyTeam, controllerID, controllerAllyTeam = GG.Capture.GetMastermind(unitID)
	
	-- you see, Anarchid's exploit is fixed this way
	if (originTeam ~= nil) and (Spring.ValidUnitID(controllerID)) then
		unitTeam = Spring.GetUnitTeam(controllerID)
	end
	
	local px, py, pz = spGetUnitPosition(unitID)
	local h = Spring.GetUnitHeading(unitID)
	Spring.SetUnitBlocking(unitID, false)
	morphUnits[unitID] = nil

	--// copy health
	local oldHealth,oldMaxHealth,paralyzeDamage,captureProgress,buildProgress = Spring.GetUnitHealth(unitID)

	local isBeingBuilt = false
	if buildProgress < 1 then
		isBeingBuilt = true
	end
	
	local newUnit

	if udDst.isImmobile then
		local x = math.floor(px/16)*16
		local y = py
		local z = math.floor(pz/16)*16
		local face = HeadingToFacing(h)
		local xsize = udDst.xsize
		local zsize =(udDst.zsize or udDst.ysize)
		if ((face == 1) or(face == 3)) then
			xsize, zsize = zsize, xsize
		end
		if xsize/4 ~= math.floor(xsize/4) then
			x = x+8
		end
		if zsize/4 ~= math.floor(zsize/4) then
			z = z+8
		end
		Spring.SetTeamRulesParam(unitTeam, "morphUnitCreating", 1, PRIVATE)
		newUnit = CreateMorphedToUnit(defName, x, y, z, face, unitTeam, isBeingBuilt, morphData.def.upgradeDef)
		Spring.SetTeamRulesParam(unitTeam, "morphUnitCreating", 0, PRIVATE)
		if not newUnit then
			StopMorph(unitID, morphData)
			return
		end
		Spring.SetUnitPosition(newUnit, x, y, z)
	else
		Spring.SetTeamRulesParam(unitTeam, "morphUnitCreating", 1, PRIVATE)
		newUnit = CreateMorphedToUnit(defName, px, py, pz, HeadingToFacing(h), unitTeam, isBeingBuilt, morphData.def.upgradeDef)
		Spring.SetTeamRulesParam(unitTeam, "morphUnitCreating", 0, PRIVATE)
		if not newUnit then
			StopMorph(unitID, morphData)
			return
		end
		Spring.SetUnitRotation(newUnit, 0, -h * math.pi / 32768, 0)
		Spring.SetUnitPosition(newUnit, px, py, pz)
	end

	if (extraUnitMorphDefs[unitID] ~= nil) then
	-- nothing here for now
	end
	
	if (hostName ~= nil) and PWUnits[unitID] then
		-- send planetwars deployment message
		PWUnit = PWUnits[unitID]
		PWUnit.currentDef = udDst
		local data = PWUnit.owner..","..defName..","..math.floor(px)..","..math.floor(pz)..",".."S" -- todo determine and apply smart orientation of the structure
		Spring.SendCommands("w "..hostName.." pwmorph:"..data)
		extraUnitMorphDefs[unitID] = nil
		--GG.PlanetWars.units[unitID] = nil
		--GG.PlanetWars.units[newUnit] = PWUnit
		SendToUnsynced('PWCreate', unitTeam, newUnit)
	elseif (not morphData.def.facing) then	-- set rotation only if unit is not planetwars and facing is not true
		--Spring.Echo(morphData.def.facing)
		Spring.SetUnitRotation(newUnit, 0, -h * math.pi / 32768, 0)
	end

	--// copy lineage
	--local lineage = Spring.GetUnitLineage(unitID)
	--// copy facplop
	local facplop = Spring.GetUnitRulesParam(unitID, "facplop")
	--//copy command queue
	local cmds = Spring.GetCommandQueue(unitID, -1)

	local states = Spring.GetUnitStates(unitID) -- This can be left in table-state mode until REVERSE_COMPAT is not an issue.
	states.retreat = Spring.GetUnitRulesParam(unitID, "retreatState") or 0
	states.buildPrio = Spring.GetUnitRulesParam(unitID, "buildpriority") or 1
	states.miscPrio = Spring.GetUnitRulesParam(unitID, "miscpriority") or 1

	--// copy cloak state
	local wantCloakState = Spring.GetUnitRulesParam(unitID, "wantcloak")
	--// copy shield power
	local shieldNum = Spring.GetUnitRulesParam(unitID, "comm_shield_num") or -1
	local oldShieldState, oldShieldCharge = Spring.GetUnitShieldState(unitID, shieldNum)
	--//copy experience
	local newXp = Spring.GetUnitExperience(unitID)
	local oldBuildTime = Spring.Utilities.GetUnitCost(unitID, unitDefID)
	--//copy unit speed
	local velX,velY,velZ = Spring.GetUnitVelocity(unitID) --remember speed
 

	Spring.SetUnitRulesParam(newUnit, "jumpReload", Spring.GetUnitRulesParam(unitID, "jumpReload") or 1)
	
	--// FIXME: - re-attach to current transport?
	--// update selection
	SendToUnsynced("unit_morph_finished", unitID, newUnit)
	GG.wasMorphedTo[unitID] = newUnit
	Spring.SetUnitRulesParam(unitID, "wasMorphedTo", newUnit)
	
	Spring.SetUnitBlocking(newUnit, true)
	
	-- copy disarmed
	local paradisdmg, pdtime = GG.getUnitParalysisExternal(unitID)
	if (paradisdmg ~= nil) then
		GG.setUnitParalysisExternal(newUnit, paradisdmg, pdtime)
	end
	
	-- copy dominatrix lineage
	if (originTeam ~= nil) then
		GG.Capture.SetMastermind(newUnit, originTeam, originAllyTeam, controllerID, controllerAllyTeam)
	end
	
	Spring.DestroyUnit(unitID, false, true) -- selfd = false, reclaim = true
	
	--//transfer unit speed
	local gy = Spring.GetGroundHeight(px, pz)
	if py>gy+1 then --unit is off-ground
		Spring.AddUnitImpulse(newUnit,0,1,0) --dummy impulse (applying impulse>1 stop engine from forcing new unit to stick on map surface, unstick!)
		Spring.AddUnitImpulse(newUnit,0,-1,0) --negate dummy impulse
	end
	Spring.AddUnitImpulse(newUnit,velX,velY,velZ) --restore speed

	-- script.StartMoving is not called if a unit is created and then given velocity via impulse.
	local speed = math.sqrt(velX^2 + velY^2 + velZ^2)
	if speed > 0.6 then
		local env = Spring.UnitScript.GetScriptEnv(newUnit)
		if env and env.script.StartMoving then
			Spring.UnitScript.CallAsUnit(newUnit,env.script.StartMoving)
		end
	end
	
	--// transfer facplop
	if facplop and (facplop == 1) then
		Spring.SetUnitRulesParam(newUnit, "facplop", 1, {inlos = true})
	end
	
	--// transfer health
	-- old health is declared far above
	local _,newMaxHealth		 = Spring.GetUnitHealth(newUnit)
	local newHealth = (oldHealth / oldMaxHealth) * newMaxHealth
	if newHealth <= 1 then
		newHealth = 1
	end
	
	local newPara = paralyzeDamage*newMaxHealth/oldMaxHealth
	local slowDamage = Spring.GetUnitRulesParam(unitID,"slowState")
	if slowDamage then
		GG.addSlowDamage(newUnit, slowDamage*newMaxHealth)
	end
	Spring.SetUnitHealth(newUnit, {health = newHealth, build = buildProgress, paralyze = newPara, capture = captureProgress })
	
	--//transfer experience
	newXp = newXp * (oldBuildTime / Spring.Utilities.GetUnitCost(unitID, morphData.def.into))
	Spring.SetUnitExperience(newUnit, newXp)
	--// transfer shield power
	if oldShieldState then
		Spring.SetUnitShieldState(newUnit, shieldNum, oldShieldCharge)
	end
	
	--//transfer some state
	Spring.GiveOrderArrayToUnitArray({ newUnit }, {
		{CMD.FIRE_STATE,    { states.firestate             }, 0 },
		{CMD.MOVE_STATE,    { states.movestate             }, 0 },
		{CMD.REPEAT,        { states["repeat"] and 1 or 0  }, 0 },
		{CMD_WANT_CLOAK,    { wantCloakState or 0          }, 0 },
		{CMD.ONOFF,         { 1                            }, 0 },
		{CMD.TRAJECTORY,    { states.trajectory and 1 or 0 }, 0 },
		{CMD_PRIORITY,      { states.buildPrio             }, 0 },
		{CMD_RETREAT,       { states.retreat               }, states.retreat == 0 and CMD.OPT_RIGHT or 0 },
		{CMD_MISC_PRIORITY, { states.miscPrio              }, 0 },
	})
	
	--//reassign assist commands to new unit
	ReAssignAssists(newUnit,unitID)

	--//transfer command queue
	for i = 1, #cmds do
		local cmd = cmds[i]
		local coded = cmd.options.coded + (cmd.options.shift and 0 or CMD.OPT_SHIFT) -- orders without SHIFT can appear at positions other than the 1st due to CMD.INSERT; they'd cancel any previous commands if added raw
		if cmd.id < 0 then -- repair case for construction
			local units = Spring.GetUnitsInRectangle(cmd.params[1] - 16, cmd.params[3] - 16, cmd.params[1] + 16, cmd.params[3] + 16)
			local allyTeam = Spring.GetUnitAllyTeam(unitID)
			local notFound = true
			for j = 1, #units do
				local areaUnitID = units[j]
				if allyTeam == Spring.GetUnitAllyTeam(areaUnitID) and Spring.GetUnitDefID(areaUnitID) == -cmd.id then
					Spring.GiveOrderToUnit(newUnit, CMD.REPAIR, {areaUnitID}, coded)
					notFound = false
					break
				end
			end
			if notFound then
				Spring.GiveOrderToUnit(newUnit, cmd.id, cmd.params, coded)
			end
		else
			Spring.GiveOrderToUnit(newUnit, cmd.id, cmd.params, coded)
		end
	end
end


local function UpdateMorph(unitID, morphData)
	local transportID = Spring.GetUnitTransporter(unitID)
	local transportUnitDefID = 0
	if transportID then
		if not morphData.combatMorph then
			StopMorph(unitID, morphUnits[unitID])
			morphUnits[unitID] = nil
			return true
		end
		transportUnitDefID = Spring.GetUnitDefID(transportID)
		if not UnitDefs[transportUnitDefID].isFirePlatform then
			return true
		end
	end
	
	-- if EMPd or disarmed do not morph
	if (Spring.GetUnitRulesParam(unitID, "disarmed") == 1) or (Spring.GetUnitIsStunned(unitID)) then
		return true
	end
	
	if (morphData.progress < 1.0) then
		
		local newMorphRate = GetMorphRate(unitID)
		
		if (morphData.morphRate ~= newMorphRate) then
			--GG.StopMiscPriorityResourcing(unitID, 2) not necessary
			GG.StartMiscPriorityResourcing(unitID, (newMorphRate*morphData.def.metal/morphData.def.time), nil, 2) --is using unit_priority.lua gadget to handle morph priority. Modifies resource drain if slowness has changed.
			morphData.morphRate = newMorphRate
		end
		local resourceUse = {
			m = (morphData.def.resTable.m * morphData.morphRate),
			e = (morphData.def.resTable.e * morphData.morphRate),
		}
		local allow = GG.AllowMiscPriorityBuildStep(unitID, morphData.teamID, false, resourceUse) --use unit_priority.lua gadget to handle morph priority.
		
		if freeMorph then
			morphData.progress = 1
		elseif allow and (Spring.UseUnitResource(unitID, resourceUse)) then
			morphData.progress = morphData.progress + morphData.increment*morphData.morphRate
		end
	end
	if (morphData.progress >= 1.0 and Spring.GetUnitRulesParam(unitID, "is_jumping") ~= 1 and not transportID) then
		FinishMorph(unitID, morphData)
		return false -- remove from the list, all done
	end
	return true
end

--------------------------------------------------------------------------------
--------------------------------------------------------------------------------
--------------------------------------------------------------------------------

local function SetFreeMorph(newFree)
	freeMorph = newFree
end

function gadget:Initialize()
	--// get the morphDefs
	morphDefs, MAX_MORPH = include("LuaRules/Configs/morph_defs.lua")
	if (not morphDefs) then
		gadgetHandler:RemoveGadget()
		return
	end
	
	GG.SetFreeMorph = SetFreeMorph

	--// make it global for unsynced access via SYNCED
	_G.morphUnits         = morphUnits
	_G.morphDefs          = morphDefs
	_G.extraUnitMorphDefs = extraUnitMorphDefs
	--_G.morphToStart       = morphToStart

	--// Register CmdIDs
	for number = 0, MAX_MORPH - 1 do
		gadgetHandler:RegisterCMDID(CMD_MORPH + number)
		gadgetHandler:RegisterCMDID(CMD_MORPH_STOP + number)
	end

	gadgetHandler:RegisterCMDID(CMD_UPGRADE_STOP)
	
	--// check existing ReqUnits+TechLevel
	local allUnits = Spring.GetAllUnits()
	for i = 1, #allUnits do
		local unitID    = allUnits[i]
		local unitDefID = Spring.GetUnitDefID(unitID)
		local teamID    = Spring.GetUnitTeam(unitID)
		if reqDefIDs[unitDefID] and isFinished(unitID) then
			local teamReq = teamReqUnits[teamID]
			teamReq[unitDefID] = (teamReq[unitDefID] or 0) + 1
		end
	end

	--// add the Morph Menu Button to existing units
	for i = 1, #allUnits do
		local unitID	= allUnits[i]
		local teamID	= Spring.GetUnitTeam(unitID)
		local unitDefID = Spring.GetUnitDefID(unitID)
		local morphDefSet	= morphDefs[unitDefID]
		if (morphDefSet) then
			for _,morphDef in pairs(morphDefSet) do
				if (morphDef) then
					local cmdDescID = Spring.FindUnitCmdDesc(unitID, morphDef.cmd)
					if (not cmdDescID) then
						AddMorphCmdDesc(unitID, unitDefID, teamID, morphDef)
					end
				end
			end
		elseif UnitDefs[unitDefID].customParams.dynamic_comm then
			GG.AddMiscPriorityUnit(unitID)
		end
	end
end

function gadget:Shutdown()
	local allUnits = Spring.GetAllUnits()
	for i = 1, #allUnits do
		local unitID    = allUnits[i]
		local morphData = morphUnits[unitID]
		if morphData then
			StopMorph(unitID, morphData)
		end
		for number = 0, MAX_MORPH - 1 do
			local cmdDescID = Spring.FindUnitCmdDesc(unitID, CMD_MORPH + number)
			if cmdDescID then
				Spring.RemoveUnitCmdDesc(unitID, cmdDescID)
			end
		end
	end
end

--------------------------------------------------------------------------------
--------------------------------------------------------------------------------
--------------------------------------------------------------------------------

function gadget:UnitCreated(unitID, unitDefID, teamID)
	GG.wasMorphedTo[unitID] = nil
	local morphDefSet = morphDefs[unitDefID]
	if (morphDefSet) then
		for _,morphDef in pairs(morphDefSet) do
			if (morphDef) then
				AddMorphCmdDesc(unitID, unitDefID, teamID, morphDef)
			end
		end
	elseif UnitDefs[unitDefID].customParams.dynamic_comm then
		GG.AddMiscPriorityUnit(unitID)
	end
end

function gadget:UnitDestroyed(unitID, unitDefID, teamID)
	if (morphUnits[unitID]) then
		StopMorph(unitID, morphUnits[unitID])
		morphUnits[unitID] = nil
	end
end

--------------------------------------------------------------------------------
--------------------------------------------------------------------------------
--------------------------------------------------------------------------------

function gadget:GameFrame(n)
	-- start pending morphs
	for unitID, data in pairs(morphToStart) do
		if StartMorph(unitID, unpack(data)) then
			morphToStart[unitID] = nil
		end
	end

	for unitID, morphData in pairs(morphUnits) do
		if (not UpdateMorph(unitID, morphData)) then
			morphUnits[unitID] = nil
		end
	end
end

local function processMorph(unitID, unitDefID, teamID, cmdID, cmdParams)
	local morphDef, _
	if cmdID == CMD_MORPH then
		if type(GG.MorphInfo[unitDefID]) ~= "table" then
			--Spring.Echo('Morph gadget: CommandFallback generic morph on non morphable unit')
			return true
		end
		if cmdParams[1] then
			--Spring.Echo('Morph gadget: CommandFallback generic morph with target provided')
			morphDef=(morphDefs[unitDefID] or {})[GG.MorphInfo[unitDefID][cmdParams[1]]]
		else
			--Spring.Echo('Morph gadget: CommandFallback generic morph, default target')
			_, morphDef = next(morphDefs[unitDefID])
		end
	else
		--Spring.Echo('Morph gadget: CommandFallback specific morph')
		morphDef = (morphDefs[unitDefID] or {})[cmdID] or extraUnitMorphDefs[unitID]
	end
	if (not morphDef) then
		return true
	end
	if morphDef then
		local morphData = morphUnits[unitID]
		if (not morphData) then
			-- dont start directly to break recursion
			--StartMorph(unitID, unitDefID, teamID, morphDef)
			morphToStart[unitID] = {unitDefID, teamID, morphDef}
			return true
		end
	end
	return false
end

local function processUpgrade(unitID, unitDefID, teamID, cmdID, cmdParams)
	if morphUnits[unitID] then
		-- Unit is already upgrading.
		return false
	end
	
	if not GG.Upgrades_GetValidAndMorphAttributes then
		return false
	end
	
	local health, maxHealth, paralyzeDamage, captureProgress, buildProgress = Spring.GetUnitHealth(unitID)
	if buildProgress < 1 then
		return true
	end
	
	local valid, targetUnitDefID, morphDef = GG.Upgrades_GetValidAndMorphAttributes(unitID, cmdParams)
	
	if not valid then
		return false
	end
	
	morphToStart[unitID] = {targetUnitDefID, teamID, morphDef}
end

function gadget:AllowCommand_GetWantedCommand()
	return true -- morph command is dynamic so incoperating it is difficult
end

function gadget:AllowCommand_GetWantedUnitDefID()
	boolDef = {}
	for udid,_ in pairs(morphDefs) do
		boolDef[udid] = true
	end
	for udid = 1, #UnitDefs do
		local ud = UnitDefs[udid]
		if ud and ud.customParams and ud.customParams.level then -- commander detection
			boolDef[udid] = true
		end
	end
	return boolDef
end

function gadget:AllowCommand(unitID, unitDefID, teamID, cmdID, cmdParams, cmdOptions)
	if cmdID == CMD_MORPH_UPGRADE_INTERNAL then
		return processUpgrade(unitID, unitDefID, teamID, cmdID, cmdParams)
	end
	local morphData = morphUnits[unitID]
	if (morphData) then
		if (cmdID == morphData.def.stopCmd) or (cmdID == CMD.STOP and not morphData.def.combatMorph) or (cmdID == CMD_MORPH_STOP) then
				StopMorph(unitID, morphData)
				morphUnits[unitID] = nil
				return false
		elseif cmdID == CMD.SELFD then
			StopMorph(unitID, morphData)
			morphUnits[unitID] = nil
		end
	elseif (cmdID >= CMD_MORPH and cmdID <= CMD_MORPH+MAX_MORPH) then
		local morphDef, _
		if cmdID == CMD_MORPH then
			if type(GG.MorphInfo[unitDefID]) ~= "table" then
				--Spring.Echo('Morph gadget: AllowCommand generic morph on non morphable unit')
				return false
			elseif #cmdParams == 0 then
				--Spring.Echo('Morph gadget: AllowCommand generic morph, default target')
				_, morphDef = next(morphDefs[unitDefID])
			elseif GG.MorphInfo[unitDefID][cmdParams[1]] then
				--Spring.Echo('Morph gadget: AllowCommand generic morph, target valid')
				--return true
				morphDef = (morphDefs[unitDefID] or {})[GG.MorphInfo[unitDefID][cmdParams[1]]]
			else
				--Spring.Echo('Morph gadget: AllowCommand generic morph, invalid target')
				return false
			end
			--Spring.Echo('Morph gadget: AllowCommand morph cannot be here!')
		elseif (cmdID > CMD_MORPH and cmdID <= CMD_MORPH+MAX_MORPH) then
			--Spring.Echo('Morph gadget: AllowCommand specific morph')
			morphDef = (morphDefs[unitDefID] or {})[cmdID] or extraUnitMorphDefs[unitID]
		end
		if morphDef then
			if (isFactory(unitDefID)) then
				--// the factory cai is broken and doesn't call CommandFallback(),
				--// so we have to start the morph here
				-- dont start directly to break recursion
				--StartMorph(unitID, unitDefID, teamID, morphDef)
				morphToStart[unitID] = {unitDefID, teamID, morphDef}
				return false
			else
				--// morph allowed
				if morphDef.combatMorph or not cmdOptions.shift then -- process now, no shift queue for combat morph to preserve command queue
					processMorph(unitID, unitDefID, teamID, cmdID, cmdParams)
					return false
				else
					return true
				end
			end
		end
		return false
	end

	return true
end

function gadget:CommandFallback(unitID, unitDefID, teamID, cmdID, cmdParams, cmdOptions)
	if cmdID == CMD_MORPH_UPGRADE_INTERNAL then
		return true, processUpgrade(unitID, unitDefID, teamID, cmdID, cmdParams)
	end
	
	if (cmdID < CMD_MORPH or cmdID > CMD_MORPH+MAX_MORPH) then
		return false --// command was not used
	end
	return true, processMorph(unitID, unitDefID, teamID, cmdID, cmdParams) -- command was used, process decides if to remove
end

function gadget:Load(zip)
	if not (GG.SaveLoad and GG.SaveLoad.ReadFile) then
		Spring.Log(gadget:GetInfo().name, LOG.ERROR, "Failed to access save/load API")
		return
	end
	
	--[[
	morphUnits[unitID] = {
		def = morphDef,
		progress = 0.0,
		increment = morphDef.increment,
		morphID = morphID,
		teamID = teamID,
		combatMorph = morphDef.combatMorph,
		morphRate = 0.0,
	}
	]]
	
	local loadData = GG.SaveLoad.ReadFile(zip, "Morph", SAVE_FILE) or emptyTable
	for oldID, entry in pairs(loadData.morph or emptyTable) do
		local newID = GG.SaveLoad.GetNewUnitID(oldID)
		if newID then
			morphUnits[newID] = entry
			
			local morphDef = entry.def
			if morphDef.cmd then
				local cmdDescID = Spring.FindUnitCmdDesc(newID, morphDef.cmd)
				if (cmdDescID) then
					Spring.EditUnitCmdDesc(newID, cmdDescID, {id = morphDef.stopCmd, name = RedStr .. "Stop"})
				end
			elseif morphDef.stopCmd == CMD_UPGRADE_STOP then
				Spring.InsertUnitCmdDesc(newID, stopUpgradeCmdDesc)
			end
		end
	end
end

--------------------------------------------------------------------------------
--	END SYNCED
--------------------------------------------------------------------------------
else
--------------------------------------------------------------------------------
--	UNSYNCED
--------------------------------------------------------------------------------
--
-- speed-ups
--

local gameFrame
local SYNCED = SYNCED
local CallAsTeam = CallAsTeam
local spairs = spairs
local snext = snext

local spGetUnitPosition = Spring.GetUnitPosition

local GetUnitTeam        = Spring.GetUnitTeam
local GetUnitHeading     = Spring.GetUnitHeading
local GetGameFrame       = Spring.GetGameFrame
local GetSpectatingState = Spring.GetSpectatingState
local AddWorldIcon       = Spring.AddWorldIcon
local AddWorldText       = Spring.AddWorldText
local IsUnitVisible      = Spring.IsUnitVisible
local GetLocalTeamID     = Spring.GetLocalTeamID
local spAreTeamsAllied   = Spring.AreTeamsAllied

local glBillboard     = gl.Billboard
local glColor         = gl.Color
local glPushMatrix    = gl.PushMatrix
local glTranslate     = gl.Translate
local glRotate        = gl.Rotate
local glUnitShape     = gl.UnitShape
local glPopMatrix     = gl.PopMatrix
local glText          = gl.Text
local glCulling       = gl.Culling
local glPushAttrib    = gl.PushAttrib
local glPopAttrib     = gl.PopAttrib
local glPolygonOffset = gl.PolygonOffset
local glBlending      = gl.Blending
local glDepthTest     = gl.DepthTest
local glUnit          = gl.Unit

local GL_LEQUAL              = GL.LEQUAL
local GL_ONE                 = GL.ONE
local GL_SRC_ALPHA           = GL.SRC_ALPHA
local GL_ONE_MINUS_SRC_ALPHA = GL.ONE_MINUS_SRC_ALPHA
local GL_COLOR_BUFFER_BIT    = GL.COLOR_BUFFER_BIT

local headingToDegree = (360 / 65535)

--------------------------------------------------------------------------------
--------------------------------------------------------------------------------

local useLuaUI = false
local oldFrame = 0		--//used to save bandwidth between unsynced->LuaUI
local drawProgress = true --//a widget can do this job too (see healthbars)

--------------------------------------------------------------------------------
--------------------------------------------------------------------------------

--//synced -> unsynced actions

local function SelectSwap(cmd, oldID, newID)
	local selUnits = Spring.GetSelectedUnits()
	for i = 1, #selUnits do
		local unitID = selUnits[i]
		if (unitID == oldID) then
			selUnits[i] = newID
			Spring.SelectUnitArray(selUnits)
			break
		end
	end

	if (Script.LuaUI('MorphFinished')) then
		if useLuaUI then
			local readTeam, spec, specFullView = nil,GetSpectatingState()
			if specFullView then
				readTeam = Script.ALL_ACCESS_TEAM
			else
				readTeam = GetLocalTeamID()
			end
			CallAsTeam({['read'] = readTeam },
				function()
					if (IsUnitVisible(oldID)) then
						Script.LuaUI.MorphFinished(oldID,newID)
					end
				end
			)
		end
	end
	return true
end

local function StartMorph(cmd, unitID, unitDefID, morphID)
	if (Script.LuaUI('MorphStart')) then
		if useLuaUI then
			local readTeam, spec, specFullView = nil, GetSpectatingState()
			if specFullView then
				readTeam = Script.ALL_ACCESS_TEAM
			else
				readTeam = GetLocalTeamID()
			end
			CallAsTeam({['read'] = readTeam },
				function()
					if (unitID)and(IsUnitVisible(unitID)) then
						Script.LuaUI.MorphStart(unitID, (SYNCED.morphDefs[unitDefID] or {})[morphID] or SYNCED.extraUnitMorphDefs[unitID])
					end
				end
			)
		end
	end
	return true
end

local function StopMorph(cmd, unitID)
	if (Script.LuaUI('MorphStop')) then
		if useLuaUI then
			local readTeam, spec, specFullView = nil, GetSpectatingState()
			if specFullView then
				readTeam = Script.ALL_ACCESS_TEAM
			else
				readTeam = GetLocalTeamID()
			end
			CallAsTeam({['read'] = readTeam },
				function()
					if (unitID)and(IsUnitVisible(unitID)) then
						Script.LuaUI.MorphStop(unitID)
					end
				end
			)
		end
	end
	return true
end

--------------------------------------------------------------------------------
--------------------------------------------------------------------------------

function gadget:Initialize()
	gadgetHandler:AddSyncAction("unit_morph_finished", SelectSwap)
	gadgetHandler:AddSyncAction("unit_morph_start", StartMorph)
	gadgetHandler:AddSyncAction("unit_morph_stop", StopMorph)
end

function gadget:Shutdown()
	gadgetHandler:RemoveSyncAction("unit_morph_finished")
	gadgetHandler:RemoveSyncAction("unit_morph_start")
	gadgetHandler:RemoveSyncAction("unit_morph_stop")
end

function gadget:Update()
	local frame = GetGameFrame()
	if frame > oldFrame then
		oldFrame = frame
		local morphUnitsSynced = SYNCED.morphUnits
		if snext(morphUnitsSynced) then
			local useLuaUI_ = Script.LuaUI('MorphUpdate')
			if useLuaUI_ ~= useLuaUI then --//Update Callins on change
				drawProgress = not Script.LuaUI('MorphDrawProgress')
				useLuaUI     = useLuaUI_
			end

			if useLuaUI then
				local morphTable = {}
				local readTeam, spec, specFullView = nil,GetSpectatingState()
				if specFullView then
					readTeam = Script.ALL_ACCESS_TEAM
				else
					readTeam = GetLocalTeamID()
				end
				CallAsTeam({ ['read'] = readTeam },
					function()
						for unitID, morphData in spairs(morphUnitsSynced) do
							if (unitID and morphData)and(IsUnitVisible(unitID)) then
								morphTable[unitID] = {progress = morphData.progress, into = morphData.def.into, combatMorph = morphData.combatMorph}
							end
						end
					end
				)
				Script.LuaUI.MorphUpdate(morphTable)
			end
		end
	end
end

local teamColors = {}
local function SetTeamColor(teamID,a)
	local color = teamColors[teamID]
	if color then
		color[4] = a
		glColor(color)
		return
	end
	local r, g, b = Spring.GetTeamColor(teamID)
	if (r and g and b) then
		color = { r, g, b }
		teamColors[teamID] = color
		glColor(color)
		return
	end
end


--//patchs an annoying popup the first time you morph a unittype(+team)
local alreadyInit = {}
local function InitializeUnitShape(unitDefID,unitTeam)
	local iTeam = alreadyInit[unitTeam]
	if  iTeam and iTeam[unitDefID] then
		return
	end

	glPushMatrix()
	gl.ColorMask(false)
	glUnitShape(unitDefID, unitTeam)
	gl.ColorMask(true)
	glPopMatrix()
	if (alreadyInit[unitTeam] == nil) then
		alreadyInit[unitTeam] = {}
	end
	alreadyInit[unitTeam][unitDefID] = true
end


local function DrawMorphUnit(unitID, morphData, localTeamID)
	local h = GetUnitHeading(unitID)
	if (h == nil) then
		return	--// bonus, heading is only available when the unit is in LOS
	end
	
	local px,py,pz = spGetUnitPosition(unitID)
	if (px == nil) then
		return
	end
	local unitTeam = morphData.teamID

	InitializeUnitShape(morphData.def.into,unitTeam) --BUGFIX

	local frac = ((gameFrame + unitID) % 30) / 30
	local alpha = 2.0 * math.abs(0.5 - frac)
	local angle
	if morphData.def.facing then
		angle = -HeadingToFacing(h) * 90 + 180
	else
		angle = h * headingToDegree
	end

	SetTeamColor(unitTeam,alpha)
	glPushMatrix()
	glTranslate(px, py, pz)
	glRotate(angle, 0, 1, 0)
	glUnitShape(morphData.def.into, unitTeam)
	glPopMatrix()

	--// cheesy progress indicator
	if (drawProgress) and (localTeamID) and
		 ((spAreTeamsAllied(unitTeam,localTeamID)) or (localTeamID == Script.ALL_ACCESS_TEAM))
		then
		glPushMatrix()
		glPushAttrib(GL_COLOR_BUFFER_BIT)
		glTranslate(px, py+14, pz)
		glBillboard()
		local progStr = string.format("%.1f%%", 100 * morphData.progress)
		gl.Text(progStr, 0, -20, 9, "oc")
		glPopAttrib()
		glPopMatrix()
	end
end

local phase = 0
local function DrawCombatMorphUnit(unitID, morphData, localTeamID)
	local c1 = math.sin(phase)*.2 + .2
	local c2 = math.sin(phase+ math.pi)*.2 + .2
	local mult = 2

	glBlending(GL_ONE, GL_ONE)
	glDepthTest(GL_LEQUAL)
	--glLighting(true)
	glPolygonOffset(-10, -10)
	glCulling(GL.BACK)
	glColor(c1*mult,0,c2*mult,1)
	glUnit(unitID, true)
	
	glColor(1,1,1,1)
	--glBlending(GL_SRC_ALPHA, GL_ONE_MINUS_SRC_ALPHA)
	--glPolygonOffset(false)
	--glCulling(false)
	--glDepthTest(false)
end

local function DrawWorldFunc()

	local morphUnits = SYNCED.morphUnits

	if (not snext(morphUnits)) then
		return --//no morphs to draw
	end

	gameFrame = GetGameFrame()

	glBlending(GL_SRC_ALPHA, GL_ONE)
	glDepthTest(GL_LEQUAL)

	local spec, specFullView = GetSpectatingState()
	local readTeam
	if (specFullView) then
		readTeam = Script.ALL_ACCESS_TEAM
	else
		readTeam = GetLocalTeamID()
	end

	CallAsTeam({['read'] = readTeam},
		function()
			for unitID, morphData in spairs(morphUnits) do
				if (unitID and morphData)and(IsUnitVisible(unitID)) then
					if morphData.combatMorph then
						DrawCombatMorphUnit(unitID, morphData,readTeam)
					else
						DrawMorphUnit(unitID, morphData,readTeam)
					end
				end
			end
		end
	)
	glDepthTest(false)
	glBlending(GL_SRC_ALPHA, GL_ONE_MINUS_SRC_ALPHA)
	phase = phase + .06
end

function gadget:DrawWorld()
	DrawWorldFunc()
end

function gadget:DrawWorldRefraction()
	DrawWorldFunc()
end

local function split(msg,sep)
	local s=sep or '|'
	local t={}
	for e in string.gmatch(msg..s,'([^%'..s..']+)%'..s) do
		t[#t+1] = e
	end
	return t
end

-- Exemple of AI messages:
-- "aiShortName|morph|762" -- morph the unit of unitId 762
-- "aiShortName|morph|861|12" -- morph the unit of unitId 861 into an unit of unitDefId 12
--
-- Does not work because apparently Spring.GiveOrderToUnit from unsynced gadgets are ignored.
--
function gadget:AICallIn(data)
	if type(data) == "string" then
		local message = split(data)
		if message[1] == "Shard" or true then-- Because other AI shall be allowed to send such morph command without having to pretend to be Shard
			if message[2] == "morph" and message[3] then
				local unitID = tonumber(message[3])
				if unitID and Spring.ValidUnitID(unitID) then
					if message[4] then
						local destDefId=tonumber(message[4])
						--Spring.Echo("Morph AICallIn: Morphing Unit["..unitID.."] into "..UnitDefs[destDefId].name)
						Spring.GiveOrderToUnit(unitID,CMD_MORPH,{destDefId}, 0)
					else
						--Spring.Echo("Morph AICallIn: Morphing Unit["..unitID.."] to auto")
						Spring.GiveOrderToUnit(unitID,CMD_MORPH,{}, 0)
					end
				else
					Spring.Echo("Not a valid unitID in AICallIn morph request: \""..data.."\"")
				end
			end
		end
	end
end

-- Just something to test the above AICallIn
--function gadget:KeyPress(key)
--	if key == 32 then--space key
--	gadget:AICallIn("asn|morph|762")
--	end
--end

function gadget:Save(zip)
	if not GG.SaveLoad then
		Spring.Log(gadget:GetInfo().name, LOG.ERROR, "Failed to access save/load API")
		return
	end
	
	local morph = Spring.Utilities.MakeRealTable(SYNCED.morphUnits, "Morph")
	--local morphToStart = Spring.Utilities.MakeRealTable(SYNCED.morphToStart, "Morph (to start)")
	local save = {morph = morph}	-- {morph = morph, morphToStart = morphToStart}
	
	GG.SaveLoad.WriteSaveData(zip, SAVE_FILE, save)
end

--------------------------------------------------------------------------------
--  UNSYNCED
--------------------------------------------------------------------------------
end
--------------------------------------------------------------------------------
--  COMMON
--------------------------------------------------------------------------------
