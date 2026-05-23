
local INLOS_ACCESS = {inlos = true}

GG.att_RegenChange={}
return {
    ---@type AttributesHandlerFactory
    StaticAttributes = {
        handledAttributeNames = {healthRegen=true},
        new = function(unitID, unitDefID)

            return {
                newDataHandler = function(frame)
                    
	                local healthRegen = 1

                    return {
                        fold = function(data)
                            healthRegen = healthRegen*(data.healthRegen or 1)
                        end,
                        apply = function()
                            GG.att_RegenChange[unitID] = healthRegen
                        end
                    }
                end,
                clear = function()
                    GG.att_RegenChange[unitID] = nil
                    -- Reset logic can be added here if needed
                end
            }
        end
    }
}