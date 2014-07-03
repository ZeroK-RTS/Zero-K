--------------------------------------------------------------------------------
--------------------------------------------------------------------------------

function gadget:GetInfo()
  return {
    name      = "Instant Self Destruct",
    desc      = "Replaces engine self-d behaviour for a set of units such that they self-destruct instantly.",
    author    = "Google Frog",
    date      = "21 September, 2013",
    license   = "GNU GPL, v2 or later",
    layer     = 0,
    enabled   = true  --  loaded by default?
  }
end

--------------------------------------------------------------------------------
--------------------------------------------------------------------------------
if (not gadgetHandler:IsSyncedCode()) then
  return false  --  no unsynced code
end

local tickDefID = UnitDefNames["armtick"].id


local selfddefs = {}
for i=1,#UnitDefs do
	if UnitDefs[i].customParams and UnitDefs[i].customParams.instantselfd then 
		selfddefs[i] = true
	end
end 

local CMD_SELFD = CMD.SELFD
local spGetUnitIsStunned = Spring.GetUnitIsStunned
local spDestroyUnit = Spring.DestroyUnit

function gadget:AllowCommand_GetWantedCommand()
	return {[CMD_SELFD] = true}
end

function gadget:AllowCommand_GetWantedUnitDefID()
	return selfddefs
end

local toDestroy 

function gadget:AllowCommand(unitID, unitDefID, unitTeam, cmdID, cmdParams, cmdOptions)
	if cmdID == CMD_SELFD and selfddefs[unitDefID] and cmdOptions.coded == 0 then
		local stunned_or_inbuild = spGetUnitIsStunned(unitID)
		if not stunned_or_inbuild then
			if not toDestroy then
				toDestroy = {count = 0, data = {}}
			end
			toDestroy.count = toDestroy.count + 1
			toDestroy.data[toDestroy.count] = unitID
		end
	end
	return true
end

function gadget:GameFrame(n)
	if toDestroy then
		for i = 1, toDestroy.count do
			spDestroyUnit(toDestroy.data[i], true)
		end
		toDestroy = nil
	end
end