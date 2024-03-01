//
//  Shaders.metal
//  quadTreeCollisions
//
//  Created by Raul on 3/1/24.
//

#include <metal_stdlib>
using namespace metal;



// Particle structure as defined in Swift
struct Particle {
    float2 position;      // Position in space
    float2 velocity;      // Speed and direction
    float radius;         // Size of each particle
    float2 acceleration;  // Changes in velocity over time
    float mass;           // Influences how particles respond to forces
    float4 color;         // RGBA color
    uint uniqueID;        // Unique identifier
    float age;            // Lifecycle of particles
    float viscosity;      // Viscous nature of the substance
    float elasticity;     // Stretchiness and bounce
    float surfaceTension; // Cohesive forces between particles
};

// Screen dimensions structure
struct ScreenDimensions {
    float width;
    float height;
};

// Structure for vertex shader output
struct VertexOut {
    float4 position [[position]];
    float pointSize [[point_size]];
    float4 color;
};

// Vertex shader
vertex VertexOut vertex_main(const device Particle* particles [[buffer(0)]],
                             uint vertexID [[vertex_id]]) {
    VertexOut out;

    Particle particle = particles[vertexID];
    out.position = float4(particle.position, 0.0, 1.0);
    out.pointSize = particle.radius * 2.0; // Diameter of the particle
    out.color = particle.color;

    return out;
}

// Fragment shader
fragment float4 fragment_main(VertexOut in [[stage_in]]) {
    return in.color;
}

// Compute shader for updating particle position and handling collision
kernel void compute_main(device Particle* particles [[buffer(0)]],
                         constant ScreenDimensions& dimensions [[buffer(1)]],
                         constant float& timeStep [[buffer(2)]],
                         constant uint& particleCount [[buffer(3)]],
                         constant float& initialAge [[buffer(4)]], // Add initialAge as a parameter

                         uint id [[thread_position_in_grid]]) {
    if (id < particleCount) {
        Particle particle = particles[id];

        // Update the position based on velocity
        particle.position += particle.velocity * timeStep;

        // Collision detection with edges
        // Assuming normalized coordinates from -1 to 1
        if (particle.position.x < -1.0 || particle.position.x > 1.0) {
            particle.velocity.x *= -1.0; // Reverse velocity on x-axis
        }
        if (particle.position.y < -1.0 || particle.position.y > 1.0) {
            particle.velocity.y *= -1.0; // Reverse velocity on y-axis
        }
        
        // Update age and fade out
               particle.age -= 0.00001; // Decrease age, adjust the rate as needed
               if (particle.age > 0) {
                   particle.color.a = particle.age / initialAge; // Calculate alpha based on age
               } else {
                   particle.color.a = 0.5; // Fully transparent when age is 0 or less
               }

        // Update the buffer with the new particle data
        particles[id] = particle;
    }
}



