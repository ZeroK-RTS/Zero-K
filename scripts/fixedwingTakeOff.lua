local FUDGE_FACTOR = 1.5

local spGetUnitMoveTypeData = Spring.GetUnitMoveTypeData
local spSetAirMoveTypeData = Spring.MoveCtrl.SetAirMoveTypeData
local spMoveCtrlGetTag = Spring.MoveCtrl.GetTag

function TakeOffThread(height, signal)
	Signal(signal)
	SetSignalMask(signal)
	while spGetUnitMoveTypeData(unitID).aircraftState ~= "takeoff" do
		Sleep(1000)
	end
	for i = 1, 5 do
		Sleep(100)
		if spMoveCtrlGetTag(unitID) == nil then
			spSetAirMoveTypeData(unitID, "wantedHeight", 10)
			Sleep(33)
		end
		if spMoveCtrlGetTag(unitID) == nil then
			spSetAirMoveTypeData(unitID, "wantedHeight", height*FUDGE_FACTOR)
		end
	end
end
