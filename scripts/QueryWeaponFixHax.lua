-- TODO: CACHE INCLUDE FILE
local queryPiece
local aimPiece, shootPiece

function SetupQueryWeaponFixHax(newAimPiece, newShootPiece)
	queryPiece = newAimPiece
	aimPiece, shootPiece = newAimPiece, newShootPiece
end

function AimingDone()
	queryPiece = shootPiece
	Sleep(500)
	queryPiece = aimPiece
end

function GetQueryPiece()
	return queryPiece
end
