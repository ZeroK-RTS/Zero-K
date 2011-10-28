unitDef = {
  unitname                      = [[napalmmissile]],
  name                          = [[Inferno]],
  description                   = [[Napalm Missile]],
  acceleration                  = 1,
  antiweapons                   = [[1]],
  bmcode                        = [[0]],
  brakeRate                     = 0,
  buildAngle                    = 8192,
  buildCostEnergy               = 500,
  buildCostMetal                = 500,
  builder                       = false,
  buildingGroundDecalDecaySpeed = 30,
  buildingGroundDecalSizeX      = 3,
  buildingGroundDecalSizeY      = 3,
  buildingGroundDecalType       = [[napalmmissile_aoplane.dds]],
  buildPic                      = [[napalmmissile.png]],
  buildTime                     = 500,
  canAttack                     = true,
  canGuard                      = true,
  canstop                       = [[1]],
  category                      = [[SINK UNARMED]],
  collisionVolumeOffsets	    = [[0 15 0]],
  collisionVolumeScales		    = [[20 60 20]],
  collisionVolumeTest	        = 1,
  collisionVolumeType	        = [[CylY]],

  customParams                  = {
    description_de = [[Napalm-Rakete]],
    helptext       = [[The Inferno is a large AoE fire weapon. Its direct damage is modest, but the cloud of fire it creates lasts for a very long time.]],
	helptext_de    = [[Der Inferno ist eine große AoE Feuerwaffe. Sein direkter Schaden ist gering, aber die Flammenhölle erzeugt Verluste für längere Zeit.]],
  },

  explodeAs                     = [[SMALL_UNITEX]],
  footprintX                    = 1,
  footprintZ                    = 1,
  idleAutoHeal                  = 5,
  idleTime                      = 1800,
  mass                          = 226,
  maxDamage                     = 1000,
  maxSlope                      = 18,
  maxVelocity                   = 0,
  maxWaterDepth                 = 0,
  minCloakDistance              = 150,
  noAutoFire                    = false,
  objectName                    = [[wep_napalm.s3o]],
  script                        = [[cruisemissile.lua]],
  seismicSignature              = 4,
  selfDestructAs                = [[SMALL_UNITEX]],

  sfxtypes                      = {

    explosiongenerators = {
      [[custom:RAIDMUZZLE]],
    },

  },

  side                          = [[CORE]],
  sightDistance                 = 200,
  smoothAnim                    = true,
  TEDClass                      = [[SPECIAL]],
  turnRate                      = 0,
  useBuildingGroundDecal        = false,
  workerTime                    = 0,
  yardMap                       = [[o]],

  weapons                       = {

    {
      def                = [[WEAPON]],
      badTargetCategory  = [[SWIM LAND SHIP HOVER]],
      onlyTargetCategory = [[SWIM LAND SINK FLOAT SHIP HOVER GUNSHIP]],
    },

  },


  weaponDefs                    = {

    WEAPON = {
      name                    = [[Napalm Missile]],
	  cegTag                  = [[tactrail]],
      areaOfEffect            = 512,
      avoidFriendly           = false,
      collideFriendly         = false,
      craterBoost             = 4,
      craterMult              = 3.5,

	  customParams        	  = {
	    setunitsonfire = "1",
		burntime = 250,
	  },
	  
      damage                  = {
        default = 150,
        planes  = 150,
        subs    = 7.5,
      },

      edgeEffectiveness       = 0.4,
      explosionGenerator      = [[custom:napalm_missile]],
      fireStarter             = 220,
      guidance                = true,
      impulseBoost            = 0,
      impulseFactor           = 0,
      interceptedByShieldType = 1,
      levelGround             = false,
      lineOfSight             = true,
      model                   = [[wep_napalm.s3o]],
      noautorange             = [[1]],
      noSelfDamage            = true,
      propeller               = [[1]],
      range                   = 3500,
      reloadtime              = 10,
      renderType              = 1,
      selfprop                = true,
      shakeduration           = [[1.5]],
      shakemagnitude          = [[32]],
      smokedelay              = [[0.1]],
      smokeTrail              = false,
      soundHit                = [[weapon/missile/nalpalm_missile_hit]],
      soundStart              = [[weapon/missile/tacnuke_launch]],
      startsmoke              = [[1]],
      tolerance               = 4000,
      twoPhase                = true,
      vlaunch                 = true,
      weaponAcceleration      = 180,
      weaponTimer             = 3,
      weaponType              = [[StarburstLauncher]],
      weaponVelocity          = 1200,
    },

  },


  featureDefs                   = {
  },

}

return lowerkeys({ napalmmissile = unitDef })
