unitDef = {
  unitname            = [[chickenf]],
  name                = [[Talon]],
  description         = [[Flying Spike Spitter]],
  acceleration        = 0.8,
  airHoverFactor      = 0,
  brakeRate           = 0.32,
  buildCostEnergy     = 0,
  buildCostMetal      = 0,
  builder             = false,
  buildPic            = [[chickenf.png]],
  buildTime           = 450,
  canAttack           = true,
  canFly              = true,
  canGuard            = true,
  canLand             = true,
  canMove             = true,
  canPatrol           = true,
  canSubmerge         = false,
  category            = [[FIXEDWING]],
  collide             = false,
  cruiseAlt           = 150,

  customParams        = {
    description_fr = [[Lanceur de pikes volant]],
	description_de = [[Fliegender Dornenspucker]],
    helptext       = [[It's a flying chicken! The Talon is a lethal predator that takes down enemy aircraft with its spikes, but will also happily employ them on ground targets. It can be defeated like any other air unit, however.]],
    helptext_fr    = [[Un poulet volant ! Le talon est un pr?dateur mortel qui peut d?truire un avion adverse avec ses dards ainsi que les employer sur des cibles terrestres. Il reste dependant vuln?rable ? toute d?fense ? capacit? anti a?rienne.]],
	helptext_de    = [[Talon ist ein fliegenes Chicken! Er ist ein t�dliches Rauptier, das feindliche Lufteinheiten mit seinen dicken Bolzen vom Himmel holt, diese aber auch au�erordentlich gerne gegen Bodenziele richtet.]],
  },

  explodeAs           = [[NOWEAPON]],
  floater             = true,
  footprintX          = 1,
  footprintZ          = 1,
  iconType            = [[chickenf]],
  idleAutoHeal        = 20,
  idleTime            = 300,
  leaveTracks         = true,
  maxDamage           = 1200,
  maxSlope            = 18,
  maxVelocity         = 10,
  minCloakDistance    = 75,
  noAutoFire          = false,
  noChaseCategory     = [[TERRAFORM SATELLITE STUPIDTARGET MINE]],
  objectName          = [[chickenf.s3o]],
  power               = 450,
  selfDestructAs      = [[NOWEAPON]],

  sfxtypes            = {

    explosiongenerators = {
      [[custom:blood_spray]],
      [[custom:blood_explode]],
      [[custom:dirt]],
    },

  },
  sightDistance       = 512,
  turnRate            = 6000,
  workerTime          = 0,

  weapons             = {

    {
      def                = [[WEAPON]],
      badTargetCategory  = [[FIXEDWING]],
      mainDir            = [[0 0 1]],
      maxAngleDif        = 120,
      onlyTargetCategory = [[FIXEDWING LAND SINK TURRET SHIP SWIM SUB FLOAT GUNSHIP HOVER]],
    },

  },


  weaponDefs          = {

    WEAPON = {
      name                    = [[Spike]],
      areaOfEffect            = 16,
      avoidFriendly           = false,
      burnblow                = true,
      cegTag                  = [[small_green_goo]],
      collideFriendly         = false,
      craterBoost             = 0,
      craterMult              = 0,
      
      customParams            = {
        light_radius = 0,
      },
      
      damage                  = {
        default = 160,
      },

      explosionGenerator      = [[custom:EMG_HIT]],
      impactOnly              = true,
      impulseBoost            = 0,
      impulseFactor           = 0.4,
      interceptedByShieldType = 1,
      model                   = [[spike.s3o]],
      range                   = 400,
      reloadtime              = 1.5,
      soundHit                = [[chickens/spike_hit]],
      soundStart              = [[chickens/chickenflyerbig1]],
      startVelocity           = 400,
      subMissile              = 1,
      turret                  = true,
      waterWeapon             = true,
      weaponAcceleration      = 100,
      weaponType              = [[Cannon]],
      weaponVelocity          = 500,
    },

  },

}

return lowerkeys({ chickenf = unitDef })
