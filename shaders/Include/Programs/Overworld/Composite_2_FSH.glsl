
/*
====================================================================================================

    Copyright (C) 2025 Pyvtron VX Shaders - Pyvtron

    All Rights Reserved unless otherwise explicitly stated.

====================================================================================================
*/


layout(location = 0) out vec4 compositeOutput3;


#include "/Include/Uniforms.glsl"
#include "/Include/Core/Core.glsl"


const bool 		shadowtex0Mipmap           = true;
const bool 		shadowtex0Nearest          = false;
const bool 		shadowtex1Mipmap           = true;
const bool 		shadowtex1Nearest          = false;
const bool 		shadowcolor0Mipmap         = true;
const bool 		shadowcolor0Nearest        = false;
const bool 		shadowcolor1Mipmap         = true;
const bool 		shadowcolor1Nearest        = false;
uniform sampler2D shadowtex0;
uniform sampler2D shadowtex1;
uniform sampler2D shadowcolor0;
uniform sampler2D shadowcolor1;

in vec4 texcoord;
in vec3 lightVector;
in vec3 upVector;

in float timeMidnight;
in float timeNoon;

in vec3 colorSunlight;
in vec3 colorMoonlight;
in vec3 colorSkylight;
in vec3 colorTorchlight;

in vec3 worldSunVector;
in vec3 worldLightVector;

in vec4 skySHR;
in vec4 skySHG;
in vec4 skySHB;



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

float ViewToScreenSpaceDepth(float depth) {
	depth = (1.0 / depth - gbufferProjectionInverse[3][3]) / gbufferProjectionInverse[2][3];
    return depth * 0.5 + 0.5;
}

vec3 WorldPosToShadowPos(vec3 worldPos)
{
	vec4 sp = (shadowModelView * vec4(worldPos, 1.0));
	sp = shadowProjection * sp;
	sp /= sp.w;

	sp.z = mix(sp.z, 0.5, 0.8);
	sp = sp * 0.5f + 0.5f;		//Transform from shadow space to shadow map coordinates

	return sp.xyz;
}

vec2 DistortShadowProjPos(vec2 sp){
	sp = sp * 2.0 - 1.0;
	float dist = sqrt(sp.x * sp.x + sp.y * sp.y);
	float distortFactor = (1.0f - SHADOW_MAP_BIAS) + dist * SHADOW_MAP_BIAS;
	sp.xy *= 0.95f / distortFactor;
	return sp * 0.5 + 0.5;
}

vec3 WorldPosToShadowProjPos(vec3 worldPos, out float dist, out float distortFactor)
{
	vec4 sp = (shadowModelView * vec4(worldPos, 1.0));
	sp = shadowProjection * sp;
	sp /= sp.w;

	dist = sqrt(sp.x * sp.x + sp.y * sp.y);
	distortFactor = (1.0f - SHADOW_MAP_BIAS) + dist * SHADOW_MAP_BIAS;
	sp.xy *= 0.95f / distortFactor;
	sp.z = mix(sp.z, 0.5, 0.8);
	sp = sp * 0.5f + 0.5f;		//Transform from shadow space to shadow map coordinates




	return sp.xyz;
}


#include "/Include/Core/GBufferData.glsl"
#include "/Include/Core/Mask.glsl"

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

float GetBayerNoise(float d){
	float noise  = bayer64(gl_FragCoord.xy);
	#ifdef TAA
		noise = fract(frameCounter * (1.0 / d) + noise);
	#endif
	return noise;
}

float GetSmoothCloudShadow(){
	float globalCloudShadow = 1.0;
	#ifdef VOLUMETRIC_CLOUDS
		#ifdef CLOUD_SHADOW
			globalCloudShadow	= texelFetch(colortex7, ivec2(4, 0), 0).a;
		#endif
	#endif
	return globalCloudShadow;
}





void LandAtmosphericScattering(inout vec3 color, in float dist, vec3 worldDir)
{

		//dist = min(dist, max(far * 0.75, 512));

		float depthFactor = dist / max(far, 512.0);
		depthFactor = pow(depthFactor, 2.0);
		#ifndef INDOOR_FOG
			depthFactor *= pow(eyeBrightnessSmooth.y / 240.0f, 6.0f);
		#endif
		depthFactor = min(depthFactor, 1.2);

		depthFactor *= 0.01;
		//depthFactor = 0.012;

		float SdotU = abs(dot(worldSunVector, vec3(0.0, 1.0, 0.0)));
		float disc = 1.0 - pow(curve(saturate((dot(worldDir, worldSunVector) - 0.4) * 1.5)), 2.0);

		vec3 atmosphere = AtmosphericScattering(normalize(worldDir), worldSunVector, 1.0, depthFactor);
		atmosphere += AtmosphericScattering(normalize(worldDir), -worldSunVector, 1.0, depthFactor) * NIGHT_BRIGHTNESS;
		atmosphere *= RAYLEIGH_AMOUNT * 0.4 * (1.0 - 0.85 * wetness);
		//atmosphere = mix(atmosphere, vec3(Luminance(atmosphere)), max(SdotU * 0.3, wetness * 0.5 * disc));

		color += atmosphere;

		//if(depthFactor > 0.012) color.r = 1.0;
}


#include "/Include/SSR.glsl"
#include "/Include/VolumetricClouds.glsl"
#include "/Include/VolumetricFog.glsl"

vec3 ComputeFakeSkyReflection(vec3 reflectWorldDir, bool isSmooth)
{
	vec2 skyImageCoord = ProjectSky(reflectWorldDir, SKY_IMAGE_LOD);
	vec4 sky = texture(colortex3, skyImageCoord);
	sky.rgb =  GammaToLinear(sky.rgb);


	if (isSmooth) {
		vec3 sunDisc = vec3(RenderSunDisc(reflectWorldDir, worldSunVector));
		//sunDisc *= colorSunlight;
		#if (defined MOON_TEXTURE && !defined COMPATIBLE_MODE)
			vec3 moonDisc = vec3(RenderMoonDiscReflection(reflectWorldDir, worldSunVector));
		#else
			vec3 moonDisc = vec3(RenderMoonDisc(reflectWorldDir, worldSunVector));
		#endif

		sunDisc *= colorSunlight;
		sunDisc += moonDisc * colorMoonlight;

		sunDisc *= 2e4;

		#ifdef VOLUMETRIC_CLOUDS
			#ifdef CLOUD_SHADOW
				sunDisc *= sky.a;
			#endif
		#endif

		sky.rgb += sunDisc * compositeOutputFactor;
	}

	return sky.rgb;
}


vec4 CalculateSpecularReflections(in vec3 viewPos, in vec3 worldPos, in vec3 viewDir, in vec3 normal, in float gbufferdepth, in vec3 albedo, in Material material, in float skylight, in bool isHand, in bool isSmooth)
{
	bool totalInternalReflection = texture(colortex1, texcoord.st).a > 0.5;

	mat3 rot = GetRotationMatrix(vec3(0, 0, 1), normal);
	vec3 tangentView = viewDir * rot;
	float NdotU = saturate((dot(normal, upVector) + 0.7) * 2.0) * 0.75 + 0.25;
	float NdotV = max(1e-12, dot(-viewDir, normal));
	float noise = GetBayerNoise(6.0);


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

		if(hit){
			vec3 hitPos = GetViewPosition(screenPos.xy, texture(gdepthtex, screenPos.xy).x);
			hitDepth = distance(hitPos, viewPos);
		}else{
			hitDepth = 1.0;
		}

		hitDepth = 1.0;
	}

	reflection = GammaToLinear(texture(colortex1, screenPos.xy).rgb);

	vec3 rayDirectionWorld = mat3(gbufferModelViewInverse) * rayDirection;
	vec3 skyReflection = vec3(0.0);
	if(!totalInternalReflection && isEyeInWater == 0){
		skylight = clamp(fma(skylight, 8.0f, -1.5f), 0.0f, 1.0f);
		skyReflection = ComputeFakeSkyReflection(rayDirectionWorld, isSmooth);
		skyReflection = mix(vec3(0.0), skyReflection, skylight);
		skyReflection *= NdotU;
	}
	if(totalInternalReflection) skyReflection = GammaToLinear(texture(colortex1, texcoord.st).rgb);

	reflection = hit ? reflection : skyReflection;



	#if defined LANDFOG_REFLECTION || defined VFOG_REFLECTION
		float dist = ScreenToViewSpaceDepth(gbufferdepth);
		float rDist = ScreenToViewSpaceDepth(1.0);
		bool notSky = false;

		#ifdef VFOG
			#ifdef VFOG_REFLECTION
				vec3 endPos = worldPos + rayDirectionWorld * max(far * 1.2 - dist, 0.0);
			#endif
		#endif

		if(hit){
			notSky = floor(texture(colortex6, screenPos.xy).b * 255.0) > 0.5;

			vec3 hitPos = GetViewPosition(screenPos.xy, texture(gdepthtex, screenPos.xy).x);
			rDist = distance(hitPos, viewPos);

			if(!isSmooth) hitDepth = saturate(max(rDist * 2.0, 3.0 * material.roughness));

			#ifdef VFOG
				#ifdef VFOG_REFLECTION
					if(notSky) endPos = mat3(gbufferModelViewInverse) * hitPos;
				#endif
			#endif
		}

		if (isEyeInWater == 0){
			reflection /= compositeOutputFactor;

			#ifdef LANDFOG_REFLECTION
				if(notSky) LandAtmosphericScattering(reflection, dist + rDist, rayDirectionWorld);
			#endif

			#ifdef VFOG
				#ifdef VFOG_REFLECTION
					VolumetricFog(reflection, worldPos, endPos, rayDirectionWorld, GetGlobalCloudProperties(), GetBayerNoise(9.0), GetSmoothCloudShadow());
				#endif
			#endif

			reflection *= compositeOutputFactor;
		}
	#else
		if(hit){
			vec3 hitPos = GetViewPosition(screenPos.xy, texture(gdepthtex, screenPos.xy).x);
			float rDist = distance(hitPos, viewPos);

			if(!isSmooth) hitDepth = saturate(max(rDist * 2.0, 3.0 * material.roughness));
		}
	#endif

	#if TEXTURE_PBR_FORMAT == 1
	if(!totalInternalReflection) {
		reflection *= FresnelNonpolarized(MdotV, ComplexVec3(airMaterial.n, airMaterial.k), ComplexVec3(material.n, material.k));
	}
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
	vec3 worldPos		= mat3(gbufferModelViewInverse) * viewPos;
	vec3 viewDir 		= normalize(viewPos.xyz);


	vec4 reflection = vec4(0.0);

	if (gbuffer.material.doCSR){
		reflection = CalculateSpecularReflections(viewPos, worldPos, viewDir, gbuffer.normalW, gbuffer.depthW, gbuffer.albedo, gbuffer.material, gbuffer.lightmapW.g, materialMask.hand > 0.5, isSmooth);
	}
	reflection.rgb = LinearToGamma(reflection.rgb);

	vec4 data6 = texture(colortex6, texcoord.st);

	compositeOutput3 = reflection;
}

/* DRAWBUFFERS:3 */
