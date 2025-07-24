/*
====================================================================================================

    Copyright (C) 2025 Pyvtron VX Shaders - Pyvtron

    All Rights Reserved unless otherwise explicitly stated.

====================================================================================================
*/


#include "/Include/Settings.glsl"

out vec4 texcoord;
out vec4 color;
out vec3 normal;
out vec4 lmcoord;

#if MC_VERSION >= 11500
layout(location = 11) in vec4 mc_Entity;
#else
layout(location = 10) in vec4 mc_Entity;
#endif

uniform vec3 cameraPosition;

uniform mat4 shadowProjectionInverse;
uniform mat4 shadowProjection;
uniform mat4 shadowModelViewInverse;
uniform mat4 shadowModelView;


void main() {
	gl_Position = ftransform();

	lmcoord = gl_TextureMatrix[1] * gl_MultiTexCoord1;
	texcoord = gl_MultiTexCoord0;

	vec4 position = gl_Position;

	position = shadowProjectionInverse * position;
	position = shadowModelViewInverse * position;
	position.xyz += cameraPosition.xyz;

		if (mc_Entity.x == 8 || mc_Entity.x == 79)
		{
			position.xyz += 10000.0;
		}


	position.xyz -= cameraPosition.xyz;

	//#define SPHERICAL_WORLD

	#define RADIUS 200 // [50 75 100 150 200 300 500 1000 1500 2000]

	#ifdef SPHERICAL_WORLD
		float distance2D = position.x * position.x + position.z * position.z;
		position.y += sqrt(RADIUS * RADIUS - distance2D) - RADIUS;
	#endif

	position = shadowModelView * position;
	position = shadowProjection * position;



	vec3 worldNormal = gl_Normal;

	if (mc_Entity.x == 21)
	{
		worldNormal = vec3(0.0, 1.0, 0.0);
	}

	normal = normalize(gl_NormalMatrix * worldNormal);

	color = gl_Color;

	gl_Position = position;

	float dist = sqrt(dot(gl_Position.xy, gl_Position.xy));
	float distortFactor = (1.0f - SHADOW_MAP_BIAS) + dist * SHADOW_MAP_BIAS + 0.0;
	gl_Position.xy *= 0.95f / distortFactor;

	gl_Position.z = mix(gl_Position.z, 0.5, 0.8);

	//gl_FrontColor = gl_Color;

}
