
/*
====================================================================================================

    Copyright (C) 2025 Pyvtron VX Shaders - Pyvtron

    All Rights Reserved unless otherwise explicitly stated.

====================================================================================================
*/


float CurveBlockLightSky(float blockLight)
{
	blockLight = 1.0 - pow(1.0 - blockLight, 0.45);
	blockLight *= blockLight * blockLight;

	return blockLight;
}

float CurveBlockLightTorch(float blockLight)
{
	float decoded = pow(blockLight, 1.0 / 0.25);

	decoded = pow(decoded, 2.0) * 5.0;
	decoded += pow(decoded, 0.4) * 0.1 * TORCHLIGHT_FILL;

	return decoded;
}

struct Material
{
	float rawSmoothness;
	float rawMetalness;
	float roughness;
	float metalness;
	float f0;
	vec3 n;
	vec3 k;
	bool albedoTintsMetalReflections;
	bool doCSR;
};

struct GbufferData
{
	vec3 albedo;
	vec4 albedoW;
	vec3 normalL;
	vec3 normalW;
	float depthL;
	float depthW;
	vec2 lightmapL;
	vec2 lightmapW;
	float materialIDL;
	float materialIDW;
	float rainAlpha;
	float parallaxShadow;
	Material material;
};

struct Ray {
	vec3 dir;
	vec3 origin;
};

struct Plane {
	vec3 normal;
	vec3 origin;
};

struct Intersection {
	vec3 pos;
	float distance;
	float angle;
};

float F0ToIor(float f0) {
	f0 = sqrt(f0) * 0.99999; // *0.99999 to prevent divide by 0 errors
	return (1.0 + f0) / (1.0 - f0);
}
vec3 F0ToIor(vec3 f0) {
	f0 = sqrt(f0) * 0.99999; // *0.99999 to prevent divide by 0 errors
	return (1.0 + f0) / (1.0 - f0);
}

Material airMaterial 	= Material(0.0, 0.0, 0.0, 0.0, 0.0,    vec3(1.000275), vec3(0.0), false, false);
Material material_water = Material(1.0, 0.0, 0.0, 0.0, 0.1427, vec3(1.200000), vec3(0.0), false, true);
Material material_glass = Material(1.0, 0.0, 0.0, 0.0, 0.1863, vec3(1.458000), vec3(0.0), false, true);
Material material_ice 	= Material(1.0, 0.0, 0.0, 0.0, 0.1338, vec3(1.309000), vec3(0.0), false, true);

Material MaterialFromTex(vec3 baseTex, vec4 specTex)
{
	//materialID = floor(materialID * 255.0);
	Material material;
	float wet = specTex.a;
	//specTex.r = 1.0;

	#if TEXTURE_PBR_FORMAT == 0
		material.rawSmoothness = specTex.r * (1.0 - wet) + wet;
		material.rawMetalness = specTex.g;

		material.roughness = (1.0 - material.rawSmoothness);
		material.roughness *= material.roughness;

		material.metalness = material.rawMetalness;

		material.f0 = mix(0.04, 1.0, material.rawMetalness);
		//material.n = F0ToIor(mix(vec3(0.04) * material.rawSmoothness, baseTex, material.rawMetalness)) * airMaterial.n;
		//material.k = vec3(0.0);

	#elif TEXTURE_PBR_FORMAT == 1
		bool isMetal = specTex.g > (229.5 / 255.0);

		#ifdef SSR_WET
			material.rawSmoothness = specTex.r * (1.0 - wet) + wet;
		#else
			material.rawSmoothness = specTex.r;
		#endif
		material.rawMetalness = float(isMetal);


		material.roughness = (1.0 - (specTex.r * (1.0 - wet) + wet));
		material.roughness *= material.roughness;

		material.metalness = material.rawMetalness;

		if (isMetal) {
		material.f0 = 0.91;
		int index = int(specTex.g * 255.0 + 0.5) - 230;
		material.albedoTintsMetalReflections = index < 8;
		if (material.albedoTintsMetalReflections) {
			vec3[8] metalN = vec3[8](
				vec3(2.91140, 2.94970, 2.58450), // Iron
				vec3(0.18299, 0.42108, 1.37340), // Gold
				vec3(1.34560, 0.96521, 0.61722), // Aluminium
				vec3(3.10710, 3.18120, 2.32300), // Chrome
				vec3(0.27105, 0.67693, 1.31640), // Copper
				vec3(1.91000, 1.83000, 1.44000), // Lead
				vec3(2.37570, 2.08470, 1.84530), // Platinum
				vec3(0.15943, 0.14512, 0.13547)  // Silver
			);
			vec3[8] metalK = vec3[8](
				vec3(3.0893, 2.9318, 2.7670), // Iron
				vec3(3.4242, 2.3459, 1.7704), // Gold
				vec3(7.4746, 6.3995, 5.3031), // Aluminium
				vec3(3.3314, 3.3291, 3.1350), // Chrome
				vec3(3.6092, 2.6248, 2.2921), // Copper
				vec3(3.5100, 3.4000, 3.1800), // Lead
				vec3(4.2655, 3.7153, 3.1365), // Platinum
				vec3(3.9291, 3.1900, 2.3808)  // Silver
			);

			material.n = metalN[index];
			material.k = metalK[index];
		} else {
			material.n = F0ToIor(baseTex.rgb) * airMaterial.n;
			material.k = vec3(0.0);
		}
	} else {
		material.f0 = mix(0.02, 1.0, specTex.g);
		material.n = F0ToIor(mix(vec3(0.04) * material.rawSmoothness, baseTex, material.rawMetalness)) * airMaterial.n;
		material.k = vec3(0.0);

		material.albedoTintsMetalReflections = false;
	}

	#endif


	#ifdef ROUGHNESS_CLAMP
		material.doCSR = saturate(0.625 - material.roughness) + material.rawMetalness > 0.0001;
	#else
		material.doCSR = saturate(1.0 - material.roughness) + material.rawMetalness > 0.0001;
	#endif


	return material;
}



GbufferData GetGbufferData()
{
	GbufferData data;

	vec4 gbuffer0 = texture(colortex0, texcoord.st);
	vec4 gbuffer3 = texture(colortex3, texcoord.st);
	vec4 gbuffer4 = texture(colortex4, texcoord.st);
	vec4 gbuffer5 = texture(colortex5, texcoord.st);
	vec4 gbuffer6 = texture(colortex6, texcoord.st);

	data.albedo 		= GammaToLinear(gbuffer0.rgb);
	data.albedoW 		= vec4(UnpackTwo8BitFrom16Bit(gbuffer5.r), UnpackTwo8BitFrom16Bit(gbuffer5.g));
	data.albedoW.rgb 	= GammaToLinear(data.albedoW.rgb);
	data.normalL 		= DecodeNormal(gbuffer3.rg);
	data.normalW 		= DecodeNormal(gbuffer4.rg);
	data.depthL 		= texture(depthtex1, texcoord.st).r;
	data.depthW 		= texture(gdepthtex, texcoord.st).r;
	data.lightmapL 		= gbuffer3.ba;
	data.lightmapW 		= gbuffer4.ba;
	data.lightmapL 		= vec2(CurveBlockLightTorch(data.lightmapL.r), CurveBlockLightSky(data.lightmapL.g));
	data.lightmapW 		= vec2(CurveBlockLightTorch(data.lightmapW.r), CurveBlockLightSky(data.lightmapW.g));
	data.materialIDL 	= gbuffer6.b;
	data.materialIDW 	= gbuffer5.b;
	data.rainAlpha 		= 1.0 - gbuffer0.a;
	data.rainAlpha 		= data.rainAlpha > 0.999 ? 0.0 : data.rainAlpha;
	data.parallaxShadow = gbuffer6.a;


	vec4 specTex		= vec4(UnpackTwo8BitFrom16Bit(gbuffer6.r), UnpackTwo8BitFrom16Bit(gbuffer6.g));
	data.material       = MaterialFromTex(data.albedo, specTex);

	return data;
}
