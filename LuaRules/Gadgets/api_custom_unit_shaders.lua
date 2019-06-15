-- $Id$
--------------------------------------------------------------------------------
--------------------------------------------------------------------------------
--
--  author:  jK
--
--  Copyright (C) 2008,2009,2010.
--  Licensed under the terms of the GNU GPL, v2 or later.
--
--------------------------------------------------------------------------------
--------------------------------------------------------------------------------

function gadget:GetInfo()
	return {
		name      = "CustomUnitShaders",
		desc      = "allows to override the engine unit and feature shaders",
		author    = "jK, gajop",
		date      = "2008,2009,2010,2016",
		license   = "GNU GPL, v2 or later",
		layer     = 1,
		enabled   = true  --  loaded by default?
	}
end

--------------------------------------------------------------------------------
--------------------------------------------------------------------------------
-- Synced
--------------------------------------------------------------------------------
--------------------------------------------------------------------------------


if (gadgetHandler:IsSyncedCode()) then
	return
end

--------------------------------------------------------------------------------
--------------------------------------------------------------------------------
-- Unsynced
--------------------------------------------------------------------------------
--------------------------------------------------------------------------------

if (not gl.CreateShader) then
	Spring.Log("CUS", LOG.WARNING, "Shaders not supported, disabling")
	return false
end

-----------------------------------------------------------------
-- File path Constants
-----------------------------------------------------------------

local MATERIALS_DIR = "ModelMaterials/"
local LUASHADER_DIR = "LuaRules/Gadgets/Include/"

-----------------------------------------------------------------
-- Includes and classes loading
-----------------------------------------------------------------

VFS.Include("luarules/utilities/unitrendering.lua", nil, VFS.MOD .. VFS.BASE)
local LuaShader = VFS.Include(LUASHADER_DIR .. "LuaShader.lua")

-----------------------------------------------------------------
-- Global Variables
-----------------------------------------------------------------

local advShading = false

local sunChanged = false
local optionsChanged = true --just in case

local shadows = false
local normalmapping = true
local treewind = false


local idToDefID = {}

---
-- rendering.materialDefs[matName] = mat_src
-- rendering.bufMaterials[objectDefID] = rendering.spGetMaterial() / luaMat
-- rendering.materialInfos[objectDefID] = {matName, name = param, name1 = param1}
---

local unitRendering = {
	drawList        = {},
	materialInfos   = {},
	bufMaterials    = {},
	materialDefs    = {},
	loadedTextures  = {},

	spGetAllObjects      = Spring.GetAllUnits,
	spGetObjectPieceList = Spring.GetUnitPieceList,

	spGetMaterial        = Spring.UnitRendering.GetMaterial,
	spSetMaterial        = Spring.UnitRendering.SetMaterial,
	spActivateMaterial   = Spring.UnitRendering.ActivateMaterial,
	spDeactivateMaterial = Spring.UnitRendering.DeactivateMaterial,
	spSetObjectLuaDraw   = Spring.UnitRendering.SetUnitLuaDraw,
	spSetLODCount        = Spring.UnitRendering.SetLODCount,
	spSetPieceList       = Spring.UnitRendering.SetPieceList,

	DrawObject           = "DrawUnit",
	ObjectCreated        = "UnitCreated",
	ObjectDestroyed      = "UnitDestroyed",
}

local featureRendering = {
	drawList        = {},
	materialInfos   = {},
	bufMaterials    = {},
	materialDefs    = {},
	loadedTextures  = {},

	spGetAllObjects      = Spring.GetAllFeatures,
	spGetObjectPieceList = Spring.GetFeaturePieceList,

	spGetMaterial        = Spring.FeatureRendering.GetMaterial,
	spSetMaterial        = Spring.FeatureRendering.SetMaterial,
	spActivateMaterial   = Spring.FeatureRendering.ActivateMaterial,
	spDeactivateMaterial = Spring.FeatureRendering.DeactivateMaterial,
	spSetObjectLuaDraw   = Spring.FeatureRendering.SetFeatureLuaDraw,
	spSetLODCount        = Spring.FeatureRendering.SetLODCount,
	spSetPieceList       = Spring.FeatureRendering.SetPieceList,

	DrawObject           = "DrawFeature",
	ObjectCreated        = "FeatureCreated",
	ObjectDestroyed      = "FeatureDestroyed",
}

local allRendering = {
	unitRendering,
	featureRendering,
}

-----------------------------------------------------------------
-- Local Functions
-----------------------------------------------------------------

local _plugins = nil
local function InsertPlugin(str)
	return (_plugins and _plugins[str]) or ""
end

local function _CompileShader(shader, definitions, plugins, addName)
	shader.vertexOrig   = shader.vertex
	shader.fragmentOrig = shader.fragment
	shader.geometryOrig = shader.geometry

	--// insert small pieces of code named `plugins`
	--// this way we can use a basic shader and add some simple vertex animations etc.
	do
		if (plugins) then
			_plugins = plugins
		end

		if (shader.vertex) then
			shader.vertex   = shader.vertex:gsub("%%%%([%a_]+)%%%%", InsertPlugin)
		end
		if (shader.fragment) then
			shader.fragment = shader.fragment:gsub("%%%%([%a_]+)%%%%", InsertPlugin)
		end
		if (shader.geometry) then
			shader.geometry = shader.geometry:gsub("%%%%([%a_]+)%%%%", InsertPlugin)
		end

		_plugins = nil
	end

	--// append definitions at top of the shader code
	--// (this way we can modularize a shader and enable/disable features in it)
	definitions = definitions or {}
	hasVersion = false
	for _, def in pairs(definitions) do
		hasVersion = hasVersion or string.sub(def,1,string.len("#version")) == "#version"
	end
	if not hasVersion then
		table.insert(definitions, 1, "#version 150 compatibility")
	end
	definitions = table.concat(definitions, "\n") .. "\n"
	if (shader.vertex) then
		shader.vertex = definitions .. shader.vertex
	end
	if (shader.fragment) then
		shader.fragment = definitions .. shader.fragment
	end
	if (shader.geometry) then
		shader.geometry = definitions .. shader.geometry
	end

	local luaShader = LuaShader(shader, "Custom Unit Shaders. " .. addName)
	luaShader:Initialize()

	shader.vertex   = shader.vertexOrig
	shader.fragment = shader.fragmentOrig
	shader.geometry = shader.geometryOrig

	return luaShader
end

local function _FillUniformLocs(luaShader)
	local engineUniforms = {
		"viewMatrix",
		"viewMatrixInv",
		"projectionMatrix",
		"projectionMatrixInv",
		"viewProjectionMatrix",
		"viewProjectionMatrixInv",
		"shadowMatrix",
		"shadowParams",
		"cameraPos",
		"cameraDir",
		"sunDir",
		"rndVec",
		"simFrame",
		"drawFrame", --visFrame
	}

	local uniformLocTbl = {}
	for _, uniformName in ipairs(engineUniforms) do
		local uniformNameLoc = string.lower(uniformName).."loc"
		uniformLocTbl[uniformNameLoc] = luaShader:GetUniformLocation(uniformName)
	end
	return uniformLocTbl
end

local function _CompileMaterialShaders(rendering)
	for matName, mat_src in pairs(rendering.materialDefs) do
		if mat_src.shaderSource then
			local luaShader = _CompileShader(
				mat_src.shaderSource,
				mat_src.shaderDefinitions,
				mat_src.shaderPlugins,
				string.format("MatName: \"%s\"(%s)", matName, "Standard")
			)

			if luaShader then
				if mat_src.standardShader then
					if mat_src.standardShaderObj then
						mat_src.standardShaderObj:Finalize()
					else
						gl.DeleteShader(mat_src.standardShader)
					end
				end
				mat_src.standardShaderObj = luaShader
				mat_src.standardShader = luaShader:GetHandle()
				luaShader:SetUnknownUniformIgnore(true)
				luaShader:ActivateWith( function()
					mat_src.standardUniforms = _FillUniformLocs(luaShader)
				end)
				luaShader:SetActiveStateIgnore(true)
			end
		end

		if (mat_src.deferredSource) then
			local luaShader = _CompileShader(
				mat_src.deferredSource,
				mat_src.deferredDefinitions,
				mat_src.deferredPlugins,
				string.format("MatName: \"%s\"(%s)", matName, "Deferred")
			)

			if luaShader then
				if mat_src.deferredShader then
					if mat_src.deferredShaderObj then
						mat_src.deferredShaderObj:Finalize()
					else
						gl.DeleteShader(mat_src.deferredShader)
					end
				end
				mat_src.deferredShaderObj = luaShader
				mat_src.deferredShader = luaShader:GetHandle()
				luaShader:SetUnknownUniformIgnore(true)
				luaShader:ActivateWith( function()
					mat_src.deferredUniforms = _FillUniformLocs(luaShader)
				end)
				luaShader:SetActiveStateIgnore(true)
			end
		end
	end
end

local function CompileMaterialShaders()
	for _, rendering in ipairs(allRendering) do
		_CompileMaterialShaders(rendering)
	end
end

local function _ProcessOptions(optName, optValue, playerID)
	if (playerID ~= Spring.GetMyPlayerID()) then
		return
	end
	for _, rendering in ipairs(allRendering) do
		for matName, matTable in pairs(rendering.materialDefs) do
			if matTable.ProcessOptions then
				optionsChanged = optionsChanged or matTable.ProcessOptions(matTable.shaderOptions, optName, optValue)
				optionsChanged = optionsChanged or matTable.ProcessOptions(matTable.deferredOptions, optName, optValue)
			end
		end
	end
end

--------------------------------------------------------------------------------
--------------------------------------------------------------------------------

local function GetObjectMaterial(rendering, objectDefID)
	local mat = rendering.bufMaterials[objectDefID]
	if mat then
		return mat
	end


	local matInfo = rendering.materialInfos[objectDefID]
	local mat = rendering.materialDefs[matInfo[1]]

	if type(objectDefID) == "number" then
		-- Non-number objectDefIDs are default material overrides. They will have
		-- their textures defined in the unit materials files.
		matInfo.UNITDEFID = objectDefID
		matInfo.FEATUREDEFID = -objectDefID
	end

	--// find unitdef tex keyword and replace it
	--// (a shader can be just for multiple unitdefs, so we support this keywords)
	local texUnits = {}
	for texid, tex in pairs(mat.texunits or {}) do
		local tex_ = tex
		for varname, value in pairs(matInfo) do
			tex_ = tex_:gsub("%%"..tostring(varname),value)
		end
		texUnits[texid] = {tex=tex_, enable=false}
	end

	--// materials don't load those textures themselves
	if (texUnits[1]) then
		local texdl = gl.CreateList(function()
			for _,tex in pairs(texUnits) do
				local prefix = tex.tex:sub(1,1)
				if    (prefix~="%")
				   and(prefix~="#")
				   and(prefix~="!")
				   and(prefix~="$") then
					gl.Texture(tex.tex)
					rendering.loadedTextures[#rendering.loadedTextures+1] = tex.tex
				end
			end
		end)
		gl.DeleteList(texdl)
	end

	local luaMat = rendering.spGetMaterial("opaque", {
		standardshader = mat.standardShader,
		deferredshader = mat.deferredShader,

		standarduniforms = mat.standardUniforms,
		deferreduniforms = mat.deferredUniforms,

		usecamera   = mat.usecamera,
		culling     = mat.culling,
		texunits    = texUnits,
		prelist     = mat.predl,
		postlist    = mat.postdl,
	})

	rendering.bufMaterials[objectDefID] = luaMat

	return luaMat
end

--------------------------------------------------------------------------------
--------------------------------------------------------------------------------

local function ResetUnit(unitID)
	local unitDefID = Spring.GetUnitDefID(unitID)
	gadget:RenderUnitDestroyed(unitID, unitDefID)
	Spring.UnitRendering.DeactivateMaterial(unitID, 3)
	if not select(3, Spring.GetUnitIsStunned(unitID)) then --// inbuild?
		gadget:UnitFinished(unitID,unitDefID)
	end
end

local function ResetFeature(featureID)
	gadget:FeatureDestroyed(featureID)
	Spring.FeatureRendering.DeactivateMaterial(featureID, 3)
	gadget:FeatureCreated(featureID)
end

local function _LoadMaterialConfigFiles(path)
	local unitMaterialDefs = {}
	local featureMaterialDefs = {}

	local files = VFS.DirList(path)
	table.sort(files)

	for i = 1, #files do
		local mats, unitMats = VFS.Include(files[i])
		for k, v in pairs(mats) do
		-- Spring.Echo(files[i],'is a feature?',v.feature)
			local rendering
			if v.feature then
				rendering = featureRendering
			else
				rendering = unitRendering
			end
			if not rendering.materialDefs[k] then
				rendering.materialDefs[k] = v
			end
		end
		for k, v in pairs(unitMats) do
			--// we check if the material is defined as a unit or as feature material (one namespace for both!!)
			local materialDefs
			if featureRendering.materialDefs[v[1]] then
				materialDefs = featureMaterialDefs
			else
				materialDefs = unitMaterialDefs
			end
			if not materialDefs[k] then
				materialDefs[k] = v
			end
		end
	end

	return unitMaterialDefs, featureMaterialDefs
end

local function _ProcessMaterials(rendering, materialDefs)
	local engineShaderTypes = {"3do", "s3o", "obj", "ass"}

	for _, mat_src in pairs(rendering.materialDefs) do

		if mat_src.shader ~= nil and engineShaderTypes[mat_src.shader] == nil then
			mat_src.shaderSource = mat_src.shader
			mat_src.shader = nil
		end

		if mat_src.deferred ~= nil and engineShaderTypes[mat_src.deferred] == nil then
			mat_src.deferredSource = mat_src.deferred
			mat_src.deferred = nil
		end
	end

	_CompileMaterialShaders(rendering)

	for objectDefID, materialInfo in pairs(materialDefs) do
		if (type(materialInfo) ~= "table") then
			materialInfo = {materialInfo}
		end
		rendering.materialInfos[objectDefID] = materialInfo
	end
end


local function ToggleShadows()

	shadows = Spring.HaveShadows()

	--unitRendering.bufMaterials = {}
	local units = Spring.GetAllUnits()
	for _, unitID in pairs(units) do
		ResetUnit(unitID)
	end

	--featureRendering.bufMaterials = {}
	local features = Spring.GetAllFeatures()
	for _, featureID in pairs(features) do
		ResetFeature(featureID)
	end

end


local function ToggleAdvShading()
	advShading = Spring.HaveAdvShading()

	if (not advShading) then
		--// unload all materials
		unitRendering.drawList = {}
		local units = Spring.GetAllUnits()
		for _,unitID in pairs(units) do
			ResetUnit(unitID)
		end

		featureRendering.drawList = {}
		local features = Spring.GetAllFeatures()
		for _, featureID in pairs(features) do
			ResetFeature(featureID)
		end
	elseif (normalmapping) then
		--// reinitializes all shaders
		--ToggleShadows()
	end
end

local function GetShaderOverride(objectID, objectDefID)
	if Spring.ValidUnitID(objectID) then
		return Spring.GetUnitRulesParam(objectID, "comm_texture")
	end
	return false
end

local function ObjectFinished(rendering, objectID, objectDefID)
	if not advShading then
		return
	end

	objectDefID = GetShaderOverride(objectID, objectDefID) or objectDefID
	local objectMat = rendering.materialInfos[objectDefID]
	if objectMat then
		local mat = rendering.materialDefs[objectMat[1]]
		if (normalmapping or mat.force) then
			rendering.spActivateMaterial(objectID, 3)
			rendering.spSetMaterial(objectID, 3, "opaque", GetObjectMaterial(rendering, objectDefID))
			for pieceID in ipairs(rendering.spGetObjectPieceList(objectID) or {}) do
				rendering.spSetPieceList(objectID, 3, pieceID)
			end
			local DrawObject = mat[rendering.DrawObject]
			local ObjectCreated = mat[rendering.ObjectCreated]
			if DrawObject then
				rendering.spSetObjectLuaDraw(objectID, true)
				rendering.drawList[objectID] = mat
			end
			if ObjectCreated then
				ObjectCreated(objectID, mat, 3)
			end
		end
	end
end


local function _CleanupTextures(rendering)
	for i = 1, #rendering.loadedTextures do
		gl.DeleteTexture(rendering.loadedTextures[i])
	end
	for _, oid in ipairs(rendering.spGetAllObjects()) do
		rendering.spSetLODCount(oid, 0)
	end
end

local function ObjectDestroyed(rendering, objectID, objectDefID)
	rendering.spDeactivateMaterial(objectID, 3)

	local mat = rendering.drawList[objectID]
	if mat then
		local _ObjectDestroyed = mat[rendering.ObjectDestroyed]
		if _ObjectDestroyed then
			_ObjectDestroyed(objectID, 3)
		end
		rendering.drawList[objectID] = nil
	end
end

local function DrawObject(rendering, objectID, objectDefID, drawMode)
	local mat = rendering.drawList[objectID]
	if not mat then
		return
	end

	local luaShaderObj = (drawMode == 5) and mat.deferredShaderObj or mat.standardShaderObj
	local _DrawObject = mat[rendering.DrawObject]
	if _DrawObject then
		return _DrawObject(objectID, objectDefID, mat, drawMode, luaShaderObj)
	end
end


-----------------------------------------------------------------
-- Gadget Functions
-----------------------------------------------------------------

function gadget:SunChanged()
	sunChanged = true
end

function gadget:DrawGenesis()
	for _, rendering in ipairs(allRendering) do
		for _, mat in pairs(rendering.materialDefs) do
			local SunChangedFunc = (sunChanged and mat.SunChanged) or nil
			local DrawGenesisFunc = mat.DrawGenesis

			if SunChangedFunc or DrawGenesisFunc then
				for _, shaderObject in pairs({mat.standardShaderObj, mat.deferredShaderObj}) do
					shaderObject:ActivateWith( function ()
						if SunChangedFunc then
							SunChangedFunc(shaderObject)
						end
						if DrawGenesisFunc then
							DrawGenesisFunc(shaderObject)
						end
					end)
				end
			end
		end
	end

	if sunChanged then
		sunChanged = false
	end

	sunChanged = false
end

-----------------------------------------------------------------
-----------------------------------------------------------------

local n = -1
local init = true
function gadget:Update()
	if init then
		ToggleShadows()
		init = true
	end
	if (n < Spring.GetDrawFrame()) then
		n = Spring.GetDrawFrame() + Spring.GetFPS()

		if (advShading ~= Spring.HaveAdvShading()) then
			ToggleAdvShading()
		elseif advShading and normalmapping and shadows ~= Spring.HaveShadows() then
			--ToggleShadows()
		end
	end
end

-----------------------------------------------------------------
-----------------------------------------------------------------

function gadget:UnitFinished(unitID, unitDefID)
	idToDefID[unitID] = unitDefID
	ObjectFinished(unitRendering, unitID, unitDefID)
end

function gadget:FeatureCreated(featureID)
	idToDefID[-featureID] = Spring.GetFeatureDefID(featureID)
	ObjectFinished(featureRendering, featureID, idToDefID[-featureID])
end

function gadget:RenderUnitDestroyed(unitID, unitDefID)
	idToDefID[unitID] = nil  --not really required
	ObjectDestroyed(unitRendering, unitID, unitDefID)
end

function gadget:FeatureDestroyed(featureID)
	idToDefID[-featureID] = nil --not really required
	ObjectDestroyed(featureRendering, featureID, Spring.GetFeatureDefID(featureID))
end

-----------------------------------------------------------------
-----------------------------------------------------------------

---------------------------
-- Draw{Unit, Feature}(id, drawMode)

-- With enum drawMode {
-- notDrawing = 0,
-- normalDraw = 1,
-- shadowDraw = 2,
-- reflectionDraw = 3,
-- refractionDraw = 4,
-- gameDeferredDraw = 5,
-- };
-----------------

function gadget:DrawUnit(unitID, drawMode)
	return DrawObject(unitRendering, unitID, idToDefID[unitID], drawMode)
end

function gadget:DrawFeature(featureID, drawMode)
	return DrawObject(featureRendering, featureID, idToDefID[-featureID], drawMode)
end

-----------------------------------------------------------------
-----------------------------------------------------------------

gadget.UnitReverseBuilt = gadget.RenderUnitDestroyed
gadget.UnitCloaked   = gadget.RenderUnitDestroyed
gadget.UnitDecloaked = gadget.UnitFinished


-- NOTE: No feature equivalent (features can't change team)
function gadget:UnitGiven(unitID, ...)
	if not select(3, Spring.GetUnitIsStunned(unitID)) then
		gadget:RenderUnitDestroyed(unitID, ...)
		gadget:UnitFinished(unitID, ...)
	end
end

-----------------------------------------------------------------
-----------------------------------------------------------------

function gadget:Initialize()
	--// GG assignment
	GG.CUS = allRendering

	--// load the materials config files
	local unitMaterialDefs, featureMaterialDefs = _LoadMaterialConfigFiles(MATERIALS_DIR)
	--// process the materials (compile shaders, load textures, ...)
	_ProcessMaterials(unitRendering,    unitMaterialDefs)
	_ProcessMaterials(featureRendering, featureMaterialDefs)

	--// material initialization
	for _, unitID in ipairs(Spring.GetAllUnits()) do
		ResetUnit(unitID)
	end
	for _, featureID in ipairs(Spring.GetAllFeatures()) do
		ResetFeature(featureID)
	end
	

	local shadows = Spring.HaveShadows()
	local normalmapping = tonumber(Spring.GetConfigInt("NormalMapping", 1) or 0) > 0
	local treewind = tonumber(Spring.GetConfigInt("TreeWind", 1) or 1) > 0

	local commonOptions = {
		shadowmapping 	= shadows,
		normalmapping 	= normalmapping,
		treewind		= treewind,
	}

	local seenOptions = {}
	for _, rendering in ipairs(allRendering) do
		for matName, matTable in pairs(rendering.materialDefs) do
			local optTableStd = Spring.Utilities.MergeWithDefault(matTable.shaderOptions, commonOptions)
			local optTableDef = Spring.Utilities.MergeWithDefault(matTable.deferredOptions, commonOptions)

			for opt, _ in pairs(optTableStd) do
				if not seenOptions[opt] then
					seenOptions[opt] = true
					gadgetHandler:AddChatAction(opt, _ProcessOptions)
				end
			end

			for opt, _ in pairs(optTableDef) do
				if not seenOptions[opt] then
					seenOptions[opt] = true
					gadgetHandler:AddChatAction(opt, _ProcessOptions)
				end
			end

		end
	end

	--// insert synced actions
	--gadgetHandler:AddSyncAction("unitshaders_reverse", UnitReverseBuilt)
	--gadgetHandler:AddChatAction("normalmapping", ToggleNormalmapping)
	--gadgetHandler:AddChatAction("treewind", ToggleTreeWind)
end

--// Workaround: unsynced LuaRules doesn't receive Shutdown events
cusShutdown = Script.CreateScream()
cusShutdown.func = function()
	 --// unload textures, so the user can do a `/luarules reload` to reload the normalmaps
	for _, rendering in ipairs(allRendering) do
		_CleanupTextures(rendering)
	end

	--// GG de-assignment
	GG.CUS = nil
end