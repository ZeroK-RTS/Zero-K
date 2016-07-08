function widget:GetInfo()
	return {
		name      = "Decloak Range",
		desc      = "Display deacloak range around cloaked units",
		author    = "banana_Ai",
		date      = "28 Feb 2016",
		license   = "GNU GPL v2",
		layer     = 0,
		enabled   = true,  --  loaded by default?
	}
end

VFS.Include("LuaRules/Utilities/glVolumes.lua")

local Chili
options_path = 'Settings/Interface/Decloak Ranges'
options_order = {"drawranges", "onlyforcloaked", "onlyforselected"}
options = {
	drawranges = {
		name = 'Draw decloak ranges', 
		type = 'bool', 
		value = false,
		OnChange = function (self)
			if self.value then
				widgetHandler:UpdateCallIn("DrawWorldPreUnit")
			else
				widgetHandler:RemoveCallIn("DrawWorldPreUnit")
			end
		end
	},
	onlyforcloaked = {
		name = 'Draw only for cloaked units', 
		type = 'bool', 
		value = true,
	},
	onlyforselected = {
		name = 'Draw only for selected units', 
		type = 'bool', 
		value = true,
	}
}

local function DrawDecloackArea(unitID,def)
	local r = def.decloakDistance
	local x,_,z=Spring.GetUnitPosition(unitID)
	gl.Color(0.3,0.3,1.0,0.4)
	gl.Utilities.DrawGroundCircle(x,z,r)
end

function widget:DrawWorldPreUnit()
	local units
	if options.onlyforselected.value then
		units = Spring.GetSelectedUnits()
	else
		units = Spring.GetTeamUnits(Spring.GetLocalTeamID())
	end
	
	for _,unitID in ipairs(units) do
		local defID = Spring.GetUnitDefID(unitID)
		local def = UnitDefs[defID]
		
		if Spring.GetUnitIsCloaked(unitID) or 
				(def and def.canCloak and not options.onlyforcloaked.value) then
			DrawDecloackArea(unitID,def)
		end
	end
end

function widget:Initialize()
	widgetHandler:RemoveCallIn("DrawWorldPreUnit")
end
