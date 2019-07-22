function widget:GetInfo()
  return {
    name      = "Recorder (Save)",
    desc      = "Records a minute of a game",
    author    = "Bluestone",
    date      = "June 2014",
    license   = "GNU GPL, v3 or later",
    layer     = 1, 
    enabled   = true  
  }
end

UNIT_FILENAME = "REC_unit.lua"
ORDER_Q_FILENAME = "REC_order_q.lua" 
FACTORY_Q_FILENAME = "REC_factory_q.lua"
ORDER_FILENAME = "REC_order.lua"

function widget:TextCommand(command)
    if not command then return end
    if string.find(command, "saveunits") then
        SaveUnits()
    end
end

function widget:Initialize()
    widgetHandler:RegisterGlobal('SaveUnits', SaveUnits)
end

local startedRecording
local recording
local stopRecording 
local recordTime = 60
local order_table = {}

local unitIDtoKey = {}

local white = "\255\255\255\255"

function widget:UnitCommand(uID, uDID, tID, cmdID, params, options)
    if recording then        
        local frame = Spring.GetGameFrame()
        local cmdName = CMD[cmdID]
        options = {coded=options} --fix format, only the options.coded parameter reaches UnitCommand
        if #params == 1 then
			params[1] = unitIDtoKey[params[1]] or 0
		end
		
		local entry = {
			uID=uID,
			key=unitIDtoKey[uID],
			cmdName=cmdName,
			cmdID=cmdID,
			params=params,
			options=options,
			f=frame-startedRecording
		}
        order_table[#order_table+1] = entry
    end
end

function widget:GameFrame(n)
    if stopRecording==n then 
        recording = nil
        Spring.Echo(white .. "finished recording")
        table.save(order_table,ORDER_FILENAME,"--orders")
    end
end

function widget:Initialize()
	widgetHandler:RemoveCallIn("GameFrame")
end

function SaveUnits()
    startedRecording = Spring.GetGameFrame()
    stopRecording = Spring.GetGameFrame() + 30*recordTime
    recording = true
    widgetHandler:UpdateCallIn("GameFrame")
    
    local units = Spring.GetAllUnits()
  
    local unit_table = {}
    local order_q_table  = {}
    local factory_q_table = {}

    for _,uID in ipairs(units) do
        local x,y,z = Spring.GetUnitBasePosition(uID)
        local uDID = Spring.GetUnitDefID(uID)
        local name = UnitDefs[uDID].name
        local f = Spring.GetUnitBuildFacing(uID)
        local aID = Spring.GetUnitAllyTeam(uID)
        local h,mh,_,_,b = Spring.GetUnitHealth(uID)
        local entry = {x=x,y=y,z=z,name=name,f=f,uID=uID,aID=aID,h=h,mh=mh,b=b}

		local key = uDID .. math.floor(x) .. math.floor(y) .. math.floor(z)
		
		unitIDtoKey[uID] = key
		
        unit_table[#unit_table+1] = entry
        
        local orderQueue = Spring.GetCommandQueue(uID, 30) 
        for _,order in ipairs(orderQueue) do
            if #order.params == 1 then
				order.params[1] = unitIDtoKey[order.params[1]] or 0
			end
			order.uID = uID
			order.key = key
            order.cmdID = order.id
            order.id = nil
            order_q_table[#order_q_table+1] = order
        end
        
        if UnitDefs[uDID].isFactory then
            local orderQueue = Spring.GetFactoryCommands(uID, -1)
            for _,order in ipairs(orderQueue) do
                order.uID = uID
				order.key = key
                order.cmdID = order.id
                order.id = nil
                factory_q_table[#factory_q_table+1] = order
            end
        end
    end

    table.save(unit_table,UNIT_FILENAME,"--units")
    table.save(order_q_table,ORDER_Q_FILENAME,"--order queue")
    table.save(factory_q_table,FACTORY_Q_FILENAME,"--factory queue")
    Spring.Echo(white .. "saved units, recording...")
    return true
end



