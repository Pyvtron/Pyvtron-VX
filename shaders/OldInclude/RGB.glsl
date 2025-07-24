


vec3 RGBcircling(float time, float phaseDiff, float rndfactor, float speed)
{
	time *= speed;
	time += phaseDiff * 3.0f * rndfactor;

	float timeR = clamp(abs(mod(time, 						phaseDiff * 3.0f) - phaseDiff * 1.5f) ,0.0f, 180.0f);
	float timeG = clamp(abs(mod(time + phaseDiff, 			phaseDiff * 3.0f) - phaseDiff * 1.5f) ,0.0f, 180.0f);
	float timeB = clamp(abs(mod(time + phaseDiff * 2.0f, 	phaseDiff * 3.0f) - phaseDiff * 1.5f) ,0.0f, 180.0f);

	vec3 RGB = vec3(cos(radians(timeR)), cos(radians(timeG)), cos(radians(timeB)));

	return RGB * 0.5 + 0.5;
}


/*
vec3 RGBflicker(vec3 color, bool worldtime, float rndfactor, float speed, float flickerstrength, bool smoothflicker){

	float lightstrength = 1.0;
	float time = 0.0;
	if (worldtime)
		time = worldTime;
	else
		time = frameTimeCounter * 128;

	if (smoothflicker){
		lightstrength+= (1.0 + sin(time * (speed * 0.03 + 6.2832 * rndfactor))) * flickerstrength / 2.0;
	}
	else{
		time = mod(time * speed + 40.0f * rndfactor, 40.0f);

		if     (time <= 20.0){lightstrength+= (0.05 * time + 0.7)  * flickerstrength;}
		else if(time > 20.0) {lightstrength+= (-0.05 * time + 2.7) * flickerstrength;}
	}

	return color * lightstrength;
}
*/
