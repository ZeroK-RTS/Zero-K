return {

  CORPYRO_NAPALM = {
    name                    = [[Napalm Blast]],
    areaofeffect            = 256,
    craterboost             = 1,
    cratermult              = 3.5,
    
	customParams        	  = {
	  setunitsonfire = "1",
	  burnchance     = "1",
	},
	
    damage                  = {
      default = 50,
      planes  = 50,
      subs    = 1,
    },
    
    edgeeffectiveness       = 0.5,
    explosionGenerator      = [[custom:napalm_koda]],
    fireStarter             = 200,
    impulseboost            = 0,
    impulsefactor           = 0,
    interceptedbyshieldtype = 1,
    range                   = 200,
    reloadtime              = 3.6,
    rendertype              = 4,
    soundhit                = [[explosion/ex_med3]],
    turret                  = 1,
    weaponvelocity          = 250,
  },
}