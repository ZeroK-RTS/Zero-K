local WACKY_CONVERSION_FACTOR_1 = 2184.53

local workingGroundMoveType = true -- not ((Spring.GetModOptions() and (Spring.GetModOptions().pathfinder == "classic") and true) or false)

local getMovetype = Spring.Utilities.getMovetype

local spMoveCtrlGetTag=Spring.MoveCtrl.GetTag

local spSetAirMoveTypeData=Spring.MoveCtrl.SetAirMoveTypeData
local spSetGunshipMoveTypeData=Spring.MoveCtrl.SetGunshipMoveTypeData
local spSetGroundMoveTypeData=Spring.MoveCtrl.SetGroundMoveTypeData

local spSetUnitCOBValue = Spring.SetUnitCOBValue

local math_max=math.max

local spGetUnitPosition=Spring.GetUnitPosition
local spGetGroundHeight=Spring.GetGroundHeight
local spSetUnitVelocity=Spring.SetUnitVelocity

local spSetUnitRulesParam=Spring.SetUnitRulesParam
local INLOS_ACCESS = {inlos = true}

GG.att_MoveChange={}

return {
    ---@type AttributesHandlerFactory
    MovementSpeed = {
        handledAttributeNames={
            move=true,turn=true,accel=true
        },
        new = function(unitID, unitDefID)
            local ud = UnitDefs[unitDefID]
            local moveData = Spring.GetUnitMoveTypeData(unitID)

            local origSpeed = ud.speed
            local origReverseSpeed = (moveData.name == "ground") and moveData.maxReverseSpeed or ud.speed
            local origTurnRate = ud.turnRate
            local origTurnAccel = (ud.turnRate or 1) * (ud.customParams.turn_accel_factor or 1)
            local origMaxRudder = ud.maxRudder
            local origMaxAcc = ud.maxAcc
            local origMaxDec = ud.maxDec
            local movetype = getMovetype(ud)

            local speedFactorCur = 1
            local turnAccelFactorCur = 1
            local maxAccelerationFactorCur = 1

            return {
                newDataHandler = function(frame)
                    local speedFactor = 1
                    local turnAccelFactor = 1
                    local maxAccelerationFactor = 1

                    return {
                        fold = function(data)
                            speedFactor = speedFactor * (data.move or 1)
                            turnAccelFactor = turnAccelFactor * (data.turn or data.move or 1)
                            maxAccelerationFactor = maxAccelerationFactor * (data.accel or data.move or 1)
                        end,
                        apply = function()
                            
	                        GG.att_MoveChange[unitID] = speedFactor
                            spSetUnitRulesParam(unitID, "totalMoveSpeedChange", speedFactor, INLOS_ACCESS)
                            if speedFactor ~= speedFactorCur or turnAccelFactor ~= turnAccelFactorCur or maxAccelerationFactor ~= maxAccelerationFactorCur then
                                if spMoveCtrlGetTag(unitID) ~= nil then
                                    return
                                end

                                local decFactor = maxAccelerationFactor
                                local isSlowed = (speedFactor < 1)
                                if isSlowed then
                                    decFactor = 1000
                                end
                                speedFactor = math_max(speedFactor, 0)
                                turnAccelFactor = math_max(turnAccelFactor, 0)
                                local turnFactor = math_max(turnAccelFactor, 0.001)
                                maxAccelerationFactor = math_max(maxAccelerationFactor, 0.001)

                                if speedFactor == 0 then
                                    local x, y, z = spGetUnitPosition(unitID)
                                    if x then
                                        local h = spGetGroundHeight(x, z)
                                        if h and h >= y then
                                            spSetUnitVelocity(unitID, 0, 0, 0)
                                        end
                                    end
                                end

                                if movetype == 0 then -- Air
                                    turnFactor = (speedFactor > 0) and (turnFactor / speedFactor) or 1
                                    local attribute={
                                        maxSpeed = origSpeed * speedFactor,
                                        maxAcc = origMaxAcc * maxAccelerationFactor,
                                        maxRudder = origMaxRudder * turnFactor,
                                    }
                                    spSetAirMoveTypeData(unitID, attribute)
                                    spSetAirMoveTypeData(unitID, attribute)
                                elseif movetype == 1 then -- Gunship
                                    spSetGunshipMoveTypeData(unitID, {
                                        maxSpeed = origSpeed * speedFactor,
                                        turnRate = origTurnRate * turnFactor,
                                        accRate = origMaxAcc * maxAccelerationFactor,
                                        decRate = origMaxDec * maxAccelerationFactor,
                                    })
                                    GG.ForceUpdateWantedMaxSpeed(unitID, unitDefID)
                                elseif movetype == 2 then -- Ground
                                    if workingGroundMoveType then
                                        local accRate = origMaxAcc * maxAccelerationFactor
                                        if isSlowed and accRate > speedFactor then
                                            accRate = speedFactor
                                        end
                                        spSetGroundMoveTypeData(unitID, {
                                            maxSpeed = origSpeed * speedFactor,
                                            maxReverseSpeed = (isSlowed and 0) or origReverseSpeed,
                                            turnRate = origTurnRate * turnFactor,
                                            accRate = accRate,
                                            decRate = origMaxDec * decFactor,
                                            turnAccel = origTurnAccel * turnAccelFactor,
                                        })
                                        GG.ForceUpdateWantedMaxSpeed(unitID, unitDefID)
                                        
                                    else
                                        spSetUnitCOBValue(unitID, COB.MAX_SPEED, math.ceil(origSpeed*speedFactor*WACKY_CONVERSION_FACTOR_1))

                                    end
                                end

                                speedFactorCur = speedFactor
                                turnAccelFactorCur = turnAccelFactor
                                maxAccelerationFactorCur = maxAccelerationFactor
                            end
                        end
                    }
                end,
                clear = function()
                    GG.att_MoveChange[unitID] = nil
                    -- Reset logic can be added here if needed
                end
            }
        end
    }
}