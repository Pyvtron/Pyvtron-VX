/*
====================================================================================================

    Copyright (C) 2025 Pyvtron VX Shaders - Pyvtron

    All Rights Reserved unless otherwise explicitly stated.

====================================================================================================
*/


layout(location = 0) out vec4 compositeOutput3;

#include "/Include/Uniforms.glsl"
#include "/Include/Core/Core.glsl"

/////////////////////////CONFIGURABLE VARIABLES////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
/////////////////////////CONFIGURABLE VARIABLES////////////////////////////////////////////////////////////////////////////////////////////////////////////////////





/////////////////////////UNIFORMS//////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
/////////////////////////UNIFORMS//////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////


in vec4 texcoord;
in vec3 lightVector;
in vec3 upVector;

in vec3 colorTorchlight;

in vec3 worldSunVector;
in vec3 worldLightVector;



/////////////////////////END OF CONFIGURABLE VARIABLES/////////////////////////////////////////////////////////////////////////////////////////////////////////////
/////////////////////////END OF CONFIGURABLE VARIABLES/////////////////////////////////////////////////////////////////////////////////////////////////////////////

vec3 GetViewPosition(in vec2 coord, in float depth)
{
	#ifdef TAA
		coord -= taaJitter * 0.5;
	#endif

	vec3 screenPos = vec3(coord, depth) * 2.0 - 1.0;

	vec4 fragposition = gbufferProjectionInverse * vec4(screenPos, 1.0f);
		 fragposition /= fragposition.w;

	return fragposition.xyz;
}

vec3 GetViewPositionRaw(in vec2 coord, in float depth)
{
	vec3 screenPos = vec3(coord, depth) * 2.0 - 1.0;

	vec4 fragposition = gbufferProjectionInverse * vec4(screenPos, 1.0f);
		 fragposition /= fragposition.w;

	return fragposition.xyz;
}

float Get3DNoise(in vec3 pos)
{
	pos.xyz += 0.5f;

	vec3 p = floor(pos);
	vec3 f = fract(pos);

	f = smoothstep(vec3(0.0), vec3(1.0), f);

	vec2 uv =  (p.xy + p.z * vec2(-17.0f, -17.0f)) + f.xy;

	vec2 coord =  (uv + 0.5f) / 64.0;
	vec2 noiseSample = texture(noisetex, coord).xy;
	float xy1 = noiseSample.x;
	float xy2 = noiseSample.y;
	return mix(xy1, xy2, f.z);
}

float ScreenToViewSpaceDepth(float depth) {
    depth = depth * 2.0 - 1.0;
    return 1.0 / (depth * gbufferProjectionInverse[2][3] + gbufferProjectionInverse[3][3]);
}

float ViewToScreenSpaceDepth(float depth) {
	depth = (1.0 / depth - gbufferProjectionInverse[3][3]) / gbufferProjectionInverse[2][3];
    return depth * 0.5 + 0.5;
}


#include "/Include/Core/GBufferData.glsl"
#include "/Include/Core/Mask.glsl"

void FixParticleMask(inout MaterialMask materialMaskSoild, inout MaterialMask materialMask){
	#if MC_VERSION >= 11500
	if(materialMaskSoild.particle > 0.5 || materialMaskSoild.particlelit > 0.5){
		materialMask.particle = 1.0;
		materialMask.water = 0.0;
		materialMask.stainedGlass = 0.0;
		materialMask.ice = 0.0;
		materialMask.sky = 0.0;
	}
	#endif
}

void ApplyMaterial(inout Material material, in MaterialMask materialMask, inout bool isSmooth){
	if (materialMask.water > 0.5){
		material = material_water;
		isSmooth = true;
	}
	if (materialMask.stainedGlass > 0.5){
		material = material_glass;
		isSmooth = true;
	}
	if (materialMask.ice > 0.5){
		material = material_ice;
		isSmooth = true;
	}
}

float GetBayerNoise(){
	float noise  = bayer64(gl_FragCoord.xy);
	#ifdef TAA
		noise = fract(frameCounter * (1.0 / 8.0) + noise);
	#endif
	return noise;
}

vec3 EndFog(float dist, vec3 worldDir){

    float angleX = -15;
    angleX = radians(angleX);

    float angleY = 150.0;
    angleY = radians(angleY);

    mat3 eyeRoataionMatrixX = mat3(1, 0, 0, 0, cos(angleX), -sin(angleX), 0, sin(angleX), cos(angleX));
    mat3 eyeRoataionMatrixY = mat3(cos(angleY), 0, sin(angleY), 0, 1, 0, -sin(angleY), 0, cos(angleY));
    mat3 eyeRoataionMatrix = eyeRoataionMatrixX * eyeRoataionMatrixY;

    worldDir = eyeRoataionMatrix * worldDir;

    dist = min(dist, 512.0);
    float h = abs(dot(worldDir, vec3(0.0, 1.0, 0.0))) * dist * 0.03;
    float density = (1.0 - exp(-h)) / h * dist;

    return vec3(1.0) * density * 0.01;
}


vec2 RaySphereIntersectionIO(vec3 p, vec3 dir, float r)
{
	float b = dot(p, dir);
	float c = -r * r + dot(p, p);

	float d = b * b -c;
	if (d < 0.0)
	{
		return vec2(-1e10, 1e10);
	}

	d = sqrt(d);

	return vec2(-b + d, -b - d);
}

Intersection RayPlaneIntersection(in Ray ray, in Plane plane)
{
	float rayPlaneAngle = dot(ray.dir, plane.normal);

	float planeRayDist = 100000000.0f;
	vec3 intersectionPos = ray.dir * planeRayDist;

	if (rayPlaneAngle > 0.0001f || rayPlaneAngle < -0.0001f)
	{
		planeRayDist = dot((plane.origin - ray.origin), plane.normal) / rayPlaneAngle;
		intersectionPos = ray.origin + ray.dir * planeRayDist;
		// intersectionPos = -intersectionPos;

		// intersectionPos += cameraPosition.xyz;
	}

	Intersection i;

	i.pos = intersectionPos;
	i.distance = planeRayDist;
	i.angle = rayPlaneAngle;

	return i;
}



vec3 H(vec3 albedo, float a){
    vec3 R = sqrt(vec3(1.0) - albedo);
    vec3 r = (1.0 - R) / (1.0 + R);
    vec3 H = r + (0.5 - r * a) * log((1.0 + a) / a);
    H *= albedo * a;

    return 1.0 / (1.0 - H);
}

vec3 ppss(vec3 albedo, vec3 normal, vec3 eyeDir, vec3 lightDir, float s){
    float NdotL = dot(normal, lightDir);
    float NdotV = dot(normal, eyeDir);
    //NdotL = saturate(NdotL);
    //NdotV = saturate(NdotV);
    albedo *= curve(saturate(NdotL));

    vec3 color = albedo * H(albedo, NdotL) * H(albedo, NdotV) / (4.0 * PI * (NdotL + NdotV));

    //return saturate(color * pow(NdotL, 1.0));
    return saturate(color);
}

float Disc(float a, float s, float h){
    return pow(curve(saturate((a - (1.0 - s)) * h)), 2.0);
}

void PlanetEnd2(inout vec3 color, in vec3 eye, in vec3 rayDir, in vec3 lightDir){
    float timeFactor = frameTimeCounter * 10.0;
    float angleX = -104.5;
    angleX = radians(angleX);

    float angleY = 150.0;
    angleY = radians(angleY);

    mat3 eyeRoataionMatrixX = mat3(1, 0, 0, 0, cos(angleX), -sin(angleX), 0, sin(angleX), cos(angleX));
    mat3 eyeRoataionMatrixY = mat3(cos(angleY), 0, sin(angleY), 0, 1, 0, -sin(angleY), 0, cos(angleY));
    mat3 eyeRoataionMatrix = eyeRoataionMatrixX * eyeRoataionMatrixY;

    float ringAngle = radians(0.5);

    mat3 ringRoataionMatrix = mat3(1.0, 0.0, 0.0,
                                   0.0, cos(ringAngle), sin(ringAngle),
                                   0.0, -sin(ringAngle), cos(ringAngle));
    mat3 ringRoataionMatrixInverse = transpose(ringRoataionMatrix);

    rayDir = eyeRoataionMatrix * rayDir;
    lightDir = eyeRoataionMatrix * lightDir;


    vec3 surface = vec3(0.0);
	float LdotR = dot(rayDir, -lightDir);


	float Rground = 20e6;
	//float Hatmo = 700.0e3;
	//float Ratmo = Rground + Hatmo;
	eye.y += Rground;
    eye.y += 15e6;

	vec2 RgroundIntersection = RaySphereIntersectionIO(eye, rayDir, Rground);
    if(RgroundIntersection.x > 0.0){
        color *= 0.0;
        vec3 surfacePos = rayDir * RgroundIntersection.y;
        vec3 surfaceNormal = normalize(surfacePos - vec3(0.0, -eye.y, 0.0));

        surface = ppss(vec3(1.0, 0.87, 0.55), surfaceNormal, -rayDir, lightDir, 1.0);
        surface *= 70.0;

        float UdotN = saturate(dot(ringRoataionMatrixInverse[2], surfaceNormal));
        float DdotN = saturate(dot(-ringRoataionMatrixInverse[2], surfaceNormal));
        float OLdotN = saturate(dot(ringRoataionMatrixInverse * normalize(vec3(-lightDir.xy, 0.0)), surfaceNormal));

        float ringLighting = Disc(UdotN, 1.2, 1.5) * (1.0 - Disc(UdotN, 3.4, 0.3));
        ringLighting += Disc(DdotN, 1.2, 1.5) * (1.0 - Disc(DdotN, 3.4, 0.3));
        //ringLighting *= 0.2;
        ringLighting *= 1.0 - Disc(OLdotN, 0.7, 1.3);

        surface += vec3(1.0, 0.87, 0.55) * (0.01 + ringLighting * 0.7);
        //surface = vec3(1.0) * OLdotN;
    }




    vec3 ring = vec3(0.0);


    vec3 planetDir = ringRoataionMatrix * rayDir;
    lightDir = ringRoataionMatrix * lightDir;

    if (planetDir.z * ringAngle < 0.0){

        Ray ray;
        ray.dir = planetDir;
        ray.origin = vec3(0.0, cos(ringAngle), sin(ringAngle)) * (eye.y / Rground);

        Plane plane;
        plane.normal= vec3(0.0, 0.0, 1.0);
        plane.origin= vec3(0.0);

        vec3 rayPos = RayPlaneIntersection(ray, plane).pos;
        float rayRadius = length(rayPos);
        vec2 ringRadius = vec2(1.6, 2.2);


        if(rayRadius > ringRadius.x && rayRadius < ringRadius.y)
        {
            const float octAlpha = 0.5;
            float octScale = 4.0; // The downscaling factor between successive octaves
            float octShift = (octAlpha / octScale) / 5; // Shift the FBM brightness based on how many octaves are active

            float accum = 0.0;
            float alpha = 0.5;
            float shift = 0.0;

            float position = rayRadius * 0.5 + 0.69;

            position += shift;

            for (int i = 0; i < 5; i++) {
                accum += alpha * texture(noisetex, vec2(position, 0.0)).z;
                position = (position + shift) * octScale;
                alpha *= octAlpha;
            }

            ring += pow(saturate(accum + octShift - 0.1) * 1.5, 3.0);

            ring *= smoothstep(ringRadius.x, ringRadius.x * 1.1, rayRadius);
            //ring *= smoothstep(ringRadius.y, ringRadius.y * 0.95, rayRadius);
            if(rayPos.y < 0.0 && RgroundIntersection.x > 0.0){
                ring *= 0.0;
            }else{
                surface *= 1.0 - ring * 1.0;
            }
            float d = length(cross(lightDir, rayPos));
            if(d < 1.0 && dot(lightDir, rayPos) < 0.0) ring *= 0.025;
        }
    }
    ring *= vec3(1.0, 0.85, 0.60) * 3.0;

	color += (surface + ring) * 1.5;
}

#include "/Include/SSR.glsl"

vec3 ComputeFakeSkyReflection(vec3 reflectWorldDir, bool isSmooth)
{
	vec2 skyImageCoord = ProjectSky(reflectWorldDir, SKY_IMAGE_LOD);
	vec3 sky = vec3(0.0);


	if (isSmooth) {
		vec3 sunDisc = vec3(RenderSunDisc(reflectWorldDir, worldSunVector));
		sky += sunDisc * 2e4;
	}

	PlanetEnd2(sky, vec3(0.0), reflectWorldDir, worldLightVector);

	//sky += EndFog(512.0, reflectWorldDir);

	return sky * compositeOutputFactor;
}


vec4 CalculateSpecularReflections(in vec3 viewPos, in vec3 viewDir, in vec3 normal, in float gbufferdepth, in vec3 albedo, in Material material, in float skylight, in bool isHand, in bool isSmooth)
{
	bool totalInternalReflection = texture(colortex1, texcoord.st).a > 0.5;

	mat3 rot = GetRotationMatrix(vec3(0, 0, 1), normal);
	vec3 tangentView = viewDir * rot;
	float NdotU = saturate((dot(normal, upVector) + 0.7) * 2.0) * 0.75 + 0.25;
	float NdotV = max(1e-12, dot(-viewDir, normal));
	float noise = GetBayerNoise();


	vec3 screenPos = vec3(texcoord.st, gbufferdepth);

	vec3 reflection;
	float hitDepth;
	vec3 rayDirection;
	float MdotV;

	bool hit;

	if(isSmooth){
		rayDirection = reflect(viewDir, normal);
		MdotV = dot(normal, -viewDir);
		float NdotL = abs(dot(normal, rayDirection));

		hit = rayTrace(viewPos, rayDirection, NdotV, noise, isHand, screenPos) && NdotL > 0.0;

		hitDepth = 0.0;

	}else{

		vec3 facetNormal = rot * sampleGGXVNDF(-tangentView, material.roughness, RandNext2F());
		MdotV = dot(facetNormal, -viewDir);
		rayDirection = viewDir + 2.0 * MdotV * facetNormal;
		float NdotL = abs(dot(normal, rayDirection));

		hit = rayTrace(viewPos, rayDirection, NdotV, noise, isHand, screenPos) && NdotL > 0.0;

		hitDepth = 1.0;
	}

	reflection = GammaToLinear(texture(colortex1, screenPos.xy).rgb);

	vec3 rayDirectionWorld = mat3(gbufferModelViewInverse) * rayDirection;
	vec3 skyReflection = vec3(0.0);
	if(!totalInternalReflection && isEyeInWater == 0){
		skylight = clamp(fma(skylight, 8.0f, -1.5f), 0.0f, 1.0f);
		skyReflection = ComputeFakeSkyReflection(rayDirectionWorld, isSmooth);
		//skyReflection = mix(vec3(0.0), skyReflection, skylight);
		skyReflection *= NdotU;
	}
	if(totalInternalReflection) skyReflection = GammaToLinear(texture(colortex1, texcoord.st).rgb);

	reflection = hit ? reflection : skyReflection;

	float rDist = max(512.0 - ScreenToViewSpaceDepth(gbufferdepth), 0.0);
	if(hit){
		vec3 hitPos = GetViewPosition(screenPos.xy, texture(gdepthtex, screenPos.xy).x);
		rDist = distance(hitPos, viewPos);

		if(!isSmooth) hitDepth = saturate(max(rDist * 2.0, 3.0 * material.roughness));
	}
	reflection += EndFog(rDist, rayDirectionWorld) * compositeOutputFactor;


	#if TEXTURE_PBR_FORMAT == 1
	if(!totalInternalReflection) {
		reflection *= FresnelNonpolarized(MdotV, ComplexVec3(airMaterial.n, airMaterial.k), ComplexVec3(material.n, material.k));
	}
	#endif

	return vec4(reflection.rgb, hitDepth);
}

/////////////////////////MAIN//////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
/////////////////////////MAIN//////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
void main()
{

	GbufferData gbuffer 			= GetGbufferData();
	MaterialMask materialMaskSoild 	= CalculateMasks(gbuffer.materialIDL);
	MaterialMask materialMask 		= CalculateMasks(gbuffer.materialIDW);

	FixParticleMask(materialMaskSoild, materialMask);
	bool isSmooth = false;
	ApplyMaterial(gbuffer.material, materialMask, isSmooth);

	vec3 viewPos 		= GetViewPosition(texcoord.st, gbuffer.depthW);
	vec3 viewDir 		= normalize(viewPos.xyz);


	vec4 reflection = vec4(0.0);

	if (gbuffer.material.doCSR){
		reflection = CalculateSpecularReflections(viewPos, viewDir, gbuffer.normalW, gbuffer.depthW, gbuffer.albedo, gbuffer.material, gbuffer.lightmapW.g, materialMask.hand > 0.5, isSmooth);
	}
	reflection.rgb = LinearToGamma(reflection.rgb);

	vec4 data6 = texture(colortex6, texcoord.st);

	compositeOutput3 = reflection;
}

/* DRAWBUFFERS:3 */
