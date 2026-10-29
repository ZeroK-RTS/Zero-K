-- categorises units into groups and compositions!



-- adds 2 tables together!
local function Union(t1, t2)
	local ret = {}
	for i, v in pairs(t1) do
		ret[i] = v
	end
	for i, v in pairs(t2) do
		ret[i] = v
	end
	return ret
end

local function Union2 (tables)
    local returnTable = {}
    for k,v in pairs(tables) do
        for k,v in pairs(v) do 
            returnTable[#returnTable+1] = v 
        end
    end
    return returnTable
end

local allGroups = {
    constructors = {
        [[amphcon]],
        [[cloakcon]],
        [[gunshipcon]],
        [[hovercon]],
        [[jumpcon]],
        [[planecon]],
        [[shieldcon]],
        [[spidercon]],
        [[tankcon]],
        [[vehcon]],
    },
    scouts = {
        [[jumpscout]],
        [[shieldscout]],
        [[spiderscout]],
        [[vehscout]],
    },
    raiders = {
        [[amphimpulse]],
        [[amphraid]],
        [[cloakheavyraid]],
        [[cloakraid]],
        [[gunshipraid]], --Locusts are here, they interact more with riots and raiders than aa
        [[hoverheavyraid]],
        [[hoverraid]],
        [[jumpraid]],
        [[shieldraid]],
        [[spideremp]],
        [[tankheavyraid]],
        [[tankraid]],
        [[vehraid]],
    },
    riots = {
        [[amphriot]],
        [[cloakriot]],
        [[hoverdepthcharge]],
        [[hoverriot]],
        [[jumpblackhole]],
        [[shieldriot]],
        [[spiderriot]],
        [[tankriot]],
        [[vehriot]],
    },
    skirmishers = {
        [[amphfloater]],
        [[amphsupport]], --for most purposes it is a skirm...
        [[cloakskirm]],
        [[hoverskirm]],
        [[jumpskirm]],
        [[shieldfelon]], --Felon is sort of a skirm >,> there  may need to be a shield grouping
        [[shieldskirm]],
        [[spiderskirm]],
        [[vehcapture]],
        [[vehsupport]], --acts as skirm most things
    },
    antiAir = {
        [[amphaa]],
        [[cloakaa]],
        [[hoveraa]],
        [[jumpaa]],
        [[shieldaa]],
        [[spideraa]],
        [[tankaa]],
    },
    assaults = {
        [[cloakassault]],
        [[hoverassault]],
        [[jumpassault]],
        [[shieldassault]],
        [[spiderassault]],
        [[tankassault]],
        [[vehaa]],
        [[vehassault]],
    },
    artillery = {
        [[cloakarty]],
        [[cloaksnipe]],
        [[hoverarty]],
        [[jumparty]],
        [[shieldarty]],
        [[tankarty]],
        [[tankheavyarty]],
        [[veharty]], -- feels skirmishy, but what is artillery but long range skirming 
        [[vehheavyarty]],
    },
    bombs = {
        [[amphbomb]],
        [[cloakbomb]],
        [[gunshipbomb]],
        [[shieldbomb]],
    },
    aerialAA = {
        [[gunshipaa]],
        [[planefighter]],
        [[planeheavyfighter]],
    },
    bombers = {
        [[bomberassault]],
        [[bomberdisarm]],
        [[bomberheavy]],
        [[bomberprec]],
        [[bomberriot]]
        --TODO add magpie once it settles in
    },
    gunships = {
        [[gunshipassault]],
        [[gunshipheavyskirm]],
        [[gunshipskirm]],
    },
    transports = {
        [[gunshipheavyskirm]],
        [[gunshiptrans]],
    },
    
    support = {
        [[spiderantiheavy]],
        [[planelightscout]],
        [[planescout]],
        [[amphlaunch]],
        [[amphtele]],
        [[athena]],
        [[cloakjammer]],
        [[shieldshield]],
    },
    antiHeavy = {
        [[jumpbomb]],
        [[striderantiheavy]], 
        [[gunshipemp]], 
    },
    stridersDemi = {
        [[amphassault]],
        [[jumpsumo]],
        [[spidercrabe]],
        [[tankheavyassault]],
    },
    stridersMedium = {
        [[gunshipkrow]],
        [[striderarty]],
        [[striderdante]],
        [[striderfunnelweb]],
        [[striderscorpion]]
    },
    stridersHeavy = {
        [[nebula]], --fuck it, nebula
        [[striderbantha]],
        --[[striderdetriment]] --TODO figure out where to put this :0
    },
    
    -- Get ships from shipfac 
    ships = {
        [[shipaa]],
        [[shiparty]],
        [[shipassault]],
        [[shipriot]],
        [[shipskirm]],
        [[shiptorpraider]],
        [[subraider]]
    },
    seaStriders = {
       [[shipcarrier]],
       [[shipheavyarty]],
       [[subtacmissile]],
       
    },
    drones = {
        [[dronecarry]],
        [[dronefighter]],
        [[droneheavyslow]],
        [[dronelight]]
    },
    --DUPLICATE UNIT CATEGORY
    antiSub = {
        [[amphimpulse]],
        [[amphraid]],
        [[hoverdepthcharge]],
        [[hoverraid]],
        [[amphriot]],
    },

        --TODO
    extra = {
        [[subscout]],
        [[assaultcruiser]],
        [[grebe]],
        [[spideranarchid]],
        --[[hoverminer]] --may be broken
    },
    
    factories = {
        [[factoryshield]],
        [[factorycloak]],
        [[factoryveh]],
        [[factoryplane]],
        [[factorygunship]],
        [[factoryhover]],
        [[factoryamph]],
        [[factoryspider]],
        [[factoryjump]],
        [[factorytank]],
        [[factoryship]],
        [[striderhub]],
    },
    factoryPlates = {
        [[plateshield]],
        [[platecloak]],
        [[plateveh]],
        [[plateplane]],
        [[plategunship]],
        [[platehover]],
        [[plateamph]],
        [[platespider]],
        [[platejump]],
        [[platetank]],
        [[plateship]],
    },
    ecoLight= {
        [[energysolar]],
	    [[energywind]],
    },
    ecoHeavy = {
        [[energyfusion]],
	    [[energysingu]],
    },
    ecoSupport = {
    	[[staticstorage]],
        [[energypylon]],
        [[staticcon]],
        [[staticrearm]],
    },
    turretsLight = {
        [[turretmissile]],
        [[turretlaser]],
    },
    turretsMedium = {
        [[turretimpulse]],
        [[turretemp]],
        [[turretriot]],
        [[turretgauss]],
        [[turretheavylaser]],
    },
    turretsHeavy = 	{
        [[turretantiheavy]],
	    [[turretheavy]]
    },
    turretsAntiSub = {
        [[turretgauss]], --Is duplicate
        [[turrettorp]],
    },
    -- Artemis is more a strategic threat than general AA thingy
    turretsAALight = {
        [[turretaalaser]],
        [[turretaaclose]],
    },
    turretsAAMedium = {
        [[turretaafar]],
        [[turretaaflak]]
    },
    -- you usually only want one jammer and then maybe more shields, so this is only useful for a 1 off roll
    -- so essentially, things that roll something from here will need to check to not duplicate a bunch of radars or jammers
    staticSupport = {
        [[staticradar]],
        [[staticheavyradar]],
        [[staticshield]],
        [[staticjammer]],
    },
    staticStrategic = {
        [[turretaaheavy]],
        [[staticantinuke]],
        [[staticarty]],
        [[staticmissilesilo]],
        -- unsure if nuke and bertha are fitting here, but they are certainly "strategic" level threats
        [[staticheavyarty]],
        [[staticnuke]]
    },
    siloMisiles = {
        [[empmissile]],
        [[missileslow]],
        [[napalmmissile]],
        [[seismic]],
        [[tacnuke]],
    },
    supers = {
        [[mahlazer]],
	    [[raveparty]],
	    [[zenith]]
    },
    pwSupport = {
        [[pw_bomberfac]],
        [[pw_dropfac]],
        [[pw_mine]],
        [[pw_mine2]],
        [[pw_mine3]], --pw_metal looks the same and is more impactfull/fits its model better
        -- [[pw_metal]] -- buuut its also too busted maybe...
        [[pw_interception]],
        [[pw_warpjammer]],
        [[pw_storage]]
    },
    pwDefence = {
        [[pw_garrison]],
        [[pw_grid]]
    },
    -- serve no function, but look nice
    pwGreebles = {
        [[generic_tech]],
        [[pw_wormhole]],
        [[pw_wormhole2]],
        [[pw_artefact]]
        -- [[pw_warpgate]] looks identical to warpjammer, so nuh
    }
}

allGroups.turretsAll = Union2({
    allGroups.turretsLight,
    allGroups.turretsMedium,
    allGroups.turretsHeavy,
    allGroups.turretsAA,
})
allGroups.allStandardLandCombatants = Union2({
    allGroups.scouts,
    allGroups.raiders,
    allGroups.riots,
    allGroups.skirmishers,
    allGroups.assaults,
    allGroups.artillery,
    allGroups.antiAir,
    allGroups.stridersDemi,
    allGroups.stridersMedium,
    allGroups.stridersHeavy,
})




return allGroups