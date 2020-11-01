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
for profileID, data in pairs( WG.ModularCommAPI.GetPlayerCommProfiles(Spring.GetMyPlayerID(), true)) do
	numComms = numComms + 1
	commDataOrdered[numComms] = data
	commDataOrdered[numComms].profileID = profileID
end
--Spring.Echo("wololo", "Player " .. Spring.GetMyPlayerID() .. " has " .. numComms .. " comms")
table.sort(commDataOrdered, function(a,b) return a.profileID < b.profileID end)

local chassisImages = {
	armcom = "LuaUI/Images/startup_info_selector/chassis_armcom.png",
	corcom = "LuaUI/Images/startup_info_selector/chassis_corcom.png",
	commrecon = "LuaUI/Images/startup_info_selector/chassis_commrecon.png",
	commsupport = "LuaUI/Images/startup_info_selector/chassis_commsupport.png",
	benzcom = "LuaUI/Images/startup_info_selector/chassis_benzcom.png",
	cremcom = "LuaUI/Images/startup_info_selector/chassis_cremcom.png",
	
	recon = "LuaUI/Images/startup_info_selector/chassis_commrecon.png",
	support = "LuaUI/Images/startup_info_selector/chassis_commsupport.png",
	assault = "LuaUI/Images/startup_info_selector/chassis_benzcom.png",
	strike = "LuaUI/Images/startup_info_selector/chassis_commstrike.png",
	knight = "LuaUI/Images/startup_info_selector/chassis_cremcom.png"
}

local moduleDefs, emptyModules, chassisDefs, upgradeUtilities, chassisDefByBaseDef, moduleDefNames, chassisDefNames = VFS.Include("LuaRules/Configs/dynamic_comm_defs.lua")

local colorWeapon = "\255\255\32\32"
local colorConversion = "\255\255\96\0"
local colorWeaponMod = "\255\255\0\255"
local colorModule = "\255\128\128\255"

local function WriteTooltip(profileID)
	local commData = WG.ModularCommAPI.GetCommProfileInfo(profileID)
	local str = ''
	for i=1,#commData.modules do
		str = str .. "\nLEVEL "..(i + 1) .. "\n\tModules:"	-- TODO calculate metal cost
		for j, modulename in pairs(commData.modules[i]) do
			if moduleDefNames[modulename] then
				local moduleDef = moduleDefs[moduleDefNames[modulename]]
				local substr = moduleDef.humanName
				
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

local function GetCommSelectTemplate(num, data)
	local commProfileID = data.profileID
	
	local option = {
		name = data.name,
		tooltip = "Select "..data.name..WriteTooltip(commProfileID),
		image = chassisImages[data.chassis],
		cmd = "customcomm:"..commProfileID,
		unitname = comm1Name,
		commProfile = commProfileID,
		trainer = string.find(commProfileID, "trainer") ~= nil,	-- FIXME should probably be in the def table
	}
	
	return option
end

--------------------------------------------------------------------------------
--------------------------------------------------------------------------------

local i = 0
for i = 1, numComms do
	local option = GetCommSelectTemplate(i, commDataOrdered[i])
	optionData[#optionData+1] = option
end


return optionData
