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

local optionData = {}

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
	armcom1 = "LuaUI/Images/startup_info_selector/chassis_armcom.png",
	corcom1 = "LuaUI/Images/startup_info_selector/chassis_corcom.png",
	commrecon1 = "LuaUI/Images/startup_info_selector/chassis_commrecon.png",
	commsupport1 = "LuaUI/Images/startup_info_selector/chassis_commsupport.png",
	benzcom1 = "LuaUI/Images/startup_info_selector/chassis_benzcom.png",
	cremcom1 = "LuaUI/Images/startup_info_selector/chassis_cremcom.png",
}

local colorWeapon = "\255\255\32\32"
local colorConversion = "\255\255\96\0"
local colorWeaponMod = "\255\255\0\255"
local colorModule = "\255\128\128\255"

local function WriteTooltip(seriesName)
	local data = WG.GetCommSeriesInfo(seriesName, true)
	local str = ''
	local upgrades = WG.GetCommUpgradeList()
	for i=2,#data do	-- exclude level 0 comm
		str = str .. "\nLEVEL "..(i-1).. " ("..data[i].cost.." metal)\n\tModules:"
		for j, modulename in pairs(data[i].modulesRaw) do
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

local function CommSelectTemplate(num, data)
	local seriesName = data.seriesName
	local comm1Name = data[1]
	if not UnitDefNames[comm1Name] then return end
	
	local option = {
		name = seriesName,
		image = chassisImages[UnitDefNames[comm1Name].customParams.statsname],
		tooltip = "Select "..seriesName..WriteTooltip(seriesName),
		--cmd = "customcomm:"..seriesName,
		unitname = comm1Name,
		trainer = data.trainer,
	}
	
	return option
end	

--------------------------------------------------------------------------------
--------------------------------------------------------------------------------

local i = 0
for i = 1, numComms do
	local option = CommSelectTemplate(i, commDataOrdered[i])
	optionData[#optionData+1] = option
end


return optionData
