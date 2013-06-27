function widget:GetInfo()
  return {
    name      = "UnitNoStuckInFactory",
    desc      = "Always move unit away from factory's build yard & Remove an accidental build unit command from unit from factory. Prevent case of unit stuck in factory & to make sure unit can complete their move queue.",
    author    = "msafwan",
    date      = "27 June 2013",
    license   = "none",
	handler   = false,
    layer     = 1,
    enabled   = true,  --  loaded by default?
  }
end

local myTeamID = Spring.GetMyTeamID()
local excludedFactory = {nil}
do
	excludedFactory[UnitDefnames["factorygunship"].id] = true
	excludedFactory[UnitDefnames["factoryplane"].id] = true
end

function widget:UnitFromFactory(unitID, unitDefID, unitTeam, factID, factDefID, userOrders)
	if myTeamID == unitTeam and (not excludedFactory[factDefID]) then
		---Order unit to move away from factory's build yard---
		local queue = Spring.GetUnitCommands(unitID, 1)
		local firstCommand = queue and queue[1]
		if firstCommand then
			if firstCommand.id ~= CMD.MOVE then --we leave unit with CMD.MOVE alone because we don't want to disturb factory's move command (factory's rallying behaviour)
				local dx,_,dz = Spring.GetUnitDirection(unitID)
				local x,y,z = Spring.GetUnitPosition(unitID)
				dx = dx*100 --Note: don't need trigonometry here because factory direction is either {0+-,1+-} or {1+-,0+-} (1 or 0), so multiply both with 100 elmo is enough
				dz = dz*100
				--note to self: CMD.OPT_META is spacebar, CMD.OPT_INTERNAL is widget. If we use CMD.OPT_INTERNAL Spring might return unit to where it originally started but the benefit is it don't effected by Repeat state (reference: cmd_retreat.lua widget by CarRepairer).
				if ( firstCommand.id < 0 ) and (not firstCommand.params[1] ) then --if build-unit-command (which can be accidentally given when you use Chili Integral Menu)
					Spring.GiveOrderArrayToUnitArray( {unitID},{
							{CMD.REMOVE, {firstCommand.tag}, {}}, --remove build-unit-command since its not functional on the unit & prevent idle state to be achieved.
							{CMD.INSERT, {0, CMD.MOVE, CMD.OPT_INTERNAL, x+dx, y, z+dz}, {"alt"}},   
							{CMD.INSERT, {1, CMD.STOP, CMD.OPT_INTERNAL,}, {"alt"}}, --stop unit at end of move command (else it will return to original position).
							})--insert move-stop command behind existing command
				else	
					Spring.GiveOrderArrayToUnitArray( {unitID},{
							{CMD.INSERT, {0, CMD.MOVE, CMD.OPT_INTERNAL, x+dx, y, z+dz}, {"alt"}},   
							{CMD.INSERT, {1, CMD.STOP, CMD.OPT_INTERNAL,}, {"alt"}},  --stop unit at end of move command (else it will return to original position).
							})--insert move-stop command behind existing command
					--Spring.Echo(CMD[firstCommand.id])
				end
			end
		end
		------
	end
end