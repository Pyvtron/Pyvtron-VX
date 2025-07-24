#version 450 compatibility

//gbuffers_terrain.vsh

#include "/OldInclude/settings.glsl"

uniform sampler2D noisetex;

uniform mat4 gbufferModelView;
uniform mat4 gbufferModelViewInverse;
uniform mat4 gbufferProjectionInverse;
uniform vec3 cameraPosition;
uniform float frameTimeCounter;
uniform int frameCounter;
uniform float wetness;

uniform vec2 taaJitter;

#if MC_VERSION >= 11500
layout(location = 11) in vec4 mc_Entity;
#else
layout(location = 10) in vec4 mc_Entity;
#endif

out vec4 color;
out vec4 texcoord;
out vec3 worldPosition;
out vec4 vertexPos;
out vec4 viewPos;
out vec3 normal;
out vec3 worldNormal;
out float distance;

out vec2 blockLight;
out float materialIDs;
out float noWetItem;
out vec2 mtc;
out vec3 amb;


vec4 cubic(float x)
{
    float x2 = x * x;
    float x3 = x2 * x;
    vec4 w;
    w.x =   -x3 + 3*x2 - 3*x + 1;
    w.y =  3*x3 - 6*x2       + 4;
    w.z = -3*x3 + 3*x2 + 3*x + 1;
    w.w =  x3;
    return w / 6.f;
}

vec4 BicubicTexture(in sampler2D tex, in vec2 coord)
{
	int resolution = 64;

	coord *= resolution;

	float fx = fract(coord.x);
    float fy = fract(coord.y);
    coord.x -= fx;
    coord.y -= fy;

    vec4 xcubic = cubic(fx);
    vec4 ycubic = cubic(fy);

    vec4 c = vec4(coord.x - 0.5, coord.x + 1.5, coord.y - 0.5, coord.y + 1.5);
    vec4 s = vec4(xcubic.x + xcubic.y, xcubic.z + xcubic.w, ycubic.x + ycubic.y, ycubic.z + ycubic.w);
    vec4 offset = c + vec4(xcubic.y, xcubic.w, ycubic.y, ycubic.w) / s;

    vec4 sample0 = texture2D(tex, vec2(offset.x, offset.z) / resolution);
    vec4 sample1 = texture2D(tex, vec2(offset.y, offset.z) / resolution);
    vec4 sample2 = texture2D(tex, vec2(offset.x, offset.w) / resolution);
    vec4 sample3 = texture2D(tex, vec2(offset.y, offset.w) / resolution);

    float sx = s.x / (s.x + s.y);
    float sy = s.z / (s.z + s.w);

    return mix( mix(sample3, sample2, sx), mix(sample1, sample0, sx), sy);
}



void main(){
    color = gl_Color;
    texcoord = gl_MultiTexCoord0;
    worldNormal = gl_Normal;
    normal = normalize(gl_NormalMatrix * gl_Normal);

    vec4 lmcoord = gl_TextureMatrix[1] * gl_MultiTexCoord1;
    blockLight.x = clamp((lmcoord.x * 33.05f / 32.0f) - 1.05f / 32.0f, 0.0f, 1.0f);
    blockLight.y = clamp((lmcoord.y * 33.05f / 32.0f) - 1.05f / 32.0f, 0.0f, 1.0f);

    vec4 position = gbufferModelViewInverse * gl_ModelViewMatrix * gl_Vertex;

    worldPosition = position.xyz;


    ////////////////////////////////Gather materials////////////////////////////////
    ////////////////////////////////Gather materials////////////////////////////////


    	materialIDs = 1.0f;
    	noWetItem = 0.0f;

    	float facingEast = abs(normalize(gl_Normal.xz).x);
    	float facingUp = abs(gl_Normal.y);

    //2		Grass
    	if (mc_Entity.x == 31 ||
            mc_Entity.x == 141 ||
            mc_Entity.x == 59 ||
            mc_Entity.x == 37 ||
            mc_Entity.x == 175 ||
            mc_Entity.x == 6 ||
			mc_Entity.x == 7001 ||
			mc_Entity.x == 7004 ||
			mc_Entity.x == 7006
            )
    	{
    		materialIDs = max(materialIDs, 2.0f);
    		noWetItem = 0.25f;
    	}


    	#ifdef GENERAL_GRASS_FIX
    	if (
    		abs(worldNormal.x) > 0.01 && abs(worldNormal.x) < 0.99 ||
    		abs(worldNormal.y) > 0.01 && abs(worldNormal.y) < 0.99 ||
    		abs(worldNormal.z) > 0.01 && abs(worldNormal.z) < 0.99
    		)
    	{
    		materialIDs = max(materialIDs, 2.0f);
    	}
    	#endif


    //3		Leaves
    	if (mc_Entity.x == 18 || mc_Entity.x == 7002)
    	{
    		materialIDs = max(materialIDs, 3.0f);
    		noWetItem = 0.125f;
    	}




    //25	torch
    	if (mc_Entity.x == 50 || mc_Entity.x == 7010) {
    		materialIDs = max(materialIDs, 25.0f);
    	}

    //26	lava
    	if (mc_Entity.x == 10) {
    		materialIDs = max(materialIDs, 26.0f);
    		noWetItem = 1.0f;
    	}

    //27	glowstone and lamp
    	if (mc_Entity.x == 89 || mc_Entity.x == 7011) {
    		materialIDs = max(materialIDs, 27.0f);
    	}

    //28	fire
    	if (mc_Entity.x == 51) {
    		materialIDs = max(materialIDs, 28.0f);
    		noWetItem = 1.0f;
    	}

    //29	redstone_torch
    	if (mc_Entity.x == 76 || mc_Entity.x == 7012) {
    		materialIDs = max(materialIDs, 29.0f);
    	}

    //30	redstone
    	if (mc_Entity.x == 55) {
    		materialIDs = max(materialIDs, 30.0f);
    	}

    //31	soul_fire
    	if (mc_Entity.x == 7100) {
    		materialIDs = max(materialIDs, 31.0f);
    	}

    //32	amethyst
        if (mc_Entity.x == 7101) {
            materialIDs = max(materialIDs, 32.0f);
        }



    ////////////////////////////////Gather materials////////////////////////////////
    ////////////////////////////////Gather materials////////////////////////////////

    #ifdef PLANT_TOUCH_EFFECT


    	if (mc_Entity.x == 31 || mc_Entity.x == 141 || mc_Entity.x == 59)
    	{
    		if (length((position.xyz + vec3(0.0,2.0,0.0))) < 2.0) position.xz *= 1+max(5.0/pow(max(length((position.xyz + vec3(0.0,2.0,0.0))*vec3(8.0,2.0,8.0)-vec3(0.0,2.0,0.0)),2.0),1.0)-0.625,0.0);
    	}
    	if (mc_Entity.x == 175)
    	{
    		if (length(position.xyz) < 2.0) position.xz *= 1+max(5.0/pow(max(length(position.xyz*vec3(8.0,2.0,8.0)),2.0),1.0)-0.625,0.0);
    	}

    #endif

    position.xyz += cameraPosition.xyz;

    ////////////////////////////////Waving Plants////////////////////////////////
    ////////////////////////////////Waving Plants////////////////////////////////

    #ifdef WAVING_PLANTS

    float tick = frameTimeCounter * ANIMATION_SPEED;

    float grassWeight = mod(texcoord.t * 16.0f, 1.0f / 16.0f);

    float lightWeight = clamp((lmcoord.t * 33.05f / 32.0f) - 1.05f / 32.0f, 0.0f, 1.0f);
    	  lightWeight *= 1.1f;
    	  lightWeight -= 0.1f;
    	  lightWeight = max(0.0f, lightWeight);
    	  lightWeight = pow(lightWeight, 5.0f);

    	  if (grassWeight < 0.01f) {
    	  	grassWeight = 1.0f;
    	  } else {
    	  	grassWeight = 0.0f;
    	  }

    const float pi = 3.14159265f;


    //grass//
    	if (mc_Entity.x == 31 || mc_Entity.x == 59 || mc_Entity.x == 37)
    	{
    		vec2 angleLight = vec2(0.0f);
    		vec2 angleHeavy = vec2(0.0f);
    		vec2 angle 		= vec2(0.0f);

    		vec3 pn0 = position.xyz;
    			 pn0.x -= frameTimeCounter * ANIMATION_SPEED / 3.0f;

    		vec3 stoch = BicubicTexture(noisetex, pn0.xz / 64.0f).xyz;
    		vec3 stochLarge = BicubicTexture(noisetex, position.xz / (64.0f * 6.0f)).xyz;

    		vec3 pn = position.xyz;
    			 pn.x *= 2.0f;
    			 pn.x -= frameTimeCounter * ANIMATION_SPEED * 15.0f;
    			 pn.z *= 8.0f;

    		vec3 stochLargeMoving = BicubicTexture(noisetex, pn.xz / (64.0f * 10.0f)).xyz;



    		vec3 p = position.xyz;
    		 	 p.x += sin(p.z / 2.0f) * 1.0f;
    		 	 p.xz += stochLarge.rg * 5.0f;

    		float windStrength = mix(0.85f, 1.0f, wetness);
    		float windStrengthRandom = stochLargeMoving.x;
    			  windStrengthRandom = pow(windStrengthRandom, mix(2.0f, 1.0f, wetness));
    			  windStrength *= mix(windStrengthRandom, 0.5f, wetness * 0.25f);
    			  //windStrength = 1.0f;

    		//heavy wind
    		float heavyAxialFrequency 			= 8.0f;
    		float heavyAxialWaveLocalization 	= 0.9f;
    		float heavyAxialRandomization 		= 13.0f;
    		float heavyAxialAmplitude 			= 15.0f;
    		float heavyAxialOffset 				= 15.0f;

    		float heavyLateralFrequency 		= 6.732f;
    		float heavyLateralWaveLocalization 	= 1.274f;
    		float heavyLateralRandomization 	= 1.0f;
    		float heavyLateralAmplitude 		= 6.0f;
    		float heavyLateralOffset 			= 0.0f;

    		//light wind
    		float lightAxialFrequency 			= 5.5f;
    		float lightAxialWaveLocalization 	= 1.1f;
    		float lightAxialRandomization 		= 21.0f;
    		float lightAxialAmplitude 			= 5.0f;
    		float lightAxialOffset 				= 5.0f;

    		float lightLateralFrequency 		= 5.9732f;
    		float lightLateralWaveLocalization 	= 1.174f;
    		float lightLateralRandomization 	= 0.0f;
    		float lightLateralAmplitude 		= 1.0f;
    		float lightLateralOffset 			= 0.0f;

    		float windStrengthCrossfade = clamp(windStrength * 2.0f - 1.0f, 0.0f, 1.0f);
    		float lightWindFade = clamp(windStrength * 2.0f, 0.2f, 1.0f);

    		angleLight.x += sin(frameTimeCounter * ANIMATION_SPEED * lightAxialFrequency 		- p.x * lightAxialWaveLocalization		+ stoch.x * lightAxialRandomization) 	* lightAxialAmplitude 		+ lightAxialOffset;
    		angleLight.y += sin(frameTimeCounter * ANIMATION_SPEED * lightLateralFrequency 	- p.x * lightLateralWaveLocalization 	+ stoch.x * lightLateralRandomization) 	* lightLateralAmplitude  	+ lightLateralOffset;

    		angleHeavy.x += sin(frameTimeCounter * ANIMATION_SPEED * heavyAxialFrequency 		- p.x * heavyAxialWaveLocalization		+ stoch.x * heavyAxialRandomization) 	* heavyAxialAmplitude 		+ heavyAxialOffset;
    		angleHeavy.y += sin(frameTimeCounter * ANIMATION_SPEED * heavyLateralFrequency 	- p.x * heavyLateralWaveLocalization 	+ stoch.x * heavyLateralRandomization) 	* heavyLateralAmplitude  	+ heavyLateralOffset;

    		angle = mix(angleLight * lightWindFade, angleHeavy, vec2(windStrengthCrossfade));
    		angle *= 2.0f;

    		// //Rotate block pivoting from bottom based on angle
    		position.x += (sin((angle.x / 180.0f) * 3.141579f)) * grassWeight * lightWeight						* 0.5f	;
    		position.z += (sin((angle.y / 180.0f) * 3.141579f)) * grassWeight * lightWeight						* 0.5f	;
    		position.y += (cos(((angle.x + angle.y) / 180.0f) * 3.141579f) - 1.0f)  * grassWeight * lightWeight	* 0.5f	;
    	}



    //Wheat//
    ///*
    	if (mc_Entity.x == 59)
        {
            {
        		float speed = 0.1;

        		float magnitude = sin((tick * pi / (28.0)) + position.x + position.z) * 0.12 + 0.02;
        			  magnitude *= grassWeight * 0.2f;
        			  magnitude *= lightWeight;
        		float d0 = sin(tick * pi / (122.0 * speed)) * 3.0 - 1.5 + position.z;
        		float d1 = sin(tick * pi / (152.0 * speed)) * 3.0 - 1.5 + position.x;
        		float d2 = sin(tick * pi / (122.0 * speed)) * 3.0 - 1.5 + position.x;
        		float d3 = sin(tick * pi / (152.0 * speed)) * 3.0 - 1.5 + position.z;
        		position.x += sin((tick * pi / (28.0 * speed)) + (position.x + d0) * 0.1 + (position.z + d1) * 0.1) * magnitude;
        		position.z += sin((tick * pi / (28.0 * speed)) + (position.z + d2) * 0.1 + (position.x + d3) * 0.1) * magnitude;
        	}
    //*/
    	//small leaf movement
            {
        		float speed = 0.04;

        		float magnitude = (sin(((position.y + position.x)/2.0 + tick * pi / ((28.0)))) * 0.025 + 0.075) * 0.2;
        			  magnitude *= grassWeight;
        			  magnitude *= lightWeight;
        		float d0 = sin(tick * pi / (112.0 * speed)) * 3.0 - 1.5;
        		float d1 = sin(tick * pi / (142.0 * speed)) * 3.0 - 1.5;
        		float d2 = sin(tick * pi / (112.0 * speed)) * 3.0 - 1.5;
        		float d3 = sin(tick * pi / (142.0 * speed)) * 3.0 - 1.5;
        		position.x += sin((tick * pi / (18.0 * speed)) + (-position.x + d0)*1.6 + (position.z + d1)*1.6) * magnitude * (1.0f + wetness * 2.0f);
        		position.z += sin((tick * pi / (18.0 * speed)) + (position.z + d2)*1.6 + (-position.x + d3)*1.6) * magnitude * (1.0f + wetness * 2.0f);
        		position.y += sin((tick * pi / (11.0 * speed)) + (position.z + d2) + (position.x + d3)) * (magnitude/3.0) * (1.0f + wetness * 2.0f);
            }
        }


    //Leaves//
    		if (mc_Entity.x == 18)
            {
        		float speed = 0.05;


        			  //lightWeight = max(0.0f, 1.0f - (lightWeight * 5.0f));

        		float magnitude = (sin((position.y + position.x + tick * pi / ((28.0) * speed))) * 0.15 + 0.15) * 0.30 * lightWeight * 0.2;
        			  // magnitude *= grassWeight;
        			  magnitude *= lightWeight;
        		float d0 = sin(tick * pi / (112.0 * speed)) * 3.0 - 1.5;
        		float d1 = sin(tick * pi / (142.0 * speed)) * 3.0 - 1.5;
        		float d2 = sin(tick * pi / (132.0 * speed)) * 3.0 - 1.5;
        		float d3 = sin(tick * pi / (122.0 * speed)) * 3.0 - 1.5;
        		position.x += sin((tick * pi / (18.0 * speed)) + (-position.x + d0)*1.6 + (position.z + d1)*1.6) * magnitude * (1.0f + wetness * 1.0f);
        		position.z += sin((tick * pi / (17.0 * speed)) + (position.z + d2)*1.6 + (-position.x + d3)*1.6) * magnitude * (1.0f + wetness * 1.0f);
        		position.y += sin((tick * pi / (11.0 * speed)) + (position.z + d2) + (position.x + d3)) * (magnitude/2.0) * (1.0f + wetness * 1.0f);

            }
    #endif

    ////////////////////////////////Waving Plants////////////////////////////////
    ////////////////////////////////Waving Plants////////////////////////////////


    viewPos = gl_ModelViewMatrix * gl_Vertex;

    distance = sqrt(viewPos.x * viewPos.x + viewPos.y * viewPos.y + viewPos.z * viewPos.z);

    position.xyz -= cameraPosition.xyz;
    gl_Position = gl_ProjectionMatrix * gbufferModelView * position;

    #include "/OldInclude/SphericalWorld.glsl"

    #ifdef TAA
        vec4 jitterPos = gl_Position;
        jitterPos.xy = taaJitter * jitterPos.w + jitterPos.xy;
        gl_Position = jitterPos;
    #endif


    vertexPos = gl_Vertex;
}
