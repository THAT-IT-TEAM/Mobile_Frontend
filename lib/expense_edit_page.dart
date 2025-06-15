import 'package:flutter/material.dart';
import 'package:it_team_app/ocr_service.dart';

class ExpenseEditPage extends StatefulWidget {
  final String expenseId;
  final Map<String, dynamic>? initialData;

  const ExpenseEditPage({
    super.key,
    required this.expenseId,
    this.initialData,
  });

  @override
  State<ExpenseEditPage> createState() => _ExpenseEditPageState();
}

class _ExpenseEditPageState extends State<ExpenseEditPage> {
  // Fields that can be edited
  final List<String> editableFields = [
    'amount',
    'currency',
    'vendor_name',
    'category',
    'description',
    'document_id',
    'payment_method',
    'tax_amount',
  ];

  // Controllers for editable fields
  final Map<String, TextEditingController> _controllers = {
    'amount': TextEditingController(),
    'currency': TextEditingController(),
    'vendor_name': TextEditingController(),
    'category': TextEditingController(),
    'description': TextEditingController(),
    'document_id': TextEditingController(),
    'payment_method': TextEditingController(),
    'tax_amount': TextEditingController(),
  };

  // Store all expense data
  Map<String, dynamic> _expenseData = {};

  bool _isSaving = false;
  String? _error;
  bool _hasChanges = false;

  @override
  void initState() {
    super.initState();    if (widget.initialData != null) {
      _expenseData = Map<String, dynamic>.from(widget.initialData!);
      _controllers.forEach((field, controller) {
        controller.text = (_expenseData[field] ?? '').toString();
      });
    } else {
      _loadExpenseDetails();
    }

    // Listen for changes to enable/disable save button
    _controllers.forEach((field, controller) {
      controller.addListener(() {
        if (!_hasChanges) {
          setState(() => _hasChanges = true);
        }
      });
    });
  }
  Future<void> _loadExpenseDetails() async {
    try {
      final details = await OcrService().getExpenseDetails(widget.expenseId);
      setState(() {
        _expenseData = Map<String, dynamic>.from(details);
        // Update all controllers with the fetched data
        editableFields.forEach((field) {
          _controllers[field]?.text = (details[field] ?? '').toString();
        });
      });
    } catch (e) {
      setState(() => _error = e.toString());
    }
  }

  Future<void> _saveChanges() async {
    if (!_hasChanges) return;

    setState(() {
      _isSaving = true;
      _error = null;
    });

    try {
      final updates = _controllers.map(
        (field, controller) => MapEntry(field, controller.text),
      );

      await OcrService().updateExpenseDetails(widget.expenseId, updates);
      
      if (mounted) {
        Navigator.pop(context, true); // Return true to indicate successful save
      }
    } catch (e) {
      setState(() => _error = e.toString());
    } finally {
      if (mounted) {
        setState(() => _isSaving = false);
      }
    }
  }

  @override
  void dispose() {
    _controllers.values.forEach((controller) => controller.dispose());
    super.dispose();
  }
  String _formatFieldLabel(String field) {
    // Convert snake_case to Title Case
    return field
        .split('_')
        .map((word) => word.substring(0, 1).toUpperCase() + word.substring(1))
        .join(' ');
  }

  TextInputType _getKeyboardType(String field) {
    switch (field) {
      case 'amount':
      case 'tax_amount':
        return TextInputType.number;
      case 'description':
        return TextInputType.multiline;
      default:
        return TextInputType.text;
    }
  }
  // Method removed as it's now handled directly in build

  @override
  Widget build(BuildContext context) {
    return WillPopScope(
      onWillPop: () async {
        if (!_hasChanges) return true;
        
        final result = await showDialog<bool>(
          context: context,
          builder: (context) => AlertDialog(
            title: const Text('Unsaved Changes'),
            content: const Text('Do you want to discard your changes?'),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context, false),
                child: const Text('Cancel'),
              ),
              TextButton(
                onPressed: () => Navigator.pop(context, true),
                child: const Text('Discard'),
              ),
            ],
          ),
        );
        
        return result ?? false;
      },
      child: Scaffold(
        backgroundColor: const Color(0xFF121212),
        appBar: AppBar(
          title: const Text('Edit Expense'),
          backgroundColor: Colors.black,
          elevation: 4,
          foregroundColor: Colors.white,
          actions: [
            if (_hasChanges)
              IconButton(
                icon: _isSaving
                    ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                        ),
                      )
                    : const Icon(Icons.save),
                onPressed: _isSaving ? null : _saveChanges,
                tooltip: 'Save Changes',
              ),
          ],
        ),
        body: _expenseData.isEmpty
            ? const Center(
                child: CircularProgressIndicator(),
              )
            : SingleChildScrollView(
                padding: const EdgeInsets.all(24),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    if (_error != null)
                      Container(
                        margin: const EdgeInsets.only(bottom: 24),
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: Colors.red.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: Colors.red.withOpacity(0.3)),
                        ),
                        child: Text(
                          _error!,
                          style: const TextStyle(color: Colors.red),
                        ),
                      ),
                    // Show editable fields in order
                    ...editableFields.map((field) => Padding(
                          padding: const EdgeInsets.only(bottom: 16),
                          child: TextField(
                            controller: _controllers[field],
                            style: const TextStyle(color: Colors.white),
                            keyboardType: _getKeyboardType(field),
                            maxLines: field == 'description' ? 3 : 1,
                            decoration: InputDecoration(
                              labelText: _formatFieldLabel(field),
                              labelStyle: const TextStyle(color: Colors.white70),
                              enabledBorder: const UnderlineInputBorder(
                                borderSide: BorderSide(color: Colors.white30),
                              ),
                              focusedBorder: const UnderlineInputBorder(
                                borderSide: BorderSide(color: Colors.white),
                              ),
                            ),
                          ),
                        )),
                  ],
                ),
              ),
      ),
    );
  }
}
