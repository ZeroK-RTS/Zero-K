if GG.Script_SetupAimPosTerraform then
	return
end

local unitData = {}

local function GetHeight(baseX, baseZ, searchRange, i, j)
	--Spring.MarkerAddPoint(baseX + i*searchRange, 0, baseZ + j*searchRange, "")
	return Spring.GetGroundHeight(baseX + i*searchRange, baseZ + j*searchRange)
end

local function DoUpdate(unitID)
	local data = unitData[unitID]
	local nearbyHeight = data.baseHeight
	local nearbyLowHeight = data.baseHeight
	for i = -1, 1, 1 do
		for j = -1, 1, 1 do
			if i ~= 0 or j ~= 0 then
				local height = GetHeight(data.baseX, data.baseZ, data.searchRange, i, j)
				nearbyHeight = math.max(nearbyHeight, height)
				nearbyLowHeight = math.min(nearbyLowHeight, height)
			end
		end
	end
	local newAimHeight = nearbyHeight - data.baseHeight + data.cliffPeek
	if data.aimOffetOverride then
		data.defaultAim[2] = data.aimOffetOverride
	elseif nearbyLowHeight - data.baseHeight < -120 then
		-- Make it easier to shoot up at turrets over the lip of tall cliffs by moving the aim upwards.
		data.defaultAim[2] = (data.minAimOffset + data.maxAimOffset)/2
	else
		data.defaultAim[2] = math.max(data.minAimOffset, math.min(data.maxAimOffset, newAimHeight))
	end
	
	if GG.OverrideMidAndAimPos then
		GG.OverrideMidAndAimPos(unitID, data.defaultMid, data.defaultAim)
	else
		Spring.SetUnitMidAndAimPos(
			unitID,
			data.defaultMid[1], data.defaultMid[2], data.defaultMid[3],
			data.defaultAim[1], data.defaultAim[2], data.defaultAim[3], true)
	end
end

local function UpdateAimPos(unitID)
	local updateTime = 10000 -- every 10 seconds.
	while true do
		DoUpdate(unitID)
		Sleep(updateTime)
	end
end

function GG.Script_SetupAimPosTerraform(unitID, floatOnWater, defaultMid, defaultAim, minAimOffset, maxAimOffset, cliffPeek, searchRange)
	local baseX,_,baseZ = Spring.GetUnitPosition(unitID)
	local baseHeight = Spring.GetGroundHeight(baseX, baseZ)
	if baseHeight < 0 and floatOnWater then
		baseHeight = 0
	end
	
	local data = {}
	data.aimOffetOverride = false -- For popup turrets
	data.baseX = baseX
	data.baseZ = baseZ
	data.baseHeight = baseHeight
	data.cliffPeek = cliffPeek
	data.defaultMid = defaultMid
	data.defaultAim = defaultAim
	data.minAimOffset = minAimOffset
	data.maxAimOffset = maxAimOffset
	data.searchRange = searchRange
	unitData[unitID] = data
	
	StartThread(UpdateAimPos, unitID)
end

function GG.Script_OffsetAimAndColVol(unitID, newAimOffetOverride, colVolOffset)
	unitData[unitID].aimOffetOverride = newAimOffetOverride
	GG.OffsetColVol(unitID, colVolOffset)
	DoUpdate(unitID)
end
