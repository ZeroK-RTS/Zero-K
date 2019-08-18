-- $Id$

local objects = {
	"behepine_regular_2.s3o",
	"behepine_regular_3.s3o",
	"behepine_regular_1.s3o",

	"behepine_brown_1.s3o",
	"behepine_brown_2.s3o",
	"behepine_brown_3.s3o",
}

local treeDefs = {}
local function CreateTreeDef(i)
  treeDefs["treetype" .. i] = {
     description = [[Tree]],
     blocking    = true,
     burnable    = true,
     reclaimable = true,
     energy      = 25,
     damage      = 5,
     metal       = 0,
     reclaimTime = 25,
     mass        = 20,
     object = objects[(i % #objects) + 1] ,
     footprintX  = 2,
     footprintZ  = 2,
     collisionVolumeScales = [[20 42 20]],
     collisionVolumeType = [[cylY]],

     customParams = {
       mod = true,
     },
  }
end

for i=0,20 do
  CreateTreeDef(i)
end

--------------------------------------------------------------------------------
--------------------------------------------------------------------------------

return lowerkeys( treeDefs )

--------------------------------------------------------------------------------
--------------------------------------------------------------------------------
