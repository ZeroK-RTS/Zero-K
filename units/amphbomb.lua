unitDef = {
  unitname               = [[amphbomb]],
  name                   = [[Limpet]],
  description            = [[Amphibious Slow Mine]],
  acceleration           = 0.25,
  activateWhenBuilt      = true,
  brakeRate              = 0.4,
  buildCostMetal         = 300,
  buildPic               = [[AMPHBOMB.png]],
  canGuard               = true,
  canMove                = true,
  canPatrol              = true,
  category               = [[LAND TOOFAST]],
  cloakCost              = 0,
  collisionVolumeOffsets = [[0 0 0]],
  collisionVolumeScales  = [[22 20 22]],
  collisionVolumeType    = [[ellipsoid]],
  corpse                 = [[DEAD]],

  customParams           = {
    amph_regen = 10,
    amph_submerged_at = 30,
    helptext       = [[The Limpet can dodge most slow projectiles thanks to its agility and small size, allowing it to get close to enemy units in order to detonate, slowing and damaging them.]],
	--floattoggle    = [[1]],
 },

  explodeAs              = [[AMPHBOMB_DEATH]],
  fireState              = 0,
  footprintX             = 2,
  footprintZ             = 2,
  iconType               = [[walkerbomb]],
  idleAutoHeal           = 5,
  idleTime               = 1800,
  kamikaze               = true,
  kamikazeDistance       = 120,
  kamikazeUseLOS         = true,
  maxDamage              = 300,
  maxSlope               = 36,
  maxVelocity            = 4.1,
  minCloakDistance       = 75,
  movementClass          = [[AKBOT2]],
  noChaseCategory        = [[FIXEDWING LAND SINK TURRET SHIP SATELLITE SWIM GUNSHIP FLOAT SUB HOVER]],
  objectName             = [[amphbomb.s3o]],
  pushResistant          = 0,
  script                 = [[amphbomb.lua]],
  selfDestructAs         = [[AMPHBOMB_DEATH]],
  selfDestructCountdown  = 0,

  sfxtypes               = {

    explosiongenerators = {
      [[custom:RAIDMUZZLE]],
      [[custom:VINDIBACK]],
      [[custom:RIOTBALL]],
      [[custom:digdig]], --EmitSfx(piece, 1024+3)
    },

  },
  sightDistance          = 240,
  sonarDistance          = 240,
  turnRate               = 3000,
}

local weaponDefs = {
  AMPHBOMB_DEATH = {
    areaOfEffect       = 500,
    craterBoost        = 1,
    craterMult         = 3.5,
	customparams = {
	    timeslow_damagefactor = 10,
		light_color = [[1.88 0.63 2.5]],
		light_radius = 320,
	 },
	 
	damage = {
      default          = 150.1,
    },
	 
    edgeEffectiveness  = 0.4,
    explosionGenerator = "custom:riotballplus2_purple_UW",
    explosionSpeed     = 7,
    impulseBoost       = 0,
    impulseFactor      = 0.3,
    name               = "Slowing Explosion",
    soundHit           = "weapon/aoe_aura",
	soundHitVolume     = 0.6,
  },
}
unitDef.weaponDefs = weaponDefs

return lowerkeys({ amphbomb = unitDef })
