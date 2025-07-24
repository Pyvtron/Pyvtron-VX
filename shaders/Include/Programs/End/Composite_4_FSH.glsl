/*
====================================================================================================

    Copyright (C) 2025 Pyvtron VX Shaders - Pyvtron

    All Rights Reserved unless otherwise explicitly stated.

====================================================================================================
*/


layout(location = 0) out vec4 compositeOutput3;


#include "/Include/Uniforms.glsl"
#include "/Include/Core/Core.glsl"


in vec4 texcoord;



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

#include "/Include/SSR.glsl"


/////////////////////////MAIN//////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
/////////////////////////MAIN//////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
void main()
{

	GbufferData gbuffer 			= GetGbufferData();
	MaterialMask materialMask 		= CalculateMasks(gbuffer.materialIDW);

	vec4 reflection = ReflectionFilter(colortex3, gbuffer, 15.0, true);

	compositeOutput3 = reflection;
}

/* DRAWBUFFERS:3 */
