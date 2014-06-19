unitDef = {
  unitname               = [[amphbomb]],
  name                   = [[Limpet]],
  description            = [[Amphibious slow mine]],
  acceleration           = 0.25,
  activateWhenBuilt      = true,
  brakeRate              = 0.4,
  buildCostEnergy        = 100,
  buildCostMetal         = 60,
  builder                = false,
  buildPic               = [[AMPHBOMB.png]],
  buildTime              = 60,
  canAttack              = true,
  canGuard               = true,
  canMove                = true,
  canPatrol              = true,
  canstop                = [[1]],
  category               = [[LAND]],
  cloakCost              = 0,
  collisionVolumeOffsets = [[0 0 0]],
  collisionVolumeScales  = [[22 20 22]],
  collisionVolumeTest    = 1,
  collisionVolumeType    = [[ellipsoid]],

  customParams           = {
    description_pl = [[Amfibijna bomba spowalniajaca]],
    helptext       = [[The Limpet can dodge most slow projectiles thanks to its agility and small size, allowing it to get close to enemy units in order to detonate, slowing and damaging them.]],
    helptext_pl    = [[Dzieki malym rozmiarom i szybkosci Limpet moze unikac wolniejszych pociskow, co pozwala mu podejsc pod jednostki przeciwnika i zdetonowac sie, zadajac obrazenia i spowalniajac.]],
 },

  explodeAs              = [[AMPHBOMB_DEATH]],
  fireState              = 0,
  footprintX             = 2,
  footprintZ             = 2,
  iconType               = [[walkerbomb]],
  idleAutoHeal           = 5,
  idleTime               = 1800,
  mass                   = 100,
  maxDamage              = 150,
  maxSlope               = 36,
  maxVelocity            = 3.7,
  maxWaterDepth          = 15,
  minCloakDistance       = 75,
  movementClass          = [[AKBOT2]],
  noAutoFire             = false,
  noChaseCategory        = [[FIXEDWING LAND SINK TURRET SHIP SATELLITE SWIM GUNSHIP FLOAT SUB HOVER]],
  objectName             = [[amphbomb.s3o]],
  pushResistant          = 0,
  script                 = [[amphbomb.lua]],
  seismicSignature       = 4,
  selfDestructAs         = [[AMPHBOMB_DEATH]],
  selfDestructCountdown  = 1,

  sfxtypes               = {

    explosiongenerators = {
      [[custom:digdig]],
    },

  },

  side                   = [[CORE]],
  sightDistance          = 240,
  smoothAnim             = true,
  turnRate               = 3000,
  workerTime             = 0,

}

--------------------------------------------------------------------------------

local weaponDefs = {
  AMPHBOMB_DEATH = {
    areaOfEffect       = 550,
    craterBoost        = 1,
    craterMult         = 3.5,
    edgeEffectiveness  = 0.4,
    explosionGenerator      = [[custom:RIOTBALL]],
    explosionSpeed          = 11,
    impulseBoost       = 0,
    impulseFactor      = 0.3,
    name               = "Explosion",
    damage = {
      default          = 80,
    },
    customParams           = {
	  lups_explodespeed = 1,
	  lups_explodelife = 0.6,
--	  nofriendlyfire = 1,
	  timeslow_damagefactor = [[10]],
    },
  },
}
unitDef.weaponDefs = weaponDefs

--------------------------------------------------------------------------------

return lowerkeys({ amphbomb = unitDef })
