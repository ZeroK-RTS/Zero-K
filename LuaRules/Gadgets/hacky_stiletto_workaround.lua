--------------------------------------------------------------------------------
--------------------------------------------------------------------------------

function gadget:GetInfo()
  return {
    name      = "Hacky Stiletto Workaround",
    desc      = "Specialised gadget that removes the use of Sleep from armstiletto_laser FireWeapon1",
    author    = "GoogleFrog",
    date      = "19 July 2011",
    license   = "GNU GPL, v2 or later",
    layer     = 0,
    enabled   = true,
  }
end

local frame = 0

local unitFrames = {}

function GG.Hacky_Stiletto_Workaround_gadget_func(unitID, offset, number)
	
	if unitFrames[frame+offset] then
		unitFrames[frame+offset].count = unitFrames[frame+offset].count + 1
		unitFrames[frame+offset].data[unitFrames[frame+offset].count] = {id = unitID, number = number}
	else
		unitFrames[frame+offset] = {count = 1, data = {[1] = {id = unitID, number = number}}}
	end
end

function gadget:GameFrame(n)
	frame = n
	
	if unitFrames[n] then
		for i = 1, unitFrames[n].count do
			if Spring.ValidUnitID(unitFrames[n].data[i].id) then
				local func = Spring.UnitScript.GetScriptEnv(unitFrames[n].data[i].id).Hacky_Stiletto_Workaround_stiletto_func
				Spring.UnitScript.CallAsUnit(unitFrames[n].data[i].id,func,unitFrames[n].data[i].number)
			end
		end
		unitFrames[n] = nil
	end
	
end