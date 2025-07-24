


//Shadow-------------------------
	#define SHADOW_MAP_BIAS			0.9	// [0.0 0.1 0.7 0.75 0.8 0.85 0.9 0.92 0.94 0.96]

	#define VARIABLE_PENUMBRA_SHADOWS
	#define COLORED_SHADOWS

	#define SCREEN_SPACE_SHADOWS

	#define CAUSTICS

//GI------------------------------
  //#define GI

	#define ENABLE_SSAO

	#define GI_QUALITY				0.5	// [0.5 1.0 2.0 3.0 4.0 5.0 6.0 7.0 8.0 9.0 10.0 12.0 14.0 16.0 18.0 20.0 25.0 30.0 35.0 40.0 50.0 60.0 70.0 80.0]
	#define GI_RADIUS				1.5 // [0.5 0.75 1.0 1.15 1.25 1.5 1.75 2.0 3.0 5.0 7.0 10.0 15.0 20.0 30.0 50.0]
	#define GI_SATURATION			0.9 // [0.0 0.1 0.2 0.3 0.4 0.5 0.7 0.9 1.1 1.3 1.5 1.7 1.9 2.1 2.5 3.0]
	#define GI_BRIGHTNESS			500 // [100 150 200 250 300 350 400 450 500 550 600 650 700 750 800 850 900 950 1000 1500 2000 3000 4000 5000 7000 10000]

	#define GI_RENDER_RESOLUTION	1	// [1 0]
	#define GI_FILTER_QUALITY		0.5	// [0.5 1.0 1.5 2.0 2.5 3.0 3.5 4.0 4.5 5.0 5.5 6.0 6.5 7.0 7.5 8.0 8.5 9.0 9.5 10.0]

	#define SKYLIGHT_EFFECT_GI

	#define SUNLIGHT_LEAK_FIX

  //#define GI_DEBUG

//Light Misc-----------------------
	#define NOLIGHT_BRIGHTNESS				0.0006 // [0.00005 0.0006 0.001 0.002 0.003 0.005 0.007 0.01 0.015 0.02]

	#define TORCHLIGHT_FILL					4.0	// [0.5 1.0 2.0 3.0 4.0 5.0 6.0 7.0 8.0]
	#define TORCHLIGHT_BRIGHTNESS			1.0	// [0.25 0.5 1.0 2.0 3.0 4.0 5.0 7.0 10.0 15.0 20.0 30.0 50.0]

	#define TORCHLIGHT_COLOR_TEMPERATURE 	3000 // Color temperature of torch light in Kelvin. [2000 2300 2500 3000 5000 999]


	#define HELDLIGHT_BRIGHTNESS 			1.0 // [0.0 0.1 0.2 0.3 0.4 0.5 0.6 0.7 0.8 0.9 1.0 1.5 2.0 3.0 5.0 7.0 10.0 15.0 20.0 30.0 50.0 100.0]
	#define HELDLIGHT_FALLOFF 				2.0 // [1.0 1.2 1.4 1.6 1.8 2.0 2.5 3.0]
	#define NORMAL_HELDLIGHT
	#define SPECULAR_HELDLIGHT
  //#define FLASHLIGHT_HELDLIGHT
  	#define FLASHLIGHT_HELDLIGHT_FALLOFF 	1.0 // [0.0 0.1 0.2 0.3 0.4 0.5 0.6 0.7 0.8 0.9 1.0 1.2 1.4 1.6 1.8 2.0]


	#define SUNLIGHT_INTENSITY				1.0	// [0.1 0.2 0.3 0.4 0.5 0.6 0.7 0.8 0.9 1.0 1.1 1.2 1.3 1.4 1.5 1.6 1.7 1.8 1.9 2.0]

//Sky&Fog--------------------------
  //#define AURORA
	#define AURORA_STRENGTH				1.0	// [0.1 0.2 0.3 0.4 0.5 0.6 0.7 0.8 0.9 1.0 1.1 1.2 1.3 1.4 1.5 1.7 2.0 2.5 3.0 4.0 5.0 7.0 10.0 15.0 20.0 30.0 50.0 70.0 100.0]

	#define VOLUMETRIC_CLOUDS
	#define CLOUD_SHADOW

	#define RAYLEIGH_AMOUNT				1.0 // [0.0 0.02 0.04 0.06 0.08 0.1 0.2 0.3 0.5 0.75 1.0 1.5 2.0 3.0 4.0 5.0 7.5 10.0 15.0 20.0 30.0 40.0 50.0]
  //#define FADE_TO_ATMOSPHERE
  //#define INDOOR_FOG
  //#define LANDSCATTERING_TO_SKY

	#define RAIN_FOG
	#define RAIN_FOG_DENSITY		0.006	// [0.001 0.002 0.003 0.004 0.006 0.008 0.01 0.015 0.02 0.03 0.04 0.06 0.08 0.1]
	#define UNDERWATER_FOG
	#define UNDERWATER_FOG_DENSITY	0.06	// [0.001 0.002 0.003 0.004 0.006 0.008 0.01 0.015 0.02 0.03 0.04 0.06 0.08 0.1]

	#define SKY_TEXTURE_BRIGHTNESS	1.0

	#define STARS
	#define STARS_SCALE 380.0 // [150.0 200.0 250.0 300.0 320.0.0 340.0 360.0 380.0 400.0.0 420.0 440.0 460.0 480.0 500.0]
	#define STARS_AMOUNT 0.007 // [0.001 0.002 0.003 0.004 0.005 0.006 0.007 0.008 0.009]

	#define ROUND_MOON
   //#define COMPATIBLE_MODE

	#define NIGHT_BRIGHTNESS 		0.0005 // [0.0 0.0001 0.00015 0.0002 0.0003 0.0005 0.0007 0.001 0.0015 0.002 0.003 0.005 0.007 0.01 1.0]

//Texture--------------------------
	#define TEXTURE_RESOLUTION		16	// [16 32 64 128 256 512 1024 2048 4096 8192]
  //#define PARALLAX
	#define PARALLAX_SHADOW
  //#define SMOOTH_PARALLAX
	#define FORCE_WET_EFFECT
	#define RAIN_SPLASH_EFFECT
        #define RAIN_SPLASH_BILATERAL
	#define PARALLAX_DEPTH			1.0	// [0.1 0.15 0.2 0.3 0.5 0.75 1.0 1.25 1.5 1.75 2.0 3.0 5.0 7.5 10.0]
	#define PARALLAX_DISTANCE		1.0	// [0.1 0.15 0.2 0.3 0.5 0.75 1.0 1.25 1.5 1.75 2.0 3.0 5.0 7.5 10.0]

//PBR------------------------------
	#define TEXTURE_PBR_FORMAT 		0 	//[0 1]

  //#define TERRAIN_NORMAL_CLAMP
	#define HAND_NORMAL_CLAMP
	#define ENTITY_NORMAL_CLAMP

	#define ROUGHNESS_CLAMP

	#define SKY_IMAGE_LOD 2 // [0 1 2]

	#define SKY_IMAGE_HORIZON

  //#define LANDFOG_REFLECTION
  //#define VFOG_REFLECTION

//Texture Misc---------------------
	#define WATER_REFRACT_IOR		1.2

 	#define CORRECT_PARTICLE_NORMAL

	#define RAIN_VISIBILITY			1.0 // [0.0 0.1 0.2 0.3 0.4 0.5 0.6 0.7 0.8 0.9 1.0 1.1 1.2 1.3 1.4 1.5 1.6 1.7 1.8 1.9 2.0 5.0]

	#define SELECTION_BOX_COLOR		1.0		// [0.0 1.0]

	#define ENTITY_STATUS_COLOR
	#define EYES_LIGHTING

  //#define GENERAL_GRASS_FIX
	#define WAVING_PLANTS
  //#define PLANT_TOUCH_EFFECT
	#define ANIMATION_SPEED 1.0


//DOF------------------------------
  //#define DOF
	#define DOF_SAMPLES 32 				// [16 32 64 128 256 512 1024]
	#define CAMERA_FOCUS_MODE 0 		// [0 1]
	#define CAMERA_FOCAL_POINT 10.0 	// [0.2 0.3 0.4 0.6 0.8 1.0 1.25 1.5 1.75 2.0 2.5 3.0 3.5 4.0 5.0 6.0 8.0 10.0 12.5 15.0 17.5 20.0 15.0 30.0 40.0 50.0 60.0 80.0 100.0 150.0 200.0 250.0 300.0 400.0 500.0 600.0 800.0 1000.0]
	#define CAMERA_AUTO_FOCAL_OFFSET 0 	//[-16 -15 -14 -13 -12 -11 -10 -9 -8 -7 -6 -5 -4.5 -4 -3.5 -3 -2.5 -2 -1.5 -1 -0.5 0 0.5 1 1.5 2 2.5 3 3.5 4 4.5 5 6 7 8 9 10 11 12 13 14 15 16]

	#define CAMERA_APERTURE 2.8 // [0.95 1.2 1.4 1.8 2.8 4 5.6 8.0 11.0 16.0 22.0]
	#define DISTORTION_BARREL 0.0 // [0.0 10.0 20.0]


//Bloom----------------------------
	#define BLOOM_EFFECTS

	#define BLOOM_AMOUNT			0.1	// [0.1 0.2 0.3 0.4 0.5 0.6 0.7 0.8 0.9 1.0 1.1 1.2 1.3 1.4 1.5 1.6 1.7 1.8 1.9 2.0 3.0 4.0 5.0 7.0 10.0 15.0 20.0 30.0 50.0]
	#define BLOOM_KB
  //#define BLOOM_DB
	#define BLOOM_DB_MULTIPLIER		1.5	// [0.5 0.7 1.0 1.5 2.0 3.0 4.0 5.0 7.0 10.0 15.0 20.0 30.0 50.0]

  //#define MICRO_BLOOM

//TAA------------------------------
	#define TAA

	#define TAA_AGGRESSION 			0.97
	#define TAA_SHARPEN
	#define TAA_SHARPNESS 			0.3     //[0.05 0.1 0.15 0.2 0.25 0.3 0.35 0.4 0.45 0.5 0.55 0.6 0.65 0.7 0.75 0.8 0.85 0.9 0.95 1.0]

//Motion Blur----------------------

	#define MOTION_BLUR
	#define MOTION_BLUR_DITHER
        #define MOTION_BLUR_STRENGTH 1.0 // [1.0 1.1 1.2 1.3 1.4 1.5 1.6 1.7 1.8 1.9 2.0 2.2 2.4 2.6 2.8 3.0]
	#define MOTION_BLUR_QUALITY 3 // [2 3 5 10 20 30 50 100]
	#define MOTION_BLUR_SUTTER_ANGLE 180.0 // [45.0 90.0 135.0 180.0 270.0 360.0]

//Post-----------------------------
	#define TONEMAP_OPERATOR 	Default // Each tonemap operator defines a different way to present the raw internal HDR color information to a color range that fits nicely with the limited range of monitors/displays. Each operator gives a different feel to the overall final image. [Default SEUSTonemap LottesTonemap UchimuraTonemap HableTonemap ACESTonemap ACESTonemap2 None]
	#define TONEMAP_CURVE 		1.0 // Controls the intensity of highlights. Lower values give a more filmic look, higher values give a more vibrant/natural look. Default: 2.0 [0.1 0.2 0.3 0.4 0.5 0.6 0.7 0.75 0.8 0.85 0.9 0.95 1.0 1.05 1.1 1.15 1.2 1.25 1.3 1.4 1.5 1.6 1.7 1.8 1.9 2.0 3.0 5.0]

  //#define MANUAL_EXPOSURE
	#define EV_VALUE 	14 		// [4 4+1.0/3.0 4+2.0/3.0 5 5+1.0/3.0 5+2.0/3.0 6 6+1.0/3.0 6+2.0/3.0 7 7+1.0/3.0 7+2.0/3.0 8 8+1.0/3.0 8+2.0/3.0 9 9+1.0/3.0 9+2.0/3.0 10 10+1.0/3.0 10+2.0/3.0 11 11+1.0/3.0 11+2.0/3.0 12 12+1.0/3.0 12+2.0/3.0 13+1.0/3.0 13+2.0/3.0 14 14+1.0/3.0 14+2.0/3.0 15 15+1.0/3.0 15+2.0/3.0 16 16+1.0/3.0 16+2.0/3.0 17 17+1.0/3.0 17+2.0/3.0 18 18+1.0/3.0 18+2.0/3.0 19 19+1.0/3.0 19+2.0/3.0 20]
	#define AE_OFFSET	0 		// [-5 -4-2.0/3.0 -4-1.0/3.0 -4 -3-2.0/3.0 -3-1.0/3.0 -3 -2-2.0/3.0 -2-1.0/3.0 -2 -1-2.0/3.0 -1-1.0/3.0 -1 -2.0/3.0 -1.0/3.0 0 1/3 2/3 1 1+1.0/3.0 1+2.0/3.0 2 2+1.0/3.0 2+2.0/3.0 3 3+1.0/3.0 3+2.0/3.0 4 4+1.0/3.0 4+2.0/3.0 5]
	#define AE_MODE		0 		// [0 1 2]
	#define AE_CURVE	0.6 	// [0.0 0.05 0.1 0.15 0.2 0.25 0.3 0.35 0.4 0.45 0.5 0.55 0.6 0.65 0.7 0.75 0.8 0.85 0.9 0.95 1.0]
  //#define LUMINANCE_WEIGHT
	#define LUMINANCE_WEIGHT_MODE 		0 	// [0 1]
	#define LUMINANCE_WEIGHT_STRENGTH 	0.7 // [0.5 0.7 1.0 1.5 2.0]

	#define SMOOTH_EXPOSURE
	#define EXPOSURE_TIME 	1.0 // [0.1 0.2 0.3 0.4 0.5 0.6 0.7 0.8 0.9 1.0 1.2 1.4 1.6 1.8 2.0]

  //#define ADVANCED_COLOR

	#define GAMMA 				1.0 // Gamma adjust. Lower values make shadows darker. Higher values make shadows brighter. Default: 1.0 [0.5 0.55 0.6 0.65 0.7 0.75 0.8 0.85 0.9 0.95 1.0 1.05 1.1 1.15 1.2 1.25 1.3 1.35 1.4 1.45 1.5]
	#define LUMA_GAMMA 			1.0 // Gamma adjust of luminance only. Preserves colors while adjusting contrast. Lower values make shadows darker. Higher values make shadows brighter. Default: 1.0 [0.5 0.55 0.6 0.65 0.7 0.75 0.8 0.85 0.9 0.95 1.0 1.05 1.1 1.15 1.2 1.25 1.3 1.35 1.4 1.45 1.5]
	#define SATURATION 			1.0 // Saturation adjust. Higher values give a more colorful image. Default: 1.0 [0.5 0.6 0.7 0.8 0.9 1.0 1.1 1.2 1.3 1.4 1.5]
	#define WHITE_CLIP 			0.0 // Higher values will introduce clipping to white on the highlights of the image. [0.0 0.05 0.1 0.15 0.2 0.25 0.3 0.35 0.4 0.45 0.5]

	#define WHITE_BALANCE 		6500 // [4000 4100 4200 4300 4400 4500 4600 4700 4800 4900 5000 5100 5200 5300 5400 5500 5600 5700 5800 5900 6000 6100 6200 6300 6400 6500 6600 6700 6800 6900 7000 7100 7200 7300 7400 7500 7600 7700 7800 7900 8000 8100 8200 8300 8400 8500 8600 8700 8800 8900 9000 9100 9200 9300 9400 9500 9600 9700 9800 9900 10000 10100 10200 10300 10400 10500 10600 10700 10800 10900 11000 11100 11200 11300 11400 11500 11600 11700 11800 11900 12000]
	#define TINT_BALANCE 		0.0 // [-1.0 -0.95 -0.9 -0.85 -0.8 -0.75 -0.7 -0.65 -0.6 -0.55 -0.5 -0.45 -0.4 -0.35 -0.3 -0.25 -0.2 -0.15 -0.1 -0.05 0.0 0.05 0.1 0.15 0.2 0.25 0.3 0.35 0.4 0.45 0.5 0.55 0.6 0.65 0.7 0.75 0.8 0.85 0.9 0.95 1.0]

	#define POST_SHARPENING 	1 //[0 1 2 3]

  //#define LOWLIGHT_COLORFADE

	#define BOOT_INFORMATION
  //#define LUT

//Debug----------------------------
  //#define WHITE_DEBUG_WORLD
  #define SELECTION_BOX_COLOR		1.0	// [0.0 1.0]

//Lens Flare----------------------

#define LENS_FLARE
#define LENS_FLARE_BLUR_SAMPLES 5 // [1 2 3 4 5 6 7 8 9 10]
#define GHOST_FLARE_SPACING_MULT 0.6 // [0.1 0.2 0.3 0.4 0.5 0.6 0.7 0.8 0.9 1.0 1.1 1.2 1.3 1.4 1.5 1.5 1.6 1.7 1.8 1.9 2.0]
#define HALO_FLARE_SPACING_MULT 0.20 // [0.01 0.02 0.03 0.04 0.05 0.06 0.07 0.08 0.09 0.10 0.11 0.12 0.13 0.14 0.15 0.16 0.17 0.18 0.19 0.20]
#define LENS_FLARE_SAMPLES 3 // [1 2 3 4 5 6 7 8 9 10]
#define LENS_FLARE_THRESHOLD 0.19 // [0.11 0.12 0.13 0.14 0.15 0.16 0.17 0.18 0.19 0.20 0.21 0.22 0.23 0.24 0.25 0.26 0.27 0.28 0.29 0.30]
#define LENS_FLARE_STRENGTH 0.005 // [0.001 0.002 0.003 0.004 0.005 0.006 0.007 0.008 0.009 0.010 0.020 0.030 0.040 0.050]
