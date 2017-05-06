-------------------------------------------------------------------------------------
-------------------------------------------------------------------------------------

function widget:GetInfo()
	return {
		name = "Raw Move Issue",
		desc = "Helper widget for command modifiers for CMD_RAW_MOVE",
		author = "GoogleFrog",
		date = "25 April 2017",
		license = "GNU GPL, v2 or later",
		layer = 0,
		enabled = true,
	}
end

VFS.Include("LuaRules/Configs/customcmds.h.lua")

function widget:CommandNotify(id, params, options)
	if id == CMD_RAW_MOVE and options.ctrl then
		local selUnits = Spring.GetSelectedUnits()
		local ax, az, count = 0, 0, 0
		local positions = {}
		for i = 1, #selUnits do
			local x,_,z = Spring.GetUnitPosition(selUnits[i])
			if x then
				ax, az, count = ax + x, az + z, count + 1
				positions[i] = {x, z}
			end
		end
		if count == 0 then
			return true
		end
		ax, az = params[1] -  ax/count, params[3] - az/count
		local ay = params[2]
		
		for i = 1, #selUnits do
			local x, y, z = ax, ay, az
			if positions[i] then
				x, z = x + positions[i][1], z + positions[i][2]
				y = Spring.GetGroundHeight(x, z)
			end
			Spring.GiveOrderToUnit(selUnits[i], CMD_RAW_MOVE, {x, y, z}, options)
		end
		return true
	end
	
	return false
end
