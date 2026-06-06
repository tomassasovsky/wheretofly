import 'aip_coord.dart';

/// A boundary segment — either a straight geodesic or a circular arc.
sealed class AipSegment {
  const AipSegment(this.to);
  final AipCoord to;
}

/// Great-circle line from the preceding point to [to].
class StraightSegment extends AipSegment {
  const StraightSegment(super.to);
}

/// Circular arc centred on [center] with [radiusNm] radius.
///
/// [directionHint] is the cardinal/intercardinal direction text from
/// "hacia el …" in the AIP (e.g. "Sur", "NO"), used to choose which way
/// around the circle to go when [clockwise] is null.
///
/// [clockwise] is set explicitly from "en sentido horario / antihorario".
class ArcSegment extends AipSegment {
  const ArcSegment({
    required this.center,
    required this.radiusNm,
    required AipCoord to,
    this.directionHint,
    this.clockwise,
  }) : super(to);

  final AipCoord center;
  final double radiusNm;
  final String? directionHint;
  final bool? clockwise;
}

/// A full circle centred on [center] with [radiusNm] radius (no start/end).
class CircleSegment extends AipSegment {
  const CircleSegment({
    required this.center,
    required this.radiusNm,
  }) : super(center); // [to] unused for full circles — set to centre

  final AipCoord center;
  final double radiusNm;
}
