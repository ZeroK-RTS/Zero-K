
if not gadgetHandler:IsSyncedCode() then
	return
end
--------------------------------------------------------------------------------
--------------------------------------------------------------------------------

function gadget:GetInfo()
	return {
		name      = "Attributes Generic",
		desc      = "Handles UnitRulesParam attributes in a generic way.",
		author    = "XNTEABDSC", -- v2 GoogleFrog, v1 CarReparier & GoogleFrog
		date      = "2025", -- v2 2018-11-30 v1 2009-11-27
		license   = "GNU GPL, v2 or later",
		layer     = -1,
		enabled   = true,
	}
end


local spGetUnitDefID           = Spring.GetUnitDefID
local INLOS_ACCESS = {inlos = true}
-- under my test, IterableMap is slower than pairs
--local IterableMap = VFS.Include("LuaRules/Gadgets/Include/IterableMap.lua")


local Attributes=GG.Attributes
if not Attributes then
    Attributes={}
    GG.Attributes=Attributes
end

--[=[
---@type 
local AllAttributes=IterableMap.New()
]=]

---UnitAttributes=Attributes[UnitId]
---UnitAttributesDomain=UnitAttributes[domain]
---UnitAttributesDomain[AttType]=value
---@type {[UnitId]:{[string]:{[string]:any}}}
local UnitsAttributes={}

---@type {[UnitId]:{[string|number]:AttributesHandler}}
local UnitAttributesHandlers={}

Spring.Echo("DEBUG: unit_attributes_generic.lua")

---@type {[string|number]:AttributesHandlerFactory}
local AttributesHandlerFactorys=VFS.Include("LuaRules/Configs/unit_attributes_generic_handlers.lua")

---@param unitId UnitId
local function ClearAttributesHandlers(unitId)
    local AttributesHandlers=UnitAttributesHandlers[unitId]
    if AttributesHandlers then
        for key, value in pairs(AttributesHandlers) do
            value.clear()
        end
        UnitAttributesHandlers[unitId]=nil
    end
end

---@param unitId UnitId
local function InitAttributesHandlers(unitId)
    local AttributesHandlers=UnitAttributesHandlers[unitId]
    if not AttributesHandlers then
        AttributesHandlers={}
        UnitAttributesHandlers[unitId]=AttributesHandlers
        local udid=spGetUnitDefID(unitId)
        ---@cast udid -nil
        for key, value in pairs(AttributesHandlerFactorys) do
            AttributesHandlers[key]=value.new(unitId,udid)
        end
    end
    return AttributesHandlers
end

local spGetGameFrame           = Spring.GetGameFrame

---@param unitID UnitId
---@param datas {[string]:{[string]:any}} -- {[domain]:{[attType]:value}}
local function UpdateUnitAttributes(unitID, datas)
    if not datas or not next(datas) then
        ClearAttributesHandlers(unitID)
        return
    end

	local frame = spGetGameFrame()
    local AttributesHandlers=InitAttributesHandlers(unitID)
    ---@type {[string|number]:AttributesDataHandler}
    local AttributesDataHandlers={}
    for key, value in pairs(AttributesHandlers) do
        AttributesDataHandlers[key]=value.newDataHandler(frame)
    end
    for domain, data in pairs(datas) do
        for key, dataHandlers in pairs(AttributesDataHandlers) do
            dataHandlers.fold(data)
        end
    end
    for key, value in pairs(AttributesDataHandlers) do
        value.apply()
    end
end


function Attributes.RemoveUnit(unitID)
    ClearAttributesHandlers(unitID)
end


---@param unitID UnitId
---@param domain string
---@param effects {[string]:any}
function Attributes.AddEffect(unitID, domain, effects)
    local UnitAttributes=UnitsAttributes[unitID]
    if not UnitAttributes then
        UnitAttributes={}
        UnitsAttributes[unitID]=UnitAttributes
    end
    UnitAttributes[domain]=effects
    UpdateUnitAttributes(unitID, UnitAttributes)
end

function Attributes.RemoveEffect(unitID, key)
    local UnitAttributes=UnitsAttributes[unitID]
    if not UnitAttributes then
        return
    end
    UnitAttributes[key]=nil
    UpdateUnitAttributes(unitID, UnitAttributes)
end


function gadget:Initialize()
    for key, fac in pairs(AttributesHandlerFactorys) do
        if fac.initialize then
            fac.initialize()
        end
    end
end


function gadget:UnitDestroyed(unitID, unitDefID, teamID)
	Attributes.RemoveUnit(unitID)
end