#ifndef WAZE_RECOVERY_CANVAS_RENDERER_HPP
#define WAZE_RECOVERY_CANVAS_RENDERER_HPP

#include "../Geometry/Coordinate.hpp"
#include <vector>

namespace Waze {
namespace Rendering {

struct ViewportPoint {
    float x;
    float y;

    ViewportPoint() : x(0.0f), y(0.0f) {}
    ViewportPoint(float x_, float y_) : x(x_), y(y_) {}
};

struct CameraState {
    Geometry::Coordinate center;
    double zoomLevel;     // 1.0 (world) to 20.0 (street level)
    double bearingDegrees; // Rotation around Z axis [0, 360)
    double tiltDegrees;   // Pitch [0, 60]
    float viewportWidth;
    float viewportHeight;

    CameraState()
        : zoomLevel(15.0),
          bearingDegrees(0.0),
          tiltDegrees(0.0),
          viewportWidth(375.0f),
          viewportHeight(812.0f) {}
};

struct RenderVertex {
    float position[2]; // (x, y) NDC [-1.0, 1.0]
    float color[4];    // (r, g, b, a)
    float texCoord[2]; // (u, v)
};

class CanvasRenderer {
public:
    CanvasRenderer() = default;
    ~CanvasRenderer() = default;

    void setCameraState(const CameraState& camera) { camera_ = camera; }
    const CameraState& cameraState() const { return camera_; }

    /**
     * Converts WGS84 coordinate to viewport pixel coordinates (top-left origin).
     */
    ViewportPoint projectToViewport(const Geometry::Coordinate& coord) const;

    /**
     * Converts viewport pixel coordinates to Normalized Device Coordinates (NDC) [-1.0, 1.0].
     */
    ViewportPoint viewportToNDC(const ViewportPoint& vp) const;

    /**
     * Tessellates a route polyline into triangle strip / mesh vertices for Metal rendering.
     */
    std::vector<RenderVertex> tessellatePolyline(
        const std::vector<Geometry::Coordinate>& polyline,
        float widthPixels,
        float r, float g, float b, float a) const;

private:
    CameraState camera_;
};

} // namespace Rendering
} // namespace Waze

#endif // WAZE_RECOVERY_CANVAS_RENDERER_HPP
