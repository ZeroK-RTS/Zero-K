if GG.StartStopMovingControl then
	return
end

function GG.StartStopMovingControl(unitID, startFunc, stopFunc, thresholdSpeed, fallingCountsAsMoving)
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
		height = spGetGroundHeight(x,z)
		if y - height < 1 then
			speed = select(4, spGetUnitVelocity(unitID))
			if moving then
				if speed <= thresholdSpeed then
					moving = false
					stopFunc()
				end
			else
				if speed > thresholdSpeed then
					moving = true
					startFunc()
				end
			end
		elseif fallingCountsAsMoving then
			if not moving then
				moving = true
				startFunc()
			end
		end
		Sleep(350)
	end
end
