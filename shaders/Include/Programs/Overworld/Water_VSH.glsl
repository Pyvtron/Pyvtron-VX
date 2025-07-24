/*
====================================================================================================

    Copyright (C) 2025 Pyvtron VX Shaders - Pyvtron

    All Rights Reserved unless otherwise explicitly stated.

====================================================================================================
*/


#include "/Include/Settings.glsl"

uniform vec3 cameraPosition;

uniform mat4 gbufferModelView;
uniform mat4 gbufferModelViewInverse;
uniform mat4 gbufferProjectionInverse;

uniform vec2 taaJitter;

#if MC_VERSION >= 11500
layout(location = 11) in vec4 mc_Entity;
#else
layout(location = 10) in vec4 mc_Entity;
#endif

out vec4 color;
out vec4 texcoord;
out vec3 worldNormal;

out vec4 viewPos;
out vec3 worldPosition;

out vec2 blockLight;

out float iswater;
out float isice;
out float isStainedGlass;
out float materialIDs;


void main() {
	viewPos = gl_ModelViewMatrix * gl_Vertex;
	gl_Position = gl_ProjectionMatrix * viewPos;

	#include "/Include/SphericalWorld.glsl"

	#ifdef TAA
		vec4 jitterPos = gl_Position;
		jitterPos.xy = taaJitter * jitterPos.w + jitterPos.xy;
		gl_Position = jitterPos;
	#endif
	//gl_Position.z -= 0.0001;

	worldPosition.xyz = mat3(gbufferModelViewInverse) * viewPos.xyz + cameraPosition.xyz;


	color = gl_Color;
	texcoord = gl_MultiTexCoord0;
	worldNormal = gl_Normal;



	vec4 lmcoord = gl_TextureMatrix[1] * gl_MultiTexCoord1;
	blockLight.x = clamp((lmcoord.x * 33.05f / 32.0f) - 1.05f / 32.0f, 0.0f, 1.0f);
	blockLight.y = clamp((lmcoord.y * 33.05f / 32.0f) - 1.05f / 32.0f, 0.0f, 1.0f);



	iswater = 0.0f;
	isice = 0.0f;
	isStainedGlass = 1.0f;
	materialIDs = 7;

	if(mc_Entity.x == 8)
	{
		iswater = 1.0;
		isStainedGlass = 0.0f;
		materialIDs = 6;
	}

	if (mc_Entity.x == 79)
	{
		isice = 1.0f;
		isStainedGlass = 0.0f;
		materialIDs = 8;
	}
}
