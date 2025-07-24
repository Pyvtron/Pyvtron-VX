#version 450 compatibility

//gbuffers_basic.fsh

#include "/OldInclude/settings.glsl"

uniform sampler2D texture;
#ifndef COMPATIBLE_MODE
	uniform int renderStage;
#endif
in vec4 color;
in vec4 texcoord;
in vec3 normal;
in vec2 blockLight;

#include "/OldInclude/core/Common.inc"

float CurveBlockLightTorch(float blockLight)
{
	float falloff = 10.0;

	blockLight = exp(-(1.0 - blockLight) * falloff);
	blockLight = max(0.0, blockLight - exp(-falloff));

	return blockLight;
}

void main(){
    //vec4 albedo = texture2D(texture, texcoord.st);
    vec4 albedo = color;

	#ifdef WHITE_DEBUG_WORLD
		albedo.rgb = vec3(1.0);
	#endif


#ifdef COMPATIBLE_MODE
	float materialIDs = 200.0;
	gl_FragData[0] = vec4(albedo);
	//gl_FragData[1] = vec4(EncodeNormal(normal), mcLightmap);
	gl_FragData[2] = vec4(0.0, 0.0, (materialIDs + 0.1) / 255.0, 1.0);
#else
	float materialIDs = 1.0;
    if (renderStage == MC_RENDER_STAGE_OUTLINE)
    {
        albedo.rgb = vec3(1.0);
        materialIDs = 200.0;
    }

    if (renderStage == MC_RENDER_STAGE_DEBUG)
    {
        materialIDs = 200.0;
    }

//lightmap
	vec2 mcLightmap = blockLight.xy;
	mcLightmap.x = CurveBlockLightTorch(mcLightmap.x);
	mcLightmap.x = pow(mcLightmap.x, 0.25);

	gl_FragData[0] = vec4(albedo);
	gl_FragData[1] = vec4(EncodeNormal(normal), mcLightmap);
	gl_FragData[2] = vec4(0.0, 0.0, (materialIDs + 0.1) / 255.0, 1.0);
#endif
}

/* DRAWBUFFERS:036 */
