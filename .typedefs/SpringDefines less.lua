-- ---@diagnostic disable: missing-return
---@meta Spring

---@class table:{[any]:any}

Spring=Spring or {}
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

Game={}
--- framePerSec
Game.gameSpeed=30
Game.mapSizeX=512
Game.mapSizeZ=512

---@type {[UnitDefId]:table}
UnitDefs={}

---@alias WeaponDefName string

---@class WeaponDefId:integer
---@class WeaponDef --:{id:WeaponDefId,[any]:any}
---@field id WeaponDefId
---@field name WeaponDefName
---@field damageAreaOfEffect number
---@field damages list<number>
---@field flightTime number
---@field projectilespeed number
---@field range number
---@field reload number
---@field salvoSize number
---@field salvoDelay number
---@field projectiles number
---@field type string
---@field beamTTL number
---@field tracks boolean
---@field sprayAngle number
---@field craterMult number
---@field myGravity number
---@field customParams {[string]:string|number|nil}
---@field accuracy number
---@field turret boolean
---@field explosionSpeed number


---@type table<WeaponDefId,WeaponDef>
WeaponDefs={}

---@type table<WeaponDefName,WeaponDef>
WeaponDefNames={}


---@class ProjectileId:number


--[=[
---@class WldxVel:number
---@operator mul(frame):WldxPos
---@operator add(WldxVel):WldxVel
---@operator sub(WldxVel):WldxVel
---@operator unm:WldxVel
---@class WldyVel:number
---@operator mul(frame):WldyPos
---@operator add(WldyVel):WldyVel
---@operator sub(WldyVel):WldyVel
---@operator unm:WldyVel
---@class WldzVel:number
---@operator mul(frame):WldzPos
---@operator add(WldzVel):WldzVel
---@operator sub(WldzVel):WldzVel
---@operator unm:WldzVel
]=]

--- show message to console. `"game_message: ".. msg` to show `msg` at chat (client only)
---@param ... any message to be shown
function Spring.Echo(...)end

--CMD={}

---@generic T
---@param v T
---@param recurse boolean|nil
---@param appendTo T|nil
---@return T
function Spring.Utilities.CopyTable(v,recurse,appendTo) end