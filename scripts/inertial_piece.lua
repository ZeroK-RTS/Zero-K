-- Spring.GetHeadingFromVector ( number x, number z )

-- Spring.GetUnitDirection ( number unitID )

-- Spring.GetUnitHeading ( number unitID )

if not Spring.UnitScript.inertial_piece then
    -- local spGetUnitHeading=Spring.GetUnitHeading
    local spGetUnitRotation=Spring.GetUnitRotation
    local spGetPieceRotation=Spring.UnitScript.GetPieceRotation

    local inertial_piece={}
    Spring.UnitScript.inertial_piece=inertial_piece
    -- local suunit=Spring.UnitScript.units
    
    inertial_piece.new=function (unitId,piece,heading_coefficient_ratio,pitch_coefficient_ratio,others)
        -- local piece_rotate_speed=suunit[unitId].pieceRotSpeeds[piece]
        -- local piece_rotate_target=suunit[unitId].pieceRotTargets[piece]

        others=others or {}
        local heading_change_ratio=1-(heading_coefficient_ratio or 0)
        local pitch_change_ratio=1-(pitch_coefficient_ratio or 0)
        --local piece_heading=others.piece_heading or 0
        --local piece_pitch=others.piece_pitch or 0
        local unit_old_pitch,unit_old_heading=spGetUnitRotation(unitId)
        local function KeepRotation()
            while true do
                Sleep(1000/30)
                local unit_pitch,unit_heading=spGetUnitRotation(unitId)

                local unit_heading_delta=unit_heading-unit_old_heading
				local unit_pitch_delta=unit_pitch-unit_old_pitch

                local piece_heading_change=-unit_heading_delta*heading_change_ratio
				local piece_pitch_change=-unit_pitch_delta*pitch_change_ratio

                local piece_pitch,piece_heading,_=spGetPieceRotation(piece)
                --[=[
                local piece_rotate_speed_x=piece_rotate_speed[x_axis]
                local piece_rotate_target_x
                ]=]
                Turn(piece,y_axis,piece_heading-piece_heading_change)
                Turn(piece,x_axis,piece_pitch-piece_pitch_change)
                unit_old_pitch,unit_old_heading=unit_pitch,unit_heading
                --[=[
                if piece_rotate_speed_x~=0 then
                    Turn(piece,x_axis,)
                end]=]
            end
        end
        StartThread(KeepRotation)
        -- local o={}
        -- return o
    end

end
return Spring.UnitScript.inertial_piece