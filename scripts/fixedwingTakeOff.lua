if GG.TakeOffFuncs then
	return
end
GG.TakeOffFuncs = {}

function GG.TakeOffFuncs.NotTakingOff()
	local state = Spring.GetUnitMoveTypeData(unitID)
	return state and (state.aircraftState ~= "takeoff")
end

function GG.TakeOffFuncs.TakeOffThread(height, signal)
	local FUDGE_FACTOR = 1.5
	
	Signal(signal)
	SetSignalMask(signal)
	while  GG.TakeOffFuncs.NotTakingOff() do
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
