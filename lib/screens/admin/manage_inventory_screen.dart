import 'dart:io';
import 'package:flutter/material.dart';
import '../../models/shop.dart';
import '../../models/item.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:image_picker/image_picker.dart';
import 'package:permission_handler/permission_handler.dart';
import '../../services/supabase_image_upload.dart';
import 'package:device_info_plus/device_info_plus.dart';

class ManageInventoryScreen extends StatefulWidget {
  final List<Shop> shops;
  final Function(Item) onItemAdded;
  final VoidCallback? onRefresh;

  const ManageInventoryScreen({
    required this.shops,
    required this.onItemAdded,
    this.onRefresh,
    super.key,
  });

  @override
  State<ManageInventoryScreen> createState() => _ManageInventoryScreenState();
}

class _ManageInventoryScreenState extends State<ManageInventoryScreen> {
  Shop? selectedShop;
  final _uploader = SupabaseImageUpload();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Manage Inventory", style: TextStyle(color: Colors.white)),
        backgroundColor: Color.fromARGB(255, 7, 12, 156),
        foregroundColor: Colors.white,
      ),
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              Color.fromARGB(255, 7, 12, 156),
              Color.fromARGB(255, 4, 3, 49),
            ],
          ),
        ),
        child: Column(
          children: [
            DropdownButton<Shop>(
              hint: const Text("Select a Shop", style: TextStyle(color: Colors.white)),
              value: selectedShop,
              dropdownColor: const Color.fromARGB(255, 37, 0, 157),
              style: const TextStyle(color: Colors.white),
              items: widget.shops.map((shop) {
                return DropdownMenuItem(
                  value: shop,
                  child: Text(shop.name, style: const TextStyle(color: Colors.white)),
                );
              }).toList(),
              onChanged: (val) => setState(() => selectedShop = val),
            ),
            const Divider(color: Colors.white),
            if (selectedShop != null)
              Expanded(
                child: StreamBuilder<QuerySnapshot>(
                  stream: FirebaseFirestore.instance
                      .collection('shops')
                      .doc(selectedShop!.id)
                      .collection('items')
                      .snapshots(),
                  builder: (ctx, snapshot) {
                    if (!snapshot.hasData) return const Center(child: CircularProgressIndicator());
                    final itemDocs = snapshot.data!.docs;
                    if (itemDocs.isEmpty) return const Center(child: Text("No items yet.", style: TextStyle(color: Colors.white)));
                    return ListView.builder(
                      itemCount: itemDocs.length,
                      itemBuilder: (ctx, i) {
                        final item = Item.fromMap(itemDocs[i].data() as Map<String, dynamic>);
                        return Card(
                          color: const Color.fromARGB(255, 4, 3, 49),
                          child: ListTile(
                            leading: item.imageUrl.isNotEmpty
                                ? Image.network(item.imageUrl, width: 50, height: 50, fit: BoxFit.cover, errorBuilder: (_, __, ___) => const Icon(Icons.image_not_supported, color: Colors.black))
                                : const Icon(Icons.image, color: Colors.white),
                            title: Text(item.name, style: const TextStyle(color: Colors.amber)),
                            subtitle: Text("Stock: ${item.stock} | \$${item.price} | ${item.category}", style: const TextStyle(color: Colors.white)),
                            trailing: IconButton(icon: const Icon(Icons.edit, color: Colors.white), onPressed: () => _showEditItemDialog(context, item)),
                          ),
                        );
                      },
                    );
                  },
                ),
              )
            else
              const Padding(padding: EdgeInsets.all(20), child: Text("Please select a shop to manage inventory.", style: TextStyle(color: Colors.white))),
          ],
        ),
      ),
      floatingActionButton: selectedShop == null ? null : FloatingActionButton(
        backgroundColor: Colors.amber,
        foregroundColor: const Color.fromARGB(255, 37, 0, 157),
        child: const Icon(Icons.add),
        onPressed: () => _showAddItemDialog(context, selectedShop!),
      ),
    );
  }

  Future<bool> requestImagePermission() async {
  if (Platform.isIOS) {
    final status = await Permission.photos.request();
    return status.isGranted;
  }

  if (Platform.isAndroid) {
    final deviceInfo = DeviceInfoPlugin();
    final androidInfo = await deviceInfo.androidInfo;
    final sdk = androidInfo.version.sdkInt;

    // Android 13+ → USE READ_MEDIA_IMAGES
    if (sdk >= 33) {
      final status = await Permission.photos.request();
      return status.isGranted;
    }

    // Android 12 and below → STORAGE permission
    final status = await Permission.storage.request();
    return status.isGranted;
  }

  return false;
  }

  void _showAddItemDialog(BuildContext context, Shop shop) {
    final nameController = TextEditingController();
    final priceController = TextEditingController();
    final stockController = TextEditingController();
    String category = 'goods';
    File? selectedImage;

    showDialog(
      context: context,
      builder: (context) {
        return StatefulBuilder(builder: (context, setStateDialog) {
          return AlertDialog(
            title: const Text("Add Item"),
            content: SingleChildScrollView(
              child: Column(mainAxisSize: MainAxisSize.min, children: [
                TextField(controller: nameController, decoration: const InputDecoration(labelText: "Item Name")),
                TextField(controller: priceController, keyboardType: TextInputType.number, decoration: const InputDecoration(labelText: "Price")),
                TextField(controller: stockController, keyboardType: TextInputType.number, decoration: const InputDecoration(labelText: "Stock")),
                const SizedBox(height: 10),
                Row(children: [
                  const Text("Category: ", style: TextStyle(color: Colors.black)),
                  const SizedBox(width: 8),
                  DropdownButton<String>(
                    value: category,
                    dropdownColor: Colors.white,
                    items: const [
                      DropdownMenuItem(value: 'goods', child: Text('Goods', style: TextStyle(color: Colors.black))),
                      DropdownMenuItem(value: 'services', child: Text('Services', style: TextStyle(color: Colors.black))),
                    ],
                    onChanged: (v) => setStateDialog(() => category = v ?? 'goods'),
                  ),
                ]),
                const SizedBox(height: 10),
                ElevatedButton(
                  onPressed: () async {
                    final allowed = await requestImagePermission();
                        if (!allowed) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(content: Text('Permission denied. Cannot access gallery.')),
                          );
                          return;
                    }
                    final picker = ImagePicker();
                    final picked = await picker.pickImage(source: ImageSource.gallery);
                    if (picked != null) setStateDialog(() => selectedImage = File(picked.path));
                  },
                  child: const Text("Select Image"),
                ),
                if (selectedImage != null) Padding(padding: const EdgeInsets.only(top: 8.0), child: Text("Selected: ${selectedImage!.path.split('/').last}", style: const TextStyle(fontSize: 12))),
              ]),
            ),
            actions: [
              TextButton(onPressed: () => Navigator.pop(context), child: const Text("Cancel")),
              ElevatedButton(
                onPressed: () async {
                  if (nameController.text.isEmpty || double.tryParse(priceController.text) == null || int.tryParse(stockController.text) == null) return;

                  String imageUrl = '';
                  if (selectedImage != null) {
                    final url = await _uploader.uploadImage(selectedImage!, 'item_images', bucketName: 'items');
                    if (url == null) {
                      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Item image upload failed.')));
                      return;
                    }
                    imageUrl = url;
                  }

                  final newId = FirebaseFirestore.instance.collection('shops').doc().id;
                  final newItem = Item(id: newId, name: nameController.text, imageUrl: imageUrl, price: double.parse(priceController.text), stock: int.parse(stockController.text), category: category, shopId: shop.id);

                  try {
                    await FirebaseFirestore.instance.collection('shops').doc(shop.id).collection('items').doc(newItem.id).set(newItem.toMap());
                    widget.onItemAdded(newItem);
                    widget.onRefresh?.call();
                    Navigator.pop(context);
                  } catch (e) {
                    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Failed to save item: $e')));
                  }
                },
                child: const Text("Add"),
              ),
            ],
          );
        });
      },
    );
  }

  void _showEditItemDialog(BuildContext context, Item item) {
    final nameController = TextEditingController(text: item.name);
    final priceController = TextEditingController(text: item.price.toString());
    final stockController = TextEditingController(text: item.stock.toString());
    String category = item.category;
    File? selectedImage;

    showDialog(
      context: context,
      builder: (context) {
        return StatefulBuilder(builder: (context, setStateDialog) {
          return AlertDialog(
            title: Text("Edit ${item.name}"),
            content: SingleChildScrollView(
              child: Column(mainAxisSize: MainAxisSize.min, children: [
                TextField(controller: nameController, decoration: const InputDecoration(labelText: "Item Name")),
                TextField(controller: priceController, keyboardType: TextInputType.number, decoration: const InputDecoration(labelText: "Price")),
                TextField(controller: stockController, keyboardType: TextInputType.number, decoration: const InputDecoration(labelText: "Stock")),
                const SizedBox(height: 10),
                Row(children: [
                  const Text("Category: ", style: TextStyle(color: Colors.black)),
                  const SizedBox(width: 8),
                  DropdownButton<String>(
                    value: category,
                    dropdownColor: Colors.white,
                    items: const [
                      DropdownMenuItem(value: 'goods', child: Text('Goods', style: TextStyle(color: Colors.black))),
                      DropdownMenuItem(value: 'services', child: Text('Services', style: TextStyle(color: Colors.black))),
                    ],
                    onChanged: (v) => setStateDialog(() => category = v ?? 'goods'),
                  ),
                ]),
                const SizedBox(height: 10),
                ElevatedButton(
                  onPressed: () async {
                    var status = await Permission.photos.request();
                    if (!status.isGranted) {
                      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Photo permission denied.')));
                      return;
                    }
                    final picker = ImagePicker();
                    final picked = await picker.pickImage(source: ImageSource.gallery);
                    if (picked != null) setStateDialog(() => selectedImage = File(picked.path));
                  },
                  child: const Text("Change Image"),
                ),
                if (selectedImage != null) Padding(padding: const EdgeInsets.only(top: 8.0), child: Text("Selected: ${selectedImage!.path.split('/').last}", style: const TextStyle(fontSize: 12))),
              ]),
            ),
            actions: [
              TextButton(onPressed: () => Navigator.pop(context), child: const Text("Cancel")),
              ElevatedButton(
                onPressed: () async {
                  if (nameController.text.isEmpty || double.tryParse(priceController.text) == null || int.tryParse(stockController.text) == null) return;

                  String imageUrl = item.imageUrl;
                  if (selectedImage != null) {
                    final url = await _uploader.uploadImage(selectedImage!, 'item_images', bucketName: 'items');
                    if (url == null) {
                      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Item image upload failed.')));
                      return;
                    }
                    imageUrl = url;
                  }

                  final updated = item.copyWith(
                    name: nameController.text,
                    price: double.parse(priceController.text),
                    stock: int.parse(stockController.text),
                    category: category,
                    imageUrl: imageUrl,
                  );

                  try {
                    await FirebaseFirestore.instance.collection('shops').doc(selectedShop!.id).collection('items').doc(item.id).update(updated.toMap());
                    widget.onRefresh?.call();
                    Navigator.pop(context);
                  } catch (e) {
                    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Failed to update item: $e')));
                  }
                },
                child: const Text("Save"),
              ),
            ],
          );
        });
      },
    );
  }
}
