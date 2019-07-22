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
	while GG.TakeOffFuncs.NotTakingOff() do
		Sleep(1000)
	end
	for i = 1, 5 do
		Sleep(100)
		if not Spring.ValidUnitID(unitID) then
			return
		end
		if not Spring.MoveCtrl.GetTag(unitID) then
			Spring.MoveCtrl.SetAirMoveTypeData(unitID, "wantedHeight", 10)
			Sleep(33)
		end
		while Spring.MoveCtrl.GetTag(unitID) do
			Sleep(500)
		end
		if not Spring.ValidUnitID(unitID) then
			return
		end
		Spring.MoveCtrl.SetAirMoveTypeData(unitID, "wantedHeight", height*FUDGE_FACTOR)
	end
end
