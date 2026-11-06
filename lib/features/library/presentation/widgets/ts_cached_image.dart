import 'dart:io';
import 'package:flutter/material.dart';
import '../../../../core/storage/authenticated_cache.dart';
import '../../../../core/storage/preferences_service.dart';
import '../../../../core/storage/secure_storage_service.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_radii.dart';
import '../../../../injection.dart';

/// Widget de imagen en red autenticada con caché aislada por usuario y fallback amigable.
class TsCachedImage extends StatefulWidget {
  final String imageUrl;
  final BoxFit fit;
  final double? width;
  final double? height;
  final BorderRadius? borderRadius;
  final IconData placeholderIcon;

  const TsCachedImage({
    super.key,
    required this.imageUrl,
    this.fit = BoxFit.cover,
    this.width,
    this.height,
    this.borderRadius,
    this.placeholderIcon = Icons.image_outlined,
  });

  @override
  State<TsCachedImage> createState() => _TsCachedImageState();
}

class _TsCachedImageState extends State<TsCachedImage> {
  File? _imageFile;
  bool _isLoading = true;
  bool _hasError = false;

  @override
  void initState() {
    super.initState();
    _loadImage();
  }

  @override
  void didUpdateWidget(covariant TsCachedImage oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.imageUrl != widget.imageUrl) {
      _loadImage();
    }
  }

  Future<void> _loadImage() async {
    // Si la imagen es un asset local (usado en Modo Demostración), se renderiza directamente sin peticiones de red
    if (widget.imageUrl.startsWith('assets/')) {
      if (mounted) {
        setState(() {
          _isLoading = false;
          _hasError = false;
        });
      }
      return;
    }

    final resolved = AuthenticatedCacheManager.resolveUrl(widget.imageUrl);
    if (resolved.isEmpty) {
      if (mounted) {
        setState(() {
          _isLoading = false;
          _hasError = true;
        });
      }
      return;
    }

    if (mounted) {
      setState(() {
        _isLoading = true;
        _hasError = false;
      });
    }

    try {
      final secureStorage = sl.isRegistered<SecureStorageService>()
          ? sl<SecureStorageService>()
          : SecureStorageService();
      final prefs = sl.isRegistered<PreferencesService>()
          ? sl<PreferencesService>()
          : null;
      final userId = prefs?.currentUserId ?? 'default_user';

      final cacheManager = AuthenticatedCacheManager.forUser(
        userId: userId,
        secureStorageService: secureStorage,
      );

      final headers = await AuthenticatedCacheManager.getAuthHeaders(secureStorage);
      final file = await cacheManager.getSingleFile(resolved, headers: headers);

      if (mounted) {
        setState(() {
          _imageFile = file;
          _isLoading = false;
          _hasError = false;
        });
      }
    } catch (_) {
      if (mounted) {
        setState(() {
          _isLoading = false;
          _hasError = true;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final radius = widget.borderRadius ?? AppRadii.sm;

    Widget content;
    if (widget.imageUrl.startsWith('assets/')) {
      content = Image.asset(
        widget.imageUrl,
        width: widget.width,
        height: widget.height,
        fit: widget.fit,
        errorBuilder: (context, error, stackTrace) => Container(
          width: widget.width,
          height: widget.height,
          color: AppColors.surface2Light,
          child: Center(
            child: Icon(
              widget.placeholderIcon,
              size: 36,
              color: AppColors.textTertiaryLight,
            ),
          ),
        ),
      );
    } else if (_isLoading) {
      content = Container(
        width: widget.width,
        height: widget.height,
        color: AppColors.surface2Light,
        child: const Center(
          child: SizedBox(
            width: 24,
            height: 24,
            child: CircularProgressIndicator(
              strokeWidth: 2,
              valueColor: AlwaysStoppedAnimation<Color>(AppColors.primary500),
            ),
          ),
        ),
      );
    } else if (_hasError || _imageFile == null) {
      content = Container(
        width: widget.width,
        height: widget.height,
        color: AppColors.surface2Light,
        child: Center(
          child: Icon(
            widget.placeholderIcon,
            size: 36,
            color: AppColors.textTertiaryLight,
          ),
        ),
      );
    } else {
      content = Image.file(
        _imageFile!,
        width: widget.width,
        height: widget.height,
        fit: widget.fit,
        errorBuilder: (context, error, stackTrace) => Container(
          width: widget.width,
          height: widget.height,
          color: AppColors.surface2Light,
          child: Center(
            child: Icon(
              widget.placeholderIcon,
              size: 36,
              color: AppColors.textTertiaryLight,
            ),
          ),
        ),
      );
    }

    return ClipRRect(
      borderRadius: radius,
      child: content,
    );
  }
}

