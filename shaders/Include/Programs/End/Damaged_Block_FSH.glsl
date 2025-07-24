/*
====================================================================================================

    Copyright (C) 2025 Pyvtron VX Shaders - Pyvtron

    All Rights Reserved unless otherwise explicitly stated.

====================================================================================================
*/


#include "/Include/Settings.glsl"

uniform sampler2D texture;
uniform sampler2D specular;

in vec4 color;
in vec4 texcoord;

void main(){
    vec4 albedo = texture2D(texture, texcoord.st);
    albedo *= color;

    #ifdef WHITE_DEBUG_WORLD
        albedo.rgb = vec3(1.0);
    #endif



    gl_FragData[0] = albedo;
}

/* DRAWBUFFERS:0 */
