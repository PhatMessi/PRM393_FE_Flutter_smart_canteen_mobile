import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../models/menu_item.dart';
import '../providers/auth_provider.dart';
import '../services/menu_service.dart';
import '../services/manager_menu_service.dart';
import '../services/menu_item_customization_service.dart';
import '../models/menu_item_customization.dart';
import '../utils/money.dart';

class _EditableOption {
  String name;
  double priceDelta;
  bool isAvailable;

  _EditableOption({
    required this.name,
    required this.priceDelta,
    this.isAvailable = true,
  });
}

class _EditableGroup {
  String key;
  String title;
  bool isRequired;
  bool isMultiple;
  int? maxSelections;
  final List<_EditableOption> options;

  _EditableGroup({
    required this.key,
    required this.title,
    required this.isRequired,
    required this.isMultiple,
    required this.maxSelections,
    required this.options,
  });
}

class ManagerMenuManagementScreen extends StatefulWidget {
  const ManagerMenuManagementScreen({super.key});

  @override
  State<ManagerMenuManagementScreen> createState() => _ManagerMenuManagementScreenState();
}

class _ManagerMenuManagementScreenState extends State<ManagerMenuManagementScreen> {
  final MenuService _menuService = MenuService();
  final ManagerMenuService _managerService = ManagerMenuService();
  final MenuItemCustomizationService _customizationService = MenuItemCustomizationService();

  bool _loading = true;
  List<MenuItem> _items = [];
  List<Category> _categories = [];

  MenuItem? _selected;

  final _nameCtrl = TextEditingController();
  final _descCtrl = TextEditingController();
  final _priceCtrl = TextEditingController();
  final _qtyCtrl = TextEditingController();

  int? _categoryId;
  bool _isAvailable = true;

  List<_EditableGroup> _groups = [];

  @override
  void initState() {
    super.initState();
    _load();
  }

  @override
  void dispose() {
    _nameCtrl.dispose();
    _descCtrl.dispose();
    _priceCtrl.dispose();
    _qtyCtrl.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    setState(() => _loading = true);
    final categories = await _menuService.getCategories();
    final items = await _menuService.getMenuItems();
    if (!mounted) return;

    setState(() {
      _categories = categories;
      _items = items;
      _loading = false;
    });

    if (_selected != null) {
      final refreshed = items.where((e) => e.itemId == _selected!.itemId).toList();
      if (refreshed.isNotEmpty) {
        _selectItem(refreshed.first);
      }
    }
  }

  void _clearEditor() {
    setState(() {
      _selected = null;
      _nameCtrl.text = '';
      _descCtrl.text = '';
      _priceCtrl.text = '';
      _qtyCtrl.text = '';
      _categoryId = null;
      _isAvailable = true;
      _groups = [];
    });
  }

  Future<void> _selectItem(MenuItem item) async {
    setState(() {
      _selected = item;
      _nameCtrl.text = item.name;
      _descCtrl.text = item.description ?? '';
      _priceCtrl.text = item.price.toStringAsFixed(0);
      _qtyCtrl.text = item.inventoryQuantity.toString();
      _categoryId = item.categoryId;
      _isAvailable = item.isAvailable;
      _groups = [];
    });

    final customization = await _customizationService.getCustomizations(item.itemId);
    if (!mounted) return;

    setState(() {
      _groups = _editableGroupsFrom(customization);
    });
  }

  List<_EditableGroup> _editableGroupsFrom(MenuItemCustomization? customization) {
    if (customization == null) return [];

    final groups = [...customization.optionGroups];
    groups.sort((a, b) {
      final byOrder = a.sortOrder.compareTo(b.sortOrder);
      if (byOrder != 0) return byOrder;
      return a.optionGroupId.compareTo(b.optionGroupId);
    });

    return groups
        .map(
          (g) => _EditableGroup(
            key: g.key,
            title: g.title,
            isRequired: g.isRequired,
            isMultiple: g.isMultiple,
            maxSelections: g.maxSelections,
            options: g.options
                .map(
                  (o) => _EditableOption(
                    name: o.name,
                    priceDelta: o.priceDelta,
                    isAvailable: o.isAvailable,
                  ),
                )
                .toList(),
          ),
        )
        .toList();
  }

  Map<String, dynamic> _toUpsertPayload() {
    final payloadGroups = <Map<String, dynamic>>[];
    for (var i = 0; i < _groups.length; i++) {
      final g = _groups[i];
      payloadGroups.add({
        'key': g.key.trim(),
        'title': g.title.trim(),
        'isRequired': g.isRequired,
        'isMultiple': g.isMultiple,
        'maxSelections': g.maxSelections,
        'sortOrder': i + 1,
        'options': [
          for (var j = 0; j < g.options.length; j++)
            {
              'name': g.options[j].name.trim(),
              'priceDelta': g.options[j].priceDelta,
              'isAvailable': g.options[j].isAvailable,
              'sortOrder': j + 1,
            },
        ],
      });
    }

    return {'optionGroups': payloadGroups};
  }

  void _toast(String message, {bool error = false}) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: error ? Colors.redAccent : Colors.green,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  Future<void> _save() async {
    final auth = context.read<AuthProvider>();
    final token = auth.user?.token;
    if (token == null || token.isEmpty) {
      _toast('Chua dang nhap', error: true);
      return;
    }

    final name = _nameCtrl.text.trim();
    final desc = _descCtrl.text.trim();
    final price = double.tryParse(_priceCtrl.text.trim());
    final qty = int.tryParse(_qtyCtrl.text.trim());

    if (name.isEmpty || price == null || qty == null || _categoryId == null) {
      _toast('Vui long nhap du thong tin bat buoc', error: true);
      return;
    }

    setState(() => _loading = true);

    try {
      if (_selected == null) {
        final created = await _managerService.createMenuItem(
          token: token,
          name: name,
          description: desc,
          price: price,
          inventoryQuantity: qty,
          categoryId: _categoryId!,
        );

        if (created == null) {
          _toast('Tao mon that bai', error: true);
          setState(() => _loading = false);
          return;
        }

        final ok = await _managerService.replaceCustomizations(
          token: token,
          itemId: created.itemId,
          payload: _toUpsertPayload(),
        );

        await _load();
        if (!mounted) return;
        _toast(ok ? 'Da tao mon + cap nhat tuy chon' : 'Da tao mon (chua cap nhat tuy chon)');
        _selectItem(created);
        return;
      }

      final updated = await _managerService.updateMenuItem(
        token: token,
        itemId: _selected!.itemId,
        name: name,
        description: desc,
        price: price,
        inventoryQuantity: qty,
        categoryId: _categoryId!,
        isAvailable: _isAvailable,
      );

      final ok = await _managerService.replaceCustomizations(
        token: token,
        itemId: _selected!.itemId,
        payload: _toUpsertPayload(),
      );

      await _load();
      if (!mounted) return;
      _toast(updated && ok ? 'Da cap nhat mon + tuy chon' : 'Cap nhat chua thanh cong');
    } catch (_) {
      if (!mounted) return;
      _toast('Co loi xay ra khi luu', error: true);
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _deleteSelected() async {
    final selected = _selected;
    if (selected == null) return;

    final auth = context.read<AuthProvider>();
    final token = auth.user?.token;
    if (token == null || token.isEmpty) {
      _toast('Chua dang nhap', error: true);
      return;
    }

    setState(() => _loading = true);
    try {
      final ok = await _managerService.deleteMenuItem(token: token, itemId: selected.itemId);
      await _load();
      if (!mounted) return;
      if (ok) {
        _toast('Da xoa mon');
        _clearEditor();
      } else {
        _toast('Xoa mon that bai', error: true);
      }
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Widget _buildList() {
    if (_loading) {
      return const Center(child: CircularProgressIndicator());
    }

    return RefreshIndicator(
      onRefresh: _load,
      child: ListView.separated(
        physics: const AlwaysScrollableScrollPhysics(),
        itemCount: _items.length,
        separatorBuilder: (context, index) => const Divider(height: 1),
        itemBuilder: (context, index) {
          final item = _items[index];
          final selected = _selected?.itemId == item.itemId;

          return ListTile(
            selected: selected,
            title: Text(item.name),
            subtitle: Text(
              'Gia: ${Money.vnd(item.price)}  •  SL: ${item.inventoryQuantity}  •  ${item.isAvailable ? 'Dang ban' : 'Tam dung'}',
            ),
            trailing: const Icon(Icons.edit_outlined),
            onTap: () => _selectItem(item),
          );
        },
      ),
    );
  }

  Widget _buildEditor() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  _selected == null ? 'Them mon moi' : 'Chinh sua mon (ID: ${_selected!.itemId})',
                  style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                ),
              ),
              TextButton.icon(
                onPressed: _clearEditor,
                icon: const Icon(Icons.add),
                label: const Text('Mon moi'),
              ),
            ],
          ),
          const SizedBox(height: 12),
          TextField(
            controller: _nameCtrl,
            decoration: const InputDecoration(labelText: 'Ten mon *'),
          ),
          const SizedBox(height: 10),
          TextField(
            controller: _descCtrl,
            decoration: const InputDecoration(labelText: 'Mo ta'),
            maxLines: 2,
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              Expanded(
                child: TextField(
                  controller: _priceCtrl,
                  keyboardType: TextInputType.number,
                  decoration: const InputDecoration(labelText: 'Gia *'),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: TextField(
                  controller: _qtyCtrl,
                  keyboardType: TextInputType.number,
                  decoration: const InputDecoration(labelText: 'So luong *'),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          DropdownButtonFormField<int>(
            initialValue: _categoryId,
            items: _categories
                .map(
                  (c) => DropdownMenuItem<int>(
                    value: c.categoryId,
                    child: Text('${c.name} (#${c.categoryId})'),
                  ),
                )
                .toList(),
            onChanged: (v) => setState(() => _categoryId = v),
            decoration: const InputDecoration(labelText: 'Category *'),
          ),
          const SizedBox(height: 10),
          SwitchListTile(
            contentPadding: EdgeInsets.zero,
            title: const Text('Dang ban'),
            value: _isAvailable,
            onChanged: (v) => setState(() => _isAvailable = v),
          ),
          const SizedBox(height: 12),
          const Text('Tuy chon cho mon', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
          const SizedBox(height: 8),
          ..._groups.asMap().entries.map((entry) {
            final idx = entry.key;
            final g = entry.value;

            return Card(
              margin: const EdgeInsets.only(bottom: 12),
              child: Padding(
                padding: const EdgeInsets.all(12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: TextFormField(
                            initialValue: g.title,
                            decoration: const InputDecoration(labelText: 'Tieu de'),
                            onChanged: (v) => g.title = v,
                          ),
                        ),
                        const SizedBox(width: 10),
                        IconButton(
                          onPressed: () => setState(() => _groups.removeAt(idx)),
                          icon: const Icon(Icons.delete_outline),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        Expanded(
                          child: TextFormField(
                            initialValue: g.key,
                            decoration: const InputDecoration(labelText: 'Key'),
                            onChanged: (v) => g.key = v,
                          ),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: SwitchListTile(
                            contentPadding: EdgeInsets.zero,
                            title: const Text('Bat buoc'),
                            value: g.isRequired,
                            onChanged: (v) => setState(() => g.isRequired = v),
                          ),
                        ),
                      ],
                    ),
                    SwitchListTile(
                      contentPadding: EdgeInsets.zero,
                      title: const Text('Chon nhieu (extras)'),
                      value: g.isMultiple,
                      onChanged: (v) => setState(() => g.isMultiple = v),
                    ),
                    const SizedBox(height: 6),
                    const Text('Lua chon'),
                    const SizedBox(height: 6),
                    ...g.options.asMap().entries.map((optEntry) {
                      final j = optEntry.key;
                      final o = optEntry.value;

                      return Padding(
                        padding: const EdgeInsets.only(bottom: 8),
                        child: Row(
                          children: [
                            Expanded(
                              child: TextFormField(
                                initialValue: o.name,
                                decoration: const InputDecoration(labelText: 'Ten'),
                                onChanged: (v) => o.name = v,
                              ),
                            ),
                            if (g.isMultiple) ...[
                              const SizedBox(width: 10),
                              SizedBox(
                                width: 120,
                                child: TextFormField(
                                  initialValue: o.priceDelta.toStringAsFixed(0),
                                  keyboardType: TextInputType.number,
                                  decoration: const InputDecoration(labelText: 'Gia +'),
                                  onChanged: (v) => o.priceDelta = double.tryParse(v) ?? 0,
                                ),
                              ),
                            ],
                            const SizedBox(width: 6),
                            IconButton(
                              onPressed: () => setState(() => g.options.removeAt(j)),
                              icon: const Icon(Icons.remove_circle_outline),
                            ),
                          ],
                        ),
                      );
                    }),
                    Align(
                      alignment: Alignment.centerLeft,
                      child: TextButton.icon(
                        onPressed: () {
                          setState(() {
                            g.options.add(_EditableOption(name: '', priceDelta: 0));
                          });
                        },
                        icon: const Icon(Icons.add),
                        label: const Text('Them lua chon'),
                      ),
                    ),
                  ],
                ),
              ),
            );
          }),
          Align(
            alignment: Alignment.centerLeft,
            child: TextButton.icon(
              onPressed: () {
                setState(() {
                  _groups.add(
                    _EditableGroup(
                      key: '',
                      title: '',
                      isRequired: false,
                      isMultiple: false,
                      maxSelections: null,
                      options: [_EditableOption(name: '', priceDelta: 0)],
                    ),
                  );
                });
              },
              icon: const Icon(Icons.add),
              label: const Text('Them nhom tuy chon'),
            ),
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: ElevatedButton(
                  onPressed: _loading ? null : _save,
                  child: const Text('Luu'),
                ),
              ),
              const SizedBox(width: 12),
              if (_selected != null)
                Expanded(
                  child: OutlinedButton(
                    onPressed: _loading ? null : _deleteSelected,
                    child: const Text('Xoa'),
                  ),
                ),
            ],
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF9FAFB),
      appBar: AppBar(
        title: const Text('Quan ly mon an'),
        centerTitle: true,
        actions: [
          IconButton(
            onPressed: _load,
            icon: const Icon(Icons.refresh),
          ),
        ],
      ),
      body: Column(
        children: [
          Expanded(child: _buildList()),
          const Divider(height: 1),
          Expanded(child: _buildEditor()),
        ],
      ),
    );
  }
}
