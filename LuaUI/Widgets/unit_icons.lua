-------------------------------------------------------------------------------------
-------------------------------------------------------------------------------------

function widget:GetInfo()
  return {
    name      = "Unit Icons",
    desc      = "v0.02 Shows icons above units",
    author    = "CarRepairer and GoogleFrog",
    date      = "2012-01-28, Oct 31",
    license   = "GNU GPL, v2 or later",
    layer     = 4,--
    enabled   = true,  -- loaded by default?
  }
end

-------------------------------------------------------------------------------------
-------------------------------------------------------------------------------------

local echo = Spring.Echo

local GetUnitDefID         = Spring.GetUnitDefID
local GetUnitDefDimensions = Spring.GetUnitDefDimensions

local glDepthTest      = gl.DepthTest
local glDepthMask      = gl.DepthMask
local glAlphaTest      = gl.AlphaTest
local glTexture        = gl.Texture
local glTexRect        = gl.TexRect
local glTranslate      = gl.Translate
local glBillboard      = gl.Billboard
local glDrawFuncAtUnit = gl.DrawFuncAtUnit

local GL_GREATER = GL.GREATER

local min   = math.min
local floor = math.floor
local osClock = os.clock
----------------------------------------------------------------------------------------
----------------------------------------------------------------------------------------

options_path = 'Settings/Interface/Hovering Icons'
options = {
	iconsize = {
		name = 'Hovering Icon Size',
		type = 'number',
		value = 30, min=10, max = 40,
	}
}

----------------------------------------------------------------------------------------
----------------------------------------------------------------------------------------

local unitHeights  = {}
local iconOrders = {}
local iconOrders_order = {}

local iconoffset = 14


local iconUnitTexture = {}
local textureUnitsXshift = {}

local textureIcons = {}
local textureOrdered = {}

--local xshiftUnitTexture = {}

local hideIcons = {}


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
	local xshift = (0.5 - iconCount*0.5)*options.iconsize.value
	
	for i=1, #iconOrders_order do
		local iconName = iconOrders_order[i]
		local texture = iconUnitTexture[iconName] and iconUnitTexture[iconName][unitID]
		if texture then
		
			if hideIcons[iconName] then
				textureUnitsXshift[texture][unitID] = false
			else
				textureUnitsXshift[texture][unitID] = xshift
				xshift = xshift + options.iconsize.value
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


local SetDisplay = function ( iconName, show )
	local hide = (not show) or nil
	curHide = hideIcons[iconName]
	if curHide ~= hide then
		hideIcons[iconName] = hide
		ReOrderIconsOnUnits()
	end
end

local SetOrder = function ( iconName, order )
	SetOrder(iconName, order)
end


local SetUnitIcon = function ( unitID, data )
	local iconName = data.name
	local texture = data.texture
	
	if not iconOrders[iconName] then
		SetOrder(iconName, math.huge)
	end

	
	local oldTexture = iconUnitTexture[iconName] and iconUnitTexture[iconName][unitID]
	if oldTexture then
		textureUnitsXshift[oldTexture][unitID] = nil
		iconUnitTexture[iconName][unitID] = nil
		if (not hideIcons[iconName])then
			OrderIconsOnUnit(unitID)
		end
	end
	if not texture then
		return
	end
	
	if not textureUnitsXshift[texture] then
		textureUnitsXshift[texture] = {}
	end
	textureUnitsXshift[texture][unitID] = 0


	if not iconUnitTexture[iconName] then
		iconUnitTexture[iconName] = {}
	end
	iconUnitTexture[iconName][unitID] = texture
	
	if not unitHeights[unitID] then
		local ud = UnitDefs[GetUnitDefID(unitID)]
		if (ud == nil) then
			unitHeights[unitID] = nil
		end
		unitHeights[unitID] = ud.height + iconoffset
	end

	OrderIconsOnUnit(unitID)
	
end

-------------------------------------------------------------------------------------
-------------------------------------------------------------------------------------



function widget:UnitCreated(unitID, unitDefID, unitTeam)
end


function widget:UnitDestroyed(unitID, unitDefID, unitTeam)
	unitHeights[unitID] = nil
	--xshiftUnitTexture[unitID] = nil
end


function widget:UnitGiven(unitID, unitDefID, oldTeam, newTeam)
end


-------------------------------------------------------------------------------------
-------------------------------------------------------------------------------------

local function DrawUnitFunc(xshift, yshift)
  glTranslate(xshift,yshift,0)
  glBillboard()
  glTexRect(-options.iconsize.value*0.5, -9, options.iconsize.value*0.5, options.iconsize.value-9)
end

-- [[
-- DrawWorld method
-- the problem with this one is that it do not follow camera rotation & do not draw during icon view.
function widget:DrawWorld()
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
			if xshift and unitHeights and unitHeights[unitID] then
				glDrawFuncAtUnit(unitID, false, DrawUnitFunc,
					xshift,
					unitHeights[unitID])
			end
		end
	end
	
	glTexture(false)
	
	glAlphaTest(false)
	glDepthTest(false)
	glDepthMask(false)
end
--]]

--[[
-- drawscreen method
-- Problem: draws at same size regardless of how far away the unit is, Pros: can show icon at unit icons (player can view unit state even when zoomed out)

-- Algorithm for Fixing icon size (only work for freestyle cam):
-- <<Code for scaling at different FOV settings>>
-- camFOV = Spring.GetCameraFOV()
-- fovScaleUp = 45/camFOV --at higher FOV (>45 degree) stuff usually look smaller, so we will enlarge them to maintain consistent view. 45 degree is the default FOV

-- <<Code for scaling at different cam height (only true for freestyle camera since Spring.GetCameraState() return inconsistent value for different camera)>>
-- cs = Spring.GetCameraState()
-- x,y,z = Spring.GetUnitPosition(unitID) --get unit position
-- y = y + (unitHeights[unitID] or 0) --get unit height
-- camDist = math.sqrt((cs.py-y)^2 + (cs.px-x)^2 + (cs.pz-z)^2) --calculate camera distance
-- howMuchToScale = (1425/camDist) * fovScaleUp --scale-up/scale-down the icon: using ratio between camera-distance & the reference distance (ie: 1425). We get 1425 from trial-n-error. We observe the icon when turn-off scaling at multiple distance and found out the appropriate relative size.
-- horizontalShift = xshift* howMuchScaleUp
-- glTranslate(x,y,z)
-- glTranslate(horizontalShift,0,0)
-- gl.Scale (howMuchScaleUp,howMuchScaleUp,howMuchScaleUp )
-- glTexRect(-options.iconsize.value*0.5, -9, options.iconsize.value*0.5, options.iconsize.value-9)
-- gl.Scale (1,1,1)
-- <<end>>

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
			x,y,z = Spring.GetUnitPosition(unitID) --get unit position
			if y == nil then --unit disappear!
				textureUnitsXshift[texture][unitID]=nil --clear it from memory
			end
			y = y + (unitHeights[unitID] or 0) --get unit height
			
			gl.PushMatrix()
			x,y,z = Spring.WorldToScreenCoords(x,y,z) --convert unit position into screen coordinate
			glTranslate(x,y,z)
			if xshift and unitHeights then
				local horizontalShift = xshift* howMuchScaleUp
				glTranslate(horizontalShift,0,0)
				--glBillboard()
				gl.Scale (howMuchScaleUp,howMuchScaleUp,howMuchScaleUp )
				glTexRect(-options.iconsize.value*0.5, -9, options.iconsize.value*0.5, options.iconsize.value-9)
				gl.Scale (1,1,1)
			end
			gl.PopMatrix()
		end
	end
	
	glTexture(false)
	
	glAlphaTest(false)
	glDepthTest(false)
	glDepthMask(false)
end

--]]

function widget:Initialize()
	WG.icons.SetDisplay = SetDisplay --initialize WG.icons
	WG.icons.SetOrder =  SetOrder
	WG.icons.SetUnitIcon = SetUnitIcon
end

function widget:Shutdown()
	for texture,_ in pairs(textureUnitsXshift) do
		gl.DeleteTexture(texture)
	end
	WG.icons={} --empty WG.icons
end

-------------------------------------------------------------------------------------
-------------------------------------------------------------------------------------
