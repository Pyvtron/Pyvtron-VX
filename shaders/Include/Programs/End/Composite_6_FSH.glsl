/*
====================================================================================================

    Copyright (C) 2025 Pyvtron VX Shaders - Pyvtron

    All Rights Reserved unless otherwise explicitly stated.

====================================================================================================
*/


layout(location = 0) out vec4 compositeOutput1;


#include "/Include/Core/Core.glsl"
#include "/Include/Uniforms.glsl"


const bool	colortex1MipmapEnabled  = true;


in vec2 texcoord;


#include "/Include/Core/Mask.glsl"


const float TAU = radians(360.0);
const float PHI = sqrt(5.0) * 0.5 + 0.5;
const float goldenAngle = TAU / PHI / PHI;


float ScreenToViewSpaceDepth(float depth) {
    depth = depth * 2.0 - 1.0;
    return -1.0 / (depth * gbufferProjectionInverse[2][3] + gbufferProjectionInverse[3][3]);
}


vec2 CalculateDistOffset(const vec2 prep, const float angle, const vec2 offset) {
    return offset * angle + prep * dot(prep, offset) * (1.0 - angle);
}


vec3 DepthOfField() { //OPTIMISATION: Add circular option for lower end hardware. TODO: Look over for accuracy and speed.

    MaterialMask materialMask = CalculateMasks(texture(colortex5, texcoord.st).b);

    if (materialMask.hand > 0.5) return GammaToLinear(textureLod(colortex1, texcoord, 0).rgb);

    vec3 dof = vec3(0.0);
    vec3 weight = vec3(0.0);

    const float filmDiagonal    = 0.04327;
    const float filmWidth       = 0.036;
    const float focalLength     = 0.5 * filmDiagonal * gbufferProjection[1][1];
    const float aperture        = CAMERA_APERTURE;
    const float apertureRadius  = 0.5 * focalLength / aperture;

    float depth = -ScreenToViewSpaceDepth(texture(depthtex0, texcoord).x);
    float centerDepth = -ScreenToViewSpaceDepth(centerDepthSmooth);
    #if CAMERA_FOCUS_MODE == 0
        float focus = centerDepth + CAMERA_AUTO_FOCAL_OFFSET;
    #else
        float focus = CAMERA_FOCAL_POINT;
    #endif

    float pcoc = focalLength * focalLength * (depth - focus) / (depth * (focus - focalLength) * aperture * filmDiagonal);


    float r = 1.0;
    const mat2 rot = mat2(
        cos(goldenAngle), -sin(goldenAngle),
        sin(goldenAngle),  cos(goldenAngle)
    );

    vec2 sampleAngle = vec2(0.0, 1.0);

    const float sizeCorrect   = 1.0 / (sqrt(DOF_SAMPLES) * 1.35914091423);
    const float apertureScale = sizeCorrect * apertureRadius / filmDiagonal;

    float lod = log2(abs(pcoc) * max(viewDimensions.x, viewDimensions.y) * apertureScale * aspectRatio) + 1.0;
    //lod = 0.0;

    vec2 distOffsetScale = apertureScale * vec2(1.0, aspectRatio);

    vec2 toCenter = texcoord.xy - 0.5;
    vec2 prep = normalize(vec2(toCenter.y, -toCenter.x));
    float lToCenter = length(toCenter);
    float angle = cos(lToCenter * DISTORTION_BARREL);

    for(int i = 0; i < DOF_SAMPLES; ++i) {
        r += 1.0 / r;
        sampleAngle = rot * sampleAngle;

        vec2 rSample = (r - 1.0) * sampleAngle;

        vec2 pos = CalculateDistOffset(prep, 1.0, rSample) * sizeCorrect;
        //vec3 bokeh = texture2D(colortex2, pos * -0.25 + vec2(0.5, 0.5) ).rgb;
        //if(i == 0)bokeh = vec3(1.0);
        vec3 bokeh = vec3(1.0);

        vec2 maxPos = CalculateDistOffset(prep, angle, rSample * pcoc) * distOffsetScale;

        dof += GammaToLinear(textureLod(colortex1, texcoord + maxPos, lod).rgb) * bokeh;
        weight += bokeh;
    }

    return dof / weight;
}

void main() {
    #ifdef DOF
    #endif
    vec3 color = LinearToGamma(DepthOfField());


    compositeOutput1 = vec4(color, 1.0);
}
/* DRAWBUFFERS:1 */
