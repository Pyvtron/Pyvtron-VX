/*
====================================================================================================

    Copyright (C) 2025 Pyvtron VX Shaders - Pyvtron

    All Rights Reserved unless otherwise explicitly stated.

====================================================================================================
*/


#include "/Include/Settings.glsl"

uniform sampler2D texture;
uniform sampler2D normals;
uniform sampler2D specular;
uniform sampler2D noisetex;
uniform sampler2D gaux1;
uniform sampler2D gaux2;
uniform sampler2D gaux3;

uniform float frameTimeCounter;
uniform vec3 sunPosition;
uniform ivec2 atlasSize;
uniform vec3 cameraPosition;

uniform mat4 gbufferModelView;
uniform mat4 gbufferModelViewInverse;
uniform mat4 gbufferProjection;
uniform mat4 gbufferProjectionInverse;

uniform float viewWidth;
uniform float viewHeight;
uniform float aspectRatio;
uniform float sunAngle;
uniform float wetness;

in vec4 color;
in vec4 texcoord;
in vec3 worldPosition;
in vec4 vertexPos;
in vec4 viewPos;
in vec3 normal;
in vec3 worldNormal;
in float distance;

in vec2 blockLight;
in float materialIDs;
in float noWetItem;

#include "/Include/Core/Core.glsl"

float CurveBlockLightTorch(float blockLight)
{
	float falloff = 10.0;

	blockLight = exp(-(1.0 - blockLight) * falloff);
	blockLight = max(0.0, blockLight - exp(-falloff));

	return blockLight;
}

vec4 GetTexture(in sampler2D tex, in vec2 coord)
{
	#ifdef PARALLAX
		vec4 t = vec4(0.0f);
		if (distance < 20.0f)
		{
			t = texture2DLod(tex, coord, 0);
		}
		else
		{
			t = texture2D(tex, coord);
		}
		return t;
	#else
		return texture2D(tex, coord);
	#endif
}


vec2 AtlasTiles;
float TextureTexel;

vec2 OffsetCoord(in vec2 coord, in vec2 offset)
{
	vec2 interTileCoord = fract(coord + offset);
	return (floor(coord) + interTileCoord) / AtlasTiles;
}

vec2 OffsetCoord2(in vec2 coord, in vec2 offset)
{
	int tileResolution = TEXTURE_RESOLUTION;
	ivec2 atlasTiles = textureSize(texture, 0) / TEXTURE_RESOLUTION;
	ivec2 atlasResolution = tileResolution * atlasTiles;

	coord *= atlasResolution;

	vec2 offsetCoord = coord + mod(offset.xy * atlasResolution, vec2(tileResolution));

	vec2 minCoord = vec2(coord.x - mod(coord.x, tileResolution), coord.y - mod(coord.y, tileResolution));
	vec2 maxCoord = minCoord + tileResolution;

	if (offsetCoord.x > maxCoord.x) {
		offsetCoord.x -= tileResolution;
	} else if (offsetCoord.x < minCoord.x) {
		offsetCoord.x += tileResolution;
	}

	if (offsetCoord.y > maxCoord.y) {
		offsetCoord.y -= tileResolution;
	} else if (offsetCoord.y < minCoord.y) {
		offsetCoord.y += tileResolution;
	}

	offsetCoord /= atlasResolution;

	return offsetCoord;
}


float BilinearHeightSample(vec2 coord)
{
	vec2 fpc = fract(coord * atlasSize + 0.5);
	coord *= AtlasTiles;

	vec4 sh;
	sh = vec4(
		texture2DLod(normals, OffsetCoord(coord, vec2(-TextureTexel,  TextureTexel)), 0).a,
		texture2DLod(normals, OffsetCoord(coord, vec2( TextureTexel,  TextureTexel)), 0).a,
		texture2DLod(normals, OffsetCoord(coord, vec2( TextureTexel, -TextureTexel)), 0).a,
		texture2DLod(normals, OffsetCoord(coord, vec2(-TextureTexel, -TextureTexel)), 0).a
	);

	return mix(
		mix(sh.w, sh.z, fpc.x),
		mix(sh.x, sh.y, fpc.x),
		fpc.y
	);
}

vec2 CalculateParallaxCoord(vec2 coord, vec3 viewVector, vec2 texGradX, vec2 texGradY, out vec3 offsetCoord)
{
	vec2 parallaxCoord = coord.st;
	vec3 stepScale = vec3(0.001, 0.001, 0.15);

	float parallaxDepth = PARALLAX_DEPTH;




	const float gradThreshold = 0.01 * PARALLAX_DISTANCE;
	float absoluteTexGrad = dot(abs(texGradX) + abs(texGradY), vec2(1.0));

	parallaxDepth *= 1.0 - saturate(absoluteTexGrad / gradThreshold);
	if (absoluteTexGrad > gradThreshold)
	{
		offsetCoord = vec3(0.0, 0.0, 1.0);
		return texcoord.st;
	}

	float parallaxStepSize = 0.5;

	stepScale.xy *= parallaxDepth;
	stepScale *= parallaxStepSize;

	#ifdef SMOOTH_PARALLAX
	float heightmap = BilinearHeightSample(coord.xy);
	#else
	float heightmap = textureGrad(normals, coord.st, texGradX, texGradY).a;
	#endif

	vec3 pCoord = vec3(0.0f, 0.0f, 1.0f);
	vec2 basicCoord = coord.xy * AtlasTiles;


	if (heightmap < 1.0)
	{
		const int maxRefinements = 4;
		int numRefinements = 0;

		vec3 stepSize = viewVector * stepScale * 0.25 * (absoluteTexGrad * 15500.0 + 1.0);
		stepSize.xy *= AtlasTiles;
		float sampleHeight = heightmap;


		for (int i = 0; i < 80; i++)
		{
			pCoord += stepSize;

			parallaxCoord = OffsetCoord(basicCoord, pCoord.xy);

			#ifdef SMOOTH_PARALLAX
			sampleHeight = BilinearHeightSample(parallaxCoord);
			#else
			sampleHeight = textureGrad(normals, parallaxCoord, texGradX, texGradY).a;
			#endif


			if (sampleHeight > pCoord.z)
			{
				if (numRefinements < maxRefinements)
				{
					pCoord -= stepSize;
					stepSize *= 0.5;
					numRefinements++;
				}
				else
				{
					break;
				}
			}
		}
	}
	pCoord.xy /= AtlasTiles;
	offsetCoord = pCoord;

	return parallaxCoord;
}

float GetParallaxShadow(in vec2 texcoord, in vec3 lightVector, float baseHeight, in vec2 texGradX, in vec2 texGradY)
{
	float sunVis = 1.0;

	lightVector.z *= 64.0;
	lightVector.z /= PARALLAX_DEPTH * 0.5;

	float shadowStrength = 1.0;

	const float gradThreshold = 0.01 * PARALLAX_DISTANCE;
	float absoluteTexGrad = dot(abs(texGradX) + abs(texGradY), vec2(1.0));

	shadowStrength *= saturate((1.0 - saturate(absoluteTexGrad / gradThreshold)) * 1.0);
	if (absoluteTexGrad > gradThreshold)
	{
		return 1.0;
	}

	vec3 currCoord = vec3(texcoord, baseHeight);

	float stepSize = 0.0005;
	ivec2 texSize = textureSize(texture, 0);
	currCoord.xy = (floor(currCoord.xy * texSize) + 0.5) / texSize;

	float allTexGrad = dot(abs(texGradX), vec2(1.0)) + dot(abs(texGradY), vec2(1.0));

	for (int i = 0; i < 12; i++)
	{
		currCoord = vec3(OffsetCoord2(currCoord.xy, lightVector.xy * stepSize), currCoord.z + lightVector.z * stepSize);
		float heightSample = textureGrad(normals, currCoord.xy, texGradX, texGradY).a;
		float shadowBias = 0.0015;
		sunVis *= mix(1.0, saturate((currCoord.z - heightSample + shadowBias) / 0.01), shadowStrength);
	}

	return sunVis;
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
	if (wetness < 0.01)
	{
		return 0.0;
	}

	//pos.y += frameTimeCounter * 3.0f;
	pos.xz *= 1.0f;
	pos.y *= 0.2f;

	vec3 p = pos;
	float n = Get3DNoise(p).y;
		  n += Get3DNoise(p / 2.0f).x * 2.0f;
		  n += Get3DNoise(p / 4.0f).x * 4.0f;

		  n /= 7.0f;

	n = saturate(n * 2.0 - 0.4) * 0.75;
	return n;
}


#include "/Include/WaterRipples.glsl"


void main(){
//parallax
    vec2 texGradX = dFdx(texcoord.st);
    vec2 texGradY = dFdy(texcoord.st);
    vec2 textureCoordinate = texcoord.st;

	mat3 tbn;
	vec3 N;
	vec2 uv = textureCoordinate;
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

    #ifdef PARALLAX
        AtlasTiles = atlasSize / TEXTURE_RESOLUTION;
        TextureTexel = 0.5 / TEXTURE_RESOLUTION;
        vec3 offsetCoord = vec3(0.0, 0.0, 1.0);

        vec3 texViewVector = viewPos.xyz * tbn;
        float atlasAspectRatio = atlasSize.x / atlasSize.y;
        texViewVector.y *= atlasSize.x / atlasSize.y;
        texViewVector = normalize(texViewVector);
        textureCoordinate =  CalculateParallaxCoord(texcoord.st, texViewVector, texGradX, texGradY, offsetCoord);
    #endif


//albedo
	vec4 albedo = textureGrad(texture, textureCoordinate.st, texGradX, texGradY);
	albedo *= color;

	#ifdef WHITE_DEBUG_WORLD
		albedo.rgb = vec3(1.0);
	#endif


//wet effect
	float wet = GetModulatedRainSpecular(worldPosition.xyz + cameraPosition.xyz);

	#ifdef RAIN_SPLASH_EFFECT
		vec3 rainNormal = GetRainNormal(worldPosition.xyz + cameraPosition.xyz, wet);
	#endif

	wet *= saturate(worldNormal.y * 0.5 + 0.5);
	wet *= clamp(blockLight.y * 1.05 - 0.9, 0.0, 0.1) / 0.1;
	wet *= wetness * (1.0f - noWetItem);

	float wetFact = saturate(wet * 1.25);


//normal
	vec4 normalTex = textureGrad(normals, textureCoordinate.st, texGradX, texGradY) * 2.0 - 1.0;
	vec3 normalMap = mix(normalTex.xyz, vec3(0.0, 0.0, 1.0), wetFact);
	#ifdef RAIN_SPLASH_EFFECT
        normalMap = normalize(normalMap + rainNormal * wet * 0.7 * saturate(worldNormal.y) * vec3(1.0, 1.0, 0.0));
    #endif

	vec3 viewNormal = tbn * normalize(normalMap);

	#ifdef TERRAIN_NORMAL_CLAMP
		vec3 viewDir = -normalize(viewPos.xyz);
		viewNormal = normalize(viewNormal + N / (sqrt(saturate(dot(viewNormal, viewDir)) + 0.001)));
	#endif


	vec2 normalEnc = EncodeNormal(viewNormal.xyz);


//parallax shadow
	float parallaxShadow = 1.0;
	#ifdef PARALLAX
		#ifdef PARALLAX_SHADOW

			float baseHeight = GetTexture(normals, textureCoordinate.st).a;

			if (dot(normalize(sunPosition), viewNormal) > 0.0 && baseHeight < 1.0)
			{
				vec3 lightVector = normalize(sunPosition.xyz);
				lightVector = normalize(lightVector * tbn);
				lightVector.y *= atlasAspectRatio;
				lightVector = normalize(lightVector);
				parallaxShadow = GetParallaxShadow(textureCoordinate.st, lightVector, baseHeight, texGradX, texGradY);
			}
		#endif
	#endif


//specular
	vec4 specTex = textureGrad(specular, textureCoordinate.st, texGradX, texGradY);
	specTex.a = wetFact;


//lightmap
    vec2 mcLightmap = blockLight;
    mcLightmap.x = CurveBlockLightTorch(mcLightmap.x);
    mcLightmap.x = pow(mcLightmap.x, 0.2);



    gl_FragData[0] = albedo;
    gl_FragData[1] = vec4(normalEnc, mcLightmap);
    gl_FragData[2] = vec4(PackTwo8BitTo16Bit(specTex.rg), PackTwo8BitTo16Bit(specTex.ba), (materialIDs + 0.1) / 255.0, parallaxShadow);
}
/* DRAWBUFFERS:036 */