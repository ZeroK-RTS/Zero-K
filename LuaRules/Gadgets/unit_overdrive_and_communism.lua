-- $Id: unit_mex_overdrive.lua 4550 2009-05-05 18:07:29Z licho $
-------------------------------------------------------------------------------------
-------------------------------------------------------------------------------------

function gadget:GetInfo()
  return {
    name      = "Overdrive&Communism",
    desc      = "Controls mex overload and pylon grid",
    author    = "jK (rewrote) (original idea by: Licho & Google Frog)",
    date      = "2008, 2009 & 2010",
    license   = "GNU GPL, v2 or later",
    layer     = 0,
    enabled   = false,
  }
end

-------------------------------------------------------------------------------------
-------------------------------------------------------------------------------------

local PYLON_RANGE = 500
local PYLON_LINK_RANGESQ   = (2*PYLON_RANGE)*(2*PYLON_RANGE) --// the circles just need to overlap/touch
local PYLON_ENERGY_RANGESQ = PYLON_RANGE*PYLON_RANGE
local PYLON_MEX_RANGESQ    = PYLON_RANGE*PYLON_RANGE
local PYLON_MEX_LIMIT       = 3

local UPDATE_RATE = 15 --// in GameFrames
local UPDATE_MULT = UPDATE_RATE / 30

-------------------------------------------------------------------------------------
-------------------------------------------------------------------------------------

local mexDefs = {}
local energyDefs = {}
local pylonDefs = {}

for i=1,#UnitDefs do
  local udef = UnitDefs[i]
  if (udef.extractsMetal > 0) then
    mexDefs[i] = true
  end
  if (udef.type == "Building") then
    if  (udef.energyMake > 0)
      or(udef.energyUpkeep < 0)
      or(udef.tidalGenerator > 0)
      or(udef.windGenerator > 0)
      or(udef.customParams.windgen)
    then
      energyDefs[i] = true
    end
    if (udef.customParams.ispylon) then
      pylonDefs[i] = (udef.customParams.isoverdrivepylon and 1) or 0
    end
  end
end


-------------------------------------------------------------------------------------
-------------------------------------------------------------------------------------

if (gadgetHandler:IsSyncedCode()) then

-------------------------------------------------------------------------------------
-------------------------------------------------------------------------------------

local gaiaTeamID = Spring.GetGaiaTeamID()
local activeTeams = {}

local grids = {}
local mexes = {} 
local pylons = {}
local energy = {}

local num_grids = 0

local unlinkedEnergy = {}
local unlinkedMexes = {}

local oldTeamExcess = {}
local oldTeamStatsFrame = {}
local energyExcessExtra = {}

-------------------------------------------------------------------------------------
-------------------------------------------------------------------------------------
-- Local Functions

local function MyIsTeamAlive(teamID)
	local isDead,isAI = select(3,Spring.GetTeamInfo(teamID))
	if (isDead) then return false end
	local activePlayers = Spring.GetPlayerList(teamID, true)
	return (#activePlayers>0)or(isAI)
end


local function MyGetMetalMake(mm,mu)
	local metalMake = (mm or 0) - (mu or 0)
	return metalMake
end


local function UpdateActiveTeams()
	local allyList = Spring.GetAllyTeamList()
	for i=1,#allyList do
		local allyID = allyList[i]
		local teamList = Spring.GetTeamList(allyID)
		local _activeTeams = {}
		activeTeams[allyID] = _activeTeams
		for j=1, #teamList do
			local teamID = teamList[j]
			if (MyIsTeamAlive(teamID)) then
				_activeTeams[#_activeTeams+1] = teamID
			end
		end
	end
end

-------------------------------------------------------------------------------------
-------------------------------------------------------------------------------------
-- ShareResources Functions

local function MyTeamShareResources(teamID, poorTeamID, type, shareAmount)
	SendToUnsynced("communism_share", teamID, poorTeamID, type, shareAmount)
end


local function SendDonations(donators, recvTeamID, type, aid)
	while (aid > 0) do
		local teamID, amount = next(donators)

		if (not teamID) then
			--// no donators left (shouldn't happen)
			break
		end

		if (amount > aid) then
			donators[teamID] = amount - aid
			amount = aid
			aid = 0
		else
			donators[teamID] = nil
			aid = aid - amount
		end
		MyTeamShareResources(teamID, recvTeamID, type, amount)
	end
end

-------------------------------------------------------------------------------------
-------------------------------------------------------------------------------------
-- Overdrive Functions

local UPDATE_MULT_SQ = UPDATE_MULT

local function energyToExtraM(energy)
	--return math.sqrt( 1 + (energy*0.2) ) - 1
	return math.sqrt( UPDATE_MULT_SQ + (energy*0.20) ) - UPDATE_MULT
end


local function MetalMultToEnergy(metalMult) --// Inverse of the above one
	return ((metalMult+1)^2 - 1) * 5 * UPDATE_MULT
end

-------------------------------------------------------------------------------------
-------------------------------------------------------------------------------------
-- Communism Functions

local function GetTeamEnergySupply(teamID)
	--// returns 2 arguments: first is the Energy supply (>0: spare Energy, <0: demand Energy), second is the weight of the demand (the higher the more important it is)

	local eCur, eMax, ePul, eInc, eExp, eShare, eSent, eRec = Spring.GetTeamResources(teamID, "energy")
	local odExp = Spring.GetTeamRulesParam(teamID,"OverdriveEnergyCurExpense") or 0
--[[
	ePul = ePul * UPDATE_MULT
	eInc = eInc * UPDATE_MULT
	eExp = eExp * UPDATE_MULT
--]]
	local eFreeStorage = eMax - eCur
	local eGain = eInc - (eExp - odExp)

	--// the Team can spare some Energy (for Overdrive and Communism)
	if (eCur + eGain > eMax) then
		return math.min(eMax, (eCur + eGain) - eMax) * UPDATE_MULT
	elseif (eCur + eGain > eMax * eShare) then
		return math.min(eMax, (eCur - (eMax * eShare)) * 0.7) * UPDATE_MULT
	end

	if (not MyIsTeamAlive(teamID)) then return 0, 0 end
	if (math.abs(eInc)>8)and(eFreeStorage < 100) then return 0, 0 end


	--// check if the Team needs badly Energy from the ally (Communism)
	local demand = 0
	local weight = 0

	if (eCur < 300) then
		local demand2 = 300 - eCur
		if (demand2 > demand) then
			demand = demand2
			weight = math.max(6,weight)
		end
	end
	if (eCur < eMax*0.5) then
		local demand2 = eMax*0.5 - eCur
		if (demand2 > demand) then
			demand = demand2
			weight = math.max(4,weight)
		end
	end
	if (eGain < eExp) then
		local demand2 = eExp - eGain
		if (demand2 > demand) then
			demand = demand2
			weight = math.max(2,weight)
		end
	end
	if (eGain < 1.5 * eExp) then
		local demand2 = 1.5 * eExp - eGain
		if (demand2 > demand) then
			demand = demand2
			weight = math.max(1,weight)
		end
	end

	return -demand * UPDATE_MULT,weight
end


local function DoCommunism(excess, demand, donators, aidTeams, aidWeights)
	--// Send the Energy Aid (Communism)
	local overdriveDonators = donators
	if (excess > 0 and demand > 0) then
		if (excess > demand) then
			--// we have more free Energy than it's needed,
			--// so we scale all donations to the needed value,
			--// this way all donators contribute
			--// (this is only important for the endgame graph)
			local scale = demand / excess
			local scaledDonaters = {}
			overdriveDonators = {}
			for teamID, amount in pairs(donators) do
				scaledDonaters[teamID] = amount * scale
				overdriveDonators[teamID] = amount * (1-scale)
			end
			donators = scaledDonaters
		end

		local aids = {}
		while (excess>0 and demand > 0) do
			local totalWeights = 0
			for _, weight in pairs(aidWeights) do
				totalWeights = totalWeights + weight
			end

			local stepE = 1e9
			for teamID, eMissing in pairs(aidTeams) do
				local step = eMissing * (totalWeights / aidWeights[teamID])
				if (step < stepE) then stepE = step end
			end

			if (stepE > excess) then
				stepE = excess
			end
			excess = excess - stepE
			demand = demand - stepE

			for teamID, weight in pairs(aidWeights) do
				local stepAid = stepE * (weight/totalWeights)
				aids[teamID] = (aids[teamID] or 0) + stepAid
				aidTeams[teamID] = aidTeams[teamID] - stepAid
				if (aidTeams[teamID] <= 0) then
					aidTeams[teamID] = nil
					aidWeights[teamID] = nil
				end
			end
		end

		for teamID, aid in pairs(aids) do
			SendDonations(donators, teamID, "energy", aid)
		end

		if (excess < 0) then
			excess = 0
		end
	end

	return excess, overdriveDonators
end

-------------------------------------------------------------------------------------
-------------------------------------------------------------------------------------
-- Classes

local CMex = {
	unitID = -1,
	teamID = -1,
	allyID = -1,
	active = true,
	x = -1,
	y = -1,
	z = -1,

	pylon = nil,

	calibrationTimer = 3, --// wait 3 seconds, before we know the correct metal extraction value
	origMetal = 0,
	overdriveMetal = 0,
	metalMult = 0,

	CreateFakeExtractor = nil,
	DestroyFakeExtractor = nil,
	ActivateFakeExtractor = nil,
	DeactivateFakeExtractor = nil,

	Activate = nil,
	Deactivate = nil,

	FindGrid = nil,

	Update = nil,
	UpdateTooltipAndAnimation = nil,
	UpdateOverdrive = nil,

	New = nil,
	Destroy = nil,
}

local CEnergy = {
	unitID = -1,
	allyID = -1,
	unitDefID = -1,
	active = true,
	x = -1,
	y = -1,
	z = -1,

	pylon  = nil,

	Update = nil,
	FindGrid = nil,

	Activate = nil,
	Deactivate = nil,

	New = nil,
	Destroy = nil,
}

local CPylon = {
	unitID = -1,
	allyID = -1,
	grid   = nil,
	conMexes = {},
	conPylons = {},
	conEnergy = {},
	overdrive = false, 
	active = true,
	x = -1,
	y = -1,
	z = -1,

	AddMex = nil,
	RemoveMex = nil,
	AddEnergy = nil,
	RemoveEnergy = nil,
	AddPylon = nil,
	RemovePylon = nil,

	CanLinkMex = nil,
	CanLinkEnergy = nil,
	CanLinkPylon = nil,

	FindMexes = nil,
	FindEnergy = nil,
	FindGrid = nil,
	GetNearbyPylons = nil,
	Update = nil,

	Activate = nil,
	Deactivate = nil,

	New = nil,
	Destroy = nil,
}

local CGrid = {
	gridID = -1,
	allyID = -1,
	conPylons = {},

	checkIntegrity = false,
	CheckIntegrity = nil,

	energy = 0,
	capacity = 0,

	AddPylon = nil,
	RemovePylon = nil,
	Update = nil,
	UpdateCapacity = nil,
	Merge = nil,
	CheckIntegrity = nil,
	New = nil,
	Destroy = nil,
}


-------------------------------------------------------------------------------------
-------------------------------------------------------------------------------------
-- The Constructors & Destructors

function CMex:New(unitID)
  local instance = {}
  for i,v in pairs(self) do
    if (type(v) == "table") then
      instance[i] = {}
    else
      instance[i] = v
    end
  end

  instance.unitID = unitID
  instance.teamID = Spring.GetUnitTeam(unitID)
  instance.allyID = Spring.GetUnitAllyTeam(unitID)
  instance.origMetal = MyGetMetalMake(Spring.GetUnitResources(unitID))
  instance.x,instance.y,instance.z = Spring.GetUnitBasePosition(unitID)
  instance.active = false --not Spring.GetUnitIsStunned(unitID)

  mexes[unitID] = instance

  instance:CreateFakeExtractor()

  --// metal extractors start always as deactivated, until we got a useful value of their M extraction
  instance:Deactivate()

  return instance
end


function CEnergy:New(unitID)
  local instance = {}
  for i,v in pairs(self) do
    if (type(v) == "table") then
      instance[i] = {}
    else
      instance[i] = v
    end
  end

  instance.unitID = unitID
  instance.unitDefID = Spring.GetUnitDefID(unitID)
  instance.allyID = Spring.GetUnitAllyTeam(unitID)
  instance.x,instance.y,instance.z = Spring.GetUnitBasePosition(unitID)
  instance.active = not Spring.GetUnitIsStunned(unitID)

  energy[unitID] = instance

  if (instance.active) then
    instance:Activate()
  else
    instance:Deactivate()
  end

  return instance
end


function CPylon:New(unitID)
  local instance = {}
  for i,v in pairs(self) do
    if (type(v) == "table") then
      instance[i] = {}
    else
      instance[i] = v
    end
  end

  instance.unitID = unitID
  instance.allyID = Spring.GetUnitAllyTeam(unitID)
  instance.overdrive = (pylonDefs[Spring.GetUnitDefID(unitID)]>=1)
  instance.x,instance.y,instance.z = Spring.GetUnitBasePosition(unitID)
  instance.active = not Spring.GetUnitIsStunned(unitID)

  pylons[unitID] = instance

  if (instance.active) then
    instance:FindGrid()
    instance:FindMexes()
    instance:FindEnergy()
  end

  return instance
end


function CGrid:New(allyID)
  local instance = {}
  for i,v in pairs(self) do
    if (type(v) == "table") then
      instance[i] = {}
    else
      instance[i] = v
    end
  end

  num_grids = num_grids + 1
  instance.gridID = num_grids
  instance.allyID = allyID
  grids[instance.gridID] = instance

  return instance
end


function CMex:Destroy()
  self:Deactivate()
  self:DestroyFakeExtractor()
  mexes[self.unitID] = nil
  unlinkedMexes[self.unitID] = nil
end


function CEnergy:Destroy()
  self:Deactivate()
  energy[self.unitID] = nil
  unlinkedEnergy[self.unitID] = nil
end


function CPylon:Destroy()
  self:Deactivate()
  pylons[self.unitID] = nil
end


function CGrid:Destroy()
  grids[self.gridID] = nil
end

-------------------------------------------------------------------------------------
-------------------------------------------------------------------------------------
-- CMex Methods

function CMex:CreateFakeExtractor()
	local udefid = Spring.GetUnitDefID(self.unitID)
	local udef = UnitDefs[udefid]

	Spring.SetUnitMetalExtraction(self.unitID, 0)

	local uid = Spring.CreateUnit(udefid, self.x,self.y,self.z, 0, Spring.GetGaiaTeamID(), false)

	Spring.MoveCtrl.Enable(uid)
	Spring.MoveCtrl.SetExtrapolate(uid,false)
	Spring.MoveCtrl.SetNoBlocking(uid,true)

	Spring.SetUnitNeutral(uid,true)
	Spring.SetUnitBlocking(uid,false,false)

	Spring.MoveCtrl.SetPosition(uid,self.x,self.y+20000,self.z)

	Spring.SetUnitCollisionVolumeData(uid, 0,0,0, 0,0,0, -1,0,0)
	for i=0,#Spring.GetAllyTeamList()-1 do
		Spring.SetUnitLosState(uid,i,0)
		Spring.SetUnitLosMask(uid,i,15)
	end

	-- hide unit
	Spring.SetUnitCloak(uid, 4)
	Spring.SetUnitStealth(uid, true)
	Spring.SetUnitNoDraw(uid, true)
	Spring.SetUnitNoSelect(uid, true)
	Spring.SetUnitNoMinimap(uid, true)

	Spring.SetUnitMetalExtraction(uid, 0)
	self.extractorID = uid
end


function CMex:DestroyFakeExtractor()
	Spring.DestroyUnit(self.extractorID,false,true)
	self.extractorID = nil
end


function CMex:ActivateFakeExtractor()
	local udefid = Spring.GetUnitDefID(self.unitID)
	local udef = UnitDefs[udefid]
	Spring.SetUnitMetalExtraction(self.extractorID, udef.extractsMetal)
	Spring.SetUnitMetalExtraction(self.unitID, 0)
	self.calibrationTimer = 3
end


function CMex:DeactivateFakeExtractor()
	Spring.SetUnitMetalExtraction(self.extractorID, 0)
	Spring.SetUnitMetalExtraction(self.unitID, 0)
end


function CMex:Activate()
	self.active = true
	self:ActivateFakeExtractor()
end


function CMex:Deactivate()
	self.active = false
	if (self.pylon) then
		self.pylon:RemoveMex(self)
	end
	self:DeactivateFakeExtractor()
end


function CMex:UpdateTooltipAndAnimation()
	local totalMult = UPDATE_MULT
	local tooltip = "Metal Extractor - (Not connected to Grid)"
	if (self.pylon) then
		tooltip = ("Metal Extractor - Overdrive: %.0f%%"):format(self.metalMult * 100 / UPDATE_MULT)
		totalMult = UPDATE_MULT + self.metalMult
	end

	--// Tooltip & luaUI
	Spring.SetUnitTooltip(self.unitID, tooltip)
	Spring.SetUnitRulesParam(self.unitID, "overdrive", totalMult/UPDATE_MULT)

	--// Anim
	local totalMetal = totalMult * self.origMetal / UPDATE_MULT
	if (totalMetal ~= self._oldTotalMetal)or((self._lastAnimUpdate or 0)+300 < Spring.GetGameFrame()) then
		self._oldTotalMetal = totalMetal / UPDATE_MULT
		self._lastAnimUpdate = Spring.GetGameFrame()
		Spring.CallCOBScript(self.unitID, "SetSpeed", 0, totalMetal * 500)
	end
end


function CMex:UpdateOverdrive(energy)
	local metalMult = energyToExtraM(energy)

	self.metalMult = metalMult
	self.overdriveMetal = metalMult * self.origMetal * UPDATE_MULT
	self:UpdateTooltipAndAnimation()

	local _activeTeams = activeTeams[self.allyID]
	local metalPerTeam = self.overdriveMetal / #_activeTeams
	Spring.AddUnitResource(self.unitID, "m", metalPerTeam)
	--FIXME Spring.UseUnitResource(self.unitID, "e", energy)
	metalPerTeam = metalPerTeam + self.origMetal / #_activeTeams --// share also the non-overdrive metal of the mex!
	for i=1,#_activeTeams do
		local teamID = _activeTeams[i]
		if (teamID ~= self.teamID) then
			Spring.AddTeamResource(teamID, "m", metalPerTeam)
		end
	end
end


function CMex:FindGrid()
	if (self.pylon) then
		return
	end

	unlinkedMexes[self.unitID] = self
	for _,pylon in pairs(pylons) do
		if (pylon:CanLinkMex(self.unitID,true)) then
			pylon.grid:RequestOptimization()
			return
		end
	end

	--// if no grid found, reset tooltip to default
	self:UpdateTooltipAndAnimation()
end


function CMex:Update()
	local stunned_or_inbuild = Spring.GetUnitIsStunned(self.unitID)
	local currentlyActive = not stunned_or_inbuild

	if (currentlyActive ~= self.active) then
		if (currentlyActive) then
			self:Activate()
		else
			self:Deactivate()
		end
	end

	local curMetalMake = MyGetMetalMake(Spring.GetUnitResources(self.extractorID))
	if (self.origMetal ~= curMetalMake) then
		--// Update Non-Overdrive Metal Extraction Rate
		local oldRate  = self.origMetal
		self.origMetal = MyGetMetalMake(Spring.GetUnitResources(self.extractorID))
		Spring.SetUnitResourcing(self.unitID, "cmm", self.origMetal*2) --//FIXME the *2 is a bug in the engine!
		if (self.calibrationTimer < 0)and(self.active) then
			if (self.pylon) then
				--// just inform the grid, if the metal extraction decreased
				--// (we are already linked so informing the grid about efficy increases isn't needed)
				if (oldRate > curMetalMake) then
					self.pylon.grid:RequestOptimization()
				end
			else
				--// inform grids, perhaps the mex is now worth to be linked?
				self:FindGrid()
			end
		end
	end

--// FIXME set self.active AFTER calibration time!
	if (self.calibrationTimer >= 0)and(self.active) then
		--// just link the mex after we know its real metal output,
		--// this way the pylons can decide which mexes give the best OD performance
		self.calibrationTimer = self.calibrationTimer - 1 * UPDATE_MULT
		if (self.calibrationTimer >= 0) then
			return
		end
		self:FindGrid()
	end
end

-------------------------------------------------------------------------------------
-------------------------------------------------------------------------------------
-- CEnergy Methods

function CEnergy:Activate()
	self.active = true
	self:FindGrid()
end


function CEnergy:Deactivate()
	self.active = false
	if (self.pylon) then
		self.pylon:RemoveEnergy(self)
		unlinkedEnergy[self.unitID] = nil
	end
end


function CEnergy:FindGrid()
	unlinkedEnergy[self.unitID] = self
	for _,pylon in pairs(pylons) do
		if (pylon:CanLinkEnergy(self.unitID)) then
			pylon:AddEnergy(self)
			return
		end
	end
end


function CEnergy:Update()
	local stunned_or_inbuild = Spring.GetUnitIsStunned(self.unitID)
	local currentlyActive = not stunned_or_inbuild
	if (currentlyActive) and (not self.active) then
		self:Activate()
	elseif (not currentlyActive) and (self.active) then
		self:Deactivate()
	end
end

-------------------------------------------------------------------------------------
-------------------------------------------------------------------------------------
-- CPylon Methods

function CPylon:AddMex(mex)
	if (not self.overdrive) then 
		return
	end
	if (#self.conMexes >= PYLON_MEX_LIMIT) then
		return
	end

	mex.pylon = self
	self.conMexes[#self.conMexes+1] = mex
	unlinkedMexes[mex.unitID] = nil

	mex:UpdateTooltipAndAnimation()
end


function CPylon:RemoveMex(mex, dontcheck)
	if (not self.overdrive) then 
		return
	end

	for i=1,#self.conMexes do
		local mex_i = self.conMexes[i]
		if (mex_i == mex) then
			self.conMexes[i] = self.conMexes[#self.conMexes]
			self.conMexes[#self.conMexes] = nil
			break
		end
	end
	mex.pylon = nil
	mex:UpdateTooltipAndAnimation()

	if (not dontcheck)and(#self.conMexes < PYLON_MEX_LIMIT) then
		self:FindMexes()
	end
end


function CPylon:AddEnergy(egen)
	egen.pylon = self
	self.conEnergy[#self.conEnergy+1] = egen
	unlinkedEnergy[egen.unitID] = nil
end


function CPylon:RemoveEnergy(egen)
	for i=1,#self.conEnergy do
		local egen_i = self.conEnergy[i]
		if (egen_i == egen) then
			self.conEnergy[i] = self.conEnergy[#self.conEnergy]
			self.conEnergy[#self.conEnergy] = nil
			break
		end
	end
	egen.pylon = nil
end


function CPylon:AddPylon(pylon)
	self.conPylons[#self.conPylons+1] = pylon
end


function CPylon:RemovePylon(pylon)
	for i=1,#self.conPylons do
		local pylon_i = self.conPylons[i]
		if (pylon_i == pylon) then
			self.conPylons[i] = self.conPylons[#self.conPylons]
			self.conPylons[#self.conPylons] = nil
			break
		end
	end
end


function CPylon:CanLinkMex(unitID, dontCheckLinkLimit)
	if (not self.active)
	  or(not self.overdrive)
	  or((not dontCheckLinkLimit)and(#self.conMexes >= PYLON_MEX_LIMIT))
	then
		return
	end

	local allyID = Spring.GetUnitAllyTeam(unitID)
	if (allyID ~= self.allyID) then
		return false
	end

	local x,_,z = Spring.GetUnitPosition(unitID)
	return (self.x-x)^2 + (self.z-z)^2 < PYLON_MEX_RANGESQ
end


function CPylon:CanLinkEnergy(unitID)
	if (not self.active) then
		return
	end

	local allyID = Spring.GetUnitAllyTeam(unitID)
	if (allyID ~= self.allyID) then
		return false
	end

	local x,_,z = Spring.GetUnitPosition(unitID)
	return (self.x-x)^2 + (self.z-z)^2 < PYLON_MEX_RANGESQ
end


function CPylon:CanLinkPylon(pylon)
	if (pylon.allyID ~= self.allyID)
	  or(pylon == self)
	  or(not self.active)
	  or(not pylon.active)
	then
		return false
	end
	local distSq = (self.x-pylon.x)^2 + (self.z-pylon.z)^2
	return (distSq < PYLON_LINK_RANGESQ) and pylon.active
end


function CPylon:FindMexes()
	if (not self.active)
	  or(not self.overdrive)
	  or(#self.conMexes >= PYLON_MEX_LIMIT)
	then
		return
	end

	for _,mex in pairs(unlinkedMexes) do
		if (self:CanLinkMex(mex.unitID)) then
			self.grid:RequestOptimization()
			return
		end
	end
end


function CPylon:FindEnergy()
	for _,egen in pairs(unlinkedEnergy) do
		if (self:CanLinkEnergy(egen.unitID)) then
			self:AddEnergy(egen)
		end
	end
end


function CPylon:FindGrid()
	local nearby = self:GetNearbyPylons()

	for i=1,#nearby do
		local pylon = nearby[i]
		self:AddPylon(pylon)
		pylon:AddPylon(self)
	end

	if (#nearby==0) then
		--// no Grid found, create a new one
		local grid = CGrid:New(self.allyID)
		grid:AddPylon(self)
	elseif (#nearby>1) then
		--// multiple Grids found, merge them
		for i=#nearby,2,-1 do
			if (nearby[1].grid ~= nearby[i].grid) then
				nearby[1].grid:Merge(nearby[i].grid)
			end
		end
		nearby[1].grid:AddPylon(self)
	else --if (#nearby==1) then
		--// Just one Grid found, connect to it
		nearby[1].grid:AddPylon(self)
	end
end


function CPylon:GetNearbyPylons()
	local nearby = {}
	for _,pylon in pairs(pylons) do
		if (self:CanLinkPylon(pylon)) then
			nearby[#nearby+1] = pylon
		end
	end
	return nearby
end


function CPylon:Activate()
	self.active = true
	self:FindGrid()
	self:FindEnergy()
	self:FindMexes()
end


function CPylon:Deactivate()
	self.active = false
	if (self.grid) then
		self.grid:RemovePylon(self)
		for i=#self.conMexes, 1, -1 do
			local mex = self.conMexes[i]
			unlinkedMexes[mex.unitID] = mex
			self:RemoveMex( mex ,true )
		end
		for i=#self.conEnergy, 1, -1 do
			self:RemoveEnergy( self.conEnergy[i] )
		end
		for i=#self.conPylons, 1, -1 do
			local pylon = self.conPylons[i]
			self:RemovePylon(pylon)
			pylon:RemovePylon(self)
		end
	end
end


function CPylon:Update()
	--// check if pylons changed their active status (emp, reverse-build, ..)
	local stunned_or_inbuild = Spring.GetUnitIsStunned(self.unitID)
	local currentlyActive = not stunned_or_inbuild
	if (currentlyActive) and (not self.active) then
		self:Activate()
	elseif (not currentlyActive) and (self.active) then
		self:Deactivate()
	end
end

-------------------------------------------------------------------------------------
-------------------------------------------------------------------------------------
-- CGrid Optimization Methods (try to link the most efficient mexes to the grid)

function CGrid:_CreateOptimizeGrid()
	--// Create Lists of all Mexes in the Grid Area
		--// Add unlinked ones
		local mexes = {}
		for _,mex in pairs(unlinkedMexes) do
			for i=1,#self.conPylons do
				local pylon = self.conPylons[i]
				if (pylon:CanLinkMex(mex.unitID, true)) then
					mexes[#mexes+1] = mex
					break
				end
			end
		end

		--// There aren't anymore mexes that could be connected to the Grid -> Nothing to optimize
		if (not mexes[1]) then return end

		--// Add already linked ones
		for i=1,#self.conPylons do
			local pylon = self.conPylons[i]
			for i=1,#pylon.conMexes do
				mexes[#mexes+1] = pylon.conMexes[i]
			end
		end

	--// Check to which Pylons a Metal Extractor can link to
	for x=1,#mexes do
		local mex = mexes[x]
		mex.near_pylons = {}

		for y=1,#self.conPylons do
			local pylon = self.conPylons[y]
			if (pylon:CanLinkMex(mex.unitID, true)) then
				mex.near_pylons[#mex.near_pylons+1] = y
			end
		end
	end

	--// Sort the Metal Extractors by their metal production (and possible pylon links)
	local cmpFunc = function(a,b)
		local m1 = a.origMetal
		local m2 = b.origMetal
		if (m1 == m2) then
			return #a.near_pylons < #b.near_pylons
		end
		return m1 > m2
	end
	table.sort(mexes, cmpFunc )

	--// Create a 2-dim Grid of the possible Mex<->Pylon links
	--// e.g.: m\p 1 2 3 n+1     (4 mexes & 3 pylons) 
	--//        1  x _ x  x      (x := can link, _ := cannot link)
	--//        2  x x _  x      (the n+1 index is always true and is used by the optimization algos (to not link the mex at all))
	--//        3  x _ _  x
	--//        4  _ x x  x
	local grid = {} --//grid[mexIndex][pylonIndex] = boolean can_link
	for x=1,#mexes do
		local t = {}
		for y=1,#self.conPylons do
			t[y] = false
		end
		t[#self.conPylons+1] = true
		grid[x] = t
	end

	for x=1,#mexes do
		local mex = mexes[x]
		for j=1,#mex.near_pylons do
			local y = mex.near_pylons[j]
			grid[x][y] = true
		end
	end

	--// Compute the Ideal Total Metal (this doesn't mean that it is reachable! but it is if: #mexes <= #pylons * PYLON_MEX_LIMIT)
	local optMetal = 0
	for x=1,math.min(#mexes,#self.conPylons * PYLON_MEX_LIMIT) do
		optMetal = optMetal + mexes[x].origMetal
	end

	--// Return
	return grid, mexes, optMetal
end


function CGrid:FuzzyOptimize(grid, mexes, pylons)
	--// This is a fuzzy algo to optimize mex<->pylon links
	--// It's quite fast so we can run it in synced code,
	--// there is also a BruteForce attempt for optimization,
	--// but because it can be slow it runs in unsynced code
	--// and not all clients calculate it

	--// Final Links between Mexes and pylons: links[mex_i] = pylon_i
	local links = {}
	for x=1,#mexes do
		links[x] = false
	end

	--// pylonNumLinks := Count of already used links of a Pylon
	local pylonNumLinks = {}
	for y=1,#pylons do
		pylonNumLinks[y] = 0
	end

	local remainingLinks = #pylons * PYLON_MEX_LIMIT
	local remainingMexes = #mexes

	local function linkMex(pylon_i,mex_i)
		remainingLinks = remainingLinks - 1
		remainingMexes = remainingMexes - 1

		pylonNumLinks[pylon_i] = pylonNumLinks[pylon_i] + 1
		links[mex_i] = pylon_i
	end


	repeat
		for y=1,#pylons do
			local maxCheck = PYLON_MEX_LIMIT - pylonNumLinks[y]
			local x = 1

			while (maxCheck > 0)and(x <= #mexes) do
				if (not links[x])and(grid[x][y]) then
					maxCheck = maxCheck - 1

					local numPossibleLinks = 0
					for y2=1,#pylons do
						if (grid[x][y2])and(pylonNumLinks[y2] < PYLON_MEX_LIMIT) then
							numPossibleLinks = numPossibleLinks + 1
						end
					end

					if (numPossibleLinks == 1) then
						linkMex(y,x)
					end
				end
				x = x + 1
			end
		end

		if (remainingLinks==0)or(remainingMexes==0) then
			break
		end

		local bestNP   = math.huge
		local bestL    = math.huge
		local bestM    = -1
		local bestPyl  = -1
		local bestMex  = -1

		for y=1,#pylons do
			local maxCheck = PYLON_MEX_LIMIT - pylonNumLinks[y]
			local x = 1

			while (maxCheck > 0)and(x <= #mexes) do
				if (not links[x])and(grid[x][y]) then
					maxCheck = maxCheck - 1

					local mex = mexes[ x ]

					if (#mex.near_pylons < bestNP)
					  or((#mex.near_pylons == bestNP)and(mex.origMetal > bestM))
					  or((#mex.near_pylons == bestNP)and(mex.origMetal == bestM)and(pylonNumLinks[y] < bestL))
					then
						bestNP   = #mex.near_pylons
						bestL    = pylonNumLinks[y]
						bestM    = mex.origMetal
						bestPyl  = y
						bestMex  = x
					end
				end
				x = x + 1
			end
		end

		if (bestMex < 0) then
			break
		end

		linkMex(bestPyl,bestMex)
	until (remainingLinks==0)or(remainingMexes==0)

	--// Compute Total Metal with this setup
	local totalMetal = 0
	for x=1,#links do
		if (links[x]) then
			totalMetal = totalMetal + mexes[ x ].origMetal
		end
	end

	return totalMetal, links
end


function CGrid:OptimizeMexLinks()
	if not next(unlinkedMexes) then
		return
	end

	--// Get a list of all mexes that come into consideration for linking
	local grid, mexes, optMetal = self:_CreateOptimizeGrid()

	if (not grid) then
		return
	end

	--// First use a fuzzy algo, perhaps we have luck and it finds the ideal solution,
	--// if not then we can still use its result as a start value for a BruteForce check
	local total_metal, links = self:FuzzyOptimize(grid,mexes,self.conPylons)

	--// If the Fuzzy algo didn't found the ideal solution we use a BruteForce,
	--// but this can be slow that's why we do it in unsynced code, so only the
	--// powerful clients have to calculate it
	if (optMetal - total_metal > optMetal*0.01) then
		--// we can't use tables as arguments for SendToUnsynced, so we go this way
		_G._OD_FUNC_TABLE_ARGS = {grid, mexes, self.conPylons}
			SendToUnsynced('overdrive_grid_optimize', self.gridID, total_metal, optMetal)
		_G._OD_FUNC_TABLE_ARGS = nil
	end

	--// Put it into reality
	local setup = {}
	for x=1,#mexes do
		if (links[x]) then
			local mexID = mexes[ x ].unitID
			local pylID = self.conPylons[ links[x] ].unitID
			setup[mexID] = pylID
		end
	end
	self:AssignMexes(setup)
end


function CGrid:RequestOptimization()
	self.optimizeGrid = true
end

-------------------------------------------------------------------------------------
-------------------------------------------------------------------------------------
-- CGrid Methods

function CGrid:AddPylon(pylon)
	self.conPylons[#self.conPylons+1] = pylon
	pylon.grid = self

	self:RequestOptimization()
end


function CGrid:RemovePylon(pylon)
	for i=1,#self.conPylons do
		local pylon_i = self.conPylons[i]
		if (pylon_i == pylon) then
			self.conPylons[i] = self.conPylons[#self.conPylons]
			self.conPylons[#self.conPylons] = nil
			break
		end
	end

	if (#self.conPylons==0) then
		--// No Pylons left, destroy the grid
		self:Destroy()
	else
		--// Check if the grid got cut in half
		self.checkIntegrity = true
		self:RequestOptimization()
	end
end


function CGrid:RecursiveCheckIntegrity(pylon, already_checked)
	--//SubFunction of :CheckIntegrity()
	already_checked[pylon] = true
	already_checked[#already_checked+1] = pylon

	local nearpylons = pylon:GetNearbyPylons()
	for i=1, #nearpylons do
		local np = nearpylons[i]
		if (not already_checked[np]) then
			self:RecursiveCheckIntegrity(np, already_checked)
		end
	end
end


function CGrid:CheckIntegrity()
	local linked = {}
	self:RecursiveCheckIntegrity(self.conPylons[1],linked)

	if (#linked ~= #self.conPylons) then
		--// Split Grid
		local sepGrid = CGrid:New(self.allyID)
		for i=#self.conPylons,1,-1 do
			local pylon = self.conPylons[i]
			if (not linked[pylon]) then
				self:RemovePylon(pylon)
				sepGrid:AddPylon(pylon)
			end
		end
		sepGrid:CheckIntegrity()
	end
end


function CGrid:Merge(grid)
	if (self == grid) then
		--Spring.Echo("tried to merge grid with itself!")
		return
	end

	local gridS = (#grid.conPylons < #self.conPylons) and grid or self
	local gridL = (#grid.conPylons < #self.conPylons) and self or grid
	for i=#gridS.conPylons,1,-1 do
		local pylon = gridS.conPylons[i]
		gridS:RemovePylon(pylon)
		gridL:AddPylon(pylon)
	end
end


function CGrid:AssignMexes(links)
	--// Unlink old mexes
	for p_i=1, #self.conPylons do
		local pylon = self.conPylons[p_i]
		for m_i=#pylon.conMexes, 1, -1 do
			local mex = pylon.conMexes[m_i]
			unlinkedMexes[mex.unitID] = mex
			pylon:RemoveMex( mex ,true )
		end
	end

	local no_error = true

	--// Link new mexes
	for mexID,pylID in pairs(links) do
		local mex = mexes[tonumber(mexID)]
		local pylon = pylons[tonumber(pylID)]
		if (mex and pylon)and(pylon.grid == self)and(mex.allyID == self.allyID)and(pylon:CanLinkMex(mexID)) then
			pylon:AddMex( mex )
		else
			no_error = false
		end
	end

	return no_error
end


function CGrid:UpdateCapacity()
	local capacity = 0
	for i=1,#self.conPylons do
		local pylon = self.conPylons[i]
		for j=1,#pylon.conEnergy do
			local unitID = pylon.conEnergy[j].unitID
			local eMake,eUse = select(3,Spring.GetUnitResources(unitID))
			capacity = capacity + (eMake - eUse)
		end
	end
	self.capacity = capacity
end


function CGrid:Update()
	--// check if all Pylons are connected
	if (self.checkIntegrity) then
		self.checkIntegrity = false
		self:CheckIntegrity()
	end

	--// There are new mexes and/or changed their status.
	--// Link the most efficient ones to the Grid.
	if (self.optimizeGrid) then
		self.optimizeGrid = false
		self:OptimizeMexLinks()
	end

--// TODO: move pylon tooltip update to the CPylon class

	--// Create Lists of all connected Mexes
	local conMexes = {}
	for i=1,#self.conPylons do
		local pylon = self.conPylons[i]
		for i=1,#pylon.conMexes do
			conMexes[#conMexes+1] = pylon.conMexes[i]
		end
	end

	--// No Metal Extractors connected
	if (not next(conMexes)) then
		for _, pylon in ipairs(self.conPylons) do
			local unitDef = UnitDefs[Spring.GetUnitDefID(pylon.unitID)]
			local tooltip = ("%s - No MetalExtractors Connected!"):format(unitDef.humanName)
			Spring.SetUnitTooltip(pylon.unitID, tooltip)
			Spring.SetUnitRulesParam(pylon.unitID, "OverdriveMetalBonus", 0)
			Spring.SetUnitRulesParam(pylon.unitID, "OverdriveEnergySpent", 0)
		end
		return
	end

	--// No Energy connected
	if (self.energy<=0)and(self.capacity<=0) then
		for _, pylon in ipairs(self.conPylons) do
			local unitDef = UnitDefs[Spring.GetUnitDefID(pylon.unitID)]
			local tooltip = ("%s - No Energy Connected!"):format(unitDef.humanName)
			Spring.SetUnitTooltip(pylon.unitID, tooltip)
			Spring.SetUnitRulesParam(pylon.unitID, "OverdriveMetalBonus", 0)
			Spring.SetUnitRulesParam(pylon.unitID, "OverdriveEnergySpent", 0)
		end
		return
	end

	--// No Energy for Overdrive
	if (self.energy<=0) then
		for i=1,#conMexes do
			local mex = conMexes[i]
			mex:UpdateOverdrive(0)
		end
		for _, pylon in ipairs(self.conPylons) do
			local unitDef = UnitDefs[Spring.GetUnitDefID(pylon.unitID)]
			local tooltip = ("%s - Extra Metal: 0.00 Overdrive: 0%% Used Energy: 0/%.0f"):format(unitDef.humanName,self.capacity)
			Spring.SetUnitTooltip(pylon.unitID, tooltip)
			Spring.SetUnitRulesParam(pylon.unitID, "OverdriveMetalBonus", 0)
			Spring.SetUnitRulesParam(pylon.unitID, "OverdriveEnergySpent", 0)
		end
		return
	end

	--// Share and optimize the free Energy across the Mexes
	local freeE = self.energy
	local usedE = freeE

	local totalOrigMetal = 0
	local mexUsedEnergy = {}
	local mexEfficiency = {}
	local metalMult1 = energyToExtraM(1)
	for i=1,#conMexes do
		local mex = conMexes[i]
		totalOrigMetal = totalOrigMetal + mex.origMetal
		mexEfficiency[i] = metalMult1 * mex.origMetal
		mexUsedEnergy[i] = 0
	end

	--// Mexes don't extract any metal -> nothing to overdrive
	if (totalOrigMetal==0) then
		for _, pylon in ipairs(self.conPylons) do
			local unitDef = UnitDefs[Spring.GetUnitDefID(pylon.unitID)]
			local tooltip = ("%s - MetalExtractors don't extract any Metal!"):format(unitDef.humanName)
			Spring.SetUnitTooltip(pylon.unitID, tooltip)
			Spring.SetUnitRulesParam(pylon.unitID, "OverdriveMetalBonus", 0)
			Spring.SetUnitRulesParam(pylon.unitID, "OverdriveEnergySpent", 0)
		end
		return
	end

	while (freeE > 0) do
		local bestMex = -1
		local bestEff = -1
		local bestEff_2nd = -1

		for i=1, #mexEfficiency do
			if (mexEfficiency[i] >= bestEff) then
				bestMex = i
				bestEff_2nd = bestEff
				bestEff = mexEfficiency[i]
			elseif(mexEfficiency[i] >= bestEff_2nd) then
				bestEff_2nd = mexEfficiency[i]
			end
		end

		if (bestEff_2nd<0) then
			--// just one mex connected?
			bestEff_2nd = bestEff
		end
		if (bestEff_2nd==bestEff) then
			--//todo: better way?
			bestEff_2nd = 0.8 * bestEff
		end

		local mex = conMexes[bestMex]
		local stepMult = bestEff_2nd/mex.origMetal
		local usedE = MetalMultToEnergy(stepMult)
		if (freeE < usedE) then
			usedE = freeE
		end

		local usedMexE = mexUsedEnergy[bestMex] + usedE
		mexUsedEnergy[bestMex] = usedMexE
		mexEfficiency[bestMex] = (energyToExtraM(usedMexE+1) - energyToExtraM(usedMexE)) * mex.origMetal
		freeE = freeE - usedE
	end

	local normalM = 0
	local overdriveM = 0

	--// Update mex tooltips & overdrive output (this also shares it across the teams!)
	for i=1,#conMexes do
		local mex = conMexes[i]

		mex:UpdateOverdrive(mexUsedEnergy[i])

		normalM = normalM + mex.origMetal
		overdriveM = overdriveM + mex.overdriveMetal
	end

	--// Update pylon tooltips
	for _, pylon in ipairs(self.conPylons) do
		local unitDef = UnitDefs[Spring.GetUnitDefID(pylon.unitID)]
		--// todo: add a efficiency tag (overdriveM/usedE ?)
		local tooltip = ("%s - Extra Metal: %.2f Overdrive: %.0f%% Used Energy: %.0f/%.0f"):format(unitDef.humanName,overdriveM / UPDATE_MULT,(overdriveM/totalOrigMetal)*100,usedE / UPDATE_MULT,self.capacity)
		--local tooltip = ("%s - Extra Metal: %.2f Efficiency: %.1f Used Energy: %.0f/%.0f"):format(unitDef.humanName,overdriveM / UPDATE_MULT,10*overdriveM/self.capacity,usedE / UPDATE_MULT,self.capacity)
		Spring.SetUnitTooltip(pylon.unitID, tooltip)

		Spring.SetUnitRulesParam(pylon.unitID, "OverdriveMetalBonus", overdriveM / UPDATE_MULT)
		Spring.SetUnitRulesParam(pylon.unitID, "OverdriveEnergySpent", usedE / UPDATE_MULT)
	end

	self.energy = 0
end

-------------------------------------------------------------------------------------
-------------------------------------------------------------------------------------
-- GAME FRAME

function gadget:GameFrame(n)
	if ((n+30)%UPDATE_RATE < 1) then
		UpdateActiveTeams()

		--// Update Mexes, Energy Generators, Pylons
		for _,mex in pairs(mexes) do
			mex:Update()
		end
		for _,egen in pairs(energy) do
			egen:Update()
		end
		for _,pylon in pairs(pylons) do
			pylon:Update()
		end
		for _,grid in pairs(grids) do
			grid:UpdateCapacity()
		end

		local allyList = Spring.GetAllyTeamList()
		for i=1,#allyList do
			local allyID = allyList[i]
			local teamList = Spring.GetTeamList(allyID)

			local freeE = 0
			local demandE = 0
			local donators = {}
			local aidTeams = {}
			local aidWeights = {}

			--//FIXME: this is just a workaround, in theory this energy should be added to freeE
			--//  but atm Spring.GetTeamStatsHistory just updates its stats each 15sec!
			--//  so we just spread it across this time
			local energyExcess = 0
			local excessUpdated = false

			--// Calculate ally's free Energy and team's demand of Energy
			for j=1, #teamList do
				local teamID = teamList[j]
				local eSpare, teamWeight = GetTeamEnergySupply(teamID)
				if (eSpare < 0) then
					demandE = demandE + eSpare
					aidTeams[teamID] = eSpare
					aidWeights[teamID] = teamWeight
				elseif (eSpare > 0) then
					freeE = freeE + eSpare
					donators[teamID] = eSpare
				end

				--//FIXME: read the comment above!
				local idx = Spring.GetTeamStatsHistory(teamID)
				local curStats = Spring.GetTeamStatsHistory(teamID,idx)[1]
				if (curStats.energyExcess ~= oldTeamExcess[teamID])or(curStats.frame ~= oldTeamStatsFrame[teamID]) then
					energyExcess = energyExcess + (curStats.energyExcess - (oldTeamExcess[teamID] or 0))
					oldTeamExcess[teamID] = curStats.energyExcess
					oldTeamStatsFrame[teamID] = curStats.frame
					excessUpdated = true
				end
			end

			--// Send the Aid (Communism)
			freeE, donators = DoCommunism(freeE, demandE, donators, aidTeams, aidWeights)


			--//FIXME: check comments above!
			--// add this extra Energy after Communism, so it can just be used for Overdrive!
			if (excessUpdated) then
				energyExcessExtra[allyID] = energyExcess
			end
			freeE = freeE + (energyExcessExtra[allyID] or 0) / 15 * UPDATE_MULT

			--// Check how much Energy is connected to the grids
			local totalCapacity = 0
			for _,grid in pairs(grids) do
				if (grid.allyID == allyID) then
					totalCapacity = totalCapacity + grid.capacity
				end
			end
			totalCapacity = totalCapacity * UPDATE_MULT

			--// We can't use more Energy than energy is connected to grids!
			if (freeE > totalCapacity * UPDATE_MULT) then
				for teamID,donation in pairs(donators) do
					donators[teamID] = donation * totalCapacity/freeE
				end
				freeE = totalCapacity
			end

			--// Share the remaining Energy across the Grids
			for _,grid in pairs(grids) do
				if (grid.allyID == allyID)and(grid.capacity>0) then
					grid.energy = grid.energy + freeE * (totalCapacity / (grid.capacity * UPDATE_MULT))
				end
			end

			--// We used the Energy
			for teamID,donation in pairs(donators) do
				Spring.UseTeamResource(teamID, "e", donation)

				--FIXME add engine tag to hide this data to enemy teams! (in luaui!)
				Spring.SetTeamRulesParam(teamID,"OverdriveEnergyCurExpense",donation)
				--local old = Spring.GetTeamRulesParam(teamID,"OverdriveEnergySpent")
				--Spring.SetTeamRulesParam(teamID,"OverdriveEnergySpent", old+donation)
			end
		end

		--// Update Grids (handle Overdrive on Grid-level)
		for _,grid in pairs(grids) do
			grid:Update()
		end
	end
end

-------------------------------------------------------------------------------------
-------------------------------------------------------------------------------------
-- EVIL HACK REMOVE THIS WITH 0.82!!!!!!!

do
	local origGameFrame = gadget.GameFrame

	function HACK_workaround_missing_coroutine_in_unsynced()
		_G._HACK_COROUTINE = coroutine
		SendToUnsynced('HACK_init_unsynced_coroutine')
		_G._HACK_COROUTINE = nil

		gadget.GameFrame = origGameFrame
		gadgetHandler:UpdateCallIn("GameFrame")
	end

	gadget.GameFrame = HACK_workaround_missing_coroutine_in_unsynced
end

-------------------------------------------------------------------------------------
-------------------------------------------------------------------------------------

function gadget:RecvLuaMsg(msg, playerID)
	if (msg:find("^OD_opt_grid:")) then
		msg = msg:sub(13)
		local links  = Spring.Utilities.json.decode(msg)
		local gridID = links.gridID;
		links.gridID = nil;

		local grid = grids[gridID]
		local allyID = select(5,Spring.GetPlayerInfo(playerID))
		local isSpec = select(3,Spring.GetPlayerInfo(playerID))

		if (not isSpec)and(grid)and(grid.allyID == allyID) then
			if (grid:AssignMexes(links)) then
				SendToUnsynced('overdrive_grid_optimization_finished',gridID)
			end
		end
	end
end

-------------------------------------------------------------------------------------
-------------------------------------------------------------------------------------

function gadget:Initialize()
	_G.communism_and_overdrive = {}
	_G.communism_and_overdrive.energy = energy
	_G.communism_and_overdrive.mexes  = mexes
	_G.communism_and_overdrive.pylons = pylons
	_G.communism_and_overdrive.grids  = grids

	for _, unitID in ipairs(Spring.GetAllUnits()) do
		local unitDefID = Spring.GetUnitDefID(unitID)
		local teamID = Spring.GetUnitTeam(unitID)
		gadget:UnitCreated(unitID, unitDefID, teamID)
	end
end


function gadget:Shutdown()
	--// destroy the hidden gaia mexes!
	for _, unitID in ipairs(Spring.GetAllUnits()) do
		local unitDefID = Spring.GetUnitDefID(unitID)
		local teamID = Spring.GetUnitTeam(unitID)
		gadget:UnitDestroyed(unitID, unitDefID, teamID)
	end
--[ [
	for _, unitID in ipairs(Spring.GetTeamUnits(gaiaTeamID)) do
		Spring.DestroyUnit(unitID, false, true)
	end
--]]
end

-------------------------------------------------------------------------------------
-------------------------------------------------------------------------------------

function gadget:UnitCreated(unitID, unitDefID, unitTeam)
	if (gaiaTeamID == unitTeam) then
		return
	end

	if (mexDefs[unitDefID]) then
		CMex:New(unitID)
	end
	if (energyDefs[unitDefID]) then
		CEnergy:New(unitID)
	end
	if (pylonDefs[unitDefID]) then
		CPylon:New(unitID)
	end
end


function gadget:UnitDestroyed(unitID, unitDefID, unitTeam)
	if (gaiaTeamID == unitTeam) then
		return
	end

	if (mexes[unitID]) then  
		mexes[unitID]:Destroy()
	end
	if (energy[unitID]) then
		energy[unitID]:Destroy()
	end
	if (pylons[unitID]) then
		pylons[unitID]:Destroy()
	end
end


function gadget:UnitTaken(unitID, unitDefID, oldTeamID, newTeamID)
	local newAllyTeam = select(6,Spring.GetTeamInfo(newTeamID))
	local oldAllyTeam = select(6,Spring.GetTeamInfo(oldTeamID))
	
	if (newAllyTeam ~= oldAllyTeam) then
		gadget:UnitDestroyed(unitID, unitDefID, oldTeamID)
		gadget:UnitCreated(unitID, unitDefID, newTeamID)
	end
end


-------------------------------------------------------------------------------------
-------------------------------------------------------------------------------------
else  -- UNSYNCED
-------------------------------------------------------------------------------------
-------------------------------------------------------------------------------------

local glVertex           = gl.Vertex
local glColor            = gl.Color
local glBeginEnd         = gl.BeginEnd
local isUnitInView       = Spring.IsUnitInView
local spGetSelectedUnits = Spring.GetSelectedUnits
local spGetActiveCommand = Spring.GetActiveCommand
local spTraceScreenRay   = Spring.TraceScreenRay
local spGetMouseState    = Spring.GetMouseState
local spGetMyAllyTeamID  = Spring.GetMyAllyTeamID

local isReplay = false

-------------------------------------------------------------------------------------
-------------------------------------------------------------------------------------

--// XYZ := SYNCED.communism_and_overdrive.XYZ
local energy,mexes,pylons,grids

-------------------------------------------------------------------------------------
-------------------------------------------------------------------------------------
-- Local Functions

local function GetAllyAvgCpuUsage(allyID)
	local allyAvgCpuUsage = 0

	local numPlayers = 0
	local teamList = Spring.GetTeamList(allyID)
	for i=1,#teamList do
		local players   = Spring.GetPlayerList(teamList[i],true)
		allyAvgCpuUsage = allyAvgCpuUsage * (numPlayers/#players)
		numPlayers      = #players

		for j=1,#players do
			local cpuUsage  = select(7, Spring.GetPlayerInfo(players[j]))
			allyAvgCpuUsage = allyAvgCpuUsage + cpuUsage/numPlayers
		end
	end

	return allyAvgCpuUsage
end

-------------------------------------------------------------------------------------
-------------------------------------------------------------------------------------
-- Unsynced Part of Team Resource Sharing (we can't do that in synced yet)

local function ShareResources(_,teamID, poorTeamID, type, shareAmount)
	if (teamID == Spring.GetMyTeamID()) then
		--// when commsharing, don't send the share command for each player
		local leader = select(2,Spring.GetTeamInfo(teamID))
		if (leader ~= Spring.GetMyPlayerID()) then
			return
		end

		--// user has disabled moduictrl -> can't share resources w/o it!
		if (not Spring.GetModUICtrl()) then
			local myPlayerName = Spring.GetPlayerInfo(Spring.GetMyPlayerID())
			Spring.SendMessage(myPlayerName .. " has ModUICtrl disabled. It's needed by communism, reenable it with '/luamoduictrl'!!!")
		end

		Spring.ShareResources(poorTeamID, type, shareAmount)
	end
end

-------------------------------------------------------------------------------------
-------------------------------------------------------------------------------------
-- Unsynced Part of Mex<->Pylons Links Optimization
--  it's BruteForce, so it's better to do it in unsynced code
--  and not let all players calculate it

local jobs = {}

function sCopyTable(outtable,intable,depth)
	if (type(intable)=="number") then
		depth = intable
		intable = nil
	end
	if (not intable) then
		intable = outtable
		outtable = {}
	end
	depth = depth or 0

	for i,v in spairs(intable) do
		if (depth>0)and(type(v)=="table") then
			if (type(outtable[i])~="table") then outtable[i] = {} end
			sCopyTable(outtable[i],v,depth-1)
		else
			outtable[i] = v
		end
	end

	return outtable
end


local function BruteForce_Rec(args,curMex)
--//TODO try to reduce the links length? (would need to presort the grid, else a BruteForce takes >10secs with 12mexes & 4 pylons)

	if (curMex > #args.mexes) then
		if (args.curMetal > args.bestMetal) then
			args.bestMetal = args.curMetal
			args.bestSqLength = args.curSqLength
			for i=1,#args.links do
				args.bestLinks[i] = args.links[i]
			end
		end

		return (args.curMetal >= args.optMetal*0.99)
	end

	if (args.curMetal + args.remainingM[curMex] <= args.bestMetal) then
		return false
	end

	if (args.yield == 0) then
		coroutine.yield(true)
		args.yield = 100
	else
		args.yield = args.yield - 1
	end

	args.curMetal = args.curMetal + args.mexes[curMex].origMetal

	local can_link_x = args.can_link[curMex]
	for y=1,#args.pylons do
		if (can_link_x[y])and(args.pylon_free_links[y] > 0) then
			args.pylon_free_links[y] = args.pylon_free_links[y]-1
			args.links[curMex] = y

			local finished = BruteForce_Rec(args, curMex+1)
			if (finished) then
				return true
			end

			args.pylon_free_links[y] = args.pylon_free_links[y]+1
		end
	end

	--// ignore the mex and don't link it
	args.links[curMex] = #can_link_x
	args.curMetal = args.curMetal - args.mexes[curMex].origMetal
	return BruteForce_Rec(args, curMex+1)
end


local function BruteForceMain(args)
	coroutine.yield(true)
	local result = BruteForce_Rec(args, 1)

	if (args.bestMetal > args.fuzzyMetal) then
		local t = {gridID=args.gridID}
		for x=1,#args.mexes do
			local p_i = args.bestLinks[x]
			if (p_i <= #args.pylons) then
				local mexID = args.mexes[x].unitID
				local pylID = args.pylons[p_i].unitID
				t[mexID] = pylID
			end
		end
		Spring.SendLuaRulesMsg("OD_opt_grid:" .. Spring.Utilities.json.encode(t))
	end

	return false
end


local function CreateBruteForceThread(gridID, can_link, mexes, pylons, fuzzyM, optMetal)
	local tot = 0
	local remainingM = {}
	for i=#mexes,1,-1 do
		tot = tot + mexes[i].origMetal
		remainingM[i] = tot
	end

	local pylon_free_links = {}
	for y=1,#pylons do
		pylon_free_links[y] = PYLON_MEX_LIMIT
	end
	pylon_free_links[#pylons+1] = math.huge

	local links = {}
	for x=1,#mexes do
		links[x] = -1
	end

	local args = {
		gridID     = gridID,
		mexes      = mexes,
		pylons     = pylons,
		can_link   = can_link,

		pylon_free_links = pylon_free_links,
		remainingM = remainingM,

		links      = links,
		curMetal   = 0,
		curMex     = 0,

		bestLinks  = {},
		bestMetal  = fuzzyM,
		fuzzyMetal = fuzzyM,
		optMetal   = optMetal,

		yield      = 100,
	}

	local thread = coroutine.wrap(BruteForceMain)
	thread(args)

	return thread
end


local function OptimizationFinished(_, gridID)
	--// Optimization was aborted or finished by another client
	--// delete the still ongoing job
	if (jobs[-gridID]) then
		for i=1,#jobs do
			local job_gridID = jobs[i][2]
			if (job_gridID == gridID) then
				table.remove(jobs,i)
				jobs[-gridID] = nil
				return
			end
		end
	end
end


local function OptimizeGrid(_, gridID, fuzzyMetal, optMetal)
	local myPlayerID = Spring.GetMyPlayerID()
	local myAllyID   = Spring.GetMyAllyTeamID()

	--// Only process jobs by the own team
	if (myAllyID ~= (grids[gridID] or {}).allyID)or(isReplay) then
		return
	end

	--// Check if we already have an optimization job for that grid,
	--// if so delete the old one
	if (jobs[-gridID]) then
		OptimizationFinished(nil, gridID)
	end

	local avgCpuUsage = GetAllyAvgCpuUsage(myAllyID)
	local myCpuUsage  = select(7, Spring.GetPlayerInfo(myPlayerID))

	--// Only process the BruteForce when the client isn't lagging
	--// (Other Ally members will still process it)
	if (myCpuUsage <= avgCpuUsage) then
		local can_link = sCopyTable(SYNCED._OD_FUNC_TABLE_ARGS[1], 1)
		local mexes    = sCopyTable(SYNCED._OD_FUNC_TABLE_ARGS[2])
		local pylons   = sCopyTable(SYNCED._OD_FUNC_TABLE_ARGS[3])

		local thread = CreateBruteForceThread(gridID, can_link, mexes, pylons, fuzzyMetal, optMetal)
		jobs[#jobs+1] = {thread,gridID}
		jobs[-gridID] = true
	end
end


function gadget:Update()
	if (not jobs[1]) then
		return
	end

	--// limit the max. time spent on the grid optimizations, so it won't lag the client
	local start = Spring.GetTimer()
	local fps   = Spring.GetFPS()
	local maxTimePerSec   = 0.08 --//80ms
	local maxTimePerFrame = maxTimePerSec/fps
	local factor          = 1/(1+math.exp(-fps/6+5)) --// 45fps := ->1, 30fps := 0.5, <15fps := ->0
	local maxTime         = maxTimePerFrame * factor

	for i=1,#jobs do
		local thread = jobs[i][1]
		while (thread()) do 
			if (Spring.DiffTimers(Spring.GetTimer(),start) > maxTime) then
				i = math.huge
				break
			end
		end
		if (i < math.huge) then
			local job_gridID  = jobs[i][2]
			jobs[-job_gridID] = nil
			table.remove(jobs,i)
			i = i-1
		end
	end
end

-------------------------------------------------------------------------------------
-------------------------------------------------------------------------------------
-- EVIL HACK REMOVE THIS WITH 0.82!!!!!!!

local function InitializeCoroutine()
	coroutine = {}
	for i,v in spairs(SYNCED._HACK_COROUTINE) do
		coroutine[i] = v
	end
end

-------------------------------------------------------------------------------------
-------------------------------------------------------------------------------------
-- Initialize

function gadget:Initialize()
	isReplay = Spring.IsReplay()

	gadgetHandler:AddSyncAction('communism_share', ShareResources)
	gadgetHandler:AddSyncAction('overdrive_grid_optimize', OptimizeGrid)
	gadgetHandler:AddSyncAction('overdrive_grid_optimization_finished', OptimizationFinished)
	gadgetHandler:AddSyncAction('HACK_init_unsynced_coroutine', InitializeCoroutine)

	energy = SYNCED.communism_and_overdrive.energy
	mexes  = SYNCED.communism_and_overdrive.mexes
	pylons = SYNCED.communism_and_overdrive.pylons
	grids  = SYNCED.communism_and_overdrive.grids
end

-------------------------------------------------------------------------------------
-------------------------------------------------------------------------------------
-- Small Helper to prevent drawing items in buildqueues multiple times

local alreadyDrawn = {}
setmetatable(alreadyDrawn, {
  __index = function(t,i)
    local newsubtable = {}
    t[i] = newsubtable
    return newsubtable
  end,

  __call = function(t,x,z, set)
    local result = (t[x][z] == Spring.GetDrawFrame())
    t[x][z] = Spring.GetDrawFrame()
    return result
  end,
})

-------------------------------------------------------------------------------------
-------------------------------------------------------------------------------------

local function DrawArray(ar, pobj)  -- renders lines from unitID to array members
	--local uvisible = isUnitInView(unitID)
	local ux = pobj.x
	local uy = pobj.y
	local uz = pobj.z
	
	for _,obj in spairs(ar) do
		--if (spValidUnitID(obj.unitID)) then
			glVertex(ux,uy,uz)
			--if (uvisible or isUnitInView(obj.unitID)) then
				glVertex(obj.x,obj.y,obj.z)
			--end
		--end
	end
end


local function DrawPylonEnergyLines()
	local myAllyID = Spring.GetMyAllyTeamID()
	local spec, fullview = Spring.GetSpectatingState()
	spec = spec or fullview

	for _, pylon in spairs(pylons) do
		if (pylon.allyID == myAllyID)or(spec) then
			DrawArray(pylon.conEnergy, pylon)
		end
	end
end

local function DrawPylonMexLines()
	local myAllyID = Spring.GetMyAllyTeamID()
	local spec, fullview = Spring.GetSpectatingState()
	spec = spec or fullview

	for _, pylon in spairs(pylons) do
		if (pylon.allyID == myAllyID)or(spec) then
			DrawArray(pylon.conMexes, pylon)
		end
	end
end

local function DrawPylonLinkLines()
	local myAllyID = Spring.GetMyAllyTeamID()
	local spec, fullview = Spring.GetSpectatingState()
	spec = spec or fullview

	for _, pylon in spairs(pylons) do
		if (pylon.allyID == myAllyID)or(spec) then
			DrawArray(pylon.conPylons, pylon)
		end
	end
end


local function HighlightPylons(selectedUnitDefID)
	local myAllyID = spGetMyAllyTeamID()
	local spec, fullview = Spring.GetSpectatingState()
	spec = spec or fullview

	glColor(0.6,0.7,0.5,0.15)

	local selUnits = spGetSelectedUnits()
	for i=1,#selUnits do
		local cmdqueue = Spring.GetUnitCommands(selUnits[i])
		for j=1,#cmdqueue do
			local cmd = cmdqueue[j]
			local params = cmd.params
			if (cmd.id<0 and pylonDefs[-cmd.id])and(not alreadyDrawn(params[1],params[3])) then
				gl.Utilities.DrawGroundCircle(params[1],params[3],PYLON_RANGE)
			end
		end

		local buildID = Spring.GetUnitIsBuilding(selUnits[i])
		if (buildID and pylonDefs[Spring.GetUnitDefID(buildID)]) then
			local x,y,z = Spring.GetUnitBasePosition(buildID)
			if (not alreadyDrawn(x,z)) then
				gl.Utilities.DrawGroundCircle(x,z,PYLON_RANGE)
			end
		end
	end

	glColor(0.6,0.7,0.5,0.3)

	for _,pylon in spairs(pylons) do
		if ((pylon.allyID == myAllyID)or(spec))and(pylon.active) then
			gl.Utilities.DrawGroundCircle(pylon.x,pylon.z,PYLON_RANGE)
		end
	end

	if selectedUnitDefID then
		local mx, my = spGetMouseState()
		local _, coords = spTraceScreenRay(mx, my, true, true)
		if coords then 
			coords = {Spring.Pos2BuildPos(selectedUnitDefID, coords[1], coords[2], coords[3])}
			gl.Utilities.DrawGroundCircle(coords[1],coords[3],PYLON_RANGE)
		end
	end

	if snext(pylons) then
		gl.DepthMask(false)
		gl.DepthTest(false)
		gl.Color(0.8,0.8,0.2,math.random()*0.1+0.3)
		gl.BeginEnd(GL.LINES, DrawPylonEnergyLines)
		gl.DepthTest(true)
		gl.DepthMask(true)
	end

	gl.Color(1,1,1,1)
end

-------------------------------------------------------------------------------------
-------------------------------------------------------------------------------------

function gadget:DrawWorldPreUnit()
	--// always show links between pylons and mexes
	--// (energy links are hidden as long as none pylon is selected)
	if snext(pylons) then
		gl.DepthMask(false)
		gl.DepthTest(false)
		gl.Color(0.5,0.4,1,math.random()*0.15+0.45)
		gl.LineWidth(3)
		gl.BeginEnd(GL.LINES, DrawPylonMexLines)

		gl.Color(0.9,0.8,0.2,math.random()*0.15+0.45)
		gl.LineWidth(2)
		gl.BeginEnd(GL.LINES, DrawPylonLinkLines)

		gl.Color(1,1,1,1)
		gl.LineWidth(1)
		gl.DepthTest(true)
		gl.DepthMask(true)
	end

	--// show pylons if pylon is about to be placed
	local _, cmd_id = spGetActiveCommand()
	if (cmd_id) then
		if pylonDefs[-cmd_id] then
			HighlightPylons(-cmd_id)
			return
		elseif energyDefs[-cmd_id] or mexDefs[-cmd_id] then
			HighlightPylons(nil)
			return
		end
		return
	end

	--// or show it if its selected
	local selUnits = spGetSelectedUnits()
	for i=1,#selUnits do
		local ud = Spring.GetUnitDefID(selUnits[i])
		if (pylonDefs[ud]) then
			HighlightPylons(nil)
			return
		end
	end
end

-------------------------------------------------------------------------------------

end
