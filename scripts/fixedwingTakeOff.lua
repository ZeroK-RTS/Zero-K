local FUDGE_FACTOR = 1.5

local spGetUnitMoveTypeData = Spring.GetUnitMoveTypeData
local spSetAirMoveTypeData = Spring.MoveCtrl.SetAirMoveTypeData

function TakeOffThread(height, signal)
	Signal(signal)
	SetSignalMask(signal)
	while spGetUnitMoveTypeData(unitID).aircraftState ~= "takeoff" do
		Sleep(1000)
	end
	for i = 1, 5 do
		Sleep(100)
		if spGetUnitMoveTypeData(unitID) then
			spSetAirMoveTypeData(unitID, "wantedHeight", 10)
			Sleep(33)
		end
		if spGetUnitMoveTypeData(unitID) then
			spSetAirMoveTypeData(unitID, "wantedHeight", height*FUDGE_FACTOR)
		end
	end
end
