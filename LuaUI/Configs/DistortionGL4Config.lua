-- This file contains all the unit-attached distortions
-- Including scripted distortions, like thruster attached ones, and fusion glows

local exampleDistortion = {
	distortionType = "point", -- or cone or beam
	-- if pieceName == nil then the distortion is treated as WORLD-SPACE
	-- if pieceName == valid piecename, then the distortion is attached to that piece
	-- if pieceName == invalid piecename, then the distortion is attached to base of unit
	pieceName = nil,
	-- If you want to make the distortion be offset from the top of the unit, specify how many elmos above it should be!
	aboveUnit = nil,
	-- Distortions that should spawn even if they are outside of view need this set:
	alwaysVisible = nil,
	distortionConfig = {
		posx = 0,
		posy = 0,
		posz = 0,
		radius = 100,
		-- cone distortions only, specify direction and half-angle in radians:
		dirx = 0,
		diry = 0,
		dirz = 1,
		theta = 0.5,
		-- beam distortions only, specifies the endpoint of the beam:
		pos2x = 100,
		pos2y = 100,
		pos2z = 100,
		lifeTime = 0,
		sustain = 1,
		selfshadowing = 0,
	},
}

-- multiple distortions per unitdef/piece are possible, as the distortions are keyed by distortionname

local unitDistortions = {

	energysingu = {
		distortion = {
			distortionType = "point",
			pieceName = "energyball",
			distortionConfig = {
				posx = 0,
				posy = 0,
				posz = 0,
				radius = 46,
				noiseStrength = 0.9,
				noiseScaleSpace = 1.2,
				distanceFalloff = 0.5,
				windAffected = -0.2,
				riseRate = 0.6,
				lifeTime = 0,
				effectType = 0,
			},
		},
	},
}

local airjets_effects = VFS.Include("luaui/configs/airjet_effects.lua")

do
	-- This is the base effect for the airjet distortion, tune it to affect all airjets
	local longAirJet = {
		posx = 0,
		posy = 0,
		posz = 0,
		radius = 130,
		dirx = 0,
		diry = -0,
		dirz = -1.0,
		theta = 0.08,
		noiseStrength = 2,
		noiseScaleSpace = 0.85,
		distanceFalloff = 1.5,
		effectStrength = 4.0,
		onlyModelMap = 0, -- I want it on unit and background too
		lifeTime = 0,
		effectType = 0,
	}

	for unitDefName, airjets in pairs(airjets_effects) do
		if not unitDistortions[unitDefName] then
			unitDistortions[unitDefName] = {}
		end
		for i, airjet in ipairs(airjets) do
			-- if that piece already has a distortion attached to it, we won't overwrite it.
			local alreadyhasjet = false
			for j, distortion in pairs(unitDistortions[unitDefName]) do
				if distortion.pieceName == airjet.piece then
					-- Spring.Echo("airjet distortion already exists for piece", unitDefName, airjet.piece)
					alreadyhasjet = true
					break
				end
			end
			if not alreadyhasjet then
				local effectname = "airjet" .. tostring(i) .. airjet.piece
				local airjetConfig = table.copy(longAirJet)

				-- The radius and cone angle are set to be close to the airjet length and width
				airjetConfig.radius = airjet.distortLength or (airjet.length * 2.5)
				-- We need to set the theta angle (half -angle of the cone in radians) to ensure that the width-length ratio is correct
				airjetConfig.theta = math.atan(airjet.width / airjetConfig.radius * 2.5) * 1.2

				--Spring.Echo("airjetConfig.theta", airjetConfig.theta, airjet.width, airjet.length)

				unitDistortions[unitDefName][effectname] = {
					distortionType = "cone",
					pieceName = airjet.piece,
					distortionConfig = airjetConfig,
				}
			end
		end
	end
end

local function BigStomp(piece)
	return {
		-- Footstep shockwave
		alwaysVisible = false,
		distortionType = "point",
		distortionName = "bigstomp",
		pieceName = piece,
		distortionConfig = {
			posx = 0,
			posy = -6,
			posz = 12,
			radius = 60,
			noiseStrength = 1.2,
			noiseScaleSpace = 0.4,
			distanceFalloff = 0.4,
			onlyModelMap = 1,
			effectStrength = 0.7,
			lifeTime = 15,
			rampUp = 3,
			decay = 15,
			startRadius = 0.3,
			shockWidth = 5,
			effectType = "groundShockwave",
		},
	}
end

local function SmallStomp(piece)
	return {
		-- Footstep shockwave
		alwaysVisible = false,
		distortionType = "point",
		distortionName = "smallstomp",
		pieceName = piece,
		distortionConfig = {
			posx = 0,
			posy = -8,
			posz = 0,
			radius = 35,
			noiseStrength = 1.2,
			noiseScaleSpace = 0.4,
			distanceFalloff = 0.5,
			onlyModelMap = 1,
			effectStrength = 0.5,
			lifeTime = 12,
			rampUp = 3,
			decay = 10,
			startRadius = 0.3,
			shockWidth = 3,
			effectType = "groundShockwave",
		},
	}
end

local unitEventDistortionsNames = {
	UnitScriptDistortions = {

		striderdetriment = {
			leftfoot = BigStomp("lfoot"),
			rightfoot = BigStomp("rfoot"),
		},
		jumpsumo = {
			leftfront = SmallStomp("lf_foot"),
			rightfront = SmallStomp("rf_foot"),
			leftback = SmallStomp("lb_foot"),
			rightback = SmallStomp("rb_foot"),
		},
		
		staticheavyarty = {
			basestomp ={
				-- Footstep shockwave
				alwaysVisible = false,
				distortionType = "point",
				distortionName = "bigstomp",
				pieceName = "base",
				distortionConfig = {
					posx = 0,
					posy = -6,
					posz = 0,
					radius = 180,
					noiseStrength = 1.5,
					noiseScaleSpace = 0.5,
					distanceFalloff = 0.5,
					onlyModelMap = 1,
					effectStrength = 0.3,
					lifeTime = 16,
					rampUp = 2.5,
					decay = 16,
					startRadius = 0.25,
					shockWidth = 7,
					effectType = "groundShockwave",
				},
			},
			shotheat = {
				-- Barrel Heat after shot
				alwaysVisible = false,
				distortionType = "beam",
				distortionName = "brthabarrelheat",
				pieceName = "sleeve",
				distortionConfig = {
					posx = 0,
					posy = 5,
					posz = 90,
					radius = 50,
					pos2x = 0,
					pos2y = 5,
					pos2z = 150,
					onlyModelMap = 0,
					riseRate = 0.5,
					windAffected = -0.5,
					noiseStrength = 0.3,
					noiseScaleSpace = 1.0,
					distanceFalloff = 1.0,
					rampUp = 20,
					decay = 200,
					lifeTime = 240,
					effectType = 0,
				},
			},
		},
	},

	------------------------------- Put additional distortions tied to events here! --------------------------------
	UnitIdle = {
		--[[
		['armcom'] = {
			idleBlink = {
				distortionType = 'point',
				pieceName = 'head',
				distortionConfig = { posx = 0, posy = 22, posz = 12, radius = 90,
					lifeTime = 12,  effectType = 0},
			},
		},
		]]
		--
	},

	UnitFinished = {
		--[[
		default = {
			default = {
				distortionType = 'cone',
				--pieceName = 'base',
				aboveUnit = 100,
				distortionConfig = { posx = 0, posy = 32, posz = 0, radius = 160,
					dirx = 0, diry = -0.99, dirz = 0.02, theta = 0.4,
					lifeTime = 20, sustain = 2, effectType = 0},
			},
		},
		]]
		--
	},

	UnitCreated = {
		--[[
		default = {
			default = {
				distortionType = 'cone',
				pieceName = 'base',
				aboveUnit = 100,
				distortionConfig = { posx = 0, posy = 32, posz = 0, radius = 200,
					dirx = 0, diry = -0.99, dirz = 0.02, theta = 0.4,
					lifeTime = 15, sustain = 2, effectType = 0},
			},
		},
		]]
		--
	},

	UnitCloaked = {
		--[[
		['armcom'] = {
			cloakBlink = {
				distortionType = 'point',
				pieceName = 'head',
				distortionConfig = { posx = 0, posy = 0, posz = 0, radius = 100,
					lifeTime = 30,  effectType = 0},
			},
			-- cloakFlash = {
			-- 	distortionType = 'point',
			-- 	pieceName = 'head',
			-- 	distortionConfig = { posx = 0, posy = -10, posz = 0, radius = 70,
			-- 		color2r = 1, color2g = 1, color2b = 1, colortime = 5,
			-- 		r = 0, g = 0, b = 0, a = 0.45,
			-- 		modelfactor = 0.2, specular = 0.4, scattering = 1.5, lensflare = 0,
			-- 		lifeTime = 5,  effectType = 0},
			-- },
		},
		default = {
			default = {
				distortionType = 'cone',
				pieceName = 'base',
				aboveUnit = 100,
				distortionConfig = { posx = 0, posy = 32, posz = 0, radius = 200,
					dirx = 0, diry = -0.99, dirz = 0.02, theta = 0.4,
					lifeTime = 15,  effectType = 0},
			},
		},
		]]
		--
	},

	UnitDecloaked = {
		--[[
		['armcom'] = {
			cloakBlink = {
				distortionType = 'point',
				pieceName = 'head',
				distortionConfig = { posx = 0, posy = 0, posz = 0, radius = 100,
					lifeTime = 30,  effectType = 0},
			},
		},
		default = {
			default = {
				distortionType = 'cone',
				pieceName = 'base',
				aboveUnit = 100,
				distortionConfig = { posx = 0, posy = 32, posz = 0, radius = 200,
					dirx = 0, diry = -0.99, dirz = 0.02, theta = 0.4,
					lifeTime = 15,  effectType = 0},
			},
		},
		]]
		--
	},

	StockpileChanged = {},
	UnitMoveFailed = {},

	UnitGiven = {},
	UnitTaken = {},
	UnitDestroyed = { -- note: dont do piece-attached distortions here!
		--[[
		default = {
			default = {
				distortionType = 'cone',
				pieceName = '',
				aboveUnit = 100,
				distortionConfig = { posx = 0, posy = 32, posz = 0, radius = 200,
					dirx = 0, diry = -0.99, dirz = 0.02, theta = 0.4,
					lifeTime = 15, effectType = 0},
			},
		},
		]]
		--
	},
}

-- Copy all distortions from source unitname to array of target unitnames
local function DuplicateDistortions(source, targets)
	for i, target in pairs(targets) do
		if UnitDefNames[source] and UnitDefNames[target] then
			if unitDistortions[source] then
				unitDistortions[target] = table.copy(unitDistortions[source])
			end

			for eventName, distortions in pairs(unitEventDistortionsNames) do
				if unitEventDistortionsNames[eventName][source] then
					unitEventDistortionsNames[eventName][target] =
						table.copy(unitEventDistortionsNames[eventName][source])
				end
			end
		end
	end
end

--AND THE REST
---unitEventDistortionsNames -> unitEventDistortions
local unitEventDistortions = {}
for key, subtables in pairs(unitEventDistortionsNames) do
	unitEventDistortions[key] = {}
	for subKey, distortions in pairs(subtables) do
		if UnitDefNames[subKey] then
			unitEventDistortions[key][UnitDefNames[subKey].id] = distortions
		else
			unitEventDistortions[key][subKey] = distortions --preserve defaults etc
		end
	end
end
unitEventDistortionsNames = nil

-- convert unitname -> unitDefID
local unitDefDistortions = {}
for unitName, distortions in pairs(unitDistortions) do
	if UnitDefNames[unitName] then
		unitDefDistortions[UnitDefNames[unitName].id] = distortions
	end
end
unitDistortions = nil

local featureDefDistortions = {}

-- Example featureDefDistortion below
local crystalDistortionBase = {
	distortionType = "point",
	distortionConfig = {
		posx = 0,
		posy = 8,
		posz = 0,
		radius = 20,
		onlyModelMap = 0,
		riseRate = 0.5,
		windAffected = -0.5,

		noiseStrength = 0.4,
		noiseScaleSpace = 2.2,
		distanceFalloff = 1.2,
		lifeTime = 0,
		effectType = 0,
	},
}

local allDistortions = {
	unitEventDistortions = unitEventDistortions,
	unitDefDistortions = unitDefDistortions,
	featureDefDistortions = featureDefDistortions,
}

----------------- Debugging code to do the reverse dump ---------------
--[[
local distortionParamKeyOrder = {	posx = 1, posy = 2, posz = 3, radius = 4,
	r = 9, g = 10, b = 11, a = 12,
	color2r = 5, color2g = 6, color2b = 7, colortime = 8, -- point distortions only, colortime in seconds for unit-attached
	dirx = 5, diry = 6, dirz = 7, theta = 8,  -- cone distortions only, specify direction and half-angle in radians
	pos2x = 5, pos2y = 6, pos2z = 7, -- beam distortions only, specifies the endpoint of the beam
	modelfactor = 13, specular = 14, scattering = 15, lensflare = 16,
	lifeTime = 18, sustain = 19, effectType = 20
}

for typename, typetable in pairs(allDistortions) do
	Spring.Echo(typename)
	for distortionunitclass, classinfo in pairs(typetable) do
		if type(distortionunitclass) == type(1) then
			Spring.Echo(UnitDefs[distortionunitclass].name)
		else
			Spring.Echo(distortionunitclass)
		end
		for distortionname, distortioninfo in pairs(classinfo) do
			Spring.Echo(distortionname)
			local distortionParamTable = distortioninfo.distortionParamTable
			Spring.Echo(string.format("			distortionConfig = { posx = %f, posy = %f, posz = %f, radius = %f,", distortioninfo.distortionParamTable[1], distortionParamTable[2],distortionParamTable[3],distortionParamTable[4] ))
			if distortioninfo.distortionType == 'point' then
				Spring.Echo(string.format("				color2r = %f, color2g = %f, color2b = %f, colortime = %f,", distortioninfo.distortionParamTable[5], distortionParamTable[6],distortionParamTable[7],distortionParamTable[8] ))

			elseif distortioninfo.distortionType == 'beam' then
				Spring.Echo(string.format("				pos2x = %f, pos2y = %f, pos2z = %f,", distortioninfo.distortionParamTable[5], distortionParamTable[6],distortionParamTable[7]))
			elseif distortioninfo.distortionType == 'cone' then
				Spring.Echo(string.format("				dirx = %f, diry = %f, dirz = %f, theta = %f,", distortioninfo.distortionParamTable[5], distortionParamTable[6],distortionParamTable[7],distortionParamTable[8] ))

			end
			Spring.Echo(string.format("				r = %f, g = %f, b = %f, a = %f,", distortioninfo.distortionParamTable[9], distortionParamTable[10],distortionParamTable[11],distortionParamTable[12] ))
			Spring.Echo(string.format("				modelfactor = %f, specular = %f, scattering = %f, lensflare = %f,", distortioninfo.distortionParamTable[13], distortionParamTable[14],distortionParamTable[15],distortionParamTable[16] ))
			Spring.Echo(string.format("				lifeTime = %f, sustain = %f, effectType = %f},", distortioninfo.distortionParamTable[18], distortionParamTable[19],distortionParamTable[20]))

		end
	end
end
]]
--

-- Icexuick Check-list

return allDistortions
