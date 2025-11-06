/// S3-specific constants and configurations
class S3Constants {
  // Music folder structure
  static const String musicPrefix = 'music/';
  
  // S3 Endpoints (public buckets use standard endpoints)
  static const String s3EndpointPattern = 'https://s3.{region}.amazonaws.com';
  
  // Standard AWS Regions
  static const List<String> awsRegions = [
    'us-east-1',
    'us-east-2',
    'us-west-1',
    'us-west-2',
    'eu-west-1',
    'eu-central-1',
    'ap-southeast-1',
    'ap-southeast-2',
    'ap-northeast-1',
  ];

  // S3 URL Patterns
  static String getBucketUrl(String bucketName, String region) {
    return 'https://$bucketName.s3.$region.amazonaws.com';
  }

  // Alternative URL format without region (for public buckets)
  static String getBucketUrlWithoutRegion(String bucketName) {
    return 'https://$bucketName.s3.amazonaws.com';
  }

  // Path-style URL (fallback for some buckets)
  static String getPathStyleBucketUrl(String bucketName, String region) {
    return 'https://s3.$region.amazonaws.com/$bucketName';
  }

  static String getObjectUrl(String bucketName, String region, String key) {
    return '${getBucketUrl(bucketName, region)}/$key';
  }

  // Get object URL without region (for public buckets)
  static String getObjectUrlWithoutRegion(String bucketName, String key) {
    return '${getBucketUrlWithoutRegion(bucketName)}/$key';
  }

  // Pagination
  static const int listObjectsMaxKeys = 1000;
}
