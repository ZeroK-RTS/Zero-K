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
	normalMappedS3o = {
		shaderDefinitions = {
			"#define use_normalmapping",
			"#define deferred_mode 0",
			"#define SHADOW_PROFILE_HIGH",
		},
		deferredDefinitions = {
			"#define use_normalmapping",
			"#define deferred_mode 1",
			"#define SHADOW_PROFILE_HIGH",
		},
		shader    = default_lua,
		deferred  = default_lua,
		usecamera = false,
		culling   = GL.BACK,
		predl  = nil,
		postdl = nil,
		texunits  = {
			[0] = '%%UNITDEFID:0',
			[1] = '%%UNITDEFID:1',
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
-- Automated normalmap detection

local unitMaterials = {}

local function FindNormalmap(tex1, tex2)
	local normaltex

	--// check if there is a corresponding _normals.dds file
	if tex1 and (VFS.FileExists(tex1)) then
		local basefilename = tex1:gsub("%....","")
		if (tonumber(basefilename:sub(-1,-1))) then
			basefilename = basefilename:sub(1,-2)
		end
		if (basefilename:sub(-1,-1) == "_") then
			basefilename = basefilename:sub(1,-2)
		end
		normaltex = basefilename .. "_normals.dds"
		if (not VFS.FileExists(normaltex)) then
			normaltex = nil
		end
	end --if FileExists

	if (not normaltex) and tex2 and (VFS.FileExists(tex2)) then
		local basefilename = tex2:gsub("%....","")
		if (tonumber(basefilename:sub(-1,-1))) then
			basefilename = basefilename:sub(1,-2)
		end
		if (basefilename:sub(-1,-1) == "_") then
			basefilename = basefilename:sub(1,-2)
		end
		normaltex = basefilename .. "_normals.dds"
		if (not VFS.FileExists(normaltex)) then
			normaltex = nil
		end
	end

	return normaltex
end

for i=1,#UnitDefs do
	local udef = UnitDefs[i]

	if (udef.customParams.normaltex and VFS.FileExists(udef.customParams.normaltex)) then
		unitMaterials[i] = {"normalMappedS3o", NORMALTEX = udef.customParams.normaltex}
	elseif (udef.modeltype == "s3o") then
		local modelpath = udef.modelpath
		if (modelpath) then
			--// udef.model.textures is empty at gamestart, so read the texture filenames from the s3o directly
			local rawstr = VFS.LoadFile(modelpath)
			local header = rawstr:sub(1,60)
			local texPtrs = VFS.UnpackU32(header, 45, 2)
			local tex1,tex2
			if texPtrs then
				if (texPtrs[2] > 0) then
					tex2 = "unittextures/" .. rawstr:sub(texPtrs[2]+1, rawstr:len()-1)
				else
					texPtrs[2] = rawstr:len()
				end
				if (texPtrs[1] > 0) then
					tex1 = "unittextures/" .. rawstr:sub(texPtrs[1]+1, texPtrs[2]-1)
				end
			end

			-- output units without tex2
			if not tex2 then
				Spring.Log(gadget:GetInfo().name, LOG.WARNING, "CustomUnitShaders: " .. udef.name .. " no tex2")
			end

			local normaltex = FindNormalmap(tex1,tex2)
			if (normaltex and not unitMaterials[i]) then
				unitMaterials[i] = {"normalMappedS3o", NORMALTEX = normaltex}
			end
		end --if model

	elseif (udef.modeltype == "obj") then
		local modelinfopath = udef.modelpath
		if (modelinfopath) then
			modelinfopath = modelinfopath .. ".lua"

			if (VFS.FileExists(modelinfopath)) then
				local infoTbl = Include(modelinfopath)
				if (infoTbl) then
					local tex1 = "unittextures/" .. (infoTbl.tex1 or "")
					local tex2 = "unittextures/" .. (infoTbl.tex2 or "")

					-- output units without tex2
					if not tex2 then
						Spring.Log(gadget:GetInfo().name, LOG.WARNING, "CustomUnitShaders: " .. udef.name .. " no tex2")
					end

					local normaltex = FindNormalmap(tex1,tex2)
					if (normaltex and not unitMaterials[i]) then
						unitMaterials[i] = {"normalMappedS3o", NORMALTEX = normaltex}
					end
				end
			end
		end
	end --elseif
end --for

--------------------------------------------------------------------------------
--------------------------------------------------------------------------------

return materials, unitMaterials

--------------------------------------------------------------------------------
--------------------------------------------------------------------------------
