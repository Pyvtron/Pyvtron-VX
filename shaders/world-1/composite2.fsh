#version 450

layout(location = 0) out vec4 compositeOutput3;


#define world
#define composite2
#define fsh

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

vec3 GetViewPositionRaw(in vec2 coord, in float depth)
{
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

void ApplyMaterial(inout Material material, in MaterialMask materialMask, inout bool isSmooth){
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

float GetBayerNoise(){
	float noise  = bayer64(gl_FragCoord.xy);
	#ifdef TAA
		noise = fract(frameCounter * (1.0 / 8.0) + noise);
	#endif
	return noise;
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

#include "/OldInclude/SSR.glsl"


vec4 CalculateSpecularReflections(in vec3 viewPos, in vec3 viewDir, in vec3 normal, in float gbufferdepth, in vec3 albedo, in Material material, in bool isHand, in bool isSmooth)
{
	mat3 rot = GetRotationMatrix(vec3(0, 0, 1), normal);
	vec3 tangentView = viewDir * rot;
	float NdotV = max(1e-12, dot(-viewDir, normal));
	float noise = GetBayerNoise();


	vec3 screenPos = vec3(texcoord.st, gbufferdepth);

	vec3 reflection;
	float hitDepth;
	vec3 rayDirection;
	float MdotV;

	bool hit;

	if(isSmooth){
		rayDirection = reflect(viewDir, normal);
		MdotV = dot(normal, -viewDir);
		float NdotL = abs(dot(normal, rayDirection));

		hit = rayTrace(viewPos, rayDirection, NdotV, noise, isHand, screenPos) && NdotL > 0.0;

		hitDepth = 0.0;

	}else{

		vec3 facetNormal = rot * sampleGGXVNDF(-tangentView, material.roughness, RandNext2F());
		MdotV = dot(facetNormal, -viewDir);
		rayDirection = viewDir + 2.0 * MdotV * facetNormal;
		float NdotL = abs(dot(normal, rayDirection));

		hit = rayTrace(viewPos, rayDirection, NdotV, noise, isHand, screenPos) && NdotL > 0.0;

		hitDepth = 1.0;
	}

	reflection = GammaToLinear(texture(colortex1, screenPos.xy).rgb);

	reflection = hit ? reflection : vec3(0.0);

	float rDist = 96.0;
	if(hit){
		vec3 hitPos = GetViewPosition(screenPos.xy, texture(gdepthtex, screenPos.xy).x);
		rDist = distance(hitPos, viewPos);

		if(!isSmooth) hitDepth = saturate(max(rDist * 2.0, 3.0 * material.roughness));
	}
	reflection += NetherFog(rDist) * compositeOutputFactor;


	#if TEXTURE_PBR_FORMAT == 1
		reflection *= FresnelNonpolarized(MdotV, ComplexVec3(airMaterial.n, airMaterial.k), ComplexVec3(material.n, material.k));
	#endif

	return vec4(reflection.rgb, hitDepth);
}

/////////////////////////MAIN//////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
/////////////////////////MAIN//////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
void main()
{

	GbufferData gbuffer 			= GetGbufferData();
	MaterialMask materialMaskSoild 	= CalculateMasks(gbuffer.materialIDL);
	MaterialMask materialMask 		= CalculateMasks(gbuffer.materialIDW);

	FixParticleMask(materialMaskSoild, materialMask);
	bool isSmooth = false;
	ApplyMaterial(gbuffer.material, materialMask, isSmooth);

	vec3 viewPos 		= GetViewPosition(texcoord.st, gbuffer.depthW);
	vec3 viewDir 		= normalize(viewPos.xyz);


	vec4 reflection = vec4(0.0);
	bool hit = false;

	if (gbuffer.material.doCSR){
		reflection = CalculateSpecularReflections(viewPos, viewDir, gbuffer.normalW, gbuffer.depthW, gbuffer.albedo, gbuffer.material, materialMask.hand > 0.5, isSmooth);
	}
	reflection.rgb = LinearToGamma(reflection.rgb);

	vec4 data6 = texture(colortex6, texcoord.st);

	compositeOutput3 = reflection;
}

/* DRAWBUFFERS:3 */
