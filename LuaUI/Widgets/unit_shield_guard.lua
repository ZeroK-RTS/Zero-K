-- $Id$

function widget:GetInfo()
  return {
    name      = "Shield Guard",
    desc      = "Replaces guarding mobile shields with follow. Shields move at speed of slowest unit following and wait for stragglers.",
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

local shields = {}
local follower = {}

----------------------------
--  CONFIG

local shieldRangeSafety = 20 -- how close to the edge shields should wait at
local shieldReactivateRange = 100 -- how far from the edge shields should reactivate at
local shieldieeStopDis = 120 -- how far from the shield the shieldiees should stop

local shieldRadius = {core_spectre = 300}

local shieldArray = { 

  "core_spectre",

}


----------------------------
--  Removes all CMD_SET_WANTED_MAX_SPEED from unitIDs queue

--local function removeSetMaxSpeed(unit)
 
----------------------------
-- Update shield info and wait if units are lagging behind

local function updateShields()
    
  for unit, i in pairs(shields) do
     
    i.ux,i.uy,i.uz = spGetUnitPosition(unit)
 
    spGiveOrderToUnit(unit, CMD_REMOVE, {1}, {"alt"} )
    spGiveOrderToUnit(unit, CMD_INSERT, {1, CMD_SET_WANTED_MAX_SPEED, CMD.OPT_RIGHT, i.maxVel }, {"alt"} )
  
    local cQueue = spGetCommandQueue(unit) 

    if (#cQueue ~= 0) and (i.folCount ~= 0) then
  
      local wait = (cQueue[1].id == CMD_WAIT)
	
	  if wait then
	  
		wait = false
		for cid, j in pairs(i.shieldiees) do
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
        for cid, j in pairs(i.shieldiees) do
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


----------------------------
-- Update shield info and wait if units are lagging behind

local function updateFollowers()

  for unit, v in pairs(follower) do
  
	if (v.fol) then -- give move orders to shieldiees
	  local dis = spGetUnitSeparation(unit,v.fol)
	  if dis > v.range then
	    spGiveOrderToUnit(unit,CMD_MOVE,{shields[v.fol].ux,shields[v.fol].uy,shields[v.fol].uz},CMD_OPT_RIGHT)
	  elseif (shieldieeStopDis < dis) then
	    spGiveOrderToUnit(unit,CMD_MOVE,{shields[v.fol].ux,shields[v.fol].uy,shields[v.fol].uz},CMD_OPT_RIGHT)
	  else
	    spGiveOrderToUnit(unit,CMD_STOP,{},CMD_OPT_RIGHT)
	  end
	end
	
  end
  
end

-- update following and shield

function widget:GameFrame(n)
  
  if (n%15<1) then 
    updateShields()
	updateFollowers()
  end
  
end 


----------------------------
-- Add/remove shielded
-- Override and add units guarding shields

function widget:CommandNotify(id, params, options)
  
  local units = spGetSelectedUnits()
  
  
  for _,sid in ipairs(units) do
    if follower[sid] then
      local c = shields[follower[sid].fol]
	  c.shieldiees[sid] = nil
	  if c.maxVelID == sid then
	    c.maxVel = c.selfVel
	    c.maxVelID = -1
		spGiveOrderToUnit(follower[sid].fol, CMD_INSERT, {1, CMD_SET_WANTED_MAX_SPEED, CMD.OPT_RIGHT, c.selfVel }, {"alt"} )
	    for cid, j in pairs(c.shieldiees) do
	      if j.vel < c.maxVel then
		    c.maxVel = j.vel
		    c.maxVelID = cid
		  end
	    end
	  end
	  c.folCount = c.folCount-1
	  follower[sid] = nil
	end
  end

  if (id == CMD_GUARD) then

    local uid = params[1]
    for cid,v in pairs(shields) do
	  if (uid == cid) then
		for _,sid in ipairs(units) do
		  local ud = UnitDefs[spGetUnitDefID(sid)]
		  if ud.canMove and not ud.isFactory then
			local speed = ud.speed/30
			if speed < v.maxVel then
			  v.maxVel = speed
			  v.maxVelID = sid
			end
		    follower[sid] = {
			fol = cid, 
			vel = speed,
			range = v.range
			}
		    v.shieldiees[sid] = follower[sid]
			v.folCount = v.folCount+1
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
--Add shield

function widget:UnitCreated(unitID, unitDefID, unitTeam)

  if unitTeam ~= team then
    return
  end

  local ud = UnitDefs[unitDefID]

  if (ud ~= nil) then
    
    for i, name in pairs(shieldArray) do
	  if (ud.name == name) then
		local ux,uy,uz = spGetUnitPosition(unitID)
		local speed = ud.speed/30
		local shieldRange = shieldRadius[ud.name]
		shields[unitID] = {id = unitID, ux = ux, uy = uy, uz = uz, 
		range = shieldRange-shieldRangeSafety, 
		reactiveRange = shieldRange-shieldReactivateRange, 
		shieldiees = {},
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
--Remove shield or follower

function widget:UnitDestroyed(unitID, unitDefID, unitTeam)

  local ud = UnitDefs[unitDefID]
  
  if shields[unitID] then -- remove shield
	for fid, j in pairs(shields[unitID].shieldiees) do
	  follower[fid] = nil
	end
	
	shields[unitID] = nil
	
  end
  
  if follower[unitID] then -- remove follower
	local c = shields[follower[unitID].fol]
	c.shieldiees[unitID] = nil
	if c.maxVelID == unitID then
	  c.maxVel = c.selfVel
	  c.maxVelID = -1
	  spGiveOrderToUnit(follower[unitID].fol, CMD_INSERT, {1, CMD_SET_WANTED_MAX_SPEED, CMD.OPT_RIGHT, c.selfVel }, {"alt"} )
	  for cid, j in pairs(c.shieldiees) do
	    if j.vel < c.maxVel then
		  c.maxVel = j.vel
		  c.maxVelID = cid
		end
	  end
	end
	c.folCount = c.folCount-1
	follower[unitID] = nil
	
  end

end

-----------------------
--Add/Remove shield or follower if given/taken

function widget:UnitTaken(unitID, unitDefID, oldTeam, newTeam)
  
  if (newTeam == team) then
	widget:UnitCreated(unitID, unitDefID, newTeam)
  end
  
  if (oldTeam == team) then
    widget:UnitDestroyed(unitID, unitDefID, newTeam)
  end
  
end

-----------------------
--Add shield names to array

function widget:Initialize() 
  
  local units = spGetTeamUnits(team)
  for i, id in ipairs(units) do 
    widget:UnitCreated(id, spGetUnitDefID(id),team)
  end
	
end

