-------------------------------------------------------------------------------------
-------------------------------------------------------------------------------------

function widget:GetInfo()
  return {
    name      = "Unit Icons",
    desc      = "v0.2 Shows icons above units. Configure at: Settings/Interface/Hovering Icons \n\nThe following widget use this service:\nState Icons\nGadget Icons\nRank Icons 2",
    author    = "CarRepairer,GoogleFrog,Xponen",
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
GoogleFrog      13 Dec 2012     :   Remove auto shutdown. Visible from far away option is default OFF. Remove FPS limit
msafwan(xponen)	14 Dec 2012    	:   Visible from far away option is default ON (this is a good feature!).
									Add echo when widget shutdown.
									Increase draw performance by ~20% by wraping both glTexture & glTexRect into display list & only update when camera rotate									
xponen			20 Dec 2012    	:   Increase efficiency by checking/updating unit-position,visibility and draw-list in widget:GameFrame() at only 30fps while drawing is done saperately at widget:DrawWorld()
									add some comment for readability
--]]
-------------------------------------------------------------------------------------
-------------------------------------------------------------------------------------
local GetUnitDefID			= Spring.GetUnitDefID
local GetUnitDefDimensions	= Spring.GetUnitDefDimensions
local spValidUnitID 		= Spring.ValidUnitID
local spGetUnitPosition 	= Spring.GetUnitPosition
local spIsUnitInView 		= Spring.IsUnitInView
local spIsUnitIcon          = Spring.IsUnitIcon

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

local spGetCameraVectors  = Spring.GetCameraVectors 
----------------------------------------------------------------------------------------
----------------------------------------------------------------------------------------

options_path = 'Settings/Interface/Hovering Icons'
options = {
	iconsize = {
		name = 'Hovering Icon Size',
		type = 'number',
		value = 30, min=10, max = 40,
	},
	forRadarIcons = {
		name = 'Draw on Icons',
		desc = 'Draws state icons on units which are icons.',
		type = 'bool',
		value = true,
	},	
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

local textureGLlist = {} --store gl list index for each texture. storing scheme: textureGLlist[textureName]=glListNumber
local iconGLlist = {} --store gl list index for each icon. storing scheme:iconGLlist[textureName][xshift][height] = glListNumber
local listToDraw = {}

local screenUpdate = false

local previousCameraVector = {} -- check camera vector which will be responsible for triggering icon update
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
				textureUnitsXshift[texture][unitID] = false --set to false: we are not drawing, but we wanted to update our display list table for this unitID
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

function widget:UnitDestroyed(unitID, unitDefID, unitTeam)
	unitHeights[unitID] = nil
	--xshiftUnitTexture[unitID] = nil
end

-------------------------------------------------------------------------------------
--DRAW + display list system----------------------------------------------------------
local function DrawUnitFunc(xshift, yshift)
	glTranslate(0,yshift,0) --translate icon to above unit's head
	glBillboard() --activate the billboard mode
	glTranslate(xshift,10,0)  --translate icon up or down on the billboard
	glTexRect(-options.iconsize.value*0.5, -9, options.iconsize.value*0.5, options.iconsize.value-9) --draw icon
	gl.PopMatrix() --restore previous coordinate/state
end

function widget:GameFrame(n) --iterate over texture & unit table, check camera vector, check unit visibility, and update display list if necessary. Max at 30fps 
	if screenUpdate then --halt updates if widget:DrawWorld() is not ready
		screenUpdate = false
		for i=1, #listToDraw do --empty listToDraw completely so that we get proper table lenght.
			listToDraw[i] = nil
		end
		
		local forward = spGetCameraVectors().forward
		local forceUpdateNow = previousCameraVector[1] ~= forward[1] or previousCameraVector[2] ~= forward[2] or previousCameraVector[3] ~= forward[3] --check if camera angle show difference
		previousCameraVector = forward
		
		for texture, units in pairs(textureUnitsXshift) do --iterate over a list of textures
			if texture and not textureGLlist[texture] then --check if we have displaylist for testure
				textureGLlist[texture] = glCreateList(function() --save this texture in graphic memory. Reference: http://fly.cc.fer.hr/~unreal/theredbook/appendixh.html , OpenGl Performance Tips
						glTexture(":l:"..texture) --load texture with linear texture filtering 
					end)
				-- local success = gl.DeleteTexture(texture) --delete texture. You can delete texture after its stored in graphic memory.
				-- Spring.Echo(success)					
			end
			for unitID,xshift in pairs(units) do --iterate over a list of texture position
				local unitIsValid = spValidUnitID(unitID)
				local iconHeight = unitHeights[unitID]
				if iconHeight then  --check if unit is valid
					local unitInView = spIsUnitInView(unitID)
					local showOnIcon =(options.forRadarIcons.value or not spIsUnitIcon(unitID))
					do
						iconGLlist[texture] = iconGLlist[texture] or {}
						iconGLlist[texture][iconHeight] = iconGLlist[texture][iconHeight] or {} --initialize table that store display list for matrix operation
						local state = iconGLlist[texture][iconHeight].update or 0
						iconGLlist[texture][iconHeight].update = (forceUpdateNow and 1) or state --the "update display list" flag. Is set to 1 if camera vector had change at least once.
					end
					if showOnIcon and unitInView and xshift then --check for valid texture position
						local drawiconGLlist = iconGLlist[texture][iconHeight][xshift]
						local state = iconGLlist[texture][iconHeight].update
						local x,y,z = spGetUnitPosition(unitID)
						if not drawiconGLlist or state>0 then --recreate display list if "update display list" is needed OR if display list wasn't found
							if drawiconGLlist then
								glDeleteList(drawiconGLlist)
							end
							--Spring.Echo("UPDATED")
							drawiconGLlist = glCreateList(DrawUnitFunc, xshift,iconHeight)
							iconGLlist[texture][iconHeight][xshift] = drawiconGLlist
							iconGLlist[texture][iconHeight].update = 0 --resets "update display list" flag
						end
						local nextEntry = #listToDraw+1
						listToDraw[nextEntry] = {} --store display list indexes in table for later drawing
						listToDraw[nextEntry][1] = textureGLlist[texture]
						listToDraw[nextEntry][2] = x
						listToDraw[nextEntry][3] = y
						listToDraw[nextEntry][4] = z
						listToDraw[nextEntry][5] = drawiconGLlist
					end
				end
				if not unitIsValid then
					textureUnitsXshift[texture][unitID]=nil --clear it from memory
				end
			end
		end
	end
end

local function DrawIcon2() --draw and draw stuff only
	gl.PushAttrib(GL.ALL_ATTRIB_BITS) --memorize existing gl attributes (ie:glDepthMask, glDepthTest ,ect). Reference: http://www.opengl.org/sdk/docs/man2/xhtml/glPushAttrib.xml
		gl.Color(1,1,1,1)
		glDepthMask(true)
		glDepthTest(true)
		glAlphaTest(GL_GREATER, 0.001)
		
		local prevTex = nil
		for i=1, #listToDraw do
			if listToDraw[i][1]~=prevTex then --check if this is same texture as before. To reduce redundant glTexture call
				glCallList(listToDraw[i][1]) --load texture
				prevTex = listToDraw[i][1]
			end
			gl.PushMatrix() --memorize current coordinate/state
			glTranslate(listToDraw[i][2],listToDraw[i][3],listToDraw[i][4]) --move icon on to unit's position
			glCallList(listToDraw[i][5]) --draw icon on unit's head
		end

		glTexture(false)
	gl.PopAttrib() --restore gl attributes
end

function widget:DrawWorld()
	if Spring.IsGUIHidden() then 
		return 
	end
	
	-- if (next(unitHeights) == nil) then
		-- return -- avoid unnecessary GL calls
	-- end
	screenUpdate = true
	DrawIcon2()
end

--[[ old method:
local function DrawUnitFunc(xshift, yshift)
  glTranslate(xshift,yshift,0)
  glBillboard()
  glTexRect(-options.iconsize.value*0.5, -9, options.iconsize.value*0.5, options.iconsize.value-9)
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
-------------------------------------------------------------------------------------
--INITIALIZE & SHUTDOWN---------------------------------------------------------------

function widget:Initialize()
	WG.icons = {}
	WG.icons.SetDisplay = SetDisplay --load SetDisplay, SetOrder & SetUnitIcon into WG table only after unit_icon.lua has fully initialized.
	WG.icons.SetOrder =  SetOrder
	WG.icons.SetUnitIcon = SetUnitIcon
end

function widget:Shutdown()
	for texture,_ in pairs(textureUnitsXshift) do
		local success = gl.DeleteTexture(texture)
		if success then
			Spring.Echo("Cached texture:" .. texture .. " Deleted") -- hint player that missing texture icon in Integral Menu is related to this widget.
		end
	end
	for _, glList in pairs(textureGLlist) do
		glDeleteList(glList)
	end
	for _, iconHeight in pairs(iconGLlist) do
		for _, xshift in pairs(iconHeight) do
			for _,glList in pairs(xshift) do
				glDeleteList(glList)
			end
		end
	end
	Spring.Echo("unit_icons.lua is shutting down. Terminating Icon service") --hint players that any widget that crash OR failed to show icon later is related to this widget.
	WG.icons=nil --empty WG.icons
end

-------------------------------------------------------------------------------------
-------------------------------------------------------------------------------------
