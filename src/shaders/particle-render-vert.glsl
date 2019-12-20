#version 300 es
precision mediump float;

uniform mat4 u_ViewProj;
uniform vec3 u_CamPos;
uniform float u_SphereCollider;

in vec3 i_Position;
in float i_Age;
in float i_Life;
in vec3 i_Velocity;


out vec3 v_Position;
out float v_Age;
out float v_Life;
out vec3 v_Velocity;


void main() {
  v_Position = i_Position;

  v_Age = i_Age;
  v_Life = i_Life;

  gl_Position =  u_ViewProj * vec4(i_Position, 1.0);

  float distanceToCamera = distance(vec3(u_ViewProj * vec4(i_Position, 1.0)), u_CamPos);
  gl_PointSize = (0.5 + 6.0 * (1.0 - 1.6 * i_Age/i_Life)) / ( distanceToCamera / 10.0);
  
  // // points on sphere
  // if (v_Age == -0.1) {
  //   gl_PointSize = (0.5 + 4.0 * (1.0 - 1.6 * i_Age/i_Life)) / ( distanceToCamera / 10.0);
  
  // }

  if (v_Age == 3.0) {
        gl_PointSize = (0.5 + 9.0 * (1.0 - 1.6 * 0.1)) / ( distanceToCamera / 10.0);
  }
  if (v_Age == 4.0) {
        gl_PointSize = (0.5 + 9.0 * (1.0 - 1.6 * 0.1)) / ( distanceToCamera / 10.0);
  }

  if (v_Age > 2.0 && u_SphereCollider == 0.0) {


      gl_PointSize = 0.0;
  }
}