unitDef = {
  unitname            = [[chickens]],
  name                = [[Spiker]],
  description         = [[Skirmisher]],
  acceleration        = 0.36,
  brakeRate           = 0.205,
  buildCostEnergy     = 0,
  buildCostMetal      = 0,
  builder             = false,
  buildPic            = [[chickens.png]],
  buildTime           = 200,
  canAttack           = true,
  canGuard            = true,
  canHover            = false,
  canMove             = true,
  canPatrol           = true,
  canstop             = [[1]],
  category            = [[HOVER]],

  customParams        = {
    description_fr = [[Cracheur de piques]],
	description_de = [[Skirmisher]],
    helptext       = [[The Spiker's razor sharp projectiles can pierce even the thickest armor. While it doesn't have much health, it remains a potent threat to both air and ground units. Counter with anything that can reliably outrange it.]],
    helptext_fr    = [[Le Spiker envoie des projectiles affut?s comme des rasoirs qui peuvent traverser m?me les armures les plus solides. Bien que poss?dant peu de vie il reste une menace tr?s r?elle tant pour les unit?s terrestres que volantes. Pour le contrer il faut utiliser tout ce qui tire plus loin.]],
	helptext_de    = [[Spikers messerscharfe Projektile können auch die dickste Penzerung durchdringen. Zwar besitzen Spiker wenig Lebensenergie, dennoch stellen sie durchauch eine große Gefahr, für sowohl Boden- als auch Lufteinheiten, dar. Wirke den Spikern mit Einheiten entgegen, die eine größere Reichweite als sie besitzen.]],
  },

  explodeAs           = [[NOWEAPON]],
  footprintX          = 3,
  footprintZ          = 3,
  iconType            = [[chickens]],
  idleAutoHeal        = 20,
  idleTime            = 300,
  leaveTracks         = true,
  mass                = 147,
  maxDamage           = 600,
  maxSlope            = 36,
  maxVelocity         = 2,
  minCloakDistance    = 75,
  movementClass       = [[BHOVER3]],
  noAutoFire          = false,
  noChaseCategory     = [[TERRAFORM FIXEDWING SATELLITE SUB]],
  objectName          = [[chickens.s3o]],
  power               = 200,
  seismicSignature    = 4,
  selfDestructAs      = [[NOWEAPON]],

  sfxtypes            = {

    explosiongenerators = {
      [[custom:blood_spray]],
      [[custom:blood_explode]],
      [[custom:dirt]],
    },

  },

  side                = [[THUNDERBIRDS]],
  sightDistance       = 550,
  smoothAnim          = true,
  sonarDistance       = 500,
  trackOffset         = 6,
  trackStrength       = 8,
  trackStretch        = 1,
  trackType           = [[ChickenTrack]],
  trackWidth          = 30,
  turnRate            = 806,
  upright             = false,
  waterline           = 16,
  workerTime          = 0,

  weapons             = {

    {
      def                = [[WEAPON]],
      badTargetCategory  = [[FIXEDWING]],
      mainDir            = [[0 0 1]],
      maxAngleDif        = 120,
      onlyTargetCategory = [[FIXEDWING LAND SINK SUB SHIP SWIM FLOAT GUNSHIP HOVER]],
    },

  },


  weaponDefs          = {

    WEAPON = {
      name                    = [[Spike]],
      areaOfEffect            = 16,
      avoidFeature            = true,
      avoidFriendly           = true,
      burnblow                = true,
      cegTag                  = [[small_green_goo]],
      collideFeature          = true,
      collideFriendly         = true,
      craterBoost             = 0,
      craterMult              = 0,

      damage                  = {
        default = 180,
        planes  = 180,
        subs    = 180,
      },

      explosionGenerator      = [[custom:EMG_HIT]],
      impactOnly              = true,
      impulseBoost            = 0,
      impulseFactor           = 0.4,
      interceptedByShieldType = 2,
      model                   = [[spike.s3o]],
      propeller               = [[1]],
      range                   = 460,
      reloadtime              = 3,
      selfprop                = true,
      soundHit                = [[chickens/spike_hit]],
      soundStart              = [[chickens/spike_fire]],
      startVelocity           = 320,
      subMissile              = 1,
      turret                  = true,
      waterWeapon             = true,
      weaponAcceleration      = 100,
      weaponTimer             = 1,
      weaponType              = [[Cannon]],
      weaponVelocity          = 280,
    },

  },

}

return lowerkeys({ chickens = unitDef })
