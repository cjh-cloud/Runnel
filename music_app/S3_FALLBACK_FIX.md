# S3 Fallback URL Fix

## Problem
After adding enhanced debugging, we discovered XML access denied errors even though buckets are public. This indicates AWS has changed how they handle public bucket access.

## Root Cause
AWS S3 public bucket access has become more restrictive. Different buckets may require different URL formats:
1. Virtual-hosted without region: `https://bucket.s3.amazonaws.com`
2. Virtual-hosted with region: `https://bucket.s3.region.amazonaws.com`
3. Path-style: `https://s3.region.amazonaws.com/bucket`

## Solution Implemented

### 1. Multiple URL Format Support (`lib/core/constants/s3_constants.dart`)
Added new URL generation methods:
- `getBucketUrlWithoutRegion()` - For public buckets (most compatible)
- `getPathStyleBucketUrl()` - Fallback for legacy buckets
- `getObjectUrlWithoutRegion()` - For object URLs

### 2. Automatic Fallback Mechanism (`lib/core/network/s3_client.dart`)
The S3Client now tries three URL formats in order:

1. **First attempt**: Without region (most common for public buckets)
   ```
   https://bucket-name.s3.amazonaws.com
   ```

2. **Second attempt**: With region (standard format)
   ```
   https://bucket-name.s3.ap-southeast-2.amazonaws.com
   ```

3. **Third attempt**: Path-style (legacy support)
   ```
   https://s3.ap-southeast-2.amazonaws.com/bucket-name
   ```

Each attempt:
- Logs which format is being tried
- On 403/404 errors, automatically tries the next format
- On success, reports which format worked
- On complete failure, reports all attempts

### 3. Updated Object URL Generation
Both the data source and streaming URL now use the region-free format for better compatibility with public buckets.

## Console Output Example

When connecting to a bucket, you'll now see:
```
🔍 S3 Request attempt 1/3 (without region): https://my-bucket.s3.amazonaws.com
   Parameters: {list-type: 2, prefix: music/}
❌ DioException (attempt 1): badResponse
   Message: Http status error [403]
   Response status: 403
   Trying next URL format...

🔍 S3 Request attempt 2/3 (with region): https://my-bucket.s3.ap-southeast-2.amazonaws.com
   Parameters: {list-type: 2, prefix: music/}
📡 S3 Response: 200
   Content-Type: application/xml
   Content-Length: 12345
📄 Parsing XML response (length: 12345 chars)
   Found 42 Content elements
✅ Success with with region format! Found 42 objects
```

## Testing

Run your app and try to connect to your public buckets:

```bash
flutter run
```

**What to expect:**
1. The app will automatically try different URL formats
2. You'll see console logs for each attempt
3. It will use whichever format works
4. If all formats fail, you'll get a detailed error message

## Benefits

1. **Automatic Recovery**: Works with buckets that require different URL formats
2. **Future-Proof**: If AWS changes defaults, the fallback mechanism adapts
3. **Better Debugging**: Clear logging shows which format worked
4. **No Configuration Needed**: Users don't need to know which format their bucket needs

## Troubleshooting

### All formats fail with 403
**Possible causes:**
- Bucket is not actually public
- Block Public Access is enabled at the bucket or account level
- Bucket policy doesn't allow anonymous access

**Solution:**
1. Check bucket policy includes:
   ```json
   {
     "Version": "2012-10-17",
     "Statement": [
       {
         "Sid": "PublicRead",
         "Effect": "Allow",
         "Principal": "*",
         "Action": "s3:GetObject",
         "Resource": "arn:aws:s3:::bucket-name/*"
       },
       {
         "Sid": "PublicList",
         "Effect": "Allow",
         "Principal": "*",
         "Action": "s3:ListBucket",
         "Resource": "arn:aws:s3:::bucket-name"
       }
     ]
   }
   ```
2. Disable "Block all public access" in bucket settings
3. Ensure ACLs allow public read if bucket uses ACLs

### First format fails but second works
This is expected! The app will automatically use the working format. The first failure is just the app discovering which format your bucket needs.

### All formats fail with 404
**Cause:** Bucket name or region is incorrect

**Solution:** Double-check the bucket name and region

## Files Modified
- `lib/core/constants/s3_constants.dart` - Added new URL generation methods
- `lib/core/network/s3_client.dart` - Implemented fallback mechanism
- `lib/features/library/data/datasources/library_remote_data_source_impl.dart` - Updated URL generation

## Next Steps

If buckets still don't connect after these changes:
1. Review the console output to see all three attempts
2. Check which HTTP status codes are returned
3. Look at the XML error messages in the response
4. Verify bucket permissions in AWS Console
5. Try accessing the bucket URL directly in a browser

