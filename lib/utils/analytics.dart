import 'package:firebase_analytics/firebase_analytics.dart';

class Analytics {

  static FirebaseAnalytics analytics = FirebaseAnalytics.instance;

  static Future<void> sendAnalyticsEvent(String key, [String value1 ='', String value2='', String value3='']) async {
    await analytics.logEvent(name: key, parameters: {'value' : value1, 'value2': value2, 'value3' : value3});

  }

}
