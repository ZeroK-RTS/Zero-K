-- note that the order of the MergeTable args matters for nested tables (such as colormaps)!

local presets = {
	commandAuraRed = {
		{class='StaticParticles', options=commandCoronaRed},
		{class='GroundFlash', options=MergeTable(groundFlashRed, {radiusFactor=3.5,mobile=true,life=60,
			colormap={ {1, 0.2, 0.2, 1},{1, 0.2, 0.2, 0.85},{1, 0.2, 0.2, 1} }})},
	},
	commandAuraOrange = {
			{class='StaticParticles', options=commandCoronaOrange},
		{class='GroundFlash', options=MergeTable(groundFlashOrange, {radiusFactor=3.5,mobile=true,life=math.huge,
			colormap={ {0.8, 0, 0.2, 1},{0.8, 0, 0.2, 0.85},{0.8, 0, 0.2, 1} }})},
	},
	commandAuraGreen = {
		{class='StaticParticles', options=commandCoronaGreen},
		{class='GroundFlash', options=MergeTable(groundFlashGreen, {radiusFactor=3.5,mobile=true,life=math.huge,
			colormap={ {0.2, 1, 0.2, 1},{0.2, 1, 0.2, 0.85},{0.2, 1, 0.2, 1} }})},
	},
	commandAuraBlue = {
		{class='StaticParticles', options=commandCoronaBlue},
		{class='GroundFlash', options=MergeTable(groundFlashBlue, {radiusFactor=3.5,mobile=true,life=math.huge,
			colormap={ {0.2, 0.2, 1, 1},{0.2, 0.2, 1, 0.85},{0.2, 0.2, 1, 1} }})},
	},
	commandAuraViolet = {
		{class='StaticParticles', options=commandCoronaViolet},
		{class='GroundFlash', options=MergeTable(groundFlashViolet, {radiusFactor=3.5,mobile=true,life=math.huge,
			colormap={ {0.8, 0, 0.8, 1},{0.8, 0, 0.8, 0.85},{0.8, 0, 0.8, 1} }})},
	},

	commAreaShield = {
		--{class='ShieldJitter', options={delay=0, life=math.huge, heightFactor = 0.75, size=350, strength = .001, precision=50, repeatEffect=true, quality=4}},
	},

	commandShieldRed = {
		{class='ShieldSphere', options=MergeTable({colormap1 = {{1, 0.1, 0.1, 0.6}}, colormap2 = {{1, 0.1, 0.1, 0.15}}}, commandShieldSphere)},
--		{class='StaticParticles', options=commandCoronaRed},
--		{class='GroundFlash', options=MergeTable(groundFlashRed, {radiusFactor=3.5,mobile=true,life=60,
--			colormap={ {1, 0.2, 0.2, 1},{1, 0.2, 0.2, 0.85},{1, 0.2, 0.2, 1} }})},
	},
	commandShieldOrange = {
		{class='ShieldSphere', options=MergeTable({colormap1 = {{0.8, 0.3, 0.1, 0.6}}, colormap2 = {{0.8, 0.3, 0.1, 0.15}}}, commandShieldSphere)},
	},
	commandShieldGreen = {
		{class='ShieldSphere', options=MergeTable({colormap1 = {{0.1, 1, 0.1, 0.6}}, colormap2 = {{0.1, 1, 0.1, 0.15}}}, commandShieldSphere)},
	},
	commandShieldBlue= {
		{class='ShieldSphere', options=MergeTable({colormap1 = {{0.1, 0.1, 0.8, 0.6}}, colormap2 = {{0.1, 0.1, 1, 0.15}}}, commandShieldSphere)},
	},
	commandShieldViolet = {
		{class='ShieldSphere', options=MergeTable({colormap1 = {{0.6, 0.1, 0.75, 0.6}}, colormap2 = {{0.6, 0.1, 0.75, 0.15}}}, commandShieldSphere)},
	},
}

effectUnitDefs = {
	--// FUSIONS //--------------------------
	energysingu = {
		{class='Bursts', options=energysinguBursts},
		{class='StaticParticles', options=energysinguCorona},
		--{class='ShieldSphere', options=energysinguShieldSphere},
		--{class='ShieldJitter', options={layer=-16, life=math.huge, pos={0,58.9,0}, size=100, precision=22, strength = 0.001, repeatEffect=true}},
		{class='GroundFlash', options=groundFlashOrange},
	},
	corfus = {
		{class='StaticParticles', options=corfusNova},
		{class='StaticParticles', options=corfusNova2},
		{class='StaticParticles', options=corfusNova3},
		{class='StaticParticles', options=corfusNova4},

		{class='Bursts', options=corfusBursts},
		{class='ShieldJitter', options={delay=0,life=math.huge, pos={0,40.5,0.0}, size=10, precision=22, repeatEffect=true}},
	},
	aafus = {
		{class='SimpleParticles2', options=MergeTable({piece="rod2", delay=30, lifeSpread=math.random()*20},sparks)},
		{class='SimpleParticles2', options=MergeTable({piece="rod4", delay=60, lifeSpread=math.random()*20},sparks)},
		{class='SimpleParticles2', options=MergeTable({piece="rod5", delay=90, lifeSpread=math.random()*20},sparks)},
		{class='SimpleParticles2', options=MergeTable({piece="rod7", delay=120, lifeSpread=math.random()*20},sparks)},

		{class='Sound', options={repeatEffect=true, file="Sparks", blockfor=4.8*30, length=5.1*30}},
	},

	--// SHIELDS //---------------------------
	-- Don't raise strength of ShieldJitter recklessly, it can really distort things (including unit icons) under it!
	staticshield = {
	{class='Bursts', options=staticshieldBursts},
	{class='ShieldSphere', options=staticshieldBall},
	--{class='Bursts',options=shieldBursts350, quality = 3},
	--{class='ShieldJitter', options={delay = 0, life=math.huge, pos={0,15,0}, size=355, precision =0, strength   = 0.001, repeatEffect = true, quality = 4, onActive = true}},
--	{class='ShieldSphere', options={piece="base", life=math.huge, size=350, pos={0,-15,0}, colormap1 = {{0.95, 0.1, 0.95, 0.2}}, repeatEffect=true}},
--	{class='GroundFlash', options=groundFlashShield},
--	{class='UnitPieceLight', options={piece="glow", colormap = {{0,0,1,0.2}},},},
	},
	shieldshield = {
		{class='Bursts', options=staticshieldBursts},
		{class='ShieldSphere', options= staticshieldBall},
	
	--{class='Bursts',options=shieldBursts350, quality = 3},
	--{class='ShieldJitter', options={delay = 0, life=math.huge, pos={0,15,0}, size=355, precision =0, strength   = 0.001, repeatEffect = true, quality = 4, onActive = true}},
	
	--{class='ShieldJitter', options={delay=0, life=math.huge, pos={0,15,0}, size=355, strength = .001, precision=50, repeatEffect=true, quality = 1, onActive = true}},
--	{class='ShieldSphere', options={piece="base", life=math.huge, size=360, pos={0,-15,0}, colormap1 = {{0.95, 0.1, 0.95, 0.2}}, repeatEffect=true}},
	},
	shieldfelon = {
	--{class='Bursts', options=MergeTable({piece="lpilot"},staticshieldBursts)},
	--{class='Bursts', options=MergeTable({piece="rpilot"},staticshieldBursts)},
	--{class='ShieldJitter', options={delay=0, life=math.huge, pos={0,15,0}, size=100, strength = .001, precision=50, repeatEffect=true, quality = 5}},
	},
	
	striderfunnelweb = {
		{class='Bursts', options=MergeTable(staticshieldBurstsBig, {piece="emitl", pos={2,14.3,0}, shieldRechargeDelay = tonumber(WeaponDefNames["striderfunnelweb_shield"].customParams.shield_recharge_delay), colormap = { {0.3, 0.3, 1, 0.8} }})},
		{class='Bursts', options=MergeTable(staticshieldBurstsBig, {piece="emitr", pos={-2,14.3,0}, shieldRechargeDelay = tonumber(WeaponDefNames["striderfunnelweb_shield"].customParams.shield_recharge_delay), colormap = { {0.3, 0.3, 1, 0.8} }})},
		{class='ShieldSphere', options={piece="emitl", life=math.huge, size=14.5, pos={2,14.3,0}, colormap1 = {{0.1, 0.85, 0.95, 0.9}}, colormap2 = {{0.5, 0.3, 0.95, 0.2}}, rechargingColor1 = {0.95, 0.4, 0.4, 1.0}, rechargingColor2 = {0.95, 0.1, 0.4, 0.2}, shieldRechargeDelay = 30*tonumber(WeaponDefNames["striderfunnelweb_shield"].customParams.shield_recharge_delay), shieldRechargeSize = 7, repeatEffect=true}},	
		{class='ShieldSphere', options={piece="emitr", life=math.huge, size=14.5, pos={-2,14.3,0}, colormap1 = {{0.1, 0.85, 0.95, 0.9}}, colormap2 = {{0.5, 0.3, 0.95, 0.2}}, rechargingColor1 = {0.95, 0.4, 0.4, 1.0}, rechargingColor2 = {0.95, 0.1, 0.4, 0.2}, shieldRechargeDelay = 30*tonumber(WeaponDefNames["striderfunnelweb_shield"].customParams.shield_recharge_delay), shieldRechargeSize = 7, repeatEffect=false}},	
	},

	--// ENERGY STORAGE //--------------------
	corestor = {
		{class='GroundFlash', options=groundFlashCorestor},
	},
	energypylon = {
		{class='GroundFlash', options=groundFlashenergypylon},
	},

	--// FACTORIES //----------------------------
	factoryship = {
		{class='StaticParticles', options=MergeTable(blinkyLightRed, {piece="flash01"}) },
	{class='StaticParticles', options=MergeTable(blinkyLightGreen, {piece="flash03", delay = 20,}) },
	{class='StaticParticles', options=MergeTable(blinkyLightBlue, {piece="flash05", delay = 40,}) },	
	},

	--// PYLONS // ----------------------------------
	staticmex = {
		{class='OverdriveParticles', options=staticmexGlow},
	},
	
	--// PYLONS // ----------------------------------
	mexpylon = {
		{class='GroundFlash', options=groundFlashCorestor},
	},

	--// OTHER
	roost = {
		{class='SimpleParticles', options=roostDirt},
		{class='SimpleParticles', options=MergeTable({delay=60},roostDirt)},
		{class='SimpleParticles', options=MergeTable({delay=120},roostDirt)},
	},
	
	staticrearm= {
		{class='StaticParticles', options=MergeTable(blinkyLightRed, {piece="light1"}) },
	{class='StaticParticles', options=MergeTable(blinkyLightGreen, {piece="light2"}) },
	},
	
	staticheavyradar = {
		{class='StaticParticles', options=MergeTable(blinkyLightWhite,{piece="point"})},
		--{class='StaticParticles', options=MergeTable(blinkyLightBlue,{piece="point", delay=15})},
	},  
	corarad = {
		{class='StaticParticles', options=radarBlink},
		{class='StaticParticles', options=MergeTable(radarBlink,{pos={-1.6,25,0.0},delay=15})},
		{class='StaticParticles', options=MergeTable(radarBlink,{pos={0,21,-1.0},delay=30})},
	},
	staticradar = {
		{class='StaticParticles', options=MergeTable(radarBlink,{piece="head"})},
		{class='StaticParticles', options=MergeTable(radarBlink,{piece="head", delay=15})},
	},

	spidercrabe = {
	{class='StaticParticles', options=MergeTable(blinkyLightWhite, {piece="blight"}) },
	},   
	jumpassault = {
	--{class='StaticParticles', options=MergeTable(jackGlow, {piece="point"}) },
	},  
	
	cloakheavyraid = {
		{class='Ribbon', options={color={.3,.3,01,1}, width=5.5, piece="blade", onActive=false, noIconDraw = true, quality = 2}},
	},
	
	pw_warpgate = {
		{class='StaticParticles', options=warpgateCorona},
--    {class='GroundFlash', options=groundFlashOrange},
	},
	
	pw_techlab = {
		{class='StaticParticles', options=warpgateCorona},
--    {class='GroundFlash', options=groundFlashOrange},
	},
	
	pw_warpjammer = {
		{class='StaticParticles', options=MergeTable(warpgateCoronaAlt, {onActive=true})},
	},

	zenith = {
		{class='StaticParticles', options=zenithCorona},
	},    

	amphtele = {
	{class='ShieldSphere', options=MergeTable(teleShieldSphere, {piece="sphere"})},
	{class='StaticParticles', options=MergeTable(teleCorona, {piece="sphere"})},
	--{class='ShieldSphere', options=MergeTable(teleShieldSphere, {piece="sphere", onActive = true, size=18})},
	{class='StaticParticles', options=MergeTable(teleCorona, {piece="sphere", onUnitRulesParam = "teleActive", size=100})},
	{class='ShieldJitter', options={delay=0, life=math.huge, piece="sphere", size=50, strength = .005, precision=50, repeatEffect=true, onUnitRulesParam = "teleActive", noIconDraw = true, quality = 2,}},
	},
	amphlaunch = {
	{class='ShieldSphere', options=MergeTable(throwShieldSphere, {piece="gunbase"})},
	{class='StaticParticles', options=MergeTable(throwCorona, {piece="gunbase"})},
	},
	
	tele_beacon = {
	{class='ShieldSphere', options=MergeTable(teleShieldSphere, {piece="sphere"})},
	{class='StaticParticles', options=MergeTable(teleCorona, {piece="sphere"})},
	{class='StaticParticles', options=MergeTable(teleCorona, {piece="sphere", onActive = true, size=50})},
	{class='ShieldJitter', options={delay=0, life=math.huge, piece="sphere", size=20, strength = .005, precision=50, repeatEffect=true, onActive=true, noIconDraw = true, quality = 2,}},	
	},
	
	striderbantha = {
	{class='StaticParticles', options=MergeTable(blinkyLightBlue, {piece="light", delay = 20, size = 25}) },
	},
	
	striderdetriment = {
	{class='StaticParticles', options=MergeTable(blinkyLightGreen, {piece="light", delay = 20, size = 30}) },
	},

	-- length tag does nothing
	--// PLANES //----------------------------
	bomberheavy = {
		{class='AirJet', options={color={0.4,0.1,0.8}, width=3.5, length=30, piece="nozzle1", onActive=true, noIconDraw = true}},
		{class='AirJet', options={color={0.4,0.1,0.8}, width=3.5, length=30, piece="nozzle2", onActive=true, noIconDraw = true}},
	 },
	armhawk2 = {
		{class='AirJet', options={color={0.2,0.2,1.0}, width=2.8, length=25, piece="enginel", onActive=true, noIconDraw = true}},
		{class='AirJet', options={color={0.2,0.2,1.0}, width=2.8, length=25, piece="enginer", onActive=true, noIconDraw = true}},
		{class='Ribbon', options={width=1, size=12, piece="wingtip1", noIconDraw = true}},
		{class='Ribbon', options={width=1, size=12, piece="wingtip2", noIconDraw = true}},
	},
	gunshipheavyskirm = {
		{class='AirJet', options={color={0.0,0.5,1.0}, width=5, length=15, piece="lfjet", onActive=true, noIconDraw = true}},
		{class='AirJet', options={color={0.0,0.5,1.0}, width=5, length=15, piece="rfjet", onActive=true, noIconDraw = true}},
		{class='AirJet', options={color={0.0,0.5,1.0}, width=2.5, length=10, piece="lrjet", onActive=true, noIconDraw = true}},
		{class='AirJet', options={color={0.0,0.5,1.0}, width=2.5, length=10, piece="rrjet", onActive=true, noIconDraw = true}},
	},
	armawac = {
		{class='Ribbon', options={color={.3,.3,01,1}, width=5.5, piece="rjet", noIconDraw = true}},
		{class='Ribbon', options={color={.3,.3,01,1}, width=5.5, piece="ljet", noIconDraw = true}},
	},
	bomberdisarm = {
		{class='AirJet', options={color={0.1,0.4,0.6}, width=3.5, length=20, piece="Jet1", onActive=true, noIconDraw = true}},
		{class='AirJet', options={color={0.1,0.4,0.6}, width=3.5, length=20, piece="Jet2", onActive=true, noIconDraw = true}},
		{class='Ribbon', options={width=1, size=6, piece="LWingTip", noIconDraw = true}},
		{class='Ribbon', options={width=1, size=6, piece="RWingTip", noIconDraw = true}},
	--{class='StaticParticles', options=MergeTable(blinkyLightRed, {piece="LWingTip"}) },
	--{class='StaticParticles', options=MergeTable(blinkyLightGreen, {piece="RWingTip"}) },	
	},
	athena = {
		{class='AirJet', options={color={0.45,0.45,0.9}, width=2.8, length=15, piece="enginel", onActive=true, noIconDraw = true}},
		{class='AirJet', options={color={0.45,0.45,0.9}, width=2.8, length=15, piece="enginer", onActive=true, noIconDraw = true}},
		{class='Ribbon', options={width=1, size=12, piece="wingtipl", noIconDraw = true}},
		{class='Ribbon', options={width=1, size=12, piece="wingtipr", noIconDraw = true}},
	},

	gunshipemp = {
		{class='Ribbon', options={width=1, size=5, piece="ljet", noIconDraw = true}},
		{class='Ribbon', options={width=1, size=5, piece="rjet", noIconDraw = true}},  
		{class='AirJet', options={color={0.1,0.4,0.6}, width=3, length=14, piece="ljet", onActive=true, emitVector = {0, 1, 0}, noIconDraw = true}},
		{class='AirJet', options={color={0.1,0.4,0.6}, width=3, length=14, piece="rjet", onActive=true, emitVector = {0, 1, 0}, noIconDraw = true}},
	},

	gunshipraid = {
		{class='Ribbon', options={width=1, size=10, piece="lfx", noIconDraw = true}},
		{class='Ribbon', options={width=1, size=10, piece="rfx", noIconDraw = true}},  
		{class='AirJet', options={color={0.1,0.4,0.6}, width=4, length=25, piece="lfx", onActive=true, emitVector = {0, 0, 1}, noIconDraw = true}},
		{class='AirJet', options={color={0.1,0.4,0.6}, width=4, length=25, piece="rfx", onActive=true, emitVector = {0, 0, 1}, noIconDraw = true}},
	},
	planecon = {
		{class='Ribbon', options={width=1, size=10, piece="engine1", noIconDraw = true}},
		{class='Ribbon', options={width=1, size=10, piece="engine2", noIconDraw = true}},  
		{class='AirJet', options={color={0.1,0.4,0.6}, width=8, length=20, piece="body", onActive=true, emitVector = {0, 1, 0}, noIconDraw = true}},
	},
	gunshipaa = { 
		{class='AirJet', options={color={0.1,0.4,0.6}, width=4, length=32, piece="ljet", onActive=true, noIconDraw = true}},
		{class='AirJet', options={color={0.1,0.4,0.6}, width=4, length=32, piece="rjet", onActive=true, noIconDraw = true}},
		{class='AirJet', options={color={0.1,0.4,0.6}, width=4, length=32, piece="mjet", onActive=true, noIconDraw = true}},
	},
	bomberstrike = {
		{class='AirJet', options={color={0.1,0.4,0.6}, width=3.5, length=25, piece="exhaustl", onActive=true, noIconDraw = true}},
		{class='AirJet', options={color={0.1,0.4,0.6}, width=3.5, length=25, piece="exhaustr", onActive=true, noIconDraw = true}},
		{class='Ribbon', options={width=1, size=10, piece="wingtipl", noIconDraw = true}},
		{class='Ribbon', options={width=1, size=10, piece="wingtipr", noIconDraw = true}},  
	},
	bomberassault = {
		{class='AirJet', options={color={0.1,0.4,0.6}, width=5, length=40, piece="exhaustLeft", onActive=true, noIconDraw = true}},
		{class='AirJet', options={color={0.1,0.4,0.6}, width=5, length=40, piece="exhaustRight", onActive=true, noIconDraw = true}},
		{class='AirJet', options={color={0.1,0.4,0.6}, width=6, length=60, piece="exhaustTop", onActive=true, noIconDraw = true}},
	},
	bomberprec = {
		{class='AirJet', options={color={0.2,0.4,0.8}, width=4, length=30, piece="thrustr", texture2=":c:bitmaps/gpl/lups/jet2.bmp", onActive=true, noIconDraw = true}},
		{class='AirJet', options={color={0.2,0.4,0.8}, width=4, length=30, piece="thrustl", texture2=":c:bitmaps/gpl/lups/jet2.bmp", onActive=true, noIconDraw = true}},
		{class='Ribbon', options={width=1, piece="wingtipl", noIconDraw = true}},
		{class='Ribbon', options={width=1, piece="wingtipr", noIconDraw = true}},
	{class='StaticParticles', options=MergeTable(blinkyLightRed, {piece="wingtipl"}) },
	{class='StaticParticles', options=MergeTable(blinkyLightGreen, {piece="wingtipr"}) },
	},
	planefighter = {
		{class='AirJet', options={color={0.6,0.1,0.0}, width=3.5, length=55, piece="nozzle1", texture2=":c:bitmaps/gpl/lups/jet2.bmp", onActive=true, noIconDraw = true}},
		{class='AirJet', options={color={0.6,0.1,0.0}, width=3.5, length=55, piece="nozzle2", texture2=":c:bitmaps/gpl/lups/jet2.bmp", onActive=true, noIconDraw = true}},
		{class='Ribbon', options={width=1, piece="wingtip1", noIconDraw = true}},
		{class='Ribbon', options={width=1, piece="wingtip2", noIconDraw = true}},
	},
	gunshipcon = { 
		{class='AirJet', options={color={0.1,0.4,0.6}, width=4, length=25, piece="ExhaustForwardRight", onActive=true, emitVector = {0, 0, -1}, noIconDraw = true}},
		{class='AirJet', options={color={0.1,0.4,0.6}, width=4, length=25, piece="ExhaustForwardLeft", onActive=true, emitVector = {0, 0, -1}, noIconDraw = true}},
		{class='AirJet', options={color={0.1,0.4,0.6}, width=3, length=15, piece="ExhaustRearLeft", onActive=true, emitVector = {0, 0, -1}, noIconDraw = true}},
		{class='AirJet', options={color={0.1,0.4,0.6}, width=3, length=15, piece="ExhaustRearRight", onActive=true, emitVector = {0, 0, -1}, noIconDraw = true}},
	 },
	bomberriot = {
		{class='AirJet', options={color={0.7,0.3,0.1}, width=5, length=40, piece="exhaust", onActive=true, noIconDraw = true}},
		{class='Ribbon', options={width=1, piece="wingtipl", noIconDraw = true}},
		{class='Ribbon', options={width=1, piece="wingtipr", noIconDraw = true}},
	{class='StaticParticles', options=MergeTable(blinkyLightRed, {piece="wingtipr"}) },
	{class='StaticParticles', options=MergeTable(blinkyLightGreen, {piece="wingtipl"}) },	
	},
	planeheavyfighter = {
		-- jets done in gadget
		{class='Ribbon', options={width=1, size=8, piece="wingtip1", noIconDraw = true}},
		{class='Ribbon', options={width=1, size=8, piece="wingtip2", noIconDraw = true}},
	},
	gunshipheavytrans = {
		{class='ShieldSphere', options=MergeTable(teleShieldSphere, {piece="agrav1", onActive=true})},
		{class='StaticParticles', options=MergeTable(teleCorona, {piece="agrav1", onActive=true})},
		{class='ShieldSphere', options=MergeTable(teleShieldSphere, {piece="agrav2", onActive=true})},
		{class='StaticParticles', options=MergeTable(teleCorona, {piece="agrav2", onActive=true})},
		{class='ShieldSphere', options=MergeTable(teleShieldSphere, {piece="agrav3", onActive=true})},
		{class='StaticParticles', options=MergeTable(teleCorona, {piece="agrav3", onActive=true})},
		{class='ShieldSphere', options=MergeTable(teleShieldSphere, {piece="agrav4", onActive=true})},
		{class='StaticParticles', options=MergeTable(teleCorona, {piece="agrav4", onActive=true})},
	}, 
	gunshiptrans = {
		{class='AirJet', options={color={0.2,0.4,0.8}, width=3.5, length=22, piece="engineEmit", onActive=true}},
		{class='ShieldSphere', options=MergeTable(valkShieldSphere, {piece="agrav1", onActive=true})},
		{class='StaticParticles', options=MergeTable(valkCorona, {piece="agrav1", onActive=true})},
		{class='ShieldSphere', options=MergeTable(valkShieldSphere, {piece="agrav2", onActive=true})},
		{class='StaticParticles', options=MergeTable(valkCorona, {piece="agrav2", onActive=true})},
		{class='ShieldSphere', options=MergeTable(valkShieldSphere, {piece="agrav3", onActive=true})},
		{class='StaticParticles', options=MergeTable(valkCorona, {piece="agrav3", onActive=true})},
		{class='ShieldSphere', options=MergeTable(valkShieldSphere, {piece="agrav4", onActive=true})},
		{class='StaticParticles', options=MergeTable(valkCorona, {piece="agrav4", onActive=true})},
	},  
	planescout = {
		{class='AirJet', options={color={0.1,0.4,0.6}, width=3.5, length=25, piece="thrust", onActive=true}},
		{class='Ribbon', options={width=1, size=8, piece="wingtipl"}},
		{class='Ribbon', options={width=1, size=8, piece="wingtipr"}},
	{class='StaticParticles', options=MergeTable(blinkyLightRed, {piece="wingtipr"}) },
	{class='StaticParticles', options=MergeTable(blinkyLightGreen, {piece="wingtipl"}) },		
	},
	planelightscout = {
		{class='AirJet', options={color={0.1,0.4,0.6}, width=1.8, length=15, piece="exhaustl", onActive=true}},
		{class='AirJet', options={color={0.1,0.4,0.6}, width=1.8, length=15, piece="exhaustr", onActive=true}},
		{class='Ribbon', options={width=1, size=6, piece="wingtipl"}},
		{class='Ribbon', options={width=1, size=6, piece="wingtipr"}},
	--{class='StaticParticles', options=MergeTable(blinkyLightRed, {piece="wingtipr"}) },
	--{class='StaticParticles', options=MergeTable(blinkyLightGreen, {piece="wingtipl"}) },		
	},
	gunshipassault = {
		{class='AirJet', options={color={0.8,0.1,0.0}, width=7, length=30, jitterWidthScale=2, distortion=0.01, piece="Lengine", texture2=":c:bitmaps/gpl/lups/jet2.bmp", onActive=true, noIconDraw = true}},
		{class='AirJet', options={color={0.8,0.1,0.0}, width=7, length=30, jitterWidthScale=2, distortion=0.01, piece="Rengine", texture2=":c:bitmaps/gpl/lups/jet2.bmp", onActive=true, noIconDraw = true}},
		{class='AirJet', options={color={0.8,0.1,0.0}, width=7, length=30, jitterWidthScale=2, distortion=0.01, piece="Lwingengine", texture2=":c:bitmaps/gpl/lups/jet2.bmp", onActive=true, noIconDraw = true}},
		{class='AirJet', options={color={0.8,0.1,0.0}, width=7, length=30, jitterWidthScale=2, distortion=0.01, piece="Rwingengine", texture2=":c:bitmaps/gpl/lups/jet2.bmp", onActive=true, noIconDraw = true}},
	},
	gunshipkrow = {
		{class='AirJet', options={color={0.0,0.5,1.0}, width=10, length=20, piece="jetrear", onActive=true, emitVector = {0, 0, 1}, noIconDraw = true}},
		{class='AirJet', options={color={0.0,0.5,1.0}, width=10, length=20, piece="jetleft", onActive=true, emitVector = {0, 0, 1}, noIconDraw = true}},
		{class='AirJet', options={color={0.0,0.5,1.0}, width=10, length=20, piece="jetright", onActive=true, emitVector = {0, 0, 1}, noIconDraw = true}},
	},
	nebula = {
		{class='AirJet', options={color={0.0,0.5,1.0}, width=15, length=60, piece="exhaustmain", onActive=true}}, 
		{class='AirJet', options={color={0.0,0.5,1.0}, width=8, length=25, piece="exhaust1", onActive=true, emitVector = {0, 1, 0}}},  
		{class='AirJet', options={color={0.0,0.5,1.0}, width=8, length=25, piece="exhaust2", onActive=true, emitVector = {0, 1, 0}}},
		{class='AirJet', options={color={0.0,0.5,1.0}, width=8, length=25, piece="exhaust3", onActive=true, emitVector = {0, 1, 0}}},
		{class='AirJet', options={color={0.0,0.5,1.0}, width=8, length=25, piece="exhaust4", onActive=true, emitVector = {0, 1, 0}}},
		{class='StaticParticles', options=MergeTable(blinkyLightRed, {piece="light2"}) },
		{class='StaticParticles', options=MergeTable(blinkyLightGreen, {piece="light1"}) },    
	},
	dronefighter = {
		--{class='AirJet', options={color={0.6,0.1,0.0}, width=3, length=40, piece="DroneMain", texture2=":c:bitmaps/gpl/lups/jet2.bmp", onActive=true}},
		{class='Ribbon', options={width=1, size=24, piece="DroneMain"}},
	},
 }

effectUnitDefsXmas = {}

local levelScale = {
		[0] = 1,
		[1] = 1,
		[2] = 1.1,
		[3] = 1.2,
		[4] = 1.25,
		[5] = 1.3,
}

-- load presets from unitdefs
for i=1,#UnitDefs do
	local unitDef = UnitDefs[i]

	if unitDef.customParams and unitDef.customParams.commtype then
		local s = levelScale[tonumber(unitDef.customParams.level) or 1]
		if unitDef.customParams.commtype == "1" then
			effectUnitDefsXmas[unitDef.name] = {
				{class='SantaHat', options={pos={0.3*s,1.1*s,-6 - 3*s}, emitVector={-1,0,-0.08}, width=3.6*s, height=6.2*s, ballSize=0.9*s, piece="Head"}},
			}
		elseif unitDef.customParams.commtype == "2" then
			effectUnitDefsXmas[unitDef.name] = {
				{class='SantaHat', options={pos={0,6*s,2*s}, emitVector={0.4,1,0.2}, width=2.7*s, height=6*s, ballSize=0.7*s, piece="head"}},
			}
		elseif unitDef.customParams.commtype == "3" then
			effectUnitDefsXmas[unitDef.name] = {
				{class='SantaHat', options={color={0,0.7,0,1}, pos={1.5*s,4*s,0.5*s}, emitVector={0.7,1.6,0.2}, width=2.5*s, height=6*s, ballSize=0.7*s, piece="head"}},
			}
		elseif unitDef.customParams.commtype == "4" then
			effectUnitDefsXmas[unitDef.name] = {
				{class='SantaHat', options={pos={0,3.8*s,0.35*s}, emitVector={0,1,0}, width=2.7*s, height=6*s, ballSize=0.7*s, piece="head"}},
			}
		elseif unitDef.customParams.commtype == "5" then
			effectUnitDefsXmas[unitDef.name] = {
				{class='SantaHat', options={color={0,0.7,0,1}, pos={0,0,0}, emitVector={0,1,0.1}, width=2.7*s, height=6*s, ballSize=0.7*s, piece="hat"}},
			}
		elseif unitDef.customParams.commtype == "6" then
			effectUnitDefsXmas[unitDef.name] = {
				{class='SantaHat', options={color={0,0,0.7,1}, pos={0,0,0}, emitVector={0,1,-0.1}, width=4.05*s, height=9*s, ballSize=1.05*s, piece="hat"}},
			}
		end
	end
	if unitDef.customParams then
		local fxTableStr = unitDef.customParams.lups_unit_fxs
		if fxTableStr then
			local fxTableFunc = loadstring("return "..fxTableStr)
			local fxTable = fxTableFunc()
			effectUnitDefs[unitDef.name] = effectUnitDefs[unitDef.name] or {}
			for i=1,#fxTable do	-- for each item in preset table
				local toAdd = presets[fxTable[i]]
				for i=1,#toAdd do
					table.insert(effectUnitDefs[unitDef.name],toAdd[i])	-- append to unit's lupsFX table
				end
			end
		end
	end
end
