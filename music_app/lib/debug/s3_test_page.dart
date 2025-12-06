import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:music_app/core/network/s3_client.dart';
import 'package:music_app/core/constants/s3_constants.dart';

/// Test page to verify S3 bucket connectivity
/// Use this to debug S3 access issues
class S3TestPage extends StatefulWidget {
  const S3TestPage({super.key});

  @override
  State<S3TestPage> createState() => _S3TestPageState();
}

class _S3TestPageState extends State<S3TestPage> {
  final s3Client = S3Client();
  String status = 'Ready to test';
  List<String> objects = [];
  List<String> debugLogs = [];
  bool isLoading = false;
  String? requestUrl;
  String? errorDetails;

  Future<void> testBucket() async {
    setState(() {
      status = 'Testing bucket access...';
      isLoading = true;
      objects = [];
      debugLogs = [];
      errorDetails = null;
    });

    try {
      final bucketName = 'runnel-sec-aksjhdcy';
      final region = 'ap-southeast-2';

      setState(() {
        requestUrl = S3Constants.getBucketUrl(bucketName, region);
        status = 'Listing objects in $bucketName ($region)...';
        debugLogs.add('🔍 Request URL: $requestUrl');
        debugLogs.add('   Parameters: list-type=2, prefix=music/');
      });

      final result = await s3Client.listObjects(
        bucketName: bucketName,
        region: region,
        prefix: 'music/',
      );

      setState(() {
        objects = result.objects.map((obj) => obj.key).toList();
        status = '✅ Success! Found ${result.objects.length} objects';
        debugLogs.add('✅ Successfully received ${result.objects.length} objects');
        isLoading = false;
      });
    } catch (e, stackTrace) {
      setState(() {
        status = '❌ Error: ${e.toString()}';
        errorDetails = 'Error: $e\n\nStack trace:\n$stackTrace';
        debugLogs.add('❌ Exception caught: ${e.runtimeType}');
        debugLogs.add('   Message: ${e.toString()}');
        isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('S3 Bucket Test'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Bucket Configuration',
                      style: Theme.of(context).textTheme.titleMedium,
                    ),
                    const SizedBox(height: 8),
                    const Text('Bucket: runnel-sec-aksjhdcy'),
                    const Text('Region: ap-southeast-2'),
                    const Text('Prefix: music/'),
                    if (requestUrl != null) ...[
                      const SizedBox(height: 4),
                      const Text('URL:', style: TextStyle(fontWeight: FontWeight.bold)),
                      SelectableText(
                        requestUrl!,
                        style: const TextStyle(fontSize: 11, fontFamily: 'monospace'),
                      ),
                    ],
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),
            ElevatedButton.icon(
              onPressed: isLoading ? null : testBucket,
              icon: isLoading
                  ? const SizedBox(
                      width: 16,
                      height: 16,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Icon(Icons.cloud),
              label: Text(isLoading ? 'Testing...' : 'Test Bucket Access'),
            ),
            const SizedBox(height: 16),
            Card(
              color: status.startsWith('✅')
                  ? Colors.green.shade50
                  : status.startsWith('❌')
                      ? Colors.red.shade50
                      : null,
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      status,
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        color: status.startsWith('✅')
                            ? Colors.green.shade900
                            : status.startsWith('❌')
                                ? Colors.red.shade900
                                : null,
                      ),
                    ),
                    if (errorDetails != null) ...[
                      const SizedBox(height: 8),
                      ElevatedButton.icon(
                        onPressed: () {
                          Clipboard.setData(ClipboardData(text: errorDetails!));
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(content: Text('Error details copied to clipboard')),
                          );
                        },
                        icon: const Icon(Icons.copy, size: 16),
                        label: const Text('Copy Error Details'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.red.shade100,
                          foregroundColor: Colors.red.shade900,
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ),
            if (debugLogs.isNotEmpty) ...[
              const SizedBox(height: 16),
              Text(
                'Debug Logs:',
                style: Theme.of(context).textTheme.titleMedium,
              ),
              const SizedBox(height: 8),
              Card(
                color: Colors.grey.shade100,
                child: Padding(
                  padding: const EdgeInsets.all(12.0),
                  child: SizedBox(
                    height: 120,
                    child: SingleChildScrollView(
                      child: SelectableText(
                        debugLogs.join('\n'),
                        style: const TextStyle(fontSize: 11, fontFamily: 'monospace'),
                      ),
                    ),
                  ),
                ),
              ),
            ],
            const SizedBox(height: 16),
            if (objects.isNotEmpty) ...[
              Text(
                'Objects Found (${objects.length}):',
                style: Theme.of(context).textTheme.titleMedium,
              ),
              const SizedBox(height: 8),
              Expanded(
                child: Card(
                  child: ListView.builder(
                    itemCount: objects.length,
                    itemBuilder: (context, index) {
                      final key = objects[index];
                      final isAudio = key.endsWith('.mp3') ||
                          key.endsWith('.m4a') ||
                          key.endsWith('.flac') ||
                          key.endsWith('.ogg') ||
                          key.endsWith('.wav');
                      
                      return ListTile(
                        dense: true,
                        leading: Icon(
                          isAudio ? Icons.music_note : Icons.folder,
                          color: isAudio ? Colors.blue : Colors.orange,
                          size: 20,
                        ),
                        title: Text(
                          key.split('/').last,
                          style: const TextStyle(fontSize: 12),
                        ),
                        subtitle: Text(
                          key,
                          style: const TextStyle(fontSize: 10),
                        ),
                      );
                    },
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
