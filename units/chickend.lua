unitDef = {
  unitname                      = [[chickend]],
  name                          = [[Chicken Tube]],
  description                   = [[Defense and energy source]],
  acceleration                  = 0,
  activateWhenBuilt             = true,
  bmcode                        = [[0]],
  brakeRate                     = 0,
  buildCostEnergy               = 0,
  buildCostMetal                = 0,
  builder                       = false,
  buildingGroundDecalDecaySpeed = 30,
  buildingGroundDecalSizeX      = 5,
  buildingGroundDecalSizeY      = 5,
  buildingGroundDecalType       = [[chickend_aoplane.dds]],
  buildPic                      = [[chickend.png]],
  buildTime                     = 120,
  canAttack                     = true,
  canstop                       = [[1]],
  category                      = [[SINK]],

  customParams                  = {
    description_fr = [[Defense d'antres]],
	description_de = [[Verteidigung und Energiequelle]],
    helptext       = [[The Tube is the chicken's only defense structure, firing deadly spores at air and ground targets alike.]],
    helptext_fr    = [[La d?fense basique des antres de poulets, employant des spores ? grande dur?e de vie poursuivant l'adversaire avant de le percuter brutalement.]],
	helptext_de    = [[Tube ist die einzige Verteidigungsanlage der Chicken und verschießt tödliche Sporen gleichermaßen gegen Luft- und Bodenziele.]],
  },

  defaultmissiontype            = [[GUARD_NOMOVE]],
  energyMake                    = 2,
  explodeAs                     = [[NOWEAPON]],
  footprintX                    = 3,
  footprintZ                    = 3,
  iconType                      = [[defense]],
  idleAutoHeal                  = 5,
  idleTime                      = 1800,
  levelGround                   = false,
  mass                          = 120,
  maxDamage                     = 500,
  maxSlope                      = 36,
  maxVelocity                   = 0,
  maxWaterDepth                 = 20,
  noAutoFire                    = false,
  noChaseCategory               = [[FIXEDWING LAND SHIP SATELLITE SWIM GUNSHIP SUB HOVER]],
  objectName                    = [[tube.s3o]],
  onoffable                     = true,
  power                         = 120,
  seismicSignature              = 4,
  selfDestructAs                = [[NOWEAPON]],

  sfxtypes                      = {

    explosiongenerators = {
      [[custom:blood_spray]],
      [[custom:blood_explode]],
      [[custom:dirt]],
    },

  },

  side                          = [[THUNDERBIRDS]],
  sightDistance                 = 512,
  smoothAnim                    = true,
  TEDClass                      = [[METAL]],
  turnRate                      = 0,
  upright                       = false,
  useBuildingGroundDecal        = true,
  workerTime                    = 0,
  yardMap                       = [[ooooooooo]],

  weapons                       = {

    {
      def                = [[SPORES]],
      onlyTargetCategory = [[FIXEDWING LAND SINK SHIP SWIM FLOAT GUNSHIP HOVER]],
    },

  },


  weaponDefs                    = {

    SPORES = {
      name                    = [[Explosive Spores]],
      areaOfEffect            = 96,
      avoidFriendly           = false,
      burst                   = 4,
      burstrate               = 0.2,
      collideFriendly         = false,
      craterBoost             = 0,
      craterMult              = 0,

      damage                  = {
        default = 60,
        planes  = 60,
        subs    = 60,
      },

      dance                   = 60,
      explosionGenerator      = [[custom:RED_GOO]],
      fireStarter             = 0,
      flightTime              = 5,
      groundbounce            = 1,
      heightmod               = 0.5,
      impulseBoost            = 0,
      impulseFactor           = 0.4,
      interceptedByShieldType = 2,
      lineOfSight             = true,
      model                   = [[chickeneggyellow.s3o]],
      range                   = 460,
      reloadtime              = 12,
      renderType              = 1,
      smokedelay              = [[0.1]],
      smokeTrail              = true,
      startsmoke              = [[1]],
      startVelocity           = 100,
      texture1                = [[]],
      texture2                = [[sporetrail]],
      tolerance               = 10000,
      tracks                  = true,
      trajectoryHeight        = 2,
      turnRate                = 24000,
      turret                  = true,
      waterweapon             = true,
      weaponAcceleration      = 100,
      weaponType              = [[MissileLauncher]],
      weaponVelocity          = 500,
      wobble                  = 32000,
    },

  },

}

return lowerkeys({ chickend = unitDef })
