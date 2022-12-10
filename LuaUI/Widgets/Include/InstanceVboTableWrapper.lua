
local luaShaderDir = "LuaUI/Widgets/Include/"
VFS.Include(luaShaderDir.."instancevbotable.lua")

local exposedFuncs = {
	makeInstanceVBOTable    = makeInstanceVBOTable    ,
	clearInstanceTable      = clearInstanceTable      ,
	makeVAOandAttach        = makeVAOandAttach        ,
	locateInvalidUnits      = locateInvalidUnits      ,
	resizeInstanceVBOTable  = resizeInstanceVBOTable  ,
	pushElementInstance     = pushElementInstance     ,
	popElementInstance      = popElementInstance      ,
	getElementInstanceData  = getElementInstanceData  ,
	uploadAllElements       = uploadAllElements       ,
	uploadElementRange      = uploadElementRange      ,
	compactInstanceVBO      = compactInstanceVBO      ,
	drawInstanceVBO         = drawInstanceVBO         ,
	countInvalidUnitIDs     = countInvalidUnitIDs     ,
	makeCircleVBO           = makeCircleVBO           ,
	makePlaneVBO            = makePlaneVBO            ,
	makePlaneIndexVBO       = makePlaneIndexVBO       ,
	makePointVBO            = makePointVBO            ,
	makeRectVBO             = makeRectVBO             ,
	makeRectIndexVBO        = makeRectIndexVBO        ,
	makeConeVBO             = makeConeVBO             ,
	makeCylinderVBO         = makeCylinderVBO         ,
	makeBoxVBO              = makeBoxVBO              ,
	makeSphereVBO           = makeSphereVBO           ,
}

makeInstanceVBOTable    = nil
clearInstanceTable      = nil
makeVAOandAttach        = nil
locateInvalidUnits      = nil
resizeInstanceVBOTable  = nil
pushElementInstance     = nil
popElementInstance      = nil
getElementInstanceData  = nil
uploadAllElements       = nil
uploadElementRange      = nil
compactInstanceVBO      = nil
drawInstanceVBO         = nil
countInvalidUnitIDs     = nil
makeCircleVBO           = nil
makePlaneVBO            = nil
makePlaneIndexVBO       = nil
makePointVBO            = nil
makeRectVBO             = nil
makeRectIndexVBO        = nil
makeConeVBO             = nil
makeCylinderVBO         = nil
makeBoxVBO              = nil
makeSphereVBO           = nil

return exposedFuncs
