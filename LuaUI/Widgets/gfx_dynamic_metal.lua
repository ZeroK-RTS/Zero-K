function widget:GetInfo()
	return {
		name      = "Lua Metal Decals",
		desc      = "Draws a decal on each metal spot",
		author    = "Bluestone (based on the Lua Metal Spots widget by Cheesecan)",
		date      = "April 2014",
		license   = "GPL v3 or later",
		layer     = 5,
		enabled   = true  --  loaded by default?
	}
end

local MEX_TEXTURE  = "luaui/images/metal_spot.png"
local MEX_WIDTH    = 80
local MEX_HEIGHT   = 80
local displayList  = 0

local mexRotation = {}

function drawPatches()
	local mSpots = WG.metalSpots
	-- Switch to texture matrix mode
	gl.MatrixMode(GL.TEXTURE)
	   
	gl.PolygonOffset(-25, -2)
	gl.Culling(GL.BACK)
	gl.DepthTest(true)
	gl.Texture(MEX_TEXTURE)
	gl.Color(1, 1, 1, 0.85) -- fix color from other widgets
	for i = 1, #mSpots do
		mexRotation[i] = mexRotation[i] or math.random(0, 360)
		gl.PushMatrix()
		gl.Translate(0.5, 0.5, 0)
		gl.Rotate(mexRotation[i], 0, 0, 1)
		gl.DrawGroundQuad(mSpots[i].x - MEX_WIDTH/2, mSpots[i].z - MEX_HEIGHT/2, mSpots[i].x + MEX_WIDTH/2, mSpots[i].z + MEX_HEIGHT/2, false, -0.5, -0.5, 0.5, 0.5)
		gl.PopMatrix()
	end
	gl.Texture(false)
	gl.DepthTest(false)
	gl.Culling(false)
	gl.PolygonOffset(false)
	   
	-- Restore Modelview matrix
	gl.MatrixMode(GL.MODELVIEW)
end

function widget:DrawWorldPreUnit()
	local mode = Spring.GetMapDrawMode()
	if (mode ~= "height" and mode ~= "path") then
		gl.CallList(displayList)
	end
end

function widget:Initialize()
	if not (WG.metalSpots and Spring.GetGameRulesParam("mex_need_drawing")) then
		widgetHandler:RemoveWidget(self)
		return
	end
	displayList = gl.CreateList(drawPatches)
end

function widget:GameFrame(n)
	if n%15 == 0 then
		-- Update display to take terraform into account
		displayList = gl.CreateList(drawPatches)
	end
end

function widget:Shutdown()
	gl.DeleteList(displayList)
end
