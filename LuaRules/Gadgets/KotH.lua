-- $Id$
-- CA Version

-- King of the Hill for ModOptions -------------------------------------
-- Set up an empty box on Spring Lobby (other clients might crash) ------
-- Set up the time to control the box in ModOptions --------------------
--------------------------------------------------------------------

function gadget:GetInfo()
	return {
		name = "King of the Hill",
		desc = "obvious",
		author = "Alchemist, Licho",
		date = "April 2009",
		license = "Public domain",
		layer = 1,
		enabled = true
	}
end


local blockedDefs = {
	[ UnitDefNames['terraunit'].id ] = true,
	[ UnitDefNames['cormine1'].id ] = true,
}

---------------------------------------------------------------------------------

if(not Spring.GetModOptions()) then
	return false
end

local teamBoxes = {}

for _, allyTeamID in ipairs(Spring.GetAllyTeamList()) do 
	local teams = Spring.GetTeamList(allyTeamID)
	if  (teams == nil or #teams == 0) then
		local x1, z1, x2, z2 = Spring.GetAllyTeamStartBox(allyTeamID)
		if (x1 ~= nil) then
			table.insert(teamBoxes, {x1, z1, x2, z2})
		end 
	end 
end 


--UNSYNCED-------------------------------------------------------------------
if(not gadgetHandler:IsSyncedCode()) then
	
	local teams = {}
	local teamTimer = nil
	local teamControl = -2
	local r, g, b = 255, 255, 255
	local grace = 1
	
	
	function gadget:Initialize()
		if(Spring.GetModOptions().camode ~= "kingofthehill") then
			gadgetHandler:RemoveGadget()
		end
		gadgetHandler:AddSyncAction("changeColor", setBoxColor)
		gadgetHandler:AddSyncAction("changeTime", updateTimers)
	end
	
	function gadget:DrawWorldPreUnit()
		gl.DepthTest(false)
		gl.Color(r, g, b, 0.4)
		for _, box in ipairs(teamBoxes) do 
			gl.DrawGroundQuad(box[1], box[2], box[3], box[4], true)
		end 
	end
	
	function DrawScreen()
		local vsx, vsy = gl.GetViewSizes()
		local posx = vsx * 0.5
		if(grace > 0) then
			posy = vsy * 0.75
			gl.Color(255, 255, 255, 1)
			if(grace % 60 < 10) then
				gl.Text("Grace period over in " .. math.floor(grace/60) .. ":0" .. math.floor(grace%60), posx, posy, 14, "ocn")
			else
				gl.Text("Grace period over in " .. math.floor(grace/60) .. ":" .. math.floor(grace%60), posx, posy, 14, "ocn")
			end
		end
		if (teamControl >= 0) then 
			local posy = vsy * 0.25
			gl.Color(255, 255, 255, 1)
			if(teamTimer % 60 < 10) then
				gl.Text("Team " .. teamControl + 1 .. " - " .. math.floor(teamTimer/60) .. ":0" .. math.floor(teamTimer%60), posx, posy, 12, "ocn")
			else
				gl.Text("Team " .. teamControl + 1 .. " - " .. math.floor(teamTimer/60) .. ":" .. math.floor(teamTimer%60), posx, posy, 12, "ocn")
			end
		end 
	end
	
	function updateTimers(cmd, team, newTime, graceT)
		if(graceT) then
			grace = graceT
		else
			teamTimer = newTime
			teamControl = team
		end
	end
	
	function setBoxColor(cmd, team)
		if(team < 0) then
			r, g, b = 255, 255, 255
		else
			r, g, b = Spring.GetTeamColor(team)
		end
	end
	
end
---------------------------------------------------------------------------------

--SYNCED-----------------------------------------------------------------------
if(gadgetHandler:IsSyncedCode()) then

	local actualTeam = -1
	local control = -1
	local goalTime = 0
	local timer = -1
	local lastControl = nil
	local lastHolder = nil
	local grace = 0
	local lG = 0

	
	function gadget:Initialize()
		if(Spring.GetModOptions().camode ~= "kingofthehill") then
			gadgetHandler:RemoveGadget()
		end
		goalTime = (Spring.GetModOptions().hilltime or 0) * 60
		lG = Spring.GetModOptions().gracetime
		if lG then
			grace = lG * 60
		else
			grace = 0
		end
		timer = goalTime
	end
	
	function gadget:GameStart()
		Spring.Echo("Goal time is " .. goalTime / 60 .. " minutes.")
	end

	function gadget:GameFrame(f)
		if(f%30 == 0 and f < grace * 30 + lG*30*60) then
			grace = grace - 1
			SendToUnsynced("changeTime", nil, nil, grace)
		end
		if(f == grace*30 + lG*30*60) then
			SendToUnsynced("changeTime", nil, nil, grace)
			Spring.Echo("Grace period is over. GET THE HILL!")
		end
		if(f % 32 == 15 and f > grace*30 + lG*30*60) then
			local control = -2 
			local team = nil 
			local present = false 
			
			for _, box in ipairs(teamBoxes) do 
				for _, u in ipairs(Spring.GetUnitsInRectangle(box[1], box[2], box[3], box[4])) do
					local ally = Spring.GetUnitAllyTeam(u)
					if (lastControl == ally) then
						present = true
					end
				
					if (control == -2)  then 
						if (not blockedDefs[Spring.GetUnitDefID(u)]) then 
							control = ally
							team = Spring.GetUnitTeam(u)
						end 
					else 
						if (control ~= ally) then 
							control = -1
							break
						end 
					end
				end 
			end 
			
			if(control ~= lastControl) then
				if (control == -1) then
					Spring.Echo("Control contested.")
					SendToUnsynced("changeColor", -1)
				else
					if (control == -2) then 
						Spring.Echo("Team " .. control + 1 .. " lost control.")
						SendToUnsynced("changeColor", -1)
						timer = goalTime
						SendToUnsynced("changeTime", control, timer)
					else 
						actualTeam = team
						if (lastHolder ~= control) then 
							timer = goalTime
							lastHolder = control
						end 
						
						Spring.Echo("Team " .. control + 1 .. " is now in control.")
						SendToUnsynced("changeColor", actualTeam)
						lastHolder = control
					end
				end 
			end
			
			if (control >= 0) then 
				timer = timer - 1  
				SendToUnsynced("changeTime", control, timer)				
			end

			if(control >= 0 and timer == 0) then
				Spring.Echo("Team " .. control + 1 .. " has won!")
				gameOver(actualTeam)
			end 
			
			lastControl = control						

		end
	end
	
	
	function gameOver(team)
		for _, u in ipairs(Spring.GetAllUnits()) do
			if(not Spring.AreTeamsAllied(Spring.GetUnitTeam(u), team)) then
				Spring.DestroyUnit(u, true)
			end
		end
	end

end

