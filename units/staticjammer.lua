return { staticjammer = {
  unitname                      = [[staticjammer]],
  name                          = [[Cornea]],
  description                   = [[Area Cloaker/Jammer]],
  activateWhenBuilt             = true,
  buildCostMetal                = 420,
  builder                       = false,
  buildingGroundDecalDecaySpeed = 30,
  buildingGroundDecalSizeX      = 4,
  buildingGroundDecalSizeY      = 4,
  buildingGroundDecalType       = [[staticjammer_aoplane.dds]],
  buildPic                      = [[staticjammer.png]],
  category                      = [[SINK UNARMED]],
  canMove                       = true, -- for queuing orders during morph to mobile
  canManualFire                 = true,
  canAttack                     = false,
  cloakCost                     = 1,
  collisionVolumeOffsets        = [[0 0 0]],
  collisionVolumeScales         = [[32 70 32]],
  collisionVolumeType           = [[CylY]],
  corpse                        = [[DEAD]],

  customParams                  = {

    morphto = [[cloakjammer]],
    morphtime = 30,

    area_cloak = 1,
    area_cloak_upkeep = 12,
    area_cloak_radius = 400,
    area_cloak_shift_range = 200,
    area_cloak_recloak_rate = 1200,
    removeattack = 1,

    priority_misc  = 1,
    addfight       = 1,
    addpatrol      = 1,

    outline_x = 90,
    outline_y = 130,
    outline_yoff = 20,
  },

  energyUse                     = 1.5,
  explodeAs                     = [[BIG_UNITEX]],
  floater                       = true,
  footprintX                    = 2,
  footprintZ                    = 2,
  iconType                      = [[staticjammer]],
  initCloaked                   = true,
  levelGround                   = false,
  maxDamage                     = 700,
  maxSlope                      = 36,
  minCloakDistance              = 100,
  noAutoFire                    = false,
  objectName                    = [[radarjammer.dae]],
  onoffable                     = true,
  radarDistanceJam              = 600,
  script                        = [[staticjammer.lua]],
  selfDestructAs                = [[BIG_UNITEX]],
  sightDistance                 = 250,
  useBuildingGroundDecal        = true,
  yardMap                       = [[oo oo]],

  weapons                = {

    {
      def                = [[BOGUS_CLOAK_TARGET]],
      onlyTargetCategory = [[SWIM LAND SUB SINK TURRET FLOAT SHIP HOVER GUNSHIP FIXEDWING]],
    },
    
  },

  weaponDefs             = {

    BOGUS_CLOAK_TARGET        = {
      name                    = [[Bogus Cloak Target]],
      areaOfEffect            = 800,
      collideFriendly         = false,
      commandfire             = true,

      customParams        = {
        gui_draw_range  = 200,
        gui_draw_leashed_to_range  = 1,
        attack_aoe_circle_mode = "cloaker"
      },
      
      damage                  = {
        default = 0,
      },

      edgeEffectiveness       = 1,
      range                   = 72000,
      reloadtime              = 4/30,
      turnrate                = 1000000000,
      turret                  = true,
      weaponAcceleration      = 20000,
      weaponTimer             = 0.5,
      weaponType              = [[StarburstLauncher]],
      weaponVelocity          = 20000,
    },

  },

  featureDefs                   = {

    DEAD  = {
      blocking         = true,
      featureDead      = [[HEAP]],
      footprintX       = 2,
      footprintZ       = 2,
      object           = [[radarjammer_dead.dae]],
    },

    HEAP  = {
      blocking         = false,
      footprintX       = 2,
      footprintZ       = 2,
      object           = [[debris2x2a.s3o]],
    },

  },

} }
