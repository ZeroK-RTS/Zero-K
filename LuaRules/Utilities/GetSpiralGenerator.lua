function Spring.Utilities.GetSpiralGenerator(x, z, step, startingDirection, clockwise)
    local radius = 16
    local mag = 1
    local spiralChangeNumber = 1
    local nx, ny, nz
    local offsetX, offsetZ = 0, 0
    local aborted = false
    repeat -- 1 right, 1 up, 2 left, 2 down, 3 right, 3 up
		nx = x + offsetX
		nz = z + offsetZ
		ny = Spring.GetGroundHeight(nx, nz)
		if step == 0 and not (mag == 8 and step == 0 and startingDirection == 4) then 
			spiralChangeNumber = spiralChangeNumber + 1
			if spiralChangeNumber%3 == 0 then 
				mag = mag + 1
			end
			step = mag
			startingDirection = startingDirection%4 + 1
		elseif mag == 8 and step == 0 and startingDirection == 4 then -- abort
			aborted = true 
		elseif clockwise == true then-- move to the next offset
			if startingDirection == 1 then
				offsetX = offsetX + radius
			elseif startingDirection == 2 then
				offsetZ = offsetZ - radius
			elseif startingDirection == 3 then
				offsetX = offsetX - radius
			elseif startingDirection == 4 then
				offsetZ = offsetZ + radius
			end
		else -- move to the next offset
			if startingDirection == 1 then
				offsetX = offsetX + radius
			elseif startingDirection == 2 then
				offsetZ = offsetZ + radius
			elseif startingDirection == 3 then
				offsetX = offsetX - radius
			elseif startingDirection == 4 then
				offsetZ = offsetZ - radius
			end
			step = step - 1
		end
	until aborted

	return aborted
end