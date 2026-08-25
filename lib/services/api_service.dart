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

  static const _sampleEndpointBase =
      'https://jsonplaceholder.typicode.com/users';
  final Random _random = Random();

  Future<Customer> fetchCustomerDetails() async {
    final userId = 1 + _random.nextInt(10);

    try {
      final response = await http
          .get(Uri.parse('$_sampleEndpointBase/$userId'))
          .timeout(const Duration(seconds: 6));

      if (response.statusCode == 200) {
        final body = jsonDecode(response.body) as Map<String, dynamic>;
        final fallback = _fallbackCustomer();
        return Customer(
          id: body['id']?.toString() ?? fallback.id,
          name: body['name']?.toString() ?? fallback.name,
          email: body['email']?.toString() ?? fallback.email,
          phone: body['phone']?.toString() ?? fallback.phone,
          address: (body['address'] is Map)
              ? _formatAddress(body['address'] as Map<String, dynamic>)
              : fallback.address,
        );
      }
    } catch (_) {
      // Network unavailable or endpoint failed — fall back to mock data below.
    }

    // Simulated network latency + dynamic fallback payload.
    await Future.delayed(const Duration(milliseconds: 900));
    return _fallbackCustomer();
  }

  String _formatAddress(Map<String, dynamic> address) {
    final street = address['street'] ?? '';
    final city = address['city'] ?? '';
    final zipcode = address['zipcode'] ?? '';
    return '$street, $city $zipcode'.trim();
  }

  Customer _fallbackCustomer() {
    final id = _randomId();
    final firstNames = [
      'Avery',
      'Blake',
      'Casey',
      'Devon',
      'Emery',
      'Finley',
      'Harper',
      'Jordan',
      'Morgan',
      'Riley',
    ];
    final lastNames = [
      'Carter',
      'Diaz',
      'Hayes',
      'Iyer',
      'Kim',
      'Patel',
      'Reed',
      'Shah',
      'Stone',
      'Walker',
    ];
    final streets = [
      'Cedar Lane',
      'Lakeview Drive',
      'Maple Avenue',
      'Market Street',
      'Oak Terrace',
      'Pine Road',
      'River Way',
      'Sunset Boulevard',
    ];
    final cities = [
      'Austin',
      'Boston',
      'Chicago',
      'Denver',
      'Phoenix',
      'Seattle',
    ];

    final firstName = firstNames[_random.nextInt(firstNames.length)];
    final lastName = lastNames[_random.nextInt(lastNames.length)];
    final streetNumber = 100 + _random.nextInt(900);
    final street = streets[_random.nextInt(streets.length)];
    final city = cities[_random.nextInt(cities.length)];

    return Customer(
      id: id,
      name: '$firstName $lastName',
      email: '${firstName.toLowerCase()}.${lastName.toLowerCase()}$id@example.com',
      phone: '+1-555-${(1000 + _random.nextInt(9000)).toString()}',
      address: '$streetNumber $street, $city',
    );
  }

  String _randomId() => (100 + _random.nextInt(900)).toString();
}
