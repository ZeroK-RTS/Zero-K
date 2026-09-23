-- ---@diagnostic disable: missing-return

---@class table:{[any]:any}
---@class list<T>:{[integer]:T}

---@class UnitId : integer
---@class UnitDefId:integer

---@class PlayerId:integer
---@class TeamId:integer
---@class AllyteamId:integer
--[==[
---@class timeSec:number

---@class frame:integer
---@operator div(framePerSec):timeSec
---@class framePerSec:integer
---@operator mul(timeSec):frame

---@class WldDist:number
---@operator div(frame):WldSpeed
---@operator add(WldDist):WldDist
---@operator add(WldSpeed):WldDist
---@alias WldxPos WldDist
---@alias WldyPos WldDist
---@alias WldzPos WldDist
--[=[
---@class WldxPos:number
---@operator div(frame):WldxVel
---@operator add(WldxPos):WldxPos
---@operator add(WldxVel):WldxPos
---@class WldyPos:number
---@operator div(frame):WldyVel
---@operator add(WldyPos):WldyPos
---@operator add(WldyVel):WldyPos
---@class WldzPos:number
---@operator div(frame):WldzVel
---@operator add(WldzPos):WldzPos
---@operator add(WldzVel):WldzPos
]=]

---@class WldSpeed:number
---@operator mul(frame):WldDist
---@operator unm:WldSpeed

---@alias WldxVel WldSpeed
---@alias WldyVel WldSpeed
---@alias WldzVel WldSpeed
]==]

---@type {[UnitDefId]:table}
UnitDefs={}

---@type {[string]:table}
UnitDefNames={}

---@class WeaponDefId:integer


---@type table<WeaponDefId,table>
WeaponDefs={}

---@type table<string,table>
WeaponDefNames={}

---@class ProjectileId:number

---@generic T
---@param v T
---@param recurse boolean|nil
---@param appendTo T|nil
---@return T
function Spring.Utilities.CopyTable(v,recurse,appendTo) end