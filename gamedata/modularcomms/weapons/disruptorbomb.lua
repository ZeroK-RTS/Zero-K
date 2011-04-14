local name = "commweapon_disruptorbomb"
local weaponDef = {
    name                    = [[Disruptor Bomb]],
    accuracy                = 256,
    areaOfEffect            = 512,
    commandFire             = true,
    craterBoost             = 0,
    craterMult              = 0,

    customParams            = {
		slot = [[3]],
        --timeslow_preset = [[module_disruptorbomb]],
		timeslow_damagefactor = [[2]],
		muzzleEffect = [[custom:RAIDMUZZLE]],
    },

    damage                  = {
		default = 600,
		planes  = 600,
		subs    = 30,
    },

    explosionGenerator      = [[custom:riotballplus]],
    fireStarter             = 100,
    impulseBoost            = 0,
    impulseFactor           = 0,
    interceptedByShieldType = 2,
    model                   = [[wep_b_fabby.s3o]],
    noSelfDamage            = true,
    range                   = 450,
    reloadtime              = 12,
    smokeTrail              = true,
    soundHit                = [[weapon/aoe_aura]],
    soundHitVolume          = 8,
    soundStart              = [[weapon/cannon/cannon_fire3]],
    startsmoke              = [[1]],
	startVelocity			= 350,
	trajectoryHeight		= 0.3,
    turret                  = true,
    weaponType              = [[MissileLauncher]],
    weaponVelocity          = 350,
}

return name, weaponDef
