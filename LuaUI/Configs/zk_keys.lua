local date = 20130219	-- yyyymmdd
			-- if newer than user's, overwrite ALL zir zk_keys
			-- else just add any that are missing from local config
local keybinds = {
	-- only keybinds that differ from uikeys.txt need to be specified
	{	[=[stop]=], 	[=[s]=], },
}

return {keybinds=keybinds, date=date}