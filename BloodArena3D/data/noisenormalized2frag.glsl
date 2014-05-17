#ifdef GL_ES
precision mediump float;
#endif

varying vec4 vertColor;
varying vec4 vertTexCoord;

uniform sampler2D texture;

uniform float time;
uniform vec2 resolution;
uniform float alpha;
uniform float floor;
uniform float ceil;
uniform float frequency;

float noise(vec2 n);
float rand(vec2 n);

void main( void ) {

	vec2 position = ( gl_FragCoord.xy / resolution.xy );

	vec4 dry = texture2D(texture, vertTexCoord.st);// * vertColor;

	float noise = rand( vec2(position.x + time, position.y + time) );

	float norm = distance(dry.xyz, vec3(0.0));

	if (norm >= ceil) {norm = 1.0;}
	if (norm < floor) {discard;} //{norm = 0.0;}

	gl_FragColor = vec4( vec3( norm ) * vec3( noise ) * vertColor.xyz, alpha);

}

float noise(vec2 n) {
	const vec2 d = vec2(0.0, 1.0);
	vec2 b = floor(n); //integer part
    vec2 f = smoothstep(vec2(0.0), vec2(1.0), fract(n)); //smoothed fractional part between 0 and 1
	return mix( mix(rand(b), rand(b + d.yx), f.x), mix(rand(b + d.xy), rand(b + d.yy), f.x), f.y); //d is just (0, 1)
}

float rand(vec2 n) {
	return fract(cos( dot(n, vec2(12.9898, 4.1414) )) * 43758.5453);
}