return { staticmissilesilo = {
  name                          = [[Missile Silo]],
  description                   = [[Produces Tactical Missiles]],
  builder                       = true,
  buildingGroundDecalDecaySpeed = 30,
  buildingGroundDecalSizeX      = 6,
  buildingGroundDecalSizeY      = 6,
  buildingGroundDecalType       = [[staticmissilesilo_aoplane.dds]],

  buildoptions                  = {
    [[tacnuke]],
    [[seismic]],
    [[empmissile]],
    [[napalmmissile]],
    [[missileslow]],
  },

  buildPic                      = [[staticmissilesilo.png]],
  canFight                      = false,
  canMove                       = false,
  canPatrol                     = false,
  category                      = [[SINK UNARMED]],
  corpse                        = [[DEAD]],
  customparams = {
    solid_factory = [[6]],
    missile_silo_capacity = 4,
    overlay_icon_size = 2.73, -- overlay icon square spans past the launch pads, so the missiles' icons sit in its corners
    health_bar_height = -45, -- overlay anchor at missile height (model 120 tall vs missiles 30), so they line up
    stats_show_death_explosion = 1,
  },
  explodeAs                     = [[LARGE_BUILDINGEX]],
  fireState                     = 0,
  footprintX                    = 6,
  footprintZ                    = 6,
  health                        = 4000,
  iconType                      = [[missilesilo]],
  maxSlope                      = 15,
  maxWaterDepth                 = 0,
  metalCost                     = 1200,
  objectName                    = [[missilesilo.s3o]],
  script                        = [[staticmissilesilo.lua]],
  selfDestructAs                = [[LARGE_BUILDINGEX]],
  showNanoSpray                 = false,
  sightDistance                 = 273,
  useBuildingGroundDecal        = true,
  workerTime                    = 10,
  yardMap                       = [[oooooo occcco occcco occcco occcco oooooo]],

  featureDefs                   = {

    DEAD = {
      blocking         = true,
      featureDead      = [[HEAP]],
      footprintX       = 6,
      footprintZ       = 6,
      object           = [[missilesilo_dead.s3o]],
    },

    HEAP = {
      blocking         = false,
      footprintX       = 6,
      footprintZ       = 6,
      object           = [[debris4x4c.s3o]],
    },

  },

} }
