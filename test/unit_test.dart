import 'package:flutter_test/flutter_test.dart';

import 'parser/block_test.dart' as block_test;
import 'parser/edge_cases_test.dart' as edge_cases_test;
import 'parser/gfm_test.dart' as gfm_test;
import 'parser/golden_test.dart' as golden_test;
import 'nodes/nodes_test.dart' as nodes_test;
import 'parser/inline_test.dart' as inline_test;
import 'parser/math_test.dart' as math_test;
import 'parser/parser_test.dart' as parser_test;
import 'parser/regression_test.dart' as regression_test;
import 'selection/markup_formatter_test.dart' as markup_formatter_test;
import 'selection/selection_handles_test.dart' as selection_handles_test;
import 'selection/selection_keyboard_test.dart' as selection_keyboard_test;
import 'selection/selection_test.dart' as selection_test;
import 'selection/selection_widget_test.dart' as selection_widget_test;
import 'theme/theme_test.dart' as theme_test;
import 'widget/render_test.dart' as render_test;
import 'widget/widget_test.dart' as widget_test;

void main() => group('Unit', () {
      parser_test.main();
      block_test.main();
      inline_test.main();
      gfm_test.main();
      edge_cases_test.main();
      math_test.main();
      regression_test.main();
      golden_test.main();
      nodes_test.main();
      theme_test.main();
      selection_test.main();
      markup_formatter_test.main();
      selection_widget_test.main();
      selection_keyboard_test.main();
      selection_handles_test.main();
      render_test.main();
      widget_test.main();
    });
