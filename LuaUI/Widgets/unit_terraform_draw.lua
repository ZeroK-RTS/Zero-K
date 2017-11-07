function widget:GetInfo()
  return {
    name      = "Terraform Icon Draw",
    desc      = "Draws terraform unit icon",
    author    = "ivand",
    date      = "2017",
    license   = "GNU GPL, v2 or later",
    layer     = -10,
    enabled   = true,
    alwaysStart = true,
  }
end

-------------------------------------------------------------

local terraunitDefID = UnitDefNames["terraunit"].id
local terraOffset = UnitDefNames["terraunit"].height + 14 --magic number from ETA widget

local terraUnits = {}

local pathPrefix = "LuaUI/Images/commands/"
local terraIcons = {
	[1] = pathPrefix.."level.png",
	[2] = pathPrefix.."raise.png",
	[3] = pathPrefix.."smooth.png",
	[4] = pathPrefix.."ramp.png",
	[5] = pathPrefix.."restore.png",
	[6] = pathPrefix.."bumpy.png",
}

local gfRemove = -1

local function UpdateTeamColors()
	for unitID, info in pairs(terraUnits) do
		local teamID = Spring.GetUnitTeam(unitID)
		if teamID then
			local r, g, b, a = Spring.GetTeamColor(teamID)
			info.r, info.g, info.b, info.a = r, g, b, a
		end
	end
end

function widget:Initialize()
	for _, unitID in ipairs(Spring.GetAllUnits()) do
		local unitDefID = Spring.GetUnitDefID(unitID)
		local teamID = Spring.GetUnitTeam(unitID)
		widget:UnitCreated(unitID, unitDefID, teamID)
	end
	
	if WG.LocalColor and WG.LocalColor.RegisterListener then
		WG.LocalColor.RegisterListener(widget:GetInfo().name, UpdateTeamColors)
	end
end

function widget:UnitCreated(unitID, unitDefID, teamID)
	if unitDefID == terraunitDefID then
		local r, g, b, a = Spring.GetTeamColor(teamID)
		terraUnits[unitID] = {
			allyTeamID = Spring.GetUnitAllyTeam(unitID),
			terraformType = 0,
			r = r,
			g = g,
			b = b,
			a = a,
		}
		gfRemove = Spring.GetGameFrame() + 0
		widgetHandler:UpdateCallIn("GameFrame")
	end
end

function widget:GameFrame(frame)
	for unitID, info in pairs(terraUnits) do
		if info and info.terraformType == 0 then --not yet known terraformType
			local terraformType=Spring.GetUnitRulesParam(unitID, "terraformType") or 0
			terraUnits[unitID].terraformType = terraformType
		end
	end

	if frame >= gfRemove then
		widgetHandler:RemoveCallIn("GameFrame")
	end
end

function widget:UnitDestroyed(unitID, unitDefID)
	if terraUnits[unitID] then
		terraUnits[unitID] = nil
	end
end

local iconSize = 14
local function DrawTerraformIcon(unitID, info)
	gl.Texture(terraIcons[info.terraformType])

	local x, y, z = Spring.GetUnitPosition(unitID)
	local cx, cy, cz = Spring.GetCameraPosition()

	local cameraDist = math.min( 8000, math.sqrt( (cx-x)*(cx-x) + (cy-y)*(cy-y) + (cz-z)*(cz-z) ) )
	local scale = math.sqrt((cameraDist / 600)) --number is an "optimal" view distance
	scale = math.min(scale, 1) --stop keeping icon size unchanged if zoomed out farther than "optimal" view distance

	gl.Scale(scale, scale, scale)

	if Spring.IsUnitSelected(unitID) then
		gl.Color(1, 1, 1)
	else
		gl.Color(info.r, info.g, info.b, info.a)
	end

	gl.Translate(0, terraOffset, 0)
	gl.Billboard()
	gl.Translate(0, -7, 0)
	gl.TexRect(-iconSize, -iconSize, iconSize, iconSize)

	gl.Texture(false)
end

function widget:DrawWorld()
	if Spring.IsGUIHidden() then return end
	gl.DepthTest(false)
	for unitID, info in pairs(terraUnits) do
		if info and info.terraformType > 0 and Spring.IsUnitVisible(unitID, nil, true) then
			local state = Spring.GetUnitLosState(unitID, info.allyTeamID, false)
			if state and state.los then
				gl.DrawFuncAtUnit(unitID, false, DrawTerraformIcon, unitID, info)
			end
		end
	end
end
