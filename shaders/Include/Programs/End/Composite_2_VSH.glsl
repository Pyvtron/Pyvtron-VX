/*
====================================================================================================

    Copyright (C) 2025 Pyvtron VX Shaders - Pyvtron

    All Rights Reserved unless otherwise explicitly stated.

====================================================================================================
*/


#include "/Include/Uniforms.glsl"
#include "/Include/Core/Core.glsl"

uniform float roataionAngle;
mat4 shadowRoataionMatrix = mat4(cos(roataionAngle * PI), sin(roataionAngle * PI), 0, 0,
                                -sin(roataionAngle * PI), cos(roataionAngle * PI), 0, 0,
                                                       0,                       0, 1, 0,
                                                       0,                       0, 0, 1);

mat4 shadowModelViewInverseEnd = transpose(shadowRoataionMatrix) * shadowModelViewInverse;


out vec4 texcoord;

out vec3 lightVector;
out vec3 sunVector;
out vec3 upVector;

out vec3 colorTorchlight;

out vec3 worldLightVector;
out vec3 worldSunVector;


#include "/Include/RGB.glsl"


void main()
{
	gl_Position = ftransform();

	texcoord = gl_MultiTexCoord0;

	//Calculate ambient light from atmospheric scattering
	worldSunVector = shadowModelViewInverseEnd[2].xyz;
	worldLightVector = worldSunVector;

	sunVector = normalize((gbufferModelView * vec4(worldSunVector.xyz, 0.0)).xyz);
	lightVector = sunVector;

	if (sunAngle >= 0.5f)
	{
		worldSunVector *= -1.0;
		sunVector *= -1.0;
	}


	upVector = gbufferModelView[1].xyz;


	if(TORCHLIGHT_COLOR_TEMPERATURE == 2000)      colorTorchlight = pow(vec3(255, 141,  11) / 255.0, vec3(2.2)); //2000k
	else if(TORCHLIGHT_COLOR_TEMPERATURE == 2300) colorTorchlight = pow(vec3(255, 152,  54) / 255.0, vec3(2.2)); //2300k
	else if(TORCHLIGHT_COLOR_TEMPERATURE == 2500) colorTorchlight = pow(vec3(255, 166,  69) / 255.0, vec3(2.2)); //2500k
	else if(TORCHLIGHT_COLOR_TEMPERATURE == 3000) colorTorchlight = pow(vec3(255, 180, 107) / 255.0, vec3(2.2)); //3000k
	else if(TORCHLIGHT_COLOR_TEMPERATURE == 5000) colorTorchlight = pow(vec3(1.0f)                 , vec3(2.2)); //5000k
	else                                          colorTorchlight = pow(RGBcircling(frameTimeCounter, 360.0, 0.0, 50.0), vec3(2.2));

}
