
local spSetUnitRulesParam=Spring.SetUnitRulesParam
local INLOS_ACCESS = {inlos = true}
local spSetUnitSensorRadius=Spring.SetUnitSensorRadius

local function tobool(val)
	local t = type(val)
	if (t == 'nil') then
		return false
	elseif (t == 'boolean') then
		return val
	elseif (t == 'number') then
		return (val ~= 0)
	elseif (t == 'string') then
		return ((val ~= '0') and (val ~= 'false'))
	end
	return false
end

---@type {[string|number]:AttributesHandlerFactory}
return{
    ---@type AttributesHandlerFactory
    SensorAndJamm={
        handledAttributeNames={
            setRadar=true,setSonar=true,setJammer=true,setSight=true,sense=true,abilityDisabled=true
        },
        new=function (unitID,unitDefID)
            local ud=UnitDefs[unitDefID]
            local udSightDistance= ud.sightDistance
            local udRadarDistance= ud.radarDistance
			local udSonarDistance =  ud.sonarDistance
            local udSonarCanDisable = tobool(ud.customParams.sonar_can_be_disabled)
            local udRadarDistanceJam = ud.radarDistanceJam
            
            local senseMultCur = 1
            local setRadarCur = false
            local setSonarCur = false
            local setJammerCur = false
            local setSightCur = false

            local abilityDisabledCur=false
            ---@type AttributesHandler
            return{
                newDataHandler=function (frame)
                    local senseMult = 1
                    ---@type nil|number
                    local radarOverride = nil
                    ---@type nil|number
                    local sonarOverride = nil
                    ---@type nil|number
                    local jammerOverride = nil
                    ---@type nil|number
                    local sightOverride = nil
                    ---@type nil|boolean
                    local abilityDisabled=nil

                    ---@type AttributesDataHandler
                    return {
                        ---@param data {abilityDisabled:boolean,sense:number?,setRadar:number?,setJammer:number?,setSonar:number?,setSight:number?}
                        fold=function (data)
                            senseMult=senseMult*(data.sense or 1)
                            radarOverride=radarOverride or data.setRadar
                            sonarOverride=sonarOverride or data.setSonar
                            jammerOverride=jammerOverride or data.setJammer
                            sightOverride=sightOverride or data.setSight
                            abilityDisabled=abilityDisabled or data.abilityDisabled

                        end,
                        apply=function ()
	                        spSetUnitRulesParam(unitID, "senseMult", senseMult, INLOS_ACCESS)
                            if senseMult~=senseMultCur or radarOverride~=setRadarCur or sonarOverride~=setSonarCur or jammerOverride~=setJammerCur or sightOverride~=setSightCur or abilityDisabledCur~=abilityDisabled then
                                
                                local abilityMult=(not abilityDisabled) and 1 or 0

                                if radarOverride or udRadarDistance>0 then
                                    spSetUnitSensorRadius(unitID, "radar", abilityMult*(radarOverride or udRadarDistance)*senseMult)
                                end

                                if sonarOverride or udSonarDistance then
                                    local sonarAbilityMult=1
                                    if udSonarCanDisable and abilityDisabled then
                                        sonarAbilityMult=0
                                    end
                                    --sonarCanDisable and abilityMult or 1
                                    --there will be a day for humanity to be cooked by this
                                    spSetUnitSensorRadius(unitID, "sonar", (sonarAbilityMult)*(sonarOverride or udSonarDistance)*senseMult)
                                end
                                if jammerOverride or udRadarDistanceJam then
                                    spSetUnitSensorRadius(unitID, "radarJammer", abilityMult*(jammerOverride or udRadarDistanceJam)*senseMult)
                                end
                                spSetUnitSensorRadius(unitID, "los", (sightOverride or udSightDistance)*senseMult)
                                spSetUnitSensorRadius(unitID, "airLos", (sightOverride or udSightDistance)*senseMult)
                            end
                        end
                    }
                end,
                clear=function ()
                    
                end
            }
        end
    }
}