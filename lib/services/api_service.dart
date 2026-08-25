import 'dart:convert';
import 'dart:math';

import 'package:http/http.dart' as http;

import '../models/customer.dart';

/// Simulates a backend API call that returns customer details.
///
/// A real HTTP request is issued against a public test endpoint to
/// demonstrate the `http` package in action; the JSON body returned by
/// that endpoint is then mapped onto a dummy [Customer] object so the
/// demo does not depend on a specific backend contract.
class ApiService {
  ApiService._();

  static final ApiService instance = ApiService._();

  static const _sampleEndpoint = 'https://jsonplaceholder.typicode.com/users/1';

  Future<Customer> fetchCustomerDetails() async {
    try {
      final response = await http
          .get(Uri.parse(_sampleEndpoint))
          .timeout(const Duration(seconds: 6));

      if (response.statusCode == 200) {
        final body = jsonDecode(response.body) as Map<String, dynamic>;
        return Customer(
          id: body['id']?.toString() ?? _randomId(),
          name: body['name']?.toString() ?? 'Unknown Customer',
          email: body['email']?.toString() ?? 'unknown@example.com',
          phone: body['phone']?.toString() ?? '+1-000-000-0000',
          address: (body['address'] is Map)
              ? _formatAddress(body['address'] as Map<String, dynamic>)
              : '221B Baker Street, London',
        );
      }
    } catch (_) {
      // Network unavailable or endpoint failed — fall back to mock data below.
    }

    // Simulated network latency + dummy fallback payload.
    await Future.delayed(const Duration(milliseconds: 900));
    final id = _randomId();
    return Customer(
      id: id,
      name: 'Alex Johnson',
      email: 'alex.johnson@example.com',
      phone: '+1-555-0${id.padLeft(3, '0')}',
      address: '742 Evergreen Terrace, Springfield',
    );
  }

  String _formatAddress(Map<String, dynamic> address) {
    final street = address['street'] ?? '';
    final city = address['city'] ?? '';
    final zipcode = address['zipcode'] ?? '';
    return '$street, $city $zipcode'.trim();
  }

  String _randomId() => (100 + Random().nextInt(900)).toString();
}
