// Driver for the profile-mode scroll benchmark.
//
// `integrationDriver()` connects to the app launched by `flutter drive`,
// collects the `reportData` that `scroll_perf_test.dart` stored (one
// TimelineSummary per library) and writes the whole map to
// `build/integration_response_data.json`.
//
// Run:
//   flutter drive \
//     --driver=test_driver/perf_driver.dart \
//     --target=integration_test/scroll_perf_test.dart \
//     --profile -d linux
import 'package:integration_test/integration_test_driver.dart';

Future<void> main() => integrationDriver();
