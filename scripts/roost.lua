local emit = piece 'emit'
-- the rim is piece 'base' but not actually used

function script.AimWeapon() return true end
function script.AimFromWeapon() return emit end
function script.QueryWeapon() return emit end

function script.Killed(recentDamage, maxHealth)
	EmitSfx(emit, 1025)
	return 1
end
