-- Spring.GetHeadingFromVector ( number x, number z )

-- Spring.GetUnitDirection ( number unitID )

-- Spring.GetUnitHeading ( number unitID )



-- local function step_to_section_loop(value,step,destination,section_left,section_right)
-- 	local section_len=section_right-section_left
	
-- 	local destination_norm_dist=destination-value
-- 	local section_len_half=section_len/2

-- 	destination_norm_dist=limit_loop(destination_norm_dist,-section_len_half,section_len_half)
-- 	-- while destination_norm_dist>section_len_half do
-- 	-- 	destination_norm_dist=destination_norm_dist-section_len
-- 	-- end
	
-- 	-- while destination_norm_dist<-section_len_half do
-- 	-- 	destination_norm_dist=destination_norm_dist+section_len
-- 	-- end
	
-- 	if destination_norm_dist>0 then
-- 		if destination_norm_dist<step then
-- 			return destination_norm_dist
-- 		else
-- 			return step
-- 		end
-- 	else
-- 		if -destination_norm_dist<step then
-- 			return destination_norm_dist
-- 		else
-- 			return -step
-- 		end
-- 	end
	
-- end

-- local function step_to_section_loop_2(value,step_left,step_right,destination,section_left,section_right)
-- 	local section_len=section_right-section_left

-- 	local destinations={
-- 		destination-section_len,
-- 		destination,
-- 		destination+section_len
-- 	}

-- end

if not Spring.UnitScript.inertial_piece then
    -- local spGetUnitHeading=Spring.GetUnitHeading
    local spGetUnitRotation = Spring.GetUnitRotation
	local spGetUnitPieceDirection = Spring.GetUnitPieceDirection
	local spGetUnitPieceInfo = Spring.GetUnitPieceInfo
	local spGetUnitPieceMap = Spring.GetUnitPieceMap
    local spGetPieceRotation=Spring.UnitScript.GetPieceRotation
	local pi=math.pi
	local abs=math.abs
	local sgn=math.sgn
	local min=math.min
	local max=math.max
	local gameSpeed=Game.gameSpeed
	local function limit_loop(value,left,right)
		local len=right-left
		return (value-left)%len+left
	end

	local function angle_limit(value)
		return limit_loop(value,-pi,pi)
	end

	local function distance_toward_section_loop(value,destination,section_left,section_right)
		local section_len=section_right-section_left
		
		local destination_norm_dist=destination-value
		local section_len_half=section_len/2

		destination_norm_dist=limit_loop(destination_norm_dist,-section_len_half,section_len_half)
		return destination_norm_dist
	end

	local function merge_2_rotation(rotation1,speed1,rotation2,speed2)
		local sgn1=sgn(rotation1)
		local sgn2=sgn(rotation2)

		-- local speed=speed1*sgn1+speed2*sgn2
		-- if speed==0 then
		-- 	return 0,0
		-- end

		-- local t1=rotation1/speed
		-- local t2=rotation2/speed

		-- local fs1=min( speed1/gameSpeed, abs(rotation1) )
		-- local fs2=min( speed2/gameSpeed, abs(rotation2) )

		local t1=speed1 and min (abs(rotation1)/speed1, 1/gameSpeed) or 0
		local t2=speed2 and min (abs(rotation2)/speed2, 1/gameSpeed) or 0
		
		local dest=speed1*sgn1*t1+speed2*sgn2*t2
		
		
		return dest,dest*gameSpeed
	end

    local inertial_piece={}
    Spring.UnitScript.inertial_piece=inertial_piece
    -- local suunit=Spring.UnitScript.units
    
    inertial_piece.new=function (unitID,piece,coefficient_ratios,others)
        -- local piece_rotate_speed=suunit[unitId].pieceRotSpeeds[piece]
        -- local piece_rotate_destination=suunit[unitId].pieceRotdestinations[piece]

        others=others or {}
        -- local heading_change_ratio=1-(heading_coefficient_ratio or 0)
        -- local pitch_change_ratio=1-(pitch_coefficient_ratio or 0)
		local change_ratios={}
		for key, value in pairs(coefficient_ratios) do
			change_ratios[key]=value and (1-value)
		end
		
		local toGetRotation

		

		do
			-- local pm=spGetUnitPieceMap(unitID)
			-- if pm then
			-- 	local parent=pm[spGetUnitPieceInfo(unitID,piece).parent]
			-- 	toGetRotation=function ()
			-- 		return spGetUnitPieceDirection(unitID,parent)
			-- 	end
			-- else
			-- 	toGetRotation=function ()
			-- 		local ur=spGetUnitRotation(unitID)
			-- 		for k, v in pairs(ur) do
			-- 			ur[k]=-v
			-- 		end
			-- 		return ur
			-- 	end
				
			-- end
			toGetRotation=function ()
				local ur={spGetUnitRotation(unitID)}
				for k, v in pairs(ur) do
					ur[k]=-v
				end
				return ur
			end
		end
        --local piece_heading=others.piece_heading or 0
        --local piece_pitch=others.piece_pitch or 0
        -- local unit_old_pitch,unit_old_heading=spGetUnitRotation(unitId)

		---@type {[1]:number,[2]:number,[3]:number}
		local unit_old_rotations=toGetRotation()

		---@class TurnParam
		---@field destination number
		---@field speed number?

		---@type {[1]:TurnParam?,[2]:TurnParam?,[3]:TurnParam?}
		local extra_rotations={}

		local old_unit_rot_delta={0,0,0}

		local dbg_counter=5

		-- local unit_old_pitch_2,unit_old_heading_2=unit_old_pitch,unit_old_heading
        local function KeepRotation()
            while true do
                Sleep(1000/30)
				local unit_rotations=toGetRotation()
				do
					-- dbg_counter=dbg_counter-1
					-- if dbg_counter<0 then
					-- 	dbg_counter=5
						
					-- end
					-- local dbgstr=""
					-- for i = 1, 3 do
					-- 	dbgstr = dbgstr .. i .. ":" .. unit_rotations[i] .. ", "
					-- end
					-- Spring.Echo(dbgstr)
				end
				local piece_rotations={spGetPieceRotation(piece)}
				for axis = 1, 3 do
					local change_ratio=change_ratios[axis]
					local extra_rotation=extra_rotations[axis]
					if change_ratio and change_ratio~=0 then

						local unit_rot_delta = distance_toward_section_loop( unit_old_rotations[axis], unit_rotations[axis],-pi,pi )
						
						local piece_rot = angle_limit(piece_rotations[axis])

						local delta_compensation = angle_limit(unit_rot_delta-old_unit_rot_delta[axis])

						piece_rot=piece_rot - delta_compensation * change_ratio

						Turn(piece,axis,piece_rot)

						local piece_rot_delta = - unit_rot_delta * change_ratio
						local piece_rot_speed = piece_rot_delta*gameSpeed

						if piece_rot_speed~=0 then

							local final_destination=piece_rot + piece_rot_delta
							local final_speed=abs(piece_rot_speed)

							if extra_rotation then

								local extra_rotation_destination=extra_rotation.destination
								local extra_rotation_speed=extra_rotation.speed

								if extra_rotation_speed and extra_rotation_speed~=0 then
									
									local extra_rotation_dir=distance_toward_section_loop(piece_rot,extra_rotation_destination,-pi,pi)

									local m_dest,m_speed=merge_2_rotation(piece_rot_delta,final_speed,extra_rotation_dir,extra_rotation_speed)

									final_destination=piece_rot + m_dest
									final_speed = abs(m_speed)
								else
									Turn(piece,axis,extra_rotation_destination)
									final_destination=extra_rotation_destination + piece_rot_delta
								end

							end
							Turn(piece,axis,final_destination,final_speed)
						else
							if extra_rotation then
								Turn(piece,axis,extra_rotation.destination,extra_rotation.speed)
							end
						end
						
						old_unit_rot_delta[axis]=unit_rot_delta
					else
						if extra_rotation then
							Turn(piece,axis,extra_rotation.destination,extra_rotation.speed)
						end
					end
					-- extra_rotations[axis]=nil

				end
				unit_old_rotations=unit_rotations

                -- local unit_pitch,unit_heading=spGetUnitRotation(unitId)

                -- local unit_heading_delta=unit_heading-unit_old_heading
				-- local unit_pitch_delta=unit_pitch-unit_old_pitch

                -- local piece_heading_change=-unit_heading_delta*heading_change_ratio
				-- local piece_pitch_change=-unit_pitch_delta*pitch_change_ratio

                -- local piece_pitch,piece_heading,_=spGetPieceRotation(piece)
                -- --[=[
                -- local piece_rotate_speed_x=piece_rotate_speed[x_axis]
                -- local piece_rotate_destination_x
                -- ]=]
                -- Turn(piece,y_axis,piece_heading-piece_heading_change,piece_heading_change*Game.gameSpeed)
                -- Turn(piece,x_axis,piece_pitch-piece_pitch_change,piece_pitch_change*Game.gameSpeed)

				-- -- unit_old_pitch_2,unit_old_heading_2=unit_old_pitch,unit_old_heading

                -- unit_old_pitch,unit_old_heading=unit_pitch,unit_heading
                --[=[
                if piece_rotate_speed_x~=0 then
                    Turn(piece,x_axis,)
                end]=]
            end
        end
        StartThread(KeepRotation)
		local function AdditionalTurn(axis,destination,speed)
			extra_rotations[axis]={destination=destination,speed=speed}
		end
        local o={
			AdditionalTurn=AdditionalTurn
		}
        return o
    end

end
return Spring.UnitScript.inertial_piece