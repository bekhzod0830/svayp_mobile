import 'dart:async';

import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:url_launcher/url_launcher.dart';

import 'package:swipe/core/cache/image_cache_manager.dart';
import 'package:swipe/core/constants/app_colors.dart';
import 'package:swipe/core/constants/app_typography.dart';

/// Matches http(s):// and bare www. URLs inside free text.
final RegExp kUrlRegExp = RegExp(
  r'((https?:\/\/)|(www\.))[^\s/$.?#][^\s]*',
  caseSensitive: false,
);

/// Returns the first URL found in [text], normalized to an absolute http(s)
/// URL (bare `www.` links get an `https://` prefix). Null if none.
String? firstUrlIn(String text) {
  final match = kUrlRegExp.firstMatch(text);
  if (match == null) return null;
  return _normalizeUrl(match.group(0)!);
}

String _normalizeUrl(String raw) {
  var url = raw.trim();
  // Strip trailing punctuation that commonly clings to URLs in chat text.
  while (url.isNotEmpty && '.,);:!?]}>"\''.contains(url[url.length - 1])) {
    url = url.substring(0, url.length - 1);
  }
  if (url.toLowerCase().startsWith('www.')) {
    url = 'https://$url';
  }
  return url;
}

/// Opens [url] in the external browser/app. Returns whether it launched.
Future<bool> openExternalUrl(String url) async {
  final uri = Uri.tryParse(url);
  if (uri == null) return false;
  try {
    return await launchUrl(uri, mode: LaunchMode.externalApplication);
  } catch (_) {
    return false;
  }
}

/// Metadata scraped from a link's HTML (Open Graph with sensible fallbacks).
class LinkPreviewData {
  final String url;
  final String? title;
  final String? description;
  final String? imageUrl;
  final String? siteName;

  const LinkPreviewData({
    required this.url,
    this.title,
    this.description,
    this.imageUrl,
    this.siteName,
  });

  bool get hasContent =>
      (title != null && title!.isNotEmpty) ||
      (description != null && description!.isNotEmpty) ||
      (imageUrl != null && imageUrl!.isNotEmpty);
}

/// Fetches and caches link metadata. In-memory cache keeps previews instant
/// when scrolling back through a conversation.
class LinkPreviewService {
  LinkPreviewService._();
  static final LinkPreviewService instance = LinkPreviewService._();

  final Map<String, LinkPreviewData> _cache = {};
  final Map<String, Future<LinkPreviewData?>> _inflight = {};

  Future<LinkPreviewData?> fetch(String url) {
    if (_cache.containsKey(url)) return Future.value(_cache[url]);
    if (_inflight.containsKey(url)) return _inflight[url]!;

    final future = _load(url).then((data) {
      if (data != null) _cache[url] = data;
      _inflight.remove(url);
      return data;
    }).catchError((_) {
      _inflight.remove(url);
      return null;
    });

    _inflight[url] = future;
    return future;
  }

  Future<LinkPreviewData?> _load(String url) async {
    final uri = Uri.tryParse(url);
    if (uri == null) return null;

    final response = await http.get(
      uri,
      headers: const {
        'User-Agent':
            'Mozilla/5.0 (compatible; SwipeApp/1.0; +https://swipe.app)',
        'Accept': 'text/html,application/xhtml+xml',
      },
    ).timeout(const Duration(seconds: 8));

    if (response.statusCode != 200) return null;
    final contentType = response.headers['content-type'] ?? '';
    if (!contentType.contains('html')) return null;

    final html = response.body;
    final data = LinkPreviewData(
      url: url,
      title: _meta(html, 'og:title') ??
          _meta(html, 'twitter:title') ??
          _titleTag(html),
      description: _meta(html, 'og:description') ??
          _meta(html, 'twitter:description') ??
          _meta(html, 'description'),
      imageUrl: _resolveUrl(
        uri,
        _meta(html, 'og:image') ??
            _meta(html, 'og:image:url') ??
            _meta(html, 'twitter:image'),
      ),
      siteName: _meta(html, 'og:site_name') ?? uri.host,
    );

    return data.hasContent ? data : null;
  }

  /// Reads a `<meta>` tag's content by property/name, attribute order agnostic.
  String? _meta(String html, String key) {
    final escaped = RegExp.escape(key);
    final patterns = [
      // property/name first, then content
      RegExp(
        '<meta[^>]*(?:property|name)\\s*=\\s*["\']$escaped["\'][^>]*content\\s*=\\s*["\']([^"\']*)["\']',
        caseSensitive: false,
      ),
      // content first, then property/name
      RegExp(
        '<meta[^>]*content\\s*=\\s*["\']([^"\']*)["\'][^>]*(?:property|name)\\s*=\\s*["\']$escaped["\']',
        caseSensitive: false,
      ),
    ];
    for (final p in patterns) {
      final m = p.firstMatch(html);
      if (m != null) {
        final value = _decodeEntities(m.group(1)!.trim());
        if (value.isNotEmpty) return value;
      }
    }
    return null;
  }

  String? _titleTag(String html) {
    final m = RegExp(r'<title[^>]*>([^<]*)</title>', caseSensitive: false)
        .firstMatch(html);
    if (m == null) return null;
    final value = _decodeEntities(m.group(1)!.trim());
    return value.isEmpty ? null : value;
  }

  /// Resolves a possibly-relative image URL against the page [base].
  String? _resolveUrl(Uri base, String? value) {
    if (value == null || value.isEmpty) return null;
    final parsed = Uri.tryParse(value);
    if (parsed == null) return null;
    if (parsed.hasScheme) return value;
    return base.resolveUri(parsed).toString();
  }

  String _decodeEntities(String input) {
    return input
        .replaceAll('&amp;', '&')
        .replaceAll('&lt;', '<')
        .replaceAll('&gt;', '>')
        .replaceAll('&quot;', '"')
        .replaceAll('&#39;', "'")
        .replaceAll('&apos;', "'")
        .replaceAll('&nbsp;', ' ');
  }
}

/// Renders message text with tappable links. Manages the lifetime of the
/// gesture recognizers it creates.
class LinkifiedMessageText extends StatefulWidget {
  final String text;
  final TextStyle baseStyle;
  final Color linkColor;

  /// Optional trailing span (e.g. invisible spacer reserving timestamp space).
  final InlineSpan? trailing;

  const LinkifiedMessageText({
    super.key,
    required this.text,
    required this.baseStyle,
    required this.linkColor,
    this.trailing,
  });

  @override
  State<LinkifiedMessageText> createState() => _LinkifiedMessageTextState();
}

class _LinkifiedMessageTextState extends State<LinkifiedMessageText> {
  final List<TapGestureRecognizer> _recognizers = [];

  @override
  void dispose() {
    for (final r in _recognizers) {
      r.dispose();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    for (final r in _recognizers) {
      r.dispose();
    }
    _recognizers.clear();

    final spans = <InlineSpan>[];
    final text = widget.text;
    var index = 0;

    for (final match in kUrlRegExp.allMatches(text)) {
      if (match.start > index) {
        spans.add(TextSpan(text: text.substring(index, match.start)));
      }
      final raw = match.group(0)!;
      final url = _normalizeUrl(raw);
      final recognizer = TapGestureRecognizer()
        ..onTap = () => openExternalUrl(url);
      _recognizers.add(recognizer);
      spans.add(
        TextSpan(
          text: raw,
          style: TextStyle(
            color: widget.linkColor,
            decoration: TextDecoration.underline,
            decorationColor: widget.linkColor,
          ),
          recognizer: recognizer,
        ),
      );
      index = match.end;
    }

    if (index < text.length) {
      spans.add(TextSpan(text: text.substring(index)));
    }
    if (widget.trailing != null) spans.add(widget.trailing!);

    return Text.rich(TextSpan(style: widget.baseStyle, children: spans));
  }
}

/// A compact link-preview card shown inside a chat bubble. Loads metadata
/// asynchronously and shows a subtle loading state in the meantime.
class LinkPreviewCard extends StatefulWidget {
  final String url;
  final bool isMine;
  final bool isDark;

  const LinkPreviewCard({
    super.key,
    required this.url,
    required this.isMine,
    required this.isDark,
  });

  @override
  State<LinkPreviewCard> createState() => _LinkPreviewCardState();
}

class _LinkPreviewCardState extends State<LinkPreviewCard> {
  late Future<LinkPreviewData?> _future;

  @override
  void initState() {
    super.initState();
    _future = LinkPreviewService.instance.fetch(widget.url);
  }

  @override
  void didUpdateWidget(covariant LinkPreviewCard oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.url != widget.url) {
      _future = LinkPreviewService.instance.fetch(widget.url);
    }
  }

  Color get _secondaryText => widget.isMine
      ? (widget.isDark
          ? AppColors.black.withOpacity(0.6)
          : AppColors.white.withOpacity(0.75))
      : (widget.isDark ? AppColors.darkSecondaryText : AppColors.gray500);

  Color get _primaryText => widget.isMine
      ? (widget.isDark ? AppColors.black : AppColors.white)
      : (widget.isDark ? AppColors.darkPrimaryText : AppColors.black);

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<LinkPreviewData?>(
      future: _future,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return _shell(
            child: SizedBox(
              height: 14,
              child: Row(
                children: [
                  SizedBox(
                    width: 12,
                    height: 12,
                    child: CircularProgressIndicator(
                      strokeWidth: 1.5,
                      valueColor:
                          AlwaysStoppedAnimation<Color>(_secondaryText),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Text(
                    'Loading preview…',
                    style: AppTypography.caption.copyWith(
                      color: _secondaryText,
                      fontSize: 11,
                    ),
                  ),
                ],
              ),
            ),
          );
        }

        final data = snapshot.data;
        if (data == null || !data.hasContent) {
          return const SizedBox.shrink();
        }

        return GestureDetector(
          onTap: () => openExternalUrl(widget.url),
          child: _shell(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                if (data.imageUrl != null && data.imageUrl!.isNotEmpty)
                  ClipRRect(
                    borderRadius: BorderRadius.circular(8),
                    child: CachedNetworkImage(
                      imageUrl: data.imageUrl!,
                      cacheManager: ImageCacheManager.instance,
                      width: double.infinity,
                      height: 130,
                      fit: BoxFit.cover,
                      errorWidget: (_, __, ___) => const SizedBox.shrink(),
                    ),
                  ),
                if (data.imageUrl != null && data.imageUrl!.isNotEmpty)
                  const SizedBox(height: 8),
                if (data.siteName != null && data.siteName!.isNotEmpty)
                  Padding(
                    padding: const EdgeInsets.only(bottom: 2),
                    child: Text(
                      data.siteName!,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: AppTypography.caption.copyWith(
                        color: _secondaryText,
                        fontSize: 10,
                        fontWeight: FontWeight.w600,
                        letterSpacing: 0.2,
                      ),
                    ),
                  ),
                if (data.title != null && data.title!.isNotEmpty)
                  Text(
                    data.title!,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: AppTypography.body2.copyWith(
                      color: _primaryText,
                      fontWeight: FontWeight.w600,
                      height: 1.25,
                    ),
                  ),
                if (data.description != null && data.description!.isNotEmpty)
                  Padding(
                    padding: const EdgeInsets.only(top: 2),
                    child: Text(
                      data.description!,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: AppTypography.caption.copyWith(
                        color: _secondaryText,
                        height: 1.3,
                      ),
                    ),
                  ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _shell({required Widget child}) {
    final accent = widget.isMine
        ? (widget.isDark
            ? AppColors.black.withOpacity(0.5)
            : AppColors.white.withOpacity(0.6))
        : (widget.isDark ? AppColors.gray400 : AppColors.gray700);
    final bg = widget.isMine
        ? (widget.isDark
            ? AppColors.black.withOpacity(0.06)
            : AppColors.white.withOpacity(0.12))
        : (widget.isDark
            ? Colors.white.withOpacity(0.04)
            : AppColors.gray100.withOpacity(0.7));

    return Container(
      margin: const EdgeInsets.only(top: 6, bottom: 2),
      width: 240,
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(12),
        border: Border(left: BorderSide(color: accent, width: 3)),
      ),
      child: child,
    );
  }
}
