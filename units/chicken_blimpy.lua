unitDef = {
  unitname            = [[chicken_blimpy]],
  name                = [[Blimpy]],
  description         = [[Dodo Bomber]],
  airHoverFactor      = 0,
  amphibious          = true,
  bmcode              = [[1]],
  buildCostEnergy     = 0,
  buildCostMetal      = 0,
  builder             = false,
  buildPic            = [[chicken_blimpy.png]],
  buildTime           = 750,
  canAttack           = true,
  canFly              = true,
  canGuard            = true,
  canLand             = true,
  canMove             = true,
  canPatrol           = true,
  canstop             = [[1]],
  canSubmerge         = false,
  category            = [[FIXEDWING]],
  collide             = false,
  cruiseAlt           = 250,

  customParams        = {
    description_fr = [[Bombardier ? Dodos]],
	description_de = [[Dodo Bomber]],
    helptext       = [[Blimpy drops a Dodo on unsuspecting armies and bases. ]],
    helptext_fr    = [[Le Blimpy est une unit? a?rienne ressemblant ? un bourdon dont apparemment la seule vocation soit de l?cher sur l'adversaire le Dodo qu'elle transporte sous son ventre. D?vastateur contre les bases.]],
	helptext_de    = [[Blimpy wirft Dodos auf ahnungslose Heere und Basen ab.]],
  },

  defaultmissiontype  = [[Standby]],
  explodeAs           = [[NOWEAPON]],
  floater             = true,
  footprintX          = 4,
  footprintZ          = 4,
  iconType            = [[bomberassault]],
  idleAutoHeal        = 20,
  idleTime            = 300,
  leaveTracks         = true,
  maneuverleashlength = [[64000]],
  mass                = 258,
  maxDamage           = 1850,
  maxSlope            = 18,
  maxVelocity         = 5,
  minCloakDistance    = 75,
  moverate1           = [[32]],
  noAutoFire          = false,
  noChaseCategory     = [[TERRAFORM FIXEDWING SATELLITE]],
  objectName          = [[chicken_blimpy.s3o]],
  power               = 750,
  seismicSignature    = 0,
  selfDestructAs      = [[NOWEAPON]],
  separation          = [[0.2]],

  sfxtypes            = {

    explosiongenerators = {
      [[custom:blood_spray]],
      [[custom:blood_explode]],
      [[custom:dirt]],
    },

  },

  side                = [[THUNDERBIRDS]],
  sightDistance       = 512,
  smoothAnim          = true,
  steeringmode        = [[2]],
  TEDClass            = [[VTOL]],
  turnRate            = 6000,
  workerTime          = 0,

  weapons             = {

    {
      def                = [[BOGUS_BOMB]],
      badTargetCategory  = [[SWIM LAND SHIP HOVER]],
      onlyTargetCategory = [[SWIM LAND SINK FLOAT SHIP HOVER]],
    },


    {
      def                = [[BOMBTRIGGER]],
      mainDir            = [[0 -1 0]],
      maxAngleDif        = 70,
      onlyTargetCategory = [[LAND SINK SHIP SWIM FLOAT HOVER SUB]],
    },


    {
      def                = [[DODOBOMB]],
      mainDir            = [[0 -1 0]],
      maxAngleDif        = 90,
      onlyTargetCategory = [[FIXEDWING LAND SINK SHIP SWIM FLOAT GUNSHIP HOVER SUB]],
    },

  },


  weaponDefs          = {

    BOGUS_BOMB  = {
      name                    = [[BogusBomb]],
      areaOfEffect            = 80,
      commandfire             = true,
      craterBoost             = 0,
      craterMult              = 0,

      damage                  = {
        default = 0,
      },

      dropped                 = true,
      edgeEffectiveness       = 0,
      explosionGenerator      = [[custom:NONE]],
      impulseBoost            = 0,
      impulseFactor           = 0,
      interceptedByShieldType = 1,
      manualBombSettings      = true,
      model                   = [[wep_b_fabby.s3o]],
      myGravity               = 1000,
      noSelfDamage            = true,
      range                   = 300,
      reloadtime              = 0.5,
      renderType              = 6,
      scale                   = [[0]],
      weaponType              = [[AircraftBomb]],
    },


    BOMBTRIGGER = {
      name                    = [[BOMBTRIGGER]],
      accuracy                = 12000,
      areaOfEffect            = 1,
      beamTime                = 0.1,
      beamWeapon              = true,
      canattackground         = true,
      coreThickness           = 0.5,
      craterBoost             = 0,
      craterMult              = 0,

      damage                  = {
        default = 1,
        planes  = 1,
        subs    = 1,
      },

      explosionGenerator      = [[custom:none]],
      impactOnly              = true,
      impulseBoost            = 0,
      impulseFactor           = 0,
      interceptedByShieldType = 0,
      lineOfSight             = true,
      lodDistance             = 10000,
      minIntensity            = 1,
      noSelfDamage            = true,
      range                   = 900,
      reloadtime              = 14,
      renderType              = 0,
      rgbColor                = [[0 0 0]],
      targetMoveError         = 0,
      thickness               = 0,
      tolerance               = 10000,
      turret                  = true,
      weaponType              = [[BeamLaser]],
      weaponVelocity          = 100,
    },


    DODOBOMB    = {
      name                    = [[Dodo Bomb]],
      accuracy                = 60000,
      areaOfEffect            = 1,
      avoidFeature            = false,
      avoidFriendly           = false,
      burnblow                = true,
      burst                   = 1,
      burstrate               = 0.1,
      collideFriendly         = false,
      craterBoost             = 0,
      craterMult              = 0,

      damage                  = {
        default = 1,
        planes  = 1,
        subs    = 1,
      },

      dropped                 = true,
      explosionGenerator      = [[custom:none]],
      fireStarter             = 70,
      flightTime              = 0,
      guidance                = false,
      impactOnly              = true,
      impulseBoost            = 0,
      impulseFactor           = 0.4,
      interceptedByShieldType = 0,
      lineOfSight             = true,
      manualBombSettings      = true,
      model                   = [[chicken_dodobomb.s3o]],
      noSelfDamage            = true,
      range                   = 900,
      reloadtime              = 10,
      renderType              = 1,
      smokedelay              = [[0.1]],
      smokeTrail              = false,
      startsmoke              = [[1]],
      startVelocity           = 200,
      targetMoveError         = 0.2,
      tolerance               = 8000,
      tracks                  = false,
      turnRate                = 4000,
      turret                  = true,
      waterweapon             = true,
      weaponAcceleration      = 200,
      weaponTimer             = 0.1,
      weaponType              = [[AircraftBomb]],
      weaponVelocity          = 200,
    },

  },

}

return lowerkeys({ chicken_blimpy = unitDef })
