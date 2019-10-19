#version 300 es
precision mediump float;

uniform vec3 u_CamPos;

in float v_Age;
in float v_Life;
in vec3 v_Position;

out vec4 o_FragColor;

/* From http://iquilezles.org/www/articles/palettes/palettes.htm */
vec3 palette( in float t, in vec3 a, in vec3 b, in vec3 c, in vec3 d )
{  return a + b*cos( 6.28318*(c*t+d) ); }

void main() {
  float t =  v_Age /v_Life;
  float distanceToCamera = distance(v_Position, u_CamPos);
  o_FragColor = vec4( palette(t,
            vec3(0.5,0.5,0.5),
            vec3(0.5,0.5,0.5),
            vec3(0.5,  0.7,1.0),
            vec3(0.0,0.15,0.20)), (1.0 -  t) / ( distanceToCamera / 10.0));

}