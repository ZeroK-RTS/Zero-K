if GG.TakeOffThread then
	return
end

function GG.TakeOffThread(height, signal)
	local FUDGE_FACTOR = 1.5
	
	Signal(signal)
	SetSignalMask(signal)
	while Spring.GetUnitMoveTypeData(unitID).aircraftState ~= "takeoff" do
		Sleep(1000)
	end
	for i = 1, 5 do
		Sleep(100)
		if Spring.MoveCtrl.GetTag(unitID) == nil then
			Spring.MoveCtrl.SetAirMoveTypeData(unitID, "wantedHeight", 10)
			Sleep(33)
		end
		while Spring.MoveCtrl.GetTag(unitID) do
			Sleep(500)
		end
		Spring.MoveCtrl.SetAirMoveTypeData(unitID, "wantedHeight", height*FUDGE_FACTOR)
	end
end
