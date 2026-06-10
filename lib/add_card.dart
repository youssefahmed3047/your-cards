import 'dart:io';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:image_picker/image_picker.dart';
import 'package:krotak/custom_textfeild.dart';

class AddCard extends StatefulWidget {
  const AddCard({super.key});

  @override
  State<AddCard> createState() => _AddCardState();
}

class _AddCardState extends State<AddCard> {
  final TextEditingController nameController = TextEditingController();

  List<TextEditingController> keyControllers = [];
  List<TextEditingController> valueControllers = [];

  // Multiple files support (up to 5)
  List<File> selectedFiles = [];
  List<String> selectedFileNames = [];
  List<bool> fileIsImage = [];

  static const int maxFiles = 5;
  static const _imageExtensions = ['jpg', 'jpeg', 'png', 'gif', 'bmp', 'webp'];

  @override
  void initState() {
    super.initState();
    keyControllers.add(TextEditingController());
    valueControllers.add(TextEditingController());
  }

  bool _isImage(String fileName) {
    final ext = fileName.split('.').last.toLowerCase();
    return _imageExtensions.contains(ext);
  }

  void showPickOptions() {
    if (selectedFiles.length >= maxFiles) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('لا يمكن إضافة أكثر من 5 ملفات')),
      );
      return;
    }

    showModalBottomSheet(
      context: context,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20.r)),
      ),
      builder: (context) => Padding(
        padding: EdgeInsets.symmetric(vertical: 20.h, horizontal: 16.w),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 40.w,
              height: 4.h,
              decoration: BoxDecoration(
                color: Colors.grey[400],
                borderRadius: BorderRadius.circular(10.r),
              ),
            ),
            SizedBox(height: 20.h),
            Text(
              'اختر مصدر الملف',
              style: TextStyle(
                fontSize: 20.sp,
                fontWeight: FontWeight.bold,
              ),
            ),
            SizedBox(height: 8.h),
            Text(
              '${selectedFiles.length}/$maxFiles ملفات مضافة',
              style: TextStyle(
                fontSize: 14.sp,
                color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.6),
              ),
            ),
            SizedBox(height: 20.h),
            ListTile(
              leading: CircleAvatar(
                backgroundColor: Theme.of(context).colorScheme.primaryContainer,
                child: Icon(
                  Icons.camera_alt,
                  color: Theme.of(context).colorScheme.primary,
                ),
              ),
              title: const Text('الكاميرا'),
              subtitle: const Text('التقط صورة بالكاميرا'),
              onTap: () {
                Navigator.pop(context);
                pickFromCamera();
              },
            ),
            Divider(height: 1.h),
            ListTile(
              leading: CircleAvatar(
                backgroundColor: Theme.of(context).colorScheme.primaryContainer,
                child: Icon(
                  Icons.folder_open,
                  color: Theme.of(context).colorScheme.primary,
                ),
              ),
              title: const Text('الملفات'),
              subtitle: const Text('اختر ملف من الجهاز'),
              onTap: () {
                Navigator.pop(context);
                pickFromFiles();
              },
            ),
            SizedBox(height: 10.h),
          ],
        ),
      ),
    );
  }

  Future<void> pickFromCamera() async {
    try {
      final picker = ImagePicker();
      final image = await picker.pickImage(source: ImageSource.camera);

      if (image != null) {
        setState(() {
          selectedFileNames.add(image.name);
          selectedFiles.add(File(image.path));
          fileIsImage.add(true);
        });
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('حدث خطأ أثناء فتح الكاميرا: $e')),
        );
      }
    }
  }

  Future<void> pickFromFiles() async {
    try {
      final result = await FilePicker.pickFiles(
        type: FileType.any,
        allowMultiple: false,
      );

      if (result != null && result.files.isNotEmpty) {
        final file = result.files.first;
        if (file.path != null) {
          setState(() {
            selectedFileNames.add(file.name);
            selectedFiles.add(File(file.path!));
            fileIsImage.add(_isImage(file.name));
          });
        } else {
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('لم يتم العثور على مسار الملف')),
            );
          }
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('حدث خطأ أثناء اختيار الملف: $e')),
        );
      }
    }
  }

  void removeFile(int index) {
    setState(() {
      selectedFiles.removeAt(index);
      selectedFileNames.removeAt(index);
      fileIsImage.removeAt(index);
    });
  }

  void addValue() {
    if (keyControllers.length >= 5) return;

    setState(() {
      keyControllers.add(TextEditingController());
      valueControllers.add(TextEditingController());
    });
  }

  void removeValue(int index) {
    keyControllers[index].dispose();
    valueControllers[index].dispose();

    setState(() {
      keyControllers.removeAt(index);
      valueControllers.removeAt(index);
    });
  }

  Future<void> saveCard() async {
    final name = nameController.text.trim();
    if (name.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('من فضلك ادخل اسم الكارت')),
      );
      return;
    }

    // Collect key-value pairs
    final List<Map<String, String>> values = [];
    for (int i = 0; i < keyControllers.length; i++) {
      final key = keyControllers[i].text.trim();
      final value = valueControllers[i].text.trim();
      if (key.isNotEmpty || value.isNotEmpty) {
        values.add({'key': key, 'value': value});
      }
    }

    // Collect file paths
    final List<String> filePaths = selectedFiles.map((f) => f.path).toList();

    // Save to Hive
    final box = Hive.box('Cards');
    await box.add({
      'name': name,
      'values': values,
      'files': filePaths,
      'createdAt': DateTime.now().toIso8601String(),
    });

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('تم حفظ الكارت بنجاح ✓')),
      );
      Navigator.pop(context);
    }
  }

  @override
  void dispose() {
    nameController.dispose();

    for (final controller in keyControllers) {
      controller.dispose();
    }

    for (final controller in valueControllers) {
      controller.dispose();
    }

    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => FocusManager.instance.primaryFocus?.unfocus(),
      child: Scaffold(
        appBar: AppBar(
          centerTitle: true,
          title: const Text('اضف بيانات الكارت الجديد'),
        ),
        body: SingleChildScrollView(
          padding: EdgeInsets.symmetric(horizontal: 20.w, vertical: 15.h),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              CustomTextfeild(
                label: 'ادخل اسم الكارت',
                controller: nameController,
              ),

              SizedBox(height: 20.h),

              Text(
                'قيم الكارت',
                style: TextStyle(
                  color: Theme.of(context).colorScheme.onSurface,
                  fontSize: 30.sp,
                  fontWeight: FontWeight.bold,
                ),
              ),

              SizedBox(height: 15.h),

              ...List.generate(
                keyControllers.length,
                (index) => Padding(
                  padding: EdgeInsets.only(bottom: 12.h),
                  child: Row(
                    children: [
                      Expanded(
                        child: CustomTextfeild(
                          label: 'اسم القيمه',
                          controller: keyControllers[index],
                        ),
                      ),

                      SizedBox(width: 10.w),

                      Expanded(
                        child: CustomTextfeild(
                          label: 'القيمه نفسها',
                          controller: valueControllers[index],
                        ),
                      ),

                      IconButton(
                        onPressed: () => removeValue(index),
                        icon: const Icon(
                          Icons.remove_circle,
                          color: Colors.red,
                        ),
                      ),
                    ],
                  ),
                ),
              ),

              SizedBox(height: 10.h),

              if (keyControllers.length < 5)
                SizedBox(
                  width: double.infinity,
                  height: 55.h,
                  child: ElevatedButton.icon(
                    onPressed: addValue,
                    icon: const Icon(Icons.add),
                    label: const Text('إضافة قيمة جديدة'),
                  ),
                ),

              SizedBox(height: 20.h),

              // Files section title
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    '${selectedFiles.length}/$maxFiles',
                    style: TextStyle(
                      fontSize: 16.sp,
                      color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.6),
                    ),
                  ),
                  Text(
                    'الملفات المرفقة',
                    style: TextStyle(
                      color: Theme.of(context).colorScheme.onSurface,
                      fontSize: 22.sp,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),

              SizedBox(height: 12.h),

              // Files display
              if (selectedFiles.isNotEmpty)
                SizedBox(
                  height: 140.h,
                  child: ListView.separated(
                    scrollDirection: Axis.horizontal,
                    reverse: true,
                    itemCount: selectedFiles.length + (selectedFiles.length < maxFiles ? 1 : 0),
                    separatorBuilder: (_, __) => SizedBox(width: 10.w),
                    itemBuilder: (context, index) {
                      // Add button at the end
                      if (index == selectedFiles.length) {
                        return _buildAddFileButton();
                      }
                      return _buildFileCard(index);
                    },
                  ),
                )
              else
                // Empty state - show add button
                InkWell(
                  borderRadius: BorderRadius.circular(20.r),
                  onTap: showPickOptions,
                  child: Container(
                    width: double.infinity,
                    height: 140.h,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(20.r),
                      border: Border.all(
                        color: Theme.of(context).colorScheme.primary,
                        width: 2.w,
                      ),
                    ),
                    child: Center(
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            Icons.add_circle_outline,
                            size: 50.sp,
                            color: Theme.of(context).colorScheme.primary,
                          ),
                          SizedBox(height: 8.h),
                          Text(
                            'أضف ملفات مع الكارت',
                            style: TextStyle(
                              fontSize: 16.sp,
                              fontWeight: FontWeight.w600,
                              color: Theme.of(context).colorScheme.onSurface,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),

              SizedBox(height: 30.h),

              // Save button
              SizedBox(
                width: double.infinity,
                height: 55.h,
                child: ElevatedButton.icon(
                  onPressed: saveCard,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Theme.of(context).colorScheme.primary,
                    foregroundColor: Theme.of(context).colorScheme.onPrimary,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16.r),
                    ),
                  ),
                  icon: const Icon(Icons.save),
                  label: Text(
                    'حفظ الكارت',
                    style: TextStyle(
                      fontSize: 18.sp,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),

              SizedBox(height: 20.h),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildAddFileButton() {
    return InkWell(
      borderRadius: BorderRadius.circular(16.r),
      onTap: showPickOptions,
      child: Container(
        width: 110.w,
        height: 140.h,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(16.r),
          border: Border.all(
            color: Theme.of(context).colorScheme.primary,
            width: 2.w,
          ),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.add_circle_outline,
              size: 36.sp,
              color: Theme.of(context).colorScheme.primary,
            ),
            SizedBox(height: 6.h),
            Text(
              'إضافة',
              style: TextStyle(
                fontSize: 14.sp,
                fontWeight: FontWeight.w600,
                color: Theme.of(context).colorScheme.primary,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFileCard(int index) {
    return Stack(
      children: [
        Container(
          width: 110.w,
          height: 140.h,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16.r),
            border: Border.all(
              color: Theme.of(context).colorScheme.primary.withValues(alpha: 0.5),
              width: 1.5.w,
            ),
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(14.r),
            child: fileIsImage[index]
                ? Image.file(
                    selectedFiles[index],
                    fit: BoxFit.cover,
                    width: double.infinity,
                    height: double.infinity,
                  )
                : Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.insert_drive_file,
                        size: 40.sp,
                        color: Theme.of(context).colorScheme.primary,
                      ),
                      SizedBox(height: 6.h),
                      Padding(
                        padding: EdgeInsets.symmetric(horizontal: 8.w),
                        child: Text(
                          selectedFileNames[index],
                          textAlign: TextAlign.center,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(fontSize: 11.sp),
                        ),
                      ),
                    ],
                  ),
          ),
        ),
        // Delete button
        Positioned(
          top: 4.h,
          left: 4.w,
          child: GestureDetector(
            onTap: () => removeFile(index),
            child: Container(
              padding: EdgeInsets.all(4.r),
              decoration: const BoxDecoration(
                color: Colors.red,
                shape: BoxShape.circle,
              ),
              child: Icon(
                Icons.close,
                size: 16.sp,
                color: Colors.white,
              ),
            ),
          ),
        ),
      ],
    );
  }
}
