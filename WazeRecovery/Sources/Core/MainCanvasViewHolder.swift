import Foundation
import UIKit
import MetalKit

public protocol MainCanvasViewHolderDelegate: AnyObject {
    func mainCanvasViewHolder(_ holder: MainCanvasViewHolder, didChangeCameraCenter center: WZCoordinate, zoom: Double)
    func mainCanvasViewHolder(_ holder: MainCanvasViewHolder, didTapCoordinate coordinate: WZCoordinate)
}

/// Reconstructed from MainCanvasViewHolder (0x107f1a4a0) in Waze ARM64 executable.
/// Primary container for the vector map canvas on iOS; instantiates Metal view controller.
public final class MainCanvasViewHolder: NSObject {
    public weak var delegate: MainCanvasViewHolderDelegate?

    public private(set) var metalViewController: UIViewController?
    public private(set) var cameraCenter: WZCoordinate
    public private(set) var zoomLevel: Double = 15.0
    public private(set) var bearingDegrees: Double = 0.0

    private var activePolyline: [WZCoordinate] = []

    public init(initialCenter: WZCoordinate = WZCoordinate(latitude: 37.7749, longitude: -122.4194)) {
        self.cameraCenter = initialCenter
        super.init()
    }

    /// Disassembled selector createMetalViewController:
    /// Instantiates Metal-backed view controller or fallback vector canvas.
    public func createMetalViewController() -> UIViewController {
        let vc = CanvasMapViewController()
        vc.viewHolder = self
        self.metalViewController = vc
        return vc
    }

    public func setCamera(center: WZCoordinate, zoom: Double, bearing: Double = 0.0) {
        self.cameraCenter = center
        self.zoomLevel = max(1.0, min(20.0, zoom))
        self.bearingDegrees = bearing
        delegate?.mainCanvasViewHolder(self, didChangeCameraCenter: center, zoom: self.zoomLevel)
        (metalViewController as? CanvasMapViewController)?.updateRouteDisplay(activePolyline)
    }

    public func setRoutePolyline(_ polyline: [WZCoordinate]) {
        self.activePolyline = polyline
        (metalViewController as? CanvasMapViewController)?.updateRouteDisplay(polyline)
    }

    public func clearRoute() {
        self.activePolyline.removeAll()
        (metalViewController as? CanvasMapViewController)?.updateRouteDisplay([])
    }
}

/// Internal Metal / UIKit canvas view controller representing Waze map viewport.
internal final class CanvasMapViewController: UIViewController, MTKViewDelegate {
    weak var viewHolder: MainCanvasViewHolder?

    private var mtkView: MTKView?
    private var metalDevice: MTLDevice?
    private var commandQueue: MTLCommandQueue?
    private let routeLayer = CAShapeLayer()
    private var panStartCenter: WZCoordinate?

    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = UIColor(red: 0.94, green: 0.95, blue: 0.96, alpha: 1.0) // Waze map canvas grey

        // Initialize Metal if available
        if let device = MTLCreateSystemDefaultDevice() {
            self.metalDevice = device
            self.commandQueue = device.makeCommandQueue()

            let mtk = MTKView(frame: view.bounds, device: device)
            mtk.autoresizingMask = [.flexibleWidth, .flexibleHeight]
            mtk.delegate = self
            mtk.clearColor = MTLClearColor(red: 0.94, green: 0.95, blue: 0.96, alpha: 1.0)
            view.addSubview(mtk)
            self.mtkView = mtk
        }

        // Setup route vector layer
        routeLayer.strokeColor = UIColor(red: 0.20, green: 0.80, blue: 1.00, alpha: 0.95).cgColor // Waze cyan route
        routeLayer.lineWidth = 6.0
        routeLayer.lineCap = .round
        routeLayer.lineJoin = .round
        routeLayer.fillColor = nil
        view.layer.addSublayer(routeLayer)

        setupGestures()
    }

    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        routeLayer.frame = view.bounds
        if let holder = viewHolder {
            updateRouteDisplay(holder.activePolyline)
        }
    }

    public func updateRouteDisplay(_ polyline: [WZCoordinate]) {
        guard !polyline.isEmpty, let holder = viewHolder, view.bounds.width > 0 else {
            routeLayer.path = nil
            return
        }

        let path = UIBezierPath()
        let scale = 256.0 * pow(2.0, holder.zoomLevel)
        let centerPt = CGPoint(x: view.bounds.midX, y: view.bounds.midY)

        for (i, coord) in polyline.enumerated() {
            let lonDelta = coord.longitude - holder.cameraCenter.longitude
            let latDelta = coord.latitude - holder.cameraCenter.latitude

            let x = centerPt.x + CGFloat(lonDelta / 360.0 * scale)
            let y = centerPt.y - CGFloat(latDelta / 180.0 * scale)

            if i == 0 {
                path.move(to: CGPoint(x: x, y: y))
            } else {
                path.addLine(to: CGPoint(x: x, y: y))
            }
        }
        routeLayer.path = path.cgPath
    }

    private func setupGestures() {
        let tap = UITapGestureRecognizer(target: self, action: #selector(handleTap(_:)))
        view.addGestureRecognizer(tap)

        let pan = UIPanGestureRecognizer(target: self, action: #selector(handlePan(_:)))
        view.addGestureRecognizer(pan)

        let pinch = UIPinchGestureRecognizer(target: self, action: #selector(handlePinch(_:)))
        view.addGestureRecognizer(pinch)
    }

    @objc private func handleTap(_ gesture: UITapGestureRecognizer) {
        guard let holder = viewHolder else { return }
        holder.delegate?.mainCanvasViewHolder(holder, didTapCoordinate: holder.cameraCenter)
    }

    @objc private func handlePan(_ gesture: UIPanGestureRecognizer) {
        guard let holder = viewHolder else { return }
        switch gesture.state {
        case .began:
            panStartCenter = holder.cameraCenter
        case .changed:
            guard let start = panStartCenter else { return }
            let translation = gesture.translation(in: view)
            let scale = 256.0 * pow(2.0, holder.zoomLevel)
            let lonDelta = -Double(translation.x) / scale * 360.0
            let latDelta = Double(translation.y) / scale * 180.0

            let newLon = min(180.0, max(-180.0, start.longitude + lonDelta))
            let newLat = min(85.0, max(-85.0, start.latitude + latDelta))
            holder.setCamera(center: WZCoordinate(latitude: newLat, longitude: newLon),
                             zoom: holder.zoomLevel,
                             bearing: holder.bearingDegrees)
        case .ended, .cancelled:
            panStartCenter = nil
        default:
            break
        }
    }

    @objc private func handlePinch(_ gesture: UIPinchGestureRecognizer) {
        guard let holder = viewHolder, gesture.state == .changed else { return }
        let newZoom = holder.zoomLevel + (gesture.scale > 1.0 ? 0.15 : -0.15)
        holder.setCamera(center: holder.cameraCenter, zoom: newZoom, bearing: holder.bearingDegrees)
        gesture.scale = 1.0
    }

    // MARK: - MTKViewDelegate
    func mtkView(_ view: MTKView, drawableSizeWillChange size: CGSize) {}

    func draw(in view: MTKView) {
        guard let drawable = view.currentDrawable,
              let renderPassDescriptor = view.currentRenderPassDescriptor,
              let cmdBuffer = commandQueue?.makeCommandBuffer(),
              let encoder = cmdBuffer.makeRenderCommandEncoder(descriptor: renderPassDescriptor) else {
            return
        }

        encoder.endEncoding()
        cmdBuffer.present(drawable)
        cmdBuffer.commit()
    }
}
