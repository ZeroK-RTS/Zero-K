-- $Id$
function gadget:GetInfo()
  return {
    name      = "Awards",
    desc      = "Awards players at end of battle with shiny trophies.",
    author    = "CarRepairer",
    date      = "2008-10-15",
    license   = "GNU GPL, v2 or later",
    layer     = 1000000, -- Must be after all other build steps
    enabled   = true -- loaded by default?
  }
end

local TESTMODE = false

local spGetAllyTeamList		= Spring.GetAllyTeamList
local spIsGameOver			= Spring.IsGameOver

local gaiaTeamID			= Spring.GetGaiaTeamID()

local echo = Spring.Echo

local totalTeams = 0
local totalTeamList = {}

-------------------------------------------------------------------------------------
-------------------------------------------------------------------------------------
if (gadgetHandler:IsSyncedCode()) then 
-------------------------------------------------------------------------------------
-------------------------------------------------------------------------------------
local spAreTeamsAllied		= Spring.AreTeamsAllied
local spGetGameSeconds 		= Spring.GetGameSeconds
local spGetTeamStatsHistory	= Spring.GetTeamStatsHistory
local spGetUnitHealth		= Spring.GetUnitHealth
local spGetAllUnits			= Spring.GetAllUnits
local spGetUnitTeam			= Spring.GetUnitTeam
local spGetUnitDefID		= Spring.GetUnitDefID
local spGetUnitExperience	= Spring.GetUnitExperience
local spGetTeamResources    = Spring.GetTeamResources

local floor = math.floor

local terraunitDefID = UnitDefNames["terraunit"].id
local terraformCost = UnitDefNames["terraunit"].metalCost

local mexDefID = UnitDefNames["cormex"].id
local mexCost = UnitDefNames["cormex"].metalCost

local airDamageList		= {}
local friendlyDamageList= {}
local damageList 		= {}
local empDamageList		= {}
local fireDamageList	= {}
local navyDamageList	= {}
local nuxDamageList		= {}
local defDamageList		= {}
local t3DamageList		= {}
local captureList		= {}
local reclaimList		= {}
local reclaimListByFeature = {}
local resurrectList		= {}
local terraformList		= {}
local ouchDamageList	= {}
local kamDamageList		= {}
local commDamageList	= {}
local mexList			= {}
local energyList		= {}	--unused
local shareList			= {}
local shareListTemp1	= {}
local shareListTemp2	= {}

local expUnitTeam, expUnitDefID, expUnitExp = 0,0,0


local awardList = {}
local sentAwards = false
local teamCount = 0

local five_minute_frames = 32*60*5
local shareList_update = five_minute_frames
--shareList_update = 32*20


local boats, t3Units, comms = {}, {}, {}

local nukes = {	armsilo=1, 	corsilo=1,
				armshock=1,	cortron=1,
				armcybr=1,	
			}
local staticO_small = {
				armemp=1, cortron=1,
				armbrtha=1, corint=1,
			}
			
local staticO_big = {
				armsilo=1,	corsilo=1,
				mahlazer=1, corbeac=1,
}

local kamikaze = {
				corroach=1, corsktl=1, blastwing=1, puppy=1,
}
			
local flamerWeaponDefs = {}

function comma_value(amount)
	local formatted = amount .. ''
	local k
	while true do  
		formatted, k = formatted:gsub("^(-?%d+)(%d%d%d)", '%1,%2')
		if (k==0) then
			break
		end
	end
  	return formatted
end

function getMeanDamageExcept(excludeTeam)
	local mean = 0
	local count = 0
	for team,dmg in pairs(damageList) do
		if team ~= excludeTeam 
			and dmg > 100
		then
			mean = mean + dmg
			count = count + 1
		end
	end
	return (count>0) and (mean/count) or 0
end

function getMaxVal(valList)
	local winTeam, maxVal = false,0
	for team,val in pairs(valList) do
		if val and val > maxVal then
			winTeam = team
			maxVal = val
		end
	end
	return winTeam, floor(maxVal)
end

function getMeanMetalIncome()
	local num, sum = 0, 0
	for _,team in pairs(totalTeamList) do
		sum = sum + select(2, Spring.GetTeamResourceStats(team, "metal"))
		num = num + 1
	end
	return (sum/num)
end

function awardAward(team, awardType, record)
	awardList[team][awardType] = record
	
	if TESTMODE then
		for _,curTeam in pairs(totalTeamList) do
			if curTeam ~= team then	
				awardList[curTeam][awardType] = nil
			end
		end
	end
end


local function CopyTable(original)   -- Warning: circular table references lead to
	local copy = {}               -- an infinite loop.
	for k, v in pairs(original) do
		if (type(v) == "table") then
			copy[k] = CopyTable(v)
		else
			copy[k] = v
		end
	end
	return copy
end

local function UpdateShareList()
	shareList = CopyTable(shareListTemp2)
	shareListTemp2 = CopyTable(shareListTemp1)
end

-------------------
-- Resource tracking

local HIDDEN_STORAGE = 10000

local allyTeamInfo = {} 
local resourceInfo = {count = 0, data = {}}

do
	local allyTeamList = Spring.GetAllyTeamList()
	for i=1,#allyTeamList do
		local allyTeamID = allyTeamList[i]
		allyTeamInfo[allyTeamID] = {
			team = {},
			teams = 0,
		}
		
		local teamList = Spring.GetTeamList(allyTeamID)
		for j=1,#teamList do
			local teamID = teamList[j]
			allyTeamInfo[allyTeamID].teams = allyTeamInfo[allyTeamID].teams + 1
			allyTeamInfo[allyTeamID].team[allyTeamInfo[allyTeamID].teams] = teamID
		end
	end
end

local function UpdateResourceStats(t)

	resourceInfo.count = resourceInfo.count + 1
	resourceInfo.data[resourceInfo.count] = {allyRes = {}, teamRes = {}, t = t}

	for allyTeamID, allyTeamData in pairs(allyTeamInfo) do 
		local teams = allyTeamData.teams
		local team = allyTeamData.team
		
		local allyOverdriveResources = GG.Overdrive_allyTeamResources[allyTeamID] or {}
		
		resourceInfo.data[resourceInfo.count].allyRes[allyTeamID] = {
			metal_income_total = 0,
			metal_income_base = allyOverdriveResources.baseMetal or 0,
			metal_income_overdrive = allyOverdriveResources.overdriveMetal or 0,
			metal_income_other = 0,
			
			metal_spend_total = 0,
			metal_spend_construction = 0,
			metal_spend_waste = 0,
			
			metal_storage_current = 0,
			metal_storage_free = 0,
			
			energy_income_total = allyOverdriveResources.baseEnergy or 0,
			
			energy_spend_total = 0,
			energy_spend_overdrive = allyOverdriveResources.overdriveEnergy or 0,
			energy_spend_construction = 0,
			energy_spend_other = 0,
			energy_spend_waste = allyOverdriveResources.wasteEnergy or 0,
			
			energy_storage_current = 0,
		}
		
		local aRes = resourceInfo.data[resourceInfo.count].allyRes[allyTeamID]
		
		for i = 1, teams do
			local teamID = team[i]
			local mCurr, mStor, mPull, mInco, mExpe, mShar, mSent, mReci = spGetTeamResources(teamID, "metal")
			aRes.metal_spend_construction = aRes.metal_spend_construction + mExpe
			aRes.metal_income_total = aRes.metal_income_total + mInco
			aRes.metal_spend_total = aRes.metal_spend_total + mExpe
			aRes.metal_storage_free = aRes.metal_storage_free + mStor - mCurr
			aRes.metal_storage_current = aRes.metal_storage_current + mCurr
			
			local eCurr, eStor, ePull, eInco, eExpe, eShar, eSent, eReci = spGetTeamResources(teamID, "energy")
			aRes.energy_spend_total = aRes.energy_spend_total + eExpe
			aRes.energy_storage_current = aRes.energy_storage_current + eCurr
			
			local teamOverdriveResources = GG.Overdrive_teamResources[teamID] or {}
			
			resourceInfo.data[resourceInfo.count].teamRes[teamID] = {
				metal_income_total = mInco + mReci,
				metal_income_base = teamOverdriveResources.baseMetal or 0,
				metal_income_overdrive = teamOverdriveResources.overdriveMetal or 0,
				metal_income_other = 0,
				
				metal_spend_total = mExpe + mSent,
				metal_spend_construction = mExpe,
				
				metal_share_net = mReci - mSent,
				
				metal_storage_current = mCurr,
				
				energy_income_total = eInco,
				
				energy_spend_total = eExpe,
				energy_spend_construction = mExpe,
				energy_spend_other = 0,
				
				energy_share_net = teamOverdriveResources.overdriveEnergyChange or 0,
				
				energy_storage_current = eCurr,
			}
			
			local tRes = resourceInfo.data[resourceInfo.count].teamRes[teamID]
			
			tRes.metal_income_other = tRes.metal_income_total - tRes.metal_income_base - tRes.metal_income_overdrive - mReci
			tRes.energy_spend_other = tRes.energy_spend_total - tRes.energy_spend_construction + math.min(0, tRes.energy_share_net) 
		end
		
		aRes.metal_income_other = aRes.metal_income_total - aRes.metal_income_base - aRes.metal_income_overdrive
		aRes.metal_spend_waste = math.min(aRes.metal_storage_free - aRes.metal_income_total - aRes.metal_spend_total,0)
		
		aRes.energy_spend_construction = aRes.metal_spend_construction
		aRes.energy_spend_other = aRes.energy_spend_total - (aRes.energy_spend_overdrive + aRes.energy_spend_construction + aRes.energy_spend_waste)		
	end
end

-------------------
-- Callins

function gadget:Initialize()
	
	_G.resourceInfo = resourceInfo
	
	local tempTeamList = Spring.GetTeamList()
	for _, team in ipairs(tempTeamList) do
		--Spring.Echo('team', team)
		if team ~= gaiaTeamID then
			totalTeams = totalTeams + 1
			totalTeamList[team] = team
		end
	end
		
	for _,team in pairs(totalTeamList) do
		airDamageList[team] 	= 0
		friendlyDamageList[team]= 0
		damageList[team] 		= 0
		empDamageList[team] 	= 0
		fireDamageList[team] 	= 0
		navyDamageList[team] 	= 0
		nuxDamageList[team] 	= 0
		defDamageList[team] 	= 0
		t3DamageList[team] 		= 0
		captureList[team]		= 0
		reclaimList[team]		= 0
		resurrectList[team]		= 0
		terraformList[team] 	= 0
		ouchDamageList[team]	= 0
		kamDamageList[team]		= 0
		commDamageList[team]	= 0
		mexList[team]			= 0
		shareList[team]			= 0
		shareListTemp1[team]	= 0
		shareListTemp2[team]	= 0
		
		awardList[team] = {}
		
		teamCount = teamCount + 1
	end

	local boatFacs = {'armsy', 'corsy', } --'armasy', 'corasy'}
	for _, boatFac in pairs(boatFacs) do
		local udBoatFac = UnitDefNames[boatFac]
		if udBoatFac then
			for _, boatDefID in pairs(udBoatFac.buildOptions) do
				boats[boatDefID] = true
			end
		end
	end
	--[[
	local t3Facs = {'armshltx', 'corgant', }
	for _, t3Fac in pairs(t3Facs) do
		local udT3Fac = UnitDefNames[t3Fac]
		for _, t3DefID in pairs(udT3Fac.buildOptions) do
			t3Units[t3DefID] = true
		end
	end
	--]]
	for i=1,#WeaponDefs do
		local wcp = WeaponDefs[i].customParams or {}
		if (wcp.setunitsonfire) then
			flamerWeaponDefs[i] = true
		end
	end

	for i=1,#UnitDefs do
		if(UnitDefs[i].customParams.level) then comms[i] = true
	end

 end
 
end

function gadget:UnitTaken(unitID, unitDefID, oldTeam, newTeam)
	-- Units given to neutral?
	if oldTeam == gaiaTeamID or newTeam == gaiaTeamID  then
		return
	end
	if not spAreTeamsAllied(oldTeam,newTeam) then
		if captureList[newTeam] then
			local ud = UnitDefs[unitDefID]
			local mCost = ud and ud.metalCost or 0
			captureList[newTeam] = captureList[newTeam] + mCost
		end
	else -- teams are allied
		if shareListTemp1[oldTeam] and shareListTemp1[newTeam] then
			local ud = UnitDefs[unitDefID]
			local mCost = ud and ud.metalCost or 0
			shareListTemp1[oldTeam] = shareListTemp1[oldTeam] + mCost
			shareListTemp1[newTeam] = shareListTemp1[newTeam] - mCost
		end
	end
end

function gadget:UnitDestroyed(unitID, unitDefID, unitTeam)
	local experience = spGetUnitExperience(unitID)
	if experience > expUnitExp then
		expUnitExp = experience
		expUnitTeam = unitTeam
		expUnitDefID = unitDefID
	end
end

function gadget:AllowUnitBuildStep(builderID, builderTeam, unitID, unitDefID, step) 
	if terraunitDefID == unitDefID then
		terraformList[builderTeam] = terraformList[builderTeam] + step*terraformCost
	end
	return true
end


function gadget:AllowFeatureBuildStep(builderID, builderTeam, featureID, featureDefID, part)
  reclaimListByFeature[featureID] = reclaimListByFeature[featureID] or { metal = FeatureDefs[featureDefID].metal }
  reclaimListByFeature[featureID][builderTeam] = (reclaimListByFeature[featureID][builderTeam] or 0) + part
  return true
end

local function AddFeatureReclaim(featureID)
  local featureData = reclaimListByFeature[featureID]
  local metal = featureData.metal
  featureData.metal = nil

  for team, part in pairs(featureData) do
    if (part < 0) then  --more metal was reclaimed from feature than spent on repairing it (during resurrecting)
      reclaimList[team] = reclaimList[team] - metal * part
    end
  end
end

local function FinalizeReclaimList()
  for featureID, _ in pairs(reclaimListByFeature) do
    AddFeatureReclaim(featureID)
  end
  reclaimListByFeature = {}
end

function gadget:FeatureDestroyed (featureID, allyTeam)
  if (reclaimListByFeature[featureID]) then
    AddFeatureReclaim(featureID)
    reclaimListByFeature[featureID] = nil
  end
end


function GG.Awards_UnitResurrected (unitDefID, teamID)
  local ud = UnitDefs[unitDefID]
  resurrectList[teamID] = resurrectList[teamID] + (ud and ud.metalCost or 0)
end


function gadget:UnitDamaged(unitID, unitDefID, unitTeam, fullDamage, paralyzer, weaponID,
		attackerID, attackerDefID, attackerTeam)
	
	if (not attackerTeam) 
		or (attackerTeam == unitTeam)
		or (attackerTeam == gaiaTeamID) 
		or (unitTeam == gaiaTeamID) 
		then return end
	
	local hp = spGetUnitHealth(unitID)
	local damage = (hp > 0) and fullDamage or fullDamage + hp
	
	if spAreTeamsAllied(attackerTeam, unitTeam) then
		if not paralyzer then
			friendlyDamageList[attackerTeam] = friendlyDamageList[attackerTeam] + damage
		end
	else
		if paralyzer then
			empDamageList[attackerTeam] = empDamageList[attackerTeam] + damage
		else
			damageList[attackerTeam] = damageList[attackerTeam] + damage
			ouchDamageList[unitTeam] = ouchDamageList[unitTeam] + damage
			local ad = UnitDefs[attackerDefID]
			
			if (flamerWeaponDefs[weaponID]) then				
				fireDamageList[attackerTeam] = fireDamageList[attackerTeam] + damage	
			end
			
			-- Static Weapons
			if (not ad.canMove) then
			
				-- bignukes, zenith, starlight
				if staticO_big[ad.name] then
					nuxDamageList[attackerTeam] = nuxDamageList[attackerTeam] + damage
					
				-- not lrpc, tacnuke, emp missile
				elseif not staticO_small[ad.name] then
					defDamageList[attackerTeam] = defDamageList[attackerTeam] + damage
					
				end
				
			elseif kamikaze[ad.name] then
				kamDamageList[attackerTeam] = kamDamageList[attackerTeam] + damage
			
			elseif ad.canFly then
				airDamageList[attackerTeam] = airDamageList[attackerTeam] + damage
				
			elseif boats[attackerDefID] then
				navyDamageList[attackerTeam] = navyDamageList[attackerTeam] + damage
			
			elseif t3Units[attackerDefID] then
				t3DamageList[attackerTeam] = t3DamageList[attackerTeam] + damage

			elseif comms[attackerDefID] then
				commDamageList[attackerTeam] = commDamageList[attackerTeam] + damage
				
			end	
		end
	end
end

function gadget:UnitFinished(unitID, unitDefID, teamID)
	if unitDefID == mexDefID then
		mexList[teamID] = mexList[teamID] + 1
	end
end

function gadget:GameFrame(n)

	if n%32 == 2 then 
        UpdateResourceStats((n-2)/32)
    end

	if n % shareList_update == 1 and not spIsGameOver() then
		UpdateShareList()
	end

	if TESTMODE then
		local frame32 = (n) % 32
		if (frame32 < 0.1) then
			sentAwards = false
		end
	
	else
		if not spIsGameOver() then return end
	end
	
	if not sentAwards then 
	
		for _, unitID in ipairs(spGetAllUnits()) do
			local teamID = spGetUnitTeam(unitID)
			local unitDefID = spGetUnitDefID(unitID)
			gadget:UnitDestroyed(unitID, unitDefID, teamID)
		end
	
		FinalizeReclaimList()
	
		local pwnTeam, 	maxDamage 		= getMaxVal(damageList)		
		local navyTeam, maxNavyDamage 	= getMaxVal(navyDamageList)
		local airTeam, 	maxAirDamage 	= getMaxVal(airDamageList)
		local nuxTeam, 	maxNuxDamage 	= getMaxVal(nuxDamageList)
		local shellTeam,maxStaticDamage = getMaxVal(defDamageList)
		local fireTeam, maxFireDamage 	= getMaxVal(fireDamageList)
		local empTeam, 	maxEmpDamage 	= getMaxVal(empDamageList)
		local t3Team, 	maxT3Damage 	= getMaxVal(t3DamageList)
		local kamTeam, 	maxKamDamage 	= getMaxVal(kamDamageList)
		local commTeam, maxCommDamage 	= getMaxVal(commDamageList)
		
		local reclaimTeam, 	maxReclaim 	= getMaxVal(reclaimList)
		local rezzTeam, maxRezz			= getMaxVal(resurrectList)
		local terraTeam, maxTerra		= getMaxVal(terraformList)
		
		local ouchTeam, maxOuchDamage 	= getMaxVal(ouchDamageList)
		
		local capTeam, 	maxCap	 		= getMaxVal(captureList)
		local shareTeam, maxShare 		= getMaxVal(shareList)

		local mexTeam, maxMex			= getMaxVal(mexList)
		
		local friendTeam
		local maxFriendlyDamageRatio = 0
		for team,dmg in pairs(friendlyDamageList) do
			
			local totalDamage = dmg+damageList[team]
			local damageRatio = totalDamage>0 and dmg/totalDamage or 0
			
			if  damageRatio > maxFriendlyDamageRatio then
				friendTeam = team
				maxFriendlyDamageRatio = damageRatio
			end
		end
	
		
		--test values
		if TESTMODE then
			local testteam = 0
			--expUnitTeam, expUnitExp			= testteam+0	,113.59444
			--expUnitDefID = 2
			--shareTeam, 	maxShare 			= testteam+0	,5144
			--[[				
			pwnTeam, 	maxDamage 			= testteam+0	,1
			navyTeam, 	maxNavyDamage 		= testteam+1	,1
			t3Team, 	maxT3Damage 		= testteam+1	,1
			capTeam, 	maxCap	 			= testteam+0	,2

			expUnitTeam, expUnitExp			= testteam+0	,2.4444
				expUnitDefID = 35
	
			airTeam, 	maxAirDamage 		= testteam+2	,2
			nuxTeam, 	maxNuxDamage 		= testteam+0	,333333333

			shellTeam, 	maxStaticDamage 	= testteam+0	,1
			mTeam,  mMax 					= testteam+0	,1
			eTeam, eMax						= testteam+0	,11111111
			friendTeam, maxFriendlyDamageRatio = testteam+0	,0.5
			fireTeam, maxFireDamage			= testteam+0	,1
			empTeam, maxEmpDamage			= testteam+0	,1
		
			pwnTeam, 	maxDamage 			= testteam	,1
			navyTeam, 	maxNavyDamage 	= testteam	,1
			airTeam, 	maxAirDamage 		= testteam	,1
			nuxTeam, 	maxNuxDamage 		= testteam	,1
			shellTeam, 	maxStaticDamage = testteam	,1
			friendTeam, maxFriendlyDamageRatio = testteam,1
			fireTeam, maxFireDamage		= testteam	,1
			empTeam, maxEmpDamage			= testteam	,1
		--]]	
		end
	
		local easyFactor = 0.5
		local veryEasyFactor = 0.3
		local minFriendRatio = 0.25
		local minReclaimRatio = 0.15
		
		if pwnTeam then
			awardAward(pwnTeam, 'pwn', 'Damage: '.. comma_value(maxDamage))
		end
		if navyTeam and maxNavyDamage > getMeanDamageExcept(navyTeam) then
			awardAward(navyTeam, 'navy', 'Damage: '.. comma_value(maxNavyDamage))
		end
		if airTeam and maxAirDamage > getMeanDamageExcept(airTeam) then
			awardAward(airTeam, 'air', 'Damage: '.. comma_value(maxAirDamage))
		end
		if t3Team and maxT3Damage > getMeanDamageExcept(t3Team) then
			awardAward(t3Team, 't3', 'Damage: '.. comma_value(maxT3Damage))
		end
		if nuxTeam and maxNuxDamage > getMeanDamageExcept(nuxTeam) * veryEasyFactor then
			awardAward(nuxTeam, 'nux', 'Damage: '.. comma_value(maxNuxDamage))
		end
		if shellTeam and maxStaticDamage > getMeanDamageExcept(shellTeam) * easyFactor then
			awardAward(shellTeam, 'shell', 'Damage: '.. comma_value(maxStaticDamage))
		end
		if kamTeam and maxKamDamage > getMeanDamageExcept(kamTeam) * veryEasyFactor then
			awardAward(kamTeam, 'kam', 'Damage: '.. comma_value(maxKamDamage))
		end
		if commTeam and maxCommDamage > getMeanDamageExcept(commTeam) * veryEasyFactor then
			awardAward(commTeam, 'comm', 'Damage: '.. comma_value(maxCommDamage))
		end
		if fireTeam and maxFireDamage > getMeanDamageExcept(fireTeam) * easyFactor then
			awardAward(fireTeam, 'fire', 'Damage: '.. comma_value(maxFireDamage))
		end
		if empTeam and maxEmpDamage/4 > getMeanDamageExcept(empTeam) * easyFactor then
			awardAward(empTeam, 'emp', 'Damage: '.. comma_value(maxEmpDamage))
		end
		if capTeam and maxCap > 1000 then
			awardAward(capTeam, 'cap', 'Captured value: '.. comma_value(maxCap))
		end
		
		if shareTeam and maxShare > 5000 then
			awardAward(shareTeam, 'share', 'Shared value: '.. comma_value(maxShare))
		end
		
		if terraTeam and maxTerra > 250 then
			awardAward(terraTeam, 'terra', 'Terraform: '.. comma_value(maxTerra) .. " spent")
		end

		if rezzTeam and maxRezz >= 1000 then
			awardAward(rezzTeam, 'rezz', 'Resurrected value: '.. comma_value(maxRezz))
		end

		--Spring.Echo(maxReclaim, getMeanMetalIncome())
		if reclaimTeam and maxReclaim > getMeanMetalIncome() * minReclaimRatio then
			awardAward(reclaimTeam , 'reclaim', comma_value(maxReclaim) .. "m from wreckage")
		end
		if friendTeam and maxFriendlyDamageRatio > minFriendRatio then
			awardAward(friendTeam, 'friend', 'Damage inflicted on allies: '.. floor(maxFriendlyDamageRatio * 100) ..'%')
		end
		if ouchTeam then
			awardAward(ouchTeam, 'ouch', 'Damage: '.. comma_value(maxOuchDamage))
		end
		if mexTeam and maxMex > 15 then
			awardAward(mexTeam, 'mex', 'Mexes: '.. maxMex .. ' built')
		end
		if expUnitExp >= 3.0 then
			local vetName = UnitDefs[expUnitDefID] and UnitDefs[expUnitDefID].humanName
			--local expUnitExpRounded = ''..floor(expUnitExp * 10)/10
			local expUnitExpRounded = ''..floor(expUnitExp * 10)
			expUnitExpRounded = expUnitExpRounded:sub(1,-2) .. '.' .. expUnitExpRounded:sub(-1) 
			awardAward(expUnitTeam, 'vet', vetName ..', '.. expUnitExpRounded ..' XP')
		end

		_G.awardList = awardList
		sentAwards = true
	end
end


function gadget:GameOver()
	SendToUnsynced("aw_GameOver")
end

-------------------------------------------------------------------------------------
-------------------------------------------------------------------------------------
else  -- UNSYNCED
-------------------------------------------------------------------------------------
-------------------------------------------------------------------------------------


local spGetGameFrame 	= Spring.GetGameFrame
local spGetMouseState 	= Spring.GetMouseState
local spSendCommands	= Spring.SendCommands


local glPushMatrix		= gl.PushMatrix
local glPopMatrix		= gl.PopMatrix
local glTexture			= gl.Texture
local glTexRect			= gl.TexRect
local glAlphaTest		= gl.AlphaTest
local glTranslate		= gl.Translate
local glColor			= gl.Color
local glBeginEnd		= gl.BeginEnd
local glVertex			= gl.Vertex
local glScale			= gl.Scale
local GL_QUADS     		= GL.QUADS
--local GL_GREATER		= GL.GREATER

LUAUI_DIRNAME = 'LuaUI/'
local fontHandler   = loadstring(VFS.LoadFile(LUAUI_DIRNAME.."modfonts.lua", VFS.ZIP_FIRST))()
local fancyFont		= LUAUI_DIRNAME.."Fonts/KOMTXT___16"
local smallFont		= LUAUI_DIRNAME.."Fonts/FreeSansBold_16"

local fhDraw    		= fontHandler.Draw
local fhDrawCentered	= fontHandler.DrawCentered

local caught, windowCaught, buttonHover
local gameOver = false
local showGameOverWin 	= true
local sentToPlanetWars	= false

local colSpacing		= 250
local bx, by 			= 100,100
local margin 			= 10
local tWidth,tHeight	= 30,40
local w, h 				= (colSpacing+margin)*3, 500
local exitX1,exitY1,exitX2,exitY2 = w-260, h-40, w-10, h-10

local teamNames		= {}
local teamColors	= {}
local teamColorsDim	= {}
local awardList

local maxRow 		= 8
local fontHeight 	= 16


local awardDescs = 
{
	pwn 	= 'Complete Annihilation Award', 
	navy 	= 'Fleet Admiral', 
	air 	= 'Airforce General', 
	nux 	= 'Apocalyptic Achievement Award', 
	friend 	= 'Friendly Fire Award', 
	shell 	= 'Turtle Shell Award', 
	fire 	= 'Master Grill-Chef',
	emp 	= 'EMP Wizard',
	t3 		= 'Experimental Engineer',
	cap 	= 'Capture Award',
	share 	= 'Share Bear',
	terra	= 'Legendary Landscaper',
	reclaim = 'Spoils of War',
	rezz	= 'Necromancy Award',
	vet 	= 'Decorated Veteran',
	ouch 	= 'Big Purple Heart',
	kam		= 'Kamikaze Award',
	comm	= 'Master and Commander',
	mex		= 'Mineral Prospector',
}

function gadget:Initialize()
	local tempTeamList = Spring.GetTeamList()
	for _, team in ipairs(tempTeamList) do
		--Spring.Echo('team', team)
		if team ~= gaiaTeamID then
			totalTeams = totalTeams + 1
			totalTeamList[team] = team
		end
	end
	
	for _,team in pairs(totalTeamList) do
		local _, leaderPlayerID = Spring.GetTeamInfo(team)
		teamNames[team] = Spring.GetPlayerInfo(leaderPlayerID)
		teamColors[team]  = {Spring.GetTeamColor(team)}
		teamColorsDim[team]  = {teamColors[team][1], teamColors[team][2], teamColors[team][3], 0.5}
	end
	spSendCommands({'endgraph 0'})


	gadgetHandler:AddSyncAction("aw_GameOver", gadget.GameOver)
	if TESTMODE then
		gadget:GameOver()
	end
end

function gadget:GameOver()
	gameOver = true
	--Spring.Echo("Game over (unsynced)")
	-- reassign colors in case they have been changed locally
	for _,team in pairs(totalTeamList) do
		teamColors[team]  = {Spring.GetTeamColor(team)}
		teamColorsDim[team]  = {teamColors[team][1], teamColors[team][2], teamColors[team][3], 0.5}
	end

	--// Resources
	local resourceInfo = SYNCED.resourceInfo
	local data = resourceInfo.data
	
	local allyTeamList = Spring.GetAllyTeamList()
	for i=1,#allyTeamList do
		local allyTeamID = allyTeamList[i]
		local teamList = Spring.GetTeamList(allyTeamID)
		local toSend = allyTeamID
		for j=1,#teamList do
			local teamID = teamList[j]
			toSend = toSend .. " " .. teamID .. " " .. (teamNames[teamID] or "no_name")
		end
		--Spring.SendCommands("wbynum 255 SPRINGIE: allyTeamPlayerMap " .. toSend)
		--Spring.Echo(toSend)
	end
	
	for i = 1, resourceInfo.count do
		if data[i] then
			local toSend = data[i].t .. " "
			for allyTeamID, allyData in spairs(data[i].allyRes) do 
				toSend = toSend .. " " .. allyTeamID .. " " ..
				allyData.metal_income_total .. " " ..
				allyData.metal_income_base .. " " ..
				allyData.metal_income_overdrive .. " " ..
				allyData.metal_income_other .. " " ..
		
				allyData.metal_spend_total .. " " ..
				allyData.metal_spend_construction .. " " ..
				allyData.metal_spend_waste .. " " ..
				
				allyData.metal_storage_current .. " " ..
				allyData.metal_storage_free .. " " ..
				
				allyData.energy_income_total .. " " ..
				
				allyData.energy_spend_total .. " " ..
				allyData.energy_spend_overdrive .. " " ..
				allyData.energy_spend_construction .. " " ..
				allyData.energy_spend_other .. " " ..
				allyData.energy_spend_waste .. " " ..
				
				allyData.energy_storage_current
			end
			--Spring.SendCommands("wbynum 255 SPRINGIE: allyResourceData " .. toSend)
			--Spring.Echo(toSend)
			
			toSend = data[i].t .. " "
			
			for teamID, teamData in spairs(data[i].teamRes) do 
				toSend = toSend .. " " .. teamID .. " " ..
				teamData.metal_income_total .. " " ..
				teamData.metal_income_base .. " " ..
				teamData.metal_income_overdrive .. " " ..
				teamData.metal_income_other .. " " ..
		
				teamData.metal_spend_total .. " " ..
				teamData.metal_spend_construction .. " " ..
				
				teamData.metal_share_net  .. " " ..
				
				teamData.metal_storage_current .. " " ..
				
				teamData.energy_income_total .. " " ..
				
				teamData.energy_spend_total .. " " ..
				teamData.energy_spend_construction .. " " ..
				teamData.energy_spend_other .. " " ..
				
				teamData.energy_share_net  .. " " ..
				
				teamData.energy_storage_current
			end
			--Spring.SendCommands("wbynum 255 SPRINGIE: teamResourceData " .. toSend)
			--Spring.Echo(toSend)
		end
	end
	
	--[[
	gadget.IsAbove = gadget.IsAbove_
	gadget.MouseMove = gadget.MouseMove_
	gadget.MousePress = gadget.MousePress_
	gadget.MouseRelease = gadget.MouseRelease_
	gadget.DrawScreen = gadget.DrawScreen_


	function UC(name)
		--// bug in gadgetHandler workaround
		gadgetHandler:UpdateCallIn(name)
		gadgetHandler:UpdateCallIn(name)
        end

	UC("IsAbove")
	UC("MouseMove")
	UC("MousePress")
	UC("MouseRelease")
	UC("DrawScreen")
	]]--
end


function gadget:IsAboveCloseButton(x,y)
	return (x > bx+exitX1) and (x < bx+exitX2) and (y > by+exitY1) and (y < by+exitY2) 
end


function gadget:IsAbove(x,y)
	if not gameOver then return false end
	local above = (x > bx) and (x < bx+w) and (y > by) and (y < by+h) 

	if (above)and(self:IsAboveCloseButton(x,y)) then
		buttonHover = true
	else
		buttonHover = false
	end

	return above
end


function gadget:MousePress(x,y,button)
  if (button==1) then
	--Spring.Echo(self:IsAbove(x,y))
    if (self:IsAbove(x,y)) then
	  --Spring.Echo(self:IsAboveCloseButton(x,y))
      if (self:IsAboveCloseButton(x,y)) then
        --// close button clicked
        if showGameOverWin then
          spSendCommands('endgraph 1')
        else
          spSendCommands('endgraph 0')
        end
        showGameOverWin = not showGameOverWin
        return true
      end
      windowCaught = true
      cx = x-bx
      cy = y-by
      caught = true
      return true
    end
  end
  return false
end


function gadget:MouseRelease(x,y,button)
	if (button==1) then
		if (windowCaught) then
			windowCaught = false
			return true
		else
			return false
		end
	end
	return false
end


function gadget:MouseMove(x,y,button)
	if (windowCaught) then
		bx = x-cx
		by = y-cy
		return true
	else
		return false
	end
end


function gadget:DrawScreen()
	if gameOver then
		if (not awardList) and SYNCED.awardList then
			awardList = SYNCED.awardList
		end
		--Spring.Echo("Drawing awards")
			
		fontHandler.UseFont(smallFont)
		glPushMatrix()
		-- Main Box
		glTranslate(bx,by, 0)
		glColor(0.2, 0.2, 0.2, 0.4)
		gl.Rect(0,0,w,h)
		
		-- Title
		glColor(1, 1, 0, 0.8)
		glPushMatrix()
		glTranslate(colSpacing,h-fontHeight*2,0)
		glScale(1.5, 1.5, 1.5)
		fhDraw('Awards', 0,0)
		glPopMatrix()
		
		-- Button
		if buttonHover then
			glColor(0.4, 0.4, 0.9, 0.85)
		else
			glColor(0.9, 0.9, 0.9, 0.85)
		end
		gl.Rect(exitX1,exitY1,exitX2,exitY2)
		fhDrawCentered('Show/Hide Stats Window', (exitX1 + exitX2)/2,(exitY1 + exitY2)/2 - fontHeight/2)
		
		glTranslate(margin, h - (tHeight + margin)*2, 0)
		local row, col = 0,0
		if awardList then
			
			local teamCount = 0
			
			for team,awards in spairs(awardList) do
			
				local awardCount = 0
				for awardType, record in spairs(awards) do
					awardCount = awardCount + 1
					if not sentToPlanetWars then
						local planetWarsData = (teamNames[team] or "no_name") ..' '.. awardType ..' '.. awardDescs[awardType] ..', '.. record
						Spring.SendCommands("wbynum 255 SPRINGIE:award,".. planetWarsData)
						Spring.Echo(planetWarsData)
					end
				end
			
				if awardCount > 0 then
					teamCount = teamCount + 1
					
					if row == maxRow-1 then
						row = 0
						col = col + 1
						glTranslate(margin+colSpacing, (tHeight+margin)*(maxRow-1) , 0)
					end
					
					glColor( teamColorsDim[team] )
					gl.Rect(0-margin/2, 0-margin/2, colSpacing-margin/2, tHeight+margin/2)
					
					glColor(1,1,1,1)	
					fhDraw((teamNames[team] or "no_name") , 0, fontHeight )
					
					row = row + 1
					glTranslate( 0, 0 - (tHeight+margin), 0)
					if row == maxRow then
						row = 0
						col = col + 1
						glTranslate(margin+colSpacing, (tHeight+margin)*maxRow , 0)
					end
					
					for awardType, record in spairs(awards) do
					
						glColor(teamColorsDim[team] )
						gl.Rect(0-margin/2, 0-margin/2, colSpacing-margin/2, tHeight+margin/2)
						glColor(1,1,1,1)	
						
						glPushMatrix()
							
							local border = 2
							glColor(0,0,0,1)
							gl.Rect(0-border, 0-border, tWidth+border, tHeight+border)
							glColor(1,1,1,1)	
							glTexture('LuaRules/Images/awards/trophy_'.. awardType ..'.png')
							glTexRect(0, 0, tWidth, tHeight )
							
							glTranslate(tWidth+margin,(fontHeight+margin),0)
							glColor(1,1,0,1)
							glPushMatrix()
								if awardDescs[awardType]:len() > 35 then
									glScale(0.6,1,1)
								elseif awardDescs[awardType]:len() > 20 then
									glScale(0.8,1,1)
								end
								--fhDraw(awardCount ..') '.. awardDescs[awardType], 0,0) 
								fhDraw(awardDescs[awardType], 0,0) 
							glPopMatrix()
							
							glTranslate(0,0-(fontHeight/2+margin),0)
							glColor(1,1,1,1)
							glPushMatrix()
								if record:len() > 35 then
									glScale(0.6,1,1)
								elseif record:len() > 20 then
									glScale(0.8,1,1)
								end
								
								fhDraw('  '..record, 0,0)
							glPopMatrix()
							
						glPopMatrix()
						
						row = row + 1
						glTranslate( 0, 0 - (tHeight+margin), 0)
						if row == maxRow then
							row = 0
							col = col + 1
							glTranslate(margin+colSpacing, (tHeight+margin)*maxRow , 0)
						end
					end
				end --if at least 1 award
			end
			
			sentToPlanetWars = true
		end
		glPopMatrix()
		glColor(0,0,0,0)
	end
end

function gadget:ViewResize(vsx, vsy)
	bx = vsx/2 - w/2
	by = vsy/2 - h/2
end

gadget:ViewResize(Spring.GetViewGeometry())

-------------------------------------------------------------------------------------
-------------------------------------------------------------------------------------
end
