import {vec2, vec3} from 'gl-matrix';
import {mat4, vec4} from 'gl-matrix';
import * as Stats from 'stats-js';
import * as DAT from 'dat-gui';
import OpenGLRenderer from './rendering/gl/OpenGLRenderer';
import Camera from './Camera';
import {setGL} from './globals';
import Square from './geometry/Square';
import ShaderProgram, {Shader} from './rendering/gl/ShaderProgram';
import {gl} from './globals';

const controls = {

  particles_per_bullet : 40000, /* number of particles */
  num_particles : 50000,
  birth_rate : 10.1, /* birth rate */
  min_life : 1.01,
  max_life : 1.70, /* life range */
  trajectory:  'sphere',
  emitter: 'sphere',
  bullet_num: 7,
  gun_type: 'beam', 
  gravity: true,
  gravity_value: 0.10,
  spread_seed: 0.0,
  spread: 0.2,
  bullet_size: 0.1,
  sphere_collider: false,
  sphere_collider_x: 0.02,
  sphere_collider_y: 0.02,
  sphere_collider_z: 0.02,
  sphere_collider_radius: 4.01,
  spray_rate: 'constant',
  spray_seed: 0.0,

};

let time: number = 0;
let square: Square;
let attrPos: number;  

function processKeyPresses() {
    // Use this if you wish
}


function randomRGData(size_x, size_y) {
  var d = [];
  for (var i = 0; i < size_x * size_y; ++i) {
    d.push(Math.random() * 255.0);
    d.push(Math.random() * 255.0);
  }
  return new Uint8Array(d);
}


function initialParticleData(num_parts : number, 
  min_age : number, max_age : number) {
    var data = [];
    for (var i = 0; i < num_parts; ++i) {
    // position
    data.push(0.0);
    data.push(0.0);
    data.push(0.0);

    var life = min_age + Math.random() * (max_age - min_age);

    data.push(life + 1);
    data.push(life);

    // velocity
    data.push(0.0);
    data.push(0.0);
    data.push(0.0);
  }
  return data;
}


/*
  Helper function used by the main initialization function.
  sets up a vertex array object based on specified attributes
*/
function setupParticleBufferVAO(buffers, 
  vao : WebGLVertexArrayObject) {
  gl.bindVertexArray(vao);
  for (var i = 0; i < buffers.length; i++) {
    var buffer = buffers[i];
    gl.bindBuffer(gl.ARRAY_BUFFER, buffer.buffer_object);
    var offset = 0;
    for (var attrib_name in buffer.attribs) {
      if (buffer.attribs.hasOwnProperty(attrib_name)) {
        /* Set up vertex attribute pointers for attributes that are stored in this buffer. */
        var attrib_desc = buffer.attribs[attrib_name];
        gl.enableVertexAttribArray(attrib_desc.location);
        gl.vertexAttribPointer(
          attrib_desc.location,
          attrib_desc.num_components,
          attrib_desc.type,
          false, 
          buffer.stride,
          offset);
        var type_size = 4;

        offset += attrib_desc.num_components * type_size;

        if (attrib_desc.hasOwnProperty("divisor")) { 
          gl.vertexAttribDivisor(attrib_desc.location, attrib_desc.divisor);
      }
    }
  }
}
gl.bindVertexArray(null);
gl.bindBuffer(gl.ARRAY_BUFFER, null);
}

  /* Creates an OpenGL program object*/
  function createGLProgram(shader_list, transform_feedback_varyings) {
    var program = gl.createProgram();
    for (var i = 0; i < shader_list.length; i++) {
      var shader = shader_list[i];
      gl.attachShader(program, shader);
    }

  /* Specify varyings that we want to be captured in the transform
  feedback buffer. */
  if (transform_feedback_varyings != null) {
    gl.transformFeedbackVaryings(
      program,
      transform_feedback_varyings,
      gl.INTERLEAVED_ATTRIBS)
  }

  gl.linkProgram(program);
  var link_status = gl.getProgramParameter(program, gl.LINK_STATUS);
  if (!link_status) {
    var error_message = gl.getProgramInfoLog(program);
    throw "Could not link program.\n" + error_message;
  }
  return program;
}

function main() {
  window.addEventListener('keypress', function (e) {
    switch(e.key) {
    }
  }, false);

  window.addEventListener('keyup', function (e) {
    switch(e.key) {
    }
  }, false);

  // Initial display for framerate
  const stats = Stats();
  stats.setMode(0);
  stats.domElement.style.position = 'absolute';
  stats.domElement.style.left = '0px';
  stats.domElement.style.top = '0px';
  document.body.appendChild(stats.domElement);

  /*
  ======================
    GUI INTERFACE 
  ======================
  */
  const gui = new DAT.GUI();

  var folder_basics = gui.addFolder('Basics');
  //var folder_beam_properties = gui.addFolder('Beam Properties');
  var folder_collider = gui.addFolder('Collider');
  var folder_projectile_properties = gui.addFolder('Projectile Properties');
  var folder_spray_properties = gui.addFolder('Spray Properties');

  folder_spray_properties.open();
  folder_basics.open();
  //folder_beam_properties.open();
  folder_projectile_properties.open();



  var emitter_controller = folder_basics.add(controls, 'emitter', [ 'sphere', 'point', 'disk', 'square' ] );
  var trajectory_controller = folder_basics.add(controls, 'trajectory', [ 'sphere', 'cone', 'straight', 'square-cone', 'cone-outline' ] );
  var bullet_num_controller = folder_projectile_properties.add(controls, 'bullet_num', 1, 10).step(1);
  var spray_rate_controller = folder_spray_properties.add(controls, 'spray_rate', [ 'constant', 'random'] );
  var spray_seed_controller =  folder_spray_properties.add(controls, 'spray_seed', 0, 1000).step(0.01);
  
  var type_controller = folder_basics.add(controls, 'gun_type', [ 'beam', 'projectile', 'spray' ] );
  //var bullet_particle_num_controller = folder_projectile_properties.add(controls, 'particles_per_bullet', 10000, 1000000).step(10000);
  var birth_rate_controller = folder_basics.add(controls, 'birth_rate', 1.3, 20.1).step(0.1);
  //var min_life_controller = folder_basics.add(controls, 'min_life', 0.01, 3.0).step(0.1);
  //var max_life_controller = folder_basics.add(controls, 'max_life', 0.01, 3.5).step(0.1);

  var gravity_controller = folder_basics.add(controls, 'gravity');
  var gravity_value_controller = folder_basics.add(controls, 'gravity_value');
  var spread_seed_controller =  folder_projectile_properties.add(controls, 'spread_seed', 0, 1000).step(0.01);
  var spread_controller =  folder_projectile_properties.add(controls, 'spread', 0.01, 0.7).step(0.01);
  var bullet_size_controller =  folder_projectile_properties.add(controls, 'bullet_size', 0.01, 0.4).step(0.01);
  var collider_controller = folder_collider.add(controls, 'sphere_collider');
  var collider_x_controller =  folder_collider.add(controls, 'sphere_collider_x', -10.1, 10.1).step(0.001);
  var collider_y_controller =  folder_collider.add(controls, 'sphere_collider_y', -10.1, 10.1).step(0.001);
  var collider_z_controller =  folder_collider.add(controls, 'sphere_collider_z', -10.1, 10.1).step(0.001);
  var collider_radius_controller =  folder_collider.add(controls, 'sphere_collider_radius', 0.01, 10.1).step(0.001);


  // chnanging bullet particle number
  bullet_num_controller.onChange(function(value) {
    controls.num_particles =  controls.bullet_num * controls.particles_per_bullet;
  });

  birth_rate_controller.onChange(function(value) {
    state.birth_rate = value;
  });

  var spray_constant = [0, 0, 0, 0]; 
  spray_rate_controller.onChange(function(value) {
    switch(value) {

      case 'constant' :
      spray_constant[0] = 0;
      break;

      case 'random' :
      spray_constant[0] = 1;
      break;

      case 'continuous random' :
      spray_constant[0] = 2;
      break;


      default: 
      spray_constant[0] = 0;

    }


  });


  // changing emission
  var emission = [0, 0, 0.0, 0];
  trajectory_controller.onChange(function(value) {
    switch(value) {
      case 'sphere':
      emission[0] = 0;
      break;

      case 'cone' :
      emission[0] = 1;
      break;

      case 'straight' :
      emission[0] = 2;
      break;

      case 'square-cone' :
      emission[0] = 3;
      break;

      case 'cone-outline' :
      emission[0] = 4;
      break;


      default: 
      emission[0] = 0;

    }
  });

  emitter_controller.onChange(function(value) {
    switch(value) {
      case 'sphere':
      emission[1] = 0;
      break;

      case 'point' :
      emission[1] = 1;
      break;

      case 'disk' :
      emission[1] = 2;
      break;

      case 'square' :
      emission[1] = 3;
      break;

      default: 
      emission[1] = 0;

    }
  });

  type_controller.onChange(function(value) {  
      switch(value) {
      case 'beam':
      //folder_beam_properties.open();
      folder_projectile_properties.close();
      emission[2] = 0;
      break;

      case 'projectile':
      //folder_beam_properties.close();
      folder_projectile_properties.open();
      emission[2] = 1;
      break;

      case 'spray':
      //folder_beam_properties.close();
      folder_projectile_properties.open();
      emission[2] = 2;
      break;

      default: 
      emission[2] = 0;

    }
  });

  gravity_controller.onChange(function(value) {  
      
    if (value) {
      emission[3] = 0;

    } else {
      emission[3] = 1;

    }
    
  });


  // get canvas and webgl context
  const canvas = <HTMLCanvasElement> document.getElementById('canvas');
  canvas.height = 800;
  canvas.width = 1200;
  canvas.style.width  = '1200px';
  canvas.style.height = '800px';
  const gl = <WebGL2RenderingContext> canvas.getContext('webgl2');
  if (!gl) {
    alert('WebGL 2 not supported!');
  }

  setGL(gl);

  // create a square
  square = new Square(vec3.fromValues(0, 0, 0));
  square.create();


  // initialize camera
  const camera = new Camera(vec3.fromValues(0, 0, -1), vec3.fromValues(0, 0, 0));
  camera.setAspectRatio(canvas.width / canvas.height);
  camera.updateProjectionMatrix();


  // call render loop
  window.requestAnimationFrame(
    function(ts) { render(gl, state, ts); });

  gl.clearColor(0.0 / 255.0, 0.0 / 255.0, 0.0 / 255.0, 1);
  gl.enable(gl.DEPTH_TEST);


 /* Create programs for updating and rendering the particle system. */
  var update_program = createGLProgram(
    [
    new Shader(gl.VERTEX_SHADER, require('./shaders/particle-update-vert.glsl')).shader,
    new Shader(gl.FRAGMENT_SHADER, require('./shaders/passthru-frag.glsl')).shader
    ],
    [
    "v_Position",
    "v_Age",
    "v_Life",
    "v_Velocity",
    ]);
  var render_program = createGLProgram(
    [
    new Shader(gl.VERTEX_SHADER, require('./shaders/particle-render-vert.glsl')).shader,
    new Shader(gl.FRAGMENT_SHADER, require('./shaders/particle-render-frag.glsl')).shader
    ],
    null);
  var raycast_program = createGLProgram(
    [
    new Shader(gl.VERTEX_SHADER, require('./shaders/flat-vert.glsl')).shader,
    new Shader(gl.FRAGMENT_SHADER, require('./shaders/flat-frag.glsl')).shader
    ], null);
  attrPos = gl.getAttribLocation(raycast_program, "vs_Pos");




  
  /* Capture attribute locations from program objects. */
  var update_attrib_locations = {
    i_Position: {
      location: gl.getAttribLocation(update_program, "i_Position"),
      num_components: 3,
      type: gl.FLOAT
    },
    i_Age: {
      location: gl.getAttribLocation(update_program, "i_Age"),
      num_components: 1,
      type: gl.FLOAT
    },
    i_Life: {
      location: gl.getAttribLocation(update_program, "i_Life"),
      num_components: 1,
      type: gl.FLOAT
    },
    i_Velocity: {
      location: gl.getAttribLocation(update_program, "i_Velocity"),
      num_components: 3,
      type: gl.FLOAT
    }
  };
  var render_attrib_locations = {
    i_Position: {
      location: gl.getAttribLocation(render_program, "i_Position"),
      num_components: 3,
      type: gl.FLOAT
     // }
    },
    i_Age: {
      location: gl.getAttribLocation(render_program, "i_Age"),
      num_components: 1,
      type: gl.FLOAT
    },
    i_Life: {
      location: gl.getAttribLocation(render_program, "i_Life"),
      num_components: 1,
      type: gl.FLOAT
    }
  };

  /* particle data buffer */
  var buffers = [
    gl.createBuffer(),
    gl.createBuffer()];

  /* We'll have 4 VAOs... */
  var vaos = [
    gl.createVertexArray(), /* for updating buffer 1 */
    gl.createVertexArray(), /* for updating buffer 2 */
    gl.createVertexArray(), /* for rendering buffer 1 */
    gl.createVertexArray() /* for rendering buffer 2 */
  ];

  /* this has information about buffers and bindings for each VAO. */
  var vao_desc = [
  {
    vao: vaos[0],
    buffers: [{
      buffer_object: buffers[0],
      stride: 4 * 8,
      attribs: update_attrib_locations
    }]
  },
  {
    vao: vaos[1],
    buffers: [{
      buffer_object: buffers[1],
      stride: 4 * 8,
      attribs: update_attrib_locations
    }]
  },
  {
    vao: vaos[2],
    buffers: [{
      buffer_object: buffers[0],
      stride: 4 * 8,
      attribs: render_attrib_locations
    }],
  },
  {
    vao: vaos[3],
    buffers: [{
      buffer_object: buffers[1],
      stride: 4 * 8,
      attribs: render_attrib_locations
    }],
  },
  ];
  
  /* Populate buffers with some initial data. */
  var initial_data =
    new Float32Array(initialParticleData(controls.num_particles, controls.min_life, controls.max_life));
    gl.bindBuffer(gl.ARRAY_BUFFER, buffers[0]);
    gl.bufferData(gl.ARRAY_BUFFER, initial_data, gl.STREAM_DRAW);
    gl.bindBuffer(gl.ARRAY_BUFFER, buffers[1]);
    gl.bufferData(gl.ARRAY_BUFFER, initial_data, gl.STREAM_DRAW);
  
  /* Set up VAOs */
  for (var i = 0; i < vao_desc.length; i++) {
    setupParticleBufferVAO(vao_desc[i].buffers, vao_desc[i].vao);
  }

  gl.clearColor(0.0, 0.0, 0.0, 1.0);

  /* Set up blending */
  gl.enable(gl.BLEND);
  gl.enable( gl.DEPTH_TEST );
  gl.blendFuncSeparate(gl.SRC_ALPHA, gl.ONE_MINUS_SRC_ALPHA, gl.ONE, gl.ONE_MINUS_SRC_ALPHA);
  //gl.blendFunc(gl.SRC_ALPHA, gl.ONE_MINUS_SRC_ALPHA);
  //gl.blendFunc(gl.ONE, gl.ONE_MINUS_SRC_ALPHA);

    // intial state of the particles
  var state =
  init(
   controls.num_particles,
   controls.birth_rate,
   controls.min_life, controls.max_life,
   [0.0, -controls.gravity_value, 0.0]); /* gravity */

  

/* Main initialization Function */
 function init(
  num_particles,
  particle_birth_rate,
  min_age,
  max_age, 
  gravity) {

  /* Do some parameter validation */
  if (max_age < min_age) {
    throw "Invalid min-max age range.";
  }

    return {
      particle_sys_buffers: buffers,
      particle_sys_vaos: vaos,
      read: 0,
      write: 1,
      particle_update_program: update_program,
      particle_render_program: render_program,
      raycast_flat_program: raycast_program,
      num_particles: initial_data.length / 8,
      old_timestamp: 0.0,
      total_time: 0.0,
      born_particles: 0,
      birth_rate: particle_birth_rate,
      origin: [0.0, 0.0, 0.0]
    };
  }






  /* render (tick) loop */
  function render(gl, state, timestamp_millis) {


    camera.update();
    stats.begin();
    var num_part = state.born_particles;

    /* Calculate time delta. */
    var time_delta = 0.0;
    if (state.old_timestamp != 0) {
      time_delta = timestamp_millis - state.old_timestamp;
      if (time_delta > 500.0) {
        // ignore if the time step was too large
        time_delta = 0.0;
      }
    }

    /* add particles to system */
    if (state.born_particles < state.num_particles) {
      state.born_particles = Math.min(state.num_particles,
      Math.floor(state.born_particles + state.birth_rate * time_delta));
    }

    state.old_timestamp = timestamp_millis;


    gl.clear(gl.COLOR_BUFFER_BIT | gl.DEPTH_BUFFER_BIT);

    gl.useProgram(state.raycast_flat_program);
    
    if (attrPos != -1 && square.bindPos()) {
       gl.enableVertexAttribArray(attrPos);
       gl.vertexAttribPointer(attrPos, 4, gl.FLOAT, false, 0, 0);
    }
    

    square.bindIdx();
    gl.drawElements(square.drawMode(), square.elemCount(), gl.UNSIGNED_INT, 0);

    if (attrPos != -1) {gl.disableVertexAttribArray(attrPos);}



    /* camera position */
    gl.uniform3f(
      gl.getUniformLocation(state.raycast_flat_program, "u_CamPos"),
      camera.position[0], camera.position[1], camera.position[2]);

    /* camera up vector */
    gl.uniform3f(
      gl.getUniformLocation(state.raycast_flat_program, "u_Up"),
      camera.controls.up[0], camera.controls.up[1], camera.controls.up[2]);

    /* camera ref vector */
    gl.uniform3f(
      gl.getUniformLocation(state.raycast_flat_program, "u_Ref"),
    camera.controls.center[0], camera.controls.center[1], camera.controls.center[2]);

    /* canvas dimensions vector */
    gl.uniform2f(
      gl.getUniformLocation(state.raycast_flat_program, "u_Dimensions"),
    canvas.width, canvas.height);


  //}
  /* Set up VAOs */
  for (var i = 0; i < vao_desc.length; i++) {
    setupParticleBufferVAO(vao_desc[i].buffers, vao_desc[i].vao);
  }
    gl.useProgram(state.particle_render_program);

    /* 
    ========================
    UNIFORM VARIABLES
    ========================
    */

    /* camera projection */
    let viewProj = mat4.create();
    mat4.multiply(viewProj, camera.projectionMatrix, camera.viewMatrix);

    gl.uniformMatrix4fv(
      gl.getUniformLocation(state.particle_render_program, "u_ViewProj"),
      false,
      viewProj);
  
    /* camera position */
    gl.uniform3f(
      gl.getUniformLocation(state.particle_render_program, "u_CamPos"),
      camera.position[0], camera.position[1], camera.position[2]);

    /* camera up vector */
    gl.uniform3f(
      gl.getUniformLocation(state.particle_render_program, "u_Up"),
      camera.controls.up[0], camera.controls.up[1], camera.controls.up[2]);

    /* camera ref vector */
    gl.uniform3f(
      gl.getUniformLocation(state.particle_render_program, "u_Ref"),
    camera.controls.center[0], camera.controls.center[1], camera.controls.center[2]);

    /* canvas dimensions vector */
    gl.uniform2f(
      gl.getUniformLocation(state.particle_render_program, "u_Dimensions"),
    canvas.width, canvas.height);


    gl.uniform1f(
      gl.getUniformLocation(state.particle_render_program, "u_SphereCollider"),
    controls.sphere_collider);


    gl.useProgram(state.particle_update_program);

    /* uniforms */
    gl.uniformMatrix4fv(
      gl.getUniformLocation(state.particle_update_program, "u_ViewProj"),
      false,
      viewProj);

    gl.uniform1f(
      gl.getUniformLocation(state.particle_update_program, "u_TimeDelta"),
      time_delta / 1000.0);

    gl.uniform1f(
      gl.getUniformLocation(state.particle_update_program, "u_SphereCollider"),
    controls.sphere_collider);

    gl.uniform1f(
      gl.getUniformLocation(state.particle_update_program, "u_TotalTime"),
      state.total_time);
  
    gl.uniform4f(
      gl.getUniformLocation(state.particle_update_program, "u_Emission"),
      emission[0], emission[1], emission[2], emission[3]);

    gl.uniform4f(
      gl.getUniformLocation(state.particle_update_program, "u_Spray_Constants"),
      spray_constant[0], controls.spray_seed, spray_constant[2], spray_constant[3]);
  
    gl.uniform1f(
      gl.getUniformLocation(state.particle_update_program, "u_BulletNum"),
      controls.bullet_num);
  
    gl.uniform1f(
      gl.getUniformLocation(state.particle_update_program, "u_SpreadSeed"),
      controls.spread_seed);
  
    gl.uniform1f(
      gl.getUniformLocation(state.particle_update_program, "u_Spread"),
      controls.spread);

    gl.uniform1f(
      gl.getUniformLocation(state.particle_update_program, "u_BulletSize"),
      controls.bullet_size);
  
    gl.uniform3f(
      gl.getUniformLocation(state.particle_update_program, "u_Gravity"),
      0.0, -controls.gravity_value, 0.0);
    
    gl.uniform3f(
      gl.getUniformLocation(state.particle_update_program, "u_Origin"),
      state.origin[0],
      state.origin[1],
      state.origin[2]);
    
    state.total_time += time_delta;


    gl.uniform4f(
      gl.getUniformLocation(state.particle_update_program, "u_SphereColliderPos"),
    controls.sphere_collider_x,
    controls.sphere_collider_y, 
    controls.sphere_collider_z, 
    controls.sphere_collider_radius);
    

    /*
    ==================
    TRANSFORM FEEDBACK SETUP
    ==================
    */
  
  
    gl.bindVertexArray(state.particle_sys_vaos[state.read]);
    gl.bindBufferBase(
      gl.TRANSFORM_FEEDBACK_BUFFER, 0, state.particle_sys_buffers[state.write]);

    gl.enable(gl.RASTERIZER_DISCARD);
    gl.beginTransformFeedback(gl.POINTS);
    gl.drawArrays(gl.POINTS, 0, num_part);
    gl.endTransformFeedback();
    gl.disable(gl.RASTERIZER_DISCARD);
    gl.bindBufferBase(gl.TRANSFORM_FEEDBACK_BUFFER, 0, null);
  
    gl.bindVertexArray(state.particle_sys_vaos[state.read + 2]);
    gl.useProgram(state.particle_render_program);
    gl.drawArrays(gl.POINTS, 0, num_part);


  
    var tmp = state.read;
    state.read = state.write;
    state.write = tmp;
  
    stats.end();

    // loop through again!
    window.requestAnimationFrame(function(ts) { render(gl, state, ts); });
  }

  camera.setAspectRatio(canvas.width / canvas.height);
  camera.updateProjectionMatrix();
}

main();
