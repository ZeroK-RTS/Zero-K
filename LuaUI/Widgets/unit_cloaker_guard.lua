-- $Id$

function widget:GetInfo()
  return {
    name      = "Cloaker Guard",
    desc      = "Replaces guarding cloakers with follow and hold fire. Cloakers move at speed of slowest unit following and wait for stragglers.",
    author    = "Google Frog",
    date      = "9 Mar, 2009",
    license   = "GNU GPL, v2 or later",
    layer     = 5,
    enabled   = true --  loaded by default?
  }
end


-- Speedups

local CMD_MOVE = CMD.MOVE
local CMD_WAIT = CMD.WAIT
local CMD_STOP = CMD.STOP
local CMD_GUARD = CMD.GUARD
local CMD_FIRE_STATE = CMD.FIRE_STATE
local CMD_SET_WANTED_MAX_SPEED = CMD.SET_WANTED_MAX_SPEED

local CMD_OPT_SHIFT = CMD.OPT_SHIFT
local CMD_OPT_RIGHT = CMD.OPT_RIGHT

local CMD_INSERT = CMD.INSERT
local CMD_REMOVE = CMD.REMOVE

local spGiveOrderToUnit = Spring.GiveOrderToUnit

local spGetUnitPosition 	= Spring.GetUnitPosition
local spGetSelectedUnits 	= Spring.GetSelectedUnits
local spGetUnitStates 		= Spring.GetUnitStates
local spValidUnitID 		= Spring.ValidUnitID
local spGetUnitDefID 		= Spring.GetUnitDefID
local spGetCommandQueue 	= Spring.GetCommandQueue
local spGetTeamUnits 		= Spring.GetTeamUnits
local spGetUnitSeparation 	= Spring.GetUnitSeparation

local team = Spring.GetMyTeamID()

local cloakers = {}
local follower = {}

----------------------------
--  CONFIG

local cloakRangeSafety = 80 -- how close to the edge cloakers should wait at
local cloakReactivateRange = 120 -- how far from the edge cloakers should reactivate at
local cloakieeStopDis = 90 -- how far from the cloaker the cloakiees should stop



local cloakerArray = { 

  "armjamt",
  "spherecloaker",
  "armadvcom",

}


----------------------------
--  Removes all CMD_SET_WANTED_MAX_SPEED from unitIDs queue

--local function removeSetMaxSpeed(unit)
 
----------------------------
-- Update cloaker info and wait if units are lagging behind

local function updateCloakers()
    
	for unit, i in pairs(cloakers) do
     
		i.ux,i.uy,i.uz = spGetUnitPosition(unit)
 
		spGiveOrderToUnit(unit, CMD_REMOVE, {1}, {"alt"} )
		spGiveOrderToUnit(unit, CMD_INSERT, {1, CMD_SET_WANTED_MAX_SPEED, CMD.OPT_RIGHT, i.maxVel }, {"alt"} )
  
		local cQueue = spGetCommandQueue(unit, 1) 

		if cQueue then
			if (#cQueue ~= 0) and (i.folCount ~= 0) then
  
				local wait = (cQueue[1].id == CMD_WAIT)
	
				if wait then
	  
					wait = false
					for cid, j in pairs(i.cloakiees) do
						local dis = spGetUnitSeparation(unit,cid)
						if dis > i.reactiveRange then
							wait = true
						end
					end
	  
					if (not wait) then
						spGiveOrderToUnit(unit,CMD_WAIT,{},CMD_OPT_RIGHT)
					end
				else
	
					wait = false
					for cid, j in pairs(i.cloakiees) do
						local dis = spGetUnitSeparation(unit,cid)
						if dis > i.range then
							wait = true
						end
					end
	  
					if wait then
						spGiveOrderToUnit(unit,CMD_WAIT,{},CMD_OPT_RIGHT)
					end
				end
	  
			end
	
		end
	end
end


----------------------------
-- Update cloaker info and wait if units are lagging behind

local function updateFollowers()

  for unit, v in pairs(follower) do
  
	if (v.fol) then -- give move orders to cloakiees
	  local dis = spGetUnitSeparation(unit,v.fol)
	  if dis > v.range then
	    spGiveOrderToUnit(unit,CMD_MOVE,{cloakers[v.fol].ux,cloakers[v.fol].uy,cloakers[v.fol].uz},CMD_OPT_RIGHT)
	  elseif (cloakieeStopDis < dis) then
	    spGiveOrderToUnit(unit,CMD_MOVE,{cloakers[v.fol].ux,cloakers[v.fol].uy,cloakers[v.fol].uz},CMD_OPT_RIGHT)
	  else
	    spGiveOrderToUnit(unit,CMD_STOP,{},CMD_OPT_RIGHT)
	  end
	end
	
  end
  
end

-- update following and cloaker

function widget:GameFrame(n)
  
  if (n%15<1) then 
    updateCloakers()
	updateFollowers()
  end
  
end 


----------------------------
-- Add/remove cloaked and hold fire units.
-- Override and add units guarding cloakers

function widget:CommandNotify(id, params, options)
  
  local units = spGetSelectedUnits()
  
  
  for _,sid in ipairs(units) do
    if follower[sid] then
      local c = cloakers[follower[sid].fol]
	  c.cloakiees[sid] = nil
	  if c.maxVelID == sid then
	    c.maxVel = c.selfVel
	    c.maxVelID = -1
		spGiveOrderToUnit(follower[sid].fol, CMD_INSERT, {1, CMD_SET_WANTED_MAX_SPEED, CMD.OPT_RIGHT, c.selfVel }, {"alt"} )
	    for cid, j in pairs(c.cloakiees) do
	      if j.vel < c.maxVel then
		    c.maxVel = j.vel
		    c.maxVelID = cid
		  end
	    end
	  end
	  spGiveOrderToUnit(sid, CMD_FIRE_STATE, { follower[sid].firestate }, {})	
	  follower[sid] = nil
	  c.folCount = c.folCount-1
	end
  end

  if (id == CMD_GUARD) then

    local uid = params[1]
    for cid,v in pairs(cloakers) do
	  if (uid == cid) then
		for _,sid in ipairs(units) do
		  local ud = UnitDefs[spGetUnitDefID(sid)]
		  if ud.canMove and not ud.isFactory then
		    local firestate = spGetUnitStates(sid).firestate
			local speed = ud.speed/30
			if speed < v.maxVel then
			  v.maxVel = speed
			  v.maxVelID = sid
			end
		    follower[sid] = {
			fol = cid, 
			firestate = firestate, 
			vel = speed,
			range = v.range
			}
		    v.cloakiees[sid] = follower[sid]
			v.folCount = v.folCount+1
		    spGiveOrderToUnit(sid, CMD_FIRE_STATE, { 0 }, {})	
		  else
			spGiveOrderToUnit(sid, id, params, options)	
		  end
		end
		
		return true
		
      end
	end 
  
  end
 
end
  
-----------------------
--Add cloaker

function widget:UnitCreated(unitID, unitDefID, unitTeam)

  if unitTeam ~= team then
    return
  end

  local ud = UnitDefs[unitDefID]

  if (ud ~= nil) then
    
    for i, name in pairs(cloakerArray) do
	  if (ud.name == name) then
		local ux,uy,uz = spGetUnitPosition(unitID)
		local speed = ud.speed/30
		cloakers[unitID] = {id = unitID, ux = ux, uy = uy, uz = uz, 
		range = ud.jammerRadius-cloakRangeSafety, 
		reactiveRange = ud.jammerRadius-cloakReactivateRange, 
		cloakiees = {},
		folCount = 0,
		selfVel = speed, 
		maxVel = speed,
		maxVelID = -1
		}
		break
	  end
	end
	
  end

end

-----------------------
--Remove cloaker or follower

function widget:UnitDestroyed(unitID, unitDefID, unitTeam)

  local ud = UnitDefs[unitDefID]
  
  if cloakers[unitID] then -- remove cloaker
	for fid, j in pairs(cloakers[unitID].cloakiees) do
	  spGiveOrderToUnit(fid, CMD_FIRE_STATE, { follower[fid].firestate }, {})	
	  follower[fid] = nil
	end
	
	cloakers[unitID] = nil
	
  end
  
  if follower[unitID] then -- remove follower
	local c = cloakers[follower[unitID].fol]
	c.cloakiees[unitID] = nil
	if c.maxVelID == unitID then
	  c.maxVel = c.selfVel
	  c.maxVelID = -1
	  spGiveOrderToUnit(follower[unitID].fol, CMD_INSERT, {1, CMD_SET_WANTED_MAX_SPEED, CMD.OPT_RIGHT, c.selfVel }, {"alt"} )
	  for cid, j in pairs(c.cloakiees) do
	    if j.vel < c.maxVel then
		  c.maxVel = j.vel
		  c.maxVelID = cid
		end
	  end
	end
	follower[unitID] = nil
	c.folCount = c.folCount-1
	
  end

end

-----------------------
--Add/Remove cloaker or follower if given/taken

function widget:UnitTaken(unitID, unitDefID, oldTeam, newTeam)
  
  if (newTeam == team) then
	widget:UnitCreated(unitID, unitDefID, newTeam)
  end
  
  if (oldTeam == team) then
    widget:UnitDestroyed(unitID, unitDefID, newTeam)
  end
end

-----------------------
--Add cloaker names to array

function widget:Initialize() 
	if Spring.GetSpectatingState() or Spring.IsReplay() then
		Spring.Echo("<Cloaker Guard>: disabled for spectators")
		widgetHandler:RemoveWidget()
	end
	local units = spGetTeamUnits(team)
	for i, id in ipairs(units) do 
		widget:UnitCreated(id, spGetUnitDefID(id),team)
	end
end