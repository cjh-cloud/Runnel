import 'package:dio/dio.dart';
import 'package:xml/xml.dart';
import '../constants/s3_constants.dart';
import '../errors/exceptions.dart';

/// Simple S3 object representation
class S3Object {
  final String key;
  final int size;
  final DateTime lastModified;

  S3Object({
    required this.key,
    required this.size,
    required this.lastModified,
  });
}

class S3ListResult {
  final List<S3Object> objects;
  final List<String> commonPrefixes;

  S3ListResult({
    this.objects = const [],
    this.commonPrefixes = const [],
  });
}

/// Wrapper around HTTP client for public S3 bucket operations
class S3Client {
  final Dio _dio = Dio();

  /// List objects in a public S3 bucket
  Future<S3ListResult> listObjects({
    required String bucketName,
    required String region,
    String? prefix,
    bool recursive = true,
    String? delimiter,
  }) async {
    // Try multiple URL formats for public bucket access
    final urlsToTry = [
      S3Constants.getBucketUrlWithoutRegion(bucketName), // Try without region first (common for public buckets)
      S3Constants.getBucketUrl(bucketName, region),      // Try with region
      S3Constants.getPathStyleBucketUrl(bucketName, region), // Try path-style as fallback
    ];

    Exception? lastException;
    
    for (int i = 0; i < urlsToTry.length; i++) {
      final bucketUrl = urlsToTry[i];
      final urlType = i == 0 ? 'without region' : i == 1 ? 'with region' : 'path-style';
      
      try {
        print('🔍 S3 Request attempt ${i + 1}/${ urlsToTry.length} ($urlType): $bucketUrl');
        
        final allObjects = <S3Object>[];
        final allPrefixes = <String>[];
        String? continuationToken;
        bool isTruncated = false;

        do {
          final params = <String, dynamic>{
            'list-type': '2', // Use ListObjectsV2
          };
          
          if (prefix != null && prefix.isNotEmpty) {
            params['prefix'] = prefix;
          }
          
          if (!recursive || delimiter != null) {
            params['delimiter'] = delimiter ?? '/';
          }

          if (continuationToken != null) {
            params['continuation-token'] = continuationToken;
          }
  
          print('   Parameters: $params');
  
          final response = await _dio.get(
            bucketUrl,
            queryParameters: params,
            options: Options(
              headers: {
                'Accept': 'application/xml',
              },
              followRedirects: true,
              maxRedirects: 5,
              validateStatus: (status) => status! < 500,
            ),
          );
  
          print('📡 S3 Response: ${response.statusCode}');
          
          if (response.statusCode != 200) {
            final responsePreview = response.data?.toString().substring(
              0, 
              response.data.toString().length > 500 ? 500 : response.data.toString().length
            ) ?? 'No response body';
            
            print('⚠️  Non-200 response: $responsePreview');
            
            if (i < urlsToTry.length - 1) {
              print('   Trying next URL format...');
              continue; // Try next URL
            }
            
            throw S3Exception(
              'Failed to list objects. Status: ${response.statusCode}. '
              'Bucket: "$bucketName", Region: "$region". '
              'Response: $responsePreview',
            );
          }
  
          final result = _parseListObjectsResponse(response.data);
          allObjects.addAll(result.objects);
          allPrefixes.addAll(result.commonPrefixes);
          
          // Check for truncation and continuation token
          final document = XmlDocument.parse(response.data);
          final isTruncatedElement = document.findAllElements('IsTruncated').firstOrNull;
          isTruncated = isTruncatedElement?.innerText == 'true';
          
          final tokenElement = document.findAllElements('NextContinuationToken').firstOrNull;
          continuationToken = tokenElement?.innerText;
          
          if (isTruncated) {
             print('   Response truncated, fetching next page...');
          }

        } while (isTruncated && continuationToken != null);

        print('✅ Success with $urlType format! Found ${allObjects.length} objects and ${allPrefixes.length} prefixes');
        
        return S3ListResult(objects: allObjects, commonPrefixes: allPrefixes);
        
      } on DioException catch (e) {
        print('❌ DioException (attempt ${i + 1}): ${e.type}');
        print('   Message: ${e.message}');
        print('   Response status: ${e.response?.statusCode}');
        
        lastException = e;
        
        // If it's a 403 or 404, try next URL format
        if (e.response?.statusCode == 403 || e.response?.statusCode == 404) {
          if (i < urlsToTry.length - 1) {
            print('   Trying next URL format...');
            continue;
          }
        }
        
        // For other errors, don't retry
        if (e.type == DioExceptionType.connectionTimeout ||
            e.type == DioExceptionType.receiveTimeout) {
          throw S3Exception('Connection timeout. Check your internet connection.');
        }
        
        // Last attempt failed
        if (i == urlsToTry.length - 1) {
          throw S3Exception(
            'Access denied to bucket "$bucketName". '
            'Tried all URL formats. Last error: ${e.response?.data ?? e.message}',
          );
        }
      } catch (e, stackTrace) {
        print('❌ Unexpected error (attempt ${i + 1}): $e');
        print('   Stack trace: $stackTrace');
        lastException = e is Exception ? e : Exception(e.toString());
        
        if (i < urlsToTry.length - 1) {
          print('   Trying next URL format...');
          continue;
        }
      }
    }
    
    // All attempts failed
    print('❌ All URL formats failed for bucket: $bucketName');
    throw S3Exception(
      'Failed to list objects in bucket: $bucketName. '
      'Tried all URL formats. Last error: ${lastException?.toString()}',
      lastException,
    );
  }

  /// Parse S3 XML response to list of objects
  S3ListResult _parseListObjectsResponse(String xmlData) {
    try {
      // print('📄 Parsing XML response (length: ${xmlData.length} chars)');
      
      if (xmlData.isEmpty) {
        print('⚠️  Warning: Empty XML response');
        return S3ListResult();
      }
      
      final document = XmlDocument.parse(xmlData);
      final objects = <S3Object>[];
      final prefixes = <String>[];

      // Check if response contains an error
      final errorElements = document.findAllElements('Error');
      if (errorElements.isNotEmpty) {
        final errorCode = errorElements.first.findElements('Code').firstOrNull?.innerText ?? 'Unknown';
        final errorMessage = errorElements.first.findElements('Message').firstOrNull?.innerText ?? 'No message';
        print('❌ S3 Error in response: $errorCode - $errorMessage');
        throw S3Exception('S3 Error: $errorCode - $errorMessage');
      }

      final contentElements = document.findAllElements('Contents');
      // print('   Found ${contentElements.length} Content elements');

      for (final content in contentElements) {
        try {
          final key = content.findElements('Key').first.innerText;
          final sizeStr = content.findElements('Size').first.innerText;
          final lastModifiedStr = content.findElements('LastModified').first.innerText;

          objects.add(S3Object(
            key: key,
            size: int.parse(sizeStr),
            lastModified: DateTime.parse(lastModifiedStr),
          ));
        } catch (e) {
          print('⚠️  Warning: Failed to parse individual object: $e');
          continue; // Skip malformed objects
        }
      }
      
      final prefixElements = document.findAllElements('CommonPrefixes');
      for (final prefix in prefixElements) {
        try {
          final p = prefix.findElements('Prefix').first.innerText;
          prefixes.add(p);
        } catch (e) {
           print('⚠️  Warning: Failed to parse prefix: $e');
        }
      }

      return S3ListResult(objects: objects, commonPrefixes: prefixes);
    } catch (e, stackTrace) {
      print('❌ XML Parsing error: $e');
      print('   XML preview: ${xmlData.substring(0, xmlData.length > 200 ? 200 : xmlData.length)}...');
      print('   Stack trace: $stackTrace');
      throw S3Exception('Failed to parse S3 response: $e', e);
    }
  }

  /// Get public URL for an object
  String getObjectUrl({
    required String bucketName,
    required String region,
    required String objectKey,
  }) {
    return S3Constants.getObjectUrl(bucketName, region, objectKey);
  }

  /// Test if bucket is accessible
  Future<bool> testBucketAccess({
    required String bucketName,
    required String region,
  }) async {
    try {
      await listObjects(
        bucketName: bucketName,
        region: region,
        prefix: '',
        recursive: false,
      );
      return true;
    } catch (e) {
      return false;
    }
  }

  void dispose() {
    _dio.close();
  }
}
