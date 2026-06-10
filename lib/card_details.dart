import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:hive_flutter/adapters.dart';

class CardDetails extends StatelessWidget {
  final dynamic cardKey;
  final Map cardData;

  const CardDetails({super.key, required this.cardKey, required this.cardData});

  static const _imageExtensions = ['jpg', 'jpeg', 'png', 'gif', 'bmp', 'webp'];

  bool _isImage(String path) {
    final ext = path.split('.').last.toLowerCase();
    return _imageExtensions.contains(ext);
  }

  @override
  Widget build(BuildContext context) {
    final name = cardData['name'] ?? 'بدون اسم';
    final values = (cardData['values'] as List?)?.cast<Map>() ?? [];
    final files = (cardData['files'] as List?)?.cast<String>() ?? [];

    return Scaffold(
      appBar: AppBar(
        centerTitle: true,
        title: Text(name),
        actions: [
          IconButton(
            icon: const Icon(Icons.delete),
            tooltip: 'حذف الكارت',
            onPressed: () => _deleteCard(context),
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: EdgeInsets.symmetric(horizontal: 20.w, vertical: 15.h),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            // Values section
            if (values.isNotEmpty) ...[
              Text(
                'بيانات الكارت',
                style: TextStyle(
                  color: Theme.of(context).colorScheme.onSurface,
                  fontSize: 24.sp,
                  fontWeight: FontWeight.bold,
                ),
              ),

              SizedBox(height: 15.h),

              ...values.map((entry) {
                final key = entry['key'] ?? '';
                final value = entry['value'] ?? '';

                return Padding(
                  padding: EdgeInsets.only(bottom: 14.h),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      if (key.isNotEmpty)
                        Padding(
                          padding: EdgeInsets.only(bottom: 6.h, right: 4.w),
                          child: Text(
                            key,
                            style: TextStyle(
                              fontSize: 16.sp,
                              fontWeight: FontWeight.w600,
                              color: Theme.of(context).colorScheme.primary,
                            ),
                          ),
                        ),
                      Container(
                        width: double.infinity,
                        padding: EdgeInsets.symmetric(
                          horizontal: 14.w,
                          vertical: 14.h,
                        ),
                        decoration: BoxDecoration(
                          color: Theme.of(context)
                              .colorScheme
                              .surfaceContainerHighest,
                          borderRadius: BorderRadius.circular(14.r),
                          border: Border.all(
                            color: Theme.of(context)
                                .colorScheme
                                .outline
                                .withValues(alpha: 0.3),
                          ),
                        ),
                        child: Row(
                          children: [
                            // Copy button
                            InkWell(
                              borderRadius: BorderRadius.circular(8.r),
                              onTap: () {
                                Clipboard.setData(ClipboardData(text: value));
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(
                                    content: Text('تم نسخ "$key"'),
                                    duration: const Duration(seconds: 1),
                                  ),
                                );
                              },
                              child: Container(
                                padding: EdgeInsets.all(8.r),
                                decoration: BoxDecoration(
                                  color: Theme.of(context)
                                      .colorScheme
                                      .primaryContainer,
                                  borderRadius: BorderRadius.circular(8.r),
                                ),
                                child: Icon(
                                  Icons.copy,
                                  size: 20.sp,
                                  color: Theme.of(context).colorScheme.primary,
                                ),
                              ),
                            ),

                            SizedBox(width: 12.w),

                            // Value text
                            Expanded(
                              child: Text(
                                value,
                                textAlign: TextAlign.right,
                                textDirection: TextDirection.rtl,
                                style: TextStyle(
                                  fontSize: 16.sp,
                                  color: Theme.of(context)
                                      .colorScheme
                                      .onSurface,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                );
              }),
            ],

            // Files section
            if (files.isNotEmpty) ...[
              SizedBox(height: 10.h),

              Text(
                'الملفات المرفقة',
                style: TextStyle(
                  color: Theme.of(context).colorScheme.onSurface,
                  fontSize: 24.sp,
                  fontWeight: FontWeight.bold,
                ),
              ),

              SizedBox(height: 15.h),

              ...files.asMap().entries.map((entry) {
                final filePath = entry.value;
                final file = File(filePath);
                final fileName = filePath.split('/').last.split('\\').last;
                final isImage = _isImage(filePath);
                final fileExists = file.existsSync();

                return Padding(
                  padding: EdgeInsets.only(bottom: 12.h),
                  child: isImage && fileExists
                      ? _buildImageCard(context, file, fileName)
                      : _buildFileCard(context, fileName, fileExists),
                );
              }),
            ],

            // Empty state
            if (values.isEmpty && files.isEmpty)
              Center(
                child: Padding(
                  padding: EdgeInsets.only(top: 100.h),
                  child: Column(
                    children: [
                      Icon(
                        Icons.info_outline,
                        size: 60.sp,
                        color: Theme.of(context)
                            .colorScheme
                            .onSurface
                            .withValues(alpha: 0.3),
                      ),
                      SizedBox(height: 12.h),
                      Text(
                        'الكارت ده فاضي',
                        style: TextStyle(
                          fontSize: 18.sp,
                          color: Theme.of(context)
                              .colorScheme
                              .onSurface
                              .withValues(alpha: 0.5),
                        ),
                      ),
                    ],
                  ),
                ),
              ),

            SizedBox(height: 20.h),
          ],
        ),
      ),
    );
  }

  Widget _buildImageCard(BuildContext context, File file, String fileName) {
    return GestureDetector(
      onTap: () => _openImageViewer(context, file, fileName),
      child: Container(
        width: double.infinity,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(16.r),
          border: Border.all(
            color: Theme.of(context).colorScheme.outline.withValues(alpha: 0.3),
          ),
        ),
        child: Column(
          children: [
            // Image preview
            ClipRRect(
              borderRadius: BorderRadius.vertical(top: Radius.circular(15.r)),
              child: Image.file(
                file,
                fit: BoxFit.cover,
                width: double.infinity,
                height: 200.h,
              ),
            ),

            // Bottom bar with file name and actions
            Container(
              padding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 10.h),
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.surfaceContainerHighest,
                borderRadius:
                    BorderRadius.vertical(bottom: Radius.circular(15.r)),
              ),
              child: Row(
                children: [
                  // View full screen button
                  InkWell(
                    borderRadius: BorderRadius.circular(8.r),
                    onTap: () => _openImageViewer(context, file, fileName),
                    child: Container(
                      padding: EdgeInsets.all(8.r),
                      decoration: BoxDecoration(
                        color: Theme.of(context).colorScheme.primaryContainer,
                        borderRadius: BorderRadius.circular(8.r),
                      ),
                      child: Icon(
                        Icons.fullscreen,
                        size: 20.sp,
                        color: Theme.of(context).colorScheme.primary,
                      ),
                    ),
                  ),

                  SizedBox(width: 8.w),

                  Expanded(
                    child: Text(
                      fileName,
                      textAlign: TextAlign.right,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        fontSize: 14.sp,
                        color: Theme.of(context).colorScheme.onSurface,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFileCard(BuildContext context, String fileName, bool fileExists) {
    return Container(
      width: double.infinity,
      padding: EdgeInsets.symmetric(horizontal: 14.w, vertical: 14.h),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(14.r),
        border: Border.all(
          color: Theme.of(context).colorScheme.outline.withValues(alpha: 0.3),
        ),
      ),
      child: Row(
        children: [
          // Status icon
          Container(
            padding: EdgeInsets.all(8.r),
            decoration: BoxDecoration(
              color: fileExists
                  ? Theme.of(context).colorScheme.primaryContainer
                  : Colors.red.withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(8.r),
            ),
            child: Icon(
              fileExists ? Icons.insert_drive_file : Icons.error_outline,
              size: 24.sp,
              color: fileExists
                  ? Theme.of(context).colorScheme.primary
                  : Colors.red,
            ),
          ),

          SizedBox(width: 12.w),

          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(
                  fileName,
                  textAlign: TextAlign.right,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontSize: 15.sp,
                    color: Theme.of(context).colorScheme.onSurface,
                  ),
                ),
                if (!fileExists)
                  Text(
                    'الملف مش موجود',
                    style: TextStyle(
                      fontSize: 12.sp,
                      color: Colors.red,
                    ),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  void _openImageViewer(BuildContext context, File file, String fileName) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => _FullScreenImage(file: file, fileName: fileName),
      ),
    );
  }

  Future<void> _deleteCard(BuildContext context) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('حذف الكارت'),
        content: const Text('هل أنت متأكد أنك تريد حذف هذا الكارت؟'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('إلغاء'),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text('حذف'),
          ),
        ],
      ),
    );

    if (confirmed != true) return;

    final box = Hive.box('Cards');
    await box.delete(cardKey);

    if (context.mounted) {
      Navigator.of(context).pop();
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('تم حذف الكارت')),
      );
    }
  }
}

class _FullScreenImage extends StatelessWidget {
  final File file;
  final String fileName;

  const _FullScreenImage({required this.file, required this.fileName});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.black,
        foregroundColor: Colors.white,
        centerTitle: true,
        title: Text(
          fileName,
          style: TextStyle(fontSize: 16.sp),
        ),
      ),
      body: Center(
        child: InteractiveViewer(
          minScale: 0.5,
          maxScale: 4.0,
          child: Image.file(
            file,
            fit: BoxFit.contain,
            width: double.infinity,
          ),
        ),
      ),
    );
  }
}
