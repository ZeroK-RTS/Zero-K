return { strideremp = {
  name                   = [[Ungoliant]],
  description            = [[Deployable EMP Strider]],
  acceleration           = 0.166,
  brakeRate              = 0.825,
  buildPic               = [[strideremp.png]],
  canGuard               = true,
  canMove                = true,
  canPatrol              = true,
  category               = [[LAND]],
  collisionVolumeOffsets = [[0 4 -14]],
  collisionVolumeScales  = [[54 34 84]],
  collisionVolumeType    = [[elipsoid]],
  selectionVolumeOffsets = [[0 0 -10]],
  selectionVolumeScales  = [[110 110 110]],
  selectionVolumeType    = [[Sphere]],
  corpse                 = [[DEAD]],

  customParams           = {
    modelradius        = [[45]],
    selection_rank     = 3,
    selection_scale    = 1.3,
    outline_x          = 150,
    outline_y          = 150,
    outline_yoff       = 20,

    -- deploy cycle, read by scripts/strideremp.lua and LuaUI/Widgets/gui_strideremp_charge.lua
    emp_charge_time    = 6,    -- seconds of charging once fully deployed (slow stretches it, stun pauses it)
    emp_cooldown       = 30,   -- seconds after folding back up before it can deploy again
    specialreloadtime     = 900,  -- show the "ability" bar (charge, then cooldown) on the health bar,
    specialreload_userate = 1,    -- driven by the script's specialReloadRemaining
  },

  explodeAs              = [[CRAWL_BLASTSML]],
  fireState              = 0,
  footprintX             = 4,
  footprintZ             = 4,
  health                 = 8000,
  iconType               = [[t3spidergeneric]],
  leaveTracks            = true,
  maxSlope               = 36,
  maxWaterDepth          = 22,
  metalCost              = 3000,
  movementClass          = [[TKBOT4]],
  noChaseCategory        = [[TERRAFORM FIXEDWING SATELLITE SUB]],
  objectName             = [[strideremp.dae]],
  script                 = [[strideremp.lua]],
  selfDestructAs         = [[CRAWL_BLASTSML]],

  sfxtypes               = {
    explosiongenerators = {
      [[custom:strideremp_spark]],
      [[custom:strideremp_charge]],
      [[custom:strideremp_footstep]],
      [[custom:strideremp_blast_ground]],
    },
  },

  sightDistance          = 600,
  speed                  = 38,
  trackOffset            = 0,
  trackStrength          = 8,
  trackStretch           = 1,
  trackType              = [[ChickenTrackPointy]],
  trackWidth             = 80,
  turnRate               = 600,

  weapons                = {

    -- Never actually fires: aiming it at a target commits the unit to deploying.
    {
      def                = [[TRIGGER]],
      badTargetCategory  = [[FIXEDWING]],
      onlyTargetCategory = [[LAND SINK TURRET SHIP SWIM FLOAT HOVER GUNSHIP FIXEDWING]],
    },

    -- Detonated from the script with EmitSfx(emit_core, DETO_W2).
    {
      def                = [[EMP_BLAST]],
      onlyTargetCategory = [[NONE]],
    },

  },

  weaponDefs             = {

    TRIGGER = {
      name                    = [[EMP Pulse]],
      areaOfEffect            = 8,
      collideFriendly         = false,
      craterBoost             = 0,
      craterMult              = 0,

      customParams            = {
        stats_hide_dps    = 1,
        stats_hide_reload = 1,
      },

      damage                  = {
        default = 1E-06,
      },

      explosionGenerator      = [[custom:NONE]],
      fireStarter             = 0,
      impactOnly              = true,
      interceptedByShieldType = 1,
      range                   = 300,
      reloadtime              = 1,
      size                    = 1E-06,
      turret                  = true,
      weaponType              = [[Cannon]],
      weaponVelocity          = 400,
    },

    EMP_BLAST = {
      name                    = [[EMP Pulse]],
      areaOfEffect            = 1280,
      craterBoost             = 0,
      craterMult              = 0,

      customParams            = {
        stats_hide_dps    = 1,
        stats_hide_reload = 1,
      },

      damage                  = {
        -- stuns anything up to ~24000 max health (itself included, 8000); a healthy
        -- Paladin (32000) or Detriment (76000) shrugs off a single pulse
        default = 24000,
      },

      edgeEffectiveness       = 0.75,
      explosionGenerator      = [[custom:strideremp_blast]],
      explosionSpeed          = 12,
      impulseBoost            = 0,
      impulseFactor           = 0,
      noSelfDamage            = false,
      paralyzer               = true,
      paralyzeTime            = 20,
      range                   = 10,
      reloadtime              = 1,
      soundHit                = [[weapon/missile/emp_missile_hit]],
      weaponType              = [[Cannon]],
      weaponVelocity          = 400,
    },

  },

  featureDefs            = {

    DEAD  = {
      blocking         = true,
      featureDead      = [[HEAP]],
      footprintX       = 4,
      footprintZ       = 4,
      object           = [[strideremp_dead.dae]],
    },

    HEAP  = {
      blocking         = false,
      footprintX       = 4,
      footprintZ       = 4,
      object           = [[debris4x4a.s3o]],
    },

  },

} }
