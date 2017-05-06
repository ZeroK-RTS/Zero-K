unitDef = {
  unitname            = [[armcybr]],
  name                = [[Wyvern]],
  description         = [[Singularity Bomber]],
  --autoheal			  = 25,
  brakerate           = 0.4,
  buildCostMetal      = 2000,
  builder             = false,
  buildPic            = [[ARMCYBR.png]],
  canFly              = true,
  canGuard            = true,
  canMove             = true,
  canPatrol           = true,
  canSubmerge         = false,
  category            = [[FIXEDWING]],
  collide             = false,
  collisionVolumeOffsets = [[-2 0 0]],
  collisionVolumeScales  = [[32 12 40]],
  collisionVolumeType    = [[box]],
  corpse              = [[DEAD]],
  crashDrag           = 0.02,
  cruiseAlt           = 250,

  customParams        = {
    helptext       = [[The Wyvern drops a single powerful bomb that can send units flying. It is sturdy enough to penetrate moderate AA and escape to repair, but should not be used recklessly - it's too expensive for that.]],
    description_de = [[Implosion Bomber]],
    description_fr = [[Bombardier r Implosion]],
    helptext_de    = [[Wyvern ist ein mächtiger Bomber, der alles in Schutt und Asche legt. Seine Schlagkraft und Ausdauer ist riesig, doch muss er nach jedem Angriff Munition nachladen, was ihn eher für Angriffe auf einzelne Ziele prädestiniert.]],
    helptext_fr    = [[Le Wyvern est tout simplement la mort venue du ciel. Ce bombardier lourdement blindé et relativement lent transporte une tete nucléaire tactique r implosion. Capable de faire des ravages dans les lignes ennemies, ou de détruire des structures lourdement blindées. Tout simplement mortel utilisé en petites escadres.]],
    modelradius    = [[10]],
    requireammo    = [[1]],
    reammoseconds  = [[30]],
	refuelturnradius = [[150]],
  },

  explodeAs           = [[GUNSHIPEX]],
  floater             = true,
  footprintX          = 3,
  footprintZ          = 3,
  iconType            = [[bombernuke]],
  idleAutoHeal        = 5,
  idleTime            = 1800,
  maneuverleashlength = [[1280]],
  maxAcc              = 0.75,
  maxDamage           = 2360,
  maxFuel             = 1000000,
  maxVelocity         = 9,
  minCloakDistance    = 75,
  mygravity           = 1,
  noAutoFire          = false,
  noChaseCategory     = [[TERRAFORM FIXEDWING SATELLITE GUNSHIP SUB]],
  objectName          = [[ARMCYBR]],
  refuelTime		  = 20,
  script			  = [[armcybr.lua]],
  selfDestructAs      = [[GUNSHIPEX]],
  sightDistance       = 660,
  turnRadius          = 20,
  workerTime          = 0,

  weapons             = {

    {
      def                = [[ARM_PIDR]],
	  badTargetCategory	 = [[GUNSHIP FIXEDWING]],
      onlyTargetCategory = [[SWIM LAND SINK TURRET FLOAT SHIP HOVER GUNSHIP FIXEDWING]],
    },

  },


  weaponDefs          = {

    ARM_PIDR = {
      name                    = [[Implosion Bomb]],
      areaOfEffect            = 192,
      avoidFeature            = false,
      avoidFriendly           = false,
	  burnblow                = true,
	  cegTag                  = [[raventrail]],
      collideFriendly         = false,
   
      craterBoost             = 1,
      craterMult              = 2,

	  customParams        	  = {
		light_color = [[1.6 0.85 0.38]],
		light_radius = 750,
	  },

      damage                  = {
        default = 2000.1,
        planes  = 2000.1,
        subs    = 100,
      },

      edgeEffectiveness       = 0.5,
      explosionGenerator      = [[custom:NUKE_150]],
      fireStarter             = 100,
      flightTime              = 3,
      impulseBoost            = 0,
      impulseFactor           = -0.8,
      interceptedByShieldType = 2,
      model                   = [[wep_m_deathblow.s3o]],
      range                   = 500,
      reloadtime              = 1,
      smokeTrail              = false,
      soundHit                = [[weapon/missile/liche_hit]],
      soundStart              = [[weapon/missile/liche_fire]],
      startVelocity           = 300,
      tolerance               = 16000,
      tracks                  = true,
      turnRate                = 30000,
	  weaponAcceleration      = 200,
      weaponType              = [[MissileLauncher]],
      weaponVelocity          = 400,
    },

  },


  featureDefs         = {

    DEAD  = {
      blocking         = true,
      featureDead      = [[HEAP]],
      footprintX       = 2,
      footprintZ       = 2,
      object           = [[licho_d.s3o]],
    },

    HEAP  = {
      blocking         = false,
      footprintX       = 2,
      footprintZ       = 2,
      object           = [[debris3x3b.s3o]],
    },

  },

}

return lowerkeys({ armcybr = unitDef })
