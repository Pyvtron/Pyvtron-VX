#include "/lib/settings.glsl"

uniform int heldItemId;
uniform int heldBlockLightValue;
uniform int heldItemId2;
uniform int heldBlockLightValue2;
uniform int fogMode;
uniform float fogDensity;
uniform vec3 fogColor;
uniform vec3 skyColor;
uniform int worldTime;
uniform int worldDay;
uniform int moonPhase;
uniform int frameCounter;
uniform float frameTime;
uniform float frameTimeCounter;
uniform float sunAngle;
uniform float shadowAngle;
uniform float rainStrength;
uniform float aspectRatio;
uniform float viewWidth;
uniform float viewHeight;
uniform float near;
uniform float far;
uniform vec3 sunPosition;
uniform vec3 moonPosition;
uniform vec3 shadowLightPosition;
uniform vec3 upPosition;
uniform vec3 cameraPosition;
uniform vec3 previousCameraPosition;
uniform mat4 gbufferModelView;
uniform mat4 gbufferModelViewInverse;
uniform mat4 gbufferPreviousModelView;
uniform mat4 gbufferProjection;
uniform mat4 gbufferProjectionInverse;
uniform mat4 gbufferPreviousProjection;
uniform mat4 shadowProjection;
uniform mat4 shadowProjectionInverse;
uniform mat4 shadowModelView;
uniform mat4 shadowModelViewInverse;
uniform float wetness;
uniform float eyeAltitude;
uniform ivec2 eyeBrightness;
uniform ivec2 eyeBrightnessSmooth;
uniform int isEyeInWater;
uniform float nightVision;
uniform float blindness;
uniform float screenBrightness;
uniform int hideGUI;
uniform float centerDepthSmooth;
uniform ivec2 atlasSize;
uniform vec4 spriteBounds;
uniform vec4 entityColor;
uniform int entityId;
uniform int blockEntityId;
uniform ivec4 blendFunc;
uniform int instanceId;
uniform float playerMood;
uniform int renderStage;

uniform vec2 taaJitter;
uniform vec2 viewDimensions;
uniform vec2 pixelSize;
uniform float compositeOutputFactor;


uniform sampler2D colortex0;
uniform sampler2D colortex1;
uniform sampler2D colortex2;
uniform sampler2D colortex3;
uniform sampler2D colortex4;
uniform sampler2D colortex5;
uniform sampler2D colortex6;
uniform sampler2D colortex7;
//uniform sampler2D colortex8;
uniform sampler2D gdepthtex;
uniform sampler2D depthtex0;
uniform sampler2D depthtex1;
uniform sampler2D depthtex2;
uniform sampler2D noisetex;

const int 		noiseTextureResolution  = 64;

const int 		shadowMapResolution 	= 2048;		// [1024 2048 4096 6144 8192 16384 32768]
const float 	shadowDistance 			= 192.0;	// [64.0 96.0 128.0 192.0 256.0 384.0 512.0 768.0 1024.0]
const float 	shadowIntervalSize 		= 4.0f;
const float     shadowDistanceRenderMul = 1.0f;		// [-1.0f 1.0f]
