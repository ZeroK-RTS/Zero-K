-------------------------------------------------------------------------------------
-------------------------------------------------------------------------------------

function widget:GetInfo()
  return {
    name      = "Unit Icons",
    desc      = "v0.1 Shows icons above units. Configure at: Settings/Interface/Hovering Icons \n\nThe following widget use this service:\nState Icons\nGadget Icons\nRank Icons 2",
    author    = "CarRepairer and GoogleFrog",
    date      = "2012-01-28",
    license   = "GNU GPL, v2 or later",
    layer     = -10,
    enabled   = true,  -- loaded by default?
	handler   = true, --allow widget to use special widgetHandler's function
  }
end
--[[
Changelog:
msafwan			12 Dec 2012		:	initialize WG function at widget:initialize 
									clear WG function at widget:shutdown
									auto shutdown 'rank icon', 'state icon', and 'gadget icon' during widget:shutdown 
									make state icon viewable even when unit is drawn as icons
									make state icon follow camera rotation
GoogleFrog      13 Dec 2012     :   Remove auto shutdown
									
--]]
-------------------------------------------------------------------------------------
-------------------------------------------------------------------------------------
local GetUnitDefID			= Spring.GetUnitDefID
local GetUnitDefDimensions	= Spring.GetUnitDefDimensions
local spValidUnitID 		= Spring.ValidUnitID
local spGetUnitPosition 	= Spring.GetUnitPosition

local glDepthTest      = gl.DepthTest
local glDepthMask      = gl.DepthMask
local glAlphaTest      = gl.AlphaTest
local glTexture        = gl.Texture
local glTexRect        = gl.TexRect
local glTranslate      = gl.Translate
local glBillboard      = gl.Billboard
local glDrawFuncAtUnit = gl.DrawFuncAtUnit
local glDeleteList = gl.DeleteList
local glCreateList = gl.CreateList
local glCallList = gl.CallList

local GL_GREATER = GL.GREATER

local spDiffTimers = Spring.DiffTimers
local spGetTimer = Spring.GetTimer
local lastIconUpdate = spGetTimer()
local iconDrawInterval = 1/60 --60fps
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
--DRAW-------------------------------------------------------------------------------

local function DrawUnitFunc(xshift, yshift,unitID)
	local x,y,z = spGetUnitPosition(unitID)
	glTranslate(x,y,z)
	glTranslate(0,yshift,0)
		gl.PushMatrix()
		glBillboard()
		glTranslate(xshift,10,0)
		glTexRect(-options.iconsize.value*0.5, -9, options.iconsize.value*0.5, options.iconsize.value-9)
		glTranslate(-xshift,-10,0)
		gl.PopMatrix()
	glTranslate(0,-yshift,0)
	glTranslate(-x,-y,-z)
end

local function DrawIcon()
	gl.Color(1,1,1,1)
	glDepthMask(true)
	glDepthTest(true)
	glAlphaTest(GL_GREATER, 0.001)
	
	for texture, units in pairs(textureUnitsXshift) do
		
		glTexture( texture )
		for unitID,xshift in pairs(units) do
			local unitIsValid = spValidUnitID(unitID)
			if unitIsValid and xshift and unitHeights and unitHeights[unitID] then
				DrawUnitFunc(xshift,unitHeights[unitID],unitID)
			end
			if not unitIsValid then
				textureUnitsXshift[texture][unitID]=nil --clear it from memory
			end
		end
	end
	
	glTexture(false)
	
	glAlphaTest(false)
	glDepthTest(false)
	glDepthMask(false)
end

function widget:DrawWorld()
	if Spring.IsGUIHidden() then return end
	
	if (next(unitHeights) == nil) then
		return -- avoid unnecessary GL calls
	end
	
	if spDiffTimers(spGetTimer(),lastIconUpdate) >= iconDrawInterval then --update at 60fps only
		if iconGLlist then 
			glDeleteList(iconGLlist)
		end
		iconGLlist = glCreateList(DrawIcon)
		lastIconUpdate = spGetTimer()
	end
	if iconGLlist then 
		glCallList(iconGLlist)
	end
end
-------------------------------------------------------------------------------------
--INITIALIZE & SHUTDOWN---------------------------------------------------------------

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
