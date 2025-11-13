import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../theme/app_theme.dart';
import '../api/aria_api_client.dart';
import '../bloc/auth_bloc.dart';
import '../bloc/auth_state.dart';

class AdminScreen extends StatefulWidget {
  final AriaApiClient apiClient;

  const AdminScreen({super.key, required this.apiClient});

  @override
  State<AdminScreen> createState() => _AdminScreenState();
}

class _AdminScreenState extends State<AdminScreen> {
  final _formKey = GlobalKey<FormState>();
  final _apiKeyController = TextEditingController();
  final _baseUrlController = TextEditingController();
  final _modelController = TextEditingController();
  bool _isLoading = false;
  bool _hasConfig = false;
  String? _errorMessage;
  String? _successMessage;

  @override
  void initState() {
    super.initState();
    _loadConfig();
  }

  @override
  void dispose() {
    _apiKeyController.dispose();
    _baseUrlController.dispose();
    _modelController.dispose();
    super.dispose();
  }

  Future<void> _loadConfig() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
      _successMessage = null;
    });

    try {
      final config = await widget.apiClient.getLLMConfig();
      
      setState(() {
        _hasConfig = true;
        _baseUrlController.text = config['baseUrl'] as String? ?? 'https://api.openai.com/v1';
        _modelController.text = config['model'] as String? ?? 'gpt-4o-mini';
        // Don't populate API key for security
        if (config['hasApiKey'] == true) {
          _apiKeyController.text = '••••••••••••••••';
        }
      });
    } catch (e) {
      // Config not found is OK - means it needs to be created
      if (e.toString().contains('404') || e.toString().contains('CONFIG_NOT_FOUND')) {
        setState(() {
          _hasConfig = false;
          _baseUrlController.text = 'https://api.openai.com/v1';
          _modelController.text = 'gpt-4o-mini';
        });
      } else {
        setState(() {
          _errorMessage = 'Failed to load config: $e';
        });
      }
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<void> _saveConfig() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    setState(() {
      _isLoading = true;
      _errorMessage = null;
      _successMessage = null;
    });

    try {
      // If API key is masked, don't send it
      String apiKey = _apiKeyController.text;
      if (apiKey == '••••••••••••••••') {
        // User didn't change the key, skip update
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Please enter a new API key to update'),
            backgroundColor: AppTheme.errorColor,
          ),
        );
        setState(() {
          _isLoading = false;
        });
        return;
      }

      await widget.apiClient.updateLLMConfig(
        apiKey: apiKey,
        baseUrl: _baseUrlController.text.trim(),
        model: _modelController.text.trim(),
      );

      setState(() {
        _successMessage = 'LLM configuration saved successfully';
        _hasConfig = true;
        _apiKeyController.text = '••••••••••••••••';
      });

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('LLM configuration saved successfully'),
          backgroundColor: AppTheme.successColor,
        ),
      );
    } catch (e) {
      setState(() {
        _errorMessage = 'Failed to save config: $e';
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error: $e'),
          backgroundColor: AppTheme.errorColor,
        ),
      );
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<void> _deleteConfig() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete LLM Configuration'),
        content: const Text(
          'Are you sure you want to delete the LLM configuration? '
          'This will disable ChatGPT analysis until a new configuration is set.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppTheme.errorColor,
            ),
            child: const Text('Delete'),
          ),
        ],
      ),
    );

    if (confirmed != true) return;

    setState(() {
      _isLoading = true;
      _errorMessage = null;
      _successMessage = null;
    });

    try {
      await widget.apiClient.deleteLLMConfig();

      setState(() {
        _hasConfig = false;
        _apiKeyController.clear();
        _baseUrlController.text = 'https://api.openai.com/v1';
        _modelController.text = 'gpt-4o-mini';
        _successMessage = 'LLM configuration deleted';
      });

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('LLM configuration deleted'),
          backgroundColor: AppTheme.successColor,
        ),
      );
    } catch (e) {
      setState(() {
        _errorMessage = 'Failed to delete config: $e';
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error: $e'),
          backgroundColor: AppTheme.errorColor,
        ),
      );
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Admin Panel'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: BlocBuilder<AuthBloc, AuthState>(
        builder: (context, state) {
          if (state is! AuthAuthenticated || !state.user.isAdmin) {
            return const Center(
              child: Text('Access denied. Admin privileges required.'),
            );
          }

          return SingleChildScrollView(
            padding: const EdgeInsets.all(AppTheme.spacingL),
            child: Form(
              key: _formKey,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // Header
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(AppTheme.spacingM),
                        decoration: BoxDecoration(
                          color: AppTheme.primaryColor.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(AppTheme.radiusM),
                        ),
                        child: const Icon(
                          Icons.settings,
                          color: AppTheme.primaryColor,
                          size: 32,
                        ),
                      ),
                      const SizedBox(width: AppTheme.spacingM),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'LLM Configuration',
                              style: Theme.of(context).textTheme.headlineSmall,
                            ),
                            const SizedBox(height: AppTheme.spacingXS),
                            Text(
                              'Configure API settings for ChatGPT analysis',
                              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                                color: AppTheme.textSecondary,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: AppTheme.spacingXL),

                  // Status messages
                  if (_errorMessage != null)
                    Container(
                      padding: const EdgeInsets.all(AppTheme.spacingM),
                      decoration: BoxDecoration(
                        color: AppTheme.errorColor.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(AppTheme.radiusM),
                        border: Border.all(color: AppTheme.errorColor),
                      ),
                      child: Row(
                        children: [
                          const Icon(Icons.error_outline, color: AppTheme.errorColor),
                          const SizedBox(width: AppTheme.spacingS),
                          Expanded(
                            child: Text(
                              _errorMessage!,
                              style: const TextStyle(color: AppTheme.errorColor),
                            ),
                          ),
                        ],
                      ),
                    ),
                  if (_successMessage != null) ...[
                    if (_errorMessage != null) const SizedBox(height: AppTheme.spacingM),
                    Container(
                      padding: const EdgeInsets.all(AppTheme.spacingM),
                      decoration: BoxDecoration(
                        color: AppTheme.successColor.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(AppTheme.radiusM),
                        border: Border.all(color: AppTheme.successColor),
                      ),
                      child: Row(
                        children: [
                          const Icon(Icons.check_circle, color: AppTheme.successColor),
                          const SizedBox(width: AppTheme.spacingS),
                          Expanded(
                            child: Text(
                              _successMessage!,
                              style: const TextStyle(color: AppTheme.successColor),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                  if (_errorMessage != null || _successMessage != null)
                    const SizedBox(height: AppTheme.spacingL),

                  // API Key
                  TextFormField(
                    controller: _apiKeyController,
                    decoration: InputDecoration(
                      labelText: 'API Key *',
                      hintText: 'Enter your LLM API key',
                      helperText: 'Required for ChatGPT analysis',
                      suffixIcon: Tooltip(
                        message: 'Your API key for the LLM service. Keep this secure and never share it.',
                        child: const Icon(Icons.info_outline, size: 20),
                      ),
                    ),
                    obscureText: _apiKeyController.text == '••••••••••••••••',
                    validator: (value) {
                      if (value == null || value.isEmpty || value == '••••••••••••••••') {
                        return 'Please enter an API key';
                      }
                      return null;
                    },
                    onChanged: (value) {
                      if (value != '••••••••••••••••') {
                        setState(() {});
                      }
                    },
                  ),
                  const SizedBox(height: AppTheme.spacingM),

                  // Base URL
                  TextFormField(
                    controller: _baseUrlController,
                    decoration: InputDecoration(
                      labelText: 'Base URL',
                      hintText: 'https://api.openai.com/v1',
                      helperText: 'API endpoint URL for the LLM service',
                      suffixIcon: Tooltip(
                        message: 'Base URL for the LLM API. Default: https://api.openai.com/v1',
                        child: const Icon(Icons.info_outline, size: 20),
                      ),
                    ),
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'Please enter a base URL';
                      }
                      final uri = Uri.tryParse(value);
                      if (uri == null || !uri.hasScheme) {
                        return 'Please enter a valid URL';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: AppTheme.spacingM),

                  // Model
                  TextFormField(
                    controller: _modelController,
                    decoration: InputDecoration(
                      labelText: 'Model',
                      hintText: 'gpt-4o-mini',
                      helperText: 'Model name to use for analysis',
                      suffixIcon: Tooltip(
                        message: 'Model identifier (e.g., gpt-4o-mini, gpt-4, etc.)',
                        child: const Icon(Icons.info_outline, size: 20),
                      ),
                    ),
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'Please enter a model name';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: AppTheme.spacingXL),

                  // Save button
                  ElevatedButton(
                    onPressed: _isLoading ? null : _saveConfig,
                    style: ElevatedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(
                        vertical: AppTheme.spacingM,
                      ),
                    ),
                    child: _isLoading
                        ? const SizedBox(
                            height: 20,
                            width: 20,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : const Text('Save Configuration'),
                  ),
                  if (_hasConfig) ...[
                    const SizedBox(height: AppTheme.spacingM),
                    OutlinedButton(
                      onPressed: _isLoading ? null : _deleteConfig,
                      style: OutlinedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(
                          vertical: AppTheme.spacingM,
                        ),
                        foregroundColor: AppTheme.errorColor,
                        side: const BorderSide(color: AppTheme.errorColor),
                      ),
                      child: const Text('Delete Configuration'),
                    ),
                  ],
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}

