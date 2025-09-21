import 'package:flutter/material.dart';

class ExpenseForm extends StatefulWidget {
  @override
  State<ExpenseForm> createState() => ExpenseFormState();
}

class ExpenseFormState extends State<ExpenseForm> {
  final _formKey = GlobalKey<FormState>();
  final TextEditingController _amountController = TextEditingController();
  final TextEditingController _descController = TextEditingController();
  String? _category;
  DateTime? _selectedDate;

  final List<String> _categories = [
    'Food', 'Transport', 'Shopping', 'Bills', 'Other'
  ];

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          Container(
            width: double.infinity,
            decoration: BoxDecoration(
              color: Color(0xFFfdeaea), // rojo muy claro
              borderRadius: BorderRadius.circular(12),
            ),
            padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 12),
            margin: const EdgeInsets.only(top: 8.0, bottom: 4.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: const [
                Text('Add Expense', style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold)),
                SizedBox(height: 4),
                Text('Register a new expense', style: TextStyle(fontSize: 15, color: Colors.grey)),
              ],
            ),
          ),
          const SizedBox(height: 10),
          // Card with form
          Card(
            elevation: 2,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
            child: Padding(
              padding: const EdgeInsets.all(18.0),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: const [
                        Icon(Icons.money_off, color: Color(0xFFfa2e38), size: 28),
                        SizedBox(width: 8),
                        Text('Expense Details', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                      ],
                    ),
                    const SizedBox(height: 18),
                    TextFormField(
                      controller: _amountController,
                      keyboardType: TextInputType.number,
                      decoration: const InputDecoration(
                        labelText: 'Amount *',
                        prefixText: "\$",
                        border: OutlineInputBorder(),
                        filled: true,
                        fillColor: Color.fromARGB(124, 205, 199, 202), // gris claro
                      ),
                      validator: (value) {
                        if (value == null || value.isEmpty) return 'Enter the amount';
                        if (double.tryParse(value) == null) return 'Invalid amount';
                        return null;
                      },
                    ),
                    const SizedBox(height: 15),
                    TextFormField(
                      controller: _descController,
                      decoration: const InputDecoration(
                        labelText: 'Description',
                        border: OutlineInputBorder(),
                        filled: true,
                        fillColor: Color.fromARGB(124, 205, 199, 202), // gris claro
                      ),
                      // validator removido, ya no es obligatorio
                    ),
                    const SizedBox(height: 15),
                    DropdownButtonFormField<String>(
                      value: _category,
                      decoration: const InputDecoration(
                        labelText: 'Category *',
                        border: OutlineInputBorder(),
                        filled: true,
                        fillColor: Color.fromARGB(124, 205, 199, 202), // gris claro
                      ),
                      items: _categories.map((cat) => DropdownMenuItem(value: cat, child: Text(cat))).toList(),
                      onChanged: (val) => setState(() => _category = val),
                      validator: (value) => value == null ? 'Select a category' : null,
                    ),
                    const SizedBox(height: 15),
                    InkWell(
                      onTap: () async {
                        final picked = await showDatePicker(
                          context: context,
                          initialDate: DateTime.now(),
                          firstDate: DateTime(2000),
                          lastDate: DateTime(2100),
                        );
                        if (picked != null) setState(() => _selectedDate = picked);
                      },
                      child: InputDecorator(
                        decoration: const InputDecoration(
                          labelText: 'Date *',
                          border: OutlineInputBorder(),
                          filled: true,
                          fillColor: Color.fromARGB(124, 205, 199, 202), // gris claro
                        ),
                        child: Text(_selectedDate == null ? 'Select a date' : '${_selectedDate!.month.toString().padLeft(2, '0')}/${_selectedDate!.day.toString().padLeft(2, '0')}/${_selectedDate!.year}'),
                      ),
                    ),
                    const SizedBox(height: 15),
                    const SizedBox(height: 25),
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton.icon(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFFfdeaea), // rojo claro
                          foregroundColor: Colors.black,
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                        ),
                        icon: const Icon(Icons.save, color: Color(0xFFfa2e38)),
                        label: const Text('Save Expense', style: TextStyle(fontSize: 16)),
                        onPressed: () {
                          if (_formKey.currentState!.validate() && _selectedDate != null) {
                            // Save the expense in your database or state
                            Navigator.pop(context);
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(content: Text('Expense saved')),
                            );
                          } else if (_selectedDate == null) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(content: Text('Select a date')),
                            );
                          }
                        },
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
          const SizedBox(height: 10),
        ],
      ),
    );
  }
}
