import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/demo/demo_scenario.dart';
import '../../../../core/time/app_clock.dart';
import 'catalog_repository.dart';
import 'mock_catalog_repository.dart';

final appClockProvider = Provider<AppClock>((ref) => const SystemAppClock());

final demoScenarioProvider = Provider<DemoScenario>(
  (ref) => DemoScenario(ref.watch(appClockProvider)),
);

final catalogRepositoryProvider = Provider<CatalogRepository>(
  (ref) => MockCatalogRepository(scenario: ref.watch(demoScenarioProvider)),
);
