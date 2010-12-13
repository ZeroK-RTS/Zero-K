--all these will be used in LuaUI\Widgets\gui_startup_info_selector.lua
-- Changelog --
-- versus666	(30oct2010)	:	Added selector to remplace tooltip which is now shown by chili_selection.
--								Added long description of commanders strengths et weakness to tooltip.
--								Commented a lot for easier modification.

local optionData = {
strikecomm = {
	enabled = function() return (not Spring.GetSpectatingState()) end, -- enabled = true is not spec
	poster = "LuaUI/Images/startup_info_selector/armcom.jpg",--will be used as option.poster
	selector = "Strike Comm",--will be used as option.selector
	tooltip = "Strike Commander\nUse beam laser, have a greater speed but less health.\nADV Strike Commander\nGain DGUN, even greater speed, cloak field, and personal cloak cost halved.",--will be used as option.tooltip
	button = function()
	Spring.SendLuaRulesMsg("faction:nova")
	printDebug("strike com")
	Spring.SendCommands({'say a: I choose: Strike Commander !'})
	Close(true)
	end 
	},

battlecomm = {
	enabled = function() return (not Spring.GetSpectatingState()) end,
	poster = "LuaUI/Images/startup_info_selector/corcom.jpg",
	selector ="Battle Comm",
	tooltip = "Battle Commander\nUse a pulse autocannon and have more health but slower speed.\nADV Battle Commander\nGain AoE cluster bombs, an high power area shield and double health gains.\n\* BOTH HAVE NO CLOAK \*",
	button = function() 
	Spring.SendLuaRulesMsg("faction:logos")
	Spring.SendCommands({'say a:I choose: Battle Commander !'})
	Close(true)
	end 
	},

reconcomm = {
	enabled = function() return (not Spring.GetSpectatingState()) end,
	poster = "LuaUI/Images/startup_info_selector/commrecon.jpg",
	selector ="Recon Comm",
	tooltip = "Recon Commander\nUse a low cost cloak and high mobility suit but a low RoF pulse rifle, lower income and reduced health.\nADV Recon Commander\nGain AoE slow bombs, higher mobility suit and an ULTRA LOW cost cloak.\n\* BOTH CAN JUMP \*",
	button = function() 
	Spring.SendLuaRulesMsg("faction:reconcomm")
	Spring.SendCommands({'say a:I choose: Recon Commander !'})
	Close(true)
	end 
	},

supportcomm = {
	enabled = function() return (not Spring.GetSpectatingState()) end,
	poster = "LuaUI/Images/startup_info_selector/commsupport.jpg",
	selector = "Support Comm",--because of the way spring handle font this text ("pp") is a shown few pixels higher than expected, nothing lethal.
	tooltip = "Support Commander\nUse a slow-ray (non-damaging), have increased income and build range but low health and speed. Comes with free storage.\nADV Support Commander\nGain better build power and radar range, wide healing aura, increased income, and a disruptor beam (damage + slow).",
	button = function() 
	Spring.SendLuaRulesMsg("faction:supportcomm")
	Spring.SendCommands({'say a:I choose: Support Commander !'})
	Close(true)
	end 
	},

communism = {
	enabled = function()
		return false -- always enabled - so we hide it
	end,
	poster = "LuaUI/Images/startup_info_selector/communism.jpg",
	selector = "Communism Mode",-- set here for futur modifications, even is unused at the moment
	tooltip = "Communism Mode",
	sound = "LuaUI/Sounds/communism/sovnat1.wav" -- only for communism -- effective sound play in LuaUI\Widgets\gui_startup_info_selector.lua
	},
shuffle = {
	enabled = function()
		return false -- Reminder panel now dedicated to commander selection.
	end,
	poster = "LuaUI/Images/startup_info_selector/shuffle.png",
	selector = "Commander Shuffle",-- set here for futur modifications, even is unused at the moment
	tooltip = "Commander Shuffle",
	},
planetwars = {
	enabled = function()
	--if modoptions and modoptions.planetwars ~= "" then
	--  return true
	--end
		return false
	end,
	poster = "LuaUI/Images/startup_info_selector/planetwars.png",
	selector = "PlanetWars",-- set here for futur modifications, even is unused at the moment
	tooltip = "PlanetWars",
	}
}
return optionData