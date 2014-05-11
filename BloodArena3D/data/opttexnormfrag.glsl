//intention here is to get the quick-and-dirty range of brightness in a texture
//and use that information to dissolve an image, using that texture as a map.
//this would be done by adjusting the floor, and/or mixing between the two textures.
//one could replace brightness with another parameter like luminance, by changing only the check
//one could apply the dissolve based on the params of one texture, or of the mix between the two.
//here I do the latter
//right now, I don't know multitexturing (and it ain't in processing) so I use a procedurally-generated cloud texture from glsl.heroku
//IDEAS: average, standard deviation, luminance, any color

varying vec4 vertColor;
varying vec4 vertTexCoord;

uniform sampler2D texture;

uniform vec2 resolution;
uniform float time;
uniform vec2 mouse;

uniform float alpha;

uniform float floor;
uniform float ceil;

uniform float mix;
uniform float periods;
uniform float rate;

uniform float cover; //.6 //clouds v. black
uniform float sharpness; //.003 //at 0 this is just black and white

uniform vec3 color;

float noise( in vec2 x );
float fbm( vec2 p );
float hash( float n );
vec3 clouds(vec2 ipos, float icover, float isharpness);

float getSmallestNorm(sampler2D itex, vec2 ires);
float getLargestNorm(sampler2D itex, vec2 ires);
//float getAverageNormal //just a thought for funsies

void main(void)
{
	vec3 filtereded;

	vec2 pos = ( gl_FragCoord.xy / resolution.xy );
	vec2 m = ( mouse.xy / resolution.xy );

    //mix with clouds
	vec3 dry = texture2D(texture, vertTexCoord.st).xyz * vertColor.xyz;
    vec3 cloudcolor = clouds(pos, cover, sharpness);
    vec3 mixed = mix(dry, cloudcolor, mix);

    //white in resulting mix.
	float norm = distance(mixed.xyz, vec3(0.0));
	
	if (norm < floor) { discard; }
	else if (norm >= ceil) { norm = 1.0; }
    
	if ( d > circle_radius )
	{
		filtered = vec3(norm) * vec3(noise);
	}
	
	else if ( d < (circle_radius - border))
	{
        filtered = vec3(norm) * vec3(noise);
	}

	else if (r >= .5)
	{
		filtered = vec3(norm) * vec3(noise) * color;
	}
    
    else
    {
        discard;
    }

	gl_FragColor = vec4(filtered, alpha);

}

vec3 clouds(vec2 ipos, float icover, float isharpness)
{
// Wind - Used to animate the clouds
	vec2 wind_vec = vec2(0.001 + time*0.1, 0.003 + time * 0.1);
	
	// Set up domain
	vec2 q = ipos;
	vec2 p = -1.0 + 5.0 * q + wind_vec;
	
	// Fix aspect ratio
	p.x *= resolution.x / resolution.y;
    
	
	// Create noise using fBm
	float f = fbm( 1.0*p );
	
	float c = f - (1.0 - icover);
	if ( c < 0.0 )
		c = 0.0;
	
	f = 1.0 - (pow(isharpness, c));
	
    
	return vec3(f);
}

float noise( in vec2 x )
{
	vec2 p = floor(x);
	vec2 f = fract(x);
    f = f*f*(3.0-2.0*f);
    float n = p.x + p.y*57.0;
    float res = mix(mix( hash(n+  0.0), hash(n+  1.0),f.x), mix( hash(n+ 57.0), hash(n+ 58.0),f.x),f.y);
    return res;
}

float fbm( vec2 p )
{
    float f = 0.0;
    f += 0.50000*noise( p ); p = p*2.02;
    f += 0.25000*noise( p+time ); p = p*2.03;
    f += 0.12500*noise( p+time/2.0 ); p = p*2.01;
    f += 0.06250*noise( p); p = p*2.04;
    f += 0.03125*noise( p );
    return f/0.984375;
}

float hash( float n )
{
	return fract(sin(n)*43758.5453);
}

float getSmallestNorm(sampler2D itex, vec2 ires)
{
    
    float snm = 0.0;
    
    for (int i = 0; i <= ires.y; i++)
    {
        for (int ii = 0; ii < ires.x; ii++)
        {
            vec2 coor = vec2(i, ii);
            vec3 tex = texture2D(itex, coor);
            nm = distance(itex, vec3(0.0, 0.0, 0.0)) //replace this to moodify for luminance or saturation or whatever else
            if (nm < snm) { snm = nm; }
        }
    }
    
    return snm;
}

float getLargestNorm(sampler2D itex, vec2 ires)
{
    float lnm = 1.0;
    
    for (int i = 0; i <= ires.y; i++)
    {
        for (int ii = 0; ii < ires.x; ii++)
        {
            vec2 coor = vec2(i, ii);
            vec3 tex = texture2D(itex, coor);
            nm = distance(itex, vec3(0.0, 0.0, 0.0)) //replace this to moodify for luminance or saturation or whatever else
            if (nm > lnm) { lnm = nm; }
        }
    }
    
    return lnm;
}

/*
float rand(vec2 co){
    return fract(sin(dot(co.xy ,vec2(12.9898,78.233))) * 43758.5453);
}
*/