local FUDGE_FACTOR = 1.5

function TakeOffThread(height, signal)
	Signal(signal)
	SetSignalMask(signal)
	local state = Spring.GetUnitMoveTypeData(unitID).aircraftState
	while state ~= "takeoff" do
		Sleep(500)
		state = Spring.GetUnitMoveTypeData(unitID).aircraftState
	end
	for i = 1, 5 do
		Sleep(100)
		Spring.MoveCtrl.SetAirMoveTypeData(unitID, "wantedHeight", 10)
		Sleep(33)
		Spring.MoveCtrl.SetAirMoveTypeData(unitID, "wantedHeight", height*FUDGE_FACTOR)
	end
end
