-- $Id$
--------------------------------------------------------------------------------
--------------------------------------------------------------------------------

local function SunChanged(curShaderObj)
	curShaderObj:SetUniformAlways("shadowDensity", gl.GetSun("shadowDensity" ,"unit"))

	curShaderObj:SetUniformAlways("sunAmbient", gl.GetSun("ambient" ,"unit"))
	curShaderObj:SetUniformAlways("sunDiffuse", gl.GetSun("diffuse" ,"unit"))
	curShaderObj:SetUniformAlways("sunSpecular", gl.GetSun("specular" ,"unit"))
end

local default_lua = VFS.Include("ModelMaterials/Shaders/default.lua")

local materials = {
   altSkinS3o = {
       shaderDefinitions = {
         "#define deferred_mode 0",
		 "#define SHADOW_PROFILE_HIGH",
       },
       deferredDefinitions = {
         "#define deferred_mode 1",
		 "#define SHADOW_PROFILE_HIGH",
       },
       shader    = default_lua,
       deferred  = default_lua,
       force     = true,
       usecamera = false,
       culling   = GL.BACK,
       texunits  = {
         [0] = '%ALTSKIN',
         [1] = '%ALTSKIN2',
         [2] = '$shadow',
         --[3] = '$specular',
         [4] = '$reflection',
         [5] = '%NORMALTEX',
       },
	   SunChanged = SunChanged,
   },
}

--------------------------------------------------------------------------------
--------------------------------------------------------------------------------
local unitMaterials = {}

for i=1,#UnitDefs do
  local udef = UnitDefs[i]

  if (udef.customParams.altskin and VFS.FileExists(udef.customParams.altskin)) then
    local tex2 = "%%"..i..":1"
    unitMaterials[i] = {"altSkinS3o", ALTSKIN = udef.customParams.altskin, ALTSKIN2 = udef.customParams.altskin2 or tex2}
  end --if
end --for

--------------------------------------------------------------------------------
--------------------------------------------------------------------------------

local skinDefs = include("LuaRules/Configs/dynamic_comm_skins.lua")

for name, data in pairs(skinDefs) do
	local altskin2 = data.altskin2
	if not altskin2 then
		altskin2 = "%%" .. UnitDefNames["dyn" .. data.chassis .. "0"].id .. ":1"
	end
	unitMaterials[name] = {"altSkinS3o", ALTSKIN = data.altskin, ALTSKIN2 = altskin2}
end

--------------------------------------------------------------------------------
--------------------------------------------------------------------------------

return materials, unitMaterials

--------------------------------------------------------------------------------
--------------------------------------------------------------------------------
