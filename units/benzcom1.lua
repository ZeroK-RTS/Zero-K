unitDef = {
  unitname            = [[benzcom1]],
  name                = [[Siege Commander]],
  description         = [[Standoff Combat Commander, Builds at 10 m/s]],
  acceleration        = 0.18,
  activateWhenBuilt   = true,
  amphibious          = [[1]],
  autoHeal            = 5,
  brakeRate           = 0.375,
  buildCostEnergy     = 1200,
  buildCostMetal      = 1200,
  buildDistance       = 128,
  builder             = true,

  buildoptions        = {
  },

  buildPic            = [[benzcom.png]],
  buildTime           = 1200,
  canAttack           = true,
  canCloak            = false,
  canGuard            = true,
  canMove             = true,
  canPatrol           = true,
  category            = [[LAND]],
  collisionVolumeOffsets = [[0 0 0]],
  collisionVolumeScales  = [[45 54 45]],
  collisionVolumeType    = [[CylY]],  
  corpse              = [[DEAD]],

  customParams        = {
	--description_de = [[Schwerer Kampfkommandant, Baut mit 10 M/s]],
	helptext       = [[The Siege Commander is optimized for pummeling the enemy from a distance. Its low speed and armor leave it vulnerable in a knife fight.]],
	--helptext_de    = [[Der Battle Commander verbindet Feuerkraft mit starker Panzerung, auf Kosten der Geschwindigkeit und seiner Unterstützungsausrüstung. Seine Standardwaffe ist eine randalierende Kanone, während seine Spezialwaffen Streubomben in einer Linie abfeuern.]],
	level = [[1]],
	statsname = [[benzcom1]],
	soundok = [[heavy_bot_move]],
	soundselect = [[bot_select]],
	soundbuild = [[builder_start]],
	commtype = [[5]],
  },

  energyMake          = 6,
  energyStorage       = 0,
  energyUse           = 0,
  explodeAs           = [[ESTOR_BUILDINGEX]],
  footprintX          = 2,
  footprintZ          = 2,
  hideDamage          = false,
  iconType            = [[commander1]],
  idleAutoHeal        = 5,
  idleTime            = 1800,
  leaveTracks         = true,
  losEmitHeight       = 40,
  maxDamage           = 2250,
  maxSlope            = 36,
  maxVelocity         = 1.25,
  maxWaterDepth       = 5000,
  metalMake           = 4,
  metalStorage        = 0,
  minCloakDistance    = 75,
  movementClass       = [[AKBOT2]],
  noChaseCategory     = [[TERRAFORM SATELLITE FIXEDWING GUNSHIP HOVER SHIP SWIM SUB LAND FLOAT SINK]],
  objectName          = [[benzcom1.s3o]],
  script              = [[benzcom.lua]],
  seismicSignature    = 16,
  selfDestructAs      = [[ESTOR_BUILDINGEX]],

  sfxtypes            = {

    explosiongenerators = {
      [[custom:RAIDMUZZLE]],
      [[custom:LEVLRMUZZLE]],
      [[custom:RAIDMUZZLE]],
    },

  },

  showNanoSpray       = false,
  showPlayerName      = true,
  sightDistance       = 500,
  sonarDistance       = 300,
  trackOffset         = 0,
  trackStrength       = 8,
  trackStretch        = 1,
  trackType           = [[ComTrack]],
  trackWidth          = 22,
  terraformSpeed      = 600,
  turnRate            = 1148,
  upright             = true,
  workerTime          = 10,

  weapons             = {
    [1] = {
      def                = [[FAKELASER]],
      badTargetCategory  = [[FIXEDWING]],
      onlyTargetCategory = [[FIXEDWING LAND SINK TURRET SHIP SWIM FLOAT GUNSHIP HOVER]],
    },

    [5] = {
      def                = [[ASSAULT_CANNON]],
      badTargetCategory  = [[FIXEDWING]],
      onlyTargetCategory = [[FIXEDWING LAND SINK TURRET SHIP SWIM FLOAT GUNSHIP HOVER]],
    },	
  },


  weaponDefs          = {

    FAKELASER    = {
      name                    = [[Fake Laser]],
      areaOfEffect            = 12,
      beamTime                = 0.1,
      coreThickness           = 0.5,
      craterBoost             = 0,
      craterMult              = 0,

      damage                  = {
        default = 0,
        subs    = 0,
      },

      edgeEffectiveness       = 0.99,
      explosionGenerator      = [[custom:flash1green]],
      fireStarter             = 70,
      impactOnly              = true,
      impulseBoost            = 0,
      impulseFactor           = 0.4,
      interceptedByShieldType = 1,
      laserFlareSize          = 5.53,
      minIntensity            = 1,
      range                   = 360,
      reloadtime              = 0.11,
      rgbColor                = [[0 1 0]],
      soundStart              = [[weapon/laser/pulse_laser3]],
      soundTrigger            = true,
      texture1                = [[largelaser]],
      texture2                = [[flare]],
      texture3                = [[flare]],
      texture4                = [[smallflare]],
      thickness               = 5.53,
      tolerance               = 10000,
      turret                  = true,
      weaponType              = [[BeamLaser]],
    },


    ASSAULT_CANNON = {
      name                    = [[Assault Cannon]],
      areaOfEffect            = 32,
      craterBoost             = 1,
      craterMult              = 3,
	
      damage                  = {
		default = 360,
		planes  = 360,
		subs    = 18,
      },
      
      explosionGenerator      = [[custom:INGEBORG]],
      impulseBoost            = 0,
      impulseFactor           = 0.4,
      interceptedByShieldType = 1,
      myGravity		      = 0.25,
      range                   = 360,
      reloadtime              = 2,
      soundHit                = [[weapon/cannon/cannon_hit2]],
      soundStart              = [[weapon/cannon/medplasma_fire]],
      turret                  = true,
      weaponType              = [[Cannon]],
      weaponVelocity          = 300,
    },

  },


  featureDefs         = {

    DEAD      = {
      blocking         = true,
      featureDead      = [[HEAP]],
      footprintX       = 2,
      footprintZ       = 2,
      object           = [[benzcom1_wreck.s3o]],
    },


    HEAP      = {
      blocking         = false,
      footprintX       = 2,
      footprintZ       = 2,
      object           = [[debris2x2c.s3o]],
    },

  },

}

return lowerkeys({ benzcom1 = unitDef })

