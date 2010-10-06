
-- needs select[1] and ok[1] (and build for cons)

return {
	-- Misc
	armasp = {
		select = {
			[1] = "building_select1",
		},
	},
	armcsa = {
		build = "builder_start",
		ok = {
			[1] = "gunship_move",
		},
		select = {
			[1] = "light_gunship_select",
		},
	},
	cortl = {
		ok = {
			[1] = "turret_move",
		},
		select = {
			[1] = "light_turret_select",
		},
	},
	cormine1 = {
		ok = {
			[1] = "light_bot_move",
		},
		select = {
			[1] = "crawlie_select",
		},
	},
	corcom = {
		build = "builder_start",
		ok = {
			[1] = "heavy_bot_move",
		},
		select = {
			[1] = "bot_select",
		},
	},
	armcom = {
		build = "builder_start",
		ok = {
			[1] = "heavy_bot_move",
		},
		select = {
			[1] = "bot_select",
		},
	},
	commsupport = {
		build = "builder_start",
		ok = {
			[1] = "heavy_bot_move",
		},
		select = {
			[1] = "bot_select",
		},
	},
	commrecon = {
		build = "builder_start",
		ok = {
			[1] = "heavy_bot_move",
		},
		select = {
			[1] = "bot_select",
		},
	},
	armcomdgun = {
		build = "builder_start",
		ok = {
			[1] = "heavy_bot_move",
		},
		select = {
			[1] = "bot_select",
		},
	},
	
	-- Spider
	arm_spider = {
		build = "builder_start",
		ok = {
			[1] = "spider_move",
		},
		select = {
			[1] = "spider_select2",
		},
	},
	spiderassault = {
		ok = {
			[1] = "spider_move",
		},
		select = {
			[1] = "spider_select",
		},
	},
	armflea = {
		ok = {
			[1] = "light_bot_move",
		},
		select = {
			[1] = "crawlie_select",
		},
	},
	armsptk = {
		ok = {
			[1] = "spider_move",
		},
		select = {
			[1] = "spider_select",
		},
	},
	arm_venom = {
		ok = {
			[1] = "spider_move",
		},
		select = {
			[1] = "spider_select",
		},
	},

	armcrabe = {
		ok = {
			[1] = "heavy_bot_move",
		},
		select = {
			[1] = "bot_select",
		},
	},
	armspy = {
		ok = {
			[1] = "spy_move",
		},
		select = {
			[1] = "spy_select",
		},
	},
	
	-- Shield
	cornecro = {
		build = "builder_start",
		ok = {
			[1] = "bot_move",
		},
		select = {
			[1] = "light_bot_select2",
		},
	},
	corclog = {
		ok = {
			[1] = "bot_move",
		},
		select = {
			[1] = "bot_select",
		},
	},
	corak = {
		ok = {
			[1] = "bot_move",
		},
		select = {
			[1] = "bot_select",
		},
	},
	corstorm = {
		ok = {
			[1] = "bot_move",
		},
		select = {
			[1] = "bot_select",
		},
	},
	corthud = {
		ok = {
			[1] = "bot_move",
		},
		select = {
			[1] = "bot_select",
		},
	},
	corroach = {
		ok = {
			[1] = "light_bot_move",
		},
		select = {
			[1] = "crawlie_select",
		},
	},
	cormak = {
		ok = {
			[1] = "bot_move",
		},
		select = {
			[1] = "bot_select",
		},
	},
	corcrash = {
		ok = {
			[1] = "bot_move",
		},
		select = {
			[1] = "bot_select",
		},
	},
	
	-- Jumper
	corfast = {
		build = "builder_start",
		ok = {
			[1] = "bot_move",
		},
		select = {
			[1] = "light_bot_select2",
		},
	},
	
	puppy = {
		ok = {
			[1] = "light_bot_move",
		},
		select = {
			[1] = "crawlie_select",
		},
	},
	slowmort = {
		ok = {
			[1] = "bot_move",
		},
		select = {
			[1] = "bot_select",
		},
	},
	corsumo = {
		ok = {
			[1] = "heavy_bot_move",
		},
		select = {
			[1] = "bot_select",
		},
	},
	corpyro = {
		ok = {
			[1] = "bot_move",
		},
		select = {
			[1] = "bot_select",
		},
	},
	corcan = {
		ok = {
			[1] = "bot_move",
		},
		select = {
			[1] = "bot_select",
		},
	},
	armaak = {
		ok = {
			[1] = "bot_move",
		},
		select = {
			[1] = "bot_select",
		},
	},
	corsktl = {
		ok = {
			[1] = "light_bot_move",
		},
		select = {
			[1] = "crawlie_select",
		},
	},
	
	-- Cloak
	armrectr = {
		build = "builder_start",
		ok = {
			[1] = "bot_move",
		},
		select = {
			[1] = "light_bot_select2",
		},
	},
	
	armsnipe = {
		ok = {
			[1] = "spy_move",
		},
		select = {
			[1] = "spy_select",
		},
	},
	armpw = {
		ok = {
			[1] = "light_bot_move",
		},
		select = {
			[1] = "light_bot_select",
		},
	},
	spherepole = {
		ok = {
			[1] = "spy_move",
		},
		select = {
			[1] = "spy_select",
		},
	},
	armrock = {
		ok = {
			[1] = "bot_move",
		},
		select = {
			[1] = "medium_bot_select",
		},
	},
	armzeus = {
		ok = {
			[1] = "bot_move",
		},
		select = {
			[1] = "medium_bot_select",
		},
	},
	armtick = {
		ok = {
			[1] = "light_bot_move",
		},
		select = {
			[1] = "crawlie_select",
		},
	},
	armwar = {
		ok = {
			[1] = "bot_move",
		},
		select = {
			[1] = "medium_bot_select",
		},
	},
	armham = {
		ok = {
			[1] = "bot_move",
		},
		select = {
			[1] = "medium_bot_select",
		},
	},
	armjeth = {
		ok = {
			[1] = "bot_move",
		},
		select = {
			[1] = "medium_bot_select",
		},
	},
	
	-- Mech
	armraz = {
		ok = {
			[1] = "heavy_bot_move",
		},
		select = {
			[1] = "heavy_bot_move",
		},
	},
	dante = {
		ok = {
			[1] = "heavy_bot_move",
		},
		select = {
			[1] = "heavy_bot_move",
		},
	},
	armraven = {
		ok = {
			[1] = "heavy_bot_move",
		},
		select = {
			[1] = "heavy_bot_move",
		},
	},
	armbanth = {
		ok = {
			[1] = "turret_select",
		},
		select = {
			[1] = "turret_select",
		},
	},
	armorco = {
		ok = {
			[1] = "turret_select",
		},
		select = {
			[1] = "turret_select",
		},
	},
	
	-- Vehicle
	corned = {
		build = "builder_start",
		ok = {
			[1] = "vehicle_move",
		},
		select = {
			[1] = "vehicle_select2",
		},
	},
	corfav = {
		ok = {
			[1] = "vehicle_move",
		},
		select = {
			[1] = "vehicle_select2",
		},
	},
	cormist = {
		ok = {
			[1] = "vehicle_move",
		},
		select = {
			[1] = "vehicle_select2",
		},
	},
	corgator = {
		ok = {
			[1] = "vehicle_move",
		},
		select = {
			[1] = "vehicle_select2",
		},
	},
	corgarp = {
		ok = {
			[1] = "vehicle_move",
		},
		select = {
			[1] = "vehicle_select2",
		},
	},
	corlevlr = {
		ok = {
			[1] = "vehicle_move",
		},
		select = {
			[1] = "vehicle_select2",
		},
	},
	corraid = {
		ok = {
			[1] = "vehicle_move",
		},
		select = {
			[1] = "vehicle_select2",
		},
	},
	
	-- Tank
	coracv = {
		build = "builder_start",
		ok = {
			[1] = "light_tank_move2",
		},
		select = {
			[1] = "tank_select",
		},
	},
	panther = {
		ok = {
			[1] = "light_tank_move2",
		},
		select = {
			[1] = "tank_select",
		},
	},
	core_egg_shell  = {
		ok = {
			[1] = "light_tank_move2",
		},
		select = {
			[1] = "tank_select",
		},
	},
	cormart = {
		ok = {
			[1] = "tank_move",
		},
		select = {
			[1] = "tank_select",
		},
	},
	correap = {
		ok = {
			[1] = "tank_move",
		},
		select = {
			[1] = "tank_select",
		},
	},
	armmerl = {
		ok = {
			[1] = "tank_move",
		},
		select = {
			[1] = "tank_select",
		},
	},
	trem = {
		ok = {
			[1] = "tank_move",
		},
		select = {
			[1] = "tank_select",
		},
	},
	tawf114 = {
		ok = {
			[1] = "tank_move",
		},
		select = {
			[1] = "tank_select",
		},
	},
	corgol = {
		ok = {
			[1] = "tank_move",
		},
		select = {
			[1] = "tank_select",
		},
	},
	corsent = {
		ok = {
			[1] = "tank_move",
		},
		select = {
			[1] = "tank_select",
		},
	},
	
	-- Hovercraft
	corch = {
		build = "builder_start",
		ok = {
			[1] = "hovercraft_move",
		},
		select = {
			[1] = "hovercraft_select",
		},
	},
	corsh = {
		ok = {
			[1] = "hovercraft_move",
		},
		select = {
			[1] = "hovercraft_select",
		},
	},
	nsaclash = {
		ok = {
			[1] = "hovercraft_move",
		},
		select = {
			[1] = "hovercraft_select",
		},
	},
	hoverassault = {
		ok = {
			[1] = "hovercraft_move",
		},
		select = {
			[1] = "hovercraft_select",
		},
	},
	hoverriot = {
		ok = {
			[1] = "hovercraft_move",
		},
		select = {
			[1] = "hovercraft_select",
		},
	},
	armmanni = {
		ok = {
			[1] = "hovercraft_move",
		},
		select = {
			[1] = "hovercraft_select",
		},
	},
	hoverartillery = {
		ok = {
			[1] = "hovercraft_move",
		},
		select = {
			[1] = "hovercraft_select",
		},
	},
	corah = {
		ok = {
			[1] = "hovercraft_move",
		},
		select = {
			[1] = "hovercraft_select",
		},
	},
	
	-- Fixed wing
	fighter = {
		ok = {
			[1] = "fighter_move",
		},
		select = {
			[1] = "fighter_select",
		},
	},
	corvamp = {
		ok = {
			[1] = "fighter_move",
		},
		select = {
			[1] = "fighter_select",
		},
	},
	corshad = {
		ok = {
			[1] = "bomber_move",
		},
		select = {
			[1] = "bomber_select",
		},
	},
	corhurc2 = {
		ok = {
			[1] = "bomber_move",
		},
		select = {
			[1] = "bomber_select",
		},
	},
	armstiletto_laser = {
		ok = {
			[1] = "bomber_move",
		},
		select = {
			[1] = "bomber_select",
		},
	},
	armcybr = {
		ok = {
			[1] = "bomber_move",
		},
		select = {
			[1] = "bomber_select",
		},
	},
	corawac = {
		ok = {
			[1] = "bomber_move",
		},
		select = {
			[1] = "bomber_select",
		},
	},
	
	-- Gunship
	armca = {
		build = "builder_start",
		ok = {
			[1] = "gunship_move",
		},
		select = {
			[1] = "light_gunship_select",
		},
	},
	bladew = {
		ok = {
			[1] = "gunship_move",
		},
		select = {
			[1] = "light_gunship_select",
		},
	},
	blastwing = {
		ok = {
			[1] = "gunship_move",
		},
		select = {
			[1] = "light_gunship_select",
		},
	},
	armkam = {
		ok = {
			[1] = "gunship_move",
		},
		select = {
			[1] = "gunship_select",
		},
	},
	corape = {
		ok = {
			[1] = "gunship_move",
		},
		select = {
			[1] = "gunship_select",
		},
	},
	armbrawl = {
		ok = {
			[1] = "heavy_gunship_move",
		},
		select = {
			[1] = "heavy_gunship_select",
		},
	},
	blackdawn = {
		ok = {
			[1] = "heavy_gunship_move",
		},
		select = {
			[1] = "heavy_gunship_select",
		},
	},
	corcrw = {
		ok = {
			[1] = "gunship_move",
		},
		select = {
			[1] = "heavy_gunship_select",
		},
	},
	corvalk = {
		ok = {
			[1] = "gunship_move",
		},
		select = {
			[1] = "gunship_select",
		},
	},
	corbtrans = {
		ok = {
			[1] = "gunship_move",
		},
		select = {
			[1] = "heavy_gunship_select",
		},
	},
	
	-- Economy
	cormex = {
		select = {
			[1] = "building_select2",
		},
	},
	armwin = {
		select = {
			[1] = "windmill",
		},
	},
	armsolar = {
		select = {
			[1] = "building_select1",
		},
	},
	armfus = {
		select = {
			[1] = "fusion_select",
		},
	},
	cafus = {
		select = {
			[1] = "adv_fusion_select",
		},
	},
	armwin = {
		select = {
			[1] = "windmill_select",
		},
	},
	geo = {
		select = {
			[1] = "geo_select",
		},
	},
	amgeo = {
		select = {
			[1] = "geo_select",
		},
	},
	armmstor = {
		select = {
			[1] = "building_select2",
		},
	},
	corestor = {
		select = {
			[1] = "fusion_select",
		},
	},
	armnanotc = {
		build = "builder_start",
		select = {
			[1] = "building_select1",
		},
	},
	
	-- Factory
	factorycloak = {
		build = "builder_start",
		select = {
			[1] = "factory_select",
		},
	},
	factoryshield = {
		build = "builder_start",
		select = {
			[1] = "factory_select",
		},
	},
	factoryjump = {
		build = "builder_start",
		select = {
			[1] = "factory_select",
		},
	},
	factoryspider = {
		build = "builder_start",
		select = {
			[1] = "factory_select",
		},
	},
	factoryveh = {
		build = "builder_start",
		select = {
			[1] = "factory_select",
		},
	},
	factorytank = {
		build = "builder_start",
		select = {
			[1] = "factory_select",
		},
	},
	factoryhover = {
		build = "builder_start",
		select = {
			[1] = "factory_select",
		},
	},
	factoryplane = {
		build = "builder_start",
		select = {
			[1] = "factory_select",
		},
	},
	factorygunship = {
		build = "builder_start",
		select = {
			[1] = "factory_select",
		},
	},
	corsy = {
		build = "builder_start",
		select = {
			[1] = "factory_select",
		},
	},
	
	-- Intel
	--[[
	corrad = { NEEDED
		select = {
			[1] = "factory_select",
		},
	},
	corvrad = { NEEDED
		ok = {
			[1] = "bot_move",
		},
		select = {
			[1] = "factory_select",
		},
	},
	armarad = { NEEDED
		select = {
			[1] = "factory_select",
		},
	},
	--]]
	armsonar = {
		select = {
			[1] = "sonar_select",
		},
	},
	corjamt = {
		select = {
			[1] = "shield_select",
		},
	},
	core_spectre = {
		ok = {
			[1] = "bot_move",
		},
		select = {
			[1] = "shield_select",
		},
	},
	armjamt = {
		select = {
			[1] = "cloaker_select",
		},
	},
	armaser = {
		ok = {
			[1] = "bot_move",
		},
		select = {
			[1] = "cloaker_select",
		},
	},
	
	-- Land Turrets
	corllt = {
		ok = {
			[1] = "turret_move",
		},
		select = {
			[1] = "light_turret_select",
		},
	},
	corgrav = {
		ok = {
			[1] = "turret_move",
		},
		select = {
			[1] = "light_turret_select",
		},
	},
	armartic = {
		ok = {
			[1] = "turret_move",
		},
		select = {
			[1] = "faraday_select",
		},
	},
	armdeva = {
		ok = {
			[1] = "turret_move",
		},
		select = {
			[1] = "light_turret_select",
		},
	},
	corhlt = {
		ok = {
			[1] = "light_turret_select",
		},
		select = {
			[1] = "turret_select",
		},
	},
	armpb = {
		ok = {
			[1] = "light_turret_select",
		},
		select = {
			[1] = "turret_select",
		},
	},
	armanni = {
		ok = {
			[1] = "light_turret_select",
		},
		select = {
			[1] = "turret_select",
		},
	},
	armbrtha = {
		ok = {
			[1] = "turret_select",
		},
		select = {
			[1] = "turret_select",
		},
	},
	corbhmth = {
		ok = {
			[1] = "turret_select",
		},
		select = {
			[1] = "turret_select",
		},
	},
	mahlazer = {
		ok = {
			[1] = "silo_select",
		},
		select = {
			[1] = "silo_select",
		},
	},
	
	-- Air Turrets
	corrl = {
		ok = {
			[1] = "turret_move",
		},
		select = {
			[1] = "light_turret_select",
		},
	},
	corraz = {
		ok = {
			[1] = "turret_move",
		},
		select = {
			[1] = "light_turret_select",
		},
	},
	missiletower = {
		ok = {
			[1] = "turret_move",
		},
		select = {
			[1] = "light_turret_select",
		},
	},
	armcir = {
		ok = {
			[1] = "light_turret_select",
		},
		select = {
			[1] = "turret_select",
		},
	},
	corflak = {
		ok = {
			[1] = "light_turret_select",
		},
		select = {
			[1] = "turret_select",
		},
	},
	screamer = {
		ok = {
			[1] = "turret_select",
		},
		select = {
			[1] = "silo_select",
		},
	},
	
	-- Silo etc
	missilesilo = {
		build = "builder_start",
		select = {
			[1] = "silo_select",
		},
	},
	tacnuke = {
		ok = {
			[1] = "turret_select",
		},
		select = {
			[1] = "silo_select",
		},
	},
	empmissile = {
		ok = {
			[1] = "turret_select",
		},
		select = {
			[1] = "silo_select",
		},
	},
	seismic = {
		ok = {
			[1] = "turret_select",
		},
		select = {
			[1] = "silo_select",
		},
	},
	armamd = {
		ok = {
			[1] = "turret_select",
		},
		select = {
			[1] = "silo_select",
		},
	},
	corsilo = {
		select = {
			[1] = "silo_select",
		},
	},
	
}
