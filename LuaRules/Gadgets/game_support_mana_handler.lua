if not gadgetHandler:IsSyncedCode() then
	return
end

function gadget:GetInfo()
	return {
		name    = "Support Mana Handler",
		desc    = "Rudimentary handler which larps as the upcoming engine interface for a 3rd resource",
		author  = "Sprung",
		date    = "2022",
		license = "Public domain",
		layer   = 0,
		enabled = true,
	}
end

local mana = {}

function gadget:Initialize()

	for _, teamID in pairs(Spring.GetTeamList()) do
		mana[teamID] = 0
	end

	local function SetTeamMana (teamID, amount)
		mana[teamID] = math.min(amount, storageMax[teamID])
	end
	local function GetTeamMana (teamID)
		return mana[teamID]
	end
	local function AddTeamMana(teamID, amount)
		SetTeamMana(teamID, GetTeamMana(teamID) + amount)
	end
	local function UseTeamMana (teamID, amount)
		if mana[teamID] < amount then
			return false
		end

		AddTeamMana (teamID, -amount)
		return true
	end

	GG.Support = GG.Support or {}
	GG.Support.SetTeamMana = SetTeamMana
	GG.Support.AddTeamMana = AddTeamMana
	GG.Support.GetTeamMana = GetTeamMana
	GG.Support.UseTeamMana = UseTeamMana
end
