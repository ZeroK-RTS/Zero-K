local CMD_PRIORITY		= 34220

-- The "brains" implement the high level reasoning of the AI.
-- Takes inputs such as economy status, own units by cost, enemy scouted units by cost.
-- Outputs factory and constructor job weights
function constructionAndEconomyHandler(a, at, frame)
	--Note: all "chance" variable have continous value from 0 to 1
	--all "importance" variable have continuous value from 0 to infinity
	--all "count" variable have integer value from 0 to infinity
	
	-- useful localisations
	local averagedEcon = a.averagedEcon
	local conJob = a.conJob
	local facJob = a.facJob
	local facJobAir = a.facJobAir
	local controlledUnit = a.controlledUnit
	
	a.unitHordingChance = 0.3 --value [0..1]
	a.nanoChance = 0.05 --chance of making a nano
	if averagedEcon.aveMInc < 50 then
		a.wantedNanoCount = math.floor(averagedEcon.aveMInc/20)
	elseif averagedEcon.aveMInc < 100 then
		a.wantedNanoCount = math.floor(averagedEcon.aveMInc/10)
	else
		a.wantedNanoCount = math.floor(averagedEcon.aveMInc/4)
	end
	
	-- example of setting default values
	conJob.defence.importance = 1.8 + at.relativeEnemyForceComposition.unit.raider
	conJob.defence.radarChance = 1
	conJob.defence.airChance = 0

	-- build airpads if the AI has too many bombers
	if controlledUnit.bomber.count*0.2 > controlledUnit.airpad.count then
		conJob.defence.airpadChance = 1
	else
		conJob.defence.airpadChance = 0
	end
	
	if averagedEcon.mStor/averagedEcon.aveMInc < 6 then
		conJob.defence.metalStorageChance = 1
	else
		conJob.defence.metalStorageChance = 0
	end
	
	-- defence handling
	if controlledUnit.turret.cost/controlledUnit.any.cost < 0.04 and averagedEcon.aveMInc > 7 then
		conJob.defence.importance = 3.5 + at.relativeEnemyForceComposition.unit.raider
		conJob.defence.radarChance = 0.2
	end
	
	if controlledUnit.mex.count < 3 then
		conJob.mex.importance = 8
	else
		if controlledUnit.turret.count < 2 then
			conJob.defence.importance = 12
			conJob.defence.radarChance = 0
		elseif controlledUnit.turret.count < 3 then
			conJob.defence.importance = 5
			conJob.defence.radarChance = 0
		end
	end
	
	-- controls AA chance
	if averagedEcon.aveMInc > 30 or at.enemyHasAir then
		conJob.defence.airChance = 0.2
	end
	if at.relativeEnemyForceComposition.unit.air > 1 and at.enemyHasAir then
		conJob.defence.airChance = 0.8
	end
	
	--** Corresponding number inputs for factory jobs
	-- 1 = con
	-- 2 = scout
	-- 3 = raider
	-- 4 = arty
	-- 5 = assault
	-- 6 = skirm
	-- 7 = riot
	-- 8 = AA
	
	--** Corresponding number inputs for airfactory jobs
	-- 1 = con
	-- 2 = scout
	-- 3 = fighterheavy
	-- 4 = bomber
	-- 5 = gunship
	
	facJob[2].importance = 3 + 6 * (at.unScoutedPoint.count/heatSquares) -- scouts are built depending on unscouted ground
	
	facJob[4].importance = 0
	if at.enemyDefence.totalCost > 4000 then
		facJob[4].importance = 8
	elseif at.enemyDefence.totalCost > 2000 then
		facJob[4].importance = 6
	elseif at.enemyDefence.totalCost > 1000 then
		facJob[4].importance = 3
	end

	if averagedEcon.aveMInc > 20 or at.enemyOffense.totalCost > 1000 then
		facJob[5].importance = 6 * at.relativeEnemyForceComposition.unit.groundDefence
		facJob[6].importance = (5/3) * (at.relativeEnemyForceComposition.unit.assault + 2*at.relativeEnemyForceComposition.unit.riot)
		facJob[7].importance = 5 * at.relativeEnemyForceComposition.unit.raider
	else
		facJob[5].importance = 0.6
		facJob[6].importance = 0.6
		facJob[7].importance = 0.6
	end
	
	if at.relativeEnemyForceComposition.unit.air > 1 then
		facJob[8].importance = 1.4
	else
		facJob[8].importance = 0.4
	end
	
	conJob.factory.airFactor = 0.3
	facJobAir[1].importance = 2.1
	facJobAir[2].importance = 2
	facJobAir[3].importance = 2
	facJobAir[4].importance = 2
	facJobAir[5].importance = 2
	
	conJob.mex.defenceChance = 0
	
	if at.units.mex.count/#GG.metalSpots > 0.5 then
		conJob.mex.defenceChance = 0.5
	elseif averagedEcon.aveMInc > 7 and averagedEcon.energyToMetalRatio < 1.2 then
		conJob.mex.defenceChance = 0.26
	end
	
	conJob.reclaim.importance = 0
	if at.units.mex.count*3 > #GG.metalSpots or frame > 14400 then
		conJob.reclaim.importance = 4
	end
	
	if at.enemyEconomy.totalCost > 300 then
		facJob[3].importance = 5
	else
		facJob[3].importance = 2
	end
	
	--conJob.mex.importance = conJob.mex.importance + 14*(1 - at.units.mex.count/#GG.metalSpots)
	conJob.energy.interruptable = false
	
	if averagedEcon.energyToMetalRatio > 1.9 then
		conJob.energy.interruptable = true
		conJob.energy.importance = 0.5
		conJob.mex.importance = 8
		if averagedEcon.mCur < 30 then
			for unitID,_ in pairs(controlledUnit.mexByID) do
				Spring.GiveOrderToUnit(unitID,CMD_PRIORITY,{2}, 0)
			end
		end
	elseif averagedEcon.energyToMetalRatio > 1.3 then
		conJob.energy.importance = 1
		conJob.mex.importance = 8
		if averagedEcon.mCur < 30 then
			for unitID,_ in pairs(controlledUnit.mexByID) do
				Spring.GiveOrderToUnit(unitID,CMD_PRIORITY,{2}, 0)
			end
		end
	elseif averagedEcon.energyToMetalRatio > 1.1 then
		conJob.energy.importance = 3
		conJob.mex.importance = 2.5
	elseif averagedEcon.energyToMetalRatio > 0.5 then
		conJob.energy.importance = 5
		conJob.mex.importance = 1.2
	else
		conJob.energy.importance = 6
		conJob.mex.importance = 0
	end
	
	conJob.factory.importance = 7
	
	if averagedEcon.activeBpToMetalRatio < 1.2 then
		facJob[1].importance = 3 + 4*(1 - at.units.mex.count/#GG.metalSpots)
		conJob.factory.importance = 6
	elseif averagedEcon.activeBpToMetalRatio < 2.3 then
		facJob[1].importance = 1 + (1 - at.units.mex.count/#GG.metalSpots)
		conJob.factory.importance = 6
	else
		facJob[1].importance = 0.15
	end
	
	if averagedEcon.aveMInc < 10 then
		facJob[1].importance = 4
	end
	
	if averagedEcon.mCur > 300 and averagedEcon.eCur > 250 then
		facJob[1].importance = 20
		conJob.defence.importance = 3
	end
	
	facJob[1].importance = facJob[1].importance + 5*(1 - at.units.mex.count/#GG.metalSpots)
		
	if controlledUnit.factory.count == 0 or (not controlledUnit.factoryByID[controlledUnit.factory[1]].finished) then
		conJob.factory.importance = 20
	end
	
	if averagedEcon.eCur < 30 and averagedEcon.energyToMetalRatio < 1.25 then
		conJob.defence.interruptable = true
		conJob.energy.importance = 18
		for unitID,_ in pairs(controlledUnit.econByID) do
			Spring.GiveOrderToUnit(unitID,CMD_PRIORITY,{2}, 0)
		end
	else
		conJob.defence.interruptable = false
	end
	
	if a.wantedDefence.count == 0 then
		conJob.defence.importance = 0
		conJob.mex.defenceChance = 0
	end
	
end
