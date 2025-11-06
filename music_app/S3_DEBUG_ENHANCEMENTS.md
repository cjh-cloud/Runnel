# S3 Debug Enhancements - Implementation Summary

## Overview
Fixed "failed to list objects in bucket" errors by adding comprehensive error logging and debugging capabilities across the S3 access layer.

## Changes Made

### 1. Enhanced S3Client (`lib/core/network/s3_client.dart`)
**Purpose**: Add detailed logging and better error handling for S3 requests

**Key Changes**:
- Added debug logging before and after each S3 request
  - Request URL and parameters
  - Response status code, content-type, and content-length
  - Number of objects found
- Added `Accept: application/xml` header to requests
- Enhanced error messages with response body previews (up to 500 chars)
- Added XML error element detection in responses
- Improved XML parsing with better error handling
- Added logging for DioException details (type, message, response data)
- Added stack trace logging for unexpected errors

**Debug Output Example**:
```
🔍 S3 Request: https://bucket-name.s3.ap-southeast-2.amazonaws.com
   Parameters: {list-type: 2, prefix: music/}
📡 S3 Response: 200
   Content-Type: application/xml
   Content-Length: 12345
📄 Parsing XML response (length: 12345 chars)
   Found 42 Content elements
✅ Found 42 objects in bucket
```

### 2. Enhanced Data Source (`lib/features/library/data/datasources/library_remote_data_source_impl.dart`)
**Purpose**: Add logging at the data source layer

**Key Changes**:
- Added logging when bucket scan starts
- Added logging for number of objects being processed
- Added completion summary (artists, albums count)
- Separated S3Exception handling from generic exceptions
- Added stack trace logging for unexpected errors

**Debug Output Example**:
```
🎵 Starting bucket scan: my-bucket (ap-southeast-2)
   Processing 150 objects...
✅ Scan complete: 5 artists, 12 albums
```

### 3. Enhanced LibraryBloc (`lib/features/library/presentation/bloc/library_bloc.dart`)
**Purpose**: Ensure error messages are logged

**Key Changes**:
- Added logging in `_mapFailureToMessage` method
- Logs all failures that occur during bucket operations

**Debug Output Example**:
```
🚨 LibraryBloc Error: Failed to scan bucket: Access denied...
```

### 4. Enhanced S3TestPage (`lib/debug/s3_test_page.dart`)
**Purpose**: Create a comprehensive debugging tool for S3 connectivity

**Key Changes**:
- Shows the exact request URL being used
- Displays debug logs in a scrollable text area
- Shows error details with stack traces
- Added "Copy Error Details" button for easy sharing
- Shows object count in the header
- Improved visual layout with better spacing

**Features**:
- Request URL display (selectable text)
- Debug logs section with emoji indicators
- Error details with copy-to-clipboard functionality
- Object list with icons for audio files vs folders

## How to Test

### Step 1: Check Console Logs
Run your app and attempt to add or scan a bucket. You should now see detailed console output:
```bash
flutter run
```

Look for the emoji-prefixed log messages:
- 🔍 = Request information
- 📡 = Response information  
- 📄 = XML parsing information
- ✅ = Success messages
- ❌ = Error messages
- ⚠️ = Warning messages
- 🎵 = Bucket scan information
- 🚨 = Bloc error messages

### Step 2: Use the S3TestPage
1. Navigate to the S3 Test Page in your app (if available in debug builds)
2. Click "Test Bucket Access"
3. Review the detailed output:
   - Request URL
   - Debug logs
   - Error details (if any)
   - List of objects found

### Step 3: Analyze Errors
When you see an error, you'll now get:
- The exact error type (DioException, S3Exception, etc.)
- The HTTP status code (if applicable)
- The response body from AWS S3
- A full stack trace
- The request URL and parameters

## Common Issues and Solutions

### Issue: "Access denied to bucket"
**Cause**: Bucket permissions not set to public
**Solution**: Update bucket policy to allow public read access

### Issue: "Bucket not found in region"
**Cause**: Wrong region specified or bucket doesn't exist
**Solution**: Verify bucket name and region are correct

### Issue: Connection timeout
**Cause**: Network connectivity issues
**Solution**: Check internet connection

### Issue: Empty XML response
**Cause**: Bucket exists but is empty, or no objects match prefix
**Solution**: Verify bucket has files under the `music/` prefix

## Next Steps

If errors persist:
1. Check the console output for specific error codes
2. Use the S3TestPage to copy error details
3. Verify the bucket URL format: `https://bucket-name.s3.region.amazonaws.com`
4. Test the bucket URL directly in a web browser
5. Verify AWS hasn't changed their public bucket access requirements

## Files Modified
- `lib/core/network/s3_client.dart`
- `lib/features/library/data/datasources/library_remote_data_source_impl.dart`
- `lib/features/library/presentation/bloc/library_bloc.dart`
- `lib/debug/s3_test_page.dart`

## Notes
- All debug logging uses `print()` statements which will appear in debug console
- Consider removing or conditionally enabling debug logs in production builds
- The enhanced error messages include response data which may be large

