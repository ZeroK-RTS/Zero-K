unitDef = {
  unitname         = [[factoryhover]],
  name             = [[Hovercraft Platform]],
  description      = [[Produces Hovercraft, Builds at 10 m/s]],
  acceleration     = 0,
  brakeRate        = 0,
  buildCostEnergy  = 600,
  buildCostMetal   = 600,
  builder          = true,

  buildoptions     = {
    [[corch]],
    [[corsh]],
    [[nsaclash]],
    [[hoverassault]],
	[[hoverdepthcharge]],
	[[hoverriot]],
    [[armmanni]],
    [[hoveraa]],
  },

  buildPic         = [[factoryhover.png]],
  buildTime        = 600,
  canAttack        = true,
  canMove          = true,
  canPatrol        = true,
  canstop          = [[1]],
  category         = [[UNARMED FLOAT]],
  corpse           = [[DEAD]],

  customParams     = {
    description_de = [[Produziert Aerogleiter, Baut mit 10 M/s]],
    helptext       = [[The Hovercraft Platform is fast and deadly, offering the ability to cross sea and plains alike and outmaneuver the enemy. Key units: Dagger, Halberd, Scalpel, Mace, Penetrator]],
	helptext_de    = [[Die Hovercraft Platform ist schnell und tödlich und eröffnet dir die Möglichkeit Wasser und Boden gleichzeitig zu überqueren und somit deinen Gegner geschickt zu überlisten. Wichtigste Einheiten: Dagger, Halberd, Scalpel, Mace, Penetrator]],
    sortName = [[8]],
	aimposoffset   = [[0 0 0]],
	midposoffset   = [[0 -25 0]],
	modelradius    = [[60]],
  },

  energyMake       = 0.3,
  energyUse        = 0,
  explodeAs        = [[LARGE_BUILDINGEX]],
  footprintX       = 8,
  footprintZ       = 8,
  iconType         = [[fachover]],
  idleAutoHeal     = 5,
  idleTime         = 1800,
  levelGround      = false,
  maxDamage        = 4000,
  maxSlope         = 15,
  maxVelocity      = 0,
  metalMake        = 0.3,
  minCloakDistance = 150,
  moveState        = 1,
  noAutoFire       = false,
  objectName       = [[ARMFHP.s3o]],
  seismicSignature = 4,
  selfDestructAs   = [[LARGE_BUILDINGEX]],
  showNanoSpray    = false,
  sightDistance    = 273,
  turnRate         = 0,
  waterline        = 1,
  workerTime       = 10,
  yardMap          = [[xoooooox ooccccoo ooccccoo ooccccoo ooccccoo ooccccoo ooccccoo xoccccox]],

  featureDefs      = {

    DEAD  = {
      blocking         = false,
      featureDead      = [[HEAP]],
      footprintX       = 8,
      footprintZ       = 7,
      object           = [[ARMFHP_DEAD.s3o]],
    },


    HEAP  = {
      blocking         = false,
      footprintX       = 8,
      footprintZ       = 7,
      object           = [[debris4x4c.s3o]],
    },

  },

}

return lowerkeys({ factoryhover = unitDef })
