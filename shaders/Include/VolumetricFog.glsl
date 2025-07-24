
/*
====================================================================================================

    Copyright (C) 2025 Pyvtron VX Shaders - Pyvtron

    All Rights Reserved unless otherwise explicitly stated.

====================================================================================================
*/


#define VFOG

#define VFOG_NOISE_TYPE 0 // [0 1 2]


#define VFOG_DENSITY 0.007 // [0.001 0.0015 0.002 0.003 0.005 0.007 0.01 0.015 0.02 0.025 0.03 0.035 0.04 0.05 0.07 0.1 0.15 0.2 0.25 0.3 0.35 0.4 0.45 0.5 0.55 0.60 0.65 0.70 0.75 0.80 0.85 0.90 0.95 1.0]
#define VFOG_DENSITY_BASE 1.0 // [0.0 0.2 0.4 0.6 0.8 1.0 1.25 1.5 1.75 2.0 3.0 4.0 5.0 6.0 7.0 8.0 9.0 10.0 11.0 12.0 13.0 14.0 15.0]

#define VFOG_HEIGHT 65.0 // [-100.0 -90.0 -80.0 -70.0 -60.0 -50.0 -40.0 -30.0 -20.0 -10.0 0.0 10.0 20.0 30.0 40.0 45.0 50.0 55.0 60.0 65.0 70.0 75.0 80.0 85.0 90.0 95.0 100.0 105.0 110.0 115.0 120.0 125.0 130.0 135.0 140.0 145.0 150.0 155.0 160.0 165.0 170.0 175.0 180.0 185.0 190.0 195.0 200.0 210.0 220.0 230.0 240.0 250.0 260.0 270.0 280.0 290.0 300.0 310.0 320.0 350.0 400.0 450.0 500.0 600.0 700.0 800.0 900.0 1000.0]
#define VFOG_HEIGHT_2 50.0 // [-100.0 -90.0 -80.0 -70.0 -60.0 -50.0 -40.0 -30.0 -20.0 -10.0 0.0 10.0 20.0 30.0 40.0 45.0 50.0 55.0 60.0 65.0 70.0 75.0 80.0 85.0 90.0 95.0 100.0 105.0 110.0 115.0 120.0 125.0 130.0 135.0 140.0 145.0 150.0 155.0 160.0 165.0 170.0 175.0 180.0 185.0 190.0 195.0 200.0 210.0 220.0 230.0 240.0 250.0 260.0 270.0 280.0 290.0 300.0 310.0 320.0 350.0 400.0 450.0 500.0 600.0 700.0 800.0 900.0 1000.0]
#define VFOG_FALLOFF 40.0 // [1.0 2.0 3.0 4.0 5.0 6.0 7.0 8.0 9.0 10.0 11.0 12.0 13.0 14.0 15.0 16.0 17.0 18.0 19.0 20.0 21.0 22.0 23.0 24.0 25.0 26.0 27.0 28.0 29.0 30.0 31.0 32.0 33.0 34.0 35.0 36.0 37.0 38.0 39.0 40.0 41.0 42.0 43.0 44.0 45.0 46.0 47.0 48.0 49.0 50.0 51.0 52.0 53.0 54.0 55.0 56.0 57.0 58.0 59.0 60.0 61.0 62.0 63.0 64.0 65.0 66.0 67.0 68.0 69.0 70.0 71.0 72.0 73.0 74.0 75.0 76.0 77.0 78.0 79.0 80.0 81.0 82.0 83.0 84.0 85.0 86.0 87.0 88.0 89.0 90.0 91.0 92.0 93.0 94.0 95.0 96.0 97.0 98.0 99.0 100.0]


#define VFOG_QUALITY 8 // [4 6 8 10 12 14 16 18 20 22 24 28 32 48 64 128]
#define VFOG_MULTISCAT_QUALITY 6 // [4 6 8 10 12 14 16 18 20 22 24 28 32 48 64 128]

#define VFOG_IGNORE_WORLDTIME
//#define INDOOR_VFOG
#define VFOG_STAINED
//#define VFOG_FLASHLIGHT
//#define VFOG_HQ_CLOUD_SHADOW

#define VFOG_SUNLIGHT_DENSITY 1.0 // [0.0 0.1 0.2 0.3 0.4 0.5 0.6 0.7 0.8 0.9 1.0 1.2 1.4 1.6 1.8 2.0 3.0 5.0 7.0 10.0 15.0 20.0 30.0 50.0 70.0 80.0 90.0 100.0]
#define VFOG_FOG_DENSITY 1.0 // [0.0 0.1 0.2 0.3 0.4 0.5 0.6 0.7 0.8 0.9 1.0 1.2 1.4 1.6 1.8 2.0 3.0 5.0 7.0 10.0 15.0 20.0 30.0 50.0 70.0 80.0 90.0 100.0]

#define VFOG_SUNLIGHT_STEPS 4 // [4 6 8 10 12 14 16 18 20 22 24 28 32 48 64 128]
#define VFOG_SUNLIGHT_STEPLENGTH 5.0 // [1.0 2.0 3.0 4.0 5.0 6.0 7.0 8.0 9.0 10.0]


float CalculatePowderEffect(float od){
    return 1.0 - exp(-od * 2.0);
}

float CalculatePowderEffect(float powder, float vDotL){
    return mix(powder, 1.0, vDotL * 0.5 + 0.5);
}

float CalculateVolumeInShadow(vec3 shadowPosition) {
    if (any(greaterThanEqual(abs(vec3(shadowPosition.xy, shadowPosition.z)), vec3(1.0)))) return 1.0;

    float solidShadow = step(shadowPosition.z, textureLod(shadowtex1, shadowPosition.xy, 0).x);

	return solidShadow;
}



float CalculateFogPhase(float vDotL){
    const float mixer = 0.5;

    float g1 = PhaseG(vDotL, 0.6);
    float g2 = PhaseG(vDotL, -0.5);

    return mix(g2, g1, mixer);
}


float CalculateMorningFogDepth(vec3 rayPosition, float sunTime, float baseDensity){

    float maxHeight = max(VFOG_HEIGHT, VFOG_HEIGHT_2);
    float minHeight = min(VFOG_HEIGHT, VFOG_HEIGHT_2);

    float k = max(rayPosition.y - maxHeight, 0.0) + max(minHeight - rayPosition.y, 0.0);

	float fogClouds = exp2(-pow(k * 2.0 / VFOG_FALLOFF, 2.0 - timeMidnight));

    return (fogClouds * VFOG_DENSITY * (0.07 + 0.13 * timeMidnight) + baseDensity) * sunTime;
}

float CalculateMorningFogDepthNoise1(vec3 rayPosition, float sunTime, float baseDensity)
{
    float k = abs(rayPosition.y - max(VFOG_HEIGHT, VFOG_HEIGHT_2)) / VFOG_FALLOFF;
    float fogDis = exp2(-pow(k, 0.65));
    vec3 fogCloudPos = rayPosition * 0.025;

	float fogTime = (frameTimeCounter * CLOUD_SPEED + 10.0 * FTC_OFFSET) * -0.0025;
	vec3 windDirection = vec3(fogTime, 0.0, -0.6 * fogTime);

	float fogClouds = 0.0;
	rayPosition *= 0.01;
	{
		const float octaves = 4;
		const float octAlpha = 0.5;
	    float octScale = 3.1;
	    float octShift = (octAlpha / octScale) / octaves;

	    float accum = 0.0;
	    float alpha = 0.5;
	    vec3  shift = windDirection;

		rayPosition += windDirection;

	    for (int i = 0; i < octaves; i++) {
			accum += alpha * Calculate3DNoise(rayPosition);
	        rayPosition = (rayPosition + shift) * octScale;
	        alpha *= octAlpha;
	    }
		fogClouds = accum;
	}

    fogClouds *= fogDis;

    fogClouds = saturate(fogClouds * 15.0 - 4.0);


    return (fogClouds * VFOG_DENSITY * 0.7 + baseDensity) * sunTime;
}

float CalculateMorningFogDepthNoise2(vec3 rayPosition, float sunTime, float baseDensity)
{
	float k = abs(rayPosition.y - max(VFOG_HEIGHT, VFOG_HEIGHT_2)) / VFOG_FALLOFF * 0.8;
    float fogDis = exp2(-pow(k, 0.8));
    vec3 fogCloudPos = rayPosition * 0.025;

	float fogTime = (frameTimeCounter * CLOUD_SPEED + 10.0 * FTC_OFFSET) * -0.0025;
	vec3 windDirection = vec3(fogTime, 0.0, -0.6 * fogTime);

	float fogClouds = 0.0;
	rayPosition *= 0.004;
	{
		const float octaves = 5;
		const float octAlpha = 0.5;
	    float octScale = 3.4;
	    float octShift = (octAlpha / octScale) / octaves;

	    float accum = 0.0;
	    float alpha = 0.5;
	    vec3  shift = windDirection;

		rayPosition += windDirection;

	    for (int i = 0; i < octaves; i++) {
			accum += alpha * Calculate3DNoise(rayPosition);
	        rayPosition = (rayPosition + shift) * octScale;
	        alpha *= octAlpha;
	    }
		fogClouds = accum;
	}

    fogClouds *= fogDis;

    fogClouds = saturate(fogClouds * 50.0 - 15.0);


    return (fogClouds * VFOG_DENSITY * 2.0 + baseDensity) * sunTime;
}




float CalculateMorningFogDepth(vec3 rayPosition, vec3 direction, const int steps, float sunTime, float baseDensity){
    float stepLength = VFOG_SUNLIGHT_STEPLENGTH;

    float totalDepth = 0.0;

    for (int i = 0; i < steps; i++, rayPosition += direction * stepLength){
		#if VFOG_NOISE_TYPE == 0
			totalDepth += CalculateMorningFogDepth(rayPosition, sunTime, baseDensity) * stepLength;
		#elif VFOG_NOISE_TYPE == 1
        	totalDepth += CalculateMorningFogDepthNoise1(rayPosition, sunTime, baseDensity) * stepLength;
		#elif VFOG_NOISE_TYPE == 2
			totalDepth += CalculateMorningFogDepthNoise2(rayPosition, sunTime, baseDensity) * stepLength;
		#elif VFOG_NOISE_TYPE == 3
			totalDepth += CalculateMorningFogDepthNoise3(rayPosition, sunTime, baseDensity) * stepLength;
		#endif

        stepLength *= 1.5;
    }

    return totalDepth;
}

void CalculateMultipleScatteringFogPhases(float vDotL, inout float phases[VFOG_MULTISCAT_QUALITY]){
    float cn = 1.0;

    for (int i = 0; i < VFOG_MULTISCAT_QUALITY; i++){
        phases[i] = CalculateFogPhase(vDotL * cn);

        cn *= 0.5;
    }
}

void VolumetricFog(inout vec3 color, in vec3 startPos, in vec3 endPos, in vec3 worldDir, in CloudProperties cloudProperties, in float noise, in float globalCloudShadow){

	float VoL = dot(worldDir, worldLightVector);
	const int steps = VFOG_QUALITY;

    //noise = 0.0;

	vec3 start = startPos + gbufferModelViewInverse[3].xyz;
	vec3 end = endPos + gbufferModelViewInverse[3].xyz;

	vec3 increment = (end - start) / steps;
	vec3 rayPosition = increment * noise + start + cameraPosition;

	vec3 shadowStart = WorldPosToShadowPos(start);
	vec3 shadowEnd = WorldPosToShadowPos(end);

	vec3 shadowIncrement = (shadowEnd - shadowStart) / steps;
	vec3 shadowRayPosition = shadowIncrement * noise + shadowStart;


	float rayLength = length(increment);

	float transmittance = 1.0;

	float raySunDensity = 0.0;
	float fogSkyDensity = 0.0;

	vec3 rayTranslucentColor = vec3(0.0);


	float sunTime = 1.0;
	#ifndef VFOG_IGNORE_WORLDTIME
		sunTime *= mix(1.0 - timeNoon, 1.0, wetness);
	#endif

    float EB = pow(clamp(float(eyeBrightnessSmooth.y), 0.0, 220.0) / 220.0, 6.0);

	float baseDensity = VFOG_DENSITY_BASE * (0.3 + timeMidnight) / far * 0.2;
    #ifndef INDOOR_VFOG
        baseDensity *= EB;
    #endif

	float[VFOG_MULTISCAT_QUALITY] phases;
	CalculateMultipleScatteringFogPhases(VoL, phases);


	for (int i = 0; i < steps; i++, rayPosition += increment, shadowRayPosition += shadowIncrement){

		if (transmittance < 0.001) {
			transmittance = 0.0;
			break;
		}

		#if VFOG_NOISE_TYPE == 0
			float stepDepth = CalculateMorningFogDepth(rayPosition, sunTime, baseDensity) * rayLength;
		#elif VFOG_NOISE_TYPE == 1
			float stepDepth = CalculateMorningFogDepthNoise1(rayPosition, sunTime, baseDensity) * rayLength;
		#elif VFOG_NOISE_TYPE == 2
			float stepDepth = CalculateMorningFogDepthNoise2(rayPosition, sunTime, baseDensity) * rayLength;
		#elif VFOG_NOISE_TYPE == 3
			float stepDepth = CalculateMorningFogDepthNoise3(rayPosition, sunTime, baseDensity) * rayLength;
		#endif


		if (stepDepth <= 0.0) continue;



		#ifdef VFOG_HQ_CLOUD_SHADOW
			float cloudShadow = 1.0;
			#ifdef VOLUMETRIC_CLOUDS
				#ifdef CLOUD_SHADOW
					cloudShadow = CloudShadow(rayPosition - cameraPosition, worldLightVector, cloudProperties);
				#endif
			#endif
		#endif

		float stepTransmittance = exp2(-stepDepth * rLOG2);
		float integral = 1.0 - stepTransmittance;

		float sunDepth = CalculateMorningFogDepth(rayPosition, worldLightVector, VFOG_SUNLIGHT_STEPS, sunTime, baseDensity);

		float powderLight  = CalculatePowderEffect(sunDepth);
		float powderView = CalculatePowderEffect(stepDepth);

		float powder = CalculatePowderEffect(powderLight, VoL) * CalculatePowderEffect(powderView, VoL);


		vec3 shadowPosition = shadowRayPosition;
		shadowPosition.xy = DistortShadowProjPos(shadowPosition.xy);

	    float solidDepth = textureLod(shadowtex1, shadowPosition.xy, 0).x;

		float shadow =  step(shadowPosition.z, solidDepth);
		if (any(greaterThanEqual(abs(vec3(shadowPosition.xy, shadowPosition.z)), vec3(1.0)))) shadow = 1.0;

		float transparentShadow = 0.0;

		#ifdef VFOG_STAINED
			float transparentDepth = textureLod(shadowtex0, shadowPosition.xy, 0).x;

			vec3 shadowColorSample = textureLod(shadowcolor0, shadowPosition.xy, 0).rgb;

			transparentShadow = step(transparentDepth, shadowPosition.z) * shadow;

			shadow -= transparentShadow;
		#endif

		float an = 1.0, bn = 1.0;


		for (int j = 0; j < VFOG_MULTISCAT_QUALITY; j++){
			float shadowMultiscat = exp2(-sunDepth * rLOG2 * bn);

			float raySunSample = integral * transmittance * an * phases[j] * powder * shadowMultiscat;
			float fogSkySample = integral * transmittance * an;

			#ifdef VFOG_HQ_CLOUD_SHADOW
				raySunSample *= cloudShadow;
				fogSkySample *= fma(cloudShadow, 0.5, 0.5);
			#endif

			#ifdef VFOG_STAINED
				rayTranslucentColor += raySunSample * transparentShadow * GammaToLinear(shadowColorSample);
			#endif

			raySunDensity += raySunSample * shadow;
			fogSkyDensity += fogSkySample;

			an *= 0.5;
			bn *= 0.5;
		}


		#ifdef VFOG_HQ_CLOUD_SHADOW
			transmittance *= mix(fma(stepTransmittance, 0.5, 0.5), stepTransmittance, cloudShadow);
		#else
			transmittance *= stepTransmittance;
		#endif
	}


	vec3 skylight = FromSH(skySHR, skySHG, skySHB, worldDir);
	skylight = skylight + colorSunlight;
	skylight = mix(skylight, colorSunlight * 0.3, vec3(wetness * 0.93));


	vec3 raySunColor = raySunDensity * colorSunlight;
	vec3 fogSkyColor = fogSkyDensity * skylight;

    #ifdef VFOG_STAINED
        raySunColor	+= colorSunlight * rayTranslucentColor;
    #endif

	#if VFOG_NOISE_TYPE == 0
		raySunColor *= 250.0;
		fogSkyColor *= 0.8;
	#elif VFOG_NOISE_TYPE == 1
		raySunColor *= 250.0;
		fogSkyColor *= 0.8;
	#elif VFOG_NOISE_TYPE == 2
		raySunColor *= 600.0;
		fogSkyColor *= 0.5;
	#elif VFOG_NOISE_TYPE == 3
		raySunColor *= 250.0;
		fogSkyColor *= 0.8;
	#endif

	#ifndef VFOG_HQ_CLOUD_SHADOW
		raySunColor *= globalCloudShadow;
		transmittance = mix(fma(transmittance, 0.5, 0.5), transmittance, globalCloudShadow);
	#endif

	#ifndef INDOOR_VFOG
		fogSkyColor *= EB;
		transmittance = mix(1.0, transmittance, EB);
	#endif

	color = transmittance * color;
	color += raySunColor * VFOG_SUNLIGHT_DENSITY + fogSkyColor * VFOG_FOG_DENSITY;
}
