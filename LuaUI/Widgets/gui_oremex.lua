--------------------------------------------------------------------------------
--------------------------------------------------------------------------------

local version = "1.0.3" -- you may find changelog in unit_oremex.lua gadget

function widget:GetInfo()
  return {
    name      = "Ore mexes are hazardous!",
    desc      = "Shows hazard icon over ore extractors should they be hazardous. Version "..version,
    author    = "Tom Fyuri",
    date      = "Mar 2014",
    license   = "GPL v2 or later",
    layer     = 4,
    enabled   = true	-- now it comes with design!
  }
end

--------------------------------------------------------------------------------
--------------------------------------------------------------------------------

-- local glVertex		= gl.Vertex
local glDepthTest	= gl.DepthTest
local glColor		= gl.Color
-- local glBeginEnd	= gl.BeginEnd
-- local glLineWidth	= gl.LineWidth
-- local glDrawFuncAtUnit	= gl.DrawFuncAtUnit
local glRotate		= gl.Rotate
local glTranslate	= gl.Translate
-- local glBillboard	= gl.Billboard
local glPopMatrix		 = gl.PopMatrix
local glPushMatrix		= gl.PushMatrix
-- local glScale			 = gl.Scale
-- local glText			= gl.Text
local glAlphaTest		 = gl.AlphaTest
local glTexture		 = gl.Texture
local glTexRect		 = gl.TexRect
local GL_GREATER		= GL.GREATER
local glUnitMultMatrix	= gl.UnitMultMatrix
-- local glUnitPieceMultMatrix = gl.UnitPieceMultMatrix

local modOptions = Spring.GetModOptions()

local iconsize	 = 32
local iconhsize	= iconsize * 0.5

local OreExtractors = {}
local Rotation = 0

local mexDefs = {
  [UnitDefNames["cormex"].id] = true,
}

--------------------------------------------------------------------------------
--------------------------------------------------------------------------------

function widget:UnitFinished(unitID, unitDefID)
	if Spring.ValidUnitID(unitID) and unitDefID and (UmexDefs[unitDefID]) then
		OreExtractors[unitID] = true
	end	
end

function widget:UnitEnteredLos(unitID)
	local unitDefID = Spring.GetUnitDefID(unitID)
	if (mexDefs[unitDefID]) then
		OreExtractors[unitID] = true
	end	
end

function widget:UnitLeftLos(unitID)
	if (OreExtractors[unitID]) then
		OreExtractors[unitID] = nil
	end
end

function widget:UnitDestroyed(unitID)
	if (OreExtractors[unitID]) then
		OreExtractors[unitID] = nil
	end
end

function widget:Update(s)
	Rotation=Rotation+1
	if (Rotation > 360) then
		Rotation = 0
	end
end

function widget:DrawWorld()
	if not Spring.IsGUIHidden() then
		glDepthTest(true)
		glAlphaTest(GL_GREATER, 0)
		for unitID,_ in pairs(OreExtractors) do
			local unitDefID = Spring.GetUnitDefID(unitID)
			if (unitDefID) then
				glPushMatrix()
				glTexture('LuaUI/Images/hazard.png')
				glUnitMultMatrix(unitID)
				glTranslate(0, UnitDefs[unitDefID].height + 4, 0)
				glRotate(Rotation,0,1,0)
				glColor(1,1,1,1)
				glTexRect(-iconhsize, 0, iconhsize, iconsize)
				glPopMatrix()
			end
		end
		-- done
		glAlphaTest(false)
		glColor(1,1,1,1)
		glTexture(false)
		glDepthTest(false)
	end
end

--------------------------------------------------------------------------------
--------------------------------------------------------------------------------

function widget:Initialize()
	local oremex = (tonumber(modOptions.oremex) == 1)
	local oredmg = (tonumber(modOptions.oremex_harm))
	
	if (oremex == false) or ((modOptions.oremex_harm ~= nil) and (oredmg == 0)) then
		widgetHandler:RemoveWidget()
		return
	end
	
	local units = Spring.GetAllUnits()
	for i=1,#units do
		local unitID = units[i]
		local unitDefID = Spring.GetUnitDefID(unitID)
		if Spring.ValidUnitID(unitID) and unitDefID and (mexDefs[unitDefID]) then
			OreExtractors[unitID] = true
		end
	end
end

--------------------------------------------------------------------------------
--------------------------------------------------------------------------------