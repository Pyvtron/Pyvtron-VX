#version 450 compatibility

//gbuffers_block.vsh

#include "/OldInclude/settings.glsl"

uniform int entityId;
uniform vec2 taaJitter;

out vec4 color;
out vec4 texcoord;
out vec3 worldNormal;
out vec4 viewPos;
out vec2 blockLight;
out float materialIDs;


void main() {
	viewPos = gl_ModelViewMatrix * gl_Vertex;
	gl_Position = gl_ProjectionMatrix * viewPos;
	#include "/OldInclude/SphericalWorld.glsl"
	#ifdef TAA
		vec4 jitterPos = gl_Position;
		jitterPos.xy = taaJitter * jitterPos.w + jitterPos.xy;
		gl_Position = jitterPos;
	#endif


	color = gl_Color;
    texcoord = gl_MultiTexCoord0;
	worldNormal = gl_Normal;

    vec4 lmcoord = gl_TextureMatrix[1] * gl_MultiTexCoord1;
    blockLight.x = clamp((lmcoord.x * 33.05f / 32.0f) - 1.05f / 32.0f, 0.0f, 1.0f);
    blockLight.y = clamp((lmcoord.y * 33.05f / 32.0f) - 1.05f / 32.0f, 0.0f, 1.0f);

    materialIDs = 1;
}
