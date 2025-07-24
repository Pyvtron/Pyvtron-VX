#version 450 compatibility

#define TORCHLIGHT_COLOR_TEMPERATURE 3000 // Color temperature of torch light in Kelvin. [2000 2300 2500 3000 5000 999]

uniform float frameTimeCounter;
uniform int worldTime;

out vec4 texcoord;
out vec3 colorTorchlight;

#include "/OldInclude/RGB.glsl"


void main() {
	gl_Position = ftransform();
	texcoord = gl_MultiTexCoord0;

	//Torchlight color
	if(TORCHLIGHT_COLOR_TEMPERATURE == 2000)      colorTorchlight = pow(vec3(255, 141,  11) / 255.0, vec3(2.2)); //2000k
	else if(TORCHLIGHT_COLOR_TEMPERATURE == 2300) colorTorchlight = pow(vec3(255, 152,  54) / 255.0, vec3(2.2)); //2300k
	else if(TORCHLIGHT_COLOR_TEMPERATURE == 2500) colorTorchlight = pow(vec3(255, 166,  69) / 255.0, vec3(2.2)); //2500k
	else if(TORCHLIGHT_COLOR_TEMPERATURE == 3000) colorTorchlight = pow(vec3(255, 180, 107) / 255.0, vec3(2.2)); //3000k
	else if(TORCHLIGHT_COLOR_TEMPERATURE == 5000) colorTorchlight = pow(vec3(1.0f)                 , vec3(2.2)); //5000k
	else                                          colorTorchlight = pow(RGBcircling(frameTimeCounter, 360.0, 0.0, 50.0), vec3(2.2));

}
