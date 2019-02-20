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

local devCompatibility = Spring.Utilities.IsCurrentVersionNewerThan(100, 0)

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
		modelRadii[i] = true -- mark that we need to initialize this
	end
end

-- lazily initialize model radius/height since they force loading the model
local function GetModelRadii(unitDefID)
	if modelRadii[unitDefID] == true then
		local ud = UnitDefs[unitDefID]
		local modelRadius  = ud.customParams.modelradius
		local modelHeight  = ud.customParams.modelheight
		modelRadii[unitDefID] = {
			radius = ( modelRadius and tonumber(modelRadius) or ud.radius ),
			height = ( modelHeight and tonumber(modelHeight) or ud.height ),
		}
	end

	return modelRadii[unitDefID]
end

--------------------------------------------------------------------------------
--------------------------------------------------------------------------------
-- Unit Handling

local function UpdateUnitGrow(unitID, growScale)
	local unit = growUnit[unitID]
	growScale = 1 - growScale
	
	if unit.isSphere then
		spSetUnitCollisionVolumeData(unitID,
			unit.scale[1], unit.scale[2], unit.scale[3], 
			unit.offset[1], unit.offset[2] - growScale*unit.scaleOff, unit.offset[3], 
			unit.volumeType, unit.testType, unit.primaryAxis
		)
	else
		spSetUnitCollisionVolumeData(unitID,
			unit.scale[1], unit.scale[2] - growScale*unit.scaleOff, unit.scale[3], 
			unit.offset[1], unit.offset[2] - growScale*unit.scaleOff/2, unit.offset[3], 
			unit.volumeType, unit.testType, unit.primaryAxis)
	end

	spSetUnitMidAndAimPos(unitID, 
		unit.mid[1], unit.mid[2], unit.mid[3],
		unit.aim[1], unit.aim[2] - growScale*unit.aimOff, unit.aim[3], true)
end

function gadget:UnitCreated(unitID, unitDefID, teamID)
	local ud = UnitDefs[unitDefID]
	
	local midTable = ud
	if devCompatibility then
		midTable = ud.model
	end
	
	local mid, aim
	
	if offsets[unitDefID] and ud then
		mid = offsets[unitDefID].mid
		aim = offsets[unitDefID].aim
		mid[2] = Spring.GetUnitRulesParam(unitID, "midpos_override") or mid[2]
		aim[2] = Spring.GetUnitRulesParam(unitID, "aimpos_override") or aim[2]
		
		spSetUnitMidAndAimPos(unitID, 
			mid[1] + midTable.midx, mid[2] + midTable.midy, mid[3] + midTable.midz, 
			aim[1] + midTable.midx, aim[2] + midTable.midy, aim[3] + midTable.midz, true)
	else
		mid = {0, Spring.GetUnitRulesParam(unitID, "midpos_override") or 0, 0}
		aim = {0, Spring.GetUnitRulesParam(unitID, "aimpos_override") or 0, 0}
	end
	
	if modelRadii[unitDefID] then
		local mr = GetModelRadii(unitDefID)
		spSetUnitRadiusAndHeight(unitID, mr.radius, mr.height)
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
	
	local isSphere = (volumeType == 3) -- Spheres are 3, seems to be no way for engine to tell me this.
	local aimOff = aimAbove - 1
	
	-- Spheres poke more above the ground to give them more vulnerabilty.
	-- Otherwise only the tip would show. Other volumes show the entire surface area because they are prisms.
	local scaleOff = scaleY - volumeBelow - ((isSphere and 8) or 2)
	
	local growScale = min(1, buildProgress/FULL_GROW)
	
	growUnit[unitID] = {
		mid = {mid[1] + midTable.midx, mid[2] + midTable.midy, mid[3] + midTable.midz},
		aim = {aim[1] + midTable.midx, aim[2] + midTable.midy, aim[3] + midTable.midz},
		aimOff = aimOff,
		scaleOff = scaleOff,
		scale = {scaleX, scaleY, scaleZ},
		offset = {offsetX, offsetY, offsetZ},
		volumeType = volumeType,
		isSphere = isSphere,
		testType = testType,
		primaryAxis = primaryAxis,
		prevGrowth = growScale,
	}
	
	local luaSelectionScale = ud.customParams.lua_selection_scale
	if Spring.SetUnitSelectionVolumeData and luaSelectionScale then
		Spring.SetUnitSelectionVolumeData(unitID,
			scaleX*luaSelectionScale, scaleY*luaSelectionScale, scaleZ*luaSelectionScale, 
			0, 0, 0, 
			volumeType, testType, primaryAxis)
	end
	
	UpdateUnitGrow(unitID, growScale)
end

local function OverrideMidAndAimPos(unitID, mid, aim)
	if not spValidUnitID(unitID) then
		return
	end
	
	-- Do not override growing units
	if growUnit[unitID] then
		return
	end
	
	spSetUnitMidAndAimPos(unitID, mid[1], mid[2], mid[3], aim[1], aim[2], aim[3], true)
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
	GG.OverrideMidAndAimPos = OverrideMidAndAimPos
	
	for _, unitID in ipairs(Spring.GetAllUnits()) do
		local unitDefID = Spring.GetUnitDefID(unitID)
		gadget:UnitCreated(unitID, unitDefID)
	end
end