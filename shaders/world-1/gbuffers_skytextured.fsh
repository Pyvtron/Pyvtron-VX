#version 450 compatibility

//gbuffers_skytextured.fsh

#include "/OldInclude/settings.glsl"

uniform sampler2D texture;
uniform int isEyeInWater;
#ifndef COMPATIBLE_MODE
	uniform int renderStage;
#endif

in vec4 color;
in vec4 texcoord;


void main() {
	vec4 albedo = vec4(0.0);

#ifndef COMPATIBLE_MODE
#ifdef MOON_TEXTURE
	if (renderStage == MC_RENDER_STAGE_MOON)
    {
		albedo = texture2D(texture, texcoord.st);
		albedo *= color;
		if(isEyeInWater == 1) albedo.a = 0.0;
	}
#endif
#endif
	gl_FragData[0] = albedo;
}
/* DRAWBUFFERS:0 */
