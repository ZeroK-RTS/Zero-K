--------------------------------------------------------------------------------
--------------------------------------------------------------------------------

function gadget:GetInfo()
   return {
      name      = "Capture",
      desc      = "Handles Yuri Style Capture System",
      author    = "Google Frog",
      date      = "30/9/2010",
      license   = "GNU GPL, v2 or later",
      layer     = 0,
      enabled   = true  
   }
end

--------------------------------------------------------------------------------
--------------------------------------------------------------------------------

local RETAKING_DEGRADE_TIMER = 15
local GENERAL_DEGRADE_TIMER = 5
local DEGRADE_FACTOR = 0.04

include("LuaRules/Configs/customcmds.h.lua")
local CMD_STOP = CMD.STOP
local CMD_SELFD = CMD.SELFD

local unitKillSubordinatesCmdDesc = {
	id      = CMD_UNIT_KILL_SUBORDINATES,
	type    = CMDTYPE.ICON_MODE,
	name    = 'Kill Subordinates',
	action  = 'killsubordinates',
	tooltip	= 'Toggles auto self-d of captured units',
	params 	= {0, 'Kill Off','Kill On'}
}

--SYNCED
if gadgetHandler:IsSyncedCode() then

--------------------------------------------------------------------------------
--------------------------------------------------------------------------------
local spGetUnitDefID        = Spring.GetUnitDefID
local spAreTeamsAllied		= Spring.AreTeamsAllied
local spSetUnitHealth		= Spring.SetUnitHealth

--------------------------------------------------------------------------------
--------------------------------------------------------------------------------

local captureWeaponDefs, captureUnitDefs = include("LuaRules/Configs/capture_defs.lua")

local capturedUnits = {}
local controllers = {}
local reloading = {}

-- updates capture bar for controllers
local function updateControllerBar(unitID)
	if controllers[unitID].unitMax then
		if controllers[unitID].unitMax == controllers[unitID].unitCount then
			Spring.SetUnitRulesParam(unitID,"cantfire",1, {inlos = true})
		else
			Spring.SetUnitRulesParam(unitID,"cantfire",0, {inlos = true})
		end
	end
end

-- remove all capture damage from a unit, does not transfere unit
local function removeCapturedUnit(unitID, alive)
	
	local unitTeam = Spring.GetUnitAllyTeam(unitID)
	
	for aTeam, allyData in pairs(capturedUnits[unitID].aTeams) do
		if allyData.inControl then
			controllers[allyData.inControl].units[unitID] = nil
			controllers[allyData.inControl].unitCount = controllers[allyData.inControl].unitCount - 1
			updateControllerBar(allyData.inControl)
		end
	end
	if alive then
		spSetUnitHealth(unitID, {capture = 0} )
	end
	capturedUnits[unitID] = nil
end

-- displays capture bar as largest capture from any ally team
local function updateCapturedUnitBar(unitID)
	capturedUnits[unitID].largestCaptureFromAnyOneTeam = 0
	local noCapture = true
	for _,data in pairs(capturedUnits[unitID].aTeams) do
		if data.inControl then
			noCapture = false
		elseif capturedUnits[unitID].largestCaptureFromAnyOneTeam < data.totalDamage  then
			noCapture = false
			capturedUnits[unitID].largestCaptureFromAnyOneTeam = data.totalDamage
		end
	end
	
	if noCapture then
		removeCapturedUnit(unitID, true)
	else
		spSetUnitHealth(unitID, {capture = capturedUnits[unitID].largestCaptureFromAnyOneTeam/capturedUnits[unitID].captureHealth} )
	end
end

-- frees all subordinates from a controller and removes the unit
local function removeController(unitID, team, aTeam)
	
	for id, data in pairs(controllers[unitID].units) do
		Spring.TransferUnit(id, capturedUnits[id].originTeam, false)
		capturedUnits[id] = nil
		spSetUnitHealth(id, {capture = 0} )
	end
	
	controllers[unitID] = nil
end

-- removes capture damage dealt by allyTeam from the unit
local function removeTeamCaptureFromUnit(unitID, allyTeam)
	if capturedUnits[unitID].aTeams[allyTeam].inControl then
		controllers[capturedUnits[unitID].aTeams[allyTeam].inControl].units[unitID] = nil
		controllers[capturedUnits[unitID].aTeams[allyTeam].inControl].unitCount = controllers[capturedUnits[unitID].aTeams[allyTeam].inControl].unitCount - 1
		updateControllerBar(capturedUnits[unitID].aTeams[allyTeam].inControl)
	end
	capturedUnits[unitID].aTeams[allyTeam] = nil
	updateCapturedUnitBar(unitID)
end

function gadget:UnitPreDamaged(unitID, unitDefID, unitTeam, damage, paralyzer, weaponID,
                            attackerID, attackerDefID, attackerTeam)
        
	if (not weaponID) or (not captureWeaponDefs[weaponID]) then 
		return damage
	end

	if ((not attackerTeam) or spAreTeamsAllied(unitTeam, attackerTeam)) or controllers[unitID] then
		return 0
	end
	
	-- add stats that the unit requires for this gadget
	if not capturedUnits[unitID] then
		capturedUnits[unitID] = {
			captureHealth = UnitDefs[unitDefID].buildTime,
			originTeam = unitTeam,
			originAllyTeam = Spring.GetUnitAllyTeam(unitID),
			aTeams = {},
		}
	end
	
	-- add ally team stats
	local _,_,_,_,_,aTeam = Spring.GetTeamInfo(attackerTeam)
	if not capturedUnits[unitID].aTeams[aTeam] then
		capturedUnits[unitID].aTeams[aTeam] = {
			totalDamage = 0,
			inControl = false,
			degradeTimer = GENERAL_DEGRADE_TIMER,
		}
	end
	
	-- check damage (armourmod, range falloff) if enabled
	local newCaptureDamage = captureWeaponDefs[weaponID].captureDamage
	if captureWeaponDefs[weaponID].scaleDamage then 
		newCaptureDamage = newCaptureDamage * (damage/WeaponDefs[weaponID].damages[0]) 
	end	--scale damage based on real damage (i.e. take into account armortypes etc.)
	-- scale damage based on target health
	local health, maxHealth = Spring.GetUnitHealth(unitID)
	if health <= 0 then health = 0.01 end
	newCaptureDamage = newCaptureDamage * (2 - (health/maxHealth))
	
	-- reset degrade timer for against this allyteam and add to damage
	capturedUnits[unitID].aTeams[aTeam].degradeTimer = GENERAL_DEGRADE_TIMER
	capturedUnits[unitID].aTeams[aTeam].totalDamage = capturedUnits[unitID].aTeams[aTeam].totalDamage + newCaptureDamage
	
	-- capture the unit if total damage is greater than max hp of unit
	if capturedUnits[unitID].aTeams[aTeam].totalDamage >= capturedUnits[unitID].captureHealth then 

		capturedUnits[unitID].aTeams[aTeam].totalDamage = capturedUnits[unitID].captureHealth
		
		for t, allyData in pairs(capturedUnits[unitID].aTeams) do
			if allyData.inControl then
				controllers[allyData.inControl].units[unitID] = nil
				controllers[allyData.inControl].unitCount = controllers[allyData.inControl].unitCount - 1
				updateControllerBar(allyData.inControl)
			end
			if aTeam ~= t then
				capturedUnits[unitID].aTeams[t] = nil
			end
		end
		
		capturedUnits[unitID].aTeams[aTeam].inControl = attackerID
		
		controllers[attackerID].unitCount = controllers[attackerID].unitCount + 1
		controllers[attackerID].units[unitID] = true
		
		if controllers[attackerID].postCaptureReload then
			local frame = Spring.GetGameFrame() + controllers[attackerID].postCaptureReload
			Spring.SetUnitRulesParam(attackerID, "selfReloadSpeedChange", 0, {inlos = true})
			Spring.SetUnitRulesParam(attackerID, "captureRechargeFrame", frame, {inlos = true})
			GG.UpdateUnitAttributes(attackerID)
			reloading[frame] = reloading[frame] or {count = 0, data = {}}
			reloading[frame].count = reloading[frame].count + 1
			reloading[frame].data[reloading[frame].count] = attackerID
			GG.attUnits[attackerID] = true
		end
	
		-- give the unit
		Spring.TransferUnit(unitID, attackerTeam, false)
		Spring.GiveOrderToUnit(unitID, CMD_STOP, {}, {})
		
		-- destroy the unit if the controller is set to destroy units
		if controllers[attackerID].killSubordinates and aTeam ~= capturedUnits[unitID].originAllyTeam then
			Spring.GiveOrderToUnit(unitID, CMD_SELFD, {}, {})
		end
	end
	
	updateControllerBar(attackerID)
	updateCapturedUnitBar(unitID)
	
	return 0
end


--------------------------------------------------------------------------------
-- Command Handling
local function KillToggleCommand(unitID, cmdParams, cmdOptions)
	if controllers[unitID] then
		local state = cmdParams[1]
		local cmdDescID = Spring.FindUnitCmdDesc(unitID, CMD_UNIT_KILL_SUBORDINATES)
		
		if (cmdDescID) then
			unitKillSubordinatesCmdDesc.params[1] = state
			Spring.EditUnitCmdDesc(unitID, cmdDescID, { params = unitKillSubordinatesCmdDesc.params})
		end
		controllers[unitID].killSubordinates = (state == 1)
	end
	
end

function gadget:AllowCommand(unitID, unitDefID, teamID, cmdID, cmdParams, cmdOptions)
	
	if (cmdID ~= CMD_UNIT_KILL_SUBORDINATES) then
		return true  -- command was not used
	end
	KillToggleCommand(unitID, cmdParams, cmdOptions)  
	return false  -- command was used
end


function gadget:UnitCreated(unitID, unitDefID, teamID)

	if not captureUnitDefs[unitDefID] then
		return
	end
	
	controllers[unitID] = {
		unitMax = captureUnitDefs[unitDefID].unitLimit,
		postCaptureReload = captureUnitDefs[unitDefID].postCaptureReload,
		units = {},
		unitCount = 0,
		killSubordinates = false,
	}
	
	Spring.SetUnitRulesParam(unitID,"cantfire",0, {inlos = true})
	
	Spring.InsertUnitCmdDesc(unitID, unitKillSubordinatesCmdDesc)
	KillToggleCommand(unitID, {0}, {})

end

function gadget:GameFrame(f)
    if (f-5) % 32 == 0 then
        for unitID, capData in pairs(capturedUnits) do
			local decay = false
			for aTeam, allyData in pairs(capData.aTeams) do
				allyData.degradeTimer = allyData.degradeTimer - 1
				if allyData.degradeTimer <= 0 and ((not allyData.inControl) or capData.originAllyTeam == aTeam) then
					local captureLoss = DEGRADE_FACTOR*capturedUnits[unitID].captureHealth
					if allyData.totalDamage <= captureLoss then
						removeTeamCaptureFromUnit(unitID, aTeam)
					else
						allyData.totalDamage = allyData.totalDamage - captureLoss
						updateCapturedUnitBar(unitID)
					end
				end
			end
        end
    end
	
	if reloading[f] then
		for i = 1, reloading[f].count do
			local unitID = reloading[f].data[i]
			Spring.SetUnitRulesParam(unitID, "selfReloadSpeedChange",1, {inlos = true})
			Spring.SetUnitRulesParam(unitID, "captureRechargeFrame", 0, {inlos = true})
			GG.UpdateUnitAttributes(unitID)
		end
		reloading[f] = false
	end
	
end

function gadget:UnitDestroyed(unitID)

	if controllers[unitID] then
		removeController(unitID, Spring.GetUnitTeam(unitID), Spring.GetUnitAllyTeam(unitID))
	end
	
	if capturedUnits[unitID] then
		removeCapturedUnit(unitID, false)
	end

end

-- ONLY WORKS FOR TRANSFER WITHIN ALLY TEAM
function gadget:UnitTaken(unitID, unitDefID, oldTeamID, teamID)
	
	if controllers[unitID] then
		local _,_,_,_,_,oldA = Spring.GetTeamInfo(oldTeamID)
		local _,_,_,_,_,newA = Spring.GetTeamInfo(teamID)
		if newA ~= oldA then
			Spring.Echo("Warning, Warning. Controller transfere between different Ally Teams. Expect things to break")
		end
	end
	
end

------------------------------------------------------

function gadget:Initialize()

	_G.controllers = controllers
	
	-- register command
	gadgetHandler:RegisterCMDID(CMD_UNIT_KILL_SUBORDINATES)
	
	-- load active units
	for _, unitID in ipairs(Spring.GetAllUnits()) do
		local unitDefID = Spring.GetUnitDefID(unitID)
		local teamID = Spring.GetUnitTeam(unitID)
		gadget:UnitCreated(unitID, unitDefID, teamID)
	end
	
end


--------------------------------------------------------------------------------
--------------------------------------------------------------------------------
--UNSYNCED
else
--------------------------------------------------------------------------------
--------------------------------------------------------------------------------

local glVertex 				= gl.Vertex
local spIsUnitInView 		= Spring.IsUnitInView
local spGetUnitPosition 	= Spring.GetUnitPosition
local spGetUnitLosState 	= Spring.GetUnitLosState
local spValidUnitID 		= Spring.ValidUnitID
local spGetMyAllyTeamID 	= Spring.GetMyAllyTeamID 	

local myTeam = spGetMyAllyTeamID()

local function DrawFunc(u1, u2)
	glVertex(spGetUnitPosition(u1))
	glVertex(spGetUnitPosition(u2))
end


function gadget:DrawWorld()

	local spec, fullview = Spring.GetSpectatingState()
	spec = spec or fullview

	if SYNCED.controllers and snext(SYNCED.controllers) then
		gl.PushAttrib(GL.LINE_BITS)
		
		gl.DepthTest(true)
		
		gl.LineWidth(2)
                gl.LineStipple('')
		local controllers = SYNCED.controllers
	
		for id, data in spairs(controllers) do
		
			if spValidUnitID(id) then
				for cid, damage in spairs(data.units) do
					local los1 = spGetUnitLosState(cid, myTeam, false)
					local los2 = spGetUnitLosState(id, myTeam, false)
					if spValidUnitID(cid) and (spec or (los1 and los1.los) or (los2 and los2.los)) and (spIsUnitInView(cid) or spIsUnitInView(id)) then
						gl.Color(1, 1, 1, 0.9)
						gl.BeginEnd(GL.LINES, DrawFunc, id, cid)
					end
				end
			end
	
		end
		
		gl.DepthTest(false)
		gl.Color(1,1,1,1)
        gl.LineStipple(false)
		
		gl.PopAttrib()
	end
	
end

--------------------------------------------------------------------------------
--------------------------------------------------------------------------------
end