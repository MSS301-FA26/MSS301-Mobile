import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mss301_mobile/core/theme/app_theme.dart';
import 'package:mss301_mobile/shared/widgets/app_button.dart';
import 'package:mss301_mobile/shared/widgets/app_surface.dart';
import 'package:mss301_mobile/shared/widgets/repository_state_pane.dart';

Widget _testApp(Widget child) => MaterialApp(
  theme: AppTheme.dark,
  home: Scaffold(body: Center(child: child)),
);

void main() {
  testWidgets('AppButton supports full width and keeps its callback', (
    tester,
  ) async {
    var pressed = false;
    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.dark,
        home: Scaffold(
          body: Center(
            child: SizedBox(
              width: 320,
              child: AppButton(
                label: 'Continue',
                fullWidth: true,
                onPressed: () => pressed = true,
              ),
            ),
          ),
        ),
      ),
    );

    expect(tester.getSize(find.byType(AppButton)), const Size(320, 48));
    await tester.tap(find.byType(FilledButton));
    expect(pressed, isTrue);
  });

  testWidgets('AppButton loading state disables action and shows progress', (
    tester,
  ) async {
    await tester.pumpWidget(
      _testApp(
        const AppButton(label: 'Saving', onPressed: null, loading: true),
      ),
    );

    expect(find.byType(CircularProgressIndicator), findsOneWidget);
    expect(
      tester.widget<FilledButton>(find.byType(FilledButton)).onPressed,
      isNull,
    );
  });

  testWidgets('AppSurface uses shared surface and radius defaults', (
    tester,
  ) async {
    await tester.pumpWidget(_testApp(const AppSurface(child: Text('Panel'))));

    final container = tester.widget<Container>(
      find.descendant(
        of: find.byType(AppSurface),
        matching: find.byType(Container),
      ),
    );
    final decoration = container.decoration! as BoxDecoration;
    expect(decoration.color, AppColors.primarySurface);
    expect(decoration.borderRadius, AppRadii.large);
  });

  testWidgets('RepositoryStatePane retry action remains callable', (
    tester,
  ) async {
    var retried = false;
    await tester.pumpWidget(
      _testApp(RepositoryStatePane.error(onRetry: () => retried = true)),
    );

    await tester.tap(find.text('Thử lại'));
    expect(retried, isTrue);
  });
}
