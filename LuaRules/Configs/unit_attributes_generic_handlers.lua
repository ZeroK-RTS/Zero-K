local Attributes=GG.Attributes
if not Attributes then
    Attributes={}
    GG.Attributes=Attributes
end
--[=[
	handledAttributeNames->attributeNames
	new -> setup current table
	newDataHandler->UpdateUnitAttributes set inital local
	fold->UpdateUnitAttributes iterating
	apply->UpdateUnitAttributes handling result
	clear -> CleanupAttributeDataForUnit
	handler file script-> set GG and functions
	initialize-> gadget:Initialize
]=]

---@class AttributesDataHandler
---@field fold fun(domainData:table) collect data from attributes
---@field apply fun() handling result

---@class AttributesHandler
---@field newDataHandler fun(frame:number):AttributesDataHandler prepare for collecting data from attributes
---@field clear fun() when a unit's attributes cleared

---@class AttributesHandlerFactory
---@field new fun(unitID:UnitId,unitDefID:UnitDefId):AttributesHandler create handler for a unit that has attributes.
---@field initialize nil|fun() gadget:Initialize
---@field handledAttributeNames table<string,boolean|nil> attribute names used (not used yet)

---@class AttributesHandlersFileReturn:{[string]:AttributesHandlerFactory}

---@type list<AttributesHandlerFactory>
local HandlersFactory=Attributes.HandlersFactory
if not HandlersFactory then
    HandlersFactory={}
    local HandlersFile=VFS.DirList("LuaRules/Configs/UnitAttributeHandlers", "*.lua") or {}
    for i = 1, #HandlersFile do

        Spring.Echo("unit_attributes_generic_handlers.lua: including " .. HandlersFile[i])

        ---@type {[string|number]:AttributesHandlerFactory}
        local HandlersDefs = VFS.Include(HandlersFile[i])
        if not HandlersDefs then
            Spring.Echo("UnitAttributeHandlers file "..HandlersFile[i].." return nil")
        else
            for key, value in pairs(HandlersDefs) do
                if type(key)=="number" then
                    HandlersFactory[#HandlersFactory+1]=value
                else
                    HandlersFactory[key]=value
                end
            end
        end
    end
    Attributes.HandlersFactory=HandlersFactory
end

return HandlersFactory
