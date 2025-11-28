import 'dart:io';
import 'package:flutter/material.dart';
import '../../models/shop.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:image_picker/image_picker.dart';
import 'package:permission_handler/permission_handler.dart';
import '../../services/supabase_image_upload.dart';
import 'package:device_info_plus/device_info_plus.dart';

class ManageShopsScreen extends StatefulWidget {
  final List<Shop> shops;
  final Function(Shop) onShopAdded;
  final VoidCallback? onRefresh;

  const ManageShopsScreen({required this.shops, required this.onShopAdded, this.onRefresh, super.key});

  @override
  State<ManageShopsScreen> createState() => _ManageShopsScreenState();
}

class _ManageShopsScreenState extends State<ManageShopsScreen> {
  final _uploader = SupabaseImageUpload();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Manage Shops", style: TextStyle(color: Colors.white)),
        backgroundColor: Color.fromARGB(255, 7, 12, 156),
        foregroundColor: Colors.amber,
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
        child: ListView.builder(
          itemCount: widget.shops.length,
          itemBuilder: (ctx, i) {
            final shop = widget.shops[i];
            return Card(
              color: const Color.fromARGB(255, 4, 3, 49),
              child: ListTile(
                title: Text(shop.name, style: const TextStyle(color: Colors.amber)),
                subtitle: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(shop.description, style: const TextStyle(color: Colors.white)),
                    Text('Rating: ${shop.rating.toStringAsFixed(1)} ⭐', style: const TextStyle(color: Colors.yellow, fontSize: 12)),
                  ],
                ),
                trailing: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    IconButton(
                      icon: const Icon(Icons.star, color: Colors.yellow),
                      onPressed: () => _showEditRatingDialog(shop),
                    ),
                    Switch(
                      value: shop.active,
                      onChanged: (val) async {
                        setState(() => shop.active = val);
                        await FirebaseFirestore.instance.collection('shops').doc(shop.id).update({'active': val});
                      },
                      activeColor: Colors.amber,
                      inactiveThumbColor: Colors.grey,
                    ),
                    IconButton(
                    icon: const Icon(Icons.person_add, color: Colors.amber),
                    onPressed: () => _showAssignOwnerDialog(shop),
                  ),
                    IconButton(
                      icon: const Icon(Icons.delete, color: Colors.red),
                      onPressed: () => _deleteShop(shop),
                    ),
                  ],
                ),
              ),
            );
          },
        ),
      ),
      floatingActionButton: FloatingActionButton(
        backgroundColor: Colors.amber,
        foregroundColor: const Color.fromARGB(255, 37, 0, 157),
        child: const Icon(Icons.add),
        onPressed: () => _showAddShopDialog(context),
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

    if (sdk >= 33) {
      final status = await Permission.photos.request();
      return status.isGranted;
    }

    final status = await Permission.storage.request();
    return status.isGranted;
  }

  return false;
  }

    void _showAssignOwnerDialog(Shop shop) async {
    List<Map<String, dynamic>> users = [];

    // Fetch users from Firestore
    final snap = await FirebaseFirestore.instance.collection('users').get();
    users = snap.docs.map((d) => d.data()).toList();

    String? selectedUserId;

    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Text('Assign Owner for ${shop.name}'),
          content: SizedBox(
          width: double.maxFinite,
          child: DropdownButtonFormField<String>(
            value: selectedUserId,
            items: users.map((user) {
              return DropdownMenuItem<String>(
                value: user['id'] as String,
                child: Text(
                  "${user['username']} (${user['email']})",  
                  overflow: TextOverflow.ellipsis
                ),
              );
            }).toList(),
            onChanged: (val) {
              setState(() {});
              selectedUserId = val;
            },
            decoration: const InputDecoration(labelText: "Select User"),
          ),
        ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text("Cancel"),
            ),
            ElevatedButton(
              onPressed: () async {
                if (selectedUserId == null) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Please select a user')),
                  );
                  return;
                }

                await _assignShopOwner(shop, selectedUserId!);
                Navigator.pop(context);

                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text('Owner assigned to ${shop.name}')),
                );

                widget.onRefresh?.call();
                setState(() {});
              },
              child: const Text("Assign"),
            )
          ],
        );
      },
    );
  }

  Future<void> _assignShopOwner(Shop shop, String newOwnerId) async {
    final firestore = FirebaseFirestore.instance;

    // 1. Find existing owner (reverse lookup)
    final previousOwnerSnap = await firestore
        .collection("users")
        .where("assignedShopId", isEqualTo: shop.id)
        .limit(1)
        .get();

    if (previousOwnerSnap.docs.isNotEmpty) {
      // Unassign old owner
      await firestore.collection("users").doc(previousOwnerSnap.docs.first.id)
          .update({'assignedShopId': null});
    }

    // 2. Get new owner data
    final newOwnerSnap = await firestore.collection("users").doc(newOwnerId).get();
    final newOwnerData = newOwnerSnap.data();
    final ownerUsername = newOwnerData?['username'] ?? 'Unknown';

    // 3. Assign new owner to shop
    await firestore.collection("shops").doc(shop.id).update({
      'ownerId': newOwnerId,
      'ownerUsername': ownerUsername,
    });

    // 4. Assign shop to user
    await firestore.collection("users").doc(newOwnerId).update({
      'assignedShopId': shop.id,
      'role': 'owner', // optional
    });

    // 5. Update local shop object
    shop.ownerId = newOwnerId;
    shop.ownerUsername = ownerUsername;
  }


    Future<void> _deleteShop(Shop shop) async {
      final confirm = await showDialog<bool>(
        context: context,
        builder: (context) => AlertDialog(
          title: const Text('Delete Shop'),
          content: Text('Are you sure you want to delete "${shop.name}"? This cannot be undone.'),
          actions: [
            TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Cancel')),
            ElevatedButton(onPressed: () => Navigator.pop(context, true), style: ElevatedButton.styleFrom(backgroundColor: Colors.red), child: const Text('Delete')),
          ],
        ),
      );

      if (confirm == true) {
        try {
          await FirebaseFirestore.instance.collection('shops').doc(shop.id).delete();
          setState(() => widget.shops.remove(shop));
          widget.onRefresh?.call();
          ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Shop "${shop.name}" deleted.')));
        } catch (e) {
          ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Failed to delete shop: $e')));
        }
      }
    }

  void _showEditRatingDialog(Shop shop) {
    final ratingController = TextEditingController(text: shop.rating.toStringAsFixed(1));

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Edit Rating for ${shop.name}'),
        content: TextField(
          controller: ratingController,
          keyboardType: TextInputType.number,
          decoration: const InputDecoration(labelText: 'Rating (0.0 - 5.0)'),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
          ElevatedButton(
            onPressed: () async {
              final newRating = double.tryParse(ratingController.text);
              if (newRating == null || newRating < 0 || newRating > 5) {
                ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Invalid rating. Must be between 0.0 and 5.0')));
                return;
              }

              try {
                await FirebaseFirestore.instance.collection('shops').doc(shop.id).update({'rating': newRating});
                setState(() => shop.rating = newRating);
                widget.onRefresh?.call();
                Navigator.pop(context);
                ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Rating updated for ${shop.name}')));
              } catch (e) {
                ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Failed to update rating: $e')));
              }
            },
            child: const Text('Save'),
          ),
        ],
      ),
    );
  }

  void _showAddShopDialog(BuildContext context) {
    final nameController = TextEditingController();
    final descController = TextEditingController();
    File? selectedImage;

    showDialog(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setStateDialog) {
            return AlertDialog(
              title: const Text("Add New Shop"),
              content: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    TextField(controller: nameController, decoration: const InputDecoration(labelText: "Shop Name")),
                    TextField(controller: descController, decoration: const InputDecoration(labelText: "Description")),
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
                      child: const Text("Select Banner Image"),
                    ),
                    if (selectedImage != null) Padding(
                      padding: const EdgeInsets.only(top: 8.0),
                      child: Text("Selected: ${selectedImage!.path.split('/').last}", style: const TextStyle(fontSize: 12)),
                    ),
                  ],
                ),
              ),
              actions: [
                TextButton(onPressed: () => Navigator.pop(context), child: const Text("Cancel")),
                ElevatedButton(
                  onPressed: () async {
                    if (nameController.text.isEmpty) return;

                    String bannerUrl = '';
                    if (selectedImage != null) {
                      final url = await _uploader.uploadImage(selectedImage!, 'shop_banners', bucketName: 'shops');
                      if (url == null) {
                        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Banner upload failed.')));
                        return;
                      }
                      bannerUrl = url;
                    }

                    try {
                      final doc = FirebaseFirestore.instance.collection('shops').doc();
                      final newShop = Shop(
                      id: doc.id,
                      name: nameController.text,
                      description: descController.text,
                      bannerUrl: bannerUrl,
                      active: true,
                      items: [],
                    );

                      await doc.set(newShop.toMap());
                      widget.onShopAdded(newShop);
                      widget.onRefresh?.call();
                      Navigator.pop(context);
                    } catch (e) {
                      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Failed to save shop: $e')));
                    }
                  },
                  child: const Text("Add"),
                ),
              ],
            );
          },
        );
      },
    );
  }
}
