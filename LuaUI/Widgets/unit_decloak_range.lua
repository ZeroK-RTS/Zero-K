function widget:GetInfo()
	return {
		name      = "Decloak Range",
		desc      = "Display decloak range around cloaked units. v2",
		author    = "banana_Ai, dahn",
		date      = "15 Jul 2016",
		license   = "GNU GPL v2",
		layer     = 0,
		enabled   = true,
	}
end

VFS.Include("LuaRules/Utilities/glVolumes.lua")

local Chili
options_path = 'Settings/Interface/Defense and Cloak Ranges'
options_order = {
	"label",
	"drawranges",
	"onlyforcloaked",
	"onlyforselected",
	"fillcolor"
}
options = {
	label = { type = 'label', name = 'Decloak Ranges' },
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
	},
	fillcolor = {
		name = 'Cloak range color',
		type = 'colors',
		value = {0.3,0.3,1.0,0.4},
	}
}

local function DrawDecloackArea(unitID,def)
	local r = def.decloakDistance
	local x,_,z=Spring.GetUnitPosition(unitID)
	local fillcolor = options.fillcolor.value
	gl.Color(fillcolor[1], fillcolor[2], fillcolor[3], fillcolor[4])
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
