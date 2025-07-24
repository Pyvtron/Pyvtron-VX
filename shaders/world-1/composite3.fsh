#version 450

layout(location = 0) out vec4 compositeOutput3;

#include "/OldInclude/uniform.glsl"
#include "/OldInclude/core/Common.inc"

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


#include "/OldInclude/core/GbufferData.inc"
#include "/OldInclude/core/Mask.inc"

#include "/OldInclude/SSR.glsl"


/////////////////////////MAIN//////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
/////////////////////////MAIN//////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
void main()
{

	GbufferData gbuffer 			= GetGbufferData();
	MaterialMask materialMask 		= CalculateMasks(gbuffer.materialIDW);

	vec4 reflection = ReflectionFilter(colortex3, gbuffer, 30.0, false);

	compositeOutput3 = reflection;
}

/* DRAWBUFFERS:3 */
