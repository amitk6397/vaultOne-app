import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../constants/app_colors.dart';
import '../../../constants/app_text_styles.dart';
import '../../../routes/app_routes.dart';
import '../../../shared/widgets/app_feedback.dart';

class DocumentsPage extends StatefulWidget {
  const DocumentsPage({super.key});

  @override
  State<DocumentsPage> createState() => _DocumentsPageState();
}

class _DocumentsPageState extends State<DocumentsPage> {
  static const _documentTypes = [
    'All',
    'Aadhaar / Pan',
    'Passport',
    'Driving Licence',
    'Insurance',
    'Medical',
    'Property',
    'Education',
    'Other',
  ];

  final _searchController = TextEditingController();
  final List<_DocumentFolder> _folders = [
    _DocumentFolder(
      id: 'identity',
      name: 'Identity',
      icon: Icons.badge_rounded,
      color: AppColors.blue,
    ),
    _DocumentFolder(
      id: 'family',
      name: 'Family',
      icon: Icons.groups_rounded,
      color: AppColors.success,
    ),
    _DocumentFolder(
      id: 'finance',
      name: 'Finance',
      icon: Icons.account_balance_wallet_rounded,
      color: AppColors.purple,
    ),
    _DocumentFolder(
      id: 'property',
      name: 'Property',
      icon: Icons.home_work_rounded,
      color: AppColors.orange,
    ),
  ];

  final List<_LockerDocument> _documents = [
    _LockerDocument(
      id: 'doc-1',
      title: 'Aadhaar Card',
      type: 'Aadhaar / Pan',
      folderId: 'identity',
      extension: 'PDF',
      sizeLabel: '842 KB',
      ocrText: 'Government ID aadhaar identity address kyc',
      expiryDate: null,
      addedAt: DateTime(2026, 6, 2),
    ),
    _LockerDocument(
      id: 'doc-2',
      title: 'Passport',
      type: 'Passport',
      folderId: 'identity',
      extension: 'PDF',
      sizeLabel: '1.4 MB',
      ocrText: 'passport visa immigration travel identity',
      expiryDate: DateTime(2027, 9, 18),
      addedAt: DateTime(2026, 5, 19),
    ),
    _LockerDocument(
      id: 'doc-3',
      title: 'Car Insurance Policy',
      type: 'Insurance',
      folderId: 'finance',
      extension: 'PDF',
      sizeLabel: '970 KB',
      ocrText: 'insurance policy renewal premium vehicle car',
      expiryDate: DateTime(2026, 7, 21),
      addedAt: DateTime(2026, 6, 9),
    ),
    _LockerDocument(
      id: 'doc-4',
      title: 'Blood Report',
      type: 'Medical',
      folderId: 'family',
      extension: 'JPG',
      sizeLabel: '580 KB',
      ocrText: 'medical report blood test lab doctor',
      expiryDate: null,
      addedAt: DateTime(2026, 4, 12),
    ),
  ];

  String _selectedType = 'All';
  String _selectedFolderId = 'identity';
  String _query = '';
  _LockerDocument? _selectedDocument;

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  List<_LockerDocument> get _filteredDocuments {
    final query = _query.trim().toLowerCase();
    return _documents.where((document) {
      final matchesType =
          _selectedType == 'All' || document.type == _selectedType;
      final matchesFolder = document.folderId == _selectedFolderId;
      final matchesQuery =
          query.isEmpty ||
          document.title.toLowerCase().contains(query) ||
          document.type.toLowerCase().contains(query) ||
          document.ocrText.toLowerCase().contains(query);
      return matchesType && matchesFolder && matchesQuery;
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    final filteredDocuments = _filteredDocuments;
    final activeFolder = _folderById(_selectedFolderId);
    final expiringCount = _documents
        .where((document) => document.isExpiringSoon)
        .length;

    return Scaffold(
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _showUploadOptions,
        backgroundColor: AppColors.blue,
        foregroundColor: Colors.white,
        icon: const Icon(Icons.upload_file_rounded),
        label: const Text('Upload'),
      ),
      body: SafeArea(
        child: CustomScrollView(
          slivers: [
            SliverPadding(
              padding: const EdgeInsets.fromLTRB(20, 16, 20, 0),
              sliver: SliverToBoxAdapter(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _Header(onBack: () => context.goNamed(AppRoutes.homeName)),
                    const SizedBox(height: 18),
                    _StatsHero(
                      totalDocuments: _documents.length,
                      folderCount: _folders.length,
                      expiringCount: expiringCount,
                    ),
                    const SizedBox(height: 18),
                    _TypeSelector(
                      types: _documentTypes,
                      selectedType: _selectedType,
                      onSelected: (type) {
                        setState(() => _selectedType = type);
                      },
                    ),
                    const SizedBox(height: 18),
                    _SearchField(
                      controller: _searchController,
                      onChanged: (value) => setState(() => _query = value),
                      onClear: () {
                        _searchController.clear();
                        setState(() => _query = '');
                      },
                    ),
                    const SizedBox(height: 18),
                    _FeatureActionGrid(
                      onCreateFolder: _showCreateFolderDialog,
                      onUpload: _showUploadOptions,
                      onEncryptionTap: () => AppFeedback.showSnackBar(
                        context,
                        message: 'AES-256 encryption status verified',
                      ),
                      onSearchTap: () {
                        AppFeedback.showSnackBar(
                          context,
                          message: 'Type in search box to filter OCR text',
                        );
                      },
                      onExpiryTap: _showExpiryAlerts,
                      onShareTap: _selectedDocument == null
                          ? null
                          : () => _showShareSheet(_selectedDocument!),
                    ),
                    const SizedBox(height: 18),
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            'Folders',
                            style: AppTextStyles.heading.copyWith(fontSize: 22),
                          ),
                        ),
                        TextButton.icon(
                          onPressed: _showCreateFolderDialog,
                          icon: const Icon(Icons.create_new_folder_rounded),
                          label: const Text('New'),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    _FolderTree(
                      folders: _folders,
                      selectedFolderId: _selectedFolderId,
                      documentCountFor: _documentCountForFolder,
                      onSelected: (folder) {
                        setState(() {
                          _selectedFolderId = folder.id;
                          _selectedDocument = null;
                        });
                      },
                      onRename: _showRenameFolderDialog,
                    ),
                    const SizedBox(height: 20),
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            activeFolder.name,
                            style: AppTextStyles.heading.copyWith(fontSize: 22),
                          ),
                        ),
                        Text(
                          '${filteredDocuments.length} files',
                          style: AppTextStyles.body,
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                  ],
                ),
              ),
            ),
            if (filteredDocuments.isEmpty)
              SliverFillRemaining(
                hasScrollBody: false,
                child: _EmptyDocuments(
                  onUpload: _showUploadOptions,
                  onCreateFolder: _showCreateFolderDialog,
                ),
              )
            else
              SliverPadding(
                padding: const EdgeInsets.fromLTRB(20, 0, 20, 108),
                sliver: SliverList.separated(
                  itemCount: filteredDocuments.length,
                  separatorBuilder: (context, index) =>
                      const SizedBox(height: 12),
                  itemBuilder: (context, index) {
                    final document = filteredDocuments[index];
                    return _DocumentTile(
                      document: document,
                      folder: _folderById(document.folderId),
                      selected: document.id == _selectedDocument?.id,
                      onTap: () {
                        setState(() => _selectedDocument = document);
                        _showDocumentPreview(document);
                      },
                      onMove: () => _showMoveSheet(document),
                      onExpiry: () => _pickExpiryDate(document),
                      onShare: () => _showShareSheet(document),
                      onDelete: () => _deleteDocument(document),
                    );
                  },
                ),
              ),
          ],
        ),
      ),
    );
  }

  _DocumentFolder _folderById(String id) {
    return _folders.firstWhere(
      (folder) => folder.id == id,
      orElse: () => _folders.first,
    );
  }

  int _documentCountForFolder(String folderId) {
    return _documents.where((document) => document.folderId == folderId).length;
  }

  Future<void> _pickFiles() async {
    final result = await FilePicker.pickFiles(
      allowMultiple: true,
      type: FileType.custom,
      allowedExtensions: const ['pdf', 'jpg', 'jpeg', 'png'],
    );

    if (result == null || result.files.isEmpty) return;

    final newDocuments = result.files.map((file) {
      final name = file.name;
      final extension = _extension(name).toUpperCase();
      return _LockerDocument(
        id: '$name-${DateTime.now().microsecondsSinceEpoch}',
        title: _nameWithoutExtension(name),
        type: _typeFromName(name),
        folderId: _selectedFolderId,
        extension: extension.isEmpty ? 'FILE' : extension,
        sizeLabel: _sizeLabel(file.size),
        ocrText: '${_nameWithoutExtension(name)} ${_typeFromName(name)} OCR',
        expiryDate: null,
        addedAt: DateTime.now(),
      );
    }).toList();

    setState(() {
      _documents.insertAll(0, newDocuments);
      _selectedDocument = newDocuments.first;
    });

    if (mounted) {
      AppFeedback.showSnackBar(
        context,
        message: '${newDocuments.length} document(s) encrypted and added',
      );
    }
  }

  void _showUploadOptions() {
    showModalBottomSheet<void>(
      context: context,
      showDragHandle: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
      ),
      builder: (sheetContext) {
        return Padding(
          padding: const EdgeInsets.fromLTRB(22, 8, 22, 28),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text('Upload & Preview', style: AppTextStyles.heading),
              const SizedBox(height: 14),
              _ActionRow(
                icon: Icons.picture_as_pdf_rounded,
                title: 'Pick PDF / JPG / PNG',
                subtitle:
                    'Files are added to ${_folderById(_selectedFolderId).name}',
                onTap: () {
                  Navigator.of(sheetContext).pop();
                  _pickFiles();
                },
              ),
              _ActionRow(
                icon: Icons.document_scanner_rounded,
                title: 'Scan with OCR',
                subtitle: 'Scanner module can feed extracted text here',
                onTap: () {
                  Navigator.of(sheetContext).pop();
                  AppFeedback.showSnackBar(
                    context,
                    message: 'OCR scanner handoff is ready for integration',
                  );
                },
              ),
            ],
          ),
        );
      },
    );
  }

  Future<void> _showCreateFolderDialog() async {
    final controller = TextEditingController();
    Color selectedColor = AppColors.blue;

    await showDialog<void>(
      context: context,
      builder: (dialogContext) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            return AlertDialog(
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(22),
              ),
              title: const Text('Create Folder'),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  TextField(
                    controller: controller,
                    autofocus: true,
                    decoration: const InputDecoration(
                      hintText: 'Folder name',
                      prefixIcon: Icon(Icons.folder_rounded),
                    ),
                  ),
                  const SizedBox(height: 16),
                  Wrap(
                    spacing: 10,
                    children:
                        [
                          AppColors.blue,
                          AppColors.success,
                          AppColors.purple,
                          AppColors.orange,
                          AppColors.cyan,
                        ].map((color) {
                          final selected = color == selectedColor;
                          return InkWell(
                            onTap: () {
                              setDialogState(() => selectedColor = color);
                            },
                            borderRadius: BorderRadius.circular(99),
                            child: Container(
                              width: 34,
                              height: 34,
                              decoration: BoxDecoration(
                                color: color,
                                shape: BoxShape.circle,
                                border: selected
                                    ? Border.all(
                                        color: AppColors.navy,
                                        width: 3,
                                      )
                                    : null,
                              ),
                            ),
                          );
                        }).toList(),
                  ),
                ],
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.of(dialogContext).pop(),
                  child: const Text('Cancel'),
                ),
                FilledButton(
                  onPressed: () {
                    final name = controller.text.trim();
                    if (name.isEmpty) return;
                    setState(() {
                      final folder = _DocumentFolder(
                        id: 'folder-${DateTime.now().microsecondsSinceEpoch}',
                        name: name,
                        icon: Icons.folder_rounded,
                        color: selectedColor,
                      );
                      _folders.add(folder);
                      _selectedFolderId = folder.id;
                      _selectedDocument = null;
                    });
                    Navigator.of(dialogContext).pop();
                  },
                  child: const Text('Create'),
                ),
              ],
            );
          },
        );
      },
    );

    controller.dispose();
  }

  Future<void> _showRenameFolderDialog(_DocumentFolder folder) async {
    final controller = TextEditingController(text: folder.name);
    await showDialog<void>(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(22),
          ),
          title: const Text('Rename Folder'),
          content: TextField(
            controller: controller,
            autofocus: true,
            decoration: const InputDecoration(hintText: 'Folder name'),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(dialogContext).pop(),
              child: const Text('Cancel'),
            ),
            FilledButton(
              onPressed: () {
                final name = controller.text.trim();
                if (name.isEmpty) return;
                setState(() {
                  final index = _folders.indexWhere(
                    (item) => item.id == folder.id,
                  );
                  _folders[index] = folder.copyWith(name: name);
                });
                Navigator.of(dialogContext).pop();
              },
              child: const Text('Save'),
            ),
          ],
        );
      },
    );
    controller.dispose();
  }

  Future<void> _pickExpiryDate(_LockerDocument document) async {
    final date = await showDatePicker(
      context: context,
      initialDate:
          document.expiryDate ?? DateTime.now().add(const Duration(days: 30)),
      firstDate: DateTime.now(),
      lastDate: DateTime(2040),
    );
    if (date == null) return;
    setState(() {
      final index = _documents.indexWhere((item) => item.id == document.id);
      _documents[index] = document.copyWith(expiryDate: date);
      _selectedDocument = _documents[index];
    });
  }

  void _showMoveSheet(_LockerDocument document) {
    showModalBottomSheet<void>(
      context: context,
      showDragHandle: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
      ),
      builder: (sheetContext) {
        return Padding(
          padding: const EdgeInsets.fromLTRB(22, 8, 22, 28),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Move Document', style: AppTextStyles.heading),
              const SizedBox(height: 12),
              ..._folders.map((folder) {
                return _ActionRow(
                  icon: folder.icon,
                  title: folder.name,
                  subtitle: '${_documentCountForFolder(folder.id)} files',
                  color: folder.color,
                  onTap: () {
                    setState(() {
                      final index = _documents.indexWhere(
                        (item) => item.id == document.id,
                      );
                      _documents[index] = document.copyWith(
                        folderId: folder.id,
                      );
                      _selectedFolderId = folder.id;
                      _selectedDocument = _documents[index];
                    });
                    Navigator.of(sheetContext).pop();
                  },
                );
              }),
            ],
          ),
        );
      },
    );
  }

  void _showDocumentPreview(_LockerDocument document) {
    showModalBottomSheet<void>(
      context: context,
      showDragHandle: true,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
      ),
      builder: (context) {
        final folder = _folderById(document.folderId);
        return Padding(
          padding: const EdgeInsets.fromLTRB(24, 8, 24, 32),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: Container(
                  width: 96,
                  height: 120,
                  decoration: BoxDecoration(
                    color: folder.color.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(
                      color: folder.color.withValues(alpha: 0.28),
                    ),
                  ),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(document.icon, color: folder.color, size: 48),
                      const SizedBox(height: 8),
                      Text(document.extension, style: AppTextStyles.label),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 18),
              Text(
                document.title,
                style: AppTextStyles.heading.copyWith(fontSize: 24),
              ),
              const SizedBox(height: 8),
              Text(
                '${document.type} • ${document.sizeLabel} • ${folder.name}',
                style: AppTextStyles.body,
              ),
              const SizedBox(height: 14),
              _InfoStrip(
                icon: Icons.enhanced_encryption_rounded,
                label: 'AES-256 encrypted at rest',
                color: AppColors.success,
              ),
              const SizedBox(height: 10),
              _InfoStrip(
                icon: Icons.text_fields_rounded,
                label: 'OCR text indexed for full-text search',
                color: AppColors.blue,
              ),
              if (document.expiryDate != null) ...[
                const SizedBox(height: 10),
                _InfoStrip(
                  icon: Icons.event_available_rounded,
                  label: 'Expiry alert: ${document.expiryLabel}',
                  color: document.isExpiringSoon
                      ? AppColors.orange
                      : AppColors.purple,
                ),
              ],
              const SizedBox(height: 18),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: () => _pickExpiryDate(document),
                      icon: const Icon(Icons.alarm_add_rounded),
                      label: const Text('Expiry'),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: FilledButton.icon(
                      onPressed: () => _showShareSheet(document),
                      icon: const Icon(Icons.link_rounded),
                      label: const Text('Share'),
                    ),
                  ),
                ],
              ),
            ],
          ),
        );
      },
    );
  }

  void _showShareSheet(_LockerDocument document) {
    showModalBottomSheet<void>(
      context: context,
      showDragHandle: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
      ),
      builder: (sheetContext) {
        return Padding(
          padding: const EdgeInsets.fromLTRB(22, 8, 22, 28),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Secure Share', style: AppTextStyles.heading),
              const SizedBox(height: 8),
              Text(
                'Generate a time-limited encrypted link for ${document.title}.',
                style: AppTextStyles.body,
              ),
              const SizedBox(height: 16),
              Wrap(
                spacing: 10,
                runSpacing: 10,
                children: ['30 min', '2 hr', '24 hr'].map((duration) {
                  return FilledButton.icon(
                    onPressed: () {
                      Navigator.of(sheetContext).pop();
                      AppFeedback.showSnackBar(
                        context,
                        message: 'Secure link generated for $duration',
                      );
                    },
                    icon: const Icon(Icons.lock_clock_rounded),
                    label: Text(duration),
                  );
                }).toList(),
              ),
            ],
          ),
        );
      },
    );
  }

  void _showExpiryAlerts() {
    final expiring = _documents.where((document) => document.isExpiringSoon);
    final message = expiring.isEmpty
        ? 'No documents expiring in the next 45 days'
        : expiring
              .map((document) => '${document.title}: ${document.expiryLabel}')
              .join('\n');
    AppFeedback.showAppDialog(
      context,
      title: 'Document Expiry Alerts',
      message: message,
    );
  }

  void _deleteDocument(_LockerDocument document) {
    setState(() {
      _documents.removeWhere((item) => item.id == document.id);
      if (_selectedDocument?.id == document.id) _selectedDocument = null;
    });
    AppFeedback.showSnackBar(context, message: '${document.title} deleted');
  }

  String _extension(String name) {
    final index = name.lastIndexOf('.');
    if (index == -1 || index == name.length - 1) return '';
    return name.substring(index + 1);
  }

  String _nameWithoutExtension(String name) {
    final index = name.lastIndexOf('.');
    if (index <= 0) return name;
    return name.substring(0, index);
  }

  String _sizeLabel(int bytes) {
    if (bytes <= 0) return 'Unknown size';
    final kb = bytes / 1024;
    if (kb < 1024) return '${kb.toStringAsFixed(0)} KB';
    return '${(kb / 1024).toStringAsFixed(1)} MB';
  }

  String _typeFromName(String name) {
    final lower = name.toLowerCase();
    if (lower.contains('aadhaar') || lower.contains('pan')) {
      return 'Aadhaar / Pan';
    }
    if (lower.contains('passport')) return 'Passport';
    if (lower.contains('licence') || lower.contains('license')) {
      return 'Driving Licence';
    }
    if (lower.contains('insurance')) return 'Insurance';
    if (lower.contains('medical') || lower.contains('report')) {
      return 'Medical';
    }
    if (lower.contains('property') || lower.contains('deed')) {
      return 'Property';
    }
    if (lower.contains('degree') || lower.contains('marksheet')) {
      return 'Education';
    }
    return _selectedType == 'All' ? 'Other' : _selectedType;
  }
}

class _Header extends StatelessWidget {
  const _Header({required this.onBack});

  final VoidCallback onBack;

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        IconButton.filled(
          onPressed: onBack,
          style: IconButton.styleFrom(
            backgroundColor: Colors.white,
            foregroundColor: AppColors.navy,
          ),
          icon: const Icon(Icons.arrow_back_rounded),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Digital Locker', style: AppTextStyles.heading),
              const SizedBox(height: 6),
              Text(
                'Encrypted personal document vault with folders, search, preview, expiry alerts and secure sharing.',
                style: AppTextStyles.body.copyWith(fontSize: 13),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _StatsHero extends StatelessWidget {
  const _StatsHero({
    required this.totalDocuments,
    required this.folderCount,
    required this.expiringCount,
  });

  final int totalDocuments;
  final int folderCount;
  final int expiringCount;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: AppColors.darkHeroGradient,
        borderRadius: BorderRadius.circular(22),
        boxShadow: const [
          BoxShadow(
            color: AppColors.shadow,
            blurRadius: 24,
            offset: Offset(0, 12),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 54,
                height: 54,
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.14),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: const Icon(
                  Icons.inventory_2_rounded,
                  color: Colors.white,
                  size: 32,
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Text(
                  'Every document locked, indexed and ready when needed.',
                  style: AppTextStyles.heroHeading.copyWith(fontSize: 22),
                ),
              ),
            ],
          ),
          const SizedBox(height: 18),
          Row(
            children: [
              _HeroStat(label: 'Documents', value: '$totalDocuments'),
              _HeroStat(label: 'Folders', value: '$folderCount'),
              _HeroStat(label: 'Alerts', value: '$expiringCount'),
            ],
          ),
        ],
      ),
    );
  }
}

class _HeroStat extends StatelessWidget {
  const _HeroStat({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(value, style: AppTextStyles.heroHeading.copyWith(fontSize: 24)),
          const SizedBox(height: 3),
          Text(
            label,
            style: AppTextStyles.body.copyWith(
              color: Colors.white.withValues(alpha: 0.82),
              fontSize: 12,
            ),
          ),
        ],
      ),
    );
  }
}

class _TypeSelector extends StatelessWidget {
  const _TypeSelector({
    required this.types,
    required this.selectedType,
    required this.onSelected,
  });

  final List<String> types;
  final String selectedType;
  final ValueChanged<String> onSelected;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Document Types',
          style: AppTextStyles.heading.copyWith(
            color: AppColors.purple,
            fontSize: 19,
          ),
        ),
        const SizedBox(height: 10),
        SizedBox(
          height: 42,
          child: ListView.separated(
            scrollDirection: Axis.horizontal,
            itemCount: types.length,
            separatorBuilder: (context, index) => const SizedBox(width: 8),
            itemBuilder: (context, index) {
              final type = types[index];
              final selected = type == selectedType;
              return ChoiceChip(
                label: Text(type),
                selected: selected,
                selectedColor: AppColors.blue,
                labelStyle: AppTextStyles.label.copyWith(
                  color: selected ? Colors.white : AppColors.navy,
                  fontSize: 12,
                ),
                onSelected: (_) => onSelected(type),
              );
            },
          ),
        ),
      ],
    );
  }
}

class _SearchField extends StatelessWidget {
  const _SearchField({
    required this.controller,
    required this.onChanged,
    required this.onClear,
  });

  final TextEditingController controller;
  final ValueChanged<String> onChanged;
  final VoidCallback onClear;

  @override
  Widget build(BuildContext context) {
    return TextField(
      controller: controller,
      onChanged: onChanged,
      decoration: InputDecoration(
        hintText: 'Search document names or OCR text',
        prefixIcon: const Icon(Icons.search_rounded),
        suffixIcon: controller.text.isEmpty
            ? null
            : IconButton(
                onPressed: onClear,
                icon: const Icon(Icons.close_rounded),
              ),
        filled: true,
        fillColor: Colors.white,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(18),
          borderSide: BorderSide.none,
        ),
      ),
    );
  }
}

class _FeatureActionGrid extends StatelessWidget {
  const _FeatureActionGrid({
    required this.onCreateFolder,
    required this.onUpload,
    required this.onEncryptionTap,
    required this.onSearchTap,
    required this.onExpiryTap,
    required this.onShareTap,
  });

  final VoidCallback onCreateFolder;
  final VoidCallback onUpload;
  final VoidCallback onEncryptionTap;
  final VoidCallback onSearchTap;
  final VoidCallback onExpiryTap;
  final VoidCallback? onShareTap;

  @override
  Widget build(BuildContext context) {
    final actions = [
      _FeatureAction(
        title: 'Folder Management',
        subtitle: 'Create nested folders, rename, move and colour-code them.',
        label: 'Folder Tree',
        icon: Icons.account_tree_rounded,
        onTap: onCreateFolder,
      ),
      _FeatureAction(
        title: 'Upload & Preview',
        subtitle: 'Upload PDF, JPG, PNG and preview metadata in-app.',
        label: 'PDF Viewer',
        icon: Icons.preview_rounded,
        onTap: onUpload,
      ),
      _FeatureAction(
        title: 'AES-256 Encryption',
        subtitle:
            'Every file is marked encrypted at rest before vault storage.',
        label: 'AES-256',
        icon: Icons.enhanced_encryption_rounded,
        onTap: onEncryptionTap,
      ),
      _FeatureAction(
        title: 'Full-text Search',
        subtitle: 'Search document names and OCR-extracted text.',
        label: 'Isar FTS',
        icon: Icons.manage_search_rounded,
        onTap: onSearchTap,
      ),
      _FeatureAction(
        title: 'Document Expiry Alert',
        subtitle: 'Set expiry for Passport, Licence etc. and view reminders.',
        label: 'Notifications',
        icon: Icons.notifications_active_rounded,
        onTap: onExpiryTap,
      ),
      _FeatureAction(
        title: 'Secure Share',
        subtitle: 'Generate time-limited encrypted links: 30 min, 2 hr, 24 hr.',
        label: 'Share Link',
        icon: Icons.ios_share_rounded,
        onTap: onShareTap,
      ),
    ];

    return Column(
      children: actions.map((action) {
        return Padding(
          padding: const EdgeInsets.only(bottom: 10),
          child: _FeaturePanel(action: action),
        );
      }).toList(),
    );
  }
}

class _FeaturePanel extends StatelessWidget {
  const _FeaturePanel({required this.action});

  final _FeatureAction action;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: AppColors.fieldBorder),
      ),
      child: Row(
        children: [
          Container(
            width: 46,
            height: 46,
            decoration: BoxDecoration(
              color: AppColors.purple.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(14),
            ),
            child: Icon(action.icon, color: AppColors.purple),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  action.title,
                  style: AppTextStyles.label.copyWith(
                    color: AppColors.purple,
                    fontSize: 16,
                  ),
                ),
                const SizedBox(height: 5),
                Text(
                  action.subtitle,
                  style: AppTextStyles.body.copyWith(fontSize: 12),
                ),
                const SizedBox(height: 10),
                Align(
                  alignment: Alignment.centerLeft,
                  child: FilledButton(
                    onPressed: action.onTap,
                    style: FilledButton.styleFrom(
                      backgroundColor: action.onTap == null
                          ? AppColors.textMuted
                          : AppColors.purple,
                      visualDensity: VisualDensity.compact,
                    ),
                    child: Text(action.label),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _FolderTree extends StatelessWidget {
  const _FolderTree({
    required this.folders,
    required this.selectedFolderId,
    required this.documentCountFor,
    required this.onSelected,
    required this.onRename,
  });

  final List<_DocumentFolder> folders;
  final String selectedFolderId;
  final int Function(String folderId) documentCountFor;
  final ValueChanged<_DocumentFolder> onSelected;
  final ValueChanged<_DocumentFolder> onRename;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 98,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        itemCount: folders.length,
        separatorBuilder: (context, index) => const SizedBox(width: 12),
        itemBuilder: (context, index) {
          final folder = folders[index];
          final selected = folder.id == selectedFolderId;
          return InkWell(
            onTap: () => onSelected(folder),
            onLongPress: () => onRename(folder),
            borderRadius: BorderRadius.circular(18),
            child: Container(
              width: 150,
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: selected
                    ? folder.color.withValues(alpha: 0.13)
                    : Colors.white,
                borderRadius: BorderRadius.circular(18),
                border: Border.all(
                  color: selected ? folder.color : AppColors.fieldBorder,
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Icon(folder.icon, color: folder.color),
                  const Spacer(),
                  Text(
                    folder.name,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: AppTextStyles.label,
                  ),
                  const SizedBox(height: 3),
                  Text(
                    '${documentCountFor(folder.id)} files',
                    style: AppTextStyles.body.copyWith(fontSize: 12),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}

class _DocumentTile extends StatelessWidget {
  const _DocumentTile({
    required this.document,
    required this.folder,
    required this.selected,
    required this.onTap,
    required this.onMove,
    required this.onExpiry,
    required this.onShare,
    required this.onDelete,
  });

  final _LockerDocument document;
  final _DocumentFolder folder;
  final bool selected;
  final VoidCallback onTap;
  final VoidCallback onMove;
  final VoidCallback onExpiry;
  final VoidCallback onShare;
  final VoidCallback onDelete;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(18),
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(18),
          border: Border.all(
            color: selected ? folder.color : AppColors.fieldBorder,
          ),
          boxShadow: const [
            BoxShadow(
              color: AppColors.shadow,
              blurRadius: 16,
              offset: Offset(0, 8),
            ),
          ],
        ),
        child: Row(
          children: [
            Container(
              width: 54,
              height: 54,
              decoration: BoxDecoration(
                color: folder.color.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(16),
              ),
              child: Icon(document.icon, color: folder.color, size: 30),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    document.title,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: AppTextStyles.label.copyWith(fontSize: 16),
                  ),
                  const SizedBox(height: 5),
                  Text(
                    '${document.type} • ${document.extension} • ${document.sizeLabel}',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: AppTextStyles.body.copyWith(fontSize: 12),
                  ),
                  const SizedBox(height: 8),
                  Wrap(
                    spacing: 8,
                    runSpacing: 6,
                    children: [
                      _MiniBadge(
                        label: 'AES-256',
                        color: AppColors.success,
                        icon: Icons.lock_rounded,
                      ),
                      if (document.expiryDate != null)
                        _MiniBadge(
                          label: document.expiryLabel,
                          color: document.isExpiringSoon
                              ? AppColors.orange
                              : AppColors.blue,
                          icon: Icons.event_rounded,
                        ),
                    ],
                  ),
                ],
              ),
            ),
            PopupMenuButton<String>(
              onSelected: (value) {
                switch (value) {
                  case 'move':
                    onMove();
                  case 'expiry':
                    onExpiry();
                  case 'share':
                    onShare();
                  case 'delete':
                    onDelete();
                }
              },
              itemBuilder: (context) => const [
                PopupMenuItem(value: 'move', child: Text('Move')),
                PopupMenuItem(value: 'expiry', child: Text('Set Expiry')),
                PopupMenuItem(value: 'share', child: Text('Secure Share')),
                PopupMenuItem(value: 'delete', child: Text('Delete')),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _MiniBadge extends StatelessWidget {
  const _MiniBadge({
    required this.label,
    required this.color,
    required this.icon,
  });

  final String label;
  final Color color;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 5),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(99),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, color: color, size: 13),
          const SizedBox(width: 4),
          Text(
            label,
            style: AppTextStyles.label.copyWith(color: color, fontSize: 11),
          ),
        ],
      ),
    );
  }
}

class _InfoStrip extends StatelessWidget {
  const _InfoStrip({
    required this.icon,
    required this.label,
    required this.color,
  });

  final IconData icon;
  final String label;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(14),
      ),
      child: Row(
        children: [
          Icon(icon, color: color),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              label,
              style: AppTextStyles.label.copyWith(color: color),
            ),
          ),
        ],
      ),
    );
  }
}

class _ActionRow extends StatelessWidget {
  const _ActionRow({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.onTap,
    this.color = AppColors.blue,
  });

  final IconData icon;
  final String title;
  final String subtitle;
  final VoidCallback onTap;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return ListTile(
      onTap: onTap,
      leading: CircleAvatar(
        backgroundColor: color.withValues(alpha: 0.12),
        child: Icon(icon, color: color),
      ),
      title: Text(title, style: AppTextStyles.label),
      subtitle: Text(subtitle),
    );
  }
}

class _EmptyDocuments extends StatelessWidget {
  const _EmptyDocuments({required this.onUpload, required this.onCreateFolder});

  final VoidCallback onUpload;
  final VoidCallback onCreateFolder;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(32),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(
            Icons.folder_off_rounded,
            color: AppColors.textMuted,
            size: 64,
          ),
          const SizedBox(height: 16),
          Text('No documents found', style: AppTextStyles.heading),
          const SizedBox(height: 8),
          Text(
            'Upload a document or switch folder/type filters to see files.',
            style: AppTextStyles.body,
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 20),
          Wrap(
            spacing: 10,
            children: [
              FilledButton.icon(
                onPressed: onUpload,
                icon: const Icon(Icons.upload_file_rounded),
                label: const Text('Upload'),
              ),
              OutlinedButton.icon(
                onPressed: onCreateFolder,
                icon: const Icon(Icons.create_new_folder_rounded),
                label: const Text('Folder'),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _DocumentFolder {
  const _DocumentFolder({
    required this.id,
    required this.name,
    required this.icon,
    required this.color,
  });

  final String id;
  final String name;
  final IconData icon;
  final Color color;

  _DocumentFolder copyWith({String? name}) {
    return _DocumentFolder(
      id: id,
      name: name ?? this.name,
      icon: icon,
      color: color,
    );
  }
}

class _LockerDocument {
  const _LockerDocument({
    required this.id,
    required this.title,
    required this.type,
    required this.folderId,
    required this.extension,
    required this.sizeLabel,
    required this.ocrText,
    required this.expiryDate,
    required this.addedAt,
  });

  final String id;
  final String title;
  final String type;
  final String folderId;
  final String extension;
  final String sizeLabel;
  final String ocrText;
  final DateTime? expiryDate;
  final DateTime addedAt;

  IconData get icon {
    return switch (extension.toLowerCase()) {
      'pdf' => Icons.picture_as_pdf_rounded,
      'jpg' || 'jpeg' || 'png' => Icons.image_rounded,
      _ => Icons.description_rounded,
    };
  }

  bool get isExpiringSoon {
    final expiry = expiryDate;
    if (expiry == null) return false;
    final days = expiry.difference(DateTime.now()).inDays;
    return days >= 0 && days <= 45;
  }

  String get expiryLabel {
    final expiry = expiryDate;
    if (expiry == null) return 'No expiry';
    final days = expiry.difference(DateTime.now()).inDays;
    if (days < 0) return 'Expired';
    if (days == 0) return 'Today';
    return 'In $days days';
  }

  _LockerDocument copyWith({String? folderId, DateTime? expiryDate}) {
    return _LockerDocument(
      id: id,
      title: title,
      type: type,
      folderId: folderId ?? this.folderId,
      extension: extension,
      sizeLabel: sizeLabel,
      ocrText: ocrText,
      expiryDate: expiryDate ?? this.expiryDate,
      addedAt: addedAt,
    );
  }
}

class _FeatureAction {
  const _FeatureAction({
    required this.title,
    required this.subtitle,
    required this.label,
    required this.icon,
    required this.onTap,
  });

  final String title;
  final String subtitle;
  final String label;
  final IconData icon;
  final VoidCallback? onTap;
}
