import 'package:flutter/material.dart';
import 'package:file_selector/file_selector.dart';
import 'package:it_team_app/main.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'File Selector Example',
      theme: ThemeData(
        primarySwatch: Colors.blue,
      ),
      home: const FileUploadPage(),
    );
  }
}

class FileUploadPage extends StatefulWidget {
  const FileUploadPage({super.key});

  @override
  State<FileUploadPage> createState() => _FileUploadPageState();
}

class _FileUploadPageState extends State<FileUploadPage> {
  String? fileName;
  int? fileSize;

  Future<void> pickAndUploadFile() async {
    final typeGroup = XTypeGroup(
      label: 'all',
      extensions: ['pdf', 'png', 'jpg', 'jpeg', 'txt', 'docx'],
    );

    final XFile? file = await openFile(acceptedTypeGroups: [typeGroup]);

    if (file == null) {
      // User canceled
      return;
    }

    final fileBytes = await file.readAsBytes();

    setState(() {
      fileName = file.name;
      fileSize = fileBytes.length;
    });

    // TODO: Upload `fileBytes` and `fileName` to backend/Cloudinary/etc.
    print('File name: $fileName');
    print('File size: $fileSize bytes');
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: HomePage.buttonColor,
        title: const Text('File Upload (file_selector)'),
      ),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: HomePage.buttonColor,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                onPressed: pickAndUploadFile,
                child: const Text('Pick & Upload File', style: TextStyle(
                  color: HomePage.textDark,
                  fontSize: 18,
                ),),
              ),
              const SizedBox(height: 24),
              if (fileName != null) ...[
                Text('Selected file: $fileName'),
                Text('Size: ${fileSize ?? 0} bytes'),
              ]
            ],
          ),
        ),
      ),
    );
  }
}
