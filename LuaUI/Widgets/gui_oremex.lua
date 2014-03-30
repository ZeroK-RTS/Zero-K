--------------------------------------------------------------------------------
--------------------------------------------------------------------------------

local version = "1.0.5" -- you may find changelog in unit_oremex.lua gadget

function widget:GetInfo()
  return {
    name      = "Ore mexes!",
    desc      = "Enjoy some graphics. Version "..version,
    author    = "Tom Fyuri",
    date      = "Mar 2014",
    license   = "GPL v2 or later",
    layer     = 4,
    enabled   = true	-- now it comes with design!
  }
end

--------------------------------------------------------------------------------
--------------------------------------------------------------------------------

local spValidUnitID	= Spring.ValidUnitID
local spGetUnitDefID	= Spring.GetUnitDefID
-- local spGetUnitRulesParam = Spring.GetUnitRulesParam
local spGetUnitViewPosition = Spring.GetUnitViewPosition
local spGetUnitTooltip	= Spring.GetUnitTooltip

local glDepthTest	= gl.DepthTest
local glColor		= gl.Color
local glRotate		= gl.Rotate
local glTranslate	= gl.Translate
local glPopMatrix	= gl.PopMatrix
local glPushMatrix	= gl.PushMatrix
local glAlphaTest	= gl.AlphaTest
local glTexture		= gl.Texture
local glTexRect		= gl.TexRect
local glBillboard	= gl.Billboard
local glText		= gl.Text
local GL_GREATER	= GL.GREATER
local glUnitMultMatrix	= gl.UnitMultMatrix
local glDrawFuncAtUnit  = gl.DrawFuncAtUnit

local modOptions = Spring.GetModOptions()

local iconsize	= 32
local iconhsize	= iconsize * 0.5

local OreExtractors = {}
local Rotation = 0

local mexDefs = {
  [UnitDefNames["cormex"].id] = true,
}

local strformat = string.format
local overheadFont = "LuaUI/Fonts/FreeSansBold_16"

--------------------------------------------------------------------------------
--------------------------------------------------------------------------------

local function AddExtractor(unitID)
	OreExtractors[unitID] = {
		income = 0,
		label = false,
		x = 0,
		fade = 0,
	}
end

function widget:UnitFinished(unitID, unitDefID)
	if spValidUnitID(unitID) and unitDefID and (mexDefs[unitDefID]) and not(OreExtractors[unitID]) then
		AddExtractor(unitID)
	end	
end

function widget:UnitEnteredLos(unitID)
	local unitDefID = spGetUnitDefID(unitID)
	if (mexDefs[unitDefID]) and not(OreExtractors[unitID]) then
		AddExtractor(unitID)
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

-- TODO this should stop rotating if game is paused
function widget:Update(s)
	Rotation=Rotation+1
	if (Rotation > 360) then
		Rotation = 0
	end
end

local function DrawIncome(unitID, color, income, x, fade)
	glTranslate(0,UnitDefNames["cormex"].height,0)
	glBillboard()
	glColor(color[1], color[2], color[3], color[4])
	fontHandler.UseFont(overheadFont)
	fontHandler.DrawCentered("+"..strformat("%.2f", income).."$", 0, 0+x)
	glColor(1,1,1,1)
end

function widget:DrawWorld()
	if not Spring.IsGUIHidden() then
		if (oredmg) then
			glDepthTest(true)
			glAlphaTest(GL_GREATER, 0)
			for unitID,_ in pairs(OreExtractors) do
				local unitDefID = spGetUnitDefID(unitID)
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
			glColor(1,1,1,1)
			glTexture(false)
		else
			for unitID,data in pairs(OreExtractors) do
				if (data.label) then
					local fade = data.fade
					local color = {0.0, 1.0, 1.0-fade, 1.0-fade}
					glDrawFuncAtUnit(unitID, false, DrawIncome, unitID, color, data.income, data.x, fade)
				end
			end
			glColor(1, 1, 1, 1)
			glAlphaTest(false)
			glDepthTest(false)
		end
	end
end

local function ShowOreMexIncome(playerID, unitID, income)
	if (spValidUnitID(unitID)) then
		OreExtractors[unitID].income = income
		if (OreExtractors[unitID].income > 0) then
			OreExtractors[unitID].label = true
		end
	end
end

function widget:GameFrame(n)
	for unitID, _ in pairs(OreExtractors) do
		if (OreExtractors[unitID].label) then
			OreExtractors[unitID].x = OreExtractors[unitID].x + 0.5
			OreExtractors[unitID].fade = OreExtractors[unitID].fade + 0.02
			if (OreExtractors[unitID].fade >= 1.0) then
				OreExtractors[unitID].label = false
				OreExtractors[unitID].x = 0
				OreExtractors[unitID].fade = 0
			end
		end
	end
end

--------------------------------------------------------------------------------
--------------------------------------------------------------------------------

function widget:Initialize()
	local oremex = modOptions.oremex and (tonumber(modOptions.oremex) == 1) or false
	local oredmg = modOptions.oremex_harm and (tonumber(modOptions.oremex_harm) > 0) or 0
	
	if (oremex == false) then
		widgetHandler:RemoveWidget()
		return
	end
	
	local units = Spring.GetAllUnits()
	for i=1,#units do
		local unitID = units[i]
		local unitDefID = spGetUnitDefID(unitID)
		if spValidUnitID(unitID) and unitDefID and (mexDefs[unitDefID]) and not(OreExtractors[unitID]) then
			AddExtractor(unitID)
		end
	end
	
	widgetHandler:RegisterGlobal("oremexIncomeAdd", ShowOreMexIncome)
end

function widget:Shutdown()
	widgetHandler:DeregisterGlobal("oremexIncomeAdd", ShowOreMexIncome)
end

--------------------------------------------------------------------------------
--------------------------------------------------------------------------------