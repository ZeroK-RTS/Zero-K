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

local RETAKING_DEGRADE_TIMER = 5
local GENERAL_DEGRADE_TIMER = 2
local DEGRADE_FACTOR = 0.2

local CMD_UNIT_KILL_SUBORDINATES = 35821
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
controllers = {}

-- updates capture bar for controllers
local function updateControllerBar(unitID)
	if controllers[unitID].captureMax then
		spSetUnitHealth(unitID, {capture = controllers[unitID].captureUsed/controllers[unitID].captureMax} )
	end
end

-- remove all capture damage from a unit, does not transfere unit
local function removeCapturedUnit(unitID, alive)
	
	for aTeam, allyData in pairs(capturedUnits[unitID].aTeams) do
		for id, data in pairs(allyData.attackers) do
			controllers[id].captureUsed = controllers[id].captureUsed - controllers[id].units[unitID].damage
			controllers[id].units[unitID] = nil
			controllers[id].unitCount = controllers[id].unitCount - 1
			updateControllerBar(id)
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

-- updates capture bar for other units. Condition is allyTeam damage is the only damage that has increased. 
-- Also checks for units that should no longer be handled
local function updateCapturedUnitBarForTeam(unitID, allyTeam)
	if capturedUnits[unitID].aTeams[allyTeam].inControl then
		updateCapturedUnitBar(unitID)
	elseif capturedUnits[unitID].aTeams[allyTeam].totalDamage > capturedUnits[unitID].largestCaptureFromAnyOneTeam then
		capturedUnits[unitID].largestCaptureFromAnyOneTeam = capturedUnits[unitID].aTeams[allyTeam].totalDamage
		spSetUnitHealth(unitID, {capture = capturedUnits[unitID].largestCaptureFromAnyOneTeam/capturedUnits[unitID].captureHealth} )
	end
end

-- frees all subordinates from a controller and removes the unit
local function removeController(unitID, team, aTeam)
	
	for id, data in pairs(controllers[unitID].units) do
		capturedUnits[id].aTeams[aTeam].totalDamage = capturedUnits[id].aTeams[aTeam].totalDamage - data.damage
		capturedUnits[id].aTeams[aTeam].teams[team].damage = capturedUnits[id].aTeams[aTeam].teams[team].damage - data.damage
		capturedUnits[id].aTeams[aTeam].attackers[unitID] = nil
		
		if capturedUnits[id].aTeams[aTeam].inControl then
			Spring.TransferUnit(id, capturedUnits[id].originTeam, false)
			capturedUnits[id].aTeams[aTeam].inControl = false
		end
		
		updateCapturedUnitBar(id)
	end
	
	controllers[unitID] = nil
end

local function transferController(unitID, aTeam, oldTeam, newTeam)

	for id, data in pairs(controllers[unitID].units) do
		capturedUnits[id].aTeams[aTeam].teams[oldTeam].damage = capturedUnits[id].aTeams[aTeam].teams[oldTeam].damage - data.damage
		capturedUnits[id].aTeams[aTeam].teams[newTeam].damage = capturedUnits[id].aTeams[aTeam].teams[newTeam].damage + data.damage
	end
	
end

-- removes capture damage dealt by teams other than allyTeam, does not transfere unit
local function removeOtherCaptureFromUnit(unitID, allyTeam)
	
	if capturedUnits[unitID].originAllyTeam == allyTeam then
		capturedUnits[unitID].aTeams[allyTeam].degradeTimer = RETAKING_DEGRADE_TIMER
	end
	
	for aTeam, allyData in pairs(capturedUnits[unitID].aTeams) do
		if allyTeam ~= aTeam then
			
			for id, data in pairs(allyData.attackers) do
				controllers[id].captureUsed = controllers[id].captureUsed - controllers[id].units[unitID].damage
				controllers[id].units[unitID] = nil
				controllers[id].unitCount = controllers[id].unitCount - 1
				updateControllerBar(id)
			end
			capturedUnits[unitID].aTeams[aTeam] = nil
		end
	end
	
	updateCapturedUnitBar(unitID)
end

-- removes capture damage dealt by allyTeam from the unit
local function removeTeamCaptureFromUnit(unitID, allyTeam)
	
	for id, data in pairs(capturedUnits[unitID].aTeams[allyTeam].attackers) do
		controllers[id].captureUsed = controllers[id].captureUsed - controllers[id].units[unitID].damage
		controllers[id].units[unitID] = nil
		controllers[id].unitCount = controllers[id].unitCount - 1
		updateControllerBar(id)
	end
	capturedUnits[unitID].aTeams[allyTeam] = nil
	
	updateCapturedUnitBar(unitID)
end

function gadget:UnitPreDamaged(unitID, unitDefID, unitTeam, damage, paralyzer, weaponID,
                            attackerID, attackerDefID, attackerTeam)
        
	if (not weaponID) or (not captureWeaponDefs[weaponID]) then 
		return damage
	end

	if ((not attackerTeam) or spAreTeamsAllied(unitTeam, attackerTeam)) or controllers[unitID] 
			or ((not controllers[attackerID].units[unitID]) and controllers[attackerID].unitMax and controllers[attackerID].unitMax <= controllers[attackerID].unitCount) 
			or (controllers[attackerID].units[unitID] and controllers[attackerID].unitMax and controllers[attackerID].unitMax < controllers[attackerID].unitCount) then
		return 0
	end
	
	-- add stats that the unit requires for this gadget
	if not capturedUnits[unitID] then
		capturedUnits[unitID] = {
			captureHealth = UnitDefs[unitDefID].buildTime,
			originTeam = unitTeam,
			originAllyTeam = Spring.GetUnitAllyTeam(unitID),
			aTeams = {},
			largestCaptureFromAnyOneTeam = 0,
		}
	end
	
	-- add ally team stats
	local _,_,_,_,_,aTeam = Spring.GetTeamInfo(attackerTeam)
	if not capturedUnits[unitID].aTeams[aTeam] then
		capturedUnits[unitID].aTeams[aTeam] = {
			totalDamage = 0,
			inControl = false,
			degradeTimer = GENERAL_DEGRADE_TIMER,
			teams = {},
			attackers = {},
		}
	end
	
	-- add player team stats
	if not capturedUnits[unitID].aTeams[aTeam].teams[attackerTeam] then
		capturedUnits[unitID].aTeams[aTeam].teams[attackerTeam] = {
			damage = 0,
		}
	end
	
	-- add damage
	local newCaptureDamage = captureWeaponDefs[weaponID].captureDamage
	if captureWeaponDefs[weaponID].scaleDamage then 
		newCaptureDamage = newCaptureDamage * (damage/WeaponDefs[weaponID].damages[0]) 
	end	--scale damage based on real damage (i.e. take into account armortypes etc.)
	
	-- reset degrade timer for against this allyteam
	capturedUnits[unitID].aTeams[aTeam].degradeTimer = GENERAL_DEGRADE_TIMER
	
	-- if the attacker cannot capture any more units return
	if controllers[attackerID].captureMax and controllers[attackerID].captureUsed == controllers[attackerID].captureMax then
		return 0
	end
	
	-- the captured unit rememeber the unitID of it's attacker
	capturedUnits[unitID].aTeams[aTeam].attackers[attackerID] = true
	
	-- take up attacker capture quota
	controllers[attackerID].captureUsed = controllers[attackerID].captureUsed + newCaptureDamage
	
	-- check for values over the capture quota
	if controllers[attackerID].captureMax and controllers[attackerID].captureUsed > controllers[attackerID].captureMax then
		local excessCapture = controllers[attackerID].captureUsed - controllers[attackerID].captureMax
		newCaptureDamage = newCaptureDamage - excessCapture
		controllers[attackerID].captureUsed = controllers[attackerID].captureMax
	end
	
	-- controller remember how much it is controlling the target unit
	if not controllers[attackerID].units[unitID] then
		controllers[attackerID].units[unitID] = {damage = 0}
		controllers[attackerID].unitCount = controllers[attackerID].unitCount + 1
	end
	controllers[attackerID].units[unitID].damage = controllers[attackerID].units[unitID].damage + newCaptureDamage
	
	-- add to damage by Team and total damage by AllyTeam
	capturedUnits[unitID].aTeams[aTeam].teams[attackerTeam].damage = capturedUnits[unitID].aTeams[aTeam].teams[attackerTeam].damage + newCaptureDamage
	capturedUnits[unitID].aTeams[aTeam].totalDamage = capturedUnits[unitID].aTeams[aTeam].totalDamage + newCaptureDamage
	
	-- capture the unit if total damage is greater than max hp of unit
	if capturedUnits[unitID].aTeams[aTeam].totalDamage >= capturedUnits[unitID].captureHealth then 
		
		-- put a maximun on capture damage for a unit to HP
		local excessCapture = capturedUnits[unitID].aTeams[aTeam].totalDamage - capturedUnits[unitID].captureHealth
		controllers[attackerID].captureUsed = controllers[attackerID].captureUsed - excessCapture
		controllers[attackerID].units[unitID].damage = controllers[attackerID].units[unitID].damage - excessCapture
		capturedUnits[unitID].aTeams[aTeam].teams[attackerTeam].damage = capturedUnits[unitID].aTeams[aTeam].teams[attackerTeam].damage - excessCapture
		capturedUnits[unitID].aTeams[aTeam].totalDamage = capturedUnits[unitID].captureHealth
		
		capturedUnits[unitID].aTeams[aTeam].inControl = true
		
		-- decide which player on the allyteam controls the unit
		
		-- find the player or players with the most control damage on the unit
		local controllingPlayers = {count = 0, team = {}}
		local maxCapture = 0
		for teamID, data in pairs(capturedUnits[unitID].aTeams[aTeam].teams) do
			if data.damage == maxCapture then
				controllingPlayers.count = controllingPlayers.count + 1
				controllingPlayers[controllingPlayers.count] = teamID
			elseif data.damage > maxCapture then
				controllingPlayers = {count = 1, team = {[1] = teamID}}
			end
		end
		
		-- give it to a random player with the most damage
		local transferePlayer
		local rand = math.random()
		local total = 0
		for i = 1, controllingPlayers.count do
			if rand < i/controllingPlayers.count then
				transferePlayer = controllingPlayers.team [i]
				break 
			end
		end
	
		-- give the unit
		Spring.TransferUnit(unitID, transferePlayer, false)
		Spring.GiveOrderToUnit(unitID, CMD_STOP, {}, {})
		
		-- destroy the unit if the controller is set to destroy units
		if controllers[attackerID].killSubordinates and aTeam ~= capturedUnits[unitID].originAllyTeam then
			Spring.GiveOrderToUnit(unitID, CMD_SELFD, {}, {})
		end
		
		removeOtherCaptureFromUnit(unitID, aTeam)
	end
	
	updateCapturedUnitBarForTeam(unitID, aTeam)
	updateControllerBar(attackerID)
	
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
		captureMax = captureUnitDefs[unitDefID].captureQuota,
		unitMax = captureUnitDefs[unitDefID].unitLimit,
		captureUsed = 0,
		units = {},
		unitCount = 0,
		killSubordinates = false,
	}
	
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
						for team, teamData in pairs(allyData.teams) do
							teamData.damage = teamData.damage - captureLoss*teamData.damage/allyData.totalDamage
						end
						for aid, _ in pairs(allyData.attackers) do
							controllers[aid].captureUsed = controllers[aid].captureUsed - captureLoss*controllers[aid].units[unitID].damage/allyData.totalDamage
							controllers[aid].units[unitID].damage = controllers[aid].units[unitID].damage - captureLoss*controllers[aid].units[unitID].damage/allyData.totalDamage
							updateControllerBar(aid)
						end
						allyData.totalDamage = allyData.totalDamage - captureLoss
						updateCapturedUnitBar(unitID)
					end
				end
			end
        end
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
		else
			transferController(unitID, newA, oldTeamID, newTeamID)
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
		local controllers = SYNCED.controllers
	
		for id, data in spairs(controllers) do
		
			if spValidUnitID(id) then
				for cid, damage in spairs(data.units) do
					local los1 = spGetUnitLosState(cid, myTeam, false)
					local los2 = spGetUnitLosState(id, myTeam, false)
					if spValidUnitID(cid) and (spec or (los1 and los1.los) or (los2 and los2.los)) and (spIsUnitInView(cid) or spIsUnitInView(id)) then
						local color 
						if data.captureMax then
							color = damage.damage/data.captureMax
						else
							color = 1
						end
						gl.Color(color, color, color, 0.9)
						gl.BeginEnd(GL.LINES, DrawFunc, id, cid)
					end
				end
			end
	
		end
		
		gl.DepthTest(false)
		gl.Color(1,1,1,1)
		
		gl.PopAttrib()
	end
	
end

--------------------------------------------------------------------------------
--------------------------------------------------------------------------------
end