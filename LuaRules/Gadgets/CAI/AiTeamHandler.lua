local AiUnitHandler = VFS.Include("LuaRules/Gadgets/CAI/AiUnitHandler.lua")

local aiTeamHandler = {}

function aiTeamHandler.CreateAiTeam(team, allyTeamID, allyTeamInfo)


	local function GameFrameUpdate()
	
	end

	local function UnitCreatedUpdate(unitID, unitDefID, unitTeam)
		allyTeamInfo.AddScout(unitID)
	end
	
	local function UnitDestroyedUpdate(unitID, unitDefID, unitTeam)
		allyTeamInfo.RemoveScout(unitID)
	end

	local newAiTeam = {
		GameFrameUpdate = GameFrameUpdate,
		UnitCreatedUpdate = UnitCreatedUpdate,
		UnitDestroyedUpdate = UnitDestroyedUpdate,
	}
	
	return newAiTeam
end

return aiTeamHandler