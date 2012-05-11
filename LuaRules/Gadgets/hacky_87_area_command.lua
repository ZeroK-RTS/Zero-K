function gadget:GetInfo()
  return {
    name      = "Hacky 87.0 Area Command workaround",
    desc      = "Uses double wait to fix area command halting",
    author    = "Google Frog",
    date      = "12 March 2012",
    license   = "GNU GPL, v2 or later",
    layer     = 0,
    enabled   = false  --  loaded by default?
  }
end

-------------------------------------------------------------------------------------
-------------------------------------------------------------------------------------

if (not gadgetHandler:IsSyncedCode()) then
    return
end

-------------------------------------------------------------------------------------
-------------------------------------------------------------------------------------

local CMD_RECLAIM = CMD.RECLAIM
local CMD_RESURRECT = CMD.RESURRECT
local CMD_REPAIR = CMD.REPAIR
local CMD_WAIT = CMD.WAIT
local spGiveOrderToUnit = Spring.GiveOrderToUnit
local spValidUnitID = Spring.ValidUnitID

local units = {count = 0, unitID = {}}
local thereIsStuffToDo = false

function gadget:UnitCmdDone(unitID, unitDefID, team, cmdID, cmdTag)
	if (cmdID == CMD_RECLAIM or cmdID == CMD_RESURRECT or cmdID == CMD_REPAIR or cmdID < 0) then
		-- Double wait requires a 1 frame delay
		thereIsStuffToDo = true
		units.count = units.count + 1
		units.unitID[units.count] = unitID
	end
end

--buildDistance
function gadget:GameFrame(f)
	if thereIsStuffToDo then
		for i = 1, units.count do
			local unitID = units.unitID[i]
			if spValidUnitID(unitID) then
				-- Double wait, is there anything you can't fix? <3
				spGiveOrderToUnit(unitID,CMD_WAIT,{},{})
				spGiveOrderToUnit(unitID,CMD_WAIT,{},{})
			end
		end
		thereIsStuffToDo = false
		units = {count = 0, unitID = {}}
	end
end

function gadget:Initialize()
	local modOptions = Spring.GetModOptions()
	if not (modOptions and Spring.Utilities.tobool(modOptions.engine_workarounds)) then
		gadgetHandler:RemoveGadget()
	end
end