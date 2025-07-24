#version 450 compatibility

//gbuffers_skytextured.vsh

out vec4 color;
out vec4 texcoord;


void main() {
	gl_Position = ftransform();


	color = gl_Color;
	texcoord = gl_TextureMatrix[0] * gl_MultiTexCoord0;
}
