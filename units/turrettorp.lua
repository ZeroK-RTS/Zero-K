unitDef = {
  unitname          = [[turrettorp]],
  name              = [[Urchin]],
  description       = [[Torpedo Launcher]],
  acceleration      = 0,
  activateWhenBuilt = true,
  brakeRate         = 0,
  buildAngle        = 16384,
  buildCostEnergy   = 120,
  buildCostMetal    = 120,
  builder           = false,
  buildPic          = [[CORTL.png]],
  buildTime         = 120,
  canAttack         = true,
  canstop           = [[1]],
  category          = [[FLOAT]],
  collisionVolumeOffsets        = [[0 -5 0]],
  collisionVolumeScales         = [[42 50 42]],
  collisionVolumeTest	        = 1,
  collisionVolumeType	        = [[CylY]],
  corpse            = [[DEAD]],

  customParams      = {
    description_fr = [[Lance Torpille]],
	description_de = [[Torpedowerfer]],
	description_pl = [[Wyrzutnia torped]],
	-- commented out: mentions of exterior sonar (now torp has its own)
    helptext       = [[This Torpedo Launcher provides defense against both surface and submerged vessels.]], -- Remember to build sonar so that the Torpedo Launcher can hit submerged targets. 
    helptext_fr    = [[Ce lance torpille permet de torpiller les unit?s flottantes ou immerg?es. Attention, le Harpoon est inefficace contre les Hovercraft.]], -- Construisez un sonar afin de d?tecter le plus t?t possible les cibles potentielles du Harpoon. 
	helptext_de    = [[Dieser Torpedowerfer dient zur Verteidigung gegen Schiffe und U-Boote.]], -- Achte darauf, dass du ein Sonar baust, damit der Torpedowerfer U-Boote lokalisieren kann. 
	helptext_pl    = [[Torpedy sa w stanie trafic zarowno cele plywajace po powierzchni jak i pod woda.]], -- Pamietaj, ze do atakowania zanurzonych celow potrzebny jest sonar.
	aimposoffset   = [[0 15 0]],
	midposoffset   = [[0 15 0]],
  },

  explodeAs         = [[MEDIUM_BUILDINGEX]],
  footprintX        = 3,
  footprintZ        = 3,
  iconType          = [[defensetorp]],
  idleAutoHeal      = 5,
  idleTime          = 1800,
  mass              = 215,
  maxDamage         = 1000,
  maxSlope          = 18,
  maxVelocity       = 0,
  minCloakDistance  = 150,
  noAutoFire        = false,
  noChaseCategory   = [[FIXEDWING LAND SHIP SATELLITE SWIM GUNSHIP SUB HOVER]],
  objectName        = [[torpedo launcher.s3o]],
  script            = [[turrettorp.lua]],
  seismicSignature  = 4,
  selfDestructAs    = [[MEDIUM_BUILDINGEX]],
  side              = [[CORE]],
  sightDistance     = 660,
  sonarDistance     = 550,
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
      range                   = 590,
      reloadtime              = 3.2,
      soundHit                = [[explosion/wet/ex_underwater]],
      --soundStart              = [[weapon/torpedo]],
      startVelocity           = 150,
      tracks                  = true,
      turnRate                = 22000,
      turret                  = true,
      waterWeapon             = true,
      weaponAcceleration      = 22,
      weaponTimer             = 3,
      weaponType              = [[TorpedoLauncher]],
      weaponVelocity          = 320,
    },

  },


  featureDefs       = {

    DEAD  = {
      description      = [[Wreckage - Urchin]],
      blocking         = false,
      category         = [[corpses]],
      damage           = 1000,
      energy           = 0,
      featureDead      = [[HEAP]],
      footprintX       = 3,
      footprintZ       = 3,
      height           = [[4]],
      hitdensity       = [[100]],
      metal            = 48,
      object           = [[torpedo launcher_dead.s3o]],
      reclaimable      = true,
      reclaimTime      = 48,
      seqnamereclamate = [[TREE1RECLAMATE]],
      world            = [[All Worlds]],
    },


    HEAP  = {
      description      = [[Debris - Urchin]],
      blocking         = false,
      category         = [[heaps]],
      damage           = 1000,
      energy           = 0,
      featurereclamate = [[SMUDGE01]],
      footprintX       = 3,
      footprintZ       = 3,
      hitdensity       = [[100]],
      metal            = 24,
      object           = [[debris3x3c.s3o]],
      reclaimable      = true,
      reclaimTime      = 24,
      seqnamereclamate = [[TREE1RECLAMATE]],
      world            = [[All Worlds]],
    },

  },

}

return lowerkeys({ turrettorp = unitDef })
