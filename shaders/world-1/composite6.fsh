#version 450

layout(location = 0) out vec4 compositeOutput1;

#include "/OldInclude/uniform.glsl"

#include "/OldInclude/core/Common.inc"

/////////////////////////CONFIGURABLE VARIABLES////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
/////////////////////////CONFIGURABLE VARIABLES////////////////////////////////////////////////////////////////////////////////////////////////////////////////////





/////////////////////////UNIFORMS//////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
/////////////////////////UNIFORMS//////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////


uniform float BiomeNetherWastesSmooth;
uniform float BiomeSoulSandValleySmooth;
uniform float BiomeCrimsonForestSmooth;
uniform float BiomeWarpedForestSmooth;
uniform float BiomeBasaltDeltasSmooth;

in vec4 texcoord;
in vec3 colorTorchlight;

/////////////////////////END OF CONFIGURABLE VARIABLES/////////////////////////////////////////////////////////////////////////////////////////////////////////////
/////////////////////////END OF CONFIGURABLE VARIABLES/////////////////////////////////////////////////////////////////////////////////////////////////////////////

vec3 GetViewPosition(in vec2 coord, in float depth)
{
	#ifdef TAA
		coord -= taaJitter * 0.5;
	#endif

	vec3 screenPos = vec3(coord, depth) * 2.0 - 1.0;

	vec4 fragposition = gbufferProjectionInverse * vec4(screenPos, 1.0f);
		 fragposition /= fragposition.w;

	return fragposition.xyz;
}


float Get3DNoise(in vec3 pos)
{
	pos.xyz += 0.5f;

	vec3 p = floor(pos);
	vec3 f = fract(pos);

	f = smoothstep(vec3(0.0), vec3(1.0), f);

	vec2 uv =  (p.xy + p.z * vec2(-17.0f, -17.0f)) + f.xy;

	vec2 coord =  (uv + 0.5f) / 64.0;
	vec2 noiseSample = texture(noisetex, coord).xy;
	float xy1 = noiseSample.x;
	float xy2 = noiseSample.y;
	return mix(xy1, xy2, f.z);
}

float ScreenToViewSpaceDepth(float depth) {
    depth = depth * 2.0 - 1.0;
    return 1.0 / (depth * gbufferProjectionInverse[2][3] + gbufferProjectionInverse[3][3]);
}


#include "/OldInclude/core/GbufferData.inc"

#include "/OldInclude/core/Mask.inc"


void FixParticleMask(inout MaterialMask materialMaskSoild, inout MaterialMask materialMask){
	#if MC_VERSION >= 11500
	if(materialMaskSoild.particle > 0.5 || materialMaskSoild.particlelit > 0.5){
		materialMask.particle = 1.0;
		materialMask.water = 0.0;
		materialMask.stainedGlass = 0.0;
		materialMask.ice = 0.0;
		materialMask.sky = 0.0;
	}
	#endif
}

void ApplyMaterial(inout Material material, in MaterialMask materialMask, out bool isSmooth){
	if (materialMask.water > 0.5){
		material = material_water;
		isSmooth = true;
	}
	if (materialMask.stainedGlass > 0.5){
		material = material_glass;
		isSmooth = true;
	}
	if (materialMask.ice > 0.5){
		material = material_ice;
		isSmooth = true;
	}
}



vec4 NetherFogColor(){
	vec4 fog =	 vec4(0.99, 0.17, 0.005, 0.007) * BiomeNetherWastesSmooth;
	fog +=		 vec4(0.01, 0.035, 0.06, 0.005) * BiomeSoulSandValleySmooth;
	fog +=		 vec4(0.2, 0.02, 0.0, 0.007) * BiomeCrimsonForestSmooth;
	fog +=		 vec4(0.03, 0.1, 0.13, 0.005) * BiomeWarpedForestSmooth;
	fog +=		 vec4(0.4, 0.4, 0.4, 0.01) * BiomeBasaltDeltasSmooth;
	return fog;
}

vec3 NetherFog(float dist)
{
	dist = min(dist, far * 1.2);

	float fogDensity = NetherFogColor().w;
	float fogFactor = pow(1.0 - exp(-dist * fogDensity), 2.0);

	vec3 fogColor = NetherFogColor().xyz * 0.5;

	return fogFactor * fogColor;
}


void WaterRefractionLite(inout vec3 color, MaterialMask mask, vec3 normal, vec3 worldSpacePosition, vec3 viewPos, float waterDepth, float opaqueDepth)
{
	if (mask.stainedGlass > 0.5 || mask.ice > 0.5)
	{
		vec2 refractCoord;

		float waterDeep = opaqueDepth - waterDepth;

		vec3 refractDir = refract(normalize(viewPos), normal, 0.66);
		refractDir = refractDir / saturate(dot(refractDir, -normal));
		refractDir *= saturate(waterDeep * 2.0) * 0.125;

		vec4 refractPos = vec4(viewPos + refractDir, 0.0);
		refractPos = gbufferProjection * refractPos;

		refractCoord = refractPos.xy / refractPos.w * 0.5 + 0.5;

		float currentDepth = texture(gdepthtex, texcoord.st).x;
		float refractDepth = texture(depthtex1, refractCoord).x;
		if(refractDepth < currentDepth) refractCoord = texcoord.st;

		refractCoord = (refractCoord.x > 1.0 || refractCoord.x < 0.0 || refractCoord.y > 1.0 || refractCoord.y < 0.0) ? texcoord.st : refractCoord;

		color = GammaToLinear(texture(colortex1, refractCoord.xy).rgb);

		float rDist = ScreenToViewSpaceDepth(texture(depthtex1, refractCoord).x);

		color += NetherFog(rDist) * compositeOutputFactor;

	}
}




#include "/OldInclude/SSR.glsl"


void 	CalculateSpecularReflections(inout vec3 color, in vec3 viewDir, in vec3 normal, in vec3 albedo, in Material material)
{
	vec3 reflection = GammaToLinear(texture(colortex3, texcoord.st).rgb);

	reflection *= mix(vec3(1.0), albedo, vec3(material.metalness));

	color *= 1.0 - material.metalness;

	#if TEXTURE_PBR_FORMAT == 0

		vec3 Y = normalize(reflect(viewDir, normal) + normal * material.roughness);
		vec3 b = normalize(-viewDir + Y);

		float g = saturate(dot(normal, Y));

		float F = saturate(dot(normal, -viewDir));

		float D = saturate(dot(Y, b)); //D
	    float P = material.metalness * 0.96 + 0.04; //P
	    float L = pow(1.0 - D, 5.0); //L
	    float u = P + (1.0 - P) * L; //u

	    float I = material.roughness / 2.0; //I
	    float invI = 1 - I; //invI
	    float k = 1.0 / ((g * invI + I) * ((F + 0.8) * invI + I)); //k

	    float T = g * u * k; //T

		#ifdef ROUGHNESS_CLAMP
			T = mix(T, 0.0, saturate(material.roughness * 4.0 - 1.5));
		#endif

		T = mix(T, 1.0, material.metalness);

		vec3 temp = color;

		float diff = (length(color) - length(reflection)) / (length(color) + length(reflection));
		diff = sign(diff) * sqrt(abs(diff));
		T += 0.75 * diff * (1.0 - T) * T;

		color = mix(color, reflection, saturate(T));

		color += temp * material.metalness;

	#elif TEXTURE_PBR_FORMAT == 1

		#ifdef ROUGHNESS_CLAMP
			reflection *= 1.0 - saturate(material.roughness * 4.0 - 1.5);
		#endif

		color += reflection;

	#endif
}





void TransparentAbsorption(inout vec3 color, in vec4 stainedGlassAlbedo, in float depthL, in float depthW, in MaterialMask mask)
{
    if(mask.stainedGlass > 0.5){
        vec3 stainedGlassColor = normalize(stainedGlassAlbedo.rgb + 0.0001) * pow(length(stainedGlassAlbedo.rgb), 0.5);
        color *= GammaToLinear(mix(vec3(1.0), stainedGlassColor, vec3(pow(stainedGlassAlbedo.a, 0.2))));
    }else if(mask.water > 0.5 || mask.ice > 0.5 || isEyeInWater == 1) {
        float opaqueDepth 	= ScreenToViewSpaceDepth(depthL);
        float waterDepth 	= ScreenToViewSpaceDepth(depthW);
        float waterDeep = isEyeInWater > 0.5 ? waterDepth * 0.5 : opaqueDepth - waterDepth;
        color *= GammaToLinear(mix(vec3(1.0), vec3(0.1, 0.4, 1.0), min(waterDeep * 0.25, 0.5)));
    }
}


float G1V(float dotNV, float k)
{
	return 1.0 / (dotNV * (1.0 - k) + k);
}

vec3 SpecularGGX(vec3 N, vec3 V, vec3 L, float alpha, float F0)
{
	const float pi = 3.14159265359;
	//float alpha = roughness * roughness;

	vec3 H = normalize(V + L);

	float dotNL = saturate(dot(N, L));
	float dotNV = saturate(dot(N, V));
	float dotNH = saturate(dot(N, H));
	float dotLH = saturate(dot(L, H));

	float F, D, vis;

	float alphaSqr = alpha * alpha;
	float denom = dotNH * dotNH * (alphaSqr - 1.0) + 1.0;
	D = alphaSqr / (pi * denom * denom);

	float dotLH5 = pow(1.0f - dotLH, 5.0);
	F = F0 + (1.0 - F0) * dotLH5;

	float k = alpha / 2.0;
	vis = G1V(dotNL, k) * G1V(dotNV, k);

	vec3 specular = vec3(dotNL * D * F * vis);

	//specular = vec3(0.1);
	//#ifndef PHYSICALLY_BASED_MAX_ROUGHNESS
	//specular *= saturate(pow(1.0 - roughness, 0.7) * 2.0);
	//#endif


	return specular;
}

void TorchSpecularHighlight(inout vec3 color, in vec3 worldPos, in vec3 viewDir, in float dist, in vec3 albedo, in vec3 normal, in Material material){

	//vec3 specularHighlight = CalculateSpecularHighlightTorch(albedo, normal, -viewDir, -viewDir, material.roughness, material.f0, mat2x3(material.n, material.k));
	vec3 specularHighlight = SpecularGGX(normal, -viewDir, -viewDir, max(material.roughness, 0.002), material.metalness * 0.96 + 0.04) * 0.3;

	#ifdef FLASHLIGHT_HELDLIGHT
		float heldLightFalloff = 1.0 / pow(max(dist, 0.5), FLASHLIGHT_HELDLIGHT_FALLOFF);

		vec3 torchPos = worldPos.xyz + gbufferModelViewInverse[1].xyz * 0.1;
		vec3 torchPosL = torchPos + gbufferModelViewInverse[0].xyz * 0.23;
		vec3 torchPosR = torchPos - gbufferModelViewInverse[0].xyz * 0.23;
		vec3 torchDirL = normalize((gbufferModelView * vec4(torchPosL, 0.0)).xyz);
		vec3 torchDirR = normalize((gbufferModelView * vec4(torchPosR, 0.0)).xyz);
		float spotRadiusL = dot(torchDirL, vec3(0.0, 0.0, -1.0));
		float spotRadiusR = dot(torchDirR, vec3(0.0, 0.0, -1.0));
		spotRadiusL = saturate(spotRadiusL * 2.0 - 1.8);
		spotRadiusR = saturate(spotRadiusR * 2.0 - 1.8);

		heldLightFalloff *= (heldBlockLightValue2 * spotRadiusL + heldBlockLightValue * spotRadiusR);
	#else
		float heldLightFalloff = 1.0 / pow(max(dist, 0.5), HELDLIGHT_FALLOFF);

		heldLightFalloff *= (heldBlockLightValue + heldBlockLightValue2) * 0.4;
	#endif

	color += specularHighlight * heldLightFalloff * colorTorchlight * HELDLIGHT_BRIGHTNESS * albedo;
}


void BlindnessFog(inout vec3 color, in float dist, in vec3 worldDir)
{
	if (blindness < 0.001)
	{
		return;
	}
	float fogDensity = 1.0 * blindness;

	float fogFactor = pow(1.0 - exp(-dist * fogDensity), 2.0);

	vec3 fogColor = vec3(0.0);

	color = mix(color, fogColor, vec3(fogFactor));
}

void SelectionBox(inout vec3 color, in vec3 albedo, in bool isSelection){
	if (isSelection){
		float exposure = pow(textureLod(colortex7, vec2(0.0, 0.0), 0).a, 5.0);
		color = albedo * exposure * 1000.0;
	}
}



/////////////////////////MAIN//////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
/////////////////////////MAIN//////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
void main()
{

	GbufferData gbuffer 			= GetGbufferData();
	MaterialMask materialMaskSoild 	= CalculateMasks(gbuffer.materialIDL);
	MaterialMask materialMask 		= CalculateMasks(gbuffer.materialIDW);

	//float noise = GetBayerNoise();

	FixParticleMask(materialMaskSoild, materialMask);
	bool isSmooth = false;
	ApplyMaterial(gbuffer.material, materialMask, isSmooth);

	vec3 viewPos 		= GetViewPosition(texcoord.st, gbuffer.depthW);
	vec3 worldPos		= mat3(gbufferModelViewInverse) * viewPos;
	vec3 viewDir 		= normalize(viewPos.xyz);
	vec3 worldDir 		= normalize(worldPos.xyz);

	float opaqueDepth 	= ScreenToViewSpaceDepth(gbuffer.depthL);
	float waterDepth 	= ScreenToViewSpaceDepth(gbuffer.depthW);


	vec3 color = GammaToLinear(texture(colortex1, texcoord.st).rgb);


	WaterRefractionLite(color, materialMask, gbuffer.normalW, worldPos, viewPos, waterDepth, opaqueDepth);

	TransparentAbsorption(color, gbuffer.albedoW, gbuffer.depthL, gbuffer.depthW, materialMask);


	if (gbuffer.material.doCSR){
		CalculateSpecularReflections(color, viewDir, gbuffer.normalW, gbuffer.albedo, gbuffer.material);
	}

	color /= compositeOutputFactor;

	#ifdef SPECULAR_HELDLIGHT
		if(heldBlockLightValue + heldBlockLightValue2 > 0.0 && materialMask.sky < 0.5){
		TorchSpecularHighlight(color, worldPos, viewDir, waterDepth, gbuffer.albedo, gbuffer.normalW, gbuffer.material);
		}
	#endif

	color += NetherFog(waterDepth);

	BlindnessFog(color, waterDepth, worldDir);

	SelectionBox(color, gbuffer.albedo, materialMaskSoild.selection > 0.5 && isEyeInWater < 2.5);

	color *= compositeOutputFactor;
	color = LinearToGamma(color);

	compositeOutput1 = vec4(color.rgb, 1.0);
}

/* DRAWBUFFERS:1 */
