if GG.StartStopMovingControl then
	return
end

function GG.StartStopMovingControl(unitID, startFunc, stopFunc, thresholdSpeed, fallingCountsAsMoving, externalDataAccess, fallTimeLeeway)
	local spGetGroundHeight = Spring.GetGroundHeight
	local spGetUnitVelocity = Spring.GetUnitVelocity
	local spGetUnitPosition = Spring.GetUnitPosition
	thresholdSpeed = thresholdSpeed or 0.05
	
	while Spring.GetUnitIsStunned(unitID) do
		Sleep(1000)
	end
	
	local x,y,z, height, speed
	local moving = false
	while true do
		x,y,z = spGetUnitPosition(unitID)
		if not x then
			return
		end
		if externalDataAccess then
			moving = externalDataAccess.moving
		end
		height = spGetGroundHeight(x,z)
		--Spring.Echo("y - height", y - height)
		if y - height < 0.01 then
			if externalDataAccess and externalDataAccess.fallTime then
				externalDataAccess.fallTime = externalDataAccess.fallTime - 1
				if externalDataAccess.fallTime <= 0 then
					externalDataAccess.fallTime = false
				end
			end
			
			if not (externalDataAccess and externalDataAccess.fallTime) then
				speed = select(4, spGetUnitVelocity(unitID))
				--Spring.Echo("speed", speed, "moving", moving, "Spring.GetUnitTravel", Spring.GetUnitTravel(unitID))
				if moving then
					if speed <= ((externalDataAccess and externalDataAccess.thresholdSpeed) or thresholdSpeed) then
						moving = false
						stopFunc()
					end
				else
					if speed > ((externalDataAccess and externalDataAccess.thresholdSpeed) or thresholdSpeed) then
						moving = true
						startFunc()
					end
				end
			end
		elseif fallingCountsAsMoving then
			if not moving then
				moving = true
				startFunc()
			end
		elseif fallTimeLeeway then
			-- Falling does not count as moving and we have some time to not start moving after hitting the ground
			externalDataAccess.fallTime = fallTimeLeeway
		end
		Sleep(350)
	end
end
