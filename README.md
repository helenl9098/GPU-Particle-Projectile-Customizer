# GPU-Particle-System

The goal of this project is to make a custom gun creation tool that simulates bullets, projectiles, and other gun-outputs using particles
that are generated, updated, and rendered using your GPU.

## Demo : https://helenl9098.github.io/GPU-Particle-System/
Controls: Drag to rotate the camera around the origin. Right click and drag to translate the camera.

## Features & Progress
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


Note: this is still in progress, but lots of combinations to play with already. My favorite is: sphere emitter with cone trajectory, as a projectile gun, with gravity turned off.
