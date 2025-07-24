#version 450 compatibility

//gbuffers_weather.vsh

#include "/OldInclude/settings.glsl"

uniform vec2 taaJitter;

out vec4 texcoord;


void main(){
    gl_Position = ftransform();
    #include "/OldInclude/SphericalWorld.glsl"
    #ifdef TAA
        vec4 jitterPos = gl_Position;
        jitterPos.xy = taaJitter * jitterPos.w + jitterPos.xy;
        gl_Position = jitterPos;
    #endif

    texcoord = gl_MultiTexCoord0;
}
