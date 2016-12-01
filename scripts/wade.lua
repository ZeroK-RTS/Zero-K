inWater = false
isMoving = false

function script.setSFXoccupy (terrainType)
	local nowInWater = (terrainType == 2 or terrainType == 1)
	
	if nowInWater then
		if not inWater and isMoving then
			StartThread(Wade);
		end
	else
		Signal(SIG_WADE)
	end
	inWater = nowInWater
end

function Wade()
	local spGetUnitPosition = Spring.GetUnitPosition
	local maxWadeDepth = -Spring.GetUnitHeight(unitID)
	
	if not (WADE_PIECE and WADE_PIECE[1]) then 
		return 
	end
	
	SetSignalMask(SIG_WADE);
	
	while true do
		local x,y,z = spGetUnitPosition(unitID)
		if (y > maxWadeDepth) then -- emit wakes only when not completely submerged
			EmitSfx(WADE_PIECE[math.random(1,#WADE_PIECE)], WADE_SFX)
		end
		Sleep(math.random(5,10)*33)
	end
end

