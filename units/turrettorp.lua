unitDef = {
  unitname          = [[turrettorp]],
  name              = [[Urchin]],
  description       = [[Torpedo Launcher]],
  acceleration      = 0,
  activateWhenBuilt = true,
  brakeRate         = 0,

  buildCostMetal    = 120,
  builder           = false,
  buildPic          = [[CORTL.png]],
  canAttack         = true,
  canstop           = [[1]],
  category          = [[FLOAT]],
  collisionVolumeOffsets        = [[0 -5 0]],
  collisionVolumeScales         = [[42 50 42]],

  collisionVolumeType	        = [[CylY]],
  corpse            = [[DEAD]],

  customParams      = {
    description_fr = [[Lance Torpille]],
	description_de = [[Torpedowerfer]],
	-- commented out: mentions of exterior sonar (now torp has its own)
    helptext       = [[This Torpedo Launcher provides defense against both surface and submerged vessels.]], -- Remember to build sonar so that the Torpedo Launcher can hit submerged targets. 
    helptext_fr    = [[Ce lance torpille permet de torpiller les unites flottantes ou immergees.]], -- Construisez un sonar afin de d?tecter le plus t?t possible les cibles potentielles du Harpoon. 
	helptext_de    = [[Dieser Torpedowerfer dient zur Verteidigung gegen Schiffe und U-Boote..]], -- Achte darauf, dass du ein Sonar baust, damit der Torpedowerfer U-Boote lokalisieren kann. 
	aimposoffset   = [[0 15 0]],
	midposoffset   = [[0 15 0]],
  },

  explodeAs         = [[MEDIUM_BUILDINGEX]],
  footprintX        = 3,
  footprintZ        = 3,
  iconType          = [[defensetorp]],
  idleAutoHeal      = 5,
  idleTime          = 1800,

  maxDamage         = 1020,
  maxSlope          = 18,
  maxVelocity       = 0,
  minCloakDistance  = 150,
  noAutoFire        = false,
  noChaseCategory   = [[FIXEDWING LAND SHIP SATELLITE SWIM GUNSHIP SUB HOVER]],
  objectName        = [[torpedo launcher.s3o]],
  script            = [[turrettorp.lua]],
  selfDestructAs    = [[MEDIUM_BUILDINGEX]],

  sightDistance     = 610,
  sonarDistance     = 610,
  turnRate          = 0,
  waterline         = 1,
  workerTime        = 0,
  yardMap           = [[wwwwwwwww]],

  weapons           = {

    {
      def                = [[TORPEDO]],
      badTargetCategory  = [[FIXEDWING]],
      onlyTargetCategory = [[SWIM FIXEDWING LAND SUB SINK TURRET FLOAT SHIP GUNSHIP HOVER]],
    },

  },


  weaponDefs        = {

    TORPEDO = {
      name                    = [[Torpedo Launcher]],
      areaOfEffect            = 64,
      avoidFriendly           = false,
      bouncerebound           = 0.5,
      bounceslip              = 0.5,
      burnblow                = true,
      collideFriendly         = false,
      craterBoost             = 0,
      craterMult              = 0,

      damage                  = {
        default = 190,
      },

      explosionGenerator      = [[custom:TORPEDO_HIT]],
      groundbounce            = 1,
      edgeEffectiveness       = 0.6,
      impulseBoost            = 0,
      impulseFactor           = 0.2,
      interceptedByShieldType = 1,
      model                   = [[wep_t_longbolt.s3o]],
      numbounce               = 4,
      range                   = 550,
      reloadtime              = 3.2,
      soundHit                = [[explosion/wet/ex_underwater]],
      --soundStart              = [[weapon/torpedo]],
      startVelocity           = 150,
      tracks                  = true,
      turnRate                = 22000,
      turret                  = true,
      waterWeapon             = true,
      weaponAcceleration      = 22,
      weaponType              = [[TorpedoLauncher]],
      weaponVelocity          = 320,
    },

  },


  featureDefs       = {

    DEAD  = {
      featureDead      = [[HEAP]],
      footprintX       = 3,
      footprintZ       = 3,
      object           = [[torpedo launcher_dead.s3o]],
    },


    HEAP  = {
      footprintX       = 3,
      footprintZ       = 3,
      object           = [[debris3x3c.s3o]],
    },

  },

}

return lowerkeys({ turrettorp = unitDef })
