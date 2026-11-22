-- units grouped and defined for the compositionbuilder,
-- bundled in a config file for ease of access and cross gadget sharing


--LETS THINK!!!

-- We can get amph and hover movetypes from their well, movetype, so dont necessarily need a category?
-- there is the category category, but I dont really want to do string befuddling or try to use a normal param
    
-- [[AKBOT2]],[[AKBOT3]],[[AKBOT4]] are amph bot movetypes
-- 
-- [[BOAT2]],[[BOAT3]],[[BOAT4]],[[BOAT5]], --boats!

-- [[ATKBOT3]] spiders that can water? mostly chickens

-- no need for sea strider category if we can differentiate via movetypes

-- shield category may be doable with just shields mabi

-- gunships are weird o,o" I will likely need help with it

-- Dampner mine could be unique?

-- Morningstar and Punisher sort of double up...

-- Anarchid needs its legs fixed

-- Dozer and slicer have potential TM but are not ready really

-- Lancelet needs some stuff but then could be good

--What a handy thing to find!
-- only thing here thats iffy is the air movetype for atkbot3... but it fits I spose!
local staticUnits, movetypeDefID, movetypes = VFS.Include("LuaRules/Configs/CAI/unitMovetype.lua")

local spTableMerge = Spring.Utilities.MergeTable

--Vibecoded Table func! would be good to have as a util func?
local function stringToTable(str)
    -- Wrap the string in a return statement
    local code = "return " .. str
    local chunk, err

    if setfenv then
        -- Lua 5.1 / LuaJIT
        chunk, err = loadstring(code)
        if chunk then setfenv(chunk, {}) end
    else
        -- Lua 5.2, 5.3, 5.4
        chunk, err = load(code, "deserialize", "t", {})
    end

    if not chunk then
        return nil, err
    end

    -- Use pcall to safely catch any runtime errors during evaluation
    local success, result = pcall(chunk)
    if not success or type(result) ~= "table" then
        return nil, result or "Result was not a table"
    end

    return result
end

local sectionGroupings = {}
local classGroupings = {}
local taggedUnitDefNames = {}
local taggedUnitDefIDs = {}
for unitDefID = 1, #UnitDefs do
    local ud = UnitDefs[unitDefID]
	local cp = UnitDefs[unitDefID].customParams
	if cp.unit_class_tags then
        local unitDefName = UnitDefs[unitDefID].name
        local movementTag = movetypeDefID[unitDefID] or "static"
        local sectionTags = nil
        local classTags = nil
        local unitClassTags = stringToTable(cp.unit_class_tags)
        if unitClassTags and unitClassTags.sectiontags then
            sectionTags = unitClassTags.sectiontags
            if type(sectionTags) =="string" then --lets them spell as they wish!
                sectionTags = {sectionTags}
            end
            if not sectionGroupings[sectionTags] then
                sectionGroupings[sectionTags] = {unitDefName}
            else
                table.insert(sectionGroupings[sectionTags],unitDefName)
            end 
        end
        if unitClassTags and unitClassTags.classtags then
            classTags = unitClassTags.classtags
            if type(classTags) =="string" then --lets them spell as they wish!
                classTags = {classTags}
            end
            for index, tagName in ipairs(classTags) do
                if not classGroupings[tagName] then
                    classGroupings[tagName] = {unitDefName}
                else
                    table.insert(classGroupings[tagName],1,unitDefName)
                end
            end
        end
        taggedUnitDefIDs[unitDefID] = {sectionTags = sectionTags, classTags = classTags, movementTags = {movementTag}}
        taggedUnitDefNames[unitDefName] = {sectionTags = sectionTags, classTags = classTags, movementTags = {movementTag}}
    end
end

--TODO make into Spring util function!!
local function Union2 (tables)
    local returnTable = {}
    for k,v in pairs(tables) do
        for k,v in pairs(v) do 
            returnTable[#returnTable+1] = v 
        end
    end
    return returnTable
end

local legacyGroups = {
    constructor = {
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
    scout = {
        [[jumpscout]],
        [[shieldscout]],
        [[spiderscout]],
        [[vehscout]],
    },
    raider = {
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
    riot = {
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
    skirm = {
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
        [[vehaa]],
    },
    assault = {
        [[cloakassault]],
        [[hoverassault]],
        [[jumpassault]],
        [[shieldassault]],
        [[spiderassault]],
        [[tankassault]],
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
    bomb = {
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
    bomberLight = {
        [[bomberdisarm]],
        [[bomberheavy]],
        [[bomberprec]],
        [[bomberriot]]
        --TODO add magpie once it settles in/ main doesnt crash anymore
    },
    bomberHeavy = {
        [[bomberheavy]],
        [[bomberassault]],
    },
    gunships = {
        [[gunshipassault]],
        [[gunshipheavyskirm]],
        [[gunshipskirm]],
    },
    transport = {
        [[gunshipheavyskirm]],
        [[gunshiptrans]],
    },
    support = {
        [[planelightscout]],
        [[planescout]],
        [[amphlaunch]],
        [[amphtele]],
        [[athena]],
        [[cloakjammer]],
        [[shieldshield]],
    },
    antiHeavy = {
        [[spiderantiheavy]],
        [[jumpbomb]],
        [[striderantiheavy]],
        [[gunshipemp]],
    },
    striderDemi = {
        [[amphassault]],
        [[jumpsumo]],
        [[spidercrabe]],
        [[tankheavyassault]],
    },
    striderMedium = {
        [[gunshipkrow]],
        [[striderarty]],
        [[striderdante]],
        [[striderfunnelweb]],
        [[striderscorpion]]
    },
    striderHeavy = {
        [[nebula]], --fuck it, nebula
        [[striderbantha]],
        [[striderdetriment]] --TODO figure out where to put this :0
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
    drone = {
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
    
    factory = {
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
    factoryPlate = {
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
    turretLight = {
        [[turretmissile]],
        [[turretlaser]],
    },
    turretRiot = {
        [[turretimpulse]],
        [[turretemp]],
        [[turretriot]],
    },
    turretSkirm = {
        [[turretgauss]],
        [[turretheavylaser]],
    },
    turretsHeavy = 	{
        [[turretantiheavy]],
	    [[turretheavy]]
    },
    turretAntiSub = {
        [[turretgauss]], --Is duplicate
        [[turrettorp]],
    },
    -- Artemis is more a strategic threat than general AA thingy
    turretAALight = {
        [[turretaalaser]],
        [[turretaaclose]],
    },
    turretAAHeavy = {
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
    super = {
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

legacyGroups.turretsAll = Union2({
    legacyGroups.turretLight,
    legacyGroups.turretRiot,
    legacyGroups.turretRiot,
    legacyGroups.turretsHeavy,
    legacyGroups.turretAALight,
    legacyGroups.turretAAHeavy,
})
legacyGroups.allStandardLandCombatants = Union2({
    legacyGroups.scout,
    legacyGroups.raider,
    legacyGroups.riot,
    legacyGroups.skirm,
    legacyGroups.assault,
    legacyGroups.artillery,
    legacyGroups.antiAir,
    legacyGroups.striderDemi,
    legacyGroups.striderMedium,
    legacyGroups.striderHeavy,
})




return classGroupings, sectionGroupings, taggedUnitDefNames , taggedUnitDefIDs