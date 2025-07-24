
/*
====================================================================================================

    Copyright (C) 2025 Pyvtron VX Shaders - Pyvtron

    All Rights Reserved unless otherwise explicitly stated.

====================================================================================================
*/


layout(location = 0) out vec4 compositeOutput1;


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

float GetBayerNoise(){
	float noise  = bayer64(gl_FragCoord.xy);
	#ifdef TAA
		noise = fract(frameCounter * (1.0 / 8.0) + noise);
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




vec4 textureSmooth(in sampler2D tex, in vec2 coord)
{
	vec2 res = vec2(64.0f, 64.0f);

	coord *= res;
	coord += 0.5f;

	vec2 whole = floor(coord);
	vec2 part  = fract(coord);

	part.x = part.x * part.x * (3.0f - 2.0f * part.x);
	part.y = part.y * part.y * (3.0f - 2.0f * part.y);
	// part.x = 1.0f - (cos(part.x * 3.1415f) * 0.5f + 0.5f);
	// part.y = 1.0f - (cos(part.y * 3.1415f) * 0.5f + 0.5f);

	coord = whole + part;

	coord -= 0.5f;
	coord /= res;

	return texture(tex, coord);
}

float AlmostIdentity(in float x, in float m, in float n)
{
	if (x > m) return x;

	float a = 2.0f * n - m;
	float b = 2.0f * m - 3.0f * n;
	float t = x / m;

	return (a * t + b) * t * t + n;
}


float GetWaves(vec3 position) {

    float wavesTime = frameTimeCounter * 0.7;

    vec2 p = position.xz / 20.0f;

    p.xy -= position.y / 20.0f;

    p.x = -p.x;

    p.x += wavesTime / 40.0f;
    p.y -= wavesTime / 40.0f;

    float weight = 1.0f;
    float weights = weight;

    float allwaves = 0.0f;

    float wave = textureSmooth(noisetex, (p * vec2(2.0f, 1.2f))  + vec2(0.0f,  p.x * 2.1f) ).z;
            p /= 2.1f;
            //p *= pow(2.0f, 1.0f);
            p.y -= wavesTime / 20.0f;
            p.x -= wavesTime / 30.0f;
    allwaves += wave;

    weight = 4.1f;
    weights += weight;
        wave = textureSmooth(noisetex, (p * vec2(2.0f, 1.4f))  + vec2(0.0f,  -p.x * 2.1f) ).z;
            p /= 1.5f;
            //p *= pow(2.0f, 2.0f);
            p.x += wavesTime / 20.0f;
        wave *= weight;
    allwaves += wave;

    weight = 17.25f;
    weights += weight;
        wave = (textureSmooth(noisetex, (p * vec2(1.0f, 0.75f))  + vec2(0.0f,  p.x * 1.1f) ).x);
            p /= 1.5f;
            p.x -= wavesTime / 55.0f;
        wave *= weight;
    allwaves += wave;

    weight = 15.25f;
    weights += weight;
        wave = (textureSmooth(noisetex, (p * vec2(1.0f, 0.75f))  + vec2(0.0f,  -p.x * 1.7f) ).x);
            p /= 1.9f;
            p.x += wavesTime / 155.0f;
        wave *= weight;
    allwaves += wave;

    weight = 29.25f;
    weights += weight;
        wave = abs(textureSmooth(noisetex, (p * vec2(1.0f, 0.8f))  + vec2(0.0f,  -p.x * 1.7f) ).y * 2.0f - 1.0f);
            p /= 2.0f;
            p.x += wavesTime / 155.0f;
        wave = 1.0f - AlmostIdentity(wave, 0.2f, 0.1f);
        wave *= weight;
    allwaves += wave;

    weight = 15.25f;
    weights += weight;
        wave = abs(textureSmooth(noisetex, (p * vec2(1.0f, 0.8f))  + vec2(0.0f,  p.x * 1.7f) ).y * 2.0f - 1.0f);
        wave = 1.0f - AlmostIdentity(wave, 0.2f, 0.1f);
        wave *= weight;
    allwaves += wave;

    allwaves /= weights;

    return allwaves;
}

vec3 GetWavesNormal(vec3 position)
{

	float WAVE_HEIGHT = 1.5;

	const float sampleDistance = 11.0f;

	position -= vec3(0.005f, 0.0f, 0.005f) * sampleDistance;

	float wavesCenter = GetWaves(position);
	float wavesLeft = GetWaves(position + vec3(0.01f * sampleDistance, 0.0f, 0.0f));
	float wavesUp   = GetWaves(position + vec3(0.0f, 0.0f, 0.01f * sampleDistance));

	vec3 wavesNormal;
		 wavesNormal.r = wavesCenter - wavesLeft;
		 wavesNormal.g = wavesCenter - wavesUp;

		 wavesNormal.r *= 10.0f * WAVE_HEIGHT / sampleDistance;
		 wavesNormal.g *= 10.0f * WAVE_HEIGHT / sampleDistance;

		 wavesNormal.b = sqrt(1.0f - wavesNormal.r * wavesNormal.r - wavesNormal.g * wavesNormal.g);
		 wavesNormal.rgb = normalize(wavesNormal.rgb);



	return wavesNormal.rgb;
}

vec3 GetWavesNormalFromTex(vec3 position) {

	vec2 coord = position.xz;
	vec3 lightVector = refract(worldLightVector, vec3(0.0, 1.0, 0.0), 1.0 / WATER_REFRACT_IOR);
	coord.x += position.y * lightVector.x / lightVector.y;
	coord.y += position.y * lightVector.z / lightVector.y;

	coord *= 0.02;
	coord = mod(coord, vec2(1.0));

	vec3 normal;
	normal.xyz = DecodeNormal(texture(colortex2, coord).xy);

	return normal;
}

void WaterRefractionLite(inout vec3 color, MaterialMask mask, vec3 normal, vec3 worldSpacePosition, vec3 viewPos, float waterDepth, float opaqueDepth)
{
	if (mask.water > 0.5 || mask.stainedGlass > 0.5)
	{
		vec2 refractCoord;

		float waterDeep = opaqueDepth - waterDepth;

		if (mask.water > 0.5){
			vec3 wavesNormal = GetWavesNormal(worldSpacePosition.xyz + cameraPosition.xyz).xzy;
			vec4 wnv = gbufferModelView * vec4(wavesNormal.xyz, 0.0);
			vec3 wavesNormalView = normalize(wnv.xyz);

			vec4 nv = gbufferModelView * vec4(0.0, 1.0, 0.0, 0.0);
			nv.xyz = normalize(nv.xyz);

			refractCoord = nv.xy - wavesNormalView.xy;
			refractCoord *= saturate(waterDeep) * 0.5 / (waterDepth + 0.0001);
			refractCoord += texcoord.st;
		}else{
			vec3 refractDir = refract(normalize(viewPos), normal, 0.66);
			refractDir = refractDir / saturate(dot(refractDir, -normal));
			refractDir *= saturate(waterDeep * 2.0) * 0.125;

			vec4 refractPos = vec4(viewPos + refractDir, 0.0);
			refractPos = gbufferProjection * refractPos;

			refractCoord = refractPos.xy / refractPos.w * 0.5 + 0.5;
		}

		float currentDepth = texture(gdepthtex, texcoord.st).x;
		float refractDepth = texture(depthtex1, refractCoord).x;
		if(refractDepth < currentDepth) refractCoord = texcoord.st;

		refractCoord = (refractCoord.x > 1.0 || refractCoord.x < 0.0 || refractCoord.y > 1.0 || refractCoord.y < 0.0) ? texcoord.st : refractCoord;

		color = GammaToLinear(texture(colortex1, refractCoord).rgb);
	}
}

#include "/Include/SSR.glsl"

void 	CalculateSpecularReflections(inout vec3 color, in vec3 viewDir, in vec3 normal, in vec3 albedo, in Material material, in float skylight, in bool isWater)
{

	bool totalInternalReflection = texture(colortex1, texcoord.st).a > 0.5;

	vec3 reflection = GammaToLinear(texture(colortex3, texcoord.st).rgb);

	reflection *= mix(vec3(1.0), albedo, vec3(material.metalness));


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

		//if(isWater && isEyeInWater == 0) T=mix(0.1, T, 0.7);

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





void TransparentAbsorption(inout vec3 color, vec4 stainedGlassAlbedo)
{
	vec3 stainedGlassColor = normalize(stainedGlassAlbedo.rgb + 0.0001) * pow(length(stainedGlassAlbedo.rgb), 0.5);

	color *= GammaToLinear(mix(vec3(1.0), stainedGlassColor, vec3(pow(stainedGlassAlbedo.a, 0.2))));
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

#include "/Include/VolumetricClouds.glsl"
#include "/Include/VolumetricFog.glsl"
#include "/Include/CloudVolumetricFog.glsl"
#include "/Include/PE11Godray.glsl"


void Rain(inout vec3 color, in vec3 worldDir, in float rainMask, in float cloudShadow){
	if(isEyeInWater == 0.0 && wetness > 0.0){
		color *= 1.0 - rainMask * 0.3 * wetness * RAIN_VISIBILITY;

		color += rainMask * (colorSkylight + colorSunlight) * 0.005 * wetness * RAIN_VISIBILITY;

		float sparkliness = mix(2.0, 3.0, dot(worldDir, worldLightVector) * 0.5 + 0.5);
		float sparkleNoise = Get3DNoise(worldDir * 170.0 * vec3(1.0, 0.1, 1.0) + vec3(frameTimeCounter * 310.0) * vec3(1.0, 0.5, 0.25));
		float rainSparkleSunlight = rainMask / (pow(sparkleNoise, sparkliness) * 40.0 + 0.001) ;
		color += rainSparkleSunlight * 0.05 * colorSunlight * (MiePhase(0.8, worldDir, worldLightVector) + MiePhase(0.5, worldDir, -worldLightVector)) * cloudShadow * wetness * RAIN_VISIBILITY;
	}
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

void LowlightColorFade(inout vec3 color){
		float luminance = Luminance(color);
		if (luminance < 2e-3) color = mix(color, luminance * vec3(0.48f, 0.62f, 1.0f) / Luminance(vec3(vec3(0.48f, 0.62f, 1.0f))), (2e-3 - luminance)/2.5e-3);
}



/////////////////////////MAIN//////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
/////////////////////////MAIN//////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
void main()
{

	GbufferData gbuffer 			= GetGbufferData();
	CloudProperties cloudProperties = GetGlobalCloudProperties();
	MaterialMask materialMaskSoild 	= CalculateMasks(gbuffer.materialIDL);
	MaterialMask materialMask 		= CalculateMasks(gbuffer.materialIDW);

	float noise = GetBayerNoise();
	float globalCloudShadow	= GetSmoothCloudShadow();

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

	if (materialMask.stainedGlass > 0.5){
		TransparentAbsorption(color, gbuffer.albedoW);
	}

	if (gbuffer.material.doCSR){
		CalculateSpecularReflections(color, viewDir, gbuffer.normalW, gbuffer.albedo, gbuffer.material, gbuffer.lightmapW.g, materialMask.water > 0.5);
	}


	color /= compositeOutputFactor;

	#ifdef SPECULAR_HELDLIGHT
	if (heldBlockLightValue + heldBlockLightValue2 > 0.0 && materialMask.sky < 0.5){
		TorchSpecularHighlight(color, worldPos, viewDir, waterDepth, gbuffer.albedo, gbuffer.normalW, gbuffer.material);
	}
	#endif

	if(isEyeInWater==1){
		PeGodrayUW(color, worldPos, worldDir, globalCloudShadow, noise);
	}

	if (isEyeInWater == 0 && materialMask.sky < 0.5){
		LandAtmosphericScattering(color, waterDepth, worldDir);
	}

	#ifdef VFOG
	if (isEyeInWater == 0){
		vec3 rayWorldPos = worldPos;
		if (materialMask.sky > 0.5) rayWorldPos = worldDir * far * 1.2;
		VolumetricFog(color, vec3(0.0), rayWorldPos, worldDir, cloudProperties, noise, globalCloudShadow);
	}
	#endif

	Rain(color, worldDir, gbuffer.rainAlpha, globalCloudShadow);

	BlindnessFog(color, waterDepth, worldDir);

	SelectionBox(color, gbuffer.albedo, materialMaskSoild.selection > 0.5 && isEyeInWater < 2.5);

	#ifdef LOWLIGHT_COLORFADE
		LowlightColorFade(color);
	#endif

	color *= compositeOutputFactor;
	color = LinearToGamma(color);

	compositeOutput1 = vec4(color.rgb, 1.0);
}

/* DRAWBUFFERS:1 */
