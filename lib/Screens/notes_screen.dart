import 'dart:io';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:image_gallery_saver/image_gallery_saver.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:path_provider/path_provider.dart';
import 'package:flutter_cache_manager/flutter_cache_manager.dart';
import '../widgets/connectivity_snack_listener.dart';

// Custom cache manager with extended cache duration and offline support
final CustomCacheManager = CacheManager(
  Config(
    'notes_images',
    stalePeriod: const Duration(days: 30),
    maxNrOfCacheObjects: 200,
    repo: JsonCacheInfoRepository(databaseName: 'notes_images.db'),
  ),
);

class NotesScreen extends StatefulWidget {
  const NotesScreen({super.key});

  @override
  State<NotesScreen> createState() => _NotesScreenState();
}

class _NotesScreenState extends State<NotesScreen> {
  final List<String> _imageUrls = []; // URLs o paths locales
  final List<File> _pendingUploads = [];

  Future<void> _pickImage() async {
    final picker = ImagePicker();
    final pickedFile = await picker.pickImage(source: ImageSource.camera);

    if (pickedFile != null) {
      final imageFile = File(pickedFile.path);
      final bytes = await imageFile.readAsBytes();

      // Guarda en galería
      await ImageGallerySaver.saveImage(
        Uint8List.fromList(bytes),
        quality: 100,
        name: "note_${DateTime.now().millisecondsSinceEpoch}",
      );

      // Verifica conectividad
      final connectivityResult = await Connectivity().checkConnectivity();

      if (connectivityResult == ConnectivityResult.none) {
        // Sin conexión → guardar para subida posterior
        _pendingUploads.add(imageFile);
        final localPath = imageFile.path;
        setState(() => _imageUrls.add(localPath));
      } else {
        // Con conexión → subir a Firebase Storage
        final downloadUrl = await _uploadToFirebase(imageFile);
        setState(() => _imageUrls.add(downloadUrl));
      }
    }
  }

  Future<String> _uploadToFirebase(File imageFile) async {
    final fileName = "note_${DateTime.now().millisecondsSinceEpoch}.jpg";
    final ref = FirebaseStorage.instance.ref().child('notes/$fileName');
    await ref.putFile(imageFile);
    return await ref.getDownloadURL();
  }

  Future<void> _tryUploadPending() async {
    final connectivityResult = await Connectivity().checkConnectivity();
    if (connectivityResult != ConnectivityResult.none && _pendingUploads.isNotEmpty) {
      for (final file in List<File>.from(_pendingUploads)) {
        final url = await _uploadToFirebase(file);
        setState(() {
          _imageUrls.add(url);
          _pendingUploads.remove(file);
        });
      }
    }
  }

  @override
  void initState() {
    super.initState();
    Connectivity().onConnectivityChanged.listen((_) => _tryUploadPending());
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Notes')),
      body: Column(
        children: [
          const ConnectivitySnackListener(),
          Expanded(
            child: _imageUrls.isEmpty
          ? const Center(child: Text('There are no notes, add one!', style: TextStyle(fontSize: 18, color: Colors.grey)))
          : ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: _imageUrls.length,
              itemBuilder: (context, index) {
                final path = _imageUrls[index];
                final isLocal = path.startsWith('/');

                return Card(
                  margin: const EdgeInsets.only(bottom: 16),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                  elevation: 3,
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(16),
                    child: isLocal
                        ? Image.file(File(path), fit: BoxFit.cover)
                        : CachedNetworkImage(
                            imageUrl: path,
                            fit: BoxFit.cover,
                            cacheManager: CustomCacheManager,
                            placeholder: (context, url) =>
                                const Center(child: CircularProgressIndicator()),
                            errorWidget: (context, url, error) {
                              // Try to load from cache when offline
                              return FutureBuilder<File?>(
                                future: CustomCacheManager.getSingleFile(url),
                                builder: (context, snapshot) {
                                  if (snapshot.hasData && snapshot.data != null) {
                                    return Image.file(snapshot.data!, fit: BoxFit.cover);
                                  }
                                  return const Icon(Icons.broken_image, color: Colors.grey);
                                },
                              );
                            },
                          ),
                  ),
                );
              },
            ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _pickImage,
        child: const Icon(Icons.add_a_photo),
      ),
    );
  }
}




