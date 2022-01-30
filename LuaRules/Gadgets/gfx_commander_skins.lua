--------------------------------------------------------------------------------
--------------------------------------------------------------------------------

function gadget:GetInfo()
	return {
		name      = "Commander Skin Renderer",
		version   = 3,
		desc      = "Replaces textures for commanders eqipped with skin decorations",
		author    = "Anarchid",
		date      = "May 2020",
		license   = "GPL V2",
		layer     = 0,
		enabled   = Spring.Utilities.IsCurrentVersionNewerThan(105, 500)
	}
end

-------------------------------------------------------------------------------------
-------------------------------------------------------------------------------------
if gadgetHandler:IsSyncedCode() then
	return
end

-------------------------------------------------------------------------------------
-------------------------------------------------------------------------------------
-- Unsynced
-------------------------------------------------------------------------------------
-------------------------------------------------------------------------------------

if (not gl.CreateShader) then
	Spring.Log("Commander Skins", LOG.WARNING, "Shaders not supported, disabling.")
	return false
end

-------------------------------------------------------------------------------------
-------------------------------------------------------------------------------------

local alphaMult = 0.35
local alphaThresholdOpaque = 0.5
local alphaThresholdAlpha  = 0.1
local overrideDrawFlags = {
	[0]  = true , --SO_OPAQUE_FLAG = 1, deferred hack
	[1]  = true , --SO_OPAQUE_FLAG = 1,
	[2]  = false , --SO_ALPHAF_FLAG = 2, -- commander skins don't change transparency; henceforth: CAN'T
	[4]  = true , --SO_REFLEC_FLAG = 4,
	[8]  = true , --SO_REFRAC_FLAG = 8,
	[16] = false , --SO_SHADOW_FLAG = 16, -- commander skins don't change geometry or transparency; hence they don't change shadows
}

--implementation
local overrideDrawFlag = 0
for f, e in pairs(overrideDrawFlags) do
	overrideDrawFlag = overrideDrawFlag + f * (e and 1 or 0)
end

local drawBinKeys = {1, 1 + 4, 1 + 8, 2, 2 + 4, 2 + 8, 16} --deferred is handled ad-hoc
local overrideDrawFlagsCombined = {
	[0    ] = overrideDrawFlags[0],
	[1    ] = overrideDrawFlags[1],
	[1 + 4] = overrideDrawFlags[1] and overrideDrawFlags[4],
	[1 + 8] = overrideDrawFlags[1] and overrideDrawFlags[8],
	[2    ] = overrideDrawFlags[2],
	[2 + 4] = overrideDrawFlags[2] and overrideDrawFlags[4],
	[2 + 8] = overrideDrawFlags[2] and overrideDrawFlags[8],
	[16   ] = overrideDrawFlags[16],
}

local overriddenUnits = {}
local processedUnits = {}
local textureOverrides = {}

local unitDrawBins = {
	[0    ] = {}, -- deferred opaque
	[1    ] = {}, -- forward  opaque
	[1 + 4] = {}, -- forward  opaque + reflection
	[1 + 8] = {}, -- forward  opaque + refraction
	[2    ] = {}, -- alpha
	[2 + 4] = {}, -- alpha + reflection
	[2 + 8] = {}, -- alpha + refraction
	[16   ] = {}, -- shadow
}

local unitIDs = {}
local idToDefId = {}
local processedCounter = 0
local shaders = {}

local vao = nil
local vbo = nil
local ebo = nil
local ibo = nil

local MAX_DRAWN_UNITS = 8192
local skinDefs = include("LuaRules/Configs/dynamic_comm_skins.lua")

-------------------------------------------------------------------------------------
-------------------------------------------------------------------------------------
-- Utilities

local function Bit(p)
	return 2 ^ (p - 1)  -- 1-based indexing
end

-- Typical call:  if hasbit(x, bit(3)) then ...
local function HasBit(x, p)
	return x % (p + p) >= p
end

local math_bit_and = math.bit_and
local function HasAllBits(x, p)
	return math_bit_and(x, p) == p
end

local function SetBit(x, p)
	return HasBit(x, p) and x or x + p
end

local function ClearBit(x, p)
	return HasBit(x, p) and x - p or x
end

-------------------------------------------------------------------------------------
-------------------------------------------------------------------------------------
-- Shader

local function GetShader(drawPass, unitDef)
	return shaders[drawPass]
end

local function SetFixedStatePre(drawPass, shaderID)
	if HasBit(drawPass, 4) then
		gl.ClipDistance(2, true)
	elseif HasBit(drawPass, 8) then
		gl.ClipDistance(2, true)
	end
end

local function SetFixedStatePost(drawPass, shaderID)
	if HasBit(drawPass, 4) then
		gl.ClipDistance(2, false)
	elseif HasBit(drawPass, 8) then
		gl.ClipDistance(2, false)
	end
end

--[[
cameraMode:
		case  1: // water reflection
		case  2: // water refraction
		default: // player, (-1) static model, (0) normal rendering
]]--
local function SetShaderUniforms(drawPass, shaderID)
	if drawPass <= 2 then
		gl.UniformInt("cameraMode", 0)
		gl.Uniform("clipPlane2", 0.0, 0.0, 0.0, 1.0)
	elseif drawPass == 16 then
		--gl.Uniform("alphaCtrl", alphaThresholdOpaque, 1.0, 0.0, 0.0)
		-- set properly by default
	end

	if HasBit(drawPass, 1) then
		gl.Uniform("alphaCtrl", alphaThresholdOpaque, 1.0, 0.0, 0.0)
		gl.Uniform("colorMult", 1.0, 1.0, 1.0, 1.0)
	elseif HasBit(drawPass, 2) then
		gl.Uniform("alphaCtrl", alphaThresholdAlpha , 1.0, 0.0, 0.0)
		gl.Uniform("colorMult", 1.0, 1.0, 1.0, alphaMult)
	end

	if HasBit(drawPass, 4) then
		gl.UniformInt("cameraMode", 1)
		gl.Uniform("clipPlane2", 0.0, 1.0, 0.0, 0.0)
	elseif HasBit(drawPass, 8) then
		gl.UniformInt("cameraMode", 2)
		gl.Uniform("clipPlane2", 0.0, -1.0, 0.0, 0.0)
	end
end

local function GetTextures(drawPass, unitID)
	local unitDef = Spring.GetUnitDefID(unitID)
	if drawPass == 16 then
		return {
			[0] = string.format("%%%s:%i", unitDef, 1), --tex2 only
		}
	else
		return {
			[0] = ':l:'..textureOverrides[unitID][1],
			[1] = ':l:'..textureOverrides[unitID][2],
			[2] = "$shadow",
			[3] = "$reflection",
		}
	end
end

local MAX_TEX_ID = 131072 --should be enough
local function GetTexturesKey(textures)
	local cs = 0
	for bp, tex in pairs(textures) do
		local texInfo = gl.TextureInfo(tex) or {}
		cs = cs + (texInfo.id or 0) + bp * MAX_TEX_ID
	end

	return cs
end

-------------------------------------------------------------------------------------
-------------------------------------------------------------------------------------
-- Unit tracking

local function AssignUnitToBin(unitID, unitDefID, flag, shader, textures, texKey)
	shader = shader or GetShader(flag, unitDefID)
	textures = textures or GetTextures(flag, unitID)
	texKey = texKey or GetTexturesKey(textures)

	local unitDrawBinsFlag = unitDrawBins[flag]
	if unitDrawBinsFlag[shader] == nil then
		unitDrawBinsFlag[shader] = {}
	end
	local unitDrawBinsFlagShader = unitDrawBinsFlag[shader]

	if unitDrawBinsFlagShader[texKey] == nil then
		unitDrawBinsFlagShader[texKey] = {
			textures = textures
		}
	end
	local unitDrawBinsFlagShaderTexKey = unitDrawBinsFlagShader[texKey]

	if unitDrawBinsFlagShaderTexKey.objects == nil then
		unitDrawBinsFlagShaderTexKey.objects = {}
	end
	local unitDrawBinsFlagShaderTexKeyObjs = unitDrawBinsFlagShaderTexKey.objects

	unitDrawBinsFlagShaderTexKeyObjs[unitID] = true
end

local function AddUnit(unitID, drawFlag)
	if (drawFlag >= 128) then --icon
		return
	end
	if (drawFlag >=  32) then --far tex
		return
	end

	local unitDefID = Spring.GetUnitDefID(unitID)
	idToDefId[unitID] = unitDefID

	--Spring.Echo(unitID, UnitDefs[unitDefID].name)

	for k = 1, #drawBinKeys do
		local flag = drawBinKeys[k]

		if HasAllBits(drawFlag, flag) then
			if overrideDrawFlagsCombined[flag] then
				AssignUnitToBin(unitID, unitDefID, flag)
				if flag == 1 then
					AssignUnitToBin(unitID, unitDefID, 0) --deferred hack
				end
			end
		end
	end

	Spring.SetUnitEngineDrawMask(unitID, 255 - overrideDrawFlag) -- ~overrideDrawFlag & 255
	overriddenUnits[unitID] = drawFlag
	--overriddenUnits[unitID] = overrideDrawFlag
end

local function RemoveUnitFromBin(unitID, unitDefID, texKey, shader, flag)
	shader = shader or GetShader(flag, unitDefID)
	textures = textures or GetTextures(flag, unitID)
	texKey = texKey or GetTexturesKey(textures)

	if unitDrawBins[flag][shader] then
		if unitDrawBins[flag][shader][texKey] then
			if unitDrawBins[flag][shader][texKey].objects then
				unitDrawBins[flag][shader][texKey].objects[unitID] = nil
			end
		end
	end
end

local function UpdateUnit(unitID, drawFlag)
	if (drawFlag >= 128) then --icon
		return
	end
	if (drawFlag >=  32) then --far tex
		return
	end

	local unitDefID = idToDefId[unitID]

	for k = 1, #drawBinKeys do
		local flag = drawBinKeys[k]

		local hasFlagOld = HasAllBits(overriddenUnits[unitID], flag)
		local hasFlagNew = HasAllBits(               drawFlag, flag)

		if hasFlagOld ~= hasFlagNew and overrideDrawFlagsCombined[flag] then
			local shader = GetShader(flag, unitDefID)
			local textures = GetTextures(flag, unitID)
			local texKey  = GetTexturesKey(textures)

			if hasFlagOld then --had this flag, but no longer have
				RemoveUnitFromBin(unitID, unitDefID, texKey, shader, flag)
				if flag == 1 then
					RemoveUnitFromBin(unitID, unitDefID, texKey, nil, 0)
				end
			end
			if hasFlagNew then -- didn't have this flag, but now has
				AssignUnitToBin(unitID, unitDefID, flag, shader, textures, texKey)
				if flag == 1 then
					AssignUnitToBin(unitID, unitDefID, 0, nil, textures, texKey) --deferred
				end
			end
		end
	end

	overriddenUnits[unitID] = drawFlag
end

local function RemoveUnit(unitID)
	--remove the object from every bin and table

	local unitDefID = idToDefId[unitID]

	for k = 1, #drawBinKeys do
		local flag = drawBinKeys[k]

		if overrideDrawFlagsCombined[flag] then
			local shader = GetShader(flag, unitDefID)
			local textures = GetTextures(flag, unitID)
			local texKey  = GetTexturesKey(textures)
			RemoveUnitFromBin(unitID, unitDefID, texKey, shader, flag)
			if flag == 1 then
				RemoveUnitFromBin(unitID, unitDefID, texKey, nil, 0)
			end
		end
	end

	idToDefId[unitID] = nil
	overriddenUnits[unitID] = nil
	processedUnits[unitID] = nil
	textureOverrides[unitID] = nil

	Spring.SetUnitEngineDrawMask(unitID, 255)
end

local function ProcessUnit(unitID, drawFlag, skinName)
	local data = skinDefs[skinName]
	local udefParent = UnitDefNames["dyn" .. data.chassis .. "0"]
	local tex1 = data.altskin
	local tex2 = data.altskin2
	if not tex2 then
		tex2 = "%%" .. udefParent.id .. ":1"
	end

	textureOverrides[unitID] = {tex1, tex2}
	if overriddenUnits[unitID] == nil then --object was not seen
		AddUnit(unitID, drawFlag)
	elseif overriddenUnits[unitID] ~= drawFlag then --flags have changed
		UpdateUnit(unitID, drawFlag)
	end
end

local function ProcessUnits(units, drawFlags)
	processedCounter = (processedCounter + 1) % (2 ^ 16)

	for i = 1, #units do
		local unitID = units[i]
		local drawFlag = drawFlags[i]

		if overriddenUnits[unitID] == nil then --object was not seen
			AddUnit(unitID, drawFlag)
		elseif overriddenUnits[unitID] ~= drawFlag then --flags have changed
			UpdateUnit(unitID, drawFlag)
		end
		processedUnits[unitID] = processedCounter
	end

	for unitID, _ in pairs(overriddenUnits) do
		if processedUnits[unitID] ~= processedCounter then --object was not updated thus was removed
			RemoveUnit(unitID)
		end
	end
end

local function ExecuteDrawPass(drawPass)
	for shaderId, data in pairs(unitDrawBins[drawPass]) do
		for _, texAndObj in pairs(data) do
			for bp, tex in pairs(texAndObj.textures) do
				gl.Texture(bp, tex)
			end

			unitIDs = {}
			for unitID, _ in pairs(texAndObj.objects) do
				unitIDs[#unitIDs + 1] = unitID
			end

			SetFixedStatePre(drawPass, shaderId)

			ibo:InstanceDataFromUnitIDs(unitIDs, 6) --id = 6, name = "instData"
			vao:ClearSubmission()
			vao:AddUnitsToSubmission(unitIDs)

			gl.UseShader(shaderId)
			SetShaderUniforms(drawPass, shaderId)
			vao:Submit()
			gl.UseShader(0)

			SetFixedStatePost(drawPass, shaderId)


			for bp, tex in pairs(texAndObj.textures) do
				gl.Texture(bp, false)
			end
		end
	end
end

-------------------------------------------------------------------------------------
-------------------------------------------------------------------------------------
-- Callins

function gadget:Initialize()
	local vsSrc = VFS.LoadFile("shaders/GLSL/ModelVertProgGL4.glsl")
	local fsSrc = VFS.LoadFile("shaders/GLSL/ModelFragProgGL4.glsl")

	vsSrc = string.gsub(vsSrc, "#version 430 core", "")
	fsSrc = string.gsub(fsSrc, "#version 430 core", "")

	local fwdShader = gl.CreateShader({
		vertex   = vsSrc,
		fragment = fsSrc,
		definitions = table.concat({
			"#version 430 core",
			"#define USE_SHADOWS 1",
			"#define DEFERRED_MODE 0",
			"#define GBUFFER_NORMTEX_IDX 0",
			"#define GBUFFER_DIFFTEX_IDX 1",
			"#define GBUFFER_SPECTEX_IDX 2",
			"#define GBUFFER_EMITTEX_IDX 3",
			"#define GBUFFER_MISCTEX_IDX 4",
			"#define GBUFFER_ZVALTEX_IDX 5",
		}, "\n") .. "\n",
		uniformInt = {
			matrixMode = 0,
		}
	})
	Spring.Echo(gl.GetShaderLog())
	if fwdShader == nil then
		gadgetHandler:Removegadget()
	end

	local dfrShader = gl.CreateShader({
		vertex   = vsSrc,
		fragment = fsSrc,
		definitions = table.concat({
			"#version 430 core",
			"#define USE_SHADOWS 1",
			"#define DEFERRED_MODE 1",
			"#define GBUFFER_NORMTEX_IDX 0",
			"#define GBUFFER_DIFFTEX_IDX 1",
			"#define GBUFFER_SPECTEX_IDX 2",
			"#define GBUFFER_EMITTEX_IDX 3",
			"#define GBUFFER_MISCTEX_IDX 4",
			"#define GBUFFER_ZVALTEX_IDX 5",
		}, "\n") .. "\n",
		uniformInt = {
			matrixMode = 0,
		}
	})

	Spring.Echo(gl.GetShaderLog())
	if dfrShader == nil then
		gadgetHandler:Removegadget()
	end

	for k = 1, #drawBinKeys do
		local flag = drawBinKeys[k]
		shaders[flag] = fwdShader
	end
	shaders[0 ] = dfrShader

	vao = gl.GetVAO()
	if vao == nil then
		gadgetHandler:Removegadget()
	end

	vbo = gl.GetVBO(GL.ARRAY_BUFFER, false)
	ebo = gl.GetVBO(GL.ELEMENT_ARRAY_BUFFER, false)
	ibo = gl.GetVBO(GL.ARRAY_BUFFER, true)

	if ((vbo == nil) or (ebo == nil) or (ibo == nil)) then
		gadgetHandler:Removegadget()
	end

	ibo:Define(MAX_DRAWN_UNITS, {
		{id = 6, name = "instData", type = GL.UNSIGNED_INT, size = 4},
	})

	vbo:ModelsVBO()
	ebo:ModelsVBO()

	vao:AttachVertexBuffer(vbo)
	vao:AttachIndexBuffer(ebo)
	vao:AttachInstanceBuffer(ibo)

	for _, unitID in ipairs(Spring.GetAllUnits()) do
		local unitDefID = Spring.GetUnitDefID(unitID)
		gadget:UnitCreated(unitID, unitDefID)
	end
end

function gadget:Shutdown()
	for unitID, _ in pairs(overriddenUnits) do
		RemoveUnit(unitID)
	end

	vbo = nil
	ebo = nil
	ibo = nil

	vao = nil

	gl.DeleteShader(shaders[0])
	gl.DeleteShader(shaders[1])
end

function gadget:DrawOpaqueUnitsLua(deferredPass, drawReflection, drawRefraction)
	local drawPass = 1 --opaque

	if deferredPass then
		drawPass = 0
	end

	if drawReflection then
		drawPass = 1 + 4
	end

	if drawRefraction then
		drawPass = 1 + 8
	end

	--Spring.Echo("drawPass", drawPass)
	ExecuteDrawPass(drawPass)
end

function gadget:DrawAlphaUnitsLua(drawReflection, drawRefraction)
	local drawPass = 2 --alpha

	if drawReflection then
		drawPass = 2 + 4
	end

	if drawRefraction then
		drawPass = 2 + 8
	end

	--Spring.Echo("drawPass", drawPass)
	ExecuteDrawPass(drawPass)
end


function gadget:UnitCreated(unitId, unitDefID)
	local skinName = Spring.GetUnitRulesParam(unitId, 'comm_texture')
	if not skinName then
		return
	end

	ProcessUnit(unitId, overrideDrawFlag, skinName)
end

function gadget:RenderUnitDestroyed(unitId)
	local skinName = Spring.GetUnitRulesParam(unitId, 'comm_texture')
	if not skinName then
		return
	end
	
	RemoveUnit(unitId)
end
