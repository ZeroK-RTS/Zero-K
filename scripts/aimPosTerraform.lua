if GG.SetupAimPosTerraform then
	return
end

function GG.SetupAimPosTerraform(unitID, unitDefID, defaultMid, defaultAim, minAimOffset, maxAimOffset, cliffPeek, searchRange)
	local baseX,_,baseZ = Spring.GetUnitPosition(unitID)
	local baseHeight = Spring.GetGroundHeight(baseX, baseZ)
	if baseHeight < 0 and UnitDefs[unitDefID].floatOnWater then
		baseHeight = 0
	end
	
	local updateTime = 10000 -- every 10 seconds.
	
	local function GetHeight(i, j)
		--Spring.MarkerAddPoint(baseX + i*searchRange, 0, baseZ + j*searchRange, "")
		return Spring.GetGroundHeight(baseX + i*searchRange, baseZ + j*searchRange)
	end

	local function UpdateAimPos()
		while true do
			local nearbyHeight = baseHeight
			for i = -1, 1, 1 do
				for j = -1, 1, 1 do
					if i ~= 0 or j ~= 0 then
						nearbyHeight = math.max(nearbyHeight, GetHeight(i, j))
					end
				end
			end
			local newAimHeight = nearbyHeight - baseHeight + cliffPeek
			defaultAim[2] = math.max(minAimOffset, math.min(maxAimOffset, newAimHeight))
			
			if GG.OverrideMidAndAimPos then
				GG.OverrideMidAndAimPos(unitID, defaultMid, defaultAim)
			else
				Spring.SetUnitMidAndAimPos(unitID, defaultMid[1], defaultMid[2], defaultMid[3], defaultAim[1], defaultAim[2], defaultAim[3], true)
			end
			Sleep(updateTime)
		end
	end
	
	StartThread(UpdateAimPos)
end
