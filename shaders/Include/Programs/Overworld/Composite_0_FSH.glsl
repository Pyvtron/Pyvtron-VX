
/*
====================================================================================================

    Copyright (C) 2025 Pyvtron VX Shaders - Pyvtron

    All Rights Reserved unless otherwise explicitly stated.

====================================================================================================
*/


#include "/Include/Uniforms.glsl"
#include "/Include/Core/Core.glsl"

layout(location = 0) out vec4 compositeOutput1;
layout(location = 1) out vec4 compositeOutput2;

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


/////////////////////////END OF CONFIGURABLE VARIABLES/////////////////////////////////////////////////////////////////////////////////////////////////////////////
/////////////////////////END OF CONFIGURABLE VARIABLES/////////////////////////////////////////////////////////////////////////////////////////////////////////////

#include "/Include/Core/Mask.glsl"


vec4 GetViewPosition(in vec2 coord, in float depth)
{
	#ifdef TAA
		coord -= taaJitter * 0.5;
	#endif

	vec3 screenPos = vec3(coord, depth) * 2.0 - 1.0;

	vec4 fragposition = gbufferProjectionInverse * vec4(screenPos, 1.0f);
		 fragposition /= fragposition.w;

	return fragposition;
}

vec4 GetViewPositionRaw(in vec2 coord, in float depth)
{
	vec3 screenPos = vec3(coord, depth) * 2.0 - 1.0;

	vec4 fragposition = gbufferProjectionInverse * vec4(screenPos, 1.0f);
		 fragposition /= fragposition.w;

	return fragposition;
}

float ScreenToViewSpaceDepth(float depth) {
    depth = depth * 2.0 - 1.0;
    return 1.0 / (depth * gbufferProjectionInverse[2][3] + gbufferProjectionInverse[3][3]);
}

vec3  	GetNormals(in vec2 coord, MaterialMask mask) {				//Function that retrieves the screen space surface normals. Used for lighting calculations
	vec3 normal = DecodeNormal(texture(colortex3, coord.st).xy);

	return normal;
}

float 	GetDepth(in vec2 coord, MaterialMask mask) {
	float depth = texture(depthtex1, coord.st).x;
	if(mask.particle > 0.5 || mask.particlelit > 0.5)
	depth = texture(gdepthtex, coord.st).x;
	return depth;
}

vec4  	GetScreenSpacePosition(in vec2 coord, MaterialMask mask) {	//Function that calculates the screen-space position of the objects in the scene using the depth texture and the texture coordinates of the full-screen quad
	float depth = GetDepth(coord, mask);
	vec4 fragposition = gbufferProjectionInverse * vec4(fma(coord.st, vec2(2.0f), vec2(-1.0f)), fma(depth, 2.0f, -1.0f), 1.0f);
		 fragposition /= fragposition.w;

	return fragposition;
}

vec4  	GetScreenSpacePosition(in vec2 coord, in float depth) {	//Function that calculates the screen-space position of the objects in the scene using the depth texture and the texture coordinates of the full-screen quad
	vec4 fragposition = gbufferProjectionInverse * vec4(fma(coord.st, vec2(2.0f), vec2(-1.0f)), fma(depth, 2.0f, -1.0f), 1.0f);
		 fragposition /= fragposition.w;

	return fragposition;
}


vec3 	CalculateNoisePattern1(vec2 offset, float size) {
	vec2 coord = texcoord.st;

	coord *= vec2(viewWidth, viewHeight);
	coord = mod(coord + offset, vec2(size));
	coord /= noiseTextureResolution;

	return texture(noisetex, coord).xyz;
}

vec2 DistortShadowSpace(in vec2 pos)
{
	vec2 signedPos = fma(pos, vec2(2.0f), vec2(-1.0f));

	float dist = sqrt(signedPos.x * signedPos.x + signedPos.y * signedPos.y);
	float distortFactor = fma(dist, SHADOW_MAP_BIAS, (1.0f - SHADOW_MAP_BIAS));
	signedPos.xy *= 0.95 / distortFactor;

	pos = fma(signedPos, vec2(0.5f), vec2(0.5f));

	return pos;
}

vec3 Contrast(in vec3 color, in float contrast)
{
	float colorLength = length(color);
	vec3 nColor = color / colorLength;

	colorLength = pow(colorLength, contrast);

	return nColor * colorLength;
}

float 	GetMaterialIDs(in vec2 coord) {			//Function that retrieves the texture that has all material IDs stored in it
	return texture(colortex6, coord).b;
}

float GetSkylight(in vec2 coord)
{
	return textureLod(colortex3, coord, 0).a;
}

float 	GetMaterialMask(in vec2 coord, const in int ID) {
	float matID = (GetMaterialIDs(coord) * 255.0f);

	//Catch last part of sky
	matID = (matID > 254.0f) ? 0.0f : matID;

	return (matID == ID) ? 1.0f : 0.0f;
}

bool 	GetSkyMask(in vec2 coord)
{
	float matID = GetMaterialIDs(coord);
	matID = floor(matID * 255.0f);

	if (matID < 1.0f || matID > 254.0f)
	{
		return true;
	} else {
		return false;
	}
}

vec3 ProjectBack(vec3 cameraSpace)
{
    vec4 clipSpace = gbufferProjection * vec4(cameraSpace, 1.0);
    vec3 NDCSpace = clipSpace.xyz / clipSpace.w;
    vec3 screenSpace = fma(NDCSpace, vec3(0.5f), vec3(0.5f));
    return screenSpace;
}

float 	ExpToLinearDepth(in float depth)
{
	return 2.0f * near * far / fma((near - far), fma(depth, 2.0f, -1.0f), (far + near));
}

float GetAO(vec2 coord, vec3 normal, float dither, MaterialMask mask)
{
	const int numRays = 16;

	const float phi = 1.618033988;
	const float gAngle = phi * 3.14159265 * 1.0003;

	float depth = GetDepth(coord, mask);
	float linDepth = ExpToLinearDepth(depth);
	vec3 origin = GetScreenSpacePosition(coord, depth).xyz;

	float aoAccum = 0.0;

	float radius = 0.30 * -origin.z;
		  radius = mix(radius, 0.8, 0.5);
	float zThickness = 0.30 * -origin.z;
		  zThickness = mix(zThickness, 1.0, 0.5);

	float aoMul = 1.0;

	for (int i = 0; i < numRays; i++)
	{
		float fi = float(i) + dither;
		float fiN = fi / float(numRays);
		float lon = gAngle * fi * 6.0;
		float lat = asin(fma(fiN, 2.0f, -1.0f)) * 1.0;

		vec3 kernel;
		kernel.x = cos(lat) * cos(lon);
		kernel.z = cos(lat) * sin(lon);
		kernel.y = sin(lat);

		kernel.xyz = normalize(kernel.xyz + normal.xyz);

		float sampleLength = radius * mod(fiN, 0.02f) / 0.02;

		vec3 samplePos = fma(vec3(sampleLength), kernel, origin);

		vec3 samplePosProj = ProjectBack(samplePos);

		vec3 actualSamplePos = GetScreenSpacePosition(samplePosProj.xy, GetDepth(samplePosProj.xy, mask)).xyz;

		vec3 sampleVector = normalize(samplePos - origin);

		float depthDiff = actualSamplePos.z - samplePos.z;

		if (depthDiff > 0.0 && depthDiff < zThickness)
		{
			float aow = 1.35 * saturate(dot(sampleVector, normal));
			aoAccum += aow;
		}
	}

	aoAccum /= numRays;

	float ao = 1.0 - aoAccum;
	ao = pow(ao, 1.7);

	return ao;
}

vec4 WorldToShadowProjPos(in vec4 spacePosition){

	vec4 shadowposition = shadowModelView * spacePosition;	//Transform from world space to shadow space
	shadowposition = shadowProjection * shadowposition;

	shadowposition /= shadowposition.w;

	return shadowposition * 0.5f + 0.5f;		//Transform from shadow space to shadow map coordinates
}
/*
vec4 RSM(){
	vec2 coord = texcoord.st;
	//GbufferData gbuffer = GetGbufferData();
	MaterialMask mask = CalculateMasks(texture(colortex6, coord).b);

	float depth = GetDepth(coord, mask);

	float dist = ScreenToViewSpaceDepth(depth);

	vec4 viewPos = GetViewPositionRaw(coord, depth);
	vec3 viewDir = normalize(viewPos.xyz);

	vec4 worldPos = gbufferModelViewInverse * viewPos;
	vec4 shadowProjPos = WorldToShadowProjPos(worldPos);


	vec3 shadowUpVector = shadowModelView[1].xyz;

	vec3 viewNormal = GetNormals(coord, mask);
	vec3 worldNormal = normalize(mat3(gbufferModelViewInverse) * viewNormal);
	vec3 shadowNormal = normalize(mat3(shadowModelView) * worldNormal);

	return vec4(0.0);
}
*/
vec4 GetLight(in int LOD, in vec2 offset, in float range, in float quality, vec3 noisePattern, out MaterialMask mask)
{

	float scale = pow(2.0f, float(LOD));

	float padding = 0.002f;

	if (	texcoord.s - offset.s + padding < 1.0f / scale + (padding * 2.0f)
		&&  texcoord.t - offset.t + padding < 1.0f / scale + (padding * 2.0f)
		&&  texcoord.s - offset.s + padding > 0.0f
		&&  texcoord.t - offset.t + padding > 0.0f)
	{

		vec2 coord = (texcoord.st - offset.st) * scale;

		mask = CalculateMasks(texture(colortex6, coord.st).b);

		if(mask.sky == 0.0){

			vec3 normal 				= GetNormals(coord.st, mask);						//Gets the screen-space normals

			vec4 gn = gbufferModelViewInverse * vec4(normal.xyz, 0.0f);
				 gn = shadowModelView * gn;
				 gn.xyz = normalize(gn.xyz);

			vec3 shadowSpaceNormal = gn.xyz;

			vec4 screenSpacePosition 	= GetScreenSpacePosition(coord.st, mask); 			//Gets the screen-space position
			vec3 viewVector 			= normalize(screenSpacePosition.xyz);


			float distance = length(screenSpacePosition);

			//float materialIDs = texture(colortex5, coord).b * 255.0f;

			vec4 upVectorShadowSpace = shadowModelView * vec4(0.0f, 1.0, 0.0, 0.0);

			vec4 worldposition = gbufferModelViewInverse * screenSpacePosition;		//Transform from screen space to world space
				 worldposition = WorldToShadowProjPos(worldposition);

			float shadowMult = 0.0f;														//Multiplier used to fade out shadows at distance
			float shad = 0.0f;
			vec3 fakeIndirect = vec3(0.0f);

			float fakeLargeAO = 0.0;


			float mcSkylight = GetSkylight(coord) * 0.8 + 0.2;

			float fademult = 0.15f;

			if (shadowDistanceRenderMul < 0.0) {
				shadowMult = 1.0;
			}else{
				shadowMult = clamp((shadowDistance * 1.4f * fademult) - (distance * fademult), 0.0f, 1.0f);	//Calculate shadowMult to fade shadows out
			}

			worldposition.z -= 0.002;

			float compare = sin(frameTimeCounter) > -0.2 ? 1.0 : 0.0;

			if (shadowMult > 0.0)
			{


				//big shadow
				float rad = range;

				int c = 0;
				float s = 2.0f * (rad / 2048.0f);

				vec2 dither = noisePattern.xy;

				float step = 1.0f / quality;

				for (float i = -2.0f; i <= 2.0f; i += step) {
					for (float j = -2.0f; j <= 2.0f; j += step) {

						vec2 offset = (vec2(i, j) + dither * step) * s;

						offset *= length(offset) * 15.0;
						offset *= GI_RADIUS * 1.0;


						vec2 coord =  worldposition.st + offset;
						vec2 lookupCoord = DistortShadowSpace(coord);

						float depthSample = textureLod(shadowtex1, lookupCoord, 0).x;


						depthSample = -3 + 5.0 * depthSample;
						vec3 samplePos = vec3(coord.x, coord.y, depthSample);


							fakeLargeAO += saturate((worldposition.z - samplePos.z) * 1000.0);


						vec3 lightVector = normalize(samplePos.xyz - worldposition.xyz);

						vec4 normalSample = textureLod(shadowcolor1, lookupCoord, 6);

						vec3 surfaceNormal = normalSample.rgb * 2.0f - 1.0f;
							 surfaceNormal.x = -surfaceNormal.x;
							 surfaceNormal.y = -surfaceNormal.y;

						float surfaceSkylight = normalSample.a;

						if (surfaceSkylight < 0.2)
						{
							surfaceSkylight = mcSkylight;
						}

						float NdotL = max(0.0f, dot(shadowSpaceNormal.xyz, lightVector * vec3(1.0, 1.0, -1.0)));
							   NdotL = NdotL * 0.9f + 0.2f;

						if (mask.leaves > 0.5 || mask.grass > 0.5)
						{
							NdotL = 0.5f;
						}

						if (NdotL > 0.0)
						{
							bool isTranslucent = length(surfaceNormal) < 0.5f;

							if (isTranslucent)
							{
								surfaceNormal.xyz = vec3(0.0f, 0.0f, 1.0f);
							}



							float weight = dot(lightVector, surfaceNormal);
							float rawdot = weight;

							if (isTranslucent)
							{
								weight = abs(weight) * 0.85f;
							}

							if (normalSample.a < 0.2)
							{
								weight = 0.5;
							}

							weight = max(weight, 0.0f);

							float dist = length(samplePos.xyz - worldposition.xyz - vec3(0.0f, 0.0f, 0.0f));
							if (dist < 0.0005f)
							{
								dist = 10000000.0f;
							}

							const float falloffPower = 1.9f; //Default: 1.9f
							float distanceWeight = (1.0f / (pow(dist * (62260.0f / rad), falloffPower) + 100.1f));
								  distanceWeight *= pow(length(offset), 2.0) * 50000.0 + 1.01;


							//Leaves self-occlusion
							if (rawdot < 0.0f)
							{
								distanceWeight = max(distanceWeight * 30.0f - 0.13f, 0.0f);
								distanceWeight *= 0.04f;
							}


							float skylightWeight = 1.0 / (max(0.0, surfaceSkylight - mcSkylight) * 15.0 + 1.0);



							vec3 colorSample = pow(textureLod(shadowcolor0, lookupCoord, 6).rgb, vec3(2.2f));


							colorSample /= surfaceSkylight;

							colorSample = normalize(colorSample) * pow(length(colorSample), 1.1f);

							fakeIndirect += colorSample * weight * distanceWeight * NdotL * skylightWeight;
						}
						c += 1;
					}
				}

				fakeIndirect /= c;
				fakeLargeAO /= c;
				fakeLargeAO = clamp(1.0 - fakeLargeAO * 0.8, 0.0, 1.0);
			}

			fakeIndirect = mix(vec3(0.0f), fakeIndirect, vec3(shadowMult));


			float ao = 1.0f;
			//bool isSky = GetSkyMask(coord.st);
			#ifdef ENABLE_SSAO
			if (mask.sky == 0.0)
			{
				ao *= GetAO(coord.st, normal.xyz, noisePattern.x, mask);
			}


			#endif
			fakeIndirect.rgb *= ao;


			fakeIndirect.rgb = mix(fakeIndirect.rgb, vec3(Luminance(fakeIndirect.rgb)), vec3(1.0 - GI_SATURATION));

			return vec4(fakeIndirect.rgb * GI_BRIGHTNESS * GI_RADIUS, ao);
		}
		else {
			return vec4(0.0f);
		}
	}
}

float  	CalculateDitherPattern1() {
	const int[16] ditherPattern = int[16] (0 , 8 , 2 , 10,
									 	   12, 4 , 14, 6 ,
									 	   3 , 11, 1,  9 ,
									 	   15, 7 , 13, 5 );

	vec2 count = vec2(0.0f);
	     count.x = floor(mod(texcoord.s * viewWidth, 4.0f));
		 count.y = floor(mod(texcoord.t * viewHeight, 4.0f));

	int dither = ditherPattern[int(fma(int(count.y), 4, int(count.x)))];

	return float(dither) / 16.0f;
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

	return texture2D(tex, coord);
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

vec3 GetWavesNormal(vec3 position) {

	float WAVE_HEIGHT = 1.5;

	const float sampleDistance = 11.0f;

	position -= vec3(0.005f, 0.0f, 0.005f) * sampleDistance;

	float wavesCenter = GetWaves(position);
	float wavesLeft = GetWaves(position + vec3(0.01f * sampleDistance, 0.0f, 0.0f));
	float wavesUp   = GetWaves(position + vec3(0.0f, 0.0f, 0.01f * sampleDistance));

	vec3 wavesNormal;
		 wavesNormal.r = wavesCenter - wavesLeft;
		 wavesNormal.g = wavesCenter - wavesUp;

		 wavesNormal.r *= 30.0f * WAVE_HEIGHT / sampleDistance;
		 wavesNormal.g *= 30.0f * WAVE_HEIGHT / sampleDistance;

		//  wavesNormal.b = sqrt(1.0f - wavesNormal.r * wavesNormal.r - wavesNormal.g * wavesNormal.g);
		 wavesNormal.b = 1.0;
		 wavesNormal.rgb = normalize(wavesNormal.rgb);



	return wavesNormal.rgb;
}


/////////////////////////MAIN//////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
/////////////////////////MAIN//////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
void main() {
	MaterialMask mask;

	vec3 noisePattern = CalculateNoisePattern1(vec2(0.0f), 4);


	vec4 light = vec4(0.0, 0.0, 0.0, 1.0);

	#ifdef GI
		light = GetLight(GI_RENDER_RESOLUTION, vec2(0.0f), 16.0, GI_QUALITY, noisePattern, mask);
		light.a = mix(light.a, 1.0, mask.hand);
	#endif


	vec3 screenCaustics = GetWavesNormal(vec3(texcoord.s * 50.0, 1.0, texcoord.t * 50.0)).xyz;
	vec2 causticsNormal = EncodeNormal(screenCaustics);

	//vec4 data1 = texture(colortex1, texcoord.st);

	compositeOutput1 = vec4(LinearToGamma(light.rgb), light.a);
	compositeOutput2 = vec4(causticsNormal.xy, 0.0, 0.0);
}

/* DRAWBUFFERS:12 */
