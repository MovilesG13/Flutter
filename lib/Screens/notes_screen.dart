import 'dart:io';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:image_gallery_saver/image_gallery_saver.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter_cache_manager/flutter_cache_manager.dart';
import '../services/notes_service.dart';
import '../services/connectivity_service.dart';
import '../services/offline_notes_queue_service.dart';
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
  final ImagePicker _picker = ImagePicker();
  bool _isUploading = false;

  Future<void> _pickImage() async {
    try {
      final pickedFile = await _picker.pickImage(
        source: ImageSource.camera,
        imageQuality: 85,
      );

      if (pickedFile != null) {
        setState(() {
          _isUploading = true;
        });

        final imageFile = File(pickedFile.path);
        
        // Guardar en galería del dispositivo
        try {
          final bytes = await imageFile.readAsBytes();
          await ImageGallerySaver.saveImage(
            Uint8List.fromList(bytes),
            quality: 100,
            name: "note_${DateTime.now().millisecondsSinceEpoch}",
          );
        } catch (e) {
          print('Error saving to gallery: $e');
          // Continuar aunque falle guardar en galería
        }

        // Verificar conectividad antes de intentar subir
        final isOnline = ConnectivityService.instance.isOnline;
        
        if (isOnline) {
          // Online: intentar subir directamente
          try {
            // Primero subir a Storage
            final downloadUrl = await _uploadToFirebase(imageFile);
            
            // Luego guardar en Firestore - esto agregará a la lista existente
            final noteId = await NotesService.instance.addNote(downloadUrl);
            
            print('Note saved with ID: $noteId and URL: $downloadUrl');
            
            if (mounted) {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Note saved successfully'),
                  duration: Duration(seconds: 2),
                  backgroundColor: Colors.green,
                ),
              );
            }
          } catch (e) {
            print('Error uploading to Firebase: $e');
            // Si falla la subida, guardar en cola offline
            await OfflineNotesQueueService.instance.enqueueNote(imageFile.path);
            if (mounted) {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Saved locally. Will sync when connection is restored.'),
                  duration: Duration(seconds: 3),
                  backgroundColor: Colors.orange,
                ),
              );
            }
          }
        } else {
          // Offline: guardar en cola para subir después
          await OfflineNotesQueueService.instance.enqueueNote(imageFile.path);
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('Saved locally. Will sync when connection is restored.'),
                duration: Duration(seconds: 3),
                backgroundColor: Colors.orange,
              ),
            );
          }
        }
        
        if (mounted) {
          setState(() {
            _isUploading = false;
          });
        }
        }
      }
    } catch (e) {
      print('Error picking image: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error: $e'),
            backgroundColor: Colors.red,
          ),
        );
        setState(() {
          _isUploading = false;
        });
      }
    }
  }

  Future<String> _uploadToFirebase(File imageFile) async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      throw Exception('User not logged in');
    }

    final fileName = "note_${DateTime.now().millisecondsSinceEpoch}_${user.uid}.jpg";
    final ref = FirebaseStorage.instance
        .ref()
        .child('users/${user.uid}/notes/$fileName');
    
    await ref.putFile(imageFile);
    return await ref.getDownloadURL();
  }

  Future<void> _deleteNote(Note note) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Note'),
        content: const Text('Are you sure you want to delete this note?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('Delete'),
          ),
        ],
      ),
    );

    if (confirm == true) {
      try {
        await NotesService.instance.deleteNote(note.id);
        // También eliminar de Firebase Storage si quieres
        // (opcional, para ahorrar espacio)
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Note deleted')),
          );
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Error deleting note: $e'),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Notes'),
        backgroundColor: const Color(0xFFbde3f6),
      ),
      body: Column(
        children: [
          const ConnectivitySnackListener(),
          Expanded(
            child: StreamBuilder<List<Note>>(
              stream: NotesService.instance.userNotesStream(),
              initialData: const [],
              builder: (context, snapshot) {
                // También obtener notas pendientes (offline)
                // Usar StreamBuilder para actualizar cuando cambia la conexión
                return StreamBuilder<bool>(
                  stream: ConnectivityService.instance.isOnlineStream,
                  initialData: ConnectivityService.instance.isOnline,
                  builder: (context, connectivitySnapshot) {
                    return FutureBuilder<List<Map<String, dynamic>>>(
                      future: OfflineNotesQueueService.instance.getPendingNotes(),
                      builder: (context, pendingSnapshot) {
                // Mostrar loading solo en el primer build
                if (snapshot.connectionState == ConnectionState.waiting && 
                    !snapshot.hasData) {
                  return const Center(
                    child: CircularProgressIndicator(),
                  );
                }

                if (snapshot.hasError) {
                  return Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(Icons.error, color: Colors.red, size: 48),
                        const SizedBox(height: 16),
                        Text('Error loading notes: ${snapshot.error}'),
                        const SizedBox(height: 16),
                        ElevatedButton(
                          onPressed: () => setState(() {}),
                          child: const Text('Retry'),
                        ),
                      ],
                    ),
                  );
                }

                final notes = snapshot.data ?? [];
                final pendingNotes = pendingSnapshot.data ?? [];
                
                // Debug: ver cuántas notas hay
                print('Notes count: ${notes.length}, Pending: ${pendingNotes.length}');

                final totalCount = notes.length + pendingNotes.length;

                if (totalCount == 0 && !_isUploading) {
                  return const Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.photo_library, size: 64, color: Colors.grey),
                        SizedBox(height: 16),
                        Text(
                          'No notes yet',
                          style: TextStyle(fontSize: 18, color: Colors.grey),
                        ),
                        SizedBox(height: 8),
                        Text(
                          'Tap the camera button to add a note',
                          style: TextStyle(fontSize: 14, color: Colors.grey),
                        ),
                      ],
                    ),
                  );
                }

                return ListView.builder(
                  padding: const EdgeInsets.all(16),
                  itemCount: totalCount,
                  itemBuilder: (context, index) {
                    // Primero mostrar las pendientes (offline), luego las de Firebase
                    if (index < pendingNotes.length) {
                      final pendingNote = pendingNotes[index];
                      final imagePath = pendingNote['image_path'] as String;
                      final noteId = pendingNote['id'] as int;
                      
                      return Card(
                        margin: const EdgeInsets.only(bottom: 16),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16),
                        ),
                        elevation: 3,
                        child: Stack(
                          children: [
                            ClipRRect(
                              borderRadius: BorderRadius.circular(16),
                              child: Image.file(
                                File(imagePath),
                                fit: BoxFit.cover,
                                width: double.infinity,
                                height: 300,
                              ),
                            ),
                            // Badge indicando que está pendiente
                            Positioned(
                              top: 8,
                              left: 8,
                              child: Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 8,
                                  vertical: 4,
                                ),
                                decoration: BoxDecoration(
                                  color: Colors.orange,
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: const Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Icon(
                                      Icons.cloud_upload,
                                      color: Colors.white,
                                      size: 16,
                                    ),
                                    SizedBox(width: 4),
                                    Text(
                                      'Pending upload',
                                      style: TextStyle(
                                        color: Colors.white,
                                        fontSize: 12,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                            // Botón de eliminar
                            Positioned(
                              top: 8,
                              right: 8,
                              child: Material(
                                color: Colors.black54,
                                borderRadius: BorderRadius.circular(20),
                                child: IconButton(
                                  icon: const Icon(Icons.delete, color: Colors.white, size: 20),
                                  onPressed: () async {
                                    final confirm = await showDialog<bool>(
                                      context: context,
                                      builder: (context) => AlertDialog(
                                        title: const Text('Delete Pending Note'),
                                        content: const Text(
                                          'Are you sure you want to delete this note?',
                                        ),
                                        actions: [
                                          TextButton(
                                            onPressed: () => Navigator.pop(context, false),
                                            child: const Text('Cancel'),
                                          ),
                                          TextButton(
                                            onPressed: () => Navigator.pop(context, true),
                                            style: TextButton.styleFrom(
                                              foregroundColor: Colors.red,
                                            ),
                                            child: const Text('Delete'),
                                          ),
                                        ],
                                      ),
                                    );
                                    if (confirm == true) {
                                      await OfflineNotesQueueService.instance
                                          .deletePendingNote(noteId);
                                      // Forzar refresh del FutureBuilder
                                      if (mounted) {
                                        setState(() {});
                                      }
                                    }
                                  },
                                  padding: EdgeInsets.zero,
                                  constraints: const BoxConstraints(
                                    minWidth: 40,
                                    minHeight: 40,
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                      );
                    }
                    
                    // Notas de Firebase (ya subidas)
                    final firebaseIndex = index - pendingNotes.length;
                    final note = notes[firebaseIndex];
                    print('Building note ${firebaseIndex + 1}/${notes.length}: ${note.id}');
                    return Card(
                      margin: const EdgeInsets.only(bottom: 16),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                      ),
                      elevation: 3,
                      child: Stack(
                        children: [
                          ClipRRect(
                            borderRadius: BorderRadius.circular(16),
                            child: CachedNetworkImage(
                              imageUrl: note.imageUrl,
                              fit: BoxFit.cover,
                              width: double.infinity,
                              height: 300,
                              cacheManager: CustomCacheManager,
                              placeholder: (context, url) => Container(
                                height: 300,
                                color: Colors.grey[200],
                                child: const Center(
                                  child: CircularProgressIndicator(),
                                ),
                              ),
                              errorWidget: (context, url, error) {
                                // Try to load from cache when offline
                                return FutureBuilder<File?>(
                                  future: CustomCacheManager.getSingleFile(url),
                                  builder: (context, cacheSnapshot) {
                                    if (cacheSnapshot.hasData && cacheSnapshot.data != null) {
                                      return Image.file(
                                        cacheSnapshot.data!,
                                        fit: BoxFit.cover,
                                        width: double.infinity,
                                        height: 300,
                                      );
                                    }
                                    return Container(
                                      height: 300,
                                      color: Colors.grey[300],
                                      child: const Column(
                                        mainAxisAlignment: MainAxisAlignment.center,
                                        children: [
                                          Icon(Icons.broken_image, size: 48, color: Colors.grey),
                                          SizedBox(height: 8),
                                          Text('Failed to load image', style: TextStyle(color: Colors.grey)),
                                        ],
                                      ),
                                    );
                                  },
                                );
                              },
                            ),
                          ),
                          // Botón de eliminar en la esquina superior derecha
                          Positioned(
                            top: 8,
                            right: 8,
                            child: Material(
                              color: Colors.black54,
                              borderRadius: BorderRadius.circular(20),
                              child: IconButton(
                                icon: const Icon(Icons.delete, color: Colors.white, size: 20),
                                onPressed: () => _deleteNote(note),
                                padding: EdgeInsets.zero,
                                constraints: const BoxConstraints(
                                  minWidth: 40,
                                  minHeight: 40,
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    );
                  },
                );
                      },
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
      floatingActionButton: _isUploading
          ? FloatingActionButton(
              onPressed: null,
              backgroundColor: Colors.grey,
              child: const CircularProgressIndicator(color: Colors.white),
            )
          : FloatingActionButton(
              onPressed: _pickImage,
              backgroundColor: const Color(0xFF0e538f),
              child: const Icon(Icons.add_a_photo, color: Colors.white),
            ),
    );
  }
}




