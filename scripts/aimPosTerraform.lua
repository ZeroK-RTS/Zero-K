if GG.SetupAimPosTerraform then
	return
end

function GG.SetupAimPosTerraform(unitID, floatOnWater, defaultMid, defaultAim, minAimOffset, maxAimOffset, cliffPeek, searchRange)
	local baseX,_,baseZ = Spring.GetUnitPosition(unitID)
	local baseHeight = Spring.GetGroundHeight(baseX, baseZ)
	if baseHeight < 0 and floatOnWater then
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
			local nearbyLowHeight = baseHeight
			for i = -1, 1, 1 do
				for j = -1, 1, 1 do
					if i ~= 0 or j ~= 0 then
						local height = GetHeight(i, j)
						nearbyHeight = math.max(nearbyHeight, height)
						nearbyLowHeight = math.min(nearbyLowHeight, height)
					end
				end
			end
			local newAimHeight = nearbyHeight - baseHeight + cliffPeek
			if nearbyLowHeight - baseHeight < -120 then
				-- Make it easier to shoot up at turrets over the lip of tall cliffs by moving the aim upwards.
				defaultAim[2] = (minAimOffset + maxAimOffset)/2
			else
				defaultAim[2] = math.max(minAimOffset, math.min(maxAimOffset, newAimHeight))
			end
			
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
