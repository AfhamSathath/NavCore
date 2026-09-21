import 'dart:math';

/// NexNav Core Math Engine - ECEF (Earth-Centered, Earth-Fixed) Positioning
/// Implements Section 6 of NexNav Technical Spec (WGS 84 reference ellipsoid)

class GeodeticCoords {
  final double latitude; // degrees φ
  final double longitude; // degrees λ
  final double height; // meters h above WGS 84 reference ellipsoid

  const GeodeticCoords({
    required this.latitude,
    required this.longitude,
    required this.height,
  });

  GeodeticCoords copyWith({
    double? latitude,
    double? longitude,
    double? height,
  }) {
    return GeodeticCoords(
      latitude: latitude ?? this.latitude,
      longitude: longitude ?? this.longitude,
      height: height ?? this.height,
    );
  }
}

class ECEFCoords {
  final double x; // meters X_ECEF
  final double y; // meters Y_ECEF
  final double z; // meters Z_ECEF

  const ECEFCoords({required this.x, required this.y, required this.z});
}

// WGS 84 Ellipsoid Parameters
const double wgs84A = 6378137.0; // Semi-major axis (meters)
const double wgs84E2 = 0.006694379990141317; // First eccentricity squared (e²)

/// Calculates radius of curvature in prime vertical N(φ)
double calculateN(double latitudeDeg) {
  final phi = (latitudeDeg * pi) / 180.0;
  final sinPhi = sin(phi);
  return wgs84A / sqrt(1.0 - wgs84E2 * sinPhi * sinPhi);
}

/// Converts Geodetic coordinates (Lat, Lon, Height) to ECEF (X, Y, Z)
/// Section 6 Equations:
/// X_ECEF = (N + h) * cos(φ) * cos(λ)
/// Y_ECEF = (N + h) * cos(φ) * sin(λ)
/// Z_ECEF = (N * (1 - e²) + h) * sin(φ)
ECEFCoords geodeticToECEF(GeodeticCoords coords) {
  final phi = (coords.latitude * pi) / 180.0;
  final lambda = (coords.longitude * pi) / 180.0;
  final h = coords.height;

  final n = calculateN(coords.latitude);
  final cosPhi = cos(phi);
  final sinPhi = sin(phi);
  final cosLambda = cos(lambda);
  final sinLambda = sin(lambda);

  final x = (n + h) * cosPhi * cosLambda;
  final y = (n + h) * cosPhi * sinLambda;
  final z = (n * (1.0 - wgs84E2) + h) * sinPhi;

  return ECEFCoords(x: x, y: y, z: z);
}

/// Converts ECEF coordinates (X, Y, Z) back to Geodetic (Lat, Lon, Height)
GeodeticCoords ecefToGeodetic(ECEFCoords ecef) {
  final x = ecef.x;
  final y = ecef.y;
  final z = ecef.z;
  final b = sqrt(wgs84A * wgs84A * (1.0 - wgs84E2));
  final ep2 = (wgs84A * wgs84A - b * b) / (b * b);
  final p = sqrt(x * x + y * y);
  final theta = atan2(wgs84A * z, b * p);

  final sinTheta = sin(theta);
  final cosTheta = cos(theta);

  final latitudeRad = atan2(
    z + ep2 * b * pow(sinTheta, 3),
    p - wgs84E2 * wgs84A * pow(cosTheta, 3),
  );

  final longitudeRad = atan2(y, x);
  final n = calculateN((latitudeRad * 180.0) / pi);
  final height = p / cos(latitudeRad) - n;

  return GeodeticCoords(
    latitude: (latitudeRad * 180.0) / pi,
    longitude: (longitudeRad * 180.0) / pi,
    height: height,
  );
}

/// Calculates 3D Euclidean distance in fixed ECEF frame
double ecefDistance(ECEFCoords p1, ECEFCoords p2) {
  final dx = p2.x - p1.x;
  final dy = p2.y - p1.y;
  final dz = p2.z - p1.z;
  return sqrt(dx * dx + dy * dy + dz * dz);
}
