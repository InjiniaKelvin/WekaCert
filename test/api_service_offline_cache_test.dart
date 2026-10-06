import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:weka_cert/models/document_category.dart';
import 'package:weka_cert/services/api_service.dart';
import 'package:weka_cert/services/preferences_service.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test('falls back to cached documents when the backend is unavailable', () async {
    SharedPreferences.setMockInitialValues({});
    final prefs = PreferencesService();
    var calls = 0;
    final client = MockClient((request) async {
      calls += 1;
      if (calls == 1 && request.method == 'GET' && request.url.path == '/documents') {
        return http.Response(
          jsonEncode([
            {
              'id': 'doc-1',
              'name': 'Passport',
              'category': 'id',
              'isExpirable': true,
              'expiryDate': '2030-01-01T00:00:00.000Z',
              'createdAt': '2026-01-01T00:00:00.000Z',
            },
          ]),
          200,
          headers: {'content-type': 'application/json'},
        );
      }
      throw const SocketException('offline');
    });
    final api = ApiService(
      baseUrl: 'http://127.0.0.1:1',
      prefs: prefs,
      client: client,
    );

    final online = await api.listDocuments();
    expect(online, hasLength(1));
    expect(online.first.name, 'Passport');
    expect(online.first.category, DocumentCategory.id);

    final cached = await api.listDocuments();
    expect(cached, hasLength(1));
    expect(cached.first.name, 'Passport');
    expect(cached.first.category, DocumentCategory.id);
  });
}
