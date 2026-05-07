import 'package:flutter/material.dart';
import 'package:koi_printer/koi_printer.dart';
import 'package:koi_printer_editor/services/cloud_sync_service.dart';
import 'package:koi_printer_editor/state/editor_state.dart';
import 'package:koi_printer_editor/mock_templates.dart';
import 'package:provider/provider.dart';

class TemplateGalleryDialog extends StatefulWidget {
  const TemplateGalleryDialog({super.key});

  @override
  State<TemplateGalleryDialog> createState() => _TemplateGalleryDialogState();
}

class _TemplateGalleryDialogState extends State<TemplateGalleryDialog> {
  final CloudSyncService _cloudService = CloudSyncService();
  bool _isLoading = false;
  List<KoiTemplateManifest> _cloudTemplates = [];

  @override
  void initState() {
    super.initState();
    _loadCloudTemplates();
  }

  Future<void> _loadCloudTemplates() async {
    setState(() => _isLoading = true);
    final templates = await _cloudService.fetchCloudTemplates();
    if (mounted) {
      setState(() {
        _cloudTemplates = templates;
        _isLoading = false;
      });
    }
  }

  Future<void> _deleteCloudTemplate(String id) async {
    setState(() => _isLoading = true);
    await _cloudService.deleteTemplate(id);
    await _loadCloudTemplates();
  }

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 2,
      child: AlertDialog(
        title: const Text('模板大厅 (Gallery)'),
        content: SizedBox(
          width: 600,
          height: 450,
          child: Column(
            children: [
              const TabBar(
                tabs: [
                  Tab(text: '内置模板 (Built-in)'),
                  Tab(text: '云端模板 (Cloud)'),
                ],
                labelColor: Colors.blue,
                unselectedLabelColor: Colors.grey,
              ),
              const SizedBox(height: 12),
              Expanded(
                child: TabBarView(
                  children: [
                    _buildGrid(templateManifests, false),
                    _isLoading
                        ? const Center(child: CircularProgressIndicator())
                        : _cloudTemplates.isEmpty
                        ? const Center(
                            child: Text(
                              '无云端模板，请使用"保存到云端"功能上传。',
                              style: TextStyle(color: Colors.grey),
                            ),
                          )
                        : _buildGrid(_cloudTemplates, true),
                  ],
                ),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('取消'),
          ),
        ],
      ),
    );
  }

  Widget _buildGrid(List<KoiTemplateManifest> list, bool isCloud) {
    return GridView.builder(
      padding: const EdgeInsets.all(8),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        mainAxisSpacing: 12,
        crossAxisSpacing: 12,
        childAspectRatio: 1.6,
      ),
      itemCount: list.length,
      itemBuilder: (ctx, i) {
        final m = list[i];
        return Card(
          clipBehavior: Clip.antiAlias,
          child: Stack(
            children: [
              InkWell(
                onTap: () {
                  final elements = manifestToEditorElements(m);
                  context.read<EditorState>().loadManifest(m, elements);
                  Navigator.pop(ctx);
                },
                child: Container(
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [Colors.blue.shade50, Colors.white],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                  ),
                  child: Stack(
                    children: [
                      Positioned.fill(
                        child: Opacity(
                          opacity: 0.15,
                          child: IgnorePointer(
                            child: FittedBox(
                              fit: BoxFit.contain,
                              alignment: Alignment.topCenter,
                              child: KoiPreviewRenderer.build(
                                document: m.document,
                                paperWidthPx: 380,
                                fontFamily: 'SarasaMono',
                              ),
                            ),
                          ),
                        ),
                      ),
                      Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Text(
                              m.name,
                              style: const TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                              ),
                              textAlign: TextAlign.center,
                            ),
                            const SizedBox(height: 4),
                            if (m.description.isNotEmpty)
                              Text(
                                m.description,
                                style: TextStyle(
                                  fontSize: 11,
                                  color: Colors.grey.shade700,
                                ),
                                textAlign: TextAlign.center,
                                maxLines: 2,
                                overflow: TextOverflow.ellipsis,
                              ),
                            const SizedBox(height: 4),
                            Text(
                              '${m.schema.length} 个变量',
                              style: TextStyle(
                                fontSize: 11,
                                color: Colors.blue.shade700,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              if (isCloud)
                Positioned(
                  top: 4,
                  right: 4,
                  child: IconButton(
                    icon: const Icon(Icons.delete, color: Colors.red, size: 18),
                    onPressed: () {
                      _deleteCloudTemplate(m.id);
                    },
                  ),
                ),
            ],
          ),
        );
      },
    );
  }
}
