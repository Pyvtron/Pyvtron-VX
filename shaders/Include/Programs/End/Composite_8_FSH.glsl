/*
====================================================================================================

    Copyright (C) 2025 Pyvtron VX Shaders - Pyvtron

    All Rights Reserved unless otherwise explicitly stated.

====================================================================================================
*/


layout(location = 0) out vec4 compositeOutput1;
layout(location = 1) out vec4 compositeOutput7;


#include "/Include/Uniforms.glsl"
#include "/Include/Core/Core.glsl"


const bool		colortex1MipmapEnabled  = true;


in vec2 texcoord;


#include "/Include/Core/Mask.glsl"


#define diagonal2(m) vec2((m)[0].x, (m)[1].y)
#define diagonal3(m) vec3(diagonal2(m), m[2].z)
#define  projMAD(mat, v) (diagonal3(mat) * (v) + (mat)[3].xyz)
#define max3(x, y, z)    max(x, max(y, z))
#define min4(x, y, z, w) min(x, min(y, min(z, w)))
#define max4(x, y, z, w) max(x, max(y, max(z, w)))


vec3 CalculateViewSpacePosition(vec3 screenPos) {
    screenPos = screenPos * 2.0 - 1.0;
    return projMAD(gbufferProjectionInverse, screenPos) / (screenPos.z * gbufferProjectionInverse[2].w + gbufferProjectionInverse[3].w);
}


vec3 SampleColor(vec2 coord) {
    return GammaToLinear(texture(colortex1, coord).rgb);
}

vec3 SamplePreviousColor(vec2 coord) {
    return GammaToLinear(texture(colortex7, coord).rgb);
}

float SampleDepth(vec2 coord, MaterialMask mask) {
    if (mask.water > 0.5){
        return texture(gdepthtex, coord).r;
    }else{
        return texture(depthtex1, coord).r;
    }
}

float SamplePreviousDepth(vec2 coord) {
    return texture(colortex7, coord).a;
}

float 	ExpToLinearDepth(in float depth)
{
	return 2.0f * near * far / (far + near - (2.0f * depth - 1.0f) * (far - near));
}



vec2 CalculateCameraVelocity(vec3 screenPos) {
    vec3 projection = mat3(gbufferModelViewInverse) * CalculateViewSpacePosition(screenPos) + gbufferModelViewInverse[3].xyz;
         projection = (screenPos.z < 1.0 ? (cameraPosition - previousCameraPosition) : vec3(0.0)) + projection;
         projection = mat3(gbufferPreviousModelView) * projection + gbufferPreviousModelView[3].xyz;
         projection = (diagonal3(gbufferPreviousProjection) * projection + gbufferPreviousProjection[3].xyz) / -projection.z * 0.5 + 0.5;

    return (screenPos.xy - projection.xy);
}

vec3 clipAABB(vec3 boxMin, vec3 boxMax, vec3 q) {
    vec3 p_clip = 0.5 * (boxMax + boxMin);
    vec3 e_clip = 0.5 * (boxMax - boxMin);

    vec3 v_clip = q - p_clip;
    vec3 v_unit = v_clip.xyz / e_clip;
    vec3 a_unit = abs(v_unit);
    float ma_unit = max3(a_unit.x, a_unit.y, a_unit.z);

    if (ma_unit > 1.0)
        return v_clip / ma_unit + p_clip;
    else
        return q;
}

vec3 CalculateMotionBlur(vec2 uv, vec2 velocity) {
    const int steps = 3;
    const float rSteps = 1.0 / steps;

	float dither = bayer16(gl_FragCoord.xy);

	vec2 vtap = velocity * (rSteps * 0.5);
	vec2 pos0 = uv + vtap * (0.5 * dither);
	vec3 accu = vec3(0.0);
	float wsum = 0.0;

	for (int i = -steps; i <= steps; i++) {
		float w = 1.0;
		accu += w * SampleColor(pos0 + float(i) * vtap);
		wsum += w;
	}

	return accu / wsum;
}



vec4 TemporalReprojection(vec2 coord, vec2 velocity, vec2 dd) {

    vec2 ccoord = coord + taaJitter * 0.5;

    vec3 currentSample = SampleColor(ccoord);
    vec3 col1 = SampleColor(ccoord + vec2(dd.x, 0.0));
    vec3 col2 = SampleColor(ccoord + vec2(-dd.x, 0.0));
    vec3 col3 = SampleColor(ccoord + vec2(dd.x, dd.y));
    vec3 col4 = SampleColor(ccoord + vec2(-dd.x, dd.y));
    vec3 col5 = SampleColor(ccoord + vec2(dd.x, -dd.y));
    vec3 col6 = SampleColor(ccoord + vec2(-dd.x, -dd.y));
    vec3 col7 = SampleColor(ccoord + vec2(0.0, dd.y));
    vec3 col8 = SampleColor(ccoord + vec2(0.0, -dd.y));

    vec3 colMin = min(currentSample, min(min4(col1, col2, col3, col4), min4(col5, col6, col7, col8)));
    vec3 colMax = max(currentSample, max(max4(col1, col2, col3, col4), max4(col5, col6, col7, col8)));
    vec3 colAVG = (currentSample + col1 + col2 + col3 + col4 + col5 + col6 + col7 + col8) * (1.0 / 9.0);

    float luminance = dot(currentSample, vec3(0.33333));

    velocity *= step(2e-8, luminance);

    coord -= velocity;
    vec3 previousSample = SamplePreviousColor(coord);


    #ifdef TAA_SHARPEN
        vec3 sharpen = vec3(1.0) - exp(-(currentSample - clamp(colAVG, colMin, colMax)));
        currentSample += sharpen * TAA_SHARPNESS;
        currentSample = saturate(currentSample);
    #endif

    //Clipping
    previousSample = clipAABB(colMin, colMax, previousSample);

    vec2 pixelVelocity = abs(fract(velocity * viewDimensions) - 0.5) * 2.0;



    float blendWeight = TAA_AGGRESSION;
        //Zombye's neat way to get rid of blurring and ghosting. Thanks <3
        //blendWeight *= mix(sqrt(pixelVelocity.x * pixelVelocity.y) * 0.25 + 0.75, 1.0, saturate((2e-7 - luminance) / 1e-7));
    blendWeight *= sqrt(pixelVelocity.x * pixelVelocity.y) * 0.25 + 0.75;


    blendWeight = saturate(coord) != coord ? 0.0 : blendWeight;

    return vec4(mix(currentSample, previousSample, blendWeight), 0.0);
    //return vec4(mix(mix(currentSample, previousSample, blendWeight), vec3(0.0005, 0.0, 0.0), debug), currentDepthMin);

}

vec4 CalculateTAA(vec2 coord, bool noAA, MaterialMask mask) {
    vec3 closest = vec3(coord, SampleDepth(coord, mask));

    vec2 velocity = CalculateCameraVelocity(closest);

    if(noAA) velocity = vec2(0.0);

    vec4 colorTemporal = TemporalReprojection(coord, velocity, pixelSize);

    return colorTemporal;

}

float GetExposureTiles()
{
	float avglod = int(log2(min(viewWidth, viewHeight)));
	float avg = dot(GammaToLinear(textureLod(colortex1, vec2(0.65, 0.65), avglod).rgb), vec3(0.33333));

	int lod = 6;

    float tileScale = exp2(float(lod));
	vec2 tileCount = floor(viewDimensions / tileScale);
	vec2 tileCenter = tileCount * 0.5;

    float exposure = 0.0;
    float weights = 0.0;

	for(int x = 0; x < tileCount.x; x++)
	{
	for(int y = 0; y < tileCount.y; y++)
	{
        float tileExposure = dot(GammaToLinear(texelFetch(colortex1, ivec2(x, y), lod).rgb), vec3(0.33333));

		vec2 tileDistance = (tileCenter - vec2(x + 0.5, y + 0.5)) * tileScale * pixelSize * 2.0;
        float centerDistance = length(tileDistance);

        #if AE_MODE == 0
            float tileWeight = saturate(1.0 - centerDistance);
            tileWeight *= tileWeight;
        #elif AE_MODE == 1
            float tileWeight = centerDistance < 0.5 ? 1.0 : 0.0;
        #elif AE_MODE == 2
            float tileWeight = 1.0;
        #endif

        #ifdef LUMINANCE_WEIGHT
        tileExposure = max(2e-8, tileExposure);
            #if LUMINANCE_WEIGHT_MODE == 0
                float lumaWeight = avg / tileExposure;
            #elif LUMINANCE_WEIGHT_MODE == 1
                float lumaWeight = tileExposure / avg;
            #endif
            lumaWeight = pow(lumaWeight, LUMINANCE_WEIGHT_STRENGTH);
            tileWeight *= lumaWeight;
        #endif

        exposure += tileExposure * tileWeight;
        weights += tileWeight;
    }
	}
    exposure /= weights;

    exposure /= compositeOutputFactor * 100.0;

    exposure = pow(exposure, 0.2);

	return exposure;
}



void main() {
    vec4 taa;
    MaterialMask materialMask	= CalculateMasks(texture(colortex5, texcoord.st).b);

    bool noAA = SampleDepth(texcoord, materialMask) < 0.7;
    #ifdef TAA
        taa = CalculateTAA(texcoord, noAA, materialMask);
        taa.rgb = LinearToGamma(taa.rgb);
    #else
        taa = texture(colortex1, texcoord);
    #endif

    float alphaPassthrough = texture(colortex7, texcoord).a;

    if (distance(gl_FragCoord.xy, vec2(0.0, 0.0)) < 1.0)
    {
        float avgExposure = GetExposureTiles();
        #ifdef SMOOTH_EXPOSURE
            float prevAvgExposure = alphaPassthrough;
            avgExposure = mix(prevAvgExposure, avgExposure, avgExposure > prevAvgExposure ? 0.015 / EXPOSURE_TIME : 0.07 / EXPOSURE_TIME);
        #endif
        alphaPassthrough = avgExposure;
    }
    if (distance(gl_FragCoord.xy, vec2(2.0, 0.0)) < 1.0)
    {
        float preAlpha = alphaPassthrough;
        float newAlpha = preAlpha + 0.004;
        alphaPassthrough = saturate(newAlpha);
    }
    if (gl_FragCoord.y < 1.0) taa.a = alphaPassthrough;

    compositeOutput1 = taa;
    compositeOutput7 = taa;
}
/* DRAWBUFFERS:17 */
