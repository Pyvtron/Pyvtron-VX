#version 450

layout(location = 0) out vec4 compositeOutput1;

#include "/OldInclude/uniform.glsl"
#include "/OldInclude/core/Common.inc"

const int 		RGB8        = 0;
const int 		RGBA8       = 0;
const int 		RGB16       = 0;
const int 		RGBA16      = 0;
const int 		RGBA32F 	= 0;


const int 		colortex0Format         = RGB8;
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

const float 	centerDepthHalflife 	= 1.0;		//[0.5 0.7 1.0 1.5 2.0 3.0 5.0 7.0 10.0]

const float     wetnessHalflife 		= 200.0; 	//[10.0 20.0 30.0 50.0 75.0 100.0 150.0 200.0 300.0 500.0]
const float     drynessHalflife 		= 50.0; 	//[10.0 20.0 30.0 50.0 75.0 100.0 150.0 200.0 300.0 500.0]


const bool		colortex1MipmapEnabled  = true;

uniform float BiomeNetherWastesSmooth;
uniform float BiomeSoulSandValleySmooth;
uniform float BiomeCrimsonForestSmooth;
uniform float BiomeWarpedForestSmooth;
uniform float BiomeBasaltDeltasSmooth;

in vec4 texcoord;

in vec3 colorTorchlight;


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

float 	ExpToLinearDepth(in float depth)
{
	return 2.0f * near * far / (far + near - (2.0f * depth - 1.0f) * (far - near));
}

float ScreenToViewSpaceDepth(float depth) {
    depth = depth * 2.0 - 1.0;
    return 1.0 / (depth * gbufferProjectionInverse[2][3] + gbufferProjectionInverse[3][3]);
}

#include "/OldInclude/core/GbufferData.inc"

#include "/OldInclude/core/Mask.inc"

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

	#ifdef CORRECT_PARTICLE_NORMAL
		if (mask.particle > 0.5 || mask.particlelit > 0.5){
			normal = vec3(0.0, 0.0, 1.0);
		}
	#endif

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

float BilateralUpsampleS(const in float scale, in vec2 offset, in float depth, in vec3 normal,  MaterialMask mask)
{
	vec2 recipres = vec2(1.0f / viewWidth, 1.0f / viewHeight);

	float light = 0.0f;
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

			light += textureLod(colortex1, fma(texcoord.st, vec2(1.0f / exp2(scale)), coord), 1).a * weight;

			weights += weight;
		}
	}


	light /= max(0.00001f, weights);

	return (weights < 0.01f) ? textureLod(colortex1, texcoord.st * vec2(1.0f / exp2(scale)), 1).a : light;
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
		vec3 blockLightColor =	 BiomeNetherWastesSmooth * vec3(0.99, 0.34, 0.1) * 0.018;
		blockLightColor +=		 BiomeSoulSandValleySmooth * vec3(0.6, 0.77, 1.0) * 0.007;
		blockLightColor +=		 BiomeCrimsonForestSmooth * vec3(0.99, 0.38, 0.05) * 0.02;
		blockLightColor +=		 BiomeWarpedForestSmooth * vec3(0.79, 0.82, 1.0) * 0.01;
		blockLightColor +=		 BiomeBasaltDeltasSmooth * vec3(1.0, 0.78, 0.62) * 0.04;

		float dist = opaqueDepth;
		dist = saturate(dist * 0.5);

		color = mix(color, blockLightColor, dist);
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

	if (materialMaskSoild.selection > 0.5) gbuffer.albedo = vec3(0.0);


	vec4 viewPos 					= GetViewPosition(texcoord.st, gbuffer.depthL);
	vec4 worldPos					= gbufferModelViewInverse * vec4(viewPos.xyz, 0.0);

	vec3 viewDir 					= normalize(viewPos.xyz);
	vec3 worldDir 					= normalize(worldPos.xyz);
	vec3 worldNormal 				= normalize((gbufferModelViewInverse * vec4(gbuffer.normalL, 0.0)).xyz);
	vec3 worldTransparentNormal 	= normalize((gbufferModelViewInverse * vec4(gbuffer.normalW, 0.0)).xyz);

	vec4 viewPosTransparent			= GetViewPosition(texcoord.st, texture(gdepthtex, texcoord.st).x);

	float linearDepth 				= ExpToLinearDepth(gbuffer.depthL);
	float cloudShadow = 1.0f;
	float globalCloudShadow			= 1.0;


	float totalInternalReflection = 0.75;
	vec3 finalComposite = vec3(0.0);


	gbuffer.albedo *= 1.0 + materialMask.water * 0.2;
	gbuffer.albedo *= 1.0 + materialMask.stainedGlass * 0.2;
	if (materialMask.water > 0.5 || materialMask.ice > 0.5)
	{
		gbuffer.lightmapL.g = gbuffer.lightmapW.g;
	}





//////AO(GI)

	float ao = BilateralUpsampleS(0, vec2(0.0f, 0.0f), linearDepth, gbuffer.normalL, materialMask);



	vec3 blockLightColor =	 BiomeNetherWastesSmooth * vec3(0.99, 0.34, 0.1) * 0.018;
	blockLightColor +=		 BiomeSoulSandValleySmooth * vec3(0.6, 0.77, 1.0) * 0.007;
	blockLightColor +=		 BiomeCrimsonForestSmooth * vec3(0.99, 0.38, 0.05) * 0.02;
	blockLightColor +=		 BiomeWarpedForestSmooth * vec3(0.79, 0.82, 1.0) * 0.01;
	blockLightColor +=		 BiomeBasaltDeltasSmooth * vec3(1.0, 0.78, 0.62) * 0.04;

	finalComposite += blockLightColor * gbuffer.albedo * ao;


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





//////held torch light
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

	finalComposite += gbuffer.albedo * heldLightFalloff * colorTorchlight * (1.0 + isEyeInWater * 20.0) * HELDLIGHT_BRIGHTNESS * 0.4;
	}




//////Sky
	if (materialMaskSoild.sky > 0.5) finalComposite = vec3(0.0);




	#ifdef UNDERWATER_FOG
		WaterFog(finalComposite, gbuffer.depthL);
	#endif


	finalComposite *= compositeOutputFactor;
	finalComposite = LinearToGamma(finalComposite);
	//finalComposite += rand(texcoord.st + sin(frameTimeCounter)) * (1.0 / 65535.0);

	compositeOutput1 = vec4(finalComposite.rgb, 1.0f);
}

/* DRAWBUFFERS:1 */
