import 'dart:io';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:file_picker/file_picker.dart';
import '../theme/app_theme.dart';
import '../bloc/requirements_bloc.dart';
import '../bloc/requirements_event.dart';
import '../bloc/requirements_state.dart';
import 'requirements_form_screen.dart';
import 'results_screen.dart';

class UploadScreen extends StatefulWidget {
  const UploadScreen({super.key});

  @override
  State<UploadScreen> createState() => _UploadScreenState();
}

class _UploadScreenState extends State<UploadScreen> {
  PlatformFile? _selectedFile;

  Future<void> _pickFile() async {
    try {
      FilePickerResult? result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['csv', 'xlsx', 'xls'],
        withData: true, // Load file bytes for web platform
      );

      if (result != null && result.files.single.size > 0) {
        setState(() {
          _selectedFile = result.files.single;
        });
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Error picking file: $e')));
      }
    }
  }

  Future<void> _uploadFile() async {
    if (_selectedFile == null) return;

    try {
      Uint8List bytes;
      if (kIsWeb) {
        bytes = _selectedFile!.bytes!;
      } else {
        final file = File(_selectedFile!.path!);
        bytes = await file.readAsBytes();
      }

      context.read<RequirementsBloc>().add(
        UploadFileEvent(
          bytes: bytes,
          filename: _selectedFile!.name,
        ),
      );
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error reading file: $e'),
            backgroundColor: AppTheme.errorColor,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Upload Requirements')),
      body: BlocConsumer<RequirementsBloc, RequirementsState>(
        listener: (context, state) {
          if (state is RequirementsUploaded) {
            // Automatically analyze after upload
            context.read<RequirementsBloc>().add(
              AnalyzePrioritizationEvent(sessionId: state.sessionId),
            );
          } else if (state is PrioritizationComplete) {
            Navigator.pushReplacement(
              context,
              MaterialPageRoute(
                builder: (context) => ResultsScreen(
                  sessionId: state.sessionId,
                  prioritizedRequirements: state.prioritizedRequirements,
                  metadata: state.metadata,
                  processingTimeMs: state.processingTimeMs,
                ),
              ),
            );
          } else if (state is RequirementsError) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(state.message),
                backgroundColor: AppTheme.errorColor,
              ),
            );
          }
        },
        builder: (context, state) {
          final isLoading =
              state is RequirementsLoading || state is PrioritizationAnalyzing;

          return SafeArea(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(AppTheme.spacingL),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  const SizedBox(height: AppTheme.spacingL),

                  // Header
                  Text(
                    'Choose Input Method',
                    style: Theme.of(context).textTheme.displayMedium,
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: AppTheme.spacingS),
                  Text(
                    'Upload a file or create requirements manually',
                    style: Theme.of(context).textTheme.bodyMedium,
                    textAlign: TextAlign.center,
                  ),

                  const SizedBox(height: AppTheme.spacingXXL),

                  // Upload Section
                  _SectionCard(
                    icon: Icons.upload_file,
                    title: 'Upload File',
                    description: 'CSV or Excel file (max 100 requirements)',
                    color: AppTheme.primaryColor,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        const SizedBox(height: AppTheme.spacingM),

                        if (_selectedFile != null)
                          Container(
                            padding: const EdgeInsets.all(AppTheme.spacingM),
                            decoration: BoxDecoration(
                              color: AppTheme.backgroundColor,
                              borderRadius: BorderRadius.circular(
                                AppTheme.radiusM,
                              ),
                            ),
                            child: Row(
                              children: [
                                const Icon(
                                  Icons.insert_drive_file,
                                  color: AppTheme.primaryColor,
                                ),
                                const SizedBox(width: AppTheme.spacingS),
                                Expanded(
                                  child: Text(
                                    _selectedFile!.name,
                                    style: Theme.of(
                                      context,
                                    ).textTheme.bodyLarge,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ),
                                IconButton(
                                  icon: const Icon(Icons.close),
                                  onPressed: () {
                                    setState(() {
                                      _selectedFile = null;
                                    });
                                  },
                                ),
                              ],
                            ),
                          )
                        else
                          OutlinedButton.icon(
                            onPressed: isLoading ? null : _pickFile,
                            icon: const Icon(Icons.folder_open),
                            label: const Text('Choose File'),
                          ),

                        const SizedBox(height: AppTheme.spacingM),

                        ElevatedButton(
                          onPressed: (_selectedFile != null && !isLoading)
                              ? _uploadFile
                              : null,
                          child: isLoading
                              ? const SizedBox(
                                  height: 20,
                                  width: 20,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                    valueColor: AlwaysStoppedAnimation<Color>(
                                      Colors.white,
                                    ),
                                  ),
                                )
                              : const Text('Upload & Analyze'),
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: AppTheme.spacingL),

                  // Divider
                  Row(
                    children: [
                      const Expanded(child: Divider()),
                      Padding(
                        padding: const EdgeInsets.symmetric(
                          horizontal: AppTheme.spacingM,
                        ),
                        child: Text(
                          'OR',
                          style: Theme.of(context).textTheme.bodyMedium,
                        ),
                      ),
                      const Expanded(child: Divider()),
                    ],
                  ),

                  const SizedBox(height: AppTheme.spacingL),

                  // Manual Entry Section
                  _SectionCard(
                    icon: Icons.edit_note,
                    title: 'Manual Entry',
                    description: 'Create requirements using our form',
                    color: AppTheme.secondaryColor,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        const SizedBox(height: AppTheme.spacingM),
                        OutlinedButton.icon(
                          onPressed: isLoading
                              ? null
                              : () {
                                  Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                      builder: (context) =>
                                          const RequirementsFormScreen(),
                                    ),
                                  );
                                },
                          icon: const Icon(Icons.add),
                          label: const Text('Create Requirements'),
                          style: OutlinedButton.styleFrom(
                            foregroundColor: AppTheme.secondaryColor,
                            side: const BorderSide(
                              color: AppTheme.secondaryColor,
                              width: 1.5,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: AppTheme.spacingXXL),

                  // Info
                  if (state is RequirementsLoading ||
                      state is PrioritizationAnalyzing)
                    Container(
                      padding: const EdgeInsets.all(AppTheme.spacingM),
                      decoration: BoxDecoration(
                        color: AppTheme.infoColor.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(AppTheme.radiusM),
                      ),
                      child: Row(
                        children: [
                          const SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          ),
                          const SizedBox(width: AppTheme.spacingM),
                          Expanded(
                            child: Text(
                              state is RequirementsLoading
                                  ? (state.message ?? 'Processing...')
                                  : 'Analyzing requirements...',
                              style: Theme.of(context).textTheme.bodyMedium,
                            ),
                          ),
                        ],
                      ),
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

class _SectionCard extends StatelessWidget {
  final IconData icon;
  final String title;
  final String description;
  final Color color;
  final Widget child;

  const _SectionCard({
    required this.icon,
    required this.title,
    required this.description,
    required this.color,
    required this.child,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(AppTheme.spacingL),
      decoration: BoxDecoration(
        color: AppTheme.surfaceColor,
        borderRadius: BorderRadius.circular(AppTheme.radiusL),
        boxShadow: AppTheme.cardShadow,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  color: color.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(AppTheme.radiusM),
                ),
                child: Icon(icon, color: color, size: 24),
              ),
              const SizedBox(width: AppTheme.spacingM),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(title, style: Theme.of(context).textTheme.titleLarge),
                    const SizedBox(height: AppTheme.spacingXS),
                    Text(
                      description,
                      style: Theme.of(context).textTheme.bodyMedium,
                    ),
                  ],
                ),
              ),
            ],
          ),
          child,
        ],
      ),
    );
  }
}
