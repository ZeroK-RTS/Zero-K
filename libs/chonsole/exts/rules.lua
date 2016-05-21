commands = {
	{ 
		command = "gamerules",
		description = i18n("gamerules_desc", {default="Sets values of specific gamerules variables"}),
		cheat = true,
		suggestions = function(cmd, cmdParts)
			local suggestions = {}
			local param = cmdParts[2]
			for name, value in pairs(Spring.GetGameRulesParams()) do
				if param == nil or param == "" or name:starts(param) then
					table.insert(suggestions, { command = "/gamerules " .. name, text = name, description = value })
				end
			end
			return suggestions
		end,
		exec = function(command, cmdParts)
			if #cmdParts >= 3 then
				Sync(cmdParts[2], cmdParts[3])
			end
		end,
		execs = function(rule, value)
			Spring.SetGameRulesParam(rule, value)
		end,
	},
	{ 
		command = "teamrules",
		description = i18n("teamrules_desc", {default="Sets values of specific teamrules variables"}),
		cheat = true,
		suggestions = function(cmd, cmdParts)
			local suggestions = {}
			local teamID = tonumber(cmdParts[2] or "")
			if teamID == nil then
				return suggestions
			end

			local param = cmdParts[3]
			for name, value in pairs(Spring.GetTeamRulesParams(teamID)) do
				if param == nil or param == "" or name:starts(param) then
					table.insert(suggestions, { command = "/teamrules " .. name, text = name, description = value })
				end
			end
			return suggestions
		end,
		exec = function(command, cmdParts)
			if #cmdParts >= 4 then
				Sync(cmdParts[2], cmdParts[3], cmdParts[4])
			end
		end,
		execs = function(teamID, rule, value)
			Spring.SetTeamRulesParam(teamID, rule, value)
		end,
	},
	{ 
		command = "unitrules",
		description = i18n("unitrules_desc", {default="Sets unitrules for the selected units"}),
		cheat = true,
		suggestions = function(cmd, cmdParts)
			local suggestions = {}
			local units = Spring.GetSelectedUnits()
			if #units == 0 then
				return suggestions
			end
			
			local unitrules = {}
			local different = {} -- mapping of unit rules that differ
			for i, unitID in pairs(units) do
				local rules = Spring.GetUnitRulesParams(unitID)
				for name, value in pairs(rules) do
					if i == 1 then
						unitrules[name] = value
					elseif unitrules[name] ~= value then
						unitrules[name] = value
						different[name] = true
					end
				end
			end
			
			local param = cmdParts[2]
			for name, value in pairs(unitrules) do
				if param == nil or param == "" or name:starts(param) then
					local v = value
					if different[name] then
						v = "?"
					end
					table.insert(suggestions, { command = "/unitrules " .. name, text = name, description = v})
				end
			end
			return suggestions
		end,
		exec = function(command, cmdParts)
			local units = Spring.GetSelectedUnits()
			if #units == 0 then
				return
			end
			if #cmdParts >= 3 then
				for _, unitID in pairs(units) do
					Sync(unitID, cmdParts[2], cmdParts[3])
				end
			end
		end,
		execs = function(unitID, rule, value)
			Spring.SetUnitRulesParam(unitID, rule, value)
		end,
	},
}
