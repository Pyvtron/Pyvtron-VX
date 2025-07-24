#define GODRAYS
#define GODRAYS_STAINED_GLASS_TINT
#define GR_VL_PERCENTAGE 0.5 // [0.5 0.6 0.7 0.8 0.9 1.0 1.1 1.2 1.3 1.4 1.5 1.7 2.0 3.0 4.0 5.0 7.0 10.0 100.0]
#define GODRAYS_STRENGTH 1.0 // [0.01 0.015 0.02 0.03 0.05 0.075 0.1 0.15 0.2 0.3 0.5 0.75 1.0 1.5 2.0 3.0 5.0 7.5 10.0 15.0 20.0 30.0 50.0 75.0 100.0 500.0 1000.0 2000.0 5000.0 10000.0]
#define GODRAYS_LENGTH 120.0 //[120.0 160.0 200.0 300.0 500.0 700.0 1000.0]
#define GODRAYS_QUALITY 10 //[10 15 20 30 50 70 100 150 200 300 500 700 1000]
//#define NOON_GODRAY







float PhaseMie( float g, float LdotV, float LdotV2 ) {
	float gg = g * g;

	float a = ( 1.0 - gg ) * ( 1.0 + LdotV2 );

	float b = 1.0 + gg - 2.0 * g * LdotV;
	b *= sqrt( b );
	b *= 2.0 + gg;

	return 1.5 * a / b;
}


float CalculateWaterCaustics(vec3 worldPos){

	worldPos.xyz += cameraPosition.xyz;

	vec3 lookupCenter = worldPos.xyz + vec3(0.0, 1.0, 0.0);

	vec3 wavesNormal = GetWavesNormalFromTex(lookupCenter).xzy;
	vec3 refractVector = refract(vec3(0.0, 1.0, 0.0), wavesNormal.xyz, 1.0);
	vec3 collisionPoint = lookupCenter - refractVector / refractVector.y;

	float dist = distance(collisionPoint, worldPos.xyz);

	return dist + 0.2;
}


void PeGodrayUW(inout vec3 color, vec3 worldPos, vec3 worldDir, float globalCloudShadow, float noise){

	float E=30;
	//Y=0.0;
	vec3 F=vec3(0.),Q=(gbufferModelViewInverse*vec4(0.,0.,0.,1.)).xyz;

	for(int V=0;V<GODRAYS_QUALITY;V++)
	{
		float N=float(V+noise)/float(GODRAYS_QUALITY);
		vec3 J=worldDir.xyz*E*N+Q;
		if(length(worldPos.xyz)<length(J-Q))
		{
			break;
		}
		float B,j;


		vec3 shadowProjPos=WorldPosToShadowProjPos(J.xyz,B,j);
		vec3 shadow = vec3(step(shadowProjPos.z + 1e-06, textureLod(shadowtex1, shadowProjPos.xy, 3).x));

		vec2 coord = J.xz / 50.0;
		coord.xy -= J.y / 50.0;

		coord = mod(coord, vec2(1.0));

		float texelScale = 4.0;

		//to fix color error with GL_CLAMP
		coord.x = coord.x * ((viewWidth - 1 * texelScale) / viewWidth) + ((0.5 * texelScale) / viewWidth);
		coord.y = coord.y * ((viewHeight - 1 * texelScale) / viewHeight) + ((0.5 * texelScale) / viewHeight);


		F+=shadow * pow(CalculateWaterCaustics(J),3.0) * pow(saturate(1.0 - N), 0.2);
	}

	vec3 lightVector = refract(worldLightVector, vec3(0.0, -1.0, 0.0), 1.0 / 1.2);

	float I=dot(lightVector,worldDir.xyz);

	float q = 0.5/(max(0.0, pow(lightVector.y, 2.0) * 2.0) + 0.4);

	float j=I*I,u=PhaseMie(.8,I,j);

	u=pow(u,1.5) * GODRAYS_STRENGTH;


	vec3 godRays = F * colorSunlight * 0.02 * u * q * E * vec3(0.1, 0.5, 1.0);

	#ifdef VOLUMETRIC_CLOUDS
		#ifdef CLOUD_SHADOW
			godRays*=mix(fma(globalCloudShadow, 0.9, 0.1), fma(globalCloudShadow, 0.7, 0.3), wetness);
		#endif
	#endif

	color += godRays;

}
