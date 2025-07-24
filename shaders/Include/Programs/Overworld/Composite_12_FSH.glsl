/*
====================================================================================================

    Copyright (C) 2025 Pyvtron VX Shaders - Pyvtron

    All Rights Reserved unless otherwise explicitly stated.

====================================================================================================
*/


#include "/Include/Uniforms.glsl"
#include "/Include/Core/Core.glsl"

in vec4 texcoord;

#include "/Include/FXAA.glsl"

/////////////////////////MAIN//////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
/////////////////////////MAIN//////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
void main() {

	vec4 col = vec4(0.0);

	#if FINAL_FXAA > 1
		col = vec4(DoFXAASimple(colortex0, texcoord.st, ScreenTexel * 1.0).rgb, texture2DLod(colortex0, texcoord.st, 0).a);
	#else
		col = texture2DLod(colortex0, texcoord.st, 0);
	#endif

	gl_FragData[0] = col;
}

/* DRAWBUFFERS:0 */
