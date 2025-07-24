/*
====================================================================================================

    Copyright (C) 2025 Pyvtron VX Shaders - Pyvtron

    All Rights Reserved unless otherwise explicitly stated.

====================================================================================================
*/


#include "/Include/Settings.glsl"

uniform vec2 taaJitter;

out vec4 color;
out vec4 texcoord;
out vec2 blockLight;
out float materialIDs;


void main(){
    gl_Position = ftransform();
 
   #include "/Include/SphericalWorld.glsl"

    #ifdef TAA
        vec4 jitterPos = gl_Position;
        jitterPos.xy = taaJitter * jitterPos.w + jitterPos.xy;
        gl_Position = jitterPos;
    #endif


    color = gl_Color;
    texcoord = gl_MultiTexCoord0;

    vec4 lmcoord = gl_TextureMatrix[1] * gl_MultiTexCoord1;
    blockLight.x = clamp((lmcoord.x * 33.05f / 32.0f) - 1.05f / 32.0f, 0.0f, 1.0f);
    blockLight.y = clamp((lmcoord.y * 33.05f / 32.0f) - 1.05f / 32.0f, 0.0f, 1.0f);

    materialIDs = 39;
    if(lmcoord.x > 0.965) materialIDs = 40;
}
