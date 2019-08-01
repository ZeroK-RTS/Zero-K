-------------------------------------------------------------------------------------
-------------------------------------------------------------------------------------

function widget:GetInfo()
  return {
    name      = "Unit Icons",
    desc      = "v0.033 Shows icons above units",
    author    = "CarRepairer and GoogleFrog",
    date      = "2012-01-28",
    license   = "GNU GPL, v2 or later",
    layer     = -10,--
    enabled   = true,  -- loaded by default?
  }
end

-------------------------------------------------------------------------------------
-------------------------------------------------------------------------------------

local echo = Spring.Echo

local spGetUnitDefID 	= Spring.GetUnitDefID
local spIsUnitInView 	= Spring.IsUnitInView
local spGetUnitViewPosition = Spring.GetUnitViewPosition
local spGetGameFrame 	= Spring.GetGameFrame

local glDepthTest      = gl.DepthTest
local glDepthMask      = gl.DepthMask
local glAlphaTest      = gl.AlphaTest
local glTexture        = gl.Texture
local glTexRect        = gl.TexRect
local glTranslate      = gl.Translate
local glBillboard      = gl.Billboard
local glDrawFuncAtUnit = gl.DrawFuncAtUnit
local glPushMatrix     = gl.PushMatrix
local glPopMatrix      = gl.PopMatrix

local GL_GREATER = GL.GREATER

local min   = math.min
local max   = math.max
local floor = math.floor
local abs 	= math.abs

local iconsize = 5
local forRadarIcons = true

----------------------------------------------------------------------------------------
----------------------------------------------------------------------------------------

options_path = 'Settings/Interface/Hovering Icons'
options = {
	iconsize = {
		name = 'Hovering Icon Size',
		type = 'number',
		value = 30, min=10, max = 40,
		OnChange = function(self)
			iconsize = self.value
		end
	},
	forRadarIcons = {
		name = 'Draw on Icons',
		desc = 'Draws state icons when zoomed out.',
		type = 'bool',
		value = true,
		noHotkey = true,
		OnChange = function(self)
			forRadarIcons = self.value
		end
	},		
}
options.iconsize.OnChange(options.iconsize)

----------------------------------------------------------------------------------------
----------------------------------------------------------------------------------------

local unitHeights  = {}
local iconOrders = {}
local iconOrders_order = {}

local iconoffset = 22


local iconUnitTexture = {}
--local textureUnitsXshift = {}
local textureData = {}

local textureIcons = {}
local textureOrdered = {}

local textureColors = {}

--local xshiftUnitTexture = {}

local hideIcons = {}
local pulseIcons = {}

local updateTime, iconFade = 0, 0

WG.icons = {}

-------------------------------------------------------------------------------------
-------------------------------------------------------------------------------------

local function OrderIcons()
	iconOrders_order = {}
	for iconName, _ in pairs(iconOrders) do
		iconOrders_order[#iconOrders_order+1] = iconName
	end
	table.sort(iconOrders_order, function(a,b)
		return iconOrders[ a ] < iconOrders[ b ]
	end)

end

local function OrderIconsOnUnit(unitID )
	local iconCount = 0
	for i=1, #iconOrders_order do
		local iconName = iconOrders_order[i]
		if (not hideIcons[iconName]) and iconUnitTexture[iconName] and iconUnitTexture[iconName][unitID] then
			iconCount = iconCount + 1
		end
	end
	local xshift = (0.5 - iconCount*0.5)*iconsize
	
	for i=1, #iconOrders_order do
		local iconName = iconOrders_order[i]
		local texture = iconUnitTexture[iconName] and iconUnitTexture[iconName][unitID]
		if texture then
		
			if hideIcons[iconName] then
				--textureUnitsXshift[texture][unitID] = nil
				textureData[texture][iconName][unitID] = nil
			else
				--textureUnitsXshift[texture][unitID] = xshift
				textureData[texture][iconName][unitID] = xshift
				xshift = xshift + iconsize
			end
		end
		
	end
end

local function SetOrder(iconName, order)
	iconOrders[iconName] = order
	OrderIcons()
end


local function ReOrderIconsOnUnits()
	local units = Spring.GetAllUnits()
	for i=1,#units do
		OrderIconsOnUnit(units[i])
	end
end


function WG.icons.SetDisplay( iconName, show )
	local hide = (not show) or nil
	curHide = hideIcons[iconName]
	if curHide ~= hide then
		hideIcons[iconName] = hide
		ReOrderIconsOnUnits()
	end
end

function WG.icons.SetOrder( iconName, order )
	SetOrder(iconName, order)
end

function WG.icons.SetPulse( iconName, pulse )
	pulseIcons[iconName] = pulse
end


function WG.icons.SetUnitIcon(unitID, data)
	local iconName = data.name
	local texture = data.texture
	local color = data.color
	
	if not iconOrders[iconName] then
		SetOrder(iconName, math.huge)
	end

	
	local oldTexture = iconUnitTexture[iconName] and iconUnitTexture[iconName][unitID]
	if oldTexture then
		--textureUnitsXshift[oldTexture][unitID] = nil
		textureData[oldTexture][iconName][unitID] = nil
		
		iconUnitTexture[iconName][unitID] = nil
		if (not hideIcons[iconName])then
			OrderIconsOnUnit(unitID)
		end
	end
	if not texture then
		return
	end
	
	--[[
	if not textureUnitsXshift[texture] then
		textureUnitsXshift[texture] = {}
	end
	textureUnitsXshift[texture][unitID] = 0
	--]]
	
	--new
	if not textureData[texture] then
		textureData[texture] = {}
	end
	if not textureData[texture][iconName] then
		textureData[texture][iconName] = {}
	end
	textureData[texture][iconName][unitID] = 0

	if color then
		if not textureColors[unitID] then
			textureColors[unitID] = {}
		end
		textureColors[unitID][iconName] = color
	end

	if not iconUnitTexture[iconName] then
		iconUnitTexture[iconName] = {}
	end
	iconUnitTexture[iconName][unitID] = texture
	
	if not unitHeights[unitID] then
		local ud = UnitDefs[spGetUnitDefID(unitID)]
		if (ud == nil) then
			unitHeights[unitID] = nil
		else
			--unitHeights[unitID] = Spring.Utilities.GetUnitHeight(ud) + iconoffset
			unitHeights[unitID] = Spring.GetUnitHeight(unitID) + iconoffset
		end
	end

	OrderIconsOnUnit(unitID)
end

-------------------------------------------------------------------------------------
-------------------------------------------------------------------------------------

function widget:UnitDestroyed(unitID, unitDefID, unitTeam)
	unitHeights[unitID] = nil
	--xshiftUnitTexture[unitID] = nil
end

-------------------------------------------------------------------------------------
-------------------------------------------------------------------------------------

local function DrawFuncAtUnitIcon2(unitID, xshift, yshift)
	local x,y,z = spGetUnitViewPosition(unitID)
	glPushMatrix()
		glTranslate(x,y,z)
		glTranslate(0,yshift,0)
		glBillboard()
		glTexRect(xshift -iconsize*0.5, -5, xshift + iconsize*0.5, iconsize-5)
	glPopMatrix()
end

local function DrawUnitFunc(xshift, yshift)
	glTranslate(0,yshift,0)
	glBillboard()
	glTexRect(xshift - iconsize*0.5, -9, xshift + iconsize*0.5, iconsize-9)
end

local function DrawWorldFunc()
	if Spring.IsGUIHidden() then return end
	
	if (next(unitHeights) == nil) then
		return -- avoid unnecessary GL calls
	end
	
	
	local gameFrame = spGetGameFrame()
	
	
	gl.Color(1,1,1,1)
	glDepthMask(true)
	glDepthTest(true)
	glAlphaTest(GL_GREATER, 0.001)
	
	--for texture, units in pairs(textureUnitsXshift) do
	
	
	for texture, curTextureData in pairs(textureData) do
		for iconName, units in pairs(curTextureData) do
		
		
		glTexture(texture)
		for unitID,xshift in pairs(units) do
			local textureColor = textureColors[unitID] and textureColors[unitID][iconName]
			if textureColor then
				gl.Color( textureColor )
			elseif pulseIcons[iconName] then
				gl.Color( 1,1,1,iconFade )
			end
			
			local unitInView = spIsUnitInView(unitID)
			if unitInView and xshift and unitHeights and unitHeights[unitID] then
				if forRadarIcons then
					DrawFuncAtUnitIcon2(unitID, xshift, unitHeights[unitID])
				else
					glDrawFuncAtUnit(unitID, false, DrawUnitFunc,xshift,unitHeights[unitID])
				end
			end
			
			if textureColor or pulseIcons[iconName] then
				gl.Color(1,1,1,1)
			end
		end
		
	end
	
	--new
	end
	
	glTexture(false)
	
	glAlphaTest(false)
	glDepthTest(false)
	glDepthMask(false)
end

function widget:DrawWorld()
	DrawWorldFunc()
end

function widget:DrawWorldRefraction()
	DrawWorldFunc()
end

function widget:Update(dt)
	updateTime = (updateTime + dt)%2
	iconFade = min(abs(((updateTime*30) % 60) - 20) / 20, 1 )
end

-- drawscreen method
-- the problem with this one is it draws at same size regardless of how far away the unit is
--[[
function widget:DrawScreenEffects()
	if Spring.IsGUIHidden() then return end
	
	if (next(unitHeights) == nil) then
		return -- avoid unnecessary GL calls
	end
	
	gl.Color(1,1,1,1)
	glDepthMask(true)
	glDepthTest(true)
	glAlphaTest(GL_GREATER, 0.001)
	
	for texture, units in pairs(textureUnitsXshift) do
		glTexture( texture )
		for unitID,xshift in pairs(units) do
			gl.PushMatrix()
			local x,y,z = Spring.GetUnitPosition(unitID)
			y = y + (unitHeights[unitID] or 0)
			x,y,z = Spring.WorldToScreenCoords(x,y,z)
			glTranslate(x,y,z)
			if xshift and unitHeights then
				glTranslate(xshift,0,0)
				--glBillboard()
				glTexRect(-iconsize*0.5, -9, iconsize*0.5, iconsize-9)
			end
			gl.PopMatrix()
		end
	end
	
	glTexture(false)
	
	glAlphaTest(false)
	glDepthTest(false)
	glDepthMask(false)
end

]]

function widget:Initialize()
end

function widget:Shutdown()
	--for texture,_ in pairs(textureUnitsXshift) do
	for texture,_ in pairs(textureData) do
		gl.DeleteTexture(texture)
	end
end

-------------------------------------------------------------------------------------
-------------------------------------------------------------------------------------

