function script.Create()
	--Spring.SetUnitCloak(unitID, 4)
	Spring.SetUnitNoDraw(unitID, true)
	Spring.SetUnitNoSelect(unitID, true)
	Spring.SetUnitNoMinimap(unitID, true)
	Spring.SetUnitNeutral(unitID, true)
	--Spring.MoveCtrl.Enable(unitID)
	--local x, y, z = Spring.GetUnitPosition(unitID)
	--Spring.MoveCtrl.SetPosition(x, 1000, z)
	Spring.SetUnitRadiusAndHeight(unitID, 0, 0)
	Spring.GiveOrderToUnit(unitID, CMD.IDLEMODE, {0}, 0)
end

function script.HitByWeapon()
	return 0
end

function script.Killed(recentDamage, maxHealth)
	return 0
end
