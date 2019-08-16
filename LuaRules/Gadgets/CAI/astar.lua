---------------------------------------------------------------------
--[[
author: quantum
GPL v2 or later

 http://www.policyalmanac.org/games/aStarTutorial.htm
 http://en.wikipedia.org/wiki/A*_search_algorithm

use: override IsBlocked, GetDistance, etc and run aStar.GetPath


-- example --------------------------------


local aStar = dofile"astar.lua"

aStar.gridHeight = 250
aStar.gridWidth = 250

aStar.IsBlocked = local function(id) return false end

function aStar.GetDistanceEstimate(a, b) -- heuristic estimate of distance to goal
  local x1, y1 = aStar.ToCoords(a)
  local x2, y2 = aStar.ToCoords(b)
  return math.max(math.abs(x2-x1), math.abs(y2-y1)) + math.min(math.abs(x2-x1), math.abs(y2-y1))/2*1.001
end

function aStar.GetDistance(a, b) -- distance between two directly connected nodes (squares if in a grid)
  local x1, y1 = aStar.ToCoords(a)
  local x2, y2 = aStar.ToCoords(b)
  if x1 == x2 or y1 == y2 then
    return 1
  else
    return 2^0.5
  end
end

local startID = aStar.ToID{1, 1}
local goalID = aStar.ToID{80, 90}
local path = aStar.GetPath(startID, goalID)
]]
---------------------------------------------------------------------
---------------------------------------------------------------------

local function GetSetCount(set)
  local count = 0
  for _ in pairs(set) do
    count = count + 1
  end
  return count
end


local function ReconstructPath(parents, node)
  local path = {}
  repeat
    path[#path + 1] = node
    node = parents[node]
  until not node
  -- reverse it
  local x, y, temp = 1, #path
  while x < y do
    temp = path[x]
    path[x] = path[y]
    path[y] = temp
    x, y = x + 1, y - 1
  end
  return path
end


local aStar = {
  -- set grid size
  gridWidth = 250,
  gridHeight = 250,
}


function aStar.NewPriorityQueue()
  local heap = {} -- binary heap
  local priorities = {}
  local heapCount = 0

  function heap.Insert(currentKey, currentPriority, currentPosition)
    if not currentPosition then -- we are inserting a new item, as opposed to changing the f value of an item already in the heap
      currentPosition = heapCount + 1
      heapCount = heapCount + 1
    end
    priorities[currentKey] = currentPriority
    heap[currentPosition] = currentKey
    while true do
      local parentPosition = math.floor(currentPosition/2)
      if parentPosition == 1 then
        break
      end
      local parentKey = heap[parentPosition]
      if parentKey and priorities[parentKey] > currentPriority then -- swap parent and current node
        heap[parentPosition] = currentKey
        heap[currentPosition] = parentKey
        currentPosition = parentPosition
      else
        break
      end
    end
  end

  function heap.UpdateNode(currentKey, currentPriority)
    for position=1, heapCount do
      local id = heap[position]
      if id == currentKey then
        heap.Insert(currentKey, currentPriority, position)
        break
      end
    end
  end
  
  function heap.Pop()
    local ret = heap[1]
    if not ret then
      error "queue is empty"
    end
    heap[1] = heap[heapCount]
    heap[heapCount] = nil
    heapCount = heapCount - 1
    local currentPosition = 1
    while true do
      local currentKey = heap[currentPosition]
      local currentPriority = priorities[currentKey]
      local child1Position = currentPosition*2
      local child1Key = heap[child1Position]
      if not child1Key then
        break
      end
      local child2Position = currentPosition*2 + 1
      local child2Key = heap[child2Position]
      if not child2Key then
        break
      end
      local child1F = priorities[child1Key]
      local child2F = priorities[child2Key]
      if currentPriority < child1F and currentPriority < child2F then
        break
      elseif child1F < child2F then
        heap[child1Position] = currentKey
        heap[currentPosition] = child1Key
        currentPosition = child1Position
      else
        heap[child2Position] = currentKey
        heap[currentPosition] = child2Key
        currentPosition = child2Position
      end
    end
    return ret, priorities[ret]
  end
  return heap
end


function aStar.ToID(coords) -- override this local function if necessary, converts grid coords to node id
  local x, y = coords[1], coords[2]
  return y * aStar.gridWidth + x
end


function aStar.ToCoords(id) -- override this local function if necessary, converts node id to grid coords
  return id % aStar.gridWidth, math.floor(id/aStar.gridWidth)
end


function aStar.GetDistance(a, b) -- override this local function, exact distance beween adjacent nodes a and b
  error"override this local function"
end


function aStar.IsBlocked(id)
  error"override this local function"
end


function aStar.GetNeighbors(id, goal) -- override this if the nodes are not arranged in a grid
  local x, y = aStar.ToCoords(id)
  local nodes = {
    aStar.ToID{x-1, y},
    aStar.ToID{x, y-1},
    aStar.ToID{x+1, y},
    aStar.ToID{x, y+1},
    aStar.ToID{x-1, y-1},
    aStar.ToID{x-1, y+1},
    aStar.ToID{x+1, y+1},
    aStar.ToID{x+1, y-1}
  }
  local passable = {}
  local passableCount = 0
  for nodeIndex=1, 8 do
    local node = nodes[nodeIndex]
    if not aStar.IsBlocked(node) then
      passableCount = passableCount + 1
      passable[passableCount] = node
    end
  end
  return passable
end


function aStar.GetDistanceEstimate(a, b) -- heuristic estimate of distance to goal
  error"override this local function"
end

function aStar.GetPathsThreaded(startID, goalID, cyclesBeforeYield)
  cyclesBeforeYield = cyclesBeforeYield or 1000
  return coroutine.create(aStar.GetPath)
end

function aStar.GetPath(startID, goalID, cyclesBeforeYield)
  local parents = {}
  local gScores = {} -- distance from start along optimal path
  local closedSet = {} --  nodes already evaluated
  local openHeap = aStar.NewPriorityQueue() -- binary heap of nodes by f score

  gScores[startID] = 0
  openHeap.Insert(startID, aStar.GetDistanceEstimate(startID, goalID))
  
  local cyclesFromLastYield = 0
  local cycleCounter = 0

  while openHeap[1] do
    -- threading
    cycleCounter = cycleCounter + 1
    if cyclesBeforeYield then
      cyclesFromLastYield = cyclesFromLastYield + 1
      if cyclesFromLastYield > cyclesBeforeYield then
        cyclesFromLastYield= 0
        coroutine.yield(cycleCounter)
      end
    end
    
    local currentNode = openHeap.Pop()
    if currentNode == goalID then -- goal reached
      return ReconstructPath(parents, currentNode), closedSet
    end
    closedSet[currentNode] = true
    for _, neighbor in ipairs(aStar.GetNeighbors(currentNode)) do
      if not closedSet[neighbor] then
        local tentativeGScore = gScores[currentNode] + aStar.GetDistance(currentNode, neighbor)
        if not gScores[neighbor] then
          parents[neighbor] = currentNode
          gScores[neighbor] = tentativeGScore
          openHeap.Insert(neighbor, gScores[neighbor] + aStar.GetDistanceEstimate(neighbor, goalID))
        elseif tentativeGScore < gScores[neighbor]  then
          parents[neighbor] = currentNode
          gScores[neighbor] = tentativeGScore
          openHeap.UpdateNode(neighbor, gScores[neighbor] + aStar.GetDistanceEstimate(neighbor, goalID))
        end
      end
    end
  end
  return false
end


return aStar
