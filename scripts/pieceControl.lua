if GG.PieceControl then
	return
end
GG.PieceControl = {}

GG.PieceControl.ROTATION_STOP = math.rad(3)
GG.PieceControl.TRANSLATION_STOP = 1

function GG.PieceControl.StopTurn(piece, axis)
	if Spring.UnitScript.IsInTurn(piece, axis) then
		local rot = select(axis, Spring.UnitScript.GetPieceRotation(piece))
		Turn(piece, axis, rot, GG.PieceControl.ROTATION_STOP)
		return true
	end
	return false
end

function GG.PieceControl.StopMove(piece, axis)
	if Spring.UnitScript.IsInMove (piece, axis) then
		local trans = select(axis, Spring.UnitScript.GetPieceRotation(piece))
		Move(piece, axis, trans, GG.PieceControl.TRANSLATION_STOP)
		return true
	end
	return false
end

function GG.PieceControl.IsDisarmed ()
	if ((Spring.SpringGetUnitRulesParam (unitID, "disarmed") == 1) or Spring.SpringGetUnitIsStunned (unitID)) then
		return true
	else
		return false
	end
end