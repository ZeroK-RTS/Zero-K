local REVERSE_COMPAT = not Spring.Utilities.IsCurrentVersionNewerThan(104, 1120)

local speedCache = {}

function Spring.Utilities.GetUnitRepeat(unitID)
	if REVERSE_COMPAT then
		local state = Spring.GetUnitStates(unitID)
		return state and state["repeat"]
	end

	local _,_,_,repeatState = Spring.GetUnitStates(unitID, false, true)
	return repeatState
end

function Spring.Utilities.GetUnitFireState(unitID)
	if REVERSE_COMPAT then
		local state = Spring.GetUnitStates(unitID)
		return state and state["firestate"]
	end

	local fireState = Spring.GetUnitStates(unitID, false)
	return fireState
end

function Spring.Utilities.GetUnitMoveState(unitID)
	if REVERSE_COMPAT then
		local state = Spring.GetUnitStates(unitID)
		return state and state["movestate"]
	end

	local _,moveState = Spring.GetUnitStates(unitID, false)
	return moveState
end

function Spring.Utilities.GetUnitActiveState(unitID)
	if REVERSE_COMPAT then
		local state = Spring.GetUnitStates(unitID)
		return state and state["active"]
	end

	local _,_,_,_,_,activeState = Spring.GetUnitStates(unitID, false, true)
	return activeState
end

function Spring.Utilities.GetUnitTrajectoryState(unitID)
	if REVERSE_COMPAT then
		local state = Spring.GetUnitStates(unitID)
		return state and state["trajectory"]
	end

	local _,_,_,_,_,_,trajectory = Spring.GetUnitStates(unitID, false, true)
	return trajectory
end

function Spring.Utilities.EstimateCurrentMaxSpeed(unitID, unitDefID)
	unitDefID = unitDefID or Spring.GetUnitDefID(unitID)
	local _, stunned, inbuild = Spring.GetUnitIsStunned(unitID)
	if stunned or inbuild then
		local health, maxHealth, paraDamage,_, buildProgress = Spring.GetUnitHealth(unitID)
		inbuild = not (buildProgress > 0.9)
		stunned = not (paraDamage and maxHealth and (maxHealth > 0) and paraDamage/maxHealth > 1.05)
	end
	
	local speedMult = (Spring.GetUnitRulesParam(unitID, "totalMoveSpeedChange") or 1)
	if speedMult < 1 then
		speedMult =  math.min(1, speedMult + 0.05)
	end
	speedMult = (inbuild and 0) or (stunned and 0) or speedMult
	if not speedCache[unitDefID] then
		local ud = UnitDefs[unitDefID]
		local speed = ud.speed/30
		if ud.customParams and ud.customParams.jump_speed then
			local jumpSpeed = tonumber(ud.customParams.jump_speed)
			if jumpSpeed and jumpSpeed/2 > speed then
				speed = jumpSpeed/2
			end
		end
		speedCache[unitDefID] = speed
	end
	
	return speedCache[unitDefID]*speedMult
end

function Spring.Utilities.CheckBit(name, number, bit)
	if not number then
		Spring.Echo("Name", name)
	end
	return number and (number%(2*bit) >= bit)
end

function Spring.Utilities.IsBitSet(number, bit)
	return number and (number%(2*bit) >= bit)
end

function Spring.Utilities.AndBit(number, bit)
	return number + ((Spring.Utilities.IsBitSet(number, bit) and 0) or bit)
end
