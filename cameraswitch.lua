function widget:GetInfo()
  return {
    name      = "FastSwitch v2.1",
    desc      = "Spacebar+ctrl switches camera to your start position , whichever is more distant from you",
    author    = "Beherith - mysterme@gmail.com",
    date      = "9/15/2008",
    license   = "GNU GPL, v2 or later",
    layer     = 5,
    enabled   = true  --  loaded by default?
  }
end

--Choose which spacebar modifier key you want:
local useALT =false	
local useCTRL =true

local spacebar=false
local unitList = {}
local homecamx
local homecamy
local homecamz
local firstframe=true

function widget:TextCommand(command)
  --Echo(command)
  if command == "fastswitch" then
		activate()
  end
end

function activate()
	if Spring.GetGameFrame()>0 then
		unitList = Spring.GetTeamUnits(Spring.GetMyTeamID())
		local mycomm =1;
		
		for i=1,#unitList do
		    local unitID    = unitList[i]
			--Spring.Echo("debug:",unitID," ",i)
			local unitDefID = Spring.GetUnitDefID(unitID)
		    local unitDef   = UnitDefs[unitDefID or -1]
		    if (unitDef ) then    --removed   and unitDef.isCommander
		       mycomm=i
			end
		end

		local vsx,vsy,_,_= Spring.GetViewGeometry()

		local x, y, z = Spring.GetUnitPosition(unitList[mycomm])
		local trash, camtrace= Spring.TraceScreenRay(vsx/2,vsy/2,true,false) --onlycoords, nominimap
		if camtrace ~= nil then
			--if 	((camtrace[1]-x)*(camtrace[1]-x)+(camtrace[3]-z)*(camtrace[3]-z))< ((camtrace[1]-homecamx)*(camtrace[1]-homecamx)+(camtrace[3]-homecamz)*(camtrace[3]-homecamz))then
				Spring.SetCameraTarget(homecamx,homecamy,homecamz,0.2)
			--	Spring.Echo("going home")
			--else
			--	Spring.SetCameraTarget(x,y,z,0.2)
			--	Spring.Echo("going to comm")
			--end
		end
	end

end

function widget:Update()

local t = Spring.GetGameSeconds()
  if  t > 0 and firstframe then
    unitList = Spring.GetTeamUnits(Spring.GetMyTeamID())
    homecamx, homecamy, homecamz = Spring.GetUnitPosition(unitList[1])
	firstframe=false
  end
  if  t > 1 then
	local alt,ctrl,meta,space = Spring.GetModKeyState()
--	Spring.Echo(meta)
--	Spring.Echo(space)

	local modifierused 
	if useALT then modifierused= alt
	else modifierused=ctrl end

	if (meta) and modifierused then
--		Spring.Echo("I smell space")
		if spacebar then			
			return
		else
			activate()
		end
	else
		if spacebar then			
			spacebar= meta;
		else
			return			
		end		
	end
  end
end