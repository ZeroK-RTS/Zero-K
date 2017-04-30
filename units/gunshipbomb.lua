unitDef = {
  unitname               = [[gunshipbomb]],
  name                   = [[Blastwing]],
  description            = [[Flying Bomb (Burrows)]],
  acceleration           = 0.25,
  brakeRate              = 0.2,
  buildCostMetal         = 55,
  builder                = false,
  buildPic               = [[gunshipbomb.png]],
  canFly                 = true,
  canGuard               = true,
  canMove                = true,
  canPatrol              = true,
  canSubmerge            = false,
  category               = [[GUNSHIP]],
  collide                = false,
  collisionVolumeOffsets = [[0 0 0]],
  collisionVolumeScales  = [[20 20 20]],
  collisionVolumeType    = [[ellipsoid]],
  corpse                 = [[DEAD]],
  cruiseAlt              = 30,

  customParams           = {
	landflystate   = [[1]],
	description_fr = [[Drône Éxplosif]],
	description_de = [[Fliegende Bombe]],
	helptext       = [[The Blastwing does only a small amount of damage, suitable for taking out mexes, solars, LLTs, wind farms and nanotowers, though it can offer a more fomidible punch en-masse. Be mindful of the speed and direction it is travelling, as much of the damage done by it is directional shrapnel that will continue on the trajectory of the bomb after it dies. In this way, you can spray an enemy with shards of metal even if your Blastwing dies before it is in range. Do not pack them too tightly, as they can chain explode. Cloaks when landed.]],
	helptext_fr    = [[Le Blastwing est un drône kamikaze de faible puissance. Idéal pour détruire les éxtraceurs ou les éoliennes ennemies, profitez de sa vitesse pour projeter des éclats de sa carcasse sur d'autres ennemis.]],
	helptext_de    = [[Der Blastwing macht sehr wenig Schaden, ideal, um etwa Metallextraktoren, Soloranlagen, Leichte Lasertürme, Windanlagen und Nanotürme auszumerzen. Dennoch können gunshipbombs in Massen durchaus ordentlich Schaden anrichten. Beachte die Geschwindigkeit und Richtung, in die die Drohnen fliegen, denn der größte Schaden wird durch das Schrapnell erzielt, das nach dem Tod der Drohne weiter in Flugrichtung fliegen wird. Auf diese Weise kannst du deinen Gegner trotzdem mit Metallsplittern überhäufen, obwohl deine gunshipbombs schon vorher abgeschossen wurden. Vermeide, dass du die gunshipbombs zu nah aneinander stationiert, da sie in einer Kettenreaktion explodieren können. Kann sich zur Mine entwickeln.]],
	idle_cloak = 1,
  },

  explodeAs              = [[gunshipbomb_EXPLOSION]],
  --fireState              = 0,
  floater                = true,
  footprintX             = 2,
  footprintZ             = 2,
  hoverAttack            = true,
  iconType               = [[gunshipspecial]],
  idleAutoHeal           = 5,
  idleTime               = 1800,
  kamikaze               = true,
  kamikazeDistance       = 60,
  kamikazeUseLOS         = true,
  maneuverleashlength    = [[1240]],
  maxDamage              = 100,
  maxSlope               = 36,
  maxVelocity            = 8.2,
  minCloakDistance       = 75,
  noAutoFire             = false,
  noChaseCategory        = [[TERRAFORM SATELLITE SUB]],
  objectName             = [[f-1.s3o]],
  script                 = [[gunshipbomb.lua]],
  selfDestructAs         = [[gunshipbomb_EXPLOSION]],
  selfDestructCountdown  = 0,
  sightDistance          = 380,
  turnRate               = 1144,
  upright                = false,
  workerTime             = 0,
  
  featureDefs            = {

    DEAD      = {
      blocking         = false,
      featureDead      = [[HEAP]],
      footprintX       = 3,
      footprintZ       = 3,
      object           = [[wreck2x2b.s3o]],
    },

    HEAP      = {
      blocking         = false,
      footprintX       = 2,
      footprintZ       = 2,
      object           = [[debris2x2c.s3o]],
    },

  },
}

--------------------------------------------------------------------------------

local weaponDefs = {
  gunshipbomb_EXPLOSION = {
    name               = "gunshipbomb Explosion",
    areaOfEffect       = 256,
    craterBoost        = 1,
    craterMult         = 3.5,
	
	customParams        	  = {
      setunitsonfire = "1",
      burntime = 60,
      
      area_damage = 1,
      area_damage_radius = 128,
      area_damage_dps = 16,
      area_damage_duration = 20,
      
      --lups_heat_fx = [[firewalker]],
    },
	
    damage = {
      default = 80,
      planes  = 80,
      subs    = 4,
    },
	
    edgeeffectiveness  = 0.7,
    explosionGenerator = [[custom:napalm_gunshipbomb]],
    explosionSpeed     = 10000,
	firestarter        = 180,
    impulseBoost       = 0,
    impulseFactor      = 0.4,
    soundHit           = "explosion/ex_med17",
	
  },
}
unitDef.weaponDefs = weaponDefs

--------------------------------------------------------------------------------

return lowerkeys({ gunshipbomb = unitDef })
