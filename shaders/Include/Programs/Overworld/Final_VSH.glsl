/*
====================================================================================================

    Copyright (C) 2025 Pyvtron VX Shaders - Pyvtron

    All Rights Reserved unless otherwise explicitly stated.

====================================================================================================
*/


out vec4 texcoord;

void main() {
	gl_Position = ftransform();
	texcoord = gl_MultiTexCoord0;
}
