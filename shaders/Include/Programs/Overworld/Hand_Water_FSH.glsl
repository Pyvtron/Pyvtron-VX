/*
====================================================================================================

    Copyright (C) 2025 Pyvtron VX Shaders - Pyvtron

    All Rights Reserved unless otherwise explicitly stated.

====================================================================================================
*/


#include "/Include/Settings.glsl"

uniform sampler2D texture;
uniform sampler2D specular;
uniform sampler2D normals;
uniform float wetness;

in vec4 color;
in vec4 texcoord;
in vec3 worldNormal;
in vec4 viewPos;
in vec2 blockLight;
in float materialIDs;


#include "/Include/Core/Core.glsl"

float CurveBlockLightTorch(float blockLight)
{
	float falloff = 10.0;

	blockLight = exp(-(1.0 - blockLight) * falloff);
	blockLight = max(0.0, blockLight - exp(-falloff));

	return blockLight;
}


void main()
{
//albedo
	vec4 albedo = texture2D(texture, texcoord.st);
	albedo *= color;

	#ifdef WHITE_DEBUG_WORLD
		albedo.rgb = vec3(1.0);
	#endif


//normal
	mat3 tbn;
	vec3 N;
	vec2 uv = texcoord.st;
	{
		vec3 dp1 = dFdx(viewPos.xyz);
		vec3 dp2 = dFdy(viewPos.xyz);
		vec2 duv1 = dFdx(uv);
		vec2 duv2 = dFdy(uv);
		N = normalize(cross(dp1, dp2));
		uv *= textureSize(texture, 0);
		vec3 dp2perp = cross(dp2, N);
		vec3 dp1perp = cross(N, dp1);
		vec3 T = normalize(dp2perp * duv1.x + dp1perp * duv2.x);
		vec3 B = normalize(dp2perp * duv1.y + dp1perp * duv2.y);
		float invmax = inversesqrt(max(dot(T, T), dot(B, B)));
		tbn = mat3(T * invmax, B * invmax, N);
	}
	vec4 normalTex = texture2D(normals, texcoord.st) * 2.0 - 1.0;
	vec3 viewNormal = tbn * normalize(normalTex.xyz);

	#ifdef HAND_NORMAL_CLAMP
		vec3 viewDir = -normalize(viewPos.xyz);
		viewNormal.xyz = normalize(viewNormal.xyz + N / (sqrt(saturate(dot(viewNormal, viewDir)) + 0.001)));
	#endif

	vec2 normalEnc = EncodeNormal(viewNormal.xyz);


//specular
	vec4 specTex = texture2D(specular, texcoord.st);

	float wet = wetness;
	wet *= saturate(worldNormal.y * 0.5 + 0.5);
	wet *= clamp(blockLight.y * 1.05 - 0.9, 0.0, 0.1) / 0.1;

	specTex.a = wet;


//lightmap
	vec2 mcLightmap = blockLight.xy;
	mcLightmap.x = CurveBlockLightTorch(mcLightmap.x);
	mcLightmap.x = pow(mcLightmap.x, 0.25);



	gl_FragData[0] = vec4(PackTwo8BitTo16Bit(albedo.rg), PackTwo8BitTo16Bit(albedo.ba), (materialIDs + 0.1) / 255.0, 1.0);
    gl_FragData[1] = vec4(normalEnc, mcLightmap);
}

/* DRAWBUFFERS:54 */
