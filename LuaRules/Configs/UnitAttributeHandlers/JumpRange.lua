local spSetUnitRulesParam=Spring.SetUnitRulesParam
local INLOS_ACCESS = {inlos = true}

GG.att_JumpRangeChange={}
return {
    ---@type AttributesHandlerFactory
    JumpRange = {
        handledAttributeNames={
            build=true
        },
        new = function(unitID, unitDefID)
            return {
                newDataHandler = function(frame)
                    local jumpRangeMult = 1

                    return {
                        fold = function(data)
                            jumpRangeMult = jumpRangeMult * (data.jumpRange or 1)
                        end,
                        apply = function()
	                        GG.att_JumpRangeChange[unitID] = jumpRangeMult
	                        spSetUnitRulesParam(unitID, "jumpRangeMult", jumpRangeMult, INLOS_ACCESS)
                        end
                    }
                end,
                clear = function()
                    GG.att_JumpRangeChange[unitID] = nil
                    -- Reset logic can be added here if needed
                end
            }
        end
    }
}