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
local GENERAL_DEGRADE_TIMER  = 5
local DEGRADE_FACTOR         = 0.04
local CAPTURE_LINGER         = 0.95
local FIREWALL_HEALTH        = 500

local DAMAGE_MULT = 3 -- n times faster when target is at 0% health

local SAVE_FILE = "Gadgets/unit_capture.lua"

include("LuaRules/Configs/customcmds.h.lua")
local CMD_STOP = CMD.STOP
local CMD_SELFD = CMD.SELFD

local unitKillSubordinatesCmdDesc = {
	id      = CMD_UNIT_KILL_SUBORDINATES,
	type    = CMDTYPE.ICON_MODE,
	name    = 'Kill Subordinates',
	action  = 'killsubordinates',
	tooltip = 'Toggles auto self-d of captured units',
	params  = {0, 'Kill Off','Kill On'}
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

local LOS_ACCESS = {inlos = true}

--------------------------------------------------------------------------------
--------------------------------------------------------------------------------

local captureWeaponDefs, captureUnitDefs = include("LuaRules/Configs/capture_defs.lua")

local damageByID = {data = {}, count = 0}
local unitDamage = {}
local capturedUnits = {}
local controllers = {}
local reloading = {}

--------------------------------------------------------------------------------
-- For gadget:Save
--------------------------------------------------------------------------------
local function UpdateSaveReferences()
	_G.unitDamage    = unitDamage
	_G.capturedUnits = capturedUnits
	_G.controllers   = controllers
	_G.reloading     = reloading
end
UpdateSaveReferences()

--------------------------------------------------------------------------------
--------------------------------------------------------------------------------
-- Utilities

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
local function recusivelyTransfer(unitID, newTeam, newAlly, newControllerID, oldTeamCaptureLinger)
	if controllers[unitID] then
		local unitByID = controllers[unitID].unitByID
		local i = 1
		while i <= unitByID.count do
			local cid = unitByID.data[i]
			recusivelyTransfer(cid, newTeam, newAlly, unitID, oldTeamCaptureLinger)
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
			spSetUnitRulesParam(unitID, "capture_controller", -1, LOS_ACCESS)
		end
		capturedUnits[unitID] = nil
	elseif newControllerID then
		if capturedUnits[unitID].controllerID ~= newControllerID then
			if capturedUnits[unitID].controllerID then
				local oldController = capturedUnits[unitID].controllerID
				removeThingFromIterable(unitID, controllers[oldController].units, controllers[oldController].unitByID)
			end
			spSetUnitRulesParam(unitID, "capture_controller", newControllerID, LOS_ACCESS)
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
		spSetUnitRulesParam(unitID, "capture_controller", -1, LOS_ACCESS)
		capturedUnits[unitID] = nil
	end
	
	if oldTeamCaptureLinger then
		if unitDamage[unitID] then
			removeThingFromDoubleTable(unitID, unitDamage, damageByID)
		end
		
		damageByID.count = damageByID.count + 1
		damageByID.data[damageByID.count] = unitID
		
		local maxHealth = (select(2, Spring.GetUnitHealth(unitID)) or 0) + FIREWALL_HEALTH
		local damageData = {
			index = damageByID.count,
			captureHealth = maxHealth,
			largestDamage = 0,
			allyTeamByID = {count = 0, data = {}},
			allyTeams = {},
		}
		local allyTeamByID = damageData.allyTeamByID
		local allyTeams = damageData.allyTeams
		
		-- add ally team stats
		local _,_,_,_,_,attackerAllyTeam = spGetTeamInfo(oldTeamCaptureLinger, false)
		if not allyTeams[attackerAllyTeam] then
			allyTeamByID.count = allyTeamByID.count + 1
			allyTeamByID.data[allyTeamByID.count] = attackerAllyTeam
			allyTeams[attackerAllyTeam] = {
				index = allyTeamByID.count,
				totalDamage = 0,
				degradeTimer = GENERAL_DEGRADE_TIMER,
			}
		end
		
		local allyTeamData = allyTeams[attackerAllyTeam]
		allyTeamData.degradeTimer = GENERAL_DEGRADE_TIMER
		allyTeamData.totalDamage = damageData.captureHealth*CAPTURE_LINGER
		
		damageData.largestDamage = allyTeamData.totalDamage
		spSetUnitHealth(unitID, {capture = damageData.largestDamage/damageData.captureHealth} )
		
		unitDamage[unitID] = damageData
	else
		if unitDamage[unitID] then
			removeThingFromDoubleTable(unitID, unitDamage, damageByID)
		end
		spSetUnitHealth(unitID, {capture = 0})
	end
	
	spTransferUnit(unitID, newTeam, false)
	spGiveOrderToUnit(unitID, CMD_STOP, {}, 0)
end

--------------------------------------------------------------------------------
--------------------------------------------------------------------------------
-- Weapon Handling

function gadget:UnitPreDamaged_GetWantedWeaponDef()
	local wantedWeaponList = {}
	for wdid = 1, #WeaponDefs do
		if captureWeaponDefs[wdid] then
			wantedWeaponList[#wantedWeaponList + 1] = wdid
		end
	end
	return wantedWeaponList
end

function gadget:UnitPreDamaged(unitID, unitDefID, unitTeam, damage, paralyzer, weaponID,attackerID, attackerDefID, attackerTeam)
	if (not weaponID) or (not captureWeaponDefs[weaponID]) then
		return damage
	end

	if ((not attackerTeam) or spAreTeamsAllied(unitTeam, attackerTeam) or (damage == 0)) then
		return 0
	end
	
	-- add stats that the unit requires for this gadget
	local health, maxHealth, _, _, build = spGetUnitHealth(unitID)
	maxHealth = maxHealth + FIREWALL_HEALTH
	if not unitDamage[unitID] then
		damageByID.count = damageByID.count + 1
		damageByID.data[damageByID.count] = unitID
		
		unitDamage[unitID] = {
			index = damageByID.count,
			captureHealth = maxHealth,
			largestDamage = 0,
			allyTeamByID = {count = 0, data = {}},
			allyTeams = {},
		}
	end
	
	local damageData = unitDamage[unitID]
	local allyTeamByID = damageData.allyTeamByID
	local allyTeams = damageData.allyTeams
	
	-- add ally team stats
	local _,_,_,_,_,attackerAllyTeam = spGetTeamInfo(attackerTeam, false)
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
	local def = captureWeaponDefs[weaponID]
	local newCaptureDamage = def.captureDamage
	if def.scaleDamage then
		newCaptureDamage = newCaptureDamage * (damage/def.baseDamage)
	end
	-- scale damage based on real damage (i.e. take into account armortypes etc.)
	health = health + FIREWALL_HEALTH
	newCaptureDamage = newCaptureDamage * (maxHealth/health)
	
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
			local captureReloadMult = (((not build) or build == 1) and 1) or (build*0.5)
			local frame = gameFrame + math.floor(controllers[attackerID].postCaptureReload*captureReloadMult)
			spSetUnitRulesParam(attackerID, "selfReloadSpeedChange", 0, LOS_ACCESS)
			spSetUnitRulesParam(attackerID, "captureRechargeFrame", frame, LOS_ACCESS)
			GG.UpdateUnitAttributes(attackerID, gameFrame)
			reloading[frame] = reloading[frame] or {count = 0, data = {}}
			reloading[frame].count = reloading[frame].count + 1
			reloading[frame].data[reloading[frame].count] = attackerID
		end
		
		-- destroy the unit if the controller is set to destroy units
		if controllers[attackerID].killSubordinates and attackerAllyTeam ~= (capturedUnits[unitID] or {}).originAllyTeam then
			spGiveOrderToUnit(unitID, CMD_SELFD, {}, 0)
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
--------------------------------------------------------------------------------
-- Update

function gadget:GameFrame(f)
	if (f - 5)%32 == 0 then
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
					j = j + 1
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
			spSetUnitRulesParam(unitID, "selfReloadSpeedChange",1, LOS_ACCESS)
			spSetUnitRulesParam(unitID, "captureRechargeFrame", 0, LOS_ACCESS)
			GG.UpdateUnitAttributes(unitID, f)
		end
		reloading[f] = nil
	end
end

--------------------------------------------------------------------------------
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

function gadget:AllowCommand_GetWantedCommand()
	return {[CMD_UNIT_KILL_SUBORDINATES] = true}
end

function gadget:AllowCommand_GetWantedUnitDefID()
	local wanted = {}
	for unitID, _ in pairs(captureUnitDefs) do
		wanted[unitID] = true
	end
	return wanted
end

function gadget:AllowCommand(unitID, unitDefID, teamID, cmdID, cmdParams, cmdOptions)
	if (cmdID ~= CMD_UNIT_KILL_SUBORDINATES) then
		return true  -- command was not used
	end
	KillToggleCommand(unitID, cmdParams, cmdOptions)
	return false  -- command was used
end

--------------------------------------------------------------------------------
--------------------------------------------------------------------------------
-- Unit Handling

local function GetActiveTeam(teamID, allyTeamID)
	if not GG.Lagmonitor then
		return teamID
	end
	local allyTeamResourceShares, teamResourceShare = GG.Lagmonitor.GetResourceShares()
	if teamResourceShare[teamID] ~= 0 or allyTeamResourceShares[allyTeamID] == 0 then
		return teamID
	end
	
	local teamList = Spring.GetTeamList(allyTeamID)
	for i = 1, #teamList do
		if teamResourceShare[teamList[i]] ~= 0 then
			return teamList[i]
		end
	end
	
	return teamID
end

function gadget:UnitCreated(unitID, unitDefID, teamID)
	if not captureUnitDefs[unitDefID] then
		return
	end
	
	controllers[unitID] = {
		postCaptureReload = captureUnitDefs[unitDefID].postCaptureReload,
		units = {},
		unitByID = {count = 0, data = {}},
		killSubordinates = false,
	}
	
	spSetUnitRulesParam(unitID,"cantfire",0, LOS_ACCESS)
	
	spInsertUnitCmdDesc(unitID, unitKillSubordinatesCmdDesc)
	KillToggleCommand(unitID, {0}, {})
end

function gadget:UnitDestroyed(unitID, unitDefID, unitTeamID)
	if controllers[unitID] then
		-- This was a mastermind, transfer captured units
		local unitByID = controllers[unitID].unitByID
		local i = 1
		while i <= unitByID.count do
			local cid = unitByID.data[i]
			local transferTeamID = GetActiveTeam(capturedUnits[cid].originTeam, capturedUnits[cid].originAllyTeam)
			recusivelyTransfer(cid, transferTeamID, capturedUnits[cid].originAllyTeam, unitID, unitTeamID)
			if cid == unitByID.data[i] then
				i = i + 1
			end
		end
		controllers[unitID] = nil
	end
	
	if capturedUnits[unitID] then
		-- This was a captured unit, update our references
		if capturedUnits[unitID].controllerID then
			local oldController = capturedUnits[unitID].controllerID
			removeThingFromIterable(unitID, controllers[oldController].units, controllers[oldController].unitByID)
		end
		capturedUnits[unitID] = nil
	end
	

	if unitDamage[unitID] then
		-- This was a partially captured unit
		local morphedTo = Spring.GetUnitRulesParam(unitID, "wasMorphedTo")
		if morphedTo then
			-- Psuedo-destruction from a morph, transfer capture progress
			unitDamage[morphedTo] = unitDamage[unitID]
			damageByID.data[unitDamage[unitID].index] = morphedTo
			unitDamage[unitID] = nil
		else
			-- True destruction, discard the capture progress we were tracking
			removeThingFromDoubleTable(unitID, unitDamage, damageByID)
		end
	end
end

--------------------------------------------------------------------------------
--------------------------------------------------------------------------------
-- External Functions

local externalFunctions = {}

function externalFunctions.SetMastermind(unitID, originTeam, originAllyTeam, controllerID, controllerAllyTeam)
	capturedUnits[unitID] = {
		originTeam = originTeam,
		originAllyTeam = originAllyTeam,
		controllerID = controllerID,
		controllerAllyTeam = controllerAllyTeam,
	}
	
	spSetUnitRulesParam(unitID, "capture_controller", controllerID, LOS_ACCESS)
	
	local unitByID = controllers[controllerID].unitByID
	unitByID.count = unitByID.count + 1
	unitByID.data[unitByID.count] = unitID
	controllers[controllerID].units[unitID] = unitByID.count
end

function externalFunctions.GetMastermind(unitID)
	local ca = capturedUnits[unitID]
	if ca ~= nil then
		return ca.originTeam, ca.originAllyTeam, ca.controllerID, ca.controllerAllyTeam
	else
		return nil
	end
end

--------------------------------------------------------------------------------
--------------------------------------------------------------------------------

function gadget:Initialize()
	-- morph uses this
	GG.Capture = externalFunctions
	
	-- register command
	gadgetHandler:RegisterCMDID(CMD_UNIT_KILL_SUBORDINATES)
	
	-- load active units
	for _, unitID in ipairs(Spring.GetAllUnits()) do
		local unitDefID = spGetUnitDefID(unitID)
		local teamID = spGetUnitTeam(unitID)
		gadget:UnitCreated(unitID, unitDefID, teamID)
	end
end

function gadget:Load(zip)
	if not (GG.SaveLoad and GG.SaveLoad.ReadFile) then
		Spring.Log(gadget:GetInfo().name, LOG.ERROR, "Capture failed to access save/load API")
		return
	end
	
	local loadData = GG.SaveLoad.ReadFile(zip, "Capture", SAVE_FILE) or {}

	local loadGameFrame = Spring.GetGameRulesParam("lastSaveGameFrame") or 0
	
	-- Reset data (something may have triggered during unit creation).
	damageByID = {data = {}, count = 0}
	unitDamage = {}
	capturedUnits = {}
	controllers = {}
	reloading = {}
	
	-- Load the data
	for oldUnitID, data in pairs(loadData.unitDamage or {}) do
		local unitID = GG.SaveLoad.GetNewUnitID(oldUnitID)
		if unitID then
			damageByID.count = damageByID.count + 1
			damageByID.data[damageByID.count] = unitID
			unitDamage[unitID] = data
			unitDamage[unitID].index = damageByID.count
		end
	end
	
	for oldUnitID, data in pairs(loadData.capturedUnits or {}) do
		local unitID = GG.SaveLoad.GetNewUnitID(oldUnitID)
		if unitID then
			capturedUnits[unitID] = data
			capturedUnits[unitID].controllerID = GG.SaveLoad.GetNewUnitID(data.controllerID)
		end
	end
	
	for oldUnitID, data in pairs(loadData.controllers or {}) do
		local unitID = GG.SaveLoad.GetNewUnitID(oldUnitID)
		if unitID then
			controllers[unitID] = {
				postCaptureReload = data.postCaptureReload,
				units = GG.SaveLoad.GetNewUnitIDKeys(data.units),
				unitByID = {
					count = data.unitByID.count,
					data = GG.SaveLoad.GetNewUnitIDValues(data.unitByID.data)
				},
				killSubordinates = data.killSubordinates,
			}
			
			KillToggleCommand(unitID, {(data.killSubordinates and 1) or 0}, {})
		end
	end
	
	for frame, data in pairs(loadData.reloading or {}) do
		local newFrame = frame - loadGameFrame
		if newFrame >= 0 then
			reloading[newFrame] = {
				count = data.count,
				data = GG.SaveLoad.GetNewUnitIDValues(data.data)
			}
		end
	end
	
	UpdateSaveReferences()
end

--------------------------------------------------------------------------------
--------------------------------------------------------------------------------
else --UNSYNCED
--------------------------------------------------------------------------------
--------------------------------------------------------------------------------

local spIsUnitInView 		= Spring.IsUnitInView
local spGetUnitPosition 	= Spring.GetUnitPosition
local spGetUnitLosState 	= Spring.GetUnitLosState
local spValidUnitID 		= Spring.ValidUnitID
local spGetMyAllyTeamID 	= Spring.GetMyAllyTeamID
local spGetGameFrame        = Spring.GetGameFrame
local spGetSpectatingState  = Spring.GetSpectatingState
local spGetUnitRulesParam   = Spring.GetUnitRulesParam
local spGetUnitVectors      = Spring.GetUnitVectors

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

local drawingUnits = {}
local unitCount = 0

local drawList = 0
local drawAnything = false

local function DrawBezierCurve(pointA, pointB, pointC, pointD, amountOfPoints)
	local step = 1/amountOfPoints
	glVertex (pointA[1], pointA[2], pointA[3])
	local px, py, pz
	for i = 0, 1, step do
		local x = pointA[1]*((1-i)^3) + pointB[1]*(3*i*(1-i)^2) + pointC[1]*(3*i*i*(1-i)) + pointD[1]*(i*i*i)
		local y = pointA[2]*((1-i)^3) + pointB[2]*(3*i*(1-i)^2) + pointC[2]*(3*i*i*(1-i)) + pointD[2]*(i*i*i)
		local z = pointA[3]*((1-i)^3) + pointB[3]*(3*i*(1-i)^2) + pointC[3]*(3*i*i*(1-i)) + pointD[3]*(i*i*i)
		glVertex(x,y,z)
		if px then
			glVertex(px,py,pz)
		end
		px, py, pz = x, y, z
	end
	glVertex(pointD[1],pointD[2],pointD[3])
	if px then
		glVertex(px,py,pz)
	end
end

local function GetUnitTop(unitID, x, y ,z, bonus)
	local height = Spring.GetUnitHeight(unitID)*1.5
	local top = select(2, spGetUnitVectors(unitID))
	local offX = top[1]*height
	local offY = top[2]*height
	local offZ = top[3]*height
	return x+offX, y+offY, z+offZ
end

local function DrawWire(units, spec)
	for controliee, controller in pairs(drawingUnits) do
		if spValidUnitID(controliee) and spValidUnitID(controller) then
			local point = {}
			local teamID = Spring.GetUnitTeam(controller)
			local los1 = spGetUnitLosState(controller, myTeam, false)
			local los2 = spGetUnitLosState(controliee, myTeam, false)
			if teamID and (spec or (los1 and los1.los) or (los2 and los2.los)) then
				-- (spIsUnitInView(controliee) or spIsUnitInView(controller)) -- Doesn't quite work because capture line may be long.
				local teamR, teamG, teamB = Spring.GetTeamColor(teamID)
				
				local _,_,_,xxx,yyy,zzz = Spring.GetUnitPosition(controller, true)
				local topX, topY, topZ = GetUnitTop(controller, xxx, yyy, zzz, 50)
				point[1] = {xxx, yyy, zzz}
				point[2] = {topX, topY, topZ}
				_,_,_,xxx,yyy,zzz = Spring.GetUnitPosition(controliee, true)
				topX, topY, topZ = GetUnitTop(controliee, xxx, yyy, zzz)
				point[3] = {topX,topY,topZ}
				point[4] = {xxx,yyy,zzz}
				gl.Color (teamR or 0.5, teamG or 0.5, teamB or 0.5, math.random()*0.1+0.3)
				gl.BeginEnd(GL_LINES, DrawBezierCurve, point[1], point[2], point[3], point[4], 10)
			end
		else
			drawingUnits[controliee] = nil
			unitCount = unitCount - 1
		end
	end
end

local function UpdateList()
	if unitCount ~= 0 then
		local _, fullview = spGetSpectatingState()
		glDeleteList(drawList)
		 
		drawAnything = true
		drawList = glCreateList(function () glBeginEnd(GL_LINES, DrawWire, drawingUnits, fullview) end)
	else
		drawAnything = false
	end
end

function gadget:PlayerChanged()
	myTeam = spGetMyAllyTeamID()
end

local lastFrame = 0
function gadget:DrawWorld()
	if Spring.GetGameFrame() ~= lastFrame then
		UpdateList()
	end
	
	if drawAnything then
		glPushAttrib(GL.LINE_BITS)
		glLineWidth(3)
		gl.DepthTest(true)
		glCallList(drawList)
		gl.DepthTest(false)
		glColor(1,1,1,1)
		glPopAttrib()
	end
end

function gadget:UnitGiven(unitID, unitDefID, teamID, oldTeamID)
	local controllerID = spGetUnitRulesParam(unitID, "capture_controller")
	if drawingUnits[unitID] then
		if (not controllerID) or controllerID == -1 then
			drawingUnits[unitID] = nil
			unitCount = unitCount - 1
		else
			drawingUnits[unitID] = controllerID
		end
	elseif controllerID and controllerID ~= -1 then
		drawingUnits[unitID] = controllerID
		unitCount = unitCount + 1
	end
end

function gadget:UnitDestroyed (unitID)
	local morphedTo = Spring.GetUnitRulesParam(unitID, "wasMorphedTo")
	if morphedTo then
		gadget:UnitGiven(morphedTo)
	end
end

--------------------------------------------------------------------------------
--------------------------------------------------------------------------------
-- Save/Load

function gadget:Load(zip)
	for _, unitID in ipairs(Spring.GetAllUnits()) do
		gadget:UnitGiven(unitID)
	end
end

local MakeRealTable = Spring.Utilities.MakeRealTable

function gadget:Save(zip)
	if not GG.SaveLoad then
		Spring.Log(gadget:GetInfo().name, LOG.ERROR, "Capture failed to access save/load API")
		return
	end
	local toSave = {
		unitDamage = MakeRealTable(SYNCED.unitDamage, "Capture unit damage"),
		capturedUnits = MakeRealTable(SYNCED.capturedUnits, "Capture captured units"),
		controllers = MakeRealTable(SYNCED.controllers, "Capture controllers"),
		reloading = MakeRealTable(SYNCED.reloading, "Capture reloads"),
	}
	GG.SaveLoad.WriteSaveData(zip, SAVE_FILE, toSave)
end

--------------------------------------------------------------------------------
--------------------------------------------------------------------------------
end
