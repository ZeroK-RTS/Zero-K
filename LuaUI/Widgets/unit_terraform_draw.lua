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
-------------------------------------------------------------

local glVertex            = gl.Vertex
local spGetUnitPosition   = Spring.GetUnitPosition
local spValidUnitID       = Spring.ValidUnitID
local spGetMyAllyTeamID   = Spring.GetMyAllyTeamID
local spGetUnitVectors    = Spring.GetUnitVectors
local spGetLocalTeamID    = Spring.GetLocalTeamID
local spGetUnitIsStunned  = Spring.GetUnitIsStunned
local spGetUnitRulesParam = Spring.GetUnitRulesParam

local terraunitDefID = UnitDefNames["terraunit"].id
local terraOffset = UnitDefNames["terraunit"].height + 14 --magic number from ETA widget

local FLASH_TIME = 1.4

local flash = 0

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
pathPrefix = "LuaUI/Images/commands/blocked/"
local terraBlockedIcons = {
	[1] = pathPrefix.."level.png",
	[2] = pathPrefix.."raise.png",
	[3] = pathPrefix.."smooth.png",
	[4] = pathPrefix.."ramp.png",
	[5] = pathPrefix.."restore.png",
	[6] = pathPrefix.."bumpy.png",
}

local UPDATE_FREQUENCY = 10
local forceGameFrame = false

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
		forceGameFrame = true
	end
end

function widget:Update(dt)
	flash = (flash + dt)%FLASH_TIME
end

function widget:GameFrame(frame)
	if not (forceGameFrame or frame%UPDATE_FREQUENCY == 0) then
		return
	end
	forceGameFrame = false
	
	for unitID, info in pairs(terraUnits) do
		if info and info.terraformType == 0 then --not yet known terraformType
			local terraformType = Spring.GetUnitRulesParam(unitID, "terraformType") or 0
			terraUnits[unitID].terraformType = terraformType
		end
		local blocked = Spring.GetUnitRulesParam(unitID, "terraform_enemy")
		if blocked then
			blocked = (blocked > -1 and blocked) or false
			terraUnits[unitID].blocked = blocked
		end
	end
end

function widget:UnitDestroyed(unitID, unitDefID)
	if terraUnits[unitID] then
		terraUnits[unitID] = nil
	end
end

local iconSize = 14
local function DrawTerraformIcon(unitID, info)
	if info.blocked then
		gl.Texture(terraBlockedIcons[info.terraformType])
	else
		gl.Texture(terraIcons[info.terraformType])
	end

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

local function DrawBezierCurve(pointA, pointB, pointC,pointD, amountOfPoints)
	local step = 1/amountOfPoints
	glVertex (pointA[1], pointA[2], pointA[3])
	for i=0, 1, step do
		local x = pointA[1]*((1-i)^3) + pointB[1]*(3*i*(1-i)^2) + pointC[1]*(3*i*i*(1-i)) + pointD[1]*(i*i*i)
		local y = pointA[2]*((1-i)^3) + pointB[2]*(3*i*(1-i)^2) + pointC[2]*(3*i*i*(1-i)) + pointD[2]*(i*i*i)
		local z = pointA[3]*((1-i)^3) + pointB[3]*(3*i*(1-i)^2) + pointC[3]*(3*i*i*(1-i)) + pointD[3]*(i*i*i)
		glVertex(x,y,z)
	end
	glVertex(pointD[1],pointD[2],pointD[3])
end

local function DrawWire(emitUnitID, recUnitID)
	local point = {}
	if spValidUnitID(recUnitID) then
		local x, y, z = Spring.GetUnitPosition(emitUnitID)
		point[1] = {x, y, z}
		point[2] = {x, y + 32, z}
		local _,_,_, rX, rY, rZ = Spring.GetUnitPosition(recUnitID, true)
		point[3] = {rX, rY + 48, rZ}
		point[4] = {rX, rY, rZ}
		gl.PushAttrib(GL.LINE_BITS)
		gl.DepthTest(true)
		local intensity = ((flash < FLASH_TIME/2 and (flash*2)) or (FLASH_TIME*2 - flash*2))/FLASH_TIME
		gl.Color (0.7 + 0.3*intensity, 0.3 + 0.1*intensity, 0.3 + 0.1*intensity, math.random()*0.05 + 0.75)
		gl.LineWidth(3)
		gl.BeginEnd(GL.LINE_STRIP, DrawBezierCurve, point[1], point[2], point[3], point[4], 14)
		gl.DepthTest(false)
		gl.Color (1,1,1,1)
		gl.PopAttrib()
	end
end

function widget:DrawWorld()
	if Spring.IsGUIHidden() then
		return
	end
	gl.DepthTest(false)
	gl.Blending(true)
	for unitID, info in pairs(terraUnits) do
		if info and info.terraformType > 0 and Spring.IsUnitVisible(unitID, 550, true) then
			local state = Spring.GetUnitLosState(unitID, info.allyTeamID, false)
			if state and state.los then
				if Spring.IsUnitVisible(unitID, nil, true) then
					gl.DrawFuncAtUnit(unitID, false, DrawTerraformIcon, unitID, info)
				else
					local x, y, z = Spring.GetUnitPosition(unitID)
					gl.PushMatrix()
					gl.Translate(x, y, z)
					DrawTerraformIcon(unitID, info)
					gl.PopMatrix()
				end
				if info.blocked then
					DrawWire(unitID, info.blocked)
				end
			end
		end
	end
	gl.Blending(false)
end
