/*
====================================================================================================

    Copyright (C) 2025 Pyvtron VX Shaders - Pyvtron

    All Rights Reserved unless otherwise explicitly stated.

====================================================================================================
*/


#define dh
#define fsh
#define dh_water

#include "/Include/Settings.glsl"
#include "/Include/Core/Core.glsl"

uniform sampler2D texture;
uniform sampler2D noisetex;
uniform sampler2D normals;

uniform float frameTimeCounter;

in vec4 color;
in vec2 texcoord;
in vec3 normal;
in vec3 worldPosition;
in vec2 blockLight;
in float iswater;

out vec4 fragColor0;
out vec4 fragColor1;
out vec4 fragColor2;

#define WAVE_HEIGHT 1.3

vec4 textureSmooth(in sampler2D tex, in vec2 coord) {
	vec2 res = vec2(64.0f, 64.0f);
	coord *= res;
	coord += 0.5f;
	vec2 whole = floor(coord);
	vec2 part  = fract(coord);
	part.x = part.x * part.x * (3.0 - 2.0 * part.x);
	part.y = part.y * part.y * (3.0 - 2.0 * part.y);
	coord = whole + part;
	coord -= 0.5f;
	coord /= res;
	return texture(tex, coord);
}

float GetWaves(vec3 position) {
	float time = frameTimeCounter * 0.7;
	vec2 p = position.xz / 20.0;
	p.xy -= position.y / 20.0;
	p.x = -p.x;
	p += time / vec2(40.0, -40.0);
	float weight = 1.0, weights = 1.0;
	float wave = textureSmooth(noisetex, p * vec2(2.0, 1.2) + vec2(0.0, p.x * 2.1)).z;
	float allwaves = wave;
	p /= 2.1; p += time / vec2(-30.0, -20.0);
	weight = 4.1; weights += weight;
	wave = textureSmooth(noisetex, p * vec2(2.0, 1.4) + vec2(0.0, -p.x * 2.1)).z;
	allwaves += wave * weight;
	return allwaves / weights;
}

vec3 GetWavesNormal(vec3 position) {
	const float sampleDistance = 13.0;
	position -= vec3(0.005, 0.0, 0.005) * sampleDistance;
	float center = GetWaves(position);
	float left   = GetWaves(position + vec3(0.01 * sampleDistance, 0.0, 0.0));
	float up     = GetWaves(position + vec3(0.0, 0.0, 0.01 * sampleDistance));
	vec3 normal;
	normal.r = (center - left) * 20.0 * WAVE_HEIGHT / sampleDistance;
	normal.g = (center - up) * 20.0 * WAVE_HEIGHT / sampleDistance;
	normal.b = 1.0;
	return normalize(normal);
}

float CurveBlockLightTorch(float blockLight) {
	float falloff = 10.0;
	blockLight = exp(-(1.0 - blockLight) * falloff);
	return max(0.0, blockLight - exp(-falloff));
}

void main() {
	vec4 tex = texture(texture, texcoord) * color;
	vec3 normalFinal = normal;
	if (iswater > 0.5) {
		normalFinal = GetWavesNormal(worldPosition);
	}

	vec2 normalEnc = EncodeNormal(normalFinal);
	vec2 lightmap = blockLight;
	lightmap.x = pow(CurveBlockLightTorch(lightmap.x), 0.4);

	fragColor0 = vec4(tex.rgb, 1.0);
	fragColor1 = vec4(normalEnc, lightmap);
	fragColor2 = vec4(0.0, 0.0, 1.0, 1.0); 
}
