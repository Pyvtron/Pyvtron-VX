#version 450 compatibility

//gbuffers_basic.vsh

#include "/OldInclude/settings.glsl"

uniform vec2 taaJitter;

out vec4 color;
out vec4 texcoord;
out vec3 normal;
out vec2 blockLight;

void main(){
    gl_Position = ftransform();
    #include "/OldInclude/SphericalWorld.glsl"
    #ifdef TAA
        vec4 jitterPos = gl_Position;
        jitterPos.xy = taaJitter * jitterPos.w + jitterPos.xy;
        gl_Position = jitterPos;
    #endif

    color = gl_Color;
    texcoord = gl_MultiTexCoord0;
    normal = gl_NormalMatrix * gl_Normal;

    vec4 lmcoord = gl_TextureMatrix[1] * gl_MultiTexCoord1;
    blockLight.x = clamp((lmcoord.x * 33.05f / 32.0f) - 1.05f / 32.0f, 0.0f, 1.0f);
    blockLight.y = clamp((lmcoord.y * 33.05f / 32.0f) - 1.05f / 32.0f, 0.0f, 1.0f);
}
