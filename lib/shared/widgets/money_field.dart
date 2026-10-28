import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

/// Isian rupiah: hanya digit, dengan awalan "Rp".
///
/// Memakai [TextFormField] supaya bisa ikut divalidasi oleh [Form] induknya.
class MoneyField extends StatelessWidget {
  const MoneyField({
    required this.controller,
    required this.label,
    this.onChanged,
    this.autofocus = false,
    this.errorText,
    this.validator,
    super.key,
  });

  final TextEditingController controller;
  final String label;
  final ValueChanged<String>? onChanged;
  final bool autofocus;
  final String? errorText;
  final FormFieldValidator<String>? validator;

  @override
  Widget build(BuildContext context) {
    return TextFormField(
      controller: controller,
      autofocus: autofocus,
      keyboardType: TextInputType.number,
      inputFormatters: <TextInputFormatter>[
        FilteringTextInputFormatter.digitsOnly,
      ],
      decoration: InputDecoration(
        labelText: label,
        prefixText: 'Rp ',
        errorText: errorText,
      ),
      validator: validator,
      onChanged: onChanged,
    );
  }
}

/// Isian jumlah bahan: digit dengan satu koma atau titik desimal.
class QtyField extends StatelessWidget {
  const QtyField({
    required this.controller,
    required this.label,
    this.onChanged,
    this.validator,
    super.key,
  });

  final TextEditingController controller;
  final String label;
  final ValueChanged<String>? onChanged;
  final FormFieldValidator<String>? validator;

  @override
  Widget build(BuildContext context) {
    return TextFormField(
      controller: controller,
      keyboardType: const TextInputType.numberWithOptions(decimal: true),
      inputFormatters: <TextInputFormatter>[
        FilteringTextInputFormatter.allow(RegExp(r'[0-9.,]')),
      ],
      decoration: InputDecoration(labelText: label),
      validator: validator,
      onChanged: onChanged,
    );
  }
}