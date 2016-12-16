unitDef = {
  unitname                      = [[armdeva]],
  name                          = [[Stardust]],
  description                   = [[Anti-Swarm Turret]],
  activateWhenBuilt             = true,
  buildCostEnergy               = 220,
  buildCostMetal                = 220,
  builder                       = false,
  buildingGroundDecalDecaySpeed = 30,
  buildingGroundDecalSizeX      = 5,
  buildingGroundDecalSizeY      = 5,
  buildingGroundDecalType       = [[armdeva_aoplane.dds]],
  buildPic                      = [[armdeva.png]],
  buildTime                     = 220,
  canAttack                     = true,
  category                      = [[FLOAT TURRET]],
  collisionVolumeOffsets        = [[0 0 0]],
  collisionVolumeScales         = [[45 45 45]],
  collisionVolumeType           = [[ellipsoid]],
  corpse                        = [[DEAD]],

  customParams                  = {
    description_de = [[Anti-Schwarm EMG]],
    description_fr = [[Mitrailleurs Anti-Nuée]],
    helptext       = [[The Stardust sports a powerful autocannon. While it has a short range and is thus even more vulnerable to skirmishers than the LLT, its high rate of fire and AoE allow it to quickly chew up swarms of lighter units.]],
    helptext_de    = [[Stardust ist ein Geschützturm mit einem lang perfektionierten und tödlichen energetischen Maschinengewehr. Zwar besitzt es nur eine kurze Reichweite, wodurch es sehr verletzbar gegenüber Skirmishern ist, dennoch machen es die hohe Feuerrate und die AoE zu einer guten Verteidigung gegen Schwärme und leichte Einheiten.]],
    helptext_fr    = [[Le Stardust est une tourelle mitrailleuse r haute energie. Son incroyable cadence de tir lui permettent d'arreter quasiment nimporte quelle nuée de Pilleur ou d'unités légcres, cependant sa portée est relativement limitée, et étant prcs du sol nimporte quel obstacle l'empeche de tirer.]],
    aimposoffset   = [[0 12 0]],
    midposoffset   = [[0 4 0]],
  },

  explodeAs                     = [[LARGE_BUILDINGEX]],
  floater                       = true,
  footprintX                    = 3,
  footprintZ                    = 3,
  iconType                      = [[defenseriot]],
  levelGround                   = false,
  maxDamage                     = 1500,
  maxSlope                      = 18,
  minCloakDistance              = 150,
  noChaseCategory               = [[FIXEDWING LAND SHIP SWIM GUNSHIP SUB HOVER]],
  objectName                    = [[afury.s3o]],
  script                        = "armdeva.lua",
  seismicSignature              = 4,
  selfDestructAs                = [[LARGE_BUILDINGEX]],

  sfxtypes                      = {

    explosiongenerators = {
      [[custom:WARMUZZLE]],
      [[custom:DEVA_SHELLS]],
    },

  },

  sightDistance                 = 451,
  useBuildingGroundDecal        = true,
  yardMap                       = [[ooo ooo ooo]],

  weapons                       = {

    {
      def                = [[ARMDEVA_WEAPON]],
      badTargetCategory  = [[FIXEDWING]],
      onlyTargetCategory = [[FIXEDWING LAND SINK TURRET SHIP SWIM FLOAT GUNSHIP HOVER]],
      mainDir            = [[0 1 0]],
      maxAngleDif        = 240,
    },

  },

  weaponDefs                    = {

    ARMDEVA_WEAPON = {
      name                    = [[Pulse Autocannon]],
      accuracy                = 2300,
      alphaDecay              = 0.7,
      areaOfEffect            = 96,
      avoidFeature            = false,
      burnblow                = true,
      craterBoost             = 0.15,
      craterMult              = 0.3,

	  customparams = {
		light_color = [[0.8 0.76 0.38]],
		light_radius = 180,
	  },

      damage                  = {
        default = 45,
        subs    = 2.25,
      },

      edgeEffectiveness       = 0.5,
      explosionGenerator      = [[custom:EMG_HIT_HE]],
      firestarter             = 70,
      impulseBoost            = 0,
      impulseFactor           = 0.4,
      intensity               = 0.7,
      interceptedByShieldType = 1,
      noSelfDamage            = true,
      range                   = 410,
      reloadtime              = 0.12,
      rgbColor                = [[1 0.95 0.4]],
      separation              = 1.5,
      soundHit                = [[weapon/cannon/emg_hit]],
      soundStart              = [[weapon/heavy_emg]],
      soundStartVolume        = 0.5,
      stages                  = 10,
      turret                  = true,
      weaponType              = [[Cannon]],
      weaponVelocity          = 550,
    },

  },

  featureDefs                   = {

    DEAD  = {
      blocking         = true,
      featureDead      = [[HEAP]],
      footprintX       = 3,
      footprintZ       = 3,
      object           = [[afury_dead.s3o]],
    },

	HEAP  = {
      blocking         = false,
      footprintX       = 3,
      footprintZ       = 3,
      object           = [[debris4x4b.s3o]],
    },

  },

}

return lowerkeys({ armdeva = unitDef })
