function widget:GetInfo()
  return {
    name      = "Restricted Zones",
    desc      = "Place restricted zones - ceasefired units walking into them will break your ceasefire.",
    author    = "CarRepairer(playerlist) and GoogleFrog(lasso)",
    date      = "2011-06-30",
    license   = "GNU GPL, v2 or later",
    layer     = 2000,
    enabled   = true, -- loaded by default?
	handler   = true,
  }
end

------------------------------------------------------------------
------------------------------------------------------------------

if Spring.FixedAllies() then
  return
end
------------------------------------------------------------------
------------------------------------------------------------------

local echo = Spring.Echo

local spGetGroundHeight		= Spring.GetGroundHeight
local spTraceScreenRay		= Spring.TraceScreenRay
local spGetSpectatingState  = Spring.GetSpectatingState
local spGetAllyTeamList     = Spring.GetAllyTeamList
local spSendLuaRulesMsg     = Spring.SendLuaRulesMsg
local spGetLocalAllyTeamID	= Spring.GetLocalAllyTeamID
local spGetLocalTeamID		= Spring.GetLocalTeamID
local spGetUnitsInRectangle		= Spring.GetUnitsInRectangle

local glLineStipple 		= gl.LineStipple
local glLineWidth   		= gl.LineWidth
local glColor       		= gl.Color
local glDepthTest			= gl.DepthTest
local glDrawGroundCircle	= gl.DrawGroundCircle -- the areas are actually rectangles but ground quads look crap

local abs = math.abs
local floor = math.floor

------------------------------------------------------------------

if not WG.rzones then
	WG.rzones = {
		rZonePlaceMode = false
	}
end

------------------------------------------------------------------
-- CONFIG
local size = 128 -- size of the zones

local myAllyID = -1
local myTeamID = -1
------------------------------------------------------------------
-- NO LONGER CONFIG

local zones = {}
local zoneID = {count = 0, data = {}}


local point = {}
local points = 0

local cycle = 0

local drawing = false

local drawingLasso = false
local addZones = false

------------------------------------------------------------------
-- THE BIT THAT DRAWS LASSOS

local function legalPos(pos)
	return pos and pos[1] > 0 and pos[3] > 0 and pos[1] < Game.mapSizeX and pos[3] < Game.mapSizeZ
end

-- adds or deletes a zone based on state
local function updateZone(x,z,state)
	if state then
		if not (zones[x] and zones[x][z]) then
			zoneID.count = zoneID.count + 1
			zoneID.data[zoneID.count] = {x = x, z = z}
			zones[x] = zones[x] or {}
			zones[x][z] = zoneID.count
		end
	else
		if (zones[x] and zones[x][z]) then
			if zoneID.count ~= zones[x][z] then
				zones[zoneID.data[zoneID.count].x][zoneID.data[zoneID.count].z] = zones[x][z]
				zoneID.data[zones[x][z]] = zoneID.data[zoneID.count]
			end
			zones[x][z] = nil
			zoneID.data[zoneID.count] = nil
			zoneID.count = zoneID.count - 1
		end
	end
end

-- fills in the lasso
local function calculateAreaPoints()
	
	-- floodfill
	local border = {left = Game.mapSizeX, right = 0, top = Game.mapSizeZ, bottom = 0}
	
	local area = {}
	
	-- deduce area to flood
	for i = 1, points do
		if point[i].x < border.left then
			border.left = point[i].x
		end
		if point[i].x > border.right then
			border.right = point[i].x
		end
		if point[i].z < border.top then
			border.top = point[i].z
		end
		if point[i].z > border.bottom then
			border.bottom = point[i].z
		end
	end
	
	-- initialise area array for required 2d space
	for i = border.left-size,border.right+size,size do
		area[i] = {}
	end
	
	-- set points as immovable
	for i = 1, points do
		area[point[i].x][point[i].z] = false
	end
	
	-- set edges to remove area points, will propagate
	local props = {0,0}
	local prop = {{},{}}
	
	for i = border.left,border.right,size do
		if area[i][border.top] ~= false then
			area[i][border.top] = true
			props[1] = props[1] + 1
			prop[1][props[1]] = {i,border.top}
		end
		if area[i][border.bottom] ~= false then
			area[i][border.bottom] = true
			props[1] =props[1] + 1
			prop[1][props[1]] = {i,border.bottom}
		end
	end
	for i = border.top,border.bottom,size do
		if area[border.left][i] ~= false then
			area[border.left][i] = -1
			props[1] = props[1] + 1
			prop[1][props[1]] = {border.left,i}
		end
		if area[border.right][i] ~= false then
			area[border.right][i] = true
			props[1] = props[1] + 1
			prop[1][props[1]] = {border.right,i}
		end
	end
	
	--set an edge around the propagation
	for i = border.left-size,border.right+size,size do
		area[i][border.top-size] = true
		area[i][border.bottom+size] = true
	end
	for i = border.top-size,border.bottom+size,size do
		area[border.left-size][i] = true
		area[border.right+size][i] = true
	end
	
	-- do the fill, at this point:
	-- * walls = false
	-- * empty = nil
	-- * edge = true
	
	local turn = 1
	local other = 2

	while props[turn] ~= 0 do
	
		props[other] = 0
		prop[other] = {}
		
		for i = 1, props[turn] do
			local x,z = prop[turn][i][1],prop[turn][i][2]
			if area[x+size][z] == nil then
				area[x+size][z] = true
				props[other] = props[other] + 1
				prop[other][props[other]] = {x+size,z}
			end
			if area[x-size][z] == nil then
				area[x-size][z] = true
				props[other] = props[other] + 1
				prop[other][props[other]] = {x-size,z}
			end
			if area[x][z+size] == nil then
				area[x][z+size] = true
				props[other] = props[other] + 1
				prop[other][props[other]] = {x,z+size}
			end
			if area[x][z-size] == nil then
				area[x][z-size] = true
				props[other] = props[other] + 1
				prop[other][props[other]] = {x,z-size}
			end
		end
		turn,other = other, turn
	end

	-- now the affected area is the nil or false area
	
	for i = border.left,border.right,size do
		for j = border.top,border.bottom,size do
			if not area[i][j] then
				updateZone(i,j,addZones)
				--Spring.MarkerAddPoint(i,0,j)
			end
		end
	end
	
end

-- THE BIT THAT DOES THE CHECK FOR "ALLIED" UNITS
local function unitInRZones(cAlliance)
	local teamList = Spring.GetTeamList(cAlliance)
	for _,teamID in ipairs(teamList) do
		for i = 1, zoneID.count do
			local zone = zoneID.data[i]
			local units = spGetUnitsInRectangle(zone.x, zone.z, zone.x+size, zone.z+size, teamID)
			if units and units[1] then
				return true
			end
		end
	end
	return false
end

local function nukeInRectangle(x1,z1,x2,z2, nx,nz)
	if nx >= x1 and nx <= x2 and nz >= z1 and nz <= z2 then
		return true
	end
	return false
end

local function nukeInRZones(x,y,z)
	for i = 1, zoneID.count do
		local zone = zoneID.data[i]
		if nukeInRectangle(zone.x, zone.z, zone.x+size, zone.z+size, x,z) then
			return true
		end
	end
	
	return false
end

local function explode(div,str)
  if (div=='') then return false end
  local pos,arr = 0,{}
  -- for each divider found
  for st,sp in function() return string.find(str,div,pos,true) end do
    table.insert(arr,string.sub(str,pos,st-1)) -- Attach chars left of current divider
    pos = sp + 1 -- Jump past current divider
  end
  table.insert(arr,string.sub(str,pos)) -- Attach chars right of last divider
  return arr
end


----------------------------------------------------
-- callins


function widget:MousePress(mx, my, button)
	
	if WG.rzones.rZonePlaceMode and (button == 1 or button == 3) and not drawingLasso then
		local _, pos = spTraceScreenRay(mx, my, true)
		if legalPos(pos) then
			points = 1
			point[points] = {x = floor(pos[1]/size)*size, z = floor(pos[3]/size)*size}
			
			addZones = (button == 1)
			drawingLasso = true
			return true
		end
	end
	return false
end

function widget:MouseMove(mx, my, dx, dy, button)

	if drawingLasso then
		local _, pos = spTraceScreenRay(mx, my, true)
		if legalPos(pos) then
			local newX = floor(pos[1]/size)*size
			local newZ = floor(pos[3]/size)*size
			
			if newX ~= point[points].x or newZ ~= point[points].z then
				
				if abs(newX - point[points].x) <= size and abs(newZ - point[points].z) <= size then
					points = points + 1
					point[points] = {x = newX, z = newZ}
				else -- prevent holes between points
				
					if pos[1] < size*0.5 then
						pos[1] = size*0.5
					end
					if pos[1] > Game.mapSizeX - size then
						pos[1] = Game.mapSizeX - size
					end
					if pos[3] < size*0.5 then
						pos[3] = size*0.5
					end
					if pos[3] > Game.mapSizeZ - size then
						pos[3] = Game.mapSizeZ - size
					end
					
					local diffX = (pos[1] - point[points].x + size/2)
					local diffZ = (pos[3] - point[points].z + size/2)
					local a_diffX = abs(diffX)
					local a_diffZ = abs(diffZ)
					
					local reffPoint = point[points]
				
					if a_diffX > a_diffZ then
						local m = diffZ/diffX
						local sign = diffX/a_diffX
						local a_diffX = floor(a_diffX/size)*size
						for j = 0, a_diffX, size do
							points = points + 1
							point[points] = {x = reffPoint.x + j*sign, z = floor((reffPoint.z + j*m*sign)/size)*size}
							--point[points] = {x = reffPoint.x + j*sign, z = reffPoint.z}
						end
					else
						local m = diffX/diffZ
						local sign = diffZ/a_diffZ
						local a_diffZ = floor(a_diffZ/size)*size
						for j = 0, a_diffZ, size do
							points = points + 1
							point[points] = {x = floor((reffPoint.x + j*m*sign)/size)*size, z = reffPoint.z + j*sign}
							--point[points] = {x = reffPoint.x, z = reffPoint.z + j*sign}
						end
					end
				
				end
			end
		end
		return true
	end
end

function widget:RecvLuaMsg(msg, playerID)
	local luamsg = explode('|',msg)
	if luamsg[1] ~= 'nukelaunch' then
		return
	end
	
	local allianceId = tonumber( luamsg[2] )
	if allianceId == myAllyID then
		return
	end
	
	local x,y,z = tonumber( luamsg[3] ), tonumber( luamsg[4] ), tonumber( luamsg[5] )
	if nukeInRZones(x,y,z) then
		spSendLuaRulesMsg('ceasefire:n:'..allianceId)
	end
	
end

function widget:MouseRelease(mx, my, button)
	
	if drawingLasso then
		
		calculateAreaPoints()
		
		point = {}
		points = 0
		drawingLasso = false
	end
	
end


function widget:Initialize()
	myAllyID = spGetLocalAllyTeamID()
	myTeamID = spGetLocalTeamID()
		
end
function widget:Update()

	if WG.rzones.rZonePlaceMode and not drawing then
		widgetHandler:UpdateWidgetCallIn("DrawWorld", self)
		drawing = true
	end
	
	cycle = cycle % (32*5) + 1
	
	spec = spGetSpectatingState()
	
	if cycle == 1 then
		if not spec then
			--for cAlliance, _ in pairs(myCeasefires) do
			local alliances = spGetAllyTeamList()
			for _, alliance in ipairs(alliances) do
				if Spring.GetGameRulesParam('cf_' .. myAllyID .. '_' .. alliance) == 1 then
					if unitInRZones(alliance) then
						spSendLuaRulesMsg('ceasefire:n:'..alliance)
					end
				end
			end
		end
		
	end
end

function widget:DrawWorld()
	
	if not WG.rzones.rZonePlaceMode then
		widgetHandler:RemoveWidgetCallIn("DrawWorld", self)
		drawing = false
		return
	end

	glDepthTest(true)
	glLineWidth(2)
	glColor(1,0,0,1)
	for i = 1, zoneID.count do
		glDrawGroundCircle(zoneID.data[i].x+size*0.5,0,zoneID.data[i].z+size*0.5, size*0.5, 16)
	end
	glLineStipple(1, 4000)
	if drawingLasso then
		for i = 1, points do
			glLineWidth(2)
			glColor(0,1,0,1)
			glDrawGroundCircle(point[i].x+size*0.5,0,point[i].z+size*0.5, size*0.5, 16)
		end
	end
	glLineStipple(false)
	glDepthTest(false)
	glColor(1,1,1,1)
end
