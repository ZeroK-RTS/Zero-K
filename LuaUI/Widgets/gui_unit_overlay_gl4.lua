function widget:GetInfo()
   return {
      name      = "Unit Overlay GL4",
      desc      = "GL4 unit overlay: health bars, weapon bars, status icons",
      author    = "Beherith",
      date      = "October 2019",
      license   = "GNU GPL, v2 or later for Lua code, (c) Beherith (mysterme@gmail.com) for GLSL",
      layer     = -10,
      enabled   = true
   }
end

local init -- forward declaration so option OnChange handlers can re-add bars
options_path = 'Settings/Interface/Unit Overlay'
local layout_path = options_path .. '/Size & Layout'
options_order = {
	-- General
	'showGlyphsNumbers', 'drawFeatureHealth', 'fadeDistance', 'statusFadeDistance', 'iconHideDistance', 'trackDarken', 'reloadThreshold',
	'debugDrawAtlas',
	-- Size & Layout (nested)
	'overallScale',
	'barSize', 'barSpacing', 'barHeightAboveUnit', 'barBorder',
	'statusSize', 'statusSpacing', 'statusHeight',
	'unitIconSize', 'weaponBarSize', 'weaponBarOffset', 'abilityBadgeHeight',
}
options = {
	showGlyphsNumbers = {
		name = 'Bar detail',
		type = 'select',
		value = 'Icons and numbers',
		items = {'Icons and numbers', 'Numbers only', 'Bars only'},
		noHotkey = true,
		desc = 'How much detail to show on bars: icons and numbers, just numbers, or plain bars.',
		OnChange = function(self)
			local map = {['Icons and numbers'] = 0.0, ['Numbers only'] = 1.0, ['Bars only'] = 2.0}
			skipGlyphsNumbers = map[self.value] or 0.0
		end
	},
	drawFeatureHealth = {
		name = 'Show health on wrecks',
		type = 'bool',
		value = false,
		noHotkey = true,
		desc = 'Show health bars on wrecks and corpses.',
		OnChange = function()
			initfeaturebars()
		end
	},
	fadeDistance = {
		name = 'Fade-out distance',
		type = 'number', value = 3200, min = 0, max = 20000, step = 100,
		noHotkey = true,
		desc = 'Camera distance at which bars start fading out. 0 = never fade.',
	},
	statusFadeDistance = {
		name = 'Status icons hide distance',
		type = 'number', value = 0, min = 0, max = 20000, step = 100,
		noHotkey = true,
		desc = 'Camera distance beyond which status/state icons above bars are hidden. 0 = never hide.',
	},
	iconHideDistance = {
		name = 'Unit icon hide distance',
		type = 'number', value = 0, min = 0, max = 2000, step = 50,
		noHotkey = true,
		desc = 'Camera distance below which the center unit type icon is hidden. 0 = never hide.',
	},
	trackDarken = {
		name = 'Empty bar brightness',
		type = 'number', value = 0.25, min = 0.0, max = 1.0, step = 0.05,
		noHotkey = true, desc = 'Brightness of the empty part of a bar (1 = as bright as the filled part, lower = darker).',
	},
	reloadThreshold = {
		name = 'Hide quick reload timers under',
		type = 'number', value = 2.0, min = 0.1, max = 15.0, step = 0.1,
		noHotkey = true,
		desc = 'Weapons that reload faster than this (seconds) do not show a reload timer. Commanders always show one.',
		OnChange = function() init() end,
	},
	debugDrawAtlas = {
		name = 'DEBUG: show icon atlas',
		type = 'bool',
		value = false,
		noHotkey = true,
		desc = 'Draw the runtime icon atlas in the center of the screen (for debugging atlas/cell issues).',
	},

	-- Size & Layout --------------------------------------------------------------------------------
	overallScale = {
		name = 'Overall overlay scale',
		path = layout_path,
		type = 'number', value = 1, min = 0.5, max = 2, step = 0.05,
		noHotkey = true, desc = 'Scales the whole overlay (bars, badges, icons) uniformly, alongside the per-unit size multiplier.',
	},
	barSize = {
		name = 'Bar size',
		path = layout_path,
		type = 'number', value = 1, min = 0.3, max = 3, step = 0.05,
		noHotkey = true, desc = 'Size of the health and status bars (and their numbers).',
	},
	barSpacing = {
		name = 'Bar spacing',
		path = layout_path,
		type = 'number', value = 1, min = 0.3, max = 3, step = 0.05,
		noHotkey = true, desc = 'Gap between stacked bars.',
	},
	barHeightAboveUnit = {
		name = 'Bar height above unit',
		path = layout_path,
		type = 'number', value = 0, min = -50, max = 50, step = 1,
		noHotkey = true, desc = 'Raise or lower the bars relative to the unit.',
	},
	barBorder = {
		name = 'Bar border thickness',
		path = layout_path,
		type = 'number', value = 0.25, min = 0.0, max = 1.0, step = 0.02,
		noHotkey = true, desc = 'Thickness of the decorative border around each bar.',
	},
	statusSize = {
		name = 'Icon & badge size',
		path = layout_path,
		type = 'number', value = 1.0, min = 0.2, max = 4.0, step = 0.1,
		noHotkey = true, desc = 'Size of the state icons, status-effect badges and weapon reload badges.',
	},
	statusSpacing = {
		name = 'Status row spacing',
		path = layout_path,
		type = 'number', value = 1.0, min = 0.2, max = 4.0, step = 0.1,
		noHotkey = true, desc = 'Spacing between items in the row of states and status effects above the bars.',
	},
	statusHeight = {
		name = 'Status row height',
		path = layout_path,
		type = 'number', value = 0.0, min = -30, max = 30, step = 0.1,
		noHotkey = true, desc = 'Raise or lower the row of states and status effects above the bars.',
	},
	unitIconSize = {
		name = 'Unit icon size',
		path = layout_path,
		type = 'number', value = 1.0, min = 0.1, max = 4, step = 0.1,
		noHotkey = true, desc = 'Size of the unit icon.',
	},
	weaponBarSize = {
		name = 'Weapon bar size',
		path = layout_path,
		type = 'number', value = 1, min = 0.1, max = 4, step = 0.1,
		noHotkey = true, desc = 'Size of the vertical weapon reload bars beside the unit.',
	},
	weaponBarOffset = {
		name = 'Weapon bar offset',
		path = layout_path,
		type = 'number', value = 0, min = -20, max = 20, step = 0.25,
		noHotkey = true, desc = 'How far the weapon bars sit out to the sides of the unit.',
	},
	abilityBadgeHeight = {
		name = 'Ability badge height',
		path = layout_path,
		type = 'number', value = 0.0, min = -30, max = 30, step = 0.1,
		noHotkey = true, desc = 'Raise or lower the ability badges (jump, morph, teleport) below the unit.',
	},
}

-- Unit-state icons (WG.icons). These options are the single source of truth for state-icon
-- visibility: the producer widgets (State Icons, Gadget Icons, Rank Icons) only push icon data;
-- this widget decides what is shown via WG.icons.SetDisplay. stateCtl.apply* are defined once
-- WG.icons exists (further down); the OnChange handlers call through stateCtl so the closures don't
-- need WG.icons at parse time.
local states_path = options_path .. '/Unit States'
local stateCtl = {} -- { apply(name), applyAll(), refreshShift() } -- assigned after WG.icons below
local stateIconBool = {
	{ name = 'rank',       label = 'Veterancy rank',          default = true },
	{ name = 'group',      label = 'Control group number',    default = true },
	{ name = 'lowpower',   label = 'Low power (no energy)',   default = true },
	{ name = 'facplop',    label = 'Factory plate to place',  default = true },
	{ name = 'nofactory',  label = 'Plate without factory',   default = true },
	{ name = 'retreat',    label = 'Retreating',              default = true },
	{ name = 'wait',       label = 'Waiting',                 default = true },
	{ name = 'padExclude', label = 'Excluded from pad',       default = true },
	{ name = 'rearm',      label = 'Out of ammo / rearming',  default = false },
}
local stateIconTri = {
	{ name = 'armored',      label = 'Armored',                         default = 'shift' },
	{ name = 'priority',     label = 'Build priority',                  default = 'shift' },
	{ name = 'firestate',    label = 'Fire state',                      default = 'shift' },
	{ name = 'movestate',    label = 'Move state',                      default = 'shift' },
	{ name = 'miscpriority', label = 'Misc priority (morph/stockpile)', default = 'shift' },
	{ name = 'command',      label = 'Current command',                 default = 'shift' },
}
for _, s in ipairs(stateIconBool) do
	local key = 'state_' .. s.name
	options[key] = {
		name = s.label, path = states_path, type = 'bool', value = s.default, noHotkey = true,
		OnChange = function() stateCtl.apply(s.name) end,
	}
	options_order[#options_order + 1] = key
end
for _, s in ipairs(stateIconTri) do
	local key = 'state_' .. s.name
	options[key] = {
		name = s.label, path = states_path, type = 'radioButton', value = s.default, noHotkey = true,
		items = { {key='always', name='Always'}, {key='shift', name='When holding Shift'}, {key='never', name='Never'} },
		OnChange = function() stateCtl.apply(s.name) end,
	}
	options_order[#options_order + 1] = key
end

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
local bitVertical = 256   -- bar fills bottom-to-top
local bitLeft = 512       -- position bar left of unit (primary weapon)
local bitRight = 1024     -- position bar right of unit (secondary weapon)
local bitIcon = 4096      -- draw unit icon billboard
local bitAlwaysShow = 8192 -- radial badge: always render (commanders), showing "ready" when below the reload threshold
local bitIconRow = 16384  -- hovering-icon row (WG.icons): billboard icon placed by centered slot index
local bitPulse = 32768    -- hovering icon flashes (alpha oscillates via pulseAlpha)
local bitConstruction = 65536 -- radial badge driven by the build channel's duration encoding (building/reclaiming/constant)
local bitGauge = 131072   -- radial badge that fills to a 0..1 magnitude (heat/speed/charge), not a countdown
local bitIconCorner = 262144 -- icon billboard pinned to a corner of the unit icon (rank TL / group number BR)
local bitModular = 524288 -- ability-slot duration bar: value is target-frame mod 4096, GPU-decremented
local bitJumpCharge = 1048576 -- below-zone gauge whose value is a reconstructed jumpReload; each badge shows one charge
local bitRateETA = 2097152 -- below-zone radial ETA badge: build-style band decode (0 hidden/1 paused/2+secs) but NOT top-band

-- Columns in the vertical (weapon bar) glyph atlas. Distinct from the horizontal
-- glyph atlas's uvoffset numbering -- these bar types are always BITVERTICAL, so
-- their uvoffset only ever feeds the vertical atlas lookup in the geom shader.
local VBAR_COL_ENERGY          = 0
local VBAR_COL_KINETIC         = 1
local VBAR_COL_EXPLOSIVE       = 2
local VBAR_COL_BURST           = 3
local VBAR_COL_GENERIC_RELOAD  = 4 -- fallback when a unit's weapon has no weapon_class
local VBAR_COL_HEAT            = 5
local VBAR_COL_DGUN            = 6
local VBAR_COL_TELEPORT        = 7
local VBAR_COL_SPEED           = 8
local VBAR_COL_STOCKPILE       = 9
local VBAR_COL_REAMMO          = 10
local VBAR_COL_CAPTURERELOAD   = 11
local VBAR_COL_LIGHTNING       = 12
local VBAR_COL_FLAME           = 13

local weaponClassVbarColumn = {
	energy    = VBAR_COL_ENERGY,
	kinetic   = VBAR_COL_KINETIC,
	explosive = VBAR_COL_EXPLOSIVE,
	burst     = VBAR_COL_BURST,
	lightning = VBAR_COL_LIGHTNING,
	flame     = VBAR_COL_FLAME,
}

local includeDir = "LuaUI/Widgets/Include/"
VFS.Include(includeDir.."gl_uniform_channels.lua")

local icontypes = VFS.FileExists(LUAUI_DIRNAME .. "Configs/icontypes.lua") and VFS.Include(LUAUI_DIRNAME .. "Configs/icontypes.lua") or {}
local _, iconFormat = VFS.Include(LUAUI_DIRNAME .. "Configs/chilitip_conf.lua", nil, VFS.ZIP)
iconFormat = iconFormat or ".dds"
local iconAtlasTexture = nil
local unitDefIconIndex = {}
-- Reload-badge icons now come from each weapon's `icon` customParam (a path), registered on demand via
-- registerDynamicIcon; weapon-class/commweapon icon tables are retired.
-- numbers.png is a 12-glyph strip "s % 9 8 7 6 5 4 3 2 1 0" (64px each), blitted across 12
-- contiguous atlas cells. digitAtlasIndex maps a digit 0-9 (and 's'/'%') to its atlas index.
local digitStripPath = "LuaUI/Images/numbers.png"
local digitStripGlyphs = { 's', '%', 9, 8, 7, 6, 5, 4, 3, 2, 1, 0 } -- left-to-right order in the strip
local digitAtlasIndex = {}
local digitAtlasStartIndex = 0 -- atlas cell of the strip's first glyph ('s'); fed to the shader as digitAtlasStart
-- Horizontal fill bars: each is a 576x64 png = 9 contiguous 64px atlas cells. barAtlasIndex maps
-- a bar name to its starting cell; the shader samples the 9-cell span across the bar's width.
local barFillCells = 9 -- 576 / 64
local barAtlasFills = { "build", "capture", "shield", "slow", "disarm", "disable", "health", "reclaim", "resurrect" }
local barAtlasIndex = {}
-- Status-duration badge icons (the Bold command icons), keyed by status name -> atlas cell.
local statusIconImage = { paralyze = "disable", disarm = "disarm", slow = "slow", build = "build", resurrect = "resurrect",
	morph = "upgrade", stockpile = "missile", teleport = "drop_beacon", ability = "sprint",
	rearm = "rearm", goo = "reclaim" }
local statusIconIndex = {}
-- Jump-charge gauge badges composite this command icon (atlas cell fed to the shader as jumpIconCell).
local jumpIconPath = "LuaUI/Images/commands/Bold/jump.png"
local jumpIconAtlasIndex = 0
local iconAtlasCols = 16
-- One 9-cell bar per row leaves 7 cells unused, so the bars alone need ~9 rows on top of the
-- ~200 unit icon-type cells + the digit row; 16 rows can't hold all that, so the atlas is 32 tall.
local iconAtlasRows = 32
local iconAtlasCellSize = 64

local barTypeMap = {
	health = {
		mincolor = {1.0, 0.0, 0.0, 1.0},
		maxcolor = {0.0, 1.0, 0.0, 1.0},
		bartype = bitPercentage + bitColorCorrect + bitInverse,
		hidethreshold = 0.99,
		uniformindex = unitHealthChannel,
		uvoffset = 18,
		fill = "health",
	},
	paralyze = {
		-- white so the pre-colored fill art (disable.png) shows as authored (fill is color-multiplied)
		mincolor = {1.0, 1.0, 1.0, 1.0},
		maxcolor = {1.0, 1.0, 1.0, 1.0},
		bartype = bitShowGlyph + bitUseOverlay + bitPercentage,
		hidethreshold = 1.99,
		uniformindex = unitParalyzeChannel,
		uvoffset = 19,
		fill = "disable",
	},
	build = {
		-- Construction/reclaim progress fill bar (ch7 = buildProgress 0..1 while building/reclaiming,
		-- 0 when finished). White so the pre-colored fill art (build.png) shows as authored.
		mincolor = {1.0, 1.0, 1.0, 1.0},
		maxcolor = {1.0, 1.0, 1.0, 1.0},
		bartype = bitShowGlyph + bitPercentage,
		hidethreshold = 0.999,
		uniformindex = unitBuildChannel,
		uvoffset = 2,
		fill = "build",
	},
	morph = { -- non-weapon ability -> below zone. rate-ETA (build-style): counts down to completion,
		-- grey static when stalled (insufficient resources). Updater encodes the band on float 8.
		mincolor = {0.80, 0.30, 1.00, 1.0},
		maxcolor = {0.80, 0.30, 1.00, 1.0}, -- magenta (forward-progress band color)
		bartype = bitVertical + bitRateETA,
		hidethreshold = 0.99,
		uniformindex = unitMorphChannel,
		uvoffset = 0,
		statusIcon = "morph", -- upgrade symbol
	},
	disarm = {
		-- white so the pre-colored fill art (disarm.png) shows as authored (fill is color-multiplied)
		mincolor = {1.0, 1.0, 1.0, 1.0},
		maxcolor = {1.0, 1.0, 1.0, 1.0},
		bartype = bitShowGlyph + bitUseOverlay + bitPercentage,
		hidethreshold = 0.99,
		uniformindex = unitDisarmChannel,
		uvoffset = 15,
		fill = "disarm",
	},
	slow = {
		-- white so the pre-colored fill art (slow.png) shows as authored (fill is color-multiplied)
		mincolor = {1.0, 1.0, 1.0, 1.0},
		maxcolor = {1.0, 1.0, 1.0, 1.0},
		bartype = bitPercentage + bitColorCorrect,
		hidethreshold = 0.99,
		uniformindex = unitSlowChannel,
		uvoffset = 16,
		fill = "slow",
	},
	-- Status-duration radial badges: read the same channel as the damage bar, but show only the
	-- "locked at max" duration (the channel value's >1 overflow, in seconds). bitTimeLeft selects the
	-- status-duration mode in the shader; uvoffset (the badge icon) is set after the atlas is built.
	paralyzetimer = {
		mincolor = {0.6, 0.6, 1.0, 1.0}, maxcolor = {0.6, 0.6, 1.0, 1.0},
		bartype = bitVertical + bitTimeLeft,
		hidethreshold = 0.99,
		uniformindex = unitParalyzeChannel,
		uvoffset = 0, statusIcon = "paralyze", layoutSlot = 0, -- top band
	},
	disarmtimer = {
		mincolor = {0.6, 0.6, 1.0, 1.0}, maxcolor = {0.6, 0.6, 1.0, 1.0},
		bartype = bitVertical + bitTimeLeft,
		hidethreshold = 0.99,
		uniformindex = unitDisarmChannel,
		uvoffset = 0, statusIcon = "disarm", layoutSlot = 1,
	},
	slowtimer = {
		mincolor = {0.4, 0.6, 1.0, 1.0}, maxcolor = {0.4, 0.6, 1.0, 1.0},
		bartype = bitVertical + bitTimeLeft,
		hidethreshold = 0.99,
		uniformindex = unitSlowChannel,
		uvoffset = 0, statusIcon = "slow", layoutSlot = 2,
	},
	-- Weapon cooldown badges flank the icon in 2 columns: primary(1)/tertiary(3) left, secondary(2)/
	-- quaternary(4) right, higher priority on top (layoutSlot = row within the column).
	reload = { -- weapon 1: left, top
		mincolor = {0.03, 0.4, 0.4, 1.0},
		maxcolor = {0.05, 0.6, 0.6, 1.0},
		bartype = bitShowGlyph + bitUseOverlay + bitPercentage + bitModular + bitInverse + bitLeft + bitVertical,
		hidethreshold = 0.99,
		uniformindex = unitPrimaryReloadChannel,
		uvoffset = VBAR_COL_GENERIC_RELOAD, layoutSlot = 0, -- overridden per-unit by weapon_class in addBarForUnit
	},
	reload2 = { -- weapon 2: right, top
		mincolor = {0.03, 0.4, 0.4, 1.0}, maxcolor = {0.05, 0.6, 0.6, 1.0},
		bartype = bitShowGlyph + bitUseOverlay + bitPercentage + bitModular + bitInverse + bitRight + bitVertical,
		hidethreshold = 0.99, uniformindex = unitPrimaryCountChannel, uvoffset = VBAR_COL_GENERIC_RELOAD, layoutSlot = 0,
	},
	reload3 = { -- weapon 3: left, second row
		mincolor = {0.03, 0.4, 0.4, 1.0}, maxcolor = {0.05, 0.6, 0.6, 1.0},
		bartype = bitShowGlyph + bitUseOverlay + bitPercentage + bitModular + bitInverse + bitLeft + bitVertical,
		hidethreshold = 0.99, uniformindex = unitSecondaryReloadChannel, uvoffset = VBAR_COL_GENERIC_RELOAD, layoutSlot = 1,
	},
	reload4 = { -- weapon 4: right, second row
		mincolor = {0.03, 0.4, 0.4, 1.0}, maxcolor = {0.05, 0.6, 0.6, 1.0},
		bartype = bitShowGlyph + bitUseOverlay + bitPercentage + bitModular + bitInverse + bitRight + bitVertical,
		hidethreshold = 0.99, uniformindex = unitSecondaryCountChannel, uvoffset = VBAR_COL_GENERIC_RELOAD, layoutSlot = 1,
	},
	primarycount = {
		mincolor = {0.03, 0.4, 0.4, 1.0},
		maxcolor = {0.05, 0.6, 0.6, 1.0},
		bartype = bitShowGlyph + bitUseOverlay + bitIntegerNumber + bitLeft + bitVertical,
		hidethreshold = 0.99,
		uniformindex = unitPrimaryCountChannel,
		uvoffset = VBAR_COL_GENERIC_RELOAD, -- overridden per-unit by weapon_class in addBarForUnit
	},
	-- Individual burst reload bars (ch9-12, sorted most-loaded first).
	-- Added dynamically up to burstCount; value 0.0 hides naturally via isVarForChannelVisible.
	bustreload1 = { -- burst weapons are "related": all in the left column, stacked
		mincolor = {0.03, 0.4, 0.4, 1.0}, maxcolor = {0.05, 0.6, 0.6, 1.0},
		bartype = bitPercentage + bitColorCorrect + bitLeft + bitVertical,
		hidethreshold = 0.99, uniformindex = unitPrimaryReloadChannel, uvoffset = VBAR_COL_GENERIC_RELOAD, layoutSlot = 0,
	},
	bustreload2 = {
		mincolor = {0.03, 0.4, 0.4, 1.0}, maxcolor = {0.05, 0.6, 0.6, 1.0},
		bartype = bitPercentage + bitColorCorrect + bitLeft + bitVertical,
		hidethreshold = 0.99, uniformindex = unitPrimaryCountChannel, uvoffset = VBAR_COL_GENERIC_RELOAD, layoutSlot = 1,
	},
	bustreload3 = {
		mincolor = {0.03, 0.4, 0.4, 1.0}, maxcolor = {0.05, 0.6, 0.6, 1.0},
		bartype = bitPercentage + bitColorCorrect + bitLeft + bitVertical,
		hidethreshold = 0.99, uniformindex = unitSecondaryReloadChannel, uvoffset = VBAR_COL_GENERIC_RELOAD, layoutSlot = 2,
	},
	bustreload4 = {
		mincolor = {0.03, 0.4, 0.4, 1.0}, maxcolor = {0.05, 0.6, 0.6, 1.0},
		bartype = bitPercentage + bitColorCorrect + bitLeft + bitVertical,
		hidethreshold = 0.99, uniformindex = unitSecondaryCountChannel, uvoffset = VBAR_COL_GENERIC_RELOAD, layoutSlot = 3,
	},
	dgun = {
		mincolor = {1.0, 1.0, 1.0, 1.0},
		maxcolor = {1.0, 1.0, 1.0, 1.0},
		bartype = bitModular + bitInverse + bitRight + bitVertical,
		hidethreshold = 0.99,
		uniformindex = unitSecondaryReloadChannel,
		uvoffset = VBAR_COL_DGUN,
	},
	-- Gauges (radial fill = current 0..1 level, not a countdown). maxcolor is the fill color.
	teleport = { -- non-weapon ability -> below zone (no left/right). frame-based countdown to teleportend.
		mincolor = {0.2, 0.8, 1.0, 1.0},
		maxcolor = {0.2, 0.8, 1.0, 1.0}, -- cyan
		bartype = bitVertical + bitModular + bitInverse, -- radial timer; fills as it completes
		hidethreshold = 0.99,
		uniformindex = unitSecondaryReloadChannel,
		uvoffset = 0,
		statusIcon = "teleport", -- beacon symbol
	},
	heat = {
		mincolor = {1.0, 0.45, 0.1, 1.0},
		maxcolor = {1.0, 0.45, 0.1, 1.0}, -- orange (heat)
		bartype = bitVertical + bitGauge + bitRight,
		hidethreshold = 0.99,
		uniformindex = unitSecondaryReloadChannel,
		uvoffset = -1, -- one-off; no symbol (fill + color identify it)
	},
	speed = {
		mincolor = {1.0, 0.9, 0.2, 1.0},
		maxcolor = {1.0, 0.9, 0.2, 1.0}, -- yellow (superweapon charge warning)
		bartype = bitVertical + bitGauge + bitRight,
		hidethreshold = 0.99,
		uniformindex = unitSecondaryReloadChannel,
		uvoffset = -1, -- one-off; no symbol (fill + color identify it)
	},
	reammo = { -- rearm -> below zone rate-ETA: counts down while rearming on a pad, grey static off-pad.
		mincolor = {1.0, 0.6, 0.1, 1.0},
		maxcolor = {1.0, 0.6, 0.1, 1.0}, -- orange (ammo / forward-progress band color)
		bartype = bitVertical + bitRateETA,
		hidethreshold = 0.99,
		uniformindex = unitPrimaryReloadChannel,
		uvoffset = 0,
		statusIcon = "rearm",
	},
	goo = { -- Puppy goo -> below zone pausable ETA: smooth countdown to replication while reclaiming next
		-- to metal, needle frozen (static) when stopped. Same badge look either way.
		mincolor = {0.6, 0.9, 0.3, 1.0},
		maxcolor = {0.6, 0.9, 0.3, 1.0}, -- greenish (goo)
		bartype = bitVertical + bitRateETA,
		hidethreshold = 0.99,
		uniformindex = unitGooChannel,
		uvoffset = 0,
		statusIcon = "goo",
	},
	-- Jump charges -> below zone. One per charge (jump/jump2/jump3); all read the same slot (a
	-- reconstructed jumpReload, 0..charges) and each subtracts its baked charge index, so charge N shows
	-- full once jumpReload passes N. Per-instance: uvoffset = chargeIndex + charges*16, range = reload
	-- frames, layoutSlot = packed (index, below-count). Separate barTypeMap names so removal iterates them.
	jump = { -- movement ability -> below zone. gauge per jump charge.
		mincolor = {0.4, 0.9, 0.5, 1.0},
		maxcolor = {0.4, 0.9, 0.5, 1.0}, -- green (movement/jump)
		bartype = bitVertical + bitGauge + bitJumpCharge,
		hidethreshold = 0.99,
		uniformindex = unitMovementChannel,
		uvoffset = 0,
	},
	jump2 = {
		mincolor = {0.4, 0.9, 0.5, 1.0},
		maxcolor = {0.4, 0.9, 0.5, 1.0},
		bartype = bitVertical + bitGauge + bitJumpCharge,
		hidethreshold = 0.99,
		uniformindex = unitMovementChannel,
		uvoffset = 0,
	},
	jump3 = {
		mincolor = {0.4, 0.9, 0.5, 1.0},
		maxcolor = {0.4, 0.9, 0.5, 1.0},
		bartype = bitVertical + bitGauge + bitJumpCharge,
		hidethreshold = 0.99,
		uniformindex = unitMovementChannel,
		uvoffset = 0,
	},
	captureReload = {
		mincolor = {0.0, 0.0, 0.0, 0.0},
		maxcolor = {0.0, 0.0, 0.0, 0.0},
		bartype = bitPercentage + bitModular + bitInverse + bitLeft + bitVertical,
		hidethreshold = 0.99,
		uniformindex = unitPrimaryReloadChannel,
		uvoffset = VBAR_COL_CAPTURERELOAD,
	},
	ability = { -- Swift sprint etc.: non-weapon movement ability -> below zone (like jump). gauge fills
		-- as it recharges (specialReloadRemaining counts down, so bitInverse turns it into a charge level).
		mincolor = {0.4, 0.9, 0.5, 1.0},
		maxcolor = {0.4, 0.9, 0.5, 1.0}, -- green (movement ability, matches jump)
		bartype = bitVertical + bitModular + bitInverse, -- frame-based cooldown; fills as it recharges
		hidethreshold = 0.99,
		uniformindex = unitMovementChannel,
		uvoffset = 0,
		statusIcon = "ability", -- sprint symbol
	},
	stockpile = {
		-- rate-ETA to the next missile (frame-based, grey static when stalled). The ready count is the
		-- stockpilecount glyph co-located on this badge (same right-column slot 0).
		mincolor = {0.6, 0.8, 1.0, 1.0},
		maxcolor = {0.6, 0.8, 1.0, 1.0}, -- light blue (forward-progress band color)
		bartype = bitVertical + bitRateETA + bitRight,
		hidethreshold = 1.99,
		uniformindex = unitSecondaryReloadChannel,
		uvoffset = 0,
		statusIcon = "stockpile", -- missile symbol
	},
	stockpilecount = {
		-- integer readout of ready stockpiled missiles (ch12), drawn centered on the stockpile gauge.
		mincolor = {0.6, 0.8, 1.0, 1.0},
		maxcolor = {0.6, 0.8, 1.0, 1.0}, -- light blue
		bartype = bitShowGlyph + bitUseOverlay + bitIntegerNumber + bitVertical + bitRight,
		hidethreshold = 1.99,
		uniformindex = unitSecondaryCountChannel,
		uvoffset = 0,
		layoutSlot = 0, -- same slot as the stockpile gauge so the number overlays it
	},
	shield = {
		maxcolor = {0.1, 0.1, 1.0, 1.0},
		mincolor = {1.0, 0.1, 0.1, 1.0},
		bartype = bitShowGlyph + bitUseOverlay + bitPercentage + bitInverse,
		hidethreshold = 0.99,
		uniformindex = unitShieldChannel,
		uvoffset = 1,
		fill = "shield",
	},
	capture = {
		mincolor = {0.6, 1.0, 0.7, 1.0},
		maxcolor =  {0.6, 1.0, 0.7, 1.0},
		bartype = bitShowGlyph + bitUseOverlay + bitPercentage,
		hidethreshold = 0.99,
		uniformindex = unitCaptureChannel,
		uvoffset = 0,
		fill = "capture",
	},
	featurehealth = {
		mincolor = {0.25, 0.25, 0.25, 1.0},
		maxcolor = {0.65, 0.65, 0.65, 1.0},
		bartype = bitShowGlyph + bitPercentage,
		hidethreshold = 0.99,
		uniformindex = featureHealthChannel,
		uvoffset = 18,
		fill = "health",
	},
	featurereclaim = {
		-- white so the pre-colored fill art (reclaim.png) shows as authored (fill is color-multiplied)
		mincolor = {1.0, 1.0, 1.0, 1.0},
		maxcolor = {1.0, 1.0, 1.0, 1.0},
		bartype = bitShowGlyph + bitPercentage,
		hidethreshold = 0.99,
		uniformindex = featureReclaimChannel,
		uvoffset = 4,
		fill = "reclaim",
	},
	featureresurrect = {
		-- Resurrect ("raise") progress fill bar (channel = resurrect progress 0..1, 0 when not raising).
		-- White so the pre-colored fill art (resurrect.png) shows as authored.
		mincolor = {1.0, 1.0, 1.0, 1.0},
		maxcolor = {1.0, 1.0, 1.0, 1.0},
		bartype = bitShowGlyph + bitPercentage,
		hidethreshold = 0.99,
		uniformindex = featureResurrectChannel,
		uvoffset = 5,
		fill = "resurrect",
	},
	icon = {
		mincolor = {1.0, 1.0, 1.0, 1.0},
		maxcolor = {1.0, 1.0, 1.0, 1.0},
		bartype = bitIcon,
		hidethreshold = -1,
		uniformindex = 0,
		uvoffset = 0,
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
	cache[8] = bt.layoutSlot or 0 -- layout slot within its zone (rides bartype_index_ssboloc.w)

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



local spec, fullview = Spring.GetSpectatingState()
local myTeamID = Spring.GetMyTeamID()
local myAllyTeamID = Spring.GetMyAllyTeamID()
local myPlayerID = Spring.GetMyPlayerID()
local gameSpeed = Game.gameSpeed

-- Count of persistent below-zone badges per unitDef (jump charges + sprint + teleport). Set in
-- addBarsForUnit; read when adding the transient morph badge so it centers within the same run.
local unitDefBelowCount = {}
local unitDefBelowMask = {} -- bitmask of the persistent below-badge channels, so the live morph badge can
                            -- count how many are currently VISIBLE (slot nonzero) and re-center the run

local chobbyInterface


local featureDefHeights = {} -- maps FeatureDefs to height


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
	BGBOTTOMCOLOR = "vec4(0.25, 0.25, 0.25, 1.0)",
	BGTOPCOLOR = "vec4(0.1, 0.1, 0.1, 1.0)",
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
	ICONATLAS_COLS = 16,
	ICONATLAS_ROWS = 32,
	BARFILLCELLS = 9, -- a 576px horizontal fill bar spans this many 64px atlas cells
	ICONCORNERSCALE = 0.5, -- corner badge (rank/group) size as a fraction of the unit icon's half-extent
}
shaderConfig.BARCORNER = 0.06 + (shaderConfig.BARHEIGHT / 9)
shaderConfig.SMALLERCORNER = shaderConfig.BARCORNER * 0.6

-- Bit-pack descriptor arrays for the shader's readField (generated from channelPack in gl_uniform_channels).
local packFloatInit, packOffsetInit, packWidthInit, packTypeInit = buildChannelPackDefines()
shaderConfig.PACK_FLOAT_INIT = packFloatInit
shaderConfig.PACK_OFFSET_INIT = packOffsetInit
shaderConfig.PACK_WIDTH_INIT = packWidthInit
shaderConfig.PACK_TYPE_INIT = packTypeInit

if debugmode then
	shaderConfig.DEBUGSHOW = 1 -- comment this to always show all bars
end

local vsSrcPath = "LuaUI/Widgets/Shaders/UnitOverlayGL4.vert.glsl"
local gsSrcPath = "LuaUI/Widgets/Shaders/UnitOverlayGL4.geom.glsl"
local fsSrcPath = "LuaUI/Widgets/Shaders/UnitOverlayGL4.frag.glsl"

local shaderSourceCache = {
		vssrcpath = vsSrcPath,
		fssrcpath = fsSrcPath,
		gssrcpath = gsSrcPath,
		shaderName = "Health Bars Shader GL4",
		uniformInt = {
			iconAtlasTex = 1,
			},
		uniformFloat = {
			--addRadius = 1,
			jumpIconCell = 0,
			iconDistance = 27,
			cameraDistanceMult = 1.0,
			cameraDistanceMultGlyph = 4.0,
			skipGlyphsNumbers = 0.0,
			overallScale = 1.0,
			barSize = 1.0,
			vbarUserX  = 0.0,
			vbarSize   = 1.0,
			iconSize   = 1.0,
			barBorderWidth = 0.25,
			trackDarken = 0.25,
			reloadThreshold = 2.0,
			pulseAlpha   = 1.0,
			rowOffset    = 0.0,
			rowSize      = 1.0,
			rowSpacing   = 1.0,
			isFeature    = 0.0,
			barOffset    = 0.0,
			barSpacing   = 1.0,
			belowBadgeHeight = 0.0,
			overlayDepthBand = 0.0,
		  },
		shaderConfig = shaderConfig,
	}

-- Walk through unitdefs for the stuff we need:
for udefID, unitDef in pairs(UnitDefs) do
	-- BAR PLACEMENT
	unitDefHeights[udefID] = unitDef.height
	unitDefSizeMultipliers[udefID] = math.min(1.45, math.max(0.85, (Spring.GetUnitDefDimensions(udefID).radius / 150) + math.min(0.6, unitDef.power / 4000))) + math.min(0.6, unitDef.health / 22000)
end

for fdefID, featureDef in pairs(FeatureDefs) do
	--Spring.Echo(featureDef.name, featureDef.height)
	featureDefHeights[fdefID] = featureDef.height or 32
end

local function goodbye(reason)
  Spring.Echo("Unit Overlay GL4 widget exiting with reason: "..reason)
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

local iconAtlasIndexToPath = {}
local iconAtlasNextIndex = 0
local iconAtlasReady = false
-- gl.Texture() can report a texture as bound (and TextureInfo gives its size) before its pixels are
-- actually uploaded to the GPU, so the first blit copies a BLANK cell yet we'd mark the atlas ready.
-- Keep re-blitting for a short settle window so those late uploads get captured. (Diagnosed via the
-- debug logging: every attempt showed allLoaded=true / bound=true / xsize=64 yet the cell was blank.)
local ICON_ATLAS_SETTLE_FRAMES = 15
local iconAtlasSettle = 0
local dbgAtlasAttempt = 0 -- DEBUG (remove later): renderIconAtlas attempts since the last build

-- Dynamic atlas insertion for arbitrary WG.icons textures (states/ranks/gadget/build icons). The
-- atlas is an FBO, so new textures are blitted into free cells at runtime (flushed in DrawWorld).
local dynamicIconIndex = {}     -- texture path -> atlas cell
local pendingDynamicIcons = {}  -- {path, cell} awaiting a blit into the atlas FBO
local function registerDynamicIcon(path)
	if not path then return nil end
	if dynamicIconIndex[path] then return dynamicIconIndex[path] end
	if iconAtlasNextIndex >= iconAtlasCols * iconAtlasRows then
		Spring.Echo("Unit Overlay GL4: icon atlas full, cannot add", path)
		return nil
	end
	local cell = iconAtlasNextIndex
	iconAtlasNextIndex = iconAtlasNextIndex + 1
	dynamicIconIndex[path] = cell
	pendingDynamicIcons[#pendingDynamicIcons + 1] = { path = path, cell = cell }
	return cell
end

-- Blit any newly-registered icon textures into the existing atlas FBO. Must run in a GL context
-- (called from DrawWorld). FBO content persists, so this appends without disturbing prior cells.
local function flushPendingIcons()
	if not iconAtlasReady or #pendingDynamicIcons == 0 then return end
	local stillPending = {} -- icons whose texture hasn't finished loading get retried next frame
	gl.RenderToTexture(iconAtlasTexture, function()
		-- Explicit state: the blit must be an exact copy regardless of whatever GL state the previous
		-- (possibly just-reloaded) widget left behind -- a stale gl.Color or blend mode otherwise makes
		-- the atlas come out modulated/blank, which alternates across /luaui reloads.
		gl.DepthTest(false)
		gl.Blending(false)
		gl.Color(1, 1, 1, 1)
		for i = 1, #pendingDynamicIcons do
			local e = pendingDynamicIcons[i]
			if VFS.FileExists(e.path) then
				local col = e.cell % iconAtlasCols
				local row = math.floor(e.cell / iconAtlasCols)
				if gl.Texture(e.path) then
					gl.TexRect((col / iconAtlasCols) * 2 - 1, (row / iconAtlasRows) * 2 - 1,
						((col + 1) / iconAtlasCols) * 2 - 1, ((row + 1) / iconAtlasRows) * 2 - 1)
				else
					stillPending[#stillPending + 1] = e -- not loaded yet
				end
				gl.Texture(false)
			end
		end
	end)
	pendingDynamicIcons = stillPending
end

--------------------------------------------------------------------------------
-- WG.icons backend: the overlay renders all hovering icons (states, ranks, gadget, build commands)
-- as instanced billboards in a centered row above each unit, replacing the legacy unit_icons.lua.
-- Provider widgets call WG.icons.SetUnitIcon/etc. unchanged. State changes mark a unit dirty;
-- the actual instance push/pop + atlas blits happen in DrawWorld (GL + VBO ready).
--------------------------------------------------------------------------------
-- We hand the per-unit count of visible state icons to the shader so it can center the states and the
-- GPU-counted status badges as one combined row (channel 15 = userDefined[3][3]). The uniform updater
-- owns the GL write (sole writer of the unit buffer); we push the count via WG.SetUnitStateCount.
local function writeStateCount(unitID, count)
	if WG.SetUnitStateCount then
		WG.SetUnitStateCount(unitID, count)
	end
end

-- Providers register their icons once (often only on a state *change*) and cache that they did, so
-- they won't re-send when THIS widget reloads. The registry is therefore persisted on WG and restored
-- here; per-unit entries keep the texture path so cells can be re-resolved against the rebuilt atlas.
local iconState = WG.unitOverlayIconState or {}
WG.unitOverlayIconState = iconState
iconState.order  = iconState.order  or {} -- iconName -> order (lower = leftmost)
iconState.hidden = iconState.hidden or {} -- iconName -> true (globally hidden category)
iconState.pulse  = iconState.pulse  or {} -- iconName -> true (flashing)
iconState.units  = iconState.units  or {} -- unitID -> { iconName -> {path, color} }

local wgIconOrder = iconState.order
local wgIconHidden = iconState.hidden
local wgIconPulse = iconState.pulse
local wgUnitIcons = iconState.units
local wgIconOrderList = {}   -- iconNames sorted by order (rebuilt from wgIconOrder below)
local wgUnitPushedNames = {} -- unitID -> { iconName -> true } currently in the VBO
local wgDirtyUnits = {}      -- unitID -> true, needs relayout in DrawWorld
local wgUnitGroup = {}       -- unitID -> control-group digit (0-9), drawn as a bottom-right corner badge
local wgUnitCommand = {}     -- unitID -> current-command atlas cell, drawn as a bottom-left corner badge
local groupCornerColor = {0.7, 1.0, 0.7, 1.0} -- tint for the group-number digit (matches the old gl.Text)

for n in pairs(wgIconOrder) do wgIconOrderList[#wgIconOrderList + 1] = n end
table.sort(wgIconOrderList, function(a, b) return wgIconOrder[a] < wgIconOrder[b] end)

local function wgReorder(name, order)
	wgIconOrder[name] = order
	wgIconOrderList = {}
	for n in pairs(wgIconOrder) do wgIconOrderList[#wgIconOrderList + 1] = n end
	table.sort(wgIconOrderList, function(a, b) return wgIconOrder[a] < wgIconOrder[b] end)
end

local function wgNewIconCache(cell, slot, rowHeight, color, pulse, sizeMod)
	local c = {}
	for i = 1, 20 do c[i] = 0 end
	c[1] = rowHeight   -- per-instance height (vert raises centerpos.y by this)
	c[2] = sizeMod     -- sizeModifier: matches the bars' effectiveScale so the row tracks the bar stack
	c[3] = slot        -- raw 0-based state index (rides v_range; the shader centers it across the row)
	c[4] = cell        -- atlas cell (UVOFFSET)
	c[5] = bitIcon + bitIconRow + (pulse and bitPulse or 0) -- bartype
	local r, g, b, a = 1, 1, 1, 1
	if color then r, g, b, a = color[1], color[2], color[3], color[4] or 1 end
	c[9], c[10], c[11], c[12] = r, g, b, a
	c[13], c[14], c[15], c[16] = r, g, b, a
	return c
end

-- A badge pinned to a corner of the unit icon (cornerSlot: 0 = top-left, 1 = bottom-right). Shares the
-- icon's baseline height + scale so it tracks the unit icon; the geom (BITICONCORNER) does the offset.
-- The center unit icon, with the rank badge (top-left) and group number (bottom-right) composited onto
-- the SAME quad by the shader -- one primitive at one depth, so nothing z-fights or sorts between them.
-- rankCell/groupCell are atlas cells (nil = absent); the shader reads rank from v_range and group from
-- bartype_index.w. teamColor tints the icon (mincolor); rankColor tints the rank badge (maxcolor); the
-- group number is tinted green by the FS.
local function wgNewClusterIconCache(iconCell, rankCell, groupCell, cmdCell, rowHeight, teamColor, rankColor, sizeMod)
	local c = {}
	for i = 1, 20 do c[i] = 0 end
	c[1] = rowHeight
	c[2] = sizeMod
	c[3] = rankCell or -1          -- v_range -> rank atlas cell (-1 = no rank)
	c[4] = iconCell or 0           -- uvOffset -> icon atlas cell
	c[5] = bitIcon                 -- center unit icon (FS composites rank+group+command)
	c[7] = cmdCell or 65535        -- bartype_index.z -> current-command atlas cell (>=60000 = none)
	c[8] = groupCell or 65535      -- bartype_index.w -> group atlas cell (>=60000 = no group)
	local r, g, b, a = 1, 1, 1, 1
	if teamColor then r, g, b, a = teamColor[1], teamColor[2], teamColor[3], teamColor[4] or 1 end
	c[9], c[10], c[11], c[12] = r, g, b, a       -- mincolor = team color (icon tint)
	local rr, rg, rb = 1, 1, 1
	if rankColor then rr, rg, rb = rankColor[1], rankColor[2], rankColor[3] end
	c[13], c[14], c[15], c[16] = rr, rg, rb, 1   -- maxcolor = rank tint
	return c
end

-- Pop a unit's icon instances and re-push the currently-visible ones, recentered. Runs in DrawWorld.
local function relayoutUnitIcons(unitID)
	local pushed = wgUnitPushedNames[unitID]
	if pushed then
		for name in pairs(pushed) do
			local key = unitID .. "_wgicon_" .. name
			if healthBarVBO.instanceIDtoIndex[key] then popElementInstance(healthBarVBO, key) end
		end
		wgUnitPushedNames[unitID] = nil
	end
	if not Spring.ValidUnitID(unitID) then
		wgUnitIcons[unitID] = nil -- unit is really gone; drop stale state
		wgUnitGroup[unitID] = nil
		wgUnitCommand[unitID] = nil
		return
	end
	local unitDefID = Spring.GetUnitDefID(unitID)
	local cp = UnitDefs[unitDefID or -1]
	local extra = (cp and cp.customParams and tonumber(cp.customParams.health_bar_height)) or 0
	-- Same centred baseline as the bars; the row rides above the top bar, the icon sits at the centre.
	local rowHeight = (Spring.GetUnitHeight(unitID) or unitDefHeights[unitDefID] or 0) * 0.5 + extra
	local effectiveScale = ((variableBarSizes and unitDefSizeMultipliers[unitDefID]) or 1.0) * barScale

	local icons = wgUnitIcons[unitID]
	local group = wgUnitGroup[unitID]
	local rankData = icons and icons['rank']
	local rankVisible = rankData and not wgIconHidden['rank']
	local groupVisible = group and not wgIconHidden['group']

	local pushedNames = {}

	-- ONE quad: the centre unit icon, with the rank badge (top-left) and group number (bottom-right)
	-- composited onto it by the shader, so all three share a single depth (no z-fight, nothing sorts
	-- between them). rank/group are optional atlas cells passed on the icon instance.
	local rankCell
	if rankVisible then
		rankCell = registerDynamicIcon(rankData.path) or rankData.cell
		rankData.cell = rankCell
	end
	local groupCell = groupVisible and digitAtlasIndex[group] or nil
	-- current command (bottom-left corner): cell maintained by the throttled command poll; gated by the
	-- 'command' visibility option (Always/Shift/Never) via wgIconHidden, like rank/group.
	local commandCell = (not wgIconHidden['command']) and wgUnitCommand[unitID] or nil
	local teamID = Spring.GetUnitTeam(unitID)
	local tr, tg, tb, ta = Spring.GetTeamColor(teamID)
	pushElementInstance(healthBarVBO,
		wgNewClusterIconCache(unitDefIconIndex[unitDefID] or 0, rankCell, groupCell, commandCell, rowHeight,
			{tr or 1, tg or 1, tb or 1, ta or 1}, rankData and rankData.color, effectiveScale),
		unitID .. "_wgicon_icon", true, nil, unitID)
	pushedNames['icon'] = true

	-- State-icon row (excludes rank/group, which are now corners of the icon above).
	local visible = {}
	if icons then
		for i = 1, #wgIconOrderList do
			local name = wgIconOrderList[i]
			if name ~= 'rank' and icons[name] and not wgIconHidden[name] then
				visible[#visible + 1] = name
			end
		end
	end
	local count = #visible
	writeStateCount(unitID, count) -- the shader centers states + status badges around this count
	for i = 1, count do
		local name = visible[i]
		local data = icons[name]
		-- Resolve the cell from the texture path: a persisted entry that survived a reload still
		-- carries the path, but its cached cell points into the old (pre-rebuild) atlas.
		local cell = registerDynamicIcon(data.path) or data.cell
		data.cell = cell
		pushElementInstance(healthBarVBO,
			wgNewIconCache(cell, i - 1, rowHeight, data.color, wgIconPulse[name], effectiveScale),
			unitID .. "_wgicon_" .. name, true, nil, unitID)
		pushedNames[name] = true
	end
	wgUnitPushedNames[unitID] = pushedNames
end

local function processDirtyIcons()
	if not iconAtlasReady or not next(wgDirtyUnits) then return end
	for unitID in pairs(wgDirtyUnits) do
		relayoutUnitIcons(unitID)
	end
	wgDirtyUnits = {}
end

-- Control-group numbers (bottom-right corner badge). The overlay is the single renderer; it polls the
-- engine's control groups and diffs membership so units that join/leave a group are relaid out.
local lastPolledGroup = {} -- unitID -> group last seen by the poll (for clear-on-leave)
local function setUnitGroupNumber(unitID, group)
	if wgUnitGroup[unitID] == group then return end
	wgUnitGroup[unitID] = group
	wgDirtyUnits[unitID] = true
end

local function refreshGroupNumbers()
	local current = {}
	if not wgIconHidden['group'] then
		for groupID in pairs(Spring.GetGroupList() or {}) do
			local units = Spring.GetGroupUnits(groupID) or {}
			for i = 1, #units do current[units[i]] = groupID end
		end
	end
	for unitID in pairs(lastPolledGroup) do
		if current[unitID] == nil then setUnitGroupNumber(unitID, nil) end
	end
	for unitID, groupID in pairs(current) do
		setUnitGroupNumber(unitID, groupID)
	end
	lastPolledGroup = current
end

-- Current-command corner (bottom-left). Maps the unit's active command to a Bold/ command icon, polled on
-- a throttle and diffed like the group numbers. registerDynamicIcon is idempotent (returns the cached
-- cell), so re-polling the same command is cheap, and only changed units get re-pushed.
local SUCMD = Spring.Utilities and Spring.Utilities.CMD
local commandIconPath = {
	[CMD.MOVE]         = "LuaUI/Images/commands/Bold/move.png",
	[CMD.ATTACK]       = "LuaUI/Images/commands/Bold/attack.png",
	[CMD.FIGHT]        = "LuaUI/Images/commands/Bold/fight.png",
	[CMD.PATROL]       = "LuaUI/Images/commands/Bold/patrol.png",
	[CMD.GUARD]        = "LuaUI/Images/commands/Bold/guard.png",
	[CMD.REPAIR]       = "LuaUI/Images/commands/Bold/repair.png",
	[CMD.RECLAIM]      = "LuaUI/Images/commands/Bold/reclaim.png",
	[CMD.RESURRECT]    = "LuaUI/Images/commands/Bold/resurrect.png",
	[CMD.CAPTURE]      = "LuaUI/Images/commands/Bold/capture.png",
	[CMD.LOAD_UNITS]   = "LuaUI/Images/commands/Bold/load.png",
	[CMD.UNLOAD_UNITS] = "LuaUI/Images/commands/Bold/unload.png",
	[CMD.MANUALFIRE]   = "LuaUI/Images/commands/Bold/dgun.png",
	[CMD.WAIT]         = "LuaUI/Images/commands/Bold/wait.png",
}
if SUCMD then
	if SUCMD.RAW_MOVE  then commandIconPath[SUCMD.RAW_MOVE]  = "LuaUI/Images/commands/Bold/move.png" end
	if SUCMD.RAW_BUILD then commandIconPath[SUCMD.RAW_BUILD] = "LuaUI/Images/commands/Bold/build.png" end
	if SUCMD.JUMP      then commandIconPath[SUCMD.JUMP]      = "LuaUI/Images/commands/Bold/jump.png" end
end

local function commandCellFor(unitID)
	local cmdID = Spring.GetUnitCurrentCommand(unitID)
	if not cmdID then return nil end -- idle, no command
	local path = (cmdID < 0) and "LuaUI/Images/commands/Bold/build.png" or commandIconPath[cmdID]
	return path and registerDynamicIcon(path) or nil
end

local function refreshUnitCommands()
	if wgIconHidden['command'] then return end -- display off -> skip the poll entirely
	for unitID in pairs(wgUnitPushedNames) do
		local cell = commandCellFor(unitID)
		if wgUnitCommand[unitID] ~= cell then
			wgUnitCommand[unitID] = cell
			wgDirtyUnits[unitID] = true
		end
	end
end

WG.icons = {}

function WG.icons.SetUnitIcon(unitID, data)
	local name = data.name
	if not name then return end
	if not wgIconOrder[name] then wgReorder(name, math.huge) end
	local icons = wgUnitIcons[unitID]
	if data.texture then
		local cell = registerDynamicIcon(data.texture)
		if not cell then return end
		if not icons then icons = {}; wgUnitIcons[unitID] = icons end
		icons[name] = { cell = cell, color = data.color, path = data.texture }
	elseif icons then
		icons[name] = nil
	end
	wgDirtyUnits[unitID] = true
end

function WG.icons.SetDisplay(name, show)
	local hide = (not show) or nil
	if wgIconHidden[name] ~= hide then
		wgIconHidden[name] = hide
		for unitID in pairs(wgUnitIcons) do wgDirtyUnits[unitID] = true end
	end
end

function WG.icons.SetOrder(name, order)
	wgReorder(name, order)
	for unitID in pairs(wgUnitIcons) do wgDirtyUnits[unitID] = true end
end

function WG.icons.SetPulse(name, pulse)
	wgIconPulse[name] = pulse or nil
	for unitID, icons in pairs(wgUnitIcons) do
		if icons[name] then wgDirtyUnits[unitID] = true end
	end
end

-- State-icon visibility control (single source of truth). Driven by the 'Unit States' options above:
-- bool options map straight to show/hide; tri-state options resolve Always/Never directly and 'shift'
-- against whether Shift is currently held (tracked via KeyPress/KeyRelease -> refreshShift).
local stateShiftHeld = false
function stateCtl.apply(name)
	local opt = options['state_' .. name]
	if not opt then return end
	local show
	if opt.type == 'bool' then
		show = opt.value and true or false
	elseif opt.value == 'always' then
		show = true
	elseif opt.value == 'never' then
		show = false
	else -- 'shift'
		show = stateShiftHeld
	end
	WG.icons.SetDisplay(name, show)
	-- group numbers aren't pushed through WG.icons (they're polled), so re-evaluate membership now
	-- that the hidden flag changed (adds badges when enabled, clears them when disabled).
	if name == 'group' then refreshGroupNumbers() end
	-- the current-command corner is also polled, not pushed through WG.icons. Re-dirty every drawn icon
	-- so the corner appears/disappears immediately, then (re)poll to fill the cells.
	if name == 'command' then
		for u in pairs(wgUnitPushedNames) do wgDirtyUnits[u] = true end
		refreshUnitCommands()
	end
end

function stateCtl.applyAll()
	for _, s in ipairs(stateIconBool) do stateCtl.apply(s.name) end
	for _, s in ipairs(stateIconTri) do stateCtl.apply(s.name) end
end

-- Re-evaluate Shift-gated states when the Shift key state changes.
function stateCtl.refreshShift()
	local _, _, _, shift = Spring.GetModKeyState()
	shift = shift and true or false
	if shift ~= stateShiftHeld then
		stateShiftHeld = shift
		for _, s in ipairs(stateIconTri) do
			if options['state_' .. s.name].value == 'shift' then stateCtl.apply(s.name) end
		end
	end
end

-- Called from UnitDestroyed (which UnitFinished also reuses). Pop the unit's icon instances and mark
-- it dirty: relayout next frame re-pushes them if the unit is still alive (UnitFinished case) or
-- clears the stale state if it's really gone (relayout's ValidUnitID check).
local function onUnitIconHolderReset(unitID)
	local pushed = wgUnitPushedNames[unitID]
	if pushed and healthBarVBO then
		for name in pairs(pushed) do
			local key = unitID .. "_wgicon_" .. name
			if healthBarVBO.instanceIDtoIndex[key] then popElementInstance(healthBarVBO, key) end
		end
		wgUnitPushedNames[unitID] = nil
	end
	if wgUnitIcons[unitID] then wgDirtyUnits[unitID] = true end
end

-- After the healthBarVBO is wiped (init / VisibleUnitsChanged), our icon instances are gone too;
-- forget them and re-push from the preserved state next frame.
local function requeueAllIcons()
	wgUnitPushedNames = {}
	for unitID in pairs(wgUnitIcons) do wgDirtyUnits[unitID] = true end
	for unitID in pairs(wgUnitGroup) do wgDirtyUnits[unitID] = true end -- group-only units have no wgUnitIcons entry
end

local function buildIconAtlas()
	local iconTypeToIndex = {}

	for udefID, unitDef in pairs(UnitDefs) do
		local iconType = unitDef.iconType or "default"
		if not iconTypeToIndex[iconType] then
			local iconDef = icontypes[iconType]
			local texPath
			if iconDef and iconDef.bitmap then
				texPath = iconDef.bitmap
			else
				texPath = 'icons/' .. iconType .. iconFormat
				if not VFS.FileExists(texPath) then
					texPath = 'icons/default' .. iconFormat
				end
			end
			iconTypeToIndex[iconType] = iconAtlasNextIndex
			iconAtlasIndexToPath[iconAtlasNextIndex] = texPath
			iconAtlasNextIndex = iconAtlasNextIndex + 1
		end
		unitDefIconIndex[udefID] = iconTypeToIndex[iconType]
	end

	-- (Reload-badge icons are no longer pre-registered here: each weapon's `icon` customParam path is
	-- registered on demand via registerDynamicIcon when the reload bar is added.)

	-- Status-duration badge icons (one cell each) from the Bold command icon set.
	for status, img in pairs(statusIconImage) do
		local path = "LuaUI/Images/commands/Bold/" .. img .. ".png"
		if VFS.FileExists(path) then
			statusIconIndex[status] = iconAtlasNextIndex
			iconAtlasIndexToPath[iconAtlasNextIndex] = path
			iconAtlasNextIndex = iconAtlasNextIndex + 1
		end
	end

	-- Jump-charge gauge badge icon (one cell): composited into the jump gauges by the shader.
	if VFS.FileExists(jumpIconPath) then
		jumpIconAtlasIndex = iconAtlasNextIndex
		iconAtlasIndexToPath[iconAtlasNextIndex] = jumpIconPath
		iconAtlasNextIndex = iconAtlasNextIndex + 1
	end

	-- Reserve a run of `count` contiguous cells for a wide image (digit strip / fill bar), kept
	-- within a single atlas row so renderIconAtlas can blit it in one piece -- a run that wrapped
	-- past the row edge would split across rows. Pads to the next row start if it wouldn't fit in
	-- the current row's remainder. Returns the starting cell index, or nil if the file is missing.
	local function addStripToAtlas(path, count)
		if not VFS.FileExists(path) then return nil end
		if (iconAtlasNextIndex % iconAtlasCols) + count > iconAtlasCols then
			iconAtlasNextIndex = (math.floor(iconAtlasNextIndex / iconAtlasCols) + 1) * iconAtlasCols
		end
		local startIndex = iconAtlasNextIndex
		iconAtlasIndexToPath[startIndex] = { strip = path, count = count }
		iconAtlasNextIndex = iconAtlasNextIndex + count
		return startIndex
	end

	-- Digit strip: 12 glyphs in one row; record where each digit/symbol landed.
	local digitStart = addStripToAtlas(digitStripPath, #digitStripGlyphs)
	if digitStart then
		digitAtlasStartIndex = digitStart
		for i, glyph in ipairs(digitStripGlyphs) do
			digitAtlasIndex[glyph] = digitStart + (i - 1)
		end
	end

	-- Horizontal fill bars: each 576x64 fill occupies barFillCells (9) contiguous cells.
	for _, name in ipairs(barAtlasFills) do
		local idx = addStripToAtlas("LuaUI/Images/bars/" .. name .. ".png", barFillCells)
		if idx then barAtlasIndex[name] = idx end
	end

	local atlasW = iconAtlasCols * iconAtlasCellSize
	local atlasH = iconAtlasRows * iconAtlasCellSize
	iconAtlasTexture = gl.CreateTexture(atlasW, atlasH, {
		min_filter = GL.LINEAR,
		mag_filter = GL.LINEAR,
		wrap_s = GL.CLAMP_TO_EDGE,
		wrap_t = GL.CLAMP_TO_EDGE,
		fbo = true,
	})
	-- Shared so other widgets (e.g. gui_bars_screen) can render bars/glyphs from the same atlas.
	WG.UnitOverlayIconAtlas = iconAtlasTexture
	iconAtlasReady = false -- a freshly created (blank) texture must be (re)blitted by renderIconAtlas
	iconAtlasSettle = 0
	dbgAtlasAttempt = 0 -- DEBUG (remove later)
end

local function renderIconAtlas()
	if iconAtlasReady or not iconAtlasTexture then return end
	local allLoaded = true -- a texture not yet loaded this frame leaves a blank cell -> retry next frame

	-- DEBUG (remove later): track which cells fail and watch the Detriment's icon cell specifically.
	dbgAtlasAttempt = dbgAtlasAttempt + 1
	local dbgNotBound, dbgNotDecoded, dbgMissing = {}, {}, {}
	local dd = UnitDefNames and UnitDefNames["striderdetriment"]
	local dbgDetCell = dd and unitDefIconIndex[dd.id]
	local dbgDetLine = nil
	-- /DEBUG

	gl.RenderToTexture(iconAtlasTexture, function()
		-- Clear only on the first blit; settle re-blits overwrite each base cell in place (no clear),
		-- so dynamic WG.icons appended by flushPendingIcons between frames aren't wiped.
		if iconAtlasSettle == 0 then gl.Clear(GL.COLOR_BUFFER_BIT, 0, 0, 0, 0) end
		-- Explicit state so the blit is an exact copy independent of inherited GL state (see
		-- flushPendingIcons): a stale gl.Color/blend left by another reloaded widget otherwise makes
		-- the atlas blank on alternating /luaui reloads.
		gl.DepthTest(false)
		gl.Blending(false)
		gl.Color(1, 1, 1, 1)
		for idx = 0, iconAtlasNextIndex - 1 do
			local entry = iconAtlasIndexToPath[idx]
			if entry then
				local col = idx % iconAtlasCols
				local row = math.floor(idx / iconAtlasCols)
				local y1 = (row / iconAtlasRows) * 2 - 1
				local y2 = ((row + 1) / iconAtlasRows) * 2 - 1
				if type(entry) == "table" then
					-- Multi-cell glyph strip: blit the whole image across `count` contiguous cells
					-- in this row, so each 64px glyph aligns exactly to one cell boundary.
					if VFS.FileExists(entry.strip) then
						local x1 = (col / iconAtlasCols) * 2 - 1
						local x2 = ((col + entry.count) / iconAtlasCols) * 2 - 1
						if gl.Texture(entry.strip) then
							gl.TexRect(x1, y1, x2, y2)
						else
							allLoaded = false
							dbgNotBound[#dbgNotBound + 1] = idx .. ":" .. entry.strip -- DEBUG
						end
						gl.Texture(false)
					else
						dbgMissing[#dbgMissing + 1] = idx .. ":" .. tostring(entry.strip) -- DEBUG
					end
				elseif VFS.FileExists(entry) then
					local x1 = (col / iconAtlasCols) * 2 - 1
					local x2 = ((col + 1) / iconAtlasCols) * 2 - 1
					local bound = gl.Texture(entry) -- DEBUG: capture bind result
					if bound then
						gl.TexRect(x1, y1, x2, y2)
					else
						allLoaded = false
						dbgNotBound[#dbgNotBound + 1] = idx .. ":" .. entry -- DEBUG
					end
					gl.Texture(false)
					-- DEBUG: a bound-but-undecoded texture reports 0 size and blits blank
					local ti = bound and gl.TextureInfo(entry)
					local xs = ti and (ti.xsize or 0) or 0
					if bound and xs == 0 then dbgNotDecoded[#dbgNotDecoded + 1] = idx .. ":" .. entry end
					if idx == dbgDetCell then
						dbgDetLine = string.format("DETRIMENT cell=%d path=%s exists=true bound=%s xsize=%s",
							idx, entry, tostring(bound), tostring(xs))
					end
				else
					dbgMissing[#dbgMissing + 1] = idx .. ":" .. tostring(entry) -- DEBUG
					if idx == dbgDetCell then
						dbgDetLine = string.format("DETRIMENT cell=%d path=%s exists=FALSE", idx, tostring(entry))
					end
				end
			elseif idx == dbgDetCell then
				dbgDetLine = string.format("DETRIMENT cell=%d has NO entry (unitDefIconIndex points to empty cell)", idx)
			end
		end
	end)

	-- DEBUG (remove later): summary once per build (first attempt) + any failures.
	if dbgAtlasAttempt == 1 then
		Spring.Echo(string.format("[OverlayAtlas DBG] attempt=%d allLoaded=%s cells=%d notBound=%d notDecoded=%d missing=%d detCell=%s settleFrames=%d",
			dbgAtlasAttempt, tostring(allLoaded), iconAtlasNextIndex, #dbgNotBound, #dbgNotDecoded, #dbgMissing, tostring(dbgDetCell), ICON_ATLAS_SETTLE_FRAMES))
		if dbgDetLine then Spring.Echo("[OverlayAtlas DBG] " .. dbgDetLine) end
	end
	if #dbgNotBound > 0 then Spring.Echo("[OverlayAtlas DBG] NOT BOUND: " .. table.concat(dbgNotBound, ", ")) end
	if #dbgNotDecoded > 0 then Spring.Echo("[OverlayAtlas DBG] BOUND BUT 0-SIZE: " .. table.concat(dbgNotDecoded, ", ")) end
	if #dbgMissing > 0 then Spring.Echo("[OverlayAtlas DBG] MISSING FILE: " .. table.concat(dbgMissing, ", ")) end
	-- /DEBUG

	-- Every source texture bound -- but a just-bound texture's pixels may not be uploaded yet, so keep
	-- re-blitting for ICON_ATLAS_SETTLE_FRAMES to capture late uploads before latching ready. A texture
	-- that fails to bind resets the settle so we keep retrying from scratch.
	if allLoaded then
		iconAtlasSettle = iconAtlasSettle + 1
		if iconAtlasSettle >= ICON_ATLAS_SETTLE_FRAMES then
			iconAtlasReady = true
			local capacity = iconAtlasCols * iconAtlasRows
			Spring.Echo("Unit Overlay GL4: built icon atlas using", iconAtlasNextIndex, "of", capacity, "cells")
			Spring.Echo(string.format("[OverlayAtlas DBG] READY after %d attempt(s)", dbgAtlasAttempt)) -- DEBUG
			if iconAtlasNextIndex > capacity then
				Spring.Echo("Unit Overlay GL4: WARNING icon atlas overflow -- increase iconAtlasRows / ICONATLAS_ROWS")
			end
		end
	else
		iconAtlasSettle = 0
	end
end

local function initGL4()
	healthBarShader =  LuaShader.CheckShaderUpdates(shaderSourceCache)

	if not healthBarShader then goodbye("Failed to compile Unit Overlay GL4") end

	healthBarVBO = initializeInstanceVBOTable("healthBarVBO", false)
	featureVBO = initializeInstanceVBOTable("featureVBO", true)
	buildIconAtlas()

	-- Point each horizontal bar's fill at its atlas cell. cache[4]/UVOFFSET for horizontal bars
	-- now means "atlas start cell of the 9-cell fill" instead of a healthbars.png patch index.
	-- A horizontal bar with no fill art gets -1, which the shader renders as flat color.
	-- Vertical (radial badge) and icon bars set cache[4] themselves (per-unit weapon/unit icon).
	for _, bt in pairs(barTypeMap) do
		local isVertical = bt.bartype % (bitVertical * 2) >= bitVertical
		local isIcon = bt.bartype % (bitIcon * 2) >= bitIcon
		if bt.statusIcon then
			-- status-duration radial badge: cache[4]/UVOFFSET is the badge's atlas icon cell
			bt.cache[4] = statusIconIndex[bt.statusIcon] or 0
		elseif not isVertical and not isIcon then
			bt.cache[4] = (bt.fill and barAtlasIndex[bt.fill]) or -1
		end
	end

	if debugmode then
		healthBarVBO.debug = true
	end
end

--------------------------------------------------------------------------------
--------------------------------------------------------------------------------

local uniformcache = {0.0}

-- uvOffsetOverride / layoutSlotOverride / alwaysShow let one barTypeMap config back several per-instance
-- variants (jump charges: same config, different charge index / centered slot / always-show flag).
local function addBarForUnit(unitID, unitDefID, barname, reason, range, uniformOverride, uvOffsetOverride, layoutSlotOverride, alwaysShow)
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

	local cp = UnitDefs[unitDefID].customParams
	local healthBarHeightExtra = (cp and tonumber(cp.health_bar_height)) or 0
	-- Every element of the overlay shares one baseline: the geom positions the unit icon, the bars
	-- (which stack from "icon center"), the flanking weapon bars and the status row all relative to it.
	-- Half the unit height centres the whole cluster vertically on the unit's body.
	healthBarTableCache[1] = (Spring.GetUnitHeight(unitID) or unitDefHeights[unitDefID]) * 0.5 + healthBarHeightExtra
	if barname == 'icon' then
		healthBarTableCache[4] = unitDefIconIndex[unitDefID] or 0
		local teamID = Spring.GetUnitTeam(unitID)
		local r, g, b, a = Spring.GetTeamColor(teamID)
		r = r or 1.0; g = g or 1.0; b = b or 1.0; a = a or 1.0
		healthBarTableCache[9]  = r;  healthBarTableCache[10] = g
		healthBarTableCache[11] = b;  healthBarTableCache[12] = a
		healthBarTableCache[13] = r;  healthBarTableCache[14] = g
		healthBarTableCache[15] = b;  healthBarTableCache[16] = a
	elseif barname == 'reload' or barname == 'primarycount' or barname:sub(1, 10) == 'bustreload' then
		local wc = unitDefWeaponColor[unitDefID]
		local iconPath = unitDefWeaponIcon[unitDefID]
		if unitDefIsComm[unitDefID] then
			-- Dynamic comms have no weapons in their unitDef; the assigned weapon's defID is
			-- exposed per-unit via the comm_weapon_id_1 rules param, so look it up at runtime.
			local wid = Spring.GetUnitRulesParam(unitID, "comm_weapon_id_1")
			local wd = wid and wid > 0 and WeaponDefs[wid]
			if wd then
				wc = getNormalizedWeaponColor(wd.visuals)
				iconPath = wd.customParams and wd.customParams.icon
			end
		end
		-- Radial badge icon (cache[4]): the weapon's `icon` customParam (an image path), registered on
		-- demand. -1 = no icon, so the badge draws just the countdown ring with no symbol.
		healthBarTableCache[4] = (iconPath and registerDynamicIcon(iconPath)) or -1
		-- Commanders always show the badge (showing "ready" below the threshold). bt.cache is shared,
		-- so always (re)assign cache[5] = bartype, OR-ing the flag only for commanders.
		healthBarTableCache[5] = bt.bartype + (unitDefIsComm[unitDefID] and bitAlwaysShow or 0)
		-- Tint the badge with the weapon's beam color. bt.cache is shared across units, so always
		-- reassign these four-component colors -- falling back to the bartype default when no color.
		if wc then
			healthBarTableCache[9]  = wc[1]; healthBarTableCache[10] = wc[2]
			healthBarTableCache[11] = wc[3]; healthBarTableCache[12] = 1.0
			healthBarTableCache[13] = wc[1]; healthBarTableCache[14] = wc[2]
			healthBarTableCache[15] = wc[3]; healthBarTableCache[16] = 1.0
		else
			healthBarTableCache[9]  = bt.mincolor[1]; healthBarTableCache[10] = bt.mincolor[2]
			healthBarTableCache[11] = bt.mincolor[3]; healthBarTableCache[12] = bt.mincolor[4]
			healthBarTableCache[13] = bt.maxcolor[1]; healthBarTableCache[14] = bt.maxcolor[2]
			healthBarTableCache[15] = bt.maxcolor[3]; healthBarTableCache[16] = bt.maxcolor[4]
		end
	elseif barname == 'reload2' or barname == 'reload3' or barname == 'reload4' then
		-- Extra weapon cooldown badge. For dynamic comms the Nth weapon is runtime-assigned
		-- (reload2 -> comm_weapon_id_2), so look it up live; otherwise pull from the unitDef extras list
		-- (reload2 -> extras[1], reload3 -> extras[2], ...). cache is shared per bartype, so reassign per unit.
		local wc, iconPath
		if unitDefIsComm[unitDefID] then
			local wid = Spring.GetUnitRulesParam(unitID, "comm_weapon_id_" .. tonumber(barname:sub(7)))
			local wd = wid and wid > 0 and WeaponDefs[wid]
			if wd then
				wc = getNormalizedWeaponColor(wd.visuals)
				iconPath = wd.customParams and wd.customParams.icon
			end
		else
			local extras = unitDefExtraWeapons[unitDefID]
			local extra = extras and extras[tonumber(barname:sub(7)) - 1]
			wc = extra and extra.color
			iconPath = extra and extra.icon
		end
		-- cache is shared per bartype, so always reassign: comms show this weapon "ready" below threshold too.
		healthBarTableCache[5] = bt.bartype + (unitDefIsComm[unitDefID] and bitAlwaysShow or 0)
		-- icon from the weapon's `icon` customParam (registered on demand); -1 = none drawn.
		healthBarTableCache[4] = (iconPath and registerDynamicIcon(iconPath)) or -1
		if wc then
			healthBarTableCache[9]  = wc[1]; healthBarTableCache[10] = wc[2]
			healthBarTableCache[11] = wc[3]; healthBarTableCache[12] = 1.0
			healthBarTableCache[13] = wc[1]; healthBarTableCache[14] = wc[2]
			healthBarTableCache[15] = wc[3]; healthBarTableCache[16] = 1.0
		else
			healthBarTableCache[9]  = bt.mincolor[1]; healthBarTableCache[10] = bt.mincolor[2]
			healthBarTableCache[11] = bt.mincolor[3]; healthBarTableCache[12] = bt.mincolor[4]
			healthBarTableCache[13] = bt.maxcolor[1]; healthBarTableCache[14] = bt.maxcolor[2]
			healthBarTableCache[15] = bt.maxcolor[3]; healthBarTableCache[16] = bt.maxcolor[4]
		end
	end
	healthBarTableCache[2] = effectiveScale
	healthBarTableCache[3] = range or 1
	healthBarTableCache[7] = uniformOverride or bt.uniformindex -- ability slots override the read channel
	if uvOffsetOverride ~= nil then healthBarTableCache[4] = uvOffsetOverride end
	if layoutSlotOverride ~= nil then healthBarTableCache[8] = layoutSlotOverride end
	if alwaysShow ~= nil then healthBarTableCache[5] = bt.bartype + (alwaysShow and bitAlwaysShow or 0) end

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
	-- Clear only the overlay-owned floats (1-11). The gadget owns float 0 (buildprogress), float 12 (cloak)
	-- and float 15 (unit height) -- zeroing 0 makes finished units render as a fresh nanoframe, zeroing 12
	-- would flicker cloak, and zeroing 15 would wipe the height the build-sweep needs. Floats 13-14 are
	-- unread (their channels pack into floats 2/11), so they need no clearing.
	for channels = 1, 11, 1 do
		gl.SetUnitBufferUniforms(unitID, uniformcache, channels)
	end

	-- This is optionally passed, and it only important in one edge case:
	-- If a unit is captured and thus immediately become outside of LOS, then the getunitallyteam is still the old ally team according to getUnitAllyTEam, and not the new allyteam.
	unitAllyTeam = unitAllyTeam or Spring.GetUnitAllyTeam(unitID)

	addBarForUnit(unitID, unitDefID, "health", reason)
	addBarForUnit(unitID, unitDefID, "build", reason)
	addBarForUnit(unitID, unitDefID, "paralyze", reason)
	addBarForUnit(unitID, unitDefID, "disarm", reason)
	addBarForUnit(unitID, unitDefID, "slow", reason)
	-- status-duration radial badges (shown only while the effect is locked at max)
	addBarForUnit(unitID, unitDefID, "paralyzetimer", reason)
	addBarForUnit(unitID, unitDefID, "disarmtimer", reason)
	addBarForUnit(unitID, unitDefID, "slowtimer", reason)
	addBarForUnit(unitID, unitDefID, "capture", reason)

	--// ABILITY SLOTS: walk the per-unitDef assignment (same list the updater packed); each ability's bar
	-- reads its slot channel via uniformOverride, presented by the kind's existing config. Modular
	-- durations (reload/dgun/capture) read target-frame mod 4096; gauges/percent read 0-100 (range 100).
	-- TODO: morph/goo (old ch8) not yet wired -- runtime morph slot + goo.
	local abSlots = unitDefAbilitySlots[unitDefID]
	if abSlots then
		local threshold = options.reloadThreshold.value
		local weaponN = 0
		-- Below-zone badges (jump charges / sprint / teleport) are collected, then created after the walk
		-- so each can bake its centered (index, count) slot for the GS to position the whole run.
		local belowList = {}
		for i = 1, #abSlots do
			local ab = abSlots[i]
			local kind = ab.kind
			local slotCh = abilitySlotChannel[i]
			if kind == "reload" or kind == "commReload" or kind == "scriptReload" then
				weaponN = weaponN + 1
				local cfg = (weaponN == 1) and "reload" or ("reload" .. weaponN)
				if barTypeMap[cfg] then
					local range, show
					if kind == "commReload" then
						local wid = Spring.GetUnitRulesParam(unitID, "comm_weapon_id_" .. (ab.commWeapon or 1))
						local wd = wid and wid > 0 and WeaponDefs[wid]
						range = (wd and wd.reload) and (wd.reload * gameSpeed) or nil
						show = (wd ~= nil) -- weapon 1 always present, 2 only if dual-equipped; shows "ready" below threshold
					elseif kind == "scriptReload" then
						range = unitDefScriptReload[unitDefID]
						show = range and (range / gameSpeed) >= threshold
					else
						range = ab.reload and (ab.reload * gameSpeed)
						show = (ab.reload or 0) >= threshold
					end
					if show then addBarForUnit(unitID, unitDefID, cfg, reason, range, slotCh) end
				end
			elseif kind == "burst" then
				addBarForUnit(unitID, unitDefID, "bustreload" .. ab.index, reason, 100, slotCh)
			elseif kind == "dgun" or kind == "moveDgun" then
				addBarForUnit(unitID, unitDefID, "dgun", reason, ab.reload and (ab.reload * gameSpeed), slotCh)
			elseif kind == "captureReload" then
				addBarForUnit(unitID, unitDefID, "captureReload", reason, ab.reload, slotCh)
			elseif kind == "shield" then addBarForUnit(unitID, unitDefID, "shield", reason, 100, slotCh)
			elseif kind == "heat" then addBarForUnit(unitID, unitDefID, "heat", reason, 100, slotCh)
			elseif kind == "speed" then addBarForUnit(unitID, unitDefID, "speed", reason, 100, slotCh)
			elseif kind == "teleport" then belowList[#belowList + 1] = { name = "teleport", range = 4096, slotCh = slotCh } -- modular: range only gates threshold/keeps rem/range<=1; countdown comes from teleportend
			elseif kind == "reammo" then belowList[#belowList + 1] = { name = "reammo", range = 1, slotCh = slotCh } -- rate-ETA band (range 1)
			elseif kind == "jump" then
				-- One below-zone gauge per charge: same slot, each baked with its charge index (+ charge
				-- count) in uvoffset, range = reload frames. Multi-charge units always show all charges.
				local charges = unitDefHasJump[unitDefID] or 1
				local reloadFrames = unitDefJumpReloadFrames[unitDefID] or 1
				for c = 0, charges - 1 do
					local nm = (c == 0) and "jump" or ("jump" .. (c + 1))
					if barTypeMap[nm] then
						belowList[#belowList + 1] = {
							name = nm, range = reloadFrames, slotCh = slotCh,
							uvoffset = c + charges * 16, alwaysShow = (charges > 1),
						}
					end
				end
			elseif kind == "moveAbility" then belowList[#belowList + 1] = { name = "ability", range = 4096, slotCh = slotCh } -- modular; countdown from the ready-frame
			elseif kind == "stockProg" then addBarForUnit(unitID, unitDefID, "stockpile", reason, 1, slotCh) -- rate-ETA band (range 1)
			elseif kind == "stockCnt" then addBarForUnit(unitID, unitDefID, "stockpilecount", reason, 1, slotCh)
			elseif kind == "goo" then belowList[#belowList + 1] = { name = "goo", range = 1, slotCh = slotCh } -- pausable-ETA band (range 1)
			end
		end
		-- Create the below-zone badges, baking each one's centered slot: .w = index | (count << 4).
		local belowCount = #belowList
		unitDefBelowCount[unitDefID] = belowCount
		-- bitmask of the distinct below-badge channels (for the morph's visible-count re-centering).
		local belowMask, seenCh = 0, {}
		for _, b in ipairs(belowList) do
			if b.slotCh and not seenCh[b.slotCh] then seenCh[b.slotCh] = true; belowMask = belowMask + 2 ^ b.slotCh end
		end
		unitDefBelowMask[unitDefID] = belowMask
		-- DEBUG (remove later): trace the Detriment's ability slots + below-badge collection.
		if UnitDefNames and UnitDefNames["striderdetriment"] and unitDefID == UnitDefNames["striderdetriment"].id then
			local kinds = {}
			for _, ab in ipairs(abSlots) do kinds[#kinds + 1] = ab.kind end
			local names = {}
			for _, b in ipairs(belowList) do names[#names + 1] = b.name end
			Spring.Echo(string.format("[Overlay DBG] Detriment hasJump=%s reloadFrames=%s | abilitySlots=[%s] | belowList=[%s] belowCount=%d",
				tostring(unitDefHasJump[unitDefID]), tostring(unitDefJumpReloadFrames[unitDefID]),
				table.concat(kinds, ","), table.concat(names, ","), belowCount))
		end
		-- /DEBUG
		for idx = 1, belowCount do
			local b = belowList[idx]
			addBarForUnit(unitID, unitDefID, b.name, reason, b.range, b.slotCh,
				b.uvoffset, (idx - 1) + belowCount * 16, b.alwaysShow)
		end
	end
	-- The unit icon is now part of the WG.icons cluster (icon + rank + group on one quad), owned by
	-- relayoutUnitIcons. Mark the unit dirty so it (re)builds the icon instance on the next DrawWorld;
	-- this also re-pushes it after a VBO wipe, since addBarsForUnit re-runs for every visible unit then.
	wgDirtyUnits[unitID] = true
end

local function removeBarsFromUnit(unitID, reason)
	for barname, v in pairs(barTypeMap) do
		removeBarFromUnit(unitID, barname, reason)
	end
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
			bt.cache[4], -- atlas cell (fill start / badge icon), resolved post-buildIconAtlas

			bt.bartype, -- bartype int
			0, -- bar index (how manyeth per unit)
			bt.uniformindex, -- ssbo location offset (> 20 for health)
			bt.layoutSlot or 0, -- layout slot (rides bartype_index_ssboloc.w)

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

function init() -- assigns the forward-declared upvalue (see top of file)
	clearInstanceTable(healthBarVBO)
	requeueAllIcons()

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
		if not healthBarVBO.instanceIDtoIndex[unitID .. "_morph"] then
			-- Bake the unit's persistent below-badge count so morph centers within that run (idx 0).
			local mudef = Spring.GetUnitDefID(unitID)
			local p = (unitDefBelowCount[mudef] or 0) * 16 + (unitDefBelowMask[mudef] or 0) * 256 -- P (bits 4-7) + below-channel mask
			addBarForUnit(unitID, nil, "morph", "MorphUpdate", nil, nil, nil, p)
		end
	end
	for _, callback in pairs(WG.MorphUpdateCallbacks) do
		callback(morphTable)
	end
end

function MorphStart(unitID, morphDef)
	local mudef = Spring.GetUnitDefID(unitID)
	local p = (unitDefBelowCount[mudef] or 0) * 16 + (unitDefBelowMask[mudef] or 0) * 256 -- P (bits 4-7) + below-channel mask (bits 8+)
	addBarForUnit(unitID, nil, "morph", "MorphStart", nil, nil, nil, p)
	for _, callback in pairs(WG.MorphStartCallbacks) do
		callback(unitID, morphDef)
	end
end

function MorphStopOrFinished(unitID)
	removeBarFromUnit(unitID, "morph", "MorphStopOrFinished")
	for _, callback in pairs(WG.MorphStopCallbacks) do
		callback(unitID)
	end
end

function widget:Initialize()
	if not gl.CreateShader then -- no shader support, so just remove the widget itself, especially for headless
		widgetHandler:RemoveWidget()
		return
	end
	WG['unitoverlay'] = {}
	WG['unitoverlay'].getScale = function()
		return barScale
	end
	WG['unitoverlay'].setScale = function(value)
		barScale = value
		init()
		initfeaturebars()
	end
	WG['unitoverlay'].getVariableSizes = function()
		return variableBarSizes
	end
	WG['unitoverlay'].setVariableSizes = function(value)
		variableBarSizes = value
		init()
		initfeaturebars()
	end
	WG['unitoverlay'].getDrawWhenGuiHidden = function()
		return drawWhenGuiHidden
	end
	WG['unitoverlay'].setDrawWhenGuiHidden = function(value)
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

	WG.MorphUpdateCallbacks = WG.MorphUpdateCallbacks or {}
	WG.MorphStartCallbacks  = WG.MorphStartCallbacks  or {}
	WG.MorphStopCallbacks   = WG.MorphStopCallbacks   or {}

	--// link morph callins
	widgetHandler:RegisterGlobal('MorphUpdate', MorphUpdate)
	widgetHandler:RegisterGlobal('MorphFinished', MorphStopOrFinished)
	widgetHandler:RegisterGlobal('MorphStart', MorphStart)
	widgetHandler:RegisterGlobal('MorphStop', MorphStopOrFinished)

	--// deactivate cheesy progress text
	widgetHandler:RegisterGlobal('MorphDrawProgress', function() return true end)

	stateCtl.applyAll() -- push initial state-icon visibility (single source of truth)
end

-- Track Shift for the Shift-gated state icons. Return nil so the key still propagates.
function widget:KeyPress(key, mods, isRepeat)
	stateCtl.refreshShift()
end

function widget:KeyRelease(key, mods)
	stateCtl.refreshShift()
end

-- DEBUG: blit the runtime icon atlas to the center of the screen so atlas/cell layout bugs are
-- inspectable live. Toggled by the 'debugDrawAtlas' option; no-op until the atlas exists.
function widget:DrawScreen()
	if not options.debugDrawAtlas.value or not iconAtlasTexture then return end
	local vsx, vsy = gl.GetViewSizes()
	local atlasW = iconAtlasCols * iconAtlasCellSize
	local atlasH = iconAtlasRows * iconAtlasCellSize
	-- Fit within 90% of screen height, preserving the atlas's aspect ratio.
	local h = vsy * 0.9
	local w = h * (atlasW / atlasH)
	local cx, cy = vsx * 0.5, vsy * 0.5
	local x1, y1 = cx - w * 0.5, cy - h * 0.5
	local x2, y2 = cx + w * 0.5, cy + h * 0.5
	-- Checkerboard-free dark backdrop so transparent/empty cells read as black, plus a border.
	gl.Color(0, 0, 0, 0.85)
	gl.Rect(x1, y1, x2, y2)
	gl.Color(1, 1, 1, 1)
	gl.Texture(iconAtlasTexture)
	-- Flip T so cell 0 (atlas-space bottom row) draws at the top, reading 0..N top-to-bottom.
	gl.TexRect(x1, y1, x2, y2, false, true)
	gl.Texture(false)
	gl.Color(1, 1, 1, 1)
end

function widget:Shutdown()
	WG.UnitOverlayIconAtlas = nil
	if iconAtlasTexture then gl.DeleteTexture(iconAtlasTexture); iconAtlasTexture = nil end
	-- Release the GL4 buffers so a /luaui reload starts from a clean slate instead of leaking the
	-- previous instance's VBO/VAO (which can leave reload in an inconsistent, toggling state).
	if healthBarVBO and healthBarVBO.Delete then healthBarVBO:Delete() end
	if featureVBO and featureVBO.Delete then featureVBO:Delete() end
	widgetHandler:DeregisterGlobal("FeatureReclaimStartedHealthbars" )
	widgetHandler:DeregisterGlobal("UnitCaptureStartedHealthbars" )
	widgetHandler:DeregisterGlobal("UnitParalyzeDamageHealthbars" )
	widgetHandler:DeregisterGlobal("ProjectileCreatedReloadHB" )
	Spring.Echo("Healthbars GL4 unloaded hooks")

        widgetHandler:DeregisterGlobal('MorphUpdate')
        widgetHandler:DeregisterGlobal('MorphFinished')
        widgetHandler:DeregisterGlobal('MorphStart')
        widgetHandler:DeregisterGlobal('MorphStop')

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
	onUnitIconHolderReset(unitID)
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
	spec, fullview = Spring.GetSpectatingState()
	myTeamID = Spring.GetMyTeamID()
	myAllyTeamID = Spring.GetMyAllyTeamID()
	myPlayerID = Spring.GetMyPlayerID()

	clearInstanceTable(healthBarVBO) -- clear all instances
	requeueAllIcons()
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


function widget:GameFrame(gameFrame)
	if gameFrame % 15 == 0 then
		refreshGroupNumbers() -- poll control-group membership for the bottom-right corner badge
	end
	if gameFrame % 15 == 7 then
		refreshUnitCommands() -- poll current command for the bottom-left corner badge (offset to spread load)
	end
	if debugmode then
		locateInvalidUnits(healthBarVBO)
	end
end

function widget:DrawWorld()
	--Spring.Echo(Engine.versionFull )
	if chobbyInterface then return end
	if not drawWhenGuiHidden and Spring.IsGUIHidden() then return end

	renderIconAtlas()
	flushPendingIcons()  -- blit any newly-registered WG.icons textures into the atlas
	processDirtyIcons()  -- (re)push hovering-icon instances for units whose icons changed
	local disticon = Spring.GetConfigInt("UnitIconDistance", 200) * 27.5 -- iconLength = unitIconDist * unitIconDist * 750.0f;
	-- "Draw on top" can't use a depth-buffer clear (the engine ignores it in DrawWorld), so instead the
	-- shader squeezes the overlay into a near-plane sliver (overlayDepthBand) -- it then wins the depth
	-- test against the world while still depth-writing so overlays sort among themselves.
	gl.DepthTest(true)
	gl.DepthMask(true)
	-- Standard alpha blending for the overlay (the atlas blits above left blending disabled).
	gl.Blending(GL.SRC_ALPHA, GL.ONE_MINUS_SRC_ALPHA)
	gl.Texture(1, iconAtlasTexture)
	healthBarShader:Activate()
	healthBarShader:SetUniform("iconDistance",disticon)
	healthBarShader:SetUniform("overlayDepthBand", 0.05)
	if not debugmode then
		local fd = options.fadeDistance.value
		healthBarShader:SetUniform("cameraDistanceMult", fd > 0 and (shaderConfig.BARFADESTART / fd) or 0.0)
	end
	local sfd = options.statusFadeDistance.value
	healthBarShader:SetUniform("statusFadeDistance", sfd)
	healthBarShader:SetUniform("iconHideDistance", options.iconHideDistance.value)
	healthBarShader:SetUniform("cameraDistanceMultGlyph", glphydistmult)
	healthBarShader:SetUniform("skipGlyphsNumbers",skipGlyphsNumbers)  --0.0 is everything,  1.0 means only numbers, 2.0 means only bars,
	healthBarShader:SetUniform("vbarUserX",  options.weaponBarOffset.value)
	healthBarShader:SetUniform("vbarSize",   options.weaponBarSize.value)
	healthBarShader:SetUniform("iconSize",   options.unitIconSize.value)
	healthBarShader:SetUniform("barBorderWidth", options.barBorder.value)
	healthBarShader:SetUniform("trackDarken", options.trackDarken.value)
	healthBarShader:SetUniform("reloadThreshold", options.reloadThreshold.value)
	healthBarShader:SetUniform("digitAtlasStart", digitAtlasStartIndex)
	healthBarShader:SetUniform("jumpIconCell", jumpIconAtlasIndex)
	healthBarShader:SetUniform("rowOffset", options.statusHeight.value)
	healthBarShader:SetUniform("rowSize", options.statusSize.value)
	healthBarShader:SetUniform("rowSpacing", options.statusSpacing.value)
	healthBarShader:SetUniform("overallScale", options.overallScale.value)
	healthBarShader:SetUniform("barSize", options.barSize.value)
	healthBarShader:SetUniform("barOffset", options.barHeightAboveUnit.value)
	healthBarShader:SetUniform("barSpacing", options.barSpacing.value)
	healthBarShader:SetUniform("belowBadgeHeight", options.abilityBadgeHeight.value)
	-- flashing icons: smooth oscillating alpha (mirrors legacy unit_icons iconFade)
	healthBarShader:SetUniform("pulseAlpha", 0.35 + 0.65 * (0.5 + 0.5 * math.sin(os.clock() * 5.0)))
	healthBarShader:SetUniform("isFeature", 0)
	if healthBarVBO.usedElements > 0 then
		healthBarVBO.VAO:DrawArrays(GL.POINTS,healthBarVBO.usedElements)
	end
	-- below its the feature bars being drawn:
	healthBarShader:SetUniform("cameraDistanceMultGlyph", glyphdistmultfeatures)
	healthBarShader:SetUniform("isFeature", 1) -- feature status channels differ; keep their fixed badge layout
	if featureVBO.usedElements > 0 then
		if not debugmode then healthBarShader:SetUniform("cameraDistanceMult",featureResurrectDistMult)  end
		featureVBO.VAO:DrawArrays(GL.POINTS,featureVBO.usedElements)
	end

	healthBarShader:Deactivate()
	gl.Texture(1, false)
	gl.DepthTest(false)
    gl.DepthMask(false) --"BK OpenGL state resets", reset to default state
end

function widget:TextCommand(command)
	if string.find(command, "debugunitoverlay", nil, true) == 1 then
		debugmode = not debugmode
		Spring.Echo("Debug mode for Unit Overlay GL4 set to", debugmode)
		healthBarVBO.debug = debugmode
	end
end

function widget:GetConfigData(data)
	return {
		barScale = barScale,
		barHeight = barHeight,
		variableBarSizes = variableBarSizes,
		drawWhenGuiHidden = drawWhenGuiHidden,
		skipGlyphsNumbers = skipGlyphsNumbers,
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
	if data.skipGlyphsNumbers ~= nil then
		skipGlyphsNumbers = data.skipGlyphsNumbers
	end
end
