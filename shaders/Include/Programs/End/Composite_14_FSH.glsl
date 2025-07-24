/*
====================================================================================================

    Copyright (C) 2025 Pyvtron VX Shaders - Pyvtron

    All Rights Reserved unless otherwise explicitly stated.

====================================================================================================
*/


#include "/Include/Settings.glsl"

uniform sampler2D colortex0;
uniform float viewWidth;
uniform float viewHeight;

in vec2 texcoord;
layout(location = 0) out vec3 colortex0Out;

vec4 texelFetchShort(sampler2D tex, vec2 uv) {
    return textureLod(tex, uv, 0.0); 
}

float blueNoiseSample(vec2 coords, float scale, vec2 offset) {
    return fract(sin(dot(coords + offset, vec2(12.9898, 78.233))) * 43758.5453); 
}

float fractDither(float value) {
    return fract(value * 10000.0); 
}

vec2 toPrevScreenPos(vec2 currentPos, float factor) {
    return currentPos - factor * 0.05; 
}

vec3 MBlurFunction(in vec3 scolor, in float blueDither) {
    vec3 blurredCol = vec3(0.0);

	#ifdef TAA
	blueDither = fractDither(blueDither);
	#endif

    vec2 pixel = 1.0 / vec2(viewWidth, viewHeight);

    vec2 previousPos = toPrevScreenPos(texcoord, 1.0);
    vec2 velocity = abs(texcoord - previousPos);

	velocity *= 1.0 / (1.5 + length(velocity)) * MOTION_BLUR_STRENGTH * 0.02;

    int samples = 5;
		
	vec2 tcoord = texcoord - velocity * blueDither;

	for (int i = 0; i < samples; ++i) {
        tcoord += velocity;
		blurredCol += textureLod(colortex0, clamp(tcoord, pixel, 1.0 - pixel), 0).rgb;
	}

	blurredCol *= 1.0 / float(samples);

	return blurredCol;
}

void main() {
    float blueDither = blueNoiseSample(texcoord, 1.0, vec2(0.0));

	vec3 color = texelFetchShort(colortex0, texcoord).rgb;

	#ifdef MOTION_BLUR
	color = MBlurFunction(color, blueDither);
	#endif

	colortex0Out = color;
}
