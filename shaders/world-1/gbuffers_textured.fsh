#version 450 compatibility

//gbuffers_textured.fsh

#include "/OldInclude/settings.glsl"

uniform sampler2D texture;

in vec4 color;
in vec4 texcoord;
in vec2 blockLight;
in float materialIDs;


#include "/OldInclude/core/Common.inc"

float CurveBlockLightTorch(float blockLight)
{
	float falloff = 10.0;

	blockLight = exp(-(1.0 - blockLight) * falloff);
	blockLight = max(0.0, blockLight - exp(-falloff));

	return blockLight;
}


void main(){
//albedo
    vec4 albedo = texture2D(texture, texcoord.st);
    albedo *= color;

	#ifdef WHITE_DEBUG_WORLD
        albedo.rgb = vec3(1.0);
    #endif


//normal
	vec2 normalEnc = EncodeNormal(vec3(0.0, 0.0, 1.0));


//lightmap
    vec2 mcLightmap = blockLight.xy;
    mcLightmap.x = CurveBlockLightTorch(mcLightmap.x);
    mcLightmap.x = pow(mcLightmap.x, 0.25);



    gl_FragData[0] = albedo;
    gl_FragData[1] = vec4(normalEnc, mcLightmap);
    gl_FragData[2] = vec4(0.0, 0.0, (materialIDs + 0.1) / 255.0, 1.0);
}
/* DRAWBUFFERS:036 */
