local name = "commweapon_napalmgrenade"
local weaponDef = {
    name                    = [[Hellfire Grenade]],
    accuracy                = 256,
    areaOfEffect            = 256,
	--cegTag                  = [[torpedo_trail]],
    commandFire             = true,
    craterBoost             = 0,
    craterMult              = 0,

    customParams            = {
		slot = [[3]],
        areadamage_preset = [[module_napalmgrenade]],
		setunitsonfire = "1",
		burntime = 180,
		muzzleEffectFire = [[custom:RAIDMUZZLE]],
    },

    damage                  = {
		default = 300,
		planes  = 300,
		subs    = 15,
    },

    explosionGenerator      = [[custom:napalmmissile_impact]],
    firestarter             = 180,
    impulseBoost            = 0,
    impulseFactor           = 0,
    interceptedByShieldType = 2,
    model                   = [[wep_b_fabby.s3o]],
    range                   = 450,
    reloadtime              = 8,
    smokeTrail              = true,
    soundHit                = [[weapon/cannon/wolverine_hit]],
    soundHitVolume          = 8,
    soundStart              = [[weapon/cannon/cannon_fire3]],
    startsmoke              = [[1]],
	--startVelocity			  = 350,
	--trajectoryHeight		  = 0.3,
    turret                  = true,
    weaponType              = [[Cannon]],
    weaponVelocity          = 350,
}

return name, weaponDef
