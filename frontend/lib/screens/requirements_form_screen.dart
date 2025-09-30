import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:uuid/uuid.dart';
import '../theme/app_theme.dart';
import '../models/requirement.dart';
import '../bloc/requirements_bloc.dart';
import '../bloc/requirements_event.dart';
import '../bloc/requirements_state.dart';
import 'results_screen.dart';

class RequirementsFormScreen extends StatefulWidget {
  const RequirementsFormScreen({super.key});

  @override
  State<RequirementsFormScreen> createState() => _RequirementsFormScreenState();
}

class _RequirementsFormScreenState extends State<RequirementsFormScreen> {
  final List<Requirement> _requirements = [];

  void _addRequirement() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => _RequirementFormSheet(
        onSave: (requirement) {
          setState(() {
            _requirements.add(requirement);
          });
        },
      ),
    );
  }

  void _editRequirement(int index) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => _RequirementFormSheet(
        requirement: _requirements[index],
        onSave: (requirement) {
          setState(() {
            _requirements[index] = requirement;
          });
        },
      ),
    );
  }

  void _deleteRequirement(int index) {
    setState(() {
      _requirements.removeAt(index);
    });
  }

  void _submitRequirements() {
    if (_requirements.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please add at least one requirement'),
          backgroundColor: AppTheme.errorColor,
        ),
      );
      return;
    }

    context.read<RequirementsBloc>().add(
      CreateRequirementsEvent(_requirements),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Create Requirements'),
        actions: [
          if (_requirements.isNotEmpty)
            TextButton(
              onPressed: _submitRequirements,
              child: const Text('Analyze'),
            ),
        ],
      ),
      body: BlocConsumer<RequirementsBloc, RequirementsState>(
        listener: (context, state) {
          if (state is RequirementsCreated) {
            // Automatically analyze after creation
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

          if (isLoading) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const CircularProgressIndicator(),
                  const SizedBox(height: AppTheme.spacingM),
                  Text(
                    state is RequirementsLoading
                        ? (state.message ?? 'Processing...')
                        : 'Analyzing requirements...',
                    style: Theme.of(context).textTheme.bodyLarge,
                  ),
                ],
              ),
            );
          }

          return Column(
            children: [
              Expanded(
                child: _requirements.isEmpty
                    ? _EmptyState(onAdd: _addRequirement)
                    : ListView.builder(
                        padding: const EdgeInsets.all(AppTheme.spacingM),
                        itemCount: _requirements.length,
                        itemBuilder: (context, index) {
                          final requirement = _requirements[index];
                          return _RequirementCard(
                            requirement: requirement,
                            onEdit: () => _editRequirement(index),
                            onDelete: () => _deleteRequirement(index),
                          );
                        },
                      ),
              ),

              // Bottom action bar
              Container(
                padding: const EdgeInsets.all(AppTheme.spacingM),
                decoration: BoxDecoration(
                  color: AppTheme.surfaceColor,
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.05),
                      blurRadius: 10,
                      offset: const Offset(0, -2),
                    ),
                  ],
                ),
                child: SafeArea(
                  child: Row(
                    children: [
                      Expanded(
                        child: OutlinedButton.icon(
                          onPressed: _addRequirement,
                          icon: const Icon(Icons.add),
                          label: const Text('Add Requirement'),
                        ),
                      ),
                      if (_requirements.isNotEmpty) ...[
                        const SizedBox(width: AppTheme.spacingM),
                        Expanded(
                          child: ElevatedButton(
                            onPressed: _submitRequirements,
                            child: Text('Analyze (${_requirements.length})'),
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}

class _EmptyState extends StatelessWidget {
  final VoidCallback onAdd;

  const _EmptyState({required this.onAdd});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(AppTheme.spacingXXL),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.edit_note_outlined,
              size: 80,
              color: AppTheme.textTertiary.withOpacity(0.5),
            ),
            const SizedBox(height: AppTheme.spacingL),
            Text(
              'No Requirements Yet',
              style: Theme.of(context).textTheme.headlineMedium,
            ),
            const SizedBox(height: AppTheme.spacingS),
            Text(
              'Add requirements to get started with AI-powered prioritization',
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.bodyMedium,
            ),
            const SizedBox(height: AppTheme.spacingXL),
            ElevatedButton.icon(
              onPressed: onAdd,
              icon: const Icon(Icons.add),
              label: const Text('Add First Requirement'),
            ),
          ],
        ),
      ),
    );
  }
}

class _RequirementCard extends StatelessWidget {
  final Requirement requirement;
  final VoidCallback onEdit;
  final VoidCallback onDelete;

  const _RequirementCard({
    required this.requirement,
    required this.onEdit,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: AppTheme.spacingM),
      decoration: BoxDecoration(
        color: AppTheme.surfaceColor,
        borderRadius: BorderRadius.circular(AppTheme.radiusM),
        boxShadow: AppTheme.cardShadow,
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onEdit,
          borderRadius: BorderRadius.circular(AppTheme.radiusM),
          child: Padding(
            padding: const EdgeInsets.all(AppTheme.spacingM),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        requirement.title,
                        style: Theme.of(context).textTheme.titleMedium,
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.delete_outline),
                      color: AppTheme.errorColor,
                      onPressed: onDelete,
                    ),
                  ],
                ),
                const SizedBox(height: AppTheme.spacingS),
                Text(
                  requirement.description,
                  style: Theme.of(context).textTheme.bodyMedium,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
                if (requirement.category != null) ...[
                  const SizedBox(height: AppTheme.spacingS),
                  _CategoryChip(category: requirement.category!),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _CategoryChip extends StatelessWidget {
  final RequirementCategory category;

  const _CategoryChip({required this.category});

  String get label {
    switch (category) {
      case RequirementCategory.feature:
        return 'Feature';
      case RequirementCategory.enhancement:
        return 'Enhancement';
      case RequirementCategory.bugFix:
        return 'Bug Fix';
      case RequirementCategory.technical:
        return 'Technical';
      case RequirementCategory.compliance:
        return 'Compliance';
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppTheme.spacingS,
        vertical: AppTheme.spacingXS,
      ),
      decoration: BoxDecoration(
        color: AppTheme.primaryColor.withOpacity(0.1),
        borderRadius: BorderRadius.circular(AppTheme.radiusS),
      ),
      child: Text(
        label,
        style: Theme.of(context).textTheme.bodySmall?.copyWith(
          color: AppTheme.primaryColor,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }
}

class _RequirementFormSheet extends StatefulWidget {
  final Requirement? requirement;
  final Function(Requirement) onSave;

  const _RequirementFormSheet({this.requirement, required this.onSave});

  @override
  State<_RequirementFormSheet> createState() => _RequirementFormSheetState();
}

class _RequirementFormSheetState extends State<_RequirementFormSheet> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _titleController;
  late TextEditingController _descriptionController;
  late TextEditingController _businessValueController;
  late TextEditingController _costController;
  late TextEditingController _riskController;
  late TextEditingController _urgencyController;
  late TextEditingController _stakeholderValueController;
  RequirementCategory? _selectedCategory;

  @override
  void initState() {
    super.initState();
    _titleController = TextEditingController(text: widget.requirement?.title);
    _descriptionController = TextEditingController(
      text: widget.requirement?.description,
    );
    _businessValueController = TextEditingController(
      text: widget.requirement?.businessValue?.toString(),
    );
    _costController = TextEditingController(
      text: widget.requirement?.cost?.toString(),
    );
    _riskController = TextEditingController(
      text: widget.requirement?.risk?.toString(),
    );
    _urgencyController = TextEditingController(
      text: widget.requirement?.urgency?.toString(),
    );
    _stakeholderValueController = TextEditingController(
      text: widget.requirement?.stakeholderValue?.toString(),
    );
    _selectedCategory = widget.requirement?.category;
  }

  @override
  void dispose() {
    _titleController.dispose();
    _descriptionController.dispose();
    _businessValueController.dispose();
    _costController.dispose();
    _riskController.dispose();
    _urgencyController.dispose();
    _stakeholderValueController.dispose();
    super.dispose();
  }

  void _save() {
    if (_formKey.currentState!.validate()) {
      final requirement = Requirement(
        id: widget.requirement?.id ?? const Uuid().v4(),
        title: _titleController.text,
        description: _descriptionController.text,
        businessValue: double.tryParse(_businessValueController.text),
        cost: double.tryParse(_costController.text),
        risk: double.tryParse(_riskController.text),
        urgency: double.tryParse(_urgencyController.text),
        stakeholderValue: double.tryParse(_stakeholderValueController.text),
        category: _selectedCategory,
      );

      widget.onSave(requirement);
      Navigator.pop(context);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        color: AppTheme.surfaceColor,
        borderRadius: BorderRadius.vertical(
          top: Radius.circular(AppTheme.radiusL),
        ),
      ),
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(context).viewInsets.bottom,
      ),
      child: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(AppTheme.spacingL),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              mainAxisSize: MainAxisSize.min,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      widget.requirement == null
                          ? 'Add Requirement'
                          : 'Edit Requirement',
                      style: Theme.of(context).textTheme.headlineMedium,
                    ),
                    IconButton(
                      icon: const Icon(Icons.close),
                      onPressed: () => Navigator.pop(context),
                    ),
                  ],
                ),
                const SizedBox(height: AppTheme.spacingL),

                TextFormField(
                  controller: _titleController,
                  decoration: const InputDecoration(
                    labelText: 'Title *',
                    hintText: 'Enter requirement title',
                  ),
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Please enter a title';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: AppTheme.spacingM),

                TextFormField(
                  controller: _descriptionController,
                  decoration: const InputDecoration(
                    labelText: 'Description *',
                    hintText: 'Enter detailed description',
                    alignLabelWithHint: true,
                  ),
                  maxLines: 4,
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Please enter a description';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: AppTheme.spacingM),

                DropdownButtonFormField<RequirementCategory>(
                  value: _selectedCategory,
                  decoration: const InputDecoration(labelText: 'Category'),
                  items: RequirementCategory.values.map((category) {
                    String label;
                    switch (category) {
                      case RequirementCategory.feature:
                        label = 'Feature';
                        break;
                      case RequirementCategory.enhancement:
                        label = 'Enhancement';
                        break;
                      case RequirementCategory.bugFix:
                        label = 'Bug Fix';
                        break;
                      case RequirementCategory.technical:
                        label = 'Technical';
                        break;
                      case RequirementCategory.compliance:
                        label = 'Compliance';
                        break;
                    }
                    return DropdownMenuItem(
                      value: category,
                      child: Text(label),
                    );
                  }).toList(),
                  onChanged: (value) {
                    setState(() {
                      _selectedCategory = value;
                    });
                  },
                ),
                const SizedBox(height: AppTheme.spacingL),

                Text(
                  'Scoring Criteria (1-10)',
                  style: Theme.of(context).textTheme.titleMedium,
                ),
                const SizedBox(height: AppTheme.spacingM),

                Row(
                  children: [
                    Expanded(
                      child: TextFormField(
                        controller: _businessValueController,
                        decoration: const InputDecoration(
                          labelText: 'Business Value',
                        ),
                        keyboardType: TextInputType.number,
                      ),
                    ),
                    const SizedBox(width: AppTheme.spacingM),
                    Expanded(
                      child: TextFormField(
                        controller: _costController,
                        decoration: const InputDecoration(labelText: 'Cost'),
                        keyboardType: TextInputType.number,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: AppTheme.spacingM),

                Row(
                  children: [
                    Expanded(
                      child: TextFormField(
                        controller: _riskController,
                        decoration: const InputDecoration(labelText: 'Risk'),
                        keyboardType: TextInputType.number,
                      ),
                    ),
                    const SizedBox(width: AppTheme.spacingM),
                    Expanded(
                      child: TextFormField(
                        controller: _urgencyController,
                        decoration: const InputDecoration(labelText: 'Urgency'),
                        keyboardType: TextInputType.number,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: AppTheme.spacingM),

                TextFormField(
                  controller: _stakeholderValueController,
                  decoration: const InputDecoration(
                    labelText: 'Stakeholder Value',
                  ),
                  keyboardType: TextInputType.number,
                ),
                const SizedBox(height: AppTheme.spacingXL),

                ElevatedButton(
                  onPressed: _save,
                  child: const Text('Save Requirement'),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
