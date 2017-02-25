unitDef = {
  unitname            = [[corawac]],
  name                = [[Vulture]],
  description         = [[Area Jammer, Radar/Sonar Plane]],
  brakerate           = 0.4,
  buildCostEnergy     = 340,
  buildCostMetal      = 340,
  builder             = false,
  buildPic            = [[CORAWAC.png]],
  buildTime           = 340,
  canAttack           = false,
  canFly              = true,
  canGuard            = true,
  canMove             = true,
  canPatrol           = true,
  canSubmerge         = false,
  category            = [[UNARMED FIXEDWING]],
  collide             = false,
  collisionVolumeOffsets = [[0 0 0]],
  collisionVolumeScales  = [[35 12 60]],
  collisionVolumeType    = [[box]],
  corpse              = [[DEAD]],
  cruiseAlt           = 250,

  customParams        = {
    description_fr = [[Avion Sonar/Radar Furtif]],
	description_de = [[Tarnkappen Radar/Sonar Flugzeug]],
    helptext       = [[The Vulture provides an unparalleled means for deep scouting, and can locate underwater targets with its sonar. It is also equipped with an area jammer, which prevents radar from working in the area underneath.]],
    helptext_fr    = [[Summum de la technologie d'information, ses multiples capteurs vous renseigneront sur toutes les activit?s ennemies: terrestre aerienne ou sousmarine.]],
	helptext_de    = [[Der Vulture bietet dir die beispiellose Möglichkeit zur unerkannten, weitläufigen Aufklärung und kann mit seinem Sonar auch Unterwasserziele lokalisieren. Er hat auch ein Stoersender der gegen feindliche Radare wirkt.]],
	modelradius    = [[20]],
	specialreloadtime = [[600]],
	refuelturnradius = [[120]],
	priority_misc = 2, -- High
  },

  energyUse           = 1.5,
  explodeAs           = [[GUNSHIPEX]],
  floater             = true,
  footprintX          = 3,
  footprintZ          = 3,
  iconType            = [[radarplane]],
  idleAutoHeal        = 5,
  idleTime            = 1800,
  maxAcc              = 0.5,
  maxDamage           = 950,
  maxAileron          = 0.018,
  maxElevator         = 0.02,
  maxRudder           = 0.008,
  maxVelocity         = 12,
  minCloakDistance    = 75,
  noAutoFire          = false,
  noChaseCategory     = [[TERRAFORM SATELLITE FIXEDWING GUNSHIP HOVER SHIP SWIM SUB LAND FLOAT SINK TURRET]],
  objectName          = [[armpnix.s3o]],
  radarDistance       = 2400,
  radarDistanceJam    = 700,
  script              = [[corawac.lua]],
  seismicSignature    = 0,
  selfDestructAs      = [[GUNSHIPEX]],
  sightDistance       = 1400,
  sonarDistance       = 700,
  turnRadius          = 60,
  workerTime          = 0,

  featureDefs         = {

    DEAD = {
      blocking         = true,
      featureDead      = [[HEAP]],
      footprintX       = 2,
      footprintZ       = 2,
      object           = [[armpnix_dead.s3o]],
    },


    HEAP = {
      blocking         = false,
      footprintX       = 2,
      footprintZ       = 2,
      object           = [[debris2x2b.s3o]],
    },

  },

}

return lowerkeys({ corawac = unitDef })
