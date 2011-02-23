local name = "commweapon_napalmgrenade"
local weaponDef = {
    name                    = [[Hellfire Grenade]],
    accuracy                = 256,
    areaOfEffect            = 256,
    commandFire             = true,
    craterBoost             = 0,
    craterMult              = 0,

    customParams            = {
		slot = [[3]],
        areadamage_preset = [[module_napalmgrenade]],
    },

    damage                  = {
		default = 300,
		planes  = 300,
		subs    = 15,
    },

    explosionGenerator      = [[custom:firewalker_impact]],
    firestarter             = 40,
    impulseBoost            = 0,
    impulseFactor           = 0,
    interceptedByShieldType = 2,
    lineOfSight             = true,
    model                   = [[wep_b_fabby.s3o]],
    noSelfDamage            = true,
    range                   = 450,
    reloadtime              = 8,
    renderType              = 4,
    smokeTrail              = true,
    soundHit                = [[weapon/cannon/wolverine_hit]],
    soundHitVolume          = 8,
    soundStart              = [[weapon/cannon/cannon_fire3]],
    startsmoke              = [[1]],
	startVelocity			  = 350,
	trajectoryHeight		  = 0.3,
    turret                  = true,
    weaponType              = [[MissileLauncher]],
    weaponVelocity          = 350,
}

return name, weaponDef
