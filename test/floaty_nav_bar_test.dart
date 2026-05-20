import 'package:floatica/floatica.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('FloaticaTab', () {
    test('copyWith preserves unchanged values', () {
      final tab = FloaticaTab(
        isSelected: true,
        title: 'Home',
        onTap: () {},
        icon: const Icon(Icons.home),
      );
      final copied = tab.copyWith(isSelected: false);
      expect(copied.isSelected, false);
      expect(copied.title, 'Home');
    });

    test('display mode defaults are correct', () {
      final tab = FloaticaTab(
        isSelected: false,
        title: 'Test',
        onTap: () {},
        icon: const Icon(Icons.search),
      );
      expect(tab.selectedDisplayMode, FloaticaTabDisplayMode.iconAndTitle);
      expect(tab.unselectedDisplayMode, FloaticaTabDisplayMode.iconOnly);
    });

    test('label position defaults to right', () {
      final tab = FloaticaTab(
        isSelected: false,
        title: 'Test',
        onTap: () {},
        icon: const Icon(Icons.search),
      );
      expect(tab.labelPosition, FloaticaLabelPosition.right);
    });

    test('indicator style defaults to background', () {
      final tab = FloaticaTab(
        isSelected: false,
        title: 'Test',
        onTap: () {},
        icon: const Icon(Icons.search),
      );
      expect(tab.indicatorStyle, FloaticaIndicatorStyle.background);
    });
  });

  group('FloaticaGlassEffect', () {
    test('default values', () {
      const effect = FloaticaGlassEffect();
      expect(effect.blur, 10.0);
      expect(effect.opacity, 0.2);
      expect(effect.borderWidth, 1.0);
      expect(effect.enableShadow, true);
      expect(effect.specularHighlight, false);
      expect(effect.innerShadow, false);
      expect(effect.saturationBoost, 1.0);
      expect(effect.noiseOpacity, 0.0);
    });

    test('liquidGlass preset values', () {
      const effect = FloaticaGlassEffect.liquidGlass();
      expect(effect.blur, 25.0);
      expect(effect.specularHighlight, true);
      expect(effect.innerShadow, true);
      expect(effect.saturationBoost, 1.3);
      expect(effect.noiseOpacity, 0.03);
    });

    test('liquidGlassClear preset values', () {
      const effect = FloaticaGlassEffect.liquidGlassClear();
      expect(effect.blur, 18.0);
      expect(effect.variant, LiquidGlassVariant.clear);
      expect(effect.innerShadow, false);
    });
  });

  group('FloaticaMenuController', () {
    test('initial state is closed', () {
      final controller = FloaticaMenuController();
      expect(controller.isOpen, false);
      controller.dispose();
    });

    test('open sets pending action', () {
      final controller = FloaticaMenuController();
      controller.open();
      final action = controller.consumeAction();
      expect(action, FloaticaMenuAction.open);
      controller.dispose();
    });

    test('consumeAction clears pending action', () {
      final controller = FloaticaMenuController();
      controller.toggle();
      final first = controller.consumeAction();
      final second = controller.consumeAction();
      expect(first, FloaticaMenuAction.toggle);
      expect(second, null);
      controller.dispose();
    });

    test('open when already open does nothing', () {
      final controller = FloaticaMenuController();
      controller.updateIsOpen(true);
      controller.open();
      final action = controller.consumeAction();
      expect(action, null);
      controller.dispose();
    });
  });

  group('FloaticaMenuItem', () {
    test('stores values correctly', () {
      final item = FloaticaMenuItem(
        icon: const Icon(Icons.home),
        title: 'Home',
        onTap: () {},
      );
      expect(item.title, 'Home');
      expect(item.backgroundColor, null);
      expect(item.iconPadding, null);
    });
  });

  group('FloatyNavBar Widget', () {
    testWidgets('renders with minimal config', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: FloatyNavBar(
              selectedTab: 0,
              tabs: [
                FloaticaTab(
                  isSelected: true,
                  title: 'Home',
                  onTap: () {},
                  icon: const Icon(Icons.home),
                ),
                FloaticaTab(
                  isSelected: false,
                  title: 'Search',
                  onTap: () {},
                  icon: const Icon(Icons.search),
                ),
              ],
            ),
          ),
        ),
      );

      expect(find.byType(FloatyNavBar), findsOneWidget);
    });

    testWidgets('renders many tabs without overflow', (tester) async {
      // Set a very small screen size
      tester.view.physicalSize = const Size(300, 400);
      tester.view.devicePixelRatio = 1.0;

      final tabs = List.generate(
        10,
        (i) => FloaticaTab(
          isSelected: i == 0,
          title: 'Tab $i',
          onTap: () {},
          icon: const Icon(Icons.circle),
        ),
      );

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            extendBody: true,
            body: FloatyNavBar(
              selectedTab: 0,
              tabs: tabs,
            ),
          ),
        ),
      );

      // Should not throw overflow errors
      expect(find.byType(FloatyNavBar), findsOneWidget);
      expect(tester.takeException(), isNull);

      // Reset screen size
      tester.view.resetPhysicalSize();
      tester.view.resetDevicePixelRatio();
    });
  });
}
