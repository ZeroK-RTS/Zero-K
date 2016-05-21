commands = {
	{
		command = "autocheat",
		description = i18n("autocheat_desc", {default = "Provides automatic /cheat for commands that need it."}),
		exec = function(command, cmdParts)
			autoCheat = not autoCheat
			if autoCheat then
				Spring.Echo(i18n("autocheat_enabled", { default = "AutoCheat enabled."}))
			else
				Spring.Echo(i18n("autocheat_disabled", { default = "AutoCheat disabled."}))
			end
		end,
	},
	{
		command = "luaui",
		suggestions = function(cmd, cmdParts)
			local suggestions = {}
			local param = cmdParts[2]
			for _, name in pairs({"reload", "enable"}) do
				if param == nil or param == "" or name:starts(param) then
					table.insert(suggestions, { command = "/luaui " .. name, text = name, description = value })
				end
			end
			return suggestions
		end,
	},
	{
		command = "luarules",
		suggestions = function(cmd, cmdParts)
			local suggestions = {}
			local param = cmdParts[2]
			for _, name in pairs({"reload", "enable"}) do
				if param == nil or param == "" or name:starts(param) then
					table.insert(suggestions, { command = "/luarules " .. name, text = name, description = value })
				end
			end
			return suggestions
		end,
	},
	{
		command = "give",
		suggestions = function(cmd, cmdParts)
			local suggestions = {}
			local param = cmdParts[2]
			local count
			local teamPart = cmdParts[3]
			if tonumber(param) ~= nil then
				param = cmdParts[3]
				count = tonumber(cmdParts[2])
				if math.floor(count) ~= count or count <= 0 then
					return suggestions
				end
				teamPart = cmdParts[4]
			end
			for id, uDef in pairs(UnitDefs) do
				if param == nil or param == "" or uDef.name:starts(param) then
					local text = uDef.name
					local desc = "Give " .. uDef.name
					if count then
						text = count .. " " .. text
						desc = "Give " .. count .. " " .. uDef.name
					end
					if teamPart then
						for _, teamID in pairs(Spring.GetTeamList()) do
							if teamPart == "" or tostring(teamID):starts(teamPart) then
								local teamText = text .. " " .. teamID
								local teamDesc = desc .. " to team " .. teamID
								if uDef.name ~= uDef.tooltip then
									teamDesc = teamDesc .. ". " .. uDef.tooltip
								end
								table.insert(suggestions, { command = "/give " .. teamText, text = teamText, description = teamDesc })
							end
						end
					else
						if uDef.name ~= uDef.tooltip then
							desc = desc .. ". " .. uDef.tooltip
						end
						table.insert(suggestions, { command = "/give " .. text, text = text, description = desc })
					end
				end
			end
			return suggestions
		end,
	},
	{
		command = "w",
		suggestions = function(cmd, cmdParts)
			local suggestions = {}
			local param = cmdParts[2]
			for _, playerID in pairs(Spring.GetPlayerList()) do
				local playerName = Spring.GetPlayerInfo(playerID)
				table.insert(suggestions, { command = "/w " .. playerName, text = playerName})
			end
			return suggestions
		end,
	},
	{
		command = "set",
		suggestions = function(cmd, cmdParts)
			local suggestions = {}
			local param = cmdParts[2]
			for _, config in pairs(Spring.GetConfigParams()) do
				if param == nil or param == "" or config.name:starts(param) then
					local desc = config.description
					if desc then
						desc = desc:gsub("\n", " ")
					end
					table.insert(suggestions, { command = "/set " .. config.name, text = config.name, description = desc})
				end
			end
			return suggestions
		end, 
	},
}