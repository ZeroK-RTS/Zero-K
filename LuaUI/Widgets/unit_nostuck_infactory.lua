function widget:GetInfo()
  return {
    name      = "UnitNoStuckInFactory",
    desc      = "Always move unit away from factory's build yard & Remove an accidental build-unit command given to unit in factory. This prevent case of unit stuck in factory & to make sure unit can complete their move queue.",
    author    = "msafwan",
    date      = "2 January 2014",
    license   = "none",
	handler   = false,
    layer     = 1,
    enabled   = true,  --  loaded by default?
  }
end

--Note: Widget became less relevant for Spring 95+ because unit will always go out from factory in Spring 95+.
VFS.Include("LuaRules/Configs/customcmds.h.lua")
local myTeamID = Spring.GetMyTeamID()

local excludedFactory = {
	[UnitDefNames["factorygunship"].id] = true,
	[UnitDefNames["factoryplane"].id] = true
}

function widget:UnitFromFactory(unitID, unitDefID, unitTeam, factID, factDefID, userOrders)
	---Order unit to move away from factory's build yard---
	if myTeamID == unitTeam and (not excludedFactory[factDefID]) then
		local cmdID, cmdOpts, cmdTag, cmdParam1 = Spring.GetUnitCurrentCommand(unitID)
		if cmdID then
			if not (cmdID == CMD.MOVE or cmdID == CMD_JUMP) then --no rally behaviour?? (we leave unit with CMD.MOVE alone because we don't want to disturb factory's move command)
				local dx,_,dz = Spring.GetUnitDirection(unitID)
				local x,y,z = Spring.GetUnitPosition(unitID)
				dx = dx*100 --Note: don't need trigonometry here because factory direction is either {0+-,1+-} or {1+-,0+-} (1 or 0), so multiply both with 100 elmo is enough
				dz = dz*100
				--note to self: CMD.OPT_META is spacebar, CMD.OPT_INTERNAL is widget. If we use CMD.OPT_INTERNAL Spring might return unit to where it originally started but the benefit is it don't effected by Repeat state (reference: cmd_retreat.lua widget by CarRepairer).
				if ( cmdID < 0 ) and (not cmdParam1 ) then --if build-unit-command (which can be accidentally given when you use Chili Integral Menu)
					Spring.GiveOrderArrayToUnitArray( {unitID},{
							{CMD.REMOVE, {cmdTag}, 0}, --remove build-unit command since its only valid for factory & it prevent idle status from being called for regular unit (it disturb other widget's logic)
							{CMD.INSERT, {0, CMD_RAW_MOVE, CMD.OPT_INTERNAL, x+dx, y, z+dz}, CMD.OPT_ALT},
							{CMD.INSERT, {1, CMD.STOP, CMD.OPT_INTERNAL,}, CMD.OPT_ALT}, --stop unit at end of move command (else it will return to original position).
							})--insert move-stop command behind existing command
				else
					Spring.GiveOrderArrayToUnitArray( {unitID},{
							{CMD.INSERT, {0, CMD_RAW_MOVE, CMD.OPT_INTERNAL, x+dx, y, z+dz}, CMD.OPT_ALT},
							{CMD.INSERT, {1, CMD.STOP, CMD.OPT_INTERNAL,}, CMD.OPT_ALT},
							})
				end
			end
		else --no command at all? (happen when factory is at edge of map and engine ask unit to rally outside of map)
			local dx,_,dz = Spring.GetUnitDirection(unitID)
			local x,y,z = Spring.GetUnitPosition(unitID)
			dx = dx*100
			dz = dz*100
			Spring.GiveOrderToUnit( unitID, CMD_RAW_MOVE, {x+dx, y, z+dz}, 0)
		end
		------
	end
end
