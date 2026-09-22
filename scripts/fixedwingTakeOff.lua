if GG.TakeOffFuncs then
	return
end
GG.TakeOffFuncs = {}

function GG.TakeOffFuncs.NotTakingOff(unitID)
	local state = Spring.GetUnitMoveTypeData(unitID)
	return state and (state.aircraftState ~= "takeoff")
end

function GG.TakeOffFuncs.NotLanding(unitID)
	local state = Spring.GetUnitMoveTypeData(unitID)
	return state and (state.aircraftState ~= "landing")
end


function GG.TakeOffFuncs.TakeOffThread(unitID, height, signal)
	local FUDGE_FACTOR = 1.5
	
	Signal(signal)
	SetSignalMask(signal)
	local giveUp = 20
	while Spring.MoveCtrl.GetTag(unitID) or GG.TakeOffFuncs.NotTakingOff(unitID) do
		Sleep(100)
		giveUp = giveUp - 1
		if giveUp <= 0 then
			return
		end
	end
	Spring.MoveCtrl.SetAirMoveTypeData(unitID, "wantedHeight", height*FUDGE_FACTOR)
	for i = 1, 5 do
		Sleep(100)
		if not Spring.ValidUnitID(unitID) then
			return
		end
		if not Spring.MoveCtrl.GetTag(unitID) then
			if GG.TakeOffFuncs.NotLanding(unitID) then
				Spring.MoveCtrl.SetAirMoveTypeData(unitID, "wantedHeight", 10)
			end
			Sleep(33)
		end
		while Spring.MoveCtrl.GetTag(unitID) do
			Sleep(500)
		end
		if not Spring.ValidUnitID(unitID) then
			return
		end
		if GG.TakeOffFuncs.NotLanding(unitID) then
			Spring.MoveCtrl.SetAirMoveTypeData(unitID, "wantedHeight", height*FUDGE_FACTOR)
		end
	end
end
