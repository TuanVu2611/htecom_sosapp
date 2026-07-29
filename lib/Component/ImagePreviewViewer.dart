// ignore_for_file: file_names

import 'package:flutter/material.dart';
import 'package:hcmu_sos/Theme/AppTypography.dart';

class ImagePreviewViewer {
  const ImagePreviewViewer._();

  static Future<void> show(
    BuildContext context, {
    required List<String> imageUrls,
    int initialIndex = 0,
    String heroTagPrefix = 'image-preview',
  }) {
    final urls = imageUrls.where((url) => url.trim().isNotEmpty).toList();
    if (urls.isEmpty) {
      return Future.value();
    }

    final safeIndex = initialIndex.clamp(0, urls.length - 1);
    return Navigator.of(context).push(
      PageRouteBuilder<void>(
        opaque: false,
        barrierColor: Colors.black,
        transitionDuration: const Duration(milliseconds: 260),
        reverseTransitionDuration: const Duration(milliseconds: 220),
        pageBuilder: (_, _, _) => _ImagePreviewPage(
          imageUrls: urls,
          initialIndex: safeIndex,
          heroTagPrefix: heroTagPrefix,
        ),
        transitionsBuilder: (_, animation, _, child) {
          final curved = CurvedAnimation(
            parent: animation,
            curve: Curves.easeOutCubic,
            reverseCurve: Curves.easeInCubic,
          );
          return FadeTransition(opacity: curved, child: child);
        },
      ),
    );
  }

  static String heroTag(String prefix, int index) => '$prefix-$index';
}

class _ImagePreviewPage extends StatefulWidget {
  const _ImagePreviewPage({
    required this.imageUrls,
    required this.initialIndex,
    required this.heroTagPrefix,
  });

  final List<String> imageUrls;
  final int initialIndex;
  final String heroTagPrefix;

  @override
  State<_ImagePreviewPage> createState() => _ImagePreviewPageState();
}

class _ImagePreviewPageState extends State<_ImagePreviewPage> {
  late final PageController _pageController;
  late final List<GlobalKey<_ZoomablePreviewImageState>> _imageKeys;
  late int _currentIndex;
  bool _closing = false;

  @override
  void initState() {
    super.initState();
    _currentIndex = widget.initialIndex;
    _pageController = PageController(initialPage: widget.initialIndex);
    _imageKeys = List.generate(
      widget.imageUrls.length,
      (_) => GlobalKey<_ZoomablePreviewImageState>(),
    );
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: _closing,
      onPopInvokedWithResult: (didPop, _) {
        if (!didPop) {
          _close();
        }
      },
      child: Scaffold(
        backgroundColor: Colors.black,
        body: SafeArea(
          child: Stack(
            children: [
              PageView.builder(
                controller: _pageController,
                itemCount: widget.imageUrls.length,
                onPageChanged: (index) => setState(() => _currentIndex = index),
                itemBuilder: (context, index) {
                  return _ZoomablePreviewImage(
                    key: _imageKeys[index],
                    imageUrl: widget.imageUrls[index],
                    heroTag: ImagePreviewViewer.heroTag(
                      widget.heroTagPrefix,
                      index,
                    ),
                  );
                },
              ),
              Positioned(
                left: 16,
                right: 16,
                top: 10,
                child: Row(
                  children: [
                    _OverlayCircleButton(
                      icon: Icons.close_rounded,
                      onTap: _close,
                    ),
                    const Spacer(),
                    _CounterPill(
                      current: _currentIndex + 1,
                      total: widget.imageUrls.length,
                    ),
                  ],
                ),
              ),
              if (widget.imageUrls.length > 1)
                Positioned(
                  left: 18,
                  right: 18,
                  bottom: 18,
                  child: _PreviewDots(
                    count: widget.imageUrls.length,
                    currentIndex: _currentIndex,
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _close() async {
    if (_closing) {
      return;
    }
    setState(() => _closing = true);
    await _imageKeys[_currentIndex].currentState?.resetZoom();
    if (mounted) {
      Navigator.of(context).pop();
    }
  }
}

class _ZoomablePreviewImage extends StatefulWidget {
  const _ZoomablePreviewImage({
    super.key,
    required this.imageUrl,
    required this.heroTag,
  });

  final String imageUrl;
  final String heroTag;

  @override
  State<_ZoomablePreviewImage> createState() => _ZoomablePreviewImageState();
}

class _ZoomablePreviewImageState extends State<_ZoomablePreviewImage> {
  late final TransformationController _controller;
  TapDownDetails? _doubleTapDetails;
  bool _zoomed = false;

  @override
  void initState() {
    super.initState();
    _controller = TransformationController();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.sizeOf(context);
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onDoubleTapDown: (details) => _doubleTapDetails = details,
      onDoubleTap: _toggleZoom,
      child: Center(
        child: InteractiveViewer(
          transformationController: _controller,
          minScale: 1,
          maxScale: 4.5,
          panEnabled: true,
          scaleEnabled: true,
          clipBehavior: Clip.none,
          child: Hero(
            tag: widget.heroTag,
            child: Image.network(
              widget.imageUrl,
              width: size.width,
              height: size.height,
              fit: BoxFit.contain,
              loadingBuilder: (context, child, progress) {
                if (progress == null) {
                  return child;
                }
                return const SizedBox(
                  width: 44,
                  height: 44,
                  child: CircularProgressIndicator(
                    strokeWidth: 2.4,
                    color: Colors.white,
                  ),
                );
              },
              errorBuilder: (_, _, _) => const Icon(
                Icons.broken_image_outlined,
                color: Colors.white70,
                size: 42,
              ),
            ),
          ),
        ),
      ),
    );
  }

  void _toggleZoom() {
    const scale = 2.35;
    if (_zoomed) {
      setState(() => _zoomed = false);
      _controller.value = Matrix4.identity();
      return;
    }

    final tapPosition = _doubleTapDetails?.localPosition;
    if (tapPosition == null) {
      _controller.value = Matrix4.identity()..scale(scale);
    } else {
      _controller.value = Matrix4.identity()
        ..translate(
          -tapPosition.dx * (scale - 1),
          -tapPosition.dy * (scale - 1),
        )
        ..scale(scale);
    }
    setState(() => _zoomed = true);
  }

  Future<void> resetZoom() async {
    setState(() => _zoomed = false);
    _controller.value = Matrix4.identity();
    await Future<void>.delayed(const Duration(milliseconds: 32));
  }
}

class _OverlayCircleButton extends StatelessWidget {
  const _OverlayCircleButton({required this.icon, required this.onTap});

  final IconData icon;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.white.withValues(alpha: 0.14),
      shape: const CircleBorder(),
      child: InkWell(
        onTap: onTap,
        customBorder: const CircleBorder(),
        child: SizedBox(
          width: 44,
          height: 44,
          child: Icon(icon, color: Colors.white, size: 24),
        ),
      ),
    );
  }
}

class _CounterPill extends StatelessWidget {
  const _CounterPill({required this.current, required this.total});

  final int current;
  final int total;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 13, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.14),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: Colors.white.withValues(alpha: 0.12)),
      ),
      child: Text(
        '$current / $total',
        style: AppTextStyles.caption.copyWith(
          color: Colors.white,
          fontSize: AppFontSizes.base,
          fontWeight: FontWeight.w900,
          height: 1,
        ),
      ),
    );
  }
}

class _PreviewDots extends StatelessWidget {
  const _PreviewDots({required this.count, required this.currentIndex});

  final int count;
  final int currentIndex;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        for (var index = 0; index < count; index++)
          AnimatedContainer(
            duration: const Duration(milliseconds: 180),
            curve: Curves.easeOutCubic,
            width: index == currentIndex ? 18 : 7,
            height: 7,
            margin: const EdgeInsets.symmetric(horizontal: 3),
            decoration: BoxDecoration(
              color: Colors.white.withValues(
                alpha: index == currentIndex ? 0.95 : 0.35,
              ),
              borderRadius: BorderRadius.circular(999),
            ),
          ),
      ],
    );
  }
}
