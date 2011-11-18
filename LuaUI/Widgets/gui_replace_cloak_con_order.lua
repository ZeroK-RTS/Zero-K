

function widget:GetInfo()
  return {
    name      = "Replace Cloak Con Orders",
    desc      = "Prevents con accidental decloak in enemy territory by replacing Repair, Reclaim and Rez with Move",
    author    = "GoogleFrog",
    date      = "13 August 2011",
    license   = "GNU GPL, v2 or later",
    layer     = 0,
    enabled   = false  --  loaded by default?
  }
end

options_path = 'Game/Unit AI/Replace Cloak Con Orders'
options = { 
	reclaim = {name='Replace Reclaim', type='bool', value=true},
	resurrect = {name='Replace Resurrect', type='bool', value=true},
	repair = {name='Replace Repair', type='bool', value=true},
}

function widget:CommandNotify(id, params, cmdOptions)
	if cmdOptions.right and #params < 4 and ((id == CMD.REPAIR and options.repair.value) or 
	(id == CMD.RECLAIM and options.reclaim.value) or id == (CMD.RESURRECT and options.resurrect.value)) then
		local selUnits = Spring.GetSelectedUnits()
		local replace = false
		for i = 1, #selUnits do
			local unitID = selUnits[i]
			local ud = Spring.GetUnitDefID(unitID)
			-- assumption here is that everything that can repair or rez can also reclaim
			if ud and UnitDefs[ud] and UnitDefs[ud].canReclaim and Spring.GetUnitIsCloaked(unitID) and UnitDefs[ud].speed > 0 then
				replace = true
				break
			end
		end
		if replace then
			local x,y,z
			if #params == 1 then
				if id == CMD.REPAIR then
					if Spring.ValidUnitID(params[1]) and Spring.GetUnitPosition(params[1]) then
						x,_,z = Spring.GetUnitPosition(params[1])
						y = Spring.GetGroundHeight(x,z)
					end
				else
					params[1] = params[1] - Game.maxUnits
					if Spring.ValidFeatureID(params[1]) and Spring.GetFeaturePosition(params[1]) then
						x,_,z = Spring.GetFeaturePosition(params[1])
						y = Spring.GetGroundHeight(x,z)
					end
				end
			else
				x,y,z = params[1], params[2], params[3]
			end
			if x and y then
				for i = 1, #selUnits do
					local unitID = selUnits[i]
					Spring.GiveOrderToUnit(unitID,CMD.MOVE,{x,y,z},cmdOptions)
				end
			end
		end
		return replace
	end
	return false
end