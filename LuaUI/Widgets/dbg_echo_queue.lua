
function widget:GetInfo()
	return {
		name      = "Echo Queue",
		desc      = "Echos the queue of selected units",
		author    = "GoogleFrog",
		date      = "1 August 2019",
		license   = "GNU GPL, v2 or later",
		layer     = 0,
		enabled   = false  --  loaded by default?
	}
end

function widget:SelectionChanged(selectedUnits)
	if not (selectedUnits and selectedUnits[1]) then
		return
	end
	local unitID = selectedUnits[1]
	local cQueue = Spring.GetCommandQueue(unitID, -1)
	if cQueue then
		Spring.Utilities.TableEcho(cQueue, "cQueue")
		Spring.Utilities.UnitEcho(unitID, "queue")
	else
		Spring.Utilities.UnitEcho(unitID, "no queue")
	end
end
