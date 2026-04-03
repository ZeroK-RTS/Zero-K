
local spSetUnitRulesParam      = Spring.SetUnitRulesParam
local spSetUnitShieldState=Spring.SetUnitShieldState
local spGetUnitRulesParam=Spring.GetUnitRulesParam
GG.att_ShieldRegenChange={}
GG.att_ShieldMaxMult={}
return {
    ---@type AttributesHandlerFactory
    Shield = {
        handledAttributeNames={
            shieldDisabled=true,shieldRegen=true,shieldMax=true
        },
        new = function(unitID, unitDefID)
            local shieldDisabledCur = false

            return {
                newDataHandler = function(frame)
                    local shieldDisabled = false
                    local shieldRegen = 1
                    local shieldMaxMult = 1

                    return {
                        fold = function(data)
                            shieldDisabled = shieldDisabled or data.shieldDisabled
                            shieldRegen = shieldRegen*(data.shieldRegen or 1)
                            shieldMaxMult = shieldMaxMult*(data.shieldMax or 1)
                        end,
                        apply = function()
                            GG.att_ShieldRegenChange[unitID] = shieldRegen
                            GG.att_ShieldMaxMult[unitID] = shieldMaxMult
                            if shieldDisabled ~= shieldDisabledCur then
                                spSetUnitRulesParam(unitID, "att_shieldDisabled", shieldDisabled and 1 or 0)
                                if shieldDisabled then
                                    spSetUnitShieldState(unitID, -1, 0)
                                end
                                if spGetUnitRulesParam(unitID, "comm_shield_max") ~= 0 then
                                    local shieldNum = Spring.GetUnitRulesParam(unitID, "comm_shield_num")--[[@as number]] or -1
                                    spSetUnitShieldState(unitID, shieldNum, not shieldDisabled)
                                end
                                shieldDisabledCur = shieldDisabled
                            end
                        end
                    }
                end,
                clear = function()
                    GG.att_ShieldRegenChange[unitID] = nil
                    GG.att_ShieldMaxMult[unitID] = nil
                end
            }
        end
    }
}