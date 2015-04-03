--------------------------------------------------------------------------------
--------------------------------------------------------------------------------
if not gadgetHandler:IsSyncedCode() then
	return
end
--------------------------------------------------------------------------------
--------------------------------------------------------------------------------

function gadget:GetInfo()
   return {
      name      = "Center Offset and Growth Scale",
      desc      = "Offsets aimpoints and grows nanoframe collision volume during construction.",
      author    = "KingRaptor (L.J. Lim) and GoogleFrog",
      date      = "12.7.2012",
      license   = "Public Domain",
      layer     = 1, -- After unit_script (hitvolume changes can occur when units are created).
      enabled   = true
   }
end

local spGetUnitBuildFacing     = Spring.GetUnitBuildFacing
local spSetUnitMidAndAimPos    = Spring.SetUnitMidAndAimPos
local spSetUnitRadiusAndHeight = Spring.SetUnitRadiusAndHeight
local spGetUnitPosition        = Spring.GetUnitPosition
local spGetUnitHealth          = Spring.GetUnitHealth
local spValidUnitID            = Spring.ValidUnitID
local spSetUnitCollisionVolumeData = Spring.SetUnitCollisionVolumeData
local spGetUnitCollisionVolumeData = Spring.GetUnitCollisionVolumeData

local min = math.min

--------------------------------------------------------------------------------
--------------------------------------------------------------------------------

if not Spring.SetUnitMidAndAimPos then
	return
end

local FULL_GROW = 0.4
local UPDATE_FREQUENCY = 25


local growUnit = {}
local offsets = {}
local modelRadii = {}

--------------------------------------------------------------------------------
--------------------------------------------------------------------------------
-- Initialization of aim and midpos

local function UnpackInt3(str)
	local index = 0
	local ret = {}
	for i=1,3 do
		ret[i] = str:match("[-]*%d+", index)
		index = (select(2, str:find(ret[i], index)) or 0) + 1
	end
	return ret
end

for i=1,#UnitDefs do
	local ud = UnitDefs[i]
	local midPosOffset = ud.customParams.midposoffset
	local aimPosOffset = ud.customParams.aimposoffset
	local modelRadius  = ud.customParams.modelradius
	local modelHeight  = ud.customParams.modelheight
	if midPosOffset or aimPosOffset then
		local mid = (midPosOffset and UnpackInt3(midPosOffset)) or {0,0,0}
		local aim = (aimPosOffset and UnpackInt3(aimPosOffset)) or mid
		offsets[i] = {
			mid = mid,
			aim = aim,
		}
	end
	if modelRadius or modelHeight then
		modelRadii[i] = {
			radius = ( modelRadius and tonumber(modelRadius) or ud.radius ),
			height = ( modelHeight and tonumber(modelHeight) or ud.height ),
		}
	end
end

--------------------------------------------------------------------------------
--------------------------------------------------------------------------------
-- Unit Handling

local function UpdateUnitGrow(unitID, growScale)
	local unit = growUnit[unitID]
	growScale = 1 - growScale
	
	spSetUnitCollisionVolumeData(unitID,
		unit.scale[1], unit.scale[2] - growScale*unit.scaleOff, unit.scale[3], 
		unit.offset[1], unit.offset[2] - growScale*unit.scaleOff/2, unit.offset[3], 
		unit.volumeType, unit.testType, unit.primaryAxis)

	spSetUnitMidAndAimPos(unitID, 
		unit.mid[1], unit.mid[2], unit.mid[3],
		unit.aim[1], unit.aim[2] - growScale*unit.aimOff, unit.aim[3], true)
end

function gadget:UnitCreated(unitID, unitDefID, teamID)
	local ud = UnitDefs[unitDefID]
	
	local mid, aim
	
	if offsets[unitDefID] and ud then
		mid = offsets[unitDefID].mid
		aim = offsets[unitDefID].aim
		mid[2] = Spring.GetUnitRulesParam(unitID, "midpos_override") or mid[2]
		aim[2] = Spring.GetUnitRulesParam(unitID, "aimpos_override") or aim[2]
		
		spSetUnitMidAndAimPos(unitID, 
			mid[1] + ud.midx, mid[2] + ud.midy, mid[3] + ud.midz, 
			aim[1] + ud.midx, aim[2] + ud.midy, aim[3] + ud.midz, true)
	else
		mid = {0, Spring.GetUnitRulesParam(unitID, "midpos_override") or 0, 0}
		aim = {0, Spring.GetUnitRulesParam(unitID, "aimpos_override") or 0, 0}
	end
	
	if modelRadii[unitDefID] then
		spSetUnitRadiusAndHeight(unitID, modelRadii[unitDefID].radius, modelRadii[unitDefID].height)
	end
	
	local buildProgress = select(5, spGetUnitHealth(unitID))
	
	if buildProgress > FULL_GROW then
		return
	end
	
	-- Sertup growth scale
	
	local _, baseY, _, _, midY, _, _, aimY = spGetUnitPosition(unitID, true, true)
	local scaleX, scaleY, scaleZ, offsetX, offsetY, offsetZ, 
		volumeType, testType, primaryAxis = spGetUnitCollisionVolumeData(unitID)
	
	local volumeBelow = -((midY - baseY) + offsetY - scaleY/2)	
	local aimAbove = (midY - baseY) + aim[2] - mid[2]
	
	if volumeBelow < 0 then
		aimAbove = aimAbove + volumeBelow
		volumeBelow = 0
	end

	local aimOff = aimAbove - 1
	local scaleOff = scaleY - volumeBelow - 2
	
	local growScale = min(1, buildProgress/FULL_GROW)

	growUnit[unitID] = {
		mid = {mid[1] + ud.midx, mid[2] + ud.midy, mid[3] + ud.midz},
		aim = {aim[1] + ud.midx, aim[2] + ud.midy, aim[3] + ud.midz},
		aimOff = aimOff,
		scaleOff = scaleOff,
		scale = {scaleX, scaleY, scaleZ},
		offset = {offsetX, offsetY, offsetZ},
		volumeType = volumeType,
		testType = testType,
		primaryAxis = primaryAxis,
		prevGrowth = growScale,
	}
	
	UpdateUnitGrow(unitID, growScale)
end

function gadget:UnitFinished(unitID, unitDefID, teamID)
	if growUnit[unitID] then
		UpdateUnitGrow(unitID, 1)
		growUnit[unitID] = nil
	end
end

function gadget:GameFrame(f)
	if f%UPDATE_FREQUENCY == 12 then
		for unitID, data in pairs(growUnit) do
			if spValidUnitID(unitID) then
				local buildProgress = select(5, spGetUnitHealth(unitID))
				if buildProgress <= FULL_GROW then
					local growScale = min(1, buildProgress/FULL_GROW)
					if growScale ~= data.prevGrowth then
						UpdateUnitGrow(unitID, growScale)
						data.prevGrowth = growScale
					end
				else
					UpdateUnitGrow(unitID, 1)
					growUnit[unitID] = nil
				end
			else
				growUnit[unitID] = nil
			end
		end
	end
end

function gadget:Initialize()
	for _, unitID in ipairs(Spring.GetAllUnits()) do
		local unitDefID = Spring.GetUnitDefID(unitID)
		gadget:UnitCreated(unitID, unitDefID)
	end
end