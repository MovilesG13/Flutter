import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';

class NotesScreen extends StatefulWidget {
  @override
  _NotesScreenState createState() => _NotesScreenState();
}

class _NotesScreenState extends State<NotesScreen> {
  final ImagePicker _picker = ImagePicker();
  List<Map<String, dynamic>> _notes = [];

  void _addNote(String title, String? imagePath) {
    setState(() {
      _notes.add({
        'title': title,
        'imagePath': imagePath,
        'date': DateTime.now(),
      });
    });
  }

  void _openAddNoteDialog() {
    final TextEditingController _titleController = TextEditingController();
    String? imagePath;

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          title: Text("Add Note"),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: _titleController,
                decoration: InputDecoration(labelText: "Title"),
              ),
              SizedBox(height: 10),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: [
                  ElevatedButton.icon(
                    onPressed: () async {
                      final XFile? photo =
                          await _picker.pickImage(source: ImageSource.camera);
                      if (photo != null) {
                        setDialogState(() {
                          imagePath = photo.path;
                        });
                      }
                    },
                    icon: Icon(Icons.camera_alt),
                    label: Text("Camera"),
                  ),
                  ElevatedButton.icon(
                    onPressed: () async {
                      final XFile? photo =
                          await _picker.pickImage(source: ImageSource.gallery);
                      if (photo != null) {
                        setDialogState(() {
                          imagePath = photo.path;
                        });
                      }
                    },
                    icon: Icon(Icons.photo_library),
                    label: Text("Gallery"),
                  ),
                ],
              ),
              if (imagePath != null) ...[
                SizedBox(height: 10),
                Image.file(File(imagePath!), height: 100),
              ]
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(ctx).pop(),
              child: Text("Cancel"),
            ),
            ElevatedButton(
              onPressed: () {
                if (_titleController.text.isNotEmpty) {
                  _addNote(_titleController.text, imagePath);
                  Navigator.of(ctx).pop();
                }
              },
              child: Text("Save"),
            )
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text("Notes"),
        backgroundColor: Color(0xFFbde3f6),
      ),
      body: _notes.isEmpty
          ? Center(child: Text("No notes yet. Add one!"))
          : ListView.builder(
              itemCount: _notes.length,
              itemBuilder: (ctx, i) {
                final note = _notes[i];
                return Card(
                  margin: EdgeInsets.all(10),
                  child: ListTile(
                    leading: note['imagePath'] != null
                        ? Image.file(File(note['imagePath']),
                            width: 50, height: 50, fit: BoxFit.cover)
                        : Icon(Icons.note, color: Color(0xFF0e538f)),
                    title: Text(note['title']),
                    subtitle: Text(
                      "${note['date']}",
                      style: TextStyle(fontSize: 12),
                    ),
                  ),
                );
              },
            ),
      floatingActionButton: FloatingActionButton(
        backgroundColor: Color(0xFFbde3f6),
        onPressed: _openAddNoteDialog,
        child: Icon(Icons.add),
      ),
    );
  }
}
