import 'package:beamer/beamer.dart';
import 'package:flutter/material.dart';

import 'package:flutter_test/flutter_test.dart';

import 'test_locations.dart';

void main() {
  final location2 = Location2(const RouteInformation(location: '/l2/1'));
  group('prepare', () {
    test('BeamLocation can create valid URI', () {
      location2.state = location2.state.copyWith(
        pathParameters: {'id': '42'},
        queryParameters: {'q': 'xxx'},
      );
      expect(location2.state.uri.toString(), '/l2/42?q=xxx');
    });
  });

  group('NotFound', () {
    testWidgets('has "empty" function overrides, but has a state',
        (tester) async {
      BuildContext? testContext;
      await tester.pumpWidget(
        Builder(
          builder: (context) {
            testContext = context;
            return Container();
          },
        ),
      );

      final notFound = NotFound(path: '/test');
      expect(notFound.pathPatterns, []);
      expect(notFound.buildPages(testContext!, BeamState()), []);
      expect(notFound.state.uri.toString(), '/test');
    });
  });

  group('EmptyBeamLocation', () {
    testWidgets('has "empty" function overrides', (tester) async {
      BuildContext? testContext;
      await tester.pumpWidget(
        Builder(
          builder: (context) {
            testContext = context;
            return Container();
          },
        ),
      );

      final notFound = EmptyBeamLocation();
      expect(notFound.pathPatterns, []);
      expect(notFound.buildPages(testContext!, BeamState()), []);
    });
  });

  group('State', () {
    test('updating state directly will add to history', () {
      final beamLocation = Location1();
      expect(beamLocation.history.length, 1);
      expect(beamLocation.history[0].routeInformation.location, '/');

      beamLocation.state = BeamState.fromUriString('/l1');
      expect(beamLocation.history.length, 2);
      expect(beamLocation.history[1].routeInformation.location, '/l1');
    });
  });

  group('Listeners', () {
    testWidgets('are registered after beamBack', (tester) async {
      final beamLocation1 = Location1();
      final beamLocation2 = Location2();

      final beamerDelegate = BeamerDelegate(
        initialPath: '/l1',
        locationBuilder: BeamerLocationBuilder(
          beamLocations: [
            beamLocation1,
            beamLocation2,
          ],
        ),
      );

      await tester.pumpWidget(
        MaterialApp.router(
          routerDelegate: beamerDelegate,
          routeInformationParser: BeamerParser(),
        ),
      );
      expect(beamerDelegate.currentBeamLocation, isA<Location1>());
      expect(
        (beamerDelegate.currentBeamLocation as Location1).doesHaveListeners,
        true,
      );

      beamerDelegate.beamToNamed('/l2');
      expect(beamerDelegate.currentBeamLocation, isA<Location2>());
      expect(
        (beamerDelegate.currentBeamLocation as Location2).doesHaveListeners,
        true,
      );

      beamerDelegate.beamBack();
      expect(beamerDelegate.currentBeamLocation, isA<Location1>());
      expect(
        (beamerDelegate.currentBeamLocation as Location1).doesHaveListeners,
        true,
      );
    });
  });

  testWidgets('strict path patterns', (tester) async {
    final delegate = BeamerDelegate(
      locationBuilder: BeamerLocationBuilder(
        beamLocations: [StrictPatternsLocation()],
      ),
    );

    await tester.pumpWidget(
      MaterialApp.router(
        routerDelegate: delegate,
        routeInformationParser: BeamerParser(),
      ),
    );

    expect(delegate.currentBeamLocation, isA<NotFound>());

    delegate.beamToNamed('/strict');
    expect(delegate.currentBeamLocation, isA<StrictPatternsLocation>());

    delegate.beamToNamed('/strict/deeper');
    expect(delegate.currentBeamLocation, isA<StrictPatternsLocation>());

    delegate.beamToNamed('/');
    expect(delegate.currentBeamLocation, isA<NotFound>());
  });
}
