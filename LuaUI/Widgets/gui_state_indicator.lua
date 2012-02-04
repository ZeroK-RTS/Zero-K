function widget:GetInfo()
  return {
    name      = "Unit State Indicator",
    desc      = "Press Q to display unit's move state & firestate",
    author    = "xponen (using trepan's code)",
    date      = "2012",
    license   = "GNU GPL, v2 or later",
    layer     = 5,
    enabled   = false  --  loaded by default?
  }
end
-------------------------------------------------------------------------------------
-------------------------------------------------------------------------------------
local glDepthTest      = gl.DepthTest
local glDepthMask      = gl.DepthMask
local glAlphaTest      = gl.AlphaTest
local glTexture        = gl.Texture
local glTexRect        = gl.TexRect
local glTranslate      = gl.Translate
local glBillboard      = gl.Billboard
local glDrawFuncAtUnit = gl.DrawFuncAtUnit

local GL_GREATER = GL.GREATER
-------------------------------------------------------------------------------------
-------------------------------------------------------------------------------------
local stateTexBase = "LuaUI\\Images\\commands\\states\\"
local fireStateTextures = {
  [1] = stateTexBase .. 'fire_hold.png',
  [2] = stateTexBase .. 'fire_return.png',
  [3] = stateTexBase .. 'fire_atwill.png',
}
local moveStateTextures = {
  [1] = stateTexBase .. 'move_hold.png',
  [2] = stateTexBase .. 'move_engage.png',
  [3] = stateTexBase .. 'move_roam.png',
}
local iconsize   = 33
local iconoffset = 14
local elapsedTime = 0
local waitDuration = 0.25
local unitHeight = {}
local moveStateTable = {}
local fireStateTable = {}
local pressQ = false
-------------------------------------------------------------------------------------
-------------------------------------------------------------------------------------
function widget:KeyPress(key, modifier, isRepeat)
	if key == 0x071 then --// reference: uikeys.txt
		pressQ = true
		elapsedTime = waitDuration
	end
end
function widget:KeyRelease(key, mods, label, unicode)
	if key == 0x071 then --// reference: uikeys.txt
		pressQ = false
	end
end

function widget:Update(n)
	if not pressQ then return end --//don't update if not pressing Q
	
	elapsedTime= elapsedTime + n
	if elapsedTime < waitDuration then --//periodic update at every 0.25 second
		return
	else elapsedTime = 0 end
	
	unitHeight = {}
	moveStateTable = {}
	fireStateTable = {}
	for i=1, 3 do --//initialize & empty the arrays
		moveStateTable[i] = {}
		fireStateTable[i] = {}
	end
	local visibleUnits = Spring.GetVisibleUnits(nil, nil, false)
	for i=1, #visibleUnits do
		local unitID = visibleUnits[i]
		local state = Spring.GetUnitStates(unitID)
		if (state ~= nil) then --//filter out 'nil' state. eg: enemy
			local firestate= state.firestate
			local movestate= state.movestate
			local unitDefID= Spring.GetUnitDefID(unitID)
			local unitDef= UnitDefs[unitDefID]
			unitHeight[unitID] = unitDef.height +iconoffset
			moveStateTable[movestate+1][unitID] = true
			fireStateTable[firestate+1][unitID] = true
		end
	end
end

-------------------------------------------------------------------------------------
-------------------------------------------------------------------------------------
local function DrawUnitFunc(yshift)
  glTranslate(0,yshift,0)
  glBillboard()
  glTexRect(-iconsize+10.5, -9, 10.5, iconsize-9)
end


function widget:DrawWorld()
  if Spring.IsGUIHidden() then return end
  if (next(unitHeight) == nil) or (not pressQ) then
    return -- avoid unnecessary GL calls
  end 

  gl.Color(1,1,1,1)
  glDepthMask(true)
  glDepthTest(true)
  glAlphaTest(GL_GREATER, 0.001)

  for i=1,3 do
    if (next(fireStateTable[i])) then
      glTexture( fireStateTextures[i] )
      for unitID,_ in pairs(fireStateTable[i]) do
        glDrawFuncAtUnit(unitID, false, DrawUnitFunc, unitHeight[unitID])
      end
    end
  end
  for i=1,3 do
    if (next(moveStateTable[i])) then
      glTexture( moveStateTextures[i] )
      for unitID,_ in pairs(moveStateTable[i]) do
        glDrawFuncAtUnit(unitID, false, DrawUnitFunc, unitHeight[unitID])
      end
    end
  end
  glTexture(false)

  glAlphaTest(false)
  glDepthTest(false)
  glDepthMask(false)
end
--------------------------------------------------------------------------------
--------------------------------------------------------------------------------