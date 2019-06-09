-- $Id$
--------------------------------------------------------------------------------
--------------------------------------------------------------------------------

local function SunChanged(curShaderObj)
	curShaderObj:SetUniformAlways("shadowDensity", gl.GetSun("shadowDensity" ,"unit"))

	curShaderObj:SetUniformAlways("sunAmbient", gl.GetSun("ambient" ,"unit"))
	curShaderObj:SetUniformAlways("sunDiffuse", gl.GetSun("diffuse" ,"unit"))
	curShaderObj:SetUniformAlways("sunSpecular", gl.GetSun("specular" ,"unit"))
end

local materials = {
	feature_tree = {
		shaderDefinitions = {
			"#define use_normalmapping",
			"#define deferred_mode 0",
			"#define SPECULARSUNEXP 16.0",
			"#define SPECULARMULT 1.0",
			"#define SHADOW_SOFTNESS SHADOW_HARD", -- cuz shadow for swaying trees is bugged anyway
		},
		deferredDefinitions = {
			--"#define use_normalmapping", --very expensive for trees (too much overdraw)
			"#define deferred_mode 1",
			"#define SPECULARSUNEXP 16.0",
			"#define SPECULARMULT 1.0",
			"#define SHADOW_SOFTNESS SHADOW_HARD", -- cuz shadow for swaying trees is bugged anyway
			"#define MAT_IDX 128",
		},
		shaderPlugins = {
			VERTEX_GLOBAL_NAMESPACE = [[
				vec2 getWind(int period) {
					vec2 wind;
					wind.x = sin(period * 5.0);
					wind.y = cos(period * 5.0);
					return wind * 10.0f;
				}
			]],
			VERTEX_PRE_TRANSFORM = [[
				// adapted from 0ad"s model_common.vs

				vec2 curWind = getWind(simFrame / 750);
				vec2 nextWind = getWind(simFrame / 750 + 1);
				float tweenFactor = smoothstep(0.0f, 1.0f, max(simFrame % 750 - 600, 0) / 150.0f);
				vec2 wind = mix(curWind, nextWind, tweenFactor);




				// fractional part of model position, clamped to >.4
				vec4 modelPos = gl_ModelViewMatrix[3];
				modelPos = fract(modelPos);
				modelPos = clamp(modelPos, 0.4, 1.0);

				// crude measure of wind intensity
				float abswind = abs(wind.x) + abs(wind.y);

				vec4 cosVec;
				float simTime = 0.02 * simFrame;
				// these determine the speed of the wind"s "cosine" waves.
				cosVec.w = 0.0;
				cosVec.x = simTime * modelPos[0] + vertex.x;
				cosVec.y = simTime * modelPos[2] / 3.0 + modelPos.x;
				cosVec.z = simTime * 1.0 + vertex.z;

				// calculate "cosines" in parallel, using a smoothed triangle wave
				vec4 tri = abs(fract(cosVec + 0.5) * 2.0 - 1.0);
				cosVec = tri * tri *(3.0 - 2.0 * tri);

				float limit = clamp((vertex.x * vertex.z * vertex.y) / 3000.0, 0.0, 0.2);

				float diff = cosVec.x * limit;
				float diff2 = cosVec.y * clamp(vertex.y / 30.0, 0.05, 0.2);

				vertex.xyz += cosVec.z * limit * clamp(abswind, 1.2, 1.7);

				vertex.xz += diff + diff2 * wind;
			]],
			FRAGMENT_POST_SHADING = [[
				//gl_FragColor.r=1.0;
			]]
		},
		force     = false, --// always use the shader even when normalmapping is disabled
		feature   = true, --// This is used to define that this is a feature shader
		usecamera = false,
		culling   = GL.BACK,
		texunits  = {
			[0] = "%%FEATUREDEFID:0",
			[1] = "%%FEATUREDEFID:1",
			[2] = "$shadow",
			--[3] = "$specular",
			[4] = "$reflection",
			[5] = "%NORMALTEX",
		},
		SunChanged = SunChanged,
	},
}

--------------------------------------------------------------------------------
--------------------------------------------------------------------------------
-- affected unitdefs

local featureMaterials = {}
local featureNameStubs = {
	-- all of the 0ad, beherith and artturi features start with these.
	{str = "ad0_", prefix = true},
	{str = "btree", prefix = true},
	{str = "art", prefix = true},
	-- Other trees will probably contain "tree" as a substring.
	{str = "tree", prefix = false},
}
local tex1_to_normaltex = {}
-- All feature defs that contain the string "aleppo" will be affected by it
for id, featureDef in ipairs(FeatureDefs) do
	for _,stubData in ipairs (featureNameStubs) do
		if featureDef.name and featureDef.name:find(stubData.str) and
			((not stubData.prefix) or featureDef.name:find(stubData.str) == 1) then
			--if featureDef.customParam.normaltex then
			if featureDef.model.textures and featureDef.model.textures.tex1 then
				-- Spring.Echo("Feature",featureDef.name,"seems like a nice tree, assigning the default normal texture to it.")
				if featureDef.name:find("btree") == 1 then --beherith"s old trees suffer if they get shitty normals
					featureMaterials[id] = {"feature_tree", NORMALTEX = "unittextures/blank_normal.tga"}
				else
					featureMaterials[id] = {"feature_tree", NORMALTEX = "unittextures/default_tree_normal.tga"}
				end
			end

			--TODO: dont forget the feature normals!
			--TODO: actually generate normals for all these old-ass features, and include them in BAR
			--TODO: add a blank normal map to avoid major fuckups.
			--Todo, grab the texture1 names for features in tex1_to_normaltex assignments,
			--and hope that I dont have to actually load the models to do so

		end
	end
end


--------------------------------------------------------------------------------
--------------------------------------------------------------------------------

return materials, featureMaterials

--------------------------------------------------------------------------------
--------------------------------------------------------------------------------
