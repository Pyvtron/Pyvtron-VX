#version 450

layout(location = 0) out vec4 compositeOutput1;

#include "/OldInclude/uniform.glsl"
#include "/OldInclude/core/Common.inc"

in vec4 texcoord;

#include "/OldInclude/core/Mask.inc"


vec3  	GetNormals(in vec2 coord, MaterialMask mask) {				//Function that retrieves the screen space surface normals. Used for lighting calculations
	vec3 normal = DecodeNormal(texture(colortex3, coord.st).xy);
	if(mask.particle > 0.5 || mask.particlelit > 0.5)
	normal = vec3(0.0, 0.0, 1.0);
	return normal;
}

float 	GetDepth(in vec2 coord, MaterialMask mask) {
	float depth = texture(depthtex1, coord.st).x;
	if(mask.particle > 0.5 || mask.particlelit > 0.5)
	depth = texture(gdepthtex, coord.st).x;
	return depth;
}

vec4  	GetScreenSpacePosition(in vec2 coord, MaterialMask mask) {	//Function that calculates the screen-space position of the objects in the scene using the depth texture and the texture coordinates of the full-screen quad
	float depth = GetDepth(coord, mask);
	vec4 fragposition = gbufferProjectionInverse * vec4(fma(coord.st, vec2(2.0f), vec2(-1.0f)), fma(depth, 2.0f, -1.0f), 1.0f);
		 fragposition /= fragposition.w;

	return fragposition;
}

vec4  	GetScreenSpacePosition(in vec2 coord, in float depth) {	//Function that calculates the screen-space position of the objects in the scene using the depth texture and the texture coordinates of the full-screen quad
	vec4 fragposition = gbufferProjectionInverse * vec4(fma(coord.st, vec2(2.0f), vec2(-1.0f)), fma(depth, 2.0f, -1.0f), 1.0f);
		 fragposition /= fragposition.w;

	return fragposition;
}


vec3 	CalculateNoisePattern1(vec2 offset, float size) {
	vec2 coord = texcoord.st;

	coord *= vec2(viewWidth, viewHeight);
	coord = mod(coord + offset, vec2(size));
	coord /= noiseTextureResolution;

	return texture(noisetex, coord).xyz;
}


vec3 ProjectBack(vec3 cameraSpace)
{
    vec4 clipSpace = gbufferProjection * vec4(cameraSpace, 1.0);
    vec3 NDCSpace = clipSpace.xyz / clipSpace.w;
    vec3 screenSpace = fma(NDCSpace, vec3(0.5f), vec3(0.5f));
    return screenSpace;
}

float 	ExpToLinearDepth(in float depth)
{
	return 2.0f * near * far / fma((near - far), fma(depth, 2.0f, -1.0f), (far + near));
}

float GetAO(vec2 coord, vec3 normal, float dither, MaterialMask mask)
{
	const int numRays = 16;

	const float phi = 1.618033988;
	const float gAngle = phi * 3.14159265 * 1.0003;

	float depth = GetDepth(coord, mask);
	float linDepth = ExpToLinearDepth(depth);
	vec3 origin = GetScreenSpacePosition(coord, depth).xyz;

	float aoAccum = 0.0;

	float radius = 0.30 * -origin.z;
		  radius = mix(radius, 0.8, 0.5);
	float zThickness = 0.30 * -origin.z;
		  zThickness = mix(zThickness, 1.0, 0.5);

	float aoMul = 1.0;

	for (int i = 0; i < numRays; i++)
	{
		float fi = float(i) + dither;
		float fiN = fi / float(numRays);
		float lon = gAngle * fi * 6.0;
		float lat = asin(fma(fiN, 2.0f, -1.0f)) * 1.0;

		vec3 kernel;
		kernel.x = cos(lat) * cos(lon);
		kernel.z = cos(lat) * sin(lon);
		kernel.y = sin(lat);

		kernel.xyz = normalize(kernel.xyz + normal.xyz);

		float sampleLength = radius * mod(fiN, 0.02) / 0.02;

		vec3 samplePos = fma(vec3(sampleLength), kernel, origin);

		vec3 samplePosProj = ProjectBack(samplePos);

		vec3 actualSamplePos = GetScreenSpacePosition(samplePosProj.xy, GetDepth(samplePosProj.xy, mask)).xyz;

		vec3 sampleVector = normalize(samplePos - origin);

		float depthDiff = actualSamplePos.z - samplePos.z;

		if (depthDiff > 0.0 && depthDiff < zThickness)
		{
			float aow = 1.35 * saturate(dot(sampleVector, normal));
			aoAccum += aow;
		}
	}

	aoAccum /= numRays;

	float ao = 1.0 - aoAccum;
	ao = pow(ao, 1.7);

	return ao;
}





/////////////////////////MAIN//////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
/////////////////////////MAIN//////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
void main() {
	MaterialMask mask = CalculateMasks(texture(colortex6, texcoord.st).b);

	vec3 noisePattern = CalculateNoisePattern1(vec2(0.0f), 4);

	vec4 light = vec4(0.0, 0.0, 0.0, 1.0);

	#ifdef ENABLE_SSAO
		light.a = GetAO(texcoord.st, GetNormals(texcoord.st, mask), noisePattern.x, mask);
	#endif

	compositeOutput1 = vec4(vec3(1.0), light.a);
}

/* DRAWBUFFERS:1 */
