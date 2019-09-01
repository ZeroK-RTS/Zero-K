--------------------------------------------------------------------------------
--------------------------------------------------------------------------------
if not gadgetHandler:IsSyncedCode() then
	return
end
--------------------------------------------------------------------------------
--------------------------------------------------------------------------------

function gadget:GetInfo()
	return {
		name      = "Gunship Oscillate",
		desc      = "Prevents oscillating gunships.",
		author    = "GoogleFrog",
		date      = "1 September, 2019",
		license   = "GNU GPL, v2 or later",
		layer     = 0,
		enabled   = true  --  loaded by default?
	}
end

-------------------------------------------------------------------------------------
-------------------------------------------------------------------------------------

local spGetUnitStates = Spring.GetUnitStates

local CMD_IDLEMODE = CMD.IDLEMODE
local UPDATE_RATE = 90

local REVERSE_COMPAT = not Spring.Utilities.IsCurrentVersionNewerThan(104, 1120)

-------------------------------------------------------------------------------------
-------------------------------------------------------------------------------------

local frame = Spring.GetGameFrame()

local unitFrame = {}
local frameList = {}
local gameFrame = Spring.GetGameFrame()

local function IdlemodeIdlemode(unitID)
	local autoland
	if REVERSE_COMPAT then
		local states = spGetUnitStates(unitID)
		autoland = states.autoland
	else
		autoland = select(4, spGetUnitStates(unitID, false, false, true))
	end
	if not autoland then
		Spring.GiveOrderToUnit(unitID, CMD_IDLEMODE, {1}, 0)
		Spring.GiveOrderToUnit(unitID, CMD_IDLEMODE, {0}, 0)
	end
end

local function AddOscillateCheck(unitID, unitDefID)
	if (not unitFrame[unitID]) or (unitFrame[unitID] < gameFrame) then
		local nextFrame = gameFrame + UPDATE_RATE
		unitFrame[unitID] = nextFrame
		frameList[nextFrame] = frameList[nextFrame] or {}
		frameList[nextFrame][#frameList[nextFrame] + 1] = unitID
	end
end

GG.AddOscillateCheck = AddOscillateCheck

-------------------------------------------------------------------------------------
-------------------------------------------------------------------------------------

function gadget:UnitDestroyed(unitID)
	if unitFrame[unitID] then
		unitFrame[unitID] = nil
	end
end

function gadget:GameFrame(n)
	gameFrame = n
	if frameList[n] then
		local units = frameList[n]
		for i = 1, #units do
			local unitID = units[i]
			if Spring.ValidUnitID(unitID) and unitFrame[unitID] then
				IdlemodeIdlemode(unitID)
				unitFrame[unitID] = nil
			end
		end
		
		frameList[n] = nil
	end
end