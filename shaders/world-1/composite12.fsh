#version 450


layout(location = 0) out vec4 compositeOutput2;


#include "/OldInclude/uniform.glsl"
#include "/OldInclude/core/Common.inc"


in vec4 texcoord;


vec3 BlurV(vec2 coord)
{
	vec3 color = vec3(0.0);

	vec2 texel = 1.0 / vec2(viewWidth, viewHeight);

	float weights[5] = float[5](0.27343750, 0.21875000, 0.10937500, 0.03125000, 0.00390625);
	float offsets[5] = float[5](0.00000000, 1.00000000, 2.00000000, 3.00000000, 4.00000000);

	color += GammaToLinear(texture(colortex2, coord).rgb) * weights[0];

	for (int i = 1; i < 5; i++)
	{
		color += GammaToLinear(texture(colortex2, texel * vec2(0.0, offsets[i] * 1.0) + coord).rgb) * weights[i];
		color += GammaToLinear(texture(colortex2, -texel * vec2(0.0, offsets[i] * 1.0) + coord).rgb) * weights[i];
	}

	return color;
}



/////////////////////////MAIN//////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
/////////////////////////MAIN//////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
void main() {
	vec3 bloomColor = vec3(0.0);
	bloomColor = BlurV(texcoord.st);
	bloomColor = LinearToGamma(bloomColor);

	compositeOutput2 = vec4(bloomColor, 0.0);
}

/* DRAWBUFFERS:2 */
