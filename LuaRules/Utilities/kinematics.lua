local kinematics = {}
local sqrt = math.sqrt

kinematics.TimeToHeight = function(velY, accel, height, multi)
  local root = sqrt((velY * velY) - (2 * accel * height))
  return (-velY + (root * multi)) / accel
end

return kinematics
