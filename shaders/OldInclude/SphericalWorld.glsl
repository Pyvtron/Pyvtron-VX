//#define SPHERICAL_WORLD
#define RADIUS 200//[50 75 100 150 200 300 500 1000 1500 2000]
#ifdef SPHERICAL_WORLD
	vec4 positionW = gbufferModelViewInverse * gl_ModelViewMatrix * gl_Vertex;
	float distance2D = positionW.x * positionW.x + positionW.z * positionW.z;
	positionW.y += sqrt(RADIUS * RADIUS - distance2D) - RADIUS;
	gl_Position = gl_ProjectionMatrix * gbufferModelView * positionW;
#endif
