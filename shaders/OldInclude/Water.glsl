/***************************************************************************************
	"Seascape" by Alexander Alekseev aka TDM - 2014
	License Creative Commons Attribution-NonCommercial-ShareAlike 3.0 Unported License.
	Contact: tdmaav@gmail.com
	Website: https://www.shadertoy.com/view/4lKSzh
***************************************************************************************/
const int ITER_GEOMETRY = 1;
const int ITER_FRAGMENT = 3;

#ifdef composite1
const float SEA_HEIGHT = 0.375;
const float SEA_CHOPPY = 5.5;
#else
const float SEA_HEIGHT = 0.5;
const float SEA_CHOPPY = 4.5;
#endif
const float SEA_SPEED = 0.865;  //Default: 0.825
const float SEA_FREQ = 0.21;  //Default: 0.2

const mat2 wavesCoord = mat2(1.5, 1.1, -1.6, 1.5);


float hash(vec2 p){
	float h = dot(p, vec2(127.1, 311.7));
	return fract(sin(h) * 43758.5453123);
}

float GetWavesNoise(in vec2 coord) {
	vec2 i = floor(coord);
	vec2 f = fract(coord);
	vec2 u = f * f * fma(f, vec2(-2.0f), vec2(3.0f));
	return fma(mix(mix(hash(i + vec2(0.0, 0.0)), hash(i + vec2(1.0, 0.0)), u.x),
				   mix(hash(i + vec2(0.0, 1.0)), hash(i + vec2(1.0, 1.0)), u.x),
				   u.y), 2.0f, -1.0f);
}

float GetDiversificationHeight(in int getIteration, in bool isTotalHeight){
	const float averageHeight = 0.235f;
	const float wavesIteration[5] = float[5](1.365, 1.065, 0.8584, 0.745, 0.725);

	if(isTotalHeight){

		float getHeight;
		float totalHeight = 0.0f;
		float getFinalHeight = 0.0f;

		for(int amount = 0; amount < getIteration; amount++){

			float getTotalHeight = 1.0f;
			for(int decrease = 0; decrease <= amount; decrease++){
				getHeight = wavesIteration[decrease];
				totalHeight += getHeight;
				getHeight *= averageHeight;

				getTotalHeight *= getHeight;
			}

			getFinalHeight += getTotalHeight;
		}

		const float heightAmount[5] = float[5](2.0, 5.0, 9.0, 14.0, 20.0);

		getFinalHeight += totalHeight / heightAmount[getIteration - 1];
		return 1.0f / getFinalHeight;
	}else{
		return wavesIteration[getIteration - 1] * averageHeight;
	}
}

float finalHeight = GetDiversificationHeight(ITER_FRAGMENT, true);

float SeaOctave(vec2 coord, float wavesChoppy) {
    coord += GetWavesNoise(coord);
    vec2 wv = 1.0 - abs(sin(coord));
    vec2 swv = abs(cos(coord));
    wv = mix(wv, swv, wv);
    return pow(1.0 - pow(wv.x * wv.y, 0.65), wavesChoppy);
}
float LakeOctave(vec2 coord, float wavesChoppy) {
	coord += GetWavesNoise(coord);
	float wv = 1.0 - sin(coord.x);
	float swv = cos(1.0 - coord.y);
	return wv * swv * wavesChoppy * 0.7f;
}









float GetWaves(vec3 pos){
	float freq = SEA_FREQ;
	float wavesHeight = fma(wetness, 0.1f, SEA_HEIGHT);
	float wavesChoppy = SEA_CHOPPY;
	vec2 coord = pos.xz;
		 coord.x *= 0.75;

	float wavesTime = frameTimeCounter * SEA_SPEED;

	float d, h = 0.0f;
	for(int i = 0; i < ITER_GEOMETRY; i++){
		d = SeaOctave((coord + wavesTime) * freq, wavesChoppy);
		d += SeaOctave((coord - wavesTime) * freq, wavesChoppy);
		h += d * wavesHeight;

		coord *= wavesCoord;
		freq *= 2.05;    //Default: 1.9

		wavesHeight *= GetDiversificationHeight(i + 1, false);
		wavesTime *= 1.375f;

		wavesChoppy /= 1.25f;
		//wavesChoppy = mix(wavesChoppy, 1.0, 0.2);
	}

	return h * finalHeight;
}

float GetWavesDetailed(vec3 pos){
	float freq = SEA_FREQ;
	float wavesHeight = fma(wetness, 0.1f, SEA_HEIGHT);
	float wavesChoppy = SEA_CHOPPY;
	vec2 coord = pos.xz;
		 coord.x *= 0.75;

	float wavesTime = frameTimeCounter * SEA_SPEED;

	float d, h = 0.0f;
	for(int i = 0; i < ITER_FRAGMENT; i++){
		d = SeaOctave((coord + wavesTime) * freq, wavesChoppy);
		d += SeaOctave((coord - wavesTime) * freq, wavesChoppy);
		h += d * wavesHeight;

		coord *= wavesCoord;
		freq *= 2.05;    //Default: 1.9

		wavesHeight *= GetDiversificationHeight(i + 1, false);
		wavesTime *= 1.375f;

		wavesChoppy /= 1.25f;
			//wavesChoppy = mix(wavesChoppy, 1.0, 0.2);
	}
	if(isEyeInWater > 0) return (pos.y - h) * finalHeight;
	else                 return h * finalHeight;
}
