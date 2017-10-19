
-------------------------------------------------------------------------------------
-------------------------------------------------------------------------------------

function math.round(num, idp)
	return ("%." .. (((num==0) and 0) or idp or 0) .. "f"):format(num)
end

function math.cross_product (px, pz, ax, az, bx, bz)
	return ((px - bx)*(az - bz) - (ax - bx)*(pz - bz))
end

local abs						= math.abs
local strFormat 				= string.format


function ToSI(num, displaySign)
  if type(num) ~= 'number' then
	num = tonumber(num)
  end
  if (num == 0) then
    return "0"
  else
    local absNum = abs(num)
    if (absNum < 0.001) then
      return displaySign and strFormat("%+.1fu", 1000000 * num) or strFormat("%.1fu", 1000000 * num)
    elseif (absNum < 1) then
      return displaySign and strFormat("%+.1f", num) or strFormat("%.1f", num) 
    elseif (absNum < 1000) then
	  return displaySign and strFormat("%+.0f", num) or strFormat("%.0f", num) 
    elseif (absNum < 1000000) then
      return displaySign and strFormat("%+.1fk", 0.001 * num) or strFormat("%.1fk", 0.001 * num) 
    else
      return displaySign and strFormat("%+.1fM", 0.000001 * num) or strFormat("%.1fM", 0.000001 * num) 
    end
  end
end



function ToSIPrec(num) -- more presise
  if type(num) ~= 'number' then
	num = tonumber(num)
  end
 
  if (num == 0) then
    return "0"
  else
    local absNum = abs(num)
    if (absNum < 0.001) then
      return strFormat("%.2fu", 1000000 * num)
    elseif (absNum < 1) then
      return strFormat("%.2f", num)
    elseif (absNum < 10) then
      return strFormat("%.2f", num)
	
	elseif (absNum < 1000) then
      return strFormat("%.0f", num)
	  --return num
	  
    elseif (absNum < 1000000) then
      return strFormat("%.1fk", 0.001 * num)
    else
      return strFormat("%.1fM", 0.000001 * num)
    end
  end
end

-- accepts an array of polygons (where a polygon is an array of {x, z} vertices), and returns an array of counterclockwise triangles
function math.triangulate(polies)
	local triangles = {}
	for j = 1, #polies do
		local polygon = polies[j]

		-- find out clockwisdom
		polygon[#polygon+1] = polygon[1]
		local clockwise = 0
		for i = 2, #polygon do
			clockwise = clockwise + (polygon[i-1][1] * polygon[i][2]) - (polygon[i-1][2] * polygon[i][1])
		end
		polygon[#polygon] = nil
		local clockwise = (clockwise < 0)

		-- the van gogh concave polygon triangulation algorithm: cuts off ears
		-- is pretty shitty at O(V^3) but was easy to code and it's typically only done once anyway
		while (#polygon > 2) do

			-- get a candidate ear
			local triangle
			local c0, c1, c2 = 0, 0, 0
			local candidate_ok = false
			while not candidate_ok do

				c0 = c0 + 1
				c1, c2 = c0+1, c0+2
				if c1 > #polygon then c1 = c1 - #polygon end
				if c2 > #polygon then c2 = c2 - #polygon end
				triangle = {
					polygon[c0][1], polygon[c0][2],
					polygon[c1][1], polygon[c1][2],
					polygon[c2][1], polygon[c2][2],
				}

				-- make sure the ear is of proper rotation but then make it counter-clockwise
				local dir = math.cross_product(triangle[5], triangle[6], triangle[1], triangle[2], triangle[3], triangle[4])
				if ((dir < 0) == clockwise) then
					if dir > 0 then
						local temp = triangle[5]
						triangle[5] = triangle[3]
						triangle[3] = temp
						temp = triangle[6]
						triangle[6] = triangle[4]
						triangle[4] = temp
					end

					-- check if no point lies inside the triangle
					candidate_ok = true
					for i = 1, #polygon do
						if (i ~= c0 and i ~= c1 and i ~= c2) then
							local current_pt = polygon[i]
							if  (math.cross_product(current_pt[1], current_pt[2], triangle[1], triangle[2], triangle[3], triangle[4]) < 0)
							and (math.cross_product(current_pt[1], current_pt[2], triangle[3], triangle[4], triangle[5], triangle[6]) < 0)
							and (math.cross_product(current_pt[1], current_pt[2], triangle[5], triangle[6], triangle[1], triangle[2]) < 0)
							then
								candidate_ok = false
							end
						end
					end
				end
			end

			-- cut off ear
			triangles[#triangles+1] = triangle
			table.remove(polygon, c1)
		end
	end

	return triangles
end