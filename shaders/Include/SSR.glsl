
/*
====================================================================================================

    Copyright (C) 2025 Pyvtron VX Shaders - Pyvtron

    All Rights Reserved unless otherwise explicitly stated.

====================================================================================================
*/


#define RAYTRACE_QUALITY 128 // [8 16 32 64 128 256 512]

#define RAYTRACE_REFINEMENT 
#define RAYTRACE_REFINEMENT_STEPS 6 // [2 3 4 5 6 7 8 9 10 12 14 16 18 20 22 24 26 28 30 32]


uint triple32(uint x) {
    x ^= x >> 17;
    x *= 0xed5ad4bbu;
    x ^= x >> 11;
    x *= 0xac4c1b51u;
    x ^= x >> 15;
    x *= 0x31848babu;
    x ^= x >> 14;
    return x;
}

uint randState = triple32(uint(gl_FragCoord.x + viewDimensions.x * gl_FragCoord.y) + uint(viewDimensions.x * viewDimensions.y) * frameCounter);
uint RandNext() { return randState = triple32(randState); }
#define RandNext2() uvec2(RandNext(), RandNext())
#define RandNext3() uvec3(RandNext2(), RandNext())
#define RandNext4() uvec4(RandNext3(), RandNext())
#define RandNextF() (float(RandNext()) / float(0xffffffffu))
#define RandNext2F() (vec2(RandNext2()) / float(0xffffffffu))
#define RandNext3F() (vec3(RandNext3()) / float(0xffffffffu))
#define RandNext4F() (vec4(RandNext4()) / float(0xffffffffu))

const float zThicknessThreshold = 0.2;


bool rayTrace(vec3 rayOrigin, vec3 rayDir, float NoV, float jitter, bool isHand, inout vec3 rayPosition) {
    const int steps = RAYTRACE_QUALITY + 3;
    const float maxLength = 1.0 / RAYTRACE_QUALITY;
    const float minLength = maxLength * 0.01;

    float maxDist = far * sqrt(3.);

	float rayLength = ((rayOrigin.z + rayDir.z * maxDist) > -near) ?
      	 			  (-near - rayOrigin.z) / rayDir.z : maxDist;

	vec3 direction = normalize(ViewSpaceToScreenSpace(rayDir * rayLength + rayOrigin, gbufferProjection) - rayPosition);
    float stepWeight = 1.0 / abs(direction.z);

	float stepLength = mix(minLength, maxLength, NoV);
    vec3 increment = direction * vec3(max(pixelSize, stepLength), stepLength);

	rayPosition = rayPosition + increment * (jitter * 0.5 + 0.5);

	float depth = texture(depthtex1, rayPosition.xy).x;

    bool intersect = false;
    bool isRayExit = false;

    bool needRefinement = true;

	for(int i = 0; i <= steps; i++){
		if (clamp(rayPosition.xy, vec2(0.0), vec2(1.0)) != rayPosition.xy) return false;

        if (depth < rayPosition.z) {
            #ifdef RAYTRACE_REFINEMENT
                if (needRefinement) {
                    if (rayPosition.z >= 1.0) {
                        isRayExit = true;
                        break;
                    }

                    vec3 newDir = direction * stepLength;

                    for (int j = 0; j < RAYTRACE_REFINEMENT_STEPS; j++) {
                        newDir *= 0.5;

                        if (rayPosition.z > depth) {
                            rayPosition -= newDir;
                        } else {
                            rayPosition += newDir;
                        }

                        if(isHand) {
                            depth = texture(depthtex2, rayPosition.xy).x;
                        }else{
                            depth = texture(depthtex1, rayPosition.xy).x;
                        }

                    }

                    needRefinement = false;

                    if (rayPosition.z < depth) {
                        continue;
                    }
                }
            #endif

            float linearZ = ScreenToViewSpaceDepth(rayPosition.z);
            float linearD = ScreenToViewSpaceDepth(depth);

            float dist = abs(linearD - linearZ) / linearZ;

            // Check if the current ray has an intersection with the scene
            if (dist < zThicknessThreshold && linearZ > 0.0 && linearZ < far) {
                intersect = true;
                break;
            }

        } else {
            needRefinement = true;
        }

        stepLength = clamp(abs(depth - rayPosition.z) * stepWeight, minLength, maxLength);
		rayPosition += direction * stepLength;
		depth = texture(depthtex1, rayPosition.xy).x;
	}

	return depth >= 1.0 && isRayExit || intersect;
}






float SignExtract(float x) {
	return uintBitsToFloat((floatBitsToUint(x) & 0x80000000u) | floatBitsToUint(1.0));
}

mat3 GetRotationMatrix(vec3 from, vec3 to) {
	float cosine = dot(from, to);

	float tmp = SignExtract(cosine);
	      tmp = 1.0 / (tmp + cosine);

	vec3 axis = cross(to, from);
	vec3 tmpv = axis * tmp;

	return mat3(
		axis.x * tmpv.x + cosine, axis.x * tmpv.y - axis.z, axis.x * tmpv.z + axis.y,
		axis.y * tmpv.x + axis.z, axis.y * tmpv.y + cosine, axis.y * tmpv.z - axis.x,
		axis.z * tmpv.x - axis.y, axis.z * tmpv.y + axis.x, axis.z * tmpv.z + cosine
	);
}

#if !defined INCLUDE_UTILITY_COMPLEX
#define INCLUDE_UTILITY_COMPLEX

struct ComplexFloat {
	float r;
	float i;
};
struct ComplexVec3 {
	vec3 r;
	vec3 i;
};

bool ComplexEqual(ComplexFloat a, ComplexFloat b) {
	return a.r == b.r && a.i == b.i;
}
bool ComplexEqual(ComplexVec3 a, ComplexVec3 b) {
	return a.r == b.r && a.i == b.i;
}
ComplexFloat ComplexConjugate(ComplexFloat z) {
	return ComplexFloat(z.r, -z.i);
}
ComplexVec3 ComplexConjugate(ComplexVec3 z) {
	return ComplexVec3(z.r, -z.i);
}
ComplexFloat ComplexAdd(ComplexFloat a, ComplexFloat b) {
	return ComplexFloat(a.r + b.r, a.i + b.i);
}
ComplexVec3 ComplexAdd(ComplexVec3 a, ComplexVec3 b) {
	return ComplexVec3(a.r + b.r, a.i + b.i);
}
ComplexVec3 ComplexAdd(ComplexVec3 a, float b) {
	return ComplexVec3(a.r + b, a.i);
}
ComplexFloat ComplexSub(ComplexFloat a, ComplexFloat b) {
	return ComplexFloat(a.r - b.r, a.i - b.i);
}
ComplexFloat ComplexSub(float a, ComplexFloat b) {
	return ComplexFloat(a - b.r, -b.i);
}
ComplexFloat ComplexSub(ComplexFloat a, float b) {
	return ComplexFloat(a.r - b, a.i);
}
ComplexVec3 ComplexSub(ComplexVec3 a, ComplexVec3 b) {
	return ComplexVec3(a.r - b.r, a.i - b.i);
}
ComplexVec3 ComplexSub(vec3 a, ComplexVec3 b) {
	return ComplexVec3(a - b.r, -b.i);
}
ComplexVec3 ComplexSub(float a, ComplexVec3 b) {
	return ComplexVec3(a - b.r, -b.i);
}
ComplexVec3 ComplexSub(ComplexVec3 a, vec3 b) {
	return ComplexVec3(a.r - b, a.i);
}
ComplexVec3 ComplexSub(ComplexVec3 a, float b) {
	return ComplexVec3(a.r - b, a.i);
}
ComplexFloat ComplexMul(ComplexFloat a, ComplexFloat b) {
	return ComplexFloat(a.r * b.r - a.i * b.i, a.i * b.r + a.r * b.i);
}
ComplexFloat ComplexMul(float a, ComplexFloat b) {
	return ComplexFloat(a * b.r, a * b.i);
}
ComplexFloat ComplexMul(ComplexFloat a, float b) {
	return ComplexFloat(a.r * b, a.i * b);
}
ComplexVec3 ComplexMul(ComplexVec3 a, ComplexVec3 b) {
	return ComplexVec3(a.r * b.r - a.i * b.i, a.i * b.r + a.r * b.i);
}
ComplexVec3 ComplexMul(vec3 a, ComplexVec3 b) {
	return ComplexVec3(a * b.r, a * b.i);
}
ComplexVec3 ComplexMul(ComplexVec3 a, vec3 b) {
	return ComplexVec3(a.r * b, a.i * b);
}
ComplexVec3 ComplexMul(ComplexVec3 a, float b) {
	return ComplexVec3(a.r * b, a.i * b);
}
ComplexFloat ComplexDiv(ComplexFloat a, ComplexFloat b) {
	ComplexFloat ret;
	float denom = b.r * b.r + b.i * b.i;
	ret.r = (a.r * b.r + a.i * b.i) / denom;
	ret.i = (a.i * b.r - a.r * b.i) / denom;
	return ret;
}
ComplexVec3 ComplexDiv(ComplexVec3 a, ComplexVec3 b) {
	ComplexVec3 ret;
	vec3 denom = b.r * b.r + b.i * b.i;
	ret.r = (a.r * b.r + a.i * b.i) / denom;
	ret.i = (a.i * b.r - a.r * b.i) / denom;
	return ret;
}
ComplexFloat ComplexRcp(ComplexFloat z) {
	float denom = z.r * z.r + z.i * z.i;
	return ComplexFloat(z.r / denom, -z.i / denom);
}
ComplexVec3 ComplexRcp(ComplexVec3 z) {
	vec3 denom = z.r * z.r + z.i * z.i;
	return ComplexVec3(z.r / denom, -z.i / denom);
}
ComplexFloat ComplexSqrt(ComplexFloat z) {
	ComplexFloat ret;
	float modulus = sqrt(z.r * z.r + z.i * z.i);
	ret.r =             sqrt(max((modulus + z.r) * 0.5, 0.0));
	ret.i = sign(z.i) * sqrt(max((modulus - z.r) * 0.5, 0.0));
	return ret;
}
ComplexVec3 ComplexSqrt(ComplexVec3 z) {
	ComplexVec3 ret;
	vec3 modulus = sqrt(z.r * z.r + z.i * z.i);
	ret.r =             sqrt(max((modulus + z.r) * 0.5, 0.0));
	ret.i = sign(z.i) * sqrt(max((modulus - z.r) * 0.5, 0.0));
	return ret;
}
float ComplexAbs(ComplexFloat z) {
	return sqrt(z.r * z.r + z.i * z.i);
}
vec3 ComplexAbs(ComplexVec3 z) {
	return sqrt(z.r * z.r + z.i * z.i);
}

ComplexFloat ComplexExp(ComplexFloat z) {
	return ComplexMul(exp(z.r), ComplexFloat(cos(z.i), sin(z.i)));
}
ComplexFloat ComplexLog(ComplexFloat z) {
	//return ComplexFloat(log(sqrt(z.r * z.r + z.i * z.i)), atan(z.i, z.r));
	return ComplexFloat(0.5 * log(z.r * z.r + z.i * z.i), atan(z.i, z.r));
}
ComplexVec3 ComplexLog(ComplexVec3 z) {
	return ComplexVec3(0.5 * log(z.r * z.r + z.i * z.i), atan(z.i, z.r));
}

ComplexFloat ComplexSinh(ComplexFloat z) {
	return ComplexFloat(sinh(z.r) * cos(z.i), cosh(z.r) * sin(z.i));
}
ComplexFloat ComplexCosh(ComplexFloat z) {
	return ComplexFloat(cosh(z.r) * cos(z.i), sinh(z.r) * sin(z.i));
}
ComplexVec3 ComplexCosh(ComplexVec3 z) {
	return ComplexVec3(cosh(z.r) * cos(z.i), sinh(z.r) * sin(z.i));
}
ComplexFloat ComplexTanh(ComplexFloat z) {
	float s = sin(z.i), c = cos(z.i), sh = sinh(z.r), ch = cosh(z.r);
	return ComplexDiv(ComplexFloat(sh*c, ch*s), ComplexFloat(ch*c, sh*s));
}

ComplexFloat ComplexSin(ComplexFloat z) {
	// sin(z) = -i*sinh(i*z)
	z = ComplexSinh(ComplexFloat(-z.i, z.r));
	return ComplexFloat(z.i, -z.r);
}
ComplexFloat ComplexCos(ComplexFloat z) {
	// cos(z) = cosh(i*z)
	return ComplexCosh(ComplexFloat(-z.i, z.r));
}
ComplexVec3 ComplexCos(ComplexVec3 z) {
	// cos(z) = cosh(i*z)
	return ComplexCosh(ComplexVec3(-z.i, z.r));
}
ComplexFloat ComplexTan(ComplexFloat z) {
	// tan(z) = -i*tanh(i*z)
	z = ComplexTanh(ComplexFloat(-z.i, z.r));
	return ComplexFloat(z.i, -z.r);
}


// No idea if these are correct.
// They do appear to be correct for Im(z) == 0, but I have no reference for Im(z) != 0.
ComplexFloat ComplexArcsin(ComplexFloat z) {
	z = ComplexLog(ComplexAdd(ComplexFloat(-z.i, z.r), ComplexSqrt(ComplexSub(1, ComplexMul(z, z)))));
	return ComplexFloat(z.i, -z.r);
}
ComplexVec3 ComplexArcsin(ComplexVec3 z) {
	z = ComplexLog(ComplexAdd(ComplexVec3(-z.i, z.r), ComplexSqrt(ComplexSub(vec3(1), ComplexMul(z, z)))));
	return ComplexVec3(z.i, -z.r);
}
ComplexFloat ComplexArccos(ComplexFloat z) {
	z = ComplexLog(ComplexAdd(ComplexFloat(-z.i, z.r), ComplexSqrt(ComplexSub(1, ComplexMul(z, z)))));
	return ComplexFloat(radians( 90.0) - z.i, z.r);
}
#endif


vec3 FresnelNonpolarized(float VdotH, ComplexVec3 n1, ComplexVec3 n2) {
	ComplexVec3 eta = ComplexDiv(n1, n2);

	float       cosThetaI = VdotH;
	float       sinThetaI = 1.0 - cosThetaI * cosThetaI;
	ComplexVec3 sinThetaT = ComplexMul(eta, sinThetaI);
	ComplexVec3 cosThetaT = ComplexSqrt(ComplexSub(1.0, ComplexMul(sinThetaT, sinThetaT)));

	ComplexVec3 RsNum = ComplexSub(ComplexMul(eta, cosThetaI), cosThetaT);
	ComplexVec3 RsDiv = ComplexAdd(ComplexMul(eta, cosThetaI), cosThetaT);
	//vec3 sqrtRs = ComplexAbs(RsNum) / ComplexAbs(RsDiv);
	//vec3 Rs = sqrtRs * sqrtRs;
	vec3 Rs = (RsNum.r * RsNum.r + RsNum.i * RsNum.i) / (RsDiv.r * RsDiv.r + RsDiv.i * RsDiv.i);

	ComplexVec3 RpNum = ComplexSub(ComplexMul(eta, cosThetaT), cosThetaI);
	ComplexVec3 RpDiv = ComplexAdd(ComplexMul(eta, cosThetaT), cosThetaI);
	//vec3 sqrtRp = ComplexAbs(RpNum) / ComplexAbs(RpDiv);
	//vec3 Rp = sqrtRp * sqrtRp;
	vec3 Rp = (RpNum.r * RpNum.r + RpNum.i * RpNum.i) / (RpDiv.r * RpDiv.r + RpDiv.i * RpDiv.i);

	return saturate((Rs + Rp) * 0.5);
}



vec2 ProjectSky(vec3 dir, float lod) {
	float tileSize       = min(floor(viewDimensions.x * 0.5) / 1.5, floor(viewDimensions.y * 0.5)) * exp2(-lod);
	float tileSizeDivide = (0.5 * tileSize) - 1.5;

	vec2 coord;
	if (abs(dir.x) > abs(dir.y) && abs(dir.x) > abs(dir.z)) {
		dir /= abs(dir.x);
		coord.x = dir.y * tileSizeDivide + tileSize * 0.5;
		coord.y = dir.z * tileSizeDivide + tileSize * (dir.x < 0.0 ? 0.5 : 1.5);
	} else if (abs(dir.y) > abs(dir.x) && abs(dir.y) > abs(dir.z)) {
		dir /= abs(dir.y);
		coord.x = dir.x * tileSizeDivide + tileSize * 1.5;
		coord.y = dir.z * tileSizeDivide + tileSize * (dir.y < 0.0 ? 0.5 : 1.5);
	} else {
		dir /= abs(dir.z);
		coord.x = dir.x * tileSizeDivide + tileSize * 2.5;
		coord.y = dir.y * tileSizeDivide + tileSize * (dir.z < 0.0 ? 0.5 : 1.5);
	}

	return coord / viewDimensions;
}


#define SPECULAR_TAIL_CLAMP 0.3

vec3 sampleGGXVNDF(vec3 Ve, float alpha, vec2 Xi) {
    Xi.y = mix(Xi.y, 0.0, SPECULAR_TAIL_CLAMP);

    // Section 3.2: transforming the view direction to the hemisphere configuration
    vec3 Vh = normalize(vec3(alpha * Ve.x, alpha * Ve.y, Ve.z));

    // Section 4.1: orthonormal basis (with special case if cross product is zero)
    float lensq = Vh.x * Vh.x + Vh.y * Vh.y;
    vec3 T1 = lensq > 0.0 ? vec3(-Vh.y, Vh.x, 0.0) * inversesqrt(lensq) : vec3(1.0, 0.0, 0.0);
    vec3 T2 = cross(Vh, T1);

    // Section 4.2: parameterization of the projected area
    float r = sqrt(Xi.y);
    float phi = radians(360.0) * Xi.x;

    float s = 0.5 * (1.0 + Vh.z);

    float t1 = r * cos(phi);
    float t2 = r * sin(phi);
        t2 = (1.0 - s) * sqrt(1.0 - t1 * t1) + s * t2;

    // Section 4.3: reprojection onto hemisphere
    vec3 Nh = t1 * T1 + t2 * T2 + sqrt(max(1.0 - t1 * t1 - t2 * t2, 0.0)) * Vh;

    // Section 3.4: transforming the normal back to the ellipsoid configuration
    vec3 Ne = normalize(vec3(alpha * Nh.x, alpha * Nh.y, max(Nh.z, 0.0)));

    return Ne;
}


vec4 ReflectionFilter(sampler2D v, GbufferData gbuffer, float size, bool applyNoise)
{
    vec4 reflectionData = texture(v, texcoord.st);
    if(!gbuffer.material.doCSR || reflectionData.w < 0.0001) return reflectionData;

    vec3 viewPos = GetViewPosition(texcoord.st, gbuffer.depthW);
    vec3 viewDir = normalize(viewPos);
    float linearDepth = ScreenToViewSpaceDepth(texture(gdepthtex, texcoord.st).x);
    float NdotV = saturate(dot(-viewDir, gbuffer.normalW));

    float roughness2 = gbuffer.material.roughness;

    float T = size * 0.9;
    T *= min(roughness2 * 20.0, 1.1);
    T *= mix(reflectionData.w, 1.0, 0.2);

    vec2 noise = vec2(0.0);
    if(applyNoise) noise = RandNext2F() * 0.99 - 0.495;

    vec4 accum = vec4(0.0);
    float weights = 0.0;

    float J = reflectionData.w * 0.475 + 0.025;

    const float cos17508 = cos(1.5708);
    const float sin15708 = sin(1.5708);
    vec2 D = normalize(cross(gbuffer.normalW, viewDir).xy);
    vec2 L = D * mat2(cos17508, -sin15708, sin15708, cos17508);
    D *= mix(0.1075, 0.5, NdotV);
    L *= mix(0.7, 0.5, NdotV);

    vec3 nVrN = reflect(-viewDir, gbuffer.normalW);

    vec2 ScreenTexel4 = 4.0 * pixelSize;
    vec2 ScreenTexel4Inverse = 1.0 - ScreenTexel4;

    vec2 Temp = T * 1.5 * pixelSize;
    L *= Temp;
    D *= Temp;
    roughness2 = 100.0 / roughness2;

    for(int i=-1; i<=1; i++)
    {
        vec2 Temp2 = D * (i + noise.x) + texcoord.st;

        for(int j=-1; j<=1; j++)
        {
            vec2 sampleCoord = Temp2 + L * (j + noise.y);
            sampleCoord = clamp(sampleCoord, ScreenTexel4, ScreenTexel4Inverse);

            vec4 sampleData = texture(v, sampleCoord);

            if (sampleData.w < 0.0001) continue;

            float sampleLinerDepth = ScreenToViewSpaceDepth(texture(gdepthtex, sampleCoord).x);
            vec3 nVrSN = reflect(-viewDir, DecodeNormal(texture(colortex4, sampleCoord).xy));

            float normalWeight = pow(saturate(dot(nVrN, nVrSN)), roughness2);
            float depthWeight = exp(-(abs(sampleLinerDepth - linearDepth) * 1.1));
            float sampleWeight = normalWeight * depthWeight;

            accum += vec4(pow(length(sampleData.xyz), J) * normalize(sampleData.xyz + 1e-10), sampleData.w) * sampleWeight;
            weights += sampleWeight;
        }
    }
    if(weights < 0.0001) return reflectionData;

    accum /= weights + 0.0001;
    accum.xyz = pow(length(accum.xyz), 1.0 / J) * normalize(accum.xyz + 1e-06);

    return accum;
}

/* GFME
vec4 G(sampler2D v)
 {
   GBufferData gbufferS=GetGBufferData(texcoord.xy);
   GBufferDataTransparent gbufferT=GetGBufferDataTransparent(texcoord.xy);

   if(gbufferT.depth < gbufferS.depth)
     gbufferS.normal = gbufferT.normal,   gbufferS.smoothness = gbufferT.smoothness,   gbufferS.metalness = 0.0,   gbufferS.depth = gbufferT.depth;


   vec4 viewPos = GetViewPosition(texcoord.xy, gbufferS.depth); //r
   vec3 viewDir = normalize(viewPos.xyz);                       //h
   float linearDepth = GetDepthLinear(texcoord.xy);             //p
   float NdotV = saturate(dot(-viewDir, gbufferS.normal.xyz));  //M
   float roughness = 1.0 - gbufferS.smoothness;                 //l
   float roughness2 = roughness * roughness;                    //w
   float fe =e(gbufferS.smoothness, gbufferS.metalness);        //b

   vec4 reflectionData = texture2DLod(v,texcoord.xy+HalfScreen,0); //F

   if(fe < 0.001) return reflectionData;

   float T = 27.0;
   T *= min(roughness2 * 20.0, 1.1);
   T *= mix(reflectionData.w, 1.0, 0.2);

   vec4 accum = vec4(0.0); //U
   float weights = 0.0; //E

   float J = reflectionData.w * 0.475 + 0.025;

   const float cos17508 = cos(1.5708);
   const float sin15708 = sin(1.5708);
   vec2 D = normalize(cross(gbufferS.normal, viewDir).xy);
   vec2 L = D * mat2(cos17508, -sin15708, sin15708, cos17508);
   D *= mix(0.1075, 0.5, NdotV);
   L *= mix(0.7, 0.5, NdotV);

   vec3 nVrN = reflect(-viewDir, gbufferS.normal); //V

   vec2 ScreenTexel4 = 4.0 * ScreenTexel;
   vec2 ScreenTexel4Inverse = 1.0 - ScreenTexel4;

   vec2 Temp = T * 1.5 * ScreenTexel;
   L *= Temp;
   D *= Temp;
   roughness2 = 105.0 / roughness2;

   for(int i=-1; i<=1; i++) //W
     {
       vec2 Temp2 = i * D + texcoord.st;

       for(int j=-1; j<=1; j++) //C
         {
           vec2 sampleCoord = Temp2 + j * L; //X
           sampleCoord = clamp(sampleCoord, ScreenTexel4, ScreenTexel4Inverse);

           vec4 sampleData = texture2DLod(v, sampleCoord + HalfScreen, 0); //V

           float sampleLinerDepth = GetDepthLinear(sampleCoord); //Z
           vec3 nVrSN = reflect(-viewDir, GetNormals(sampleCoord));

           float normalWeight = pow(saturate(dot(nVrN, nVrSN)), roughness2);
           float depthWeight = exp(-(abs(sampleLinerDepth - linearDepth) * 1.1));
           float sampleWeight = normalWeight * depthWeight;

           accum += vec4(pow(length(sampleData.xyz), J) * normalize(sampleData.xyz + 1e-10), sampleData.w) * sampleWeight;
           weights += sampleWeight;
         }
     }
   if(weights < 0.001) return reflectionData;

   accum /= weights + 0.0001;
   accum.xyz = pow(length(accum.xyz), 1.0 / J) * normalize(accum.xyz + 1e-06);

   return accum;
 }
*/
