unitDef = {
  unitname               = [[a_shipcruiser_slowform]],
  name                   = [[Cavalier (Disruptor)]],
  description            = [[Morphable Cruiser (Artillery)]],
  acceleration           = 0.0417,
  activateWhenBuilt      = true,
  brakeRate              = 0.142,
  buildCostEnergy        = 850,
  buildCostMetal         = 850,
  builder                = false,
  buildPic               = [[armroy_slow.png]],
  buildTime              = 850,
  canAttack              = true,
  canMove                = true,
  category               = [[SHIP]],
  collisionVolumeOffsets = [[0 1 3]],
  collisionVolumeScales  = [[32 32 132]],
  collisionVolumeTest    = 1,
  collisionVolumeType    = [[cylZ]],
  corpse                 = [[DEAD]],

  customParams           = {
    helptext       = [[This morphed Cruiser packs a long-range disruptor bomb, useful for harassing and slowing enemies from range. Beware of aircraft, submarines and raider ships.]],

    extradrawrange = 200,
    modelradius    = [[17]],
    turnatfullspeed = [[1]],
	
	morphto = [[a_shipcruiser_fireform]],
    morphtime = [[10]],
  },

  explodeAs              = [[BIG_UNITEX]],
  floater                = true,
  footprintX             = 4,
  footprintZ             = 4,
  iconType               = [[a_shipcruiser]],
  idleAutoHeal           = 5,
  idleTime               = 1800,
  losEmitHeight          = 25,
  maxDamage              = 3000,
  maxVelocity            = 1.7,
  minCloakDistance       = 75,
  minWaterDepth          = 10,
  movementClass          = [[BOAT4]],
  noChaseCategory        = [[TERRAFORM FIXEDWING GUNSHIP TOOFAST]],
  objectName             = [[armroy.s3o]],
  script                 = [[a_shipcruiser.cob]],
  seismicSignature       = 4,
  selfDestructAs         = [[BIG_UNITEX]],
  sightDistance          = 660,
  sonarDistance          = 660,
  turninplace            = 0,
  turnRate               = 350,
  waterline              = 0,

  weapons                = {

    {
      def                = [[DISBOMB]],
      badTargetCategory  = [[GUNSHIP]],
      onlyTargetCategory = [[SWIM LAND SHIP SINK TURRET FLOAT GUNSHIP HOVER]],
    },

  },

  weaponDefs             = {

    DISBOMB = {
	name                    = [[Disruptor Bomb]],
	accuracy                = 400,
	areaOfEffect            = 256,
	avoidFeature            = false,
	cegTag                  = [[beamweapon_muzzle_purple]],
	craterBoost             = 0,
	craterMult              = 0,

	customParams            = {
		timeslow_damagefactor = [[4]],
		muzzleEffectFire = [[custom:RAIDMUZZLE]],
		
		light_camera_height = 2500,
		light_color = [[1.5 0.75 1.8]],
		light_radius = 280,
	},

	damage                  = {
		default = 150,
		planes  = 150,
		subs    = 7.5,
	},

	explosionGenerator      = [[custom:riotballplus_purple]],
	explosionSpeed          = 5,
	fireStarter             = 100,
	impulseBoost            = 0,
	impulseFactor           = 0,
	interceptedByShieldType = 2,
	model                   = [[wep_b_fabby.s3o]],
	myGravity               = 0.1,
    noSelfDamage            = false,
	range                   = 1100,
	reloadtime              = 6,
	smokeTrail              = true,
	soundHit                = [[weapon/aoe_aura]],
	soundHitVolume          = 8,
	soundStart              = [[weapon/cannon/cannon_fire3]],
	--startVelocity           = 350,
	--trajectoryHeight        = 0.3,
	turret                  = true,
	weaponType              = [[Cannon]],
	weaponVelocity          = 340,
}

  },

  featureDefs            = {

    DEAD  = {
      blocking         = false,
      featureDead      = [[HEAP]],
      footprintX       = 4,
      footprintZ       = 4,
      object           = [[armroy_dead.s3o]],
    },

    HEAP  = {
      blocking         = false,
      footprintX       = 4,
      footprintZ       = 4,
      object           = [[debris4x4b.s3o]],
    },

  },

}

return lowerkeys({ a_shipcruiser_slowform = unitDef })
