/*
====================================================================================================

    Copyright (C) 2025 Pyvtron VX Shaders - Pyvtron

    All Rights Reserved unless otherwise explicitly stated.

====================================================================================================
*/


out vec4 color;
out vec4 texcoord;


void main() {
	gl_Position = ftransform();


	color = gl_Color;
	texcoord = gl_TextureMatrix[0] * gl_MultiTexCoord0;
}
