--------------------------------------------------------------------------------
--------------------------------------------------------------------------------

function widget:GetInfo()
  return {
    name      = "Drawing Cursors",
    desc      = "v0.01 Shows drawing cursors and indicator.",
    author    = "CarRepairer",
    date      = "2011-02-12",
    license   = "GNU GPL, v2 or later",
    layer     = 1000,
    enabled   = true,
  }
end

include("keysym.h.lua")

--------------------------------------------------------------------------------
--------------------------------------------------------------------------------

local echo = Spring.Echo


local GL_LINES		= GL.LINES
local GL_GREATER	= GL.GREATER
local GL_POINTS		= GL.POINTS

local glColor		= gl.Color
--local glAlphaTest	= gl.AlphaTest
local glTexture 	= gl.Texture
local glTexRect 	= gl.TexRect

local tildepressed, drawing, erasing
local icon_size = 24

--------------------------------------------------------------------------------
--------------------------------------------------------------------------------


function widget:KeyPress(key, modifier, isRepeat)
	if key == KEYSYMS.BACKQUOTE then
		tildepressed = true
	end
end
function widget:KeyRelease(key)
	if key == KEYSYMS.BACKQUOTE then
		tildepressed = false
	end
end


function widget:DrawScreen()
	if not tildepressed then return end
	
	local x, y, lmb, mmb, rmb = Spring.GetMouseState()
	
	drawing = lmb
	erasing = rmb
	
	local filefound
	local icon_size2 = icon_size
	if drawing then
		filefound = glTexture(LUAUI_DIRNAME .. 'Images/drawingcursors/pencil.png')
	elseif erasing then
		filefound = glTexture(LUAUI_DIRNAME .. 'Images/drawingcursors/eraser.png')
	else
		icon_size2 = 100
		filefound = glTexture(LUAUI_DIRNAME .. 'Images/drawingcursors/drawing.png')
	end
	
	if filefound then
		--do teamcolor?
		--glColor(0,1,1,1) 
		
		--glAlphaTest(GL_GREATER, 0)
		if drawing or erasing then
			Spring.SetMouseCursor('none')
		end
		
		glTexRect(x, y-icon_size2, x+icon_size2, y)
		glTexture(false)

		--glColor(1,1,1,1)
		--glAlphaTest(false)		
	end
end


--------------------------------------------------------------------------------
