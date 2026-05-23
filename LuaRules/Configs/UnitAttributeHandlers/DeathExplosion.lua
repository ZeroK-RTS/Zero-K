local spSetUnitRulesParam=Spring.SetUnitRulesParam
local INLOS_ACCESS = {inlos = true}

GG.att_DeathExplodeMult={}
return {
    ---@type AttributesHandlerFactory
    DeathExplosion = {
        handledAttributeNames={deathExplode=true},
        new = function(unitId)
            return {
                newDataHandler = function()
	                local deathExplodeMult = 1

                    return {
                        fold = function(data)
                            deathExplodeMult = deathExplodeMult * (data.deathExplode or 1)
			
                        end,
                        apply = function()
	                        GG.att_DeathExplodeMult[unitId] = deathExplodeMult
	                        spSetUnitRulesParam(unitId, "deathExplodeMult", deathExplodeMult, INLOS_ACCESS)
                        end
                    }
                end,
                clear = function()
	                GG.att_DeathExplodeMult[unitId] = nil
                end
            }
        end
    }
}