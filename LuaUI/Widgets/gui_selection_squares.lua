function widget:GetInfo()
  return {
    name      = "Selection Squares",
    desc      = "Shows a green box that follows a unit's rotation around the selected unit(s)",
    author    = "Pressure Line - modified from trepan's TeamPlatters.lua",
    date      = "2007, 2010",
    license   = "GNU GPL, v2 or later",
    layer     = 5,
    enabled   = false  --  loaded by default?
  }
end

--------------------------------------------------------------------------------
--------------------------------------------------------------------------------

local function SetupCommandColors(state)
  local alpha = state and 1 or 0
  local f = io.open('cmdcolors.tmp', 'w+')
  if (f) then
    f:write('unitBox  0 1 0 ' .. alpha)
    f:close()
    Spring.SendCommands({'cmdcolors cmdcolors.tmp'})
  end
  os.remove('cmdcolors.tmp')
end

--------------------------------------------------------------------------------
--------------------------------------------------------------------------------

function widget:Initialize()
	squareLines = gl.CreateList(function()
		gl.BeginEnd(GL.LINE_LOOP, function()
		for i = 1, 1 do
			gl.Vertex(1, 2, 1)
			gl.Vertex(-1, 2, 1)
			gl.Vertex(-1, 2, -1)
			gl.Vertex(1, 2, -1)
		end
	end)
end)

  SetupCommandColors(false)
end


function widget:Shutdown()
  gl.DeleteList(squareLines)

  SetupCommandColors(true)
end

--------------------------------------------------------------------------------
--------------------------------------------------------------------------------

function widget:DrawWorldPreUnit()
	gl.LineWidth(1.0)
  gl.Color(0, 1, 0)
  -- special function from ca's LuaUI Cache - no need to speed up
  local visibleUnitsRev = Spring.GetVisibleUnitsReverse(Spring.ALL_UNITS, nil, false)
	for _,unitID in ipairs(Spring.GetSelectedUnits()) do
		if (visibleUnitsRev[unitID]) then
			local udid = Spring.GetUnitDefID(unitID)
			local scalex = 4.0 * UnitDefs[udid]["xsize"]
			local scalez = 4.0 * UnitDefs[udid]["zsize"]
			local heading = Spring.GetUnitHeading(unitID)
			local dirx, diry, dirz = Spring.GetUnitDirection(unitID)
			local heading = Spring.GetHeadingFromVector(dirx, dirz)
			local degrot = math.acos(dirz) * 180 / math.pi
			gl.DrawListAtUnit(unitID, squareLines, false, scalex, 1.0, scalez, degrot, 0, heading, 0)				
		end
	end
end

