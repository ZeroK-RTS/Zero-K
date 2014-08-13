unitDef = {
  unitname                      = [[napalmmissile]],
  name                          = [[Inferno]],
  description                   = [[Napalm Missile]],
  buildCostEnergy               = 500,
  buildCostMetal                = 500,
  builder                       = false,
  buildingGroundDecalDecaySpeed = 30,
  buildingGroundDecalSizeX      = 3,
  buildingGroundDecalSizeY      = 3,
  buildingGroundDecalType       = [[napalmmissile_aoplane.dds]],
  buildPic                      = [[napalmmissile.png]],
  buildTime                     = 500,
  canAttack                     = true,
  category                      = [[SINK UNARMED]],
  collisionVolumeOffsets        = [[0 15 0]],
  collisionVolumeScales         = [[20 60 20]],
  collisionVolumeTest	        = 1,
  collisionVolumeType	        = [[CylY]],

  customParams                  = {
    description_de = [[Napalm-Rakete]],
    description_pl = [[Rakieta zapalajaca]],
    helptext       = [[The Inferno is a large AoE fire weapon. Its direct damage is modest, but the cloud of fire it creates lasts for a very long time.]],
    helptext_de    = [[Der Inferno ist eine große AoE Feuerwaffe. Sein direkter Schaden ist gering, aber die Flammenhölle erzeugt Verluste für längere Zeit.]],
    helptext_pl    = [[Jednorazowa rakieta dalekiego zasięgu, ktora podpala na dlugi czas trafiony obszar, zadajac znajdujacym sie w nim jednostkom obrazenia.]],
  },

  explodeAs                     = [[WEAPON]],
  footprintX                    = 1,
  footprintZ                    = 1,
  iconType                      = [[cruisemissilesmall]],
  idleAutoHeal                  = 5,
  idleTime                      = 1800,
  maxDamage                     = 1000,
  maxSlope                      = 18,
  minCloakDistance              = 150,
  objectName                    = [[wep_napalm.s3o]],
  script                        = [[cruisemissile.lua]],
  seismicSignature              = 4,
  selfDestructAs                = [[WEAPON]],

  sfxtypes                      = {

    explosiongenerators = {
      [[custom:RAIDMUZZLE]],
    },

  },

  sightDistance                 = 0,
  useBuildingGroundDecal        = false,
  yardMap                       = [[o]],

  weapons                       = {

    {
      def                = [[WEAPON]],
      badTargetCategory  = [[SWIM LAND SHIP HOVER]],
      onlyTargetCategory = [[SWIM LAND SINK TURRET FLOAT SHIP HOVER GUNSHIP]],
    },

  },

  weaponDefs                    = {

    WEAPON = {
      name                    = [[Napalm Missile]],
      cegTag                  = [[napalmtrail]],
      areaOfEffect            = 512,
      avoidFriendly           = false,
      collideFriendly         = false,
      craterBoost             = 4,
      craterMult              = 3.5,

      customParams        	  = {
        setunitsonfire = "1",
        burntime = 90,
      },

      damage                  = {
        default = 150,
        subs    = 7.5,
      },

      edgeEffectiveness       = 0.4,
      explosionGenerator      = [[custom:napalm_missile]],
      fireStarter             = 220,
      impulseBoost            = 0,
      impulseFactor           = 0,
      interceptedByShieldType = 1,
      levelGround             = false,
      model                   = [[wep_napalm.s3o]],
      noSelfDamage            = true,
      range                   = 3500,
      reloadtime              = 10,
      shakeduration           = [[1.5]],
      shakemagnitude          = [[32]],
      smokeTrail              = false,
      soundHit                = [[weapon/missile/nalpalm_missile_hit]],
      soundStart              = [[weapon/missile/tacnuke_launch]],
      tolerance               = 4000,
      turnrate                = 18000,
      weaponAcceleration      = 180,
      weaponTimer             = 3,
      weaponType              = [[StarburstLauncher]],
      weaponVelocity          = 1200,
    },

  },

  featureDefs                   = {
  },

}

return lowerkeys({ napalmmissile = unitDef })
