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
