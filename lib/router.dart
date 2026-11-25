import 'dart:async';
import 'dart:math';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_web_plugins/url_strategy.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';

import 'firebase_options.dart';
import 'admin_products.dart';
import 'admin_dashboard.dart';

// ============================================================================
// 0. POINT D'ENTRÉE & CONFIGURATION DU THÈME
// ============================================================================

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  usePathUrlStrategy();
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
  runApp(const FycoApp());
}

class FycoApp extends StatelessWidget {
  const FycoApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp.router(
      title: 'FYCO — FYCO Sculpt Jumpsuit',
      debugShowCheckedModeBanner: false,
      routerConfig: appRouter,
      theme: ThemeData(
        useMaterial3: true,
        brightness: Brightness.light,
        scaffoldBackgroundColor: FycoColors.background,
        canvasColor: FycoColors.background,
        colorScheme: const ColorScheme.light(
          primary: FycoColors.ink,
          surface: FycoColors.background,
          onSurface: FycoColors.ink,
        ),
        popupMenuTheme: PopupMenuThemeData(
          color: Colors.white,
          surfaceTintColor: Colors.transparent,
          elevation: 4,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(6),
            side: const BorderSide(color: FycoColors.line),
          ),
          textStyle: GoogleFonts.plusJakartaSans(
            fontSize: 13,
            fontWeight: FontWeight.w600,
            color: FycoColors.ink,
          ),
        ),
        textTheme: GoogleFonts.plusJakartaSansTextTheme().apply(
          bodyColor: FycoColors.ink,
          displayColor: FycoColors.ink,
        ),
        splashFactory: NoSplash.splashFactory,
        highlightColor: Colors.transparent,
        hoverColor: Colors.transparent,
      ),
    );
  }
}

// ============================================================================
// 1. SYSTÈME DE DESIGN & TYPOGRAPHIE RESPONSIVE
// ============================================================================

class FycoColors {
  static const Color background = Color(0xFFF9F6F0);
  static const Color surface = Color(0xFFFFFFFF);
  static const Color surfaceWarm = Color(0xFFF1EBE1);
  static const Color ink = Color(0xFF141211);
  static const Color inkMuted = Color(0xFF6B6560);
  static const Color line = Color(0xFFE4DCD3);
  static const Color success = Color(0xFF2C6B4F);
  static const Color danger = Color(0xFFBA2D25);
  static const Color gold = Color(0xFFC59A4E);
}

TextStyle serifDisplay(double size, {FontWeight weight = FontWeight.w400, Color color = FycoColors.ink, double letterSpacing = -0.5, double height = 1.1}) {
  return GoogleFonts.playfairDisplay(fontSize: size, fontWeight: weight, color: color, letterSpacing: letterSpacing, height: height);
}

TextStyle panelDisplay(double size, {FontWeight weight = FontWeight.w600, Color color = FycoColors.ink, double letterSpacing = 0.5, double height = 1.15}) {
  return GoogleFonts.cormorantGaramond(fontSize: size, fontWeight: weight, color: color, letterSpacing: letterSpacing, height: height);
}

TextStyle sans(double size, {FontWeight weight = FontWeight.w400, Color color = FycoColors.ink, double letterSpacing = 0, double height = 1.45}) {
  return GoogleFonts.plusJakartaSans(fontSize: size, fontWeight: weight, color: color, letterSpacing: letterSpacing, height: height);
}

TextStyle overline({Color color = FycoColors.inkMuted, double size = 11}) => sans(size, weight: FontWeight.w700, color: color, letterSpacing: 2.2);

TextStyle logoStyle(double size) => GoogleFonts.syncopate(fontSize: size, fontWeight: FontWeight.w600, letterSpacing: size * 0.28, color: FycoColors.ink);

InputDecoration fieldDecoration(String label) {
  OutlineInputBorder border(Color c, [double w = 1]) => OutlineInputBorder(
        borderRadius: BorderRadius.circular(6),
        borderSide: BorderSide(color: c, width: w),
      );
  return InputDecoration(
    labelText: label,
    labelStyle: sans(13.5, color: FycoColors.inkMuted),
    floatingLabelStyle: sans(13, weight: FontWeight.w600, color: FycoColors.ink),
    filled: true,
    fillColor: Colors.white,
    contentPadding: const EdgeInsets.symmetric(horizontal: 18, vertical: 18),
    border: border(FycoColors.line),
    enabledBorder: border(FycoColors.line),
    focusedBorder: border(FycoColors.ink, 1.4),
    errorBorder: border(FycoColors.danger),
    focusedErrorBorder: border(FycoColors.danger, 1.4),
  );
}

class FycoButton extends StatelessWidget {
  const FycoButton({super.key, required this.label, required this.onTap, this.icon, this.loading = false, this.expand = false, this.inverted = false});
  final String label;
  final VoidCallback? onTap;
  final IconData? icon;
  final bool loading;
  final bool expand;
  final bool inverted;

  @override
  Widget build(BuildContext context) {
    final bg = inverted ? Colors.white : FycoColors.ink;
    final fg = inverted ? FycoColors.ink : Colors.white;

    return SizedBox(
      width: expand ? double.infinity : null,
      height: 52,
      child: ElevatedButton(
        onPressed: loading ? null : onTap,
        style: ElevatedButton.styleFrom(
          backgroundColor: bg,
          foregroundColor: fg,
          elevation: 0,
          shadowColor: Colors.transparent,
          side: BorderSide(color: inverted ? FycoColors.line : FycoColors.ink),
          padding: const EdgeInsets.symmetric(horizontal: 28),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(4)),
        ),
        child: loading
            ? SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2, color: fg))
            : Row(
                mainAxisSize: MainAxisSize.min,
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(label, style: sans(12.5, weight: FontWeight.w700, color: fg, letterSpacing: 0.8)),
                  if (icon != null) ...[const SizedBox(width: 8), Icon(icon, size: 16, color: fg)],
                ],
              ),
      ),
    );
  }
}

PreferredSizeWidget fycoAppBar(BuildContext context, {bool back = true}) {
  return AppBar(
    backgroundColor: FycoColors.background,
    surfaceTintColor: Colors.transparent,
    elevation: 0,
    centerTitle: true,
    leading: back
        ? IconButton(
            icon: const Icon(Icons.arrow_back_ios_new, size: 16, color: FycoColors.ink),
            onPressed: () {
              if (context.canPop()) {
                context.pop();
              } else {
                context.go('/');
              }
            },
          )
        : null,
    title: InkWell(
      onTap: () => context.go('/'),
      child: Text('FYCO', style: logoStyle(19)),
    ),
    actions: [
      IconButton(
        tooltip: 'Mon Compte / Profil',
        onPressed: () => context.push('/auth'),
        icon: const Icon(Icons.person_outline, size: 21, color: FycoColors.ink),
      ),
    ],
    bottom: PreferredSize(
      preferredSize: const Size.fromHeight(1),
      child: Container(height: 1, color: FycoColors.line),
    ),
  );
}

// ============================================================================
// 2. MODÈLES & GESTION DU PANIER ET FIDÉLITÉ
// ============================================================================

class FycoImages {
  static const String hero = 'assets/images/hero.jpeg';
  static const String front = 'assets/images/front.jpeg';
  static const String back = 'assets/images/back.jpeg';
  static const String milkWhite = 'assets/images/milk_white.jpeg';
  static const String chocolate = 'assets/images/chocolate2.jpeg';
  static const String pink = 'assets/images/pink2.jpeg';

  static const String milkWhite2 = 'assets/images/milk_white2.jpeg';
  static const String chocolate2 = 'assets/images/chocolate.jpeg';
  static const String pink2 = 'assets/images/pink2.jpeg';

  static const String gallery1 = 'assets/images/gallery1.jpeg';
  static const String gallery2 = 'assets/images/gallery2.jpeg';
  static const String gallery3 = 'assets/images/pink.jpeg';
  static const String gallery4 = 'assets/images/gallery4.jpeg';
  static const String gallery5 = 'assets/images/gallery5.jpeg';

}

class FycoImage extends StatelessWidget {
  const FycoImage(this.path, {super.key, this.fit = BoxFit.cover, this.alignment = Alignment.center, this.fallback});
  final String path;
  final BoxFit fit;
  final Alignment alignment;
  final Color? fallback;

  @override
  Widget build(BuildContext context) {
    return Image.asset(
      path,
      fit: fit,
      alignment: alignment,
      width: double.infinity,
      height: double.infinity,
      errorBuilder: (_, __, ___) => Container(
        color: fallback ?? FycoColors.surfaceWarm,
        alignment: Alignment.center,
        child: Icon(Icons.image_outlined, size: 32, color: FycoColors.inkMuted.withOpacity(0.4)),
      ),
    );
  }
}

class FycoColor {
  const FycoColor({required this.id, required this.name, required this.swatch, required this.image, required this.cardImage});
  final String id;
  final String name;
  final Color swatch;
  final String image;
  final String cardImage;
}

class FycoProduct {
  const FycoProduct({required this.id, required this.name, required this.tagline, required this.priceMad, required this.originalPriceMad, required this.colors, required this.sizes});
  final String id;
  final String name;
  final String tagline;
  final int priceMad;
  final int originalPriceMad;
  final List<FycoColor> colors;
  final List<String> sizes;

  FycoColor colorById(String? colorId) => colors.firstWhere((c) => c.id == colorId, orElse: () => colors.first);
}

const FycoProduct sculptJumpsuit = FycoProduct(
  id: 'sculpt-jumpsuit',
  name: 'FYCO Sculpt Jumpsuit',
  tagline: 'Une silhouette sublimée, des lignes sculptantes et un dos nu signature.',
  priceMad: 449,
  originalPriceMad: 600,
  colors: [
    FycoColor(id: 'milk-white', name: 'Blanc Lait', swatch: Color(0xFFF0EAE1), image: FycoImages.milkWhite, cardImage: FycoImages.milkWhite2),
    FycoColor(id: 'chocolate', name: 'Chocolat', swatch: Color(0xFF2A1D1A), image: FycoImages.chocolate, cardImage: FycoImages.chocolate2),
    FycoColor(id: 'vibrant-pink', name: '** Éclatant', swatch: Color(0xFFD64D87), image: FycoImages.pink, cardImage: FycoImages.pink2),
  ],
  sizes: ['S', 'M', 'L'],
);

const List<String> moroccanCities = [
  'Casablanca', 'Rabat', 'Salé', 'Témara', 'Marrakech', 'Tanger',
  'Fès', 'Meknès', 'Agadir', 'Oujda', 'Kénitra', 'Tétouan',
  'Mohammedia', 'El Jadida', 'Autre ville'
];

String? normalizePhone(String raw) {
  var p = raw.replaceAll(RegExp(r'[\s\-\.\(\)]'), '');
  if (p.startsWith('+212')) p = '0${p.substring(4)}';
  else if (p.startsWith('00212')) p = '0${p.substring(5)}';
  return RegExp(r'^0[5-7]\d{8}$').hasMatch(p) ? p : null;
}

String? normalizeEmail(String raw) {
  final email = raw.trim();
  return RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$').hasMatch(email) ? email : null;
}

String generateOrderCode() {
  const alphabet = 'ABCDEFGHJKLMNPQRSTUVWXYZ23456789';
  final rnd = Random.secure();
  String block() => List.generate(4, (_) => alphabet[rnd.nextInt(alphabet.length)]).join();
  return 'FYCO-${block()}-${block()}';
}

class FycoCartLine {
  FycoCartLine({required this.product, required this.color, required this.size, this.quantity = 1});
  final FycoProduct product;
  final FycoColor color;
  final String size;
  int quantity;
  String get key => '${product.id}|${color.id}|$size';
  int get subtotal => product.priceMad * quantity;
}

class FycoCart extends ChangeNotifier {
  FycoCart._();
  static final FycoCart instance = FycoCart._();
  final List<FycoCartLine> lines = [];
  int get itemCount => lines.fold(0, (sum, line) => sum + line.quantity);
  int get total => lines.fold(0, (sum, line) => sum + line.subtotal);

  void add(FycoProduct product, FycoColor color, String size, {int quantity = 1}) {
    final key = '${product.id}|${color.id}|$size';
    final index = lines.indexWhere((line) => line.key == key);
    if (index >= 0) {
      lines[index].quantity += quantity;
    } else {
      lines.add(FycoCartLine(product: product, color: color, size: size, quantity: quantity));
    }
    notifyListeners();
  }

  void setQuantity(FycoCartLine line, int quantity) {
    if (quantity < 1) lines.remove(line);
    else line.quantity = quantity;
    notifyListeners();
  }

  void remove(FycoCartLine line) {
    lines.remove(line);
    notifyListeners();
  }

  void clear() {
    lines.clear();
    notifyListeners();
  }

  List<Map<String, dynamic>> toOrderItems() => lines.map((line) => {
        'productId': line.product.id,
        'productName': line.product.name,
        'colorId': line.color.id,
        'color': line.color.name,
        'size': line.size,
        'priceMad': line.product.priceMad,
        'quantity': line.quantity,
        'subtotalMad': line.subtotal,
      }).toList();
}

// ============================================================================
// 3. CONFIGURATION DU ROUTEUR GO_ROUTER
// ============================================================================

final GoRouter appRouter = GoRouter(
  routes: [
    GoRoute(path: '/', builder: (context, state) => const HomeScreen()),
    GoRoute(path: '/product', builder: (context, state) => ProductScreen(initialColorId: state.uri.queryParameters['color'])),
    GoRoute(path: '/cart', builder: (context, state) => const CartScreen()),
    GoRoute(path: '/checkout', builder: (context, state) => CheckoutScreen(colorId: state.uri.queryParameters['color'], size: state.uri.queryParameters['size'])),
    GoRoute(path: '/success/:code', builder: (context, state) => SuccessScreen(code: state.pathParameters['code'] ?? '')),
    GoRoute(path: '/track/:code', builder: (context, state) => TrackingScreen(code: state.pathParameters['code'] ?? '')),
    GoRoute(path: '/auth', builder: (context, state) => const AuthScreen()),
    GoRoute(path: '/profile', builder: (context, state) => const ProfileScreen()),
    GoRoute(path: '/admin', builder: (context, state) => const AdminScreen()),
    GoRoute(path: '/admin/products', builder: (context, state) => Theme(
      data: ThemeData.light().copyWith(
        scaffoldBackgroundColor: const Color(0xFFF6F3EE),
        colorScheme: ColorScheme.fromSeed(seedColor: const Color(0xFFB77E78), brightness: Brightness.light),
        textTheme: ThemeData.light().textTheme.apply(bodyColor: const Color(0xFF171717), displayColor: const Color(0xFF171717)),
        appBarTheme: const AppBarTheme(backgroundColor: Colors.white, foregroundColor: Color(0xFF171717), elevation: 0, surfaceTintColor: Colors.transparent),
      ),
      child: const AdminProductsScreen(),
    )),
  ],
);

// ============================================================================
// 4. COMPOSANTS AUXILIAIRES DE LA PAGE D'ACCUEIL
// ============================================================================

class _TopAnnouncementBar extends StatefulWidget {
  const _TopAnnouncementBar();

  @override
  State<_TopAnnouncementBar> createState() => _TopAnnouncementBarState();
}

class _TopAnnouncementBarState extends State<_TopAnnouncementBar> with SingleTickerProviderStateMixin {
  late AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(seconds: 12),
      vsync: this,
    )..repeat();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    const text = 'OFFRE DE LANCEMENT : -20% DE RÉDUCTION · LIVRAISON OFFERTE AU MAROC ·';
    return Container(
      height: 32,
      color: FycoColors.ink,
      child: OverflowBox(
        maxWidth: double.infinity,
        alignment: Alignment.centerLeft,
        child: AnimatedBuilder(
          animation: _controller,
          builder: (context, child) {
            return Transform.translate(
              offset: Offset(-_controller.value * 600, 0),
              child: Row(
                children: List.generate(
                  4,
                  (_) => Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 24),
                    child: Text(text, style: sans(11, weight: FontWeight.w700, color: Colors.white, letterSpacing: 1.5)),
                  ),
                ),
              ),
            );
          },
        ),
      ),
    );
  }
}

class _NavLink extends StatelessWidget {
  const _NavLink({required this.label, required this.onTap, this.active = false});
  final String label;
  final VoidCallback onTap;
  final bool active;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      child: Text(
        label,
        style: sans(11.5, weight: FontWeight.w700, letterSpacing: 1.2, color: active ? FycoColors.ink : FycoColors.inkMuted),
      ),
    );
  }
}

class _ViewPanel extends StatelessWidget {
  const _ViewPanel({
    required this.desktop,
    required this.image,
    required this.imageAlignment,
    required this.kicker,
    required this.title,
    required this.body,
    required this.textOnLeft,
  });

  final bool desktop;
  final String image;
  final Alignment imageAlignment;
  final String kicker;
  final String title;
  final String body;
  final bool textOnLeft;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: desktop ? 520 : 440,
      child: ClipRRect(
        borderRadius: BorderRadius.circular(6),
        child: Stack(
          fit: StackFit.expand,
          children: [
            FycoImage(image, alignment: imageAlignment),
            DecoratedBox(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: textOnLeft ? Alignment.centerLeft : Alignment.centerRight,
                  end: textOnLeft ? Alignment.centerRight : Alignment.centerLeft,
                  colors: [
                    FycoColors.background.withOpacity(0.14),
                    FycoColors.background.withOpacity(0.04),
                    Colors.transparent,
                  ],
                  stops: const [0.0, 0.16, 0.35],
                ),
              ),
            ),
            Align(
              alignment: textOnLeft ? Alignment.centerLeft : Alignment.centerRight,
              child: SizedBox(
                width: desktop ? 250 : 190,
                child: Padding(
                  padding: EdgeInsets.symmetric(horizontal: desktop ? 28 : 16),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(kicker, style: overline(size: 10, color: FycoColors.ink).copyWith(letterSpacing: 2.4)),
                      const SizedBox(height: 6),
                      Text(title, style: panelDisplay(desktop ? 29 : 25, color: FycoColors.ink)),
                      Container(width: 28, height: 1.5, margin: const EdgeInsets.symmetric(vertical: 10), color: FycoColors.ink),
                      Text(body, style: sans(12.5, color: FycoColors.ink, height: 1.45, weight: FontWeight.w500)),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ColorCard extends StatelessWidget {
  const _ColorCard({required this.color, required this.onTap});
  final FycoColor color;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(8),
      child: Container(
        decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(8), border: Border.all(color: FycoColors.line)),
        padding: const EdgeInsets.all(8),
        child: Column(
          children: [
            AspectRatio(
              aspectRatio: 0.75,
              child: ClipRRect(borderRadius: BorderRadius.circular(5), child: FycoImage(color.cardImage, alignment: Alignment.topCenter)),
            ),
            const SizedBox(height: 12),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Container(width: 14, height: 14, decoration: BoxDecoration(color: color.swatch, shape: BoxShape.circle, border: Border.all(color: FycoColors.line))),
                const SizedBox(width: 8),
                Flexible(child: Text(color.name, overflow: TextOverflow.ellipsis, style: sans(12.5, weight: FontWeight.w600))),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _GalleryTile extends StatelessWidget {
  const _GalleryTile({required this.image, required this.tag, required this.caption, required this.height});
  final String image;
  final String tag;
  final String caption;
  final double height;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: height,
      child: ClipRRect(
        borderRadius: BorderRadius.circular(6),
        child: Stack(
          fit: StackFit.expand,
          children: [
            FycoImage(image),
            DecoratedBox(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.bottomCenter,
                  end: Alignment.topCenter,
                  colors: [FycoColors.ink.withOpacity(0.7), Colors.transparent],
                  stops: const [0.0, 0.45],
                ),
              ),
            ),
            Positioned(
              left: 16, right: 16, bottom: 16,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(tag, style: sans(10, weight: FontWeight.w800, color: Colors.white70, letterSpacing: 1.5)),
                  const SizedBox(height: 2),
                  Text(caption, style: serifDisplay(16, color: Colors.white, weight: FontWeight.w500)),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ============================================================================
// 5. ÉCRAN D'ACCUEIL (HOMESCREEN RESPONSIVE)
// ============================================================================

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final ScrollController _scroll = ScrollController();
  final GlobalKey _shopKey = GlobalKey();
  final GlobalKey _aboutKey = GlobalKey();
  final GlobalKey _galleryKey = GlobalKey();
  final GlobalKey _faqKey = GlobalKey();

  @override
  void dispose() {
    _scroll.dispose();
    super.dispose();
  }

  void _toTop() => _scroll.animateTo(0, duration: const Duration(milliseconds: 600), curve: Curves.easeInOutCubic);
  void _goTo(GlobalKey key) {
    final ctx = key.currentContext;
    if (ctx != null) Scrollable.ensureVisible(ctx, duration: const Duration(milliseconds: 600), curve: Curves.easeInOutCubic);
  }

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final desktop = constraints.maxWidth >= 900;
        return Scaffold(
          backgroundColor: FycoColors.background,
          body: Stack(
            children: [
              SingleChildScrollView(
                controller: _scroll,
                child: Column(
                  children: [
                    const SizedBox(height: 104), // 32px (barre annonce) + 72px (nav)
                    _hero(desktop),
                    _viewPanels(desktop),
                    _colorsSection(desktop),
                    _creativeGallery(desktop),
                    _featuresStrip(desktop),
                    const _AnimatedComingSoonBanner(),
                    _faqSection(desktop),
                    _footer(desktop),
                  ],
                ),
              ),
              Positioned(
                top: 0,
                left: 0,
                right: 0,
                child: Column(
                  children: [
                    const _TopAnnouncementBar(),
                    _nav(desktop),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _nav(bool desktop) {
    return Container(
      height: 72,
      padding: EdgeInsets.symmetric(horizontal: desktop ? 48 : 16),
      decoration: BoxDecoration(
        color: FycoColors.background.withOpacity(0.96),
        border: const Border(bottom: BorderSide(color: FycoColors.line, width: 0.8)),
      ),
      child: Row(
        children: [
          Text('FYCO', style: logoStyle(22)),
          if (desktop)
            Expanded(
              child: Center(
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    _NavLink(label: 'ACCUEIL', active: true, onTap: _toTop),
                    const SizedBox(width: 28),
                    _NavLink(label: 'COLLECTION', onTap: () => _goTo(_shopKey)),
                    const SizedBox(width: 28),
                    _NavLink(label: 'GALERIE', onTap: () => _goTo(_galleryKey)),
                    const SizedBox(width: 28),
                    _NavLink(label: 'COMBINAISON', onTap: () => context.push('/product')),
                    const SizedBox(width: 28),
                    _NavLink(label: 'DÉTAILS', onTap: () => _goTo(_aboutKey)),
                    const SizedBox(width: 28),
                    _NavLink(label: 'FAQ', onTap: () => _goTo(_faqKey)),
                  ],
                ),
              ),
            )
          else
            const Spacer(),
          IconButton(
            tooltip: 'Suivre ma commande',
            onPressed: () => showDialog<void>(context: context, builder: (_) => const _TrackDialog()),
            icon: const Icon(Icons.local_shipping_outlined, size: 21, color: FycoColors.ink),
          ),
          IconButton(
            tooltip: 'Mon Compte / Profil',
            onPressed: () => context.push('/auth'),
            icon: const Icon(Icons.person_outline, size: 21, color: FycoColors.ink),
          ),
          Stack(
            clipBehavior: Clip.none,
            children: [
              IconButton(
                tooltip: 'Panier',
                onPressed: () => context.push('/cart'),
                icon: const Icon(Icons.shopping_bag_outlined, size: 21, color: FycoColors.ink),
              ),
              AnimatedBuilder(
                animation: FycoCart.instance,
                builder: (_, __) {
                  final c = FycoCart.instance.itemCount;
                  if (c == 0) return const SizedBox.shrink();
                  return Positioned(
                    right: 6,
                    top: 6,
                    child: Container(
                      padding: const EdgeInsets.all(4),
                      decoration: const BoxDecoration(color: FycoColors.ink, shape: BoxShape.circle),
                      child: Text('$c', style: sans(9, weight: FontWeight.w700, color: Colors.white)),
                    ),
                  );
                },
              ),
            ],
          ),
          if (!desktop)
            PopupMenuButton<String>(
              icon: const Icon(Icons.menu, color: FycoColors.ink),
              color: Colors.white,
              surfaceTintColor: Colors.transparent,
              elevation: 4,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(6), side: const BorderSide(color: FycoColors.line)),
              onSelected: (v) {
                switch (v) {
                  case 'home': _toTop();
                  case 'shop': _goTo(_shopKey);
                  case 'gallery': _goTo(_galleryKey);
                  case 'product': context.push('/product');
                  case 'about': _goTo(_aboutKey);
                  case 'faq': _goTo(_faqKey);
                  case 'auth': context.push('/auth');
                }
              },
              itemBuilder: (_) => [
                const PopupMenuItem(value: 'home', child: Text('Accueil')),
                const PopupMenuItem(value: 'shop', child: Text('Collection')),
                const PopupMenuItem(value: 'gallery', child: Text('Galerie Lookbook')),
                const PopupMenuItem(value: 'product', child: Text('FYCO Sculpt Jumpsuit')),
                const PopupMenuItem(value: 'about', child: Text('Détails')),
                const PopupMenuItem(value: 'faq', child: Text('Questions & Réponses')),
                const PopupMenuItem(value: 'auth', child: Text('Mon Compte / Profil')),
              ],
            ),
        ],
      ),
    );
  }

  Widget _hero(bool desktop) {
    final pad = desktop ? 72.0 : 20.0;
    return SizedBox(
      height: desktop ? 640 : 520,
      child: Stack(
        fit: StackFit.expand,
        children: [
          FycoImage(FycoImages.hero, alignment: desktop ? const Alignment(0.65, -0.3) : const Alignment(0.85, -0.3)),
          DecoratedBox(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.centerLeft,
                end: Alignment.centerRight,
                colors: [
                  FycoColors.background.withOpacity(desktop ? 0.70 : 0.58),
                  FycoColors.background.withOpacity(desktop ? 0.28 : 0.15),
                  Colors.transparent,
                ],
                stops: [0, desktop ? 0.38 : 0.52, 1],
              ),
            ),
          ),
          Padding(
            padding: EdgeInsets.fromLTRB(pad, desktop ? 36 : 24, pad, 24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: Align(
                    alignment: Alignment.centerLeft,
                    child: ConstrainedBox(
                      constraints: BoxConstraints(maxWidth: desktop ? 450 : 310),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
 
                          const SizedBox(height: 14),
                          Text(
                            'Rencontrez votre nouvelle\ncombinaison favorite.',
                            style: serifDisplay(desktop ? 44 : 30, weight: FontWeight.w500, letterSpacing: -0.7, color: FycoColors.ink, height: 1.08),
                          ),
                          const SizedBox(height: 12),
                          Text(
                            'Découvrez la FYCO Sculpt Jumpsuit, pensée pour sublimer votre silhouette et révéler votre confiance. Un style à la fois sportif, féminin et élégant.',
                            style: sans(desktop ? 13.5 : 12, color: FycoColors.inkMuted, height: 1.45),
                          ),
                          const SizedBox(height: 22),
                          FycoButton(
                            label: 'ACHETEZ MAINTENANT',
                            icon: Icons.arrow_forward_rounded,
                            onTap: () => context.push('/product'),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
                Wrap(
                  crossAxisAlignment: WrapCrossAlignment.center,
                  spacing: 10,
                  runSpacing: 6,
                  children: [
                    Text('COUPE SCULPTANTE', style: overline(color: FycoColors.ink, size: 9.5)),
                    Container(width: 3.5, height: 3.5, decoration: const BoxDecoration(color: FycoColors.ink, shape: BoxShape.circle)),
                    Text('DOS NU AUDACIEUX', style: overline(color: FycoColors.ink, size: 9.5)),
                    Container(width: 3.5, height: 3.5, decoration: const BoxDecoration(color: FycoColors.ink, shape: BoxShape.circle)),
                    Text('TISSU PREMIUM', style: overline(color: FycoColors.ink, size: 9.5)),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _viewPanels(bool desktop) {
    final front = _ViewPanel(desktop: desktop, image: FycoImages.gallery5, imageAlignment: const Alignment(0.85, -0.2), kicker: 'VUE DE DOS', title: 'Dos Nu Signature', body: 'Une ouverture en V qui dévoile et sublime votre dos.', textOnLeft: true);
    final back = _ViewPanel(desktop: desktop, image: FycoImages.front, imageAlignment: const Alignment(-0.85, -0.2), kicker: 'VUE DE FACE', title: 'Galbe & Maintien', body: 'Des lignes de contour pensées pour dessiner et sublimer naturellement votre silhouette.', textOnLeft: false);
    final side = desktop ? 36.0 : 16.0;

    return Padding(
      padding: EdgeInsets.fromLTRB(side, 24, side, 0),
      child: desktop
          ? Row(children: [Expanded(child: front), const SizedBox(width: 16), Expanded(child: back)])
          : Column(children: [front, const SizedBox(height: 16), back]),
    );
  }

  Widget _colorsSection(bool desktop) {
    final colors = sculptJumpsuit.colors;
    return Container(
      key: _shopKey,
      padding: EdgeInsets.fromLTRB(desktop ? 64 : 20, 56, desktop ? 64 : 20, 56),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('PALETTE EXCLUSIVE', style: overline()),
                  const SizedBox(height: 8),
                  Text('Trois couleurs iconiques', style: serifDisplay(desktop ? 36 : 26, weight: FontWeight.w500)),
                ],
              ),
              if (desktop)
                TextButton.icon(
                  onPressed: () => context.push('/product'),
                  icon: const Icon(Icons.arrow_forward_rounded, size: 16, color: FycoColors.ink),
                  label: Text('Voir les détails', style: sans(13, weight: FontWeight.w600, color: FycoColors.ink)),
                ),
            ],
          ),
          const SizedBox(height: 24),
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              for (var i = 0; i < colors.length; i++) ...[
                if (i > 0) const SizedBox(width: 14),
                Expanded(child: _ColorCard(color: colors[i], onTap: () => context.push('/product?color=${colors[i].id}'))),
              ],
            ],
          ),
        ],
      ),
    );
  }

  Widget _creativeGallery(bool desktop) {
    final items = [
      (FycoImages.gallery1, '01 / CONTRASTE', 'Compression sculptante'),
      (FycoImages.gallery2, '02 / DOS OUVERT', 'Lignes architecturales'),
      (FycoImages.gallery3, '03 / ÉNERGIE', 'Nuance Rose Éclatant'),
      (FycoImages.gallery4, '04 / PROFONDEUR', 'Édition Chocolat Intense'),
    ];

    return Container(
      key: _galleryKey,
      padding: EdgeInsets.symmetric(horizontal: desktop ? 64 : 20, vertical: 48),
      color: Colors.white,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('GALLERIE', style: overline()),
                  const SizedBox(height: 6),
                  Text('Vos look FYCO', style: serifDisplay(desktop ? 34 : 24, weight: FontWeight.w500)),
                ],
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                decoration: BoxDecoration(border: Border.all(color: FycoColors.line), borderRadius: BorderRadius.circular(4)),
                child: Text('ÉDITION LIMITÉE', style: sans(10.5, weight: FontWeight.w700)),
              ),
            ],
          ),
          const SizedBox(height: 24),
          desktop
              ? Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(flex: 4, child: _GalleryTile(image: items[0].$1, tag: items[0].$2, caption: items[0].$3, height: 520)),
                    const SizedBox(width: 16),
                    Expanded(flex: 3, child: Column(children: [
                      _GalleryTile(image: items[1].$1, tag: items[1].$2, caption: items[1].$3, height: 252),
                      const SizedBox(height: 16),
                      _GalleryTile(image: items[2].$1, tag: items[2].$2, caption: items[2].$3, height: 252),
                    ])),
                    const SizedBox(width: 16),
                    Expanded(flex: 3, child: _GalleryTile(image: items[3].$1, tag: items[3].$2, caption: items[3].$3, height: 520)),
                  ],
                )
              : Column(
                  children: [
                    _GalleryTile(image: items[0].$1, tag: items[0].$2, caption: items[0].$3, height: 360),
                    const SizedBox(height: 14),
                    Row(children: [
                      Expanded(child: _GalleryTile(image: items[1].$1, tag: items[1].$2, caption: items[1].$3, height: 200)),
                      const SizedBox(width: 12),
                      Expanded(child: _GalleryTile(image: items[2].$1, tag: items[2].$2, caption: items[2].$3, height: 200)),
                    ]),
                    const SizedBox(height: 14),
                    _GalleryTile(image: items[3].$1, tag: items[3].$2, caption: items[3].$3, height: 280),
                  ],
                ),
        ],
      ),
    );
  }

  Widget _featuresStrip(bool desktop) {
    final items = [
      (Icons.auto_fix_high_rounded, 'Effet Sculptant', 'Des lignes sculptantes qui épousent et subliment vos courbes.'),
      (Icons.checkroom_rounded, 'Dos Nu Signature', 'Une découpe élégante qui dévoile et met en valeur votre dos.'),
      (Icons.eco_rounded, 'Douceur au Toucher', 'Une matière douce et agréable à porter au quotidien.'),
      (Icons.local_shipping_outlined, 'Paiement à la Livraison', 'Payez en espèces à la réception de votre commande au Maroc.'),
    ];

    return Container(
      key: _aboutKey,
      width: double.infinity,
      padding: EdgeInsets.symmetric(horizontal: desktop ? 64 : 20, vertical: 42),
      decoration: const BoxDecoration(
        color: FycoColors.surfaceWarm,
        border: Border.symmetric(horizontal: BorderSide(color: FycoColors.line, width: 0.8)),
      ),
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 1100),
          child: desktop
              ? Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    for (var i = 0; i < items.length; i++) ...[
                      if (i > 0) Container(width: 1, height: 60, margin: const EdgeInsets.symmetric(horizontal: 20), color: FycoColors.line),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Icon(items[i].$1, size: 24, color: FycoColors.ink),
                            const SizedBox(height: 12),
                            Text(items[i].$2, style: sans(13.5, weight: FontWeight.w700)),
                            const SizedBox(height: 6),
                            Text(items[i].$3, style: sans(12, color: FycoColors.inkMuted, height: 1.45)),
                          ],
                        ),
                      ),
                    ],
                  ],
                )
              : Wrap(
                  spacing: 20,
                  runSpacing: 24,
                  children: [
                    for (final item in items)
                      SizedBox(
                        width: (MediaQuery.of(context).size.width - 48 - 20) / 2,
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Icon(item.$1, size: 22, color: FycoColors.ink),
                            const SizedBox(height: 10),
                            Text(item.$2, style: sans(13, weight: FontWeight.w700)),
                            const SizedBox(height: 4),
                            Text(item.$3, style: sans(11.5, color: FycoColors.inkMuted, height: 1.4)),
                          ],
                        ),
                      ),
                  ],
                ),
        ),
      ),
    );
  }

  Widget _faqSection(bool desktop) {
    const faqs = [
      ['Quels sont les délais de livraison au Maroc ?', 'Livraison à Casablanca sous 24h et dans toutes les autres villes du Maroc sous 48h.'],
      ['Comment s\'effectue le paiement à la livraison ?', 'Vous ne payez rien en ligne. Vous réglez directement le livreur en espèces dès réception et vérification de votre colis.'],
      ['Quelqu\'un me contacte-t-il avant l\'expédition ?', 'Oui. Notre équipe vous appelle directement sur votre mobile pour confirmer votre taille, la couleur et l’adresse exacte avant l\'envoi.'],
      ['Comment suivre l\'acheminement de ma commande ?', 'Utilisez votre code FYCO avec le bouton « Suivre ma commande » en haut du site pour consulter l\'état en temps réel.'],
    ];

    return Container(
      key: _faqKey,
      width: double.infinity,
      padding: EdgeInsets.symmetric(horizontal: desktop ? 64 : 20, vertical: 56),
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 780),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('QUESTIONS & RÉPONSES', style: overline()),
              const SizedBox(height: 8),
              Text('Tout Ce Qu\'il Faut Savoir', style: serifDisplay(desktop ? 34 : 24, weight: FontWeight.w500)),
              const SizedBox(height: 24),
              for (final f in faqs)
                Container(
                  margin: const EdgeInsets.only(bottom: 12),
                  decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(6), border: Border.all(color: FycoColors.line)),
                  child: Theme(
                    data: Theme.of(context).copyWith(dividerColor: Colors.transparent),
                    child: ExpansionTile(
                      tilePadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 6),
                      childrenPadding: const EdgeInsets.fromLTRB(20, 0, 20, 18),
                      expandedAlignment: Alignment.centerLeft,
                      iconColor: FycoColors.ink,
                      collapsedIconColor: FycoColors.ink,
                      title: Text(f[0], style: sans(14, weight: FontWeight.w600)),
                      children: [Text(f[1], style: sans(13, color: FycoColors.inkMuted, height: 1.55))],
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _footer(bool desktop) {
    return Container(
      width: double.infinity,
      padding: EdgeInsets.symmetric(horizontal: desktop ? 64 : 24, vertical: 32),
      decoration: const BoxDecoration(color: Colors.white, border: Border(top: BorderSide(color: FycoColors.line))),
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 1100),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('© 2026 FYCO made by Mr ZAKARIA FAHSI. Tous droits réservés.', style: sans(11.5, color: FycoColors.inkMuted)),
            ],
          ),
        ),
      ),
    );
  }
}

// ============================================================================
// 5.1 DIALOGUE DE SUIVI & POPUP
// ============================================================================

class _TrackDialog extends StatefulWidget {
  const _TrackDialog();

  @override
  State<_TrackDialog> createState() => _TrackDialogState();
}

class _TrackDialogState extends State<_TrackDialog> {
  final TextEditingController _ctrl = TextEditingController();

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  void _go() {
    final code = _ctrl.text.trim().toUpperCase();
    if (code.isEmpty) return;
    Navigator.pop(context);
    context.push('/track/$code');
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      backgroundColor: FycoColors.background,
      surfaceTintColor: Colors.transparent,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(6)),
      title: Text('Suivre ma commande', style: serifDisplay(20, weight: FontWeight.w600)),
      content: SizedBox(
        width: 340,
        child: TextField(
          controller: _ctrl,
          autofocus: true,
          style: sans(14, weight: FontWeight.w600, color: FycoColors.ink),
          textCapitalization: TextCapitalization.characters,
          onSubmitted: (_) => _go(),
          decoration: fieldDecoration('Code de commande (ex: FYCO-7K3M-P9QD)'),
        ),
      ),
      actionsPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      actions: [
        TextButton(onPressed: () => Navigator.pop(context), child: Text('Annuler', style: sans(13, color: FycoColors.inkMuted))),
        FycoButton(label: 'SUIVRE', onTap: _go),
      ],
    );
  }
}

class _AnimatedComingSoonBanner extends StatefulWidget {
  const _AnimatedComingSoonBanner();

  @override
  State<_AnimatedComingSoonBanner> createState() => _AnimatedComingSoonBannerState();
}

class _AnimatedComingSoonBannerState extends State<_AnimatedComingSoonBanner> {
  Timer? _timer;
  bool _isBlack = true;

  @override
  void initState() {
    super.initState();
    _timer = Timer.periodic(const Duration(milliseconds: 450), (_) {
      if (!mounted) return;
      setState(() => _isBlack = !_isBlack);
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final bg = _isBlack ? const Color(0xFF141211) : const Color(0xFFFAF7F2);
    final fg = _isBlack ? const Color(0xFFFAF7F2) : const Color(0xFF141211);

    return AnimatedContainer(
      duration: const Duration(milliseconds: 220),
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 48),
      decoration: BoxDecoration(
        color: bg,
        border: Border.symmetric(horizontal: BorderSide(color: fg.withOpacity(0.2), width: 1.5)),
      ),
      child: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
              decoration: BoxDecoration(border: Border.all(color: fg, width: 1.2), borderRadius: BorderRadius.circular(20)),
              child: Text('FYCO WEAR // TEASER', style: sans(9.5, weight: FontWeight.w800, color: fg, letterSpacing: 2)),
            ),
            const SizedBox(height: 14),
            AnimatedDefaultTextStyle(
              duration: const Duration(milliseconds: 200),
              style: serifDisplay(MediaQuery.of(context).size.width >= 800 ? 38 : 26, weight: FontWeight.w600, color: fg, letterSpacing: -0.5),
              child: const Text('NOUVELLE COLLECTION BIENTÔT DISPONIBLE', textAlign: TextAlign.center),
            ),
            const SizedBox(height: 8),
            AnimatedDefaultTextStyle(
              duration: const Duration(milliseconds: 200),
              style: sans(13, weight: FontWeight.w500, color: fg.withOpacity(0.85), letterSpacing: 0.5),
              child: const Text('Nouvelles coupes, silhouettes exclusives et nuances inédites en préparation.', textAlign: TextAlign.center),
            ),
          ],
        ),
      ),
    );
  }
}

// ============================================================================
// 6. PAGE PRODUIT
// ============================================================================

class ProductScreen extends StatefulWidget {
  const ProductScreen({super.key, this.initialColorId});
  final String? initialColorId;

  @override
  State<ProductScreen> createState() => _ProductScreenState();
}

class _ProductScreenState extends State<ProductScreen> {
  static const FycoProduct _product = sculptJumpsuit;
  late FycoColor _color;
  String _size = 'M';
  int _quantity = 1;
  int _priceMad = 449;
  int _originalPriceMad = 600;
  bool _productActive = true;
  bool _inventoryManaged = false;
  Map<String, int> _inventory = {};
  StreamSubscription<DocumentSnapshot<Map<String, dynamic>>>? _productSubscription;

  @override
  void initState() {
    super.initState();
    _color = _product.colorById(widget.initialColorId);
    _productSubscription = FirebaseFirestore.instance.collection('store_products').doc(_product.id).snapshots().listen((snapshot) {
      final data = snapshot.data();
      if (data == null || !mounted) return;
      final rawInventory = (data['inventory'] as Map?)?.cast<String, dynamic>() ?? {};
      setState(() {
        _priceMad = (data['priceMad'] as num?)?.toInt() ?? _priceMad;
        _originalPriceMad = (data['originalPriceMad'] as num?)?.toInt() ?? _originalPriceMad;
        _productActive = data['active'] as bool? ?? true;
        _inventoryManaged = data.containsKey('inventory');
        _inventory = rawInventory.map((key, value) => MapEntry(key, (value as num).toInt()));
      });
    });
  }

  @override
  void dispose() {
    _productSubscription?.cancel();
    super.dispose();
  }

  bool get _variantAvailable => !_inventoryManaged || (_inventory['${_color.id}__$_size'] ?? 0) > 0;

  void _addToCart({bool checkout = false}) {
    if (!_productActive || !_variantAvailable) return;
    if (_inventoryManaged && _quantity > (_inventory['${_color.id}__$_size'] ?? 0)) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('La quantité demandée dépasse le stock disponible.')));
      return;
    }
    final liveProduct = FycoProduct(id: _product.id, name: _product.name, tagline: _product.tagline, priceMad: _priceMad, originalPriceMad: _originalPriceMad, colors: _product.colors, sizes: _product.sizes);
    FycoCart.instance.add(liveProduct, _color, _size, quantity: _quantity);
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      backgroundColor: FycoColors.ink,
      content: Text('Ajouté au panier : ${_product.name} (${_color.name}, $_size)', style: sans(13, color: Colors.white)),
      action: SnackBarAction(label: 'VOIR LE PANIER', textColor: Colors.white, onPressed: () => context.push('/cart')),
    ));
    if (checkout) context.push('/cart');
  }

  @override
  Widget build(BuildContext context) {
    final desktop = MediaQuery.of(context).size.width >= 900;
    final image = AspectRatio(
      aspectRatio: 0.8,
      child: ClipRRect(borderRadius: BorderRadius.circular(8), child: FycoImage(_color.image, alignment: Alignment.topCenter)),
    );

    final details = Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('FYCO / PIÈCE MAÎTRESSE', style: overline()),
        const SizedBox(height: 10),
        Text(_product.name, style: serifDisplay(desktop ? 42 : 30, weight: FontWeight.w500)),
        const SizedBox(height: 8),
        Text(_product.tagline, style: sans(14, color: FycoColors.inkMuted, height: 1.4)),
        if (!_productActive) Padding(padding: const EdgeInsets.only(top: 12), child: Text('Produit temporairement indisponible.', style: sans(13, color: FycoColors.danger, weight: FontWeight.w700))),
        const SizedBox(height: 18),
        Row(
          crossAxisAlignment: CrossAxisAlignment.baseline,
          textBaseline: TextBaseline.alphabetic,
          children: [
            Text('$_priceMad MAD', style: sans(24, weight: FontWeight.w700, color: FycoColors.danger)),
            const SizedBox(width: 12),
            Text('$_originalPriceMad MAD', style: sans(18, weight: FontWeight.w500, color: FycoColors.inkMuted).copyWith(decoration: TextDecoration.lineThrough)),
            const SizedBox(width: 14),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
              decoration: BoxDecoration(color: FycoColors.surfaceWarm, borderRadius: BorderRadius.circular(4), border: Border.all(color: FycoColors.line)),
              child: Text('PAIEMENT À LA LIVRAISON', style: sans(10, weight: FontWeight.w700, letterSpacing: 0.6)),
            ),
          ],
        ),
        const SizedBox(height: 24),
        const Divider(color: FycoColors.line),
        const SizedBox(height: 16),
        Text('COULEUR — ${_color.name.toUpperCase()}', style: overline(size: 10.5, color: FycoColors.ink)),
        const SizedBox(height: 12),
        Wrap(
          spacing: 12,
          children: _product.colors.map((c) {
            final sel = c.id == _color.id;
            return InkWell(
              onTap: () => setState(() => _color = c),
              borderRadius: BorderRadius.circular(24),
              child: Container(
                width: 40, height: 40, padding: const EdgeInsets.all(3),
                decoration: BoxDecoration(shape: BoxShape.circle, border: Border.all(color: sel ? FycoColors.ink : FycoColors.line, width: sel ? 2 : 1)),
                child: Container(decoration: BoxDecoration(color: c.swatch, shape: BoxShape.circle, border: Border.all(color: FycoColors.line))),
              ),
            );
          }).toList(),
        ),
        const SizedBox(height: 24),
        Text('TAILLE', style: overline(size: 10.5, color: FycoColors.ink)),
        if (_inventoryManaged && !_variantAvailable) Padding(padding: const EdgeInsets.only(bottom: 8), child: Text('Cette combinaison est en rupture de stock.', style: sans(12, color: FycoColors.danger, weight: FontWeight.w700))),
        const SizedBox(height: 12),
        Wrap(
          spacing: 8,
          children: _product.sizes.map((s) {
            final sel = s == _size;
            return InkWell(
              onTap: () => setState(() => _size = s),
              child: Container(
                width: 52, height: 42, alignment: Alignment.center,
                decoration: BoxDecoration(color: sel ? FycoColors.ink : Colors.white, borderRadius: BorderRadius.circular(4), border: Border.all(color: sel ? FycoColors.ink : FycoColors.line)),
                child: Text(s, style: sans(13, weight: FontWeight.w700, color: sel ? Colors.white : FycoColors.ink)),
              ),
            );
          }).toList(),
        ),
        const SizedBox(height: 24),
        Text('QUANTITÉ', style: overline(size: 10.5, color: FycoColors.ink)),
        const SizedBox(height: 10),
        Container(
          decoration: BoxDecoration(color: Colors.white, border: Border.all(color: FycoColors.line), borderRadius: BorderRadius.circular(4)),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              IconButton(onPressed: _quantity > 1 ? () => setState(() => _quantity--) : null, icon: const Icon(Icons.remove, size: 16)),
              SizedBox(width: 36, child: Text('$_quantity', textAlign: TextAlign.center, style: sans(14, weight: FontWeight.w700))),
              IconButton(onPressed: _quantity < 20 ? () => setState(() => _quantity++) : null, icon: const Icon(Icons.add, size: 16)),
            ],
          ),
        ),
        const SizedBox(height: 28),
        FycoButton(
          expand: true,
          label: 'AJOUTER AU PANIER · ${_priceMad * _quantity} MAD',
          icon: Icons.shopping_bag_outlined,
          onTap: _productActive && _variantAvailable ? () => _addToCart() : null,
        ),
        const SizedBox(height: 10),
        FycoButton(
          expand: true,
          inverted: true,
          label: 'COMMANDER MAINTENANT',
          onTap: _productActive && _variantAvailable ? () => _addToCart(checkout: true) : null,
        ),
        const SizedBox(height: 18),
        Row(
          children: [
            const Icon(Icons.local_shipping_outlined, size: 18, color: FycoColors.ink),
            const SizedBox(width: 10),
            Expanded(child: Text('Livraison gratuite et confirmation téléphonique. Paiement à l\'arrivée.', style: sans(12, color: FycoColors.inkMuted))),
          ],
        ),
      ],
    );

    return Scaffold(
      backgroundColor: FycoColors.background,
      appBar: fycoAppBar(context),
      body: SingleChildScrollView(
        padding: EdgeInsets.symmetric(horizontal: desktop ? 48 : 20, vertical: desktop ? 36 : 20),
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 1040),
            child: desktop
                ? Row(crossAxisAlignment: CrossAxisAlignment.start, children: [Expanded(child: image), const SizedBox(width: 54), Expanded(child: details)])
                : Column(children: [image, const SizedBox(height: 28), details]),
          ),
        ),
      ),
    );
  }
}

// ============================================================================
// 7. PAGE PANIER
// ============================================================================

class CartScreen extends StatelessWidget {
  const CartScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: FycoCart.instance,
      builder: (context, _) {
        final cart = FycoCart.instance;
        final desktop = MediaQuery.of(context).size.width >= 800;
        return Scaffold(
          backgroundColor: FycoColors.background,
          appBar: fycoAppBar(context),
          body: cart.lines.isEmpty
              ? Center(
                  child: Padding(
                    padding: const EdgeInsets.all(28),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(Icons.shopping_bag_outlined, size: 48, color: FycoColors.inkMuted),
                        const SizedBox(height: 16),
                        Text('Votre panier est vide', style: serifDisplay(28, weight: FontWeight.w500)),
                        const SizedBox(height: 8),
                        Text('Sélectionnez une couleur et une taille pour débuter.', style: sans(14, color: FycoColors.inkMuted)),
                        const SizedBox(height: 24),
                        FycoButton(label: 'CONTINUER MES ACHATS', onTap: () => context.go('/product')),
                      ],
                    ),
                  ),
                )
              : SingleChildScrollView(
                  padding: EdgeInsets.all(desktop ? 36 : 20),
                  child: Center(
                    child: ConstrainedBox(
                      constraints: const BoxConstraints(maxWidth: 900),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('VOTRE COMMANDE', style: overline()),
                          const SizedBox(height: 8),
                          Text('Récapitulatif du Panier', style: serifDisplay(34, weight: FontWeight.w500)),
                          const SizedBox(height: 24),
                          for (final line in cart.lines)
                            Container(
                              margin: const EdgeInsets.only(bottom: 12),
                              padding: const EdgeInsets.all(14),
                              decoration: BoxDecoration(color: Colors.white, border: Border.all(color: FycoColors.line), borderRadius: BorderRadius.circular(6)),
                              child: Row(
                                crossAxisAlignment: CrossAxisAlignment.center,
                                children: [
                                  SizedBox(width: 70, height: 90, child: ClipRRect(borderRadius: BorderRadius.circular(4), child: FycoImage(line.color.image))),
                                  const SizedBox(width: 16),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Text(line.product.name, style: sans(15, weight: FontWeight.w700)),
                                        const SizedBox(height: 4),
                                        Text('${line.color.name} · Taille ${line.size}', style: sans(13, color: FycoColors.inkMuted)),
                                        const SizedBox(height: 6),
                                        Text('${line.product.priceMad} MAD', style: sans(13, weight: FontWeight.w600)),
                                        const SizedBox(height: 8),
                                        Row(
                                          children: [
                                            IconButton(visualDensity: VisualDensity.compact, onPressed: () => cart.setQuantity(line, line.quantity - 1), icon: const Icon(Icons.remove_circle_outline, size: 18)),
                                            Text('${line.quantity}', style: sans(13, weight: FontWeight.w700)),
                                            IconButton(visualDensity: VisualDensity.compact, onPressed: () => cart.setQuantity(line, line.quantity + 1), icon: const Icon(Icons.add_circle_outline, size: 18)),
                                          ],
                                        ),
                                      ],
                                    ),
                                  ),
                                  Column(
                                    crossAxisAlignment: CrossAxisAlignment.end,
                                    children: [
                                      Text('${line.subtotal} MAD', style: sans(15, weight: FontWeight.w700)),
                                      IconButton(tooltip: 'Supprimer', onPressed: () => cart.remove(line), icon: const Icon(Icons.delete_outline, size: 20, color: FycoColors.inkMuted)),
                                    ],
                                  ),
                                ],
                              ),
                            ),
                          const SizedBox(height: 14),
                          Container(
                            padding: const EdgeInsets.all(22),
                            decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(6), border: Border.all(color: FycoColors.line)),
                            child: Column(
                              children: [
                                Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [Text('Sous-total articles (${cart.itemCount})', style: sans(14)), Text('${cart.total} MAD', style: sans(14, weight: FontWeight.w600))]),
                                const SizedBox(height: 10),
                                Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [Text('Livraison au Maroc', style: sans(13, color: FycoColors.inkMuted)), Text('Gratuite', style: sans(13, weight: FontWeight.w700, color: FycoColors.success))]),
                                const Divider(height: 28, color: FycoColors.line),
                                Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [Text('TOTAL DÛ À LA LIVRAISON', style: overline(size: 10.5, color: FycoColors.ink)), Text('${cart.total} MAD', style: sans(22, weight: FontWeight.w700))]),
                                const SizedBox(height: 20),
                                FycoButton(expand: true, label: 'PASSER LA COMMANDE', icon: Icons.arrow_forward_rounded, onTap: () => context.push('/checkout')),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
        );
      },
    );
  }
}

// ============================================================================
// 8. PAGE DE COMMANDE (AVEC EMAIL & POINTS FIDÉLITÉ)
// ============================================================================

class CheckoutScreen extends StatefulWidget {
  const CheckoutScreen({super.key, this.colorId, this.size});
  final String? colorId;
  final String? size;

  @override
  State<CheckoutScreen> createState() => _CheckoutScreenState();
}

class _CheckoutScreenState extends State<CheckoutScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameCtrl = TextEditingController();
  final _phoneCtrl = TextEditingController();
  final _emailCtrl = TextEditingController();
  final _addrCtrl = TextEditingController();
  String _city = moroccanCities.first;
  bool _submitting = false;

  @override
  void initState() {
    super.initState();
    if (FycoCart.instance.lines.isEmpty && widget.colorId != null) {
      FycoCart.instance.add(sculptJumpsuit, sculptJumpsuit.colorById(widget.colorId), sculptJumpsuit.sizes.contains(widget.size) ? widget.size! : 'M');
    }
    final user = FirebaseAuth.instance.currentUser;
    if (user != null && user.email != null) {
      _emailCtrl.text = user.email!;
    }
  }

  @override
  void dispose() {
    _nameCtrl.dispose();
    _phoneCtrl.dispose();
    _emailCtrl.dispose();
    _addrCtrl.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    if (FycoCart.instance.lines.isEmpty) return;

    setState(() => _submitting = true);

    final phone = normalizePhone(_phoneCtrl.text);
    final email = normalizeEmail(_emailCtrl.text);
    if (phone == null || email == null) {
      setState(() => _submitting = false);
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(backgroundColor: FycoColors.danger, content: Text('Veuillez vérifier votre numéro de téléphone et votre adresse e-mail.')));
      return;
    }

    final cart = FycoCart.instance;
    final orderItems = cart.toOrderItems();
    final total = cart.total;
    final code = generateOrderCode();
    final earnedPoints = (total / 10).round();

    try {
      await FirebaseFirestore.instance.collection('orders').doc(code).set({
        'orderRef': code,
        'createdAt': FieldValue.serverTimestamp(),
        'status': 'pending_confirmation',
        'customer': {
          'fullName': _nameCtrl.text.trim(),
          'phone': phone,
          'email': email,
          'city': _city,
          'address': _addrCtrl.text.trim(),
        },
        'items': orderItems,
        'itemCount': cart.itemCount,
        'subtotalMad': total,
        'deliveryMad': 0,
        'totalCodMad': total,
        'earnedPoints': earnedPoints,
        'paymentMethod': 'cash_on_delivery',
      });

      final user = FirebaseAuth.instance.currentUser;
      if (user != null) {
        final userRef = FirebaseFirestore.instance.collection('users').doc(user.uid);
        await userRef.set({
          'points': FieldValue.increment(earnedPoints),
          'email': email,
          'lastOrderCode': code,
        }, SetOptions(merge: true));
      }

      if (mounted) {
        cart.clear();
        context.go('/success/$code');
      }
    } catch (e) {
      if (mounted) {
        setState(() => _submitting = false);
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(backgroundColor: FycoColors.danger, content: Text('Erreur lors de la commande : $e')));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: FycoCart.instance,
      builder: (context, _) {
        final cart = FycoCart.instance;
        return Scaffold(
          backgroundColor: FycoColors.background,
          appBar: fycoAppBar(context),
          body: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 28),
            child: Center(
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 720),
                child: Form(
                  key: _formKey,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('INFORMATIONS DE LIVRAISON', style: overline()),
                      const SizedBox(height: 8),
                      Text('Presque chez vous.', style: serifDisplay(36, weight: FontWeight.w500)),
                      const SizedBox(height: 4),
                      Text('Paiement en espèces lors de la livraison partout au Maroc.', style: sans(13.5, color: FycoColors.inkMuted)),
                      const SizedBox(height: 24),
                      Container(
                        padding: const EdgeInsets.all(18),
                        decoration: BoxDecoration(color: Colors.white, border: Border.all(color: FycoColors.line), borderRadius: BorderRadius.circular(6)),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text('RÉCAPITULATIF (${cart.itemCount} ARTICLES)', style: overline(size: 10, color: FycoColors.ink)),
                            const SizedBox(height: 14),
                            for (final line in cart.lines)
                              Padding(
                                padding: const EdgeInsets.only(bottom: 10),
                                child: Row(
                                  children: [
                                    SizedBox(width: 44, height: 56, child: ClipRRect(borderRadius: BorderRadius.circular(4), child: FycoImage(line.color.image))),
                                    const SizedBox(width: 12),
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          Text(line.product.name, style: sans(13.5, weight: FontWeight.w600)),
                                          Text('${line.color.name} · Taille ${line.size} · Qté ${line.quantity}', style: sans(12, color: FycoColors.inkMuted)),
                                        ],
                                      ),
                                    ),
                                    Text('${line.subtotal} MAD', style: sans(13, weight: FontWeight.w600)),
                                  ],
                                ),
                              ),
                            const Divider(color: FycoColors.line),
                            Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [Text('Total dû à la livraison', style: sans(14, weight: FontWeight.w600)), Text('${cart.total} MAD', style: sans(18, weight: FontWeight.w700))]),
                          ],
                        ),
                      ),
                      const SizedBox(height: 24),
                      TextFormField(
                        controller: _nameCtrl,
                        textCapitalization: TextCapitalization.words,
                        style: sans(14, weight: FontWeight.w600, color: FycoColors.ink),
                        decoration: fieldDecoration('Nom et prénom complets'),
                        validator: (v) => (v == null || v.trim().length < 2) ? 'Veuillez saisir votre nom complet' : null,
                      ),
                      const SizedBox(height: 14),
                      TextFormField(
                        controller: _phoneCtrl,
                        keyboardType: TextInputType.phone,
                        style: sans(14, weight: FontWeight.w600, color: FycoColors.ink),
                        decoration: fieldDecoration('Numéro de mobile marocain (ex: 0612345678)'),
                        validator: (v) => normalizePhone(v ?? '') == null ? 'Veuillez entrer un numéro marocain valide (10 chiffres)' : null,
                      ),
                      const SizedBox(height: 14),
                      TextFormField(
                        controller: _emailCtrl,
                        keyboardType: TextInputType.emailAddress,
                        style: sans(14, weight: FontWeight.w600, color: FycoColors.ink),
                        decoration: fieldDecoration('Adresse E-mail (pour recevoir la facture et vos points)'),
                        validator: (v) => normalizeEmail(v ?? '') == null ? 'Veuillez entrer une adresse e-mail valide' : null,
                      ),
                      const SizedBox(height: 14),
                      DropdownButtonFormField<String>(
                        value: _city,
                        decoration: fieldDecoration('Ville de livraison'),
                        dropdownColor: Colors.white,
                        style: sans(14, weight: FontWeight.w600, color: FycoColors.ink),
                        items: moroccanCities.map((c) => DropdownMenuItem(value: c, child: Text(c, style: sans(14, weight: FontWeight.w600, color: FycoColors.ink)))).toList(),
                        onChanged: (v) => setState(() => _city = v ?? _city),
                      ),
                      const SizedBox(height: 14),
                      TextFormField(
                        controller: _addrCtrl,
                        maxLines: 2,
                        textCapitalization: TextCapitalization.sentences,
                        style: sans(14, weight: FontWeight.w600, color: FycoColors.ink),
                        decoration: fieldDecoration('Adresse exacte (Quartier, Rue, Immeuble, Étage)'),
                        validator: (v) => (v == null || v.trim().length < 4) ? 'Veuillez préciser votre adresse de livraison' : null,
                      ),
                      const SizedBox(height: 20),
                      Container(
                        padding: const EdgeInsets.all(14),
                        decoration: BoxDecoration(color: FycoColors.surfaceWarm, borderRadius: BorderRadius.circular(6), border: Border.all(color: FycoColors.line)),
                        child: Row(
                          children: [
                            const Icon(Icons.star_outline, size: 22, color: FycoColors.gold),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Text(
                                'Bonus fidélité : Vous gagnerez ${(cart.total / 10).round()} points fidélité sur cette commande de ${cart.total} MAD !',
                                style: sans(12.5, color: FycoColors.ink, height: 1.4),
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 22),
                      FycoButton(
                        expand: true,
                        loading: _submitting,
                        label: 'CONFIRMER LA COMMANDE · ${cart.total} MAD',
                        icon: Icons.check_circle_outline,
                        onTap: _submit,
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}

// ============================================================================
// 9. PAGE DE SUCCÈS & FACTURE ÉLECTRONIQUE
// ============================================================================

class SuccessScreen extends StatelessWidget {
  const SuccessScreen({super.key, required this.code});
  final String code;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: FycoColors.background,
      appBar: fycoAppBar(context, back: false),
      body: StreamBuilder<DocumentSnapshot<Map<String, dynamic>>>(
        stream: FirebaseFirestore.instance.collection('orders').doc(code).snapshots(),
        builder: (context, snap) {
          final data = snap.data?.data();
          final orderItems = (data?['items'] as List?)?.whereType<Map>().map((x) => x.cast<String, dynamic>()).toList() ?? [];
          final customer = (data?['customer'] as Map?)?.cast<String, dynamic>() ?? {};
          final total = data?['totalCodMad'] ?? 0;
          final points = data?['earnedPoints'] ?? 0;
          final email = customer['email'] ?? '';

          return SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: Center(
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 620),
                child: Column(
                  children: [
                    Container(
                      width: 64, height: 64,
                      decoration: BoxDecoration(shape: BoxShape.circle, color: FycoColors.success.withOpacity(0.12), border: Border.all(color: FycoColors.success)),
                      child: const Icon(Icons.check, color: FycoColors.success, size: 30),
                    ),
                    const SizedBox(height: 20),
                    Text('Commande Enregistrée !', style: serifDisplay(30, weight: FontWeight.w500)),
                    const SizedBox(height: 8),
                    Text(
                      'Un récapitulatif complet a été envoyé à $email. Notre équipe va vous téléphoner pour valider votre taille avant l’expédition.',
                      textAlign: TextAlign.center,
                      style: sans(14, color: FycoColors.inkMuted, height: 1.5),
                    ),
                    const SizedBox(height: 24),
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.symmetric(vertical: 20),
                      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(6), border: Border.all(color: FycoColors.line)),
                      child: Column(
                        children: [
                          Text('VOTRE CODE DE COMMANDE UNIQUE', style: overline(size: 10, color: FycoColors.ink)),
                          const SizedBox(height: 6),
                          SelectableText(code, style: sans(22, weight: FontWeight.w800, letterSpacing: 2)),
                          const SizedBox(height: 4),
                          TextButton.icon(
                            onPressed: () {
                              Clipboard.setData(ClipboardData(text: code));
                              ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Code de commande copié')));
                            },
                            icon: const Icon(Icons.copy_rounded, size: 15, color: FycoColors.ink),
                            label: Text('Copier le code', style: sans(12.5, color: FycoColors.ink)),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 20),
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(20),
                      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(6), border: Border.all(color: FycoColors.line)),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text('FACTURE & DÉTAIL DES ARTICLES', style: overline(size: 10)),
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                decoration: BoxDecoration(color: FycoColors.surfaceWarm, borderRadius: BorderRadius.circular(4)),
                                child: Text('+$points PTS FIDÉLITÉ', style: sans(9.5, weight: FontWeight.w700, color: FycoColors.gold)),
                              ),
                            ],
                          ),
                          const Divider(height: 24, color: FycoColors.line),
                          for (final item in orderItems)
                            Padding(
                              padding: const EdgeInsets.only(bottom: 12),
                              child: Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text('${item['productName']}', style: sans(13.5, weight: FontWeight.w700)),
                                      Text('${item['color']} · Taille ${item['size']} (Qté ${item['quantity']})', style: sans(12, color: FycoColors.inkMuted)),
                                    ],
                                  ),
                                  Text('${item['subtotalMad'] ?? item['priceMad']} MAD', style: sans(13.5, weight: FontWeight.w700)),
                                ],
                              ),
                            ),
                          const Divider(color: FycoColors.line),
                          Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [Text('Montant total à régler au livreur', style: sans(13.5, weight: FontWeight.w600)), Text('$total MAD', style: sans(18, weight: FontWeight.w800))]),
                        ],
                      ),
                    ),
                    const SizedBox(height: 24),
                    FycoButton(
                      expand: true,
                      label: 'SUIVRE EN DIRECT L\'EXPÉDITION',
                      icon: Icons.local_shipping_outlined,
                      onTap: () => context.go('/track/$code'),
                    ),
                    const SizedBox(height: 10),
                    FycoButton(
                      expand: true,
                      inverted: true,
                      label: 'RETOURNER À L\'ACCUEIL',
                      onTap: () => context.go('/'),
                    ),
                  ],
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}

// ============================================================================
// 10. TIMELINE DE SUIVI DU COLIS
// ============================================================================

class TrackingScreen extends StatelessWidget {
  const TrackingScreen({super.key, required this.code});
  final String code;

  static const List<Map<String, String>> _steps = [
    {'key': 'pending_confirmation', 'title': 'Commande Reçue', 'desc': 'En attente de l\'appel de confirmation.'},
    {'key': 'confirmed', 'title': 'Taille & Adresse Confirmées', 'desc': 'Validé par notre équipe logistique.'},
    {'key': 'preparing', 'title': 'Colis en Préparation', 'desc': 'Contrôle qualité et emballage soigné.'},
    {'key': 'shipped', 'title': 'Remis au Transporteur', 'desc': 'En acheminement vers votre ville.'},
    {'key': 'out_for_delivery', 'title': 'En Cours de Livraison', 'desc': 'Le livreur vous contacte lors de son passage.'},
    {'key': 'delivered', 'title': 'Livré & Réglé', 'desc': 'Colis remis et paiement en espèces effectué.'},
  ];

  int _stepIndex(String status) {
    final i = _steps.indexWhere((s) => s['key'] == status);
    return i < 0 ? 0 : i;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: FycoColors.background,
      appBar: fycoAppBar(context),
      body: StreamBuilder<DocumentSnapshot<Map<String, dynamic>>>(
        stream: FirebaseFirestore.instance.collection('orders').doc(code).snapshots(),
        builder: (context, snap) {
          if (snap.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator(color: FycoColors.ink));
          }
          final data = snap.data?.data();
          if (data == null) {
            return Center(child: Text('Aucune commande trouvée pour le code « $code ».', style: sans(14, color: FycoColors.inkMuted)));
          }

          final status = (data['status'] as String?) ?? 'pending_confirmation';
          final orderItems = (data['items'] as List?)?.whereType<Map>().map((x) => x.cast<String, dynamic>()).toList() ?? [];
          final customer = (data['customer'] as Map?)?.cast<String, dynamic>() ?? {};
          final total = data['totalCodMad'] ?? 0;
          final active = _stepIndex(status);

          return SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 28),
            child: Center(
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 620),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      padding: const EdgeInsets.all(20),
                      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(6), border: Border.all(color: FycoColors.line)),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text('SUIVI DE COLIS', style: overline(size: 10)),
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                decoration: BoxDecoration(color: FycoColors.surfaceWarm, borderRadius: BorderRadius.circular(4)),
                                child: Text('PAIEMENT À LA LIVRAISON', style: sans(9.5, weight: FontWeight.w700)),
                              ),
                            ],
                          ),
                          const SizedBox(height: 6),
                          Text(code, style: sans(20, weight: FontWeight.w700, letterSpacing: 1.5)),
                          const Divider(color: FycoColors.line, height: 24),
                          for (final i in orderItems)
                            Text('${i['productName']} — ${i['color']}, Taille ${i['size']} (Qté ${i['quantity']})', style: sans(13, weight: FontWeight.w600)),
                          const SizedBox(height: 6),
                          Text('Destinataire : ${customer['fullName'] ?? ''} · ${customer['city'] ?? ''} · Total : $total MAD', style: sans(12.5, color: FycoColors.inkMuted)),
                        ],
                      ),
                    ),
                    const SizedBox(height: 24),
                    Text('ÉTAPES DE LIVRAISON', style: overline(size: 10.5)),
                    const SizedBox(height: 12),
                    Container(
                      padding: const EdgeInsets.fromLTRB(20, 24, 20, 6),
                      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(6), border: Border.all(color: FycoColors.line)),
                      child: Column(
                        children: List.generate(_steps.length, (i) {
                          final passed = i <= active;
                          final current = i == active;
                          final last = i == _steps.length - 1;
                          return Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Column(
                                children: [
                                  CircleAvatar(
                                    radius: 10,
                                    backgroundColor: passed ? FycoColors.ink : FycoColors.line,
                                    child: passed ? const Icon(Icons.check, size: 12, color: Colors.white) : null,
                                  ),
                                  if (!last) Container(width: 2, height: 42, color: i < active ? FycoColors.ink : FycoColors.line),
                                ],
                              ),
                              const SizedBox(width: 14),
                              Expanded(
                                child: Padding(
                                  padding: const EdgeInsets.only(bottom: 20),
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(_steps[i]['title']!, style: sans(13.5, weight: current ? FontWeight.w700 : FontWeight.w600, color: passed ? FycoColors.ink : FycoColors.inkMuted)),
                                      const SizedBox(height: 2),
                                      Text(_steps[i]['desc']!, style: sans(12, color: FycoColors.inkMuted)),
                                    ],
                                  ),
                                ),
                              ),
                            ],
                          );
                        }),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}

// ============================================================================
// 11. AUTHENTIFICATION UTILISATEUR & MOT DE PASSE OUBLIÉ
// ============================================================================

class AuthScreen extends StatefulWidget {
  const AuthScreen({super.key});

  @override
  State<AuthScreen> createState() => _AuthScreenState();
}

class _AuthScreenState extends State<AuthScreen> {
  bool _isLogin = true;
  bool _isForgot = false;
  final _emailCtrl = TextEditingController();
  final _passCtrl = TextEditingController();
  bool _busy = false;
  String? _error;
  String? _successMessage;

  @override
  void dispose() {
    _emailCtrl.dispose();
    _passCtrl.dispose();
    super.dispose();
  }

  Future<void> _submitAuth() async {
    setState(() { _busy = true; _error = null; _successMessage = null; });
    try {
      if (_isForgot) {
        await FirebaseAuth.instance.sendPasswordResetEmail(email: _emailCtrl.text.trim());
        setState(() {
          _successMessage = 'E-mail de réinitialisation envoyé ! Vérifiez votre boîte de réception.';
          _isForgot = false;
        });
      } else if (_isLogin) {
        await FirebaseAuth.instance.signInWithEmailAndPassword(email: _emailCtrl.text.trim(), password: _passCtrl.text);
        if (mounted) context.go('/profile');
      } else {
        final credential = await FirebaseAuth.instance.createUserWithEmailAndPassword(email: _emailCtrl.text.trim(), password: _passCtrl.text);
        await FirebaseFirestore.instance.collection('users').doc(credential.user!.uid).set({
          'email': _emailCtrl.text.trim(),
          'points': 50,
          'createdAt': FieldValue.serverTimestamp(),
        });
        if (mounted) context.go('/profile');
      }
    } catch (e) {
      setState(() => _error = 'Erreur : ${e.toString()}');
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      WidgetsBinding.instance.addPostFrameCallback((_) => context.go('/profile'));
    }

    return Scaffold(
      backgroundColor: FycoColors.background,
      appBar: fycoAppBar(context),
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 380),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(_isForgot ? 'RÉCUPÉRATION' : (_isLogin ? 'CONNEXION CLIENT' : 'CRÉER UN COMPTE'), style: overline()),
                const SizedBox(height: 8),
                Text(_isForgot ? 'Mot de passe oublié ?' : (_isLogin ? 'Bienvenue chez FYCO' : 'Rejoignez le Club'), style: serifDisplay(30, weight: FontWeight.w500)),
                const SizedBox(height: 6),
                Text(
                  _isForgot
                      ? 'Entrez votre e-mail pour recevoir un lien de réinitialisation.'
                      : (_isLogin ? 'Connectez-vous pour suivre vos commandes et cumuler des points.' : 'Inscrivez-vous et recevez 50 points offerts dès maintenant !'),
                  style: sans(13, color: FycoColors.inkMuted),
                ),
                const SizedBox(height: 24),
                TextField(controller: _emailCtrl, style: sans(14, color: FycoColors.ink), decoration: fieldDecoration('Adresse Email')),
                if (!_isForgot) ...[
                  const SizedBox(height: 14),
                  TextField(controller: _passCtrl, obscureText: true, style: sans(14, color: FycoColors.ink), decoration: fieldDecoration('Mot de passe')),
                ],
                if (_error != null) ...[const SizedBox(height: 12), Text(_error!, style: sans(12.5, color: FycoColors.danger))],
                if (_successMessage != null) ...[const SizedBox(height: 12), Text(_successMessage!, style: sans(12.5, color: FycoColors.success))],
                const SizedBox(height: 20),
                FycoButton(
                  expand: true,
                  loading: _busy,
                  label: _isForgot ? 'ENVOYER LE LIEN' : (_isLogin ? 'SE CONNECTER' : 'S\'INSCRIRE'),
                  onTap: _submitAuth,
                ),
                const SizedBox(height: 14),
                Center(
                  child: Column(
                    children: [
                      TextButton(
                        onPressed: () => setState(() { _isForgot = !_isForgot; _error = null; _successMessage = null; }),
                        child: Text(_isForgot ? 'Retour à la connexion' : 'Mot de passe oublié ?', style: sans(13, weight: FontWeight.w600, color: FycoColors.ink)),
                      ),
                      if (!_isForgot)
                        TextButton(
                          onPressed: () => setState(() { _isLogin = !_isLogin; _error = null; _successMessage = null; }),
                          child: Text(_isLogin ? 'Pas de compte ? Créer un compte' : 'Déjà un compte ? Se connecter', style: sans(13, weight: FontWeight.w600, color: FycoColors.inkMuted)),
                        ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

// ============================================================================
// 11.1 PAGE PROFIL (HISTORIQUE DES COMMANDES & POINTS)
// ============================================================================

class ProfileScreen extends StatelessWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      WidgetsBinding.instance.addPostFrameCallback((_) => context.go('/auth'));
      return const SizedBox.shrink();
    }

    return Scaffold(
      backgroundColor: FycoColors.background,
      appBar: fycoAppBar(context),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 700),
            child: StreamBuilder<DocumentSnapshot<Map<String, dynamic>>>(
              stream: FirebaseFirestore.instance.collection('users').doc(user.uid).snapshots(),
              builder: (context, userSnap) {
                final userData = userSnap.data?.data() ?? {};
                final points = userData['points'] ?? 0;

                return Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('MON ESPACE CLIENT', style: overline()),
                    const SizedBox(height: 8),
                    Text('Profil & Historique', style: serifDisplay(34, weight: FontWeight.w500)),
                    const SizedBox(height: 24),
                    Container(
                      padding: const EdgeInsets.all(24),
                      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(8), border: Border.all(color: FycoColors.line)),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              const CircleAvatar(backgroundColor: FycoColors.ink, child: Icon(Icons.person, color: Colors.white)),
                              const SizedBox(width: 14),
                              Expanded(child: Text(user.email ?? 'Client FYCO', style: sans(15, weight: FontWeight.w700))),
                            ],
                          ),
                          const Divider(height: 32, color: FycoColors.line),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text('SOLDE DE POINTS FIDÉLITÉ', style: overline(size: 10)),
                                  const SizedBox(height: 4),
                                  Text('$points Points', style: sans(24, weight: FontWeight.w800, color: FycoColors.gold)),
                                ],
                              ),
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                                decoration: BoxDecoration(color: FycoColors.surfaceWarm, borderRadius: BorderRadius.circular(4)),
                                child: Text('Club VIP FYCO', style: sans(11, weight: FontWeight.w700)),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 32),
                    Text('VOS COMMANDES PASSÉES', style: overline()),
                    const SizedBox(height: 14),
                    StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
                      stream: FirebaseFirestore.instance
                          .collection('orders')
                          .where('customer.email', isEqualTo: user.email)
                          .snapshots(),
                      builder: (context, orderSnap) {
                        if (orderSnap.connectionState == ConnectionState.waiting) {
                          return const Center(child: CircularProgressIndicator(color: FycoColors.ink));
                        }
                        final docs = orderSnap.data?.docs ?? [];
                        if (docs.isEmpty) {
                          return Container(
                            width: double.infinity,
                            padding: const EdgeInsets.all(28),
                            decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(8), border: Border.all(color: FycoColors.line)),
                            child: Text('Vous n\'avez pas encore passé de commande.', style: sans(13.5, color: FycoColors.inkMuted), textAlign: TextAlign.center),
                          );
                        }

                        return Column(
                          children: docs.map((doc) {
                            final data = doc.data();
                            final code = data['orderRef'] ?? doc.id;
                            final total = data['totalCodMad'] ?? 0;
                            final status = data['status'] ?? 'pending_confirmation';
                            final items = (data['items'] as List?)?.whereType<Map>().map((x) => x.cast<String, dynamic>()).toList() ?? [];

                            return Container(
                              margin: const EdgeInsets.only(bottom: 12),
                              padding: const EdgeInsets.all(18),
                              decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(6), border: Border.all(color: FycoColors.line)),
                              child: Row(
                                children: [
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Text('$code', style: sans(14, weight: FontWeight.w800)),
                                        const SizedBox(height: 4),
                                        Text('${items.length} article(s) · $total MAD', style: sans(13, weight: FontWeight.w600, color: FycoColors.inkMuted)),
                                        const SizedBox(height: 2),
                                        Text('Statut : $status', style: sans(12, color: FycoColors.success, weight: FontWeight.w700)),
                                      ],
                                    ),
                                  ),
                                  FycoButton(
                                    label: 'SUIVRE',
                                    onTap: () => context.push('/track/$code'),
                                  ),
                                ],
                              ),
                            );
                          }).toList(),
                        );
                      },
                    ),
                    const SizedBox(height: 32),
                    FycoButton(
                      expand: true,
                      inverted: true,
                      label: 'SE DÉCONNECTER',
                      onTap: () {
                        FirebaseAuth.instance.signOut();
                        context.go('/');
                      },
                    ),
                  ],
                );
              },
            ),
          ),
        ),
      ),
    );
  }
}

// ============================================================================
// 12. TABLEAU DE BORD ADMINISTRATEUR (CONTRÔLE TOTAL)
// ============================================================================

class AdminScreen extends StatelessWidget {
  const AdminScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<User?>(
      stream: FirebaseAuth.instance.authStateChanges(),
      builder: (context, snap) {
        if (snap.connectionState == ConnectionState.waiting) {
          return const Scaffold(body: Center(child: CircularProgressIndicator()));
        }
        if (snap.data == null) return const _AdminLogin();
        return FutureBuilder<bool>(
          future: snap.data!.getIdTokenResult(true).then((token) => token.claims?['admin'] == true),
          builder: (context, adminSnap) {
            if (adminSnap.connectionState == ConnectionState.waiting) {
              return const Scaffold(body: Center(child: CircularProgressIndicator()));
            }
            if (adminSnap.data != true) {
              return Scaffold(
                backgroundColor: FycoColors.background,
                appBar: fycoAppBar(context),
                body: Container(
                  width: double.infinity,
                  color: FycoColors.background,
                  alignment: Alignment.center,
                  padding: const EdgeInsets.all(24),
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: 520),
                    child: Container(
                      padding: const EdgeInsets.all(28),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: FycoColors.line),
                      ),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(Icons.lock_outline, size: 42, color: FycoColors.ink),
                          const SizedBox(height: 18),
                          Text('Accès administrateur requis', textAlign: TextAlign.center,
                            style: serifDisplay(25, weight: FontWeight.w600)),
                          const SizedBox(height: 12),
                          Text(
                            'Vous êtes connecté, mais ce compte ne possède pas encore le droit administrateur FYCO.',
                            textAlign: TextAlign.center,
                            style: sans(14, color: FycoColors.inkMuted, height: 1.5),
                          ),
                          const SizedBox(height: 18),
                          Container(
                            width: double.infinity,
                            padding: const EdgeInsets.all(14),
                            decoration: BoxDecoration(color: FycoColors.surfaceWarm, borderRadius: BorderRadius.circular(8)),
                            child: Text(
                              'À faire : attribuer le rôle Firebase custom claim admin = true à votre utilisateur, puis vous déconnecter et vous reconnecter.',
                              textAlign: TextAlign.center,
                              style: sans(12, color: FycoColors.ink, weight: FontWeight.w600, height: 1.5),
                            ),
                          ),
                          const SizedBox(height: 20),
                          SizedBox(
                            width: double.infinity,
                            child: OutlinedButton.icon(
                              onPressed: () async => FirebaseAuth.instance.signOut(),
                              icon: const Icon(Icons.logout),
                              label: const Text('Se déconnecter'),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              );
            }
            return const FycoAdminDashboard();
          },
        );
      },
    );
  }
}

class _AdminLogin extends StatefulWidget {
  const _AdminLogin();

  @override
  State<_AdminLogin> createState() => _AdminLoginState();
}

class _AdminLoginState extends State<_AdminLogin> {
  final _email = TextEditingController();
  final _password = TextEditingController();
  bool _busy = false;
  String? _error;

  Future<void> _signIn() async {
    setState(() { _busy = true; _error = null; });
    try {
      await FirebaseAuth.instance.signInWithEmailAndPassword(email: _email.text.trim(), password: _password.text);
    } catch (_) {
      setState(() => _error = 'Identifiants administrateur incorrects.');
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: FycoColors.background,
      appBar: fycoAppBar(context),
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 380),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('ESPACE SÉCURISÉ', style: overline()),
                const SizedBox(height: 8),
                Text('Connexion Admin', style: serifDisplay(30, weight: FontWeight.w500)),
                const SizedBox(height: 22),
                TextField(controller: _email, style: sans(14, color: FycoColors.ink), decoration: fieldDecoration('Adresse Email')),
                const SizedBox(height: 12),
                TextField(controller: _password, obscureText: true, style: sans(14, color: FycoColors.ink), decoration: fieldDecoration('Mot de passe')),
                if (_error != null) ...[const SizedBox(height: 12), Text(_error!, style: sans(12.5, color: FycoColors.danger))],
                const SizedBox(height: 20),
                FycoButton(expand: true, loading: _busy, label: 'SE CONNECTER', onTap: _signIn),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _AdminDashboard extends StatefulWidget {
  const _AdminDashboard();

  @override
  State<_AdminDashboard> createState() => _AdminDashboardState();
}

class _AdminDashboardState extends State<_AdminDashboard> {
  String _filter = 'all';
  String _search = '';

  static const Map<String, String> _statusLabels = {
    'pending_confirmation': 'À Confirmer',
    'confirmed': 'Confirmée',
    'preparing': 'En Préparation',
    'shipped': 'Expédiée',
    'out_for_delivery': 'En Cours de Livraison',
    'delivered': 'Livrée & Payée',
    'canceled': 'Annulée',
  };

  Widget _statCard(String title, String val, {Color? bg, Color? fg}) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(color: bg ?? Colors.white, borderRadius: BorderRadius.circular(6), border: Border.all(color: FycoColors.line)),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(title, style: sans(11, weight: FontWeight.w700, color: fg?.withOpacity(0.8) ?? FycoColors.inkMuted)),
            const SizedBox(height: 4),
            Text(val, style: sans(24, weight: FontWeight.w800, color: fg ?? FycoColors.ink)),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: FycoColors.background,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        title: Text('Tableau de Bord FYCO', style: sans(16, weight: FontWeight.w700)),
        actions: [
          TextButton.icon(onPressed: () => context.push('/admin/products'), icon: const Icon(Icons.inventory_2_outlined, size: 17), label: Text('Produits & stock', style: sans(13, color: FycoColors.ink))),
          TextButton(onPressed: () => FirebaseAuth.instance.signOut(), child: Text('Déconnexion', style: sans(13, color: FycoColors.ink))),
        ],
      ),
      body: StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
        stream: FirebaseFirestore.instance.collection('orders').orderBy('createdAt', descending: true).snapshots(),
        builder: (context, snap) {
          if (snap.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snap.hasError) {
            return Center(
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: SelectableText(
                  'Erreur Firestore : ${snap.error}',
                  style: sans(14, weight: FontWeight.w600, color: FycoColors.danger),
                ),
              ),
            );
          }
          final docs = snap.data?.docs ?? [];

          int toConfirm = 0;
          int inTransit = 0;
          int delivered = 0;
          int totalRevenue = 0;

          for (final d in docs) {
            final st = (d.data()['status'] as String?) ?? 'pending_confirmation';
            final tot = (d.data()['totalCodMad'] as num?)?.toInt() ?? 0;
            if (st == 'pending_confirmation') toConfirm++;
            if (st == 'shipped' || st == 'out_for_delivery') inTransit++;
            if (st == 'delivered') {
              delivered++;
              totalRevenue += tot;
            }
          }

          final filtered = docs.where((doc) {
            final data = doc.data();
            final st = (data['status'] as String?) ?? 'pending_confirmation';
            final cust = (data['customer'] as Map?)?.cast<String, dynamic>() ?? {};
            final name = (cust['fullName'] ?? '').toString().toLowerCase();
            final phone = (cust['phone'] ?? '').toString();
            final ref = (data['orderRef'] ?? doc.id).toString().toLowerCase();

            if (_filter != 'all' && st != _filter) return false;
            if (_search.isNotEmpty) {
              final q = _search.toLowerCase();
              return name.contains(q) || phone.contains(q) || ref.contains(q);
            }
            return true;
          }).toList();

          return SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: Center(
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 960),
                child: Column(
                  children: [
                    Row(
                      children: [
                        _statCard('À CONFIRMER', '$toConfirm', bg: FycoColors.ink, fg: Colors.white),
                        const SizedBox(width: 10),
                        _statCard('EN ROUTE', '$inTransit'),
                        const SizedBox(width: 10),
                        _statCard('LIVRÉES', '$delivered'),
                        const SizedBox(width: 10),
                        _statCard('ENCAISSÉ', '$totalRevenue MAD', bg: FycoColors.success, fg: Colors.white),
                      ],
                    ),
                    const SizedBox(height: 16),
                    Row(
                      children: [
                        Expanded(
                          child: TextField(
                            onChanged: (v) => setState(() => _search = v.trim()),
                            style: sans(13.5, color: FycoColors.ink),
                            decoration: fieldDecoration('Rechercher client, tél, code...'),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 14),
                          decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(6), border: Border.all(color: FycoColors.line)),
                          child: DropdownButton<String>(
                            value: _filter,
                            underline: const SizedBox.shrink(),
                            dropdownColor: Colors.white,
                            style: sans(13, weight: FontWeight.w700, color: FycoColors.ink),
                            items: [
                              const DropdownMenuItem(value: 'all', child: Text('Toutes les commandes')),
                              ..._statusLabels.entries.map((e) => DropdownMenuItem(value: e.key, child: Text(e.value))),
                            ],
                            onChanged: (v) => setState(() => _filter = v ?? 'all'),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    if (filtered.isEmpty)
                      Padding(
                        padding: const EdgeInsets.all(32),
                        child: Center(child: Text('Aucune commande ne correspond aux critères.', style: sans(14, color: FycoColors.inkMuted))),
                      ),
                    for (final doc in filtered) _adminOrderTile(doc),
                  ],
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _adminOrderTile(QueryDocumentSnapshot<Map<String, dynamic>> doc) {
    final d = doc.data();
    final customer = (d['customer'] as Map?)?.cast<String, dynamic>() ?? {};
    final orderItems = (d['items'] as List?)?.whereType<Map>().map((x) => x.cast<String, dynamic>()).toList() ?? [];
    final status = (d['status'] as String?) ?? 'pending_confirmation';
    final safeStatus = _statusLabels.containsKey(status) ? status : 'pending_confirmation';
    final phone = (customer['phone'] ?? '').toString();

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(6), border: Border.all(color: FycoColors.line)),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                SelectableText('${d['orderRef'] ?? doc.id}', style: sans(13, weight: FontWeight.w800, color: FycoColors.ink)),
                const SizedBox(height: 4),
                Text('${customer['fullName']} · ${customer['city']}', style: sans(14, weight: FontWeight.w600, color: FycoColors.ink)),
                Text('$phone · ${customer['email'] ?? 'Sans e-mail'} · ${customer['address']}', style: sans(12.5, color: FycoColors.inkMuted)),
                const SizedBox(height: 6),
                for (final item in orderItems)
                  Text('${item['productName']} [${item['color']}, ${item['size']}] × ${item['quantity']}', style: sans(12, weight: FontWeight.w600, color: FycoColors.ink)),
                const SizedBox(height: 4),
                Text('Total : ${d['totalCodMad']} MAD (Paiement à la livraison)', style: sans(13, weight: FontWeight.w700, color: FycoColors.ink)),
              ],
            ),
          ),
          const SizedBox(width: 14),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              DropdownButton<String>(
                value: safeStatus,
                dropdownColor: Colors.white,
                underline: Container(height: 1, color: FycoColors.ink),
                style: sans(13, weight: FontWeight.w700, color: FycoColors.ink),
                items: _statusLabels.entries.map((e) => DropdownMenuItem(value: e.key, child: Text(e.value))).toList(),
                onChanged: (v) {
                  if (v != null) {
                    doc.reference.update({'status': v}).catchError((err) {
                      debugPrint('Erreur mise à jour statut: $err');
                    });
                  }
                },
              ),
              const SizedBox(height: 8),
              Wrap(
                spacing: 8,
                children: [
                  OutlinedButton.icon(
                    onPressed: () {
                      Clipboard.setData(ClipboardData(text: phone));
                      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Numéro copié : $phone')));
                    },
                    style: OutlinedButton.styleFrom(foregroundColor: FycoColors.ink, side: const BorderSide(color: FycoColors.line), padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6)),
                    icon: const Icon(Icons.copy, size: 13),
                    label: Text('Tél', style: sans(11, weight: FontWeight.w700)),
                  ),
                  ElevatedButton.icon(
                    onPressed: () => context.push('/track/${doc.id}'),
                    style: ElevatedButton.styleFrom(backgroundColor: FycoColors.ink, foregroundColor: Colors.white, elevation: 0, padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6)),
                    icon: const Icon(Icons.remove_red_eye_outlined, size: 13),
                    label: Text('Voir', style: sans(11, weight: FontWeight.w700)),
                  ),
                ],
              ),
            ],
          ),
        ],
      ),
    );
  }
}