/// Inline SVG sources for the intro carousel, lifted from the
/// "LIBAS Онбординг" design deck. All garment silhouettes share a
/// 100×100 viewBox; render with `SvgPicture.string(...)`.
class IntroSvgs {
  IntroSvgs._();

  static String _svg(String body, {String viewBox = '0 0 100 100'}) =>
      '<svg xmlns="http://www.w3.org/2000/svg" viewBox="$viewBox">$body</svg>';

  /// T-shirt / blouse silhouette. Deck fills: #F5B9CE (pink), #E9C6A0 (tan),
  /// #EBA9C4 (rose).
  static String tshirt([String fill = '#F5B9CE']) => _svg(
        '<path d="M32 20 L20 31 L27 44 L34 39 L34 78 Q34 85 41 85 L59 85 '
        'Q66 85 66 78 L66 39 L73 44 L80 31 L68 20 Q59 31 50 31 Q41 31 32 20 Z" '
        'fill="$fill"/>',
      );

  /// Trousers silhouette. Deck fills: #9FB4CF (blue), #B7A9C6 (mauve).
  static String pants([String fill = '#9FB4CF']) => _svg(
        '<path d="M32 18 H68 L64 85 H53 L50 46 L47 85 H36 Z" fill="$fill"/>',
      );

  /// Hooded dress / covered-look silhouette (fixed deck colors).
  static String dress() => _svg(
        '<path d="M50 12 C28 12 22 40 30 68 C35 84 65 84 70 68 C78 40 72 12 '
        '50 12 Z" fill="#C6A2D6"/>'
        '<ellipse cx="50" cy="42" rx="16" ry="19" fill="#F1D8C2"/>'
        '<path d="M50 12 C33 12 26 32 30 52 L37 49 C34 34 40 23 50 23 C60 23 '
        '66 34 63 49 L70 52 C74 32 67 12 50 12 Z" fill="#B48BC9"/>',
      );

  /// Jacket / outer-layer silhouette. Deck fills: #B9CBA8 (sage),
  /// #EBA9C4 (rose).
  static String jacket([String fill = '#B9CBA8']) => _svg(
        '<path d="M38 22 L30 30 L36 40 L40 36 L28 82 Q28 86 33 86 L67 86 '
        'Q72 86 72 82 L60 36 L64 40 L70 30 L62 22 Q56 30 50 30 Q44 30 38 22 Z" '
        'fill="$fill"/>',
      );

  /// Loafer silhouette.
  static String loafer([String fill = '#8A5A3C']) => _svg(
        '<path d="M18 58 Q18 48 33 48 L60 48 Q82 48 82 62 Q82 72 68 72 L28 72 '
        'Q18 72 18 62 Z" fill="$fill"/>',
      );

  /// Flat shoe with strap detail (fixed deck colors).
  static String strapShoe() => _svg(
        '<path d="M14 62 Q14 52 26 50 L60 45 Q82 43 86 58 Q88 66 78 67 L22 69 '
        'Q14 69 14 62 Z" fill="#C98A4A"/>'
        '<path d="M40 50 Q52 55 64 50" stroke="#9c6a30" stroke-width="4" '
        'fill="none" stroke-linecap="round"/>',
      );

  /// Plus icon for the dashed "add" cell (24×24 viewBox, pink stroke).
  static String plus([String stroke = '#E32B86']) => _svg(
        '<path d="M12 5v14M5 12h14" fill="none" stroke="$stroke" '
        'stroke-width="2.4" stroke-linecap="round"/>',
        viewBox: '0 0 24 24',
      );

  /// The LIBAS coin: radial-gold disc with an inner ring and "L" glyph.
  /// [withRing] matches the deck: large coins draw the inner ring, tiny
  /// inline coins (22–38px) omit it.
  static String coin({bool withRing = true}) => _svg(
        '<defs><radialGradient id="cg" cx="38%" cy="32%" r="78%">'
        '<stop offset="0%" stop-color="#FBE7AE"/>'
        '<stop offset="44%" stop-color="#ECB652"/>'
        '<stop offset="100%" stop-color="#CB881F"/>'
        '</radialGradient></defs>'
        '<circle cx="22" cy="22" r="21" fill="url(#cg)"/>'
        '${withRing ? '<circle cx="22" cy="22" r="16" fill="none" stroke="#7A4A0A" stroke-opacity="0.28" stroke-width="1.4"/>' : ''}'
        '<path d="M17 12 L21.6 12 L21.6 27.6 L30 27.6 L30 32 L17 32 Z" '
        'fill="#8a561a" fill-opacity="0.8"/>',
        viewBox: '0 0 44 44',
      );

  /// Pink wardrobe with doors, hanger and drawer (deck slide 2).
  static const String wardrobe =
      '<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 128 152">'
      '<ellipse cx="64" cy="144" rx="48" ry="7" fill="#E0A9C6" opacity=".45"/>'
      '<rect x="16" y="12" width="96" height="120" rx="18" fill="#E9A9C8"/>'
      '<rect x="22" y="18" width="40" height="82" rx="10" fill="#FDF2F7"/>'
      '<rect x="27" y="30" width="30" height="3" rx="1.5" fill="#D98BB0"/>'
      '<path d="M42 33 l-6 5 2.6 6 4-2.6 v20 h11 v-20 l4 2.6 2.6-6 -6-5 '
      'q-3.8 3.6 -7.1 3.6 q-3.3 0 -7.1-3.6z" fill="#E6B36A"/>'
      '<rect x="64" y="18" width="44" height="82" rx="10" fill="#DE93B9"/>'
      '<rect x="16" y="102" width="96" height="30" rx="15" fill="#F5C4DA"/>'
      '<circle cx="55" cy="60" r="4.4" fill="#E0A337"/>'
      '<circle cx="71" cy="60" r="4.4" fill="#E0A337"/>'
      '<circle cx="64" cy="118" r="4.4" fill="#E0A337"/>'
      '<rect x="26" y="132" width="9" height="14" rx="3.5" fill="#C77FA4"/>'
      '<rect x="93" y="132" width="9" height="14" rx="3.5" fill="#C77FA4"/>'
      '</svg>';
}
