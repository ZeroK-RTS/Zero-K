--------------------------------------------------------------------------------
--------------------------------------------------------------------------------

function widget:GetInfo()
  return {
    name      = "Selection Hierarchy",
    desc      = "Do selection hierarchy like military>constructors>buildings.",
    author    = "GoogleFrog",
    date      = "13 April 2017",
    license   = "GNU GPL, v2 or later",
    layer     = -math.huge,
    enabled   = true  --  loaded by default?
  }
end

--------------------------------------------------------------------------------
--------------------------------------------------------------------------------

local selectionRank = {}

for i = 1, #UnitDefs do
	local ud = UnitDefs[i]
	if ud.isImmobile or ud.speed == 0 then
		selectionRank[i] = 1
	elseif ud.isMobileBuilder then
		selectionRank[i] = 2
	else
		selectionRank[i] = 3
	end
end

--------------------------------------------------------------------------------
--------------------------------------------------------------------------------


function widget:SelectionChanged(units)
	if not units then
		return
	end
	local alt, ctrl, meta, shift = Spring.GetModKeyState()
	if shift then
		return
	end
	
	local needsChanging = false
	local bestRank, bestUnits 
	for i = 1, #units do
		local unitID = units[i]
		local unitDefID = Spring.GetUnitDefID(unitID)
		local rank = unitDefID and selectionRank[unitDefID]
		if rank then
			if (not bestRank) or (bestRank < rank) then
				bestRank = rank
				bestUnits = {unitID}
			elseif bestRank == rank then
				bestUnits[#bestUnits + 1] = unitID
			else
				needsChanging = true
			end
		end
	end
	
	if needsChanging then
		return bestUnits
	end
end


--------------------------------------------------------------------------------
--------------------------------------------------------------------------------