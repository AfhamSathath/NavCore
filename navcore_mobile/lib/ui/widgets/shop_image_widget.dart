import 'package:flutter/material.dart';

/// Custom widget to display shop images seamlessly whether they are local asset paths
/// (e.g., 'assets/images/shops/odel_flagship_store.jpg') or network URLs.
class ShopImage extends StatelessWidget {
  final String imagePathOrUrl;
  final double? width;
  final double? height;
  final BoxFit fit;
  final Widget? fallbackWidget;

  const ShopImage({
    super.key,
    required this.imagePathOrUrl,
    this.width,
    this.height,
    this.fit = BoxFit.cover,
    this.fallbackWidget,
  });

  bool get isNetworkUrl =>
      imagePathOrUrl.startsWith('http://') || imagePathOrUrl.startsWith('https://');

  @override
  Widget build(BuildContext context) {
    final defaultFallback = fallbackWidget ??
        Container(
          width: width,
          height: height,
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              colors: [Color(0xFF1E3A8A), Color(0xFF3B82F6)],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
          ),
          child: const Center(
            child: Icon(
              Icons.storefront_rounded,
              color: Colors.white70,
              size: 28,
            ),
          ),
        );

    if (imagePathOrUrl.trim().isEmpty) {
      return defaultFallback;
    }

    if (isNetworkUrl) {
      return Image.network(
        imagePathOrUrl,
        width: width,
        height: height,
        fit: fit,
        loadingBuilder: (context, child, loadingProgress) {
          if (loadingProgress == null) return child;
          return Container(
            width: width,
            height: height,
            color: const Color(0xFFF1F5F9),
            child: const Center(
              child: SizedBox(
                width: 20,
                height: 20,
                child: CircularProgressIndicator(strokeWidth: 2),
              ),
            ),
          );
        },
        errorBuilder: (context, error, stackTrace) => defaultFallback,
      );
    }

    return Image.asset(
      imagePathOrUrl,
      width: width,
      height: height,
      fit: fit,
      errorBuilder: (context, error, stackTrace) => defaultFallback,
    );
  }
}
