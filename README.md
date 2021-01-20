# GPU-Particle-System

The goal of this project is to make a custom gun creation tool that simulates bullets, projectiles, and other gun-outputs using particles
that are generated, updated, and rendered using your GPU.

## Demo : https://helenl9098.github.io/GPU-Particle-Projectile-Customizer/
Controls: Drag to rotate the camera around the origin. Right click and drag to translate the camera.

## Alpha Features & Progress
- Particle System(s) that generates particles on the GPU, updates them through transform feedback, and renders the results. The particle generator keeps track of the current life of each particle. If the particle's life is greater than its max life, the particle will reborn. 
In the beginning, all the particles will not appear at once. The birth rate of the particles decides how many new particles to spawn every tick until the maximum number
of particles is achieved. 

- Visuals: As the particle continues in its life, its size and transparency (alpha) will decrease. These values will also decrease as the camera gets further away. The color of the 
particles is dependent on a cosine palette, but can also be altered by linearly interpolating the colors in the future.

- Shape Emitters: You can specify how the particle system generates particles by changing the shape of the emitter. The shape of the emitter will distribute particles uniformly across different 2D and 3D shapes using warping functions.

- Trajectory: You can specify the shape of the trajectory (spread) of the particles. Do you want the particles to spread in a cone shape or go up vertically?

- Gravity (and other forces) can act on the particles. You can turn gravity on and off as well as change its value. 

- Gun Type: There are two types of guns you can make -- beam guns and projectile guns. For beam guns, there is a constant source and the particles emit as a uniform shape away from thos source.
For projectile guns, particles will travel as clusters following a ballistic curve. The cluster shape is determined by your shape emitter and the bullet trail is determined by your particle trajectory. 
Projectile guns are described in more detail below. 

- (Projectile) Bullet Number & Size: For projectile guns, you can specify the number of clusters that particles form. Additionally, you can specify how big you want your clusters to be.  

- (Projectile) Spread Seed & Spread: Projectile guns shoot out clusters (bullets) in a random spread. The spread seed determines the initial random velocity and the spread determines how 
far the bullets deviate from going straight in the x axis. The larger the spread, the farther apart the bullets. 

------------------------------


## Beta Features 
- Added new Gun type: Spray (bad name, will probably change). This type of gun is more traditional -- bullets come out one by one at a certain rate. This type is different than the projectile gun, where all the bullets come out at once. 

- (Spray Gun) The spread, bullet number, and bullet size can be altered using the same sliders as the projectile properties 

- (Spray Gun) In addition to the projectile properties, you can specify the rate at which the bullets are fired.
  - Constant: The bullets appear at a constant rate.
  - Random: The bullets appear at a rate that is offset by some noise, whoseseed you can also specify. 

- Added Collider: Particle Sphere that your particles will collide against!

- Collider Controls: After expanding the Collider folder on the right, you can turn the collider on and off. You can also change the x, y, z position of the collider as well as the radius. 

- Collision Behavior: There are three main behaviors of the collider. 
  - (Beam Gun) When beam gun particles collide with the collider, the particles reflect off of the surface normal of the impact point, with small noise offsets
  - (Projectile Gun) When projectiles gun bullets intersect with the collider, parts of the bullet die off at the surface of impact, but the bullet continues to travel through the sphere
  - (Spray Gun) When spray projectiles intersect with the collider, they explode on impact with the surface
  
- Visuals: There is now a raytraced background so there are pretty colors when you rotate the camera. Was tired of staring at the black void :) 


------------------------------


## Final Features

- Added in First person camera: Toggle on and off by pressing F. In first person mode, you can move around using WASD. 
Note: if you press f and the particle systems disappear, it might mean that your camera is spun around. Move your mouse to look around and find the particle system again. 

- Added in collision detection. Now if projectiles hit the collider, the collider will trun red in places that collided with a certain density of particles. The collider will retain these red spots even if you move it around or resize it. To reset the collision visuals, just turn the collider on and off again.  
