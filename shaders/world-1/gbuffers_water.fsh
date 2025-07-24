#version 450 compatibility

//layout(location = 1) out vec4 gbufferOutput4;
//layout(location = 0) out vec4 gbufferOutput5;

#define world
#define gbuffers_water
#define fsh

#define WAVE_HEIGHT 1.0

#define WATER_PARALLAX

#define RAIN_SPLASH_EFFECT

//#define RAIN_SPLASH_BILATERAL

//#define WHITE_DEBUG_WORLD

uniform sampler2D texture;
uniform sampler2D normals;
uniform sampler2D specular;
uniform sampler2D noisetex;
uniform sampler2D gaux1;
uniform sampler2D gaux2;
uniform sampler2D gaux3;

uniform mat4 gbufferProjectionInverse;
uniform mat4 gbufferPreviousProjection;

uniform mat4 gbufferModelViewInverse;
uniform mat4 gbufferPreviousModelView;

uniform vec3 cameraPosition;
uniform vec3 previousCameraPosition;

uniform float frameTimeCounter;
uniform int isEyeInWater;
uniform int frameCounter;
uniform float wetness;

in vec4 color;
in vec4 texcoord;
in vec3 worldPosition;

in vec3 worldNormal;
in vec2 blockLight;
in vec4 viewPos;

in float iswater;
in float isice;
in float isStainedGlass;
in float isSlime;

in float distance;

in float materialIDs;


#include "/OldInclude/core/Common.inc"



vec4 textureSmooth(in sampler2D tex, in vec2 coord)
{
	vec2 res = vec2(64.0f, 64.0f);

	coord *= res;
	coord += 0.5f;

	vec2 whole = floor(coord);
	vec2 part  = fract(coord);

	part.x = part.x * part.x * (3.0f - 2.0f * part.x);
	part.y = part.y * part.y * (3.0f - 2.0f * part.y);
	// part.x = 1.0f - (cos(part.x * 3.1415f) * 0.5f + 0.5f);
	// part.y = 1.0f - (cos(part.y * 3.1415f) * 0.5f + 0.5f);

	coord = whole + part;

	coord -= 0.5f;
	coord /= res;

	return texture2D(tex, coord);
}

float AlmostIdentity(in float x, in float m, in float n)
{
	if (x > m) return x;

	float a = 2.0f * n - m;
	float b = 2.0f * m - 3.0f * n;
	float t = x / m;

	return (a * t + b) * t * t + n;
}


float GetWaves(vec3 position) {

    float wavesTime = frameTimeCounter * 0.7;

    vec2 p = position.xz / 20.0f;

    p.xy -= position.y / 20.0f;

    p.x = -p.x;

    p.x += wavesTime / 40.0f;
    p.y -= wavesTime / 40.0f;

    float weight = 1.0f;
    float weights = weight;

    float allwaves = 0.0f;

    float wave = textureSmooth(noisetex, (p * vec2(2.0f, 1.2f))  + vec2(0.0f,  p.x * 2.1f) ).z;
            p /= 2.1f;
            //p *= pow(2.0f, 1.0f);
            p.y -= wavesTime / 20.0f;
            p.x -= wavesTime / 30.0f;
    allwaves += wave;

    weight = 4.1f;
    weights += weight;
        wave = textureSmooth(noisetex, (p * vec2(2.0f, 1.4f))  + vec2(0.0f,  -p.x * 2.1f) ).z;
            p /= 1.5f;
            //p *= pow(2.0f, 2.0f);
            p.x += wavesTime / 20.0f;
        wave *= weight;
    allwaves += wave;

    weight = 17.25f;
    weights += weight;
        wave = (textureSmooth(noisetex, (p * vec2(1.0f, 0.75f))  + vec2(0.0f,  p.x * 1.1f) ).x);
            p /= 1.5f;
            p.x -= wavesTime / 55.0f;
        wave *= weight;
    allwaves += wave;

    weight = 15.25f;
    weights += weight;
        wave = (textureSmooth(noisetex, (p * vec2(1.0f, 0.75f))  + vec2(0.0f,  -p.x * 1.7f) ).x);
            p /= 1.9f;
            p.x += wavesTime / 155.0f;
        wave *= weight;
    allwaves += wave;

    weight = 29.25f;
    weights += weight;
        wave = abs(textureSmooth(noisetex, (p * vec2(1.0f, 0.8f))  + vec2(0.0f,  -p.x * 1.7f) ).y * 2.0f - 1.0f);
            p /= 2.0f;
            p.x += wavesTime / 155.0f;
        wave = 1.0f - AlmostIdentity(wave, 0.2f, 0.1f);
        wave *= weight;
    allwaves += wave;

    weight = 15.25f;
    weights += weight;
        wave = abs(textureSmooth(noisetex, (p * vec2(1.0f, 0.8f))  + vec2(0.0f,  p.x * 1.7f) ).y * 2.0f - 1.0f);
        wave = 1.0f - AlmostIdentity(wave, 0.2f, 0.1f);
        wave *= weight;
    allwaves += wave;

    allwaves /= weights;

    return allwaves;
}

vec3 GetWaterParallaxCoord(in vec3 position, in vec3 viewVector)
{
	vec3 parallaxCoord = position.xyz;

	vec3 stepSize = vec3(0.6f * WAVE_HEIGHT, 0.6f * WAVE_HEIGHT, 0.6f);

	float waveHeight = GetWaves(position);

		vec3 pCoord = vec3(0.0f, 0.0f, 1.0f);

		vec3 step = viewVector * stepSize;
		float distAngleWeight = ((distance * 0.2f) * (2.1f - viewVector.z)) / 2.0f;
		distAngleWeight = 1.0f;
		step *= distAngleWeight;

		float sampleHeight = waveHeight;

		for (int i = 0; sampleHeight < pCoord.z && i < 120; ++i)
		{
			pCoord.xy = mix(pCoord.xy, pCoord.xy + step.xy, clamp((pCoord.z - sampleHeight) / (stepSize.z * 0.2f * distAngleWeight / (-viewVector.z + 0.05f)), 0.0f, 1.0f));
			pCoord.z += step.z;
			//pCoord += step;
			sampleHeight = GetWaves(position + vec3(pCoord.x, 0.0f, pCoord.y));
		}

	parallaxCoord = position.xyz + vec3(pCoord.x, 0.0f, pCoord.y);

	return parallaxCoord;
}

vec3 GetWavesNormal(vec3 position, in mat3 tbn) {

	vec4 modelView = viewPos;

	vec3 viewVector = normalize(modelView.xyz * tbn);

		 viewVector = normalize(viewVector);


	#ifdef WATER_PARALLAX
		position = GetWaterParallaxCoord(position, viewVector);
	#endif


	const float sampleDistance = 13.0f;

	position -= vec3(0.005f, 0.0f, 0.005f) * sampleDistance;

	float wavesCenter = GetWaves(position);
	float wavesLeft = GetWaves(position + vec3(0.01f * sampleDistance, 0.0f, 0.0f));
	float wavesUp   = GetWaves(position + vec3(0.0f, 0.0f, 0.01f * sampleDistance));

	vec3 wavesNormal;
		 wavesNormal.r = wavesCenter - wavesLeft;
		 wavesNormal.g = wavesCenter - wavesUp;

		 wavesNormal.r *= 20.0f * WAVE_HEIGHT / sampleDistance;
		 wavesNormal.g *= 20.0f * WAVE_HEIGHT / sampleDistance;

     wavesNormal.b = 1.0;
	wavesNormal.rgb = normalize(wavesNormal.rgb);


	return wavesNormal.rgb;
}



float CurveBlockLightTorch(float blockLight)
{
	float falloff = 10.0;

	blockLight = exp(-(1.0 - blockLight) * falloff);
	blockLight = max(0.0, blockLight - exp(-falloff));

	return blockLight;
}


vec3 Get3DNoise(in vec3 pos)
{
	pos.z += 0.0f;
	vec3 p = floor(pos);
	vec3 f = fract(pos);
		 f = f * f * (3.0f - 2.0f * f);

	vec2 uv =  (p.xy + p.z * vec2(17.0f, 37.0f)) + f.xy;
	vec2 uv2 = (p.xy + (p.z + 1.0f) * vec2(17.0f, 37.0f)) + f.xy;
	vec2 coord =  (uv  + 0.5f) / 64.0f;
	vec2 coord2 = (uv2 + 0.5f) / 64.0f;
	vec3 xy1 = texture2D(noisetex, coord).xyz;
	vec3 xy2 = texture2D(noisetex, coord2).xyz;
	return mix(xy1, xy2, vec3(f.z));
}

vec3 Get3DNoiseNormal(in vec3 pos)
{
	float center = Get3DNoise(pos + vec3( 0.0f, 0.0f, 0.0f)).x * 2.0f - 1.0f;
	float left 	 = Get3DNoise(pos + vec3( 0.1f, 0.0f, 0.0f)).x * 2.0f - 1.0f;
	float up     = Get3DNoise(pos + vec3( 0.0f, 0.1f, 0.0f)).x * 2.0f - 1.0f;

	vec3 noiseNormal;
		 noiseNormal.x = center - left;
		 noiseNormal.y = center - up;

		 noiseNormal.x *= 0.2f;
		 noiseNormal.y *= 0.2f;

		 noiseNormal.b = sqrt(1.0f - noiseNormal.x * noiseNormal.x - noiseNormal.g * noiseNormal.g);
		 noiseNormal.b = 0.0f;

	return noiseNormal.xyz;
}

float GetModulatedRainSpecular(in vec3 pos)
{
	//pos.y += frameTimeCounter * 3.0f;
	pos.xz *= 1.0f;
	pos.y *= 0.2f;

	// pos.y += Get3DNoise(pos.xyz * vec3(1.0f, 0.0f, 1.0f)).x * 2.0f;

	vec3 p = pos;

	float n = Get3DNoise(p).y;
		  n += Get3DNoise(p / 2.0f).x * 2.0f;
		  n += Get3DNoise(p / 4.0f).x * 4.0f;

		  n /= 7.0f;


	n = saturate(n * 0.8 + 0.5) * 0.97;


	return n;
}

#include "/OldInclude/Ripple2.glsl"

void main() {
//albedo
	vec4 tex = texture2D(texture, texcoord.st);
	tex *= color;


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

	float wet = GetModulatedRainSpecular(worldPosition.xyz);
		  wet *= saturate(worldNormal.y * 0.5 + 0.5);
		  wet *= clamp(blockLight.y * 1.05 - 0.9, 0.0, 0.1) / 0.1;
		  wet *= wetness;

	vec3 waterNormal = vec3(0.0);

	waterNormal = texture2D(normals, texcoord.st).rgb * 2.0f - 1.0f;

    if (iswater > 0.5){
        waterNormal = GetWavesNormal(worldPosition, tbn);
    }

	#ifdef RAIN_SPLASH_EFFECT
		if(iswater > 0.5){
			waterNormal = normalize(waterNormal + GetRainNormal(worldPosition.xyz, wet) * wet * saturate(worldNormal.y) * vec3(1.0, 1.0, 0.0));
		}else{
			waterNormal = normalize(waterNormal + GetRainNormal(worldPosition.xyz, wet) * wet * saturate(worldNormal.y) * vec3(1.0, 1.0, 0.0));
		}
	#endif

	waterNormal = tbn * waterNormal;

	vec2 normalEnc = EncodeNormal(waterNormal);


//lightmap
    vec2 mcLightmap = blockLight;
    mcLightmap.x = CurveBlockLightTorch(mcLightmap.x);
    mcLightmap.x = pow(mcLightmap.x, 0.4);



	gl_FragData[0] = vec4(PackTwo8BitTo16Bit(tex.rg), PackTwo8BitTo16Bit(tex.ba), (materialIDs + 0.1) / 255.0, 1.0);
	gl_FragData[1] = vec4(normalEnc, mcLightmap);

}

/* DRAWBUFFERS:54 */
