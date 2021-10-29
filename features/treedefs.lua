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

--[[ In theory it's possible to have treetype16 or higher.
     However in practice Spring struggles to render trees
     higher than 15, for which reason map compilers don't
     allow trees higher than that, in turn making it hard
     to find a map with those. ]]
for i=0,15 do
  CreateTreeDef(i)
end

--------------------------------------------------------------------------------
--------------------------------------------------------------------------------

return lowerkeys( treeDefs )

--------------------------------------------------------------------------------
--------------------------------------------------------------------------------
