import 'dart:convert';

import 'package:mmkv/mmkv.dart';

import '../models/customer.dart';

/// Wraps MMKV access for persisting customer data fetched by FSD.
class StorageService {
  StorageService._();

  static final StorageService instance = StorageService._();

  static const String _customersKey = 'stored_customers';

  MMKV get _kv => MMKV.defaultMMKV();

  /// Appends [customer] to the locally stored list of customers.
  List<Customer> storeCustomer(Customer customer) {
    final customers = getStoredCustomers();
    customers.removeWhere((c) => c.id == customer.id);
    customers.add(customer);
    final encoded = jsonEncode(customers.map((c) => c.toJson()).toList());
    _kv.encodeString(_customersKey, encoded);
    return customers;
  }

  List<Customer> getStoredCustomers() {
    final raw = _kv.decodeString(_customersKey);
    if (raw == null || raw.isEmpty) return [];
    try {
      final decoded = jsonDecode(raw) as List<dynamic>;
      return decoded
          .map((e) => Customer.fromJson(e as Map<String, dynamic>))
          .toList();
    } catch (_) {
      return [];
    }
  }

  void clearAll() {
    _kv.removeValue(_customersKey);
  }
}
