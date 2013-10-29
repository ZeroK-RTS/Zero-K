--------------------------------------------------------------------------------
--------------------------------------------------------------------------------

function widget:GetInfo()
	return {
		name      = "Command Indicator",
		desc      = "Simple visual feedback of received commands",
		author    = "KingRaptor (L.J. Lim)",
		date      = "2013.10.29",
		license   = "Public domain/CC0",
		layer     = 0,
		enabled   = true  --  loaded by default?
	}
end

--------------------------------------------------------------------------------
--------------------------------------------------------------------------------
VFS.Include("LuaRules/Configs/customcmds.h.lua")

local image = "LuaUI/Images/arrowhead.png"
local INIT_Y_OFFSET = 24
local UPDATE_FREQUENCY = 0.05

local colorWhite = {1,1,1}

-- TODO add more commands
local cmdColors = {
	[CMD.MOVE] = {0.1, 0.9, 0.1},
	[CMD.ATTACK] = {0.9, 0.1, 0.1},
	[CMD.PATROL] = {0.1, 0.1, 0.9},
	[CMD.FIGHT] = {0.1, 0.1, 0.9},
	[CMD.GUARD] = {0.1, 0.8, 0.8},
	[CMD.REPAIR] = {0.1, 0.8, 0.8},
	[CMD_JUMP] = {0.1, 0.9, 0.1},
	[CMD_REARM] = {0.1, 0.8, 0.8},
	[CMD_PLACE_BEACON] = {0.1, 0.8, 0.8},
	[CMD_WAIT_AT_BEACON] = {0.1, 0.1, 0.9},
	[CMD_UNIT_SET_TARGET] = {0.8, 0.8, 0.1},
	[CMD_UNIT_SET_TARGET_CIRCLE] = {0.8, 0.8, 0.1},
}

local phases = {
	{time = 0, offset = INIT_Y_OFFSET, alpha = 0.8},
	{time = 0.6, offset = 0, alpha = 0.8},
	{time = 1.2, offset = 24, alpha = 0}
}
local highestTime = phases[#phases].time

local commands = {} -- [1] = {pos = {x, y, z}, cmdID = cmdID, time = time, phase = 1, alpha = alpha, offset = offset}
local toRemove = {} -- {1, 2, 7, ...}

local updateTimer = 0

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
	if #params >= 3 then
		commands[#commands+1] = {
			cmdID = id,
			pos = {params[1], params[2] + INIT_Y_OFFSET, params[3]},
			time = 0,
			phase = 1,
			alpha = 1,
			offset = 0,
		}
	end
	return false	-- don't do anything to the command
end

function widget:DrawWorld()
	if Spring.IsGUIHidden() then return end
	gl.DepthTest(true)
	gl.Texture(image)
	
	for i=1,#commands do
		local command = commands[i]
		local x, y, z = unpack(command.pos)
		y = y + command.offset
		gl.PushMatrix()
		gl.Translate(x, y, z)
		local r, g, b = unpack(cmdColors[command.cmdID] or colorWhite)
		gl.Color(r, g, b, command.alpha)
		gl.Billboard()
		gl.Rotate(180, 0, 0, 1)
		gl.TexRect(-24, -24, 24, 24)
		gl.PopMatrix()
	end

	gl.Texture(false)
	gl.DepthTest(false)
	gl.Color(1, 1, 1, 1)
end
  

--------------------------------------------------------------------------------
--------------------------------------------------------------------------------
