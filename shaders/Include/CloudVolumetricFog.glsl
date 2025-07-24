
/*
====================================================================================================

    Copyright (C) 2025 Pyvtron VX Shaders - Pyvtron

    All Rights Reserved unless otherwise explicitly stated.

====================================================================================================
*/


#define VCFOG
#define VCFOG_RANGE 			10000	// [6000 8000 10000 12500 15000 17500 20000]
#define VCFOG_DENSITY 			100.0	// [50.0 70.0 100.0 150.0 200.0 220.0 240.0 260.0 280.0 300.0 340.0 380.0 420.0 460.0 500.0]
#define VCFOG_QUALITY 			32		// [8 16 24 32 48 64 128]
//#define VCFOG_HIGH_ACCURACY
#define VCFOG_H_FADE_HEIGHT 	700 	// [500 600 700 800 1000 1200 1400 1600 1800 2000]
#define VCFOG_H_FADE_MIDPOINT 	50.0 	// [50.0 60.0 70.0 80.0 90.0 100.0 120.0 140.0 160.0 180.0 200.0]
#define VCFOG_D_FADE_RATIO 		0.05	// [0.03 0.04 0.05 0.06 0.07 0.08 0.09 0.1 0.2 0.3 0.4 0.5]

void VolumetricFogCloud(inout vec3 color, in vec3 worldDir, in CloudProperties cp, in MaterialMask mask, in float noise){

	float rayDensity = 0.0;

	int steps = VCFOG_QUALITY;

	vec3 start = gbufferModelViewInverse[3].xyz;
	vec3 end = worldDir * VCFOG_RANGE;

	vec3 increment = (end - start) / steps;
	vec3 rayPosition = increment * noise + cameraPosition;


	float VoL = dot(worldDir, worldLightVector);

	float planeLevel1 = cp.altitude + cp.thickness * cp.lowerLimit;
	float planeLevel2 = cp.altitude + cp.thickness * (cp.upperLimit + 0.8) * 0.5;
	float midPoint = VCFOG_H_FADE_MIDPOINT;
	float lowPoint = planeLevel1 + VCFOG_H_FADE_HEIGHT;

	float cloudDensity, rayLengthVertical, rayVerticalDensity;

	float an = 1.0;
	float fadeRatio = 1.0 - 160000.0 * VCFOG_D_FADE_RATIO / steps / VCFOG_RANGE;

	for (int i = 1; i <= steps; i++, rayPosition += increment)
	{

		if(rayPosition.y > planeLevel1) break;

		#ifdef VCFOG_HIGH_ACCURACY
			cloudDensity = CloudVolumetricFogHQ(rayPosition, worldLightVector, cp);
		#else
			cloudDensity = CloudVolumetricFog(rayPosition, worldLightVector, cp, planeLevel1, planeLevel2);
		#endif

		rayLengthVertical = planeLevel1 - rayPosition.y;

		rayVerticalDensity = remap(0.0, midPoint, rayLengthVertical);
		rayVerticalDensity *= remap(lowPoint, midPoint, rayLengthVertical);
		rayVerticalDensity = smoothstep(0.0, 1.0, rayVerticalDensity);

		cloudDensity *= rayVerticalDensity;

		rayDensity += cloudDensity * an;

		an *= fadeRatio;
	}
	rayDensity /= steps;


	vec3 rayColor = rayDensity * colorSunlight * VCFOG_DENSITY;

	rayColor *= pow((VoL + 1.0) * 0.5, 2.0);


	color += rayColor;
}
