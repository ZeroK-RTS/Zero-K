
local luaShaderDir = "LuaUI/Widgets/Include/"
local exposedFuncs = VFS.Include(luaShaderDir.."instancevboidtable.lua")

-- Note that this file is the worst.
makeInstanceVBOTable    = exposedFuncs.makeInstanceVBOTable   
clearInstanceTable      = exposedFuncs.clearInstanceTable     
makeVAOandAttach        = exposedFuncs.makeVAOandAttach       
locateInvalidUnits      = exposedFuncs.locateInvalidUnits     
resizeInstanceVBOTable  = exposedFuncs.resizeInstanceVBOTable 
pushElementInstance     = exposedFuncs.pushElementInstance    
popElementInstance      = exposedFuncs.popElementInstance     
getElementInstanceData  = exposedFuncs.getElementInstanceData 
uploadAllElements       = exposedFuncs.uploadAllElements      
uploadElementRange      = exposedFuncs.uploadElementRange     
compactInstanceVBO      = exposedFuncs.compactInstanceVBO     
drawInstanceVBO         = exposedFuncs.drawInstanceVBO        
countInvalidUnitIDs     = exposedFuncs.countInvalidUnitIDs    
makeCircleVBO           = exposedFuncs.makeCircleVBO          
makePlaneVBO            = exposedFuncs.makePlaneVBO           
makePlaneIndexVBO       = exposedFuncs.makePlaneIndexVBO      
makePointVBO            = exposedFuncs.makePointVBO           
makeRectVBO             = exposedFuncs.makeRectVBO            
makeRectIndexVBO        = exposedFuncs.makeRectIndexVBO       
makeConeVBO             = exposedFuncs.makeConeVBO            
makeCylinderVBO         = exposedFuncs.makeCylinderVBO        
makeBoxVBO              = exposedFuncs.makeBoxVBO             
makeSphereVBO           = exposedFuncs.makeSphereVBO          
