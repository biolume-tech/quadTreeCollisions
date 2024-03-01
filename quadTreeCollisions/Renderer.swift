//
//  Renderer.swift
//  quadTreeCollisions
//
//  Created by Raul on 3/1/24.
//

import MetalKit

class Renderer: NSObject {
    static var device: MTLDevice!
    static var commandQueue: MTLCommandQueue!
    static var library: MTLLibrary!
    var pipelineState: MTLRenderPipelineState!
    
    var computePipelineState: MTLComputePipelineState!
    var dimensionsBuffer: MTLBuffer?

    var particles: [Particle] = []
    var particleBuffer: MTLBuffer?

    let gridWidth = 25   // Adjust as needed
    let gridHeight = 25  // Adjust as needed
    let spacing: Float = 0.05  // Spacing between particles
    var timeStep: Float = 1.0 // Adjust as needed for movement speed
    
    var initialAge: Float = 30000.0 // Example initial age value

    var initialAgeBuffer: MTLBuffer?

    

    
    struct ScreenDimensions {
        var width: Float
        var height: Float
    }

    init(metalView: MTKView) {
        

        guard let device = MTLCreateSystemDefaultDevice(), let commandQueue = device.makeCommandQueue() else {
            fatalError("GPU not available")
        }
        Renderer.device = device
        Renderer.commandQueue = commandQueue
        metalView.device = device

        let library = device.makeDefaultLibrary()
        Renderer.library = library
        let vertexFunction = library?.makeFunction(name: "vertex_main")
        let fragmentFunction = library?.makeFunction(name: "fragment_main")

        let pipelineDescriptor = MTLRenderPipelineDescriptor()
        pipelineDescriptor.vertexFunction = vertexFunction
        pipelineDescriptor.fragmentFunction = fragmentFunction
        pipelineDescriptor.colorAttachments[0].pixelFormat = metalView.colorPixelFormat
        do {
            pipelineState = try device.makeRenderPipelineState(descriptor: pipelineDescriptor)
        } catch {
            fatalError(error.localizedDescription)
        }
        
        initialAgeBuffer = Renderer.device.makeBuffer(bytes: &initialAge, length: MemoryLayout<Float>.size, options: [])

        

        super.init()

        metalView.clearColor = MTLClearColor(red: 0.0, green: 0.0, blue: 0.0, alpha: 1.0)
        metalView.delegate = self

        createParticlesGrid()
        createParticleBuffer()
        setupComputePipeline()
            updateScreenDimensions(metalView: metalView)
    }
    
    func setupComputePipeline() {
        guard let computeFunction = Renderer.library?.makeFunction(name: "compute_main") else {
            fatalError("Compute function not found")
        }

        do {
            computePipelineState = try Renderer.device.makeComputePipelineState(function: computeFunction)
        } catch {
            fatalError("Failed to create compute pipeline state: \(error)")
        }
    }
    
    func updateScreenDimensions(metalView: MTKView) {
        let size = metalView.bounds.size
        var dimensions = SIMD2<Float>(Float(size.width), Float(size.height))
        dimensionsBuffer = Renderer.device.makeBuffer(bytes: &dimensions, length: MemoryLayout<SIMD2<Float>>.stride, options: [])
    }
    
    func performComputePass() {
        guard let commandBuffer = Renderer.commandQueue.makeCommandBuffer(),
              let computeEncoder = commandBuffer.makeComputeCommandEncoder(),
              let particleBuffer = particleBuffer,
              let dimensionsBuffer = dimensionsBuffer else {
            return
        }

        computeEncoder.setComputePipelineState(computePipelineState)
        computeEncoder.setBuffer(particleBuffer, offset: 0, index: 0)
        computeEncoder.setBuffer(dimensionsBuffer, offset: 0, index: 1)

        var particleCount = UInt32(particles.count)
        computeEncoder.setBytes(&particleCount, length: MemoryLayout<UInt32>.size, index: 3)
        
        if let initialAgeBuffer = initialAgeBuffer {
               computeEncoder.setBuffer(initialAgeBuffer, offset: 0, index: 4) // Use an unused index, e.g., 4
           }

        computeEncoder.setBytes(&timeStep, length: MemoryLayout<Float>.size, index: 2) // Set timeStep buffer

        let gridSize = MTLSize(width: Int(particleCount), height: 1, depth: 1)
        let threadGroupSize = MTLSize(width: 1, height: 1, depth: 1)
        computeEncoder.dispatchThreadgroups(gridSize, threadsPerThreadgroup: threadGroupSize)

        computeEncoder.endEncoding()
        commandBuffer.commit()
    }




    func createParticlesGrid() {
            let initialAge: Float = 30000.0 // Set the initial age for the fading effect

            let centerX = Float(gridWidth) / 2.0
            let centerY = Float(gridHeight) / 2.0

            for i in 0..<gridWidth {
                for j in 0..<gridHeight {
                    let x = (Float(i) - centerX) * spacing
                    let y = (Float(j) - centerY) * spacing
                    let randomVelocityX = Float.random(in: -0.001...0.001)
                    let randomVelocityY = Float.random(in: -0.001...0.001)

                    let particle = Particle(
                        position: SIMD2<Float>(x, y),
                        velocity: SIMD2<Float>(randomVelocityX, randomVelocityY),
                        radius: 5.0,
                        acceleration: SIMD2<Float>(0, 0),
                        mass: 1.0,
                        color: SIMD4<Float>(0, 0, 1, 1), // Blue color with full opacity
                        uniqueID: UInt32(i * gridWidth + j),
                        age: initialAge, // Set initial age for each particle
                        viscosity: 0,
                        elasticity: 0,
                        surfaceTension: 0
                    )
                    particles.append(particle)
                }
            }
        }
    


    func createParticleBuffer() {
        guard !particles.isEmpty else { return }
        particleBuffer = Renderer.device.makeBuffer(
            bytes: particles,
            length: particles.count * MemoryLayout<Particle>.stride,
            options: .storageModeShared
        )
    }
}

extension Renderer: MTKViewDelegate {
    func mtkView(_ view: MTKView, drawableSizeWillChange size: CGSize) {
        updateScreenDimensions(metalView: view)
    }

    func draw(in view: MTKView) {
        performComputePass() // Update particle positions before rendering

        guard let commandBuffer = Renderer.commandQueue.makeCommandBuffer(),
              let descriptor = view.currentRenderPassDescriptor,
              let renderEncoder = commandBuffer.makeRenderCommandEncoder(descriptor: descriptor) else {
            return
        }

        renderEncoder.setRenderPipelineState(pipelineState)

        if let particleBuffer = particleBuffer {
            renderEncoder.setVertexBuffer(particleBuffer, offset: 0, index: 0)
            renderEncoder.drawPrimitives(type: .point, vertexStart: 0, vertexCount: particles.count)
        }

        renderEncoder.endEncoding()

        if let drawable = view.currentDrawable {
            commandBuffer.present(drawable)
        }

        commandBuffer.commit()
    }
}
