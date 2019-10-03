--------------------------------------------------------------------------------
--------------------------------------------------------------------------------

function widget:GetInfo()
	return {
		name      = "Command Indicator (beta)",
		desc      = "Simple visual feedback of received commands",
		author    = "KingRaptor (L.J. Lim)",
		date      = "2013.10.29",
		license   = "Public domain/CC0",
		layer     = 0,
		enabled   = false  --  loaded by default?
	}
end

--------------------------------------------------------------------------------
--------------------------------------------------------------------------------
VFS.Include("LuaRules/Configs/customcmds.h.lua")

local spGetUnitPosition = Spring.GetUnitPosition
local spGetFeaturePosition = Spring.GetFeaturePosition
local spGetUnitHeight = Spring.GetUnitHeight
local spGetFeatureHeight = Spring.GetFeatureHeight

local image = "LuaUI/Images/arrowhead.png"
local diamondDList

local INIT_Y_OFFSET = 24
local UPDATE_FREQUENCY = 0.02

local colorWhite = {1,1,1}

-- TODO add more commands
local cmdColors = {
	[CMD.MOVE] = {0.1, 0.9, 0.1},
	[CMD_RAW_MOVE] = {0.1, 0.9, 0.1},
	[CMD.ATTACK] = {0.9, 0.1, 0.1},
	[CMD.PATROL] = {0.1, 0.1, 0.9},
	[CMD.FIGHT] = {0.1, 0.1, 0.9},
	[CMD.GUARD] = {0.1, 0.8, 0.8},
	[CMD.REPAIR] = {0.1, 0.8, 0.8},
	[CMD.RECLAIM] = {0.8, 0.1, 0.8},
	[CMD.RESURRECT] = {0.1, 0.8, 0.8},
	[CMD_JUMP] = {0.1, 0.9, 0.1},
	[CMD_REARM] = {0.1, 0.8, 0.8},
	[CMD_PLACE_BEACON] = {0.1, 0.8, 0.8},
	[CMD_WAIT_AT_BEACON] = {0.1, 0.1, 0.9},
	[CMD_UNIT_SET_TARGET] = {0.8, 0.8, 0.1},
	[CMD_UNIT_SET_TARGET_CIRCLE] = {0.8, 0.8, 0.1},
}

local phases = {
	{time = 0, offset = INIT_Y_OFFSET, alpha = 0.8},
	{time = 0.3, offset = 0, alpha = 0.8},
	{time = 0.6, offset = 24, alpha = 0}
}
local highestTime = phases[#phases].time

local commands = {} -- [1] = {targetID = unitID/featureID, isFeature = bool, pos = {x, y, z}, cmdID = cmdID, time = time, phase = number, alpha = number, offset = number}
local toRemove = {} -- {1, 2, 7, ...}

local updateTimer = 0

local function Diamond()	-- FIXME: not a diamond (it's actually an inverted pyramid)
	gl.Vertex(0, -16, 0)
	gl.Vertex(12, 0, 0)
	gl.Vertex(0, 0, 12)
	gl.Vertex(-12, 0, 0)
	gl.Vertex(0, 0, -12)
	gl.Vertex(12, 0, 0)
	
	--[[
	gl.Vertex(0, -16, 0)
	gl.Vertex(12, 0, 0)
	gl.Vertex(0, 16, 0)
	
	gl.Vertex(0, 0, 12)
	gl.Vertex(0, -16, 0)
	
	gl.Vertex(-12, 0, 0)
	gl.Vertex(0, 16, 0)
	
	gl.Vertex(0, 0, -12)
	gl.Vertex(0, -16, 0)
	]]
end

local function GetUnitTopPos(unitID)
	local x,y,z = spGetUnitPosition(unitID)
	if not (x and y and z) then
		return
	end
	local height = spGetUnitHeight(unitID) or 0
	return x, y + height, z
end

local function GetFeatureTopPos(featureID)
	local x,y,z = spGetFeaturePosition(featureID)
	if not (x and y and z) then
		return
	end
	return x, y + spGetFeatureHeight(featureID), z
end
--------------------------------------------------------------------------------
--------------------------------------------------------------------------------
function widget:Update(dt)
	updateTimer = updateTimer + dt
	if updateTimer >= UPDATE_FREQUENCY then
		for i=1,#commands do
			local command = commands[i]
			command.time = command.time + updateTimer
			local time = command.time
			if time > highestTime then
				toRemove[#toRemove+1] = i
			else
				local previousPhase = math.floor(command.phase)
				local nextPhase = previousPhase + 1
				if time > phases[nextPhase].time then
					previousPhase = nextPhase
					nextPhase = nextPhase + 1
				end
				local nextPhaseDef = phases[nextPhase]
				local previousPhaseDef = phases[previousPhase]
				local nextTime = nextPhaseDef.time
				local previousTime = previousPhaseDef.time
				local timeDiff = nextTime - previousTime
				command.phase = previousPhase + (time - previousTime)/timeDiff
				local phaseProgress = command.phase%1
				
				local alphaDiff = nextPhaseDef.alpha - previousPhaseDef.alpha
				command.alpha = previousPhaseDef.alpha + alphaDiff*phaseProgress
				local offsetDiff = nextPhaseDef.offset - previousPhaseDef.offset
				command.offset = previousPhaseDef.offset + offsetDiff*phaseProgress
				
				if command.targetID then
					if command.isFeature then
						local x, y, z = GetFeatureTopPos(command.targetID)
						command.pos = x and {x, y, z} or command.pos
					else
						local x, y, z = GetUnitTopPos(command.targetID)
						command.pos = x and {x, y, z} or command.pos
					end
				end
			end
		end
		if #toRemove > 0 then	-- so we don't recreate the table unless we have to
			for i=1, #toRemove do
				table.remove(commands, toRemove[i])
			end
			toRemove = {}
		end
		updateTimer = 0
	end
end

function widget:CommandNotify(id, params, options)
	if params == nil then
		return false
	end
	if #params >= 3 then
		commands[#commands+1] = {
			cmdID = id,
			pos = {params[1], params[2] + INIT_Y_OFFSET, params[3]},
			time = 0,
			phase = 1,
			alpha = 1,
			offset = 0,
			radius = params[4],
		}
	elseif #params == 1 then
		local targetID = params[1]
		local isFeature = (targetID > 32000)
		if (isFeature) or Spring.ValidUnitID(targetID) then
			local x, y, z
			if isFeature then
				targetID = targetID - 32000
				x, y, z = GetFeatureTopPos(targetID)
			else
				x, y, z = GetUnitTopPos(targetID)
			end
			if x and y and z then
				commands[#commands+1] = {
					targetID = targetID,
					isFeature = isFeature,
					cmdID = id,
					pos = {x, y + INIT_Y_OFFSET, z },
					time = 0,
					phase = 1,
					alpha = 1,
					offset = 0,
				}
			end
		end
	end
	return false	-- don't do anything to the command
end

--function widget:GameFrame(f)
--	commands[#commands+1] = {
--		cmdID = id,
--		pos = {(f%25)*40+40, 42 + INIT_Y_OFFSET, (math.floor(f/25)%25)*40+40},
--		time = 0,
--		phase = 1,
--		alpha = 1,
--		offset = 0,
--		radius = 0,
--	}
--end

function widget:DrawWorld()
	if Spring.IsGUIHidden() then return end
	gl.DepthTest(true)
	--gl.Texture(image)
	for i=1,#commands do
		local command = commands[i]
		local x, y, z = unpack(command.pos)
		y = y + command.offset
		gl.PushMatrix()
		local r, g, b = unpack(cmdColors[command.cmdID] or colorWhite)
		gl.Color(r, g, b, command.alpha)
		if command.radius then
			gl.DrawGroundCircle(x, y, z, command.radius, 32)
		end
		gl.Translate(x, y, z)
		gl.CallList(diamondDList)
		--gl.Billboard()
		gl.Rotate(180, 0, 0, 1)
		--gl.TexRect(-24, -24, 24, 24)
		gl.CallList(diamondDList)
		gl.PopMatrix()
	end

	--gl.Texture(false)
	gl.DepthTest(false)
	gl.Color(1, 1, 1, 1)
end
  
function widget:Initialize()
	diamondDList = gl.CreateList(gl.BeginEnd, GL.POLYGON, Diamond)
end

function widget:Shutdown()
	gl.DeleteList(diamondDList)
end
--------------------------------------------------------------------------------
--------------------------------------------------------------------------------
