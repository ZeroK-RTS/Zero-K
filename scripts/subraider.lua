--by Chris Mackey

-- unused piece: 'wake'
local base, firepoint = piece ("base", "firepoint")

local OKP_DAMAGE = tonumber(UnitDefs[unitDefID].customParams.okp_damage)

function script.QueryWeapon(num)
	return firepoint
end
function script.AimFromWeapon(num)
	return firepoint
end

function script.AimWeapon(num, heading, pitch)
	return num == 2
end

function script.Create()
	Move(firepoint, y_axis, 10)
end

function script.BlockShot(num, targetID)
	return GG.Script.OverkillPreventionCheck(unitID, targetID, OKP_DAMAGE, 220, 12, 0.05, true)
end

function script.Killed(recentDamage, maxHealth)
	-- the whole mesh is 1 piece so not much room to do anything fancy
	if recentDamage * 2 < maxHealth then
		return 1
	else
		Explode(base, SFX.SHATTER)
		return 2
	end
end
