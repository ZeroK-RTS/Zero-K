function widget:GetInfo()
  return {
    name      = "Context Menu",
    desc      = "v0.088 Chili Context Menu\nPress [Space] while clicking for a context menu.",
    author    = "CarRepairer",
    date      = "2009-06-02",
    license   = "GNU GPL, v2 or later",
    layer     = 0,
    experimental = false,
    enabled   = true,
  }
end

--[[
Todo:
- Puppy kamikaziness (is through weapon/gadget, not self-D)
- Deployability (Crab, Djinn, Slasher) - needs sensible way to convey these, each one does different thing when static
- Weapon impulse (no idea how the values relate to applied force, will need research)
- Drone production (would need some work to do properly because of entanglement)
- Clogging (Dirtbag)
- Water tank (Archer)

Customparams to add to units:
stats_show_death_explosion

Customparams to add to weapons:
stats_hide_aoe
stats_hide_range
stats_hide_damage
stats_hide_reload
stats_hide_dps
stats_hide_projectile_speed

]]

--------------------------------------------------------------------------------
--------------------------------------------------------------------------------

include("keysym.h.lua")
VFS.Include("LuaRules/Utilities/numberfunctions.lua")
VFS.Include("LuaRules/Utilities/versionCompare.lua")

local spSendLuaRulesMsg			= Spring.SendLuaRulesMsg
local spGetCurrentTooltip		= Spring.GetCurrentTooltip
local spGetUnitDefID			= Spring.GetUnitDefID
local spGetUnitAllyTeam			= Spring.GetUnitAllyTeam
local spGetUnitTeam				= Spring.GetUnitTeam
local spTraceScreenRay			= Spring.TraceScreenRay
local spGetTeamInfo				= Spring.GetTeamInfo
local spGetPlayerInfo			= Spring.GetPlayerInfo
local spGetTeamColor			= Spring.GetTeamColor
local spGetModKeyState			= Spring.GetModKeyState

local abs						= math.abs
local strFormat 				= string.format

local echo = Spring.Echo

local VFSMODE      = VFS.RAW_FIRST
local ignoreweapon, iconFormat = VFS.Include(LUAUI_DIRNAME .. "Configs/chilitip_conf.lua" , nil, VFSMODE)
local confdata = VFS.Include(LUAUI_DIRNAME .. "Configs/epicmenu_conf.lua", nil, VFSMODE)
local color = confdata.color

local iconTypesPath = LUAUI_DIRNAME.."Configs/icontypes.lua"
local icontypes = VFS.FileExists(iconTypesPath) and VFS.Include(iconTypesPath)

local emptyTable = {}

local moduleDefs, chassisDefs, upgradeUtilities = VFS.Include("LuaRules/Configs/dynamic_comm_defs.lua")

--------------------------------------------------------------------------------
--------------------------------------------------------------------------------

local Chili
local Button
local Label
local Window
local ScrollPanel
local StackPanel
local Grid
local TextBox
local Image
local screen0
local color2incolor

--------------------------------------------------------------------------------
--------------------------------------------------------------------------------

local B_HEIGHT 		= 30
local icon_size 	= 18

local scrH, scrW 		= 0,0
local myAlliance 		= Spring.GetLocalAllyTeamID()
local myTeamID 			= Spring.GetLocalTeamID()

local ceasefires 		= (not Spring.FixedAllies())
local marketandbounty 	= false

local window_unitcontext, window_unitstats
local statswindows = {}

local colorCyan = {0.2, 0.7, 1, 1}
local colorFire = {1, 0.3, 0, 1}
local colorPurple = {0.9, 0.2, 1, 1}
local colorDisarm = {0.5, 0.5, 0.5, 1}
local colorCapture = {0.6, 1, 0.6, 1}

local valkMaxCost = tonumber(UnitDefNames.gunshiptrans.customParams.transportcost)
local valkMaxSize = UnitDefNames.gunshiptrans.transportSize * 2

--------------------------------------------------------------------------------
--------------------------------------------------------------------------------
-- Generate unit behaviour paths 
local BEHAVIOUR_PATH = "Settings/Unit Behaviour/Default States/"

local behaviourPath = {}
local unitAlreadyAdded = {}

local function AddFactoryOfUnits(defName)
	if unitAlreadyAdded[defName] then
		return
	end
	local ud = UnitDefNames[defName]
	local name = string.gsub(ud.humanName, "/", "-")
	local path = BEHAVIOUR_PATH .. name
	behaviourPath[ud.id] = path
	for i = 1, #ud.buildOptions do
		behaviourPath[ud.buildOptions[i]] = path
	end
end

AddFactoryOfUnits("factoryshield")
AddFactoryOfUnits("factorycloak")
AddFactoryOfUnits("factoryveh")
AddFactoryOfUnits("factoryplane")
AddFactoryOfUnits("factorygunship")
AddFactoryOfUnits("factoryhover")
AddFactoryOfUnits("factoryamph")
AddFactoryOfUnits("factoryspider")
AddFactoryOfUnits("factoryjump")
AddFactoryOfUnits("factorytank")
AddFactoryOfUnits("factoryship")
AddFactoryOfUnits("striderhub")
AddFactoryOfUnits("staticmissilesilo")

local buildOpts = VFS.Include("gamedata/buildoptions.lua")
local factory_commands, econ_commands, defense_commands, special_commands = include("Configs/integral_menu_commands.lua")

for i = 1, #buildOpts do
	local name = buildOpts[i]
	local unitDefID = UnitDefNames[name].id
	if econ_commands[-unitDefID] then
		behaviourPath[unitDefID] = BEHAVIOUR_PATH .. "Economy"
	elseif defense_commands[-unitDefID] then
		behaviourPath[unitDefID] = BEHAVIOUR_PATH .. "Defence"
	elseif special_commands[-unitDefID] then
		behaviourPath[unitDefID] = BEHAVIOUR_PATH .. "Special"
	else
		behaviourPath[-unitDefID] = BEHAVIOUR_PATH .. "Misc"
	end
end

--------------------------------------------------------------------------------
--------------------------------------------------------------------------------

local function MakeStatsWindow() 
end

options_order = {'shortNotation', 'text_hotkey'}
options_path = 'Help/Unit List'
options = {
		
	shortNotation = {
		name = "Short Number Notation",
		type = 'bool',
		value = false,
		noHotkey = true,
		desc = 'Shows short number notation for HP and other values.',
		path = 'Settings/HUD Panels/Unit Stats Help Window'
	},
	
	text_hotkey = {
		name = 'Global Construction Hotkeys',
		type = 'text',
		value = [[These hotkey are always active. To edit the in-tab hotkeys look in "Hotkeys/Command Panel". Each tab can even have their own layout.]],
		path = 'Hotkeys/Construction',
	},
}

local alreadyAdded = {}

local function addUnit (unitDefID, path, buildable)
	if (alreadyAdded[unitDefID]) then
		return
	end
	alreadyAdded[unitDefID] = true
	local ud = UnitDefs[unitDefID]
	local unitName = ud.humanName
	local optionName = unitName .. 'help'
	options[optionName] = {
		name = unitName,
		type = 'button',
		desc = "Description For " .. unitName,
		OnChange = function(self)
			MakeStatsWindow(ud)
		end,
		path = options_path ..'/' .. path,
	}
	options_order[#options_order + 1] = optionName
	
	if (buildable) then
		optionName = unitName .. 'build'
		options[unitName .. 'build'] = {
			name=unitName,
			type='button',
			desc = "Build " .. unitName,
			action = 'buildunit_' .. ud.name,
			path = 'Hotkeys/Construction/' .. path,
		}
		options_order[#options_order + 1] = optionName
	end
end

local function AddFactoryOfUnits(defName)
	local ud = UnitDefNames[defName]
    local name = "Units/" .. string.gsub(ud.humanName, "/", "-")
	addUnit(ud.id, "Buildings/Factory", true)
	for i = 1, #ud.buildOptions do
		addUnit(ud.buildOptions[i], name, true)
    end
end

AddFactoryOfUnits("factoryshield")
AddFactoryOfUnits("factorycloak")
AddFactoryOfUnits("factoryveh")
AddFactoryOfUnits("factoryplane")
AddFactoryOfUnits("factorygunship")
AddFactoryOfUnits("factoryhover")
AddFactoryOfUnits("factoryamph")
AddFactoryOfUnits("factoryspider")
AddFactoryOfUnits("factoryjump")
AddFactoryOfUnits("factorytank")
AddFactoryOfUnits("factoryship")
AddFactoryOfUnits("striderhub")
AddFactoryOfUnits("staticmissilesilo")

local buildOpts = VFS.Include("gamedata/buildoptions.lua")
local factory_commands, econ_commands, defense_commands, special_commands = include("Configs/integral_menu_commands.lua")

for i = 1, #buildOpts do
	local udid = UnitDefNames[buildOpts[i]].id
	if econ_commands[-udid] then
		addUnit(udid,"Buildings/Economy", true)
	elseif defense_commands[-udid] then
		addUnit(udid,"Buildings/Defence", true)
	elseif special_commands[-udid] then
		addUnit(udid,"Buildings/Special", true)
	end
end

-- Misc stuff without direct buildability
addUnit(UnitDefNames["energyheavygeo"].id, "Buildings/Economy", true) -- moho geo
addUnit(UnitDefNames["athena"].id, "Units/Misc", true) -- athena
addUnit(UnitDefNames["wolverine_mine"].id, "Units/Misc", false) -- maybe should go under LV fac, like wolverine? to consider.
addUnit(UnitDefNames["tele_beacon"].id, "Units/Misc", false)
addUnit(UnitDefNames["asteroid"].id, "Units/Misc", false)


local lobbyIDs = {} -- stores peoples names by lobbyID to match commanders to owners 
local players = Spring.GetPlayerList()
for i = 1, #players do
	local customkeys = select(10, Spring.GetPlayerInfo(players[i]))
	if customkeys.lobbyid then
		lobbyIDs[customkeys.lobbyid] = select(1, Spring.GetPlayerInfo(players[i], false))
	end
end

for i = 1, #UnitDefs do
	if not alreadyAdded[i] then
		local ud = UnitDefs[i]
		if ud.name:lower():find('pw_') and (Spring.GetGameRulesParam("planetwars_structures") == 1) then
			addUnit(i,"Misc/Planet Wars", false)
		elseif ud.name:lower():find('chicken') and Spring.GetGameRulesParam("difficulty") then -- fixme: not all of these are actually used
			addUnit(i,"Misc/Chickens", false)
		elseif ud.customParams.is_drone then
			addUnit(i,"Units/Misc", false)
		end
	end
end

--------------------------------------------------------------------------------
--------------------------------------------------------------------------------

function comma_value(amount, displayPlusMinus)
	local formatted

	-- amount is a string when ToSI is used before calling this function
	if type(amount) == "number" then
		if (amount ==0) then formatted = "0" else 
			if (amount < 2 and (amount * 100)%100 ~=0) then 
				if displayPlusMinus then formatted = strFormat("%+.2f", amount)
				else formatted = strFormat("%.2f", amount) end 
			elseif (amount < 20 and (amount * 10)%10 ~=0) then 
				if displayPlusMinus then formatted = strFormat("%+.1f", amount)
				else formatted = strFormat("%.1f", amount) end 
			else 
				if displayPlusMinus then formatted = strFormat("%+d", amount)
				else formatted = strFormat("%d", amount) end 
			end 
		end
	else
		formatted = amount .. ""
	end

  	return formatted
end



local function numformat(num)
	return options.shortNotation.value and ToSIPrec(num) or comma_value(num)
end

local function AdjustWindow(window)
	local nx
	if (0 > window.x) then
		nx = 0
	elseif (window.x + window.width > screen0.width) then
		nx = screen0.width - window.width
	end

	local ny
	if (0 > window.y) then
		ny = 0
	elseif (window.y + window.height > screen0.height) then
		ny = screen0.height - window.height
	end

	if (nx or ny) then
		window:SetPos(nx,ny)
	end
end
--------------------------------------------------------------------------------
--------------------------------------------------------------------------------

local function CloseButtonFunc(self)
	self.parent.parent:Dispose()
end
local function CloseButtonFunc2(self)
	self.parent.parent.parent:Dispose()
end

local function CloseButton(width)
	return Button:New{ 
		caption = 'Close', 
		OnClick = { CloseButtonFunc }, 
		width=width, 
		height = B_HEIGHT,
		--backgroundColor=color.sub_back_bg, 
		--textColor=color.sub_back_fg,
		--classname = "back_button",
	}
end

local UnitDefByHumanName_cache = {}
local function GetUnitDefByHumanName(humanName)
	local cached_udef = UnitDefByHumanName_cache[humanName]
	if (cached_udef ~= nil) then
		return cached_udef
	end
	-- uncomment the altResult stuff to allow a non-exact match
	--local altResult

	for _,ud in pairs(UnitDefs) do
		if (ud.humanName == humanName) then
			UnitDefByHumanName_cache[humanName] = ud
			return ud
		--elseif (ud.humanName:find(humanName)) then
		--	altResult = altResult or ud
		end
	end
	--if altResult then
	--	UnitDefByHumanName_cache[humanName] = altResult
	--	return altResult
	--end
	
	UnitDefByHumanName_cache[humanName] = false
	return false
end

local function GetShieldRegenDrain(wd)
	local shieldRegen = wd.shieldPowerRegen
	if shieldRegen == 0 and wd.customParams and wd.customParams.shield_rate then
		shieldRegen = wd.customParams.shield_rate
	end
	
	local shieldDrain = wd.shieldPowerRegenEnergy
	if shieldDrain == 0 and wd.customParams and wd.customParams.shield_drain then
		shieldDrain = wd.customParams.shield_drain
	end
	return shieldRegen, shieldDrain
end

local function weapons2Table(cells, ws, unitID)
	local cells = cells
	
	local wd = WeaponDefs[ws.weaponID]
	local cp = wd.customParams or emptyTable

	local name = wd.description or "Weapon"
	if ws.count > 1 then
		name = name .. " x " .. ws.count
	end

	if wd.type == "TorpedoLauncher" then
		name = name .. " (water only)"
	end

	if wd.manualFire then
		name = name .. " (manual fire)"
	end
	
	if ws.aa_only then
		name = name .. " (anti-air only)"
	end

	cells[#cells+1] = name
	cells[#cells+1] = ''

	if wd.isShield then
		local regen, drain = GetShieldRegenDrain(wd) 
		cells[#cells+1] = ' - Strength:'
		cells[#cells+1] = wd.shieldPower .. " HP"
		cells[#cells+1] = ' - Regen:'
		cells[#cells+1] = regen .. " HP/s"
		cells[#cells+1] = ' - Regen cost:'
		cells[#cells+1] = drain .. " E/s"
		local rechargeDelay = tonumber(wd.shieldrechargedelay or wd.customParams.shield_recharge_delay)
		if rechargeDelay and rechargeDelay > 0 then
			cells[#cells+1] = ' - Regen delay:'
			cells[#cells+1] = rechargeDelay .. " s"
		end
		cells[#cells+1] = ' - Radius:'
		cells[#cells+1] = wd.shieldRadius .. " elmo"
		if wd.customParams.unlinked then
			cells[#cells+1] = ' - Does not link with other shields'
			cells[#cells+1] = ''
		end
	else
		-- calculate damages

		local dam  = 0
		local damw = 0
		local dams = 0
		local damd = 0
		local damc = 0

		local stun_time = 0

		local comm_mult = (unitID and Spring.GetUnitRulesParam(unitID, "comm_damage_mult")) or 1
		local val = (tonumber(cp.stats_damage) or wd.customParams.shield_damage or 0) * comm_mult

		if cp.disarmdamagemult then
			damd = val * cp.disarmdamagemult
			if (cp.disarmdamageonly == "1") then
				val = 0
			end
			stun_time = tonumber(cp.disarmtimer)
		end

		if cp.timeslow_damagefactor then
			dams = val * cp.timeslow_damagefactor
			if (cp.timeslow_onlyslow == "1") then
				val = 0
			end
		end

		if cp.is_capture then
			damc = val
			val = 0
		end

		if cp.extra_damage then
			damw = tonumber(cp.extra_damage) * comm_mult
			stun_time = tonumber(wd.customParams.extra_paratime)
		end

		if wd.paralyzer then
			damw = val
			if stun_time == 0 then
				stun_time = wd.damages.paralyzeDamageTime
			end
		else
			dam = val
		end

		-- get reloadtime and calculate dps
		local reloadtime = tonumber(cp.script_reload) or wd.reload
		
		local dps  = math.floor(dam /reloadtime + 0.5)
		local dpsw = math.floor(damw/reloadtime + 0.5)
		local dpss = math.floor(dams/reloadtime + 0.5)
		local dpsd = math.floor(damd/reloadtime + 0.5)
		local dpsc = math.floor(damc/reloadtime + 0.5)

		local mult = tonumber(cp.statsprojectiles) or ((tonumber(cp.script_burst) or wd.salvoSize) * wd.projectiles)

		local dps_str, dam_str = '', ''
		if dps > 0 then
			dam_str = dam_str .. numformat(dam,2)
			if wd.customParams.stats_damage_per_second then
				dps_str = dps_str .. numformat(tonumber(cp.stats_damage_per_second),2)
			else
				dps_str = dps_str .. numformat(dps*mult,2)
			end
		end
		if dpsw > 0 then
			if dps_str ~= '' then
				dps_str = dps_str .. ' + '
				dam_str = dam_str .. ' + '
			end
			dam_str = dam_str .. color2incolor(colorCyan) .. numformat(damw,2) .. " (P)\008"
			dps_str = dps_str .. color2incolor(colorCyan) .. numformat(dpsw*mult,2) .. " (P)\008"
		end
		if dpss > 0 then
			if dps_str ~= '' then
				dps_str = dps_str .. ' + '
				dam_str = dam_str .. ' + '
			end
			dam_str = dam_str .. color2incolor(colorPurple) .. numformat(dams,2) .. " (S)\008"
			dps_str = dps_str .. color2incolor(colorPurple) .. numformat(dpss*mult,2) .. " (S)\008"
		end

		if dpsd > 0 then
			if dps_str ~= '' then
				dps_str = dps_str .. ' + '
				dam_str = dam_str .. ' + '
			end
			dam_str = dam_str .. color2incolor(colorDisarm) .. numformat(damd,2) .. " (D)\008"
			dps_str = dps_str .. color2incolor(colorDisarm) .. numformat(dpsd*mult,2) .. " (D)\008"
		end

		if dpsc > 0 then
			if dps_str ~= '' then
				dps_str = dps_str .. ' + '
				dam_str = dam_str .. ' + '
			end
			dam_str = dam_str .. color2incolor(colorCapture) .. numformat(damc,2) .. " (C)\008"
			dps_str = dps_str .. color2incolor(colorCapture) .. numformat(dpsc*mult,2) .. " (C)\008"
		end

		if mult > 1 then
			dam_str = dam_str .. " x " .. mult
		end
		
		local show_damage = not cp.stats_hide_damage
		local show_dps = not cp.stats_hide_dps
		local show_reload = not cp.stats_hide_reload
		local show_range = not cp.stats_hide_range
		local show_aoe = not cp.stats_hide_aoe

		local hitscan = {
			BeamLaser = true,
			LightningCannon = true,
		}
		local show_projectile_speed = not cp.stats_hide_projectile_speed and not hitscan[wd.type]

		if ((dps + dpsw + dpss + dpsd + dpsc) < 2) then -- no damage: newtons and such
			show_damage = false
			show_dps = false
		end
		
		if cp.damage_vs_shield then -- Badger
			dam_str = tostring(cp.damage_vs_shield) .. " (" .. dam .. " + " .. (tonumber(cp.damage_vs_shield)-dam) .. " mine)"
			dps_str = numformat(math.floor(tonumber(cp.damage_vs_shield)/reloadtime))
		end

		if show_damage then
			cells[#cells+1] = ' - Damage:'
			cells[#cells+1] = dam_str
		end
		
		if cp.post_capture_reload then
			cells[#cells+1] = ' - Reloadtime:'
			cells[#cells+1] = numformat (tonumber(cp.post_capture_reload)/30,2) .. 's'
		elseif show_reload then
			cells[#cells+1] = ' - Reloadtime:'
			cells[#cells+1] = numformat (reloadtime,2) .. 's'
		end
		if show_dps then
			cells[#cells+1] = ' - DPS:'
			cells[#cells+1] = dps_str
		end
		
		local lowerName = name:lower()
		if lowerName:find("flamethrower") or lowerName:find("flame thrower") then
			cells[#cells+1] = ' - Shield damage:'
			cells[#cells+1] = "300%"
		elseif lowerName:find("gauss") then
			cells[#cells+1] = ' - Shield damage:'
			cells[#cells+1] = "150%"
		end

		if (wd.interceptedByShieldType == 0) then
			cells[#cells+1] = ' - Ignores shields'
			cells[#cells+1] = ''
		end

		if stun_time > 0 then
			cells[#cells+1] = ' - Stun time:'
			cells[#cells+1] = color2incolor((damw > 0) and colorCyan or colorDisarm) .. numformat(stun_time,2) .. 's\008'
		end

		if cp.setunitsonfire then
			cells[#cells+1] = ' - Afterburn:'
			local afterburn_frames = (cp.burntime or (450 * (wd.fireStarter or 0)))
			cells[#cells+1] = color2incolor(colorFire) .. numformat(afterburn_frames/30) .. 's (15 DPS)\008'
		end

		if show_range then
			local range = cp.truerange or wd.range
			cells[#cells+1] = ' - Range:'
			cells[#cells+1] = numformat(range * ((unitID and Spring.GetUnitRulesParam(unitID, "comm_range_mult")) or 1),2) .. " elmo"
		end

		local aoe = wd.impactOnly and 0 or wd.damageAreaOfEffect
		if aoe > 15 and show_aoe then
			cells[#cells+1] = ' - AoE radius:'
			cells[#cells+1] = numformat(aoe) .. " elmo"
		end

		if show_projectile_speed then
			cells[#cells+1] = ' - Projectile speed:'
			cells[#cells+1] = numformat(wd.projectilespeed*30) .. " elmo/s"
		elseif hitscan[wd.type] then
			cells[#cells+1] = ' - Instantly hits'
			cells[#cells+1] = ''
		end

		--[[ Unimportant stuff, maybe make togglable with some option later
		if (wd.type == "MissileLauncher") then
			if ((wd.startvelocity < wd.projectilespeed) and (wd.weaponAcceleration > 0)) then
				cells[#cells+1] = ' - Missile speed:'
				cells[#cells+1] = numformat(wd.startvelocity*30) .. " - " .. numformat(wd.projectilespeed*30) .. " elmo/s"
				cells[#cells+1] = ' - Acceleration:'
				cells[#cells+1] = numformat(wd.weaponAcceleration*900) .. " elmo/s^2"
			else
				cells[#cells+1] = ' - Missile speed:'
				cells[#cells+1] = numformat(wd.projectilespeed*30) .. " elmo/s"
			end
			cells[#cells+1] = ' - Flight time:'
			if cp.flighttime then
				cells[#cells+1] = numformat(tonumber(cp.flighttime)) .. "s"
			else
				cells[#cells+1] = numformat(((wd.range / wd.projectilespeed) + (wd.selfExplode and 25 or 0))/32) .. "s"
			end
			
			if wd.selfExplode then
				cells[#cells+1] = " - Explodes on timeout"
			else
				cells[#cells+1] = " - Falls down on timeout"
			end
			cells[#cells+1] = ''
		end

		if (wd.type == "StarburstLauncher") then
			cells[#cells+1] = ' - Vertical rise:'
			cells[#cells+1] = numformat(wd.uptime) .. "s"
		end
		]]

		if wd.tracks and wd.turnRate > 0 then
			cells[#cells+1] = ' - Homing:'
			local turnrate = wd.turnRate * 30 * 180 / math.pi
			cells[#cells+1] = numformat(turnrate, 1) .. " deg/s"
		end

		if wd.wobble > 0 then
			cells[#cells+1] = ' - Wobbly:'
			local wobble = wd.wobble * 30 * 180 / math.pi
			cells[#cells+1] = "up to " .. numformat(wobble, 1) .. " deg/s"
		end

		if wd.sprayAngle > 0 then
			cells[#cells+1] = ' - Inaccuracy:'
			local accuracy = math.asin(wd.sprayAngle) * 90 / math.pi
			cells[#cells+1] = numformat(accuracy, 1) .. " deg"
		end

		if wd.type == "BeamLaser" and wd.beamtime > 0.2 then
			cells[#cells+1] = ' - Burst time:'
			cells[#cells+1] = numformat(wd.beamtime) .. "s"
		end

		if cp.spawns_name then
			cells[#cells+1] = ' - Spawns: '
			cells[#cells+1] = Spring.Utilities.GetHumanName(UnitDefNames[cp.spawns_name])
			if cp.spawns_expire then
				cells[#cells+1] = ' - Spawn life: '
				cells[#cells+1] = cp.spawns_expire .. "s"
			end
		end
		
		if cp.reload_move_mod_time then
			cells[#cells+1] = ' - Move mult time: '
			cells[#cells+1] = cp.reload_move_mod_time .. "s"
		end

		if cp.area_damage then
			if (cp.area_damage_is_impulse == "1") then
				cells[#cells+1] = ' - Creates a gravity well:'
				cells[#cells+1] = ''
			else
				cells[#cells+1] = ' - Sets the ground on fire:'
				cells[#cells+1] = ''
				cells[#cells+1] = '   * DPS:'
				cells[#cells+1] = cp.area_damage_dps
			end
			cells[#cells+1] = '   * Radius:'
			cells[#cells+1] = numformat(tonumber(cp.area_damage_radius)) .. " elmo"
			cells[#cells+1] = '   * Duration:'
			cells[#cells+1] = numformat(tonumber(cp.area_damage_duration)) .. " s"
		end

		if wd.trajectoryHeight > 0 then
			cells[#cells+1] = ' - Arcing shot:'
			cells[#cells+1] = numformat(math.atan(wd.trajectoryHeight) * 180 / math.pi) .. " deg"
		end

		if wd.stockpile then
			cells[#cells+1] = ' - Stockpile time:'
			cells[#cells+1] = (((tonumber(ws.stockpile_time) or 0) > 0) and tonumber(ws.stockpile_time) or wd.stockpileTime) .. 's'
			if ((not ws.free_stockpile) and (ws.stockpile_cost or (wd.metalCost > 0))) then
				cells[#cells+1] = ' - Stockpile cost:'
				cells[#cells+1] = ws.stockpile_cost or wd.metalCost .. " M"
			end
		end

		if ws.firing_arc and (ws.firing_arc > -1) then
			cells[#cells+1] = ' - Firing arc:'
			cells[#cells+1] = numformat(360*math.acos(ws.firing_arc)/math.pi) .. ' deg'
		end

		if cp.needs_link then
			cells[#cells+1] = ' - Grid needed:'
			cells[#cells+1] = tonumber(cp.needs_link) .. " E"
		end

		if cp.smoothradius then
			cells[#cells+1] = ' - Smoothes ground'
			--cells[#cells+1] = cp.smoothradius .. " radius" -- overlaps
			cells[#cells+1] = ''
		end

		local highTraj = wd.highTrajectory
		if highTraj == 2 then
			highTraj = ws.highTrajectory
		end
		if highTraj == 1 then
			cells[#cells+1] = ' - High trajectory'
			cells[#cells+1] = ''
		elseif highTraj == 2 then
			cells[#cells+1] = ' - Trajectory toggle'
			cells[#cells+1] = ''
		end

		if wd.waterWeapon and (wd.type ~= "TorpedoLauncher") then
			cells[#cells+1] = ' - Water capable'
			cells[#cells+1] = ''
		end

		if not wd.avoidFriendly and not wd.noFriendlyCollide then
			cells[#cells+1] = ' - Potential friendly fire'
			cells[#cells+1] = ''
		end

		if wd.noGroundCollide then
			cells[#cells+1] = ' - Passes through ground'
			cells[#cells+1] = ''
		end

		if wd.noExplode then
			cells[#cells+1] = ' - Piercing '
			cells[#cells+1] = ''
			if not cp.single_hit then
				cells[#cells+1] = ' - Damage increase vs large units'
				cells[#cells+1] = ''
			end
		end

		if cp.dyndamageexp then
			cells[#cells+1] = ' - Damage falls off with range'
			cells[#cells+1] = ''
		end

		if cp.nofriendlyfire then
			cells[#cells+1] = ' - No friendly fire'
			cells[#cells+1] = ''
		end

		if cp.shield_drain then
			cells[#cells+1] = ' - Shield drain:'
			cells[#cells+1] = cp.shield_drain .. " HP/shot"
		end

		if cp.aim_delay then
			cells[#cells+1] = ' - Aiming time:'
			cells[#cells+1] = numformat(tonumber(cp.aim_delay)/1000) .. "s"
		end

		if wd.targetMoveError > 0 then
			cells[#cells+1] = ' - Inaccuracy vs moving targets'
			cells[#cells+1] = '' -- actual value doesn't say much as it's a multiplier for the target speed
		end

		if wd.targetable and ((wd.targetable == 1) or (wd.targetable == true)) then
			cells[#cells+1] = ' - Can be shot down by antinukes'
			cells[#cells+1] = ''
		end
	end
	return cells
end

local function printAbilities(ud, unitID)
	local cells = {}

	local cp = ud.customParams

	
	if ud.buildSpeed > 0 and not cp.nobuildpower then
		local buildSpeed = ud.buildSpeed * (unitID and Spring.GetUnitRulesParam(unitID, "buildpower_mult") or 1)
		cells[#cells+1] = 'Construction'
		cells[#cells+1] = ''
		cells[#cells+1] = ' - Buildpower: '
		cells[#cells+1] = numformat(buildSpeed)
		if ud.canResurrect then
			cells[#cells+1] = ' - Can resurrect wreckage'
			cells[#cells+1] = ''
		end
		if (#ud.buildOptions == 0) then
			cells[#cells+1] = ' - Can only assist'
			cells[#cells+1] = ''
		end
		cells[#cells+1] = ''
		cells[#cells+1] = ''
	end

	if ud.armoredMultiple < 1 then
		cells[#cells+1] = 'Armored form'
		cells[#cells+1] = ''
		cells[#cells+1] = ' - Reduction: '
		cells[#cells+1] = numformat((1-ud.armoredMultiple)*100) .. '%'
		if cp.force_close then
			cells[#cells+1] = ' - Forced for: '
			cells[#cells+1] = cp.force_close .. 's on damage'
		end
		cells[#cells+1] = ''
		cells[#cells+1] = ''
	end

	if cp.area_cloak or (unitID and Spring.GetUnitRulesParam(unitID, "comm_area_cloak")) then
		local areaCloakUpkeep = (unitID and Spring.GetUnitRulesParam(unitID, "comm_area_cloak_upkeep") or cp.area_cloak_upkeep)
		local areaCloakRadius = ((unitID and Spring.GetUnitRulesParam(unitID, "comm_area_cloak_radius")) or cp.area_cloak_radius)
		cells[#cells+1] = 'Area cloak'
		cells[#cells+1] = ''
		cells[#cells+1] = ' - Upkeep:'
		cells[#cells+1] = areaCloakUpkeep .. " E/s"
		cells[#cells+1] = ' - Radius:'
		cells[#cells+1] = areaCloakRadius .. " elmo"
		cells[#cells+1] = ''
		cells[#cells+1] = ''
	end

	if ud.cloakCost > 0 and (not unitID or Spring.GetUnitRulesParam(unitID, "comm_personal_cloak")) then
		local decloakDistance = (unitID and Spring.GetUnitRulesParam(unitID, "comm_decloak_distance")) or ud.decloakDistance
		cells[#cells+1] = 'Personal cloak'
		cells[#cells+1] = ''
		if not ud.isImmobile then
			cells[#cells+1] = ' - Upkeep mobile: '
			cells[#cells+1] = numformat(ud.cloakCostMoving) .. " E/s"
			cells[#cells+1] = ' - Upkeep idle: '
		else
			cells[#cells+1] = ' - Upkeep: '
		end
		cells[#cells+1] = numformat(ud.cloakCost) .. " E/s"
		cells[#cells+1] = ' - Decloak radius: '
		cells[#cells+1] = numformat(decloakDistance) .. " elmo"
		if not ud.decloakOnFire then
			cells[#cells+1] = ' - No decloak while shooting'
			cells[#cells+1] = ''
		end
		cells[#cells+1] = ''
		cells[#cells+1] = ''
	end

	if cp.idle_cloak then
		cells[#cells+1] = 'Personal cloak'
		cells[#cells+1] = ''
		cells[#cells+1] = ' - Only when idle'
		cells[#cells+1] = ''
		cells[#cells+1] = ' - Free and automated'
		cells[#cells+1] = ''
		cells[#cells+1] = ' - Decloak radius: '
		cells[#cells+1] = numformat(ud.decloakDistance) .. " elmo"
		cells[#cells+1] = ''
		cells[#cells+1] = ''
	end

	local radarRadius = unitID and Spring.GetUnitRulesParam(unitID, "radarRangeOverride") or ud.radarRadius
	local jammerRadius = unitID and Spring.GetUnitRulesParam(unitID, "jammingRangeOverride") or ud.jammerRadius
	
	if (radarRadius > 0) or (jammerRadius > 0) or ud.targfac then
		cells[#cells+1] = 'Provides intel'
		cells[#cells+1] = ''
		if (radarRadius > 0) then
			cells[#cells+1] = ' - Radar:'
			cells[#cells+1] = numformat(radarRadius) .. " elmo"
		end
		if (jammerRadius > 0) then
			cells[#cells+1] = ' - Radar jamming:'
			cells[#cells+1] = numformat(jammerRadius) .. " elmo"
		end
		if ud.targfac then
			cells[#cells+1] = ' - Improves radar accuracy'
			cells[#cells+1] = ''
		end
		cells[#cells+1] = ''
		cells[#cells+1] = ''
	end

	if cp.canjump and (not cp.no_jump_handling) then
		cells[#cells+1] = 'Jumping'
		cells[#cells+1] = ''
		cells[#cells+1] = ' - Range:'
		cells[#cells+1] = cp.jump_range .. " elmo"
		cells[#cells+1] = ' - Reload: '
		cells[#cells+1] = cp.jump_reload .. 's'
		cells[#cells+1] = ' - Speed:'
		cells[#cells+1] = numformat(30*tonumber(cp.jump_speed)) .. " elmo/s"
		cells[#cells+1] = ' - Midair jump:'
		cells[#cells+1] = (tonumber(cp.jump_from_midair) == 0) and "No" or "Yes"
		cells[#cells+1] = ''
		cells[#cells+1] = ''
	end

	if cp.morphto then
		cells[#cells+1] = 'Morphing'
		cells[#cells+1] = ''
		cells[#cells+1] = ' - To: '
		cells[#cells+1] = Spring.Utilities.GetHumanName(UnitDefNames[cp.morphto])
		cells[#cells+1] = ' - Cost: '
		cells[#cells+1] = math.max(0, (UnitDefNames[cp.morphto].buildTime - ud.buildTime)) .. " M"
		if cp.morphrank and (tonumber(cp.morphrank) > 0) then
			cells[#cells+1] = ' - Rank:'
			cells[#cells+1] = cp.morphrank
		end
		cells[#cells+1] = ' - Time: '
		cells[#cells+1] = cp.morphtime .. "s"
		if cp.combatmorph == '1' then
			cells[#cells+1] = ' - Not disabled during morph'
		else
			cells[#cells+1] = ' - Disabled during morph'
		end
		cells[#cells+1] = ''
		cells[#cells+1] = ''
		cells[#cells+1] = ''
	end

	if (ud.idleTime < 1800) or (cp.amph_regen) or (cp.armored_regen) then
		cells[#cells+1] = 'Improved regeneration'
		cells[#cells+1] = ''
		if ud.idleTime < 1800 then
			if ud.idleTime > 0 then
				cells[#cells+1] = ' - Idle regen: '
				cells[#cells+1] = numformat(cp.idle_regen) .. ' HP/s'
				cells[#cells+1] = ' - Time to enable: '
				cells[#cells+1] = numformat(ud.idleTime / 30) .. 's'
			else
				cells[#cells+1] = ' - Combat regen: '
				local dynamic_regen = unitID and Spring.GetUnitRulesParam(unitID, "comm_autorepair_rate") or cp.idle_regen
				cells[#cells+1] = numformat(dynamic_regen) .. ' HP/s'
			end
		end
		if cp.amph_regen then
			cells[#cells+1] = ' - Water regen: '
			cells[#cells+1] = cp.amph_regen .. ' HP/s'
			cells[#cells+1] = ' - At depth: '
			cells[#cells+1] = cp.amph_submerged_at .. " elmo"
		end
		if cp.armored_regen then
			cells[#cells+1] = ' - Closed regen: '
			cells[#cells+1] = numformat(tonumber(cp.armored_regen)) .. ' HP/s'
		end
		cells[#cells+1] = ''
		cells[#cells+1] = ''
	end

	if cp.teleporter then
		cells[#cells+1] = 'Teleporter'
		cells[#cells+1] = ''
		cells[#cells+1] = ' - Spawns a beacon for one-way recall'
		cells[#cells+1] = ''
		cells[#cells+1] = ' - Spawn time:'
		cells[#cells+1] = numformat(tonumber(cp.teleporter_beacon_spawn_time), 1) .. "s"
		cells[#cells+1] = ' - Throughput: '
		cells[#cells+1] = numformat(tonumber(cp.teleporter_throughput), 1) .. " mass / s"
		cells[#cells+1] = ''
		cells[#cells+1] = ''
	end

	if cp.pad_count then
		cells[#cells+1] = 'Rearms and repairs aircraft'
		cells[#cells+1] = ''
		cells[#cells+1] = ' - Pads:'
		cells[#cells+1] = cp.pad_count
		cells[#cells+1] = ' - Pad buildpower:'
		cells[#cells+1] = '2.5' -- maybe could use being a customparam too
		cells[#cells+1] = ''
		cells[#cells+1] = ''
	end

	if cp.is_drone then
		cells[#cells+1] = 'Bound to owner'
		cells[#cells+1] = ''
		cells[#cells+1] = " - Uncontrollable, uses owner's orders"
		cells[#cells+1] = ''
		cells[#cells+1] = ' - Must stay near owner'
		cells[#cells+1] = ''
		cells[#cells+1] = ' - Will die if owner does'
		cells[#cells+1] = ''
		cells[#cells+1] = ''
		cells[#cells+1] = ''
	end

	if cp.boost_speed_mult then
		cells[#cells+1] = 'Speed boost'
		cells[#cells+1] = ''
		cells[#cells+1] = ' - Speed: '
		cells[#cells+1] = 'x' .. cp.boost_speed_mult
		cells[#cells+1] = ' - Duration: '
		cells[#cells+1] = numformat(tonumber(cp.boost_duration)/30, 1) .. 's'
		cells[#cells+1] = ' - Reload: '
		cells[#cells+1] = numformat(tonumber(cp.specialreloadtime)/30, 1) .. 's'
		cells[#cells+1] = ''
		cells[#cells+1] = ''
	end

	if cp.windgen then
		local ground_extreme = Spring.GetGameRulesParam("WindGroundExtreme") or 1
		local wind_slope = Spring.GetGameRulesParam("WindSlope") or 0
		local max_wind = Spring.GetGameRulesParam("WindMax") or 2.5
		local bonus_per_elmo = max_wind * wind_slope / ground_extreme
		local bonus_100 = numformat(100*bonus_per_elmo)

		cells[#cells+1] = 'Generates energy from wind'
		cells[#cells+1] = ''
		cells[#cells+1] = ' - Variable income'
		cells[#cells+1] = ''
		cells[#cells+1] = ' - Max wind:' 
		cells[#cells+1] = max_wind
		cells[#cells+1] = ' - Altitude bonus:'
		cells[#cells+1] = bonus_100 .. " E / 100 height"
		cells[#cells+1] = ''
		cells[#cells+1] = ''
	end

	if cp.grey_goo then
		cells[#cells+1] = 'Gray Goo'
		cells[#cells+1] = ''
		cells[#cells+1] = ' - Eats nearby wreckage to spawn units'
		cells[#cells+1] = ''
		cells[#cells+1] = ' - Spawns:'
		cells[#cells+1] = Spring.Utilities.GetHumanName(UnitDefNames[cp.grey_goo_spawn])
		cells[#cells+1] = ' - BP:'
		cells[#cells+1] = cp.grey_goo_drain
		cells[#cells+1] = ' - Cost:'
		cells[#cells+1] = cp.grey_goo_cost .. " M"
		cells[#cells+1] = ''
		cells[#cells+1] = ''
	end

	if cp.floattoggle then
		cells[#cells+1] = 'Floating'
		cells[#cells+1] = ''
		cells[#cells+1] = ' - Can move from seabed to surface'
		cells[#cells+1] = ''
		cells[#cells+1] = ' - Cannot move sideways while afloat'
		cells[#cells+1] = ''
		if (cp.sink_on_emp ~= '0') then
			cells[#cells+1] = ' - Sinks when stunned'
		else
			cells[#cells+1] = ' - Stays afloat when stunned'
		end
		cells[#cells+1] = ''
	end

	if ud.transportCapacity and (ud.transportCapacity > 0) then
		cells[#cells+1] = 'Transport: '
		cells[#cells+1] = ((ud.customParams.islighttransport) and "Light" or "Heavy")
	end

	if ud.customParams.nuke_coverage then
		cells[#cells+1] = 'Can intercept strategic nukes'
		cells[#cells+1] = ''
		cells[#cells+1] = ' - Coverage:'
		cells[#cells+1] = ud.customParams.nuke_coverage .. " elmo"
		cells[#cells+1] = ''
		cells[#cells+1] = ''
	end

	if cp.combat_slowdown then
		cells[#cells+1] = 'Combat slowdown: '
		cells[#cells+1] = numformat(100*tonumber(cp.combat_slowdown)) .. "%"
	end

	if ud.stealth then
		cells[#cells+1] = 'Invisible to radar'
		cells[#cells+1] = ''
	end

	if ud.selfDCountdown <= 1 then
		cells[#cells+1] = 'Instant self-destruction'
		cells[#cells+1] = ''
	end

	if ud.needGeo then
		cells[#cells+1] = 'Requires thermal vent to build'
		cells[#cells+1] = ''
	end

	if cp.ismex then
		cells[#cells+1] = 'Extracts metal'
		cells[#cells+1] = ''
	end

	if cp.fireproof then
		cells[#cells+1] = 'Immunity to afterburn'
		cells[#cells+1] = ''
	end

	if ud.metalStorage > 0 then
		cells[#cells+1] = 'Stores metal: '
		cells[#cells+1] = ud.metalStorage .. " M"
	end
	
	if ud.energyStorage > 0 then
		cells[#cells+1] = 'Stores energy: '
		cells[#cells+1] = ud.energyStorage .. " E"
	end
	
	if (#cells > 2 and cells[#cells-1] == '') then
		cells[#cells] = nil
		cells[#cells] = nil
	end

	return cells
end

local function printWeapons(unitDef, unitID)
	local weaponStats = {}

	local wd = WeaponDefs
	if not wd then return false end	
	
	local ucp = unitDef.customParams
	
	for i=1, #unitDef.weapons do
		if not unitID or -- filter out commander weapons not in current loadout
		(  i == Spring.GetUnitRulesParam(unitID, "comm_weapon_num_1")
		or i == Spring.GetUnitRulesParam(unitID, "comm_weapon_num_2")
		or i == Spring.GetUnitRulesParam(unitID, "comm_shield_num")) then
			local weapon = unitDef.weapons[i]
			local weaponID = weapon.weaponDef
			local weaponDef = WeaponDefs[weaponID]

			local aa_only = true
			for cat in pairs(weapon.onlyTargets) do
				if ((cat ~= "fixedwing") and (cat ~= "gunship")) then
					aa_only = false
					break;
				end
			end

			local isDuplicate = false

			for i=1,#weaponStats do
				if weaponStats[i].weaponID == weaponID then
					weaponStats[i].count = weaponStats[i].count + 1
					isDuplicate = true
					break
				end
			end
			
			if (not isDuplicate) and not weaponDef.customParams.fake_weapon then 
				local wsTemp = {
					weaponID = weaponID,
					count = 1,
					
					-- stuff that the weapon gets from the owner unit
					aa_only = aa_only,
					highTrajectory = unitDef.highTrajectoryType,
					free_stockpile = ucp.freestockpile,
					stockpile_time = ucp.stockpiletime,
					stockpile_cost = ucp.stockpilecost,
					firing_arc = weapon.maxAngleDif
				}
				
				-- dual wielding comms
				if (unitID and i == Spring.GetUnitRulesParam(unitID, "comm_weapon_id_1") and i == Spring.GetUnitRulesParam(unitID, "comm_weapon_id_2")) then
					wsTemp.count = 2
				end
				weaponStats[#weaponStats+1] = wsTemp
			end
		end
	end

	local cells = {}

	for index,ws in pairs(weaponStats) do
		--if not ignoreweapon[unitDef.name] or not ignoreweapon[unitDef.name][index] then
		if (index ~= 1) then
			cells[#cells+1] = ''
			cells[#cells+1] = ''
		end
		cells = weapons2Table(cells, ws, unitID)
		--end
	end
	
	return cells
end

local function GetWeapon(weaponName)
	return WeaponDefNames[weaponName] 
end

local function printunitinfo(ud, buttonWidth, unitID)	
	local icons = {
		Image:New{
			file2 = (WG.GetBuildIconFrame)and(WG.GetBuildIconFrame(ud)),
			file = "#" .. ud.id,
			keepAspect = false;
			x = 32,
			y = 0,
			height  = 88*(4/5);
			width   = 88;
		},
	}
	if ud.iconType ~= 'default' then
		icons[#icons + 1] = Image:New{
			file=icontypes and icontypes[(ud and ud.iconType or "default")].bitmap
				or 'icons/'.. ud.iconType ..iconFormat,
			x = 0,
			y = 2,
			height=32,
			width=32,
		}
	end
	
	if behaviourPath[ud.id] then
		icons[#icons + 1] = Button:New{
			x = 2,
			right = 2,
			y = 88*(4/5),
			height = 30,
			caption = "Edit Behaviour",
			tooltip = "Edit the default behaviour of " .. Spring.Utilities.GetHumanName(ud) .. ".",
			OnClick = {function ()
					WG.crude.OpenPathToLabel(behaviourPath[ud.id], true, Spring.Utilities.GetHumanName(ud))
				end,
			}
		}
	end

	local helptextbox = TextBox:New{
		text = Spring.Utilities.GetHelptext(ud), 
		textColor = color.stats_fg, 
		width = '100%',
		height = '100%',
		padding = { 0, 0, 0, 0 }, 
		} 
	
	local statschildren = {}

	local isCommander = (unitID and Spring.GetUnitRulesParam(unitID, "comm_level"))

	local cost = numformat(ud.metalCost)
	local health = numformat(ud.health)
	local speed = numformat(ud.speed)
	local mass = numformat(ud.mass)
	
	-- stuff for modular commanders
	local legacyModules, legacyCommCost
	if ud.customParams.commtype and not isCommander then	-- old style pregenerated commander (still used in missions etc.)
		legacyModules = WG.ModularCommAPI and WG.ModularCommAPI.GetLegacyModulesForComm(ud.id)
		legacyCommCost = ud.customParams.cost -- or (WG.GetCommUnitInfo and WG.GetCommUnitInfo(ud.id) and WG.GetCommUnitInfo(ud.id).cost)
	end

	-- dynamic comms get special treatment
	if isCommander then
		cost = Spring.GetUnitRulesParam(unitID, "comm_cost") or 1200
		health = select(2, Spring.GetUnitHealth(unitID))
		speed = numformat(ud.speed * (Spring.GetUnitRulesParam(unitID, "upgradesSpeedMult") or 1))
		mass = numformat(Spring.GetUnitRulesParam(unitID, "massOverride") or ud.mass)

		statschildren[#statschildren+1] = Label:New{ caption = "COMMANDER", textColor = color.stats_header, }
		statschildren[#statschildren+1] = Label:New{ caption = '', textColor = color.stats_header, }
		statschildren[#statschildren+1] = Label:New{ caption = 'Level: ', textColor = color.stats_fg, }
		statschildren[#statschildren+1] = Label:New{ caption = Spring.GetUnitRulesParam(unitID, "comm_level")+1, textColor = color.stats_fg, }
		statschildren[#statschildren+1] = Label:New{ caption = 'Chassis: ', textColor = color.stats_fg, }
		statschildren[#statschildren+1] = Label:New{ caption = chassisDefs[Spring.GetUnitRulesParam(unitID, "comm_chassis")].humanName, textColor = color.stats_fg, }
		statschildren[#statschildren+1] = Label:New{ caption = '', textColor = color.stats_header,}
		statschildren[#statschildren+1] = Label:New{ caption = '', textColor = color.stats_header,}

		statschildren[#statschildren+1] = Label:New{ caption = 'MODULES', textColor = color.stats_header, }
		statschildren[#statschildren+1] = Label:New{ caption = '', textColor = color.stats_header, }

		local modules = Spring.GetUnitRulesParam(unitID, "comm_module_count")

		if modules > 0 then
			local module_instances = {}
			for i = 1, modules do
				local moduleID = Spring.GetUnitRulesParam(unitID, "comm_module_" .. i)
				module_instances[moduleID] = (module_instances[moduleID] or 0) + 1
			end
			for moduleID, moduleCount in pairs(module_instances) do
				local moduleStr = moduleDefs[moduleID].humanName
				if moduleCount > 1 then moduleStr = moduleStr .. "  x" .. moduleCount end
				statschildren[#statschildren+1] = Label:New{ caption = moduleStr, textColor = color.stats_fg, }
				statschildren[#statschildren+1] = Label:New{ caption = '', textColor = color.stats_fg, }
			end
		end
		statschildren[#statschildren+1] = Label:New{ caption = '', textColor = color.stats_header,}
		statschildren[#statschildren+1] = Label:New{ caption = '', textColor = color.stats_header,}
	end

	local costStr = cost .. " M"
	if (legacyCommCost) then
		costStr = costStr .. "(" .. legacyCommCost .. " M)"
	end
	
	statschildren[#statschildren+1] = Label:New{ caption = 'STATS', textColor = color.stats_header, }
	statschildren[#statschildren+1] = Label:New{ caption = '', textColor = color.stats_header, }

	statschildren[#statschildren+1] = Label:New{ caption = 'Cost: ', textColor = color.stats_fg, }
	statschildren[#statschildren+1] = Label:New{ caption = costStr, textColor = color.stats_fg, }
	
	statschildren[#statschildren+1] = Label:New{ caption = 'Health: ', textColor = color.stats_fg, }
	statschildren[#statschildren+1] = Label:New{ caption = health, textColor = color.stats_fg, }

	statschildren[#statschildren+1] = Label:New{ caption = 'Mass: ', textColor = color.stats_fg, }
	statschildren[#statschildren+1] = Label:New{ caption = mass, textColor = color.stats_fg, }

	if not ud.isImmobile then
		statschildren[#statschildren+1] = Label:New{ caption = 'Speed: ', textColor = color.stats_fg, }
		statschildren[#statschildren+1] = Label:New{ caption = speed .. " elmo/s", textColor = color.stats_fg, }
	end

	--[[ Enable through some option perhaps
	local gameSpeed2 = Game.gameSpeed * Game.gameSpeed

	if (ud.maxAcc) > 0 then
		statschildren[#statschildren+1] = Label:New{ caption = 'Acceleration: ', textColor = color.stats_fg, }
		statschildren[#statschildren+1] = Label:New{ caption = numformat(ud.maxAcc * gameSpeed2) .. " elmo/s^2", textColor = color.stats_fg, }
	end
	if (ud.maxDec) > 0 then
		statschildren[#statschildren+1] = Label:New{ caption = 'Brake rate: ', textColor = color.stats_fg, }
		statschildren[#statschildren+1] = Label:New{ caption = numformat(ud.maxDec * gameSpeed2) .. " elmo/s^2", textColor = color.stats_fg, }
	end ]]

	local COB_angle_to_degree = 360 / 65536
	if ud.turnRate > 0 then
		statschildren[#statschildren+1] = Label:New{ caption = 'Turn rate: ', textColor = color.stats_fg, }
		statschildren[#statschildren+1] = Label:New{ caption = numformat(ud.turnRate * Game.gameSpeed * COB_angle_to_degree) .. " deg/s", textColor = color.stats_fg, }
	end

	local metal = (isCommander and (Spring.GetUnitRulesParam(unitID, "wanted_metalIncome") or 0) or ((ud.metalMake or 0) + (ud.customParams.income_metal or 0)))

	if metal ~= 0 then
		statschildren[#statschildren+1] = Label:New{ caption = 'Metal: ', textColor = color.stats_fg, }
		statschildren[#statschildren+1] = Label:New{ caption = (metal > 0 and '+' or '') .. numformat(metal,2) .. " M/s", textColor = color.stats_fg, }
	end
	
	local energy = (isCommander and (Spring.GetUnitRulesParam(unitID, "wanted_energyIncome") or 0) or ((ud.energyMake or 0) - (ud.customParams.upkeep_energy or 0) + (ud.customParams.income_energy or 0)))

	if energy ~= 0 then
		statschildren[#statschildren+1] = Label:New{ caption = 'Energy: ', textColor = color.stats_fg, }
		statschildren[#statschildren+1] = Label:New{ caption = (energy > 0 and '+' or '') .. numformat(energy,2) .. " E/s", textColor = color.stats_fg, }
	end
	
	if ud.losRadius > 0 then
		statschildren[#statschildren+1] = Label:New{ caption = 'Sight: ', textColor = color.stats_fg, }
		statschildren[#statschildren+1] = Label:New{ caption = numformat(ud.losRadius) .. " elmo", textColor = color.stats_fg, }
	end

	if (ud.sonarRadius > 0) then
		statschildren[#statschildren+1] = Label:New{ caption = 'Sonar: ', textColor = color.stats_fg, }
		statschildren[#statschildren+1] = Label:New{ caption = numformat(ud.sonarRadius) .. " elmo", textColor = color.stats_fg, }
	end

	if ud.wantedHeight > 0 then
		statschildren[#statschildren+1] = Label:New{ caption = 'Altitude: ', textColor = color.stats_fg, }
		statschildren[#statschildren+1] = Label:New{ caption = numformat(ud.wantedHeight) .. " elmo", textColor = color.stats_fg, }
	end

	if ud.customParams.pylonrange then
		statschildren[#statschildren+1] = Label:New{ caption = 'Grid link range: ', textColor = color.stats_fg, }
		statschildren[#statschildren+1] = Label:New{ caption = numformat(ud.customParams.pylonrange) .. " elmo", textColor = color.stats_fg, }
	end

	-- transportability by light or heavy airtrans
	if not (ud.canFly or ud.cantBeTransported) then
		statschildren[#statschildren+1] = Label:New{ caption = 'Transportable: ', textColor = color.stats_fg, }
		statschildren[#statschildren+1] = Label:New{ caption = ((ud.customParams.requireheavytrans and "Heavy") or "Light"), textColor = color.stats_fg, }
	end
	
	if ud.customParams.reload_move_penalty then
		statschildren[#statschildren+1] = Label:New{ caption = 'Reload move mult: ', textColor = color.stats_fg, }
		statschildren[#statschildren+1] = Label:New{ caption = numformat(100*tonumber(ud.customParams.reload_move_penalty)) .. "%", textColor = color.stats_fg, }
	end
	
	if legacyModules then
		statschildren[#statschildren+1] = Label:New{ caption = '', textColor = color.stats_header,}
		statschildren[#statschildren+1] = Label:New{ caption = '', textColor = color.stats_header,}
		statschildren[#statschildren+1] = Label:New{ caption = 'MODULES', textColor = color.stats_header, }
		statschildren[#statschildren+1] = Label:New{ caption = '', textColor = color.stats_header,}
		for i=1, #legacyModules do
			statschildren[#statschildren+1] = Label:New{ caption = legacyModules[i], textColor = color.stats_fg,}
			statschildren[#statschildren+1] = Label:New{ caption = '', textColor = color.stats_fg,}
		end	
	end

	local cells = printAbilities(ud, isCommander and unitID)
	
	if cells and #cells > 0 then

		statschildren[#statschildren+1] = Label:New{ caption = '', textColor = color.stats_header,}
		statschildren[#statschildren+1] = Label:New{ caption = '', textColor = color.stats_header,}

		statschildren[#statschildren+1] = Label:New{ caption = 'ABILITIES', textColor = color.stats_header,}
		statschildren[#statschildren+1] = Label:New{ caption = '', textColor = color.stats_header,}
		for i=1, #cells do
			statschildren[#statschildren+1] = Label:New{ caption = cells[i], textColor = color.stats_fg, }
		end
	end

	cells = printWeapons(ud, isCommander and unitID)
	
	if cells and #cells > 0 then
		
		statschildren[#statschildren+1] = Label:New{ caption = '', textColor = color.stats_header,}
		statschildren[#statschildren+1] = Label:New{ caption = '', textColor = color.stats_header,}
		
		statschildren[#statschildren+1] = Label:New{ caption = 'WEAPONS', textColor = color.stats_header,}
		statschildren[#statschildren+1] = Label:New{ caption = '', textColor = color.stats_header,}
		for i=1, #cells do
			statschildren[#statschildren+1] = Label:New{ caption = cells[i], textColor = color.stats_fg, }
		end
	end

	-- fixme: get a better way to get default buildlist?
	local default_buildlist = UnitDefNames["shieldcon"].buildOptions 
	local this_buildlist = ud.buildOptions
	if ((#this_buildlist ~= #default_buildlist) and (#this_buildlist > 0)) then
		statschildren[#statschildren+1] = Label:New{ caption = '', textColor = color.stats_header,}
		statschildren[#statschildren+1] = Label:New{ caption = '', textColor = color.stats_header,}

		statschildren[#statschildren+1] = Label:New{ caption = 'BUILDS', textColor = color.stats_header,}
		statschildren[#statschildren+1] = Label:New{ caption = '', textColor = color.stats_header,}
		for i=1, #this_buildlist do
			statschildren[#statschildren+1] = Label:New{ caption = Spring.Utilities.GetHumanName(UnitDefs[this_buildlist[i]]), textColor = color.stats_fg, }
			-- desc. would be nice, but there is horizontal cutoff
			-- and long names can overlap (eg. Adv Radar)
			-- statschildren[#statschildren+1] = Label:New{ caption = UnitDefs[this_buildlist[i]].tooltip, textColor = colorDisarm,}
			statschildren[#statschildren+1] = Label:New{ caption = '', textColor = colorDisarm,}
		end
	end

	-- death explosion
	if ud.canKamikaze or ud.customParams.stats_show_death_explosion then
		statschildren[#statschildren+1] = Label:New{ caption = '', textColor = color.stats_header,}
		statschildren[#statschildren+1] = Label:New{ caption = '', textColor = color.stats_header,}
		statschildren[#statschildren+1] = Label:New{ caption = 'Death Explosion', textColor = color.stats_header,}
		statschildren[#statschildren+1] = Label:New{ caption = '', textColor = color.stats_fg, }

		local weaponStats = GetWeapon( ud.deathExplosion:lower() )
		local wepCp = weaponStats.customParams
		local damageValue = tonumber(weaponStats.customParams.stats_damage)

		statschildren[#statschildren+1] = Label:New{ caption = 'Damage: ', textColor = color.stats_fg, }
		if (weaponStats.paralyzer) then
			statschildren[#statschildren+1] = Label:New{ caption = numformat(damageValue,2) .. " (P)", textColor = colorCyan, }
			statschildren[#statschildren+1] = Label:New{ caption = 'Max EMP time: ', textColor = color.stats_fg, }
			statschildren[#statschildren+1] = Label:New{ caption = numformat(weaponStats.damages.paralyzeDamageTime,2) .. "s", textColor = color.stats_fg, }
		else
			local damageSlow = (wepCp.timeslow_damagefactor or 0)*damageValue
			local damageText
			if damageSlow > 0 then
				if wepCp.timeslow_onlyslow == "1" then
					 damageText = color2incolor(colorPurple) .. numformat(damageSlow,2) .. " (S)\008"
				else
					damageText = numformat(damageValue,2) .. " + " .. color2incolor(colorPurple) .. numformat(damageSlow,2) .. " (S)\008"
				end
			else
				damageText = numformat(damageValue,2)
			end
			statschildren[#statschildren+1] = Label:New{ caption = damageText, textColor = color.stats_fg, }
		end

		statschildren[#statschildren+1] = Label:New{ caption = 'AoE radius: ', textColor = color.stats_fg, }
		statschildren[#statschildren+1] = Label:New{ caption = numformat(weaponStats.damageAreaOfEffect,2) .. " elmo", textColor = color.stats_fg, }
		
		if (weaponStats.customParams.setunitsonfire) then
			statschildren[#statschildren+1] = Label:New{ caption = 'Afterburn: ', textColor = color.stats_fg, }
			statschildren[#statschildren+1] = Label:New{ caption = numformat((weaponStats.customParams.burntime or 450)/30) .. "s (15 DPS)", textColor = colorFire, }
		end

		-- statschildren[#statschildren+1] = Label:New{ caption = 'Edge Damage: ', textColor = color.stats_fg, }
		-- statschildren[#statschildren+1] = Label:New{ caption = numformat(damageValue * weaponStats.edgeEffectiveness,2), textColor = color.stats_fg, }
		-- edge damage is always 0, see http://springrts.com/mediawiki/images/1/1c/EdgeEffectiveness.png

	end

	--adding this because of annoying  cutoff
	statschildren[#statschildren+1] = Label:New{ caption = '', textColor = color.stats_fg, }
	statschildren[#statschildren+1] = Label:New{ caption = '', textColor = color.stats_fg, }
	statschildren[#statschildren+1] = Label:New{ caption = '', textColor = color.stats_fg, }
	statschildren[#statschildren+1] = Label:New{ caption = '', textColor = color.stats_fg, }
	
	
	local stack_icons = Chili.Control:New{
		y = 3,
		right = 1,
		height = 200,
		width = 120,
		padding = {0,0,0,0},
		itemMargin = {0,4,0,4},
		children = icons,
	}
	
	local stack_stats = Grid:New{
		columns=2,
		autoArrangeV  = false,
		--height = (#statschildren/2)*statschildren[1].height,
		height = (#statschildren/2)*15,
		
		width = '100%',
		children = statschildren,
		y = 1,
		padding = {1,1,1,1},
		itemPadding = {1,1,1,1},
		itemMargin = {1,1,1,1},
	}
	
	local helptext_stack = StackPanel:New{
		resizeItems = false,
		orientation = 'vertical',
		autoArrangeV  = false,
		autoArrangeH  = false,
		centerItems  = false,
		right = 128,
		x = 0,
		--width = 200,
		--height = '100%',
		autosize=true,
		resizeItems = false,
		children = { helptextbox, stack_stats, },
	}
	return {
		helptext_stack, 
		stack_icons,
	}
end

local function tooltipBreakdown(tooltip)
	local unitname = nil

	if tooltip:find('Build', 1, true) == 1 then
		local name = string.sub(tooltip, ((tooltip:find('BuildUnit', 1, true) == 1) and 10) or 6)
		local ud = name and UnitDefNames[name]
		return ud or false
	elseif tooltip:find('Morph', 1, true) == 1 then
		local unitHumanName = tooltip:gsub('Morph into a (.*)(time).*', '%1'):gsub('[^%a \\-]', '')
		local udef = GetUnitDefByHumanName(unitHumanName)
		return udef or false
			
	elseif tooltip:find('Selected', 1, true) == 1 then
		local start,fin = tooltip:find([[ - ]], 1, true)
		if start and fin then
			local unitHumanName = tooltip:sub(11,start-1)
			local udef = GetUnitDefByHumanName(unitHumanName)
			return udef or false
		end
	end
	
	return false
end

----------------------------------------------------------------

local function hideWindow(window)
	if not window then return end
	window:SetPos(-1000, -1000)
	window.visible = false
end
--[[
local function showWindow(window, x, y)
	window.visible = true
	if x then
		window:SetPos(x,y)
	end
end
--]]
local function KillStatsWindow(num)
	statswindows[num]:Dispose()
	statswindows[num] = nil
end

MakeStatsWindow = function(ud, x,y, unitID)
	hideWindow(window_unitcontext)
	local x = x
	local y = y
	if x then
		y = scrH-y
	else
		x = scrH / 3
		y = scrH / 3
	end
	
	local window_width = 450
	local window_height = 450

	local num = #statswindows+1
	
	local children = {
		ScrollPanel:New{
			--horizontalScrollbar = false,
			x=5,y=15,
			right = 5,
			bottom = B_HEIGHT + 10,
			padding = {2,2,2,2},
			children = printunitinfo(ud, window_width, unitID) ,
		},	
		Button:New{ 
			caption = 'Close', 
			OnClick = { function(self) KillStatsWindow(num) end }, 
			
			x=5,
			height=B_HEIGHT,
			right=5,
			bottom=5,
			
			--backgroundColor=color.sub_back_bg, 
			--textColor=color.sub_back_fg,
			--classname = "back_button",
		}
	}

	if window_unitstats then
		window_unitstats:Dispose()
	end

	statswindows[num] = Window:New{  
		x = x,
		y = y,
		width  = window_width,
		height = window_height,
		resizable = true,
		parent = screen0,
		backgroundColor = color.stats_bg, 
		classname = "main_window_small",
		
		minWidth = 250,
		minHeight = 300,
		
		caption = Spring.Utilities.GetHumanName(ud, unitID) ..' - '.. Spring.Utilities.GetDescription(ud, unitID),
		
		children = children,
	}
	AdjustWindow(statswindows[num])
end

local function PriceWindow(unitID, action)
	local window_width = 250
	
	local header = 'Offer For Sale'
	local command = '$sell'
	local cancelText = 'Cancel Sale'
	if action == 'buy' then
		header = 'Offer To Buy'
		command = '$buy'
		cancelText = 'Cancel Offer'
	elseif action == 'bounty' then
		header = 'Place Bounty (5 Minutes - Cannot cancel!)'
		command = '$bounty'
	end
	
	local children = {}
	children[#children+1] = Label:New{ caption = header, width=window_width, height=B_HEIGHT, textColor = color.context_header,}
	
	local grid_children = {}
	
	local dollar_amounts = {50,100,200,500,1000,2000,5000,10000, 0}
	for i=1, #dollar_amounts do
		local dollar_amount = dollar_amounts[i]
		local caption, func
		if action == 'bounty' then
			if dollar_amount ~= 0 then
				caption = '$' .. dollar_amount
				func = function() spSendLuaRulesMsg(  command .. '|' .. unitID .. '|' .. dollar_amount ) end
			end
		else
			caption = dollar_amount == 0 and cancelText or '$' .. dollar_amount
			func = function() spSendLuaRulesMsg(  command .. '|' .. unitID .. '|' .. dollar_amount) end
		end
		if caption then
			grid_children[#grid_children+1] = Button:New{ 
				caption = caption, 
				OnClick = { func, CloseButtonFunc2 }, 
				width=window_width,
				height=B_HEIGHT,
				--backgroundColor=color.sub_back_bg, 
				--textColor=color.sub_back_fg,
				--classname = "back_button",
			}
		end
	end
	--local grid_height = (B_HEIGHT)* #grid_children /3
	local grid_height = (B_HEIGHT)* 3
	local price_grid = Grid:New{
		--rows = 3,
		columns = 3,
		resizeItems=true,
		width = window_width,
		height = grid_height,
		padding = {0,0,0,0},
		itemPadding = {2,2,2,2},
		itemMargin = {0,0,0,0},
		
		children = grid_children,
	}
	
	children[#children+1] = price_grid
	
	children[#children+1] = Label:New{ caption = '', width=window_width, height=B_HEIGHT, autosize=false,}

	children[#children+1] =  CloseButton(window_width)
	
	local window_height = (B_HEIGHT) * (#children-1) + grid_height
		
	local stack1 = StackPanel:New{
		centerItems = false,
		resizeItems=false,
		width = window_width,
		height = window_height,
		padding = {0,0,0,0},
		itemPadding = {2,2,2,2},
		itemMargin = {0,0,0,0},
		children = children,
	}
	
	local window = Window:New{  
		x = scrW/2,  
		y = scrH/2,
		clientWidth  = window_width,
		clientHeight = window_height,
		resizable = false,
		parent = screen0,
		backgroundColor = color.context_bg, 
		children = {stack1},
	}
end

local function MakeUnitContextMenu(unitID,x,y)
	--hideWindow(window_unitstats)
					
	local udid 			= spGetUnitDefID(unitID)
	local ud 			= UnitDefs[udid]
	if not ud then return end
	local alliance 		= spGetUnitAllyTeam(unitID)
	local team			= spGetUnitTeam(unitID)
	local _, player 	= spGetTeamInfo(team, false)
	local playerName 	= spGetPlayerInfo(player, false) or 'noname'
	local teamColor 	= {spGetTeamColor(team)}
		
	local window_width = 200
	--local buttonWidth = window_width - 0

	local children = {
		Label:New{ caption = Spring.Utilities.GetHumanName(ud) ..' - '.. Spring.Utilities.GetDescription(ud), width=window_width, textColor = color.context_header,},
		Label:New{ caption = 'Player: ' .. playerName, width=window_width, textColor=teamColor },
		Label:New{ caption = 'Alliance - ' .. alliance .. '    Team - ' .. team, width=window_width ,textColor = color.context_fg,},
		
		Button:New{ 
			caption = 'Unit Info', 
			OnClick = { function() MakeStatsWindow(ud,x,y) end }, 
			width=window_width,
			--backgroundColor=color.sub_back_bg, 
			--textColor=color.sub_back_fg,
			--classname = "back_button",
		},
	}
	local y = scrH-y
	local x = x
	
	if marketandbounty then
		if team == myTeamID then
			children[#children+1] =  Button:New{ 
				caption = 'Set Sale Price', 
				OnClick = { function(self) PriceWindow(unitID, 'sell') end }, 
				width=window_width, 
				--backgroundColor=color.sub_back_bg, 
				--textColor=color.sub_back_fg,
				--classname = "back_button",
			}
		else
			children[#children+1] =  Button:New{ 
				caption = 'Offer To Buy', 
				OnClick = { function(self) PriceWindow(unitID, 'buy') end }, 
				width=window_width, 
				--backgroundColor=color.sub_back_bg, 
				--textColor=color.sub_back_fg,
				--classname = "back_button",
			}
		end
		if myAlliance ~= alliance then
			children[#children+1] =  Button:New{ 
				caption = 'Place Bounty', 
				OnClick = { function(self) PriceWindow(unitID, 'bounty') end }, 
				width=window_width, 
				--backgroundColor=color.sub_back_bg, 
				--textColor=color.sub_back_fg,
				--classname = "back_button",
			}
		end
	end

	
	if ceasefires and myAlliance ~= alliance then
		--window_height = window_height + B_HEIGHT*2 --error no such window_height!
		children[#children+1] = Button:New{ caption = 'Vote for ceasefire', OnClick = { function() spSendLuaRulesMsg('cf:y'..alliance) end }, width=window_width}
		children[#children+1] = Button:New{ caption = 'Break ceasefire/unvote', OnClick = { function() spSendLuaRulesMsg('cf:n'..alliance) spSendLuaRulesMsg('cf:b'..alliance) end }, width=window_width}
	end
	children[#children+1] = CloseButton()
	
	local window_height = (B_HEIGHT)* #children
	
	if window_unitcontext then
		window_unitcontext:Dispose()
	end
	local stack1 = StackPanel:New{
		centerItems = false,
		--autoArrangeV = true,
		--autoArrangeH = true,
		resizeItems=true,
		width = window_width,
		height = window_height,
		padding = {0,0,0,0},
		itemPadding = {2,2,2,2},
		itemMargin = {0,0,0,0},
		children = children,
	}
	
	window_unitcontext = Window:New{  
		x = x,  
		y = y,  
		clientWidth  = window_width,
		clientHeight = window_height,
		classname = "main_window_small",
		resizable = false,
		parent = screen0,
		backgroundColor = color.context_bg, 
		children = {stack1},
	}
	AdjustWindow(window_unitcontext)
end

--------------------------------------------------------------------------------
--------------------------------------------------------------------------------

function widget:MousePress(x,y,button)
	
	if button ~= 1 then return end
	
	local alt, ctrl, meta, shift = spGetModKeyState()
	
	if meta then
		----------
		local groundTooltip
		if WG.customToolTip then --find any custom ground tooltip placed on the ground
			local _, pos = spTraceScreenRay(x,y, true, false, false, true) --return coordinate of the ground
			for _, data in pairs(WG.customToolTip) do --iterate over WG.customToolTip
				if data.box and pos and (pos[1]>= data.box.x1 and pos[1]<= data.box.x2) and (pos[3]>= data.box.z1 and pos[3]<= data.box.z2) then --check if within box side x & check if within box side z
					groundTooltip = data.tooltip --copy tooltip
					break
				end
			end
		end
		----------
		local cur_ttstr = screen0.currentTooltip or groundTooltip or spGetCurrentTooltip()
		local ud = tooltipBreakdown(cur_ttstr)
		
		local _,cmd_id = Spring.GetActiveCommand()
		
		if cmd_id then
			return false
		end
		
		local type, data = spTraceScreenRay(x, y, false, false, false, true)
		if (type == 'unit') then
			local unitID = data
			
			if marketandbounty then
				MakeUnitContextMenu(unitID,x,y)
				return
			end
			
			local udid = UnitDefs[Spring.GetUnitDefID(unitID)]
			
			if udid then
				MakeStatsWindow(udid,x,y, unitID)
			end
			-- FIXME enable later when does not show useless info
			return true
		elseif (type == 'feature') then
			local fdid = Spring.GetFeatureDefID(data)
			local fd = fdid and FeatureDefs[fdid]
			local feature_name = fd and fd.name
			if feature_name then
				
				local live_name
				if fd and fd.customParams and fd.customParams.unit then
					live_name = fd.customParams.unit
				else
					live_name = feature_name:gsub('([^_]*).*', '%1')
				end
				
				local ud = UnitDefNames[live_name]
				if ud then
					MakeStatsWindow(ud,x,y)
					return true
				end
			end
		end

		if ud then
			MakeStatsWindow(ud,x,y)
			return true
		end
	end

	--[[
	if window_unitcontext and window_unitcontext.visible and (not screen0.hoveredControl or not screen0.hoveredControl:IsDescendantOf(window_unitcontext)) then
		hideWindow(window_unitcontext)
		return true
	end
	
	if window_unitstats and window_unitstats.visible and (not screen0.hoveredControl or not screen0.hoveredControl:IsDescendantOf(window_unitstats)) then
		hideWindow(window_unitstats)
		return true
	end
	--]]
end

function widget:ViewResize(vsx, vsy)
	scrW = vsx
	scrH = vsy
end


function widget:Initialize()

	if (not WG.Chili) then
		widgetHandler:RemoveWidget(widget)
		return
	end
	
	-- setup Chili
	 Chili = WG.Chili
	 Button = Chili.Button
	 Label = Chili.Label
	 Window = Chili.Window
	 ScrollPanel = Chili.ScrollPanel
	 StackPanel = Chili.StackPanel
	 Grid = Chili.Grid
	 TextBox = Chili.TextBox
	 Image = Chili.Image
	 screen0 = Chili.Screen0
	 color2incolor = Chili.color2incolor

	widget:ViewResize(Spring.GetViewGeometry())
	
end

function widget:Shutdown()
end
