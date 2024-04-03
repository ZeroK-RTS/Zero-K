function widget:GetInfo()
	return {
		name      = "Inspect Commands",
		desc      = "Debug tool for inspecting the commands given to a unit",
		author    = "GoogleFrog",
		date      = "3 April 2024",
		license   = "GNU GPL, v2 or later",
		layer     = 0,
		enabled   = false  --  loaded by default?
	}
end

--------------------------------------------------------------------------------
--------------------------------------------------------------------------------

local activeUnits

local function ActivateOnSelectedUnits()
	if activeUnits then
		for i = 1, #activeUnits do
			Spring.SendCommands({"luarules unitcmds " .. activeUnits[i] .. " 0"})
		end
	end
	local units = Spring.GetSelectedUnits()
	if not units or #units == 0 then
		activeUnits = nil
		return
	end
	activeUnits = {}
	for i = 1, #units do
		Spring.SendCommands({"luarules unitcmds " .. units[i] .. " 1"})
		activeUnits[#activeUnits + 1] = units[i]
	end
end

options_path = 'Settings/Toolbox/Inspect Commands'
options_order = {'enableOnSelection'}
options = {
	enableOnSelection = {
		name = "Set units",
		desc = "Sets the selected units to command inspection mode",
		type = "button",
		OnChange = ActivateOnSelectedUnits,
	},
}

--------------------------------------------------------------------------------
--------------------------------------------------------------------------------
