unitDef = {
  unitname               = [[shipcarrier]],
  name                   = [[Reef]],
  description            = [[Aircraft Carrier (Bombardment), Stockpiles tacnukes at 10 m/s]],
  acceleration           = 0.0354,
  activateWhenBuilt   	 = true,
  brakeRate              = 0.0466,
  buildCostEnergy        = 3500,
  buildCostMetal         = 3500,
  builder                = false,
  buildPic               = [[shipcarrier.png]],
  buildTime              = 3500,
  canMove                = true,
  canManualFire          = true,
  cantBeTransported      = true,
  category               = [[SHIP]],
  CollisionSphereScale   = 0.6,
  collisionVolumeOffsets = [[10 -10 0]],
  collisionVolumeScales  = [[80 80 240]],
  collisionVolumeType    = [[CylZ]],
  corpse                 = [[DEAD]],

  customParams           = {
    description_de = [[Flugzeugträger (Bomber)]],
    description_fr = [[Porte-Avion Bombardier]],
    helptext       = [[The most versatile ship on the high seas, the carrier serves several functions. It is equipped with a manual-fire tactical missile launcher for long range bombardment and serves as a mobile repair base for friendly aircraft. Perhaps most notably, the carrier provides its own complement of surface attack drones to engage targets.]],
	midposoffset   = [[0 -10 0]],
    modelradius    = [[80]],
	stockpiletime  = [[60]],
	stockpilecost  = [[600]],
	priority_misc = 2, -- High
	extradrawrange = 3000,
  },

  explodeAs              = [[ATOMIC_BLASTSML]],
  floater                = true,
  footprintX             = 10,
  footprintZ             = 10,
  iconType               = [[shipcarrier]],
  idleAutoHeal           = 5,
  idleTime               = 1800,
  maxDamage              = 7500,
  maxVelocity            = 2.75,
  minCloakDistance       = 75,
  minWaterDepth          = 10,
  movementClass          = [[BOAT10]],
  objectName             = [[shipcarrier.dae]],
  script                 = [[shipcarrier.lua]],
  radarEmitHeight        = 48,
  selfDestructAs         = [[BIG_UNITEX]],
  sfxtypes               = {
    explosiongenerators = {
      [[custom:xamelimpact]],
      [[custom:ROACHPLOSION]],
      [[custom:shellshockflash]],
    },
  },
  showNanoSpray          = false,
  sightDistance          = 660,
  sonarDistance          = 660,
  turninplace            = 0,
  turnRate               = 233,
  waterline              = 20,

  weapons                = {

    {
      def                = [[carriertargeting]],
      badTargetCategory  = [[SINK]],
      onlyTargetCategory = [[SWIM LAND SINK TURRET FLOAT SHIP HOVER]],
    },

	{
      def                = [[TACNUKE]],
      badTargetCategory  = [[SWIM LAND SUB SHIP HOVER]],
      onlyTargetCategory = [[SWIM LAND SUB SINK TURRET FLOAT SHIP HOVER]],
    },
	
  },

  weaponDefs             = {

	TACNUKE        = {
      name                    = [[Tactical Nuke]],
      areaOfEffect            = 256,
      collideFriendly         = false,
      commandfire             = true,
      craterBoost             = 4,
      craterMult              = 3.5,

      damage                  = {
        default = 3500,
        planes  = 3500,
        subs    = 175,
      },

      edgeEffectiveness       = 0.4,
      explosionGenerator      = [[custom:NUKE_150]],
      fireStarter             = 0,
      flightTime              = 10,
      impulseBoost            = 0,
      impulseFactor           = 0.4,
      interceptedByShieldType = 1,
      model                   = [[wep_tacnuke.s3o]],
      noSelfDamage            = true,
      range                   = 3000,
      reloadtime              = 1,
      smokeTrail              = true,
      soundHit                = [[explosion/mini_nuke]],
      soundStart              = [[weapon/missile/tacnuke_launch]],
      stockpile               = true,
      stockpileTime           = 10^5,
      tolerance               = 4000,
      turnrate                = 18000,
      waterWeapon             = true,
      weaponAcceleration      = 180,
      weaponTimer             = 4,
      weaponType              = [[StarburstLauncher]],
      weaponVelocity          = 1200,
    },

    carriertargeting   = {
      name                    = [[Fake Targeting Weapon]],
      areaOfEffect            = 8,
      collideFriendly         = false,
      craterBoost             = 0,
      craterMult              = 0,

      damage                  = {
        default = 1E-06,
        planes  = 1E-06,
        subs    = 5E-08,
      },

      explosionGenerator      = [[custom:NONE]],
      fireStarter             = 0,
      flightTime              = 1,
      impactOnly              = true,
      interceptedByShieldType = 1,
      range                   = 1000,
      reloadtime              = 1.25,
      size                    = 1E-06,
      smokeTrail              = false,

      textures                = {
        [[null]],
        [[null]],
        [[null]],
      },

      turnrate                = 1000000000,
      turret                  = true,
      weaponAcceleration      = 20000,
      weaponTimer             = 0.5,
      weaponType              = [[StarburstLauncher]],
      weaponVelocity          = 20000,
    },

  },

  featureDefs            = {

    DEAD  = {
      CollisionSphereScale   = 0.6,
      collisionVolumeOffsets = [[-5 -10 0]],
	  collisionVolumeScales  = [[80 80 240]],
	  collisionVolumeType    = [[CylZ]],
      blocking         = false,
      featureDead      = [[HEAP]],
      footprintX       = 6,
      footprintZ       = 6,
      object           = [[shipcarrier_dead.dae]],
    },

    HEAP  = {
      blocking         = false,
      footprintX       = 6,
      footprintZ       = 6,
      object           = [[debris4x4b.s3o]],
    },

  },

}

return lowerkeys({ shipcarrier = unitDef })
