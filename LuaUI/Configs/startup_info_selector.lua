--all these will be used in LuaUI\Widgets\gui_startup_info_selector.lua
-- Changelog --
-- versus666	(30oct2010)	:	Added selector to remplace tooltip which is now shown by chili_selection.
--								Added long description of commanders strengths et weakness to tooltip.
--								Commented a lot for easier modification.
Spring.Utilities = Spring.Utilities or {}
VFS.Include("LuaRules/Utilities/base64.lua")

local function ReturnFalse()
	return false
end

local noCustomComms = ((Spring.GetModOptions().commandertypes == nil or Spring.GetModOptions().commandertypes == '') and true) or false
local function ReturnNoCustomComms()
	return noCustomComms
end

local optionData = {
	strikecomm = {
		enabled = ReturnNoCustomComms, --function() return (not Spring.GetSpectatingState()) end, -- enabled = true is not spec
		poster = "LuaUI/Images/startup_info_selector/armcom.jpg",--will be used as option.poster
		selector = "Strike Comm",--will be used as option.selector
		tooltip = "Strike Commander\nUses beam laser, has a greater speed but less health.\nADV Strike Commander\nGain DGUN, even greater speed, cloak field, and personal cloak cost halved.",--will be used as option.tooltip
		button = function()
			Spring.SendLuaRulesMsg("faction:strikecomm")
			Spring.SendCommands({'say a: I choose: Strike Commander !'})
			Close(true)
		end 
	},

	battlecomm = {
		enabled = ReturnNoCustomComms,	-- function() return (not Spring.GetSpectatingState()) end,
		poster = "LuaUI/Images/startup_info_selector/corcom.jpg",
		selector ="Battle Comm",
		tooltip = "Battle Commander\nUses a pulse autocannon and has more health but slower speed.\nADV Battle Commander\nGain AoE cluster bombs, an high power area shield and double health gains.\n\* BOTH HAVE NO CLOAK \*",
		button = function() 
			Spring.SendLuaRulesMsg("faction:battlecomm")
			Spring.SendCommands({'say a:I choose: Battle Commander !'})
			Close(true)
		end 
	},

	reconcomm = {
		enabled = ReturnNoCustomComms,	--function() return (not Spring.GetSpectatingState()) end,
		poster = "LuaUI/Images/startup_info_selector/commrecon.jpg",
		selector ="Recon Comm",
		tooltip = "Recon Commander\nUses a slow-ray, has low cost cloak and high mobility but with lower income and reduced health.\nADV Recon Commander\nGain AoE slow bombs, higher mobility suit and an ULTRA LOW cost cloak.\n\* BOTH CAN JUMP \*",
		button = function() 
			Spring.SendLuaRulesMsg("faction:reconcomm")
			Spring.SendCommands({'say a:I choose: Recon Commander !'})
			Close(true)
		end 
	},

	supportcomm = {
		enabled = ReturnNoCustomComms,	--function() return (not Spring.GetSpectatingState()) end,
		poster = "LuaUI/Images/startup_info_selector/commsupport.jpg",
		selector = "Support Comm",--because of the way spring handle font this text ("pp") is a shown few pixels higher than expected, nothing lethal.
		tooltip = "Support Commander\nUses a railgun (pierces units), has increased income and build range but low health and speed. Comes with free storage.\nADV Support Commander\nGain better build power and radar range, wide healing aura, increased income, and can fire a concussion shot (AoE + impulse).",
		button = function() 
			Spring.SendLuaRulesMsg("faction:supportcomm")
			Spring.SendCommands({'say a:I choose: Support Commander !'})
			Close(true)
		end 
	},

	communism = {
		enabled = ReturnFalse, -- always enabled - so we hide it
		poster = "LuaUI/Images/startup_info_selector/communism.jpg",
		selector = "Communism Mode",-- set here for future modifications, even is unused at the moment
		tooltip = "Communism Mode",
		sound = "LuaUI/Sounds/communism/sovnat1.wav" -- only for communism -- effective sound play in LuaUI\Widgets\gui_startup_info_selector.lua
	},
	shuffle = {
		enabled = ReturnFalse, -- Reminder panel now dedicated to commander selection.
		poster = "LuaUI/Images/startup_info_selector/shuffle.png",
		selector = "Commander Shuffle",-- set here for future modifications, even is unused at the moment
		tooltip = "Commander Shuffle",
	},
	planetwars = {
		enabled = ReturnFalse,
		poster = "LuaUI/Images/startup_info_selector/planetwars.png",
		selector = "PlanetWars",-- set here for future modifications, even is unused at the moment
		tooltip = "PlanetWars",
	}
}

local chassisImages = {
	armcom1 = "LuaUI/Images/startup_info_selector/chassis_strike.png",
	corcom1 = "LuaUI/Images/startup_info_selector/chassis_battle.png",
	commrecon1 = "LuaUI/Images/startup_info_selector/chassis_recon.png",
	commsupport1 = "LuaUI/Images/startup_info_selector/chassis_support.png",
}

--------------------------------------------------------------------------------
-- load data
--------------------------------------------------------------------------------
local success, err

-- global comm data (from the modoption)
local commDataGlobal
local commDataGlobalRaw = Spring.GetModOptions().commandertypes
if not (commDataGlobalRaw and type(commDataGlobalRaw) == 'string') then
	err = "Comm data entry in modoption is empty or in invalid format"
	commDataGlobal = {}
else
	commDataGlobalRaw = string.gsub(commDataGlobalRaw, '_', '=')
	commDataGlobalRaw = Spring.Utilities.Base64Decode(commDataGlobalRaw)
	--Spring.Echo(commDataRaw)
	local commDataGlobalFunc, err = loadstring("return "..commDataGlobalRaw)
	if commDataGlobalFunc then 
		success, commDataGlobal = pcall(commDataGlobalFunc)
		if not success then
			err = commDataGlobal
			commData = {}
		end
	end
end

if err then 
	Spring.Echo('Startup Info & Selector error: ' .. err)
end

-- player comm data (from customkeys)
local myID = Spring.GetMyPlayerID()
local commData
local customKeys = select(10, Spring.GetPlayerInfo(myID))
local commDataRaw = customKeys and customKeys.commanders
if not (commDataRaw and type(commDataRaw) == 'string') then
	err = "Your comm data entry is empty or in invalid format"
	commData = {}
else
	commDataRaw = string.gsub(commDataRaw, '_', '=')
	commDataRaw = Spring.Utilities.Base64Decode(commDataRaw)
	--Spring.Echo(commDataRaw)
	local commDataFunc, err = loadstring("return "..commDataRaw)
	if commDataFunc then 
		success, commData = pcall(commDataFunc)
		if not success then
			err = commData
			commData = {}
		end
	end
end
if err then 
	Spring.Echo('Startup Info & Selector error: ' .. err)
end

local commDataOrdered = {}
local numComms = 0
for seriesName, comms in pairs(commData) do
	numComms = numComms + 1
	commDataOrdered[numComms] = comms
	commDataOrdered[numComms].seriesName = seriesName
end
table.sort(commDataOrdered, function(a,b) return a[1] < b[1] end)

VFS.Include("gamedata/modularcomms/moduledefs.lua")

--------------------------------------------------------------------------------
--------------------------------------------------------------------------------
-- yeah, yeah, n^2
local function RemoveDuplicates(base, delete)
	for i1,v1 in pairs(base) do
		for i2,v2 in pairs(delete) do
			if v1 == v2 then
				base[i1] = nil
				break
			end
		end
	end
end

-- gets modules and costs
local function GetSeriesInfo(seriesName)
	local data = {}
	local commList = commData[seriesName]
	for i=1,#commList do
		data[i] = {name = commList[i]}
	end
	for i=1,#data do
		data[i].modules = commDataGlobal[data[i].name] and commDataGlobal[data[i].name].modules or {}
		data[i].cost = commDataGlobal[data[i].name] and commDataGlobal[data[i].name].cost or 0
	end
	-- remove reference to modules already in previous levels
	for i = #data, 2, -1 do
		RemoveDuplicates(data[i].modules, data[i-1].modules)
		data[i].cost = data[i].cost - data[i-1].cost
	end
	return data
end

local colorWeapon = "\255\255\32\32"
local colorConversion = "\255\255\96\0"
local colorWeaponMod = "\255\255\0\255"
local colorModule = "\255\128\128\255"

local function WriteTooltip(seriesName)
	local data = GetSeriesInfo(seriesName)
	local str = ''
	for i=1,#data do
		str = str .. "\nLEVEL "..i.. " ("..data[i].cost.." metal)\n\tModules:"
		for j=1,#(data[i].modules) do
			if upgrades[data[i].modules[j]] then
				local substr = upgrades[data[i].modules[j]].name
				-- assign color
				if (data[i].modules[j]):find("commweapon_") then
					substr = colorWeapon..substr
				elseif (data[i].modules[j]):find("conversion_") then
					substr = colorConversion..substr
				elseif (data[i].modules[j]):find("weaponmod_") then
					substr = colorWeaponMod..substr
				else
					substr = colorModule..substr
				end
				str = str.."\n\t\t"..substr.."\008"
			end
		end
	end
	return str
end

local function CommSelectTemplate(num, seriesName, comm1Name)
	local option = {
		enabled = function() return true end,
		poster = chassisImages[UnitDefNames[comm1Name].customParams.statsname],
		poster2 = "LuaUI/Images/startup_info_selector/customcomm"..num..".png",
		selector = seriesName,
		tooltip = "Select comm config number "..num.." ("..seriesName..")"..WriteTooltip(seriesName),
		button = function()
			Spring.SendLuaRulesMsg("customcomm:"..seriesName)
			Spring.SendCommands({'say a:I choose: '..seriesName..'!'})
			Close(true)
		end
	}
	
	return option
end	

--------------------------------------------------------------------------------
--------------------------------------------------------------------------------

local i = 0
for i = 1, numComms do
	local option = CommSelectTemplate(i, commDataOrdered[i].seriesName, commDataOrdered[i][1])
	optionData[#optionData+1] = option
end


return optionData