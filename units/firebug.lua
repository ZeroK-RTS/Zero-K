unitDef = {
  unitname               = [[firebug]],
  name                   = [[firebug]],
  description            = [[Burrowing Fire Skirmisher]],
  acceleration           = 0.25,
  activateWhenBuilt      = true,
  brakeRate              = 0.4,
  buildCostEnergy        = 300,
  buildCostMetal         = 300,
  builder                = false,
  buildPic               = [[FIREBUG.png]],
  buildTime              = 300,
  canAttack              = true,
  canGuard               = true,
  canMove                = true,
  canPatrol              = true,
  canstop                = [[1]],
  category               = [[LAND]],
  cloakCost              = 0,
  collisionVolumeOffsets = [[0 0 0]],
  collisionVolumeScales  = [[22 20 22]],
  collisionVolumeTest    = 1,
  collisionVolumeType    = [[ellipsoid]],

  customParams           = {
    helptext       = [[The Firebug shoots a single missile at range with a 50 second reload time doing 1500 damage and 2000 fire damage. The firebug can then run away and burrow until it reloads its missile.]],
 },

  explodeAs              = [[FIREBUG_DEATH]],
  fireState              = 0,
  footprintX             = 2,
  footprintZ             = 2,
  iconType               = [[walkerbomb]],
  idleAutoHeal           = 5,
  idleTime               = 1800,
  mass                   = 200,
  maxDamage              = 300,
  maxSlope               = 36,
  maxVelocity            = 3,
  maxWaterDepth          = 15,
  minCloakDistance       = 75,
  movementClass          = [[KBOT2]],
  noAutoFire             = false,
  noChaseCategory        = [[FIXEDWING LAND SINK TURRET SHIP SATELLITE SWIM GUNSHIP FLOAT SUB HOVER]],
  objectName             = [[firebug.s3o]],
  pushResistant          = 0,
  script                 = [[firebug.lua]],
  seismicSignature       = 4,
  selfDestructAs         = [[FIREBUG_DEATH]],
  selfDestructCountdown  = 1,

  sfxtypes               = {

    explosiongenerators = {
      [[custom:RAIDMUZZLE]],
      [[custom:VINDIBACK]],
      [[custom:digdig]],
    },

  },

  side                   = [[CORE]],
  sightDistance          = 240,
  smoothAnim             = true,
  turnRate               = 3000,
  workerTime             = 0,

  weapons             = {

    {
      def                = [[MISSILE]],
      onlyTargetCategory = [[FIXEDWING LAND SINK TURRET SHIP SWIM FLOAT GUNSHIP HOVER]],
    },

  },


  weaponDefs          = {

    MISSILE = {
      name                    = [[Napalm Missile]],
      areaOfEffect            = 96,
      cegTag                  = [[missiletrailred]],
      craterBoost             = 1,
      craterMult              = 2,
	  
	  customParams        	  = {
	    setunitsonfire = "1",
	    burnchance     = "1",
		burnDamage     = "2",
		burnTime       = "5000", --~1904 damage
	},
	  
      damage                  = {
        default = 1500,
        planes  = 1500,
        subs    = 7.5,
      },

      fireStarter             = 100,
      fixedlauncher           = true,
      flightTime              = 3.5,
      impulseBoost            = 0,
      impulseFactor           = 0.2,
      interceptedByShieldType = 2,
      model                   = [[firebug_missile.s3o]],
      projectiles             = 1,
      range                   = 520,
      reloadtime              = 50,
      selfprop                = true,
      smokedelay              = [[.1]],
      smokeTrail              = true,
      soundHit                = [[explosion/ex_med5]],
      soundHitVolume          = 8,
      soundStart              = [[weapon/missile/rapid_rocket_fire2]],
      soundStartVolume        = 7,
      startsmoke              = [[1]],
      startVelocity           = 100,
      texture2                = [[lightsmoketrail]],
      tracks                  = true,
      trajectoryHeight        = 0.2,
      turnRate                = 30000,
      turret                  = true,
      weaponAcceleration      = 100,
      weaponTimer             = 3,
      weaponType              = [[MissileLauncher]],
      weaponVelocity          = 400,
    },

  },
  
}

return lowerkeys({ firebug = unitDef })
