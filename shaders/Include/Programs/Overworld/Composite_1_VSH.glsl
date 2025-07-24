
/*
====================================================================================================

    Copyright (C) 2025 Pyvtron VX Shaders - Pyvtron

    All Rights Reserved unless otherwise explicitly stated.

====================================================================================================
*/


#include "/Include/Uniforms.glsl"
#include "/Include/Core/Core.glsl"

out vec4 texcoord;

out vec3 lightVector;
out vec3 sunVector;
out vec3 upVector;

out float timeSunriseSunset;
out float timeNoon;
out float timeMidnight;

out vec3 colorSunlight;
out vec3 colorMoonlight;
out vec3 colorSkylight;
out vec3 colorTorchlight;

out vec4 skySHR;
out vec4 skySHG;
out vec4 skySHB;

out vec3 worldLightVector;
out vec3 worldSunVector;


#include "/Include/RGB.glsl"


void main()
{
	gl_Position = ftransform();

	texcoord = gl_MultiTexCoord0;


	//Calculate ambient light from atmospheric scattering
	worldSunVector = shadowModelViewInverse[2].xyz;
	worldLightVector = worldSunVector;

	sunVector = normalize((gbufferModelView * vec4(worldSunVector.xyz, 0.0)).xyz);
	lightVector = sunVector;

	if (sunAngle >= 0.5f)
	{
		worldSunVector *= -1.0;
		sunVector *= -1.0;
	}


	upVector = gbufferModelView[1].xyz;


	float nightDarkness = 0.005 * (1.0 + 32.0 * nightVision);


	float timePow = 6.0f;

	float LdotUp = dot(upVector, sunVector);
	float LdotDown = dot(-upVector, sunVector);

	timeNoon = 1.0 - pow(1.0 - (clamp(LdotUp, 0.2, 0.99) - 0.2) / 0.8, 6.0);
	timeMidnight = curve(curve(saturate(LdotDown * 20.0f + 0.4)));
	timeMidnight = 1.0 - pow(1.0 - timeMidnight, 2.0);


	float horizonTimeSun = curve(saturate((1.0 - abs(LdotUp)) * 20.0f - 19.0f));
	float horizonTimeMoon = curve(saturate((1.0 - abs(LdotDown)) * 7.0f - 6.0f));

	colorSunlight = AtmosphericScatteringSingle(worldSunVector, worldSunVector, 1.0) * 0.2;
	colorSunlight = normalize(colorSunlight + 0.001);
	colorSunlight *= pow(saturate(worldSunVector.y), 0.9);
	colorSunlight *= 1.0f - horizonTimeSun;

	colorMoonlight = AtmosphericScatteringSingle(-worldSunVector, -worldSunVector, 1.0) * 0.2;
	colorMoonlight = normalize(colorMoonlight + 0.001);
	colorMoonlight *= pow(saturate(-worldSunVector.y), 0.9);
	colorMoonlight *= NIGHT_BRIGHTNESS;
	colorMoonlight *= 1.0f - horizonTimeMoon;

	colorSunlight += colorMoonlight;


	const int latSamples = 5;
	const int lonSamples = 5;

	colorSkylight = vec3(0.0);
	vec4 shR = vec4(0.0);
	vec4 shG = vec4(0.0);
	vec4 shB = vec4(0.0);

	for (int i = 0; i < latSamples; i++)
	{
		float latitude = (float(i) / float(latSamples)) * 3.14159265;
			  latitude = latitude;
		for (int j = 0; j < lonSamples; j++)
		{
			float longitude = (float(j) / float(lonSamples)) * 3.14159265 * 2.0;

			vec3 kernel;
			kernel.x = cos(latitude) * cos(longitude);
			kernel.z = cos(latitude) * sin(longitude);
			kernel.y = sin(latitude);


			vec3 skyCol = AtmosphericScatteringHorizon(normalize(kernel + vec3(0.0, 1.0, 0.0) * 0.1), worldSunVector, 0.0, wetness);

			vec3 moonAtmosphere = AtmosphericScatteringHorizon(normalize(kernel + vec3(0.0, 1.0, 0.0) * 0.1), -worldSunVector, 0.0, wetness);
			//DoNightEye(moonAtmosphere);

			skyCol += moonAtmosphere * NIGHT_BRIGHTNESS;

			colorSkylight += skyCol;

			shR += ToSH(skyCol.r, kernel);
			shG += ToSH(skyCol.g, kernel);
			shB += ToSH(skyCol.b, kernel);

		}
	}
	colorSkylight /= latSamples * lonSamples;

	shR /= latSamples * lonSamples;
	shG /= latSamples * lonSamples;
	shB /= latSamples * lonSamples;

	skySHR = shR;
	skySHG = shG;
	skySHB = shB;




	//Torchlight color
	if(TORCHLIGHT_COLOR_TEMPERATURE == 2000)      colorTorchlight = pow(vec3(255, 141,  11) / 255.0, vec3(2.2)); //2000k
	else if(TORCHLIGHT_COLOR_TEMPERATURE == 2300) colorTorchlight = pow(vec3(255, 152,  54) / 255.0, vec3(2.2)); //2300k
	else if(TORCHLIGHT_COLOR_TEMPERATURE == 2500) colorTorchlight = pow(vec3(255, 166,  69) / 255.0, vec3(2.2)); //2500k
	else if(TORCHLIGHT_COLOR_TEMPERATURE == 3000) colorTorchlight = pow(vec3(255, 180, 107) / 255.0, vec3(2.2)); //3000k
	else if(TORCHLIGHT_COLOR_TEMPERATURE == 5000) colorTorchlight = pow(vec3(1.0f)                 , vec3(2.2)); //5000k
	else                                          colorTorchlight = pow(RGBcircling(frameTimeCounter, 360.0, 0.0, 50.0), vec3(2.2));

}
