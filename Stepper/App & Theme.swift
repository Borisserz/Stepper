import SwiftUI
import MapKit

// MARK: - EXTENSIONS (ДОСТАЕМ ИЗВИЛИСТЫЙ МАРШРУТ ИЗ APPLE MAPS)
extension MKRoute {
    var coordinates: [CLLocationCoordinate2D] {
        let pointCount = self.polyline.pointCount
        var coords = [CLLocationCoordinate2D](repeating: kCLLocationCoordinate2DInvalid, count: pointCount)
        self.polyline.getCoordinates(&coords, range: NSRange(location: 0, length: pointCount))
        return coords
    }
}
