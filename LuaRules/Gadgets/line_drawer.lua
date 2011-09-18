
function gadget:GetInfo()
  return {
    name      = "Line Drawer",
    desc      = "Draws lines",
    author    = "Google Frog",
    date      = "6 June 2011",
    license   = "GNU GPL, v2 or later",
    layer     = 0,
    enabled   = false  --  loaded by default?
  }
end

-------------------------------------------------------------------------------------
-------------------------------------------------------------------------------------

if (gadgetHandler:IsSyncedCode()) then

-------------------------------------------------------------------------------------
-------------------------------------------------------------------------------------

local lines = {count = 0, data = {}}

local function drawAxis(x,y,z,normal, radial, right,scale)

	scale = scale or 1000

	lines.count = lines.count + 1
	lines.data[lines.count] = {x+normal[1]*scale, y+normal[2]*scale, z+normal[3]*scale, x, y, z}
	lines.count = lines.count + 1
	lines.data[lines.count] = {x+radial[1]*scale, y+radial[2]*scale, z+radial[3]*scale, x, y, z}
	lines.count = lines.count + 1
	lines.data[lines.count] = {x+right[1]*scale, y+right[2]*scale, z+right[3]*scale, x, y, z}

end

GG.drawAxis = drawAxis

local function clearLines()
	lines = {count = 0, data = {}} 
end

GG.clearLines = clearLines

function gadget:Initialize()
	_G.linesToDraw = lines
end


-------------------------------------------------------------------------------------
-------------------------------------------------------------------------------------
 -- UNSYNCED
else

-------------------------------------------------------------------------------------
-------------------------------------------------------------------------------------

local function Line(line)
   gl.Vertex(line[1], line[2], line[3])
   gl.Vertex(line[4], line[5], line[6])
end

function gadget:DrawWorld()
	
	local lines = SYNCED.linesToDraw
	
	local i = 1
	while i <= lines.count do
		
		gl.LineWidth(3)
		
		gl.Color(1,0,0,1)
		gl.BeginEnd(GL.LINES, Line, lines.data[i])
		i = i + 1
		
		gl.Color(0,1,0,1)
		gl.BeginEnd(GL.LINES, Line, lines.data[i])
		i = i + 1
		
		gl.Color(0,0,1,1)
		gl.BeginEnd(GL.LINES, Line, lines.data[i])
		i = i + 1
	end
	
end

end