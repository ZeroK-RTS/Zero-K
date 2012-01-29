-------------------------------------------------------------------------------------
-------------------------------------------------------------------------------------

function widget:GetInfo()
  return {
    name      = "Unit Icons",
    desc      = "v0.01 Shows icons above units",
    author    = "CarRepairer",
    date      = "2012-01-28",
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

----------------------------------------------------------------------------------------
----------------------------------------------------------------------------------------

local unitHeights  = {}
local iconOrders = {}
local iconOrders_order = {}

local iconsize   = 33
local iconoffset = 14


local iconUnitTexture = {}
local textureUnitsXshift = {}

local textureIcons = {}
local textureOrdered = {}

local xshiftUnitTexture = {}

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
	local xshift = 0
	
	for _,iconName in ipairs(iconOrders_order) do
		
		local texture = iconUnitTexture[iconName] and iconUnitTexture[iconName][unitID]
		if texture then
		
			if hideIcons[iconName] then
				textureUnitsXshift[texture][unitID] = false
			else
				textureUnitsXshift[texture][unitID] = xshift
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
	for _,unitID in ipairs( Spring.GetAllUnits() ) do
		OrderIconsOnUnit(unitID)
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


function WG.icons.SetUnitIcon( unitID, data )

	local iconName = data.name
	local texture = data.texture
	
	if not iconOrders[iconName] then
		SetOrder(iconName, math.huge)
	end

	
	local oldTexture = iconUnitTexture[iconName] and iconUnitTexture[iconName][unitID]
	if oldTexture then
		textureUnitsXshift[oldTexture][unitID] = nil
		iconUnitTexture[iconName][unitID] = nil
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
	xshiftUnitTexture[unitID] = nil
	
end


function widget:UnitGiven(unitID, unitDefID, oldTeam, newTeam)
end


-------------------------------------------------------------------------------------
-------------------------------------------------------------------------------------

local function DrawUnitFunc(xshift, yshift)
  glTranslate(xshift,yshift,0)
  glBillboard()
  glTexRect(-iconsize+10.5, -9, 10.5, iconsize-9)
end


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
			if xshift then
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


function widget:Initialize()
end

function widget:Shutdown()
	for texture,_ in pairs(textureUnitsXshift) do
		gl.DeleteTexture(texture)
	end
end

-------------------------------------------------------------------------------------
-------------------------------------------------------------------------------------
