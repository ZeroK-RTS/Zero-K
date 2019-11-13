--------------------------------------------------------------------------------
--------------------------------------------------------------------------------

function widget:GetInfo()
	return {
		name      = "GC Control",
		desc      = "Control lua GC rate.",
		author    = "GoogleFrog",
		date      = "8 November 2018",
		license   = "GNU GPL, v2 or later",
		layer     = math.huge,
		alwaysStart = true,
		enabled   = true,
	}
end

--------------------------------------------------------------------------------
--------------------------------------------------------------------------------

local CATCHING_UP_THRESHOLD = 150

local spGetGameFrame = Spring.GetGameFrame
local spSendCommands = Spring.SendCommands

local currentState = 0
local function SetGcState(newState)
	if currentState == newState then
		return
	end
	currentState = newState
	spSendCommands("luagccontrol " .. currentState)
end

function widget:GameProgress (serverFrame)
	-- See:
	-- https://springrts.com/mantis/view.php?id=5951
	-- https://github.com/spring/spring/commit/a8b5ffc86351680c6e0e8d7e8db161e63dbb912e
	-- https://github.com/spring/spring/commit/20c5c96c9ec4a7810346e0f20abdf1c3ae0f9513

	if serverFrame > spGetGameFrame() + CATCHING_UP_THRESHOLD then
		-- runs GC each simframe (or at 6Hz when paused). Simframes
		-- are by far the main source of garbage during catching up
		-- and there can be hundreds of them per second, making the
		-- usual 30Hz GC struggle to keep up and leading to OOM crashes.
		SetGcState(0)
	else
		-- runs GC at 30Hz. Since that is also the usual game speed
		-- outside of catching up, this should not result in any
		-- difference to the simframe mode, but empirical evidence
		-- says it somehow runs more smoothly.
		SetGcState(1)
	end
end
