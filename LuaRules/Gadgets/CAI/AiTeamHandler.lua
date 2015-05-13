


local AiUnitHandler = VFS.Include("LuaRules/Gadgets/CAI/AiUnitHandler.lua")
local ScoutHandler = VFS.Include("LuaRules/Gadgets/CAI/ScoutHandler.lua")

local aiTeamHandler = {}

function aiTeamHandler.CreateAiTeam(team, allyTeamID, allyTeamInfo)


	function Update()
	
	end

	function AddUnit(unitID)
	
	end
	
	function RemoveUnit(unitID)
	
	end



	local newAiTeam = {
		UpdateHeatmap = UpdateHeatmap,
		RunJobHandler = RunJobHandler,
		IsScoutingRequired = IsScoutingRequired,
		GetScoutedProportion = GetScoutedProportion,
		GetPositionToScount = GetPositionToScount,
	}
	
	return newAiTeam
end

return aiTeamHandler