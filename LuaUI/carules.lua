-------------------------------------------------------------------------------- 
-------------------------------------------------------------------------------- 
--
-- disallow viewing of enemy startbox after it was shuffled
--

if (Spring.GetModOptions().shuffledbox=="1") and (not Spring.GetSpectatingState()) then
	local myAllyID = Spring.GetMyAllyTeamID()
	local x,z,x2,z2 = Spring.GetAllyTeamStartBox(myAllyID)
	
	function Spring.GetAllyTeamStartBox(allyID)
		if allyID ~= myAllyID then
			return nil,0,100,100
		else
			return x,z,x2,z2
		end
	end
end