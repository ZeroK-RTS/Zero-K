unitDef = {
  unitname            = [[attackdrone]],
  name                = [[Firefly]],
  description         = [[Attack Drone]],
  acceleration        = 0.3,
  airHoverFactor      = 4,
  amphibious          = true,
  brakeRate           = 4.18,
  buildCostEnergy     = 50,
  buildCostMetal      = 50,
  builder             = false,
  buildPic            = [[attackdrone.png]],
  buildTime           = 50,
  canAttack           = true,
  canFly              = true,
  canGuard            = true,
  canMove             = true,
  canPatrol           = true,
  canstop             = [[1]],
  canSubmerge         = false,
  category            = [[GUNSHIP]],
  collide             = false,
  
  collisionVolumeOffsets        = [[0 0 0]],
  collisionVolumeScales         = [[28 12 26]],
  collisionVolumeTest           = 1,
  collisionVolumeType           = [[ellipsoid]],    
  
  cruiseAlt           = 100,
  defaultmissiontype  = [[VTOL_standby]],
  explodeAs           = [[TINY_BUILDINGEX]],
  floater             = true,
  footprintX          = 2,
  footprintZ          = 2,
  hoverAttack         = true,
  iconType            = [[fighter]],
  mass                = 84,
  maxDamage           = 160,
  maxVelocity         = 7,
  minCloakDistance    = 75,
  noAutoFire          = false,
  noChaseCategory     = [[TERRAFORM SATELLITE SUB]],
  objectName          = [[attackdrone.s3o]],
  refuelTime          = 10,
  scale               = [[1]],
  script              = [[attackdrone.lua]],
  seismicSignature    = 0,
  selfDestructAs      = [[TINY_BUILDINGEX]],
  
  customParams        = {
	description_de = [[Trägerdrohne]],
	helptext_de    = [[]],
  },
  
  
  sfxtypes            = {

    explosiongenerators = {
    },

  },

  side                = [[ARM]],
  sightDistance       = 500,
  turnRate            = 792,
  upright             = true,

  weapons             = {

    {
      def                = [[LASER]],
      badTargetCategory  = [[FIXEDWING]],
      mainDir            = [[0 0 1]],
      maxAngleDif        = 90,
      onlyTargetCategory = [[FIXEDWING LAND SINK SHIP SWIM FLOAT GUNSHIP HOVER]],
    },

  },


  weaponDefs          = {

    LASER      = {
      name                    = [[Light Particle Beam]],
      beamDecay               = 0.9,
      beamTime                = 0.01,
      beamttl                 = 60,
      coreThickness           = 0.25,
      craterBoost             = 0,
      craterMult              = 0,
      cylinderTargetting      = 1,

      damage                  = {
        default = 32,
        subs    = 1.6,
      },

      explosionGenerator      = [[custom:flash_teal7]],
      fireStarter             = 100,
      impactOnly              = true,
      impulseFactor           = 0,
      interceptedByShieldType = 1,
      laserFlareSize          = 3.25,
      minIntensity            = 1,
      pitchtolerance          = 8192,
      range                   = 400,
      reloadtime              = 0.8,
      rgbColor                = [[0 1 0]],
      soundStart              = [[weapon/laser/mini_laser]],
      soundStartVolume        = 3,
      thickness               = 2.165,
      tolerance               = 8192,
      turret                  = true,
      weaponType              = [[BeamLaser]],
    },
  },

}

return lowerkeys({ attackdrone = unitDef })
