function widget:GetInfo()
  return {
    name      = "UnitNoStuckInFactory",
    desc      = "DEBUG: Always move unit away from factory's build yard. Prevent case of unit stuck in factory",
    author    = "msafwan",
    date      = "23 Jan 2013",
    license   = "none",
	handler   = false,
    layer     = 1,
    enabled   = true,  --  loaded by default?
  }
end

function widget:UnitFromFactory(unitID, unitDefID, unitTeam, factID, factDefID, userOrders)
	---Order unit to move away from factory's build yard---
	local queue = Spring.GetUnitCommands(unitID, 1)
	local firstCommand = queue and queue[1]
	if firstCommand then
		if firstCommand.id ~= CMD.MOVE then --we leave unit with CMD.MOVE alone because we don't want to disturb factory's move command (factory's rallying behaviour)
			local dx,_,dz = Spring.GetUnitDirection(unitID)
			local x,y,z = Spring.GetUnitPosition(unitID)
			dx = dx*100 --Note: don't need trigonometry here because factory direction is either {0+-,1+-} or {1+-,0+-} (1 or 0), so multiply both with 100 elmo is enough
			dz = dz*100
			Spring.GiveOrderToUnit(unitID, CMD.INSERT, {0, CMD.MOVE, CMD.OPT_INTERNAL, x+dx, y, z+dz}, {"alt"})--insert move command behind existing command
			--Spring.Echo(CMD[firstCommand.id])
		end
	end
	------
end