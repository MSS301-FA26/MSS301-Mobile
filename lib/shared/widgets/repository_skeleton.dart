import 'package:flutter/material.dart';

import '../../core/theme/app_theme.dart';

enum RepositorySkeleton { movies, showtimes, orders, account, poster, foods }

/// Static placeholders preserve structure without continuous shimmer/animation.
class RepositorySkeletonView extends StatelessWidget {
  const RepositorySkeletonView({super.key, required this.layout});
  final RepositorySkeleton layout;

  @override
  Widget build(BuildContext context) => ExcludeSemantics(
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        if (layout == RepositorySkeleton.movies)
          for (var i = 0; i < 2; i++) ...[
            Row(
              children: [
                for (var j = 0; j < 2; j++) ...[
                  if (j > 0) const SizedBox(width: AppSpacing.sm),
                  const Expanded(
                    child: _Frame(
                      child: Column(
                        children: [
                          AspectRatio(aspectRatio: 2 / 3, child: _Block()),
                          SizedBox(height: 12),
                          _Block(height: 16),
                          SizedBox(height: 8),
                          _Block(height: 12, fraction: 0.7),
                        ],
                      ),
                    ),
                  ),
                ],
              ],
            ),
            const SizedBox(height: AppSpacing.md),
          ]
        else if (layout == RepositorySkeleton.poster)
          const Center(
            child: FractionallySizedBox(
              widthFactor: 0.64,
              child: AspectRatio(aspectRatio: 2 / 3, child: _Block()),
            ),
          )
        else if (layout == RepositorySkeleton.account) ...[
          const _Frame(
            child: Row(
              children: [
                SizedBox(width: 56, height: 56, child: _Block()),
                SizedBox(width: 16),
                Expanded(
                  child: Column(
                    children: [
                      _Block(height: 18),
                      SizedBox(height: 10),
                      _Block(height: 12),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          const _Block(height: 180),
          const SizedBox(height: 16),
          for (var i = 0; i < 4; i++) ...[
            const _Block(height: 48),
            const SizedBox(height: 10),
          ],
        ] else
          for (var i = 0; i < 3; i++) ...[
            _Frame(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Row(
                    children: [
                      SizedBox(
                        width: 64,
                        height: layout == RepositorySkeleton.foods ? 64 : 88,
                        child: const _Block(),
                      ),
                      const SizedBox(width: 16),
                      const Expanded(
                        child: Column(
                          children: [
                            _Block(height: 18),
                            SizedBox(height: 12),
                            _Block(height: 12, fraction: 0.8),
                            SizedBox(height: 8),
                            _Block(height: 12, fraction: 0.6),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  if (layout == RepositorySkeleton.showtimes)
                    const Row(
                      children: [
                        Expanded(child: _Block(height: 42)),
                        SizedBox(width: 10),
                        Expanded(child: _Block(height: 42)),
                        SizedBox(width: 10),
                        Expanded(child: _Block(height: 42)),
                      ],
                    )
                  else
                    const _Block(height: 36),
                ],
              ),
            ),
            const SizedBox(height: AppSpacing.md),
          ],
      ],
    ),
  );
}

class _Frame extends StatelessWidget {
  const _Frame({required this.child});
  final Widget child;
  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.all(AppSpacing.md),
    decoration: BoxDecoration(
      color: AppColors.surface,
      borderRadius: AppRadii.card,
      border: Border.all(color: AppColors.border),
    ),
    child: child,
  );
}

class _Block extends StatelessWidget {
  const _Block({this.height, this.fraction = 1});
  final double? height;
  final double fraction;
  @override
  Widget build(BuildContext context) => FractionallySizedBox(
    widthFactor: fraction,
    alignment: Alignment.centerLeft,
    child: Container(
      height: height,
      decoration: const BoxDecoration(
        color: AppColors.surfaceRaised,
        borderRadius: AppRadii.small,
      ),
    ),
  );
}
