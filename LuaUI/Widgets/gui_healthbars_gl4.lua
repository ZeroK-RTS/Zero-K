function widget:GetInfo()
   return {
      name      = "Health Bars GL4",
      desc      = "Yes this healthbars, just gl4",
      author    = "Beherith",
      date      = "October 2019",
      license   = "GNU GPL, v2 or later for Lua code, (c) Beherith (mysterme@gmail.com) for GLSL",
      layer     = -10,
      enabled   = true
   }
end

options_path = 'Settings/Interface/Healthbars'
options_order = { 'drawFeatureHealth' }
options = {
	drawFeatureHealth = {
                name = 'Draw health of features (corpses)',
                type = 'bool',
                value = false,
                noHotkey = true,
                desc = 'Shows healthbars on corpses',
                OnChange = function()
			initfeaturebars()
		end
        },
}

-- wellity wellity the time has come, and yes, this is design documentation
-- what can we do with 64 verts per healthbars?
	-- 9 verts bg
	-- 9 verts fg
	-- 20 verts for numbers like an asshole
-- fade bars in and out based on last modified times of values?
-- what info do we need outputted from GS?
-- for fg/bg
-- color? is that it?

-- for numbers:
-- uv coords
-- we also need one extra for text - no bueno for translations tho

-- use billboards,
-- THE TYPES OF UNIT BARS:
	-- timer based, all these need a start and (predicted) end time.
		-- EMP time left
			-- 3 floats, start, end, empdamage
			-- needs update on every fucking unitdamaged callin
			-- handle cases where uni is empd outside of view?

		-- reload
			-- 2 floats, lastshot, nextshot
		-- time left in construction
			-- this is a special hybrid bar added on unitcreated, and removed on unitfinished...
			-- 2 floats, buildpct, eta? (eta could get liveupdated cause unitfinished?)
	-- static percentage based:
		-- health --
		-- emp damage
		-- capture
		-- stockpile build progress
		-- shield

-- stuff that needs to occupy a contiguouis stretch in the user uniforms:

--  Spring.GetUnitHealth ( number unitID )
-- return: nil | number health, number maxHealth, number paralyzeDamage, number captureProgress, number buildProgress

-- local shieldOn, shieldPower = GetUnitShieldState(unitID)
-- numStockpiled, numStockpileQued, stockpileBuild = GetUnitStockpile(unitID)
-- local stunned = GetUnitIsStunned(unitID)
-- local _, reloaded, reloadFrame = GetUnitWeaponState(unitID, ci.primaryWeapon)

-- Features can only have: Health, reclaim and resurrectprogress - in fact they should be completely separate bar ids, and all of them are static percentage based
	-- feature resurrect -- this list must be handled in-widget, maintained and updated accordingly for in-los features.
		-- advanced concepts include priority watch lists of features actively being resurrected (or hooking into allowcommand, but that is garbage!)

	-- feature health
	-- feature reclaim
--  AllowFeatureBuildStep() called when wreck is resurrected

-- Spring.GetFeatureHealth ( number featureID )
--return: nil | number health, number maxHealth, number resurrectProgress
--Spring.GetFeatureResources ( number featureID )
--return: nil | number RemainingMetal, number maxMetal, number RemainingEnergy, number maxEnergy, number reclaimLeft, number reclaimTime

-- the vertex shader:
	-- Job of the VS:
		-- read the data and position
		-- identify if the bar needs to be drawn based on :
			-- visibility of unit
			-- distance of bar
			-- value of the bar
		-- the colormap of the bar needs to be interpolated here from a fixed define string?
		--[[ -- https://community.khronos.org/t/constant-vec3-array-no-go/60184/8
			vec3 MyArray[4]=vec3[4](
				vec3(1.5,34.4,3.2),
				vec3(1.6,34.1,1.2),
				vec3(18.981777,6.258294,-27.141813),
				vec3(1.0,3.0,1.0)
			);
		]]--
	--
	-- VS input:
		-- uint barindex
			-- this is the index of how manyeth bar it is in the list, where 0 is always health. and if an additional bar is needed, then increment accordingly
		-- uint bartype
			-- this is for where to get the colortable and 'icon' from
		-- float unitheight
			-- for correct offsetting
		-- uint uniformSSBOloc
			-- this is what uniform offset to read, 0 will be health?
		-- float2 timers
			-- this is for setting the time from which to calculate the timer based bars, set to 0 for no timer, start and end time maybe to calc diff?
		-- uint unitID
			-- or a featureID for features, those will be a separate list, but use hopefully the same shader.
		--
	-- VS output
		-- unit position
		-- bar position
		-- bar 'scale'
		-- bar basecolor
		-- bar colormap vec3[3]
		-- bar value
		-- bar type
		-- bar alpha
		-- corner size

-- Geometry shader:
	-- should only output anything if the bar actually needs to be drawn
-- Job of the geometry shader:
	-- take the VS output params, and create the following bar components:
	-- At furthest detail:
		-- background which is same size as bar
		-- the bar itself
		-- 2*4 vertices
	-- midrange:
		-- a nicer 6 triangle cornered bar background
		-- a cornered bar foreground
		-- 2*8 vertices
	-- closeup:
		-- add the percentage value to the left of the bar
		-- this is 4*4 vertices
	-- full closeness
		-- also write the 'name' of the bar type
	-- GS output per vertex:
		-- position on screen
		-- Z depth (somehow with emission ordering from back to front?
		-- UV coordinates -- this could get nasty quickly
		-- vertex color
		-- solid or textured

-- Fragment shader:
	-- if solid, interpolate vertex color, and straight up draw it
	-- if uv mapped, sample the texture and draw it

-- atlas plans:
	-- 512 x 512 atlas
	-- 16 rows in it
	-- each number from 0 to 9, '.' % and space (the 15th.) 's', ':'
	-- the text?
	-- overlay textures for bars
	-- symbol glyphs

-- TODO
-- 1. enemy paralyzed is not visible?
-- enemy comms and fusions health? hide the ones which should be hidden!
-- check for invalidness on addbars -- dont
-- better maintenance of bartypes and watch lists
-- feature bars fade out faster -- done
-- CLOAKED UNITSES -- done
-- Healthbars color correction -- done
-- Hide buildbars when at full hp - or convert them to build bars? -- done
-- todo some tex filtering issues on healthbar tops and bottoms :/  -- done
-- TODO: some GAIA shit? -- done
-- TODO: enemy comms and fus and decoy fus should not get healthbars! -- done
-- TODO: allies dont get reload bars? Do Specs see them? -- done (it was f'ed up previously)
-- TODO: correct draw order (after highlightunit) -- done
-- TODO: when reiniting feature bars, also check for resurrect/reclaim status -- done, just dont reinit them on playerchanged, no point!
	-- now this is problematic, as the gadget only sends us an event on first reclaim event
	-- we must assume that all features
	-- feature bars dont actually need a reinit, now do they?
-- TODO: make numbers, glyphs optional? -- done, but untested

--/luarules fightertest corak armpw 100 10 2000

local drawWhenGuiHidden = false

local healthbartexture = "LuaUI/Images/healthbars.png"

-- a little explanation for 'bartype'
-- 0: default percentage progress bar
-- 1: timer based full textured bar, with time left being read from unitformindex
-- 2: timer based progress bar, with start and end times reading time left from uniformindex, uniformindex + 1 and timeInfo.x
-- 3: default percentage bar with overlayed texture progression
-- 5: The stockpile bar, nasty as hell but whatevs, it

-- TODO: should be a freaking bitmask instead
-- bit 0: use overlay texture false/true
-- bit 1: show glyph icon
-- bit 2: use percentage style display
-- bit 3: use timeleft style display    (2 and 3 mutually exclusive!)
-- bit 4: use integernumber style display (stockpile)
-- bit 5: get progress from nowtime-uniform2 / (uniform3 - uniform2)
-- bit 6: flash bar at 1hz
local bitUseOverlay = 1
local bitShowGlyph = 2
local bitPercentage = 4
local bitTimeLeft = 8
local bitIntegerNumber = 16
local bitInverse = 32
local bitFrameTime = 64
local bitColorCorrect = 128


local includeDir = "LuaUI/Widgets/Include/"
VFS.Include(includeDir.."gl_uniform_channels.lua")

--[[
local healthChannel = 20 -- if its =20, then its health/maxhealth
local buildChannel = 1
local morphChannel = 10
local paralyzeChannel = 2
local disarmChannel = 3
local slowChannel = 4
local reloadChannel = 5
local dgunChannel = 6
local teleportChannel = 7
local heatChannel = 7
local speedChannel = 7
local reammoChannel = 7
local gooChannel = 7
local jumpChannel = 7
local captureReloadChannel = 7
local abilityChannel = 7
local stockpileChannel = 7
local shieldChannel = 8
local captureChannel = 9
local reclaimChannel = 3
local resurrectChannel = 2
--]]
local barTypeMap = {
	health = {
		mincolor = {1.0, 0.0, 0.0, 1.0},
		maxcolor = {0.0, 1.0, 0.0, 1.0},
		bartype = bitPercentage + bitColorCorrect + bitInverse,
		hidethreshold = 0.99,
		uniformindex = unitHealthChannel,
		uvoffset = 18,
	},
	paralyze = {
		mincolor = {0.6, 0.6, 1.0, 1.0},
		maxcolor = {0.6, 0.6, 1.0, 1.0},
		bartype = bitShowGlyph + bitUseOverlay + bitPercentage,
		hidethreshold = 1.99,
		uniformindex = unitParalyzeChannel,
		uvoffset = 19,
	},
	build = {
		mincolor = {1.0, 1.0, 1.0, 1.0},
		maxcolor = {1.0, 1.0, 1.0, 1.0},
		bartype = bitShowGlyph + bitUseOverlay + bitPercentage + bitInverse,
		hidethreshold = 0.999,
		uniformindex = unitBuildChannel,
		uvoffset = 2,
	},
	morph = {
		mincolor = {0.0, 0.0, 0.0, 0.0},
		maxcolor = {0.0, 0.0, 0.0, 0.0},
		bartype = bitPercentage + bitColorCorrect,
		hidethreshold = 0.99,
		uniformindex = unitMorphChannel,
		uvoffset = 20,
	},
	disarm = {
		mincolor = {0.4, 0.4, 0.8, 1.0},
		maxcolor = {0.6, 0.6, 1.0, 1.0},
		bartype = bitShowGlyph + bitUseOverlay + bitPercentage,
		hidethreshold = 0.99,
		uniformindex = unitDisarmChannel,
		uvoffset = 15,
	},
	slow = {
		mincolor = {0.0, 0.0, 0.0, 0.0},
		maxcolor = {0.0, 0.0, 0.0, 0.0},
		bartype = bitPercentage + bitColorCorrect,
		hidethreshold = 0.99,
		uniformindex = unitSlowChannel,
		uvoffset = 16,
	},
	reload = {
		mincolor = {0.03, 0.4, 0.4, 1.0},
		maxcolor = {0.05, 0.6, 0.6, 1.0},
		bartype = bitShowGlyph + bitUseOverlay + bitPercentage + bitFrameTime + bitInverse,
		hidethreshold = 0.99,
		uniformindex = unitReloadChannel,
		uvoffset = 21,
	},
	dgun = {
		mincolor = {1.0, 1.0, 1.0, 1.0},
		maxcolor = {1.0, 1.0, 1.0, 1.0},
		bartype = bitFrameTime + bitInverse,
		hidethreshold = 0.99,
		uniformindex = unitDgunChannel,
		uvoffset = 17,
	},
	teleport = {
		mincolor = {0.0, 0.0, 0.0, 0.0},
		maxcolor = {0.0, 0.0, 0.0, 0.0},
		bartype = bitPercentage + bitColorCorrect,
		hidethreshold = 0.99,
		uniformindex = unitTeleportChannel,
		uvoffset = 12,
	},
	heat = {
		mincolor = {0.0, 0.0, 0.0, 0.0},
		maxcolor = {0.0, 0.0, 0.0, 0.0},
		bartype = bitPercentage + bitColorCorrect,
		hidethreshold = 0.99,
		uniformindex = unitHeatChannel,
		uvoffset = 13,
	},
	speed = {
		mincolor = {0.0, 0.0, 0.0, 0.0},
		maxcolor = {0.0, 0.0, 0.0, 0.0},
		bartype = bitPercentage + bitColorCorrect,
		hidethreshold = 0.99,
		uniformindex = unitSpeedChannel,
		uvoffset = 14,
	},
	reammo = {
		mincolor = {0.0, 0.0, 0.0, 0.0},
		maxcolor = {0.0, 0.0, 0.0, 0.0},
		bartype = bitPercentage + bitColorCorrect,
		hidethreshold = 0.99,
		uniformindex = unitReammoChannel,
		uvoffset = 9,
	},
	goo = {
		mincolor = {0.0, 0.0, 0.0, 0.0},
		maxcolor = {0.0, 0.0, 0.0, 0.0},
		bartype = bitPercentage + bitColorCorrect,
		hidethreshold = 0.99,
		uniformindex = unitGooChannel,
		uvoffset = 10,
	},
	jump = {
		mincolor = {0.0, 0.0, 0.0, 0.0},
		maxcolor = {0.0, 0.0, 0.0, 0.0},
		bartype = bitPercentage + bitColorCorrect,
		hidethreshold = 0.99,
		uniformindex = unitJumpChannel,
		uvoffset = 11,
	},
	captureReload = {
		mincolor = {0.0, 0.0, 0.0, 0.0},
		maxcolor = {0.0, 0.0, 0.0, 0.0},
		bartype = bitPercentage + bitFrameTime + bitInverse,
		hidethreshold = 0.99,
		uniformindex = unitCaptureReloadChannel,
		uvoffset = 6,
	},
	ability = {
		mincolor = {0.0, 0.0, 0.0, 0.0},
		maxcolor = {0.0, 0.0, 0.0, 0.0},
		bartype = bitPercentage + bitColorCorrect + bitInverse,
		hidethreshold = 0.99,
		uniformindex = unitAbilityChannel,
		uvoffset = 7,
	},
	stockpile = {
		mincolor = {0.1, 0.1, 0.1, 1.0},
		maxcolor = {0.1, 0.1, 0.1, 1.0},
		bartype = bitShowGlyph + bitUseOverlay + bitPercentage, --bitIntegerNumber,
		hidethreshold = 1.99,
		uniformindex = unitStockpileChannel,
		uvoffset = 8,
	},
	shield = {
		mincolor = {0.15, 0.4, 0.4, 1.0},
		maxcolor = {0.3, 0.8, 0.8, 1.0},
		bartype = bitShowGlyph + bitUseOverlay + bitPercentage,
		hidethreshold = 0.99,
		uniformindex = unitShieldChannel,
		uvoffset = 1,
	},
	capture = {
		mincolor = {0.5, 0.25, 0.0, 1.0},
		maxcolor = {1.0, 0.5, 0.0, 1.0},
		bartype = bitShowGlyph + bitUseOverlay + bitPercentage,
		hidethreshold = 0.99,
		uniformindex = unitCaptureChannel,
		uvoffset = 0,
	},
	featurehealth = {
		mincolor = {0.25, 0.25, 0.25, 1.0},
		maxcolor = {0.65, 0.65, 0.65, 1.0},
		bartype = bitShowGlyph + bitPercentage,
		hidethreshold = 0.99,
		uniformindex = unitHealthChannel,
		uvoffset = 18,
	},
	featurereclaim = {
		mincolor = {0.00, 1.00, 0.00, 1.0},
		maxcolor = {0.85, 1.00, 0.85, 1.0},
		bartype = bitShowGlyph + bitPercentage,
		hidethreshold = 0.99,
		uniformindex = reclaimChannel,
		uvoffset = 4,
	},
	featureresurrect = {
		mincolor = {0.75, 0.15, 0.75, 1.0},
		maxcolor = {1.0, 0.2, 1.0, 1.0},
		bartype = bitShowGlyph + bitPercentage,
		hidethreshold = 0.99,
		uniformindex = resurrectChannel,
		uvoffset = 5,
	},
}

for barname, bt in pairs(barTypeMap) do
	local cache = {}
	for i=1,20 do cache[i] = 0 end
	
	--cache[1] = unitDefHeights[unitDefID] + additionalheightaboveunit * effectiveScale  -- height
	--cache[2] = sizeModifier
	cache[3] = 1 -- range 
	cache[4] = tonumber(bt.uvoffset) -- glyph uv offset

	cache[5] = bt.bartype -- bartype int
	--cache[6] = 0.0 -- unused
	cache[7] = bt.uniformindex -- ssbo location offset (> 20 for health)
	--cache[8] = 0.0 -- unused

	cache[9]  = bt.mincolor[1]
	cache[10] = bt.mincolor[2]
	cache[11] = bt.mincolor[3]
	cache[12] = bt.mincolor[4]

	cache[13] = bt.maxcolor[1]
	cache[14] = bt.maxcolor[2]
	cache[15] = bt.maxcolor[3]
	cache[16] = bt.maxcolor[4]
	
	bt['cache'] = cache
end

--------------------------------------------------------------------------------
--------------------------------------------------------------------------------

local GetUnitIsStunned     = Spring.GetUnitIsStunned
local GetUnitHealth        = Spring.GetUnitHealth
local GetUnitWeaponState   = Spring.GetUnitWeaponState
local GetUnitShieldState   = Spring.GetUnitShieldState
--local GetUnitViewPosition  = Spring.GetUnitViewPosition
local GetUnitStockpile     = Spring.GetUnitStockpile
local GetUnitRulesParam    = Spring.GetUnitRulesParam


local spec, fullview = Spring.GetSpectatingState()
local myTeamID = Spring.GetMyTeamID()
local myAllyTeamID = Spring.GetMyAllyTeamID()
local myPlayerID = Spring.GetMyPlayerID()
local gameSpeed = Game.gameSpeed

local chobbyInterface

local unitDefIgnore = {} -- commanders!
local unitDefHasShield = {} -- value is shield max power
local unitDefCanStockpile = {} -- 0/1?
local unitDefPrimaryReload = {} -- value is max reload time
local unitDefHeights = {} -- maps unitDefs to height
local unitDefPrimaryWeapon = {} -- the index for reloadable weapon on unitdef weapons
local unitDefHasAbility = {}
local unitDefScriptReload = {}
local unitDefDgun = {}
local unitDefDgunReload = {}
local unitDefHasGoo = {}
local unitDefHasJump = {}
local unitDefHasHeat = {}
local unitDefHasSpeed = {}
local unitDefHasReammo = {}
local unitDefHasCaptureReload = {}
local unitDefHasTeleport = {}

local unitHealthWatch = {}
local unitBuildWatch = {}
local unitMorphWatch = {}
local unitParalyzeWatch = {}
local unitDisarmWatch = {}
local unitSlowWatch = {}
local unitReloadWatch = {}
local unitDgunWatch = {}
local unitTeleportWatch = {}
local unitHeatWatch = {}
local unitSpeedWatch = {}
local unitReammoWatch = {}
local unitScriptReloadWatch = {}
local unitGooWatch = {}
local unitJumpWatch = {}
local unitCaptureReloadWatch = {}
local unitAbilityWatch = {}
local unitStockpileWatch = {}
local unitShieldWatch = {} -- works
local unitCaptureWatch = {}

local featureDefHeights = {} -- maps FeatureDefs to height

local empDecline = 1 / Game.paralyzeDeclineRate
local minReloadTime = 4 -- weapons reloading slower than this willget bars

local featureVBO

local barScale = 1 -- Option 'healthbarsscale'
local variableBarSizes = true -- Option 'healthbarsvariable'

--local resurrectableFeaturesFast = {} -- value is  this is for keeping an eye on resurrectable features, maybe store resurrect progress here?
--local resurrectableFeaturesSlow = {} -- this is for keeping an eye on resurrectable features, maybe store resurrect progress here?
--local reclaimableFeaturesSlow = {} -- for faster updates of features being reclaimed/rezzed
--local reclaimableFeaturesFast = {} -- for faster updates of features being reclaimed/rezzed

--------------------------------------------------------------------------------
-- GL4 Backend stuff:
local healthBarVBO = nil
local healthBarShader = nil

local luaShaderDir = "LuaUI/Widgets/Include/"
local LuaShader = VFS.Include(luaShaderDir.."LuaShader.lua")
VFS.Include(luaShaderDir.."instancevbotable.lua")

-------------------- configurables -----------------------
local additionalheightaboveunit = 24 --16?
local featureHealthDistMult = 7 -- how many times closer features have to be for their bars to show
local featureReclaimDistMult = 2 -- how many times closer features have to be for their bars to show
local featureResurrectDistMult = 1 -- how many times closer features have to be for their bars to show
local glphydistmult = 3.5 -- how much closer than BARFADEEND the bar has to be to start drawing numbers/icons. Numbers closer to 1 will make the glyphs be drawn earlier, high numbers will only shows glyphs when zoomed in hard.
local glyphdistmultfeatures = 1.8 -- how much closer than BARFADEEND the bar has to be to start drawing numbers/icons

local unitDefSizeMultipliers = {} -- table of unitdefID to a size mult (default 1.0) to override sizing of bars per unitdef
local skipGlyphsNumbers = 0.0  -- 0.0 is draw glyph and number,  1.0 means only numbers, 2.0 means only bars,

local debugmode = false

local barHeight = 0.9
local shaderConfig = { -- these are our shader defines
	HEIGHTOFFSET = 3, -- Additional height added to everything
	CLIPTOLERANCE = 1.1, -- At 1.0 it wont draw at units just outside of view (may pop in), 1.1 is a good safe amount
	MAXVERTICES = 64, -- The max number of vertices we can emit, make sure this is consistent with what you are trying to draw (tris 3, quads 4, corneredrect 8, circle 64
	CLIPTOLERANCE = 1.2,
	BARWIDTH = 2.56,
	BARHEIGHT = barHeight,
	BGBOTTOMCOLOR = "vec4(0.25, 0.25, 0.25, 0.8)",
	BGTOPCOLOR = "vec4(0.1, 0.1, 0.1, 0.8)",
	BARSCALE = 4.0,
	PERCENT_VISIBILITY_MAX = 0.99,
	TIMER_VISIBILITY_MIN = 0.0,
	BARSTEP = 10, -- pixels to downshift per new bar
	BOTTOMDARKENFACTOR = 0.5,
	BARFADESTART = 3200,
	BARFADEEND = 3800,
	ATLASSTEPY = 0.03125,
	ATLASSTEPX = 0.0625,
	MINALPHA = 0.2,
}
shaderConfig.BARCORNER = 0.06 + (shaderConfig.BARHEIGHT / 9)
shaderConfig.SMALLERCORNER = shaderConfig.BARCORNER * 0.6

if debugmode then
	shaderConfig.DEBUGSHOW = 1 -- comment this to always show all bars
end

local vsSrcPath = "LuaUI/Widgets/Shaders/HealthbarsGL4.vert.glsl"
local gsSrcPath = "LuaUI/Widgets/Shaders/HealthbarsGL4.geom.glsl"
local fsSrcPath = "LuaUI/Widgets/Shaders/HealthbarsGL4.frag.glsl"

local shaderSourceCache = {
		vssrcpath = vsSrcPath,
		fssrcpath = fsSrcPath,
		gssrcpath = gsSrcPath,
		shaderName = "Health Bars Shader GL4",
		uniformInt = {
			healthbartexture = 0;
			},
		uniformFloat = {
			--addRadius = 1,
			iconDistance = 27,
			cameraDistanceMult = 1.0,
			cameraDistanceMultGlyph = 4.0,
			skipGlyphsNumbers = 0.0,
			globalSizeMult = 1.0,
		  },
		shaderConfig = shaderConfig,
	}

-- Walk through unitdefs for the stuff we need:
for udefID, unitDef in pairs(UnitDefs) do
	if unitDef.customParams and unitDef.customParams.nohealthbars then
		unitDefIgnore[udefID] = true
	end --ignore debug units

	-- SHIELDS
	local shieldDefID = unitDef.shieldWeaponDef
	local shieldPower = ((shieldDefID) and (WeaponDefs[shieldDefID].shieldPower)) or (-1)
	if shieldPower > 1 then unitDefHasShield[udefID] = shieldPower
		--Spring.Echo("HAS SHIELD")
	end

	local primaryReloadTime = minReloadTime

	local isDynamic = false

	if unitDef.customParams and unitDef.customParams.dynamic_comm then
		isDynamic = true
	end

	if not isDynamic then -- TODO if isDynamic then return end
		local weapons = unitDef.weapons

		for i = 1, #weapons do
			local WeaponDef = WeaponDefs[weapons[i].weaponDef]

			if not WeaponDef then

			-- DGUN
			elseif WeaponDef.manualFire then 
				unitDefDgun[udefID] = i
				unitDefDgunReload[udefID] = WeaponDef.reload

			-- CAPTURE RELOAD
			elseif WeaponDef.customParams and WeaponDef.customParams.post_capture_reload then
				unitDefHasCaptureReload[udefID] = tonumber(WeaponDef.customParams.post_capture_reload)

			-- RELOAD
			elseif WeaponDef.reload and WeaponDef.reload >= primaryReloadTime then
				primaryReloadTime = WeaponDef.reload
				unitDefPrimaryReload[udefID] = primaryReloadTime
				unitDefPrimaryWeapon[udefID] = i
			end
		end

                -- SPECIAL ABILITY
		if unitDef.customParams and unitDef.customParams.specialreloadtime then
			unitDefHasAbility[udefID] = unitDef.customParams.specialreloadtime
		end

		-- SCRIPT RELOAD
		if unitDef.customParams and unitDef.customParams.script_reload then
			unitDefScriptReload[udefID] = tonumber(unitDef.customParams.script_reload) * gameSpeed
		end

		-- GOO
		if unitDef.customParams and unitDef.customParams.grey_goo then
			unitDefHasGoo[udefID] = 1
		end

		-- HEAT
		if unitDef.customParams and unitDef.customParams.heat_initial then
			unitDefHasHeat[udefID] = 1
		end

		-- SPEED
		if unitDef.customParams and unitDef.customParams.speed_bar then
			unitDefHasSpeed[udefID] = 1
		end

		-- REAMMO
		if unitDef.customParams and unitDef.customParams.reammoseconds then
			unitDefHasReammo[udefID] = 1
		end

		-- STOCKPILE
		if unitDef.canStockpile then
			unitDefCanStockpile[udefID] = unitDef.canStockpile
		end
		
		-- TELEPORT
		if unitDef.customParams and (unitDef.customParams.teleporter_throughput or unitDef.customParams.teleporter_is_beacon) then
			unitDefHasTeleport[udefID] = 1
		end
	end

	-- JUMP
	if unitDef.customParams and unitDef.customParams.canjump then
		unitDefHasJump[udefID] = 1
	end

	-- BAR PLACEMENT
	unitDefHeights[udefID] = unitDef.height
	unitDefSizeMultipliers[udefID] = math.min(1.45, math.max(0.85, (Spring.GetUnitDefDimensions(udefID).radius / 150) + math.min(0.6, unitDef.power / 4000))) + math.min(0.6, unitDef.health / 22000)
end

for fdefID, featureDef in pairs(FeatureDefs) do
	--Spring.Echo(featureDef.name, featureDef.height)
	featureDefHeights[fdefID] = featureDef.height or 32
end

local function goodbye(reason)
  Spring.Echo("Healthbars GL4 widget exiting with reason: "..reason)
  widgetHandler:RemoveWidget()
end

local function initializeInstanceVBOTable(myName, usesFeatures)
	local newVBOTable
	newVBOTable = makeInstanceVBOTable(
		{
			{id = 0, name = 'height_timers', size = 4},
			{id = 1, name = 'type_index_ssboloc', size = 4, type = GL.UNSIGNED_INT},
			{id = 2, name = 'startcolor', size = 4},
			{id = 3, name = 'endcolor', size = 4},
			{id = 4, name = 'instData', size = 4, type = GL.UNSIGNED_INT},
		},
		256, -- maxelements
		myName, -- name
		4 -- unitIDattribID (instData)
	)
	if newVBOTable == nil then goodbye("Failed to create " .. myName) end

	local newVAO = gl.GetVAO()
	newVAO:AttachVertexBuffer(newVBOTable.instanceVBO)
	newVBOTable.VAO = newVAO
	if usesFeatures then newVBOTable.featureIDs = true end
	return newVBOTable
end

local function initGL4()
	healthBarShader =  LuaShader.CheckShaderUpdates(shaderSourceCache)

	if not healthBarShader then goodbye("Failed to compile health bars GL4 ") end

	healthBarVBO = initializeInstanceVBOTable("healthBarVBO", false)
	featureVBO = initializeInstanceVBOTable("featureVBO", true)

	if debugmode then
		healthBarVBO.debug = true
	end
end

--------------------------------------------------------------------------------
--------------------------------------------------------------------------------

local uniformcache = {0.0}

local function addBarForUnit(unitID, unitDefID, barname, reason, range)
	unitDefID = unitDefID or Spring.GetUnitDefID(unitID)

	-- Why? Because adding additional bars can be triggered from outside of unit tracker api
	-- like EMP, where we assume that unit is already visible, however
	-- debug units are not present in unittracker api!
	if (unitDefID == nil) or unitDefIgnore[unitDefID] then return nil end

	local gf = Spring.GetGameFrame()
	local bt = barTypeMap[barname]
	if bt == nil then Spring.Echo(barname) end
	local instanceID = unitID .. '_' .. barname

	if healthBarVBO.instanceIDtoIndex[instanceID] then
		if debugmode then Spring.Echo("Trying to add duplicate bar", unitID, instanceID, barname, reason) end
		return
	end -- we already have this bar !

	if unitDefID == nil or Spring.ValidUnitID(unitID) == false or Spring.GetUnitIsDead(unitID) == true then -- dead or invalid
		if debugmode then
			Spring.Debug.TraceEcho("Tried to add a bar to dead/invalid/nounitdef unit", unitID, unitdefID, barname)
		end
		return nil
	end

	local effectiveScale = ((variableBarSizes and unitDefSizeMultipliers[unitDefID]) or 1.0) * barScale
	
	local healthBarTableCache = bt.cache

	healthBarTableCache[1] = unitDefHeights[unitDefID] + additionalheightaboveunit * effectiveScale  -- height
	healthBarTableCache[2] = effectiveScale
	healthBarTableCache[3] = range or 1
	
	return pushElementInstance(
		healthBarVBO, -- push into this Instance VBO Table
		healthBarTableCache,
		instanceID, -- this is the key inside the VBO Table, should be unique per unit
		true, -- update existing element
		nil, -- noupload, dont use unless you know what you want to batch push/pop
		unitID) -- last one should be featureID!
		-- we are returning here, to sign successful adds
end

local function removeBarFromUnit(unitID, barname, reason) -- this will bite me in the ass later, im sure, yes it did, we need to just update them :P
	local instanceKey = unitID .. "_" .. barname
	if healthBarVBO.instanceIDtoIndex[instanceKey] then
		if debugmode then Spring.Debug.TraceEcho(reason) end
		--if barname == 'emp_damage' or barname == 'paralyze' then
			-- dont decrease counter for these
		--else
		--end
		popElementInstance(healthBarVBO, instanceKey)
	end
end

local function addBarsForUnit(unitID, unitDefID, unitTeam, unitAllyTeam, reason) -- TODO, actually, we need to check for all of these for stuff entering LOS

	if unitDefID == nil or Spring.ValidUnitID(unitID) == false or Spring.GetUnitIsDead(unitID) == true then
		if debugmode then Spring.Echo("Tried to add a bar to a dead or invalid unit", unitID, "at", Spring.GetUnitPosition(unitID), reason) end
		return
	end

	uniformcache[1] = 0
	for channels = 0, 15, 1 do
		gl.SetUnitBufferUniforms(unitID, uniformcache, channels)
	end

	-- This is optionally passed, and it only important in one edge case:
	-- If a unit is captured and thus immediately become outside of LOS, then the getunitallyteam is still the old ally team according to getUnitAllyTEam, and not the new allyteam.
	unitAllyTeam = unitAllyTeam or Spring.GetUnitAllyTeam(unitID)

	addBarForUnit(unitID, unitDefID, "health", reason)
	unitHealthWatch[unitID] = -1

	addBarForUnit(unitID, unitDefID, "build", reason)
	unitBuildWatch[unitID] = -1

	addBarForUnit(unitID, unitDefID, "paralyze", reason)
	unitParalyzeWatch[unitID] = -1

	addBarForUnit(unitID, unitDefID, "disarm", reason)
	unitDisarmWatch[unitID] = -1

	addBarForUnit(unitID, unitDefID, "slow", reason)
	unitSlowWatch[unitID] = -1

	if unitDefDgun[unitDefID] then
		addBarForUnit(unitID, unitDefID, "dgun", reason, unitDefDgunReload[unitDefID] * gameSpeed)
		unitDgunWatch[unitID] = -1
	end

	--[[
	addBarForUnit(unitID, unitDefID, "teleport", reason)
	unitTeleportWatch[unitID] = -1

	addBarForUnit(unitID, unitDefID, "ability", reason)
	unitAbilityWatch[unitID] = -1

	addBarForUnit(unitID, unitDefID, "stockpile", reason)
	unitStockpileWatch[unitID] = -1
	]]--

	if unitDefHasShield[unitDefID] then
		addBarForUnit(unitID, unitDefID, "shield", reason)
		unitShieldWatch[unitID] = -1.0
	end

	if unitDefPrimaryWeapon[unitDefID] then
	        local reloadTime = unitDefPrimaryReload[unitDefID]
		addBarForUnit(unitID, unitDefID, "reload", reason, reloadTime * gameSpeed)
		unitReloadWatch[unitID] = -1.0
	end
--[[
	local unitDef = UnitDefs[unitDefID]
	if unitDef.customParams and unitDef.customParams.dynamic_comm then
		addBarForUnit(unitID, unitDefID, "reload", reason)
		unitReloadWatch[unitID] = -1.0
	end
	--]]

	if unitDefHasAbility[unitDefID] then
		addBarForUnit(unitID, unitDefID, "ability", reason)
		unitAbilityWatch[unitID] = -1.0
	end
	
	if unitDefScriptReload[unitDefID] then
		local reloadTime = unitDefScriptReload[unitDefID]
		addBarForUnit(unitID, unitDefID, "reload", reason, reloadTime)
		unitScriptReloadWatch[unitID] = -1.0
	end
	
	if unitDefHasGoo[unitDefID] then
		addBarForUnit(unitID, unitDefID, "goo", reason)
		unitGooWatch[unitID] = -1.0
	end

	if unitDefHasJump[unitDefID] then
		addBarForUnit(unitID, unitDefID, "jump", reason)
		unitJumpWatch[unitID] = -1.0
	end

	if unitDefHasHeat[unitDefID] then
		addBarForUnit(unitID, unitDefID, "heat", reason)
		unitHeatWatch[unitID] = -1.0
	end

	if unitDefHasSpeed[unitDefID] then
		addBarForUnit(unitID, unitDefID, "speed", reason)
		unitSpeedWatch[unitID] = -1.0
	end

	if unitDefHasReammo[unitDefID] then
		addBarForUnit(unitID, unitDefID, "reammo", reason)
		unitReammoWatch[unitID] = -1.0
	end

	if unitDefCanStockpile[unitDefID] then
		addBarForUnit(unitID, unitDefID, "stockpile", reason)
		unitStockpileWatch[unitID] = -1.0
	end

	if unitDefHasCaptureReload[unitDefID] then
		addBarForUnit(unitID, unitDefID, "captureReload", reason, unitDefHasCaptureReload[unitDefID])
		unitCaptureReloadWatch[unitID] = -1.0
	end

	if unitDefHasTeleport[unitDefID] then
		addBarForUnit(unitID, unitDefID, "teleport", reason)
		unitTeleportWatch[unitID] = -1.0
	end

	addBarForUnit(unitID, unitDefID, "capture", reason)
	unitCaptureWatch[unitID] = -1
end

local function removeBarsFromUnit(unitID, reason)
	for barname,v in pairs(barTypeMap) do
		removeBarFromUnit(unitID, barname, reason)
	end
	unitHealthWatch[unitID] = nil
	unitBuildWatch[unitID] = nil
	unitMorphWatch[unitID] = nil
	unitParalyzeWatch[unitID] = nil
	unitDisarmWatch[unitID] = nil
	unitSlowWatch[unitID] = nil
	unitReloadWatch[unitID] = nil
	unitDgunWatch[unitID] = nil
	unitTeleportWatch[unitID] = nil
	unitHeatWatch[unitID] = nil
	unitSpeedWatch[unitID] = nil
	unitReammoWatch[unitID] = nil
	unitScriptReloadWatch[unitID] = nil
	unitGooWatch[unitID] = nil
	unitJumpWatch[unitID] = nil
	unitCaptureReloadWatch[unitID] = nil
	unitAbilityWatch[unitID] = nil
	unitStockpileWatch[unitID] = nil
	unitShieldWatch[unitID] = nil
	unitCaptureWatch[unitID] = nil
end

local function addBarToFeature(featureID, barname)
	if debugmode then Spring.Debug.TraceEcho() end
	local featureDefID = Spring.GetFeatureDefID(featureID)

	local bt = barTypeMap[barname]

	if featureVBO.instanceIDtoIndex[featureID] then return end -- already exists, bail

	pushElementInstance(
		featureVBO, -- push into this Instance VBO Table
			{featureDefHeights[featureDefID] + additionalheightaboveunit,  -- height
			1.0 * barScale, -- size mult
			1.0, -- timer end
			bt.uvoffset, -- unused float

			bt.bartype, -- bartype int
			0, -- bar index (how manyeth per unit)
			bt.uniformindex, -- ssbo location offset (> 20 for health)
			0, -- unused int

			bt.mincolor[1], bt.mincolor[2], bt.mincolor[3], bt.mincolor[4],
			bt.maxcolor[1], bt.maxcolor[2], bt.maxcolor[3], bt.maxcolor[4],
			0, 0, 0, 0}, -- these are just padding zeros for instData, that will get filled in
		featureID .. "_" .. barname, -- this is the key inside the VBO Table, should be unique per unit
		true, -- update existing element
		nil, -- noupload, dont use unless you know what you want to batch push/pop
		featureID) -- last one should be featureID!
end

local function removeBarFromFeature(featureID, barname)
	local instanceKey = featureID .. "_" .. barname
	if featureVBO.instanceIDtoIndex[instanceKey] then
		popElementInstance(featureVBO, instanceKey)
	end
end

local function init()
	clearInstanceTable(healthBarVBO)
	unitHealthWatch = {}
	unitBuildWatch = {}
	unitMorphWatch = {}
	unitParalyzeWatch = {}
	unitDisarmWatch = {}
	unitSlowWatch = {}
	unitReloadWatch = {}
	unitDgunWatch = {}
	unitTeleportWatch = {}
	unitHeatWatch = {}
	unitSpeedWatch = {}
	unitReammoWatch = {}
	unitScriptReloadWatch = {}
	unitGooWatch = {}
	unitJumpWatch = {}
	unitCaptureReloadWatch = {}
	unitAbilityWatch = {}
	unitStockpileWatch = {}
	unitShieldWatch = {}
	unitCaptureWatch = {}

	for i, unitID in ipairs(Spring.GetAllUnits()) do -- gets radar blips too!
		-- probably shouldnt be adding non-visible units

		if fullview then
			addBarsForUnit(unitID, Spring.GetUnitDefID(unitID), Spring.GetUnitTeam(unitID), nil, 'initfullview')
		else
			local losstate = Spring.GetUnitLosState(unitID, myAllyTeamID)
			if losstate.los then
				addBarsForUnit(unitID, Spring.GetUnitDefID(unitID), Spring.GetUnitTeam(unitID), nil, 'initlos')
				--Spring.Echo(unitID, "IS in los")
			else
				--Spring.Echo(unitID, "is not in los for ", myAllyTeamID)
			end
		end
	end

end

local function addFeature(featureID) 
	-- some map-supplied features dont have a model, in these cases modelpath == ""
	local featureDefID = Spring.GetFeatureDefID(featureID)
	if FeatureDefs[featureDefID].name ~= 'geovent' and FeatureDefs[featureDefID].modelpath ~= ''  then
		addBarToFeature(featureID, 'featureresurrect')
		addBarToFeature(featureID, 'featurereclaim')

		if options.drawFeatureHealth.value then
			addBarToFeature(featureID, 'featurehealth')
		end
	end
end

local function removeFeature(featureID) 
	removeBarFromFeature(featureID, 'featureresurrect')
	removeBarFromFeature(featureID, 'featurereclaim')
	removeBarFromFeature(featureID, 'featurehealth')
end

local GetVisibleFeatures   = Spring.GetVisibleFeatures
local GetFeatureDefID      = Spring.GetFeatureDefID

function initfeaturebars()
	clearInstanceTable(featureVBO)

	local currentWidget = widget:GetInfo().name

	WG.GlUnionUpdaterAddFeatureCallbacks = WG.GlUnionUpdaterAddFeatureCallbacks or {}
        WG.GlUnionUpdaterRemoveFeatureCallbacks = WG.GlUnionUpdaterRemoveFeatureCallbacks or {}

        WG.GlUnionUpdaterAddFeatureCallbacks[currentWidget] = addFeature
        WG.GlUnionUpdaterRemoveFeatureCallbacks[currentWidget] = removeFeature

	local visibleFeatures = GetVisibleFeatures(-1, nil, false, false)

        local cnt = #visibleFeatures
        for i = cnt, 1, -1 do
                featureID = visibleFeatures[i]
                featureDefID = GetFeatureDefID(featureID) or -1
		if FeatureDefs[featureDefID].destructable and FeatureDefs[featureDefID].drawTypeString == "model" then
			addFeature(featureID) 
		end
	end
end

--12:32 PM] Beherith: widget:PlayerChanged generalizations
--[12:33 PM] Beherith: So, I would like to ask if we have a general guideline or if @Floris knows anything about what circumstances should trigger UI GFX widget reinitialization
--[12:36 PM] Beherith: Here, I assume we can live with a few assumptions:
--1. UI GFX widgets are LOS dependent things, that either
--    A. Should look the same for all players on an ALLYteam
--    B. Could look different for each member of an ALLYTeam
--2. Always render different things for different ALLYteams
--This presents and interesting state for most widgets  especially for SPECFULLVIEW
--Obviously, the biggest reason for needing to abstract this is to avoid boilerplate mistakes for most new GL4 widgets, which are --stateful, unlike most previous widgets (most of which collected things they wanted to draw every frame)
--[12:39 PM] Beherith: So I assume widget:PlayerChanged gets called on any legal player change, and should keep track of the following:
--1. spectating state
--2. specfullview state
--3. myAllyTeamID
--4. myTeamID
--[12:40 PM] Beherith: There are 3 real states someone can be in:
--1. player
--2. spectator no fullview
--3. spectator with fullview

--(excluding godmode /globallos et al)
--[12:40 PM] Beherith: Transitions between any of the above 3 should trigger a full reinit
--[12:41 PM] Beherith: But some internal transitions, for stuff that is draw differently for allies might require additional checks, for spectators who have fullview off?

local function FeatureReclaimStartedHealthbars (featureID, step) -- step is negative for reclaim, positive for resurrect
	--Spring.Echo("FeatureReclaimStartedHealthbars", featureID)

    --gl.SetFeatureBufferUniforms(featureID, 0.5, 2) -- update GL
end

local function UnitCaptureStartedHealthbars(unitID, step) -- step is negative for reclaim, positive for resurrect
	--TODO
end

--function widget:UnitDamaged(unitID, unitDefID, unitTeam, damage, paralyzer)
local function UnitParalyzeDamageHealthbars(unitID, unitDefID, damage)
	-- TODO
end

local function ProjectileCreatedReloadHB(projectileID, unitID, weaponID, unitDefID)
	--TODO
	--local unitDefID = Spring.GetUnitDefID(unitID)

	--updateReloadBar(unitID, unitDefID, 'ProjectileCreatedReloadHB')
end

function MorphUpdate(morphTable)
	for unitID, morph in pairs(morphTable) do
		local oldMorph = unitMorphWatch[unitID]
		if not oldMorph then 
			addBarForUnit(unitID, unitDefID, "morph", "MorphUpdate")
			oldMorph = -1.0
		end
		if oldMorph and morph and morph.progress ~= UnitMorphs then
			unitMorphWatch[unitID] = morph.progress
			uniformcache[1] = morph.progress
			gl.SetUnitBufferUniforms(unitID, uniformcache, morphChannel)
		end
	end
end

function MorphStart(unitID, morphDef)
	addBarForUnit(unitID, unitDefID, "morph", "MorphStart")
	unitMorphWatch[unitID] = -1.0
end

function MorphStopOrFinished(unitID)
	removeBarFromUnit(unitID, "morph", "MorphStopOrFinished")
	unitMorphWatch[unitID] = nil
end

function widget:Initialize()
	if not gl.CreateShader then -- no shader support, so just remove the widget itself, especially for headless
		widgetHandler:RemoveWidget()
		return
	end
	WG['healthbars'] = {}
	WG['healthbars'].getScale = function()
		return barScale
	end
	WG['healthbars'].setScale = function(value)
		barScale = value
		init()
		initfeaturebars()
	end
	WG['healthbars'].getVariableSizes = function()
		return variableBarSizes
	end
	WG['healthbars'].setVariableSizes = function(value)
		variableBarSizes = value
		init()
		initfeaturebars()
	end
	WG['healthbars'].getDrawWhenGuiHidden = function()
		return drawWhenGuiHidden
	end
	WG['healthbars'].setDrawWhenGuiHidden = function(value)
		drawWhenGuiHidden = value
	end

	initGL4()

	-- TODO: dont even bother drawing health bars for features that were present on frame 0 - no point in doing so
	-- This is stuff like trees and map features, and scenario features
	init()
	initfeaturebars()
	widgetHandler:RegisterGlobal("FeatureReclaimStartedHealthbars", FeatureReclaimStartedHealthbars )
	widgetHandler:RegisterGlobal("UnitCaptureStartedHealthbars", UnitCaptureStartedHealthbars )
	widgetHandler:RegisterGlobal("UnitParalyzeDamageHealthbars", UnitParalyzeDamageHealthbars )
	widgetHandler:RegisterGlobal("ProjectileCreatedReloadHB", ProjectileCreatedReloadHB )

	--// link morph callins
	widgetHandler:RegisterGlobal('MorphUpdate', MorphUpdate)
	widgetHandler:RegisterGlobal('MorphFinished', MorphStopOrFinished)
	widgetHandler:RegisterGlobal('MorphStart', MorphStart)
	widgetHandler:RegisterGlobal('MorphStop', MorphStopOrFinished)

	--// deactivate cheesy progress text
	widgetHandler:RegisterGlobal('MorphDrawProgress', function() return true end)
end

function widget:Shutdown()
	widgetHandler:DeregisterGlobal("FeatureReclaimStartedHealthbars" )
	widgetHandler:DeregisterGlobal("UnitCaptureStartedHealthbars" )
	widgetHandler:DeregisterGlobal("UnitParalyzeDamageHealthbars" )
	widgetHandler:DeregisterGlobal("ProjectileCreatedReloadHB" )
	Spring.Echo("Healthbars GL4 unloaded hooks")

        widgetHandler:DeregisterGlobal('MorphUpdate', MorphUpdate)
        widgetHandler:DeregisterGlobal('MorphFinished', MorphFinished)
        widgetHandler:DeregisterGlobal('MorphStart', MorphStart)
        widgetHandler:DeregisterGlobal('MorphStop', MorphStop)

        widgetHandler:DeregisterGlobal('MorphDrawProgress')

	local currentWidget = widget:GetInfo().name
	WG.GlUnionUpdaterAddFeatureCallbacks[currentWidget] = nil
        WG.GlUnionUpdaterRemoveFeatureCallbacks[currentWidget] = nil
end

function widget:RecvLuaMsg(msg, playerID)
	if msg:sub(1,18) == 'LobbyOverlayActive' then
		chobbyInterface = (msg:sub(1,19) == 'LobbyOverlayActive1')
	end
end

--[[
function widget:UnitCreated(unitID, unitDefID, teamID)
	addBarsForUnit(unitID, unitDefID, teamID, nil, 'UnitCreated')
end

function widget:UnitDestroyed(unitID, unitDefID, teamID)
	if debugmode then Spring.Echo("HBGL4:UnitDestroyed",unitID, unitDefID, teamID) end
	removeBarsFromUnit(unitID,'UnitDestroyed')
end

function widget:UnitFinished(unitID, unitDefID, teamID) -- reset bars on construction complete?
	widget:UnitDestroyed(unitID, unitDefID, teamID)
	widget:UnitCreated(unitID, unitDefID, teamID)
end

function widget:UnitEnteredLos(unitID, unitTeam, allyTeam, unitDefID) -- this is still called when in spectator mode :D
	if not fullview then addBarsForUnit(unitID, Spring.GetUnitDefID(unitID), unitTeam, nil, 'UnitEnteredLos') end
end

function widget:UnitLeftLos(unitID, unitTeam, allyTeam, unitDefID)
	if spec and fullview then return end -- Interesting bug: if we change to spec with /spectator 1, then we receive unitLeftLos callins afterwards :P
	removeBarsFromUnit(unitID, 'UnitLeftLos')
end

function widget:UnitTaken(unitID, unitDefID, oldTeamID, newTeamID)
	local newAllyTeamID = select( 6, Spring.GetTeamInfo(newTeamID))

	if debugmode then
		Spring.Echo("widget:UnitTaken",unitID, unitDefID, oldTeamID, newTeamID, Spring.GetUnitAllyTeam(unitID),newAllyTeamID)
	end

	removeBarsFromUnit(unitID,'UnitTaken') -- because taken units dont actually call unitleftlos :D
	if newAllyTeamID == myAllyTeamID then  -- but taken units, that we see being taken trigger unitenteredlos  on the same frame
		addBarsForUnit(unitID, unitDefID, newTeamID, newAllyTeamID, 'UnitTaken')
	end
end

function widget:UnitGiven(unitID, unitDefID, newTeamID)
	--Spring.Echo("widget:UnitGiven",unitID, unitDefID, newTeamID)
	removeBarsFromUnit(unitID, 'UnitGiven')
	addBarsForUnit(unitID, unitDefID, newTeamID, nil,  'UnitTaken')
end
]]--

function widget:VisibleUnitAdded(unitID, unitDefID, unitTeam)
	addBarsForUnit(unitID, unitDefID, unitTeam, nil, 'VisibleUnitAdded')
end

function widget:VisibleUnitRemoved(unitID)
	removeBarsFromUnit(unitID, 'VisibleUnitRemoved')
end

function widget:VisibleUnitsChanged(extVisibleUnits, extNumVisibleUnits)
	clearInstanceTable(healthBarVBO)
	unitHealthWatch = {}
	unitBuildWatch = {}
	unitMorphWatch = {}
	unitParalyzeWatch = {}
	unitDisarmWatch = {}
	unitSlowWatch = {}
	unitReloadWatch = {}
	unitDgunWatch = {}
	unitTeleportWatch = {}
	unitHeatWatch = {}
	unitSpeedWatch = {}
	unitReammoWatch = {}
	unitScriptReloadWatch = {}
	unitGooWatch = {}
	unitJumpWatch = {}
	unitCaptureReloadWatch = {}
	unitAbilityWatch = {}
	unitStockpileWatch = {}
	unitShieldWatch = {}
	unitCaptureWatch = {}

	spec, fullview = Spring.GetSpectatingState()
	myTeamID = Spring.GetMyTeamID()
	myAllyTeamID = Spring.GetMyAllyTeamID()
	myPlayerID = Spring.GetMyPlayerID()

	clearInstanceTable(healthBarVBO) -- clear all instances
	for unitID, unitDefID in pairs(extVisibleUnits) do
		addBarsForUnit(unitID, unitDefID, Spring.GetUnitTeam(unitID), nil, "VisibleUnitsChanged") -- TODO: add them with noUpload = true
	end
	--uploadAllElements(healthBarVBO) -- upload them all
end

function widget:PlayerChanged(playerID)

	local currentspec, currentfullview = Spring.GetSpectatingState()
	local currentTeamID = Spring.GetMyTeamID()
	local currentAllyTeamID = Spring.GetMyAllyTeamID()
	local currentPlayerID = Spring.GetMyPlayerID()
	local reinit = false

	if debugmode then Spring.Echo("HBGL4 widget:PlayerChanged",'spec', currentspec, 'fullview', currentfullview, 'teamID', currentTeamID, 'allyTeamID', currentAllyTeamID, "playerID", currentPlayerID) end

	-- cases where we need to trigger:
	if (currentspec ~= spec) or -- we transition from spec to player, yes this is needed
		(currentfullview ~= fullview) or -- we turn on or off fullview
		((currentAllyTeamID ~= myAllyTeamID) and not currentfullview)  -- our ALLYteam changes, and we are not in fullview
		--((currentTeamID ~= myTeamID) and not currentfullview)

		then
		-- do the actual reinit stuff, but first change my own
		reinit = true
		if debugmode then Spring.Echo("HBGL4 triggered a playerchanged reinit") end

	end
	-- save the state:
	spec = currentspec
	fullview = currentfullview
	myAllyTeamID = currentAllyTeamID
	myTeamID = currentTeamID
	myPlayerID = currentPlayerID
	--if reinit then init() end
end

local paralyzeOnMaxHealth = Game.paralyzeOnMaxHealth

function widget:GameFrame(gameFrame)

	if debugmode then
		locateInvalidUnits(healthBarVBO)
	end
	--[[ TODO:
        unitMorphWatch[unitID] = nil
        unitReloadWatch[unitID] = nil
        unitDgunWatch[unitID] = nil
        unitTeleportWatch[unitID] = nil
        unitAbilityWatch[unitID] = nil
        unitStockpileWatch[unitID] = nil
	--]]
	if gameFrame % 3 == 5 then -- TODO: move this to unit_gl_updater
		for unitID, oldHealthPower in pairs(unitHealthWatch) do
			local health, maxHealth, paralyzeDamage, capture, build = GetUnitHealth(unitID)
			paralyzeDamage = GetUnitRulesParam(unitID, "real_para") or paralyzeDamage or 0

			if (not maxHealth)or(maxHealth < 1) then
				maxHealth = 1
			end

			if (not build) then
				build = 1
			end

			local empHP = (not paralyzeOnMaxHealth) and health or maxHealth
			local emp = paralyzeDamage/empHP
			local hp  = (health or 0)/maxHealth
			
			--// HEALTH
			unitHealthWatch[unitID] = hp
			-- Health is passed to shaders using health/maxHealth

			--// BUILD
			if unitBuildWatch[unitID] ~= build then
				unitBuildWatch[unitID] = build
				uniformcache[1] = 1-build
				gl.SetUnitBufferUniforms(unitID, uniformcache, buildChannel)
			end

			--// PARALYZE
			local paraTime = false
			local stunned = GetUnitIsStunned(unitID)
			stunned = stunned and paralyzeDamage >= empHP
			if (stunned) then
				emp = (paralyzeDamage-empHP)/(maxHealth*empDecline) + 1
			else
				if (emp > 1) then
					emp = 1
				end
			end

			if unitParalyzeWatch[unitID] ~= emp then
				unitParalyzeWatch[unitID] = emp
				uniformcache[1] = emp
				gl.SetUnitBufferUniforms(unitID, uniformcache, paralyzeChannel)
			end

			--// CAPTURE
			capture = capture or 0
			if unitCaptureWatch[unitID] ~= capture then
				unitCaptureWatch[unitID] = capture
				uniformcache[1] = capture
				gl.SetUnitBufferUniforms(unitID, uniformcache, captureChannel)
			end

			--// DISARM
			local disarmFrame = GetUnitRulesParam(unitID, "disarmframe")
			if disarmFrame and disarmFrame ~= -1 and disarmFrame > gameFrame then
				local disarm
				local disarmProp = (disarmFrame - gameFrame)/1200
				if disarmProp < 1 then
					if (not paraTime) and disarmProp > emp + 0.014 then -- 16 gameframes of emp time
						disarm = disarmProp
					end
				else
					local disarmTime = (disarmFrame - gameFrame - 1200)/gameSpeed
					if (not paraTime) or disarmTime > paraTime + 0.5 then
						disarm = disarmTime + 1
					end
				end
				if unitDisarmWatch[unitID] ~= disarm then
					unitDisarmWatch[unitID] = disarm
					uniformcache[1] = disarm
					gl.SetUnitBufferUniforms(unitID, uniformcache, disarmChannel)
				end
			end

			--// SLOW
		-- for unitID, oldSlow in pairs(unitSlowWatch) do
			local slow = GetUnitRulesParam(unitID, "slowState") or 0
			if unitSlowWatch[unitID] ~= slow then
				unitSlowWatch[unitID] = slow
				uniformcache[1] = slow * 2
				gl.SetUnitBufferUniforms(unitID, uniformcache, slowChannel)
			end
		-- end

		end
	end

	if gameFrame % 3 == 1 then
		--// SHIELD
		for unitID, oldshieldPower in pairs(unitShieldWatch) do
			local shieldOn, shieldPower = GetUnitShieldState(unitID)
			if shieldOn == false then shieldPower = 0.0 end
			if oldshieldPower ~= shieldPower then
				if shieldPower == nil then
					removeBarFromUnit(unitID, "shield", "unitShieldWatch")
				else
					uniformcache[1] = shieldPower / (unitDefHasShield[Spring.GetUnitDefID(unitID)])
					gl.SetUnitBufferUniforms(unitID, uniformcache, shieldChannel)
				end
				unitShieldWatch[unitID] = shieldPower
			end
		end

	-- RELOAD
		for unitID, oldReload in pairs(unitReloadWatch) do
			local unitDefID = Spring.GetUnitDefID(unitID)
			local reload 
                        _, _, reload = GetUnitWeaponState(unitID, unitDefPrimaryWeapon[unitDefID])
			reload = reload or 0

			if oldReload ~= reload then
				unitReloadWatch[unitID] = reload
				uniformcache[1] = -reload 
				gl.SetUnitBufferUniforms(unitID, uniformcache, reloadChannel)
			end
		end

	-- DGUN
		for unitID, oldReload in pairs(unitDgunWatch) do
			local unitDefID = Spring.GetUnitDefID(unitID)
			local reload 
                        _, _, reload = GetUnitWeaponState(unitID, unitDefDgun[unitDefID])

			reload = reload or 0

			if oldReload ~= reload then
				unitDgunWatch[unitID] = reload
				uniformcache[1] = -reload 
				gl.SetUnitBufferUniforms(unitID, uniformcache, dgunChannel)
			end
		end

		-- ABILITY
		for unitID, oldAbility in pairs(unitAbilityWatch) do
			local ability = GetUnitRulesParam(unitID, "specialReloadRemaining") or 0
			if oldAbility ~= ability then
				unitAbilityWatch[unitID] = ability
				uniformcache[1] = ability 
				gl.SetUnitBufferUniforms(unitID, uniformcache, abilityChannel)
			end
		end

		-- SCRIPT RELOAD
		for unitID, oldReload in pairs(unitScriptReloadWatch) do
                        local reload = GetUnitRulesParam(unitID, "scriptReloadFrame") or 0

			if oldReload ~= reload then
				unitScriptReloadWatch[unitID] = reload
				uniformcache[1] = -reload 
				gl.SetUnitBufferUniforms(unitID, uniformcache, reloadChannel)
			end
                end
	end

	if gameFrame % 3 == 2 then
		--// GOO
		for unitID, oldGoo in pairs(unitGooWatch) do
			local goo = GetUnitRulesParam(unitID, "gooState") or 0
			if oldGoo ~= goo then
				unitGooWatch[unitID] = goo
				uniformcache[1] = goo
				gl.SetUnitBufferUniforms(unitID, uniformcache, gooChannel)
			end
		end

		--// JUMP
		for unitID, oldJump in pairs(unitJumpWatch) do
			local jump = GetUnitRulesParam(unitID, "jumpReload") or 0
			if oldJump ~= jump then
				unitJumpWatch[unitID] = jump
				uniformcache[1] = jump
				gl.SetUnitBufferUniforms(unitID, uniformcache, jumpChannel)
			end
		 end

		--// HEAT
		for unitID, oldHeat in pairs(unitHeatWatch) do
			local heat = GetUnitRulesParam(unitID, "heat_bar")
			if oldHeat ~= heat then
				unitHeatWatch[unitID] = heat
				uniformcache[1] = heat
				gl.SetUnitBufferUniforms(unitID, uniformcache, heatChannel)
			end
		end

		--// SPEED
		for unitID, oldSpeed in pairs(unitSpeedWatch) do
			local speed = GetUnitRulesParam(unitID, "speed_bar") or 0
			if oldSpeed ~= speed then
				unitSpeedWatch[unitID] = speed
				uniformcache[1] = speed
				gl.SetUnitBufferUniforms(unitID, uniformcache, speedChannel)
			end
		end

		--// REAMMO
		for unitID, oldReammo in pairs(unitReammoWatch) do
			local reammo = GetUnitRulesParam(unitID, "reammoProgress") or 0
			if oldReammo ~= reammo then
				unitReammoWatch[unitID] = reammo
				uniformcache[1] = reammo
				gl.SetUnitBufferUniforms(unitID, uniformcache, reammoChannel)
			end
		end

		--// STOCKPILE
		for unitID, oldStockpile in pairs(unitStockpileWatch) do
			local numStockpiled
			local numStockpileQued
			local stockpileBuild 
			numStockpiled, numStockpileQued, stockpileBuild = GetUnitStockpile(unitID)

	                local unitDefID = unitDefID or Spring.GetUnitDefID(unitID)
                        local unitDef = UnitDefs[unitDefID]
			if unitDef.customParams and unitDef.customParams.stockpiletime then
                                stockpileBuild = GetUnitRulesParam(unitID, "gadgetStockpile")
                        end

			if oldStockpile ~= stockpileBuild then
				unitStockpileWatch[unitID] = stockpileBuild 
				uniformcache[1] = stockpileBuild
				gl.SetUnitBufferUniforms(unitID, uniformcache, stockpileChannel)
			end
		end

		--// CAPTURE RELOAD
		for unitID, oldCaptureReload in pairs(unitCaptureReloadWatch) do
			if oldCaptureReload <= gameFrame then 
				local captureReload = GetUnitRulesParam(unitID, "captureRechargeFrame") or 0

				if oldCaptureReload ~= captureReload then
					unitCaptureReloadWatch[unitID] = captureReload
					uniformcache[1] = -captureReload
					gl.SetUnitBufferUniforms(unitID, uniformcache, captureReloadChannel)
				end
			end
		end

		--// TELEPORT
		for unitID, oldTeleport in pairs(unitTeleportWatch) do
			local TeleportEnd = GetUnitRulesParam(unitID, "teleportend") or 0
			local TeleportCost = GetUnitRulesParam(unitID, "teleportcost") or 1
			local teleport = 1 - (TeleportEnd - gameFrame)/TeleportCost

			if teleport > 1 then
				teleport = 1
			end

			if oldTeleport ~= teleport then
				unitTeleportWatch[unitID] = teleport 
				uniformcache[1] = teleport
				gl.SetUnitBufferUniforms(unitID, uniformcache, teleportChannel)
			end
		end
	end
end

function widget:DrawWorld()
	--Spring.Echo(Engine.versionFull )
	if chobbyInterface then return end
	if not drawWhenGuiHidden and Spring.IsGUIHidden() then return end

	local disticon = Spring.GetConfigInt("UnitIconDistance", 200) * 27.5 -- iconLength = unitIconDist * unitIconDist * 750.0f;
	gl.DepthTest(true)
	gl.DepthMask(true)
	gl.Texture(0,healthbartexture)
	healthBarShader:Activate()
	healthBarShader:SetUniform("iconDistance",disticon)
	if not debugmode then healthBarShader:SetUniform("cameraDistanceMult",1.0)  end
	healthBarShader:SetUniform("cameraDistanceMultGlyph", glphydistmult)
	healthBarShader:SetUniform("skipGlyphsNumbers",skipGlyphsNumbers)  --0.0 is everything,  1.0 means only numbers, 2.0 means only bars,
	if healthBarVBO.usedElements > 0 then
		healthBarVBO.VAO:DrawArrays(GL.POINTS,healthBarVBO.usedElements)
	end
	-- below its the feature bars being drawn:
	healthBarShader:SetUniform("cameraDistanceMultGlyph", glyphdistmultfeatures)
	if featureVBO.usedElements > 0 then
		if not debugmode then healthBarShader:SetUniform("cameraDistanceMult",featureResurrectDistMult)  end
		featureVBO.VAO:DrawArrays(GL.POINTS,featureVBO.usedElements)
	end

	healthBarShader:Deactivate()
	gl.Texture(false)
	gl.DepthTest(false)
    gl.DepthMask(false) --"BK OpenGL state resets", reset to default state
end

function widget:TextCommand(command)
	if string.find(command, "debughealthbars", nil, true) == 1 then
		debugmode = not debugmode
		Spring.Echo("Debug mode for HealthBars GL4 set to", debugmode)
		healthBarVBO.debug = debugmode
	end
end

function widget:GetConfigData(data)
	return {
		barScale = barScale,
		barHeight = barHeight,
		variableBarSizes = variableBarSizes,
		drawWhenGuiHidden = drawWhenGuiHidden
	}
end

function widget:SetConfigData(data)
	barScale = data.barScale or barScale
	if data.variableBarSizes ~= nil then
		variableBarSizes = data.variableBarSizes
	end
	if data.drawWhenGuiHidden ~= nil then
		drawWhenGuiHidden = data.drawWhenGuiHidden
	end
	if data.barHeight ~= nil then
		barHeight = data.barHeight
		shaderSourceCache.shaderConfig.BARHEIGHT = barHeight
		shaderSourceCache.shaderConfig.BARCORNER = 0.06 + (shaderConfig.BARHEIGHT / 9)
		shaderSourceCache.shaderConfig.SMALLERCORNER = shaderConfig.BARCORNER * 0.6
	end
end
