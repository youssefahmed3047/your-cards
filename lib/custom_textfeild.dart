import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

class CustomTextfeild extends StatelessWidget {
  final String label;
  final TextEditingController controller ;
  const CustomTextfeild({super.key, required this.label, required this.controller});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(bottom: 10.h),
      child: TextField(
        controller: controller,
        style: TextStyle(color: Theme.of(context).colorScheme.primary),
        decoration: InputDecoration(
          labelText: label,
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(20.r),
            borderSide: BorderSide(
              color: Theme.of(context).colorScheme.secondary,
              width: 1.w,
            ),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(50.r),
            borderSide: BorderSide(
              color: Theme.of(context).colorScheme.primary,
              width: 3.w,
            ),
          ),
          filled: true,
          fillColor: Theme.of(context).colorScheme.primary.withValues(alpha: 0.4),
        ),
      ),
    );
  }
}
