# -*- coding: utf-8 -*-
from pathlib import Path

ROOT = Path(r'd:\fpt\ky8\PRM393\assignment\lib')
TEST = Path(r'd:\fpt\ky8\PRM393\assignment\test')


def w(rel: str, content: str, root: Path = ROOT) -> None:
    p = root / rel
    p.parent.mkdir(parents=True, exist_ok=True)
    p.write_text(content.strip() + '\n', encoding='utf-8')
    print(('test/' if root == TEST else 'lib/') + rel)


w('main.dart', r'''
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:chuoi_xanh_viet/app.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(const ProviderScope(child: ChuoiXanhVietApp()));
}
''')

w('app.dart', r'''
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:chuoi_xanh_viet/core/router/app_router.dart';
import 'package:chuoi_xanh_viet/core/theme/app_theme.dart';

class ChuoiXanhVietApp extends ConsumerWidget {
  const ChuoiXanhVietApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final router = ref.watch(appRouterProvider);
    return MaterialApp.router(
      title: 'Chuỗi Xanh Việt',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.light,
      routerConfig: router,
    );
  }
}
''')

w('widget_test.dart', r'''
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:chuoi_xanh_viet/app.dart';

void main() {
  testWidgets('App boots', (tester) async {
    await tester.pumpWidget(
      const ProviderScope(child: ChuoiXanhVietApp()),
    );
    await tester.pump(const Duration(milliseconds: 100));
    expect(find.byType(ChuoiXanhVietApp), findsOneWidget);
  });
}
''', root=TEST)

print('main app test done')
