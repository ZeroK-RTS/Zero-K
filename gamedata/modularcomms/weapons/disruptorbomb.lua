local name = "commweapon_disruptorbomb"
local weaponDef = {
    name                    = [[Disruptor Bomb]],
    accuracy                = 256,
    areaOfEffect            = 512,
	--cegTag                  = [[torpedo_trail]],
    commandFire             = true,
    craterBoost             = 0,
    craterMult              = 0,

    customParams            = {
		slot = [[3]],
        --timeslow_preset = [[module_disruptorbomb]],
		timeslow_damagefactor = [[4]],
		muzzleEffectFire = [[custom:RAIDMUZZLE]],
    },

    damage                  = {
		default = 350,
		planes  = 350,
		subs    = 17.5,
    },

    explosionGenerator      = [[custom:riotballplus]],
    fireStarter             = 100,
    impulseBoost            = 0,
    impulseFactor           = 0,
    interceptedByShieldType = 2,
    model                   = [[wep_b_fabby.s3o]],
    range                   = 450,
    reloadtime              = 12,
    smokeTrail              = true,
    soundHit                = [[weapon/aoe_aura]],
    soundHitVolume          = 8,
    soundStart              = [[weapon/cannon/cannon_fire3]],
    startsmoke              = [[1]],
	--startVelocity			= 350,
	--trajectoryHeight		= 0.3,
    turret                  = true,
    weaponType              = [[Cannon]],
    weaponVelocity          = 350,
}

return name, weaponDef
