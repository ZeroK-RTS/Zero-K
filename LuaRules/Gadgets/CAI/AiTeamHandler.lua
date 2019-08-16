local AiUnitHandler = VFS.Include("LuaRules/Gadgets/CAI/AiUnitHandler.lua")
local AssetTracker = VFS.Include("LuaRules/Gadgets/CAI/AssetTracker.lua")

local aiTeamHandler = {}

function aiTeamHandler.CreateAiTeam(team, allyTeamID, allyTeamInfo)

	local myUnits = AssetTracker.CreateAssetTracker(allyTeamID, teamID)

	local function GameFrameUpdate()
	
	end

	local function UnitCreatedUpdate(unitID, unitDefID, unitTeam)
		--allyTeamInfo.AddScout(unitID)
		myUnits.AddUnit(unitID)
	end
	
	local function UnitDestroyedUpdate(unitID, unitDefID, unitTeam)
		--allyTeamInfo.RemoveScout(unitID)
		myUnits.AddUnit(unitID)
	end

	local newAiTeam = {
		GameFrameUpdate = GameFrameUpdate,
		UnitCreatedUpdate = UnitCreatedUpdate,
		UnitDestroyedUpdate = UnitDestroyedUpdate,
	}
	
	return newAiTeam
end

return aiTeamHandler
