---Just nil, number, string and boolean datatypes are allowed as arguments! NO tables, userdatas, ...
---@param ... nil|number|string|boolean
function SendToUnsynced(...)end

---@param teamID integer
---@param f function
---@param ... any
function CallAsTeam(teamID,f,...)end

---@param access {ctrl:number|nil,read:number|nil,select:number|nil}
---@param f function
---@param ... any
function CallAsTeam(access,f,...)end