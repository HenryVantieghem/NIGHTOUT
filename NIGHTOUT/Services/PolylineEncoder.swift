//
//  PolylineEncoder.swift
//  NIGHTOUT
//
//  Google Polyline Algorithm encoding/decoding for efficient GPS route storage
//  Based on: https://developers.google.com/maps/documentation/utilities/polylinealgorithm
//

import Foundation
import CoreLocation

/// Encodes and decodes GPS coordinates using Google's Polyline Algorithm
/// Achieves ~90% compression vs raw lat/lng storage
enum PolylineEncoder {

    /// Precision for encoding (5 = standard, 6 = high precision)
    private static let precision: Double = 1e5

    // MARK: - Encoding

    /// Encode an array of coordinates to a polyline string
    /// - Parameter coordinates: Array of CLLocationCoordinate2D
    /// - Returns: Encoded polyline string
    static func encode(_ coordinates: [CLLocationCoordinate2D]) -> String {
        guard !coordinates.isEmpty else { return "" }

        var result = ""
        var previousLat: Int = 0
        var previousLng: Int = 0

        for coordinate in coordinates {
            let lat = Int(round(coordinate.latitude * precision))
            let lng = Int(round(coordinate.longitude * precision))

            result += encodeValue(lat - previousLat)
            result += encodeValue(lng - previousLng)

            previousLat = lat
            previousLng = lng
        }

        return result
    }

    /// Encode an array of CLLocation to a polyline string
    /// - Parameter locations: Array of CLLocation
    /// - Returns: Encoded polyline string
    static func encode(_ locations: [CLLocation]) -> String {
        encode(locations.map { $0.coordinate })
    }

    /// Encode a single integer value using the polyline algorithm
    private static func encodeValue(_ value: Int) -> String {
        var v = value < 0 ? ~(value << 1) : (value << 1)
        var result = ""

        while v >= 0x20 {
            let char = Character(UnicodeScalar((0x20 | (v & 0x1f)) + 63)!)
            result.append(char)
            v >>= 5
        }

        let char = Character(UnicodeScalar(v + 63)!)
        result.append(char)

        return result
    }

    // MARK: - Decoding

    /// Decode a polyline string to an array of coordinates
    /// - Parameter polyline: Encoded polyline string
    /// - Returns: Array of CLLocationCoordinate2D
    static func decode(_ polyline: String) -> [CLLocationCoordinate2D] {
        guard !polyline.isEmpty else { return [] }

        var coordinates: [CLLocationCoordinate2D] = []
        var index = polyline.startIndex
        var lat: Int = 0
        var lng: Int = 0

        while index < polyline.endIndex {
            // Decode latitude
            let (latDelta, newIndex1) = decodeValue(polyline, from: index)
            lat += latDelta
            index = newIndex1

            guard index < polyline.endIndex else { break }

            // Decode longitude
            let (lngDelta, newIndex2) = decodeValue(polyline, from: index)
            lng += lngDelta
            index = newIndex2

            let coordinate = CLLocationCoordinate2D(
                latitude: Double(lat) / precision,
                longitude: Double(lng) / precision
            )
            coordinates.append(coordinate)
        }

        return coordinates
    }

    /// Decode a single value from the polyline string
    private static func decodeValue(_ polyline: String, from startIndex: String.Index) -> (value: Int, nextIndex: String.Index) {
        var result: Int = 0
        var shift: Int = 0
        var index = startIndex

        while index < polyline.endIndex {
            let char = polyline[index]
            let b = Int(char.asciiValue!) - 63
            result |= (b & 0x1f) << shift
            shift += 5
            index = polyline.index(after: index)

            if b < 0x20 {
                break
            }
        }

        // Handle negative values
        let value = (result & 1) == 1 ? ~(result >> 1) : (result >> 1)
        return (value, index)
    }

    // MARK: - Simplification (Douglas-Peucker Algorithm)

    /// Simplify a polyline using Douglas-Peucker algorithm
    /// - Parameters:
    ///   - coordinates: Array of coordinates to simplify
    ///   - tolerance: Tolerance in degrees (default 0.00005 ≈ 5 meters)
    /// - Returns: Simplified array of coordinates
    static func simplify(_ coordinates: [CLLocationCoordinate2D], tolerance: Double = 0.00005) -> [CLLocationCoordinate2D] {
        guard coordinates.count > 2 else { return coordinates }

        return douglasPeucker(coordinates, tolerance: tolerance)
    }

    /// Douglas-Peucker recursive simplification
    private static func douglasPeucker(_ points: [CLLocationCoordinate2D], tolerance: Double) -> [CLLocationCoordinate2D] {
        guard points.count > 2 else { return points }

        var maxDistance: Double = 0
        var maxIndex = 0

        let first = points.first!
        let last = points.last!

        for i in 1..<(points.count - 1) {
            let distance = perpendicularDistance(points[i], from: first, to: last)
            if distance > maxDistance {
                maxDistance = distance
                maxIndex = i
            }
        }

        if maxDistance > tolerance {
            let left = douglasPeucker(Array(points[0...maxIndex]), tolerance: tolerance)
            let right = douglasPeucker(Array(points[maxIndex...]), tolerance: tolerance)

            return left.dropLast() + right
        } else {
            return [first, last]
        }
    }

    /// Calculate perpendicular distance from a point to a line segment
    private static func perpendicularDistance(_ point: CLLocationCoordinate2D, from start: CLLocationCoordinate2D, to end: CLLocationCoordinate2D) -> Double {
        let dx = end.longitude - start.longitude
        let dy = end.latitude - start.latitude

        let magnitude = sqrt(dx * dx + dy * dy)
        guard magnitude > 0 else {
            return sqrt(pow(point.latitude - start.latitude, 2) + pow(point.longitude - start.longitude, 2))
        }

        let u = ((point.longitude - start.longitude) * dx + (point.latitude - start.latitude) * dy) / (magnitude * magnitude)

        let closestX: Double
        let closestY: Double

        if u < 0 {
            closestX = start.longitude
            closestY = start.latitude
        } else if u > 1 {
            closestX = end.longitude
            closestY = end.latitude
        } else {
            closestX = start.longitude + u * dx
            closestY = start.latitude + u * dy
        }

        return sqrt(pow(point.latitude - closestY, 2) + pow(point.longitude - closestX, 2))
    }

    // MARK: - Utilities

    /// Calculate the total distance of a route in meters
    /// - Parameter coordinates: Array of coordinates
    /// - Returns: Total distance in meters
    static func calculateDistance(_ coordinates: [CLLocationCoordinate2D]) -> Double {
        guard coordinates.count > 1 else { return 0 }

        var totalDistance: Double = 0
        for i in 1..<coordinates.count {
            let from = CLLocation(latitude: coordinates[i-1].latitude, longitude: coordinates[i-1].longitude)
            let to = CLLocation(latitude: coordinates[i].latitude, longitude: coordinates[i].longitude)
            totalDistance += from.distance(from: to)
        }

        return totalDistance
    }

    /// Get the bounding region for a set of coordinates
    /// - Parameter coordinates: Array of coordinates
    /// - Returns: MKCoordinateRegion that fits all coordinates with padding
    static func boundingRegion(for coordinates: [CLLocationCoordinate2D], padding: Double = 1.2) -> (center: CLLocationCoordinate2D, span: (latDelta: Double, lngDelta: Double))? {
        guard !coordinates.isEmpty else { return nil }

        var minLat = coordinates[0].latitude
        var maxLat = coordinates[0].latitude
        var minLng = coordinates[0].longitude
        var maxLng = coordinates[0].longitude

        for coord in coordinates {
            minLat = min(minLat, coord.latitude)
            maxLat = max(maxLat, coord.latitude)
            minLng = min(minLng, coord.longitude)
            maxLng = max(maxLng, coord.longitude)
        }

        let center = CLLocationCoordinate2D(
            latitude: (minLat + maxLat) / 2,
            longitude: (minLng + maxLng) / 2
        )

        let latDelta = max((maxLat - minLat) * padding, 0.01) // Minimum span
        let lngDelta = max((maxLng - minLng) * padding, 0.01)

        return (center, (latDelta, lngDelta))
    }
}
