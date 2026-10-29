import 'dart:math' as math;
import 'dart:ui' as ui show PlaceholderAlignment;

import 'package:flutter/foundation.dart';
import 'package:flutter/painting.dart';

/// What a [MarkdownImageRequest] asks a [MarkdownImageResolver] to show.
enum MarkdownImageKind {
  /// An inline image: `![alt](src "title")`. [MarkdownImageRequest.url] is
  /// the image source and [MarkdownImageRequest.text] its alt text.
  image,

  /// A small picture painted right before a link's text, such as the linked
  /// site's favicon. [MarkdownImageRequest.url] is the link target and
  /// [MarkdownImageRequest.text] the link label.
  linkIcon,
}

/// A picture the Markdown renderer wants to show, passed to a
/// [MarkdownImageResolver].
///
/// Two requests are equal when they ask for the same picture, so the renderer
/// reuses one [MarkdownImage] for repeated occurrences and across streaming
/// updates of the same document.
@immutable
final class MarkdownImageRequest {
  /// Creates a request for a picture of [kind] at [url].
  const MarkdownImageRequest({
    required this.kind,
    required this.url,
    this.text = '',
    this.title,
  });

  /// Whether this is an inline image or a link decoration.
  final MarkdownImageKind kind;

  /// The image source for [MarkdownImageKind.image], or the link target for
  /// [MarkdownImageKind.linkIcon], exactly as written in the Markdown (it may
  /// be relative).
  final String url;

  /// The image alt text, or the link label.
  final String text;

  /// The optional title (`![alt](src "title")` / `[label](href "title")`).
  final String? title;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is MarkdownImageRequest &&
          other.kind == kind &&
          other.url == url &&
          other.text == text &&
          other.title == title;

  @override
  int get hashCode => Object.hash(kind, url, text, title);

  @override
  String toString() => 'MarkdownImageRequest(${kind.name}, $url)';
}

/// The layout context of one [MarkdownImage] occurrence: the room the text
/// line offers and the text style around it.
@immutable
final class MarkdownImageConstraints {
  /// Creates layout constraints for a picture inside text styled by
  /// [textStyle].
  const MarkdownImageConstraints({
    required this.maxWidth,
    required this.textStyle,
    this.textScaler = TextScaler.noScaling,
    this.textDirection = TextDirection.ltr,
  });

  /// The widest the picture may be: the width of the text box it sits in.
  /// Infinite while a table measures the natural width of its cells.
  final double maxWidth;

  /// The effective style of the text the picture replaces or decorates.
  final TextStyle textStyle;

  /// The text scaler applied to the surrounding text.
  final TextScaler textScaler;

  /// The direction of the surrounding text.
  final TextDirection textDirection;

  /// The scaled font size of the surrounding text, in logical pixels — the
  /// natural unit for text-sized pictures such as link icons.
  double get fontSize =>
      textScaler.scale(textStyle.fontSize ?? kDefaultFontSize);

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is MarkdownImageConstraints &&
          other.maxWidth == maxWidth &&
          other.textStyle == textStyle &&
          other.textScaler == textScaler &&
          other.textDirection == textDirection;

  @override
  int get hashCode =>
      Object.hash(maxWidth, textStyle, textScaler, textDirection);
}

/// A picture painted inline in Markdown text — an image or a link icon.
///
/// The renderer is canvas based, so a picture is not a widget: it reports the
/// [layout] size of the slot it needs in the line of text and [paint]s itself
/// into that slot. Implement it to control where pictures come from (memory
/// cache, disk, a CDN with auth headers) and how they look (rounded corners,
/// a loading shimmer, a "broken image" glyph).
///
/// Call [notifyListeners] whenever the picture changes: it finished loading,
/// failed, or advanced an animation frame. The renderer measures it again and
/// re-lays out the text only when its [layout] size changed; otherwise it
/// only repaints.
///
/// Instances are created by a [MarkdownImageResolver] and owned by the
/// renderer, which disposes them once no rendered document shows them. Return
/// a new instance from every resolver call; never share one between
/// resolvers or widgets.
///
/// The selected text of an image is its alt text
/// ([MarkdownImageRequest.text]); a link icon adds no text. Selection treats
/// the picture as a single unit.
abstract class MarkdownImage extends ChangeNotifier {
  /// How the picture sits on its line of text. Defaults to
  /// [ui.PlaceholderAlignment.middle].
  ///
  /// [ui.PlaceholderAlignment.baseline] puts the bottom of the picture on the
  /// text baseline.
  ui.PlaceholderAlignment get alignment => ui.PlaceholderAlignment.middle;

  /// The size of the slot this picture needs in a line laid out under
  /// [constraints]. Called on every layout of the text, so keep it cheap; it
  /// is also a good moment to start loading.
  ///
  /// Must not call [notifyListeners] synchronously.
  Size layout(MarkdownImageConstraints constraints);

  /// Paints the picture into [rect], the slot reserved by [layout] under
  /// [constraints], in the coordinate space of [canvas].
  void paint(Canvas canvas, Rect rect, MarkdownImageConstraints constraints);
}

/// Resolves the [MarkdownImage] for a [request], or returns `null` to keep the
/// default rendering: the alt text for an image, the bare label for a link.
///
/// See [MarkdownProviderImageResolver] for a ready-made resolver backed by
/// Flutter [ImageProvider]s.
typedef MarkdownImageResolver = MarkdownImage? Function(
  MarkdownImageRequest request,
);

/// A [MarkdownImage] that loads and paints an [ImageProvider].
///
/// Any provider works, so caching and sources are the provider's business: a
/// [NetworkImage], a [FileImage] or [AssetImage], a [MemoryImage], or a
/// third-party provider with a disk cache. Decoded images go through Flutter's
/// [ImageCache] like any [Image] widget.
///
/// The default constructor shows an inline image at its natural size, scaled
/// down to fit the line width (and [maxHeight]). [MarkdownProviderImage.icon]
/// shows a text-sized square icon in front of a link.
class MarkdownProviderImage extends MarkdownImage {
  /// Shows [provider] at its natural size, scaled down to fit.
  MarkdownProviderImage(
    this.provider, {
    this.configuration = ImageConfiguration.empty,
    this.maxHeight,
    this.borderRadius = BorderRadius.zero,
    this.fit = BoxFit.contain,
    this.filterQuality = FilterQuality.medium,
    this.placeholderColor = const Color(0x1F9E9E9E),
  })  : iconScale = null,
        iconGap = 0;

  /// Shows [provider] as a square icon [iconScale] times the font size of the
  /// link it decorates, followed by [iconGap] logical pixels of space.
  ///
  /// An icon that fails to load collapses, leaving the link as it would be
  /// without one.
  MarkdownProviderImage.icon(
    this.provider, {
    this.configuration = ImageConfiguration.empty,
    double this.iconScale = 1,
    this.iconGap = 4,
    this.borderRadius = const BorderRadius.all(Radius.circular(2)),
    this.fit = BoxFit.contain,
    this.filterQuality = FilterQuality.medium,
    this.placeholderColor,
  }) : maxHeight = null;

  /// The image source.
  final ImageProvider provider;

  /// The configuration [provider] is resolved with (device pixel ratio,
  /// locale, platform) — relevant to resolution-aware providers such as
  /// [AssetImage].
  final ImageConfiguration configuration;

  /// The tallest an inline image may be, or `null` for no limit beyond its
  /// natural size.
  final double? maxHeight;

  /// Corner rounding applied to the painted picture.
  final BorderRadius borderRadius;

  /// How the decoded image is inscribed into its slot.
  final BoxFit fit;

  /// The sampling quality used when the image is scaled.
  final FilterQuality filterQuality;

  /// Fill painted in the slot while the image loads or after it failed, or
  /// `null` to leave the slot empty.
  final Color? placeholderColor;

  /// The icon side as a multiple of the font size, or `null` for an inline
  /// image.
  final double? iconScale;

  /// Space between an icon and the link text, in logical pixels.
  final double iconGap;

  ImageStream? _stream;
  ImageStreamListener? _listener;
  ImageInfo? _info;
  bool _failed = false;
  bool _resolving = false;
  bool _disposed = false;

  /// The decoded image, once loaded.
  @visibleForTesting
  ImageInfo? get imageInfo => _info;

  /// Whether loading the image failed.
  bool get hasError => _failed;

  void _resolve() {
    if (_stream != null || _disposed) return;
    final listener = _listener = ImageStreamListener(
      _handleImage,
      onError: _handleError,
    );
    _resolving = true;
    try {
      (_stream = provider.resolve(configuration)).addListener(listener);
    } finally {
      _resolving = false;
    }
  }

  void _handleImage(ImageInfo info, bool synchronousCall) {
    if (_disposed) {
      info.dispose();
      return;
    }
    _info?.dispose();
    _info = info;
    _failed = false;
    if (!synchronousCall && !_resolving) notifyListeners();
  }

  void _handleError(Object error, StackTrace? stackTrace) {
    if (_disposed) return;
    _failed = true;
    if (!_resolving) notifyListeners();
  }

  @override
  Size layout(MarkdownImageConstraints constraints) {
    _resolve();
    final fontSize = constraints.fontSize;
    final scale = iconScale;
    if (scale != null) {
      if (_failed) return Size.zero;
      final side = fontSize * scale;
      return Size(side + iconGap, side);
    }
    final info = _info;
    if (info == null) return Size.square(fontSize);
    final width = info.image.width / info.scale;
    final height = info.image.height / info.scale;
    if (width <= 0 || height <= 0) return Size.zero;
    var factor = 1.0;
    if (constraints.maxWidth.isFinite && width > constraints.maxWidth) {
      factor = constraints.maxWidth / width;
    }
    final limit = maxHeight;
    if (limit != null && height * factor > limit) factor = limit / height;
    return Size(width * factor, height * factor);
  }

  @override
  void paint(Canvas canvas, Rect rect, MarkdownImageConstraints constraints) {
    var target = rect;
    if (iconScale != null) {
      // The slot is the icon followed by the gap, in reading order.
      final side = math.max(0.0, math.min(rect.height, rect.width - iconGap));
      target = Rect.fromLTWH(
        constraints.textDirection == TextDirection.rtl
            ? rect.right - side
            : rect.left,
        rect.top + (rect.height - side) / 2,
        side,
        side,
      );
    }
    if (target.isEmpty) return;
    final rounded = borderRadius != BorderRadius.zero;
    final info = _info;
    if (info == null) {
      final color = placeholderColor;
      if (color == null) return;
      final paint = Paint()..color = color;
      if (rounded) {
        canvas.drawRRect(borderRadius.toRRect(target), paint);
      } else {
        canvas.drawRect(target, paint);
      }
      return;
    }
    if (rounded) {
      canvas
        ..save()
        ..clipRRect(borderRadius.toRRect(target));
    }
    paintImage(
      canvas: canvas,
      rect: target,
      image: info.image,
      scale: info.scale,
      fit: fit,
      filterQuality: filterQuality,
    );
    if (rounded) canvas.restore();
  }

  @override
  void dispose() {
    _disposed = true;
    final listener = _listener;
    if (listener != null) _stream?.removeListener(listener);
    _stream = null;
    _info?.dispose();
    _info = null;
    super.dispose();
  }
}

/// A ready-made [MarkdownImageResolver] that shows images and link icons with
/// [MarkdownProviderImage].
///
/// Pass its [call] method as [MarkdownThemeData.imageResolver]:
///
/// ```dart
/// MarkdownThemeData(
///   textStyle: const TextStyle(fontSize: 14),
///   imageResolver: const MarkdownProviderImageResolver(linkIcons: true).call,
/// )
/// ```
///
/// A `const` resolver keeps its tear-off equal across rebuilds, so loaded
/// pictures survive a theme rebuilt in `build`.
///
/// Swap [imageProvider] to change where pictures come from — a disk-cached
/// network provider, files, or assets — without writing a [MarkdownImage].
/// Implement [MarkdownImage] instead to change how they are painted.
///
/// Rendering remote images reveals the reader's address to whoever hosts them
/// (tracking pixels), so neither images nor link icons are shown unless a
/// resolver is installed.
@immutable
class MarkdownProviderImageResolver {
  /// Creates a resolver for inline [images] and, when [linkIcons] is set, a
  /// favicon in front of every web link.
  const MarkdownProviderImageResolver({
    this.images = true,
    this.linkIcons = false,
    this.baseUri,
    this.imageProvider = defaultImageProvider,
    this.faviconUri = defaultFaviconUri,
    this.configuration = ImageConfiguration.empty,
    this.maxImageHeight,
    this.imageBorderRadius = BorderRadius.zero,
    this.iconScale = 1,
    this.iconGap = 4,
  });

  /// Whether inline `![alt](src)` images are shown (otherwise the alt text
  /// is).
  final bool images;

  /// Whether links get an icon in front of their label.
  final bool linkIcons;

  /// The base that relative image sources and link targets resolve against,
  /// or `null` to ignore relative ones.
  final Uri? baseUri;

  /// Maps an absolute image location to a provider, or `null` to skip it.
  /// Defaults to [defaultImageProvider].
  final ImageProvider? Function(Uri uri) imageProvider;

  /// Maps a link target to the location of its icon, or `null` for no icon.
  /// Defaults to [defaultFaviconUri].
  final Uri? Function(Uri link) faviconUri;

  /// Passed to every [MarkdownProviderImage].
  final ImageConfiguration configuration;

  /// See [MarkdownProviderImage.maxHeight].
  final double? maxImageHeight;

  /// See [MarkdownProviderImage.borderRadius], for inline images.
  final BorderRadius imageBorderRadius;

  /// See [MarkdownProviderImage.iconScale].
  final double iconScale;

  /// See [MarkdownProviderImage.iconGap].
  final double iconGap;

  /// Loads `http`/`https` locations with a [NetworkImage] and inline `data:`
  /// URIs with a [MemoryImage]; skips every other scheme (files, assets),
  /// which a host must opt into with its own [imageProvider].
  static ImageProvider? defaultImageProvider(Uri uri) {
    switch (uri.scheme) {
      case 'http' || 'https':
        return uri.host.isEmpty ? null : NetworkImage(uri.toString());
      case 'data':
        final data = uri.data;
        if (data == null || !data.mimeType.toLowerCase().startsWith('image/'))
          return null;
        return MemoryImage(data.contentAsBytes());
      default:
        return null;
    }
  }

  /// `/favicon.ico` at the root of a web link's origin, or `null` for any
  /// other link (mail, phone). In-page anchors (`#section`) never get an
  /// icon, even with a [baseUri].
  static Uri? defaultFaviconUri(Uri link) {
    if (link.scheme != 'http' && link.scheme != 'https') return null;
    if (link.host.isEmpty) return null;
    return Uri(
      scheme: link.scheme,
      host: link.host,
      port: link.hasPort ? link.port : null,
      path: '/favicon.ico',
    );
  }

  Uri? _absolute(String url) {
    final uri = Uri.tryParse(url.trim());
    if (uri == null) return null;
    if (uri.hasScheme) return uri;
    return baseUri?.resolveUri(uri);
  }

  /// Resolves [request]; see [MarkdownImageResolver].
  MarkdownImage? call(MarkdownImageRequest request) {
    if (request.kind == MarkdownImageKind.linkIcon &&
        request.url.trimLeft().startsWith('#')) {
      return null;
    }
    final uri = _absolute(request.url);
    if (uri == null) return null;
    switch (request.kind) {
      case MarkdownImageKind.image:
        if (!images) return null;
        final provider = imageProvider(uri);
        if (provider == null) return null;
        return MarkdownProviderImage(
          provider,
          configuration: configuration,
          maxHeight: maxImageHeight,
          borderRadius: imageBorderRadius,
        );
      case MarkdownImageKind.linkIcon:
        if (!linkIcons) return null;
        final icon = faviconUri(uri);
        if (icon == null) return null;
        final provider = imageProvider(icon);
        if (provider == null) return null;
        return MarkdownProviderImage.icon(
          provider,
          configuration: configuration,
          iconScale: iconScale,
          iconGap: iconGap,
        );
    }
  }
}
