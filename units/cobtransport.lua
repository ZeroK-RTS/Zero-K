unitDef = {
  unitname            = [[cobtransport]],
  name                = [[Valkyrie]],
  description         = [[Air Transport]],
  acceleration        = 0.15,
  brakeRate           = 6,
  buildCostMetal      = 80,
  builder             = false,
  buildPic            = [[CORVALK.png]],
  canFly              = true,
  canGuard            = true,
  canload             = [[1]],
  canMove             = true,
  canPatrol           = true,
  canSubmerge         = false,
  category            = [[GUNSHIP UNARMED]],
  collide             = false,
  collisionVolumeOffsets = [[0 0 0]],
  collisionVolumeScales  = [[28 16 35]],
  collisionVolumeType    = [[box]],
  corpse              = [[DEAD]],
  cruiseAlt           = 80,

  customParams        = {
    airstrafecontrol = [[1]],
    description_fr = [[Transport Aerien]],
	description_de = [[Lufttransport]],
    helptext       = [[The Valkyrie is the basic air transport. It is ideal to ferry units to the front or make a drop deep behind enemy lines, but should not be used to land in areas with any kind of AA cover.]],
    helptext_fr    = [[Le Valkyrie est une unit? de transport a?rien basique. Elle peut ?tre utilis?e pour a?roporter des troups sur le front comme derri?re les lignes ennemies. Il faut cependant ?viter ? tout prix les endroits couvert par de l'Anti-Air: il n'y survivrait pas.]],
	helptext_de    = [[Der Valkyrie ist ein einfacher Lufttransport. Er wird benutzt, um Einheiten an die Front zu befördern oder gezielte Abwürfe in das feindliche Territorium zu durchzuführen, allerdings mit der Einschränkung, sich ausdrücklich von jeder Luftabwehr fernzuhalten.]],
	midposoffset   = [[0 0 0]],
	modelradius    = [[15]],
  },

  explodeAs           = [[GUNSHIPEX]],
  floater             = true,
  footprintX          = 3,
  footprintZ          = 3,
  hoverAttack         = true,
  iconType            = [[airtransport]],
  idleAutoHeal        = 5,
  idleTime            = 1800,
  maxDamage           = 300,
  maxVelocity         = 10.7,
  minCloakDistance    = 75,
  noAutoFire          = false,
  noChaseCategory     = [[TERRAFORM SATELLITE FIXEDWING GUNSHIP HOVER SHIP SWIM SUB LAND FLOAT SINK TURRET]],
  objectName          = [[CORVALK.s3o]],
  releaseHeld         = true,
  selfDestructAs      = [[GUNSHIPEX]],

  sfxtypes            = {

    explosiongenerators = {
      [[custom:ATLAS_ENGINE]],
    },

  },
  sightDistance       = 300,
  transportCapacity   = 1,
  transportSize       = 25,
  turninplace         = 0,
  turnRate            = 550,
  verticalSpeed       = 30,

  featureDefs         = {

    DEAD  = {
      blocking         = true,
      featureDead      = [[HEAP]],
      footprintX       = 2,
      footprintZ       = 2,
      object           = [[smalltrans_d.dae]],
    },


    HEAP  = {
      blocking         = false,
      footprintX       = 2,
      footprintZ       = 2,
      object           = [[debris2x2c.s3o]],
    },

  },

}

return lowerkeys({ cobtransport = unitDef })
