/*
====================================================================================================

    Copyright (C) 2025 Pyvtron VX Shaders - Pyvtron

    All Rights Reserved unless otherwise explicitly stated.

====================================================================================================
*/


layout(location = 0) out vec4 compositeOutput1;


#include "/Include/Uniforms.glsl"
#include "/Include/Core/Core.glsl"

/////////////////////////CONFIGURABLE VARIABLES////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
/////////////////////////CONFIGURABLE VARIABLES////////////////////////////////////////////////////////////////////////////////////////////////////////////////////





/////////////////////////UNIFORMS//////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
/////////////////////////UNIFORMS//////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////


const int 		RGB8        = 0;
const int 		RGBA8       = 0;
const int 		RGB16       = 0;
const int 		RGBA16      = 0;
const int 		RGBA32F 	= 0;


const int 		colortex0Format         = RGBA8;
const int 		colortex1Format         = RGBA16;
const int 		colortex2Format         = RGBA16;
const int 		colortex3Format 		= RGBA16;
const int 		colortex4Format 		= RGBA16;
const int 		colortex5Format 		= RGBA16;
const int 		colortex6Format 		= RGBA16;
const int 		colortex7Format 		= RGBA16;

const bool		colortex7Clear          = false;
const float		sunPathRotation			= -30;		// [-90 -89 -88 -87 -86 -85 -84 -83 -82 -81 -80 -79 -78 -77 -76 -75 -74 -73 -72 -71 -70 -69 -68 -67 -66 -65 -64 -63 -62 -61 -60 -59 -58 -57 -56 -55 -54 -53 -52 -51 -50 -49 -48 -47 -46 -45 -44 -43 -42 -41 -40 -39 -38 -37 -36 -35 -34 -33 -32 -31 -30 -29 -28 -27 -26 -25 -24 -23 -22 -21 -20 -19 -18 -17 -16 -15 -14 -13 -12 -11 -10 -9 -8 -7 -6 -5 -4 -3 -2 -1 0 1 2 3 4 5 6 7 8 9 10 11 12 13 14 15 16 17 18 19 20 21 22 23 24 25 26 27 28 29 30 31 32 33 34 35 36 37 38 39 40 41 42 43 44 45 46 47 48 49 50 51 52 53 54 55 56 57 58 59 60 61 62 63 64 65 66 67 68 69 70 71 72 73 74 75 76 77 78 79 80 81 82 83 84 85 86 87 88 89 90 ]

const int       superSamplingLevel 		= 0;
const float 	ambientOcclusionLevel 	= 0.0f;

const float 	centerDepthHalflife 	= 1.0;		// [0.5 0.7 1.0 1.5 2.0 3.0 5.0 7.0 10.0]

const float     wetnessHalflife 		= 200.0; 	// [10.0 20.0 30.0 50.0 75.0 100.0 150.0 200.0 300.0 500.0]
const float     drynessHalflife 		= 50.0; 	// [10.0 20.0 30.0 50.0 75.0 100.0 150.0 200.0 300.0 500.0]


const bool 		shadowHardwareFiltering1   = true;

const bool 		shadowtex0Mipmap           = true;
const bool 		shadowtex0Nearest          = false;
const bool 		shadowtex1Mipmap           = true;
const bool 		shadowtex1Nearest          = false;
const bool 		shadowcolor0Mipmap         = true;
const bool 		shadowcolor0Nearest        = false;
const bool 		shadowcolor1Mipmap         = true;
const bool 		shadowcolor1Nearest        = false;
uniform sampler2D shadowtex0;
uniform sampler2DShadow shadowtex1;
uniform sampler2D shadowcolor0;
uniform sampler2D shadowcolor1;

uniform float roataionAngle;
mat4 shadowRoataionMatrix = mat4(cos(roataionAngle * PI), sin(roataionAngle * PI), 0, 0,
                                -sin(roataionAngle * PI), cos(roataionAngle * PI), 0, 0,
                                                       0,                       0, 1, 0,
                                                       0,                       0, 0, 1);

mat4 shadowModelViewEnd = shadowModelView * shadowRoataionMatrix;


const bool		colortex1MipmapEnabled  = true;


in vec4 texcoord;

in vec3 lightVector;
in vec3 upVector;

in vec3 colorTorchlight;

in vec3 worldLightVector;
in vec3 worldSunVector;



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


float ScreenToViewSpaceDepth(float depth) {
    depth = depth * 2.0 - 1.0;
    return 1.0 / (depth * gbufferProjectionInverse[2][3] + gbufferProjectionInverse[3][3]);
}

#include "/Include/Core/GBufferData.glsl"

#include "/Include/Core/Mask.glsl"

void FixParticleMask(inout MaterialMask materialMaskSoild, inout MaterialMask materialMask, inout float depthL, in float depthW){
	#if MC_VERSION >= 11500
	if(materialMaskSoild.particle > 0.5 || materialMaskSoild.particlelit > 0.5){
		materialMask.particle = 1.0;
		materialMask.water = 0.0;
		materialMask.stainedGlass = 0.0;
		materialMask.ice = 0.0;
		materialMask.sky = 0.0;
		depthL = depthW;
	}
	#endif
}


float GetDepthLinear(in vec2 coord, MaterialMask mask)
{
	float depth = texture(depthtex1, coord).x;
	if (mask.particle > 0.5 || mask.particlelit > 0.5){
		depth = texture(gdepthtex, coord).x;
	}
	return (near * far) / (depth * (near - far) + far);
}

vec3  	GetNormals(in vec2 coord, MaterialMask mask) {				//Function that retrieves the screen space surface normals. Used for lighting calculations
	vec3 normal = DecodeNormal(texture(colortex3, coord).xy);

	return normal;
}


float GetDepth(vec2 coord, MaterialMask mask)
{
	float depth = texture(depthtex1, coord).x;
	if (mask.particle > 0.5 || mask.particlelit > 0.5){
		depth = texture(gdepthtex, coord).x;
	}
	return depth;
}


float OrenNayar(vec3 normal, vec3 eyeDir, vec3 lightDir)
{
	const float PI = 3.14159;
	const float roughness = 0.55;

	// interpolating normals will change the length of the normal, so renormalize the normal.



	// normal = normalize(normal + surface.lightVector * pow(clamp(dot(eyeDir, surface.lightVector), 0.0, 1.0), 5.0) * 0.5);

	// normal = normalize(normal + eyeDir * clamp(dot(normal, eyeDir), 0.0f, 1.0f));

	// calculate intermediary values
	float NdotL = dot(normal, lightDir);
	float NdotV = dot(normal, eyeDir);

	float angleVN = acos(NdotV);
	float angleLN = acos(NdotL);

	float alpha = max(angleVN, angleLN);
	float beta = min(angleVN, angleLN);
	float gamma = dot(eyeDir - normal * dot(eyeDir, normal), lightDir - normal * dot(lightDir, normal));

	float roughnessSquared = roughness * roughness;

	// calculate A and B
	float A = 1.0 - 0.5 * (roughnessSquared / (roughnessSquared + 0.57));

	float B = 0.45 * (roughnessSquared / (roughnessSquared + 0.09));

	float C = sin(alpha) * tan(beta);

	// put it all together
	float L1 = max(0.0, NdotL) * (A + B * max(0.0, gamma) * C);

	//return max(0.0f, surface.NdotL * 0.99f + 0.01f);
	return clamp(L1, 0.0f, 1.0f);
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

vec3 WorldPosToShadowProjPosBias(vec3 worldPos, vec3 worldNormal, out float dist, out float distortFactor)
{
	vec3 sn = normalize((shadowModelViewEnd * vec4(worldNormal.xyz, 0.0)).xyz) * vec3(1, 1, -1);

	vec4 sp = (shadowModelViewEnd * vec4(worldPos, 1.0));
	sp = shadowProjection * sp;
	sp /= sp.w;

	dist = sqrt(sp.x * sp.x + sp.y * sp.y);
	distortFactor = (1.0f - SHADOW_MAP_BIAS) + dist * SHADOW_MAP_BIAS;

	sp.xyz += sn * 0.002 * distortFactor;
	sp.xy *= 0.95f / distortFactor;
	sp.z = mix(sp.z, 0.5, 0.8);
	sp = sp * 0.5f + 0.5f;		//Transform from shadow space to shadow map coordinates



	return sp.xyz;
}

vec3 VariablePenumbraShadow(vec3 worldPos, MaterialMask mask, vec3 worldGeoNormal) {				//Calculates shadows

    worldPos += gbufferModelViewInverse[3].xyz;

		if (mask.grass > 0.5 || mask.leaves > 0.5 )
		{
			worldGeoNormal.xyz = vec3(0, 1, 0);
		}

		if (mask.hand > 0.5)
		{
			worldPos.y += 0.5;
		}

		float dist;
		float distortFactor;
		vec3 shadowProjPos = WorldPosToShadowProjPosBias(worldPos.xyz, worldGeoNormal, dist, distortFactor);

		vec3 result = vec3(0.0);

		#ifdef TAA
			vec2 noise = rand(texcoord.st + sin(frameTimeCounter)).xy;
		#else
			vec2 noise = rand(texcoord.st).xy;
		#endif


		float vpsSpread = 0.105 / distortFactor;

		float avgDepth = 0.0;
		float minDepth = 11.0;
		int c;

		for (int i = -1; i <= 1; i++)
		{
			for (int j = -1; j <= 1; j++)
			{
				vec2 lookupCoord = shadowProjPos.xy + (vec2(i, j) / shadowMapResolution) * 8.0 * vpsSpread;
				float depthSample = textureLod(shadowtex0, lookupCoord, 2).x;
				minDepth = min(minDepth, depthSample);
				avgDepth += pow(min(max(0.0, shadowProjPos.z - depthSample) * 1.0, 0.025), 2.0);
				c++;
			}
		}

		avgDepth /= c;
		avgDepth = pow(avgDepth, 0.5);

		float penumbraSize = avgDepth;

		int count = 0;
		float spread = penumbraSize * 0.055 * vpsSpread + 0.55 / shadowMapResolution;


		for (int i = 0; i < 25; i++)
		{
			float fi = float(i + noise.x) / 10.0;
			float r = float(i + noise.x) * 3.14159265 * 2.0 * 1.61;

			vec2 radialPos = vec2(cos(r), sin(r));
			vec2 coordOffset = radialPos * spread * sqrt(fi) * 2.0;



			#ifdef COLORED_SHADOWS
				float translucentShadow = step(shadowProjPos.z - 0.0012 * dist - (noise.x * 0.00005), textureLod(shadowtex0, shadowProjPos.st + coordOffset, 0).x);
				result += vec3(translucentShadow);

				float soildShadow = textureLod(shadowtex1, vec3(shadowProjPos.st + coordOffset, shadowProjPos.z - 0.0012 * dist - (noise.x * 0.00005)), 0).x;
				vec3 shadowColorSample = GammaToLinear(textureLod(shadowcolor0, shadowProjPos.st + coordOffset, 0).rgb);
				result += shadowColorSample * (soildShadow - translucentShadow);
			#else
				float soildShadow = textureLod(shadowtex1, vec3(shadowProjPos.st + coordOffset, shadowProjPos.z - 0.0012 * dist - (noise.x * 0.00005)), 0).x;
				result += vec3(soildShadow);
			#endif

			count += 1;
		}
		result /= count;

		return result;
}


vec3 ClassicSoftShadow(vec3 worldPos, MaterialMask mask, vec3 worldGeoNormal) {				//Calculates shadows

    worldPos += gbufferModelViewInverse[3].xyz;

	if (mask.grass > 0.5 || mask.leaves > 0.5 )
	{
		worldGeoNormal.xyz = vec3(0, 1, 0);
	}

	if (mask.hand > 0.5)
	{
		worldPos.y += 0.5;
	}

	float dist;
	float distortFactor;
	vec3 shadowProjPos = WorldPosToShadowProjPosBias(worldPos.xyz, worldGeoNormal, dist, distortFactor);

	vec3 result = vec3(0.0);

	#ifdef TAA
		vec2 noise = rand(texcoord.st + sin(frameTimeCounter)).xy;
	#else
		vec2 noise = rand(texcoord.st).xy;
	#endif


	int count = 0;
	float spread = 1.0f / shadowMapResolution;

	for (float i = -0.5f; i <= 0.5f; i += 1.0f)
	{
		for (float j = -0.5f; j <= 0.5f; j += 1.0f)
		{
			float angle = noise.x * 3.14159 * 2.0;

			mat2 rot = mat2(cos(angle), -sin(angle), sin(angle), cos(angle));
			vec2 coordOffset = vec2(i, j) * rot * spread;

			#ifdef COLORED_SHADOWS
				float translucentShadow = step(shadowProjPos.z - 0.0012 * dist - (noise.x * 0.00005), textureLod(shadowtex0, shadowProjPos.st + coordOffset, 0).x);
				result += vec3(translucentShadow);

				float soildShadow = textureLod(shadowtex1, vec3(shadowProjPos.st + coordOffset, shadowProjPos.z - 0.0012 * dist - (noise.x * 0.00005)), 0).x;
				vec3 shadowColorSample = GammaToLinear(textureLod(shadowcolor0, shadowProjPos.st + coordOffset, 0).rgb);
				result += shadowColorSample * (soildShadow - translucentShadow);
			#else
				float soildShadow = textureLod(shadowtex1, vec3(shadowProjPos.st + coordOffset, shadowProjPos.z - 0.0012 * dist - (noise.x * 0.00005)), 0).x;
				result += vec3(soildShadow);
			#endif

			count += 1;
		}
	}
	result /= count;

	return result;
}




vec4 BilateralUpsample(const in float scale, in vec2 offset, in float depth, in vec3 normal,  MaterialMask mask)
{
	vec2 recipres = vec2(1.0f / viewWidth, 1.0f / viewHeight);

	vec4 light = vec4(0.0f);
	float weights = 0.0f;

	for (float i = -GI_FILTER_QUALITY; i <= GI_FILTER_QUALITY; i++)
	{
		for (float j = -GI_FILTER_QUALITY; j <= GI_FILTER_QUALITY; j++)
		{
			vec2 coord = vec2(i, j) * recipres * 2.0f;

			float sampleDepth = GetDepthLinear(fma(vec2(exp2(scale)), (coord * 2.0f), texcoord.st), mask);
			vec3 sampleNormal = GetNormals(fma(vec2(exp2(scale)), (coord * 2.0f), texcoord.st), mask);
			float weight = clamp(fma(abs(sampleDepth - depth), -0.5f, 1.0f), 0.0f, 1.0f);
				  weight *= max(0.0f, fma(dot(sampleNormal, normal), 2.0f, -1.0f));

			light += pow(textureLod(colortex1, fma(texcoord.st, vec2(1.0f / exp2(scale)), (offset + coord)), 1), vec4(vec3(2.2f), 1.0f)) * weight;

			weights += weight;
		}
	}


	light /= max(0.00001f, weights);

	return (weights < 0.01f) ? pow(textureLod(colortex1, fma(texcoord.st, vec2(1.0f / exp2(scale)), offset), 1), vec4(vec3(2.2f), 1.0f)) : light;




}

float ExpToLinearDepth(in float depth)
{
	return 2.0f * near * far / (far + near - (2.0f * depth - 1.0f) * (far - near));
}

vec4 GetGI(vec3 albedo, vec3 normal, float depth, float skylight, MaterialMask mask)
{

	depth = ExpToLinearDepth(depth);

	vec4 indirectLight = BilateralUpsample(GI_RENDER_RESOLUTION, vec2(0.0f, 0.0f), depth, normal, mask);

	float value = length(indirectLight.rgb);

	indirectLight.rgb = pow(value, 1.0) * normalize(indirectLight.rgb + 0.0001) * 0.8;

	indirectLight.rgb = indirectLight.rgb * albedo;

	if (isEyeInWater < 0.5) {
		indirectLight.rgb *= 2.0f;
		#ifdef SKYLIGHT_EFFECT_GI
			//indirectLight.rgb *= saturate(pow(skylight, 0.7));
			//if (isEyeInWater < 0.5) indirectLight.rgb *= skylight;
		#endif
	}

	return indirectLight;
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


float CalculateWaterCaustics(vec3 worldPos, MaterialMask mask){
	if (isEyeInWater == 1)
	{
		if (mask.water > 0.5)
		{
			return 1.0;
		}
	}
	worldPos.xyz += cameraPosition.xyz;

	vec2 dither = rand(texcoord.st + sin(frameTimeCounter)).xy / 4.0;

	vec3 lookupCenter = worldPos.xyz + vec3(0.0, 1.0, 0.0);
	const float distanceThreshold = 0.15;

	vec3 lightVector = refract(worldLightVector, vec3(0.0, -1.0, 0.0), 1.0 / 1.2);
	//vec3 depthBias = vec3(worldPos.y * worldLightVector.x, 0.0, worldPos.y * worldLightVector.z) / worldLightVector.y;
	vec3 depthBias = vec3(worldPos.y * lightVector.x, 0.0, worldPos.y * lightVector.z) / lightVector.y;

	const int numSamples = 1;
	int c = 0;

	float caustics = 0.0;

	for (int i = -numSamples; i <= numSamples; i++)
	{
		for (int j = -numSamples; j <= numSamples; j++)
		{
			vec2 offset = vec2(i + dither.x, j + dither.y) * 0.2;
			vec3 lookupPoint = lookupCenter + vec3(offset.x, 0.0, offset.y);


			vec3 wavesNormal = GetWavesNormalFromTex(lookupPoint).xzy;

			vec3 refractVector = refract(vec3(0.0, 1.0, 0.0), wavesNormal.xyz, 1.0);
			vec3 collisionPoint = lookupPoint - refractVector / refractVector.y;

			//float dist = distance(collisionPoint, worldPos.xyz);
			float dist = dot(collisionPoint - worldPos.xyz, collisionPoint - worldPos.xyz) * 7.1;

			caustics += 1.0 - saturate(dist / distanceThreshold);

			c++;
		}
	}

	caustics /= c;

	caustics /= distanceThreshold;

	return (caustics + 0.7) * 0.4;
}






vec3 ProjectBack(vec3 cameraSpace)
{
    vec4 clipSpace = gbufferProjection * vec4(cameraSpace, 1.0);
    vec3 NDCSpace = clipSpace.xyz / clipSpace.w;
    vec3 screenSpace = fma(NDCSpace, vec3(0.5f), vec3(0.5f));
		 //screenSpace.z = 0.1f;
    return screenSpace;
}


float ScreenSpaceShadow(vec3 origin, vec3 geoNormal, MaterialMask mask)
{
	if(mask.hand > 0.5) return 1.0;

	float randomness = rand(texcoord.st + sin(frameTimeCounter)).x;


	float fov = 2.0 * atan( 1.0 / gbufferProjection[1][1] ) * 180.0 / 3.14159265;

	vec3 rayPos = origin;
	vec3 rayDir = lightVector * -origin.z * 0.000035 * fov;

	float NdotL = saturate(dot(lightVector, geoNormal));

	rayPos += geoNormal * 0.0003 * max(abs(origin.z), 0.1) / (NdotL + 0.01) * (1.0 - mask.grass);

	if (mask.grass < 0.5 && mask.leaves < 0.5)
	{
		rayPos += geoNormal * 0.00001 * -origin.z * fov * 0.15;
		rayPos += rayDir * 13000.0 * min(pixelSize.x, pixelSize.y) * 0.15;
	}

	float zThickness = 0.025 * -origin.z;
	float shadow = 1.0;
	float absorption = 0.0;
	absorption += 0.7 * mask.grass;
	absorption += 0.85 * mask.leaves;
	absorption = pow(absorption, sqrt(length(origin)) * 0.5);

	float ds = 1.0;
	for (int i = 0; i < 12; i++)
	{
		rayPos += rayDir * ds;

		ds += 0.3;

		vec3 thisRayPos = rayPos + rayDir * randomness * ds;

		vec2 rayProjPos = ProjectBack(thisRayPos).xy;

		if(abs(rayProjPos.x) > 1.0 || abs(rayProjPos.y) > 1.0) break;

		#ifdef TAA
			rayProjPos.xy += taaJitter * 0.5;
		#endif

		vec3 samplePos = GetViewPositionRaw(rayProjPos.xy, GetDepth(rayProjPos.xy, mask)).xyz; // half res rendering fix

		float depthDiff = samplePos.z - thisRayPos.z;

		if (depthDiff > 0.0 && depthDiff < zThickness)
			shadow *= absorption;

		if(shadow < 0.01)
			break;
	}

	return shadow;
}


vec2 Hash2(vec3 p3) {
	p3 = fract(p3 * vec3(443.897, 441.423, 437.195));
	p3 += dot(p3, p3.yzx + 19.19);
	return fract((p3.xx + p3.yz) * p3.zy);
}

vec3 Rotate(vec3 vector, vec3 from, vec3 to) {
	// where "from" and "to" are two unit vectors determining how far to rotate
	// adapted version of https://en.wikipedia.org/wiki/Rodrigues%27_rotation_formula

	float cosine = dot(from, to);
	vec3 axis = cross(from, to);
	float cosecantSquared = 1.0 / dot(axis, axis);

	return cosine * vector + cross(axis, vector) + (cosecantSquared - cosecantSquared * cosine) * dot(axis, vector) * axis;
}

vec3 CalculateStars(vec3 worldDir) {
	const float scale = 484.0;
	const float coverage = 0.047;
	const float maxLuminance = 500.0 * NIGHT_BRIGHTNESS;
	const float minTemperature = 9000.0;
	const float maxTemperature = 16000.0;

	// Set visibility to 1 for full visibility of stars
	float visibility = 1.0;

	worldDir = Rotate(worldDir, worldLightVector, vec3(0, 0, 1));


	vec3  p = worldDir * scale;
	ivec3 i = ivec3(floor(p));
	vec3  f = p - i;
	float r = dot(f - 1.5, f - 1.5);

	vec2 hash = Hash2(i);
	hash.y = 3.0 * hash.y - 3.0 * hash.y * hash.y + 3.0 * hash.y * hash.y * hash.y;

	// Apply the visibility adjustment to the luminance calculation
	vec3 luminance = pow(remap(1.0 - coverage, 1.0, hash.x), 2) * Blackbody(mix(minTemperature, maxTemperature, hash.y));

	// Return the final star color, ensuring they are always visible
	return visibility * maxLuminance * remap(0.1, 0.1, r) * pow(remap(1.0 - coverage, 1.0, hash.x), 2) * Blackbody(mix(minTemperature, maxTemperature, hash.y));
}



void WaterFog(inout vec3 color, in float depthL)
{
	float opaqueDepth 	= ScreenToViewSpaceDepth(depthL);

	if(isEyeInWater == 2){
		float dist = opaqueDepth;

		float fogDensity = 1.0;
		float fogFactor = pow(1.0 - exp(-dist * fogDensity), 3.0);

		vec3 fogColor = vec3(0.99, 0.17, 0.005) * 20.0;
		color += pow(fogColor * fogFactor, vec3(1.1));


	}else if(isEyeInWater == 3){
		vec3 skyUpColor = vec3(2.0);

		float dist = opaqueDepth;
		dist = saturate(dist * 0.5);

		color = mix(color, skyUpColor, dist);
    }
}


vec3 UnprojectSky(vec2 coord, float lod) {
	coord *= viewDimensions;
	float tileSize       = min(floor(viewDimensions.x * 0.5) / 1.5, floor(viewDimensions.y * 0.5)) * exp2(-lod);
	float tileSizeDivide = (0.5 * tileSize) - 1.5;

	vec3 direction = vec3(0.0);

	if (coord.x < tileSize) {
		direction.x =  coord.y < tileSize ? -1 : 1;
		direction.y = (coord.x - tileSize * 0.5) / tileSizeDivide;
		direction.z = (coord.y - tileSize * (coord.y < tileSize ? 0.5 : 1.5)) / tileSizeDivide;
	} else if (coord.x < 2.0 * tileSize) {
		direction.x = (coord.x - tileSize * 1.5) / tileSizeDivide;
		direction.y =  coord.y < tileSize ? -1 : 1;
		direction.z = (coord.y - tileSize * (coord.y < tileSize ? 0.5 : 1.5)) / tileSizeDivide;
	} else {
		direction.x = (coord.x - tileSize * 2.5) / tileSizeDivide;
		direction.y = (coord.y - tileSize * (coord.y < tileSize ? 0.5 : 1.5)) / tileSizeDivide;
		direction.z =  coord.y < tileSize ? -1 : 1;
	}

	return normalize(direction);
}


vec2 RaySphereIntersectionIO(vec3 p, vec3 dir, float r)
{
	float b = dot(p, dir);
	float c = -r * r + dot(p, p);

	float d = b * b -c;
	if (d < 0.0)
	{
		return vec2(-1e10, 1e10);
	}

	d = sqrt(d);

	return vec2(-b + d, -b - d);
}

Intersection RayPlaneIntersection(in Ray ray, in Plane plane)
{
	float rayPlaneAngle = dot(ray.dir, plane.normal);

	float planeRayDist = 100000000.0f;
	vec3 intersectionPos = ray.dir * planeRayDist;

	if (rayPlaneAngle > 0.0001f || rayPlaneAngle < -0.0001f)
	{
		planeRayDist = dot((plane.origin - ray.origin), plane.normal) / rayPlaneAngle;
		intersectionPos = ray.origin + ray.dir * planeRayDist;
		// intersectionPos = -intersectionPos;

		// intersectionPos += cameraPosition.xyz;
	}

	Intersection i;

	i.pos = intersectionPos;
	i.distance = planeRayDist;
	i.angle = rayPlaneAngle;

	return i;
}


vec3 H(vec3 albedo, float a){
    vec3 R = sqrt(vec3(1.0) - albedo);
    vec3 r = (1.0 - R) / (1.0 + R);
    vec3 H = r + (0.5 - r * a) * log((1.0 + a) / a);
    H *= albedo * a;

    return 1.0 / (1.0 - H);
}

vec3 ppss(vec3 albedo, vec3 normal, vec3 eyeDir, vec3 lightDir, float s){
    float NdotL = dot(normal, lightDir);
    float NdotV = dot(normal, eyeDir);
    //NdotL = saturate(NdotL);
    //NdotV = saturate(NdotV);
    albedo *= curve(saturate(NdotL));

    vec3 color = albedo * H(albedo, NdotL) * H(albedo, NdotV) / (4.0 * PI * (NdotL + NdotV));

    //return saturate(color * pow(NdotL, 1.0));
    return saturate(color);
}

float Disc(float a, float s, float h){
    return pow(curve(saturate((a - (1.0 - s)) * h)), 2.0);
}



void PlanetEnd2(inout vec3 color, in vec3 eye, in vec3 rayDir, in vec3 lightDir) {
    float angleX = radians(-204.5);
    float angleY = radians(90.0);

    mat3 eyeRoataionMatrixX = mat3(1, 0, 0, 0, cos(angleX), -sin(angleX), 0, sin(angleX), cos(angleX));
    mat3 eyeRoataionMatrixY = mat3(cos(angleY), 0, sin(angleY), 0, 1, 0, -sin(angleY), 0, cos(angleY));
    mat3 eyeRoataionMatrix = eyeRoataionMatrixX * eyeRoataionMatrixY;

    rayDir = eyeRoataionMatrix * rayDir;
    lightDir = eyeRoataionMatrix * lightDir;

    float Rground = 20e6; 
    eye.y += Rground + 15e6;

    vec2 RgroundIntersection = RaySphereIntersectionIO(eye, rayDir, Rground);
    if (RgroundIntersection.x > 0.0) {
        color *= 0.0;
        vec3 surfacePos = rayDir * RgroundIntersection.y;
        vec3 surfaceNormal = normalize(surfacePos - vec3(0.0, -eye.y, 0.0));

        vec3 venusColor = vec3(1.0, 0.85, 0.6); 
        vec3 lighting = ppss(venusColor, surfaceNormal, -rayDir, lightDir, 1.0);
        lighting *= 70.0;

        float facing = saturate(dot(surfaceNormal, lightDir));
        vec3 glow = venusColor * pow(facing, 2.0) * 10.0;

        color += (lighting + glow) * 1.2;
    }
}





/////////////////////////MAIN//////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
/////////////////////////MAIN//////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
void main()
{

	GbufferData gbuffer 			= GetGbufferData();
	MaterialMask materialMask 		= CalculateMasks(gbuffer.materialIDW);
	MaterialMask materialMaskSoild 	= CalculateMasks(gbuffer.materialIDL);

	FixParticleMask(materialMaskSoild, materialMask, gbuffer.depthL, gbuffer.depthW);

	if (materialMask.water > 0.5)
	{
		gbuffer.material.roughness = 1.0;
		gbuffer.material.metalness = 0.0;
	}

	if (materialMaskSoild.selection > 0.5) gbuffer.albedo = vec3(0.0);


	vec3 viewPos 					= GetViewPosition(texcoord.st, gbuffer.depthL);
	vec3 worldPos					= mat3(gbufferModelViewInverse) * viewPos;

	vec3 viewDir 					= normalize(viewPos);
	vec3 worldDir 					= normalize(worldPos);
	vec3 rawWorldNormal 			= normalize((gbufferModelViewInverse * vec4(gbuffer.normalL, 0.0)).xyz);
	vec3 worldNormal 				= rawWorldNormal;

	float cloudShadow 				= 1.0;
	float globalCloudShadow			= 1.0;


	float noise_0  = bayer64(gl_FragCoord.xy);

	float noise_1 = noise_0;
	#ifdef TAA
		noise_1 = fract(frameCounter * (1.0 / 7.0) + noise_1);
    #endif





	vec3 finalComposite = vec3(0.0);

	if (materialMaskSoild.sky < 0.5){

//////AO(GI)
	vec4 gi = vec4(0.0, 0.0, 0.0, 1.0);
	#ifdef GI
		gi = GetGI(gbuffer.albedo, gbuffer.normalL, gbuffer.depthL, gbuffer.lightmapL.g, materialMaskSoild);
	#endif
	float ao = gi.a;





//////grass points up
	if (materialMaskSoild.grass > 0.5) worldNormal = vec3(0.0, 1.0, 0.0);





//////Skylight
	finalComposite += (worldNormal.y * 0.35 + 0.65) * gbuffer.albedo * 2.0 * ao;




//////no light
	vec3 nolight = vec3(0.02 * nightVision + NOLIGHT_BRIGHTNESS);

	finalComposite += nolight * gbuffer.albedo * 1.0 * ao;





//////Entity & Block & Particle Light
	const float torchlightBrightness = TORCHLIGHT_BRIGHTNESS;
	float lightSourceMask = 1.0;

	if (materialMaskSoild.glowstone
		+ materialMaskSoild.torch
		+ materialMaskSoild.entitysLitHigh
		+ materialMaskSoild.entitysLitMedium
		+ materialMaskSoild.entitysLitLow
		+ materialMaskSoild.particlelit
		+ materialMaskSoild.soulFire
		+ materialMaskSoild.amethyst > 0.5)
	lightSourceMask = 0.0;

	vec3 blockLighting = gbuffer.lightmapL.r * colorTorchlight * lightSourceMask * gbuffer.albedo * ao;

	float albedoLuminance = length(gbuffer.albedo.rgb);
	vec3 albedo2 = gbuffer.albedo * albedoLuminance;

	float blockLightingMask = materialMaskSoild.glowstone * 5.0;
	blockLightingMask += materialMaskSoild.torch * 5.0;
	blockLightingMask += materialMaskSoild.fire * 3.0;
	blockLightingMask += materialMaskSoild.lava * 3.0;
	blockLightingMask += materialMaskSoild.redstoneTorch * 0.5;

	blockLighting += blockLightingMask * colorTorchlight * albedo2;


	blockLightingMask = materialMaskSoild.soulFire * 0.2;
	blockLightingMask += materialMaskSoild.amethyst * 0.03;
	blockLightingMask += materialMaskSoild.entitysLitHigh * 2.0;
	blockLightingMask += materialMaskSoild.entitysLitMedium * 1.0;
	blockLightingMask += materialMaskSoild.entitysLitLow * 0.5;
	blockLightingMask += materialMaskSoild.particlelit * 1.0;
	blockLightingMask += materialMaskSoild.eyes * 3.0;

	blockLighting += blockLightingMask * albedo2;

	finalComposite += blockLighting * torchlightBrightness;



	if(heldBlockLightValue + heldBlockLightValue2 > 0.0){
	#ifdef FLASHLIGHT_HELDLIGHT
		float heldLightFalloff = 1.0 / pow(max(length(worldPos.xyz), 0.2), FLASHLIGHT_HELDLIGHT_FALLOFF);

		#ifdef NORMAL_HELDLIGHT
			heldLightFalloff *= saturate(dot(-viewDir, gbuffer.normalL)) * (ao * 0.5 + 0.5);
		#else
			heldLightFalloff *= ao;
		#endif

		vec3 torchPos = worldPos.xyz + gbufferModelViewInverse[1].xyz * 0.1;
		vec3 torchPosL = torchPos + gbufferModelViewInverse[0].xyz * 0.23;
		vec3 torchPosR = torchPos - gbufferModelViewInverse[0].xyz * 0.23;
		vec3 torchDirL = normalize((gbufferModelView * vec4(torchPosL, 0.0)).xyz);
		vec3 torchDirR = normalize((gbufferModelView * vec4(torchPosR, 0.0)).xyz);
		float spotRadiusL = dot(torchDirL, vec3(0.0, 0.0, -1.0));
		float spotRadiusR = dot(torchDirR, vec3(0.0, 0.0, -1.0));
		spotRadiusL = saturate(spotRadiusL * 2.0 - 1.8);
		spotRadiusR = saturate(spotRadiusR * 2.0 - 1.8);

		heldLightFalloff = materialMask.hand > 0.5 ? 0.2 * max(heldBlockLightValue, heldBlockLightValue2) : heldLightFalloff * (heldBlockLightValue2 * spotRadiusL + heldBlockLightValue * spotRadiusR);
	#else
		float heldLightFalloff = 1.0 / pow(max(length(worldPos.xyz), 1.0), HELDLIGHT_FALLOFF);

		#ifdef NORMAL_HELDLIGHT
			heldLightFalloff *= saturate(dot(-viewDir, gbuffer.normalL)) * (ao * 0.5 + 0.5);
		#else
			heldLightFalloff *= ao;
		#endif

		heldLightFalloff = materialMask.hand > 0.5 ? 0.2 * max(heldBlockLightValue, heldBlockLightValue2) : heldLightFalloff * (heldBlockLightValue + heldBlockLightValue2) * 0.4;
	#endif

	finalComposite += gbuffer.albedo * heldLightFalloff * colorTorchlight * HELDLIGHT_BRIGHTNESS * 0.4;
	}




//////Sunlight & Shadow
	float sunlightMult = 40.0 * SUNLIGHT_INTENSITY;
	float sunlight = OrenNayar(worldNormal, -worldDir, worldLightVector);

	if (materialMaskSoild.leaves > 0.5)
	{
		sunlight = mix(sunlight, 0.5, 0.5);
	}

	#ifdef VARIABLE_PENUMBRA_SHADOWS
		vec3 shadow = VariablePenumbraShadow(worldPos, materialMaskSoild, worldNormal);
	#else
		vec3 shadow = ClassicSoftShadow(worldPos, materialMaskSoild, worldNormal);
	#endif

	#ifdef SCREEN_SPACE_SHADOWS
		shadow *= ScreenSpaceShadow(viewPos.xyz, gbuffer.normalL, materialMaskSoild);
	#endif

	#ifdef CAUSTICS
		if (materialMask.water > 0.5 || isEyeInWater == 1)
		{
			shadow *= mix(CalculateWaterCaustics(worldPos, materialMask), 1.0, 0.3 * (1.0 - isEyeInWater));
		}
	#endif

	float waterAbsorbtion = isEyeInWater == 1 ? 1.0 / max(3.0, ScreenToViewSpaceDepth(gbuffer.depthW) * 0.2) : 1.0;
	shadow *= waterAbsorbtion;

	shadow *= gbuffer.parallaxShadow;

	finalComposite += sunlight * gbuffer.albedo * shadow * sunlightMult;



//////GI
	gi.rgb *= waterAbsorbtion;
	finalComposite += gi.rgb * sunlightMult * 0.1;


//////Sunlight specular
	vec3 specularHighlight = vec3(0.0);

	if (materialMask.water < 0.5 && materialMask.ice < 0.5){
		specularHighlight = SpecularGGX(worldNormal, -worldDir, worldLightVector, max(gbuffer.material.roughness, 0.0015), gbuffer.material.f0);
		specularHighlight *= mix(vec3(1.0), gbuffer.albedo, vec3(gbuffer.material.metalness));
		specularHighlight *= mix(1.0, 0.5, materialMaskSoild.grass);
		specularHighlight *= shadow * sunlightMult * 0.3;
	}

	float metalnessMask = float(gbuffer.material.doCSR) * gbuffer.material.metalness;
	finalComposite *= 1.0 - metalnessMask * 0.75;

	finalComposite += specularHighlight;

	}

	worldDir = (isEyeInWater == 1 && materialMask.water > 0.5) ? refract(worldDir, normalize((gbufferModelViewInverse * vec4(gbuffer.normalW, 0.0)).xyz), WATER_REFRACT_IOR) : worldDir;


	if (materialMaskSoild.sky > 0.3)
	{
		vec3 atmosphere = vec3(0.0);
		vec3 moonAtmosphere = vec3(0.0);
		vec3 sunDisc = vec3(0.0);
		vec3 moonDisc = vec3(0.0);
		finalComposite = vec3(0.0);

        #ifdef STARS
			finalComposite += CalculateStars(worldDir);
		#endif

		sunDisc = vec3(RenderSunDisc(worldDir, worldSunVector));

		finalComposite += sunDisc * 2e4;

        PlanetEnd2(finalComposite, vec3(0.0), worldDir, worldLightVector);
	}



	float totalInternalReflection = 0.0;
	if (length(worldDir) < 0.5)
	{
		finalComposite = vec3(0.0);
		totalInternalReflection = 1.0;
	}


	#ifdef UNDERWATER_FOG
		WaterFog(finalComposite, gbuffer.depthL);
	#endif


	finalComposite *= compositeOutputFactor;
	finalComposite = LinearToGamma(finalComposite);
	//finalComposite += rand(texcoord.st + sin(frameTimeCounter)) * (1.0 / 255.0) * compositeOutputFactor;

	compositeOutput1 = vec4(finalComposite.rgb, totalInternalReflection);
}

/* DRAWBUFFERS:1 */
