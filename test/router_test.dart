import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:voyager/voyager.dart';

import 'mock_classes.dart';
import 'mock_classes_cupertino.dart';
import 'navigation_yml.dart';

class MyMockedEntity {
  final Object db;
  const MyMockedEntity(this.db);
}

void main() {
  test('using global entity', () async {
    final paths = loadPathsFromString('''
---
'/home' :
  type: 'home'
  widget: HomeWidget
  title: "This is Home"
  fab: /other/thing
'/other/:title' :
  type: 'other'
  widget: OtherWidget
  title: "This is %{title}"
''');
    final plugins = [
      WidgetPlugin({
        "HomeWidget": (context) => MockHomeWidget(),
        "OtherWidget": (context) => MockOtherWidget(),
      })
    ];

    final router = await loadRouter(paths, plugins);
    final myDatabase = MyMockedEntity("database");

    router.registerGlobalEntity("database", myDatabase);
    expect(router.getGlobalEntity("database"), myDatabase);
  });

  test('getting plugins', () async {
    final paths = loadPathsFromString('''
---
'/home' :
  type: 'home'
  widget: HomeWidget
  title: "This is Home"
  fab: /other/thing
'/other/:title' :
  type: 'other'
  widget: OtherWidget
  title: "This is %{title}"
''');
    final plugins = [
      WidgetPlugin({
        "HomeWidget": (context) => MockHomeWidget(),
        "OtherWidget": (context) => MockOtherWidget(),
      }),
      RedirectPlugin()
    ];

    final router = await loadRouter(paths, plugins);
    final routerPlugins = router.getPlugins();

    expect(routerPlugins.length, 2);
    expect(routerPlugins["widget"], isInstanceOf<WidgetPlugin>());
    expect(routerPlugins["redirect"], isInstanceOf<RedirectPlugin>());
  });

  test('voyager caching', () async {
    final paths = loadPathsFromString('''
---
'/home' :
  type: 'home'
  widget: HomeWidget
  title: "This is Home"
  fab: /other/thing
'/other/:title' :
  type: 'other'
  widget: OtherWidget
  title: "This is %{title}"
''');
    final plugins = [
      WidgetPlugin({
        "HomeWidget": (context) => MockHomeWidget(),
        "OtherWidget": (context) => MockOtherWidget(),
      }),
      RedirectPlugin()
    ];

    final router = await loadRouter(paths, plugins);

    final thing1 = router.findCached("/other/thing");
    final thing2 = router.findCached("/other/thing");
    final thing3 = router.findCached("/other/thingy");

    expect(thing1.hashCode, thing2.hashCode);
    expect(thing1.hashCode, isNot(thing3.hashCode));
  });

  test('non string value of type', () async {
    final paths = loadPathsFromString('''
---
'/home' :
  type: 'home'
  widget: HomeWidget
  title: "This is Home"
  fab: /other/thing
'/other/:title' :
  type: [1, 2, 3]
  widget: OtherWidget
  title: "This is %{title}"
''');
    final plugins = [
      WidgetPlugin({
        "HomeWidget": (context) => MockHomeWidget(),
        "OtherWidget": (context) => MockOtherWidget(),
      }),
      RedirectPlugin()
    ];

    final router = await loadRouter(paths, plugins);
    expect(() => router.find("/other/thing"), throwsA(predicate((e) {
      expect(e, isInstanceOf<AssertionError>());
      expect((e as AssertionError).message,
          "Provided type value must be String but is [1, 2, 3] instead!");
      return true;
    })));
  });

  testWidgets('test material navigation', (WidgetTester tester) async {
    await tester.runAsync(() async {
      final paths = loadPathsFromString(navigation_yml);
      final plugins = [
        WidgetPlugin({
          "HomeWidget": (context) => MockHomeWidget(),
          "OtherWidget": (context) => MockOtherWidget(),
        })
      ];

      final router = await loadRouter(paths, plugins);

      expect(router, isInstanceOf<RouterNG>());

      await tester.pumpWidget(Provider<RouterNG>.value(
          value: router,
          child: MaterialApp(
              home: VoyagerWidget(path: "/home"),
              onGenerateRoute:
                  router.generator(routeType: RouterNG.materialRoute))));

      expect(find.text("Home Page"), findsOneWidget);
      expect(find.text("Home Title"), findsOneWidget);
      expect(find.text("Other Page"), findsNothing);

      await tester.tap(find.byType(Icon));
      await tester.pumpAndSettle();
      expect(find.text("Other Page"), findsOneWidget);
    });
  });

  testWidgets('test cupertino navigation', (WidgetTester tester) async {
    await tester.runAsync(() async {
      final paths = loadPathsFromString(navigation_yml);
      final plugins = [
        WidgetPlugin({
          "HomeWidget": (context) => MockCupertinoHomeWidget(),
          "OtherWidget": (context) => MockCupertinoOtherWidget(),
        })
      ];

      final router = await loadRouter(paths, plugins);

      expect(router, isInstanceOf<RouterNG>());

      await tester.pumpWidget(Provider<RouterNG>.value(
          value: router,
          child: CupertinoApp(
              home: VoyagerWidget(path: "/home"),
              onGenerateRoute:
                  router.generator(routeType: RouterNG.cupertinoRoute))));

      expect(find.text("Home Page"), findsOneWidget);
      expect(find.text("Home Title"), findsOneWidget);
      expect(find.text("Other Page"), findsNothing);

      expect(find.widgetWithText(CupertinoButton, 'Navigate'), findsOneWidget);
      await tester.tap(find.text('Navigate'));
      await tester.pumpAndSettle();
      expect(find.text("Other Page"), findsOneWidget);
    });
  });

  testWidgets('test 9000 navigation', (WidgetTester tester) async {
    await tester.runAsync(() async {
      final paths = loadPathsFromString(navigation_yml);
      final plugins = [
        WidgetPlugin({
          "HomeWidget": (context) => MockHomeWidget(),
          "OtherWidget": (context) => MockOtherWidget(),
        })
      ];

      final router = await loadRouter(paths, plugins);

      expect(router, isInstanceOf<RouterNG>());

      final generator = router.generator(routeType: 9000);
      try {
        generator(RouteSettings(name: "/other/thing"));
      } catch (e) {
        expect(e, isInstanceOf<ArgumentError>());
        expect((e as ArgumentError).message, "routeType = 9000 not supported");
      }
    });
  });
}
