import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/demo/demo_scenario.dart';
import '../../../../core/time/app_clock.dart';
import '../../../../core/network/network_providers.dart';
import 'catalog_repository.dart';
import 'mock_catalog_repository.dart';
import 'remote_catalog_repository.dart';

final appClockProvider = Provider<AppClock>((ref) => const SystemAppClock());

final demoScenarioProvider = Provider<DemoScenario>(
  (ref) => DemoScenario(ref.watch(appClockProvider)),
);

final mockCatalogRepositoryProvider = Provider<CatalogRepository>(
  (ref) => MockCatalogRepository(scenario: ref.watch(demoScenarioProvider)),
);

final catalogRepositoryProvider = Provider<CatalogRepository>(
  (ref) => RemoteCatalogRepository(ref.watch(dioProvider)),
);
