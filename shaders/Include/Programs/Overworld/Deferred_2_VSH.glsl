/*
====================================================================================================

    Copyright (C) 2025 Pyvtron VX Shaders - Pyvtron

    All Rights Reserved unless otherwise explicitly stated.

====================================================================================================
*/


#define CLOUD_SHADOWTEX_SIZE 256.0 // [128.0 192.0 256.0 384.0 512.0 768.0 1024.0]

uniform vec2 screenSize;
uniform vec2 pixelSize;


void main(){
	vec2 shadowTexSize = pixelSize * floor(min(screenSize.y * 0.45, CLOUD_SHADOWTEX_SIZE));
	vec2 texCoord = gl_Vertex.xy;
    texCoord = texCoord * shadowTexSize + (1.0 - shadowTexSize);
	gl_Position = vec4(texCoord * 2.0 - 1.0, 0.0, 1.0);
}