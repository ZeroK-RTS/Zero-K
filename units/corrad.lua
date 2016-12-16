unitDef = {
  unitname                      = [[corrad]],
  name                          = [[Radar Tower]],
  description                   = [[Early Warning System]],
  acceleration                  = 0,
  activateWhenBuilt             = true,
  brakeRate                     = 0,
  buildCostEnergy               = 55,
  buildCostMetal                = 55,
  builder                       = false,
  buildingGroundDecalDecaySpeed = 30,
  buildingGroundDecalSizeX      = 4,
  buildingGroundDecalSizeY      = 4,
  buildingGroundDecalType       = [[corrad_aoplane.dds]],
  buildPic                      = [[corrad.png]],
  buildTime                     = 55,
  canAttack                     = false,
  category                      = [[FLOAT UNARMED]],
  collisionVolumeOffsets        = [[0 -32 0]],
  collisionVolumeScales         = [[32 90 32]],
  collisionVolumeType           = [[CylY]],
  corpse                        = [[DEAD]],
  
  customParams = {
    description_fr = [[]],
    description_de = [[Frühwarnsystem]],
    helptext       = [[The Radar tower provides early warning of enemy units and their movements over a moderate distance at virtually no cost. It has a very small but steady energy cost and will automatically shut down if you run out of energy. Radar coverage is blocked by terrain such as mountains.]],
    helptext_fr    = [[]],
    helptext_de    = [[Dieser Radarturm ermöglicht die frühzeitige Lokalisierung von feindlichen Einheiten in der entsprechenden Reichweite. Für den Betrieb wird eine sehr kleine Menge Energie benötigt. Die Radarbedeckung wird durch Gelände - beispielsweise Berge - blockiert.]],
    modelradius    = [[16]],
	removewait     = 1,
	priority_misc  = 2, -- High
  },    
  
  energyUse                     = 0.8,
  explodeAs                     = [[SMALL_BUILDINGEX]],
  floater                       = true,
  footprintX                    = 2,
  footprintZ                    = 2,
  iconType                      = [[radar]],
  idleAutoHeal                  = 5,
  idleTime                      = 1800,
  isTargetingUpgrade            = false,
  levelGround                   = false,
  maxDamage                     = 80,
  maxSlope                      = 36,
  maxVelocity                   = 0,
  minCloakDistance              = 150,
  noAutoFire                    = false,
  objectName                    = [[ARADARLVL1.s3o]],
  script                        = [[corrad.lua]],
  onoffable                     = true,
  radarDistance                 = 2100,
  radarEmitHeight			    = 32,
  seismicSignature              = 4,
  selfDestructAs                = [[SMALL_BUILDINGEX]],
  sightDistance                 = 800,
  turnRate                      = 0,
  useBuildingGroundDecal        = true,
  workerTime                    = 0,
  yardMap                       = [[oooo]],
  
    sfxtypes               = {

    explosiongenerators = {
      [[custom:scanner_ping]]
    },

  },

  weapons                       = {
    --{
    --  def                = [[TARGETER]],
    --  onlyTargetCategory = [[NONE]],
    --},
    --{
    --  def                = [[SCANNERSWEEP]],
    --  onlyTargetCategory = [[NONE]],
    --},
  },


  weaponDefs                    = {

    TARGETER = {
      name                    = [[Scanning Lidar]],
      avoidFeature            = false,
      avoidNeutral            = false,
      beamTime                = 1/30,
      canattackground         = false,
      coreThickness           = 0.5,
      craterBoost             = 0,
      craterMult              = 0,

      damage                  = {
        default = -1E-06,
        planes  = -1E-06,
      },

      explosionGenerator      = [[custom:NONE]],
      impactOnly              = true,
      impulseBoost            = 0,
      impulseFactor           = 0,
      interceptedByShieldType = 1,
      largeBeamLaser          = false,
      laserFlareSize          = 1,
      minIntensity            = 1,
      range                   = 500,
      reloadtime              = 0.03,
      rgbColor                = [[0 0.7 0.6]],
      texture1                = [[largelaser]],
      texture2                = [[flare]],
      texture3                = [[flare]],
      texture4                = [[smallflare]],
      thickness               = 1,
      tolerance               = 10000,
      turret                  = true,
      waterWeapon             = true,
      weaponType              = [[BeamLaser]],
    },
    
    SCANNERSWEEP    = {
      name                    = [[Scanner Sweep]],
      areaOfEffect            = 1200,
      craterBoost             = 0,
      craterMult              = 0,

      damage                  = {
        default = -1E-06,
      },

      customParams           = {
	lups_noshockwave = "1",
	nofriendlyfire = "1",
      },

      edgeeffectiveness       = 1,
      explosionGenerator      = [[custom:none]],
      impulseBoost            = 0,
      impulseFactor           = 0,
      interceptedByShieldType = 1,
      noSelfDamage            = true,
      range                   = 600,
      reloadtime              = 1,
      soundHitVolume          = 1,
      turret                  = true,
      weaponType              = [[LaserCannon]],
      weaponVelocity          = 230,
    },    

  },


  featureDefs                   = {

    DEAD  = {
      blocking         = true,
      featureDead      = [[HEAP]],
      footprintX       = 2,
      footprintZ       = 2,
      object           = [[ARADARLVL1_dead.s3o]],
    },


    HEAP  = {
      blocking         = false,
      footprintX       = 2,
      footprintZ       = 2,
      object           = [[debris2x2c.s3o]],
    },

  },

}

return lowerkeys({ corrad = unitDef })
