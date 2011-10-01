function widget:GetInfo()
  return {
    name      = "Brute Force Keep Target",
    desc      = "Simple and slowest usage of target on the move",
    author    = "Google Frog",
    date      = "29 Sep 2011",
    license   = "GNU GPL, v2 or later",
    layer     = 0,
    enabled   = false  --  loaded by default?
  }
end

local CMD_UNIT_SET_TARGET = 34923
local CMD_UNIT_CANCEL_TARGET = 34924

function widget:CommandNotify(id, params, options)
    if (id == CMD.ATTACK) then
        local units = Spring.GetSelectedUnits()
        for i = 1, #units do
            Spring.GiveOrderToUnit(units[i],CMD_UNIT_SET_TARGET,params,{})
        end
    elseif (id == CMD.STOP) then
        local units = Spring.GetSelectedUnits()
        for i = 1, #units do
            Spring.GiveOrderToUnit(units[i],CMD_UNIT_CANCEL_TARGET,params,{})
        end
    end
end 