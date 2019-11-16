#version 300 es
precision highp float;

uniform vec3 u_CamPos;

uniform vec3 u_Ref, u_Up;
uniform vec2 u_Dimensions;
uniform float u_Time;

in vec2 fs_Pos;
out vec4 out_Col;

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

  vec3 p = u_Ref + fs_Pos.x * h + fs_Pos.y * v;
  vec3 dir = normalize(p - u_CamPos);

  return dir;

}

bool hit_sphere(vec3 center, float radius, vec3 dir){
    vec3 oc = u_CamPos - center;
    float a = dot(dir, dir);
    float b = 2.0 * dot(oc, dir);
    float c = dot(oc,oc) - radius*radius;
    float discriminant = b*b - 4.0*a*c;
    return (discriminant>0.0);
}

void main() {
  vec3 dir = getRayDirection();
  if (hit_sphere(vec3(3.0, 0, 0), 1.0, dir)){
    out_Col = vec4(0.0, 0.0, 0.0, 1.0);
  }
  else {
    out_Col = vec4(0.0, 0.0, 0.0, 1.0);
  }
  
  out_Col =  0.4 * vec4((dir + vec3(1.0, 1.0, 1.0)), 1.0);
  //out_Col = vec4(0.5 * (fs_Pos + vec2(1.0)), 0.5 * (sin(u_Time * 3.14159 * 0.01) + 1.0), 1.0);
}
