local spSetUnitRulesParam=Spring.SetUnitRulesParam

return {
    ---@type AttributesHandlerFactory
    AbilityDisabled = {
        handledAttributeNames={abilityDisabled=true},
        new = function(unitID, unitDefID)
            local abilityDisabledCur = false

            return {
                newDataHandler = function(frame)
                    local abilityDisabled = false

                    return {
                        fold = function(data)
                            abilityDisabled = abilityDisabled or data.abilityDisabled
                        end,
                        apply = function()
                            if abilityDisabled ~= abilityDisabledCur then
                                spSetUnitRulesParam(unitID, "att_abilityDisabled", abilityDisabled and 1 or 0)
                                abilityDisabledCur = abilityDisabled
                            end
                        end
                    }
                end,
                clear = function()
                    -- Reset logic can be added here if needed
                end
            }
        end
    }
}