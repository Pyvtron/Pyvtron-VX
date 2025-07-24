/*
====================================================================================================

    Copyright (C) 2025 Pyvtron VX Shaders - Pyvtron

    All Rights Reserved unless otherwise explicitly stated.

====================================================================================================
*/


#include "/Include/Settings.glsl"

uniform sampler2D colortex11;
uniform sampler2D colortex0;
uniform sampler2D colortex3;

uniform float viewWidth;
uniform float viewHeight;

in vec2 texcoord;

/* DRAWBUFFERS:0 */
layout(location = 0) out vec3 colortex0Out;

vec4 texelFetchShort(sampler2D tex, vec2 uv) {
    return textureLod(tex, uv, 0.0);
}

// pow2(x) = x*x
float pow2(float x) {
    return x * x;
}

float luminance(vec3 color) {
    return dot(color, vec3(0.2126, 0.7152, 0.0722));
}

vec3 lensFlareSampling(sampler2D smpTex, vec2 coords)
{
    const int sampleRad = LENS_FLARE_BLUR_SAMPLES;
    vec3 sampleOutput = vec3(0.0);

    for(int x = -sampleRad; x < sampleRad; x++) {
        for(int y = -sampleRad; y < sampleRad; y++) {
            vec2 offset = vec2(x, y) / vec2(viewWidth, viewHeight);
            sampleOutput += textureLod(smpTex, coords + offset, 4.0).rgb;
        }
    }

    sampleOutput *= 1.0 / pow2(float(sampleRad * 2)); 

    return sampleOutput;
}

vec3 lensFlareCalc()
{
    vec2 flippedCoord = vec2(1.0) - texcoord;
    vec3 ret = vec3(0.0);

    vec2 ghostPreCoord = (vec2(0.5) - flippedCoord) * GHOST_FLARE_SPACING_MULT;
    vec2 haloPreCoord = normalize((vec2(0.5) - flippedCoord)) * HALO_FLARE_SPACING_MULT;

    vec3 lensTexPre = texture2D(colortex11, texcoord).rgb;

    for (int i = 0; i < LENS_FLARE_SAMPLES; i++) 
    {
        vec2 sampleCoord = flippedCoord + ghostPreCoord * float(i);
        if (i % 2 == 0) {
            sampleCoord = flippedCoord + haloPreCoord * float(i);
        }

        ivec2 scaledLensCoord = ivec2(sampleCoord * vec2(viewWidth, viewHeight));
        vec3 lensColor = lensFlareSampling(colortex0, sampleCoord);

        int lensBlockID     = int(texelFetch(colortex3, scaledLensCoord, 0).b * 65535);
        int lensBlockIDoff1 = int(texelFetch(colortex3, scaledLensCoord + ivec2(1,0), 0).b * 65535);
        int lensBlockIDoff2 = int(texelFetch(colortex3, scaledLensCoord + ivec2(2,0), 0).b * 65535);
        int lensBlockIDoff3 = int(texelFetch(colortex3, scaledLensCoord - ivec2(1,0), 0).b * 65535);
        int lensBlockIDoff4 = int(texelFetch(colortex3, scaledLensCoord - ivec2(2,0), 0).b * 65535);

        float lensMask = 0.0;
        lensMask += float(lensBlockID == 1190);
        lensMask += float(lensBlockIDoff1 == 1190);
        lensMask += float(lensBlockIDoff2 == 1190);
        lensMask += float(lensBlockIDoff3 == 1190);
        lensMask += float(lensBlockIDoff4 == 1190);

        lensColor *= lensMask * max(luminance(lensColor) - LENS_FLARE_THRESHOLD, 0.0) * 5.0;

        if (i % 2 == 0) {
            lensColor *= pow(1.0 - (length(vec2(0.5) - fract(sampleCoord)) / 0.70710678118), 5.0);
        }

        vec3 lensTexGhost = lensTexPre * texture2D(colortex11, sampleCoord).rgb;
        ret += lensColor * lensTexGhost * LENS_FLARE_STRENGTH;
    }

    return ret;
}

void main() {
    vec3 color = texelFetchShort(colortex0, texcoord).rgb;

    #ifdef LENS_FLARE
    color += lensFlareCalc();
    #endif

    colortex0Out = color;
}
