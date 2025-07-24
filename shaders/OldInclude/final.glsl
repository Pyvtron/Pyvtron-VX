

in vec4 texcoord;

const float overlap = 0.2;

const float rgOverlap = 0.1 * overlap;
const float rbOverlap = 0.01 * overlap;
const float gbOverlap = 0.04 * overlap;

const mat3 coneOverlap = mat3(1.0, 			rgOverlap, 	rbOverlap,
							  rgOverlap, 	1.0, 		gbOverlap,
							  rbOverlap, 	rgOverlap, 	1.0);

const mat3 coneOverlapInverse = mat3(	1.0 + (rgOverlap + rbOverlap), 			-rgOverlap, 	-rbOverlap,
									  	-rgOverlap, 		1.0 + (rgOverlap + gbOverlap), 		-gbOverlap,
									  	-rbOverlap, 		-rgOverlap, 	1.0 + (rbOverlap + rgOverlap));

vec3 SEUSTonemap(vec3 color)
{
	color = color * coneOverlap;



	const float p = TONEMAP_CURVE;
	color = pow(color, vec3(p));
	color = color / (1.0 + color);
	color = pow(color, vec3(1.0 / p));


	color = color * coneOverlapInverse;
	color = saturate(color);

	return color;
}



/////////////////////////////////////////////////////////////////////////////////
// Tonemapping by John Hable
vec3 HableTonemap(vec3 color)
{

	color = color * coneOverlap;

	color *= 1.25;

	const float A = 0.15;
	const float B = 0.50;
	const float C = 0.10;
	const float D = 0.20;
	const float E = 0.00;
	const float F = 0.30;

	color = pow(color, vec3(TONEMAP_CURVE));

   	vec3 result = pow((color*(A*color+C*B)+D*E)/(color*(A*color+B)+D*F), vec3(1.0 / TONEMAP_CURVE))-E/F;
   	result = saturate(result);


   	result = result * coneOverlapInverse;

   	return result;
}
/////////////////////////////////////////////////////////////////////////////////

// Uchimura 2017, "HDR theory and practice"
// Math: https://www.desmos.com/calculator/gslcdxvipg
// Source: https://www.slideshare.net/nikuque/hdr-theory-and-practicce-jp
// Modified by Satellite.
vec3 UchimuraTonemap(vec3 color) {
    const float P = 1.0;  // max display brightness Default:1.2
    const float a = 0.85;  // contrast Default:0.625
    const float m = 0.175; // linear section start Default:0.1
    const float l = 0.15;  // linear section length Default:0.0
    const float c = 1.425; // black Default:1.33
    const float b = 0.0;  // pedestal
/*
    const float P = 1.0;  // max display brightness Default:1.2
    const float a = 0.85;  // contrast Default:0.625
    const float m = 0.175; // linear section start Default:0.1
    const float l = 0.15;  // linear section length Default:0.0
    const float c = 1.425; // black Default:1.33
    const float b = 0.0;  // pedestal
*/


    float l0 = ((P - m) * l) / a;
    float L0 = m - m / a;
    float L1 = m + (1.0 - m) / a;
    float S0 = m + l0;
    float S1 = m + a * l0;
    float C2 = (a * P) / (P - S1);
    float CP = -C2 / P;

    vec3 w0 = 1.0 - smoothstep(0.0, m, color);
    vec3 w2 = step(m + l0, color);
    vec3 w1 = 1.0 - w0 - w2;

	vec3 T = m * pow(color / vec3(m), vec3(c)) + vec3(b);
    vec3 S = P - (P - S1) * exp(CP * (color - S0));
    vec3 L = m + a * (color - m);

	color = color * coneOverlap;

	color = pow(color, vec3(1.0 / TONEMAP_CURVE));
    color = T * w0 + L * w1 + S * w2;
	color = pow(color, vec3(TONEMAP_CURVE));

	color = color * coneOverlapInverse;
    color = saturate(color);

	return color;
}

/////////////////////////////////////////////////////////////////////////////////
//	ACES Fitting by Stephen Hill
vec3 RRTAndODTFit(vec3 v)
{
    vec3 a = v * (v + 0.0245786f) - 0.000090537f;
    vec3 b = v * (1.0f * v + 0.4329510f) + 0.238081f;
    return a / b;
}

vec3 ACESTonemap2(vec3 color)
{
	color *= 1.4;
	color = color * coneOverlap;
	color = pow(color, vec3(TONEMAP_CURVE));


    // Apply RRT and ODT
    color = RRTAndODTFit(color);


	//color = pow(color, vec3(1.0 / TONEMAP_CURVE));
    // Clamp to [0, 1]
	color = color * coneOverlapInverse;
    //color = saturate(color);

    return color;
}
/////////////////////////////////////////////////////////////////////////////////

vec3 LottesTonemap(vec3 color)
{
	color *= 5.0;  // Default: 5.0



	// float peak = max(max(color.r, color.g), color.b);
	float peak = Luminance(color);
	vec3 ratio = color / peak;


	//Tonemap here
	const float contrast = 1.0; // Default: 1.1
	const float shoulder = 1.0;
	const float b = 1.0;	//Clipping point
	const float c = 3.0;	//Speed of compression. Default: 5.0

	peak = pow(peak, 1.6);

	float x = peak;
	float z = pow(x, contrast);
	peak = z / (pow(z, shoulder) * b + c);

	peak = pow(peak, 1.0 / 1.6);

	vec3 tonemapped = peak * ratio;


	//Crosstalk
	// float tonemappedMaximum = max(max(tonemapped.r, tonemapped.g), tonemapped.b);
	float tonemappedMaximum = Luminance(tonemapped);
	vec3 crosstalk = vec3(5.0, 0.5, 5.0) * 2.0;
	// vec3 crosstalk = vec3(5.0, 5.0, 5.0);
	float saturation = 0.75;  // Default: 1.1
	float crossSaturation = 1280.0;  // Default: 1114.0

	ratio = pow(ratio, vec3(saturation / crossSaturation));
	ratio = mix(ratio, vec3(1.0), pow(vec3(tonemappedMaximum), crosstalk));
	ratio = pow(ratio, vec3(crossSaturation));



	vec3 outputColor = peak * ratio;

	// outputColor = smoothstep(vec3(0.0), vec3(1.0), outputColor);
	// outputColor = pow(outputColor, vec3(0.7));

	return outputColor;
}

vec3 ACESTonemap(vec3 color){
	const float a = 2.51f;  // Default: 2.51f
	const float b = 0.03f;  // Default: 0.03f
	const float c = 2.43f;  // Default: 2.43f
	const float d = 0.59f;  // Default: 0.59f
	const float e = 0.14f;  // Default: 0.14f
	float p = TONEMAP_CURVE / 2.0;

	color = color * coneOverlap;

	color = pow(color, vec3(p));

	color = (color * (a * color + b)) / (color * (c * color + d) + e);

	color = pow(color, vec3(1.0 / p));

	color = color * coneOverlapInverse;

	color = saturate(color);



	return color;
}

vec3 None(vec3 color){
	return color;
}


float AverageExposure(){
	return texture2DLod(colortex7, vec2(0.0, 0.0), 0).a;
}




vec3 Lookup(vec3 color, sampler2D lookupTable) {
    float blueColor = color.b * 63.0;

    vec4 quad = vec4(0.0);
    quad.y = floor(floor(blueColor) * 0.125);
    quad.x = floor(blueColor) - (quad.y * 8.0);
	quad.w = floor(ceil(blueColor) * 0.125);
    quad.z = ceil(blueColor) - (quad.w * 8.0);

    vec4 texPos = ((quad * 0.125) + (0.123046875 * color.rg).xyxy + 0.0009765625);

    vec3 newColor1 = texture2D(lookupTable, texPos.xy).rgb;
    vec3 newColor2 = texture2D(lookupTable, texPos.zw).rgb;

    return mix(newColor1, newColor2, fract(blueColor));
}
