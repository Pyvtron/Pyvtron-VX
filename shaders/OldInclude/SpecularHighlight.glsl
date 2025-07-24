float FSchlick(const float f0, const float LoH) {
    return f0 + (1.0 - f0) * pow(1.0 - LoH, 5);
}

float FSchlickGaussian(const float f0, const float LoH) {
    return f0 + (1.0 - f0) * exp2(-9.60232 * pow(LoH, 8) - 8.58092 * LoH);
}

vec3 FExactF0(const vec3 f0, const float LoH){
    vec3 f = sqrt(f0);
    vec3 f01 = f + 1.0;
    vec3 f0n1 = f - 1.0;

    vec3 alpha = f0n1 * f0n1 * (1.0 - LoH * LoH) / (f01 * f01);
    vec3 f01a = f01 * alpha;
    vec3 f0n1a = f0n1 * alpha;

    vec3 x_num = f01 * LoH + f0n1a;
    vec3 x_den = f01 * LoH - f0n1a;
    vec3 x = x_num / x_den;

    vec3 y_num = f0n1 * LoH + f01a;
    vec3 y_den = f0n1 * LoH - f01a;
    vec3 y = y_num / y_den;

    return saturate(0.5 * (y * y + x * x));
}

vec3 FExact(const vec3 n, const vec3 k, const float c) {
    float c2 = c * c;
    vec3 k2 = k * k;
    vec3 n2 = n * n;
    vec3 n2k2 = n2 + k2;

    vec3 nc2 = 2.0 * n * c;

    vec3 rs_num = n2k2 - nc2 + c2;
    vec3 rs_den = n2k2 + nc2 + c2;
    vec3 rs = rs_num / rs_den;

    vec3 rp_num = n2k2 * c2 - nc2 + 1.0;
    vec3 rp_den = n2k2 * c2 + nc2 + 1.0;
    vec3 rp = rp_num / rp_den;

    return saturate(0.5 * (rs + rp));
}

vec3 FMaster(const float f0, const float LoH, const mat2x3 metalIOR, const vec3 diffuseColor){
    if (f0 < 0.16){
        return vec3(FSchlickGaussian(f0, LoH));         // Standard materials
    //} else if (f0 < 230.0 / 255.0){
    //    return vec3(FSchlick(f0, LoH));                 // Gems, Extreme reflectance
    } else if (f0 < 1.0){
        return FExact(metalIOR[0], metalIOR[1], LoH);   // Hard Coded Metals
    }

    return FExact(F0ToIor(diffuseColor), vec3(0.0), LoH);                    // Other Metals
}

float DGGX(float a2, float NoH) {
    float d = (NoH * a2 - NoH) * NoH + 1.0;	// 2 mad
    return a2 / (PI * d * d); // 4 mul, 1 rcp
}

float G1Smith(float alpha2, float NoS) {
    return (2.0 * NoS) / (sqrt(alpha2 + (1.0 - alpha2) * pow(NoS, 2)) + NoS);
}

float G2Smith(float alpha2, float NoL, float NoV) {
    float x = 2.0 * NoL * NoV;
    float y = (1.0 - alpha2);

    return x / (NoV * sqrt(alpha2 + y * (NoL * NoL)) + NoL * sqrt(alpha2 + y * (NoV * NoV)));
}

float VisJoint(float alpha, float NoL, float NoV) {
    float invAlpha = 1.0 - alpha;
    float Vis_SmithV = NoL * (NoV * invAlpha + alpha);
    float Vis_SmithL = NoV * (NoL * invAlpha + alpha);

    return 0.5 / (Vis_SmithV + Vis_SmithL);
}

float GetNoHSquared(float radiusTan, float NoL, float NoV, float VoL){
	float radiusCos = inversesqrt(radiusTan * radiusTan + 1.0);

	float RoL = 2.0 * NoL * NoV - VoL;
	if (RoL >= radiusCos)
		return 1.0;

	float rOverLengthT = radiusCos * radiusTan * inversesqrt(1.0 - RoL * RoL);
	float NoTr = rOverLengthT * (NoV - RoL * NoL);
	float VoTr = rOverLengthT * (2.0 * NoV * NoV - 1.0 - RoL * VoL);

	float triple = sqrt(saturate(1.0 - NoL * NoL - NoV * NoV - VoL * VoL + 2.0 * NoL * NoV * VoL));

	float NoBr = rOverLengthT * triple, VoBr = rOverLengthT * (2.0 * triple * NoV);
	float NoLVTr = NoL * radiusCos + NoV + NoTr, VoLVTr = VoL * radiusCos + 1.0 + VoTr;
	float p = NoBr * VoLVTr, q = NoLVTr * VoLVTr, s = VoBr * NoLVTr;
	float xNum = q * (-0.5 * p + 0.25 * VoBr * NoLVTr);
	float xDenom = p * p + s * (s - 2.0 * p) + NoLVTr * ((NoL * radiusCos + NoV) * VoLVTr * VoLVTr +
				   q * (-0.5 * (VoLVTr + VoL * radiusCos) - 0.5));
	float twoX1 = 2.0 * xNum / (xDenom * xDenom + xNum * xNum);
	float sinTheta = twoX1 * xDenom;
	float cosTheta = 1.0 - twoX1 * xNum;

	NoTr = cosTheta * NoTr + sinTheta * NoBr;
	VoTr = cosTheta * VoTr + sinTheta * VoBr;

	float newNol = NoL * radiusCos + NoTr;
	float newVol = VoL * radiusCos + VoTr;
	float NoH = NoV + newNol;
	float HoH = 2.0 * newVol + 2.0;

	return max(NoH * NoH / HoH, 0.0);
}

void EvaluateNdotH(float radius, float NdotL, float NdotV, float LdotV, inout float NdotH) {
	float radiusTan = max(0.001, tan(radius));
    NdotH = sqrt(GetNoHSquared(radiusTan, NdotL, NdotV, LdotV));
}

float EvaluateNormalizationFactor(float alpha, float LdotH, float radius) {
	// Decima: Still in flux
	float roughnessSquaredLdotH = alpha * alpha * (LdotH + 0.001);
    return roughnessSquaredLdotH / (roughnessSquaredLdotH + 0.25 * radius * (2.0 * alpha + radius));
}

vec3 CalculateSpecularHighlight(vec3 diffuseColor, vec3 normal, vec3 viewVector, float roughness, float f0, mat2x3 metalIOR) {
	vec3 lightVector = worldLightVector;
	float NoL = dot(normal, lightVector);
    if (NoL <= 0.0) return vec3(0.0);

    float alpha = roughness;
    float alpha2 = alpha * alpha;

    vec3 H = normalize(viewVector + lightVector);

    float NoV = dot(normal, viewVector);
    float LoV = dot(lightVector, viewVector);
    float LoH = dot(lightVector, H);
    float NoH = 0.0;

    float lightAngularRadius = 0.015;

    EvaluateNdotH(lightAngularRadius, NoL, NoV, LoV, NoH);
    float pdf = EvaluateNormalizationFactor(alpha, LoH, lightAngularRadius);

    vec3 F = FMaster(f0, LoH, metalIOR, diffuseColor);
    float D = DGGX(alpha2, NoH);
    float G2Smith = G2Smith(alpha2, NoL, clamp(NoV, 1e-6, 1.0));

    vec3 highlight = (F * D * G2Smith) / (4.0 * NoL * NoV);
         highlight *= saturate(NoL) * (f0 > (230.0 / 255.0) && f0 < 1.0 ? diffuseColor : vec3(1.0));

    return highlight * pdf;
}

vec3 CalculateSpecularHighlightTorch(vec3 diffuseColor, vec3 normal, vec3 viewVector, vec3 lightVector, float roughness, float f0, mat2x3 metalIOR) {
	float NoL = dot(normal, lightVector);
    if (NoL <= 0.0) return vec3(0.0);

    float alpha = roughness;
    float alpha2 = alpha * alpha;

    vec3 H = normalize(viewVector + lightVector);

    float NoV = dot(normal, viewVector);
    float LoV = dot(lightVector, viewVector);
    float LoH = dot(lightVector, H);
    float NoH = 0.0;

    float lightAngularRadius = 1e-6;

    EvaluateNdotH(lightAngularRadius, NoL, NoV, LoV, NoH);
    float pdf = EvaluateNormalizationFactor(alpha, LoH, lightAngularRadius);

    vec3 F = FMaster(f0, LoH, metalIOR, diffuseColor);
    float D = DGGX(alpha2, NoH);
    float G2Smith = G2Smith(alpha2, NoL, clamp(NoV, 1e-6, 1.0));

    vec3 highlight = (F * D * G2Smith) / (4.0 * NoL * NoV);
         highlight *= saturate(NoL) * (f0 > (230.0 / 255.0) && f0 < 1.0 ? diffuseColor : vec3(1.0));

    return highlight * pdf;
}
