-------------------------------------------------------------------------------- 
-------------------------------------------------------------------------------- 
--
-- disallow viewing of enemy startbox after it was shuffled
--

if (Spring.GetModOptions().shuffledbox=="1") and (not Spring.GetSpectatingState()) then
	local myAllyID = Spring.GetMyAllyTeamID()

	--Scramble GetAllyTeamStartBox() output
	local allyBox = {}
	local shfBox = {}
	for at=0, 32 do
		if (at ~= myAllyID) then
			local ex,ez,ex1,ez1 = Spring.GetAllyTeamStartBox(at)
			if ex then
				allyBox[at+1] = 10
				shfBox[#shfBox+1] = {ex,ez,ex1,ez1}
			end
		end
	end
	
	--shuffle
	math.randomseed(os.date("!*t").sec)
	for i=1, #shfBox do
		local newPos = math.random(1,#shfBox)
		if i ~= newPos then
			local temp = shfBox[i]
			shfBox[i] = shfBox[newPos]
			shfBox[newPos] = temp
		end
	end

	local cnt = 1
	for at,_ in pairs(allyBox) do
		allyBox[at] = shfBox[cnt]
		cnt = cnt + 1
	end
	--our startbox
	allyBox[myAllyID + 1] = {Spring.GetAllyTeamStartBox(myAllyID)}
	
	function Spring.GetAllyTeamStartBox(allyID)
		if not allyBox[allyID+1] then
			return nil,0,100,100
		end
		return unpack(allyBox[allyID+1])
	end
end