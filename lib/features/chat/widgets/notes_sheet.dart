import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:file_picker/file_picker.dart';
// import 'package:video_thumbnail/video_thumbnail.dart';  // Temporarily disabled due to Android SDK issues
import 'package:image/image.dart' as img;
import 'dart:io';
import 'dart:typed_data';

import 'note_viewers.dart';

enum NoteType { text, image, video, audio, pdf, file }

class NoteItem {
  NoteItem({
    required this.id,
    required this.type,
    this.text,
    this.path,
    this.title,
    this.sizeBytes,
    this.thumbnailPath,
    this.storagePath,
    this.thumbnailStoragePath,
    this.createdAt,
  });

  final String id; // Firestore doc id
  final NoteType type;
  String? text;
  String? path; // URL
  String? title;
  int? sizeBytes;
  String? thumbnailPath; // URL for videos
  String? storagePath; // gs path
  String? thumbnailStoragePath;
  DateTime? createdAt;
}

class NotesSheet extends StatefulWidget {
  const NotesSheet({Key? key, required this.workspaceId, this.customerId, required this.chatroomId}) : super(key: key);
  final String workspaceId;
  final String? customerId;
  final String chatroomId;

  @override
  State<NotesSheet> createState() => _NotesSheetState();
}

class _NotesSheetState extends State<NotesSheet> {
  final List<NoteItem> _notes = [];
  bool _busy = false;

  // Determine whether notes are saved under a customer or directly under a chatroom
  bool get _hasCustomer => (widget.customerId != null && widget.customerId!.isNotEmpty);

  DocumentReference<Map<String, dynamic>> get _targetDoc {
    final ws = FirebaseFirestore.instance.collection('workspaces').doc(widget.workspaceId);
    if (_hasCustomer) {
      return ws.collection('customers').doc(widget.customerId);
    }
    return ws.collection('chatrooms').doc(widget.chatroomId);
  }

  @override
  void initState() {
    super.initState();
    _loadNotes();
  }

  Future<void> _loadNotes() async {
    try {
      setState(() => _busy = true);
      final snap = await _targetDoc.get();
      final data = snap.data() ?? {};
      final list = (data['notes'] as List<dynamic>? ?? []).cast<Map<String, dynamic>>();
      list.sort((a, b) => ((b['timestamp'] ?? 0) as int).compareTo((a['timestamp'] ?? 0) as int));
      final items = list.map((m) {
        final t = (m['type'] as String?) ?? 'text';
        final type = {
          'text': NoteType.text,
          'image': NoteType.image,
          'video': NoteType.video,
          'audio': NoteType.audio,
          'pdf': NoteType.pdf,
          'file': NoteType.file,
        }[t] ?? NoteType.text;
        return NoteItem(
          id: (m['id'] ?? '') as String,
          type: type,
          text: m['text'] as String?,
          path: m['url'] as String?,
          title: (m['title'] ?? m['fileName']) as String?,
          sizeBytes: (m['fileSize'] is int) ? m['fileSize'] as int : int.tryParse('${m['fileSize']}'),
          thumbnailPath: m['thumbnailUrl'] as String?,
          storagePath: m['storagePath'] as String?,
          thumbnailStoragePath: m['thumbnailStoragePath'] as String?,
          createdAt: m['timestamp'] != null ? DateTime.fromMillisecondsSinceEpoch(m['timestamp'] as int) : null,
        );
      }).toList();
      setState(() {
        _notes
          ..clear()
          ..addAll(items);
      });
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('โหลดโน้ตไม่สำเร็จ: $e')));
      }
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _persistNotes() async {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    final arr = _notes.map((n) => {
      'id': n.id,
      'type': n.type.name,
      'text': n.text,
      'title': n.title,
      'fileName': n.title,
      'fileSize': n.sizeBytes,
      'url': n.path,
      'thumbnailUrl': n.thumbnailPath,
      'storagePath': n.storagePath,
      'thumbnailStoragePath': n.thumbnailStoragePath,
      'timestamp': (n.createdAt ?? DateTime.now()).millisecondsSinceEpoch,
      'userId': uid,
      'userDisplayName': FirebaseAuth.instance.currentUser?.displayName,
      'userPhotoURL': FirebaseAuth.instance.currentUser?.photoURL,
    }).toList();
    await _targetDoc.set({'notes': arr}, SetOptions(merge: true));
  }

  Future<void> _addTextNote() async {
    final controller = TextEditingController();
    final result = await showDialog<String>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('เพิ่มโน้ตข้อความ'),
        content: TextField(
          controller: controller,
          decoration: const InputDecoration(hintText: 'พิมพ์ข้อความ...'),
          maxLines: 5,
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: Text('cancel'.tr)),
          ElevatedButton(onPressed: () => Navigator.pop(ctx, controller.text.trim()), child: Text('save'.tr)),
        ],
      ),
    );
    if (result != null && result.isNotEmpty) {
      try {
        setState(() => _busy = true);
        final id = 'note-${DateTime.now().millisecondsSinceEpoch}';
        setState(() {
          _notes.insert(0, NoteItem(
            id: id,
            type: NoteType.text,
            text: result,
            title: result.split('\n').first,
            createdAt: DateTime.now(),
          ));
        });
        await _persistNotes();
      } catch (e) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('บันทึกไม่สำเร็จ: $e')));
      } finally {
        if (mounted) setState(() => _busy = false);
      }
    }
  }

  Future<String> _uploadBytes(String pathInStorage, List<int> bytes, {String? contentType}) async {
    final ref = FirebaseStorage.instance.ref(pathInStorage);
    final task = await ref.putData(Uint8List.fromList(bytes), SettableMetadata(contentType: contentType));
    return await task.ref.getDownloadURL();
  }

  Future<String> _uploadFile(String pathInStorage, File file, {String? contentType}) async {
    final ref = FirebaseStorage.instance.ref(pathInStorage);
    final task = await ref.putFile(file, SettableMetadata(contentType: contentType));
    return await task.ref.getDownloadURL();
  }

  Future<void> _addFileNote() async {
    try {
      setState(() => _busy = true);
      final picked = await FilePicker.platform.pickFiles(withData: false);
      if (picked == null || picked.files.isEmpty) return;
      final f = picked.files.single;
      final path = f.path;
      if (path == null) return;
      final ext = path.split('.').last.toLowerCase();
      NoteType type = NoteType.file;
      if (['png', 'jpg', 'jpeg', 'gif', 'webp', 'heic'].contains(ext)) type = NoteType.image;
      else if (['mp4', 'mov', 'm4v', 'webm'].contains(ext)) type = NoteType.video;
      else if (['mp3', 'wav', 'm4a', 'aac', 'ogg'].contains(ext)) type = NoteType.audio;
      else if (ext == 'pdf') type = NoteType.pdf;

      final ts = DateTime.now().millisecondsSinceEpoch;
      final baseDir = _hasCustomer
          ? 'notes/${widget.workspaceId}/customers/${widget.customerId}/$ts'
          : 'notes/${widget.workspaceId}/chatrooms/${widget.chatroomId}/$ts';

      String url;
      String? thumbUrl;
      String storagePath;
      String? thumbStoragePath;

      if (type == NoteType.image) {
        // Resize image before upload
        final bytes = await File(path).readAsBytes();
        final decoded = img.decodeImage(bytes);
        List<int> outBytes;
        if (decoded != null) {
          const maxDim = 1600;
          int w = decoded.width;
          int h = decoded.height;
          if (w > maxDim || h > maxDim) {
            final ratio = w > h ? maxDim / w : maxDim / h;
            w = (w * ratio).round();
            h = (h * ratio).round();
          }
          final resized = img.copyResize(decoded, width: w, height: h);
          outBytes = img.encodeJpg(resized, quality: 70);
        } else {
          outBytes = bytes; // fallback
        }
        storagePath = '$baseDir/${f.name.replaceAll(' ', '_')}.jpg';
        url = await _uploadBytes(storagePath, outBytes, contentType: 'image/jpeg');
      } else if (type == NoteType.video) {
        storagePath = '$baseDir/${f.name.replaceAll(' ', '_')}';
        url = await _uploadFile(storagePath, File(path), contentType: 'video/${ext == 'mov' ? 'quicktime' : 'mp4'}');
        // thumbnail - temporarily disabled due to video_thumbnail plugin issues
        // final thumbFile = await VideoThumbnail.thumbnailFile(
        //   video: path,
        //   imageFormat: ImageFormat.PNG,
        //   maxHeight: 320,
        //   quality: 80,
        // );
        // if (thumbFile != null) {
        //   final tb = await File(thumbFile).readAsBytes();
        //   thumbStoragePath = '$baseDir/thumbnail.png';
        //   thumbUrl = await _uploadBytes(thumbStoragePath, tb, contentType: 'image/png');
        // }
      } else if (type == NoteType.audio) {
        storagePath = '$baseDir/${f.name.replaceAll(' ', '_')}';
        url = await _uploadFile(storagePath, File(path), contentType: 'audio/$ext');
      } else if (type == NoteType.pdf) {
        storagePath = '$baseDir/${f.name.replaceAll(' ', '_')}';
        url = await _uploadFile(storagePath, File(path), contentType: 'application/pdf');
      } else {
        storagePath = '$baseDir/${f.name.replaceAll(' ', '_')}';
        url = await _uploadFile(storagePath, File(path));
      }

      final id = 'note-$ts';
      setState(() {
        _notes.insert(0, NoteItem(
          id: id,
          type: type,
          path: url,
          title: f.name,
          sizeBytes: f.size,
          thumbnailPath: thumbUrl,
          storagePath: storagePath,
          thumbnailStoragePath: thumbStoragePath,
          createdAt: DateTime.now(),
        ));
      });
      await _persistNotes();
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('อัปโหลดไม่สำเร็จ: $e')));
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _editText(NoteItem note) async {
    final controller = TextEditingController(text: note.text ?? '');
    final result = await showDialog<String>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: Colors.white,
        title: const Text('แก้ไขโน้ตข้อความ'),
        content: TextField(
          controller: controller,
          maxLines: 5,
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: Text('cancel'.tr)),
          ElevatedButton(onPressed: () => Navigator.pop(ctx, controller.text.trim()), child: Text('save'.tr)),
        ],
      ),
    );
    if (result != null) {
      setState(() {
        note.text = result;
        note.title = result.split('\n').first;
      });
      try {
        await _persistNotes();
      } catch (e) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('อัปเดตไม่สำเร็จ: $e')));
      }
    }
  }

  Future<void> _removeNote(NoteItem note) async {
    try {
      // Try delete storage files
      if (note.storagePath != null && note.storagePath!.isNotEmpty) {
        await FirebaseStorage.instance.ref(note.storagePath!).delete().catchError((_){});
      }
      if (note.thumbnailStoragePath != null && note.thumbnailStoragePath!.isNotEmpty) {
        await FirebaseStorage.instance.ref(note.thumbnailStoragePath!).delete().catchError((_){});
      }
      setState(() => _notes.removeWhere((n) => n.id == note.id));
      await _persistNotes();
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('ลบไม่สำเร็จ: $e')));
    }
  }

  void _openNote(NoteItem note) {
    switch (note.type) {
      case NoteType.text:
        _editText(note);
        break;
      case NoteType.image:
        Navigator.of(context).push(MaterialPageRoute(builder: (_) => ImageViewer(path: note.path!)));
        break;
      case NoteType.video:
        Navigator.of(context).push(MaterialPageRoute(builder: (_) => VideoViewer(path: note.path!, thumbnailPath: note.thumbnailPath)));
        break;
      case NoteType.audio:
        Navigator.of(context).push(MaterialPageRoute(builder: (_) => AudioViewer(path: note.path!)));
        break;
      case NoteType.pdf:
        Navigator.of(context).push(MaterialPageRoute(builder: (_) => PdfViewer(path: note.path!)));
        break;
      case NoteType.file:
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('ไม่รองรับการแสดงไฟล์นี้ในแอพ')));
        break;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('โน้ต'),
        actions: [
          IconButton(
            onPressed: _busy ? null : _addTextNote,
            icon: const Icon(Icons.note_add_outlined),
            tooltip: 'เพิ่มข้อความ',
          ),
          // IconButton(
          //   onPressed: _busy ? null : _addFileNote,
          //   icon: const Icon(Icons.attach_file),
          //   tooltip: 'แนบไฟล์',
          // ),
        ],
      ),
      body: _busy && _notes.isEmpty
          ? const Center(child: CircularProgressIndicator())
          : _notes.isEmpty
              ? const Center(child: Text('ยังไม่มีโน้ต'))
              : ListView.separated(
                  padding: const EdgeInsets.all(12),
                  itemBuilder: (context, index) {
                    final n = _notes[index];
                    return ListTile(
                      leading: NoteLeading(note: n),
                      title: Text(n.title ?? (n.text ?? '')),
                      subtitle: _buildSubtitle(n),
                      onTap: () => _openNote(n),
                      trailing: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          if (n.type == NoteType.text)
                            IconButton(
                              icon: const Icon(Icons.edit_outlined),
                              onPressed: () => _editText(n),
                            ),
                          IconButton(
                            icon: const Icon(Icons.delete_outline),
                            onPressed: () => _removeNote(n),
                          ),
                        ],
                      ),
                    );
                  },
                  separatorBuilder: (_, __) => const Divider(height: 1),
                  itemCount: _notes.length,
                ),
    );
  }

  Widget? _buildSubtitle(NoteItem n) {
    if (n.type == NoteType.text) return null;
    final size = (n.sizeBytes ?? 0);
    String readable = '';
    if (size > 0) {
      if (size < 1024) readable = '$size B';
      else if (size < 1024 * 1024) readable = '${(size / 1024).toStringAsFixed(1)} KB';
      else readable = '${(size / (1024 * 1024)).toStringAsFixed(1)} MB';
    }
    switch (n.type) {
      case NoteType.image:
        return Text('รูปภาพ • $readable');
      case NoteType.video:
        return Text('วิดีโอ • $readable');
      case NoteType.audio:
        return Text('เสียง • $readable');
      case NoteType.pdf:
        return Text('PDF • $readable');
      case NoteType.file:
        return Text('ไฟล์ • $readable');
      case NoteType.text:
        return null;
    }
  }
}

class NoteLeading extends StatelessWidget {
  const NoteLeading({Key? key, required this.note}) : super(key: key);
  final NoteItem note;

  @override
  Widget build(BuildContext context) {
    switch (note.type) {
      case NoteType.text:
        return const CircleAvatar(child: Icon(Icons.notes));
      case NoteType.image:
        final p = note.path;
        if (p == null) return const CircleAvatar(child: Icon(Icons.image_outlined));
        return ClipRRect(
          borderRadius: BorderRadius.circular(8),
          child: Image(
            image: p.startsWith('http') ? NetworkImage(p) as ImageProvider : FileImage(File(p)),
            fit: BoxFit.cover,
            width: 48,
            height: 48,
          ),
        );
      case NoteType.video:
        final tp = note.thumbnailPath;
        if (tp != null) {
          return ClipRRect(
            borderRadius: BorderRadius.circular(8),
            child: Stack(
              alignment: Alignment.center,
              children: [
                if (tp.startsWith('http'))
                  Image.network(tp, width: 48, height: 48, fit: BoxFit.cover)
                else if (File(tp).existsSync())
                  Image.file(File(tp), width: 48, height: 48, fit: BoxFit.cover)
                else
                  const SizedBox(width: 48, height: 48),
                const Icon(Icons.play_circle_fill, color: Colors.white),
              ],
            ),
          );
        }
        return const CircleAvatar(child: Icon(Icons.videocam_outlined));
      case NoteType.audio:
        return const CircleAvatar(child: Icon(Icons.audiotrack));
      case NoteType.pdf:
        return const CircleAvatar(child: Icon(Icons.picture_as_pdf));
      case NoteType.file:
        return const CircleAvatar(child: Icon(Icons.insert_drive_file));
    }
  }
}
