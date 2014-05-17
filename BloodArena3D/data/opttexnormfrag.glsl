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
uniform vec2 texres;
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


void main(void)
{
	vec3 filtered = vec3(0.0);
    
	vec2 position = ( gl_FragCoord.xy / resolution.xy );
	vec2 m = ( mouse.xy / resolution.xy );

	float noize = cos(position.x*1000.0+cos(position.y*489.9+time+position.x*50.0)*1450.0); //range is -1 - 1

    //mix with clouds
	vec3 dry = texture2D(texture, vertTexCoord.st).xyz * vertColor.xyz;
    	vec3 cloudcolor = clouds(position, cover, sharpness);
    	vec3 mixed = mix(dry, cloudcolor, mix);
	float norm = distance(mixed.xyz, vec3(0.0));

	if (norm <= floor)
	{
		discard;
	}
	else
	{
		filtered = vec3(norm) * vec3(noize) * color;
	}
    

	gl_FragColor = vec4(filtered, alpha);
}

vec3 clouds(vec2 ipos, float icover, float isharpness)
{
	
	// Set up domain
	vec2 q = ipos;
	vec2 p = -1.0 + 5.0 * q; //increasing the number we multiply by makes denser, smaller clouds, "zoomed-out"
	
	// Fix aspect ratio
	p.x *= resolution.x / resolution.y;
    
	// Create noise using fBm
	float f = fbm( 1.0*p );
	
	float c = f - (1.0 - icover);
	if ( c < 0.0 ) { c = 0.0; }
	
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
	return fract(sin(n)*43758.5453); //this is 0-1
}



/*
float rand(vec2 co){
    return fract(sin(dot(co.xy ,vec2(12.9898,78.233))) * 43758.5453);
}
*/