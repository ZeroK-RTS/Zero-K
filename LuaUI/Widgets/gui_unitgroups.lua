function widget:GetInfo()
  return {
    name      = "UnitGroups",
    desc      = "v5.1 Unit Group Icons, fixed bug",
    author    = "gunblob, original by tinnun",
    date      = "Aug 8, 2007",
    license   = "GNU GPL, v2 or later",
    layer     = 0,
    enabled   = false  --  loaded by default?
  }
end

-------------------------------------------------------------------------------
-------------------------------------------------------------------------------
include("colors.h.lua")

-------------------------------------------------------------------------------
local vsx, vsy = widgetHandler:GetViewSizes()

local updated = true
local updatedGroups = {}

local nLastClick = 0
local nLastIcon = -1

local unitGroups = {}
--[[ each element contains:
-totalMaxHealth 			total maxHealth of all units in group
-totalHealth 					total of health of all units in group
-numUnits 					number of units in the group
-unitTable						table of unitids of units in the group
-primaryUnitTypeId		the unit time that has the largest number of units in the group
-lastHealthDrop				game time when group last lost health (used to calc when group is under attack)
-iconId							the icon used to display this group (needed for when iconsShrink==true)
--]]

local alignment="right"	-- can be either "right" for the right hand side of the screen, or "bottom" for the bottom of the screen

local nRows = 4
local nColumns = 2
local sAlign = "lc" -- left centre

local nLastGroupChecked = 1

local activePress = false
local mouseIcon = -1

local iconsAlwaysOn = false
local iconsShrink = false
local iconCount = 0		-- number of visible icons.  required for when iconsShrink==true.  includes icons that do not have a group assigned, but are currently sliding off screen.
local iconWindows = {}
--[[ array of
groupId
windowHidden
--]]

local selectedGroupId = nil
local slideMode = false	-- used to indicate that the box is moved by the user
local slideOffset={
	right = -1,
	bottom = -1,
}
local slideOffsetChanged={}	-- this table holds two booleans, "right" and "bottom".  if false, then the player has not changed the offset in that direction so
-- we just use the screen resolution.  If true, we ignore the screen resolution.
local oldMouseX = 0
local oldMouseY = 0

--local iconSizeX = math.floor(80)
local iconSizeX = math.floor(100)
local iconSizeY = math.floor(50)

local iconDefaultWidth = {
	right = 130,
	bottom = 60,
}
local iconDefaultHeight = {
	right = 40,
	bottom = 72,
}

local alpha = 0.8
local bgIcexuickGrey = {0.22, 0.22, 0.22, alpha}
local boIcexuickGrey = {0, 0, 0, alpha}


local rectMinX = 0
local rectMaxX = 0
local rectMinY = 0
local rectMaxY = 0

-------------------------------------------------------------------------------
function widget:ViewResize(viewSizeX, viewSizeY)
  vsx = viewSizeX
  vsy = viewSizeY
  if not slideOffsetChanged.bottom then
    slideOffset.bottom = vsx/2 - iconSizeX * iconCount / 2
  end
  if not slideOffsetChanged.right then
    slideOffset.right = vsy/2 - iconSizeY * iconCount / 2
  end
end
-------------------------------------------------------------------------------

function widget:GetConfigData(data)
	return {
	  alignment = alignment,
	  iconsShrink = iconsShrink,
	  iconsAlwaysOn = iconsAlwaysOn,
	  iconDefaultWidthRight = iconDefaultWidth.right,
	  iconDefaultHeightRight = iconDefaultHeight.right,
	  iconDefaultWidthBottom = iconDefaultWidth.bottom,
	  iconDefaultHeightBottom = iconDefaultHeight.bottom,
	  slideOffsetRight = slideOffset.right,
	  slideOffsetBottom = slideOffset.bottom,
	}
end

function widget:SetConfigData(data)
	alignment = data.alignment or "right"
	iconsShrink = data.iconsShrink or false
	iconsAlwaysOn = data.iconsAlwaysOn or false
	iconDefaultWidth.right = data.iconDefaultWidthRight or 130
	iconDefaultHeight.right = data.iconDefaultHeightRight or 40
	iconDefaultWidth.bottom = data.iconDefaultWidthBottom or 60
	iconDefaultHeight.bottom = data.iconDefaultHeightBottom or 72
	slideOffset.right = data.slideOffsetRight or -1
	slideOffset.bottom = data.slideOffsetBottom or -1
end

function widget:Initialize()
	local _, _, spec, team = Spring.GetPlayerInfo(Spring.GetMyPlayerID(), false)
	if spec then
		widgetHandler:RemoveWidget()
		return false
	end
  local groupId
  local icon

  iconSizeX = iconDefaultWidth[alignment]
  iconSizeY = iconDefaultHeight[alignment]

  if slideOffset.right ~= -1 then
    slideOffsetChanged.right = true
  else
    slideOffset.right = vsy/2 - iconSizeY * iconCount / 2
  end

  if slideOffset.bottom ~= -1 then
    slideOffsetChanged.bottom = true
  else
    slideOffset.bottom = vsx/2 - iconSizeX * iconCount / 2
  end

  -- loop through icons
  for icon = 1, 10 do
    iconWindows[icon] = {}
    iconWindows[icon].windowHidden = 0
  end

  updated = true
  for groupId = 1, 10 do
    updatedGroups[groupId] = true

    unitGroups[groupId] = {}
    unitGroups[groupId].totalHealth = 0
    unitGroups[groupId].numUnits = 0
  end

end

function widget:Shutdown()

end

function widget:GroupChanged(groupId)
  --Spring.Echo("GroupChanged " .. groupId)
  groupId = GetNumFromGroupId(groupId)
  if groupId <= 10 and groupId >=1 then
    updated = true
    updatedGroups[groupId] = true
  end

  -- now we re-calc the groupToIconMapping and iconToGroupMapping tables
end

function RecalcMappings()
  local iCounter
  local icon = 1
  for groupId = 1, 10 do
    if iconsShrink == false or unitGroups[groupId].numUnits ~= 0 then
      unitGroups[groupId].iconId = icon
      iconWindows[icon].groupId = groupId
      --~ 			iconToGroupMapping[icon] = groupId
      icon = icon + 1
    else
      unitGroups[groupId].iconId = nil
    end
  end
  iconCount = icon

  -- now loop through any remaining icons (this will only happen if iconsShrink == true)
  local tMax = iconCount
  for icon = tMax, 10 do
    iconWindows[icon].groupId = nil
    if iconWindows[icon].windowHidden ~= 1 then
      iconCount = iconCount + 1
    end
  end
  iconCount = iconCount + 1 -- add 1 to allow for the control icon group
end

--~ [[
--~ 	UpdateOneGroupsDetails()
--~ 	Called by Initialize() and GroupChanged() as it only needs to be done whenever a group is changed (or the script just started)
--~ ]]
function UpdateOneGroupsDetails(groupId)
  local nMaxUnitTypeId = -1
  local nMaxUnitTypeNumber = 0
  local tGroupNumbers = {}
  local unitTypeNumber = {}

  unitGroups[groupId].unitTable = Spring.GetGroupUnits(GetGroupIdFromNum((groupId)))
  unitGroups[groupId].numUnits  =  0 -- we'll calculate this below.

  --~ 	-- Work out which unittype has the biggest presence in this group and then use it as the icon for the group
  --~ 	tGroupNumbers = Spring.GetGroupUnitsSorted(groupId)
  --~ 	for unitTypeId, unitTypeNumber in pairs(tGroupNumbers) do
  --~ 		if getn(r) > nMaxUnitTypeNumber then
  --~ 			nMaxUnitTypeNumber = unitTypeNumber
  --~ 			nMaxUnitTypeId = unitTypeId
  --~ 		end
  --~ 		unitGroups[groupId].numUnits  = unitGroups[groupId].numUnits  + unitTypeNumber
  --~ 	end
  unitGroups[groupId].numUnits, nMaxUnitTypeId = GetGroupsUnitNumbers(groupId)

  unitGroups[groupId].lastHealthDrop = -10
  unitGroups[groupId].primaryUnitTypeId = nMaxUnitTypeId
  unitGroups[groupId].totalHealth = 0
  CheckOneGroupsHealth(groupId)
end


function GetGroupsUnitNumbers(groupId)
  local nMostCommonUnitId = 0
  local nUnitNumber = 0
  local nIndex
  local nUnitId
  local nUnitDefId
  local tUnitIdCounts = {}
  local maxDefId = nil
  local maxDefCount = 0

  --~     if unitGroups[groupId].unitTable == nil

  for nIndex, nUnitId in ipairs(unitGroups[groupId].unitTable) do
    nUnitDefId = Spring.GetUnitDefID(nUnitId)
    if tUnitIdCounts[nUnitDefId] ~= nil then
      tUnitIdCounts[nUnitDefId] = tUnitIdCounts[nUnitDefId] + 1
    else
      tUnitIdCounts[nUnitDefId] = 1
    end
    if tUnitIdCounts[nUnitDefId] > maxDefCount then
      maxDefCount = tUnitIdCounts[nUnitDefId]
      maxDefId = nUnitDefId
    end
    nUnitNumber = nUnitNumber + 1
  end

  --~     return tUnitIdCounts[nUnitDefId], nUnitDefId
  return nUnitNumber, maxDefId
end


function CheckOneGroupsHealth(groupId)
  local tGroup = unitGroups[groupId]
  local nMaxHealth = 0
  local nHealth = 0
  local maxHealth
  local health
  local paralyzeDamage
  local captureProgress
  local buildProgress
  local nUnitId = 0
  local tUnitDetails = {}
  local nIndex
  local count = 0

  for nIndex, nUnitId in ipairs(tGroup.unitTable) do
    health, maxHealth, paralyzeDamage, captureProgress, buildProgress = Spring.GetUnitHealth(nUnitId)
    if (health) then
      nMaxHealth = nMaxHealth + maxHealth
      nHealth = nHealth + health
      count = count + 1
    end
  end
  tGroup.totalMaxHealth = nMaxHealth
  tGroup.numUnits = count
  if nHealth < tGroup.totalHealth then
    -- someone in the group has taken damage since we last checked!
    tGroup.lastHealthDrop = Spring.GetGameSeconds()
  end
  tGroup.totalHealth = nHealth
end


function widget:DrawScreen()
  if WG.Cutscene and WG.Cutscene.IsInCutscene() then
    return
  end
  local iCounter

  if updated then
    updated = false
    -- loop through each possible group
    for groupId = 1, 10 do
      if updatedGroups[groupId] then
        updatedGroups[groupId] = false

        UpdateOneGroupsDetails(groupId)
      end
    end

    RecalcMappings()

  end

  --~ 	SetupDimensions(10)

  -- Check to see if we're in "slideMode" (we're moving the icons around)
  if slideMode then
    local newX, newY, _, _, _ = Spring.GetMouseState()
    if alignment=="right" then
      if newY ~= oldMouseY then
        slideOffset.right = slideOffset.right + newY - oldMouseY
        oldMouseY = newY
      end
    else -- "bottom"
      if newX ~= oldMouseX then
        slideOffset.bottom = slideOffset.bottom + newX - oldMouseX
        oldMouseX = newX
      end
    end
  end

  -- Check to see if the control icon is at least on the screen.  If it isn't, move it onto the screen.
  if slideOffset.bottom < 0 then
    slideOffset.bottom = 0
  elseif slideOffset.bottom > vsx - iconSizeX then
    slideOffset.bottom = vsx - iconSizeX
  end
  if slideOffset.right < iconSizeY then
    slideOffset.right = iconSizeY
  elseif slideOffset.right > vsy - iconSizeY then
    slideOffset.right = vsy - iconSizeY
  end


  -- We check the health status of one group / frame (we don't reeeally need to check them all every frame)
  CheckOneGroupsHealth(nLastGroupChecked)
  nLastGroupChecked  = nLastGroupChecked + 1
  if (nLastGroupChecked > 10) then
    nLastGroupChecked = 1
  end

  -- unit model rendering uses the depth-buffer
  gl.Clear(GL.DEPTH_BUFFER_BIT)

  -- draw the control icons
  DrawControlIcons()

  selectedGroupId = Spring.GetSelectedGroup()
  if selectedGroupId ~= nil then
    selectedGroupId = GetNumFromGroupId(selectedGroupId)
  end

  -- draw the buildpics
  for iCounter = 1, 10 do
    --~ 		DrawUnitDefIcon(iCounter) --old system
    DrawGroupIcon(iCounter) --new system
  end
end

function GetGroupIdFromNum(num)
  -- the Lua mod (%) does not seem to work.
  if num ~= 10 then
    return num
  else
    return 0
  end
end

function GetNumFromGroupId(groupId)
  if groupId == 0 then
    return 10
  else
    return groupId
  end
end

function DrawControlIcons()
  -- the control icons are three buttons:
  --	(1) "Alignment" switch between right screen edge and bottom
  --	(2) "AlwaysOn" always show empty groups or allow them to slide away; and
  --	(3) "Shrink" close space between empty groups when they're empty (like idlecons script)
  local xmin, ymin, xmax, ymax = GetBoxForIcon(0)
  if xmin == nil then
    echo("DrawControlIcons(): GetBoxForIcon(0) returned nil!")
    return -- error?
  end

  -- blueish grey
  local boxTopColor = {0.9, 0.9, 1, 0.5}
  local boxBottomColor = {0.55, 0.55, 0.65, 0.5}

  -- draw a box with the above colours
  drawBox(xmin, ymax, iconSizeX, iconSizeY, bgIcexuickGrey, boIcexuickGrey)
  --~ 	drawBoxGradient(xmin, ymax, iconSizeX, iconSizeY, boxTopColor, boxTopColor, boxBottomColor, boxBottomColor)
  --~ 	drawBoxOutline(xmin, ymax, iconSizeX, iconSizeY, {0.3, 0.3, 0.3, 1})

  local sliderTopColor = {0, 0, 0, 1}
  local sliderBottomColor = {0.4, 0.4, 0.4, 1}

  gl.Color(1,1,1)
  if alignment=="right" then
    -- draw slider bar
    drawBoxGradient(xmin, ymax, iconSizeX, iconSizeY/4, sliderTopColor, sliderTopColor, sliderBottomColor, sliderBottomColor)
    -- draw buttons left to right
    gl.Color(1,1,1)
    gl.Text("Bottom", xmin, ymin + iconSizeY/3 - 4, 8, "on")
    if iconsAlwaysOn then
      drawBox(xmin + iconSizeX / 3 + 1, ymax - iconSizeY/4 - 1, iconSizeX / 3 - 2, iconSizeY*2/3 - 2, {0, 1, 0, 0.5}, {0.1,0.1,0.1,1})
    end
    gl.Color(1,1,1)
    gl.Text("Always", xmin + iconSizeX / 3 + 1, ymin + iconSizeY/3 - 4 , 8, "on")
    if iconsShrink then
      drawBox(xmin + iconSizeX*2/3 + 1, ymax - iconSizeY/4 - 1, iconSizeX / 3 - 2, iconSizeY*2/3 - 2, {0, 1, 0, 0.5}, {0.1,0.1,0.1,1})
    end
    gl.Color(1,1,1)
    gl.Text("Shrink", xmin + iconSizeX * 2 / 3 + 1, ymin + iconSizeY/3 - 4 , 8, "on")
  else
    -- draw slider bar
    drawBoxGradient(xmin, ymax, iconSizeX/4, iconSizeY, sliderTopColor, sliderBottomColor, sliderBottomColor, sliderTopColor)
    -- draw buttons top to bottom
    gl.Color(1,1,1)
    gl.Text("Right", xmin + iconSizeX/4 + 2, ymax - 12, 8, "on")
    if iconsAlwaysOn then
      drawBox(xmin + iconSizeX/4 + 1, ymax - iconSizeY/3+1, iconSizeX*3/4 - 2, iconSizeY/3, {0, 1, 0, 0.5}, {0.1,0.1,0.1,1})
    end
    gl.Color(1,1,1)
    gl.Text("Always", xmin + iconSizeX/4 + 2, ymax - 12 - iconSizeY / 3 , 8, "on")
    if iconsShrink then
      drawBox(xmin + iconSizeX/4 + 1, ymax - iconSizeY*2/3+1, iconSizeX*3/4 - 2, iconSizeY/3, {0, 1, 0, 0.5}, {0.1,0.1,0.1,1})
    end
    gl.Color(1,1,1)
    gl.Text("Shrink", xmin + iconSizeX/4 + 2, ymax - 12 - iconSizeY * 2 / 3  , 8, "on")
  end
end

function GetBoxForIcon(iconNum)
  if iconNum ~= 0 and iconWindows[iconNum].groupId == nil then
    -- There is no mapping from this icon number to a group, so it doesn't get drawn.
    return nil
  end
  local xEdge = 0
  local yEdge = 0
  --    echo("c:"..(vsx - iconSizeX))
  if iconNum ~= 0 and (iconWindows[iconNum].windowHidden == 1 and iconsAlwaysOn == false)  then
    -- This icon is currently fully hidden, so we won't draw it here.
    return nil
  end
  if alignment == "right" then
    xEdge = vsx - iconSizeX
    yEdge = (iconSizeY + 1) * (iconCount - iconNum)
    -- the following allows for the scrolling of the icon in and out
    if iconNum ~= 0 and iconsAlwaysOn == false then
      xEdge = xEdge + (iconSizeX * iconWindows[iconNum].windowHidden)
    end
    --~ 		yEdge = yEdge + vsy/2 - iconCount * iconSizeY / 2
    yEdge = yEdge  + slideOffset.right - iconCount * iconSizeY
    return xEdge, yEdge, xEdge + iconSizeX, yEdge + iconSizeY
  else
    xEdge = (iconSizeX + 1) * iconNum
    yEdge = 0
    --~ 		xEdge = xEdge + vsx/2 - iconCount * iconSizeX / 2
    xEdge = xEdge + slideOffset.bottom
    -- the following allows for the scrolling of the icon in and out
    if iconNum ~= 0 and iconsAlwaysOn == false then
      yEdge = yEdge - (iconSizeY * iconWindows[iconNum].windowHidden)
    end
    return xEdge, yEdge, xEdge + iconSizeX, yEdge + iconSizeY
  end
end

--~ function SetupDimensions(count)
  --~ 	xmid = vsx * 0.5
  --~ 	width = math.floor(iconSizeX * count)
  --~ 	rectMinX = math.floor(xmid - (0.5 * width))
  --~ 	rectMaxX = math.floor(xmid + (0.5 * width))
  --~ 	rectMinY = math.floor(0)
  --~ 	rectMaxY = math.floor(rectMinY + iconSizeY)
  --~
  --~ end

  -------------------------------------------------------------------------------
  -------------------------------------------------------------------------------

  function CenterUnitDef(unitDefID)
    local ud = UnitDefs[unitDefID]
    if (not ud) then
      return
    end
    if (not ud.dimensions) then
      ud.dimensions = Spring.GetUnitDefDimensions(unitDefID)
    end
    if (not ud.dimensions) then
      return
    end

    local d = ud.dimensions
    local xSize = (d.maxx - d.minx)
    local ySize = (d.maxy - d.miny)
    local zSize = (d.maxz - d.minz)

    local hSize -- maximum horizontal dimension
    if (xSize > zSize) then hSize = xSize else hSize = zSize end

    -- aspect ratios
    local mAspect = hSize / ySize
    --~ 	local vAspect = iconSizeX / iconSizeY
    local vAspect
    if alignment == "right" then
      vAspect = iconSizeX / 2 / iconSizeY
    else
      vAspect = iconSizeX / (iconSizeY / 2)
    end

    -- scale the unit to the box (maxspect)
    local scale
    if (mAspect > vAspect) then
      if alignment == "right" then
        scale = (iconSizeX / 2 / hSize)
      else
        scale = (iconSizeX / hSize)
      end
    else
      if alignment == "right" then
        scale = (iconSizeY / ySize)
      else
        scale = (iconSizeY / 2 / ySize)
      end
    end
    scale = scale * 0.8 -- * 0.5
    gl.Scale(scale, scale, scale)

    -- translate to the unit's midpoint
    local xMid = 0.5 * (d.maxx + d.minx)
    local yMid = 0.5 * (d.maxy + d.miny)
    local zMid = 0.5 * (d.maxz + d.minz)
    gl.Translate(-xMid, -yMid, -zMid)
  end

  -------------------------------------------------------------------------------
  -------------------------------------------------------------------------------

  local function SetupModelDrawing()
    gl.DepthTest(true)
    gl.DepthMask(true)
    gl.Culling(GL.FRONT)
    gl.Lighting(true)
    gl.Blending(false)
    gl.Material({
      ambient  = { 0.2, 0.2, 0.2, 1.0 },
      diffuse  = { 1.0, 1.0, 1.0, 1.0 },
      emission = { 0.0, 0.0, 0.0, 1.0 },
      specular = { 0.2, 0.2, 0.2, 1.0 },
      shininess = 16.0
    })
  end

  -------------------------------------------------------------------------------
  -------------------------------------------------------------------------------

  local function RevertModelDrawing()
    gl.Blending(true)
    gl.Lighting(false)
    gl.Culling(false)
    gl.DepthMask(false)
    gl.DepthTest(false)
  end

  -------------------------------------------------------------------------------
  -------------------------------------------------------------------------------
  function DrawGroupIcon(iconId)
    local scrollRate = 0.04
    local groupId = iconWindows[iconId].groupId
    local tUnitGroup = unitGroups[groupId]
    local tIconWindow = iconWindows[iconId]

    -- the following scrolls the group icons in and out
    -- at the moment it is dependent on the screen refresh rate.  this will need to be fixed.
    -- maybe with  widgetHandler:GetHourTimer()
    if not iconsAlwaysOn then
      --~         if groupId == 1 then
      --~            -- echo("numUnits:".. tUnitGroup.numUnits .. ", hidden:"..tIconWindow.windowHidden)
      --~         end
      if (tUnitGroup ~= nil and tUnitGroup.numUnits > 0 and tIconWindow.windowHidden > 0)then
        -- we've got units, and the window is at least partially hidden
        tIconWindow.windowHidden = tIconWindow.windowHidden - scrollRate
      elseif (tUnitGroup ~= nil and tUnitGroup.numUnits == 0) and tIconWindow.windowHidden < 1  then
        -- we've got no units (or there is no group assigned), and the window is not yet fully hidden
        tIconWindow.windowHidden = tIconWindow.windowHidden + scrollRate
      end
      -- now we need to make sure that the windowHidden value is not greater than 1, or less than 0
      if tIconWindow.windowHidden > 1 then
        tIconWindow.windowHidden = 1
      elseif tIconWindow.windowHidden < 0 then
        tIconWindow.windowHidden = 0
      end
    else
      if tUnitGroup ~= nil and tUnitGroup.numUnits > 0 then
        tIconWindow.windowHidden = 0
      else
        tIconWindow.windowHidden = 1
      end
    end

    local xmin, ymin, xmax, ymax = GetBoxForIcon(iconId)
    if xmin==nil then
      --echo("DrawGroupIcon(): problem with GetBoxForIcon()")
      return
    end
    local xmid = (xmin + xmax) * 0.5
    local ymid = (ymin + ymax) * 0.5

    gl.Scissor(xmin, ymin, xmax - xmin, ymax - ymin)

    --~ 	gl.Blending(GL.SRC_ALPHA, GL.ONE)

    -- blueish grey gradient
    local boxTopColor = {0.85, 0.85, 0.95, 0.5}
    local boxBottomColor = {0.65, 0.65, 0.75, 0.5}
    local background = bgIcexuickGrey
    local border = boIcexuickGrey

    gl.Texture(false)
    if tUnitGroup ~= nil then
      gl.Scissor(xmin, ymin, xmax - xmin, ymax - ymin)
      if tUnitGroup.lastHealthDrop > Spring.GetGameSeconds() - 9 then
        -- this group has suffered damange within the last 5 seconds!
        -- maybe add an icon or have the box flash!
        local colourTimer = math.cos(20 * widgetHandler:GetHourTimer())
        gl.Blending(GL.SRC_ALPHA, GL.ONE)
        boxTopColor = {colourTimer/2+0.5, 0, 0, 0.5}
        boxBottomColor = {colourTimer * 0.7/2+0.5, 0, 0, 0.5}
        background = boxTopColor
      end
      gl.Scissor(false)
    end

    -- Draw a box for the icon.  This will be flashing red if the group has taken damage, otherwise it will be a grey gradient.
    drawBox(xmin, ymax, iconSizeX, iconSizeY, background, border)
    --~ 	drawBoxGradient(xmin, ymax, iconSizeX, iconSizeY, boxTopColor, boxTopColor, boxBottomColor, boxBottomColor)

    -- Draw the outline for the box
    if selectedGroupId == groupId then
      -- this group is selected so we'll draw a thick yellow box around them
      drawBorder(xmin, ymax, iconSizeX, iconSizeY, 4,  {0.7, 0.7, 0.1, 1})
    else
      -- not selected so we'll instead draw a dark grey box
      drawBoxOutline(xmin, ymax, iconSizeX, iconSizeY, {0.3, 0.3, 0.3, 1})
    end

    -- draw the 3d model of the unit
    if tUnitGroup ~= nil and tUnitGroup.primaryUnitTypeId ~= nil then
      local ud = UnitDefs[tUnitGroup.primaryUnitTypeId]
      if ud ~= nil then
        -- draw the 3D unit
        SetupModelDrawing()
        gl.PushMatrix()
        gl.Scissor(xmin, ymin, xmax - xmin, ymax - ymin)
        --~ 			gl.Translate(xmid, ymid, 0)
        if alignment == "right" then
          gl.Translate((xmid + xmax) / 2, ymid, 0)
        else
          gl.Translate(xmid, (ymid + ymin)/2, 0)
        end
        gl.Rotate(15.0, 1, 0, 0)
        local timer = 1.5 * widgetHandler:GetHourTimer()
        gl.Rotate(math.cos(0.5 * math.pi * timer) * 60.0, 0, 1, 0)
        CenterUnitDef(tUnitGroup.primaryUnitTypeId)
        gl.UnitShape(tUnitGroup.primaryUnitTypeId, Spring.GetMyTeamID())
        gl.Scissor(false)
        gl.PopMatrix()
        RevertModelDrawing()
      end
    end

    -- Draw a "health box" if there are any units
    if tUnitGroup ~= nil and tUnitGroup.totalMaxHealth > 0 then
      -- border of box for total health
      local nVBuffer = 23
      local nHBuffer = 3
      local nBarHeight = 13
      local nBarLength
      if alignment == "right" then
        nBarLength = (xmax - xmin) / 2 - nHBuffer * 2
      else
        nBarLength = xmax - xmin - nHBuffer * 2
      end
      drawBox(xmin + nHBuffer, ymax - nVBuffer, nBarLength, nBarHeight, {0.8,0.8,0.8, 0.7}, {0.1,0.1,0.1, 0.7})
      -- health bar
      local nHealthRatio = tUnitGroup.totalHealth / tUnitGroup.totalMaxHealth
      local nHealthLength = nHealthRatio * (nBarLength - 2)
      local tHealthColour = { (1 - nHealthRatio), nHealthRatio, 0, 0.5}
      local tHealthColourBorder = {(1 - nHealthRatio) / 2, nHealthRatio / 2, 0, 0.5}
      drawBox(xmin + nHBuffer + 1, ymax  - nVBuffer - 1, nHealthLength,  nBarHeight - 1, tHealthColour, tHealthColourBorder)
      -- write the health as a number over the top of the health bar
      gl.Color({ 1, 1, 1 })
      gl.Text(" "..math.floor(tUnitGroup.totalHealth), xmin + 3, ymax - nVBuffer - nBarHeight , 10, "on")
    end

    -- display the "group number" (ie: its name)
    gl.Color({ 1, 1, 1 })
    gl.Text(""..GetGroupIdFromNum(groupId), xmin, ymax - 12, 10, "on")

    -- display the number of units in the group
    if tUnitGroup ~= nil and tUnitGroup.numUnits ~= nil then
      gl.Text("Count: "..tUnitGroup.numUnits, xmin, ymax - 22, 10, "n")
    else
      gl.Text("Count: 0", xmin, ymax - 22, 10, "n")
    end
    gl.Scissor(false)
  end

  -------------------------------------------------------------------------------

  function widget:MousePress(x, y, button)
    mouseIcon = MouseOverIcon(x, y)
    activePress = (mouseIcon >= 0)
    if activePress then
      local shift
      _, _, _, shift = Spring.GetModKeyState()
      if button == 4 then
        if shift then
          iconSizeX = iconSizeX + 3
        else
          iconSizeY = iconSizeY + 3
        end
      elseif button == 5 then
        if shift then
          iconSizeX = iconSizeX - 3
        else
          iconSizeY = iconSizeY - 3
        end
      end
      iconDefaultWidth[alignment] = iconSizeX
      iconDefaultHeight[alignment] = iconSizeY
      if button == 1 and mouseIcon == 0 then
        -- left mouse press on control box
        local xmin, ymin, xmax, ymax = GetBoxForIcon(0)
        if (alignment=="right" and y > ymax - iconSizeY/3) or (alignment == "bottom" and x < xmin + iconSizeX/3) then
          slideMode = true
          slideOffsetChanged[alignment] = true
          oldMouseX = x
          oldMouseY = y
        end
      end
    end
    return activePress
  end

  -------------------------------------------------------------------------------

  function widget:MouseRelease(x, y, button)
    if (not activePress) then
      return -1
    end

    activePress = false

    if slideMode then
      slideMode = false
      return true
    end

    local iconNum = MouseOverIcon(x, y)
    local bDoubleClick = false
    local nNewClickTime = Spring.GetGameSeconds()

    -- Test for a double click action
    if (iconNum == nLastIcon) and (nNewClickTime - nLastClick < 2) then
      -- The user double clicked.
      bDoubleClick = true
      nLastClick = 0
      nLastIcon = -1
    else
      -- Only a single click
      nLastClick = nNewClickTime
      nLastIcon = iconNum
    end

    if iconNum ~= 0 then
      -- one of the UnitGroup icons was selected
      if button == 1 and iconWindows[iconNum].groupId ~= nil then
        -- select that group, and go to it if double-clicked
        Spring.SendCommands({"group"..GetGroupIdFromNum(iconWindows[iconNum].groupId)})
        if bDoubleClick then
          -- The user double clicked so we'll also centre the camera on the units
          Spring.SendCommands({"viewselection"})
        end
      elseif button == 3 and iconWindows[iconNum].groupId ~= nil then
        -- add the selcted units to the group icon clicked on
        local selectedUnits = Spring.GetSelectedUnits()
        Spring.SendCommands({"@+C@group"..GetGroupIdFromNum(iconWindows[iconNum].groupId)})
      elseif button == 2 and iconWindows[iconNum].groupId ~= nil then
        -- replace the group with the selected units
        Spring.SendCommands({"@+C+S@group"..GetGroupIdFromNum(iconWindows[iconNum].groupId)})
      end
    else
      -- they've clicked in the icon controlls area
      local iconChoice
      if alignment == "right" then
        iconChoice = 2 - math.floor((vsx - x) / iconSizeX * 3)
      else
        iconChoice = 2 - math.floor(y / iconSizeY * 3)
      end
      if iconChoice == 0 then
        -- selected "alignment" button
        if alignment=="right" then
          alignment = "bottom"
        else
          alignment = "right"
        end
        iconSizeX = iconDefaultWidth[alignment]
        iconSizeY = iconDefaultHeight[alignment]
      elseif iconChoice == 1 then
        -- selected the Always On button
        iconsAlwaysOn = not iconsAlwaysOn
        if iconsAlwaysOn and iconsShrink then
          -- these can not both be on at the same time
          iconsShrink = false
          RecalcMappings()
        end
      else
        -- selected the Icons Shrink button
        iconsShrink = not iconsShrink
        if iconsAlwaysOn and iconsShrink then
          -- these can not both be on at the same time
          iconsAlwaysOn = false
        end
        RecalcMappings()
      end
    end

    return -1
  end

  -------------------------------------------------------------------------------

  function MouseOverIcon(x, y)
    local icon
    local xmin, ymin, xmax, ymax
    for icon = 0, 10 do
      xmin, ymin, xmax, ymax = GetBoxForIcon(icon)
      if xmin ~= nil then
        if x > xmin and x < xmax and y > ymin and y < ymax then
          -- we're in this box
          return icon
        end
      end
    end
    return -1
  end

  -------------------------------------------------------------------------------

  function echo(msg)
    Spring.SendCommands({"echo " .. msg})
  end

  -------------------------------------------------------------------------------

  function widget:GetTooltip(x, y)
    local iconNum = MouseOverIcon(x, y)
    if iconNum ~= 0 then
      return "Single Left Click: select group\nDouble Left Click: select and move to group"
    else
      -- they've clicked in the icon controlls area
      local iconChoice
      if alignment == "right" then
        iconChoice = 2 - math.floor((vsx - x) / iconSizeX * 3)
      else
        iconChoice = 2 - math.floor(y / iconSizeY * 3)
      end
      if iconChoice == 0 then
        -- Alignment button
        if alignment=="right" then
          return "Click to move the UnitGroups Icons to the bottom of the screen"
        else
          return "Click to move the UnitGroups Icons to the right side of the screen"
        end
      elseif iconChoice == 1 then
        -- iconsAlwaysOn button
        return "Click to alternate between always showing all of the UnitGroup icons, even when empty, or not showing them."
      else
        -- iconsShrink button
        return "Click to alternate between always shrinking the icon list to exclude empty groups, or not."
      end
    end
  end

  -------------------------------------------------------------------------------

  function widget:IsAbove(x, y)
    if MouseOverIcon(x, y) == -1 then
      return false
    else
      return true
    end
  end

  function drawTextureAdv(name, screenLeft, screenTop, screenWidth, screenHeight, texLeft, texTop, texWidth, texHeight, imgSize, imgColour)
    -- Note: images have 0,0 in the top left corner, while the screen coords are 0,0 in the bottom left corner.
    if imgColour == nil then
      gl.Color(Colors.white)
    else
      gl.Color(imgColour)
    end
    gl.Texture(":n:LuaUI/Images/" .. name)
    gl.Shape(GL.QUADS, {
      { v = { screenLeft-1,						screenTop       +1 }, 					t = { texLeft/imgSize, 				texTop/imgSize}},
      { v = { screenLeft+screenWidth-1,	screenTop       +1 }, 					t = {(texLeft+texWidth)/imgSize,	texTop/imgSize}},
      { v = { screenLeft+screenWidth-1, 	screenTop-screenHeight+1 }, 	t = {(texLeft+texWidth)/imgSize,	(texTop+texHeight)/imgSize}},
      { v = { screenLeft -1, 					screenTop-screenHeight+1 }, 	t = { texLeft/imgSize,					(texTop+texHeight)/imgSize}}
    })
    gl.Texture(false)
  end

  function drawTexture(name, left, top, width, height, innerX, innerY, imgSize)
    gl.Color(Colors.white)
    gl.Texture(":n:LuaUI/Images/" .. name)
    gl.Shape(GL.QUADS, {
      { v = { left-1,				top       +1 }, 		t = { innerX/imgSize, 				innerY/imgSize}},
      { v = { left+width-1,	top       +1 }, 		t = {(innerX+width)/imgSize, 	innerY/imgSize}},
      { v = { left+width-1, 	top-height+1 }, 	t = {(innerX+width)/imgSize,	(innerY+height)/imgSize}},
      { v = { left -1, 			top-height+1 }, 	t = { innerX/imgSize,				(innerY+height)/imgSize}}
    })
    gl.Texture(false)
  end

  function drawBox(left,top, width,height, bgColor, boColor)
    if left==nil or width < 2 or height < 2 then
      return false
    end
    gl.Color(bgColor)
    gl.Shape(GL.QUADS, {
      { v = { left+width, top-height }},
      { v = { left,       top-height }},
      { v = { left,       top        }},
      { v = { left+width, top        }}
    })

    gl.Color(boColor)
    gl.Shape(GL.LINE_LOOP, {
      { v = { left+width, top-height }},
      { v = { left,         top-height }},
      { v = { left,         top          }},
      { v = { left+width,   top        }}
    })
  end

  function drawBoxSimple(left,top, width,height, bgColor)
    if left==nil or width < 2 or height < 2 then
      return false
    end
    gl.Color(bgColor)
    gl.Shape(GL.QUADS, {
      { v = { left+width, top-height }},
      { v = { left,       top-height }},
      { v = { left,       top        }},
      { v = { left+width, top        }}
    })
  end

  function drawBoxOutline(left,top, width,height, boColor)
    if left==nil or width < 2 or height < 2 then
      return false
    end
    gl.Color(boColor)
    gl.Shape(GL.LINE_LOOP, {
      { v = { left+width, top-height }},
      { v = { left,         top-height }},
      { v = { left,         top          }},
      { v = { left+width,   top        }}
    })
  end

  function drawBorder(left, top, width, height, lineWidth, boColor)
    -- top line
    drawBoxSimple(left, top, width, lineWidth, boColor)
    -- right line
    drawBoxSimple(left + width - lineWidth, top - lineWidth +1, lineWidth, height - lineWidth + 1, boColor)
    -- bottom line
    drawBoxSimple(left, top - height + lineWidth, width - lineWidth, lineWidth, boColor)
    -- left line
    drawBoxSimple(left, top - lineWidth + 1, lineWidth, height - lineWidth*2 + 2, boColor)
  end

  function drawBoxGradient(left, top, width, height, topLeftColour, topRightColour, bottomRightColour, bottomLeftColour)
    if left==nil or width < 2 or height < 2 then
      return false
    end
    gl.Color(1,1,1)
    gl.Shape(GL.QUADS, {
      { v = { left+width, top-height },	color = bottomRightColour},
      { v = { left,       top-height },		color = bottomLeftColour},
      { v = { left,       top        },				color = topLeftColour},
      { v = { left+width, top        },			color = topRightColour}
    })
  end

  function boolToNumber(value)
    if value then
      return 1
    else
      return 0
    end
  end

  function numberToBool(value)
    if value ~= 0 then
      return true
    else
      return false
    end
  end

