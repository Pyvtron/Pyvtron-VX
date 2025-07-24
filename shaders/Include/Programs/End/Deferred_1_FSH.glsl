/*
====================================================================================================

    Copyright (C) 2025 Pyvtron VX Shaders - Pyvtron

    All Rights Reserved unless otherwise explicitly stated.

====================================================================================================
*/


#define DIMENSION_MAIN

#include "/Include/Uniforms.glsl"
#include "/Include/Core/Core.glsl"

#ifdef MC_GL_VENDOR_NVIDIA
	uniform sampler2D shadowtex1;
#else
	uniform sampler2D shadowtex0;
#endif

uniform sampler2D shadowcolor0; 
uniform sampler2D shadowcolor1; 


/* DRAWBUFFERS:2 */
layout(location = 0) out vec4 deferredOutput2;

#include "/Include/Uniform/GbufferTransforms.glsl"
#include "/Include/Uniform/ShadowTransforms.glsl"
#include "/Include/TemporalNoise.glsl"

ivec2 texelCoord = ivec2(gl_FragCoord.xy);
vec2 texCoord = gl_FragCoord.xy * pixelSize;

vec4 GI_TemporalFilter() {
	vec3 currentGI = texture(shadowcolor0, texCoord).rgb;

	vec3 previousGI = texture(shadowcolor1, texCoord).rgb;

	const float blendFactor = 0.9;

	vec3 filteredGI = mix(currentGI, previousGI, blendFactor);

	return vec4(filteredGI, 1.0);
}

// MAIN //////////////////////////////////////////////////////////////////////
void main() {
	deferredOutput2 = GI_TemporalFilter();
}
