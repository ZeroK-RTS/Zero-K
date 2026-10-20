-- Weapons whose explosions every player can see regardless of LOS, because their
-- CEGs have alwaysvisible particles. Skirmish AIs are told about these so that
-- they get the same information. Dynamic commander weapons match with or without
-- their numeric prefix.
--
-- Zenith and Starlight are deliberately absent. They fire continuously, so AIs are
-- told when their meteor stream or beam turns on and off instead.

return {
	-- Strategic and tactical missiles
	staticnuke_crblmssl                   = true, -- Trinity
	tacnuke_weapon                        = true, -- Eos
	subtacmissile_tacnuke                 = true, -- Scylla
	empmissile_emp_weapon                 = true, -- Shockley
	seismic_seismic_weapon                = true, -- Quake
	shipcarrier_disarm_rocket             = true, -- Reef

	-- Superweapons and heavy artillery
	raveparty_red_killer                  = true, -- Disco Rave Party
	raveparty_blue_shocker                = true,
	raveparty_yellow_slammer              = true,
	striderdetriment_obliteration_blaster = true, -- Detriment
	bomberassault_zeppelin_bomb           = true, -- Odin
	bomberheavy_arm_pidr                  = true, -- Likho
	bomberheavyold_arm_pidr               = true,
	staticarty_plasma                     = true, -- Cerberus
	shipheavyarty_plasma                  = true, -- Shogun
	commweapon_slamrocket                 = true, -- Commander S.L.A.M.

	-- Death explosions
	atomic_blast                          = true, -- Fusion, Starlight, Planetwars structures
	nuclear_missile                       = true, -- Heavy Geothermal, Detriment
	energysingu_singularity               = true, -- Singularity Reactor
	jumpbomb_jumpbomb_death               = true, -- Skuttle
}
