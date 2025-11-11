function widget:GetInfo()
	return {
		name = "Sensor Ranges Radar Preview 2",
		desc = "Raytraced Radar Range Coverage on building Radar (GL4)",
		author = "Beherith",
		date = "2021.07.12",
		license = "GPLv2",
		layer = 0,
		enabled = true
	}
end
local spGetActiveCommand = Spring.GetActiveCommand
local spGetGroundHeight = Spring.GetGroundHeight
local SHADERRESOLUTION = 32 -- THIS SHOULD MATCH RADARMIPLEVEL!
options_path = 'Settings/Interface/Building Placement'
options_order = { 'showOnPlacement', 'showOnSelected'}
options = {}
-- options.shaderRes = {
-- 	name = 'Resolution',
-- 	type = 'number',
-- 	min = 16, max = 32, step = 16,
-- 	value = SHADERRESOLUTION,
-- 	OnChange = function(self)
-- 		SHADERRESOLUTION = self.value
-- 	end
-- }
options.showOnPlacement = {
	name = 'Radar coverage preview',
	type = 'bool',
	value = true,
}
options.showOnSelected = {
	name = 'Selected radar coverage',
	type = 'bool',
	value = true,
}

local radarStructureRange = {}
local radarTotalHeight = {}
local radarEmitHeight = {}

local radarRangeShaders = {}
local radarTruthShader = nil
local selectedRadarUnitID = false

for unitDefID, ud in pairs(UnitDefs) do
	if ud.radarDistance > 100 and not ud.customParams.disable_radar_preview then
		local range = ud.radarDistance
		radarStructureRange[unitDefID] = range
		radarEmitHeight[unitDefID] = ud.radarEmitHeight
		radarTotalHeight[unitDefID] = radarEmitHeight[unitDefID] + ud.model.midy
		if not radarRangeShaders[range] then
			radarRangeShaders[range] = true
		end
	end
end

local luaShaderDir = "LuaUI/Widgets/Include/"
local LuaShader = VFS.Include(luaShaderDir .. "LuaShader.lua")
VFS.Include(luaShaderDir .. "instancevbotable.lua")

local shaderConfig = {}
local vsSrcPath = "LuaUI/Widgets/Shaders/sensor_ranges_radar_preview.vert.glsl"
local fsSrcPath = "LuaUI/Widgets/Shaders/sensor_ranges_radar_preview.frag.glsl"

local shaderSourceCache = {
	vssrcpath = vsSrcPath,
	fssrcpath = fsSrcPath,
	shaderName = "radarTruthShader GL4",
	uniformInt = {
			heightmapTex = 0,
		},
	uniformFloat = {
		radarcenter_range = { 1000, 100, 1000, 1000 },
		resolution = { 128 },
	},
	shaderConfig = shaderConfig,
}

local function goodbye(reason)
	Spring.Echo("radarTruthShader GL4 widget exiting with reason: " .. reason)
	widgetHandler:RemoveWidget()
end

local function initgl4()
	radarTruthShader = LuaShader.CheckShaderUpdates(shaderSourceCache)

	if not radarTruthShader then
		goodbye("Failed to compile radarTruthShader  GL4 ")
	end

	for range, _ in pairs(radarRangeShaders) do
		local radarVertex, _ = makePlaneVBO(1, 1, range / SHADERRESOLUTION)
		local radarIndex, _ = makePlaneIndexVBO(range / SHADERRESOLUTION, range / SHADERRESOLUTION, true)
		radVAO = gl.GetVAO()
		radVAO:AttachVertexBuffer(radarVertex)
		radVAO:AttachIndexBuffer(radarIndex)
		radarRangeShaders[range] = radVAO
	end
end


function widget:Initialize()
	if not gl.CreateShader then -- no shader support, so just remove the widget itself, especially for headless
		widgetHandler:RemoveWidget()
		return
	end

	initgl4()
end

function widget:SelectionChanged(sel)
	selectedRadarUnitID = false
	if #sel == 1 and Spring.GetUnitDefID(sel[1]) and radarStructureRange[Spring.GetUnitDefID(sel[1])] then
		selectedRadarUnitID = sel[1]
	end
end

local function GetRadarUnitToDraw()
	if selectedRadarUnitID and options.showOnSelected.value then
		unitDefID = Spring.GetUnitDefID(selectedRadarUnitID)
		if not unitDefID then
			selectedRadarUnitID = false
			return
		end
		return selectedRadarUnitID, unitDefID
	elseif options.showOnPlacement.value then
		local cmdID = select(2, spGetActiveCommand())
		if cmdID == nil or cmdID >= 0 then
			-- cmdID = WG.currentBuild and WG.currentBuild.defID
			if not cmdID then
				return
			end
		end
		if radarStructureRange[-cmdID] then
			return false, -cmdID
		end
	end
end



local function GetRadarDrawPos(unitID, unitDefID)
	if unitID then
		local _, _, _, x, y, z = Spring.GetUnitPosition(unitID, true) -- Base position
		return x, y + radarEmitHeight[unitDefID], z
	else
		local mx, my, lp, mp, rp, offscreen = Spring.GetMouseState()
		local _, coords = Spring.TraceScreenRay(mx, my, true, true)
		if coords and coords[3] or WG.placementX then
			local x, z
			if WG.placementX then
				x, z = WG.placementX, WG.placementZ
			else
				x, z = Spring.Utilities.SnapToBuildGrid(unitDefID, Spring.GetBuildFacing(), coords[1], coords[3])
			end
			local y = (coords and coords[2] or spGetGroundHeight(x,z)) + radarTotalHeight[unitDefID]
			if WG.placementHeight then
				y = y + WG.placementHeight
			end
			return x, y, z
		end
	end
end

function widget:DrawWorld()
	if Spring.IsGUIHidden() then
		return
	end
	
	local unitID, unitDefID = GetRadarUnitToDraw()
	if not unitDefID then
		return
	end
	
	local drawX, drawY, drawZ = GetRadarDrawPos(unitID, unitDefID)
	if not drawX then
		return
	end
	local range = radarStructureRange[unitDefID]
	gl.DepthTest(false)
	gl.Culling(GL.BACK)
	gl.Texture(0, "$heightmap")
	radarTruthShader:Activate()
	
	radarTruthShader:SetUniform("radarcenter_range",
		drawX, drawY, drawZ, range
	)
	
	radarRangeShaders[range]:DrawElements(GL.TRIANGLES)
	radarTruthShader:Deactivate()
	gl.Texture(0, false)

	gl.DepthTest(true)
end

