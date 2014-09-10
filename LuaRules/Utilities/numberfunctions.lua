
-------------------------------------------------------------------------------------
-------------------------------------------------------------------------------------

function math.round(num, idp)
	return ("%." .. (((num==0) and 0) or idp or 0) .. "f"):format(num)
end



local abs						= math.abs
local strFormat 				= string.format


function ToSI(num, displaySign)
  if type(num) ~= 'number' then
	return 'ToSI wacky error #55'
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


--[[
local function ToSIPrec(num) -- more presise
  if type(num) ~= 'number' then
	return 'Tooltip wacky error #56'
  end
 
  if (num == 0) then
    return "0"
  else
    local absNum = abs(num)
    if (absNum < 0.001) then
      return strFormat("%.2fu", 1000000 * num)
    elseif (absNum < 1) then
      return strFormat("%.2f", num)
    elseif (absNum < 1000) then
      return strFormat("%.1f", num)
	  --return num
    elseif (absNum < 1000000) then
      return strFormat("%.2fk", 0.001 * num)
    else
      return strFormat("%.2fM", 0.000001 * num)
    end
  end
end
--]]