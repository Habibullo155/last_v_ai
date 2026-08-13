import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../models/rag_document.dart';
import '../services/documents_service.dart';
import '../state/auth_store.dart';
import '../widgets/app_background.dart';
import '../widgets/glass_panel.dart';

class AdminDocumentsScreen extends StatefulWidget {
  final AuthStore authStore;
  const AdminDocumentsScreen({super.key, required this.authStore});

  @override
  State<AdminDocumentsScreen> createState() => _AdminDocumentsScreenState();
}

class _AdminDocumentsScreenState extends State<AdminDocumentsScreen> {
  final _service = DocumentsService();
  List<RagDocument> _documents = [];
  bool _isLoading = true;
  bool _isUploading = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    _load();
  }

  @override
  void dispose() {
    _service.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    final token = widget.authStore.token;
    if (token == null) return;
    setState(() {
      _isLoading = true;
      _error = null;
    });
    try {
      final docs = await _service.list(baseUrl: widget.authStore.baseUrl, token: token);
      if (!mounted) return;
      setState(() => _documents = docs);
    } on DocumentsException catch (e) {
      if (!mounted) return;
      setState(() => _error = e.message);
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _pickAndUpload() async {
    final result = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['pdf'],
      withData: true, // байты сразу в памяти — одинаково работает и в вебе
    );
    if (result == null || result.files.isEmpty) return;
    final file = result.files.single;
    final bytes = file.bytes;
    if (bytes == null) {
      setState(() => _error = 'Не удалось прочитать файл.');
      return;
    }

    final token = widget.authStore.token;
    if (token == null) return;

    setState(() {
      _isUploading = true;
      _error = null;
    });
    try {
      final doc = await _service.upload(
        baseUrl: widget.authStore.baseUrl,
        token: token,
        filename: file.name,
        bytes: bytes,
      );
      if (!mounted) return;
      setState(() => _documents = [doc, ..._documents]);
    } on DocumentsException catch (e) {
      if (!mounted) return;
      setState(() => _error = e.message);
    } finally {
      if (mounted) setState(() => _isUploading = false);
    }
  }

  Future<void> _delete(RagDocument doc) async {
    final token = widget.authStore.token;
    if (token == null) return;
    try {
      await _service.delete(baseUrl: widget.authStore.baseUrl, token: token, documentId: doc.id);
      if (!mounted) return;
      setState(() => _documents.removeWhere((d) => d.id == doc.id));
    } on DocumentsException catch (e) {
      if (!mounted) return;
      setState(() => _error = e.message);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.transparent,
      body: AppBackground(
        child: SafeArea(
          child: Column(
            children: [
              Padding(
                padding: const EdgeInsets.all(16),
                child: Row(
                  children: [
                    IconButton(
                      icon: const Icon(Icons.arrow_back_rounded, color: Colors.white),
                      onPressed: () => Navigator.of(context).pop(),
                    ),
                    const Expanded(
                      child: Text(
                        'Обучение на документах (RAG)',
                        style: TextStyle(color: Colors.white, fontSize: 17, fontWeight: FontWeight.w600),
                      ),
                    ),
                  ],
                ),
              ),
              Expanded(
                child: Center(
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: 640),
                    child: RefreshIndicator(
                      onRefresh: _load,
                      child: ListView(
                        padding: const EdgeInsets.all(16),
                        children: [
                          _buildIntro(),
                          const SizedBox(height: 16),
                          _buildUploadButton(),
                          if (_error != null) ...[
                            const SizedBox(height: 12),
                            Text(_error!, style: const TextStyle(color: Color(0xFFFFB4B4), fontSize: 13)),
                          ],
                          const SizedBox(height: 20),
                          if (_isLoading)
                            const Center(child: CircularProgressIndicator(color: Color(0xFF6C5CE7)))
                          else if (_documents.isEmpty)
                            _buildEmptyState()
                          else
                            ..._documents.map(_buildDocTile),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildIntro() {
    return GlassPanel(
      opacity: 0.08,
      borderRadius: BorderRadius.circular(20),
      padding: const EdgeInsets.all(16),
      child: Text(
        'Загрузи PDF — сервер сам разобьёт его на смысловые разделы и '
        'посчитает эмбеддинги. При ответах модель будет автоматически '
        'подмешивать релевантные куски из загруженных документов, если '
        'вопрос пользователя с ними связан.',
        style: TextStyle(color: Colors.white.withOpacity(0.65), fontSize: 13, height: 1.5),
      ),
    );
  }

  Widget _buildUploadButton() {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: _isUploading ? null : _pickAndUpload,
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 14),
          alignment: Alignment.center,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16),
            gradient: LinearGradient(
              colors: _isUploading
                  ? [Colors.white24, Colors.white10]
                  : [const Color(0xFF6C5CE7), const Color(0xFF00B4D8)],
            ),
          ),
          child: _isUploading
              ? const Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                    ),
                    SizedBox(width: 10),
                    Text('Загружаю и считаю эмбеддинги…', style: TextStyle(color: Colors.white)),
                  ],
                )
              : const Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.upload_file_rounded, color: Colors.white, size: 20),
                    SizedBox(width: 10),
                    Text('Загрузить PDF', style: TextStyle(color: Colors.white, fontWeight: FontWeight.w600)),
                  ],
                ),
        ),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 40),
      child: Center(
        child: Text(
          'Документов пока нет',
          style: TextStyle(color: Colors.white.withOpacity(0.4)),
        ),
      ),
    );
  }

  Widget _buildDocTile(RagDocument doc) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: GlassPanel(
        opacity: 0.08,
        blurred: false, // рендерится по одному на документ в списке
        borderRadius: BorderRadius.circular(16),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        child: Row(
          children: [
            Icon(Icons.picture_as_pdf_rounded, color: Colors.white.withOpacity(0.6)),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    doc.filename,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w500, fontSize: 14),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    '${doc.chunkCount} разделов · ${DateFormat.yMMMd().format(doc.createdAt)}',
                    style: TextStyle(color: Colors.white.withOpacity(0.4), fontSize: 12),
                  ),
                ],
              ),
            ),
            IconButton(
              icon: Icon(Icons.delete_outline_rounded, color: Colors.white.withOpacity(0.5), size: 20),
              onPressed: () => _delete(doc),
            ),
          ],
        ),
      ),
    );
  }
}
