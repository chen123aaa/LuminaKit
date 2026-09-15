import Foundation
import Metal
import MetalKit
import QuartzCore
import simd
import SwiftUI

// MARK: - Uniforms (must match IridescentBlob.metal)

struct BlobUniforms {
    var resolution: SIMD2<Float>
    var time: Float
    var morph: Float
}

// MARK: - Public SwiftUI view

/// Translucent pearl / iridescent soft blob, matching the reference:
/// slow tumble + liquid folds + thin-film pastel highlights on a light gray field.
///
/// ```swift
/// IridescentBlobView()
/// IridescentBlobView(morph: 1.2, speed: 0.8)
/// ```
public struct IridescentBlobView: View {
    public var morph: Float
    public var speed: Float

    public init(morph: Float = 1.0, speed: Float = 1.0) {
        self.morph = morph
        self.speed = speed
    }

    public var body: some View {
        BlobMetalRepresentable(morph: morph, speed: speed)
            .ignoresSafeArea()
            .accessibilityLabel("Iridescent translucent blob animation")
    }
}

// MARK: - Platform bridge

#if os(iOS) || os(tvOS)
import UIKit

struct BlobMetalRepresentable: UIViewRepresentable {
    var morph: Float
    var speed: Float

    func makeCoordinator() -> BlobRenderer { BlobRenderer() }

    func makeUIView(context: Context) -> MTKView {
        makeMTKView(renderer: context.coordinator)
    }

    func updateUIView(_ uiView: MTKView, context: Context) {
        context.coordinator.morph = morph
        context.coordinator.speed = speed
    }
}
#else
import AppKit

struct BlobMetalRepresentable: NSViewRepresentable {
    var morph: Float
    var speed: Float

    func makeCoordinator() -> BlobRenderer { BlobRenderer() }

    func makeNSView(context: Context) -> MTKView {
        makeMTKView(renderer: context.coordinator)
    }

    func updateNSView(_ nsView: MTKView, context: Context) {
        context.coordinator.morph = morph
        context.coordinator.speed = speed
    }
}
#endif

private func makeMTKView(renderer: BlobRenderer) -> MTKView {
    let view = MTKView()
    view.device = MTLCreateSystemDefaultDevice()
    view.framebufferOnly = true
    view.colorPixelFormat = .bgra8Unorm
    view.clearColor = MTLClearColor(red: 0.945, green: 0.945, blue: 0.950, alpha: 1)
    view.preferredFramesPerSecond = 60
    view.enableSetNeedsDisplay = false
    view.isPaused = false
    view.autoResizeDrawable = true
    #if os(iOS) || os(tvOS)
    view.backgroundColor = UIColor(red: 0.945, green: 0.945, blue: 0.950, alpha: 1)
    view.isOpaque = true
    #else
    view.layer?.backgroundColor = CGColor(red: 0.945, green: 0.945, blue: 0.950, alpha: 1)
    #endif

    guard let device = view.device else {
        assertionFailure("Metal is not available")
        return view
    }

    do {
        try renderer.setup(device: device, pixelFormat: view.colorPixelFormat)
        view.delegate = renderer
    } catch {
        assertionFailure("Blob renderer setup failed: \(error)")
    }
    return view
}

// MARK: - Renderer

final class BlobRenderer: NSObject, MTKViewDelegate {
    var morph: Float = 1.0
    var speed: Float = 1.0

    private let startTime = CACurrentMediaTime()
    private var commandQueue: MTLCommandQueue?
    private var pipelineState: MTLRenderPipelineState?
    private var viewportSize = SIMD2<Float>(1, 1)

    enum RendererError: Error {
        case noDevice
        case noLibrary
        case missingFunction(String)
    }

    func setup(device: MTLDevice, pixelFormat: MTLPixelFormat) throws {
        commandQueue = device.makeCommandQueue()

        let library = try loadLibrary(device: device)
        guard let fragment = library.makeFunction(name: "iridescentBlobFragment") else {
            throw RendererError.missingFunction("iridescentBlobFragment")
        }
        guard let vertex = library.makeFunction(name: "fullscreenVertex") else {
            throw RendererError.missingFunction("fullscreenVertex")
        }

        let descriptor = MTLRenderPipelineDescriptor()
        descriptor.vertexFunction = vertex
        descriptor.fragmentFunction = fragment
        descriptor.colorAttachments[0].pixelFormat = pixelFormat
        pipelineState = try device.makeRenderPipelineState(descriptor: descriptor)
    }

    /// Xcode compiles .metal into the default metallib.
    /// SPM ships the .metal as a bundle resource and we compile it at runtime.
    private func loadLibrary(device: MTLDevice) throws -> MTLLibrary {
        if let lib = device.makeDefaultLibrary() {
            return lib
        }
        #if SWIFT_PACKAGE
        if let url = Bundle.module.url(forResource: "IridescentBlob", withExtension: "metal") {
            let source = try String(contentsOf: url, encoding: .utf8)
            return try device.makeLibrary(source: source, options: nil)
        }
        #endif
        if let url = Bundle.main.url(forResource: "IridescentBlob", withExtension: "metal") {
            let source = try String(contentsOf: url, encoding: .utf8)
            return try device.makeLibrary(source: source, options: nil)
        }
        throw RendererError.noLibrary
    }

    func mtkView(_ view: MTKView, drawableSizeWillChange size: CGSize) {
        viewportSize = SIMD2<Float>(Float(max(size.width, 1)), Float(max(size.height, 1)))
    }

    func draw(in view: MTKView) {
        guard
            let pipelineState,
            let drawable = view.currentDrawable,
            let passDescriptor = view.currentRenderPassDescriptor,
            let commandBuffer = commandQueue?.makeCommandBuffer(),
            let encoder = commandBuffer.makeRenderCommandEncoder(descriptor: passDescriptor)
        else { return }

        // Rebuild clear pass color to match the reference background
        passDescriptor.colorAttachments[0].clearColor = MTLClearColor(red: 0.945, green: 0.945, blue: 0.950, alpha: 1)
        passDescriptor.colorAttachments[0].loadAction = .clear

        let elapsed = Float(CACurrentMediaTime() - startTime) * speed
        var uniforms = BlobUniforms(
            resolution: viewportSize,
            time: elapsed,
            morph: morph
        )

        encoder.setRenderPipelineState(pipelineState)
        encoder.setFragmentBytes(&uniforms, length: MemoryLayout<BlobUniforms>.stride, index: 0)
        encoder.drawPrimitives(type: .triangle, vertexStart: 0, vertexCount: 3)
        encoder.endEncoding()

        commandBuffer.present(drawable)
        commandBuffer.commit()
    }
}

// MARK: - Preview

#if DEBUG
struct IridescentBlobView_Previews: PreviewProvider {
    static var previews: some View {
        IridescentBlobView()
    }
}
#endif
