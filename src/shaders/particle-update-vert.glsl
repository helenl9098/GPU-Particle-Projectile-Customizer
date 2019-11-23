#version 300 es
precision mediump float;

#define M_PI 3.1415926535897932384626433832795

uniform mat4 u_ViewProj;

uniform float u_TimeDelta;
uniform float u_TotalTime;

uniform float u_SphereCollider;
uniform vec4 u_SphereColliderPos;


uniform vec4 u_Emission;
uniform float u_BulletNum;

uniform float u_SpreadSeed;
uniform float u_Spread;

uniform float u_BulletSize;

uniform vec3 u_Gravity;
uniform vec3 u_Origin;

uniform vec4 u_Spray_Constants;


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

  vec3 reflection(vec3 incidentVec, vec3 normal)
{
  return incidentVec - 2.0 * dot(incidentVec, normal) * normal;
}

  void main() {

    // change the value of gravity depending on whether or not it's turned off
    vec3 gravity = u_Gravity;
    if (u_Emission[3] == 1.0) {
      gravity[1] = 0.0;
    }

    vec3 sphere_center = vec3(u_SphereColliderPos);
    float sphere_radius = u_SphereColliderPos[3];

    vec2 rand_sphere = random2D(vec2(float(gl_VertexID) / 1000.0,
                          float(gl_VertexID) / 1000.0), 
                          vec2(13.0, 13.0));

    // particle exceed life time. Spawn another one.
    if (i_Age >= i_Life) {


  /*
  *
  * INITIALIZE PARTICLE
  *
  *
  */  

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



    v_Age = 0.0;
    v_Life = i_Life;

    // ============ Particle Trajectory =================

    vec3 velocity = vec3(0, 1, 0);

    // sphere
    if (u_Emission[0] == 0.0) {
      velocity = normalize(squareToSphereUniform(rand2)) * 3.5;
      if (u_Emission[2] == 1.0 || u_Emission[2] == 2.0) {
        velocity = 2.0 *normalize(squareToSphereUniform(rand2));
      }
    }

    // cone
    if (u_Emission[0] == 1.0) {
      velocity = normalize(squareToDiskUniform(rand2) + vec3(2.5, 0, 0)) * 3.5;
      if (u_Emission[2] == 1.0 || u_Emission[2] == 2.0) {
        velocity = 2.0 *normalize(squareToDiskUniform(rand2) + vec3(2.5, 0, 0));
      }
    } 

    //straight up
    if (u_Emission[0] == 2.0) {
      velocity = vec3(1, 0, 0) * 3.5;
      if (u_Emission[2] == 1.0 || u_Emission[2] == 2.0) {
        velocity = 2.0 *vec3(1, 0, 0);
      }
    } 

    // square cone
    if (u_Emission[0] == 3.0) {
      velocity = normalize(vec3(1.f, rand3.x * 1.2 - 0.6, rand3.y* 1.2 - 0.6)) * 3.5;
      if (u_Emission[2] == 1.0 || u_Emission[2] == 2.0) {
        velocity = 2.0 *normalize(vec3(1.f, rand3.x * 1.2 - 0.6, rand3.y* 1.2 - 0.6));
      }
    } 

    // outline
    if (u_Emission[0] == 4.0) {
      float theta = radians(rand3.z * 359.0);
      float y = cos (theta);
      float x = 3.0;
      float z = sin (theta);
      velocity = normalize(vec3(x, y, z)) * 3.5;

      if (u_Emission[2] == 1.0 || u_Emission[2] == 2.0) {
        velocity = 2.0 *normalize(vec3(x, y, z));
      }
    } 


    // ============ BASE SHAPE EMITTERS ===============

    v_Position = u_Origin;

    // sphere emitter 
    if (u_Emission[1] == 0.0) {
      v_Position = squareToSphereUniform(rand_origin_disk);
      if (u_Emission[2] == 1.0 || u_Emission[2] == 2.0) {
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
      if (u_Emission[2] == 1.0 || u_Emission[2] == 2.0) {
        v_Position *= u_BulletSize;
      }
    }

    //square
    if (u_Emission[1] == 3.0) {
      v_Position = vec3(0, rand_origin_disk.x, rand_origin_disk.y) * 2.0 - vec3(0.0, 1.0, 1.0);
      if (u_Emission[2] == 1.0 || u_Emission[2] == 2.0) {
        v_Position *= u_BulletSize;
      }
    }

    // ============ BULLET GENERATION ===============
    // random value to get different bullets spread
    vec3 velocity_seed = vec3(u_SpreadSeed, u_SpreadSeed, u_SpreadSeed);
    float spread = u_Spread;

    float random_bullet = random(vec3(float(gl_VertexID) / 1000.0,
                                float(gl_VertexID) / 1000.0,
                                float(gl_VertexID) / 1000.0), 
                                vec3(30.0, 30.0, 30.0));
    random_bullet *= u_BulletNum;
    random_bullet = floor(random_bullet);


    //vec3 current_bullet_velocity = vec3(2, 2, 0.0);

    // generates random velocity from spread of bullet
    vec3 random_velocity = random3D(vec3(random_bullet, random_bullet, random_bullet) , 
                                    velocity_seed);


    random_velocity.x = ((random_velocity.x * spread) + 1.0) * 1.5;
    random_velocity.z = (((random_velocity.z * 2.0 - 1.0) * spread)) * 1.5;
    random_velocity.y = (((random_velocity.y * 2.0 - 1.0) * spread)) * 1.5;
    vec3 current_bullet_velocity = random_velocity;


    // ===========================================
    // MAKES A SPHERE
    if (rand_sphere.x > 0.90) {

          vec2 rand_warp = random2D(vec2(float(gl_VertexID) / 1000.0,
                               float(gl_VertexID) / 1000.0), 
                                vec2(13.0, 3.0));

          v_Position = normalize(squareToSphereUniform(rand_warp)) * sphere_radius + sphere_center;
          v_Velocity = vec3(0, 0, 0);
          v_Life = -0.2; 

          if (u_SphereCollider == 0.0) {
            v_Position = sphere_center;
          }

    } else {
        /* Generate final velocity vector. */
        v_Velocity = velocity; 

        //========== PROJECTILE GUN MOVEMENT
        if (u_Emission[2] == 1.0) {
          // moves the system in a ballistic projectile 
          vec3 original_position = v_Position + vec3(-5, 0, 0);
          float t = mod(u_TotalTime, 3000.0) * 0.002; // will eventually be replaced with collision test
          vec3 center = vec3(4.0, 0.0, 0.0);
          
          vec3 tempPos = v_Position + vec3(-6, 0, 0) + current_bullet_velocity * t + 0.5 * gravity * t * t;
          float distanceToSphere = distance(tempPos, sphere_center);
          if (distanceToSphere < sphere_radius) {

            //tempPos = v_Position + vec3(-6, 0, 0);
            //v_Age = v_Life + 1;
          }
    
          v_Position = tempPos;


    
             // if (distanceToSphere < sphere_radius) {
                //vec3 vel = 3.0 * normalize(reflection(current_bullet_velocity, tempPos - center));
                //v_Position += tempPos + (tempPos - center) * t + 0.5 * gravity * t * t;
               //   v_Position = tempPos;
                  //velocity = 
              //} 
    
        }

         //========== SPRAY GUN MOVEMENT
        else if (u_Emission[2] == 2.0) {
          // moves the system in a ballistic projectile 
          vec3 original_position = v_Position + vec3(-5, 0, 0);
          float t = 0.0;
          if (u_Spray_Constants[0] == 0.0) {
            t = mod(u_TotalTime + (random_bullet * 300.0), 2000.0) * 0.002; // will eventually be replaced with collision test
          }
          else if (u_Spray_Constants[0] == 1.0) {

            float random_spray = random(vec3(float(random_bullet) / 1000.0,
                                float(random_bullet) / 1000.0,
                                float(random_bullet) / 1000.0), 
                                vec3(0.0,
                                     u_Spray_Constants[1], 
                                     0.0));

            t = mod(u_TotalTime + (random_bullet * 300.0) + (random_spray * 300.0), 2000.0) * 0.002;

          }
          
          vec3 tempPos = v_Position + vec3(-6, 0, 0) + current_bullet_velocity * t + 0.5 * gravity * t * t;
          float distanceToSphere = distance(tempPos, sphere_center);
          if (distanceToSphere < sphere_radius && u_SphereCollider == 1.0) {

            tempPos = vec3(-6, 0, 0);
            v_Velocity = vec3(0, 0, 0); 
            //v_Age = i_Life +;
          }
    
          v_Position = tempPos;

        }
    
    }


  } 
  else {
  
  /*
  *
  * UPDATE PARTICLE!!!
  *
  *
  */  
  

  // this is if the particle is forming the sphere
    if (rand_sphere.x > 0.90) {
      v_Age = -0.1;
      gravity = vec3(0.0, 0.0, 0.0);
      v_Velocity = i_Velocity;
      v_Position = i_Position; 
      v_Life = -0.2;
    }

    // this is if particle is part of the beam or projectile
    else {
      v_Life = i_Life;
      v_Age = i_Age + u_TimeDelta;

      float distanceToSphere = distance(i_Position, sphere_center);

      // this is if the particle is inside the sphere
      if (distanceToSphere < sphere_radius && u_SphereCollider == 1.0) {
        // this should be the normal of the sphere
        //vec3 vel = length(i_Velocity) * normalize(i_Position - sphere_center);
        vec3 random_reflection_noise_seed = vec3(5.0, 5.0, 5.0);
        vec3 random_reflection_noise = random3D(i_Position * u_TimeDelta, random_reflection_noise_seed);
        random_reflection_noise *= 2.0;
        random_reflection_noise -= vec3(1.0, 1.0, 1.0);

        vec3 vel = length(i_Velocity) * normalize(random_reflection_noise + normalize(reflect(i_Velocity + gravity * 2.0 * u_TimeDelta, i_Position - sphere_center)));
        //vec3 vel = vec3(-1.0, 1.0, -1.0);
        v_Velocity = vel + gravity * 2.0 * u_TimeDelta;
        v_Position = i_Position  + v_Velocity * u_TimeDelta;

      }
      else {
        v_Velocity = i_Velocity + gravity * 2.0 * u_TimeDelta;
        v_Position = i_Position  + v_Velocity * u_TimeDelta;
      }
    }
    

    // random force
    //vec3 rand_force = random3D(vec3(float(gl_VertexID) / 1000.0,
    //                                float(gl_VertexID) / 1000.0,
    //                                float(gl_VertexID) / 1000.0), 
    //                                vec3(4.0, 4.0, 4.0));


  

    //if (distanceToSphere < sphere_radius) {
    //   vec3 vel = 1.0 * normalize(reflection(i_Velocity, i_Position - sphere_center));
    //   v_Velocity = vel + gravity * 2.0 * u_TimeDelta;
    //   v_Position = i_Position  + v_Velocity * u_TimeDelta;
      
    // } 
  }
}
