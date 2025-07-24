
/*
====================================================================================================

    Copyright (C) 2025 Pyvtron VX Shaders - Pyvtron

    All Rights Reserved unless otherwise explicitly stated.

====================================================================================================
*/


//#define INTEL_SUPPORT

const float PI = radians(180.0);

const float R = 1.0;
const float R_INNER = 0.985;
const float SCALE_H = 4.0 / (R - R_INNER);
const float SCALE_L = 1.0 / (R - R_INNER);
const float rayleighAmount = 0.675;


float saturate(float x)
{
	return clamp(x, 0.0, 1.0);
}

vec3 saturate(vec3 x)
{
	return clamp(x, vec3(0.0), vec3(1.0));
}

vec2 saturate(vec2 x)
{
	return clamp(x, vec2(0.0), vec2(1.0));
}

vec2 EncodeNormal(vec3 normal)
{
	float p = sqrt(fma(normal.z, 8.0, 8.0));
	return vec2(fma(normal.xy, vec2(1 / p), vec2(0.5)));
}

vec3 DecodeNormal(vec2 enc)
{
	vec2 fenc = fma(enc, vec2(4.0), vec2(-2.0));
	float f = dot(fenc, fenc);
	float g = sqrt(fma(f, -0.25f, 1.0f));
	vec3 normal;
	normal.xy = fenc * g;
	normal.z = fma(f, -0.5f, 1.0f);
	return normal;
}

vec3 ViewSpaceToScreenSpace(vec3 viewPosition, mat4 projection)
{
	vec3 screenPosition = vec3(projection[0].x, projection[1].y, projection[2].z) * viewPosition + projection[3].xyz;

	return screenPosition * (0.5 / -viewPosition.z) + 0.5;
}

vec3 ScreenSpaceToViewSpace(vec3 screenPosition, mat4 projectionInverse)
{
	screenPosition = screenPosition * 2.0 - 1.0;

	vec3 viewPosition  = vec3(vec2(projectionInverse[0].x, projectionInverse[1].y) * screenPosition.xy + projectionInverse[3].xy, projectionInverse[3].z);
	     viewPosition /= projectionInverse[2].w * screenPosition.z + projectionInverse[3].w;

	return viewPosition;
}

float PackTwo8BitTo16Bit(vec2 v)
{
	float data;

	v.x = clamp(v.x, 0.0, 255.0 / 256.0);
	v.y = clamp(v.y, 0.0, 255.0 / 256.0);

	v.x *= 255.0;
	v.y *= 255.0;

	v.x = floor(v.x);
	v.y = floor(v.y);

	data = v.x * exp2(8.0);
	data += v.y;



	data /= exp2(16.0) - 1;

	return data;
}

vec2 UnpackTwo8BitFrom16Bit(float value)
{
	vec2 data;

	value *= exp2(16.0) - 1;

	data.x = floor(value / exp2(8.0));
	data.y = mod(value, exp2(8.0));

	data.x /= 255.0;
	data.y /= 255.0;

	return data;
}

float PackTwo16BitTo32Bit(vec2 v) {
    return dot(floor(v*8191.9999),vec2(1./8192.,1.));
}

vec2 UnpackTwo16BitFrom32Bit(float v) {
    return vec2(fract(v)*(8192./8191.),floor(v)/8191.);
}



vec3 LinearToGamma(vec3 c)
{
	return pow(c, vec3(1.0 / 2.2));
}

vec3 GammaToLinear(vec3 c)
{
	return pow(c, vec3(2.2));
}

float curve(float x)
{
	return x * x * fma(x, -2.0f, 3.0f);
}

float remap(float e0, float e1, float x)
{
	return saturate((x - e0) / (e1 - e0));
}

float Luminance(in vec3 color)
{
	return dot(color.rgb, vec3(0.2125f, 0.7154f, 0.0721f));
}

const mat3 tmp_r709 = mat3(
	0.64 / 0.33, 0.3 / 0.6, 0.15 / 0.06,
	1.0,         1.0,       1.0,
	0.03 / 0.33, 0.1 / 0.6, 0.79 / 0.06
);
const vec3 lc_r709 = vec3(0.3127 / 0.329, 1.0, 0.3583 / 0.329) * inverse(tmp_r709);

const mat3 R709ToXyz = mat3(lc_r709 * tmp_r709[0], lc_r709, lc_r709 * tmp_r709[2]);
const mat3 XyzToR709 = inverse(R709ToXyz);

vec3 Blackbody(float temperature) { // Returns XYZ blackbody radiation
	// https://en.wikipedia.org/wiki/Planckian_locus
	const vec4[2] xc = vec4[2](
		vec4(-0.2661293e9,-0.2343589e6, 0.8776956e3, 0.179910), // 1667k <= t <= 4000k
		vec4(-3.0258469e9, 2.1070479e6, 0.2226347e3, 0.240390)  // 4000k <= t <= 25000k
	);
	const vec4[3] yc = vec4[3](
		vec4(-1.1063814,-1.34811020, 2.18555832,-0.20219683), // 1667k <= t <= 2222k
		vec4(-0.9549476,-1.37418593, 2.09137015,-0.16748867), // 2222k <= t <= 4000k
		vec4( 3.0817580,-5.87338670, 3.75112997,-0.37001483)  // 4000k <= t <= 25000k
	);

	float temperatureSquared = temperature * temperature;
	vec4 t = vec4(temperatureSquared * temperature, temperatureSquared, temperature, 1.0);

	float x = dot(1.0 / t, temperature < 4000.0 ? xc[0] : xc[1]);
	float xSquared = x * x;
	vec4 xVals = vec4(xSquared * x, xSquared, x, 1.0);

	vec3 xyz = vec3(0.0);
	xyz.y = 1.0;
	xyz.z = 1.0 / dot(xVals, temperature < 2222.0 ? yc[0] : temperature < 4000.0 ? yc[1] : yc[2]);
	xyz.x = x * xyz.z;
	xyz.z = xyz.z - xyz.x - 1.0;

	return xyz * XyzToR709;
}

void DoNightEye(inout vec3 color)
{
	float luminance = Luminance(color);

	color = mix(color, luminance * vec3(0.2, 0.4, 0.9), vec3(0.8));
}

vec3 rand(vec2 coord)
{
	float noiseX = saturate(fract(sin(dot(coord, vec2(12.9898, 78.223))) * 43758.5453));
	float noiseY = saturate(fract(sin(dot(coord, vec2(12.9898, 78.223)*2.0)) * 43758.5453));
	float noiseZ = saturate(fract(sin(dot(coord, vec2(12.9898, 78.223)*3.0)) * 43758.5453));

	return vec3(noiseX, noiseY, noiseZ);
}


vec4 ToSH(float value, vec3 dir)
{
	const float N1 = sqrt(4 * PI / 3);
	const float transferl1 = (sqrt(PI) / 3.0) * N1;
	const float transferl0 = PI;

	const float sqrt1OverPI = sqrt(1.0 / PI);
	const float sqrt3OverPI = sqrt(3.0 / PI);

	vec4 coeffs;

	coeffs.x = 0.5 * sqrt1OverPI * value * transferl0;
	coeffs.y = -0.5 * sqrt3OverPI * dir.y * value * transferl1;
	coeffs.z = 0.5 * sqrt3OverPI * dir.z * value * transferl1;
	coeffs.w = -0.5 * sqrt3OverPI * dir.x * value * transferl1; //TODO: Vectorize the math so it's faster

	return coeffs;
}


vec3 FromSH(vec4 cR, vec4 cG, vec4 cB, vec3 lightDir)
{
	const float N1 = sqrt(4 * PI / 3);
	const float transferl1 = (sqrt(PI) / 3.0) * N1;
	const float transferl0 = PI;

	const float sqrt1OverPI = sqrt(1.0 / PI);
	const float sqrt3OverPI = sqrt(3.0 / PI);

	vec4 sh;

	sh.x = 0.5 * sqrt1OverPI;
	sh.y = -0.5 * sqrt3OverPI * lightDir.y;
	sh.z = 0.5 * sqrt3OverPI * lightDir.z;
	sh.w = -0.5 * sqrt3OverPI * lightDir.x;

	vec3 result;
	result.r = sh.x * cR.x;
	result.r += sh.y * cR.y;
	result.r += sh.z * cR.z;
	result.r += sh.w * cR.w;

	result.g = sh.x * cG.x;
	result.g += sh.y * cG.y;
	result.g += sh.z * cG.z;
	result.g += sh.w * cG.w;

	result.b = sh.x * cB.x;
	result.b += sh.y * cB.y;
	result.b += sh.z * cB.z;
	result.b += sh.w * cB.w;

	return result.rgb;
}

//x is distance to outer surface, y is distance to inner surface
vec2 RaySphereIntersection( vec3 p, vec3 dir, float r )
{
	float b = dot( p, dir );
	float c = fma(r, -r, dot( p, p ));

	float d = fma(b, b, -c);
	if ( d < 0.0 )
	{
		return vec2( 10000.0, -10000.0 );
	}

	d = sqrt( d );

	return vec2( -b - d, -b + d );
}

// Mie
// g : ( -0.75, -0.999 )
//      3 * ( 1 - g^2 )               1 + c^2
// F = ----------------- * -------------------------------
//      2 * ( 2 + g^2 )     ( 1 + g^2 - 2 * g * c )^(3/2)
float phase_mie( float g, float c, float cc ) {
	float gg = g * g;

	float a = ( 1.0 - gg ) * ( 1.0 + cc );

	float b = fma((g * c), -2.0f, (1.0 + gg));
	b *= sqrt( b );
	b *= 2.0 + gg;

	return 1.5 * a / b;
}

// Reyleigh
// g : 0
// F = 3/4 * ( 1 + c^2 )
float phase_reyleigh( float cc )
{
	return 0.75 * ( 1.0 + cc );
}

float density( vec3 p )
{
	return exp( -( length( p ) - R_INNER ) * SCALE_H ) * 2.0;
}

float optic( vec3 p, vec3 q )
{
	const int numOutscatter = 1;

	vec3 step = ( q - p ) / float(numOutscatter);
	step *= 0.3;
	vec3 v = fma(step, vec3(0.5f), p);

	float sum = 0.0;
	for ( int i = 0; i < numOutscatter; i++ )
	{
		sum += density( v );
		v += step;
	}
	sum *= length( step ) * SCALE_L;


	return sum;
}

vec3 in_scatter(vec3 o, vec3 rayDir, vec2 originToSkyIntersection, vec3 lightVector, const float mieAmount)
{
	const float numInscatter = 3;
	const float K_R = 0.186 * rayleighAmount;
	const float K_M_NUM = 0.020;


	const float K_M = K_M_NUM * mieAmount;
	const float E = 25;
	const vec3 C_R = vec3(0.2, 0.45, 1.0);	//Rayleigh scattering coefficients
	const float G_M = -0.75;

	//float boosty = Boosty(lightVector.y);

	//float rayStepSize = (originToSkyIntersection.y * (1.0 + boosty * 0.0)) / float(numInscatter);
	float rayStepSize = originToSkyIntersection.y / float(numInscatter);
	vec3 step = rayDir * rayStepSize;
	step *= 2.0;
	vec3 p = o;

	//vec3 skyRayPos = p + rayDir * (rayStepSize * (0.55 + boosty * 0.0));
	vec3 skyRayPos = fma((rayDir * vec3(rayStepSize)), vec3(0.5), p);



	vec3 sum = vec3( 0.0 );
	for ( int i = 0; i < numInscatter; i++ )
	{
		vec2 atmosphereIntersection = RaySphereIntersection(skyRayPos, lightVector, R);
		vec3 outerAtmospherePos = fma(lightVector, vec3(atmosphereIntersection.y), skyRayPos);

		float n = (optic(p, skyRayPos) + optic(skyRayPos, outerAtmospherePos)) * (PI * 4.0);

		sum += density(skyRayPos) * exp(-n * (fma(vec3(K_R), C_R, vec3(K_M))));

		skyRayPos += step;
	}
	sum *= rayStepSize * SCALE_L;

	float c  = dot(rayDir, -lightVector);
	float cc = c * c;

	return sum * (K_R * C_R * phase_reyleigh(cc) + K_M * phase_mie(G_M, c, cc)) * E;
}

vec3 in_scatter2(vec3 rayOrigin, vec3 rayDir, vec2 originToSkyIntersection, vec3 lightVector)
{
	const float numInscatter = 2;

	const float K_R = 0.186;
	const float K_M = 0.00;
	const float E = 25;
	const vec3 C_R = vec3(0.2, 0.3, 1.0);	//Rayleigh scattering coefficients
	const float G_M = -0.75;

	float len = (originToSkyIntersection.y) / float(numInscatter);
	vec3 step = rayDir * len;
	step *= 2.0;
	vec3 p = rayOrigin;

	//float boosty = Boosty(lightVector.y);

	//vec3 skyRayPos = p + rayDir * (len * (0.5 + boosty * 0.0));
	vec3 skyRayPos = fma((rayDir * vec3(len)), vec3(0.5), p);



	vec3 sum = vec3( 0.0 );
	for ( int i = 0; i < numInscatter; i++ )
	{
		vec2 atmosphereIntersection = RaySphereIntersection(skyRayPos, lightVector, R);
		vec3 outerAtmospherePos = fma(lightVector, vec3(atmosphereIntersection.y), skyRayPos);

		float n = (optic(p, skyRayPos) + optic(skyRayPos, outerAtmospherePos)) * (PI * 4.0);

		sum += density(skyRayPos) * exp(-n * (fma(vec3(K_R), C_R, vec3(K_M))));

		skyRayPos += step;
	}
	sum *= len * SCALE_L;

	float c  = dot(rayDir, -lightVector);
	float cc = c * c;

	return sum * (K_R * C_R * phase_reyleigh(cc) + K_M * phase_mie(G_M, c, cc)) * E;
}


vec3 Scattering(vec3 eye, vec3 rayDir, vec2 e, vec3 lightVector, const float mieAmount, vec3 up, vec2 eup, bool horizon)
{

	vec3 atmosphere = in_scatter(eye, rayDir, e, lightVector, mieAmount);

	vec3 secondary = in_scatter2(eye, up, eup, lightVector);

	vec3 ambient = vec3(0.08, 0.2, 1.0);

	if (rayDir.y <= 0.0 && horizon)
	{
		float boosty = saturate(lightVector.y * 3.0) * 0.70 + 0.30;
		ambient *= boosty;
	}
	atmosphere += dot(secondary, vec3(0.625)) * ambient;
	//atmosphere = pow(atmosphere, vec3(1.3));

	return atmosphere;
}




vec3 AtmosphericScatteringHorizon(vec3 rayDir, vec3 lightVector, const float mieAmount, float wet)
{
	//Scatter constants
	vec3 eye = vec3(0.0, mix(R_INNER, 1.0, 0.05), 0.0);

	//if (rayDir.y < 0.0)
	//{
	//	rayDir.y = mix(rayDir.y, 0.0, saturate(wet * 20.0));
	//}

	vec3 up = vec3(0.0, 1.0, 0.0);

	vec2 e = RaySphereIntersection(eye, rayDir, R);
	vec2 eup = RaySphereIntersection(eye, up, R);

	if (rayDir.y < 0.0)
	{
		float ry = -0.0016 / clamp(rayDir.y - 0.03, -1.0, 0.0);
		e.y = ry;
	}

	vec3 atmosphere = in_scatter(eye, rayDir, e, lightVector, mieAmount);
	vec3 secondary = in_scatter2(eye, up, eup, lightVector);

	vec3 ambient = vec3(0.08, 0.2, 1.0);
	if (rayDir.y <= 0.0)
	{
		float boosty = saturate(lightVector.y * 3.0) * 0.70 + 0.30;
		ambient *= mix(boosty, 1.0, wet);
	}
	atmosphere += dot(secondary, vec3(0.625)) * ambient;

	return atmosphere;
}

vec3 AtmosphericScattering(vec3 rayDir, vec3 lightVector, const float mieAmount, float depth)
{
	//Scatter constants
	vec3 eye = vec3(0.0, mix(R_INNER, 1.0, 0.05), 0.0);

	if (rayDir.y < 0.0)
	{
		rayDir.y = 0.0;
	}


	vec3 up = vec3(0.0, 1.0, 0.0);

	vec2 e = RaySphereIntersection(eye, rayDir, R);
	vec2 eup = RaySphereIntersection(eye, up, R);

	e.y = depth;
	eup.y = depth;


	vec3 atmosphere = in_scatter(eye, rayDir, e, lightVector, mieAmount);
	vec3 secondary = in_scatter2(eye, up, eup, lightVector);

	vec3 ambient = vec3(0.08, 0.2, 1.0);
	atmosphere += dot(secondary, vec3(0.625)) * ambient;

	return atmosphere;
}


vec3 AtmosphericScatteringSingle(vec3 rayDir, vec3 lightVector, const float mieAmount)
{
	//Scatter constants
	vec3 eye = vec3(0.0, mix(R_INNER, 1.0, 0.05), 0.0);

	if (rayDir.y < 0.0)
	{
		rayDir.y = 0.0;
	}


	vec3 up = vec3(0.0, 1.0, 0.0);

	vec2 e = RaySphereIntersection(eye, rayDir, R);
	vec2 eup = RaySphereIntersection(eye, up, R);


	vec3 atmosphere = in_scatter(eye, rayDir, e, lightVector, mieAmount);
	vec3 secondary = in_scatter2(eye, up, eup, lightVector);

	vec3 ambient = vec3(0.15, 0.3, 1.0);
	atmosphere += dot(secondary, vec3(0.625));

	return atmosphere;
}










float RenderSunDisc(vec3 worldDir, vec3 sunDir)
{
	float d = dot(worldDir, sunDir);

	float disc = 0.0;

	float size = 0.0003;
	float hardness = 10000.0;

	disc = pow(curve(saturate((d - (1.0 - size)) * hardness)), 2.0);

	float visibility = curve(saturate(worldDir.y * 30.0));

	disc *= visibility;

	return disc;
}

float RenderMoonDisc(vec3 worldDir, vec3 sunDir)
{
	float d = dot(worldDir, -sunDir);

	float disc = 0.0;

	float size = 0.0003;
	float hardness = 10000.0;

	disc = pow(curve(saturate((d - (1.0 - size)) * hardness)), 2.0);

	float visibility = curve(saturate(worldDir.y * 10.0));

	disc *= visibility;

	return disc;
}

float RenderMoonDiscReflection(vec3 worldDir, vec3 sunDir)
{
	float d = dot(worldDir, -sunDir);

	float disc = 0.0;

	float size = 0.0025;
	float hardness = 300.0;

	disc = pow(curve(saturate((d - (1.0 - size)) * hardness)), 2.0);

	float visibility = curve(saturate(worldDir.y * 10.0));

	disc *= visibility;

	return disc;
}


float bayer2(vec2 a) {
	a = floor(a);

	return fract(dot(a, vec2(0.5, a.y * 0.75)));
}

float bayer4(const vec2 a)   { return bayer2 (0.5   * a) * 0.25     + bayer2(a); }
float bayer8(const vec2 a)   { return bayer4 (0.5   * a) * 0.25     + bayer2(a); }
float bayer16(const vec2 a)  { return bayer4 (0.25  * a) * 0.0625   + bayer4(a); }
float bayer32(const vec2 a)  { return bayer8 (0.25  * a) * 0.0625   + bayer4(a); }
float bayer64(const vec2 a)  { return bayer8 (0.125 * a) * 0.015625 + bayer8(a); }
float bayer128(const vec2 a) { return bayer16(0.125 * a) * 0.015625 + bayer8(a); }
