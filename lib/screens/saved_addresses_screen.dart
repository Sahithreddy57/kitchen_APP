

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../core/app_core.dart';
import '../providers/auth_provider.dart';
import '../widgets/checkout_widgets.dart';
import 'add_address_screen.dart';

class SavedAddressesScreen extends StatefulWidget {
  const SavedAddressesScreen({super.key});

  @override
  State<SavedAddressesScreen> createState() =>
      _SavedAddressesScreenState();
}

class _SavedAddressesScreenState
    extends State<SavedAddressesScreen> {
  bool _loading = false;
  final Set<int> _deleting = {};

  @override
  void initState() {
    super.initState();

    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadAddresses();
    });
  }

  Future<void> _loadAddresses() async {
    final auth = context.read<AuthProvider>();

    if (!auth.isLoggedIn) return;

    setState(() => _loading = true);

    try {
      await auth.refreshAddressesFromBackend();
    } catch (e) {
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Could not load addresses: $e'),
        ),
      );
    } finally {
      if (mounted) {
        setState(() => _loading = false);
      }
    }
  }

  Future<void> _deleteAddress(int index) async {
    if (_deleting.contains(index)) return;

    setState(() => _deleting.add(index));

    try {
      await context.read<AuthProvider>().removeAddress(index);

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Address deleted')),
      );
    } catch (e) {
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Could not delete address: $e'),
        ),
      );
    } finally {
      if (mounted) {
        setState(() => _deleting.remove(index));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();

    const labelKeys = {
      'home': 'addrHome',
      'work': 'addrWork',
      'other': 'other',
    };

    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(12, 16, 20, 8),
              child: Row(
                children: [
                  IconButton(
                    onPressed: () => Navigator.pop(context),
                    icon: const Icon(
                      Icons.chevron_left,
                      size: 30,
                      color: kNavy,
                    ),
                  ),
                  Expanded(
                    child: Text(
                      context.tr('savedAddresses'),
                      style: const TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.w800,
                        color: kNavy,
                      ),
                    ),
                  ),
                  IconButton(
                    tooltip: 'Refresh addresses',
                    onPressed: _loading ? null : _loadAddresses,
                    icon: const Icon(Icons.refresh),
                  ),
                ],
              ),
            ),
            if (_loading)
              const LinearProgressIndicator(minHeight: 2),
            Expanded(
              child: ListView(
                padding:
                    const EdgeInsets.fromLTRB(20, 12, 20, 24),
                children: [
                  if (auth.addresses.isEmpty && !_loading)
                    Padding(
                      padding:
                          const EdgeInsets.symmetric(vertical: 24),
                      child: Center(
                        child: Text(
                          context.tr('noAddresses'),
                          style: const TextStyle(
                            color: AppColors.textMuted,
                          ),
                        ),
                      ),
                    ),
                  for (int i = 0; i < auth.addresses.length; i++)
                    Container(
                      margin: const EdgeInsets.only(bottom: 12),
                      padding:
                          const EdgeInsets.fromLTRB(16, 14, 6, 14),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(
                          color: const Color(0xFFEFE8DC),
                        ),
                      ),
                      child: Row(
                        children: [
                          Expanded(
                            child: Column(
                              crossAxisAlignment:
                                  CrossAxisAlignment.start,
                              children: [
                                Row(
                                  children: [
                                    Flexible(
                                      child: Text(
                                        context.tr(
                                          labelKeys[
                                                  auth.addresses[i]
                                                      .label
                                                      .toLowerCase()] ??
                                              'other',
                                        ),
                                        style: const TextStyle(
                                          fontSize: 16,
                                          fontWeight: FontWeight.w700,
                                          color: kNavy,
                                        ),
                                      ),
                                    ),
                                    if (auth.addresses[i].isDefault) ...[
                                      const SizedBox(width: 8),
                                      const Icon(
                                        Icons.check_circle,
                                        size: 16,
                                        color: Colors.green,
                                      ),
                                    ],
                                  ],
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  auth.addresses[i].line,
                                  style: const TextStyle(
                                    fontSize: 13.5,
                                    color: Color(0xFF55606B),
                                  ),
                                ),
                              ],
                            ),
                          ),
                          IconButton(
                            tooltip: context.tr('edit'),
                            onPressed: () async {
                              await Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (_) => AddAddressScreen(
                                    existing: auth.addresses[i],
                                    index: i,
                                  ),
                                ),
                              );
                            },
                            icon: const Icon(
                              Icons.edit_outlined,
                              color: AppColors.textMuted,
                            ),
                          ),
                          IconButton(
                            onPressed: _deleting.contains(i)
                                ? null
                                : () => _deleteAddress(i),
                            icon: _deleting.contains(i)
                                ? const SizedBox(
                                    width: 18,
                                    height: 18,
                                    child: CircularProgressIndicator(
                                      strokeWidth: 2,
                                    ),
                                  )
                                : const Icon(
                                    Icons.delete_outline,
                                    color: AppColors.textMuted,
                                  ),
                          ),
                        ],
                      ),
                    ),
                  DashedButton(
                    label: context.tr('addAddress'),
                    onTap: () async {
                      await Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => const AddAddressScreen(),
                        ),
                      );
                    },
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
