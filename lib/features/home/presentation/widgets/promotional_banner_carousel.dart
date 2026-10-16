import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../../core/routing/app_routes.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../movie/data/repositories/catalog_providers.dart';
import '../../data/home_banner_repository.dart';
import '../providers/home_preview_provider.dart';

class PromotionalBannerCarousel extends ConsumerStatefulWidget {
  const PromotionalBannerCarousel({super.key});
  @override
  ConsumerState<PromotionalBannerCarousel> createState() =>
      _PromotionalBannerCarouselState();
}

class _PromotionalBannerCarouselState
    extends ConsumerState<PromotionalBannerCarousel>
    with WidgetsBindingObserver {
  final _pages = PageController();
  Timer? _timer;
  int _index = 0;
  int _count = 0;
  bool _interacting = false;
  bool _foreground = true;
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _schedule();
  }

  @override
  void dispose() {
    _timer?.cancel();
    _pages.dispose();
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    _foreground = state == AppLifecycleState.resumed;
    _schedule();
  }

  void _schedule() {
    _timer?.cancel();
    if (!mounted ||
        !_foreground ||
        _interacting ||
        _count < 2 ||
        MediaQuery.disableAnimationsOf(context)) {
      return;
    }
    _timer = Timer(const Duration(seconds: 5), () {
      if (!mounted || !_pages.hasClients) return;
      _pages.animateToPage(
        (_index + 1) % _count,
        duration: const Duration(milliseconds: 420),
        curve: Curves.easeInOut,
      );
    });
  }

  bool _canOpen(HomeBanner banner) =>
      ((banner.ctaType == 'BOOK_NOW' || banner.ctaType == 'VIEW_MOVIE') &&
          banner.movieId != null) ||
      (banner.url?.isNotEmpty == true && banner.ctaType != 'NONE');
  Future<void> _open(HomeBanner banner) async {
    if (ref.read(homeUiPreviewProvider)) return;
    if (banner.movieId != null &&
        (banner.ctaType == 'BOOK_NOW' || banner.ctaType == 'VIEW_MOVIE')) {
      if (banner.ctaType == 'BOOK_NOW') {
        // Only book currently showing movies; never infer prebooking support.
        final movie = await ref
            .read(catalogRepositoryProvider)
            .getMovie(banner.movieId!);
        if (!mounted || movie == null) return;
        context.go(
          movie.status.wireValue == 'NOW_SHOWING'
              ? AppRoutes.showtimesForMovie(movie.id)
              : AppRoutes.movieDetail(movie.id),
        );
      } else {
        context.push(AppRoutes.movieDetail(banner.movieId!));
      }
      return;
    }
    final uri = Uri.tryParse(banner.url ?? '');
    if (uri == null) return;
    if (['https', 'http'].contains(uri.scheme) && uri.host.isNotEmpty) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    } else if ([
          AppRoutes.home,
          AppRoutes.discover,
          AppRoutes.showtimes,
          AppRoutes.orders,
          AppRoutes.account,
        ].contains(uri.path) &&
        uri.scheme.isEmpty &&
        !uri.hasAuthority) {
      if (mounted) context.go(uri.toString());
    }
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(homeBannersProvider);
    final banners = state.value ?? const <HomeBanner>[];
    if (_count != banners.length) {
      _count = banners.length;
      _index = 0;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted) return;
        if (_pages.hasClients) _pages.jumpToPage(0);
        _schedule();
      });
    }
    return Padding(
      padding: const EdgeInsets.fromLTRB(AppSpacing.md, 12, AppSpacing.md, 12),
      child: Column(
        children: [
          AspectRatio(
            aspectRatio: 2.1,
            child: ClipRRect(
              borderRadius: AppRadii.small,
              child: state.isLoading && banners.isEmpty
                  ? Semantics(
                      liveRegion: true,
                      label: 'Đang tải banner',
                      child: const ColoredBox(color: AppColors.surfaceRaised),
                    )
                  : state.hasError && banners.isEmpty
                  ? ColoredBox(
                      color: AppColors.surface,
                      child: Center(
                        child: TextButton.icon(
                          onPressed: () => ref.invalidate(homeBannersProvider),
                          icon: const Icon(Icons.refresh, size: 16),
                          label: const Text('Thử lại banner'),
                        ),
                      ),
                    )
                  : banners.isEmpty
                  ? const ColoredBox(
                      color: AppColors.surface,
                      child: Center(
                        child: Text(
                          'Chưa có banner',
                          style: AppTextStyles.caption,
                        ),
                      ),
                    )
                  : Listener(
                      onPointerDown: (_) {
                        _interacting = true;
                        _schedule();
                      },
                      onPointerUp: (_) {
                        _interacting = false;
                        _schedule();
                      },
                      onPointerCancel: (_) {
                        _interacting = false;
                        _schedule();
                      },
                      child: PageView.builder(
                        key: const ValueKey('home-promotion-carousel'),
                        controller: _pages,
                        itemCount: banners.length,
                        onPageChanged: (index) {
                          setState(() => _index = index);
                          _schedule();
                        },
                        itemBuilder: (context, index) {
                          final banner = banners[index];
                          final provider = banner.image.startsWith('assets/')
                              ? AssetImage(banner.image) as ImageProvider
                              : NetworkImage(banner.image);
                          return InkWell(
                            onTap: _canOpen(banner)
                                ? () async {
                                    try {
                                      await _open(banner);
                                    } catch (_) {
                                      if (context.mounted) {
                                        ScaffoldMessenger.of(
                                          context,
                                        ).showSnackBar(
                                          const SnackBar(
                                            content: Text(
                                              'Không thể mở banner lúc này.',
                                            ),
                                          ),
                                        );
                                      }
                                    }
                                  }
                                : null,
                            child: ColoredBox(
                              color: AppColors.surface,
                              child: Image(
                                image: provider,
                                fit: BoxFit.cover,
                                alignment: switch (banner.focalPoint
                                    .toUpperCase()) {
                                  'LEFT' => Alignment.centerLeft,
                                  'RIGHT' => Alignment.centerRight,
                                  _ => Alignment.center,
                                },
                                semanticLabel: banner.title,
                                errorBuilder: (_, _, _) => const Center(
                                  child: Icon(
                                    Icons.image_not_supported_outlined,
                                    color: AppColors.textMuted,
                                  ),
                                ),
                              ),
                            ),
                          );
                        },
                      ),
                    ),
            ),
          ),
          if (state.hasError && banners.isNotEmpty)
            TextButton.icon(
              onPressed: () => ref.invalidate(homeBannersProvider),
              icon: const Icon(Icons.refresh, size: 16),
              label: const Text('Chưa cập nhật được banner. Thử lại'),
            ),
          if (banners.length > 1)
            Padding(
              padding: const EdgeInsets.only(top: 10),
              child: Wrap(
                alignment: WrapAlignment.center,
                children: List.generate(
                  banners.length,
                  (index) => Semantics(
                    label: 'Banner ${index + 1} / ${banners.length}',
                    selected: index == _index,
                    button: true,
                    child: GestureDetector(
                      behavior: HitTestBehavior.opaque,
                      onTap: () {
                        _schedule();
                        if (MediaQuery.disableAnimationsOf(context)) {
                          _pages.jumpToPage(index);
                        } else {
                          _pages.animateToPage(
                            index,
                            duration: const Duration(milliseconds: 350),
                            curve: Curves.easeInOut,
                          );
                        }
                      },
                      child: SizedBox(
                        width: 48,
                        height: 48,
                        child: Center(
                          child: AnimatedContainer(
                            duration: MediaQuery.disableAnimationsOf(context)
                                ? Duration.zero
                                : const Duration(milliseconds: 200),
                            width: index == _index ? 18 : 5,
                            height: 5,
                            decoration: BoxDecoration(
                              color: index == _index
                                  ? AppColors.gold
                                  : AppColors.border,
                              borderRadius: BorderRadius.circular(4),
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}
