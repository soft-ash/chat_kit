/// Human-readable file size, e.g. `482 KB`, `3.1 MB` — used by the
/// document message widget so raw byte counts never leak into the UI.
String formatFileSize(int? bytes) {
  if (bytes == null || bytes <= 0) return '';
  const units = ['B', 'KB', 'MB', 'GB'];
  double size = bytes.toDouble();
  var unitIndex = 0;
  while (size >= 1024 && unitIndex < units.length - 1) {
    size /= 1024;
    unitIndex++;
  }
  final formatted = unitIndex == 0 ? size.toStringAsFixed(0) : size.toStringAsFixed(1);
  return '$formatted ${units[unitIndex]}';
}
