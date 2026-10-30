import 'package:flutter_test/flutter_test.dart';

import 'coverage_gaps_test.dart' as coverage_gaps_test;
import 'highlight/grammar_coverage_test.dart' as grammar_coverage_test;
import 'highlight/highlight_test.dart' as highlight_test;
import 'nodes/nodes_test.dart' as nodes_test;
import 'parser/block_test.dart' as block_test;
import 'parser/edge_cases_test.dart' as edge_cases_test;
import 'parser/gfm_test.dart' as gfm_test;
import 'parser/golden_test.dart' as golden_test;
import 'parser/hostile_input_test.dart' as hostile_input_test;
import 'parser/inline_test.dart' as inline_test;
import 'parser/math_test.dart' as math_test;
import 'parser/parser_test.dart' as parser_test;
import 'parser/regression_test.dart' as regression_test;
import 'parser/streaming_test.dart' as streaming_test;
import 'selection/markup_formatter_test.dart' as markup_formatter_test;
import 'selection/selection_autoscroll_target_test.dart'
    as selection_autoscroll_target_test;
import 'selection/selection_autoscroll_test.dart' as selection_autoscroll_test;
import 'selection/selection_chrome_test.dart' as selection_chrome_test;
import 'selection/selection_coverage_test.dart' as selection_coverage_test;
import 'selection/selection_controller_edge_test.dart'
    as selection_controller_edge_test;
import 'selection/selection_scope_coverage_test.dart'
    as selection_scope_coverage_test;
import 'selection/selection_scope_regressions_test.dart'
    as selection_scope_regressions_test;
import 'selection/selection_autoscroll_regressions_test.dart'
    as selection_autoscroll_regressions_test;
import 'selection/selection_host_gates_test.dart' as selection_host_gates_test;
import 'selection/selection_nested_blocks_test.dart'
    as selection_nested_blocks_test;
import 'selection/selection_registry_test.dart' as selection_registry_test;
import 'selection/selection_handle_endpoints_test.dart'
    as selection_handle_endpoints_test;
import 'selection/selection_handles_test.dart' as selection_handles_test;
import 'selection/selection_keyboard_test.dart' as selection_keyboard_test;
import 'selection/selection_rtl_test.dart' as selection_rtl_test;
import 'selection/selection_test.dart' as selection_test;
import 'selection/selection_widget_test.dart' as selection_widget_test;
import 'theme/theme_test.dart' as theme_test;
import 'widget/block_painters_test.dart' as block_painters_test;
import 'widget/layout_optimizations_test.dart' as layout_optimizations_test;
import 'widget/render_coverage_test.dart' as render_coverage_test;
import 'widget/inline_image_test.dart' as inline_image_test;
import 'widget/render_object_test.dart' as render_object_test;
import 'widget/render_test.dart' as render_test;
import 'widget/rtl_geometry_test.dart' as rtl_geometry_test;
import 'widget/rtl_test.dart' as rtl_test;
import 'widget/widget_test.dart' as widget_test;

void main() => group('Unit', () {
      parser_test.main();
      hostile_input_test.main();
      block_test.main();
      inline_test.main();
      gfm_test.main();
      edge_cases_test.main();
      math_test.main();
      regression_test.main();
      streaming_test.main();
      golden_test.main();
      nodes_test.main();
      highlight_test.main();
      grammar_coverage_test.main();
      theme_test.main();
      selection_test.main();
      markup_formatter_test.main();
      selection_widget_test.main();
      selection_keyboard_test.main();
      selection_rtl_test.main();
      selection_handles_test.main();
      selection_handle_endpoints_test.main();
      selection_autoscroll_test.main();
      selection_autoscroll_target_test.main();
      selection_host_gates_test.main();
      selection_registry_test.main();
      selection_chrome_test.main();
      selection_nested_blocks_test.main();
      selection_controller_edge_test.main();
      selection_coverage_test.main();
      selection_scope_regressions_test.main();
      selection_scope_coverage_test.main();
      selection_autoscroll_regressions_test.main();
      render_test.main();
      render_object_test.main();
      block_painters_test.main();
      layout_optimizations_test.main();
      render_coverage_test.main();
      inline_image_test.main();
      rtl_test.main();
      rtl_geometry_test.main();
      widget_test.main();
      coverage_gaps_test.main();
    });
