#version 450 compatibility


layout(location = 0) out vec4 compositeOutput0;


#include "/OldInclude/uniform.glsl"
#include "/OldInclude/core/Common.inc"


uniform float BiomeNetherWastesSmooth;
uniform float BiomeSoulSandValleySmooth;
uniform float BiomeCrimsonForestSmooth;
uniform float BiomeWarpedForestSmooth;
uniform float BiomeBasaltDeltasSmooth;


in vec4 texcoord;


#include "/OldInclude/core/Mask.inc"


float 	GetDepthLinear(in vec2 coord) {					//Function that retrieves the scene depth. 0 - 1, higher values meaning farther away
	return 2.0f * near * far / (far + near - (2.0f * texture2D(gdepthtex, coord).x - 1.0f) * (far - near));
}


vec4 cubic(float x)
{
    float x2 = x * x;
    float x3 = x2 * x;
    vec4 w;
    w.x =   -x3 + 3*x2 - 3*x + 1;
    w.y =  3*x3 - 6*x2       + 4;
    w.z = -3*x3 + 3*x2 + 3*x + 1;
    w.w =  x3;
    return w / 6.f;
}


vec4 BicubicTexture(in sampler2D tex, in vec2 coord)
{
	vec2 resolution = vec2(viewWidth, viewHeight);

	coord *= resolution;

	float fx = fract(coord.x);
    float fy = fract(coord.y);
    coord.x -= fx;
    coord.y -= fy;

    fx -= 0.5;
    fy -= 0.5;

    vec4 xcubic = cubic(fx);
    vec4 ycubic = cubic(fy);

    vec4 c = vec4(coord.x - 0.5, coord.x + 1.5, coord.y - 0.5, coord.y + 1.5);
    vec4 s = vec4(xcubic.x + xcubic.y, xcubic.z + xcubic.w, ycubic.x + ycubic.y, ycubic.z + ycubic.w);
    vec4 offset = c + vec4(xcubic.y, xcubic.w, ycubic.y, ycubic.w) / s;

    vec4 sample0 = texture2D(tex, vec2(offset.x, offset.z) / resolution);
    vec4 sample1 = texture2D(tex, vec2(offset.y, offset.z) / resolution);
    vec4 sample2 = texture2D(tex, vec2(offset.x, offset.w) / resolution);
    vec4 sample3 = texture2D(tex, vec2(offset.y, offset.w) / resolution);

    float sx = s.x / (s.x + s.y);
    float sy = s.z / (s.z + s.w);

    return mix( mix(sample3, sample2, sx), mix(sample1, sample0, sx), sy);
}


vec3 GetBloomTap(vec2 coord, const float octave, const vec2 offset)
{
	float scale = exp2(octave);

	coord /= scale;
	coord -= offset;

	return GammaToLinear(BicubicTexture(colortex2, coord).rgb);
}


vec2 CalcOffset(float octave)
{
    vec2 offset = vec2(0.0);

    vec2 padding = vec2(30.0) * pixelSize;

    offset.x = -min(3.0, floor(octave / 2.0)) * (0.25 + padding.x);
    offset.y = -(1.0 - (1.0 / exp2(octave))) - padding.y * octave;
	offset.y += min(3.0, floor(octave / 2.0)) * 0.25;

 	return offset;
}


vec3 GetBloom(vec2 coord)
{
	vec3 bloom = vec3(0.0);

	float w = 0.0;
	float ws = 0.0;
	const float p = 1.3;

	w = 1.0 / pow(p, 1.0); ws += w; bloom += GetBloomTap(coord, 1.0, CalcOffset(0.0)) 	* w;
	w = 1.0 / pow(p, 2.0); ws += w; bloom += GetBloomTap(coord, 2.0, CalcOffset(1.0)) 	* w;
	w = 1.0 / pow(p, 3.0); ws += w; bloom += GetBloomTap(coord, 3.0, CalcOffset(2.0)) 	* w;
	w = 1.0 / pow(p, 4.0); ws += w; bloom += GetBloomTap(coord, 4.0, CalcOffset(3.0)) 	* w;
	w = 1.0 / pow(p, 5.0); ws += w; bloom += GetBloomTap(coord, 5.0, CalcOffset(4.0)) 	* w;
	w = 1.0 / pow(p, 6.0); ws += w; bloom += GetBloomTap(coord, 6.0, CalcOffset(5.0)) 	* w;
	w = 1.0 / pow(p, 7.0); ws += w; bloom += GetBloomTap(coord, 7.0, CalcOffset(6.0)) 	* w;
	w = 1.0 / pow(p, 8.0); ws += w; bloom += GetBloomTap(coord, 8.0, CalcOffset(7.0)) 	* w;
	w = 1.0 / pow(p, 9.0); ws += w; bloom += GetBloomTap(coord, 9.0, CalcOffset(8.0)) 	* w;

	bloom /= ws;

	return bloom;
}


void AddFogScatter(inout vec3 color, in vec3 bloomData, in float exposure)
{
	float linearDepth = GetDepthLinear(texcoord.st);

	float fogDensity = 0.006f;

	if (isEyeInWater == 2) fogDensity = 0.5;

	float visibility = 1.0f / (pow(exp(linearDepth * fogDensity), 1.0f));
	float fogFactor = 1.0f - visibility;

	float bloomAmount = BLOOM_AMOUNT;

	float biomeOffset =	 BiomeNetherWastesSmooth;
	biomeOffset +=		 BiomeSoulSandValleySmooth * 0.2;
	biomeOffset +=		 BiomeCrimsonForestSmooth;
	biomeOffset +=		 BiomeWarpedForestSmooth * 0.3;
	biomeOffset +=		 BiomeBasaltDeltasSmooth * 0.5;

	#ifdef BLOOM_KB
		color = mix(color, bloomData, vec3(saturate(max(bloomAmount * 0.1, fogFactor + 0.1))) * biomeOffset);
	#else
		color += max(bloomAmount * biomeOffset * 0.1, bloomData * fogFactor + 0.1);
	#endif
}


/////////////////////////MAIN//////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
/////////////////////////MAIN//////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
void main() {
	float exposure = texture2DLod(colortex7, vec2(0.0, 0.0), 0).a;

	vec3 color = GammaToLinear(texture2D(colortex1, texcoord.st).rgb);

	#ifdef BLOOM_EFFECTS
		vec3 bloomData = GetBloom(texcoord.st);
		AddFogScatter(color, bloomData, saturate(exposure * 5.0));
	#endif

	color = LinearToGamma(color);

	compositeOutput0 = vec4(color, 0.0);
}

/* DRAWBUFFERS:1 */
