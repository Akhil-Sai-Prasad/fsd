import 'package:flutter/material.dart';
import 'package:shared_store/shared_store.dart';
import 'package:url_launcher/url_launcher.dart';

import '../services/api_service.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  Customer? _customer;
  bool _isLoading = false;
  String? _errorMessage;
  bool _wasStored = false;

  Future<void> _fetchCustomerDetails() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
      _wasStored = false;
    });

    try {
      final customer = await ApiService.instance.fetchCustomerDetails();

      // Auto-save: a freshly fetched record goes straight into the shared
      // store, so QT and LT can read it without it ever travelling in a URL.
      await CustomerStore.upsert(customer);

      if (!mounted) return;
      setState(() {
        _customer = customer;
        _isLoading = false;
        _wasStored = true;
      });
      _showSnackBar('Customer fetched and saved to the shared store.');
    } on SharedStoreException catch (e) {
      if (!mounted) return;
      setState(() {
        _errorMessage = 'Fetched, but could not write to the shared store: '
            '${e.message}';
        _isLoading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _errorMessage = 'Failed to fetch customer details. Please try again.';
        _isLoading = false;
      });
    }
  }

  Future<void> _goToQt() async {
    final customer = _customer;
    if (customer == null) return;

    // The record is already in the shared store; the link only says which one.
    final uri = Uri.parse('qtapp://customer?id=${Uri.encodeComponent(customer.id)}');

    try {
      final launched = await launchUrl(
        uri,
        mode: LaunchMode.externalApplication,
      );
      if (!launched && mounted) {
        _showSnackBar(
          'Could not open QT app. Is it installed on this device?',
          isError: true,
        );
      }
    } catch (e) {
      if (mounted) {
        _showSnackBar('Failed to launch QT app: $e', isError: true);
      }
    }
  }

  Future<void> _goToLt() async {
    if (_customer == null) return;

    // LT reads the list out of the shared store, so the link carries nothing.
    final uri = Uri.parse('ltapp://customers');

    try {
      final launched = await launchUrl(
        uri,
        mode: LaunchMode.externalApplication,
      );
      if (!launched && mounted) {
        _showSnackBar(
          'Could not open LT app. Is it installed on this device?',
          isError: true,
        );
      }
    } catch (e) {
      if (mounted) {
        _showSnackBar('Failed to launch LT app: $e', isError: true);
      }
    }
  }

  void _showSnackBar(String message, {bool isError = false}) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: isError ? Colors.red.shade600 : Colors.green.shade600,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final hasCustomer = _customer != null;

    return Scaffold(
      appBar: AppBar(
        title: const Text('FSD'),
        centerTitle: true,
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Card(
                elevation: 1,
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Customer Data Source',
                        style: Theme.of(context).textTheme.titleMedium,
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Fetch a customer record from the backend. It is '
                        'written straight to the shared store, so QT and LT '
                        'can read it without it travelling in a deep link.',
                        style: Theme.of(context).textTheme.bodyMedium,
                      ),
                      const SizedBox(height: 16),
                      SizedBox(
                        width: double.infinity,
                        child: ElevatedButton.icon(
                          onPressed: _isLoading ? null : _fetchCustomerDetails,
                          icon: _isLoading
                              ? const SizedBox(
                                  width: 18,
                                  height: 18,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                    color: Colors.white,
                                  ),
                                )
                              : const Icon(Icons.cloud_download_outlined),
                          label: Text(
                            _isLoading
                                ? 'Fetching...'
                                : 'Fetch Customer Details',
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              if (_errorMessage != null) ...[
                const SizedBox(height: 16),
                Card(
                  color: Colors.red.shade50,
                  elevation: 0,
                  child: Padding(
                    padding: const EdgeInsets.all(12),
                    child: Row(
                      children: [
                        Icon(Icons.error_outline, color: Colors.red.shade700),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            _errorMessage!,
                            style: TextStyle(color: Colors.red.shade700),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
              if (hasCustomer) ...[
                const SizedBox(height: 16),
                Card(
                  elevation: 1,
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            const Icon(Icons.person_outline),
                            const SizedBox(width: 8),
                            Text(
                              'Customer Details',
                              style: Theme.of(context).textTheme.titleMedium,
                            ),
                            const Spacer(),
                            if (_wasStored)
                              Chip(
                                label: const Text('Stored'),
                                avatar: const Icon(Icons.check, size: 16),
                                backgroundColor: Colors.green.shade50,
                                labelStyle: TextStyle(
                                  color: Colors.green.shade700,
                                ),
                              ),
                          ],
                        ),
                        const Divider(height: 24),
                        _DetailRow(label: 'ID', value: _customer!.id),
                        _DetailRow(label: 'Name', value: _customer!.name),
                        _DetailRow(label: 'Email', value: _customer!.email),
                        _DetailRow(label: 'Phone', value: _customer!.phone),
                        _DetailRow(label: 'Address', value: _customer!.address),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                Row(
                  children: [
                    Expanded(
                      child: ElevatedButton.icon(
                        onPressed: hasCustomer ? _goToQt : null,
                        icon: const Icon(Icons.open_in_new),
                        label: const Text('Go to QT'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.indigo,
                          foregroundColor: Colors.white,
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: ElevatedButton.icon(
                        onPressed: hasCustomer ? _goToLt : null,
                        icon: const Icon(Icons.open_in_new),
                        label: const Text('Go to LT'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.green.shade700,
                          foregroundColor: Colors.white,
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

class _DetailRow extends StatelessWidget {
  final String label;
  final String value;

  const _DetailRow({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 80,
            child: Text(
              label,
              style: TextStyle(
                color: Colors.grey.shade600,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
          Expanded(
            child: Text(
              value.isEmpty ? '-' : value,
              style: const TextStyle(fontWeight: FontWeight.w500),
            ),
          ),
        ],
      ),
    );
  }
}
