--------------------------------------------------------------------------------
--------------------------------------------------------------------------------

-- note name and description are obtained from server and modified at runtime
ALLOW_SERVER_OVERRIDE_UNIT_TEXT = true

structureConfig = {
	generic_tech = function(unitDef)
			unitDef.maxdamage = 10000
			unitDef.objectname = "pw_techlab.obj"
			unitDef.script = "pw_techlab.lua"
			unitDef.footprintx = 8		
			unitDef.footprintz = 9
			
			unitDef.buildpic = "pw_generic.png"
			
			unitDef.customparams.soundselect = "radar_select"
			unitDef.customparams.helptext = "This structure unlocks a specific tech for its owning faction."
			unitDef.customparams.description_pl = "Stacja badawcza"
			unitDef.customparams.helptext_pl = "Ten budynek odblokowuje konkretna technologie dla swojej frakcji."
		end,

	pw_artefact = function(unitDef)
			unitDef.maxdamage = 100000
			unitDef.name = "Ancient Artefact"
			unitDef.description = "Mysterious Relic"
			unitDef.objectname = "pw_artefact.obj"
			unitDef.script = "pw_artefact.lua"
			
			unitDef.footprintx = 4			
			unitDef.footprintz = 4
			
			unitDef.customparams.soundselect = "cloaker_select"
			unitDef.customparams.helptext = "This mysterious alien device houses unimaginable powers. Although it remains poorly understood by our scientists, "
							.."it could potentially be harnessed as a galaxy-dominating superweapon. The artefact is invulnerable to all known weapons."
			unitDef.customparams.helptext_pl = "Te tajemnicze artefakty obcych skrywaja niesamowita moc. Chociaz naukowcy nie rozumieja do konca zasady ich dzialania, to uwaza sie, "
							.."ze moga posluzyc za bron zdolna do dominacji nad galaktyka. Artefakt jest niewrazliwy na wszystkie znane rodzaje broni."
			unitDef.customparams.description_pl = "Artefakt obcych"
			
			unitDef.collisionvolumescales = [[60 70 60]]
			unitDef.collisionvolumetype	= [[CylY]]			
		end,		
		
	pw_dropfac = function(unitDef)
			unitDef.maxdamage = 25000
			unitDef.name = "Bomber Fabricator"
			unitDef.description = "Produces bombers"
			unitDef.objectname = "pw_dropfac.obj"
			unitDef.selfdestructcountdown = 180
			
			unitDef.footprintx = 20			
			unitDef.footprintz = 16
			
			unitDef.customparams.soundselect = "building_select1"
			unitDef.customparams.helptext = "Produces space bombers for attacking hostile planets."
			unitDef.customparams.helptext_pl = "Produkuje bombowce orbitalne do atakow na wrogie planety."
			unitDef.customparams.description_pl = "Produkuje bombowce."
			
			unitDef.collisionvolumescales = [[275 120 215]]
			unitDef.modelcenteroffset = [[0 00 0]]	
		end,
		
	pw_dropdepot = function(unitDef)
			unitDef.maxdamage = 20000
			unitDef.name = "Fleet Command"
			unitDef.description = "Increases ship capacity"
			unitDef.objectname = "pw_dropdepot.obj"
			unitDef.waterline = 30
			unitDef.selfdestructcountdown = 180
			
			unitDef.footprintx = 16			
			unitDef.footprintz = 11
			
			unitDef.customparams.soundselect = "building_select1"
			unitDef.customparams.helptext = "Increases the number of dropships that can be deployed to a single planet."
			
			unitDef.collisionvolumescales = [[245 220 145]]
			unitDef.modelcenteroffset = [[15 40 0]]			
		end,

	pw_bombercontrol = function(unitDef)
			unitDef.maxdamage = 20000
			unitDef.name = "Bomber Control"
			unitDef.description = "Increases bomber capacity"
			unitDef.objectname = "pw_dropdepot.obj"
			unitDef.waterline = 30
			unitDef.selfdestructcountdown = 180
			
			unitDef.footprintx = 16			
			unitDef.footprintz = 11
			
			unitDef.customparams.soundselect = "building_select1"
			unitDef.customparams.helptext = "Increases the number of bombers that can be deployed to a single planet."
			
			unitDef.collisionvolumescales = [[230 210 130]]
			unitDef.modelcenteroffset = [[15 30 0]]
			
			unitDef.buildpic = "pw_dropdepot.png"
		end,		
				
	pw_mine = function(unitDef)
			unitDef.maxdamage = 10000
			unitDef.name = "Power Generator Unit"
			unitDef.description = "Produces 50 energy/turn" 
			unitDef.objectname = "pw_mine.obj"
			unitDef.script = "pw_mine.lua"
			unitDef.selfdestructcountdown = 60
			
			unitDef.footprintx = 4		
			unitDef.footprintz = 4
			
			unitDef.explodeas = "ESTOR_BUILDING"
			unitDef.selfdestructas = "ESTOR_BUILDING"
			
			unitDef.customparams.soundselect = "building_select2"
			unitDef.customparams.helptext = "A small, efficient power generator."
			unitDef.customparams.helptext_pl = "Maly, efektywny generator planetarny."
			unitDef.customparams.description_pl = "Wytwarza 50 energii/ture"
			
			unitDef.collisionvolumescales = [[56 120 56]]
			unitDef.modelcenteroffset = [[0 10 0]]
			unitDef.collisionvolumetype	= [[CylY]]		
		end,
		
	pw_mine2 = function(unitDef)
			unitDef.maxdamage = 16000
			unitDef.name = "Orbital Solar Array"
			unitDef.description = "Produces 100 energy/turn" 
			unitDef.objectname = "pw_mine2.obj"
			unitDef.script = "pw_mine2.lua"
			
			unitDef.footprintx = 7
			unitDef.footprintz = 7
			
			unitDef.customparams.soundselect = "building_select2"
			unitDef.customparams.helptext = "A larger power generator with increased output."
			unitDef.customparams.helptext_pl = "Sredni generator planetarny."
			unitDef.customparams.description_pl = "Wytwarza 100 energii/ture"
			
			unitDef.collisionvolumescales = [[90 125 90]]
			unitDef.modelcenteroffset = [[0 10 0]]			
		end,
		
	pw_mine3 = function(unitDef)
			unitDef.maxdamage = 24000
			unitDef.name = "Planetary Geothermal Tap"
			unitDef.description = "Produces 250 energy/turn" 
			unitDef.objectname = "pw_mine3.obj"
			unitDef.script = "pw_mine3.lua"
			unitDef.selfdestructcountdown = 240
			
			unitDef.footprintx = 12		
			unitDef.footprintz = 12
			
			unitDef.explodeas = "NUCLEAR_MISSILE"
			unitDef.selfdestructas = "NUCLEAR_MISSILE"
			
			unitDef.customparams.soundselect = "building_select2"
			unitDef.customparams.helptext = "This massive complex draws energy directly from the planet's mantle. It goes up in a nuclear explosion if destroyed."
			unitDef.customparams.helptext_pl = "Planetarny kompleks energetyczny. Uzywa glownie mocy geotermicznych, ale takze nuklearnych, co powoduje niebezpieczenstwo wybuchu w razie zniszczenia."
			unitDef.customparams.description_pl = "Wytwarza 250 energii/ture."
			
			unitDef.collisionvolumescales = [[130 130 130]]
			unitDef.modelcenteroffset = [[0 10 0]]					
		end,
		
	pw_garrison = function(unitDef)
			unitDef.maxdamage = 16000
			unitDef.name = "Field Garrison"
			unitDef.description = "Reduces Influence gain"
			unitDef.objectname = "pw_wormhole.obj"
			unitDef.selfdestructcountdown = 90
			
			unitDef.footprintx = 11
			unitDef.footprintz = 6
			
			unitDef.customparams.soundselect = "factory_select"
			unitDef.customparams.helptext = "This structure maintains an army which reduces the Influence gained from battles."
			unitDef.customparams.helptext_pl = "Garnizon sprawuje piecze nad planeta, ograniczajac wrogie wplywy zyskane z bitew."
			unitDef.customparams.description_pl = "Garnizon - ogranicza wplywy"
			
			unitDef.collisionvolumescales = [[160 65 80]]
			unitDef.modelcenteroffset = [[0 30 0]]					
		end,
		
	pw_interception = function(unitDef)
			unitDef.maxdamage = 16000
			unitDef.name = "Interception Network"
			unitDef.description = "Intercepts approaching bombers"
			unitDef.objectname = "pw_wormhole2.obj"
			
			unitDef.footprintx = 8
			unitDef.footprintz = 8
			
			unitDef.customparams.soundselect = "turret_select"
			unitDef.customparams.helptext = "This structure intercepts incoming bombers."
			unitDef.customparams.helptext_pl = "Ten budynek przechwytuje nadlatujace bombowce orbitalne."
			unitDef.customparams.description_pl = "Przechwytuje bombowce orbitalne."
			
			unitDef.collisionvolumescales = [[100 90 100]]
			unitDef.modelcenteroffset = [[0 20 0]]
			unitDef.collisionvolumetype	= [[CylY]]				
		end,
		
	pw_grid = function(unitDef)
			unitDef.maxdamage = 20000
			unitDef.name = "Planetary Defense Grid"
			unitDef.description = "Defends against everything"
			unitDef.objectname = "pw_warpjammer.s3o"
			unitDef.script = "pw_warpjammer.lua"
			unitDef.selfdestructcountdown = 150
			
			unitDef.footprintx = 6
			unitDef.footprintz = 6
			
			unitDef.customparams.soundselect = "radar_select"
			unitDef.customparams.helptext = "This structure reduces Influence gains as well as intercepting incoming bombers."
			unitDef.customparams.helptext_pl = "Ten budynek zmniejsza wrogie wplywy z bitew i przechwytuje bombowce orbitalne."
			unitDef.customparams.description_pl = "Kompleks ochrony planetarnej"
			
			unitDef.collisionvolumescales = [[100 80 100]]
			unitDef.modelcenteroffset = [[0 0 0]]
			unitDef.collisionvolumetype	= [[Box]]					
		end,
		
	pw_wormhole = function(unitDef)
			unitDef.maxdamage = 12500
			unitDef.name = "Wormhole Generator Beacon"
			unitDef.description = "Links this planet to nearby planets"
			unitDef.objectname = "pw_estorage.obj"
			unitDef.selfdestructcountdown = 90
			
			unitDef.footprintx = 3
			unitDef.footprintz = 3
			
			unitDef.customparams.soundselect = "shield_select"
			unitDef.customparams.helptext = "Allows ships to leave this planet for its connected neighbours, and projects influence spread to connected planets."
			unitDef.customparams.helptext_pl = "Tunel czasoprzestrzenny laczy planete z sasiadami - pozwala statkom orbitalnym opuszczac planete i szerzy wplywy."
			unitDef.customparams.description_pl = "Tunel czasoprzestrzenny"
			
			unitDef.collisionvolumescales = [[40 45 40]]
			unitDef.modelcenteroffset = [[0 0 0]]
			unitDef.collisionvolumetype	= [[CylY]]			
		end,
		
	pw_wormhole2 = function(unitDef)
			unitDef.maxdamage = 17500
			unitDef.name = "Improved Wormhole Stabilizer"
			unitDef.description = "Improved link to nearby planets"
			unitDef.objectname = "pw_estorage2.obj"
			
			unitDef.footprintx = 3
			unitDef.footprintz = 5
			
			unitDef.customparams.soundselect = "shield_select"
			unitDef.customparams.helptext = "This structure maintains a stronger wormhole for increased influence spread to neighboring planets."
			unitDef.customparams.helptext_pl = "Ulepszony tunel czasoprzestrzenny zwieksza wplywy na polaczonych planetach."
			unitDef.customparams.description_pl = "Ulepszony tunel czasoprzestrzenny"
			
			unitDef.collisionvolumescales = [[64 25 45]]
			unitDef.modelcenteroffset = [[0 0 0]]
			unitDef.collisionvolumetype	= [[Box]]				
		end,
		
	pw_warpgate = function(unitDef)
			unitDef.maxdamage = 15000
			unitDef.name = "Warp Core Fabricator"
			unitDef.description = "Produces warp cores"
			unitDef.objectname = "pw_techlab.obj"
			unitDef.script = "pw_techlab.lua"
			unitDef.selfdestructcountdown = 180
			
			unitDef.footprintx = 8		
			unitDef.footprintz = 9
			
			unitDef.customparams.soundselect = "cloaker_select"
			unitDef.customparams.helptext = "This facility produces the coveted Warp Cores that can send ships across the galaxy in the blink of an eye."	
			unitDef.customparams.helptext_pl = "Tutaj produkowane sa Rdzenie Czasoprzestrzenne, ktore pozwalaja wysylac statki w dowolne miejsce w galaktyce w mgnieniu oka."	
			unitDef.customparams.description_pl = "Produkuje Rdzenie Czasoprzestrzenne"				
		end,
		
	pw_warpjammer = function(unitDef)
			unitDef.maxdamage = 12000
			unitDef.name = "Warp Jammer"
			unitDef.description = "Prevents warp attacks"
			unitDef.objectname = "pw_warpgate.obj"
			unitDef.script = "pw_warpgate.lua"
			unitDef.selfdestructcountdown = 150
			
			unitDef.footprintx = 8
			unitDef.footprintz = 8
			
			unitDef.explodeas = "GRAV_BLAST"
			unitDef.selfdestructas = "GRAV_BLAST"
			
			unitDef.customparams.soundselect = "radar_select"
			unitDef.customparams.helptext = "The Warp Jammer protects the planet with a field that prevents warpcore-equipped ships from jumping to it."
			unitDef.customparams.helptext_pl = "Zagluszacz czasoprzestrzenny nie pozwala na skok czasoprzestrzenny przy uzyciu Rdzeni na ta planete."
			unitDef.customparams.description_pl = "Zagluszacz czasoprzestrzenny"
			
			unitDef.collisionvolumescales = [[120 100 120]]
			unitDef.modelcenteroffset = [[0 0 0]]
			unitDef.collisionvolumetype	= [[CylY]]					
		end,
	
	pw_inhibitor = function(unitDef)
			unitDef.maxdamage = 15000
			unitDef.name = "Wormhole Inhibitor"
			unitDef.description = "Wormhole Inhibitor"
			unitDef.objectname = "pw_mstorage2.obj"
			unitDef.selfdestructcountdown = 150
			
			unitDef.footprintx = 7
			unitDef.footprintz = 5
			
			unitDef.customparams.soundselect = "shield_select"
			unitDef.customparams.helptext = "Inhibits Influence spread from enemy planets."
			unitDef.customparams.helptext_pl = "Nie pozwala wrogim planetom szerzyc wplywow przez tunel czasoprzestrzenny."
			unitDef.customparams.description_pl = "Inhibitor tunelu czasoprzestrzennego"
			
			unitDef.collisionvolumescales = [[80 25 60]]
			unitDef.modelcenteroffset = [[0 0 0]]
			unitDef.collisionvolumetype	= [[Box]]					
		end,
	pw_estorage = function(unitDef)
			unitDef.maxdamage = 10000
			unitDef.name = "Energy Storage"
			unitDef.description = "Stores energy"
			unitDef.objectname = "pw_estorage.obj"
			unitDef.selfdestructcountdown = 150
			
			unitDef.footprintx = 3
			unitDef.footprintz = 3
			
			unitDef.customparams.soundselect = "fusion_select"
			unitDef.customparams.helptext = "A large capacitor bank."
			
			unitDef.collisionvolumescales = [[40 45 40]]
			unitDef.modelcenteroffset = [[0 0 0]]
			unitDef.collisionvolumetype	= [[CylY]]					
		end,
	pw_estorage2 = function(unitDef)
			unitDef.maxdamage = 15000
			unitDef.name = "Double Energy Storage"
			unitDef.description = "Stores energy"
			unitDef.objectname = "pw_estorage2.obj"
			unitDef.selfdestructcountdown = 150
			
			unitDef.footprintx = 5
			unitDef.footprintz = 3
			
			unitDef.customparams.soundselect = "fusion_select"
			unitDef.customparams.helptext = "A large double capacitor bank."
			
			unitDef.collisionvolumescales = [[60 45 40]]
			unitDef.modelcenteroffset = [[0 0 0]]
			unitDef.collisionvolumetype	= [[Box]]					
		end,
	pw_guerilla = function(unitDef)
			unitDef.maxdamage = 15000
			unitDef.name = "Guerilla Jumpgate"
			unitDef.description = "Spreads Influence remotely"
			unitDef.objectname = "pw_gaspowerstation.obj"
			unitDef.script = "pw_gaspowerstation.lua"
			unitDef.selfdestructcountdown = 150
			
			unitDef.footprintx = 6
			unitDef.footprintz = 6
			
			unitDef.customparams.soundselect = "shield_select"
			unitDef.customparams.helptext = "A jumpgate capable of sending Influence to any planet."
			unitDef.customparams.helptext_pl = "Ten budynek pozwala szerzyc wplywy na dowolnej innej planecie."
			unitDef.customparams.description_pl = "Zdalnie szerzy wplywy"
			
			unitDef.collisionvolumescales = [[70 60 70]]
			unitDef.modelcenteroffset = [[0 0 0]]
			unitDef.collisionvolumetype	= [[CylY]]					
		end,
}

-- test data here
TEST_DEF_STRING = "ew0KICBzMCA9IHsNCiAgICB1bml0bmFtZSA9ICJwd19nZW5lcmljdGVjaCIsDQogICAgbmFtZSA9ICJUZWNoIEJ1aWxkaW5nIiwNCiAgICBkZXNjcmlwdGlvbiA9ICJQcm9kdWNlcyBSZXNlYXJjaCINCiAgfSwgIA0KICBzMSA9IHsNCiAgICB1bml0bmFtZSA9ICJwd19kcm9wZmFjIiwNCiAgICBuYW1lID0gIlN0YXJzaGlwIEZhY3RvcnkiLA0KICAgIGRlc2NyaXB0aW9uID0gIlByb2R1Y2VzIFNoaXBzIg0KICB9LA0KICBzMiA9IHsNCiAgICB1bml0bmFtZSA9ICJwd19kcm9wZGVwb3QiLA0KICAgIG5hbWUgPSAiRmxlZXQgQ29tbWFuZCIsDQogICAgZGVzY3JpcHRpb24gPSAiSW5jcmVhc2VzIERyb3BzaGlwIENhcCINCiAgfSwNCiAgczMgPSB7DQogICAgdW5pdG5hbWUgPSAicHdfYm9tYmVyY29udHJvbCIsDQogICAgbmFtZSA9ICJCb21iZXIgQ29udHJvbCIsDQogICAgZGVzY3JpcHRpb24gPSAiSW5jcmVhc2VzIEJvbWJlciBDYXAiDQogIH0sDQogIHM0ID0gew0KICAgIHVuaXRuYW1lID0gInB3X3dhcnBnYXRlIiwNCiAgICBuYW1lID0gIldhcnAgQ29yZSBGYWJyaWNhdG9yIiwNCiAgICBkZXNjcmlwdGlvbiA9ICJQcm9kdWNlcyBXYXJwIENvcmVzIg0KICB9LCAgICANCiAgczUgPSB7DQogICAgdW5pdG5hbWUgPSAicHdfd29ybWhvbGUiLA0KICAgIG5hbWUgPSAiV29ybWhvbGUgR2VuZXJhdG9yIiwNCiAgICBkZXNjcmlwdGlvbiA9ICJMaW5rcyBQbGFuZXRzOyBTcHJlYWRzIEluZmx1ZW5jZSINCiAgfSwNCiAgczYgPSB7DQogICAgdW5pdG5hbWUgPSAicHdfd29ybWhvbGUyIiwNCiAgICBuYW1lID0gIkltcHJvdmVkIFdvcm1ob2xlIFN0YWJpbGl6ZXIiLA0KICAgIGRlc2NyaXB0aW9uID0gIkxpbmtzIFBsYW5ldHM7IFNwcmVhZHMgR3JlYXRlciBJbmZsdWVuY2UiDQogIH0sDQogIHM3ID0gew0KICAgIHVuaXRuYW1lID0gInB3X3dhcnBqYW1tZXIiLA0KICAgIG5hbWUgPSAiV2FycCBKYW1tZXIiLA0KICAgIGRlc2NyaXB0aW9uID0gIkJsb2NrcyBXYXJwIEF0dGFja3MiDQogIH0sDQogIHM4ID0gew0KICAgIHVuaXRuYW1lID0gInB3X2dhc3Bvd2Vyc3RhdGlvbiIsDQogICAgbmFtZSA9ICJHYXMgUG93ZXIgU3RhdGlvbiIsDQogICAgZGVzY3JpcHRpb24gPSAiU21hbGwgUG93ZXIgUHJvZHVjZXIiICAgIA0KICB9LA0KICBzMTAgPSB7DQogICAgdW5pdG5hbWUgPSAicHdfbWluZSIsDQogICAgbmFtZSA9ICJQb3dlciBHZW5lcmF0b3IgVW5pdCIsDQogICAgZGVzY3JpcHRpb24gPSAiTGlnaHQgRW5lcmd5IFByb2R1Y2VyIg0KICB9LA0KICBzMTEgPSB7DQogICAgdW5pdG5hbWUgPSAicHdfbWluZTIiLA0KICAgIG5hbWUgPSAiQW5uaWhpbGF0aW9uIFBsYW50IiwNCiAgICBkZXNjcmlwdGlvbiA9ICJNZWRpdW0gRW5lcmd5IFByb2R1Y2VyIg0KICB9LA0KICBzMTIgPSB7DQogICAgdW5pdG5hbWUgPSAicHdfbWluZTMiLA0KICAgIG5hbWUgPSAiUGxhbmV0YXJ5IEdlb3RoZXJtYWwgVGFwIiwNCiAgICBkZXNjcmlwdGlvbiA9ICJIZWF2eSBFbmVyZ3kgUHJvZHVjZXIiDQogIH0sDQogIHMxMyA9IHsNCiAgICB1bml0bmFtZSA9ICJwd19tc3RvcmFnZTIiLA0KICAgIG5hbWUgPSAiRHVhbCBNZXRhbCBTdG9yYWdlIiwNCiAgICBkZXNjcmlwdGlvbiA9ICJTdG9yZXMgTWV0YWwiICAgIA0KICB9LA0KICBzMTQgPSB7DQogICAgdW5pdG5hbWUgPSAicHdfZXN0b3JhZ2UiLA0KICAgIG5hbWUgPSAiRW5lcmd5IFN0b3JhZ2UiLA0KICAgIGRlc2NyaXB0aW9uID0gIlN0b3JlcyBFbmVyZ3kiICAgIA0KICB9LA0KICBzMTUgPSB7DQogICAgdW5pdG5hbWUgPSAicHdfZXN0b3JhZ2UyIiwNCiAgICBuYW1lID0gIkR1YWwgRW5lcmd5IFN0b3JhZ2UiLA0KICAgIGRlc2NyaXB0aW9uID0gIlN0b3JlcyBFbmVyZ3kiICAgIA0KICB9LA0KICBzMTYgPSB7DQogICAgdW5pdG5hbWUgPSAicHdfZ3VlcmlsbGEiLA0KICAgIG5hbWUgPSAiRHVhbCBFbmVyZ3kgU3RvcmFnZSIsDQogICAgZGVzY3JpcHRpb24gPSAiU3RvcmVzIEVuZXJneSIgICAgDQogIH0sDQogIHMxNyA9IHsNCiAgICB1bml0bmFtZSA9ICJwd19pbmhpYml0b3IiLA0KICAgIG5hbWUgPSAiRHVhbCBFbmVyZ3kgU3RvcmFnZSIsDQogICAgZGVzY3JpcHRpb24gPSAiU3RvcmVzIEVuZXJneSIgICAgDQogIH0sDQogIHMxOCA9IHsNCiAgICB1bml0bmFtZSA9ICJwd19ncmlkIiwNCiAgICBuYW1lID0gIkR1YWwgRW5lcmd5IFN0b3JhZ2UiLA0KICAgIGRlc2NyaXB0aW9uID0gIlN0b3JlcyBFbmVyZ3kiICAgIA0KICB9LA0KICBzMTkgPSB7DQogICAgdW5pdG5hbWUgPSAicHdfZ2Fycmlzb24iLA0KICAgIG5hbWUgPSAiRHVhbCBFbmVyZ3kgU3RvcmFnZSIsDQogICAgZGVzY3JpcHRpb24gPSAiU3RvcmVzIEVuZXJneSIgICAgDQogIH0sDQogIHMyMCA9IHsNCiAgICB1bml0bmFtZSA9ICJwd19pbnRlcmNlcHRpb24iLA0KICAgIG5hbWUgPSAiRHVhbCBFbmVyZ3kgU3RvcmFnZSIsDQogICAgZGVzY3JpcHRpb24gPSAiU3RvcmVzIEVuZXJneSIgICAgDQogIH0sDQogIHM5OSA9IHsNCiAgICB1bml0bmFtZSA9ICJwd19hcnRlZmFjdCIsDQogICAgbmFtZSA9ICJBbmNpZW50IEFydGVmYWN0IiwNCiAgICBkZXNjcmlwdGlvbiA9ICJNeXN0ZXJpb3VzIFJlbGljIg0KICB9LCAgDQp9DQo="
--[[
{
  s0 = {
    unitname = "pw_generictech",
    name = "Tech Building",
    description = "Produces Research"
  },  
  s1 = {
    unitname = "pw_dropfac",
    name = "Starship Factory",
    description = "Produces Ships"
  },
  s2 = {
    unitname = "pw_dropdepot",
    name = "Fleet Command",
    description = "Increases Dropship Cap"
  },
  s3 = {
    unitname = "pw_bombercontrol",
    name = "Bomber Control",
    description = "Increases Bomber Cap"
  },
  s4 = {
    unitname = "pw_warpgate",
    name = "Warp Core Fabricator",
    description = "Produces Warp Cores"
  },    
  s5 = {
    unitname = "pw_wormhole",
    name = "Wormhole Generator",
    description = "Links Planets; Spreads Influence"
  },
  s6 = {
    unitname = "pw_wormhole2",
    name = "Improved Wormhole Stabilizer",
    description = "Links Planets; Spreads Greater Influence"
  },
  s7 = {
    unitname = "pw_warpjammer",
    name = "Warp Jammer",
    description = "Blocks Warp Attacks"
  },
  s8 = {
    unitname = "pw_gaspowerstation",
    name = "Gas Power Station",
    description = "Small Power Producer"    
  },
  s10 = {
    unitname = "pw_mine",
    name = "Power Generator Unit",
    description = "Light Energy Producer"
  },
  s11 = {
    unitname = "pw_mine2",
    name = "Annihilation Plant",
    description = "Medium Energy Producer"
  },
  s12 = {
    unitname = "pw_mine3",
    name = "Planetary Geothermal Tap",
    description = "Heavy Energy Producer"
  },
  s13 = {
    unitname = "pw_mstorage2",
    name = "Dual Metal Storage",
    description = "Stores Metal"    
  },
  s14 = {
    unitname = "pw_estorage",
    name = "Energy Storage",
    description = "Stores Energy"    
  },
  s15 = {
    unitname = "pw_estorage2",
    name = "Dual Energy Storage",
    description = "Stores Energy"    
  },
  s16 = {
    unitname = "pw_guerilla",
    name = "Dual Energy Storage",
    description = "Stores Energy"    
  },
  s17 = {
    unitname = "pw_inhibitor",
    name = "Dual Energy Storage",
    description = "Stores Energy"    
  },
  s18 = {
    unitname = "pw_grid",
    name = "Dual Energy Storage",
    description = "Stores Energy"    
  },
  s19 = {
    unitname = "pw_garrison",
    name = "Dual Energy Storage",
    description = "Stores Energy"    
  },
  s20 = {
    unitname = "pw_interception",
    name = "Dual Energy Storage",
    description = "Stores Energy"    
  },
  s99 = {
    unitname = "pw_artefact",
    name = "Ancient Artefact",
    description = "Mysterious Relic"
  },  
}
]]--

