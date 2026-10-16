#include "CanvasRenderer.hpp"
#include <cmath>

namespace Waze {
namespace Rendering {

static constexpr double kPi = 3.14159265358979323846;

static inline double degreesToRadians(double deg) {
    return deg * (kPi / 180.0);
}

ViewportPoint CanvasRenderer::projectToViewport(const Geometry::Coordinate& coord) const {
    if (camera_.viewportWidth <= 0 || camera_.viewportHeight <= 0) {
        return ViewportPoint(0.0f, 0.0f);
    }

    // Standard Spherical Web Mercator projection
    double scale = 256.0 * std::pow(2.0, camera_.zoomLevel);

    // Mercator X
    double centerWorldX = (camera_.center.longitude + 180.0) / 360.0 * scale;
    double pointWorldX = (coord.longitude + 180.0) / 360.0 * scale;

    // Mercator Y
    double centerLatRad = degreesToRadians(camera_.center.latitude);
    double centerWorldY = (1.0 - std::log(std::tan(centerLatRad) + 1.0 / std::cos(centerLatRad)) / kPi) / 2.0 * scale;

    double pointLatRad = degreesToRadians(coord.latitude);
    double pointWorldY = (1.0 - std::log(std::tan(pointLatRad) + 1.0 / std::cos(pointLatRad)) / kPi) / 2.0 * scale;

    // Delta in screen space (relative to center)
    double dx = pointWorldX - centerWorldX;
    double dy = pointWorldY - centerWorldY;

    // Rotate according to camera bearing
    if (std::fabs(camera_.bearingDegrees) > 1e-3) {
        double rotRad = -degreesToRadians(camera_.bearingDegrees);
        double cosR = std::cos(rotRad);
        double sinR = std::sin(rotRad);
        double rx = dx * cosR - dy * sinR;
        double ry = dx * sinR + dy * cosR;
        dx = rx;
        dy = ry;
    }

    float screenX = static_cast<float>(camera_.viewportWidth / 2.0 + dx);
    float screenY = static_cast<float>(camera_.viewportHeight / 2.0 + dy);

    return ViewportPoint(screenX, screenY);
}

ViewportPoint CanvasRenderer::viewportToNDC(const ViewportPoint& vp) const {
    float ndcX = (vp.x / camera_.viewportWidth) * 2.0f - 1.0f;
    float ndcY = 1.0f - (vp.y / camera_.viewportHeight) * 2.0f; // Invert Y for Metal NDC
    return ViewportPoint(ndcX, ndcY);
}

std::vector<RenderVertex> CanvasRenderer::tessellatePolyline(
    const std::vector<Geometry::Coordinate>& polyline,
    float widthPixels,
    float r, float g, float b, float a) const {

    std::vector<RenderVertex> vertices;
    if (polyline.size() < 2) {
        return vertices;
    }

    float halfWidth = widthPixels / 2.0f;

    for (size_t i = 0; i + 1 < polyline.size(); ++i) {
        ViewportPoint p1 = projectToViewport(polyline[i]);
        ViewportPoint p2 = projectToViewport(polyline[i + 1]);

        float dx = p2.x - p1.x;
        float dy = p2.y - p1.y;
        float len = std::sqrt(dx * dx + dy * dy);
        if (len < 1e-4f) continue;

        // Normal perpendicular vector
        float nx = -dy / len * halfWidth;
        float ny = dx / len * halfWidth;

        ViewportPoint v1(p1.x + nx, p1.y + ny);
        ViewportPoint v2(p1.x - nx, p1.y - ny);
        ViewportPoint v3(p2.x + nx, p2.y + ny);
        ViewportPoint v4(p2.x - nx, p2.y - ny);

        ViewportPoint ndc1 = viewportToNDC(v1);
        ViewportPoint ndc2 = viewportToNDC(v2);
        ViewportPoint ndc3 = viewportToNDC(v3);
        ViewportPoint ndc4 = viewportToNDC(v4);

        // Quad = 2 triangles (ndc1, ndc2, ndc3) and (ndc2, ndc4, ndc3)
        RenderVertex vert1{{ndc1.x, ndc1.y}, {r, g, b, a}, {0.0f, 0.0f}};
        RenderVertex vert2{{ndc2.x, ndc2.y}, {r, g, b, a}, {1.0f, 0.0f}};
        RenderVertex vert3{{ndc3.x, ndc3.y}, {r, g, b, a}, {0.0f, 1.0f}};
        RenderVertex vert4{{ndc4.x, ndc4.y}, {r, g, b, a}, {1.0f, 1.0f}};

        vertices.push_back(vert1);
        vertices.push_back(vert2);
        vertices.push_back(vert3);

        vertices.push_back(vert2);
        vertices.push_back(vert4);
        vertices.push_back(vert3);
    }

    return vertices;
}

} // namespace Rendering
} // namespace Waze
