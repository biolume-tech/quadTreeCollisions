//
//  Particle.swift
//  quadTreeCollisions
//
//  Created by Raul on 3/1/24.
//


import Foundation
import simd




struct Particle {
    
    var position: SIMD2<Float>  // Position in space
    
    var velocity: SIMD2<Float>  // Represents the speed and direction
    
    var radius: Float           // size of each particle
    
    var acceleration: SIMD2<Float> // Changes in velocity over time simulating the dynamic, responsive behavior of the substance
    
    var mass: Float                // Influences how particles respond to forces, like gravity or interactions, affecting the                                                       draping and settling of the silk-like material.
    
    var color: SIMD4<Float>     // RGBA color
    
    var uniqueID: UInt32        // Unique identifier
    
    var age: Float                // Used to track the lifecycle of particles, potentially affecting their physical properties as                                                  they 'age' within the simulation.
    
    var viscosity: Float          // Critical for simulating the viscous nature of the substance, affecting how particles flow and                                                 stick together.
    
    var elasticity: Float         // Determines the stretchiness and bounce, mimicking the flexible yet resilient nature of silk.
    
    var surfaceTension: Float     // Key for simulating the cohesive forces between particles, aiding in creating the continuous,                                                  flowing surface of the silk-like material.
            
    init(position: SIMD2<Float>,
         velocity: SIMD2<Float>,
         radius: Float,
         acceleration: SIMD2<Float>,
         mass: Float,
         color: SIMD4<Float>,
         uniqueID: UInt32,
         age: Float,
         viscosity: Float,
         elasticity: Float,
         surfaceTension: Float
         
    
    )
    {
        self.position = position
        self.velocity = velocity
        self.radius = radius
        self.acceleration = acceleration
        self.mass = mass
        self.color = color
        self.uniqueID = uniqueID
        self.age = age
        self.viscosity = viscosity
        self.elasticity = elasticity
        self.surfaceTension = surfaceTension
    }
}
