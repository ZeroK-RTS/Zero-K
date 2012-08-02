--all these will be used in LuaUI\Widgets\gui_startup_info_selector.lua
-- Changelog --
-- versus666	(30oct2010)	:	Added selector to remplace tooltip which is now shown by chili_selection.
--								Added long description of commanders strengths et weakness to tooltip.
--								Commented a lot for easier modification.
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
		tooltip = "Strike Commander\nUses beam laser, has a greater speed but less health.",--will be used as option.tooltip
		button = function()
			Spring.SendLuaRulesMsg("faction:strikecomm")
			Spring.SendCommands({'say a:I choose: Strike Commander !'})
			Close(true)
		end 
	},

	battlecomm = {
		enabled = ReturnNoCustomComms,	-- function() return (not Spring.GetSpectatingState()) end,
		poster = "LuaUI/Images/startup_info_selector/corcom.jpg",
		selector ="Battle Comm",
		tooltip = "Battle Commander\nUses a riot cannon; has more health but slower speed.",
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
		tooltip = "Recon Commander\nUses a slow-ray, has high mobility but with lower income and reduced health.",
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
		tooltip = "Support Commander\nUses a railgun (pierces units), has increased income and build range but low health and speed. Comes with free storage.",
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
		selector = "Commander Shuffle",-- set here for future modifications, even if unused at the moment
		tooltip = "Commander Shuffle",
	},
	planetwars = {
		enabled = ReturnFalse,
		poster = "LuaUI/Images/startup_info_selector/planetwars.png",
		selector = "PlanetWars",-- set here for future modifications, even if unused at the moment
		tooltip = "PlanetWars",
	}
}

--------------------------------------------------------------------------------
--------------------------------------------------------------------------------
-- most of the data processing was moved to api_modularcomms.lua

local commDataOrdered = {}
local numComms = 0
for seriesName, comms in pairs(WG.commData) do
	numComms = numComms + 1
	commDataOrdered[numComms] = comms
	commDataOrdered[numComms].seriesName = seriesName
end
table.sort(commDataOrdered, function(a,b) return a[1] < b[1] end)

local chassisImages = {
	armcom1 = "LuaUI/Images/startup_info_selector/chassis_strike.png",
	corcom1 = "LuaUI/Images/startup_info_selector/chassis_battle.png",
	commrecon1 = "LuaUI/Images/startup_info_selector/chassis_recon.png",
	commsupport1 = "LuaUI/Images/startup_info_selector/chassis_support.png",
}

local colorWeapon = "\255\255\32\32"
local colorConversion = "\255\255\96\0"
local colorWeaponMod = "\255\255\0\255"
local colorModule = "\255\128\128\255"

local function WriteTooltip(seriesName)
	local data = WG.GetCommSeriesInfo(seriesName, true)
	local str = ''
	local upgrades = WG.GetCommUpgradeList()
	for i=1,#data do
		str = str .. "\nLEVEL "..i.. " ("..data[i].cost.." metal)\n\tModules:"
		for j, modulename in pairs(data[i].modules) do
			if upgrades[modulename] then
				local substr = upgrades[modulename].name
				-- assign color
				if (modulename):find("commweapon_") then
					substr = colorWeapon..substr
				elseif (modulename):find("conversion_") then
					substr = colorConversion..substr
				elseif (modulename):find("weaponmod_") then
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
	if not UnitDefNames[comm1Name] then return end
	
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