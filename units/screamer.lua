unitDef = {
  unitname                      = [[screamer]],
  name                          = [[Screamer]],
  description                   = [[Very Long-Range Anti-Air Missile Tower]],
  acceleration                  = 0,
  activateWhenBuilt             = true,
  brakeRate                     = 0,
  buildCostEnergy               = 2400,
  buildCostMetal                = 2400,
  builder                       = false,
  buildingGroundDecalDecaySpeed = 30,
  buildingGroundDecalSizeX      = 6,
  buildingGroundDecalSizeY      = 6,
  buildingGroundDecalType       = [[screamer_aoplane.dds]],
  buildPic                      = [[SCREAMER.png]],
  buildTime                     = 2400,
  canAttack                     = true,
  canstop                       = [[1]],
  category                      = [[SINK]],
  collisionVolumeOffsets        = [[0 0 0]],
  collisionVolumeScales         = [[74 74 74]],
  collisionVolumeType           = [[ellipsoid]],
  corpse                        = [[DEAD]],

  customParams                  = {
    description_fr = [[Tourelle Lance Missile Anti-Air Longue Portée]],
	description_de = [[Extrem weitreichender Flugabwehrraketenturm, 20s zum Bevorraten]],
    helptext       = [[The Screamer is an extremely long-ranging first strike anti-air weapon that sends a clear message to enemy aircraft - can't go here, sonny. Each shot must be stockpiled for 20 seconds, but is well worth the time, for a quick salvo of missiles will wipe out almost any air attack without fuss.]],
    helptext_fr    = [[Leest un lance missile trcs longue portée. Ses missiles r tete chercheuse ultra rapides peuvent abattre r peu prcs nimporte quel avion d'un seul tir. L'ultime défense Anti-Air, de tous points de vue, met necessite de programmer la production de missiles Sol/Air dans son interface avant d'etre apte r faire feu.]],
    helptext_de    = [[Der Screamer ist eine extrem weitreichende Flugabwehrwaffe, die eine klare Botschaft an die feindlichen Lufteinheiten sendet - hier kommst du nicht rein, Kleiner. Jeder Schuss muss 20 Sekunden bevorratet werden, doch das Warten lohnt sich, mit einer Raketensalve wird fast jeder Luftangriff zunichtegemacht.]],
	modelradius    = [[37]],
	freestockpile  = [[1]],
	stockpilecost  = [[0]],
	stockpiletime  = [[20]],
  },

  explodeAs                     = [[ESTOR_BUILDING]],
  footprintX                    = 4,
  footprintZ                    = 4,
  iconType                      = [[heavysam]],
  idleAutoHeal                  = 5,
  idleTime                      = 1800,
  maxDamage                     = 1570,
  maxSlope                      = 18,
  maxVelocity                   = 0,
  maxWaterDepth                 = 0,
  minCloakDistance              = 150,
  noAutoFire                    = false,
  objectName                    = [[SCREAMER.s3o]],
  onoffable                     = false,
  script						= [[screamer.lua]],
  seismicSignature              = 4,
  selfDestructAs                = [[ESTOR_BUILDING]],
  sightDistance                 = 660,
  turnRate                      = 0,
  useBuildingGroundDecal        = true,
  workerTime                    = 0,
  yardMap                       = [[oooooooooooooooo]],

  weapons                       = {

    {
      def                = [[ADVSAM]],
      onlyTargetCategory = [[FIXEDWING GUNSHIP SATELLITE]],
    },

  },


  weaponDefs                    = {

    ADVSAM = {
      name                    = [[Advanced Anti-Air Missile]],
      areaOfEffect            = 240,
      canAttackGround         = false,
      cegTag                  = [[screamertrail]],
      craterBoost             = 0.1,
      craterMult              = 0.2,
      cylinderTargeting       = 3.2,

	  customParams        	  = {
		isaa = [[1]],

		light_color = [[1.5 1.8 1.8]],
		light_radius = 600,
	  },

      damage                  = {
        default    = 160.15,
        planes     = 1601.5,
        subs       = 80,
      },

      edgeEffectiveness       = 0.25,
      energypershot           = 0,
      explosionGenerator      = [[custom:MISSILE_HIT_SPHERE_120]],
      fireStarter             = 90,
      flightTime              = 4,
      groundbounce            = 1,
      impulseBoost            = 0,
      impulseFactor           = 0,
      interceptedByShieldType = 1,
      metalpershot            = 0,
      model                   = [[wep_m_avalanche.s3o]],
      noSelfDamage            = true,
      range                   = 2400,
      reloadtime              = 1.8,
      smokeTrail              = false,
      soundHit                = [[weapon/missile/heavy_aa_hit]],
      soundStart              = [[weapon/missile/heavy_aa_fire2]],
      startVelocity           = 1000,
      stockpile               = true,
      stockpileTime           = 10000,
      tolerance               = 10000,
      tracks                  = true,
      trajectoryHeight        = 0.55,
      turnRate                = 60000,
      turret                  = true,
      weaponAcceleration      = 600,
      weaponType              = [[MissileLauncher]],
      weaponVelocity          = 1600,
    },

  },


  featureDefs                   = {

    DEAD  = {
      blocking         = true,
      featureDead      = [[HEAP]],
      footprintX       = 4,
      footprintZ       = 4,
      object           = [[screamer_dead.s3o]],
    },

    HEAP  = {
      blocking         = false,
      footprintX       = 4,
      footprintZ       = 4,
      object           = [[debris4x4a.s3o]],
    },

  },

}

return lowerkeys({ screamer = unitDef })
