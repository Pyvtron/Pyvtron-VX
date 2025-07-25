mat2 mm2(in float a){float c = cos(a), s = sin(a);return mat2(c,s,-s,c);}
mat2 m2 = mat2(0.95534, 0.29552, -0.29552, 0.95534);
float tri(in float x){return clamp(abs(fract(x)-.5),0.01,0.49);}
vec2 tri2(in vec2 p){return vec2(tri(p.x)+tri(p.y),tri(p.y+tri(p.x)));}



float triNoise2d(in vec2 p, float spd)
{
    float z=1.8;
    float z2=2.5;
	float rz = 0.;
    p *= mm2(p.x*0.06);
    vec2 bp = p;
	for (float i=0.; i<5.; i++ )
	{
        vec2 dg = tri2(bp*1.85)*.75;
        dg *= mm2(frameTimeCounter*spd);
        p -= dg/z2;

        bp *= 1.3;
        z2 *= .45;
        z *= .42;
		p *= 1.21 + (rz-1.0)*.02;
        
        rz += tri(p.x+tri(p.y))*z;
        p*= -m2;
	}
    return clamp(1./pow(rz*29., 1.3),0.,.55);
}

float hash21(in vec2 n){ return fract(sin(dot(n, vec2(12.9898, 4.1414))) * 43758.5453); }


vec4 aurora(vec3 ro, vec3 rd)
{
    vec4 col = vec4(0);
    vec4 avgCol = vec4(0);
    
    for(float i=0.;i<50.;i++)
    {
        float of = 0.006*hash21(gl_FragCoord.xy)*smoothstep(0.,15., i);
        float pt = ((.8+pow(i,1.4)*.002)-ro.y)/(rd.y*2.+0.4);
        pt -= of;
    	vec3 bpos = ro + pt*rd;
        vec2 p = bpos.zx;
		
        float rzt = triNoise2d(p, 0.1883);
		
        vec4 col2 = vec4(0,0,0, rzt);
        col2.rgb = (sin(1.-vec3(2.15,-.5, 1.2)+i*0.043)*0.5+0.5)*rzt;
        avgCol =  mix(avgCol, col2, .5);
        col += avgCol*exp2(-i*0.065 - 2.5)*smoothstep(0.,5., i);
        
    }
   
    col *= (clamp(rd.y*15.+.4,0.,1.));
    
    return col*1.8;
}

void NightAurora(inout vec3 color,vec3 fposition)
{
    vec3 sVector = normalize(fposition);
	
    float cosT = dot(sVector,upVector);
	vec3 upVec = normalize(upPosition);
    vec3 tpos = vec3(gbufferModelViewInverse * vec4(fposition,1.0));

    vec3 wVector = normalize(tpos);
    vec3 intersection = wVector*(50.0/(wVector.y));
         intersection *= mix(1.0, cosT, 0.70 - cosT);
	vec2 wind = vec2(abs(frameTimeCounter/10.-0.5),abs(frameTimeCounter/10.-0.5));
	intersection.xz = intersection.xz*40. + 5.0*cosT*intersection.xz;
	vec3 iSpos = (gbufferModelView*vec4(intersection,1.0)).rgb;
	float cosT2 = max(dot(normalize(iSpos),upVec),0.0);

	float position = dot(normalize(fposition.xyz), upPosition);
	float horizonPos = max(1.0 - abs(position) * 0.03, 0.0);

	float horizonBorder = min((1.0 - clamp(position + length(position), 0.0, 1.0)) + horizonPos, 1.0);
	
	vec3 col = vec3(0.);
    vec3 ro = vec3(0,0,0);
    vec3 rd = intersection/12392.0f;
    vec3 brd = rd;
    float fade = smoothstep(0.,0.01,abs(brd.y))*0.1+0.9;
	
    vec4 aur = smoothstep(0.,1.5,aurora(ro,rd))*fade;
	
         col = col*(1.-aur.a) + aur.rgb * pow(cosT2, 0.18) * (1.0 - horizonBorder);
		 
		 col = pow(col, vec3(1.5)) * 2.0;
   
	color += col * 0.4 * AURORA_STRENGTH * timeMidnight * (1-wetness * 0.75);
}
