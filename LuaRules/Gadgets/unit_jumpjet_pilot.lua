--------------------------------------------------------------------------------
--------------------------------------------------------------------------------

if (not gadgetHandler:IsSyncedCode()) then
  return false
end

function gadget:GetInfo()
  return {
    name      = "Jumpjet Pilot",
    desc      = "Steers leapers",
    author    = "quantum",
    date      = "Jul 24, 2007",
    license   = "GNU GPL, v2 or later",
    layer     = 0,
    enabled   = false  --  loaded by default?
  }
end

--------------------------------------------------------------------------------
--------------------------------------------------------------------------------

local aStar = VFS.Include "LuaRules/Gadgets/astar.lua"

--------------------------------------------------------------------------------
--------------------------------------------------------------------------------

include("LuaRules/Configs/customcmds.h.lua")

local leaperDefID = UnitDefNames.chicken_leaper.id
local pathCache = {}
local threadCyclesPerFrame = 1
local cyclesPerYield = 25 -- A* cycles per thread cycle

local threads = aStar.NewPriorityQueue()

local function StartCoroutine(action)
  threads.Insert(coroutine.create(action), 1)
end

local function ResumeThreads()
  --[[
  Pathfinding jobs are stored in a priority queue with the priority being the number of nodes processed.
  If a pathfinding job has already been running for a long time, there is probably no solution so this
  makes sure it wont delay jobs that are more likely to succeed.
  ]]
  for _=1, threadCyclesPerFrame do
    if not threads[1] then
      return
    end
    local co = threads.Pop()
    local _, priority = assert(coroutine.resume(co))
    if priority then
      threads.Insert(co, priority)
    end
  end
end


--------------------------------------------------------------------------------
-- A* pathfinding
--------------------------------------------------------------------------------

gridSize = math.floor(350/2)

aStar.gridWidth = math.floor(Game.mapSizeX/gridSize)
aStar.gridHeight = math.floor(Game.mapSizeZ/gridSize)

function aStar.IsBlocked(id)
  local x, z = aStar.ToCoords(id)
  x, z = x*gridSize, z*gridSize
  return Spring.TestBuildOrder(leaperDefID, x, 0, z, 1) ~= 2
end


function aStar.GetNeighbors(id, goal)
  local x, y = aStar.ToCoords(id)
  local nodes = {
    -- half jump (8 directions)
    aStar.ToID{x-1, y}, 
    aStar.ToID{x, y-1},  
    aStar.ToID{x+1, y}, 
    aStar.ToID{x, y+1}, 
    aStar.ToID{x-1, y-1},  
    aStar.ToID{x-1, y+1}, 
    aStar.ToID{x+1, y+1}, 
    aStar.ToID{x+1, y-1},
    -- full jump (8 directions)
    aStar.ToID{x-2, y},
    aStar.ToID{x, y-2},  
    aStar.ToID{x+2, y}, 
    aStar.ToID{x, y+2}, 
    aStar.ToID{x-2, y-2},  
    aStar.ToID{x-2, y+2}, 
    aStar.ToID{x+2, y+2}, 
    aStar.ToID{x+2, y-2},
  }
  local passable = {}
  local passableCount = 0
  for nodeIndex=1, 8+8 do
    local node = nodes[nodeIndex]
    -- assume the goal is passable
    if not aStar.IsBlocked(node) or node == goal then
      passableCount = passableCount + 1
      passable[passableCount] = node
    end
  end
  return passable
end


function aStar.GetDistanceEstimate(a, b) -- heuristic estimate of distance to goal
  local x1, y1 = aStar.ToCoords(a)
  local x2, y2 = aStar.ToCoords(b)
  return ((x2-x1)^2+(y2-y1)^2)^0.5 -- linear distance
end

--------------------------------------------------------------------------------
--------------------------------------------------------------------------------


function aStar.GetDistance(a, b) -- distance between two directly connected nodes (squares if in a grid)
  return 1 -- jumps always take the same time (iirc)
end

function gadget:AllowCommand_GetWantedCommand()	
	return true
end

function gadget:AllowCommand_GetWantedUnitDefID()	
	return {[leaperDefID] = true}
end

function gadget:AllowCommand(unitID, unitDefID, unitTeam, cmdID, cmdParams, cmdOptions, cmdTag, synced)
  if noRecursion then
    return true
  end
  if unitDefID == leaperDefID and (cmdID == CMD.MOVE or cmdID == CMD_RAW_MOVE or cmdID == CMD_RAW_BUILD or cmdID == CMD.FIGHT) then
    local startX, startZ
    if cmdOptions.shift then -- queue, use last queue position
      local queue = Spring.GetCommandQueue(unitID, -1)
      for i=#queue, 1, -1 do
        if #(queue[i].params) == 3 then -- todo: be less lazy
          startX, startZ = queue[i].params[1], queue[i].params[3]
          break
        end
      end
    end
    if not startX or not startZ then
      startX, _, startZ = Spring.GetUnitPosition(unitID)
    end
    local start = aStar.ToID{math.floor(startX/gridSize), math.floor(startZ/gridSize)}
    local goal = aStar.ToID{math.floor(cmdParams[1]/gridSize), math.floor(cmdParams[3]/gridSize)}

    StartCoroutine(function()
      if (not Spring.GetUnitIsDead(unitID)) then
        return;
      end

      local path
      -- if the cached path shows "no path found" (false), abort
      if pathCache[start] and pathCache[start][goal] ~= nil then
        path = pathCache[start][goal]
      else
        path = aStar.GetPath(start, goal, cyclesPerYield)

        -- cache the found path
        if pathCache[start] then
          pathCache[start][goal] = path
        else
          pathCache[start] = {[goal] = path}
        end
      end

      -- if the computed path shows "no path found" (false), abort
      if Spring.GetUnitIsDead(unitID) and not path then
        Spring.GiveOrderToUnit(unitID, CMD.STOP, {}, cmdOptions.shift and CMD.OPT_SHIFT or 0)
        return
      end

      -- give the orders
      if Spring.GetUnitIsDead(unitID) and not cmdOptions.shift then
        Spring.GiveOrderToUnit(unitID, CMD.STOP, {}, 0)
      end
      for nodeIndex=2, #path do -- skip first node
        local node = path[nodeIndex]
        local x, z = aStar.ToCoords(node)
        x, z = x*gridSize, z*gridSize
        local y = Spring.GetGroundHeight(x, z)
        if Spring.GetUnitIsDead(unitID) then Spring.GiveOrderToUnit(unitID, CMD_JUMP, {x, y, z}, CMD.OPT_SHIFT) end
      end
      if Spring.GetUnitIsDead(unitID) then Spring.GiveOrderToUnit(unitID, CMD_JUMP, {cmdParams[1], cmdParams[2], cmdParams[3]}, CMD.OPT_SHIFT) end
    end)
    return false -- reject original command, we're handling it
  end
  
  return true -- other order
end

function gadget:GameFrame(frameNumber)
  -- clear the path cache every minute
  if frameNumber % (30*60*1) == 0 then
    pathCache = {}
  end
  ResumeThreads()
end
