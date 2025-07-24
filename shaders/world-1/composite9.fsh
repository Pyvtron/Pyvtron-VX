#version 450 compatibility

layout(location = 0) out vec4 compositeOutput1;


#include "/OldInclude/uniform.glsl"

#include "/OldInclude/core/Common.inc"

//#include "/OldInclude/core/Mask.inc"





in vec4 texcoord;




vec3 GetColorTexture(vec2 coord)
{
	return GammaToLinear(textureLod(colortex7, coord, 0).rgb);
}

vec3 MotionBlur() {
	float depth = texture(depthtex1, texcoord.st).x;

	vec4 currentPosition = vec4(texcoord.x * 2.0f - 1.0f, texcoord.y * 2.0f - 1.0f, 2.0f * depth - 1.0f, 1.0f);

	vec4 fragposition = gbufferProjectionInverse * currentPosition;
	fragposition = gbufferModelViewInverse * fragposition;
	fragposition /= fragposition.w;
	fragposition.xyz += cameraPosition;

	vec4 previousPosition = fragposition;
	previousPosition.xyz -= previousCameraPosition;
	previousPosition = gbufferPreviousModelView * previousPosition;
	previousPosition = gbufferPreviousProjection * previousPosition;
	previousPosition /= previousPosition.w;

	vec2 velocity = (currentPosition - previousPosition).st * 0.25 * (MOTION_BLUR_SUTTER_ANGLE / 360.0);
	float maxVelocity = 0.1f;
		 velocity = clamp(velocity, vec2(-maxVelocity), vec2(maxVelocity));

	if (depth < 0.7)
	{
		velocity *= 0.0;
	}

	//float isHand = GetMaterialMask(4, floor(texture(colortex5, texcoord.st).b * 255.0));
	//velocity *= 1.0f - isHand;

	int steps = MOTION_BLUR_QUALITY;

	int samples = 0;

	vec3 color = vec3(0.0f);

	float dither = 0.0;
	#ifdef MOTION_BLUR_DITHER
		dither = bayer16(gl_FragCoord.xy);
	#endif


	for (int i = -steps; i <= steps; ++i) {
		vec2 coord = texcoord.st + velocity * (float(i + dither) / (steps + 1.0));
			 //coord += vec2(dither) * 1.0f * velocity;

		if (coord.x > 0.0f && coord.x < 1.0f && coord.y > 0.0f && coord.y < 1.0f) {

			color += GetColorTexture(coord).rgb;
			samples += 1;

		}
	}

	color.rgb /= samples;

	return LinearToGamma(color);
}

/////////////////////////MAIN//////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
/////////////////////////MAIN//////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
void main() {

	vec3 color = texture(colortex1, texcoord.st).rgb;

	#ifdef MOTION_BLUR
		color = MotionBlur();
	#endif

	compositeOutput1 = vec4(color, 1.0);
}

/* DRAWBUFFERS:1 */
