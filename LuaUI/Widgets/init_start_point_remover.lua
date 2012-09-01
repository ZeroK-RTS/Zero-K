-- $Id: init_start_point_remover.lua 3171 2008-11-06 09:06:29Z det $
function widget:GetInfo()
  return {
    name      = "Start Point Remover & Comm Selector",
    desc      = "Deletes your start point once the game begins & select commander",
    author    = "TheFatController and jK",
    date      = "Jul 11, 2007",
    license   = "GNU GPL, v2 or later",
    layer     = 0,
    enabled   = true  --  loaded by default?
  }
end

	n=1 --counter just in case there would be more than one unit spawned with only one being the comm but not being the first one. Note that if the Commander is spawned with an offset from the start point the marker may not be erased.

function widget:Initialize()

  if (CheckForSpec()) then return false end
 
end

function CheckForSpec()
   if (Spring.GetSpectatingState() or Spring.IsReplay()) and (not Spring.IsCheatingEnabled()) then
    widgetHandler:RemoveWidget()
    return true
  end
end

function widget:Update()
	local t = Spring.GetGameSeconds()
	if (t < 0.1) then return end
	local teamUnits = Spring.GetTeamUnits(Spring.GetMyTeamID())
	for _,unitID in ipairs(teamUnits) do
	local unitDefID = Spring.GetUnitDefID(unitID)
	local unitDef   = UnitDefs[unitDefID]
		if (unitDef.customParams.commtype) then
			local x, y, z = Spring.GetUnitPosition(unitID)
			Spring.MarkerErasePosition(x, y, z)
			Spring.SetCameraTarget(x, y, z)
			Spring.SelectUnitArray{teamUnits[n]}
		end
		n=n+1
	end
	widgetHandler:RemoveWidget()
end