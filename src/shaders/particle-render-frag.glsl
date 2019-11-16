#version 300 es
precision mediump float;

uniform vec3 u_CamPos;

uniform vec3 u_Ref, u_Up;
uniform vec2 u_Dimensions;

in float v_Age;
in float v_Life;
in vec3 v_Position;
in vec3 v_Velocity;

out vec4 o_FragColor;

/* From http://iquilezles.org/www/articles/palettes/palettes.htm */
vec3 palette( in float t, in vec3 a, in vec3 b, in vec3 c, in vec3 d )
{  return a + b*cos( 6.28318*(c*t+d) ); }

// this is a helper function for raycasting
vec3 getRayDirection() {

  float fovy = 45.0;
  vec3 look = normalize(u_Ref - u_CamPos);
  vec3 right = normalize(cross(look, u_Up));
  vec3 up = cross(right, look);

  float tan_fovy = tan(radians(fovy / 2.0));
  float len = length(u_Ref - u_CamPos);
  float aspect = u_Dimensions.x / float(u_Dimensions.y);

  vec3 v = up * len * tan_fovy;
  vec3 h = right * len * aspect * tan_fovy;

  vec2 fragCoords = gl_FragCoord.xy / u_Dimensions;
  vec3 p = u_Ref + fragCoords.x * h + fragCoords.y * v;
  vec3 dir = normalize(p - u_CamPos);

  return dir;

}

float hit_sphere(vec3 center, float radius, vec3 dir){
    vec3 oc = u_CamPos - center;
    float a = dot(dir, dir);
    float b = 2.0 * dot(oc, dir);
    float c = dot(oc,oc) - radius*radius;
    float discriminant = b*b - 4.0*a*c;
    if(discriminant < 0.0){
        return -1.0;
    }
    else{
        return (-b - sqrt(discriminant)) / (2.0*a);
    }
}


void main() {
  // vec3 dir = getRayDirection();
  // float x = hit_sphere(vec3(3.0, 0, 0), 1.0, dir);
  // vec3 intersection_point = u_CamPos + x * dir;

  // float distToSphere = distance(intersection_point, u_CamPos);
  float distanceToCamera = distance(v_Position, u_CamPos);
  // if (distToSphere < distanceToCamera) {

  // o_FragColor = vec4(0.0, 1.0, 0.0, 1.0);
  // } 
  // else {
  	 float t =  v_Age /v_Life;
  	 
  	 o_FragColor = vec4( palette(t,
            vec3(0.5,0.5,0.5),
            vec3(0.5,0.5,0.5),
            vec3(0.5,  0.7,1.0),
            vec3(0.0,0.15,0.20)), (1.0 -  t) / ( distanceToCamera / 10.0));

      // renders the sphere a different color
      if (v_Age == -0.1) {
        o_FragColor = vec4(0, 1, 0, 1);
      }

  //}
 
}