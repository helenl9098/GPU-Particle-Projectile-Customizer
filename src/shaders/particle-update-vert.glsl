#version 300 es
precision mediump float;

#define M_PI 3.1415926535897932384626433832795

uniform mat4 u_ViewProj;

uniform float u_TimeDelta;
uniform float u_TotalTime;

uniform vec4 u_Emission;
uniform float u_BulletNum;

uniform float u_SpreadSeed;
uniform float u_Spread;

uniform float u_BulletSize;

uniform vec3 u_Gravity;
uniform vec3 u_Origin;


in vec3 i_Position;
in float i_Age; // in seconds
in float i_Life;
in vec3 i_Velocity;


out vec3 v_Position;
out vec3 v_Velocity;
out float v_Age;
out float v_Life;

float random( vec3 p , vec3 seed) {
  return fract(sin(dot(p + seed, vec3(987.654, 123.456, 531.975))) * 85734.3545);
}

vec3 random3D(vec3 p , vec3 seed) {
  return fract(sin(vec3(dot(p + seed, vec3(311.7, 127.1, 135.0)), dot(p + seed, vec3(269.5, 183.3, 10.0)), dot(p + seed, vec3(86.5, 279.3, 103.0)))) * 85734.3545);
}

vec2 random2D( vec2 p , vec2 seed) {
  return fract(sin(vec2(dot(p + seed, vec2(311.7, 127.1)), dot(p + seed, vec2(269.5, 183.3)))) * 85734.3545);
}

vec3 squareToSphereUniform(vec2 s)
{
  float z = 1.0 - 2.0 * s.x;
  float x = cos(2.0 * M_PI * s.y) * sqrt(1.0 - z * z);
  float y = sin(2.0 * M_PI * s.y) * sqrt(1.0 - z * z);
  return vec3(x, y, z);
}

vec3 squareToDiskUniform(vec2 s)
{
    // maps sample x to radius, and sample y to angle
    float x = pow(s.x, 0.5) * cos(radians(s.y * 360.0));
    float y = pow(s.x, 0.5) * sin(radians(s.y * 360.0));
    return vec3(0, x , y);

  }

  vec3 squareToDiskConcentric(vec2 s)
  {
    if (s.x == 0.0 && s.y == 0.0) {
      return vec3(0, 0.5, 0);
    }

    float phi = 0.0;
    float a = 2.0 * s.x - 1.0;
    float b = 2.0 * s.y - 1.0;
    float r;

    if (a > -b) {
      if (a > b) {
        phi = (M_PI / 4.0) * (b / a);
        r = a;
      }
      else {
        r = b;
        phi = (M_PI / 4.0) * (2.0 - (a / b));
      }
    }
    else {
      if (a < b) {
        r = -a;
        phi = (M_PI / 4.0) * (4.0 + (b / a));
      }
      else {
        r = -b;
        if (b != 0.0) {
          phi = (M_PI / 4.0) * (6.0 - (a / b));
        }
        else {
          phi = 0.0;
        }
      }
    }

    float u = r * cos(phi);
    float v = r * sin(phi);
    return vec3(u, 0.5, v);
  }

  void main() {

    // change the value of gravity depending on whether or not it's turned off
    vec3 gravity = u_Gravity;
    if (u_Emission[3] == 1.0) {
      gravity[1] = 0.0;
    }

    // particle exceed life time. Spawn another one.
    if (i_Age >= i_Life) {

    vec3 seed = vec3(0, 0, 0);
    vec2 seed2 = vec2(0, 0);
    vec2 seed3 = vec2(10, 10);

    vec2 rand = random2D(vec2(float(gl_VertexID) / 1000.0,
                              float(gl_VertexID) / 1000.0), 
                             vec2(3.0, 3.0));


    vec2 rand2 = random2D(vec2(float(gl_VertexID) / 1000.0,
                               float(gl_VertexID) / 1000.0), 
                                seed2);
    vec2 rand_origin_disk = random2D(vec2(float(gl_VertexID) / 1000.0,
                                          float(gl_VertexID) / 1000.0), 
                                          seed3);


    vec3 rand3 = random3D(vec3(float(gl_VertexID) / 1000.0,
                               float(gl_VertexID) / 1000.0,
                               float(gl_VertexID) / 1000.0), 
                               seed);


    // ============ Particle Trajectory =================

    vec3 velocity = vec3(0, 1, 0);

    // sphere
    if (u_Emission[0] == 0.0) {
      velocity = normalize(squareToSphereUniform(rand2)) * 1.5;
    }

    // cone
    if (u_Emission[0] == 1.0) {
      velocity = normalize(squareToDiskUniform(rand2) + vec3(2.5, 0, 0)) * 1.5;
    } 

    //straight up
    if (u_Emission[0] == 2.0) {
      velocity = vec3(1, 0, 0);
    } 

    // square cone
    if (u_Emission[0] == 3.0) {
      velocity = vec3(1.f, rand3.x * 1.2 - 0.6, rand3.y* 1.2 - 0.6);
    } 

    // outline
    if (u_Emission[0] == 4.0) {
      float theta = radians(rand3.z * 359.0);
      float y = cos (theta);
      float x = 3.0;
      float z = sin (theta);
      velocity = vec3(x, y, z);
    } 


    // ============ BASE SHAPE EMITTERS ===============

    v_Position = u_Origin;

    // sphere emitter 
    if (u_Emission[1] == 0.0) {
      v_Position = squareToSphereUniform(rand_origin_disk);
      if (u_Emission[2] == 1.0) {
        v_Position *= u_BulletSize;
      }
    }

    //regular/point emitter
    if (u_Emission[1] == 1.0) {
      v_Position = u_Origin;
    }

    //disk
    if (u_Emission[1] == 2.0) {
      v_Position = squareToDiskUniform(rand_origin_disk);
      if (u_Emission[2] == 1.0) {
        v_Position *= u_BulletSize;
      }
    }

    //square
    if (u_Emission[1] == 3.0) {
      v_Position = vec3(0, rand_origin_disk.x, rand_origin_disk.y) * 2.0 - vec3(0.0, 1.0, 1.0);
      if (u_Emission[2] == 1.0) {
        v_Position *= u_BulletSize;
      }
    }

    // random value to get different bullets spread
    vec3 velocity_seed = vec3(u_SpreadSeed, u_SpreadSeed, u_SpreadSeed);
    float spread = u_Spread;

    float random_bullet = random(vec3(float(gl_VertexID) / 1000.0,
                                float(gl_VertexID) / 1000.0,
                                float(gl_VertexID) / 1000.0), 
                                vec3(30.0, 30.0, 30.0));
    random_bullet *= u_BulletNum;
    random_bullet = floor(random_bullet);


    vec3 current_bullet_velocity = vec3(2, 2, 0.0);

    vec3 random_velocity = random3D(vec3(random_bullet, random_bullet, random_bullet) , 
                                    velocity_seed);


    random_velocity.x = ((random_velocity.x * spread) + 1.0) * 1.5;
    random_velocity.z = (((random_velocity.z * 2.0 - 1.0) * spread)) * 1.5;
    random_velocity.y = (((random_velocity.y * 2.0 - 1.0) * spread)) * 1.5;
    current_bullet_velocity = random_velocity;


    // moves back and forth
    //v_Position += vec3(sin(u_TotalTime * 0.0005) * 5.0, 0.0, 0.0);

    if (u_Emission[2] == 1.0) {
      // moves the system in a ballistic projectile 
      vec3 original_position = v_Position + vec3(-5, 0, 0);
      float t = mod(u_TotalTime, 3000.0) * 0.002; // will eventually be replaced with collision test
      v_Position += vec3(-5, 0, 0) + current_bullet_velocity * t + 0.5 * gravity * t * t;
    }

    v_Age = 0.0;
    v_Life = i_Life;

    /* Generate final velocity vector. */
    v_Velocity = velocity; 


  } else {
    
    /* Update parameters*/
    v_Position = i_Position + i_Velocity * u_TimeDelta;

    v_Age = i_Age + u_TimeDelta;
    v_Life = i_Life;

    // random force
    vec3 rand_force = random3D(vec3(float(gl_VertexID) / 1000.0,
                                    float(gl_VertexID) / 1000.0,
                                    float(gl_VertexID) / 1000.0), 
                                    vec3(4.0, 4.0, 4.0));

    //v_Velocity = i_Velocity + u_Gravity * 2.0 * u_TimeDelta + (vec3(3.0, 0.0, 0.0) + rand_force) * u_TimeDelta;
    v_Velocity = i_Velocity + gravity * 2.0 * u_TimeDelta;
  }
}
