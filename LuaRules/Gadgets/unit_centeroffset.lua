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

local FULL_GROW = 0.4
local UPDATE_FREQUENCY = 25

local growUnit = {}
local completeGrowUnit = {}
local offsets = {}
local modelRadii = {}
local noGrowUnitDefs = {}
local unitScales = {}
local origColvolCache = {}

local postCompleteGrowDefs = {}
for i = 1, #UnitDefs do
	if UnitDefs[i].customParams.dynamic_colvol then
		postCompleteGrowDefs[i] = true
	end
end

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

for i = 1,#UnitDefs do
	local ud = UnitDefs[i]
	local midPosOffset = ud.customParams.midposoffset
	local aimPosOffset = ud.customParams.aimposoffset
	local modelRadius  = ud.customParams.modelradius
	local modelHeight  = ud.customParams.modelheight
	if ud.customParams.no_grow then
		noGrowUnitDefs[i] = true
	end
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

local function UpdateUnitGrow(unitID, data, growScale)
	growScale = 1 - growScale
	
	if data.isSphere then
		spSetUnitCollisionVolumeData(unitID,
			data.scale[1], data.scale[2], data.scale[3],
			data.offset[1], data.offset[2] - growScale*data.scaleOff, data.offset[3],
			data.volumeType, data.testType, data.primaryAxis
		)
	else
		spSetUnitCollisionVolumeData(unitID,
			data.scale[1], data.scale[2] - growScale*data.scaleOff, data.scale[3],
			data.offset[1], data.offset[2] - growScale*data.scaleOff/2, data.offset[3],
			data.volumeType, data.testType, data.primaryAxis)
	end

	spSetUnitMidAndAimPos(unitID,
		data.mid[1], data.mid[2], data.mid[3],
		data.aim[1], data.aim[2] - growScale*data.aimOff, data.aim[3], true)
end

local function UpdateUnitCollisionData(unitID, unitDefID, scales)
	if unitScales[unitID] and not scales then
		scales = unitScales[unitID]
	end
	local ud = UnitDefs[unitDefID]
	local midTable = ud.model
	local mid, aim
	
	if offsets[unitDefID] and ud then
		mid = Spring.Utilities.CopyTable(offsets[unitDefID].mid)
		aim = Spring.Utilities.CopyTable(offsets[unitDefID].aim)
		mid[2] = Spring.GetUnitRulesParam(unitID, "midpos_override") or mid[2]
		aim[2] = Spring.GetUnitRulesParam(unitID, "aimpos_override") or aim[2]
	else
		mid = {0, Spring.GetUnitRulesParam(unitID, "midpos_override") or 0, 0}
		aim = {0, Spring.GetUnitRulesParam(unitID, "aimpos_override") or 0, 0}
	end
	
	mid[1], mid[2], mid[3] = mid[1] + midTable.midx, mid[2] + midTable.midy, mid[3] + midTable.midz
	aim[1], aim[2], aim[3] = aim[1] + midTable.midx, aim[2] + midTable.midy, aim[3] + midTable.midz
	if scales then
		mid[1], mid[2], mid[3] = mid[1]*scales[1], mid[2]*scales[2], mid[3]*scales[3]
		aim[1], aim[2], aim[3] = aim[1]*scales[1], aim[2]*scales[2], aim[3]*scales[3]
	end
	spSetUnitMidAndAimPos(unitID,
		mid[1], mid[2], mid[3],
		aim[1], aim[2], aim[3], true)
		
	if modelRadii[unitDefID] then
		local mr = GetModelRadii(unitDefID)
		spSetUnitRadiusAndHeight(unitID, mr.radius, mr.height)
	end
	
	if noGrowUnitDefs[unitDefID] and not scales then
		return
	end
	
	local buildProgress = select(5, spGetUnitHealth(unitID))
	if buildProgress > FULL_GROW and not postCompleteGrowDefs[unitDefID] and not scales then
		return
	end
	
	-- Sertup growth scale
	local _, baseY, _, _, midY, _, _, aimY = spGetUnitPosition(unitID, true, true)
	if not origColvolCache[unitDefID] then
		local scaleX, scaleY, scaleZ, offsetX, offsetY, offsetZ,
			volumeType, testType, primaryAxis = spGetUnitCollisionVolumeData(unitID)
		origColvolCache[unitDefID] = {
			scaleX, scaleY, scaleZ, offsetX, offsetY, offsetZ,
			volumeType, testType, primaryAxis
		}
	end
	local cache = origColvolCache[unitDefID]
	local scaleX, scaleY, scaleZ, offsetX, offsetY, offsetZ,
			volumeType, testType, primaryAxis = cache[1], cache[2], cache[3], cache[4], cache[5], cache[6], cache[7], cache[8], cache[9]
	
	if scales then
		scaleX, scaleY, scaleZ = scaleX*scales[1], scaleY*scales[2], scaleZ*scales[3]
		offsetX, offsetY, offsetZ = offsetX*scales[1], offsetY*scales[2], offsetZ*scales[3]
	end
	-- Some units can be deeper than usual via waterline.
	-- Poke above the surface instead of their "base" level
	-- since it blocks lots of weaponry
	if baseY < 0 and ud.floatOnWater then
		baseY = 0
	end

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
	if noGrowUnitDefs[unitDefID] then
		growScale = 1
	end
	
	growUnit[unitID] = {
		mid = mid,
		aim = aim,
		aimOff = aimOff,
		scaleOff = scaleOff,
		scale = {scaleX, scaleY, scaleZ},
		offset = {offsetX, offsetY, offsetZ},
		volumeType = volumeType,
		isSphere = isSphere,
		testType = testType,
		primaryAxis = primaryAxis,
		prevGrowth = growScale,
		dynamicColvol = postCompleteGrowDefs[unitDefID],
	}
	
	local luaSelectionScale = ud.customParams.lua_selection_scale
	if Spring.SetUnitSelectionVolumeData and luaSelectionScale then
		Spring.SetUnitSelectionVolumeData(unitID,
			scaleX*luaSelectionScale, scaleY*luaSelectionScale, scaleZ*luaSelectionScale,
			0, 0, 0,
			volumeType, testType, primaryAxis)
	end
	
	UpdateUnitGrow(unitID, growUnit[unitID], growScale)
end

function gadget:UnitCreated(unitID, unitDefID, teamID)
	UpdateUnitCollisionData(unitID, unitDefID)
end

local function OverrideMidAndAimPos(unitID, mid, aim)
	if not spValidUnitID(unitID) then
		return
	end
	
	-- Do not override growing units
	if growUnit[unitID] then
		return
	end
	local sx, sy, sz = GG.GetColvolScales(unitID)
	spSetUnitMidAndAimPos(unitID, sx*mid[1], sy*mid[2], sz*mid[3], sx*aim[1], sy*aim[2], sz*aim[3], true)
end

function gadget:UnitFinished(unitID, unitDefID, teamID)
	if growUnit[unitID] then
		UpdateUnitGrow(unitID, growUnit[unitID], 1)
		if growUnit[unitID].dynamicColvol then
			completeGrowUnit[unitID] = growUnit[unitID]
		end
		growUnit[unitID] = nil
	end
end

function gadget:UnitDestroyed(unitID, unitDefID, teamID)
	if completeGrowUnit[unitID] then
		growUnit[unitID] = nil
	end
	unitScales[unitID] = nil
end

function gadget:GameFrame(f)
	if f%UPDATE_FREQUENCY == 12 then
		for unitID, data in pairs(growUnit) do
			if spValidUnitID(unitID) then
				local buildProgress = select(5, spGetUnitHealth(unitID))
				if buildProgress <= FULL_GROW then
					local growScale = min(1, buildProgress/FULL_GROW)
					if growScale ~= data.prevGrowth then
						UpdateUnitGrow(unitID, growUnit[unitID], growScale)
						data.prevGrowth = growScale
					end
				else
					UpdateUnitGrow(unitID, growUnit[unitID], 1)
					if growUnit[unitID].dynamicColvol then
						completeGrowUnit[unitID] = growUnit[unitID]
					end
					growUnit[unitID] = nil
				end
			else
				if growUnit[unitID].dynamicColvol then
					completeGrowUnit[unitID] = growUnit[unitID]
				end
				growUnit[unitID] = nil
			end
		end
	end
end

local function OffsetColVol(unitID, offset)
	if growUnit[unitID] then
		growUnit[unitID].offset[2] = offset
		UpdateUnitGrow(unitID, growUnit[unitID], 1)
		return
	end
	if completeGrowUnit[unitID] then
		completeGrowUnit[unitID].offset[2] = offset
		UpdateUnitGrow(unitID, completeGrowUnit[unitID], 1)
	end
end

local function SetColvolScales(unitID, scales)
	-- Wants a list of three values
	unitScales[unitID] = scales
	UpdateUnitCollisionData(unitID, Spring.GetUnitDefID(unitID), scales)
end

local function GetColvolScales(unitID)
	if unitScales[unitID] then
		return unitScales[unitID][1], unitScales[unitID][2], unitScales[unitID][3]
	end
	return 1, 1, 1
end

function gadget:Shutdown()
	for unitID in pairs(unitScales) do
		UpdateUnitCollisionData(unitID, Spring.GetUnitDefID(unitID), {1, 1, 1})
	end
end

function gadget:Initialize()
	GG.OverrideMidAndAimPos = OverrideMidAndAimPos
	GG.SetColvolScales = SetColvolScales
	GG.GetColvolScales = GetColvolScales
	GG.OffsetColVol = OffsetColVol
	
	for _, unitID in ipairs(Spring.GetAllUnits()) do
		local unitDefID = Spring.GetUnitDefID(unitID)
		gadget:UnitCreated(unitID, unitDefID)
	end
end
