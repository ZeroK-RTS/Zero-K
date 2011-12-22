function widget:GetInfo()
  return {
    name      = "Attack Warning",
    desc      = "Warns if stuff gets attacked",
    author    = "knorke",
    date      = "Oct 2011",
    license   = "GNU GPL, v2 or later",
    layer     = 0,
    enabled   = true,
  }
end

local warningDelay = 30 * 5 	--in frames
local lastWarning = 0			--in frames
local localTeamID = Spring.GetLocalTeamID ()

function widget:UnitDamaged (unitID, unitDefID, unitTeam, damage, paralyzer, weaponID, attackerID, attackerDefID, attackerTeam)	
	local currentFrame = Spring.GetGameFrame ()
	if (lastWarning+warningDelay > currentFrame) then		
		return
	end
	if (localTeamID==unitTeam and not Spring.IsUnitInView (unitID)) then
		lastWarning = currentFrame
		local attackedUnit = (unitDefID and UnitDefs[unitDefID].humanName) or "Unit"
		Spring.Echo (attackedUnit  .." is under attack")
		--Spring.PlaySoundFile (blabla attack.wav, ... "userinterface")
		local x,y,z = Spring.GetUnitPosition (unitID)
		if (x and y and z) then
			Spring.SetLastMessagePosition (x,y,z)
		end
	end
end

--changing teams, rejoin, becoming spec etc
function widget:PlayerChanged (playerID)
	localTeamID = Spring.GetLocalTeamID ()	
end