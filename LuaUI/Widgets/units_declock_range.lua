function widget:GetInfo()
	return {
		name      = "DecloackArea v1.1",
		desc      = "Display deacloack area around cloacked units",
		author    = "banana_Ai",
		date      = "28 Feb 2016",
		license   = "GNU GPL v2",
		layer     = 0,
		enabled   = true,  --  loaded by default?
	}
end

local Chili
options_path = 'Settings/Interface/Decloak Ranges'
options={
	onlyforcloacked={
		name = 'Draw only for cloaked units', 
		type = 'bool', 
		value = true,
	},
	onlyforselected={
		name = 'Draw only for selected units', 
		type = 'bool', 
		value = true,
	}
}

options_order = {
	'onlyforcloacked',
	'onlyforselected'
}

local localTeamID=Spring.GetLocalTeamID()

local function DrawDecloackArea(unitID,def)
	local r=def.decloakDistance
	local x,_,z=Spring.GetUnitPosition(unitID)
	gl.Color(0.3,0.3,1.0,0.4)
	gl.Utilities.DrawGroundCircle(x,z,r)
end

function widget:DrawWorldPreUnit()
	local units
	if options.onlyforselected.value then
		units=Spring.GetSelectedUnits()
	else
		units=Spring.GetTeamUnits(localTeamID)
	end
	
	for _,unitID in ipairs(units) do
		local defID=Spring.GetUnitDefID(unitID)
		local def=UnitDefs[defID]
		
		if Spring.GetUnitIsCloaked(unitID) or 
				(def.canCloak and not options.onlyforcloacked.value) then
			DrawDecloackArea(unitID,def)
		end
	end
end

VFS.Include("LuaRules/Utilities/glVolumes.lua")
