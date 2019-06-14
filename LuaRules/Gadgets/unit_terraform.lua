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

-------------------------------------------------------------------------------------
-------------------------------------------------------------------------------------
if gadgetHandler:IsSyncedCode() then

--------------------------------------------------------------------------------
-- SYNCED
--------------------------------------------------------------------------------

-------------------------------------------------------------------------------------
-------------------------------------------------------------------------------------

--------------------------------------------------------------------------------
--------------------------------------------------------------------------------
local USE_TERRAIN_TEXTURE_CHANGE = true -- (Spring.GetModOptions() or {}).terratex == "1"

-- Speedups
local cos                   = math.cos
local floor                 = math.floor
local abs                   = math.abs
local pi                    = math.pi
local ceil                  = math.ceil
local sqrt                  = math.sqrt
local pow                   = math.pow
local random                = math.random
local max                   = math.max

local spAdjustHeightMap     = Spring.AdjustHeightMap
local spGetGroundHeight     = Spring.GetGroundHeight
local spGetGroundOrigHeight = Spring.GetGroundOrigHeight
local spGetGroundNormal     = Spring.GetGroundNormal
local spLevelHeightMap      = Spring.LevelHeightMap
local spGetUnitBuildFacing  = Spring.GetUnitBuildFacing
local spGetCommandQueue     = Spring.GetCommandQueue
local spValidUnitID         = Spring.ValidUnitID
local spGetGameFrame        = Spring.GetGameFrame
local spGiveOrderToUnit     = Spring.GiveOrderToUnit
local spInsertUnitCmdDesc   = Spring.InsertUnitCmdDesc
local spTestBuildOrder      = Spring.TestBuildOrder
local spSetHeightMap        = Spring.SetHeightMap
local spSetHeightMapFunc    = Spring.SetHeightMapFunc
local spRevertHeightMap     = Spring.RevertHeightMap
local spEditUnitCmdDesc     = Spring.EditUnitCmdDesc
local spFindUnitCmdDesc     = Spring.FindUnitCmdDesc
local spGetActiveCommand    = Spring.GetActiveCommand
local spSpawnCEG            = Spring.SpawnCEG
local spCreateUnit          = Spring.CreateUnit
local spDestroyUnit         = Spring.DestroyUnit
local spGetAllyTeamList     = Spring.GetAllyTeamList
local spSetUnitLosMask      = Spring.SetUnitLosMask
local spGetTeamInfo         = Spring.GetTeamInfo
local spGetUnitHealth       = Spring.GetUnitHealth
local spSetUnitHealth       = Spring.SetUnitHealth
local spGetUnitTeam         = Spring.GetUnitTeam
local spGetUnitAllyTeam     = Spring.GetUnitAllyTeam
local spAddHeightMap        = Spring.AddHeightMap
local spGetUnitPosition     = Spring.GetUnitPosition
local spSetUnitPosition     = Spring.SetUnitPosition
local spSetUnitSensorRadius = Spring.SetUnitSensorRadius
local spGetAllUnits         = Spring.GetAllUnits
local spGetUnitIsDead       = Spring.GetUnitIsDead
local spSetUnitRulesParam   = Spring.SetUnitRulesParam

local mapWidth = Game.mapSizeX
local mapHeight = Game.mapSizeZ

local CMD_OPT_RIGHT = CMD.OPT_RIGHT
local CMD_OPT_SHIFT = CMD.OPT_SHIFT
local CMD_OPT_ALT   = CMD.OPT_ALT
local CMD_STOP = CMD.STOP
local CMD_REPAIR = CMD.REPAIR
local CMD_INSERT = CMD.INSERT

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

local bumpyMap = {}

for i = 0, 64, 8 do
	bumpyMap[i] = {}
	for j = 0, 64, 8 do
		bumpyMap[i][j] = 32 - max(abs(i-32), abs(j-32))
	end
end

local maxAreaSize = 2000 -- max X or Z bound of area terraform
local areaSegMaxSize = 200 -- max width and height of terraform squares

local maxWallPoints = 700 -- max points that can makeup a wall
local wallSegmentLength = 14 -- how many points are part of a wall segment (points are seperated 8 elmos orthagonally)

local maxRampWidth = 200 -- maximun width of ramp segment
local maxRampLegth = 200 -- maximun length of ramp segment

local maxHeightDifference = 30 -- max difference of height around terraforming, Makes Shraka Pyramids
local maxRampGradient = 5

local volumeCost = 0.0128
local pointExtraAreaCost = 0 -- 0.027
local pointExtraAreaCostDepth = 6
local pointExtraPerimeterCost = 0.1
local pointExtraPerimeterCostDepth = 6
local baseTerraunitCost = 12
local inbuiltCostMult = 0.5

local perimeterEdgeCost = {
	[0] = 0,
	[1] = 1,
	[2] = 1.4,
	[3] = 1,
	[4] = 1,
}
-- cost of a point = volumeCost*diffHeight + extraCost*(extraCostDepth < diffHeight and diffHeight or extraCostDepth)
-- cost of shraka pyramid point = volumeCost*diffHeight

--ramp dimensions
local maxTotalRampLength = 3000
local maxTotalRampWidth = 800
local minTotalRampLength = 40
local minTotalRampWidth = 24

local checkLoopFrames = 1200 -- how many frames it takes to check through all cons
local terraformDecayFrames = 1800 -- how many frames a terrablock can survive for without a repair command
local decayCheckFrequency = 90 -- frequency of terraform decay checks

local structureCheckLoopFrames = 300 -- frequency of slow update for building deformation check

local terraUnitLimit = 250 -- limit on terraunits per player

local terraUnitLeash = 100 -- how many elmos a terraunit is allowed to roam

local costMult = 1
local modOptions = Spring.GetModOptions()
if modOptions.terracostmult then
	costMult = modOptions.terracostmult
end

volumeCost = volumeCost * costMult * inbuiltCostMult
pointExtraPerimeterCost = pointExtraPerimeterCost * costMult * inbuiltCostMult
pointExtraAreaCost = pointExtraAreaCost * costMult * inbuiltCostMult

--------------------------------------------------------------------------------
-- Arrays
--------------------------------------------------------------------------------

local drawPositions			= {count = 0, data = {}}
local drawPosMap			= {}
local steepnessMarkers		= {inner = {count = 0, data = {}, frame = 0}}

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

-- Performance
local MIN_UPDATE_PERIOD     = 3
local MAX_UPDATE_PERIOD     = 30
local updatePeriod          = 15 -- how many frames to update
local terraformOperations   = 0 -- tracks how many operations. Used to prevent slowdown.
local nextUpdateCheck       = 0 -- Time at which to check performance

-- Map terraform commands given by teamID and tag.
local fallbackCommands  = {}

local terraunitDefID = UnitDefNames["terraunit"].id

local shieldscoutDefID = UnitDefNames["shieldscout"].id
--local novheavymineDefID = UnitDefNames["novheavymine"].id

local exceptionArray = {
	[UnitDefNames["shipcarrier"].id] = true,
}

local terraformUnitDefIDs = {}
for i = 1, #UnitDefs do
	local ud = UnitDefs[i]
	if ud and ud.isBuilder and not ud.isFactory and not exceptionArray[i] then
		terraformUnitDefIDs[i] = true
	end
end

local REPAIR_ORDER_PARAMS = {0, CMD_REPAIR, CMD_OPT_RIGHT, 0} -- static because only the 4th parameter changes

local workaround_recursion_in_cmd_fallback = {}
local workaround_recursion_in_cmd_fallback_needed = false

--------------------------------------------------------------------------------
-- Custom Commands
--------------------------------------------------------------------------------

include("LuaRules/Configs/customcmds.h.lua")

local rampCmdDesc = {
  id      = CMD_RAMP,
  type    = CMDTYPE.ICON_MAP,
  name    = 'Ramp',
  cursor  = 'Ramp', 
  action  = 'rampground',
  tooltip = 'Build a Ramp - Click and drag between two positions.',
}

local levelCmdDesc = {
  id      = CMD_LEVEL,
  type    = CMDTYPE.ICON_AREA,
  name    = 'Level',
  cursor  = 'Level', 
  action  = 'levelground',
  tooltip = 'Level the terrain - Click and drag a line or closed shape.',
}

local raiseCmdDesc = {
  id      = CMD_RAISE,
  type    = CMDTYPE.ICON_AREA,
  name    = 'Raise',
  cursor  = 'Raise', 
  action  = 'raiseground',
  tooltip = 'Raises/Lower terrain -  - Click and drag a line or closed shape.',
}

local smoothCmdDesc = {
  id      = CMD_SMOOTH,
  type    = CMDTYPE.ICON_AREA,
  name    = 'Smooth',
  cursor  = 'Smooth', 
  action  = 'smoothground',
  tooltip = 'Smooth the terrain - Click and drag a line or closed shape.',
}

local restoreCmdDesc = {
  id      = CMD_RESTORE,
  type    = CMDTYPE.ICON_AREA,
  name    = 'Restore2',
  cursor  = 'Restore2', 
  action  = 'restoreground',
  tooltip = 'Restore the terrain to its original shape - Click and drag a line or closed shape.',
}

local bumpyCmdDesc = {
  id      = CMD_BUMPY,
  type    = CMDTYPE.ICON_AREA,
  name    = 'Bumpify',
  cursor  = 'Repair', 
  action  = 'bumpifyground',
  tooltip = 'Makes the ground bumpy',
}

local fallbackableCommands = {
	[CMD_RAMP] = true,
	[CMD_LEVEL] = true,
	[CMD_RAISE] = true,
	[CMD_SMOOTH] = true,
	[CMD_RESTORE] = true,
}

local wantedCommands = {
	[CMD_RAMP] = true,
	[CMD_LEVEL] = true,
	[CMD_RAISE] = true,
	[CMD_SMOOTH] = true,
	[CMD_RESTORE] = true,
	[CMD_TERRAFORM_INTERNAL] = true,
}

local cmdDescsArray = {
	rampCmdDesc,
	levelCmdDesc,
	raiseCmdDesc,
	smoothCmdDesc,
	restoreCmdDesc,
	--bumpyCmdDesc,
}

if (not Game.mapDamage) then  -- map has "notDeformable = true", or "disablemapdamage = 1" modoption was set in the startscript
	include("LuaRules/colors.h.lua")
	local disabledText = '\n' .. RedStr .. "DISABLED" .. PinkStr .. "  (map not deformable)"

	for _, cmdDesc in ipairs(cmdDescsArray) do
		cmdDesc.disabled = true
		cmdDesc.tooltip  = cmdDesc.tooltip .. disabledText
	end
elseif modOptions.terrarestoreonly == "1" then
	include("LuaRules/colors.h.lua")
	local disabledText = '\n' .. RedStr .. "DISABLED" .. PinkStr .. "  (only restore allowed)"

	for _, cmdDesc in ipairs(cmdDescsArray) do
		if cmdDesc ~= restoreCmdDesc then
			cmdDesc.disabled = true
			cmdDesc.tooltip  = cmdDesc.tooltip .. disabledText
		end
	end
end

--------------------------------------------------------------------------------
-- New Functions
--------------------------------------------------------------------------------

local function IsBadNumber(value, thingToSay)
	local isBad = (string.find(tostring(value), "n") and true) or false
	if isBad then
		Spring.Echo("Terraform bad number detected", thingToSay, value)
	end
	return isBad
end

local function SetTooltip(unitID, spent, estimatedCost)
	Spring.SetUnitRulesParam(unitID, "terraform_spent", spent, {allied = true})
	if IsBadNumber(estimatedCost, "SetTooltip") then 
		estimatedCost = 100 -- the estimate is for widgets only so better to have wrong data than to crash
	end
	Spring.SetUnitRulesParam(unitID, "terraform_estimate", estimatedCost, {allied = true})
end

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

local function bumpyFunc(x,z,bumpyType)
	local sign = pow(-1,((x - x%64)/64 + (z - z%64)/64))
	--return pow(-1,((x - x%8)/8 + (z - z%8)/8))*3*(bumpyType + 1)
	return bumpyMap[x%64][z%64]*sign*(bumpyType + 1)
end

local function checkPointCreation(terraform_type, volumeSelection, orHeight, newHeight, startHeight, x, z)
	
	if terraform_type == 6 then
		local _, ny, _ = spGetGroundNormal(x,z)
		if ny > select(2,spGetGroundNormal(x+8,z)) then
			ny = select(2,spGetGroundNormal(x+8,z))
		end
		if ny > select(2,spGetGroundNormal(x-8,z)) then
			ny = select(2,spGetGroundNormal(x-8,z))
		end
		if ny > select(2,spGetGroundNormal(x,z+8)) then
			ny = select(2,spGetGroundNormal(x,z+8))
		end
		if ny > select(2,spGetGroundNormal(x,z-8)) then
			ny = select(2,spGetGroundNormal(x,z-8))
		end
		--if (volumeSelection == 1 and ny > 0.595) or ny > 0.894 then
		--	Spring.MarkerAddLine(x,0,z,x+8,0,z+8)
		--	Spring.MarkerAddLine(x+8,0,z,x,0,z+8)
		--end
		return (volumeSelection == 1 and ny > 0.595) or ny > 0.894
	end
	
	if volumeSelection == 0 or terraform_type == 2 then
		return true
	end
	
	if abs(orHeight-newHeight) == 0 then
		return false
	end

	if terraform_type == 5 then
		return (volumeSelection == 1 and orHeight < startHeight) or (volumeSelection == 2 and orHeight > startHeight)
	else
		return (volumeSelection == 1 and orHeight < newHeight) or (volumeSelection == 2 and orHeight > newHeight)
	end
end

local function updateBorderWithPoint(border, x, z)
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
end

local function getPointInsideMap(x,z)
	if x < 1 then
		x = 1
	end
	if x > mapWidth-1 then
		x = mapWidth-1
	end
	if z < 1 then
		z = 1
	end
	if z > mapHeight-1 then
		z = mapHeight-1
	end
	return x, z
end


local function setupTerraunit(unitID, team, x, y, z)

	y = y or CallAsTeam(team, function () return spGetGroundHeight(x,z) end)

	Spring.MoveCtrl.Enable(unitID)
	Spring.MoveCtrl.SetPosition(unitID, x, y or 0, z)
	Spring.MoveCtrl.Disable(unitID)
	
	spSetUnitSensorRadius(unitID,"los",0) -- REMOVE IN 0.83
	spSetUnitSensorRadius(unitID,"airLos",0) -- REMOVE IN 0.83
	
	local allyTeamList = spGetAllyTeamList()
	local _,_,_,_,_,unitAllyTeam = spGetTeamInfo(team, false)
	for i=1, #allyTeamList do
		local allyID = allyTeamList[i]
		if allyID ~= unitAllyTeam then
			spSetUnitLosMask(unitID, allyID, {los=true, radar=true, prevLos=true, contRadar=true } )
		end
	end

	spSetUnitHealth(unitID, {
		health = 0.01,
		build  = 0
	})
end

local function GetTerraunitLeashedSpot(teamID, anchorX, anchorZ, biasX, biasZ)
	local x, z

	local vx = biasX - anchorX
	local vz = biasZ - anchorZ

	local leashLength = sqrt(vx*vx + vz*vz)
	if leashLength > terraUnitLeash then
		-- cruel leash!
		local leashScale = terraUnitLeash / leashLength
		x = anchorX + leashScale * vx
		z = anchorZ + leashScale * vz
	else
		x = biasX
		z = biasZ
	end

	x, z = getPointInsideMap(x, z)
	local y = CallAsTeam(teamID, spGetGroundHeight, x, z)

	return x, y, z
end

local function AddFallbackCommand(teamID, commandTag, terraunits, terraunitList, commandX, commandZ)
	fallbackCommands[teamID] = fallbackCommands[teamID] or {}
	
	fallbackCommands[teamID][commandTag] = {
		terraunits = terraunits,
		terraunitList = terraunitList,
		commandX = commandX, 
		commandZ = commandZ, 
	}
end

local function GetUnitAveragePosition(unit, units)
	if not unit then
		return
	end
	local unitsX = 0
	local unitsZ = 0
	local i = 1
	while i <= units do
		if (spValidUnitID(unit[i])) then
			local x,_,z = spGetUnitPosition(unit[i])
			unitsX = unitsX + x
			unitsZ = unitsZ + z
			i = i + 1
		else
			unit[i] = unit[units]
			unit[units] = nil
			units = units - 1
		end
	end
		
	if units == 0 then 
		return
	end
	
	return unitsX/units, unitsZ/units
end

local function TerraformRamp(x1, y1, z1, x2, y2, z2, terraform_width, unit, units, team, volumeSelection, shift, commandX, commandZ, commandTag, disableForceCompletion)

	--** Initial constructor processing **
	local unitsX, unitsZ = GetUnitAveragePosition(unit, units)
	if not unitsX then
		unitsX, unitsZ = commandX, commandZ
	end
	
	--calculate equations of the 3 lines, left, right and mid
	
	local border = {}
	
	if abs(x1 - x2) < 0.1 then
		x2 = x1 + 0.1
	end
	if abs(z1 - z2) < 0.1 then
		z2 = z1 + 0.1
	end
  
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
	
	-- Due to previous checks, m is not 0 or infinity.
	local m = (z1-z2)/(x1-x2)
	
	local segmentsAlong = ceil(dis/maxRampLegth)
	local segmentsAcross = ceil(terraform_width/maxRampWidth)
	local segLength = dis/segmentsAlong
	local segWidth = terraform_width/segmentsAcross
	local widthScale = terraform_width/dis
	local lengthScale = segLength/dis
  
	local add = {x = (x2-x1)*lengthScale, z = (z2-z1)*lengthScale}
	local addPerp = {x = (z1-z2)*segWidth/dis, z = -(x1-x2)*segWidth/dis}
	
	local mid = {x = (x1-x2)*widthScale/2, z = (z1-z2)*widthScale/2}
	local leftRot = {x = mid.z+x1, z = -mid.x+z1}
	local rightRot = {x = -mid.z+x1, z = mid.x+z1}
  
	--Spring.MarkerAddPoint(leftRot.x,0,leftRot.z,"L")
	--Spring.MarkerAddPoint(rightRot.x,0,rightRot.z,"R")
	--Spring.MarkerAddPoint(rightRot.x+add.x,0,rightRot.z+add.z,"R + A")
	--Spring.MarkerAddPoint(rightRot.x+addPerp.x,0,rightRot.z+addPerp.z,"R + AP")
	
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
	
	do local i = 0
	while i < segmentsAlong do
		local j = 0
		while j < segmentsAcross do
			local middleSegment = (i > 0) and (j > 0) and (i < segmentsAlong - 1) and (j < segmentsAcross - 1)
			local offset = (middleSegment and 8) or 0
			
			segment[n] = {}
			segment[n].along = i
			segment[n].point = {}
			segment[n].area = {}
			segment[n].border = {
				left = floor((leftpoint.x+add.x*i+addPerp.x*j)/8)*8 - offset, 
				right = ceil((rightpoint.x+add.x*i+addPerp.x*j)/8)*8 + offset, 
				top = floor((toppoint.z+add.z*i+addPerp.z*j)/8)*8 - offset, 
				bottom = ceil((botpoint.z+add.z*i+addPerp.z*j)/8)*8 + offset
			}
			-- end of segment
			--segment[n].position = {x = (rightRot.x-4+add.x*i+addPerp.x*(j+0.5)-16*(x2-x1)/dis), z = (rightRot.z-4+add.z*i+addPerp.z*(j+0.5)-16*(z2-z1)/dis)}
			
			-- middle of segment
			segment[n].position = {x = rightRot.x+add.x*(i+0.5)+addPerp.x*(j+0.5), z = rightRot.z+add.z*(i+0.5)+addPerp.z*(j+0.5)}
			local pc = 1
		  
			local topline1 = {x = leftpoint.x+add.x*i+addPerp.x*j - offset, z = leftpoint.z+add.z*i+addPerp.z*j - offset, m = topleftGrad}
			local topline2 = {x = toppoint.x+add.x*i+addPerp.x*j + offset, z = toppoint.z+add.z*i+addPerp.z*j - offset, m = botleftGrad}
			local botline1 = {x = leftpoint.x+add.x*i+addPerp.x*j - offset, z = leftpoint.z+add.z*i+addPerp.z*j + offset, m = botleftGrad}
			local botline2 = {x = botpoint.x+add.x*i+addPerp.x*j + offset, z = botpoint.z+add.z*i+addPerp.z*j + offset, m = topleftGrad}
			
			local topline = topline1
			local botline = botline1
			
			local lx = segment[n].border.left - offset
			while lx <= segment[n].border.right + offset do
				segment[n].area[lx] = {}
				local zmin = linearEquation(lx,topline.m,topline.x,topline.z)
				local zmax = linearEquation(lx,botline.m,botline.x,botline.z)
				
				local lz = segment[n].border.top
				while lz <= zmax do
					if zmin <= lz then
						local h = pointHeight(x1, y1, z1, lx, lz, m, heightDiff, xdis)
						local orHeight = spGetGroundHeight(lx,lz)
						if checkPointCreation(4, volumeSelection, orHeight, h, 0, lx, lz) then
							segment[n].point[pc] = {x = lx, y = h ,z = lz, orHeight = orHeight, prevHeight = spGetGroundHeight(lx,lz)}
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
	end end
	
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
	
	local rampLevels = {count = 0, data = {[0] = {along = false}}}
	
	local frame = spGetGameFrame()
	
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
		local areaCost = 0
		local perimeterCost = 0
		
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
			areaCost = areaCost + (pointExtraAreaCostDepth > abs(segment[i].point[j].diffHeight) and abs(segment[i].point[j].diffHeight) or pointExtraAreaCostDepth)
		end
		
		-- Perimeter Cost
		local pyramidCostEstimate = 0
		
		for j = 1, segment[i].points do
			local x = segment[i].point[j].x
			local z = segment[i].point[j].z
			
			if segment[i].area[x] and segment[i].area[x][z] then
				
				local edgeCount = 0
				
				if (not segment[i].area[x+8]) or (not segment[i].area[x+8][z]) then
					edgeCount = edgeCount + 1
				end
				if (not segment[i].area[x-8]) or (not segment[i].area[x-8][z]) then
					edgeCount = edgeCount + 1
				end
				if (not segment[i].area[x][z+8]) then
					edgeCount = edgeCount + 1
				end
				if (not segment[i].area[x][z-8]) then
					edgeCount = edgeCount + 1
				end
				
				if perimeterEdgeCost[edgeCount] > 0 then
					perimeterCost = perimeterCost + perimeterEdgeCost[edgeCount]*(pointExtraPerimeterCostDepth > abs(segment[i].point[j].diffHeight) and abs(segment[i].point[j].diffHeight) or pointExtraPerimeterCostDepth)
				end
				
				if edgeCount > 0 then
					local height = abs(segment[i].point[j].diffHeight)
					if height > 30 then
						pyramidCostEstimate = pyramidCostEstimate + ((height - height%maxHeightDifference)*(floor(height/maxHeightDifference)-1)*0.5 + floor(height/maxHeightDifference)*(height%maxHeightDifference))*volumeCost
					end
				end
			end
		end
		
		if totalCost ~= 0 then
			local baseCost = areaCost*pointExtraAreaCost + perimeterCost*pointExtraPerimeterCost + baseTerraunitCost
			totalCost = totalCost*volumeCost + baseCost
			
			--Spring.Echo(totalCost .. "\t" .. baseCost)
			local pos = segment[i].position
			local terraunitX, teamY, terraunitZ = GetTerraunitLeashedSpot(team, pos.x, pos.z, unitsX, unitsZ)
			
			local id = spCreateUnit(terraunitDefID, terraunitX, teamY or 0, terraunitZ, 0, team, true)
			
			if id then
				spSetUnitHealth(id, 0.01)
				if segment[i].along ~= rampLevels.data[rampLevels.count].along then
					rampLevels.count = rampLevels.count + 1
					rampLevels.data[rampLevels.count] = {along = segment[i].along, count = 0, data = {}}
				end
				rampLevels.data[rampLevels.count].count = rampLevels.data[rampLevels.count].count + 1
				rampLevels.data[rampLevels.count].data[rampLevels.data[rampLevels.count].count] = id

				setupTerraunit(id, team, terraunitX, false, terraunitZ)
				spSetUnitRulesParam(id, "terraformType", 4) --ramp
			
				blocks = blocks + 1
				block[blocks] = id

				terraformUnitCount = terraformUnitCount + 1
				terraformOrder[terraformOrders].indexes = terraformOrder[terraformOrders].indexes + 1
				
				terraformUnit[id] = {
					positionAnchor = pos,
					position = {x = terraunitX, z = terraunitZ}, 
					progress = 0, 
					lastUpdate = 0, 
					totalSpent = 0,
					baseCostSpent = 0,
					cost = totalCost, 
					baseCost = baseCost,
					totalCost = totalCost,
					pyramidCostEstimate = pyramidCostEstimate,
					point = segment[i].point, 
					points = segment[i].points, 
					area = segment[i].area, 
					border = segment[i].border, 
					smooth = false, 
					intercepts = 0, 
					intercept = {}, 
					interceptMap = {},
					decayTime = frame + terraformDecayFrames, 
					allyTeam = unitAllyTeam,
					team = team,
					order = terraformOrders,
					orderIndex = terraformOrder[terraformOrders].indexes,
					fullyInitialised = false,
					lastProgress = 0,
					lastHealth = 0,
					disableForceCompletion = disableForceCompletion,
				}
				
				terraformUnitTable[terraformUnitCount] = id
				terraformOrder[terraformOrders].index[terraformOrder[terraformOrders].indexes] = terraformUnitCount
				
				SetTooltip(id, 0, pyramidCostEstimate + totalCost)
			end
		end
		
	end
	--** Give repair order for each block to all selected units **
	if rampLevels.count == 0 then
		return
	end

	local orderList = {data = {}, count = 0}
	
	local zig = 0
	if linearEquation(unitsX,m,x1,z1) < unitsZ then
		zig = 1
	end
	
	for i = 1, rampLevels.count do
		for j = 1 + rampLevels.data[i].count*zig, (rampLevels.data[i].count-1)*(1-zig) + 1, 1-zig*2 do
			orderList.count = orderList.count + 1
			orderList.data[orderList.count] = rampLevels.data[i].data[j]
		end
		zig = 1-zig
	end
	
	if orderList.count == 0 then
		return
	end
	
	AddFallbackCommand(team, commandTag, orderList.count, orderList.data, commandX, commandZ)
end

local function TerraformWall(terraform_type, mPoint, mPoints, terraformHeight, unit, units, team, volumeSelection, shift, commandX, commandZ, commandTag, disableForceCompletion)

	local border = {left = mapWidth, right = 0, top = mapHeight, bottom = 0}
	
	--** Initial constructor processing **
	local unitsX, unitsZ = GetUnitAveragePosition(unit, units)
	if not unitsX then
		unitsX, unitsZ = commandX, commandZ
	end
	
	
	--** Convert Mouse Points to a Closed Loop on a Grid **

	-- points interpolated from mouse points
	local point = {}
	local points = 1
	
	mPoint[1].x = floor((mPoint[1].x+8)/16)*16
	mPoint[1].z = floor((mPoint[1].z+8)/16)*16
	point[1] = mPoint[1]
	updateBorderWithPoint(border, point[points].x, point[points].z)
	
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
			updateBorderWithPoint(border, point[points].x, point[points].z)
		else
			-- interpolate between far apart points to prevent wall holes.
			if a_diffX > a_diffZ then
				local m = diffZ/diffX
				local sign = diffX/a_diffX
				for j = 0, a_diffX, 16 do	
					points = points + 1
					point[points] = {x = mPoint[i-1].x + j*sign, z = floor((mPoint[i-1].z + j*m*sign)/16)*16}
					updateBorderWithPoint(border, point[points].x, point[points].z)
				end
			else
				local m = diffX/diffZ
				local sign = diffZ/a_diffZ
				for j = 0, a_diffZ, 16 do	
					points = points + 1
					point[points] = {x = floor((mPoint[i-1].x + j*m*sign)/16)*16, z = mPoint[i-1].z + j*sign}
					updateBorderWithPoint(border, point[points].x, point[points].z)
				end
			end
			
		end
	end
	
	border.left = border.left - 16
	border.top = border.top - 16
	border.right = border.right + 16
	border.bottom = border.bottom + 16
	
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
			
			local averagePosition = {x = 0, z = 0, n = 0}
			
			local pc = 1
			
			for j = count*wallSegmentLength+1, (count+1)*wallSegmentLength do
			
				if j > points then
					continue = false				
					break
				else
					
					averagePosition.x = averagePosition.x + point[j].x
					averagePosition.z = averagePosition.z + point[j].z
					averagePosition.n = averagePosition.n + 1
					
					for lx = -16,16,8 do
						for lz = -16,16,8 do
							-- lx/lz steps through the points around the mousePoint
							if not area[point[j].x+lx][point[j].z+lz] then 
								-- check if the point will be terraformed be a previous block
								segment[n].point[pc] = {x = point[j].x+lx, z = point[j].z+lz}
								area[point[j].x+lx][point[j].z+lz] = true
								-- update border
								updateBorderWithPoint(segment[n].border, segment[n].point[pc].x, segment[n].point[pc].z)
								--[[if segment[n].point[pc].x-16 < .left then
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
								end--]]
								local currHeight = spGetGroundHeight(segment[n].point[pc].x, segment[n].point[pc].z)
								segment[n].point[pc].orHeight = currHeight
								segment[n].point[pc].prevHeight = currHeight
								if checkPointCreation(terraform_type, volumeSelection, currHeight, terraformHeight,
										spGetGroundOrigHeight(segment[n].point[pc].x, segment[n].point[pc].z),segment[n].point[pc].x, segment[n].point[pc].z) then
									pc = pc + 1
								end
							end
						end
					end
					
				end
			
			end
			
			-- discard segments with no new terraforming
			if pc ~= 1 then
				segment[n].position = {x = averagePosition.x/averagePosition.n, z = averagePosition.z/averagePosition.n}
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
	
	local frame = spGetGameFrame()

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
		local areaCost = 0
		local perimeterCost = 0
		
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
				areaCost = areaCost + (pointExtraAreaCostDepth > abs(segment[i].point[j].diffHeight) and abs(segment[i].point[j].diffHeight) or pointExtraAreaCostDepth)
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
				areaCost = areaCost + (pointExtraAreaCostDepth > abs(segment[i].point[j].diffHeight) and abs(segment[i].point[j].diffHeight) or pointExtraAreaCostDepth)
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
				areaCost = areaCost + (pointExtraAreaCostDepth > abs(segment[i].point[j].diffHeight) and abs(segment[i].point[j].diffHeight) or pointExtraAreaCostDepth)
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
				areaCost = areaCost + (pointExtraAreaCostDepth > abs(segment[i].point[j].diffHeight) and abs(segment[i].point[j].diffHeight) or pointExtraAreaCostDepth)
			end
		elseif terraform_type == 6 then
			for j = 1, segment[i].points do
				if not segment[i].area[segment[i].point[j].x] then
					segment[i].area[segment[i].point[j].x] = {}
				end
				currHeight = segment[i].point[j].orHeight
				segment[i].point[j].aimHeight = currHeight + bumpyFunc(segment[i].point[j].x,segment[i].point[j].z,volumeSelection)
				if segment[i].structureArea[segment[i].point[j].x] and segment[i].structureArea[segment[i].point[j].x][segment[i].point[j].z] then
					segment[i].point[j].diffHeight = 0.0001
					segment[i].point[j].structure = true
					--segment[i].area[segment[i].point[j].x][segment[i].point[j].z] = {orHeight = segment[i].point[j].orHeight,diffHeight = segment[i].point[j].diffHeight, building = true}
				else
					segment[i].point[j].diffHeight = segment[i].point[j].aimHeight-currHeight
					segment[i].area[segment[i].point[j].x][segment[i].point[j].z] = {orHeight = segment[i].point[j].orHeight,diffHeight = segment[i].point[j].diffHeight, building = false}
				end
				totalCost = totalCost + abs(segment[i].point[j].diffHeight)
				areaCost = areaCost + (pointExtraAreaCostDepth > abs(segment[i].point[j].diffHeight) and abs(segment[i].point[j].diffHeight) or pointExtraAreaCostDepth)
			end
		end
		
		-- Perimeter Cost
		local pyramidCostEstimate = 0
		
		for j = 1, segment[i].points do
			local x = segment[i].point[j].x
			local z = segment[i].point[j].z
			
			if segment[i].area[x] and segment[i].area[x][z] then
				
				local edgeCount = 0
				
				if (not segment[i].area[x+8]) or (not segment[i].area[x+8][z]) then
					edgeCount = edgeCount + 1
				end
				if (not segment[i].area[x-8]) or (not segment[i].area[x-8][z]) then
					edgeCount = edgeCount + 1
				end
				if (not segment[i].area[x][z+8]) then
					edgeCount = edgeCount + 1
				end
				if (not segment[i].area[x][z-8]) then
					edgeCount = edgeCount + 1
				end
				
				if perimeterEdgeCost[edgeCount] > 0 then
					perimeterCost = perimeterCost + perimeterEdgeCost[edgeCount]*(pointExtraPerimeterCostDepth > abs(segment[i].point[j].diffHeight) and abs(segment[i].point[j].diffHeight) or pointExtraPerimeterCostDepth)
				end
				
				if edgeCount > 0 then
					local height = abs(segment[i].point[j].diffHeight)
					if height > 30 then
						pyramidCostEstimate = pyramidCostEstimate + ((height - height%maxHeightDifference)*(floor(height/maxHeightDifference)-1)*0.5 + floor(height/maxHeightDifference)*(height%maxHeightDifference))*volumeCost
					end
				end
			end
		end
		
		if totalCost ~= 0 then
			local baseCost = areaCost*pointExtraAreaCost + perimeterCost*pointExtraPerimeterCost + baseTerraunitCost
			totalCost = totalCost*volumeCost + baseCost
			
			--Spring.Echo(totalCost .. "\t" .. baseCost)
			local pos = segment[i].position
			local terraunitX, teamY, terraunitZ = GetTerraunitLeashedSpot(team, pos.x, pos.z, unitsX, unitsZ)
			
			local id = spCreateUnit(terraunitDefID, terraunitX, teamY or 0, terraunitZ, 0, team, true)
			if not id then
				-- TODO: notify user? SendToUnsynced("terra_failed_unitlimit", team, terraunitX, terraunitZ) -> Script.LuaUI.something -> Spring.MarkerAddPoint
			else
				spSetUnitHealth(id, 0.01)
				setupTerraunit(id, team, terraunitX, false, terraunitZ)
				spSetUnitRulesParam(id, "terraformType", terraform_type)
			
				blocks = blocks + 1
				block[blocks] = id
				
				terraformUnitCount = terraformUnitCount + 1
				terraformOrder[terraformOrders].indexes = terraformOrder[terraformOrders].indexes + 1

				terraformUnit[id] = {
					positionAnchor = pos,
					position = {x = terraunitX, z = terraunitZ}, 
					progress = 0, 
					lastUpdate = 0, 
					totalSpent = 0,
					baseCostSpent = 0,
					cost = totalCost, 
					baseCost = baseCost,
					totalCost = totalCost,
					pyramidCostEstimate = pyramidCostEstimate,
					point = segment[i].point, 
					points = segment[i].points, 
					area = segment[i].area, 
					border = segment[i].border, 
					smooth = false, 
					intercepts = 0, 
					intercept = {}, 
					interceptMap = {},
					decayTime = frame + terraformDecayFrames, 
					allyTeam = unitAllyTeam,
					team = team,
					order = terraformOrders,
					orderIndex = terraformOrder[terraformOrders].indexes,
					fullyInitialised = false,
					lastProgress = 0,
					lastHealth = 0,
					disableForceCompletion = disableForceCompletion,
				}
				
				terraformUnitTable[terraformUnitCount] = id
				terraformOrder[terraformOrders].index[terraformOrder[terraformOrders].indexes] = terraformUnitCount
				
				SetTooltip(id, 0, pyramidCostEstimate + totalCost)
			end
		end
		
	end
	
	AddFallbackCommand(team, commandTag, blocks, block, commandX, commandZ)
end

local function TerraformArea(terraform_type, mPoint, mPoints, terraformHeight, unit, units, team, volumeSelection, shift, commandX, commandZ, commandTag, disableForceCompletion)

	local border = {left = mapWidth, right = 0, top = mapHeight, bottom = 0} -- border for the entire area
	
	--** Initial constructor processing **
	local unitsX, unitsZ = GetUnitAveragePosition(unit, units)
	if not unitsX then
		unitsX, unitsZ = commandX, commandZ
	end
	
	
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
	updateBorderWithPoint(border, point[points].x, point[points].z)
	
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
			updateBorderWithPoint(border, point[points].x, point[points].z)
		else
			-- interpolate between far apart points to prevent loop holes.
			if a_diffX > a_diffZ then
				local m = diffZ/diffX
				local sign = diffX/a_diffX
				for j = 0, a_diffX, 16 do	
					points = points + 1
					point[points] = {x = mPoint[i].x - j*sign, z = floor((mPoint[i].z - j*m*sign)/16)*16}
					updateBorderWithPoint(border, point[points].x, point[points].z)
				end
			else
				local m = diffX/diffZ
				local sign = diffZ/a_diffZ
				for j = 0, a_diffZ, 16 do	
					points = points + 1
					point[points] = {x = floor((mPoint[i].x - j*m*sign)/16)*16, z = mPoint[i].z - j*sign}
					updateBorderWithPoint(border, point[points].x, point[points].z)
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
	
	local wCount = ceil((border.right-border.left)/areaSegMaxSize) - 1
	local hCount = ceil((border.bottom-border.top)/areaSegMaxSize) - 1
	-- w/hCount is the number of segments that fit into the width/height
	local addX = 0
	-- addX and addZ prevent overlap
	local n = 1 -- segment count
	for i = 0, wCount do
		local addZ = 0
		for j = 0, hCount do
			-- i and j step through possible segments based on splitting the rectangular area into rectangles
			segment[n] = {}
			segment[n].grid = {x = i, z = j}
			segment[n].point = {}
			segment[n].area = {}
			segment[n].border = {left = mapWidth, right = 0, top = mapHeight, bottom = 0}
			local totalX = 0
			local totalZ = 0
			-- totalX/Z is used to find the average position of the segment
			local m = 1 -- number of points in the segment
			for lx = border.left + floor(width * i/8)*8 + addX, border.left + floor(width * (i+1)/8)*8, 16 do
				for lz = border.top + floor(height * j/8)*8 + addZ, border.top + floor(height * (j+1)/8)*8, 16 do
					-- lx/lz steps though all 16x16 points
					if area[floor(lx/16)*16][floor(lz/16)*16] then
						--Spring.MarkerAddLine(floor(lx/16)*16-2,0,floor(lz/16)*16-2, floor(lx/16)*16+2,0,floor(lz/16)*16+2)
						--Spring.MarkerAddLine(floor(lx/16)*16-2,0,floor(lz/16)*16+2, floor(lx/16)*16+2,0,floor(lz/16)*16-2)
						
						-- fill in the top, left and middle
						for x = lx, lx+8, 8 do
							for z = lz, lz+8, 8 do
								local currHeight = spGetGroundHeight(x, z)
								if checkPointCreation(terraform_type, volumeSelection, currHeight, terraformHeight,spGetGroundOrigHeight(x, z), x, z) then
									segment[n].point[m] = {x = x, z = z, orHeight = currHeight, prevHeight = currHeight}
									m = m + 1
									totalX = totalX + x
									totalZ = totalZ + z
									updateBorderWithPoint(segment[n].border, x, z)
								end
							end
						end
						
						local right = not area[floor(lx/16)*16+16][floor(lz/16)*16]
						local bottom = not area[floor(lx/16)*16][floor(lz/16)*16+16]
						
						-- fill in bottom right if it is missing
						if right and bottom then
							local currHeight = spGetGroundHeight(lx+16, lz+16)
							if checkPointCreation(terraform_type, volumeSelection, currHeight, terraformHeight,spGetGroundOrigHeight(lx+16, lz+16), lx+16, lz+16) then
								segment[n].point[m] = {x = lx+16, z = lz+16, orHeight = currHeight, prevHeight = currHeight}
								m = m + 1
								totalX = totalX + lx+16
								totalZ = totalZ + lz+16
								updateBorderWithPoint(segment[n].border, lx+16, lz+16)
							end
						end
							
						if right then
							for z = lz, lz+8, 8 do
								local currHeight = spGetGroundHeight(lx+16, z)
								if checkPointCreation(terraform_type, volumeSelection, currHeight, terraformHeight,spGetGroundOrigHeight(lx+16, z), lx+16, z) then
									segment[n].point[m] = {x = lx+16, z = z, orHeight = currHeight, prevHeight = currHeight}
									m = m + 1
									totalX = totalX + lx+16
									totalZ = totalZ + z
									updateBorderWithPoint(segment[n].border, lx+16, z)
								end
							end
						end
						
						if bottom then
							for x = lx, lx+8, 8 do
								local currHeight = spGetGroundHeight(x, lz+16)
								if checkPointCreation(terraform_type, volumeSelection, currHeight, terraformHeight,spGetGroundOrigHeight(x, lz+16), x, lz+16) then
									segment[n].point[m] = {x = x, z = lz+16, orHeight = currHeight, prevHeight = currHeight}
									m = m + 1
									totalX = totalX + x
									totalZ = totalZ + lz+16
									updateBorderWithPoint(segment[n].border, x, lz+16)
								end
							end
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

	local frame = spGetGameFrame()
	
	local unitIdGrid = {}
	local aveX = 0
	local aveZ = 0
	
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
		local areaCost = 0
		local perimeterCost = 0
		
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
				areaCost = areaCost + (pointExtraAreaCostDepth > abs(segment[i].point[j].diffHeight) and abs(segment[i].point[j].diffHeight) or pointExtraAreaCostDepth)
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
				totalCost = totalCost + abs(segment[i].point[j].diffHeight)
				areaCost = areaCost + (pointExtraAreaCostDepth > abs(segment[i].point[j].diffHeight) and abs(segment[i].point[j].diffHeight) or pointExtraAreaCostDepth)
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
				areaCost = areaCost + (pointExtraAreaCostDepth > abs(segment[i].point[j].diffHeight) and abs(segment[i].point[j].diffHeight) or pointExtraAreaCostDepth)
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
				areaCost = areaCost + (pointExtraAreaCostDepth > abs(segment[i].point[j].diffHeight) and abs(segment[i].point[j].diffHeight) or pointExtraAreaCostDepth)
			end
		elseif terraform_type == 6 then
			for j = 1, segment[i].points do
				if not segment[i].area[segment[i].point[j].x] then
					segment[i].area[segment[i].point[j].x] = {}
				end
				local currHeight = segment[i].point[j].orHeight
				segment[i].point[j].aimHeight = currHeight + bumpyFunc(segment[i].point[j].x,segment[i].point[j].z,volumeSelection)
				if segment[i].structureArea[segment[i].point[j].x] and segment[i].structureArea[segment[i].point[j].x][segment[i].point[j].z] then
					segment[i].point[j].diffHeight = 0.0001
					segment[i].point[j].structure = true
					--segment[i].area[segment[i].point[j].x][segment[i].point[j].z] = {orHeight = segment[i].point[j].orHeight,diffHeight = segment[i].point[j].diffHeight, building = true}
				else
					segment[i].point[j].diffHeight = segment[i].point[j].aimHeight-currHeight
					segment[i].area[segment[i].point[j].x][segment[i].point[j].z] = {orHeight = segment[i].point[j].orHeight,diffHeight = segment[i].point[j].diffHeight, building = false}
				end
				totalCost = totalCost + abs(segment[i].point[j].diffHeight)
				areaCost = areaCost + (pointExtraAreaCostDepth > abs(segment[i].point[j].diffHeight) and abs(segment[i].point[j].diffHeight) or pointExtraAreaCostDepth)
			end
			
		end
		
		-- Perimeter Cost
		local pyramidCostEstimate = 0 -- just for UI
		
		for j = 1, segment[i].points do
			local x = segment[i].point[j].x
			local z = segment[i].point[j].z
			
			if segment[i].area[x] and segment[i].area[x][z] then
				
				local edgeCount = 0
				
				if (not segment[i].area[x+8]) or (not segment[i].area[x+8][z]) then
					edgeCount = edgeCount + 1
				end
				if (not segment[i].area[x-8]) or (not segment[i].area[x-8][z]) then
					edgeCount = edgeCount + 1
				end
				if (not segment[i].area[x][z+8]) then
					edgeCount = edgeCount + 1
				end
				if (not segment[i].area[x][z-8]) then
					edgeCount = edgeCount + 1
				end
				
				if perimeterEdgeCost[edgeCount] > 0 then
					perimeterCost = perimeterCost + perimeterEdgeCost[edgeCount]*(pointExtraPerimeterCostDepth > abs(segment[i].point[j].diffHeight) and abs(segment[i].point[j].diffHeight) or pointExtraPerimeterCostDepth)
				end
				
				if edgeCount > 0 then
					local diffHeight = abs(segment[i].point[j].diffHeight)
					if diffHeight > 30 then
						pyramidCostEstimate = pyramidCostEstimate + ((diffHeight - diffHeight%maxHeightDifference)*(floor(diffHeight/maxHeightDifference)-1)*0.5 + floor(diffHeight/maxHeightDifference)*(diffHeight%maxHeightDifference))*volumeCost
					end
				end
			end
		end
		
		if totalCost ~= 0 then
			local baseCost = areaCost*pointExtraAreaCost + perimeterCost*pointExtraPerimeterCost + baseTerraunitCost
			totalCost = totalCost*volumeCost + baseCost
			
			--Spring.Echo("Total Cost", totalCost, "Area Cost", areaCost*pointExtraAreaCost, "Perimeter Cost", perimeterCost*pointExtraPerimeterCost)
			local pos = segment[i].position
			local terraunitX, teamY, terraunitZ = GetTerraunitLeashedSpot(team, pos.x, pos.z, unitsX, unitsZ)
			
			local id = spCreateUnit(terraunitDefID, terraunitX, teamY or 0, terraunitZ, 0, team, true)
			
            if id then
				spSetUnitHealth(id, 0.01)
				unitIdGrid[segment[i].grid.x] = unitIdGrid[segment[i].grid.x] or {}
				unitIdGrid[segment[i].grid.x][segment[i].grid.z] = id
				
				aveX = aveX + segment[i].position.x
				aveZ = aveZ + segment[i].position.z
				
				setupTerraunit(id, team, terraunitX, false, terraunitZ)
				spSetUnitRulesParam(id, "terraformType", terraform_type)
			
				blocks = blocks + 1
				block[blocks] = id
				
				terraformUnitCount = terraformUnitCount + 1
				terraformOrder[terraformOrders].indexes = terraformOrder[terraformOrders].indexes + 1

				terraformUnit[id] = {
					positionAnchor = pos,
					position = {x = terraunitX, z = terraunitZ}, 
					progress = 0, 
					lastUpdate = 0, 
					totalSpent = 0,
					baseCostSpent = 0,
					cost = totalCost, 
					baseCost = baseCost,
					totalCost = totalCost,
					pyramidCostEstimate = pyramidCostEstimate,
					point = segment[i].point, 
					points = segment[i].points,
					area = segment[i].area, 
					border = segment[i].border, 
					smooth = false, 
					intercepts = 0, 
					intercept = {}, 
					interceptMap = {},
					decayTime = frame + terraformDecayFrames, 
					allyTeam = unitAllyTeam,
					team = team,
					order = terraformOrders,
					orderIndex = terraformOrder[terraformOrders].indexes,
					fullyInitialised = false,
					lastProgress = 0,
					lastHealth = 0,
					disableForceCompletion = disableForceCompletion,
				}

				terraformUnitTable[terraformUnitCount] = id
				terraformOrder[terraformOrders].index[terraformOrder[terraformOrders].indexes] = terraformUnitCount
				
				SetTooltip(id, 0, pyramidCostEstimate + totalCost)
			end
		end
		
	end
	
	--** Give repair order for each block to all selected units **
	if terraformOrder[terraformOrders].indexes == 0 then
		return
	end
	
	aveX = aveX/terraformOrder[terraformOrders].indexes
	aveZ = aveZ/terraformOrder[terraformOrders].indexes
	
	local orderList = {data = {}, count = 0}
	
	if unitsX < unitsZ - aveZ + aveX then -- left or top
		if unitsX < -unitsZ + aveZ + aveX then -- left
			local zig = 0
			if unitsZ > aveZ then  -- 4th octant
				zig = 1
			end
			for gx = 0, wCount do
				for gz = 0 + hCount*zig, hCount*(1-zig), 1-zig*2 do
					if unitIdGrid[gx] and unitIdGrid[gx][gz] then
						orderList.count = orderList.count + 1
						orderList.data[orderList.count] = unitIdGrid[gx][gz]
					end
				end
				zig = 1 - zig
			end
		else -- top
			local zig = 0
			if unitsX > aveX then  -- 2nd octant
				zig = 1
			end
			for gz = hCount, 0, -1 do
				for gx = 0 + wCount*zig, wCount*(1-zig), 1-zig*2 do
					if unitIdGrid[gx] and unitIdGrid[gx][gz] then
						orderList.count = orderList.count + 1
						orderList.data[orderList.count] = unitIdGrid[gx][gz]
					end
				end
				zig = 1 - zig
			end
		end
	else -- bottom or right
		if unitsX < -unitsZ + aveZ + aveX then -- bottom
			local zig = 0
			if unitsX > aveX then  -- 7th octant
				zig = 1
			end
			for gz = 0, hCount do
				for gx = 0 + wCount*zig, wCount*(1-zig), 1-zig*2 do
					if unitIdGrid[gx] and unitIdGrid[gx][gz] then
						orderList.count = orderList.count + 1
						orderList.data[orderList.count] = unitIdGrid[gx][gz]
					end
				end
				zig = 1 - zig
			end
		else -- right
			local zig = 0
			if unitsZ > aveZ then  -- 1st octant
				zig = 1
			end
			for gx = wCount, 0, -1  do
				for gz = 0 + hCount*zig, hCount*(1-zig), 1-zig*2 do
					if unitIdGrid[gx] and unitIdGrid[gx][gz] then
						orderList.count = orderList.count + 1
						orderList.data[orderList.count] = unitIdGrid[gx][gz]
					end
				end
				zig = 1 - zig
			end
		end
	end
	
	if orderList.count == 0 then
		return
	end
	
	AddFallbackCommand(team, commandTag, orderList.count, orderList.data, commandX, commandZ)
end

--------------------------------------------------------------------------------
-- Recieve Terraform command from UI widget
--------------------------------------------------------------------------------

function gadget:AllowCommand_GetWantedCommand()
	return wantedCommands
end

function gadget:AllowCommand_GetWantedUnitDefID()
	return true
end

function gadget:AllowCommand(unitID, unitDefID, teamID, cmdID, cmdParams, cmdOptions)
	-- Don't allow non-constructors to queue terraform fallback.
	if fallbackableCommands[cmdID] and not terraformUnitDefIDs[unitDefID] then
		return false
	end

	if (cmdID == CMD_TERRAFORM_INTERNAL) then
		if GG.terraformRequiresUnlock and not GG.terraformUnlocked[teamID] then
			return false
		end
		
		local terraform_type = cmdParams[1]
		local commandX = cmdParams[3]
		local commandZ = cmdParams[4]
		local commandTag = cmdParams[5]
		local loop = cmdParams[6]
		local terraformHeight = cmdParams[7]
		local pointCount = cmdParams[8]
		local constructorCount = cmdParams[9]
		local volumeSelection = cmdParams[10]
		
		--level or raise or smooth or restore or bumpify
		if terraform_type == 1 or terraform_type == 2 or terraform_type == 3 or terraform_type == 5 then --or terraform_type == 6 then 
			local point = {}
			local unit = {}
			local i = 11
			for j = 1, pointCount do
				point[j] = {x = cmdParams[i], z = cmdParams[i+1]}
				i = i + 2
			end
			for j = 1, constructorCount do
				unit[j] = cmdParams[i]
				i = i + 1
			end
			
			if loop == 0 then
				TerraformWall(terraform_type, point, pointCount, terraformHeight, unit, constructorCount, teamID, volumeSelection, cmdOptions.shift, commandX, commandZ, commandTag)
			else
				TerraformArea(terraform_type, point, pointCount, terraformHeight, unit, constructorCount, teamID, volumeSelection, cmdOptions.shift, commandX, commandZ, commandTag)
			end
			
			return false

		elseif terraform_type == 4 then --ramp
		
			local point = {}
			local unit = {}
			local i = 11
			for j = 1, pointCount do
				point[j] = {x = cmdParams[i], y = cmdParams[i+1],z = cmdParams[i+2]}
				i = i + 3
			end
			for j = 1, constructorCount do
				unit[j] = cmdParams[i]
				i = i + 1
			end
			
			TerraformRamp(point[1].x,point[1].y,point[1].z,point[2].x,point[2].y,point[2].z,terraformHeight*2,unit, constructorCount,teamID, volumeSelection, cmdOptions.shift, commandX, commandZ, commandTag)
		
			return false
		end
  end
  return true -- allowed
end

--------------------------------------------------------------------------------
-- Sudden Death Mode
--------------------------------------------------------------------------------

function GG.Terraform_RaiseWater(raiseAmount)
	
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
			local commands = spGetCommandQueue(allUnits[i], -1)
			local commandsCount = #commands
			for j = 1, commandsCount do
			
			end
		end
	end
	--]]
	spAdjustHeightMap(0, 0, mapWidth, mapHeight, -raiseAmount)
	
	Spring.SetGameRulesParam("waterLevelModifier", raiseAmount)
	
	local features = Spring.GetAllFeatures()
	for i = 1, #features do
		local featureID = features[i]
		local fx, fy, fz = Spring.GetFeaturePosition(featureID)
		if featureID and fy then
			Spring.SetFeaturePosition(featureID, fx, fy - raiseAmount, fz, true)
		end
	end
end

--------------------------------------------------------------------------------
-- Handle terraunit
--------------------------------------------------------------------------------

local function deregisterTerraformUnit(id,terraformIndex,origin)
	
	if not terraformUnit[id] then
		Spring.Log(gadget:GetInfo().name, LOG.ERROR, "Terraform:")
		Spring.Log(gadget:GetInfo().name, LOG.ERROR, "Attempted to remove nil terraform ID")
		Spring.Log(gadget:GetInfo().name, LOG.ERROR, "Error Tpye " .. origin)
		Spring.Log(gadget:GetInfo().name, LOG.ERROR, "Tell Google Frog")
		return
	end
	
	--Removed Intercept Check
	--if not terraformUnit[id].intercepts then
	--	Spring.Echo("Terraform:")
	--	Spring.Echo("Attempted to index terraformUnit with wrong id")
	--	Spring.Echo("Tell Google Frog")
	--	return
	--end
	----Spring.MarkerAddPoint(terraformUnit[id].position.x,0,terraformUnit[id].position.z,"Spent " .. terraformUnit[id].totalSpent)
	--
	-- remove from intercepts tables 
	--for j = 1, terraformUnit[id].intercepts do -- CRASH ON THIS LINE -- not for a while though
	--	local oid = terraformUnit[id].intercept[j].id
	--	local oindex = terraformUnit[id].intercept[j].index
	--	if oindex < terraformUnit[oid].intercepts then
	--		terraformUnit[terraformUnit[oid].intercept[terraformUnit[oid].intercepts].id].intercept[terraformUnit[oid].intercept[terraformUnit[oid].intercepts].index].index = oindex
	--		terraformUnit[oid].intercept[oindex] = terraformUnit[oid].intercept[terraformUnit[oid].intercepts]
	--	end
	--	terraformUnit[oid].intercept[terraformUnit[oid].intercepts] = nil
	--	terraformUnit[oid].intercepts = terraformUnit[oid].intercepts - 1
	--	terraformUnit[oid].interceptMap[id] = nil
	--end
		
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

local function CheckThickness(x, z, area)
	-- This function returns whether the terraform point has sufficient nearby points 
	-- for the terraform to not be considered too thin.

	if x%16 == 8 then
		if z%16 == 8 then
			local north = area[x] and (area[x][z-16] ~= nil)
			local northEast = area[x+16] and (area[x+16][z-16] ~= nil)
			local east = area[x+16] and (area[x+16][z] ~= nil)
			if north and northEast and east then
				return true
			end
			local southEast = area[x+16] and (area[x+16][z+16] ~= nil)
			if northEast and east and southEast then
				return true
			end
			local south = area[x] and (area[x][z+16] ~= nil)
			if east and southEast and south then
				return true
			end
			local southWest = area[x-16] and (area[x-16][z+16] ~= nil)
			if southEast and south and southWest then
				return true
			end
			local west = area[x-16] and (area[x-16][z] ~= nil)
			if south and southWest and west then
				return true
			end
			local northWest = area[x-16] and (area[x-16][z-16] ~= nil)
			if southWest and west and northWest then
				return true
			end
			if west and northWest and north then
				return true
			end
			if northWest and north and northEast then
				return true
			end
		else
			return (area[x] and (area[x][z-8] ~= nil)) or (area[x] and (area[x][z+8] ~= nil))
		end
	elseif z%16 == 8 then
		return (area[x-8] and (area[x-8][z] ~= nil)) or (area[x+8] and (area[x+8][z] ~= nil))
	else
		if area[x-8] and (area[x-8][z-8] ~= nil) then
			return true
		end
		if area[x-8] and (area[x-8][z+8] ~= nil) then
			return true
		end
		if area[x+8] and (area[x+8][z-8] ~= nil) then
			return true
		end
		if area[x+8] and (area[x+8][z+8] ~= nil) then
			return true
		end
	end
	return false
end

local function updateTerraformCost(id)
	local terra = terraformUnit[id]

	local checkAreaRemoved = true
	local areaRemoved = false
	while checkAreaRemoved do
		checkAreaRemoved = false
		for i = 1, terra.points do
			local point = terra.point[i]
			if not point.structure then
				local x = point.x
				local z = point.z
				
				if not CheckThickness(x, z, terra.area) then
					if terra.area[x] and terra.area[x][z] then
						terra.area[x][z] = nil
					end
					point.structure = 1		
					areaRemoved = true
					checkAreaRemoved = true
				end
			end		
		end
	end
	
	if areaRemoved then
		updateTerraformEdgePoints(id)
	end
	
	local volume = 0
	for i = 1, terra.points do
		local point = terra.point[i]
		local x = point.x
		local z = point.z
		
		local height = spGetGroundHeight(x,z)
		point.orHeight = height
		if point.structure == 1 then
			point.diffHeight = 0
		elseif point.structure then
			point.diffHeight = 0
		else
			point.diffHeight = point.aimHeight - height 
		end
		volume = volume + abs(point.diffHeight) 
	end
	
	spSetUnitHealth(id, {
		health = 0,
		build  = 0
	})
	
	if volume < 0.0001 then
		-- Destroying the terraform here would enable structure-detecting maphax.
		volume = 0.0001
		terra.toRemove = true
	end

	terra.lastProgress = 0
	terra.lastHealth = 0
	terra.progress = 0
	terra.cost = volume*volumeCost
	terra.totalCost = terra.cost + terra.baseCost
	
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
	
	--checkTerraformIntercepts(id) --Removed Intercept Check
	
	updateTerraformEdgePoints(id)
	updateTerraformCost(id)
	
	--Spring.MarkerAddPoint(terraformUnit[id].position.x,0,terraformUnit[id].position.z,"Base " .. terraformUnit[id].baseCost)
	--Spring.MarkerAddPoint(terraformUnit[id].position.x,0,terraformUnit[id].position.z,"Cost " .. terraformUnit[id].cost)
	--Spring.MarkerAddPoint(terraformUnit[id].position.x,0,terraformUnit[id].position.z,"Points " .. terraformUnit[id].points)
	terraformUnit[id].fullyInitialised = true

end

local function addSteepnessMarker(team, x, z)
	local n = spGetGameFrame()
	if steepnessMarkers.inner.frame ~= n then
		steepnessMarkers.inner = {count = 0, data = {}, frame = n}
	end
	Spring.Echo(steepnessMarkers.inner.frame)
	steepnessMarkers.inner.count = steepnessMarkers.inner.count+1
	steepnessMarkers.inner.data[steepnessMarkers.inner.count] = {team = team, x = x, z = z}
end

local function updateTerraform(health,id,arrayIndex,costDiff)
	local terra = terraformUnit[id]
	
	if terra.toRemove and terra.totalSpent > 0.1 then
		-- Removing terraform too early enables structure-detecting maphax.
		deregisterTerraformUnit(id,arrayIndex,2)
		spDestroyUnit(id, false, true)
		return 0
	end
	
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
			
			--[[ naive ground drawing
			local drawingList = {}
			for i = 1, terra.points do
				local x = terra.point[i].x
				local z = terra.point[i].z
				drawingList[#drawingList+1] = {x = x, z = z, tex = 1}
			end
			GG.Terrain_Texture_changeBlockList(drawingList)
			--]]
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
	
	for i = 1, terra.points do
		local heightDiff = terra.point[i].prevHeight - spGetGroundHeight(terra.point[i].x, terra.point[i].z)
		if heightDiff ~= 0 then
			updateTerraformCost(id)
			break
			-- There must be a nicer way to update costs, below is an unstable attempt.
			--local change = ((1-terra.progress)*terra.point[i].diffHeight + heightDiff)/((1-terra.progress)*terra.point[i].diffHeight)
			--Spring.Echo(change)
			--local costChange = (abs(change * terra.point[i].diffHeight) - abs(terra.point[i].diffHeight))*volumeCost
			--terra.point[i].diffHeight = change * terra.point[i].diffHeight
			--terra.point[i].orHeight = terra.point[i].aimHeight - terra.point[i].diffHeight
			--terraformUnit[id].cost = terraformUnit[id].cost + costChange
			--terraformUnit[id].totalCost = terraformUnit[id].totalCost + costChange
		end
	end
	
	local newProgress = terra.progress + costDiff/terra.totalCost
	if newProgress> 1 then
		newProgress = 1
	end
	
	local addedCost = 0
	local extraPoint = {}
	local extraPoints = 0
	local extraPointArea = {}
	
	--[[
	for i = 1, terra.points do
		if terra.point[i].edges then
			for j = 1, terra.point[i].edges do
			
				local x = terra.point[i].edge[j].x
				local z = terra.point[i].edge[j].z
				
				Spring.MarkerAddLine(x-2,0,z-2, x+2,0,z+2)
				Spring.MarkerAddLine(x-2,0,z+2, x+2,0,z-2)
				
			end
		end
	end
	--]]
	
	for i = 1, terra.points do
		if terra.point[i].edges then
			local newHeight = terra.point[i].orHeight+(terra.point[i].aimHeight-terra.point[i].orHeight)*newProgress
			local up = terra.point[i].aimHeight-terra.point[i].orHeight > 0
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
				if diffHeight > maxHeightDifference and up then
				
					local index = extraPoints + 1
					if overlap then
						if not extraPoint[overlap].pyramid then
							addSteepnessMarker(terra.team, terra.position.x,terra.position.z)
							deregisterTerraformUnit(id,arrayIndex,2)
							spDestroyUnit(id, false, true)
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
					--updateTerraformBorder(id,x,z) --Removed Intercept Check
					
					if structureAreaMap[x] and structureAreaMap[x][z] then
						if terra.area[terra.point[i].x] and terra.area[terra.point[i].x][terra.point[i].z] then
							terra.area[terra.point[i].x][terra.point[i].z] = false
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

				elseif diffHeight < -maxHeightDifference and not up then
					
					local index = extraPoints + 1
					if overlap then
						if extraPoint[overlap].pyramid then
							addSteepnessMarker(terra.team, terra.position.x,terra.position.z)
							deregisterTerraformUnit(id,arrayIndex,2)
							spDestroyUnit(id, false, true)
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
					--updateTerraformBorder(id,x,z) --Removed Intercept Check
					
					if structureAreaMap[x] and structureAreaMap[x][z] then
						if terra.area[terra.point[i].x] and terra.area[terra.point[i].x][terra.point[i].z] then
							terra.area[terra.point[i].x][terra.point[i].z] = false
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
	
	do local i = 1
	while i <= extraPoints do
		local newHeight = extraPoint[i].supportH
		-- diamond pyramids
		--local maxHeightDifferenceLocal = (abs(extraPoint[i].x-extraPoint[i].supportX) + abs(extraPoint[i].z-extraPoint[i].supportZ))*maxHeightDifference/8+maxHeightDifference
		-- circular pyramids
		local maxHeightDifferenceLocal = sqrt((extraPoint[i].x-extraPoint[i].supportX)^2 + (extraPoint[i].z-extraPoint[i].supportZ)^2)*maxHeightDifference/8+maxHeightDifference 
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
				if diffHeight > maxHeightDifferenceLocal and extraPoint[i].pyramid then
					local index = extraPoints + 1
					if overlap then
						if not extraPoint[overlap].pyramid then
							addSteepnessMarker(terra.team, terra.position.x,terra.position.z)
							deregisterTerraformUnit(id,arrayIndex,2)
							spDestroyUnit(id, false, true)
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
					--updateTerraformBorder(id,x,z) --Removed Intercept Check
					
					if structureAreaMap[x] and structureAreaMap[x][z] then
						if terra.area[extraPoint[index].supportX] and terra.area[extraPoint[index].supportX][extraPoint[index].supportZ] then
							terra.area[extraPoint[index].supportX][extraPoint[index].supportZ] = false
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

				elseif diffHeight < -maxHeightDifferenceLocal and not extraPoint[i].pyramid then
					local index = extraPoints + 1
					if overlap then
						if extraPoint[overlap].pyramid then
							addSteepnessMarker(terra.team, terra.position.x,terra.position.z)
							deregisterTerraformUnit(id,arrayIndex,2)
							spDestroyUnit(id, false, true)
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
					--updateTerraformBorder(id,x,z) --Removed Intercept Check
					
					if structureAreaMap[x] and structureAreaMap[x][z] then
						if terra.area[extraPoint[index].supportX] and terra.area[extraPoint[index].supportX][extraPoint[index].supportZ] then
							terra.area[extraPoint[index].supportX][extraPoint[index].supportZ] = false -- false for edge-derived problems
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
			Spring.Log(gadget:GetInfo().name, LOG.WARNING, "spire wall break")
			break -- safty
		end
		i = i + 1
	end end
	
	terraformOperations = terraformOperations + extraPoints
	
	local oldCostDiff = costDiff
	
	local edgeTerraMult = 1
	if costDiff ~= 0 then
		if addedCost == 0 then
			terra.progress = terra.progress + costDiff/terra.totalCost
		else
			local extraCost = 0
			
			if terra.progress + costDiff/terra.cost > 1 then
				extraCost = costDiff - terra.cost*(1 - terra.progress)
				costDiff = (1 - terra.progress)*terra.cost
			end
			
			addedCost = addedCost*volumeCost
			
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
		Spring.Log(gadget:GetInfo().name, LOG.ERROR, "Terraform:")
		Spring.Log(gadget:GetInfo().name, LOG.ERROR, "edgeTerraMult > 1 THIS IS VERY BAD")
		Spring.Log(gadget:GetInfo().name, LOG.ERROR, "Tell Google Frog")
	end
	
	local progress = terra.progress
	if terra.progress > 1 then
		progress = 1
		edgeTerraMult = 1
	end

	local newBuild = terra.progress
	
	spSetUnitHealth(id, {
		health = newBuild*terraUnitHP,
		build  = newBuild
	})
	
	terra.lastHealth = newBuild*terraUnitHP
	terra.lastProgress = newBuild

	-- Bug Safety
	for i = 1, extraPoints do
		if abs(extraPoint[i].orHeight + extraPoint[i].heightDiff*edgeTerraMult) > 3000 then
			Spring.Log(gadget:GetInfo().name, LOG.WARNING, "Terraform:")
			Spring.Log(gadget:GetInfo().name, LOG.WARNING, "Strange pyramid construction")
			Spring.Log(gadget:GetInfo().name, LOG.WARNING, "Destroying Terraform Unit")
			deregisterTerraformUnit(id,arrayIndex,2)
			spDestroyUnit(id, false, true)
			return 0
		end
	end
	
	local func = function()
		for i = 1, terra.points do
			local height = terra.point[i].orHeight+terra.point[i].diffHeight*progress
			spSetHeightMap(terra.point[i].x,terra.point[i].z, height)
			terra.point[i].prevHeight = height
		end 
		for i = 1, extraPoints do
			spSetHeightMap(extraPoint[i].x,extraPoint[i].z,extraPoint[i].orHeight + extraPoint[i].heightDiff*edgeTerraMult)
		end
	end
	spSetHeightMapFunc(func)

	-- Draw the changes
	if USE_TERRAIN_TEXTURE_CHANGE then
		local drawingList = {}
		for i = 1, terra.points do
			local x = terra.point[i].x
			local z = terra.point[i].z
			local freeLeft = not (terra.area[x-8] and terra.area[x-8][z]) and not (extraPointArea[x-8] and extraPointArea[x-8][z])
			local freeUp = not (terra.area[x] and terra.area[x][z-8]) and not (extraPointArea[x] and extraPointArea[x][z-8])
			local freeRight = not (terra.area[x+8] and terra.area[x+8][z]) and not (extraPointArea[x+8] and extraPointArea[x+8][z])
			local freeDown = not (terra.area[x] and terra.area[x][z+8]) and not (extraPointArea[x] and extraPointArea[x][z+8])
			drawingList[#drawingList+1] = {x = x, z = z, tex = 1, edge = freeRight or freeDown}
			if freeLeft then
				drawingList[#drawingList+1] = {x = x-8, z = z, tex = 1, edge = true}
			end
			if freeUp then
				drawingList[#drawingList+1] = {x = x, z = z-8, tex = 1, edge = true}
				if freeLeft then
					drawingList[#drawingList+1] = {x = x-8, z = z-8, tex = 1, edge = true}
				end
			end
		end
		for i = 1, extraPoints do
			local x = extraPoint[i].x
			local z = extraPoint[i].z
			local freeLeft = not (extraPointArea[x-8] and extraPointArea[x-8][z])
			local freeUp = not (terra.area[x] and terra.area[x][z-8]) and not (extraPointArea[x] and extraPointArea[x][z-8])
			drawingList[#drawingList+1] = {x = x, z = z, tex = 2}
			if freeLeft then
				drawingList[#drawingList+1] = {x = x-8, z = z, tex = 2}
			end
			if freeUp then
				drawingList[#drawingList+1] = {x = x, z = z-8, tex = 2}
				if freeLeft then
					drawingList[#drawingList+1] = {x = x-8, z = z-8, tex = 2}
				end
			end
		end
		
		for i = 1, #drawingList do
			local x = drawingList[i].x+4
			local z = drawingList[i].z+4
			local edge = drawingList[i].edge
			drawingList[i].edge = nil -- don't sent to other gadget to send to unsynced
			-- edge exists because raised walls have passability at higher normal than uniform ramps
			local oHeight = spGetGroundOrigHeight(x,z)
			local height = spGetGroundHeight(x,z)
			if abs(oHeight-height) < 1 then
				drawingList[i].tex = 0
			else
				local normal = select(2,Spring.GetGroundNormal(x,z))
				if (edge and normal > 0.8) or (not edge and  normal > 0.892) then
					drawingList[i].tex = 1
				elseif (edge and normal > 0.41) or (not edge and normal > 0.585) then
					drawingList[i].tex = 2
				else
					drawingList[i].tex = 3
				end
			end
		end
		
		GG.Terrain_Texture_changeBlockList(drawingList)
	end
	
	--Removed Intercept Check
	--if terraformUnit[id].intercepts ~= 0 then
	--	local i = 1
	--	while i <= terra.intercepts  do
	--		local test = updateTerraformCost(terra.intercept[i].id)
	--		if test then
	--			i = i + 1
	--		end
	--	end
	--end
	
	if terra.progress > 1 then
		deregisterTerraformUnit(id,arrayIndex,2)
		spDestroyUnit(id, false, true)
		return 0
	end
	
	return 1
end

local function DoTerraformUpdate(n, forceCompletion)
	local i = 1
	while i <= terraformUnitCount do
		local id = terraformUnitTable[i]
		if (spValidUnitID(id)) then
			local force = (forceCompletion and not terraformUnit[id].disableForceCompletion)
			
			local health = spGetUnitHealth(id)
			local diffProgress = health/terraUnitHP - terraformUnit[id].progress
			
			if diffProgress == 0 then
				if (not forceCompletion) and (n % decayCheckFrequency == 0 and terraformUnit[id].decayTime < n) then
					deregisterTerraformUnit(id,i,3)
					spDestroyUnit(id, false, true)
				else
					i = i + 1
				end
			else
			
				if not terraformUnit[id].fullyInitialised then
					finishInitialisingTerraformUnit(id,i)
				end
				
				if force or (n - terraformUnit[id].lastUpdate >= updatePeriod) then
					local costDiff = health - terraformUnit[id].lastHealth
					if force then
						costDiff = costDiff + 100000 -- enough?
					end
					terraformUnit[id].totalSpent = terraformUnit[id].totalSpent + costDiff
					SetTooltip(id, terraformUnit[id].totalSpent, terraformUnit[id].pyramidCostEstimate + terraformUnit[id].totalCost)
					
					if GG.Awards and GG.Awards.AddAwardPoints then
						GG.Awards.AddAwardPoints('terra', terraformUnit[id].team, costDiff)
					end
					
					local updateVar = updateTerraform(health,id,i,costDiff) 
					while updateVar == -1 do
						if updateTerraformCost(id) then
							updateTerraformEdgePoints(id)
							updateVar = updateTerraform(health,id,i,costDiff) 
						else
							updateVar = 0
						end
					end
					
					if updateVar == 1 then
						if n then
							terraformUnit[id].lastUpdate = n
						end
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
end

function gadget:GameFrame(n)

	if workaround_recursion_in_cmd_fallback_needed then
		for unitID, terraID in pairs(workaround_recursion_in_cmd_fallback) do
			REPAIR_ORDER_PARAMS[4] = terraID
			spGiveOrderToUnit(unitID, CMD_INSERT, REPAIR_ORDER_PARAMS, CMD_OPT_ALT)
		end
		workaround_recursion_in_cmd_fallback = {}
		workaround_recursion_in_cmd_fallback_needed = false
	end
	
	--if n % 300 == 0 then
	--	GG.Terraform_RaiseWater(-20)
	--end
	
	if n >= nextUpdateCheck then
		updatePeriod = math.max(MIN_UPDATE_PERIOD, math.min(MAX_UPDATE_PERIOD, terraformOperations/60))
		--Spring.Echo("Terraform operations", terraformOperations, updatePeriod)
		terraformOperations = 0
		nextUpdateCheck = n + updatePeriod
	end
	
	DoTerraformUpdate(n)
	
	--check constrcutors that are repairing terraform blocks
	
	if constructors ~= 0 then
		if n % checkInterval == 0 then
			-- only check 1 con per cycle
			currentCon = currentCon + 1
			if currentCon > constructors then
				currentCon = 1
			end
			
			local cQueue = spGetCommandQueue(constructorTable[currentCon], -1)
			if cQueue then
				local ncq = #cQueue
				for i = 1, ncq do
					if cQueue[i].id == CMD_REPAIR then
						if #cQueue[i].params == 1 then
							-- target unit command
							if terraformUnit[cQueue[i].params[1]] then
								terraformUnit[cQueue[i].params[1]].decayTime = n + terraformDecayFrames
							end
							
							-- bring terraunit towards con
							if i == 1 and spValidUnitID(cQueue[i].params[1]) and terraformUnit[cQueue[i].params[1] ] then
								local cx, _, cz = spGetUnitPosition(constructorTable[currentCon])
								local team = spGetUnitTeam(constructorTable[currentCon])
								if cx and team then

									local tpos = terraformUnit[cQueue[i].params[1] ].positionAnchor
									local x, y, z = GetTerraunitLeashedSpot(team, tpos.x, tpos.z, cx, cz)
									terraformUnit[cQueue[i].params[1] ].position = {x = x, z = z}
									spSetUnitPosition(cQueue[i].params[1], x, y , z)
									--Spring.MoveCtrl.Enable(cQueue[i].params[1])
									--Spring.MoveCtrl.SetPosition(cQueue[i].params[1], x, y , z)
									--Spring.MoveCtrl.Disable(cQueue[i].params[1])
								end
							end
							
						elseif #cQueue[i].params == 4 then -- there is a command with 5 params that I do not want 
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
											--Spring.MarkerAddPoint(terra.position.x,0,terra.position.z,"saved " .. cX)
											terra.decayTime = n + terraformDecayFrames
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
					spLevelHeightMap(unit.minx,unit.minz,unit.maxx,unit.maxz,unit.h)
				end
			else
				
			end
			i = i + 1
		end
	end	
end

function gadget:CommandFallback(unitID, unitDefID, teamID, cmdID, cmdParams, cmdOptions)
	if not fallbackableCommands[cmdID] then
		return false
	end
	if not fallbackCommands[teamID] then
		return false
	end
	if not (cmdParams and cmdParams[4]) then
		return false
	end
	local command = fallbackCommands[teamID][cmdParams[4]]
	if not command then
		return false
	end
	
	if not terraformUnitDefIDs[unitDefID] then
		return false, true
	end
	
	local ux,_,uz = spGetUnitPosition(unitID)
	
	local closestID
	local closestDistanceSq
	for i = 1, command.terraunits do
		local terraID = command.terraunitList[i]
		if (Spring.ValidUnitID(terraID) and Spring.GetUnitDefID(terraID) == terraunitDefID) then
			local tx,_,tz = spGetUnitPosition(terraID)
			local distanceSq = (tx-ux)*(tx-ux) + (tz-uz)*(tz-uz)
			if (not closestDistanceSq) or (distanceSq < closestDistanceSq) then
				closestID = terraID
				closestDistanceSq = distanceSq
			end
		end
	end
	
	if closestID then
		--[[ Recursion not allowed.
			REPAIR_ORDER_PARAMS[4] = closestID
			spGiveOrderToUnit(unitID, CMD_INSERT, REPAIR_ORDER_PARAMS, CMD_OPT_ALT)
		]]
		workaround_recursion_in_cmd_fallback[unitID] = closestID
		workaround_recursion_in_cmd_fallback_needed = true
		return true, false
	end
	
	fallbackCommands[teamID][cmdParams[4]] = nil
	return false
end

function gadget:UnitPreDamaged(unitID, unitDefID, unitTeam, damage, paralyzer, 
                            weaponID, attackerID, attackerDefID, attackerTeam)
							
	if unitDefID == terraunitDefID then
		return 0 -- terraunit starts on 0 HP. If a unit is damaged and has 0 HP it dies
	end
	return damage
end

--------------------------------------------------------------------------------
-- Weapon Terraform
--------------------------------------------------------------------------------

local wantedList = {}
local SeismicWeapon = {}
local DEFAULT_SMOOTH = 0.5
local HEIGHT_FUDGE_FACTOR = 10
local HEIGHT_RAD_MULT = 0.8
local MIN_SMOOTH_RAD = 20

for i=1,#WeaponDefs do
	local wd = WeaponDefs[i]
	if wd.customParams and wd.customParams.smoothradius or wd.customParams.smoothmult then
		wantedList[#wantedList + 1] = wd.id
		if Script.SetWatchExplosion then
			Script.SetWatchExplosion(wd.id, true)
		else
			Script.SetWatchWeapon(wd.id, true)
		end
		SeismicWeapon[wd.id] = {
			smooth = wd.customParams.smoothmult or DEFAULT_SMOOTH,
			smoothradius = wd.customParams.smoothradius or wd.craterAreaOfEffect*0.5,
			gatherradius = wd.customParams.gatherradius or wd.craterAreaOfEffect*0.75,
			detachmentradius = wd.customParams.detachmentradius
		}
	end
end

local function makeTerraChangedPointsPyramidAroundStructures(posX,posY,posZ,posCount)
	--local found = {count = 0, data = {}}
	for i = 1, posCount do
		if structureAreaMap[posX[i]] and structureAreaMap[posX[i]][posZ[i]] then
			posY[i] = 0
			--found.count = found.count + 1
			--found.data[found.count] = {x = posX[i], z = posZ[i]}
		end	
	end
	
	
	--[[
	if found.count == 0 then	
		return posY
	end
	
	for i = 1, posCount do
		local x = posX[i]
		local z = posZ[i]
		for j = 1, found.count do
			local fx = found.data[j].x
			local fz = found.data[j].z
			local maxChange = sqrt((fx-x)^2 + (fz-z)^2)*maxHeightDifference/64
			if abs(posY[i]) > maxChange then
				posY[i] = abs(posY[i])/posY[i]*maxChange
			end
		end
	end
	--]]

	return posY
end

function gadget:Explosion_GetWantedWeaponDef()
	return wantedList
end

function gadget:Explosion(weaponID, x, y, z, owner)
	
	if SeismicWeapon[weaponID] then
		local height = spGetGroundHeight(x,z)
		
		local smoothradius = SeismicWeapon[weaponID].smoothradius
		local gatherradius = SeismicWeapon[weaponID].gatherradius
		local detachmentradius = SeismicWeapon[weaponID].detachmentradius	
		local maxSmooth = SeismicWeapon[weaponID].smooth
		if y > height + HEIGHT_FUDGE_FACTOR then
			local factor = 1 - ((y - height - HEIGHT_FUDGE_FACTOR)/smoothradius*HEIGHT_RAD_MULT)^2
			if factor > 0 then
				smoothradius = smoothradius*factor
				gatherradius = gatherradius*factor
				maxSmooth = maxSmooth*factor
			else
				return
			end
		end
		
		local smoothradiusSQ = smoothradius^2
		local gatherradiusSQ = gatherradius^2
		
		smoothradius = smoothradius + (8 - smoothradius%8)
		gatherradius = gatherradius + (8 - gatherradius%8)
		
		local sx = floor((x+4)/8)*8
		local sz = floor((z+4)/8)*8
		
		local groundPoints = 0
		local groundHeight = 0
		
		local origHeight = {} -- just to not read the heightmap twice
		
		for i = sx-gatherradius, sx+gatherradius,8 do
			origHeight[i] = {}
			for j = sz-gatherradius, sz+gatherradius,8 do
				local disSQ = (i - x)^2 + (j - z)^2
				if disSQ <= gatherradiusSQ then
					origHeight[i][j] = spGetGroundHeight(i,j)
					groundPoints = groundPoints + 1
					groundHeight = groundHeight + origHeight[i][j]
				end
			end
		end
		
		local biggestChange = 0
		if groundPoints > 0 then
			groundHeight = groundHeight/groundPoints
			
			local posX, posY, posZ = {}, {}, {}
			local posCount = 0
			
			for i = sx-smoothradius, sx+smoothradius,8 do
				for j = sz-smoothradius, sz+smoothradius,8 do
					local disSQ = (i - x)^2 + (j - z)^2
					if disSQ <= smoothradiusSQ then
						if not origHeight[i] then
							origHeight[i] = {}
						end
						if not origHeight[i][j] then
							origHeight[i][j] = spGetGroundHeight(i,j)
						end
						local newHeight = (groundHeight - origHeight[i][j]) * maxSmooth * (1 - disSQ/smoothradiusSQ)^1.5
						posCount = posCount + 1
						posX[posCount] = i
						posY[posCount] = newHeight
						posZ[posCount] = j
						local absChange = math.abs(newHeight)
						if biggestChange and absChange > biggestChange then
							if absChange > 0.5 then
								biggestChange = false
							else
								biggestChange = absChange
							end
						end
					end
				end
			end 
			
			posY = makeTerraChangedPointsPyramidAroundStructures(posX,posY,posZ,posCount)
			
			if (not biggestChange) or (math.random() < biggestChange/2) then
				spSetHeightMapFunc(
					function(xt,zt,ht)
						for i = 1, #xt, 1 do
							spAddHeightMap(xt[i],zt[i],ht[i])
						end
					end,
					posX,
					posZ,
					posY
				)
			end
		end
		
		if detachmentradius then
			local GRAVITY = Game.gravity
			local units = Spring.GetUnitsInCylinder(sx,sz,detachmentradius)
			for i = 1, #units do
				local hitUnitID = units[i]
				GG.DetatchFromGround(hitUnitID, 1, 0.25, 0.002*GRAVITY)
			end
		end
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

	if (unitDefID == shieldscoutDefID) then
		local  _,_,_,_,build = spGetUnitHealth(unitID)
		if build == 1 then
			local ux, uy, uz  = spGetUnitPosition(unitID)
			ux = floor((ux+8)/16)*16
			uz = floor((uz+8)/16)*16
			
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
			
			--        {0 ,0 ,0 ,
			--	  1 ,3 ,5 ,3 ,1 ,
			--   1 ,7 ,14,17,14,7 ,1 ,
			--0 ,3 ,14,26,31,26,14,3 ,0 ,
			--0 ,5 ,17,31,36,31,17,5 ,0 ,
			--0 ,3 ,14,26,31,26,14,3 ,0 ,
			--   1 ,7 ,14,17,14,7 ,1 ,
			--      1 ,3 ,5 ,3 ,1 ,
			--		 0 ,0 ,0 }
			
			local posY = 
				    {2 ,3 ,2 ,
			      2 ,3 ,7 ,3 ,2 ,
			   2 ,5 ,20,21,20,4 ,2 ,
			2 ,3 ,20,25,26,25,20,3 ,2 ,
			3 ,7 ,21,26,28,26,21,7 ,3 ,
			2 ,3 ,20,25,26,25,20,3 ,2 ,
			   2 ,4 ,20,21,20,5 ,2 ,
			       2,3 ,7 ,3 ,2 ,
				     2 ,3 ,2 }
			
			posY = makeTerraChangedPointsPyramidAroundStructures(posX,posY,posZ,posCount)
			
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
			
			local units = Spring.GetUnitsInCylinder(ux,uz,40)
			for i = 1, #units do
				local hitUnitID = units[i]
				if hitUnitID ~= unitID then
					GG.AddGadgetImpulseRaw(hitUnitID, 0, 0.3, 0, true, true)
				end
			end
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

function gadget:UnitCreated(unitID, unitDefID, teamID)

	if spGetUnitIsDead(unitID) then
		return
	end
	
	local ud = UnitDefs[unitDefID]
	-- add terraform commands to builders
	if terraformUnitDefIDs[unitDefID] and not(GG.terraformRequiresUnlock and not GG.terraformUnlocked[teamID]) then
		for _, cmdDesc in ipairs(cmdDescsArray) do
			spInsertUnitCmdDesc(unitID, cmdDesc)
		end
		
		local aTeam = spGetUnitAllyTeam(unitID)
		
		constructors = constructors + 1
		constructorTable[constructors] = unitID
		
		constructor[unitID]	= {allyTeam = aTeam, index = constructors}
		
		checkInterval = ceil(checkLoopFrames/constructors)
	end
	
	-- add structure to structure table
	if ud.isImmobile and not ud.customParams.mobilebuilding then
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
						local area = terraformUnit[oid].area
						for k = 1, terraformUnit[oid].points do
							local point = terraformUnit[oid].point[k]
							local x, z = point.x, point.z
							if structure[unitID].area[x] and structure[unitID].area[x][z] then
								terraformUnit[oid].point[k].diffHeight = 0.0001
								terraformUnit[oid].point[k].structure = true
								if area[x] and area[x][z] then
									area[x][z] = nil
								end
								recalc = true
							end
						end
						
						if recalc then
							updateTerraformCost(oid)
							updateTerraformEdgePoints(oid)
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

local TerraformFunctions = {}

function TerraformFunctions.ForceTerraformCompletion(pregame)
	DoTerraformUpdate(Spring.GetGameFrame(), true)
	if pregame then
		-- gadget:UnsyncedHeightMapUpdate seems to not be called pregame.
		GG.TerrainTexture.UpdateAll()
	end
end

function TerraformFunctions.TerraformArea(terraform_type, point, pointCount, terraformHeight, unit, constructorCount, teamID, volumeSelection, shift, commandX, commandZ, commandTag, disableForceCompletion)
	TerraformArea(terraform_type, point, pointCount, terraformHeight, unit, constructorCount, teamID, volumeSelection, shift, commandX, commandZ, commandTag, disableForceCompletion)
end

function TerraformFunctions.TerraformWall(terraform_type, point, pointCount, terraformHeight, unit, constructorCount, teamID, volumeSelection, shift, commandX, commandZ, commandTag, disableForceCompletion)
	TerraformWall(terraform_type, point, pointCount, terraformHeight, unit, constructorCount, teamID, volumeSelection, shift, commandX, commandZ, commandTag, disableForceCompletion)
end

function TerraformFunctions.TerraformRamp(startX, startY, startZ, endX, endY, endZ, width, unit, constructorCount,teamID, volumeSelection, shift, commandX, commandZ, commandTag, disableForceCompletion)
	TerraformRamp(startX, startY, startZ, endX, endY, endZ, width, unit, constructorCount,teamID, volumeSelection, shift, commandX, commandZ, commandTag, disableForceCompletion)
end

function TerraformFunctions.SetStructureHeight(unitID, height)
	if structure[unitID] then
		structure[unitID].h = height
	end
end

function gadget:Initialize()
	gadgetHandler:RegisterCMDID(CMD_TERRAFORM_INTERNAL)
	
	local terraformColor = {0.7, 0.75, 0, 0.7}
	
	Spring.SetCustomCommandDrawData(CMD_RAMP, "Ramp", terraformColor, false)
	Spring.SetCustomCommandDrawData(CMD_LEVEL, "Level", terraformColor, false)
	Spring.SetCustomCommandDrawData(CMD_RAISE, "Raise", terraformColor, false)
	Spring.SetCustomCommandDrawData(CMD_SMOOTH, "Smooth", terraformColor, false)
	Spring.SetCustomCommandDrawData(CMD_RESTORE, "Restore2", terraformColor, false)
	
	Spring.AssignMouseCursor("Ramp", "cursorRamp", true, true)
	Spring.AssignMouseCursor("Level", "cursorLevel", true, true)
	Spring.AssignMouseCursor("Raise", "cursorRaise", true, true)
	Spring.AssignMouseCursor("Smooth", "cursorSmooth", true, true)
	Spring.AssignMouseCursor("Restore2", "cursorRestore2", true, true)
	
	gadgetHandler:RegisterCMDID(CMD_RAMP)
	gadgetHandler:RegisterCMDID(CMD_LEVEL)
	gadgetHandler:RegisterCMDID(CMD_RAISE)
	gadgetHandler:RegisterCMDID(CMD_SMOOTH)
	gadgetHandler:RegisterCMDID(CMD_RESTORE)
	
	GG.Terraform = TerraformFunctions
	
	for _, unitID in ipairs(Spring.GetAllUnits()) do
		local unitDefID = Spring.GetUnitDefID(unitID)
		local teamID = spGetUnitTeam(unitID)
		gadget:UnitCreated(unitID, unitDefID, teamID)
	end
end

--------------------------------------------------------------------------------
--------------------------------------------------------------------------------
-- Save/Load

function gadget:Load(zip)
	for _, unitID in ipairs(Spring.GetAllUnits()) do
		if Spring.GetUnitDefID(unitID) == terraunitDefID then
			spDestroyUnit(unitID)
		end
	end
end

--------------------------------------------------------------------------------
-- SYNCED
--------------------------------------------------------------------------------

else

--------------------------------------------------------------------------------
-- UNSYNCED
--------------------------------------------------------------------------------

local terraunitDefID = UnitDefNames["terraunit"].id
local terraUnits = {}

function gadget:Initialize()
	for _, unitID in ipairs(Spring.GetAllUnits()) do
		local unitDefID = Spring.GetUnitDefID(unitID)
		local teamID = Spring.GetUnitTeam(unitID)
		gadget:UnitCreated(unitID, unitDefID, teamID)
	end
end


function gadget:UnitCreated(unitID, unitDefID, teamID)
	if unitDefID == terraunitDefID then
		terraUnits[unitID] = true
		Spring.UnitRendering.SetUnitLuaDraw(unitID, true)
	end
end

function gadget:UnitDestroyed(unitID, unitDefID)
	if terraUnits[unitID] then
		terraUnits[unitID] = nil
	end
end

function gadget:DrawUnit(unitID, drawMode)
	if terraUnits[unitID] then
		return true --suppress engine drawing
	end
end

--------------------------------------------------------------------------------
-- UNSYNCED
--------------------------------------------------------------------------------
end
