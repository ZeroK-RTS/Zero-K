unitDef = {
  unitname               = [[amphbomb]],
  name                   = [[Limpet]],
  description            = [[Amphibious slow mine]],
  acceleration           = 0.25,
  activateWhenBuilt      = true,
  brakeRate              = 0.4,
  buildCostEnergy        = 100,
  buildCostMetal         = 100,
  builder                = false,
  buildPic               = [[AMPHBOMB.png]],
  buildTime              = 100,
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
    description_pl = [[Amfibijna bomba spowalniajaca]],
    helptext       = [[The Limpet can dodge most slow projectiles thanks to its agility and small size, allowing it to get close to enemy units in order to detonate, slowing and damaging them.]],
    helptext_pl    = [[Dzieki malym rozmiarom i szybkosci Limpet moze unikac wolniejszych pociskow, co pozwala mu podejsc pod jednostki przeciwnika i zdetonowac sie, zadajac obrazenia i spowalniajac.]],
 	maxwatertank = [[100]],
 },

  explodeAs              = [[AMPHBOMB_DEATH]],
  fireState              = 0,
  footprintX             = 2,
  footprintZ             = 2,
  iconType               = [[walkerbomb]],
  idleAutoHeal           = 5,
  idleTime               = 1800,
  mass                   = 100,
  maxDamage              = 140,
  maxSlope               = 36,
  maxVelocity            = 4.1,
  maxWaterDepth          = 15,
  minCloakDistance       = 75,
  movementClass          = [[AKBOT2]],
  noAutoFire             = false,
  noChaseCategory        = [[FIXEDWING LAND SINK TURRET SHIP SATELLITE SWIM GUNSHIP FLOAT SUB HOVER]],
  objectName             = [[amphbomb.s3o]],
  pushResistant          = 0,
  script                 = [[amphbomb.lua]],
  seismicSignature       = 4,
  selfDestructAs         = [[AMPHBOMB_DEATH]],
  selfDestructCountdown  = 1,

  sfxtypes               = {

    explosiongenerators = {
      [[custom:RAIDMUZZLE]],
      [[custom:VINDIBACK]],
      [[custom:RIOTBALL]],
      [[custom:digdig]], --EmitSfx(piece, 1024+3)
    },

  },

  side                   = [[CORE]],
  sightDistance          = 240,
  sonarDistance          = 260,
  smoothAnim             = true,
  turnRate               = 3000,
  workerTime             = 0,

  weapons             = {

    {
      def                = [[WATERCANNON]],
      onlyTargetCategory = [[FIXEDWING LAND SINK TURRET SHIP SWIM FLOAT GUNSHIP HOVER]],
    },

  },


  weaponDefs          = {

    WATERCANNON    = {
      name                    = [[Disruptor Pulser]],
      areaOfEffect            = 360,
      burst		              = 7,
      burstRate		          = 0.15,
      craterBoost             = 0,
      craterMult              = 0,

      damage                  = {
        default = 15,
        planes  = 15,
        subs    = 15,
      },

      customParams           = {
	    lups_explodespeed = 1,
	    lups_explodelife = 0.6,
      },

      explosionGenerator      = [[custom:GIANT_WATER_HIT]],
		cegTag					= [[sonictrail]],
      explosionSpeed          = 10000,
      edgeEffectiveness       = 0.8,
      fireStarter             = 0,
      impactOnly              = false,
      interceptedByShieldType = 1,
      range                   = 200,
      reloadtime              = 6.0,
      size                    = 1E-06,
      soundStart              = [[weapon/laser/pulse_laser2]],
      soundStartVolume	      = 0.9,
      soundTrigger            = true,
      smokeTrail              = false,
	  waterweapon             = true,
	  myGravity               = 8,

      textures                = {
        [[null]],
        [[null]],
        [[null]],
      },

      turnrate                = 90000,
      turret                  = true,
      weaponAcceleration      = 200,
      weaponTimer             = 0.1,
      flightTime              = 0.2,
      weaponType              = [[StarburstLauncher]],
      weaponVelocity          = 800,
    },

  },
  
}

return lowerkeys({ amphbomb = unitDef })
