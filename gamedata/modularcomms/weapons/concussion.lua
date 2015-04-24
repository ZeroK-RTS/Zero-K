local name = "commweapon_concussion"
local weaponDef = {
	name                    = [[Concussion Shell]],
	alphaDecay              = 0.12,
	areaOfEffect            = 256,
    avoidGround             = true,
	--cegTag                  = [[gauss_tag_m]],
    cegTag                  = [[concussiontrail]],
	commandfire             = true,
	craterBoost             = 0,
	craterMult              = 0,

	customParams            = {
		slot = [[3]],
		muzzleEffectFire = [[custom:RAIDMUZZLE]],
        gatherradius = [[208]],
        smoothradius = [[128]],
        detachmentradius = [[128]],
        smoothmult   = [[0.5]],
	},

	damage                  = {
		default = 180,
		planes  = 180,
		subs    = 9,
	},

	edgeEffectiveness       = 0.5,
	explosionGenerator      = [[custom:bull_fade_concussion]],
    flightTime              = 0,
    fallOffRate             = 0,
	impulseBoost            = 0,
	impulseFactor           = 22.5,
	interceptedByShieldType = 1,
    model                   = [[wep_merl]],
	range                   = 450,
	reloadtime              = 12,
	rgbColor                = [[1 0.6 0]],
	separation              = 0.5,
	size                    = 0.8,
	sizeDecay               = -0.1,
	soundHit                = [[weapon/cannon/earthshaker]],
	soundStart              = [[weapon/gauss_fire]],
	stages                  = 32,
    startVelocity           = 1500,
	turret                  = true,
	waterbounce             = 1,
	weaponType              = [[MissileLauncher]],
	weaponVelocity          = 1500,
}

return name, weaponDef
