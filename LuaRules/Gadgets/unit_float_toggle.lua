
function gadget:GetInfo()
  return {
    name      = "Float Toggle",
    desc      = "Adds a float/sink toggle to units, currently static while floating",
    author    = "Google Frog",
    date      = "9 March 2012, 7 Jan 2014",
    license   = "GNU GPL, v2 or later",
    layer     = 0,
    enabled   = false,  --  loaded by default?
  }
end

-------------------------------------------------------------------------------------
-------------------------------------------------------------------------------------

if (not gadgetHandler:IsSyncedCode()) then
    return
end

-------------------------------------------------------------------------------------
-------------------------------------------------------------------------------------
-- Commands

local DEFAULT_FLOAT = 1
local CMD_STOP = CMD.STOP

include("LuaRules/Configs/customcmds.h.lua")

local unitFloatIdleBehaviour = {
	id      = CMD_UNIT_FLOAT_STATE,
	type    = CMDTYPE.ICON_MODE,
	name    = 'Float State',
	action  = 'floatstate',
	tooltip	= 'Float / Sink', --colorful tooltip is written in integral_menu_commands.lua
	params 	= {DEFAULT_FLOAT, 'Sink','Attack','Float'}
}

local FLOAT_NEVER = 0
local FLOAT_ATTACK = 1
local FLOAT_ALWAYS = 2

-------------------------------------------------------------------------------------
-- Config

local sinkCommand = {
	[CMD.MOVE] = true,
	[CMD_RAW_MOVE] = true,
	[CMD.GUARD] = true,
	[CMD.FIGHT] = true,
	[CMD.PATROL] = true,
	[CMD_WAIT_AT_BEACON] = true,
}

local floatDefs = include("LuaRules/Configs/float_defs.lua")

--------------------------------------------------------------------------------
-- Local Vars

local float = {}
local floatByID = {data = {}, count = 0}

local floatState = {}
local aimWeapon = {}
local GRAVITY = Game.gravity/30/30
local RAD_PER_ROT = (math.pi/(2^15))
local buildTestUnitDefID = UnitDefNames["turretriot"].id --we use Stardust to check blockage on water surface because on Spring 96 onward amphibious are always buildable under factory.
--------------------------------------------------------------------------------
-- Communication to script

local function callScript(unitID, funcName, args)
	local func = Spring.UnitScript.GetScriptEnv(unitID)[funcName]
	if func then
		Spring.UnitScript.CallAsUnit(unitID,func, args)
	end
end
--------------------------------------------------------------------------------
-- Float Table Manipulation

local function addFloat(unitID, unitDefID, isFlying,transportCall)
	if not float[unitID] then
		local def = floatDefs[unitDefID]
		local x,y,z = Spring.GetUnitPosition(unitID)
		if y < def.depthRequirement or isFlying then
			Spring.MoveCtrl.Enable(unitID)
			Spring.MoveCtrl.SetNoBlocking(unitID, true)
			local place, feature = Spring.TestBuildOrder(buildTestUnitDefID, x, y ,z, 1)
			Spring.MoveCtrl.SetNoBlocking(unitID, false)
			if place == 2 then
				Spring.SetUnitRulesParam(unitID, "disable_tac_ai", 1)
				floatByID.count = floatByID.count + 1
				floatByID.data[floatByID.count] = unitID
				float[unitID] = {
					index = floatByID.count,
					surfacing = true,
					prevSurfacing = false,
					onSurface = false,
					justStarted = true,
					sinkTank = 0,
					nextSpecialDrag = 1,
					speed = def.initialRiseSpeed,
					x = x, y = y, z = z,
					unitDefID = unitDefID,
					isFlying = isFlying,
					paraData = {want = false, para = false},
					transportCall = transportCall or 0,
				}
				Spring.MoveCtrl.SetRotation(unitID, 0, -Spring.GetUnitHeading(unitID)*RAD_PER_ROT, 0)
				if isFlying then
					Spring.MoveCtrl.Disable(unitID) --disable MoveCtrl temporary so that Newton can work
				end
			else
				Spring.MoveCtrl.Disable(unitID)
			end
		end
	end
end

local function removeFloat(unitID)
	float[floatByID.data[floatByID.count] ].index = float[unitID].index
	floatByID.data[float[unitID].index] = floatByID.data[floatByID.count]
	floatByID.data[floatByID.count] = nil
	float[unitID] = nil
	floatByID.count = floatByID.count - 1
end

local function setSurfaceState(unitID, unitDefID, surfacing)
	local stun = float[unitID].paraData.para or Spring.GetUnitIsStunned(unitID)
	local data = float[unitID]
	if not stun then
		data.surfacing = surfacing
	else
		data.paraData.want = surfacing 
		if not data.paraData.para then
			local def = floatDefs[data.unitDefID]
			if def.sinkOnPara then
				data.surfacing = false
			end
		end
		data.paraData.para = true
	end
end

function gadget:UnitLoaded(unitID, unitDefID, unitTeam, transportID, transportTeam)
	if float[unitID] then
		Spring.SetUnitRulesParam(unitID, "disable_tac_ai", 0)
		Spring.MoveCtrl.Disable(unitID)
		Spring.GiveOrderToUnit(unitID,CMD.WAIT, {}, 0)
		Spring.GiveOrderToUnit(unitID,CMD.WAIT, {}, 0)
		callScript(unitID, "script.StopMoving")
		removeFloat(unitID)
	end
end

function gadget:UnitUnloaded(unitID, unitDefID, unitTeam,transportID, transportTeam)
	if floatDefs[unitDefID] and not float[unitID] then
		local px,py,pz = Spring.GetUnitPosition(unitID)
		if py > Spring.GetGroundHeight(px,pz) + 20 then
			addFloat(unitID, unitDefID, true)
		end
	end
end

--------------------------------------------------------------------------------
-- Script calls

GG.Floating_StopMoving = GG.Floating_StopMoving or function() end --empty function. Defined in gadget:Initialize()
GG.Floating_AimWeapon = GG.Floating_AimWeapon or function() end
GG.Floating_UnitTeleported = GG.Floating_UnitTeleported or function() end

local function checkAlwaysFloat(unitID)
	if not select(1, Spring.GetUnitIsStunned(unitID)) then
		local unitDefID = Spring.GetUnitDefID(unitID)
		local cmdID = Spring.Utilities.GetUnitFirstCommand(unitID)
		local moving = cmdID and sinkCommand[cmdID]
		if not moving then
			addFloat(unitID, unitDefID)
		end
	end
end

--------------------------------------------------------------------------------
-- Realism/Physic

--Reference: http://en.wikipedia.org/wiki/Drag_equation
local function CalculateDrag (velocity, dragCoefficient, unitsMass, waterDensity, unitsArea)
	local acceleration = 0.5*(waterDensity*velocity*velocity*dragCoefficient*unitsArea)/unitsMass
	local accWithDirection = acceleration*(math.abs(velocity)/velocity)
	return -accWithDirection
end

--------------------------------------------------------------------------------
-- Update that moves things around

function gadget:GameFrame(f)

	local checkStun = f%16 == 4
	local checkOrder = f%16 == 12

	local i = 1
	while i <= floatByID.count do
		local unitID = floatByID.data[i]
		local isValidUnitID = Spring.ValidUnitID(unitID)
		local isFlying = isValidUnitID and float[unitID]["isFlying"]
		
		if isFlying then --check if unit has landed or not
			local data = float[unitID] --(get reference to data table)
			data.x,data.y,data.z = Spring.GetUnitPosition(unitID)
			local height = Spring.GetGroundHeight(data.x, data.z)
			if data.y == height then --touch down on ground
				removeFloat(unitID)
				i = i - 1
			elseif data.y <= 0 then --touch down on water level
				local _,dy = Spring.GetUnitVelocity(unitID)
				data.speed = dy
				data.isFlying = false
				local cmdID, cmdOpts, cmdTag
				if Spring.Utilities.COMPAT_GET_ORDER then
					local queue = Spring.GetCommandQueue(unitID, 1)
					if queue and queue[1] then
						cmdID, cmdOpts, cmdTag = queue[1].id, queue[1].options.coded, queue[1].tag
					end
				else
					cmdID, cmdOpts, cmdTag = Spring.GetUnitCurrentCommand(unitID)
				end
				if cmdID then 
					if (cmdID == CMD.MOVE or cmdID == CMD_RAW_MOVE) and cmdOpts == CMD.OPT_RIGHT then --Note: not sure what is "coded == 16" and "right" is but we want to remove any MOVE command as soon as amphfloater touch down so that it doesn't try to return to old position
						Spring.GiveOrderArrayToUnitArray({unitID},{
							{CMD.REMOVE, {cmdTag}, 0},--clear Spring's command that desire unit to return to old position	
							{CMD.INSERT, {0, CMD.STOP, CMD.SHIFT,}, CMD.OPT_ALT},
						})
					end
				end
				Spring.MoveCtrl.Enable(unitID)
				Spring.MoveCtrl.SetRotation(unitID, 0, -Spring.GetUnitHeading(unitID)*RAD_PER_ROT, 0)
			end
			i = i + 1
			
		elseif isValidUnitID and not isFlying then --perform float/sink behaviour
			local data = float[unitID]
			local def = floatDefs[data.unitDefID]
			
			-- This cannot be done when the float is added because that will often be
			-- the result of a unit script. Strange trigger inheritence bleh!
			if data.justStarted and data.surfacing then
				callScript(unitID, "Float_startFromFloor")
				data.justStarted = nil
			end
			
			-- Check various paralysis conditions
			if checkStun then
				local stun
				-- Units that are paralysed cannot change state so change
				-- state when they become unstunned
				if data.paraData.para then
					stun = select(1, Spring.GetUnitIsStunned(unitID))
					if not stun then
						data.surfacing = data.paraData.want
						data.paraData.para = false
					end
				end
				-- Some units may sink when paralised, ie they require power to stay afloat.
				if def.sinkOnPara and not data.paraData.para then
					stun = stun or select(1, Spring.GetUnitIsStunned(unitID))
					if stun then
						data.paraData.want = data.surfacing 
						data.surfacing = false
						data.paraData.para = true
					end
				end
			end
			
			-- Check if the unit should sink
			if checkOrder then
				if data.transportCall>0 then
					local cmdID = Spring.Utilities.GetUnitFirstCommand(unitID)
					local moving = cmdID and sinkCommand[cmdID]
					setSurfaceState(unitID, data.unitDefID, not moving)
					data.transportCall = data.transportCall - 1
				elseif floatState[unitID] == FLOAT_ALWAYS then
					local cmdID = Spring.Utilities.GetUnitFirstCommand(unitID)
					local moving = cmdID and sinkCommand[cmdID]
					setSurfaceState(unitID, data.unitDefID, not moving)
				elseif floatState[unitID] == FLOAT_ATTACK then
					local cmdID, cmdOpts
					if Spring.Utilities.COMPAT_GET_ORDER then
						local queue = Spring.GetCommandQueue(unitID, 1)
						if queue and queue[1] then
							cmdID, cmdOpts = queue[1].id, queue[1].options.coded
						end
					else
						cmdID, cmdOpts = Spring.GetUnitCurrentCommand(unitID)
					end
					local moving = cmdID and (cmdID == CMD.MOVE or cmdID == CMD_RAW_MOVE) and not Spring.Utilities.CheckBit(gadget:GetInfo().name, cmdOpts, CMD.OPT_INTERNAL)
					setSurfaceState(unitID, data.unitDefID, (not moving and aimWeapon[unitID]) or false)
				elseif floatState[unitID] == FLOAT_NEVER then
					setSurfaceState(unitID, data.unitDefID, false)
				end
			end
			
			-- Rising/Sinking Animation
			if data.prevSurfacing ~= data.surfacing then
				if data.surfacing then
					callScript(unitID, "Float_rising")
				else
					callScript(unitID, "Float_sinking")
				end
				data.prevSurfacing = data.surfacing
			end
			
			-- Update unit current position
			data.x,data.y,data.z = Spring.GetUnitPosition(unitID)
			
			-- Fill tank
			if def.sinkTankRequirement then
				if not data.surfacing then
					if data.y <= def.floatPoint and data.sinkTank <= def.sinkTankRequirement then
						data.sinkTank = data.sinkTank + 1
					end
				else
					data.sinkTank = 0
				end
			end
			
			-- Accelerate the speed
			if data.y <= def.floatPoint then
				if not data.surfacing then --sinking
					if (not def.sinkTankRequirement or data.sinkTank > def.sinkTankRequirement) then
						local dragFactors = (data.speed > 0 and def.sinkUpDrag or def.sinkDownDrag)*data.nextSpecialDrag*def.waterHitDrag
						local drag = CalculateDrag(data.speed,dragFactors, 1,0.2,1)
						data.speed = (data.speed + def.sinkAccel +drag) --sink as fast as possible
						data.onSurface = false
					else
						local dragFactors = (data.speed > 0 and def.sinkUpDrag or def.sinkDownDrag)*data.nextSpecialDrag*def.waterHitDrag
						local drag = CalculateDrag(data.speed,dragFactors, 1,0.2,1)
						data.speed = (data.speed + def.sinkAccel*(data.sinkTank/def.sinkTankRequirement) +drag) --sink as fast as sinktank fill
					end
				else --rising
					local dragFactors = (data.speed > 0 and def.riseUpDrag or def.riseDownDrag)*data.nextSpecialDrag*def.waterHitDrag
					local drag = CalculateDrag(data.speed,dragFactors, 1,0.2,1)				
					data.speed = (data.speed + def.riseAccel+drag) --float as fast as possible
				end
			else
				local dragFactors = (def.airDrag)*data.nextSpecialDrag
				local drag = CalculateDrag(data.speed,dragFactors, 1,0.02,1)	
				data.speed = (data.speed + def.airAccel + drag) --fall down from sky
			end
			
			-- Speed the position/Test for special case
			local height = Spring.GetGroundHeight(data.x, data.z)
			if data.speed ~= 0 or data.y <= height or not data.onSurface then
				
				-- Splash animation
				if not data.onSurface then
					local waterline = data.y - def.floatPoint
					-- enter water
					if data.speed < 0 and waterline > 0 and waterline < -data.speed then
						callScript(unitID, "Float_crossWaterline", {data.speed})
					end
					
					--leave water
					if data.speed > 0 and waterline < 0 and -waterline < data.speed then
						callScript(unitID, "Float_crossWaterline", {data.speed})
					end
				end
				
				data.y = data.y + data.speed
				
				if data.y > height then
					if data.surfacing and def.stopSpeedLeeway > math.abs(data.speed) and def.stopPositionLeeway > math.abs(data.y - def.floatPoint) then
						if not data.onSurface then
							callScript(unitID, "Float_stationaryOnSurface")
							data.onSurface = true
						end
					end
					Spring.MoveCtrl.SetPosition(unitID, data.x, data.y, data.z)
				else
					Spring.SetUnitRulesParam(unitID, "disable_tac_ai", 0)
					Spring.SetUnitPosition(unitID, data.x, height, data.z)
					Spring.MoveCtrl.Disable(unitID)
					Spring.GiveOrderToUnit(unitID,CMD.WAIT, {}, 0)
					Spring.GiveOrderToUnit(unitID,CMD.WAIT, {}, 0)
					callScript(unitID, "Float_stopOnFloor")
					removeFloat(unitID)
					
					i = i - 1 
				end
			end
			
			i = i + 1
		else
			removeFloat(unitID)
		end
	end
	
	if f%16 == 12 then
		aimWeapon = {}
	end
end

--------------------------------------------------------------------------------
-- Command Handling

local function FloatToggleCommand(unitID, cmdParams, cmdOptions)
	if floatState[unitID] then
		local state = cmdParams[1]
		local cmdDescID = Spring.FindUnitCmdDesc(unitID, CMD_UNIT_FLOAT_STATE)
		if cmdOptions.right then
			state = (state + 1)%3
		end
		if (cmdDescID) then
			Spring.EditUnitCmdDesc(unitID, cmdDescID, { params = {state, 'Sink','Attack','Float'}})
		end
		floatState[unitID] = state
		if state == FLOAT_ALWAYS then
			checkAlwaysFloat(unitID)
		end
	end
end

function gadget:AllowCommand_GetWantedCommand()	
	return {[CMD_UNIT_FLOAT_STATE] = true, [CMD_STOP] = true}
end

function gadget:AllowCommand_GetWantedUnitDefID()	
	return true
end

function gadget:AllowCommand(unitID, unitDefID, teamID, cmdID, cmdParams, cmdOptions)
	if (cmdID == CMD_UNIT_FLOAT_STATE) then
		FloatToggleCommand(unitID, cmdParams, cmdOptions)  
		return false  -- command was used
	elseif (cmdID == CMD_STOP) then
		if floatState[unitID] == FLOAT_ALWAYS then
			checkAlwaysFloat(unitID)
		end
	end

	return true  -- command was not used
end

function gadget:UnitCreated(unitID, unitDefID, unitTeam)
	if floatDefs[unitDefID] then
		floatState[unitID] = DEFAULT_FLOAT
		Spring.InsertUnitCmdDesc(unitID, unitFloatIdleBehaviour)
	end
end

function gadget:Initialize()
	-- register command
	gadgetHandler:RegisterCMDID(CMD_UNIT_FLOAT_STATE)
	-- load active units
	for _, unitID in ipairs(Spring.GetAllUnits()) do
		local unitDefID = Spring.GetUnitDefID(unitID)
		gadget:UnitCreated(unitID, unitDefID)
	end
	
	GG.Floating_StopMoving =function(unitID) --real function. Note: we do this in gadget:Initialize() so that only gadget that actually run will initialize GG. with a correct function
		if floatState[unitID] == FLOAT_ALWAYS  then
			checkAlwaysFloat(unitID)
		end
	end

	GG.Floating_AimWeapon = function(unitID)
		if floatState[unitID] == FLOAT_ATTACK and not select(1, Spring.GetUnitIsStunned(unitID)) then
			local unitDefID = Spring.GetUnitDefID(unitID)
			local cmdID, cmdOpts
			if Spring.Utilities.COMPAT_GET_ORDER then
				local queue = Spring.GetCommandQueue(unitID, 1)
				if queue and queue[1] then
					cmdID, cmdOpts = queue[1].id, queue[1].options.coded
				end
			else
				cmdID, cmdOpts = Spring.GetUnitCurrentCommand(unitID)
			end
			
			local moving = cmdID and (cmdID == CMD.MOVE or cmdID == CMD_RAW_MOVE) and not Spring.Utilities.CheckBit(gadget:GetInfo().name, cmdOpts, CMD.OPT_INTERNAL)
			if not moving then
				addFloat(unitID, unitDefID)
			end
		end
		aimWeapon[unitID] = true
	end

	GG.Floating_UnitTeleported = function(unitID, position)
		if float[unitID] then
			local data = float[unitID]
			local def = floatDefs[data.unitDefID]
			data.x, data.y, data.z = position[1], position[2], position[3]
			--data.speed = 0.1
			local height = Spring.GetGroundHeight(data.x, data.z)
			if height <= def.depthRequirement then
				data.onSurface = false
				Spring.MoveCtrl.SetPosition(unitID, data.x, data.y, data.z)
				return true
			else
				Spring.SetUnitRulesParam(unitID, "disable_tac_ai", 0)
				callScript(unitID, "script.StopMoving")
				removeFloat(unitID)
				return false
			end
		end
		return false
	end	
	
	GG.WantToTransport_FloatNow = function(unitID)
		local unitDefID = Spring.GetUnitDefID(unitID)
		if floatDefs[unitDefID] then
			addFloat(unitID, unitDefID, false, 2) --is called once by "unit_transport_ai_button.lua" when CMD.LOAD_UNITS is given
			return true
		else
			return false
		end
	end
	GG.HoldStillForTransport_HoldFloat = function(unitID)
		if float[unitID] then
			float[unitID].transportCall =2--is called every frame until transport no longer want to transport
			return true
		else
			return false
		end
	end
end
