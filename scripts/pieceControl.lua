local IsInTurn = Spring.UnitScript.IsInTurn
local IsInMove  = Spring.UnitScript.IsInMove 
local GetPieceRotation = Spring.UnitScript.GetPieceRotation
local GetPieceTranslation  = Spring.UnitScript.GetPieceTranslation 

-- for some reason a 4th argument is required
local ROTATION_STOP = math.rad(3)
local TRANSLATION_STOP = 1

function StopTurn(piece, axis)
	if IsInTurn(piece, axis) then
		local rot = select(axis, GetPieceRotation(piece))
		Turn( piece , axis, rot, ROTATION_STOP)
		return true
	end
	return false
end

function StopMove(piece, axis)
	if IsInMove(piece, axis) then
		local trans = select(axis, GetPieceRotation(piece))
		Move( piece , axis, trans, TRANSLATION_STOP)
		return true
	end
	return false
end