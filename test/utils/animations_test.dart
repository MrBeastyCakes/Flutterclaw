import 'package:flutter_test/flutter_test.dart';
import 'package:flutterclaw/utils/animations.dart';

void main() {
  group('AppAnimations', () {
    test('durations are positive', () {
      expect(AppAnimations.fast.inMilliseconds, greaterThan(0));
      expect(AppAnimations.normal.inMilliseconds, greaterThan(0));
      expect(AppAnimations.slow.inMilliseconds, greaterThan(0));
    });
  });
}
