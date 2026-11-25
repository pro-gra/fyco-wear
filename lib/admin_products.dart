import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

class AdminProductsScreen extends StatefulWidget {
  const AdminProductsScreen({super.key});

  @override
  State<AdminProductsScreen> createState() => _AdminProductsScreenState();
}

class _AdminProductsScreenState extends State<AdminProductsScreen> {
  static const _productId = 'sculpt-jumpsuit';
  static const _variants = <String, List<String>>{
    'milk-white': ['S', 'M', 'L'],
    'chocolate': ['S', 'M', 'L'],
    'vibrant-pink': ['S', 'M', 'L'],
  };
  static const _colorNames = {
    'milk-white': 'Blanc Lait',
    'chocolate': 'Chocolat',
    'vibrant-pink': 'Éclatant',
  };

  final _price = TextEditingController();
  final _comparePrice = TextEditingController();
  final Map<String, TextEditingController> _stockControllers = {};
  bool _active = true;
  bool _saving = false;
  bool _loaded = false;
  String? _error;
  bool? _isAdmin;

  DocumentReference<Map<String, dynamic>> get _productRef =>
      FirebaseFirestore.instance.collection('store_products').doc(_productId);

  @override
  void initState() {
    super.initState();
    _checkAdmin();
  }

  Future<void> _checkAdmin() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      if (mounted) setState(() => _isAdmin = false);
      return;
    }
    try {
      final token = await user.getIdTokenResult(true);
      if (mounted) setState(() => _isAdmin = token.claims?['admin'] == true);
    } catch (_) {
      if (mounted) setState(() => _isAdmin = false);
    }
  }

  void _load(Map<String, dynamic> data) {
    if (_loaded) return;
    _price.text = (data['priceMad'] ?? 449).toString();
    _comparePrice.text = (data['originalPriceMad'] ?? 600).toString();
    _active = data['active'] as bool? ?? true;
    final inventory = (data['inventory'] as Map?)?.cast<String, dynamic>() ?? {};
    for (final color in _variants.entries) {
      for (final size in color.value) {
        final key = '${color.key}__$size';
        _stockControllers[key] = TextEditingController(
          text: (inventory[key] ?? 0).toString(),
        );
      }
    }
    _loaded = true;
  }

  @override
  void dispose() {
    _price.dispose();
    _comparePrice.dispose();
    for (final controller in _stockControllers.values) {
      controller.dispose();
    }
    super.dispose();
  }

  Future<void> _save() async {
    final price = int.tryParse(_price.text.trim());
    final compare = int.tryParse(_comparePrice.text.trim());
    if (price == null || price < 0 || compare == null || compare < 0) {
      setState(() => _error = 'Enter valid prices in MAD.');
      return;
    }
    final inventory = <String, int>{};
    for (final entry in _stockControllers.entries) {
      final quantity = int.tryParse(entry.value.text.trim());
      if (quantity == null || quantity < 0) {
        setState(() => _error = 'Every stock quantity must be zero or a positive number.');
        return;
      }
      inventory[entry.key] = quantity;
    }

    setState(() { _saving = true; _error = null; });
    try {
      await _productRef.set({
        'productId': _productId,
        'name': 'FYCO Sculpt Jumpsuit',
        'priceMad': price,
        'originalPriceMad': compare,
        'active': _active,
        'inventory': inventory,
        'updatedAt': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Product settings saved.')),
        );
      }
    } catch (e) {
      if (mounted) setState(() => _error = 'Could not save: $e');
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      return const Scaffold(body: Center(child: Text('Please sign in with your administrator account.')));
    }
    if (_isAdmin == null) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }
    if (_isAdmin != true) {
      return Scaffold(
        appBar: AppBar(title: const Text('Product management')),
        body: const Center(
          child: Padding(
            padding: EdgeInsets.all(28),
            child: Text(
              'This account is not an administrator. Ask the project owner to grant it the Firebase custom claim: admin = true.',
              textAlign: TextAlign.center,
            ),
          ),
        ),
      );
    }

    return Scaffold(
      backgroundColor: const Color(0xFFF9F6F0),
      appBar: AppBar(
        title: const Text('Product & inventory'),
        backgroundColor: Colors.white,
        actions: [
          TextButton.icon(
            onPressed: _saving ? null : _save,
            icon: const Icon(Icons.save_outlined),
            label: const Text('Save changes'),
          ),
          const SizedBox(width: 12),
        ],
      ),
      body: StreamBuilder<DocumentSnapshot<Map<String, dynamic>>>(
        stream: _productRef.snapshots(),
        builder: (context, snapshot) {
          if (snapshot.hasError) return Center(child: Text('Firestore error: ${snapshot.error}'));
          if (!snapshot.hasData) return const Center(child: CircularProgressIndicator());
          _load(snapshot.data!.data() ?? {});
          return ListView(
            padding: const EdgeInsets.all(24),
            children: [
              const Text('FYCO SCULPT JUMPSUIT', style: TextStyle(fontSize: 12, letterSpacing: 2, fontWeight: FontWeight.bold, color: Colors.black54)),
              const SizedBox(height: 8),
              const Text('Product controls', style: TextStyle(fontSize: 28, fontWeight: FontWeight.w700)),
              const SizedBox(height: 6),
              const Text('Changes are saved to Firestore and can be reflected on the storefront without another code deployment.'),
              const SizedBox(height: 24),
              _section(
                title: 'Pricing & visibility',
                child: Column(
                  children: [
                    SwitchListTile(
                      contentPadding: EdgeInsets.zero,
                      title: const Text('Product available on the storefront'),
                      subtitle: const Text('Turn this off to temporarily hide or disable the product.'),
                      value: _active,
                      onChanged: (value) => setState(() => _active = value),
                    ),
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        Expanded(child: TextField(controller: _price, keyboardType: TextInputType.number, decoration: const InputDecoration(labelText: 'Selling price (MAD)', border: OutlineInputBorder()))),
                        const SizedBox(width: 16),
                        Expanded(child: TextField(controller: _comparePrice, keyboardType: TextInputType.number, decoration: const InputDecoration(labelText: 'Original price (MAD)', border: OutlineInputBorder()))),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 18),
              _section(
                title: 'Stock by color and size',
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('Set the exact number of pieces available for each variant. Use 0 to mark a variant as sold out.'),
                    const SizedBox(height: 16),
                    for (final color in _variants.entries) ...[
                      Text(_colorNames[color.key]!, style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 16)),
                      const SizedBox(height: 10),
                      Wrap(
                        spacing: 12,
                        runSpacing: 12,
                        children: [
                          for (final size in color.value)
                            SizedBox(
                              width: 145,
                              child: TextField(
                                controller: _stockControllers['${color.key}__$size'],
                                keyboardType: TextInputType.number,
                                decoration: InputDecoration(
                                  labelText: 'Size $size — pieces',
                                  border: const OutlineInputBorder(),
                                ),
                              ),
                            ),
                        ],
                      ),
                      const Divider(height: 28),
                    ],
                  ],
                ),
              ),
              if (_error != null) ...[
                const SizedBox(height: 12),
                Text(_error!, style: const TextStyle(color: Colors.red)),
              ],
              const SizedBox(height: 20),
              SizedBox(
                height: 52,
                child: ElevatedButton.icon(
                  onPressed: _saving ? null : _save,
                  icon: _saving ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2)) : const Icon(Icons.save),
                  label: Text(_saving ? 'Saving…' : 'SAVE ALL PRODUCT CHANGES'),
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _section({required String title, required Widget child}) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: const Color(0xFFE4DCD3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title, style: const TextStyle(fontSize: 17, fontWeight: FontWeight.w700)),
          const SizedBox(height: 18),
          child,
        ],
      ),
    );
  }
}
