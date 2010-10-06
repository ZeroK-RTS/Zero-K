--[[
example buildTasksMods
		buildTasksMods = function(teamArray)
			teamArray.robots.factoryByDefId[UnitDefNames['factorycloak'].id].importance = 0
			teamArray.robots.factoryByDefId[UnitDefNames['factoryshield'].id].importance = 1
			teamArray.robots.factoryByDefId[UnitDefNames['factoryveh'].id].importance = 0
			teamArray.robots.factoryByDefId[UnitDefNames['factoryspider'].id].importance = 0
		end,

nova = armcom
logos = corcom
--]]
local function noFunc()
end

strategies = {
	[1] = {	--standard
		name = "Standard",
		chance	= 0.2,
		commanders = {
			count = 4,
			[1] = {ID = "nova", chance = 0.25},
			[2] = {ID = "logos", chance = 0.25},
			[3] = {ID = "reconcomm", chance = 0.25},
			[4] = {ID = "supportcomm", chance = 0.25},
		},
		buildTasksMods = noFunc,
		conAndEconHandlerMods = {},
	},
	[2] = {	--blitz
		name = "Blitz",
		chance	= 0.2,
		commanders = {
			count = 3,
			[1] = {ID = "nova", chance = 0.3},
			[2] = {ID = "logos", chance = 0.2},
			[3] = {ID = "reconcomm", chance = 0.4},
		},
		buildTasksMods = noFunc,
		conAndEconHandlerMods = {},
	},
	[3] = {	--pusher
		name = "Push",
		chance	= 0.2,
		commanders = {
			count = 4,
			[1] = {ID = "nova", chance = 0.3},
			[2] = {ID = "logos", chance = 0.3},
			[3] = {ID = "reconcomm", chance = 0.2},
			[4] = {ID = "supportcomm", chance = 0.2},
		},
		buildTasksMods = noFunc,
		conAndEconHandlerMods = {},
	},
	[4] = {	--defensive
		name = "Defensive",
		chance	= 0.2,
		commanders = {
			count = 3,
			[1] = {ID = "nova", chance = 0.26},
			[2] = {ID = "logos", chance = 0.37},
			[3] = {ID = "supportcomm", chance = 0.37},
		},
		buildTasksMods = noFunc,
		conAndEconHandlerMods = {},
	},
	[5] = {	--econ
		name = "Econ",
		chance	= 0.2,
		commanders = {
			count = 3,
			[1] = {ID = "nova", chance = 0.3},
			[2] = {ID = "logos", chance = 0.3},
			[3] = {ID = "supportcomm", chance = 0.4},
		},
		buildTasksMods = noFunc,
		conAndEconHandlerMods = {},
	},
}

local function SelectComm(team, strat)
	local count = strategies[strat].commanders.count
	local rand = math.random()
	
	local commName
	local total = 0
	for i = 1, count do
		total = total + strategies[strat].commanders[i].chance
		if rand < total then
			commName = strategies[strat].commanders[i].ID
			GG.SetFaction(commName, team)
			break
		end
	end
	Spring.Echo("CAI: team "..team.." has selected strategy: "..strategies[strat].name..", using commander "..commName)
end

function SelectRandomStrat(team)
	local count = #strategies
	local rand = math.random()
	
	local stratIndex
	local total = 0
	for i = 1, count do
		total = total + strategies[i].chance
		if rand < total then
			SelectComm(team, i)
			stratIndex = i
			break
		end
	end
	
	return stratIndex
end