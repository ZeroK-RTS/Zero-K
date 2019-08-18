--------------------------------------------------------------------------------
--------------------------------------------------------------------------------

function widget:GetInfo()
	return {
		name      = "Draw Mouse Build",
		desc      = "Draws build icons at the mouse position.",
		author    = "GoogleFrog, xponen",
		date      = "10 Novemember 2016",
		license   = "GNU GPL, v2 or later",
		layer     = 0,
		enabled   = true,
		handler   = true,

		api         = true,
		alwaysStart = true,
	}
end

--------------------------------------------------------------------------------
--------------------------------------------------------------------------------
-- Local Variables

local unitDefID
local size
local count
local badX, badY, badRight, badBottom
local screenHeight

--------------------------------------------------------------------------------
--------------------------------------------------------------------------------
-- Draw Icon

local function DrawMouseIcon()
	if unitDefID then
		local mx,my,lmb = Spring.GetMouseState()
		if not lmb then
			return
		end
		
		if mx > badX and mx < badRight and my > badY and my < badBottom then
			return
		end
		
		gl.Color(1,1,1,0.5)
		gl.Texture(WG.GetBuildIconFrame(UnitDefs[unitDefID])) --draw build icon on screen. Copied from gui_chili_gesture_menu.lua
		gl.TexRect(mx-size, my-size, mx+size, my+size)
		gl.Texture("#"..unitDefID)
		gl.TexRect(mx-size, my-size, mx+size, my+size)
		gl.Texture(false)
		gl.Color(1,1,1,1)
		if count > 1 then
			gl.Text(count+1,mx-size*0.82, my+size*0.45,14,"")
		end
	end
end
--------------------------------------------------------------------------------
--------------------------------------------------------------------------------
-- External Functions

local externalFunctions = {}

function externalFunctions.SetMouseIcon(newUnitDefID, newSize, newCount, bX, bY, bWidth, bHeight)
	unitDefID = newUnitDefID
	size = newSize
	count = newCount
	badX, badY, badRight, badBottom = bX, bY, bX + bWidth, bY + bHeight
	badY, badBottom = screenHeight - badBottom, screenHeight - badY
	widgetHandler:UpdateWidgetCallIn("DrawScreen", widget)
end

function externalFunctions.ClearMouseIcon()
	unitDefID = nil
	widgetHandler:RemoveWidgetCallIn("DrawScreen", widget)
end

--------------------------------------------------------------------------------
--------------------------------------------------------------------------------
-- Widget Interface

function widget:ViewResize(viewSizeX, viewSizeY)
	screenHeight = viewSizeY
end

function widget:DrawScreen()
	DrawMouseIcon()
end

function widget:Initialize()
	screenHeight = select(2, Spring.GetWindowGeometry())
	WG.DrawMouseBuild = externalFunctions
	widgetHandler:RemoveWidgetCallIn("DrawScreen", widget)
end
