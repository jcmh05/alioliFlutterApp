import 'package:flutter/material.dart';

class CustomTextField extends StatelessWidget {
  final String? hintText;
  final String? labelText;
  final TextEditingController? controller;
  final TextInputType? keyboardType;
  final Widget? suffixIcon;
  final String? Function(String?)? validator;
  final int? maxLines;
  final bool? obscureText;
  final ValueChanged<String>? onChanged; // Nuevo campo

  const CustomTextField({
    Key? key,
    this.hintText,
    this.labelText,
    this.controller,
    this.keyboardType,
    this.suffixIcon,
    this.validator,
    this.maxLines,
    this.obscureText,
    this.onChanged, // Nuevo campo
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final bool isDarkMode = Theme.of(context).brightness == Brightness.dark;

    // Colores para modo oscuro y modo claro
    final borderColor = isDarkMode ? Colors.grey[600] : Colors.grey[300];
    final focusedBorderColor = isDarkMode ? Colors.white : Theme.of(context).primaryColor;

    return TextFormField(
      decoration: InputDecoration(
        fillColor: Theme.of(context).brightness == Brightness.dark ? Color(0xFF1C1C1C) : Colors.white,
        filled: true,
        border: OutlineInputBorder(
          borderSide: BorderSide(color: borderColor ?? Colors.grey),
          borderRadius: BorderRadius.circular(8.0),
        ),
        focusedBorder: OutlineInputBorder(
          borderSide: BorderSide(color: focusedBorderColor),
          borderRadius: BorderRadius.circular(8.0),
        ),
        hintText: hintText,
        labelText: labelText,
        floatingLabelBehavior: labelText != null
            ? FloatingLabelBehavior.always // Si hay un labelText se muestra siempre flotando
            : FloatingLabelBehavior.never, // Si no hay labelText no se muestra nunca
        suffixIcon: suffixIcon,
      ),
      keyboardType: keyboardType,
      validator: validator,
      controller: controller,
      style: TextStyle(color: isDarkMode ? Colors.white : Colors.black),
      maxLines: maxLines!=null ? maxLines : 1,
      obscureText: obscureText!=null ? obscureText! : false,
      onChanged: onChanged, // Nuevo campo
    );
  }
}