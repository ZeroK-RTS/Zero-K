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

local optionData = {
	strikecomm = {
		enabled = ReturnFalse, --function() return (not Spring.GetSpectatingState()) end, -- enabled = true is not spec
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
		enabled = ReturnFalse,	-- function() return (not Spring.GetSpectatingState()) end,
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
		enabled = ReturnFalse,	--function() return (not Spring.GetSpectatingState()) end,
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
		enabled = ReturnFalse,	--function() return (not Spring.GetSpectatingState()) end,
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
		selector = "Communism Mode",-- set here for futur modifications, even is unused at the moment
		tooltip = "Communism Mode",
		sound = "LuaUI/Sounds/communism/sovnat1.wav" -- only for communism -- effective sound play in LuaUI\Widgets\gui_startup_info_selector.lua
	},
	shuffle = {
		enabled = ReturnFalse, -- Reminder panel now dedicated to commander selection.
		poster = "LuaUI/Images/startup_info_selector/shuffle.png",
		selector = "Commander Shuffle",-- set here for futur modifications, even is unused at the moment
		tooltip = "Commander Shuffle",
	},
	planetwars = {
		enabled = ReturnFalse,
		poster = "LuaUI/Images/startup_info_selector/planetwars.png",
		selector = "PlanetWars",-- set here for futur modifications, even is unused at the moment
		tooltip = "PlanetWars",
	}
}

local function CommSelectTemplate(num, seriesName, comm1Name)
	local option = {
		enabled = function() return true end,
		poster = "LuaUI/Images/startup_info_selector/customcomm"..num..".png",
		selector = seriesName,
		tooltip = "Select comm config number "..num.." ("..seriesName..")",
		button = function()
			Spring.SendLuaRulesMsg("customcomm:"..seriesName)
			Spring.SendCommands({'say a:I choose: '..seriesName..'!'})
			Close(true)
		end
	}
	-- TODO: put chassis and module info in here
	
	return option
end	


local myID = Spring.GetMyPlayerID()
local commData, success
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

local i = 0
for seriesName, comms in pairs(commData) do
	i = i+1
	if i > 4 then break end
	local option = CommSelectTemplate(i, seriesName, comms[1])
	optionData[#optionData+1] = option
end


return optionData