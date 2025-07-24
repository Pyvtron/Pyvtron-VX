#version 450 compatibility

//gbuffers_weather.fsh

uniform sampler2D texture;

in vec4 texcoord;


void main() {
	vec4 tex = texture2D(texture, texcoord.st);

	gl_FragData[0] = vec4(0.0, 0.0, 0.0, tex.a);
}

/* DRAWBUFFERS:0 */
