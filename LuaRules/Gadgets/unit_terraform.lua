-- $Id: unit_terraform.lua 4610 2009-05-12 13:03:32Z google frog $
--------------------------------------------------------------------------------
--------------------------------------------------------------------------------

function gadget:GetInfo()
  return {
    name      = "Terraformers",
    desc      = "Terraforming script for lasso based area/line terraform, also ramp",
    author    = "Google Frog",
    date      = "Nov, 2009",
    license   = "GNU GPL, v2 or later",
    layer     = 0,
    enabled   = true  --  loaded by default?
  }
end

--------------------------------------------------------------------------------
--------------------------------------------------------------------------------
if (gadgetHandler:IsSyncedCode()) then -- SYNCED
--------------------------------------------------------------------------------
--------------------------------------------------------------------------------
  
-- Speedups
local cos             		= math.cos
local floor           		= math.floor
local abs             		= math.abs
local pi             		= math.pi
local ceil 			  		= math.ceil
local sqrt 					= math.sqrt
local random 		  		= math.random
local spAdjustHeightMap     = Spring.AdjustHeightMap
local spGetGroundHeight     = Spring.GetGroundHeight
local spGetGroundOrigHeight = Spring.GetGroundOrigHeight
local spLevelHeightMap      = Spring.LevelHeightMap
local spGetUnitBuildFacing  = Spring.GetUnitBuildFacing
local spGetUnitCommands     = Spring.GetUnitCommands
local spValidUnitID         = Spring.ValidUnitID
local spGetGameFrame		= Spring.GetGameFrame
local spGiveOrderToUnit		= Spring.GiveOrderToUnit
local spInsertUnitCmdDesc   = Spring.InsertUnitCmdDesc
local spTestBuildOrder      = Spring.TestBuildOrder
local spSetHeightMap        = Spring.SetHeightMap
local spSetHeightMapFunc    = Spring.SetHeightMapFunc
local spRevertHeightMap     = Spring.RevertHeightMap
local spEditUnitCmdDesc     = Spring.EditUnitCmdDesc
local spFindUnitCmdDesc     = Spring.FindUnitCmdDesc
local spGetActiveCommand	= Spring.GetActiveCommand
local spSpawnCEG     		= Spring.SpawnCEG
local spCreateUnit			= Spring.CreateUnit
local spDestroyUnit			= Spring.DestroyUnit
local spGetAllyTeamList		= Spring.GetAllyTeamList
local spSetUnitLosMask		= Spring.SetUnitLosMask
local spGetTeamInfo			= Spring.GetTeamInfo
local spGetUnitHealth		= Spring.GetUnitHealth 
local spSetUnitHealth		= Spring.SetUnitHealth
local spGetCommandQueue 	= Spring.GetCommandQueue
local spGetUnitAllyTeam		= Spring.GetUnitAllyTeam	
local spAddHeightMap		= Spring.AddHeightMap	
local spGetUnitPosition		= Spring.GetUnitPosition	
local spSetUnitPosition		= Spring.SetUnitPosition	
local spSetUnitSensorRadius	= Spring.SetUnitSensorRadius
local spGetAllUnits			= Spring.GetAllUnits
local spSetUnitTooltip		= Spring.SetUnitTooltip

local mapWidth = Game.mapSizeX
local mapHeight = Game.mapSizeZ

local CMD_OPT_RIGHT = CMD.OPT_RIGHT
local CMD_OPT_SHIFT = CMD.OPT_SHIFT 
local CMD_STOP = CMD.STOP
local CMD_REPAIR = CMD.REPAIR

local checkCoord = {
	{x = -8, z = 0},
	{x = 8, z = 0},
	{x = 0, z = -8},
	{x = 0, z = 8},
	}

local invRoot2 = 1/sqrt(2)

local terraUnitHP = 1000000 --hp of terraunit, must be the same as on unitdef

--------------------------------------------------------------------------------
-- Configuration
--------------------------------------------------------------------------------

local maxAreaSize = 2000 -- max X or Z bound of area terraform
local updateFrequency = 30 -- how many frames to update
local areaSegMaxSize = 200 -- max width and height of terraform squares

local maxWallPoints = 700 -- max points that can makeup a wall
local wallSegmentLength = 14 -- how many points are part of a wall segment (points are seperated 8 elmos orthagonally)

local maxRampWidth = 200 -- maximun width of ramp segment
local maxRampLegth = 200 -- maximun length of ramp segment

local maxHeightDifference = 30 -- max difference of height around terraforming, Makes Shraka Pyramids
local maxRampGradient = 5

local pointBaseCost = 0.16
local volumeCost = 0.016

-- seismic missile
local seismicRad = 256

--ramp dimensions
local maxTotalRampLength = 3000
local maxTotalRampWidth = 800
local minTotalRampLength = 32
local minTotalRampWidth = 24

local checkLoopFrames = 1800 -- how many frames it takes to check through all cons
local terraformDecayFrames = 2400 -- how many frames a terrablock can survive for without a repair command
local decayCheckFrequency = 90 -- frequency of terraform decay checks

local structureCheckLoopFrames = 300 -- frequency of slow update for building deformation check

local terraUnitLimit = 250 -- limit on terraunits per player

local terraUnitTooltip = "Spent: "

local costMult = 1
local modOptions = Spring.GetModOptions()
if modOptions.terracostmult then
	costMult = modOptions.terracostmult
end

costMult = costMult * volumeCost

--------------------------------------------------------------------------------
-- Arrays
--------------------------------------------------------------------------------

local drawPositions			= {count = 0, data = {}}
local drawPosMap			= {}

local structure          	= {}
local structureTable		= {}
local structureCount	 	= 0

local structureAreaMap      = {}

local structureCheckFrame	= {}
local currentCheckFrame 	= 0

local terraformUnit 		= {}
local terraformUnitTable 	= {}
local terraformUnitCount 	= 0

local terraformOrder		= {}
local terraformOrders 		= 0

local constructor			= {}
local constructorTable		= {}
local constructors			= 0
local currentCon 			= 0 

local checkInterval 		= 0 

local terraunitDefID = UnitDefNames["terraunit"].id

local corclogDefID = UnitDefNames["corclog"].id
--local novheavymineDefID = UnitDefNames["novheavymine"].id

--------------------------------------------------------------------------------
-- Custom Commands
--------------------------------------------------------------------------------

include("LuaRules/Configs/customcmds.h.lua")

local rampCmdDesc = {
  id      = CMD_RAMP,
  type    = CMDTYPE.ICON_MAP,
  name    = 'Ramp',
  cursor  = 'Repair', 
  action  = 'rampground',
  tooltip = 'Build a Ramp between 2 positions, click 2x - start and end of ramp',
}

local levelCmdDesc = {
  id      = CMD_LEVEL,
  type    = CMDTYPE.ICON_MAP,
  name    = 'Level',
  cursor  = 'Repair', 
  action  = 'levelground',
  tooltip = 'Levels the ground in an area - draw a line or shape while holding mouse',
}

local raiseCmdDesc = {
  id      = CMD_RAISE,
  type    = CMDTYPE.ICON_MAP,
  name    = 'Raise',
  cursor  = 'Repair', 
  action  = 'raiseground',
  tooltip = 'Raises/Lowers the ground in an area',
}

local smoothCmdDesc = {
  id      = CMD_SMOOTH,
  type    = CMDTYPE.ICON_MAP,
  name    = 'Smooth',
  cursor  = 'Repair', 
  action  = 'smoothground',
  tooltip = 'Smooths the ground in an area',
}

local restoreCmdDesc = {
  id      = CMD_RESTORE,
  type    = CMDTYPE.ICON_MAP,
  name    = 'Restore',
  cursor  = 'Repair', 
  action  = 'restoreground',
  tooltip = 'Restores the ground to origional height',
}

--------------------------------------------------------------------------------
-- Terraform Calculation Functions
--------------------------------------------------------------------------------

local function linearEquation(x,m,x1,y1)
  return m*(x-x1)+y1
end

local function distance(x1,y1,x2,y2)
  return ((x1-x2)^2+(y1-y2)^2)^0.5
end

local function pointHeight(xs, ys, zs, x, z, m, h, xdis)

  local xInt = (z-zs+m*xs+x/m)/(m+1/m)
  
  local ratio = abs(xInt-xs)/xdis
  
  return ratio*h+ys

end

local function checkPointCreation(terraform_type, volumeSelection, orHeight, newHeight, startHeight)

	if volumeSelection == 0 or terraform_type == 2 or terraform_type == 3 then
		return true
	end
	
	if terraform_type == 5 then
		return (volumeSelection == 1 and orHeight < startHeight) or (volumeSelection == 2 and orHeight > startHeight)
	else
		return (volumeSelection == 1 and orHeight < newHeight) or (volumeSelection == 2 and orHeight > newHeight)
	end
	
end

local function TerraformRamp(x1, y1, z1, x2, y2, z2, terraform_width, unit, units, team, volumeSelection, shift)

	--calculate equations of the 3 lines, left, right and mid
	
	local border = {}
  
	local dis = distance(x1,z1,x2,z2)
	
	if dis < minTotalRampLength-0.05 or dis > maxTotalRampLength+0.05 then
		return
	end
	
	if terraform_width < minTotalRampWidth or terraform_width > maxTotalRampWidth*2 then
		return
	end
  
	local xdis = abs(x1-x2)
	local heightDiff = y2-y1
	if heightDiff/dis > maxRampGradient then
		heightDiff = maxRampGradient*dis
	elseif heightDiff/dis < -maxRampGradient then
		heightDiff = -maxRampGradient*dis
	end
	
	local m
	if x1 ~= x2 then
		m = (z1-z2)/(x1-x2)
	else
		m = 100000
	end
	if m == 0 then 
		m = 0.0001 
	end 
  
	local segLength = dis/(ceil(dis/maxRampLegth))
	local segWidth = terraform_width/ceil(terraform_width/maxRampWidth)
	local widthScale = terraform_width/dis
	local lengthScale = segLength/dis
  
	local add = {x = (x2-x1)*lengthScale, z = (z2-z1)*lengthScale}
	local addPerp = {x = (z1-z2)*segWidth/dis, z = -(x1-x2)*segWidth/dis}
	
	local mid = {x = (x1-x2)*widthScale/2, z = (z1-z2)*widthScale/2}
	local leftRot = {x = mid.z+x1, z = -mid.x+z1}
	local rightRot = {x = -mid.z+x1, z = mid.x+z1}
  
	local topleftGrad
	local botleftGrad
  
	local toppoint
	local botpoint
	local leftpoint
	local rightpoint
 
	--** Store the 4 points of each segment diamond, changes with quadrant **
	
	if x1 < x2 then
		if z1 < z2 then
			-- bottom right
			topleftGrad = -1/m
			botleftGrad = m
			
			toppoint = rightRot
			leftpoint = {x = rightRot.x+addPerp.x, z = rightRot.z+addPerp.z}
			rightpoint = {x = toppoint.x+add.x, z = toppoint.z+add.z}
			botpoint = {x = leftpoint.x+add.x, z = leftpoint.z+add.z}
			
			border = {left = leftRot.x, right = rightRot.x-x1+x2, top = rightRot.z, bottom = leftRot.z-z1+z2}
		else
			-- top right
			topleftGrad = m
			botleftGrad = -1/m
			
			leftpoint = rightRot
			botpoint = {x = rightRot.x+addPerp.x, z = rightRot.z+addPerp.z}
			rightpoint = {x = botpoint.x+add.x, z = botpoint.z+add.z}
			toppoint = {x =  rightRot.x+add.x, z =  rightRot.z+add.z}
			
			border = {left = rightRot.x, right = leftRot.x-x1+x2, top = rightRot.z-z1+z2, bottom = leftRot.z}
		end
	else
		if z1 < z2 then
			-- bottom left
			topleftGrad = m
			botleftGrad = -1/m
	  
			rightpoint = rightRot
			toppoint = {x = rightRot.x+addPerp.x, z = rightRot.z+addPerp.z}
			botpoint = {x = rightRot.x+add.x, z = rightRot.z+add.z}
			leftpoint = {x = toppoint.x+add.x, z = toppoint.z+add.z}
			
			border = {left = leftRot.x-x1+x2, right = rightRot.x, top = rightRot.z-z1+z2, bottom = leftRot.z}
		else 
			-- top left
			topleftGrad = -1/m 
			botleftGrad = m
			
			botpoint = rightRot
			rightpoint = {x = rightRot.x+addPerp.x, z = rightRot.z+addPerp.z}
			toppoint = {x = rightpoint.x+add.x, z = rightpoint.z+add.z}
			leftpoint = {x = rightRot.x+add.x, z = rightRot.z+add.z}
			
			border = {left = rightRot.x-x1+x2, right = leftRot.x, top = leftRot.z-z1+z2, bottom = rightRot.z}
		end
	end
	-- check it's all working
	--[[
	
	Spring.MarkerAddPoint( border.left,0,border.top,"topleft")
	Spring.MarkerAddPoint( border.right,0,border.bottom,"botright")
	Spring.MarkerAddPoint( x1,y1,z1,  "start")
	Spring.MarkerAddPoint( x2,y2,z2,  "end")
	Spring.MarkerAddPoint( leftpoint.x,y1,leftpoint.z,  "leftP")
	Spring.MarkerAddPoint( toppoint.x,y1,toppoint.z,  "topP")
	Spring.MarkerAddPoint( botpoint.x,y1,botpoint.z,  "botP")
	Spring.MarkerAddPoint( leftpoint.x,y1,toppoint.z,  "topleft")
	Spring.MarkerAddPoint( rightpoint.x,y1,botpoint.z,  "botright")
	  
	Spring.MarkerAddLine(toppoint.x,y1,toppoint.z,leftpoint.x,y1,leftpoint.z)
	Spring.MarkerAddLine(botpoint.x,y1,botpoint.z,leftpoint.x,y1,leftpoint.z)
	Spring.MarkerAddLine(toppoint.x,y1,toppoint.z,rightpoint.x,y1,rightpoint.z)
	Spring.MarkerAddLine(botpoint.x,y1,botpoint.z,rightpoint.x,y1,rightpoint.z)

	Spring.MarkerAddLine(leftpoint.x,y1,toppoint.z,rightpoint.x,y1,toppoint.z)
	Spring.MarkerAddLine(rightpoint.x,y1,toppoint.z,rightpoint.x,y1,botpoint.z)
	Spring.MarkerAddLine(leftpoint.x,y1,toppoint.z,leftpoint.x,y1,botpoint.z)
	Spring.MarkerAddLine(leftpoint.x,y1,botpoint.z,rightpoint.x,y1,botpoint.z)
	--]]

	--** Split the ramp into segments and calculate the points within each one**
  
	local otherTerraformUnitCount = terraformUnitCount
  
	local segment = {}
	local n = 1
	
	local i = 0
	while i*segLength < dis do
		local j = 0
		while j*segWidth < terraform_width do
		
			segment[n] = {}
			segment[n].point = {}
			segment[n].area = {}
			segment[n].border = {
				left = floor((leftpoint.x+add.x*i+addPerp.x*j)/8)*8, 
				right = ceil((rightpoint.x+add.x*i+addPerp.x*j)/8)*8, 
				top = floor((toppoint.z+add.z*i+addPerp.z*j)/8)*8, 
				bottom = ceil((botpoint.z+add.z*i+addPerp.z*j)/8)*8
			}
			segment[n].position = {x = (rightRot.x-4+add.x*i+addPerp.x*(j+0.5)-16*(x2-x1)/dis), z = (rightRot.z-4+add.z*i+addPerp.z*(j+0.5)-16*(z2-z1)/dis)}
			local pc = 1
		  
			local topline1 = {x = leftpoint.x+add.x*i+addPerp.x*j, z = leftpoint.z+add.z*i+addPerp.z*j, m = topleftGrad}
			local topline2 = {x = toppoint.x+add.x*i+addPerp.x*j, z = toppoint.z+add.z*i+addPerp.z*j, m = botleftGrad}
			local botline1 = {x = leftpoint.x+add.x*i+addPerp.x*j, z = leftpoint.z+add.z*i+addPerp.z*j, m = botleftGrad}
			local botline2 = {x = botpoint.x+add.x*i+addPerp.x*j, z = botpoint.z+add.z*i+addPerp.z*j, m = topleftGrad}
			
			local topline = topline1
			local botline = botline1
			
			local lx = segment[n].border.left
			while lx <= segment[n].border.right do
				segment[n].area[lx] = {}
				local zmin = linearEquation(lx,topline.m,topline.x,topline.z)
				local zmax = linearEquation(lx,botline.m,botline.x,botline.z)
				
				local lz = segment[n].border.top
				while lz <= zmax do
				
					if zmin <= lz then
						local h = pointHeight(x1, y1, z1, lx, lz, m, heightDiff, xdis)		  
						segment[n].point[pc] = {x = lx, y = h ,z = lz, orHeight = spGetGroundHeight(lx,lz)}
						
						if checkPointCreation(4, volumeSelection, segment[n].point[pc].orHeight, h, 0) then
							pc = pc + 1
						end
					end
			  
					lz = lz+8
				end	  
				lx = lx+8
			  
				if topline == topline1 and topline2.x < lx then
					topline = topline2
				end
			  
				if botline == botline1 and botline2.x < lx then
					botline = botline2
				end
			  
			end  
			
			if pc ~= 1 then
				segment[n].points = pc - 1
				n = n + 1
			end
	 
			j = j+1
		end
		i = i+1
	end
	
	--** Detect potentially overlapping buildings**
	
	local localStructure = {}
	local localStructureCount = 0
	
	for i = 1, structureCount do
		local s = structure[structureTable[i] ]
		if (border.left < s.maxx and 
			border.right > s.minx and
			border.top < s.maxz and
			border.bottom > s.minz) then
			
			localStructureCount = localStructureCount + 1
			localStructure[localStructureCount] = i
		end	
	end
    
	--** Creates terraform building and assigns each one segment data **
		
	local block = {}
	local blocks = 0
	
	terraformOrders = terraformOrders + 1
	terraformOrder[terraformOrders] = {border = border, index = {}, indexes = 0}
	
	for i = 1,n-1 do
		
		-- detect overlapping buildings
		
		segment[i].structure = {}
		segment[i].structureCount = 0
		segment[i].structureArea = {}
		
		for j = 1, localStructureCount do
			local s = structure[structureTable[localStructure[j]]]
			if (segment[i].border.left < s.maxx and 
				segment[i].border.right > s.minx and
				segment[i].border.top < s.maxz and
				segment[i].border.bottom > s.minz) then
				
				segment[i].structureCount = segment[i].structureCount + 1
				segment[i].structure[segment[i].structureCount] = {id = s}
				
				s.checkAtDeath = true
				
				for lx = s.minx, s.maxx, 8 do
					if not segment[i].structureArea[lx] then
						segment[i].structureArea[lx] = {}
					end
					for lz = s.minz,s.maxz, 8 do
						segment[i].structureArea[lx][lz] = true
					end
				end 
				
			end	
		end
	
		-- calculate cost
		local totalCost = 0
		for j = 1, segment[i].points do
			if not segment[i].area[segment[i].point[j].x] then
				segment[i].area[segment[i].point[j].x] = {}
			end
			local currHeight = segment[i].point[j].orHeight
			segment[i].point[j].aimHeight = segment[i].point[j].y
			if segment[i].structureArea[segment[i].point[j].x] and segment[i].structureArea[segment[i].point[j].x][segment[i].point[j].z] then
				segment[i].point[j].diffHeight = 0.0001
				segment[i].point[j].structure = true
				--segment[i].area[segment[i].point[j].x][segment[i].point[j].z] = {orHeight = segment[i].point[j].orHeight,diffHeight = segment[i].point[j].diffHeight, building = true}
			else
				segment[i].point[j].diffHeight = segment[i].point[j].aimHeight-currHeight
				segment[i].area[segment[i].point[j].x][segment[i].point[j].z] = {orHeight = segment[i].point[j].orHeight,diffHeight = segment[i].point[j].diffHeight, building = false}
			end
			totalCost = totalCost + abs(segment[i].point[j].diffHeight)
		end
		
		if totalCost ~= 0 then
			totalCost = totalCost*costMult
		
			local id = spCreateUnit(terraunitDefID, segment[i].position.x, 0, segment[i].position.z, 0, team, true)
			if id then
				local allyTeamList = spGetAllyTeamList()
				local _,_,_,_,_,unitAllyTeam = spGetTeamInfo(team)
				for _,allyID in ipairs (allyTeamList) do
					if allyID ~= unitAllyTeam then
						spSetUnitLosMask(id, allyID, {los=true, radar=true, prevLos=true, contRadar=true } )
					end
				end
			
				spSetUnitSensorRadius(id,"los",0)
				spSetUnitSensorRadius(id,"airLos",0)
				spSetUnitHealth(id, {
					health = 0,
					build  = 0
				})
			
				blocks = blocks + 1
				block[blocks] = id

				terraformUnitCount = terraformUnitCount + 1
				terraformOrder[terraformOrders].indexes = terraformOrder[terraformOrders].indexes + 1
				
				terraformUnit[id] = {
					position = segment[i].position, 
					progress = 0, 
					lastUpdate = 0, 
					totalSpent = 0,
					baseCostSpent = 0,
					cost = totalCost, 
					baseCost = segment[i].points*pointBaseCost,
					totalCost = totalCost + segment[i].points*pointBaseCost,
					point = segment[i].point, 
					points = segment[i].points, 
					area = segment[i].area, 
					border = segment[i].border, 
					smooth = false, 
					intercepts = 0, 
					intercept = {}, 
					interceptMap = {},
					decayTime = terraformDecayFrames, 
					allyTeam = unitAllyTeam,
					team = team,
					order = terraformOrders,
					orderIndex = terraformOrder[terraformOrders].indexes,
					fullyInitialised = false,
					lastProgress = 0,
					lastHealth = 0,
				}
				
				terraformUnitTable[terraformUnitCount] = id
				terraformOrder[terraformOrders].index[terraformOrder[terraformOrders].indexes] = terraformUnitCount
			end
		end
		
	end
	--** Give repair order for each block to all selected units **
		
	for i = 1, units do
	
		if (spValidUnitID(unit[i])) then
			if shift then
				spGiveOrderToUnit(unit[i],CMD_REPAIR,{block[1]},CMD_OPT_SHIFT)
			else
				spGiveOrderToUnit(unit[i],CMD_REPAIR,{block[1]},CMD_OPT_RIGHT)
			end
			
			for j = 2, blocks do
				spGiveOrderToUnit(unit[i],CMD_REPAIR,{block[j]},CMD_OPT_SHIFT)
			end
		end
	end
  
end

local function TerraformWall(terraform_type,mPoint,mPoints,terraformHeight,unit,units,team,volumeSelection,shift)

	local border = {left = mapWidth, right = 0, top = mapHeight, bottom = 0}
	
	--** Convert Mouse Points to a Closed Loop on a Grid **

	-- points interpolated from mouse points
	local point = {}
	local points = 1
	
	mPoint[1].x = floor((mPoint[1].x+8)/16)*16
	mPoint[1].z = floor((mPoint[1].z+8)/16)*16
	point[1] = mPoint[1]
	-- update border
	if point[points].x-16 < border.left then
		border.left = point[points].x-16
	end
	if point[points].x+16 > border.right then
		border.right = point[points].x+16
	end
	if point[points].z-16 < border.top then
		border.top = point[points].z-16
	end
	if point[points].z+16 > border.bottom then
		border.bottom = point[points].z+16
	end
	
	
	for i = 2, mPoints, 1 do
		mPoint[i].x = floor((mPoint[i].x+8)/16)*16
		mPoint[i].z = floor((mPoint[i].z+8)/16)*16
		
		local diffX = mPoint[i].x - mPoint[i-1].x
		local diffZ = mPoint[i].z - mPoint[i-1].z
		local a_diffX = abs(diffX)
		local a_diffZ = abs(diffZ)
			
		if a_diffX <= 16 and a_diffZ <= 16 then
			points = points + 1
			point[points] = {x = mPoint[i].x, z = mPoint[i].z}
			-- update border
			if point[points].x-16 < border.left then
				border.left = point[points].x-16
			end
			if point[points].x+16 > border.right then
				border.right = point[points].x+16
			end
			if point[points].z-16 < border.top then
				border.top = point[points].z-16
			end
			if point[points].z+16 > border.bottom then
				border.bottom = point[points].z+16
			end
		else
			-- interpolate between far apart points to prevent wall holes.
			if a_diffX > a_diffZ then
				local m = diffZ/diffX
				local sign = diffX/a_diffX
				for j = 0, a_diffX, 16 do	
					points = points + 1
					point[points] = {x = mPoint[i-1].x + j*sign, z = floor((mPoint[i-1].z + j*m*sign)/16)*16}
					-- update border
					if point[points].x-16 < border.left then
						border.left = point[points].x-16
					end
					if point[points].x+16 > border.right then
						border.right = point[points].x+16
					end
					if point[points].z-16 < border.top then
						border.top = point[points].z-16
					end
					if point[points].z+16 > border.bottom then
						border.bottom = point[points].z+16
					end
				end
			else
				local m = diffX/diffZ
				local sign = diffZ/a_diffZ
				for j = 0, a_diffZ, 16 do	
					points = points + 1
					point[points] = {x = floor((mPoint[i-1].x + j*m*sign)/16)*16, z = mPoint[i-1].z + j*sign}
					-- update border
					if point[points].x-16 < border.left then
						border.left = point[points].x-16
					end
					if point[points].x+16 > border.right then
						border.right = point[points].x+16
					end
					if point[points].z-16 < border.top then
						border.top = point[points].z-16
					end
					if point[points].z+16 > border.bottom then
						border.bottom = point[points].z+16
					end
				end
			end
			
		end
	end
	
	if points > maxWallPoints then
		-- cancel command if the wall is too big, anti-slowdown
		return false 
	end

	
	--** Split the mouse points into segments **
	
	-- area checks for overlap
	local area = {}
	
	for i = border.left,border.right,8 do
		area[i] = {}
	end
	
	local segment = {}
	local n = 1
	local count = 0
	local continue = true
	
	while continue do
		
		if count*wallSegmentLength+1 <= points then
			segment[n] = {}
			segment[n].point = {}
			segment[n].area = {}
			segment[n].border = {left = mapWidth, right = 0, top = mapHeight, bottom = 0}
			segment[n].position = {x = point[count*wallSegmentLength+1].x, z = point[count*wallSegmentLength+1].z}
			local pc = 1
			
			for j = count*wallSegmentLength+1, (count+1)*wallSegmentLength do
			
				if j > points then
					continue = false				
					break
				else
					
					for lx = -16,16,8 do
						for lz = -16,16,8 do
							-- lx/lz steps through the points around the mousePoint
							if not area[point[j].x+lx][point[j].z+lz] then 
								-- check if the point will be terraformed be a previous block
								segment[n].point[pc] = {x = point[j].x+lx, z = point[j].z+lz}
								area[point[j].x+lx][point[j].z+lz] = true
								-- update border
								if segment[n].point[pc].x-16 < segment[n].border.left then
									segment[n].border.left = segment[n].point[pc].x-16
								end
								if segment[n].point[pc].x+16 > segment[n].border.right then
									segment[n].border.right = segment[n].point[pc].x+16 
								end
								if segment[n].point[pc].z-16 < segment[n].border.top then
									segment[n].border.top = segment[n].point[pc].z-16
								end
								if segment[n].point[pc].z+16 > segment[n].border.bottom then
									segment[n].border.bottom = segment[n].point[pc].z+16 
								end
								local currHeight = spGetGroundHeight(segment[n].point[pc].x, segment[n].point[pc].z)
								segment[n].point[pc].orHeight = currHeight
								if checkPointCreation(terraform_type, volumeSelection, currHeight, terraformHeight,spGetGroundOrigHeight(segment[n].point[pc].x, segment[n].point[pc].z)) then
									pc = pc + 1
								end
							end
						end
					end
					
				end
			
			end
			
			-- discard segments with no new terraforming
			if pc ~= 1 then
				segment[n].points = pc - 1
				n = n + 1
			end
			count = count + 1
		else
			continue = false
		end
		
	end
	
	--** Detect potentially overlapping buildings**
	
	local localStructure = {}
	local localStructureCount = 0
	
	for i = 1, structureCount do
		local s = structure[structureTable[i]]
		if (border.left < s.maxx and 
			border.right > s.minx and
			border.top < s.maxz and
			border.bottom > s.minz) then
				
			localStructureCount = localStructureCount + 1
			localStructure[localStructureCount] = i
		end	
	end
	

	--** Creates terraform building and assigns each one segment data **
	
	local block = {}
	local blocks = 0
	
	terraformOrders = terraformOrders + 1
	terraformOrder[terraformOrders] = {border = border, index = {}, indexes = 0}
	
	local otherTerraformUnitCount = terraformUnitCount

	for i = 1,n-1 do
	
		-- detect overlapping buildings
		
		segment[i].structure = {}
		segment[i].structureCount = 0
		segment[i].structureArea = {}
		
		for j = 1, localStructureCount do
			local s = structure[structureTable[localStructure[j]]]
			if (segment[i].border.left < s.maxx and 
				segment[i].border.right > s.minx and
				segment[i].border.top < s.maxz and
				segment[i].border.bottom > s.minz) then
				
				segment[i].structureCount = segment[i].structureCount + 1
				segment[i].structure[segment[i].structureCount] = {id = s}
				
				s.checkAtDeath = true
				
				for lx = s.minx, s.maxx, 8 do
					if not segment[i].structureArea[lx] then
						segment[i].structureArea[lx] = {}
					end
					for lz = s.minz,s.maxz, 8 do
						segment[i].structureArea[lx][lz] = true
					end
				end 
				
			end	
		end
		
		-- calculate cost
		local totalCost = 0
		if terraform_type == 1 then
			for j = 1, segment[i].points do
				if not segment[i].area[segment[i].point[j].x] then
					segment[i].area[segment[i].point[j].x] = {}
				end
				currHeight = segment[i].point[j].orHeight
				segment[i].point[j].aimHeight = terraformHeight
				if segment[i].structureArea[segment[i].point[j].x] and segment[i].structureArea[segment[i].point[j].x][segment[i].point[j].z] then
					segment[i].point[j].diffHeight = 0.0001
					segment[i].point[j].structure = true
					--segment[i].area[segment[i].point[j].x][segment[i].point[j].z] = {orHeight = segment[i].point[j].orHeight,diffHeight = segment[i].point[j].diffHeight, building = true}
				else
					segment[i].point[j].diffHeight = segment[i].point[j].aimHeight-currHeight
					segment[i].area[segment[i].point[j].x][segment[i].point[j].z] = {orHeight = segment[i].point[j].orHeight,diffHeight = segment[i].point[j].diffHeight, building = false}
				end
				totalCost = totalCost + abs(segment[i].point[j].diffHeight)
				if not segment[i].area[segment[i].point[j].x] then
					segment[i].area[segment[i].point[j].x] = {}
				end
			end
		elseif terraform_type == 2 then 
			for j = 1, segment[i].points do
				if not segment[i].area[segment[i].point[j].x] then
					segment[i].area[segment[i].point[j].x] = {}
				end
				currHeight = segment[i].point[j].orHeight
				segment[i].point[j].aimHeight = terraformHeight+currHeight
				if segment[i].structureArea[segment[i].point[j].x] and segment[i].structureArea[segment[i].point[j].x][segment[i].point[j].z] then
					segment[i].point[j].diffHeight = 0.0001
					segment[i].point[j].structure = true
					--segment[i].area[segment[i].point[j].x][segment[i].point[j].z] = {orHeight = segment[i].point[j].orHeight,diffHeight = segment[i].point[j].diffHeight, building = true}
				else
					segment[i].point[j].diffHeight = terraformHeight
					segment[i].area[segment[i].point[j].x][segment[i].point[j].z] = {orHeight = segment[i].point[j].orHeight,diffHeight = segment[i].point[j].diffHeight, building = false}
				end
				totalCost = totalCost + abs(terraformHeight)
				if not segment[i].area[segment[i].point[j].x] then
					segment[i].area[segment[i].point[j].x] = {}
				end
			end
		elseif terraform_type == 3 then 
			for j = 1, segment[i].points do
				local totalHeight = 0
				for lx = -16, 16,8 do
					for lz = -16, 16,8 do
						totalHeight = totalHeight + spGetGroundHeight(segment[i].point[j].x+lx, segment[i].point[j].z+lz)
					end
				end
				if not segment[i].area[segment[i].point[j].x] then
					segment[i].area[segment[i].point[j].x] = {}
				end
				currHeight = segment[i].point[j].orHeight
				segment[i].point[j].aimHeight = totalHeight/25
				if segment[i].structureArea[segment[i].point[j].x] and segment[i].structureArea[segment[i].point[j].x][segment[i].point[j].z] then
					segment[i].point[j].diffHeight = 0.0001
					segment[i].point[j].structure = true
					--segment[i].area[segment[i].point[j].x][segment[i].point[j].z] = {orHeight = segment[i].point[j].orHeight,diffHeight = segment[i].point[j].diffHeight, building = true}
				else
					segment[i].point[j].diffHeight = segment[i].point[j].aimHeight-currHeight
					segment[i].area[segment[i].point[j].x][segment[i].point[j].z] = {orHeight = segment[i].point[j].orHeight,diffHeight = segment[i].point[j].diffHeight, building = false}
				end
				totalCost = totalCost + abs(segment[i].point[j].diffHeight)
				if not segment[i].area[segment[i].point[j].x] then
					segment[i].area[segment[i].point[j].x] = {}
				end
			end
		elseif terraform_type == 5 then 
			for j = 1, segment[i].points do
				if not segment[i].area[segment[i].point[j].x] then
					segment[i].area[segment[i].point[j].x] = {}
				end
				currHeight = segment[i].point[j].orHeight
				segment[i].point[j].aimHeight = spGetGroundOrigHeight(segment[i].point[j].x, segment[i].point[j].z)
				if segment[i].structureArea[segment[i].point[j].x] and segment[i].structureArea[segment[i].point[j].x][segment[i].point[j].z] then
					segment[i].point[j].diffHeight = 0.0001
					segment[i].point[j].structure = true
					--segment[i].area[segment[i].point[j].x][segment[i].point[j].z] = {orHeight = segment[i].point[j].orHeight,diffHeight = segment[i].point[j].diffHeight, building = true}
				else
					segment[i].point[j].diffHeight = segment[i].point[j].aimHeight-currHeight
					segment[i].area[segment[i].point[j].x][segment[i].point[j].z] = {orHeight = segment[i].point[j].orHeight,diffHeight = segment[i].point[j].diffHeight, building = false}
				end
				totalCost = totalCost + abs(segment[i].point[j].diffHeight)
			end
		end
		
		if totalCost ~= 0 then
			totalCost = totalCost*costMult
		
			local id = spCreateUnit(terraunitDefID, segment[i].position.x, 0, segment[i].position.z, 0, team, true)
			if id then
				local allyTeamList = spGetAllyTeamList()
				local _,_,_,_,_,unitAllyTeam = spGetTeamInfo(team)
				for _,allyID in ipairs (allyTeamList) do
					if allyID ~= unitAllyTeam then
						spSetUnitLosMask(id, allyID, {los=true, radar=true, prevLos=true, contRadar=true } )
					end
				end
			
				spSetUnitSensorRadius(id,"los",0)
				spSetUnitSensorRadius(id,"airLos",0)
				spSetUnitHealth(id, {
					health = 0,
					build  = 0
				})
			
				blocks = blocks + 1
				block[blocks] = id
				
				terraformUnitCount = terraformUnitCount + 1
				terraformOrder[terraformOrders].indexes = terraformOrder[terraformOrders].indexes + 1

				terraformUnit[id] = {
					position = segment[i].position, 
					progress = 0, 
					lastUpdate = 0, 
					totalSpent = 0,
					baseCostSpent = 0,
					cost = totalCost, 
					baseCost = segment[i].points*pointBaseCost,
					totalCost = totalCost + segment[i].points*pointBaseCost,
					point = segment[i].point, 
					points = segment[i].points, 
					area = segment[i].area, 
					border = segment[i].border, 
					smooth = false, 
					intercepts = 0, 
					intercept = {}, 
					interceptMap = {},
					decayTime = terraformDecayFrames, 
					allyTeam = unitAllyTeam,
					team = team,
					order = terraformOrders,
					orderIndex = terraformOrder[terraformOrders].indexes,
					fullyInitialised = false,
					lastProgress = 0,
					lastHealth = 0,
				}
				
				terraformUnitTable[terraformUnitCount] = id
				terraformOrder[terraformOrders].index[terraformOrder[terraformOrders].indexes] = terraformUnitCount
			end
		end
		
	end
	
	--** Give repair order for each block to all selected units **
		
	for i = 1, units do
	
		if (spValidUnitID(unit[i])) then
			if shift then
				spGiveOrderToUnit(unit[i],CMD_REPAIR,{block[1]},CMD_OPT_SHIFT)
			else
				spGiveOrderToUnit(unit[i],CMD_REPAIR,{block[1]},CMD_OPT_RIGHT)
			end
			
			for j = 2, blocks do
				spGiveOrderToUnit(unit[i],CMD_REPAIR,{block[j]},CMD_OPT_SHIFT)
			end
		end
	end
	

end

local function TerraformArea(terraform_type,mPoint,mPoints,terraformHeight,unit,units,team,volumeSelection,shift)

	local border = {left = mapWidth, right = 0, top = mapHeight, bottom = 0} -- border for the entire area
	
	--** Convert Mouse Points to a Closed Loop on a Grid **
	
	-- close the mouse points loop
	mPoints = mPoints + 1 
	mPoint[mPoints] = mPoint[1]
	
	-- points interpolated from mouse points
	local point = {}
	local points = 1
	
	-- snap mouse to grid
	mPoint[1].x = floor(mPoint[1].x/16)*16
	mPoint[1].z = floor(mPoint[1].z/16)*16
	point[1] = mPoint[1]
	
	-- update border
	if point[points].x < border.left then
		border.left = point[points].x 
	end
	if point[points].x > border.right then
		 border.right = point[points].x 
	end
	if point[points].z < border.top then
		 border.top = point[points].z
	end
	if point[points].z > border.bottom then
		 border.bottom = point[points].z 
	end
	
	for i = 2, mPoints, 1 do
		-- snap mouse to grid
		mPoint[i].x = floor(mPoint[i].x/16)*16
		mPoint[i].z = floor(mPoint[i].z/16)*16
		
		local diffX = mPoint[i].x - mPoint[i-1].x
		local diffZ = mPoint[i].z - mPoint[i-1].z
		local a_diffX = abs(diffX)
		local a_diffZ = abs(diffZ)
			
		-- do not add another points of the same coordinates	
		if a_diffX <= 16 and a_diffZ <= 16 then
			points = points + 1
			point[points] = {x = mPoint[i].x, z = mPoint[i].z}
			-- update border
			if point[points].x < border.left then
				border.left = point[points].x 
			end
			if point[points].x > border.right then
				 border.right = point[points].x 
			end
			if point[points].z < border.top then
				 border.top = point[points].z
			end
			if point[points].z > border.bottom then
				 border.bottom = point[points].z 
			end
		else
			-- interpolate between far apart points to prevent loop holes.
			if a_diffX > a_diffZ then
				local m = diffZ/diffX
				local sign = diffX/a_diffX
				for j = 0, a_diffX, 16 do	
					points = points + 1
					point[points] = {x = mPoint[i].x - j*sign, z = floor((mPoint[i].z - j*m*sign)/16)*16}
					-- update border
					if point[points].x < border.left then
						 border.left = point[points].x 
					end
					if point[points].x > border.right then
						 border.right = point[points].x 
					end
					if point[points].z < border.top then
						 border.top = point[points].z
					end
					if point[points].z > border.bottom then
						 border.bottom = point[points].z 
					end
				end
			else
				local m = diffX/diffZ
				local sign = diffZ/a_diffZ
				for j = 0, a_diffZ, 16 do	
					points = points + 1
					point[points] = {x = floor((mPoint[i].x - j*m*sign)/16)*16, z = mPoint[i].z - j*sign}
					-- update border
					if point[points].x < border.left then
						border.left = point[points].x 
					end
					if point[points].x > border.right then
						 border.right = point[points].x 
					end
					if point[points].z < border.top then
						 border.top = point[points].z
					end
					if point[points].z > border.bottom then
						 border.bottom = point[points].z 
					end
				end
			end
			
		end
	end
	
	if border.right-border.left > maxAreaSize or border.bottom-border.top > maxAreaSize then
		-- cancel command if the area is too big, anti-slowdown
		return false 
	end
	
	--** Compute which points are on the inside of the Loop **
	-- Uses Floodfill, a faster algorithm is possible?
	
	local area = {}
	
	-- 2D array
	for i = border.left-16,border.right+16,16 do
		area[i] = {}
	end
	
	-- set loop edge points to 2. 2 cannot be flooded
	for i = 1, points do
		area[point[i].x][point[i].z] = 2
	end
	
	-- set all other array points to 1. 1 is vunerable
	for i = border.left,border.right,16 do
		for j = border.top,border.bottom,16 do
			if area[i][j] ~= 2 then
				area[i][j] = 1
			end
		end
	end
	
	-- set the points on the border of the array to -1. -1 is the 'flood'
	for i = border.left,border.right,16 do
		if area[i][border.top] ~= 2 then
			area[i][border.top] = -1
		end
		if area[i][border.bottom] ~= 2 then
			area[i][border.bottom] = -1
		end
	end
	for i = border.top,border.bottom,16 do
		if area[border.left][i] ~= 2 then
			area[border.left][i] = -1
		end
		if area[border.right][i] ~= 2 then
			area[border.right][i] = -1
		end
	end
	
	-- floodfill algorithm turning 1s into -1s. -1s turn to false
	local continue = true
	while continue do
		continue = false
		for i = border.left,border.right,16 do
			for j = border.top,border.bottom,16 do
				if area[i][j] == -1 then
					if area[i+16][j] == 1 then
						area[i+16][j] = -1
						continue = true
					end
					if area[i-16][j]  == 1 then
						area[i-16][j]  = -1
						continue = true
					end
					if area[i][j+16] == 1 then
						area[i][j+16] = -1
						continue = true
					end
					if area[i][j-16] == 1 then
						area[i][j-16] = -1
						continue = true
					end
					area[i][j] = false
				end
			end
		end
		
	end
	
	--** Break the area into segments to be individually terraformed **
	
	border.right = border.right + 16
	border.bottom = border.bottom + 16
	
	local width = (border.right-border.left)/ceil((border.right-border.left)/areaSegMaxSize)
	local height = (border.bottom-border.top)/ceil((border.bottom-border.top)/areaSegMaxSize)
	-- width and height are the witdh and height of segments. They must be squished to all be the same size
	
	local segment = {}
	
	local otherTerraformUnitCount = terraformUnitCount
	
	local wCount = ceil((border.right-border.left)/areaSegMaxSize)
	local hCount = ceil((border.bottom-border.top)/areaSegMaxSize)
	-- w/hCount is the number of segments that fit into the width/height
	local addX = 0
	-- addX and addZ prevent overlap
	local n = 1 -- segment count
	for i = 0, wCount-1 do
		local addZ = 0
		for j = 0, hCount-1 do
			-- i and j step through possible segments based on splitting the rectangular area into rectangles
			segment[n] = {}
			segment[n].point = {}
			segment[n].area = {}
			segment[n].border = {left = mapWidth, right = 0, top = mapHeight, bottom = 0}
			local totalX = 0
			local totalZ = 0
			-- totalX/Z is used to find the average position of the segment
			local m = 1 -- number of points in the segment
			for lx = border.left + floor(width * i/8)*8 + addX, border.left + floor(width * (i+1)/8)*8, 8 do
				for lz = border.top + floor(height * j/8)*8 + addZ, border.top + floor(height * (j+1)/8)*8, 8 do
					-- lx/lz steps though all points within a segment area
					if area[floor(lx/16)*16][floor(lz/16)*16] then
						
						local right = not area[floor(lx/16)*16+16][floor(lz/16)*16]
						local bottom = not area[floor(lx/16)*16][floor(lz/16)*16+16]
						if right or bottom then
							-- fill the edges of the 16 elmo grid
							segment[n].point[m] = {x = lx+8, z = lz+8}
							local currHeight = spGetGroundHeight(segment[n].point[m].x, segment[n].point[m].z)
							segment[n].point[m].orHeight = currHeight
							if checkPointCreation(terraform_type, volumeSelection, currHeight, terraformHeight,spGetGroundOrigHeight(segment[n].point[m].x, segment[n].point[m].z)) then
								m = m + 1
								totalX = totalX + lx + 8
								totalZ = totalZ + lz + 8
							end
							if segment[n].border.left > lx + 8 then	
								segment[n].border.left = lx + 8
							end
							if segment[n].border.right < lx + 8 then	
								segment[n].border.right = lx + 8
							end
							if segment[n].border.top > lz + 8 then	
								segment[n].border.top = lz + 8
							end
							if segment[n].border.bottom < lz + 8 then	
								segment[n].border.bottom = lz + 8
							end
							if right then
								segment[n].point[m] = {x = lx+8, z = lz}
								local currHeight = spGetGroundHeight(segment[n].point[m].x, segment[n].point[m].z)
								segment[n].point[m].orHeight = currHeight
								if checkPointCreation(terraform_type, volumeSelection, currHeight, terraformHeight,spGetGroundOrigHeight(segment[n].point[m].x, segment[n].point[m].z)) then
									m = m + 1
									totalX = totalX + lx + 8
									totalZ = totalZ + lz
								end
							end
							if bottom then
								segment[n].point[m] = {x = lx, z = lz+8}
								local currHeight = spGetGroundHeight(segment[n].point[m].x, segment[n].point[m].z)
								segment[n].point[m].orHeight = currHeight
								if checkPointCreation(terraform_type, volumeSelection, currHeight, terraformHeight,spGetGroundOrigHeight(segment[n].point[m].x, segment[n].point[m].z)) then
									m = m + 1
									totalX = totalX + lx + 8
									totalZ = totalZ + lz
								end
							end
						end
						
						segment[n].point[m] = {x = lx, z = lz}
						local currHeight = spGetGroundHeight(segment[n].point[m].x, segment[n].point[m].z)
						segment[n].point[m].orHeight = currHeight
						if checkPointCreation(terraform_type, volumeSelection, currHeight, terraformHeight,spGetGroundOrigHeight(segment[n].point[m].x, segment[n].point[m].z)) then
							m = m + 1
							totalX = totalX + lx
							totalZ = totalZ + lz
						end
						
						-- update segment border. used when forcing repath
						if segment[n].border.left > lx then	
							segment[n].border.left = lx
						end
						if segment[n].border.right < lx then	
							segment[n].border.right = lx
						end
						if segment[n].border.top > lz then	
							segment[n].border.top = lz
						end
						if segment[n].border.bottom < lz then	
							segment[n].border.bottom = lz
						end
					end
				end
				
			end
			addZ = 8
			-- if there are no points in the segment the segment is discarded
			if m ~= 1 then
				segment[n].points = m - 1
				segment[n].position = {x = totalX/(m-1), z = totalZ/(m-1)}				
				n = n + 1
			end
		end
		addX = 8
	end
	
	--** Detect potentially overlapping buildings**
	
	local localStructure = {}
	local localStructureCount = 0
	
	for i = 1, structureCount do
		local s = structure[structureTable[i]]
		if (border.left < s.maxx and 
			border.right > s.minx and
			border.top < s.maxz and
			border.bottom > s.minz) then
				
			localStructureCount = localStructureCount + 1
			localStructure[localStructureCount] = i
		end	
	end
	
	--** Creates terraform building and assigns each one segment data **
	
	local block = {}
	local blocks = 0
	
	terraformOrders = terraformOrders + 1
	terraformOrder[terraformOrders] = {border = border, index = {}, indexes = 0}

	for i = 1,n-1 do
	
		-- detect overlapping buildings
		
		segment[i].structure = {}
		segment[i].structureCount = 0
		segment[i].structureArea = {}
		
		for j = 1, localStructureCount do
			local s = structure[structureTable[localStructure[j]]]
			if (segment[i].border.left < s.maxx and 
				segment[i].border.right > s.minx and
				segment[i].border.top < s.maxz and
				segment[i].border.bottom > s.minz) then
				
				segment[i].structureCount = segment[i].structureCount + 1
				segment[i].structure[segment[i].structureCount] = {id = s}
				
				s.checkAtDeath = true
				
				for lx = s.minx, s.maxx, 8 do
					if not segment[i].structureArea[lx] then
						segment[i].structureArea[lx] = {}
					end
					for lz = s.minz,s.maxz, 8 do
						segment[i].structureArea[lx][lz] = true
					end
				end 
				
			end	
		end
		
		--calculate cost of terraform
		local totalCost = 0
		if terraform_type == 1 then
			for j = 1, segment[i].points do
				if not segment[i].area[segment[i].point[j].x] then
					segment[i].area[segment[i].point[j].x] = {}
				end
				local currHeight = segment[i].point[j].orHeight
				segment[i].point[j].aimHeight = terraformHeight
				if segment[i].structureArea[segment[i].point[j].x] and segment[i].structureArea[segment[i].point[j].x][segment[i].point[j].z] then
					segment[i].point[j].diffHeight = 0.0001
					segment[i].point[j].structure = true
					--segment[i].area[segment[i].point[j].x][segment[i].point[j].z] = {orHeight = segment[i].point[j].orHeight,diffHeight = segment[i].point[j].diffHeight, building = true}
				else
					segment[i].point[j].diffHeight = segment[i].point[j].aimHeight-currHeight
					segment[i].area[segment[i].point[j].x][segment[i].point[j].z] = {orHeight = segment[i].point[j].orHeight,diffHeight = segment[i].point[j].diffHeight, building = false}
				end
				totalCost = totalCost + abs(segment[i].point[j].diffHeight)
			end
		elseif terraform_type == 2 then 
			for j = 1, segment[i].points do
				if not segment[i].area[segment[i].point[j].x] then
					segment[i].area[segment[i].point[j].x] = {}
				end
				local currHeight = segment[i].point[j].orHeight
				segment[i].point[j].aimHeight = terraformHeight+currHeight
				if segment[i].structureArea[segment[i].point[j].x] and segment[i].structureArea[segment[i].point[j].x][segment[i].point[j].z] then
					segment[i].point[j].diffHeight = 0.0001
					segment[i].point[j].structure = true
					--segment[i].area[segment[i].point[j].x][segment[i].point[j].z] = {orHeight = segment[i].point[j].orHeight,diffHeight = segment[i].point[j].diffHeight, building = true}
				else
					segment[i].point[j].diffHeight = terraformHeight
					segment[i].area[segment[i].point[j].x][segment[i].point[j].z] = {orHeight = segment[i].point[j].orHeight,diffHeight = segment[i].point[j].diffHeight, building = false}
				end
				totalCost = totalCost + abs(terraformHeight)
			end
		elseif terraform_type == 3 then 
			for j = 1, segment[i].points do
				local totalHeight = 0
				for lx = -16, 16,8 do
					for lz = -16, 16,8 do
						totalHeight = totalHeight + spGetGroundHeight(segment[i].point[j].x+lx, segment[i].point[j].z+lz)
					end
				end
				if not segment[i].area[segment[i].point[j].x] then
					segment[i].area[segment[i].point[j].x] = {}
				end
				local currHeight = segment[i].point[j].orHeight
				segment[i].point[j].aimHeight = totalHeight/25
				if segment[i].structureArea[segment[i].point[j].x] and segment[i].structureArea[segment[i].point[j].x][segment[i].point[j].z] then
					segment[i].point[j].diffHeight = 0.0001
					segment[i].point[j].structure = true
					--segment[i].area[segment[i].point[j].x][segment[i].point[j].z] = {orHeight = segment[i].point[j].orHeight,diffHeight = segment[i].point[j].diffHeight, building = true}
				else
					segment[i].point[j].diffHeight = segment[i].point[j].aimHeight-currHeight
					segment[i].area[segment[i].point[j].x][segment[i].point[j].z] = {orHeight = segment[i].point[j].orHeight,diffHeight = segment[i].point[j].diffHeight, building = false}
				end
				totalCost = totalCost + abs(segment[i].point[j].diffHeight)
			end
		elseif terraform_type == 5 then 
			for j = 1, segment[i].points do
				if not segment[i].area[segment[i].point[j].x] then
					segment[i].area[segment[i].point[j].x] = {}
				end
				local currHeight = segment[i].point[j].orHeight
				segment[i].point[j].aimHeight = spGetGroundOrigHeight(segment[i].point[j].x, segment[i].point[j].z)
				if segment[i].structureArea[segment[i].point[j].x] and segment[i].structureArea[segment[i].point[j].x][segment[i].point[j].z] then
					segment[i].point[j].diffHeight = 0.0001
					segment[i].point[j].structure = true
					--segment[i].area[segment[i].point[j].x][segment[i].point[j].z] = {orHeight = segment[i].point[j].orHeight,diffHeight = segment[i].point[j].diffHeight, building = true}
				else
					segment[i].point[j].diffHeight = segment[i].point[j].aimHeight-currHeight
					segment[i].area[segment[i].point[j].x][segment[i].point[j].z] = {orHeight = segment[i].point[j].orHeight,diffHeight = segment[i].point[j].diffHeight, building = false}
				end
				totalCost = totalCost + abs(segment[i].point[j].diffHeight)
				
			end
		end
		
		if totalCost ~= 0 then
			totalCost = totalCost*costMult
		
			local id = spCreateUnit(terraunitDefID, segment[i].position.x, 0, segment[i].position.z, 0, team, true)
			if id then
				local allyTeamList = spGetAllyTeamList()
				local _,_,_,_,_,unitAllyTeam = spGetTeamInfo(team)
				for _,allyID in ipairs (allyTeamList) do
					if allyID ~= unitAllyTeam then
						spSetUnitLosMask(id, allyID, {los=true, radar=true, prevLos=true, contRadar=true } )
					end
				end
			
				spSetUnitSensorRadius(id,"los",0)
				spSetUnitSensorRadius(id,"airLos",0)
				spSetUnitHealth(id, {
					health = 0,
					build  = 0
				})
			
				blocks = blocks + 1
				block[blocks] = id
				
				terraformUnitCount = terraformUnitCount + 1
				terraformOrder[terraformOrders].indexes = terraformOrder[terraformOrders].indexes + 1

				terraformUnit[id] = {
					position = segment[i].position, 
					progress = 0, 
					lastUpdate = 0, 
					totalSpent = 0,
					baseCostSpent = 0,
					cost = totalCost, 
					baseCost = segment[i].points*pointBaseCost,
					totalCost = totalCost + segment[i].points*pointBaseCost,
					point = segment[i].point, 
					points = segment[i].points,
					area = segment[i].area, 
					border = segment[i].border, 
					smooth = false, 
					intercepts = 0, 
					intercept = {}, 
					interceptMap = {},
					decayTime = terraformDecayFrames, 
					allyTeam = unitAllyTeam,
					team = team,
					order = terraformOrders,
					orderIndex = terraformOrder[terraformOrders].indexes,
					fullyInitialised = false,
					lastProgress = 0,
					lastHealth = 0,
				}
			
				terraformUnitTable[terraformUnitCount] = id
				terraformOrder[terraformOrders].index[terraformOrder[terraformOrders].indexes] = terraformUnitCount
			end
		end
		
	end
	
	--** Give repair order for each block to all selected units **
	
	for i = 1, units do
	
		if (spValidUnitID(unit[i])) then
			if not shift then
				spGiveOrderToUnit(unit[i],CMD_STOP,{},{})
			end
			
			for j = 1, blocks do
				spGiveOrderToUnit(unit[i],CMD_REPAIR,{block[j]},CMD_OPT_SHIFT)
			end
		end
	end
	
	
end

--------------------------------------------------------------------------------
-- Recieve Terraform command from UI widget
--------------------------------------------------------------------------------

function gadget:AllowCommand(unitID, unitDefID, teamID,cmdID, cmdParams, cmdOptions)

  if (cmdID == CMD_TERRAFORM_INTERNAL) then

		local terraform_type = cmdParams[1]
		if terraform_type == 1 or terraform_type == 2 or terraform_type == 3 or terraform_type == 5 then --level or raise or smooth or restore
			local point = {}
			local unit = {}
			local i = 8
			for j = 1, cmdParams[5] do
				point[j] = {x = cmdParams[i], z = cmdParams[i+1]}
				i = i + 2
			end
			for j = 1, cmdParams[6] do
				unit[j] = cmdParams[i]
				i = i + 1
			end
			
			if cmdParams[3] == 0 then
				TerraformWall(terraform_type, point, cmdParams[5], cmdParams[4], unit, cmdParams[6], cmdParams[2], cmdParams[7], cmdOptions.shift)
			else
				TerraformArea(terraform_type, point, cmdParams[5], cmdParams[4], unit, cmdParams[6], cmdParams[2], cmdParams[7], cmdOptions.shift)
			end
			
			return false

		elseif terraform_type == 4 then --ramp
		
			local point = {}
			local unit = {}
			local i = 8
			for j = 1, cmdParams[5] do
				point[j] = {x = cmdParams[i], y = cmdParams[i+1],z = cmdParams[i+2]}
				i = i + 3
			end
			for j = 1, cmdParams[6] do
				unit[j] = cmdParams[i]
				i = i + 1
			end
			
			TerraformRamp(point[1].x,point[1].y,point[1].z,point[2].x,point[2].y,point[2].z,cmdParams[4]*2,unit, cmdParams[6],cmdParams[2], cmdParams[7], cmdOptions.shift)
		
			return false
			
		end
  
  end
  return true -- allowed
end

--------------------------------------------------------------------------------
-- Sudden Death Mode
--------------------------------------------------------------------------------

local function RaiseWater( raiseAmount)
	
	for i = 1, structureCount do
		local s = structure[structureTable[i]]
		s.h = s.h - raiseAmount
	end
	
	for i = 1, terraformUnitCount do
		local id = terraformUnitTable[i] 
		for j = 1, terraformUnit[id].points do
			local point = terraformUnit[id].point[j]
			point.orHeight = point.orHeight - raiseAmount
			point.aimHeight = point.aimHeight - raiseAmount
		end
	end
	--[[ move commands looks as though it will be messy
	
	
	local allUnits = spGetAllUnits()
	local allUnitsCount = #allUnits
	for i = 1, allUnitsCount do
		if spValidUnitID(allUnits[i]) then
			local x,y,z = spGetUnitPosition(allUnits[i])
			spSetUnitPosition(x,y-raiseAmount,z)
			local commands = spGetUnitCommands(allUnits[i])
			local commandsCount = #commands
			for j = 1, commandsCount do
			
			end
		end
	end
	--]]
	spAdjustHeightMap(0, 0, mapWidth, mapHeight, -raiseAmount)
	
end

--------------------------------------------------------------------------------
-- Handle terraunit
--------------------------------------------------------------------------------

local function deregisterTerraformUnit(id,terraformIndex,origin)
	
	if not terraformUnit[id] then
		Spring.Echo("Terraform:")
		Spring.Echo("Attempted to remove nil terraform ID")
		Spring.Echo("Error Tpye " .. origin)
		Spring.Echo("Tell Google Frog")
		return
	end
	
	if not terraformUnit[id].intercepts then
		Spring.Echo("Terraform:")
		Spring.Echo("Attempted to index terraformUnit with wrong id")
		Spring.Echo("Tell Google Frog")
		return
	end
	--Spring.MarkerAddPoint(terraformUnit[id].position.x,0,terraformUnit[id].position.z,"Cost " .. math.floor(terraformUnit[id].totalSpent))

	
	-- remove from intercepts tables
	for j = 1, terraformUnit[id].intercepts do -- CRASH ON THIS LINE -- not for a while though
		local oid = terraformUnit[id].intercept[j].id
		local oindex = terraformUnit[id].intercept[j].index
		if oindex < terraformUnit[oid].intercepts then
			terraformUnit[terraformUnit[oid].intercept[terraformUnit[oid].intercepts].id].intercept[terraformUnit[oid].intercept[terraformUnit[oid].intercepts].index].index = oindex
			terraformUnit[oid].intercept[oindex] = terraformUnit[oid].intercept[terraformUnit[oid].intercepts]
		end
		terraformUnit[oid].intercept[terraformUnit[oid].intercepts] = nil
		terraformUnit[oid].intercepts = terraformUnit[oid].intercepts - 1
		terraformUnit[oid].interceptMap[id] = nil
	end
		
	-- remove from order table
	local to = terraformOrder[terraformUnit[id].order]
	if terraformUnit[id].orderIndex ~= to.indexes then
		to.index[terraformUnit[id].orderIndex] = to.index[to.indexes]
		terraformUnit[terraformUnitTable[to.index[to.indexes]]].orderIndex = terraformUnit[id].orderIndex
	end
	to.indexes = to.indexes - 1
	
	-- remove order table if it is now emty
	if to.indexes < 1 then
		if terraformOrders ~= terraformUnit[id].order then
			terraformOrder[terraformUnit[id].order] = terraformOrder[terraformOrders]
			for i = 1, terraformOrder[terraformOrders].indexes do
				terraformUnit[terraformUnitTable[terraformOrder[terraformOrders].index[i]]].order = terraformUnit[id].order
			end
		end
		terraformOrders = terraformOrders - 1
	end
	
	-- remove from terraform table
	terraformUnit[id] = nil
	if terraformIndex ~= terraformUnitCount then
		terraformUnitTable[terraformIndex] = terraformUnitTable[terraformUnitCount]
		local t = terraformUnit[terraformUnitTable[terraformUnitCount]]
		terraformOrder[t.order].index[t.orderIndex] = terraformIndex
	end
	terraformUnitCount = terraformUnitCount - 1

end

local function updateTerraformEdgePoints(id)

	for i = 1, terraformUnit[id].points do
		local point = terraformUnit[id].point[i]
		
		if point.structure then
			point.edges = nil
		else
			local x = point.x
			local z = point.z

			local area = terraformUnit[id].area		
			local edges = 0
			local edge = {}
			
			local spots = {top = false, bot = false, left = false, right = false}
			
			if (not area[x-8]) or (not area[x-8][z]) then
				spots.left = true
			end
			if (not area[x+8]) or (not area[x+8][z]) then
				spots.right = true
			end
			if not area[x][z-8] then
				spots.top = true
			end
			if not area[x][z+8] then
				spots.bot = true
			end
			
			if spots.left then
				edges = edges + 1
				edge[edges] = {x = x-8, z = z, check = {count = 1, pos = {[1] = {x = -8, z = 0}, } } }
				if spots.top then
					edge[edges].check.count = edge[edges].check.count + 1
					edge[edges].check.pos[edge[edges].check.count] = {x = 0, z = -8}
				end
				if spots.bot then
					edge[edges].check.count = edge[edges].check.count + 1
					edge[edges].check.pos[edge[edges].check.count] = {x = 0, z = 8}
				end
			end
			
			if spots.right then
				edges = edges + 1
				edge[edges] = {x = x+8, z = z, check = {count = 1, pos = {[1] = {x = 8, z = 0}, } } }
				if spots.top then
					edge[edges].check.count = edge[edges].check.count + 1
					edge[edges].check.pos[edge[edges].check.count] = {x = 0, z = -8}
				end
				if spots.bot then
					edge[edges].check.count = edge[edges].check.count + 1
					edge[edges].check.pos[edge[edges].check.count] = {x = 0, z = 8}
				end
			end
			
			if spots.top then
				edges = edges + 1
				edge[edges] = {x = x, z = z-8, check = {count = 1, pos = {[1] = {x = 0, z = -8}, } } }
				if spots.left then
					edge[edges].check.count = edge[edges].check.count + 1
					edge[edges].check.pos[edge[edges].check.count] = {x = -8, z = 0}
				end
				if spots.right then
					edge[edges].check.count = edge[edges].check.count + 1
					edge[edges].check.pos[edge[edges].check.count] = {x = 8, z = 0}
				end
			end
			
			if spots.bot then
				edges = edges + 1
				edge[edges] = {x = x, z = z+8, check = {count = 1, pos = {[1] = {x = 0, z = 8}, } } }
				if spots.left then
					edge[edges].check.count = edge[edges].check.count + 1
					edge[edges].check.pos[edge[edges].check.count] = {x = -8, z = 0}
				end
				if spots.right then
					edge[edges].check.count = edge[edges].check.count + 1
					edge[edges].check.pos[edge[edges].check.count] = {x = 8, z = 0}
				end
			end
			
			if edges ~= 0 then
				point.edges = edges
				point.edge = edge
			else
				point.edges = nil
			end
		end
		
	end

end

local function updateTerraformCost(id)

	local totalCost = 0
	for i = 1, terraformUnit[id].points do
		local point = terraformUnit[id].point[i]
		local x = point.x
		local z = point.z

		local height = spGetGroundHeight(x,z)
		point.orHeight = height
		if point.structure == 1 then
			point.diffHeight = 0
		elseif point.structure then
			point.diffHeight = 0.0001
		else
			point.diffHeight = point.aimHeight - height 
		end
		totalCost = totalCost + abs(point.diffHeight) 
	end
	
	spSetUnitHealth(id, {
		health = 0,
		build  = 0
	})
	
	if totalCost == 0 then
		totalCost = 0.01
		-- deregistering here causes crash bug
	end

	terraformUnit[id].lastProgress = 0
	terraformUnit[id].lastHealth = 0
	terraformUnit[id].progress = 0
	terraformUnit[id].cost = totalCost*costMult
	terraformUnit[id].totalCost = terraformUnit[id].cost + terraformUnit[id].baseCost
	
	return true
	
end


local function checkTerraformIntercepts(id)

	for i = 1, terraformOrders do
		--Spring.MarkerAddLine(terraformOrder[i].border.left,0,terraformOrder[i].border.top,terraformOrder[i].border.right,0,terraformOrder[i].border.top)
		--Spring.MarkerAddLine(terraformOrder[i].border.left,0,terraformOrder[i].border.bottom,terraformOrder[i].border.right,0,terraformOrder[i].border.bottom)
		--Spring.MarkerAddLine(terraformOrder[i].border.left,0,terraformOrder[i].border.top,terraformOrder[i].border.left,0,terraformOrder[i].border.bottom)
		--Spring.MarkerAddLine(terraformOrder[i].border.right,0,terraformOrder[i].border.top,terraformOrder[i].border.right,0,terraformOrder[i].border.bottom)
		if (terraformOrder[i].border.left <= terraformOrder[terraformUnit[id].order].border.right and 
			terraformOrder[i].border.right >= terraformOrder[terraformUnit[id].order].border.left and
			terraformOrder[i].border.top <= terraformOrder[terraformUnit[id].order].border.bottom and
			terraformOrder[i].border.bottom >= terraformOrder[terraformUnit[id].order].border.top) then
			
			for j = 1, terraformOrder[i].indexes do
				local oid = terraformUnitTable[terraformOrder[i].index[j]] 
				if oid ~= id and not terraformUnit[id].interceptMap[oid] and terraformUnit[oid].fullyInitialised then
					if (terraformUnit[id].border.left <= terraformUnit[oid].border.right and 
						terraformUnit[id].border.right >= terraformUnit[oid].border.left and
						terraformUnit[id].border.top <= terraformUnit[oid].border.bottom and
						terraformUnit[id].border.bottom >= terraformUnit[oid].border.top) then
						
						terraformUnit[oid].intercepts = terraformUnit[oid].intercepts + 1				
						terraformUnit[id].intercepts = terraformUnit[id].intercepts + 1
					
						terraformUnit[oid].intercept[terraformUnit[oid].intercepts] = {index = terraformUnit[id].intercepts, id = id}
						terraformUnit[id].intercept[terraformUnit[id].intercepts] = {index = terraformUnit[oid].intercepts, id = oid}
						
						terraformUnit[oid].interceptMap[id] = true
						terraformUnit[id].interceptMap[oid] = true
					end
				end
			end
		end
	end

end

local function updateTerraformBorder(id,x,z) -- updates border for edge point x,z
	
	local change = false
	
	if x < terraformUnit[id].border.left then
		terraformUnit[id].border.left = x
		change = true
	end
	if x > terraformUnit[id].border.right then
		terraformUnit[id].border.right = x
		change = true
	end
	if z < terraformUnit[id].border.top then
		terraformUnit[id].border.top = z
		change = true
	end
	if z > terraformUnit[id].border.bottom then
		terraformUnit[id].border.bottom = z
		change = true
	end
	
	if change then
		local border = terraformOrder[terraformUnit[id].order].border
		if x < border.left then
			border.left = x
		end
		if x > border.right then
			border.right = x
		end
		if z < border.top then
			border.top = z
		end
		if z > border.bottom then
			border.bottom = z
		end
		
		checkTerraformIntercepts(id)
	end

end

local function finishInitialisingTerraformUnit(id)
	
	checkTerraformIntercepts(id)
	
	updateTerraformEdgePoints(id)
	updateTerraformCost(id)
	
	terraformUnit[id].fullyInitialised = true

end

local function updateTerraform(diffProgress,health,id,arrayIndex,costDiff)
	
	local terra = terraformUnit[id]
	if terra.baseCostSpent then
		if costDiff < terra.baseCost-terra.baseCostSpent then
			terra.baseCostSpent = terra.baseCostSpent + costDiff
			
			local newBuild = terra.baseCostSpent/terra.totalCost
			spSetUnitHealth(id, {
				health = newBuild*terraUnitHP,
				build  = newBuild
			})
			terra.lastHealth = newBuild*terraUnitHP
			terra.lastProgress = newBuild
			return 1
		else
			costDiff = costDiff - (terra.baseCost-terra.baseCostSpent)
			terra.baseCostSpent = false
			--[[
			something pertaining to drawing would go here
			for i = 1, terra.points do
				local x = terra.point[i].x
				local z = terra.point[i].z
				if terra.area[x+8] and terra.area[x+8][z+8] then 
					if drawPosMap[x] and drawPosMap[x][z] then
						drawPositions.data[drawPosMap[x][z] ].r = 0.5
						drawPositions.data[drawPosMap[x][z] ].g = 0
						drawPositions.data[drawPosMap[x][z] ].b = 0
						drawPositions.data[drawPosMap[x][z] ].a = 0.5
					else
						drawPositions.count = drawPositions.count + 1
						drawPositions.data[drawPositions.count] = {x1 = x, z1 = z, x2 = x+8, z2 = z+8, r = 0.5, g = 0, b = 0, a = 0.5}
						drawPosMap[x] = drawPosMap[x] or {}
						drawPosMap[x][z] = drawPositions.count
					end
				end
			end--]]
		end
	end
	
	local newProgress = terra.progress + costDiff/terra.cost
	if newProgress> 1 then
		newProgress = 1
	end
	
	local addedCost = 0
	local extraPoint = {}
	local extraPoints = 0
	local extraPointArea = {}
	
	for i = 1, terra.points do
		if terra.point[i].edges then
			local newHeight = terra.point[i].orHeight+(terra.point[i].aimHeight-terra.point[i].orHeight)*newProgress
			for j = 1, terra.point[i].edges do
			
				local x = terra.point[i].edge[j].x
				local z = terra.point[i].edge[j].z
			
				local groundHeight = spGetGroundHeight(x, z)
				local edgeHeight = groundHeight
				local overlap = false
				local overlapCost = 0
				if extraPointArea[x] and extraPointArea[x][z] then
					overlap = extraPointArea[x][z]
					edgeHeight = extraPoint[overlap].orHeight + extraPoint[overlap].heightDiff 
					overlapCost = extraPoint[overlap].cost
				end

				local diffHeight = newHeight - edgeHeight
				if diffHeight > maxHeightDifference then
				
					local index = extraPoints + 1
					if overlap then
						if not extraPoint[overlap].pyramid then
							CallAsTeam(terra.team, function () return Spring.MarkerAddPoint(terra.position.x,0,terra.position.z,"Terraform cancelled due to steepness") end)
							deregisterTerraformUnit(id,arrayIndex,2)			
							spDestroyUnit(id,{reclaimed = true})
							return 0
						end
						index = overlap
					else
						extraPoints = extraPoints + 1
					end

					extraPoint[index] = {
						x = x, z = z, 
						orHeight = groundHeight, 
						heightDiff = newHeight - maxHeightDifference - groundHeight, 
						cost = (newHeight - maxHeightDifference - groundHeight), 
						supportX = terra.point[i].x, 
						supportZ = terra.point[i].z, 
						supportH = newHeight,
						supportID = i,
						check = terra.point[i].edge[j].check,
						pyramid = true, -- pyramid = rising up, not pyramid = ditch
					}
					updateTerraformBorder(id,x,z)
					
					if structureAreaMap[x] and structureAreaMap[x][z] then
						if terra.area[terra.point[i].x] and terra.area[terra.point[i].x][terra.point[i].z] then
							terra.area[terra.point[i].x][terra.point[i].z] = nil
						end
						terra.point[i].diffHeight = 0.0001
						terra.point[i].structure = 1
						return -1
					end
						
					addedCost = addedCost + extraPoint[index].cost - overlapCost
					
					if not extraPointArea[x] then
						extraPointArea[x] = {}
					end
					extraPointArea[x][z] = index

				elseif diffHeight < -maxHeightDifference then
					
					local index = extraPoints + 1
					if overlap then
						if extraPoint[overlap].pyramid then
							CallAsTeam(terra.team, function () return Spring.MarkerAddPoint(terra.position.x,0,terra.position.z,"Terraform cancelled due to steepness") end)
							deregisterTerraformUnit(id,arrayIndex,2)			
							spDestroyUnit(id,{reclaimed = true})
							return 0
						end
						index = overlap
					else
						extraPoints = extraPoints + 1
					end
					
					extraPoint[index] = {
						x = x, 
						z = z, 
						orHeight = groundHeight, 
						heightDiff = newHeight + maxHeightDifference - groundHeight, 
						cost = -(newHeight + maxHeightDifference - groundHeight), 
						supportX = terra.point[i].x, 
						supportZ = terra.point[i].z, 
						supportH = newHeight,
						supportID = i,
						check = terra.point[i].edge[j].check,
						pyramid = false, -- pyramid = rising up, not pyramid = ditch
					}
					updateTerraformBorder(id,x,z)
					
					if structureAreaMap[x] and structureAreaMap[x][z] then
						if terra.area[terra.point[i].x] and terra.area[terra.point[i].x][terra.point[i].z] then
							terra.area[terra.point[i].x][terra.point[i].z] = nil
						end
						terra.point[i].diffHeight = 0.0001
						terra.point[i].structure = 1
						return -1
					end
					
					addedCost = addedCost + extraPoint[index].cost - overlapCost
					
					if not extraPointArea[x] then
						extraPointArea[x] = {}
					end
					extraPointArea[x][z] = index

				end
				
			end
		end
	end
	
	local i = 1
	while i <= extraPoints do
		local newHeight = extraPoint[i].supportH
		-- diamond pyramids
		--local maxHeightDifferenceLocal = (abs(extraPoint[i].x-extraPoint[i].supportX) + abs(extraPoint[i].z-extraPoint[i].supportZ))*maxHeightDifference/8+maxHeightDifference
		-- circular pyramids
		local maxHeightDifferenceLocal = math.sqrt((extraPoint[i].x-extraPoint[i].supportX)^2 + (extraPoint[i].z-extraPoint[i].supportZ)^2)*maxHeightDifference/8+maxHeightDifference 
		for j = 1, extraPoint[i].check.count do
			local x = extraPoint[i].check.pos[j].x + extraPoint[i].x
			local z = extraPoint[i].check.pos[j].z + extraPoint[i].z
			--and not (extraPointArea[x] and extraPointArea[x][z])
			if not (terra.area[x] and terra.area[x][z]) then

				local groundHeight = spGetGroundHeight(x, z)
				local edgeHeight = groundHeight
				local overlap = false
				local overlapCost = 0
				if extraPointArea[x] and extraPointArea[x][z] then
					overlap = extraPointArea[x][z]
					edgeHeight = extraPoint[overlap].orHeight + extraPoint[overlap].heightDiff 
					overlapCost = extraPoint[overlap].cost
				end

				local diffHeight = newHeight - edgeHeight
				if diffHeight > maxHeightDifferenceLocal then
					local index = extraPoints + 1
					if overlap then
						if not extraPoint[overlap].pyramid then
							CallAsTeam(terra.team, function () return Spring.MarkerAddPoint(terra.position.x,0,terra.position.z,"Terraform cancelled due to steepness") end)
							deregisterTerraformUnit(id,arrayIndex,2)			
							spDestroyUnit(id,{reclaimed = true})
							return 0
						end
						index = overlap
					else
						extraPoints = extraPoints + 1
					end
					extraPoint[index] = {
						x = x, 
						z = z, 
						orHeight = groundHeight, 
						heightDiff = newHeight - maxHeightDifferenceLocal - groundHeight, 
						cost = (newHeight - maxHeightDifferenceLocal - groundHeight), 
						supportX = extraPoint[i].supportX, 
						supportZ = extraPoint[i].supportZ, 
						supportH = extraPoint[i].supportH,
						supportID = extraPoint[i].supportID,
						check =  extraPoint[i].check,
						pyramid = true, -- pyramid = rising up, not pyramid = ditch
					}
					updateTerraformBorder(id,x,z)
					
					if structureAreaMap[x] and structureAreaMap[x][z] then
						if terra.area[extraPoint[index].supportX] and terra.area[extraPoint[index].supportX][extraPoint[index].supportZ] then
							terra.area[extraPoint[index].supportX][extraPoint[index].supportZ] = nil
						end
						terra.point[extraPoint[i].supportID].diffHeight = 0.0001
						terra.point[extraPoint[i].supportID].structure = 1
						return -1
					end
					
					addedCost = addedCost + extraPoint[index].cost - overlapCost
					
					if not extraPointArea[x] then
						extraPointArea[x] = {}
					end
					extraPointArea[x][z] = index

				elseif diffHeight < -maxHeightDifferenceLocal then
					local index = extraPoints + 1
					if overlap then
						if extraPoint[overlap].pyramid then
							CallAsTeam(terra.team, function () return Spring.MarkerAddPoint(terra.position.x,0,terra.position.z,"Terraform cancelled due to steepness") end)
							deregisterTerraformUnit(id,index,2)			
							spDestroyUnit(id,{reclaimed = true})
							return 0
						end
						index = overlap
					else
						extraPoints = extraPoints + 1
					end
					extraPoint[index] = {
						x = x, 
						z = z, 
						orHeight = groundHeight, 
						heightDiff = newHeight + maxHeightDifferenceLocal - groundHeight,						
						cost = -(newHeight + maxHeightDifferenceLocal - groundHeight), 
						supportX = extraPoint[i].supportX, 
						supportZ = extraPoint[i].supportZ, 
						supportH = extraPoint[i].supportH,
						supportID = extraPoint[i].supportID,
						check =  extraPoint[i].check,
						pyramid = false, -- pyramid = rising up, not pyramid = ditch
					}
					updateTerraformBorder(id,x,z)
					
					if structureAreaMap[x] and structureAreaMap[x][z] then
						if terra.area[extraPoint[index].supportX] and terra.area[extraPoint[index].supportX][extraPoint[index].supportZ] then
							terra.area[extraPoint[index].supportX][extraPoint[index].supportZ] = nil
						end
						terra.point[extraPoint[i].supportID].diffHeight = 0.0001
						terra.point[extraPoint[i].supportID].structure = 1
						return -1
					end
						
					addedCost = addedCost + extraPoint[index].cost - overlapCost
						
					if not extraPointArea[x] then
						extraPointArea[x] = {}
					end
					extraPointArea[x][z] = index
				
				end
			end
		end
		
		if extraPoints > 9000 then
			Spring.Echo("spire wall break")
			break -- safty
		end
		i = i + 1
	end
	
	local oldCostDiff = costDiff
	
	local edgeTerraMult = 1
	if costDiff ~= 0 then
		if addedCost == 0 then
			terra.progress = terra.progress + costDiff/terra.cost
		else
			local extraCost = 0
			
			if terra.progress + costDiff/terra.cost > 1 then
				extraCost = costDiff - terra.cost*(1 - terra.progress)
				costDiff = (1 - terra.progress)*terra.cost
			end
				
			addedCost = addedCost*costMult
			
			local edgeTerraCost = (costDiff*addedCost/(costDiff+addedCost))
			terra.progress = terra.progress + (costDiff-edgeTerraCost)/terra.cost
			edgeTerraMult = edgeTerraCost/addedCost
			if extraCost > 0 then
				
				edgeTerraCost = edgeTerraCost + extraCost
				
				if edgeTerraCost > addedCost then
					terra.progress = terra.progress + (edgeTerraCost - addedCost)/terra.cost
					edgeTerraMult = 1
				else
					edgeTerraMult = edgeTerraCost/addedCost
				end

			end
			
		end
	end
	
	if edgeTerraMult > 1 then
		Spring.Echo("Terraform:")
		Spring.Echo("edgeTerraMult > 1 THIS IS VERY BAD")
		Spring.Echo("Tell Google Frog")
	end
	
	local progress = terra.progress
	if terra.progress > 1 then
		progress = 1
		edgeTerraMult = 1
	end

	local newBuild = (terra.progress*terra.cost+terra.baseCost)/terra.totalCost
	
	spSetUnitHealth(id, {
		health = newBuild*terraUnitHP,
		build  = newBuild
	})
	
	terra.lastHealth = newBuild*terraUnitHP
	terra.lastProgress = newBuild

	-- Bug Safety
	for i = 1, extraPoints do
		if math.abs(extraPoint[i].orHeight + extraPoint[i].heightDiff*edgeTerraMult) > 3000 then
			Spring.Echo("Terraform:")
			Spring.Echo("Strange pyramid construction")
			Spring.Echo("Destroying Terraform Unit")
			deregisterTerraformUnit(id,arrayIndex,2)			
			spDestroyUnit(id,{reclaimed = true})
			return 0
		end
	end
	
	local test2 = 0
	local test3 = 0
	local func = function()
		for i = 1, terra.points do	
			test3 = test3 + abs(spGetGroundHeight(terra.point[i].x,terra.point[i].z)-(terra.point[i].orHeight+terra.point[i].diffHeight*progress))
			spSetHeightMap(terra.point[i].x,terra.point[i].z,terra.point[i].orHeight+terra.point[i].diffHeight*progress)
		end 
		for i = 1, extraPoints do
			test2 = test2 + abs(spGetGroundHeight(extraPoint[i].x,extraPoint[i].z)-(extraPoint[i].orHeight + extraPoint[i].heightDiff*edgeTerraMult))
			spSetHeightMap(extraPoint[i].x,extraPoint[i].z,extraPoint[i].orHeight + extraPoint[i].heightDiff*edgeTerraMult)
		end
	end
	spSetHeightMapFunc(func)
--[[
	Spring.Echo("costDiff " .. oldCostDiff)
	Spring.Echo("actual edge cost " .. test2*costMult)
	Spring.Echo("actual terra cost " .. test3*costMult)
--]]
	--spAdjustHeightMap(terra.border.left-16, terra.border.top-16, terra.border.right+16, terra.border.bottom+16, 0)
	if terraformUnit[id].intercepts ~= 0 then
		local i = 1
		while i <= terra.intercepts  do
			local test = updateTerraformCost(terra.intercept[i].id)
			if test then
				i = i + 1
			end
		end
	end
	
	if terra.progress > 1 then
		deregisterTerraformUnit(id,arrayIndex,2)			
		spDestroyUnit(id,{reclaimed = true})
		return 0
	end
	
	return 1
	
end

function gadget:GameFrame(n)
	
	--if n % 300 == 0 then
	--	RaiseWater(-20)
	--end
	
	local i = 1
	while i <= terraformUnitCount do
		local id = terraformUnitTable[i]
		if (spValidUnitID(id)) then
		
			local health,_,_,_,build  = spGetUnitHealth(id)
			local diffProgress = health/terraUnitHP - terraformUnit[id].progress
			
			if diffProgress == 0 then
			
				if n % decayCheckFrequency == 0 then
					if terraformUnit[id].decayTime < decayCheckFrequency then
						
						deregisterTerraformUnit(id,i,3)
						
						spDestroyUnit(id,{reclaimed = true})
					
					else
						terraformUnit[id].decayTime = terraformUnit[id].decayTime - decayCheckFrequency
						i = i + 1
					end
				else
					i = i + 1
				end
			else
			
				if not terraformUnit[id].fullyInitialised then
					finishInitialisingTerraformUnit(id,i)
					diffProgress = health/terraUnitHP - terraformUnit[id].progress
				end
				
				if n - terraformUnit[id].lastUpdate > updateFrequency then
					local costDiff = health - terraformUnit[id].lastHealth
					terraformUnit[id].totalSpent = terraformUnit[id].totalSpent + costDiff
					spSetUnitTooltip(id, terraUnitTooltip .. terraformUnit[id].totalSpent)
					local updateVar = updateTerraform(diffProgress,health,id,i,costDiff) 
					while updateVar == -1 do
						if updateTerraformCost(id) then
							updateTerraformEdgePoints(id)
							updateVar = updateTerraform(diffProgress,health,id,i,costDiff) 
						else
							updateVar = 0
						end
					end
					
					if updateVar == 1 then
						terraformUnit[id].lastUpdate = n
						i = i + 1
					end
				else
					i = i + 1
				end
				
			end
			
		else
			-- remove if the unit is no longer valid
			deregisterTerraformUnit(id,i,4)
		end
		
	end
	
	--check constrcutors that are repairing terraform blocks
	if constructors ~= 0 then
		if n % checkInterval == 0 then
			-- only check 1 con per cycle
			currentCon = currentCon + 1
			if currentCon > constructors then
				currentCon = 1
			end
			local cQueue = spGetCommandQueue(constructorTable[currentCon])
			if cQueue then
				local ncq = #cQueue
				for i = 1, ncq do
					if cQueue[i].id == CMD_REPAIR then
						if #cQueue[i].params == 1 then
							-- target unit command
							if terraformUnit[cQueue[i].params[1]] then
								terraformUnit[cQueue[i].params[1]].decayTime = terraformDecayFrames
							end
						else
							-- area command
							local radSQ = cQueue[i].params[4]^2
							local cX, _, cZ = cQueue[i].params[1],cQueue[i].params[2],cQueue[i].params[3]
							if constructor[constructorTable[currentCon]] and constructor[constructorTable[currentCon]].allyTeam then
								local allyTeam = constructor[constructorTable[currentCon]].allyTeam 
								for j = 1, terraformUnitCount do
									local terra = terraformUnit[terraformUnitTable[j]]
									if terra.allyTeam == allyTeam then
										local disSQ = (terra.position.x - cX)^2 + (terra.position.z - cZ)^2
										if disSQ < radSQ then
											terra.decayTime = terraformDecayFrames
										end
									end
								end
							end
						end
					end
				end
			end
		end
	end
	
	--check structures for terrain deformation
	local struc = structureCheckFrame[n % structureCheckLoopFrames]
	if struc then
		local i = 1
		while i <= struc.count do
			local unit = structure[struc.unit[i]]
			if unit then
				local height = spGetGroundHeight(unit.x, unit.z)
				if height ~= unit.h then
					Spring.LevelHeightMap(unit.minx,unit.minz,unit.maxx,unit.maxz,unit.h)
				end
			else
				
			end
			i = i + 1
		end
	end	
	
end

function gadget:UnitPreDamaged(unitID, unitDefID, unitTeam, damage, paralyzer, 
                            weaponID, attackerID, attackerDefID, attackerTeam)
							
	if unitDefID == terraunitDefID then
		return -0.0001 -- terraunit starts on 0 HP. If a unit is damaged and has 0 HP it dies
	end
	return damage
end

--------------------------------------------------------------------------------
-- Weapon Terraform
--------------------------------------------------------------------------------


local BBweapon = {}
local SeismicWeapon = {}

for i=1,#WeaponDefs do
	local wd = WeaponDefs[i]
	if (wd.description == "Heavy Plasma Cannon") then
		Script.SetWatchWeapon(wd.id,true)
		BBweapon[wd.id] = true
	elseif (wd.description == "Seismic") then
		Script.SetWatchWeapon(wd.id,true)
		SeismicWeapon[wd.id] = true
	end
end

local seismicPoints = 0
local seismicTerra = {}
local seismicRadSQ = seismicRad^2
local gravity = Game.gravity

for i = -seismicRad, seismicRad,8 do
	for j = -seismicRad, seismicRad,8 do
		if ((i^2 + j^2) < seismicRadSQ) then
			seismicPoints = seismicPoints + 1
			seismicTerra[seismicPoints] = {x = i, z = j}
		end
	end
end

function gadget:Explosion(weaponID, x, y, z, owner)
	
	if BBweapon[weaponID] then
	
		local radius = 96
		local radius2 = 64
		
		local area = {}
		local area2 = {}
		local radiusSQ = radius^2
		local radius2SQ = radius2^2
		local point = {}
		local points = 0
		
		local sx = floor((x+4)/8)*8
		local sz = floor((z+4)/8)*8
			
		for i = sx-radius-16, sx+radius+16,8 do
			area[i] = {}
			for j = sz-radius-16, sz+radius+16,8 do
				area[i][j] = spGetGroundHeight(i,j)
			end
		end
		
		for i = sx-radius2-16, sx+radius2+16,8 do
			area2[i] = {}
			for j = sz-radius2-16, sz+radius2+16,8 do
				area2[i][j] = (area[i][j]+area[i+8][j]+area[i][j+8]+area[i-8][j]+area[i][j-8]+area[i+8][j+8]+area[i+8][j-8]+area[i+8][j+8]+area[i-8][j+8]+area[i+16][j]+area[i][j+16]+area[i-16][j]+area[i][j-16])/13
			end
		end
		
		for i = sx-radius2-16, sx+radius2+16,8 do
			for j = sz-radius2-16, sz+radius2+16,8 do
				local disSQ = (i - x)^2 + (j - z)^2
				if disSQ <= radius2SQ then
					points = points + 1
					point[points] = {
						x = i, 
						y = (area2[i][j]+area2[i+8][j]+area2[i][j+8]+area2[i-8][j]+area2[i][j-8]+area2[i+8][j+8]+area2[i+8][j-8]+area2[i+8][j+8]+area2[i-8][j+8]+area2[i+16][j]+area2[i][j+16]+area2[i-16][j]+area2[i][j-16])/13,
						z = j
					}
				elseif disSQ <= radiusSQ then
					points = points + 1
					point[points] = {
						x = i, 
						y = area2[i][j],
						z = j
					}
				end
			end
		end
		
		local func = function()
				for i = 1, points do	
					spSetHeightMap(point[i].x,point[i].z,point[i].y)
				end   
			end
		spSetHeightMapFunc(func)
		
	elseif SeismicWeapon[weaponID] then
		-- SMOOTHING
		local radius = 512
		local radius2 = 448
		
		local area = {}
		local area2 = {}
		local radiusSQ = radius^2
		local radius2SQ = radius2^2
		local point = {}
		local points = 0
		
		local sx = floor((x+4)/8)*8
		local sz = floor((z+4)/8)*8
			
		for i = sx-radius-24, sx+radius+24,8 do
			area[i] = {}
			for j = sz-radius-24, sz+radius+24,8 do
				area[i][j] = spGetGroundHeight(i,j)
			end
		end
		
		for i = sx-radius2-24, sx+radius2+24,8 do
			area2[i] = {}
			for j = sz-radius2-24, sz+radius2+24,8 do
				area2[i][j] = (
					area[i-8][j-24]+area[i][j-24]+area[i+8][j-24]
					+area[i-16][j-16]+area[i-8][j-16]+area[i][j-16]+area[i+8][j-16]+area[i-16][j-16]
					+area[i-24][j-8]+area[i-16][j-8]+area[i-8][j-8]+area[i][j-8]+area[i+8][j-8]+area[i+16][j-8]+area[i+24][j-8]
					+area[i-24][j]+area[i-16][j]+area[i-8][j]+area[i][j]+area[i+8][j]+area[i+16][j]+area[i+24][j]
					+area[i-24][j+8]+area[i-16][j+8]+area[i-8][j+8]+area[i][j+8]+area[i+8][j+8]+area[i+16][j+8]+area[i+24][j+8]
					+area[i-16][j+16]+area[i-8][j+16]+area[i][j+16]+area[i+8][j+16]+area[i+16][j+16]
					+area[i-8][j+24]+area[i][j+24]+area[i+8][j+24]
				)/37
			end
		end
		
		for i = sx-radius2-24, sx+radius2+24,8 do
			for j = sz-radius2-24, sz+radius2+24,8 do
				local disSQ = (i - x)^2 + (j - z)^2
				if disSQ <= radius2SQ then
					points = points + 1
					point[points] = {
						x = i, 
						y = (
							area2[i-8][j-24]+area2[i][j-24]+area2[i+8][j-24]
							+area2[i-16][j-16]+area2[i-8][j-16]+area2[i][j-16]+area2[i+8][j-16]+area2[i-16][j-16]
							+area2[i-24][j-8]+area2[i-16][j-8]+area2[i-8][j-8]+area2[i][j-8]+area2[i+8][j-8]+area2[i+16][j-8]+area2[i+24][j-8]
							+area2[i-24][j]+area2[i-16][j]+area2[i-8][j]+area2[i][j]+area2[i+8][j]+area2[i+16][j]+area2[i+24][j]
							+area2[i-24][j+8]+area2[i-16][j+8]+area2[i-8][j+8]+area2[i][j+8]+area2[i+8][j+8]+area2[i+16][j+8]+area2[i+24][j+8]
							+area2[i-16][j+16]+area2[i-8][j+16]+area2[i][j+16]+area2[i+8][j+16]+area2[i+16][j+16]
							+area2[i-8][j+24]+area2[i][j+24]+area2[i+8][j+24]
						)/37,
						z = j
					}
				elseif disSQ <= radiusSQ then
					points = points + 1
					point[points] = {
						x = i, 
						y = area2[i][j],
						z = j
					}
				end
			end
		end

		local func = function()
				for i = 1, points do	
					spSetHeightMap(point[i].x,point[i].z,point[i].y)
				end   
			end
		spSetHeightMapFunc(func)
		
		local units = Spring.GetUnitsInCylinder(sx,sz,seismicRad)
		
		for i = 1, #units do
			local mass = UnitDefs[Spring.GetUnitDefID(units[i])].mass
			--Spring.AddUnitImpulse(units[i],0,(mass^0.5)*gravity/100,0)
		end
		
		--[[ LEVELING
		local sx = floor((x+4)/8)*8
		local sz = floor((z+4)/8)*8
		
		spSetHeightMapFunc(
			function()
				for i = 1, seismicPoints do	
					spSetHeightMap(seismicTerra[i].x+sx,seismicTerra[i].z+sz,y)
				end   
			end
		)
		--]]
	end

end

--------------------------------------------------------------------------------
-- Death Explosion Terraform
--------------------------------------------------------------------------------

local function deregisterStructure(unitID)

	if structure[unitID].checkAtDeath then			
		for i = 1, terraformOrders do
				
			if (structure[unitID].minx < terraformOrder[i].border.right and 
				structure[unitID].maxx > terraformOrder[i].border.left and
				structure[unitID].minz < terraformOrder[i].border.bottom and
				structure[unitID].maxz> terraformOrder[i].border.top) then
				
				for j = 1, terraformOrder[i].indexes do
					local oid = terraformUnitTable[terraformOrder[i].index[j]] 
					if (structure[unitID].minx < terraformUnit[oid].border.right and 
						structure[unitID].maxx > terraformUnit[oid].border.left and
						structure[unitID].minz < terraformUnit[oid].border.bottom and
						structure[unitID].maxz > terraformUnit[oid].border.top) then

						local recalc = false
						for k = 1, terraformUnit[oid].points do
							if structure[unitID].area[terraformUnit[oid].point[k].x] then
								if structure[unitID].area[terraformUnit[oid].point[k].x][terraformUnit[oid].point[k].z] then
									terraformUnit[oid].point[k].structure = false
									terraformUnit[oid].area[terraformUnit[oid].point[k].x][terraformUnit[oid].point[k].z] = true
									recalc = true
								end
							end
							if terraformUnit[oid].point[k].structure == 1 then
								terraformUnit[oid].point[k].structure = false
								terraformUnit[oid].area[terraformUnit[oid].point[k].x][terraformUnit[oid].point[k].z] = true
								recalc = true
							end
						end
						
						if recalc then
							updateTerraformEdgePoints(oid)
							updateTerraformCost(oid)
						end
					end
				end
			end
		end
	end
	
	for i = structure[unitID].minx, structure[unitID].maxx, 8 do
		if not structureAreaMap[i] then
			structureAreaMap[i] = {}
		end
		for j = structure[unitID].minz, structure[unitID].maxz, 8 do
			structureAreaMap[i][j] = structureAreaMap[i][j] - 1
			if structureAreaMap[i][j] < 1 then
				structureAreaMap[i][j] = nil
			end
		end
	end
		
	local f = structureCheckFrame[structure[unitID].frame]
	if f.count ~= structure[unitID].frameIndex then
		structureCheckFrame[structure[unitID].frame].unit[structure[unitID].frameIndex] = structureCheckFrame[structure[unitID].frame].unit[f.count]
	end
	if structureCheckFrame[structure[unitID].frame].count == 1 then
		structureCheckFrame[structure[unitID].frame] = nil
	else
		structureCheckFrame[structure[unitID].frame].count = structureCheckFrame[structure[unitID].frame].count - 1
	end
		
	if structure[unitID].index ~= structureCount then
		structureTable[structure[unitID].index] = structureTable[structureCount] 
		structure[structureTable[structureCount]].index = structure[unitID].index
	end
	structureCount = structureCount - 1
	structure[unitID] = nil
	
end

function gadget:UnitDestroyed(unitID, unitDefID)

	if (unitDefID == corclogDefID) then
		local  _,_,_,_,build = spGetUnitHealth(unitID)
		if build == 1 then
			local ux, uy, uz  = spGetUnitPosition(unitID)
			ux = floor((ux+4)/8)*8
			uz = floor((uz+4)/8)*8
			
			local posCount = 57
			
			local posX = 
							{ux-8,ux,ux+8,
						ux-16,ux-8,ux,ux+8,ux+16,
				  ux-24,ux-16,ux-8,ux,ux+8,ux+16,ux+24,
			ux-32,ux-24,ux-16,ux-8,ux,ux+8,ux+16,ux+24,ux+32,
			ux-32,ux-24,ux-16,ux-8,ux,ux+8,ux+16,ux+24,ux+32,
			ux-32,ux-24,ux-16,ux-8,ux,ux+8,ux+16,ux+24,ux+32,
				  ux-24,ux-16,ux-8,ux,ux+8,ux+16,ux+24,
						ux-16,ux-8,ux,ux+8,ux+16,
							  ux-8,ux,ux+8}
							  
			local posZ = 
							{uz-32,uz-32,uz-32,
						uz-24,uz-24,uz-24,uz-24,uz-24,
				  uz-16,uz-16,uz-16,uz-16,uz-16,uz-16,uz-16,
			uz-8 ,uz-8 ,uz-8 ,uz-8 ,uz-8 ,uz-8 ,uz-8 ,uz-8 ,uz-8 ,
			uz   ,uz   ,uz   ,uz   ,uz   ,uz   ,uz   ,uz   ,uz   ,
			uz+8 ,uz+8 ,uz+8 ,uz+8 ,uz+8 ,uz+8 ,uz+8 ,uz+8 ,uz+8 ,
				  uz+16,uz+16,uz+16,uz+16,uz+16,uz+16,uz+16,
						uz+24,uz+24,uz+24,uz+24,uz+24,
							  uz+32,uz+32,uz+32}
			
			local posY = 
					{6 ,7 ,6 ,
				  9 ,15,18,15,9 ,
			   9 ,17,24,27,24,17,9 ,
			6 ,15,24,29,36,29,24,15,6 ,
			7 ,18,27,36,40,36,27,18,7 ,
			6 ,15,24,29,36,29,24,15,6 ,
			   9 ,17,24,27,24,17,9 ,
				  9 ,15,18,15,9 ,
					 6 ,7 ,6 }
			
			for i = 1, posCount do
				if structureAreaMap[posX[i]] and structureAreaMap[posX[i]][posZ[i]] then
					posY[i] = 0
				end	
			end
			
			spSetHeightMapFunc(
				function(x,z,h)
					for i = 1, #x, 1 do
						spAddHeightMap(x[i],z[i],h[i])
					end
				end,
				posX,
				posZ,
				posY
			) 
		end
		--spAdjustHeightMap(ux-64, uz-64, ux+64, uz+64 , 0)
	end
	--[[
  	if (unitDefID == novheavymineDefID) then
		local  _,_,_,_,build = spGetUnitHealth(unitID)
		
		if build == 1 then
			local ux, uy, uz = spGetUnitPosition(unitID)
			ux = ceil(ux/8)*8-4
			uz = ceil(uz/8)*8-4
			
			local heightChange = -30
			local size = 48
			local heightMap = {}
			
			for ix = ux-size-8, ux+size+8, 8 do
				heightMap[ix] = {}
				for iz = uz-size-8, uz+size+8, 8 do
					heightMap[ix][iz] = spGetGroundHeight(ix, iz)
				end
			end
			
			local point = {}
			local points = 0
			
			for ix = ux-size, ux+size, 8 do
				for iz = uz-size, uz+size, 8 do
					local newHeight = heightMap[ix][iz] + heightChange
					
					local maxDiff = heightMap[ix-8][iz]-newHeight
					if heightMap[ix+8][iz]-newHeight > maxDiff then 
						maxDiff = heightMap[ix+8][iz]-newHeight 
					end
					if heightMap[ix][iz-8]-newHeight > maxDiff then 
						maxDiff = heightMap[ix][iz-8]-newHeight 
					end
					if heightMap[ix][iz+8]-newHeight > maxDiff then 
						maxDiff = heightMap[ix][iz+8]-newHeight 
					end
					
					if maxDiff < maxHeightDifference then
						points = points + 1
						point[points] = {x = ix, y = newHeight, z = iz}
					elseif maxDiff < maxHeightDifference*2 then
						points = points + 1
						point[points] = {x = ix, y = newHeight+maxDiff-maxHeightDifference, z = iz}
					end
				end
			end

			local func = function()
					for i = 1, points do	
						spSetHeightMap(point[i].x,point[i].z,point[i].y)
					end 
				end
			spSetHeightMapFunc(func)
		end
		--spAdjustHeightMap(ux-64, uz-64, ux+64, uz+64 , 0)
	end
	--]]
	if constructor[unitID] then
		local index = constructor[unitID].index
		if index ~= constructors then
			constructorTable[index] = constructorTable[constructors]
		end
		constructorTable[constructors] = nil
		constructors = constructors - 1
		constructor[unitID]	= nil
		
		if constructors ~= 0 then
			checkInterval = ceil(checkLoopFrames/constructors)
			if checkInterval <= 1 then
				checkLoopFrames = checkLoopFrames * 2
			end
			checkInterval = ceil(checkLoopFrames/constructors)
		end
	end
  
	if structure[unitID] then
		deregisterStructure(unitID)
	end
	
end

--------------------------------------------------------------------------------
--------------------------------------------------------------------------------

function gadget:UnitCreated(unitID, unitDefID)

	local ud = UnitDefs[unitDefID]
	-- add terraform commands to builders
	if ud.isBuilder and not ud.isFactory then
		spInsertUnitCmdDesc(unitID, rampCmdDesc)
		spInsertUnitCmdDesc(unitID, levelCmdDesc)
		spInsertUnitCmdDesc(unitID, raiseCmdDesc)
		spInsertUnitCmdDesc(unitID, smoothCmdDesc)
		spInsertUnitCmdDesc(unitID, restoreCmdDesc)
		
		local aTeam = spGetUnitAllyTeam(unitID)
		
		constructors = constructors + 1
		constructorTable[constructors] = unitID
		
		constructor[unitID]	= {allyTeam = aTeam, index = constructors}
		
		checkInterval = ceil(checkLoopFrames/constructors)
	end
	
	-- add structure to structure table
    if (ud.isBuilding == true or ud.maxAcc == 0) and (not ud.customParams.mobilebuilding) then
	    local ux, uy, uz = spGetUnitPosition(unitID)
		ux = floor((ux+4)/8)*8
		uz = floor((uz+4)/8)*8
	    local face = spGetUnitBuildFacing(unitID)
	    local xsize = ud.xsize*4
	    local ysize = (ud.zsize or ud.ysize)*4
		
		structureCount = structureCount + 1
		
	    if ((face == 0) or(face == 2)) then
			structure[unitID] = { x = ux, z = uz , h = spGetGroundHeight(ux, uz), def = ud,
	        minx = ux-xsize, minz = uz-ysize, maxx = ux+xsize, maxz = uz+ysize, area = {}, index = structureCount}
	    else
	        structure[unitID] = { x = ux, z = uz , h = spGetGroundHeight(ux, uz), def = ud,
	        minx = ux-ysize, minz = uz-xsize, maxx = ux+ysize, maxz = uz+xsize, area = {}, index = structureCount}
	    end
		
		for i = structure[unitID].minx, structure[unitID].maxx, 8 do
			structure[unitID].area[i] = {}
			if not structureAreaMap[i] then
				structureAreaMap[i] = {}
			end
			for j = structure[unitID].minz, structure[unitID].maxz, 8 do
				structure[unitID].area[i][j] = true
				if structureAreaMap[i][j] then
					structureAreaMap[i][j] = structureAreaMap[i][j] + 1
				else
					structureAreaMap[i][j] = 1
				end
				
			end
		end
		
		structureTable[structureCount] = unitID
		
		-- slow update for terrain checking
		if not structureCheckFrame[currentCheckFrame] then
			structureCheckFrame[currentCheckFrame] = {count = 0, unit = {}}
		end
		structureCheckFrame[currentCheckFrame].count = structureCheckFrame[currentCheckFrame].count + 1
		structureCheckFrame[currentCheckFrame].unit[structureCheckFrame[currentCheckFrame].count] = unitID
		structure[unitID].frame = currentCheckFrame
		structure[unitID].frameIndex = structureCheckFrame[currentCheckFrame].count
		
		currentCheckFrame = currentCheckFrame + 1
		if currentCheckFrame > structureCheckLoopFrames then
			currentCheckFrame = 0
		end
		
		-- check if the building is on terraform
		for i = 1, terraformOrders do
			
			if (structure[unitID].minx < terraformOrder[i].border.right and 
				structure[unitID].maxx > terraformOrder[i].border.left and
				structure[unitID].minz < terraformOrder[i].border.bottom and
				structure[unitID].maxz> terraformOrder[i].border.top) then
				
				for j = 1, terraformOrder[i].indexes  do
					local oid = terraformUnitTable[terraformOrder[i].index[j]] 

					if (structure[unitID].minx < terraformUnit[oid].border.right and 
						structure[unitID].maxx > terraformUnit[oid].border.left and
						structure[unitID].minz < terraformUnit[oid].border.bottom and
						structure[unitID].maxz > terraformUnit[oid].border.top) then
						
						structure[unitID].checkAtDeath = true
						
						local recalc = false
						for k = 1, terraformUnit[oid].points do
							if structure[unitID].area[terraformUnit[oid].point[k].x] then
								if structure[unitID].area[terraformUnit[oid].point[k].x][terraformUnit[oid].point[k].z] then
									terraformUnit[oid].point[k].diffHeight = 0.0001
									terraformUnit[oid].point[k].structure = true
									--terraformUnit[oid].area[terraformUnit[oid].point[k].x][terraformUnit[oid].point[k].z].building = true
									recalc = true
								end
							end
						end
						
						if recalc then
							updateTerraformCost(oid)
						end
						
					end
				end
			end
		end
		

	end
	
end

--------------------------------------------------------------------------------
--------------------------------------------------------------------------------
-- Initialise, check modoptions and register command

function gadget:Initialize()
	gadgetHandler:RegisterCMDID(CMD_TERRAFORM_INTERNAL)
	
	_G.drawPositions = drawPositions
	if modOptions.waterlevel and modOptions.waterlevel ~= 0 then
		RaiseWater(modOptions.waterlevel)
	end
	
	for _, unitID in ipairs(Spring.GetAllUnits()) do
		local unitDefID = Spring.GetUnitDefID(unitID)
		local teamID = Spring.GetUnitTeam(unitID)
		gadget:UnitCreated(unitID, unitDefID, teamID)
	end
end

--------------------------------------------------------------------------------
--------------------------------------------------------------------------------
else -- UNSYNCED
--------------------------------------------------------------------------------
--------------------------------------------------------------------------------

function gadget:DrawWorldPreUnit()
	local drawPositions = SYNCED.drawPositions
	--[[
	--gl.DepthTest(true)
	for i = 1, drawPositions.count do
		local point = drawPositions.data[i]
		--gl.Texture('Luaui/Images/energy.png' )
		--gl.Texture('LuaRules/Images/trophy_kam.png' )
		gl.Color(0.5,0,0,0.5)
		--gl.DrawGroundQuad(point.x1,point.z1,point.x2,point.z2)
		--gl.Utilities.DrawGroundRectangle(point.x1,point.z1,point.x2,point.z2)
	end--]]
end

--------------------------------------------------------------------------------
--------------------------------------------------------------------------------

end
