import 'package:flutter/material.dart';

import '../../theme/chat_colors.dart';
import '../../theme/chat_theme.dart';

/// Renders a location attachment as a compact map-style card — a pin
/// badge over either a real static-map snapshot ([staticMapImageUrl],
/// e.g. from Google Static Maps or Mapbox, fetched however the host app
/// likes) or a plain gridded placeholder when none is supplied.
///
/// The package has no maps SDK dependency of its own (see doc section 32,
/// dependency policy) — this widget only draws what you give it. Tapping
/// opens whatever the host app wants via [onTap], typically the native
/// maps app with the coordinates from `message.metadata`.
class LocationPreviewCard extends StatelessWidget {
  final String address;
  final String? label;
  final String? staticMapImageUrl;
  final ChatTheme theme;
  final VoidCallback? onTap;

  static const double _mapHeight = 110;
  static const double _width = 220;

  const LocationPreviewCard({
    super.key,
    required this.address,
    required this.theme,
    this.label = 'Pinned location',
    this.staticMapImageUrl,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final colors = theme.colors;
    final radius = BorderRadius.circular(theme.dimensions.messageBubbleRadius - 6);

    return GestureDetector(
      onTap: onTap,
      child: ClipRRect(
        borderRadius: radius,
        child: SizedBox(
          width: _width,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              SizedBox(
                height: _mapHeight,
                width: double.infinity,
                child: Stack(
                  fit: StackFit.expand,
                  children: [
                    if (staticMapImageUrl != null && staticMapImageUrl!.isNotEmpty)
                      Image.network(
                        staticMapImageUrl!,
                        fit: BoxFit.cover,
                        errorBuilder: (_, __, ___) => _mapPlaceholder(colors),
                      )
                    else
                      _mapPlaceholder(colors),
                    Center(
                      child: Container(
                        padding: const EdgeInsets.all(6),
                        decoration: const BoxDecoration(color: Colors.black87, shape: BoxShape.circle),
                        child: const Icon(Icons.location_on, color: Colors.white, size: 18),
                      ),
                    ),
                  ],
                ),
              ),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(10),
                color: colors.receiverBubble,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    if (label != null)
                      Text(
                        label!,
                        style: theme.typography.messageText.copyWith(
                          fontWeight: FontWeight.w700,
                          color: colors.receiverText,
                          fontSize: 13,
                        ),
                      ),
                    Text(
                      address,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: theme.typography.timestamp.copyWith(color: colors.hintText),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _mapPlaceholder(ChatColors colors) {
    return Container(
      color: colors.inputBackground,
      child: CustomPaint(painter: _MapGridPainter(lineColor: colors.inputBorder)),
    );
  }
}

/// Faint grid pattern standing in for a real map tile when no
/// [LocationPreviewCard.staticMapImageUrl] is supplied.
class _MapGridPainter extends CustomPainter {
  final Color lineColor;

  const _MapGridPainter({required this.lineColor});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = lineColor
      ..strokeWidth = 1;
    const step = 18.0;
    for (double x = 0; x < size.width; x += step) {
      canvas.drawLine(Offset(x, 0), Offset(x, size.height), paint);
    }
    for (double y = 0; y < size.height; y += step) {
      canvas.drawLine(Offset(0, y), Offset(size.width, y), paint);
    }
  }

  @override
  bool shouldRepaint(covariant _MapGridPainter oldDelegate) => oldDelegate.lineColor != lineColor;
}
