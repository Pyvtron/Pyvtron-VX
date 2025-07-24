/*
====================================================================================================

    Copyright (C) 2025 Pyvtron VX Shaders - Pyvtron

    All Rights Reserved unless otherwise explicitly stated.

====================================================================================================
*/


in vec3 mc_EntityPos;  
in vec2 mc_TexCoord;   
in vec4 mc_Color;   

uniform mat4 dh_projectionMatrix; 
uniform mat4 dh_modelViewMatrix;  
uniform vec3 dh_cameraPosition;   

out vec4 color;
out vec2 texcoord;
out vec2 dh_texcoord;
out float dh_distance;

void main() {
    vec4 worldPos = vec4(mc_EntityPos, 1.0);
    gl_Position = dh_projectionMatrix * dh_modelViewMatrix * worldPos;

    texcoord = mc_TexCoord;
    dh_texcoord = mc_TexCoord;
    color = mc_Color;

    vec3 delta = mc_EntityPos - dh_cameraPosition;
    dh_distance = length(delta);
}
