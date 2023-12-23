return { statictempshield = {
  name                   = [[Pavise]],
  description            = [[Temporary Shield]],
  activateWhenBuilt      = true,
  buildDistance          = 200,
  builder                = true,
  buildPic               = [[statictempshield.png]],
  canGuard               = true,
  canMove                = false,
  canPatrol              = true,
  cantBeTransported      = true,
  category               = [[FLOAT MINE STUPIDTARGET]],
  cloakCost              = 0,
  collisionVolumeOffsets = [[0 0 0]],
  collisionVolumeScales  = [[20 20 20]],
  collisionVolumeType    = [[ellipsoid]],

  customParams           = {
    bait_level_default = 0,
    bait_level_target  = 1, -- Just for safety.
    dontcount = [[1]],
    mobilebuilding = [[1]],
    has_parent_unit = 1,
    like_structure   = 1,
    very_low_priority_target = 1,

    shield_draw_style = [[noisy]],
    shield_color_mult = 0.6,
  },

  explodeAs              = [[NOWEAPON]],
  footprintX             = 1,
  footprintZ             = 1,
  health                 = 500,
  levelGround            = false,
  iconType               = [[tempshield]],
  idleAutoHeal           = 10,
  idleTime               = 300,
  maxSlope               = 255,
  metalCost              = 10,
  minCloakDistance       = 80,
  noAutoFire             = false,
  noChaseCategory        = [[FIXEDWING LAND SINK TURRET SHIP SATELLITE SWIM GUNSHIP FLOAT SUB HOVER]],
  objectName             = [[m-8_deploy.s3o]],
  onoffable              = false,
  reclaimable            = false,
  repairable             = false, -- mostly not to waste constructor attention on area-repair; has regen anyway
  script                 = [[statictempshield.lua]],
  selfDestructAs         = [[NOWEAPON]],
  selfDestructCountdown  = 0,
  showNanoSpray          = false,
  sightDistance          = 240,
  waterline              = 1,
  workerTime             = 10,

  weapons                = {

    {
      def = [[SHIELD]],
    },

  },


  weaponDefs             = {

    SHIELD      = {
      name                    = [[Energy Shield]],

      customParams            = {
        unlinked                  = true,
        shield_die_on_zero_charge = 1,
        die_on_empty              = 1,
        shield_rate_charge        = -30,
      },

      damage                  = {
        default = 10,
      },

      exteriorShield          = true,
      shieldAlpha             = 0.2,
      shieldBadColor          = [[1 0.1 0.1 1]],
      shieldGoodColor         = [[0.1 0.1 1 1]],
      shieldInterceptType     = 3,
      shieldPower             = 3400,
      shieldPowerRegen        = 200,
      shieldPowerRegenEnergy  = 0,
      shieldRadius            = 200,
      shieldRepulser          = false,
      shieldStartingPower     = 3400,
      smartShield             = true,
      visibleShield           = false,
      visibleShieldRepulse    = false,
      weaponType              = [[Shield]],
    },

  },

} }
