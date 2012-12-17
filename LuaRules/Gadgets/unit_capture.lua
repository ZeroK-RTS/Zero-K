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

local DAMAGE_MULT = 3	-- n times faster when target is at 0% health

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
local spGetUnitIsDead       = Spring.GetUnitIsDead
local spValidUnitID         = Spring.ValidUnitID
local spGetUnitTeam         = Spring.GetUnitTeam
local spGetUnitAllyTeam     = Spring.GetUnitAllyTeam
local spTransferUnit        = Spring.TransferUnit
local spGiveOrderToUnit     = Spring.GiveOrderToUnit
local spGetTeamInfo         = Spring.GetTeamInfo
local spGetUnitHealth       = Spring.GetUnitHealth
local spGetGameFrame        = Spring.GetGameFrame
local spSetUnitRulesParam   = Spring.SetUnitRulesParam
local spFindUnitCmdDesc     = Spring.FindUnitCmdDesc
local spEditUnitCmdDesc     = Spring.EditUnitCmdDesc
local spInsertUnitCmdDesc   = Spring.InsertUnitCmdDesc

--------------------------------------------------------------------------------
--------------------------------------------------------------------------------

local captureWeaponDefs, captureUnitDefs = include("LuaRules/Configs/capture_defs.lua")

local damageByID = {data = {}, count = 0}
local unitDamage = {}

local capturedUnits = {}

local controllerByID = {data = {}, count = 0}
local controllers = {} 

local drawingByID = {data = {}, count = 0}
local drawing = {} 

local reloading = {}

local function checkThingsDoubleTable(things, thingByID)
	
	local covered = {}
	
	for i = 1, thingByID.count do
		local id = thingByID.data[i]
		if things[id].index == i then
			covered[id] = true
		else
			Spring.Echo("Thing with incorrect index")
			local bla = bla + 1
		end
	end
	
	for id,data in pairs(things) do
		if not covered[id] then
			Spring.Echo("Thing not covered")
			local bla = bla + 1
		end
	end
end

local function removeThingFromDoubleTable(id, things, thingByID)
	things[thingByID.data[thingByID.count] ].index = things[id].index
	thingByID.data[things[id].index] = thingByID.data[thingByID.count]
	thingByID.data[thingByID.count] = nil
	things[id] = nil
	thingByID.count = thingByID.count - 1
end

local function removeThingFromIterable(id, things, thingByID)
	things[thingByID.data[thingByID.count] ] = things[id]
	thingByID.data[things[id]] = thingByID.data[thingByID.count]
	thingByID.data[thingByID.count] = nil
	things[id] = nil
	thingByID.count = thingByID.count - 1
end

-- transfer with trees
local function recusivelyTransfer(unitID, newTeam, newAlly, newControllerID)
	if controllers[unitID] then
		local unitByID = controllers[unitID].unitByID
		local i = 1
		while i <= unitByID.count do
			local cid = unitByID.data[i]
			recusivelyTransfer(cid, newTeam, newAlly, unitID)
			if cid == unitByID.data[i] then
				i = i + 1
			end
		end
	end
	
	if spGetUnitIsDead(unitID) or not spValidUnitID(unitID) then
		return
	end
	
	if not capturedUnits[unitID] then
		capturedUnits[unitID] = {
			originTeam = spGetUnitTeam(unitID),
			originAllyTeam = spGetUnitAllyTeam(unitID),
			controllerID = nil,
			controllerAllyTeam = nil,
		}
	end
	
	if capturedUnits[unitID].originAllyTeam == newAlly then
		if capturedUnits[unitID].controllerID then
			local oldController = capturedUnits[unitID].controllerID
			removeThingFromIterable(unitID, controllers[oldController].units, controllers[oldController].unitByID)
			removeThingFromDoubleTable(unitID, drawing, drawingByID)
		end
		capturedUnits[unitID] = nil
	elseif newControllerID then
		if capturedUnits[unitID].controllerID ~= newControllerID then
			if capturedUnits[unitID].controllerID then
				local oldController = capturedUnits[unitID].controllerID
				removeThingFromIterable(unitID, controllers[oldController].units, controllers[oldController].unitByID)
				drawing[unitID].controller = newControllerID
			else
				drawingByID.count = drawingByID.count + 1
				drawingByID.data[drawingByID.count] = unitID
				drawing[unitID] = {
					index = drawingByID.count,
					controller = newControllerID,
				}
			end
			capturedUnits[unitID].controllerID = newControllerID
			capturedUnits[unitID].controllerAllyTeam = newAlly
			local unitByID = controllers[newControllerID].unitByID
			unitByID.count = unitByID.count + 1
			unitByID.data[unitByID.count] = unitID
			controllers[newControllerID].units[unitID] = unitByID.count
		end
	elseif capturedUnits[unitID].controllerID then
		local oldController = capturedUnits[unitID].controllerID
		removeThingFromIterable(unitID, controllers[oldController].units, controllers[oldController].unitByID)
		removeThingFromDoubleTable(unitID, drawing, drawingByID)
		capturedUnits[unitID] = nil
	end
	
	if unitDamage[unitID] then
		removeThingFromDoubleTable(unitID, unitDamage, damageByID)
	end
	spSetUnitHealth(unitID, {capture = 0} )
	
	spTransferUnit(unitID, newTeam, false)
	spGiveOrderToUnit(unitID, CMD_STOP, {}, {})
end

function gadget:UnitPreDamaged(unitID, unitDefID, unitTeam, damage, paralyzer, weaponID,
                            attackerID, attackerDefID, attackerTeam)
        
	if (not weaponID) or (not captureWeaponDefs[weaponID]) then 
		return damage
	end

	if ((not attackerTeam) or spAreTeamsAllied(unitTeam, attackerTeam)) then
		return 0
	end
	
	-- add stats that the unit requires for this gadget
	if not unitDamage[unitID] then
		damageByID.count = damageByID.count + 1
		damageByID.data[damageByID.count] = unitID
		unitDamage[unitID] = {
			index = damageByID.count,
			captureHealth = UnitDefs[unitDefID].buildTime,
			largestDamage = 0,
			allyTeamByID = {count = 0, data = {}},
			allyTeams = {},
		}
	end
	
	local damageData = unitDamage[unitID]
	local allyTeamByID = damageData.allyTeamByID
	local allyTeams = damageData.allyTeams
	
	-- add ally team stats
	local _,_,_,_,_,attackerAllyTeam = spGetTeamInfo(attackerTeam)
	if not allyTeams[attackerAllyTeam] then
		allyTeamByID.count = allyTeamByID.count + 1
		allyTeamByID.data[allyTeamByID.count] = attackerAllyTeam
		allyTeams[attackerAllyTeam] = {
			index = allyTeamByID.count,
			totalDamage = 0,
			degradeTimer = GENERAL_DEGRADE_TIMER,
		}
	end
	
	-- check damage (armourmod, range falloff) if enabled
	local newCaptureDamage = captureWeaponDefs[weaponID].captureDamage
	if captureWeaponDefs[weaponID].scaleDamage then 
		newCaptureDamage = newCaptureDamage * (damage/WeaponDefs[weaponID].damages[0]) 
	end	--scale damage based on real damage (i.e. take into account armortypes etc.)
	-- scale damage based on target health
	local health, maxHealth = spGetUnitHealth(unitID)
	if health <= 0 then 
		health = 0.01 
	end
	newCaptureDamage = newCaptureDamage * (DAMAGE_MULT - (DAMAGE_MULT - 1)*(health/maxHealth))
	
	local allyTeamData = allyTeams[attackerAllyTeam]
	
	-- reset degrade timer for against this allyteam and add to damage
	allyTeamData.degradeTimer = GENERAL_DEGRADE_TIMER
	allyTeamData.totalDamage = allyTeamData.totalDamage + newCaptureDamage
	
	-- capture the unit if total damage is greater than max hp of unit
	if allyTeamData.totalDamage >= damageData.captureHealth then

		-- give the unit
		recusivelyTransfer(unitID, attackerTeam, attackerAllyTeam, attackerID)
		
		-- reload handling
		if controllers[attackerID].postCaptureReload then
			local gameFrame = spGetGameFrame()
			local frame = gameFrame + controllers[attackerID].postCaptureReload
			spSetUnitRulesParam(attackerID, "selfReloadSpeedChange", 0, {inlos = true})
			spSetUnitRulesParam(attackerID, "captureRechargeFrame", frame, {inlos = true})
			GG.UpdateUnitAttributes(attackerID, gameFrame)
			reloading[frame] = reloading[frame] or {count = 0, data = {}}
			reloading[frame].count = reloading[frame].count + 1
			reloading[frame].data[reloading[frame].count] = attackerID
			GG.attUnits[attackerID] = true
		end
		
		-- destroy the unit if the controller is set to destroy units
		if controllers[attackerID].killSubordinates and attackerAllyTeam ~= capturedUnits[unitID].originAllyTeam then
			spGiveOrderToUnit(unitID, CMD_SELFD, {}, {})
		end
		return 0
	end
	
	if damageData.largestDamage < allyTeamData.totalDamage then
		damageData.largestDamage = allyTeamData.totalDamage
		spSetUnitHealth(unitID, {capture = damageData.largestDamage/damageData.captureHealth} )
	end
	
	return 0
end

--------------------------------------------------------------------------------
-- Update

function gadget:GameFrame(f)
    if (f-5) % 32 == 0 then
		local i = 1
		while i <= damageByID.count do
			local unitID = damageByID.data[i]
			local damageData = unitDamage[unitID]
			local allyTeamByID = damageData.allyTeamByID
			local allyTeams = damageData.allyTeams
			local largestDamage = 0
			local j = 1
			while j <= allyTeamByID.count do
				local allyTeamID = allyTeamByID.data[j]
				local allyData = allyTeams[allyTeamID]
				if allyData.degradeTimer <= 0 then
					local captureLoss = DEGRADE_FACTOR*damageData.captureHealth
					if allyData.totalDamage <= captureLoss then
						removeThingFromDoubleTable(allyTeamID, allyTeams, allyTeamByID)
					else
						allyData.totalDamage = allyData.totalDamage - captureLoss
						if largestDamage < allyData.totalDamage then
							largestDamage = allyData.totalDamage
						end
						j = j + 1
					end
				else
					allyData.degradeTimer = allyData.degradeTimer - 1
					if largestDamage < allyData.totalDamage then
						largestDamage = allyData.totalDamage
					end
				end
			end
			
			if largestDamage == 0 then
				removeThingFromDoubleTable(unitID, unitDamage, damageByID)
				spSetUnitHealth(unitID, {capture = 0} )
			else
				damageData.largestDamage = largestDamage
				spSetUnitHealth(unitID, {capture = damageData.largestDamage/damageData.captureHealth} )
				i = i + 1
			end
        end
    end
	
	if reloading[f] then
		for i = 1, reloading[f].count do
			local unitID = reloading[f].data[i]
			spSetUnitRulesParam(unitID, "selfReloadSpeedChange",1, {inlos = true})
			spSetUnitRulesParam(unitID, "captureRechargeFrame", 0, {inlos = true})
			GG.UpdateUnitAttributes(unitID, f)
		end
		reloading[f] = nil
	end
end

--------------------------------------------------------------------------------
-- Command Handling
local function KillToggleCommand(unitID, cmdParams, cmdOptions)
	if controllers[unitID] then
		local state = cmdParams[1]
		local cmdDescID = spFindUnitCmdDesc(unitID, CMD_UNIT_KILL_SUBORDINATES)
		
		if (cmdDescID) then
			unitKillSubordinatesCmdDesc.params[1] = state
			spEditUnitCmdDesc(unitID, cmdDescID, { params = unitKillSubordinatesCmdDesc.params})
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


--------------------------------------------------------------------------------
-- Unit Handling


function gadget:UnitCreated(unitID, unitDefID, teamID)

	if not captureUnitDefs[unitDefID] then
		return
	end
	
	controllerByID.count = controllerByID.count + 1
	controllerByID.data[controllerByID.count] = unitID
	
	controllers[unitID] = {
		index = controllerByID.count,
		postCaptureReload = captureUnitDefs[unitDefID].postCaptureReload,
		units = {},
		unitByID = {count = 0, data = {}},
		killSubordinates = false,
	}
	
	spSetUnitRulesParam(unitID,"cantfire",0, {inlos = true})
	
	spInsertUnitCmdDesc(unitID, unitKillSubordinatesCmdDesc)
	KillToggleCommand(unitID, {0}, {})

end


function gadget:UnitDestroyed(unitID)

	if controllers[unitID] then
		local unitByID = controllers[unitID].unitByID
		local i = 1
		while i <= unitByID.count do
			local cid = unitByID.data[i]
			recusivelyTransfer(cid, capturedUnits[cid].originTeam, capturedUnits[cid].originAllyTeam, unitID)
			if cid == unitByID.data[i] then
				i = i + 1
			end
		end
		removeThingFromDoubleTable(unitID, controllers, controllerByID)
	end
	
	if capturedUnits[unitID] then
		if capturedUnits[unitID].controllerID then
			removeThingFromIterable(unitID, controllers[capturedUnits[unitID].controllerID].units, controllers[capturedUnits[unitID].controllerID].unitByID)
		end
	end
	
	if unitDamage[unitID] then
		removeThingFromDoubleTable(unitID, unitDamage, damageByID)
	end

end

------------------------------------------------------

function gadget:Initialize()

	_G.drawing = drawing
	_G.drawingByID = drawingByID
	
	-- register command
	gadgetHandler:RegisterCMDID(CMD_UNIT_KILL_SUBORDINATES)
	
	-- load active units
	for _, unitID in ipairs(Spring.GetAllUnits()) do
		local unitDefID = spGetUnitDefID(unitID)
		local teamID = spGetUnitTeam(unitID)
		gadget:UnitCreated(unitID, unitDefID, teamID)
	end
	
end


--------------------------------------------------------------------------------
--------------------------------------------------------------------------------
--UNSYNCED
else
--------------------------------------------------------------------------------
--------------------------------------------------------------------------------

local spIsUnitInView 		= Spring.IsUnitInView
local spGetUnitPosition 	= Spring.GetUnitPosition
local spGetUnitLosState 	= Spring.GetUnitLosState
local spValidUnitID 		= Spring.ValidUnitID
local spGetMyAllyTeamID 	= Spring.GetMyAllyTeamID 	
local spGetGameFrame        = Spring.GetGameFrame
local spGetSpectatingState  = Spring.GetSpectatingState

local glVertex 		= gl.Vertex
local glPushAttrib  = gl.PushAttrib
local glLineStipple = gl.LineStipple
local glDepthTest   = gl.DepthTest
local glLineWidth   = gl.LineWidth
local glColor       = gl.Color
local glBeginEnd    = gl.BeginEnd
local glPopAttrib   = gl.PopAttrib
local glCreateList  = gl.CreateList
local glCallList    = gl.CallList
local glDeleteList  = gl.DeleteList
local GL_LINES      = GL.LINES

local myTeam = spGetMyAllyTeamID()

local drawList = 0
local drawAnything = false

function gadget:DrawWorld()
    if drawAnything then
        glPushAttrib(GL.LINE_BITS)
		glDepthTest(true)
		glLineWidth(2)
        glLineStipple('')
        glColor(1, 1, 1, 0.9)
        glCallList(drawList)
        glColor(1,1,1,1)
        glLineStipple(false)
        glPopAttrib()
    end
end

local function drawFunc(drawing, drawingByID, spec)
	for i = 1, drawingByID.count do
		local controliee = drawingByID.data[i]
		local controller = drawing[controliee].controller
		if spValidUnitID(controliee) and spValidUnitID(controller) then
			local los1 = spGetUnitLosState(controliee, myTeam, false)
			local los2 = spGetUnitLosState(controller, myTeam, false)
			if (spec or (los1 and los1.los) or (los2 and los2.los)) and (spIsUnitInView(controliee) or spIsUnitInView(controller)) then
				 local _,_,_,x1, y1, z1 = spGetUnitPosition(controller, true)
				 local _,_,_,x2, y2, z2 = spGetUnitPosition(controliee, true)
				 glVertex(x1, y1, z1)
				 glVertex(x2, y2, z2)
			end
		end
	end
end

local function gameFrame()
	if SYNCED.drawing and SYNCED.drawingByID then
		local spec, fullview = spGetSpectatingState()
		spec = spec or fullview
		local drawing = SYNCED.drawing
		local drawingByID = SYNCED.drawingByID
		glDeleteList(drawList)
		
		if drawingByID.count ~= 0 then
			drawAnything = true
			drawList = glCreateList(function () glBeginEnd(GL_LINES, drawFunc, drawing, drawingByID, spec) end)
		else
			drawAnything = false
		end
	else
		drawAnything = false
	end
end

local lastFrame = 0
function gadget:Update()
    local f = spGetGameFrame()
    if lastFrame < f then
        lastFrame = f
        gameFrame()
    end
end

--------------------------------------------------------------------------------
--------------------------------------------------------------------------------
end