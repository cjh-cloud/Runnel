# Music App - Technical Specification

**Version:** 1.0.0  
**Date:** 5 October 2025  
**Status:** Draft

## 1. Executive Summary

A Flutter mobile application (Android primary, iOS secondary) that enables users to stream audio files from AWS S3 storage and download them for offline playback. Users can connect to multiple public S3 buckets and the app dynamically discovers music organized in artist/album folder structures. The app provides a seamless music listening experience with support for both online streaming and local cached playback.

**Key Differentiator:** Multi-bucket support with dynamic catalog discovery - no backend required.

## 2. Core Features

### 2.1 Audio Streaming
- Stream audio files directly from S3 bucket URLs
- Progressive download with buffering support
- Playback controls: play, pause, stop, seek, skip
- Display playback progress and duration
- Background audio playback support
- Audio interruption handling (calls, notifications)

### 2.2 Download Management
- Download audio files from S3 to local storage
- Download progress tracking with percentage and speed
- Pause/resume download capability
- Queue multiple downloads
- Auto-retry on network failure
- Storage space validation before download

### 2.3 Offline Playback
- Play downloaded audio files without internet
- Seamless switching between streaming and local playback
- Manage downloaded files (view, delete)
- Downloaded files indicator/badge

### 2.4 Library Management
- **Multi-Bucket Support:** Add/remove S3 bucket sources
- **Dynamic Catalog:** Scan and index bucket contents
- Browse by artists → albums → tracks hierarchy
- Search and filter across all buckets
- Track metadata display (title, artist, album, duration, artwork, format)
- Album artwork from embedded tags or folder images
- Recently played tracks
- Favorites/playlist support (Phase 2)
- Show bucket source for each track

### 2.5 User Interface
- Home screen with track listing
- Now Playing screen with controls and artwork
- Downloads management screen
- Mini-player for quick controls
- Material Design 3 with dark/light theme support

## 3. Technical Architecture

### 3.1 App Architecture Pattern
**Clean Architecture with Feature-Based Structure**

```
lib/
├── core/
│   ├── constants/
│   ├── errors/
│   ├── network/
│   ├── storage/
│   └── utils/
├── features/
│   ├── audio_player/
│   │   ├── data/
│   │   │   ├── models/
│   │   │   ├── repositories/
│   │   │   └── datasources/
│   │   ├── domain/
│   │   │   ├── entities/
│   │   │   ├── repositories/
│   │   │   └── usecases/
│   │   └── presentation/
│   │       ├── bloc/
│   │       ├── pages/
│   │       └── widgets/
│   ├── downloads/
│   │   └── [same structure]
│   └── library/
│       └── [same structure]
└── main.dart
```

### 3.2 State Management
**Flutter Bloc (flutter_bloc)**
- Separation of business logic from UI
- Predictable state management
- Easy testing and debugging
- Event-driven architecture

### 3.3 Key Dependencies

#### Audio Playback
- `just_audio` (^0.9.x) - Audio player with streaming support
- `just_audio_background` - Background playback
- `audio_service` - System integration for media controls

#### Network & Storage
- `dio` (^5.x) - HTTP client for S3 downloads
- `path_provider` - Access to file system directories
- `hive` / `hive_flutter` - Local database for metadata
- `shared_preferences` - Simple key-value storage

#### AWS Integration
- `aws_s3_api` or `minio` - S3 SDK for bucket listing and object access
- `http` / `dio` - Fallback for direct S3 URL downloads
- No authentication SDK needed (public buckets)

#### Metadata Parsing
- `audiotags` or `flutter_audio_metadata` - Extract ID3 tags from audio files
- `path` - File path manipulation and parsing

#### UI Components
- `cached_network_image` - Album artwork caching
- `flutter_slidable` - Swipe actions for lists
- `percent_indicator` - Download progress visualization

#### Utilities
- `equatable` - Value equality for Bloc states
- `dartz` - Functional programming (Either for error handling)
- `get_it` - Dependency injection
- `connectivity_plus` - Network status monitoring

### 3.4 Data Models

```dart
class Track {
  final String id; // Generated hash from S3 path
  final String title;
  final String artist;
  final String album;
  final String s3Url;
  final String bucketName; // Source bucket
  final String s3Key; // Full S3 object key
  final AudioFormat format; // mp3, m4a, flac, ogg, wav
  final String? artworkUrl; // Embedded or album cover.jpg
  final Duration? duration; // From metadata
  final int? fileSize; // From S3 object metadata
  final DateTime? lastModified; // From S3 object metadata
  final bool isDownloaded;
  final String? localPath;
  final int? trackNumber; // Parsed from filename or tags
}

enum AudioFormat { mp3, m4a, flac, ogg, wav, unknown }

class BucketConfig {
  final String name;
  final String region; // e.g., 'us-east-1'
  final bool isDefault;
  final DateTime addedDate;
  final int trackCount; // Cached count
}

class Album {
  final String name;
  final String artist;
  final String bucketName;
  final String s3Prefix; // Path to album folder
  final String? artworkUrl;
  final List<Track> tracks;
  final Duration totalDuration;
}

class DownloadTask {
  final String trackId;
  final String url;
  final String savePath;
  final DownloadStatus status; // pending, downloading, paused, completed, failed
  final double progress; // 0.0 to 1.0
  final int bytesDownloaded;
  final int totalBytes;
  final DateTime startTime;
}

class PlaybackState {
  final Track? currentTrack;
  final bool isPlaying;
  final Duration position;
  final Duration duration;
  final PlaybackSource source; // stream or local
  final List<Track> queue;
  final LoopMode loopMode;
  final bool shuffleEnabled;
}
```

## 4. AWS S3 Integration

### 4.1 S3 Bucket Structure
```
music-app-public-bucket/
└── music/
    ├── {artist_name}/
    │   ├── {album_name}/
    │   │   ├── 01 - Track Name.mp3
    │   │   ├── 02 - Another Track.m4a
    │   │   ├── cover.jpg (optional)
    │   │   └── ...
    │   └── {another_album}/
    └── {another_artist}/
```

**Notes:**
- No pre-existing catalog.json - app must scan bucket dynamically
- Album artwork discovered by looking for image files (cover.jpg, folder.jpg, etc.)
- Track metadata extracted from filenames and ID3 tags
- Support multiple user-provided bucket names

### 4.2 Authentication & Access
**Current Implementation: Public Bucket (Option A)**
- S3 buckets with public read access (listable)
- No authentication required
- Anonymous usage
- Direct S3 API calls via AWS SDK

**Multi-Bucket Support:**
- Default bucket: `music-app-public-bucket`
- User can add custom bucket names via settings
- App scans each bucket's `music/` folder for content
- Store bucket list in local storage

**Future Migration Path:**
- **Option B (Pre-signed URLs):** For private buckets with backend
- **Option C (AWS Cognito):** For user authentication and personal libraries

**Required S3 Permissions:**
- `s3:ListBucket` - Browse folder structure
- `s3:GetObject` - Download/stream audio files
- Public bucket policy or CORS configuration for mobile access

### 4.3 Catalog Management (Dynamic Discovery)
**No pre-existing catalog** - app builds catalog by:
1. **Bucket Scanning:** List objects in `{bucket}/music/` prefix
2. **Folder Parsing:** Extract artist/album from path structure
3. **Metadata Extraction:** Parse ID3 tags from audio files
4. **Local Caching:** Store discovered catalog in Hive database
5. **Refresh Strategy:** Manual pull-to-refresh or background sync

**Parsing Logic:**
```
Path: music/Pink Floyd/The Dark Side of the Moon/01 - Speak to Me.mp3
→ Artist: "Pink Floyd"
→ Album: "The Dark Side of the Moon"
→ Track: "01 - Speak to Me" (clean track number prefix)
```

**Metadata Extraction:**
- Primary: ID3 tags (title, artist, album, duration, artwork)
- Fallback: Filename parsing if tags missing
- Use `flutter_audio_metadata` or `audiotagger` package

**Performance Optimization:**
- Incremental scanning (paginated ListObjects)
- Cache discovered structure to avoid re-scanning
- Background worker for metadata extraction

## 5. Local Storage Strategy

### 5.1 File Storage
- **Audio Files:** `{app_documents}/music/tracks/`
- **Artwork Cache:** `{app_cache}/artwork/`
- **Temp Downloads:** `{app_temp}/downloads/`

### 5.2 Database (Hive)
- **Tracks Box:** All track metadata
- **Downloads Box:** Download queue and status
- **Playback Box:** Playback history, favorites
- **Settings Box:** User preferences

### 5.3 Storage Management
- Maximum cache size limit (e.g., 5GB)
- LRU eviction for cache cleanup
- User-configurable storage limits
- Storage usage statistics screen

## 6. Playback Features

### 6.1 Player Capabilities
- Gapless playback
- Crossfade between tracks (optional)
- Equalizer support (future enhancement)
- Playback speed control
- Sleep timer

### 6.2 Notifications & Lock Screen
- Media notification with controls
- Lock screen media controls
- Android Auto / CarPlay support (Phase 2)

### 6.3 Audio Focus Management
- Pause on phone calls
- Duck audio for notifications
- Resume after interruptions

## 7. Network & Offline Handling

### 7.1 Connectivity States
- **Online:** Full streaming and download capability
- **Offline:** Local playback only, disable streaming
- **Poor Connection:** Adjust buffer size, show warnings

### 7.2 Caching Strategy
- Cache streamed audio for quick replay
- Keep last N played tracks in cache
- Clear cache on storage pressure

### 7.3 Error Handling
- Network timeouts with retry logic
- Graceful degradation on errors
- User-friendly error messages
- Automatic fallback to local version if available

## 8. UI/UX Specifications

### 8.1 Screens

#### Home/Library Screen
- Search bar at top
- Filter chips (All, Downloaded, Recent)
- Track list with artwork thumbnails
- Download status indicators
- Pull-to-refresh for catalog updates

#### Now Playing Screen
- Full-screen album artwork
- Prominent playback controls
- Progress slider with time stamps
- Queue management button
- Download/remove download button
- Shuffle and repeat toggles

#### Downloads Screen
- Active downloads with progress
- Completed downloads list
- Storage usage indicator
- Clear all cache option

#### Settings/Buckets Screen
- List configured S3 buckets
- Add new bucket (name + region input)
- Remove bucket
- Set default bucket
- Refresh/rescan bucket catalog
- Show track count per bucket

#### Mini Player
- Collapsible bottom sheet
- Track info and artwork
- Play/pause and skip controls
- Tap to expand to Now Playing

### 8.2 Themes
- Material Design 3
- Dynamic color support (Material You on Android 12+)
- Light and dark mode
- Adaptive layouts for tablets

### 8.3 Animations
- Smooth transitions between screens
- Playing indicator animation
- Download progress animations
- Artwork fade-in

## 9. Performance Requirements

- **App Launch:** < 2 seconds to home screen
- **Track Start (Streaming):** < 3 seconds buffering
- **Track Start (Local):** < 500ms
- **Download Speed:** Utilize full network bandwidth
- **Memory Usage:** < 150MB during playback
- **Battery:** Optimize for < 5% drain per hour of playback

## 10. Testing Strategy

### 10.1 Unit Tests
- Bloc state transitions
- Use case logic
- Repository implementations
- Data model serialization

### 10.2 Widget Tests
- UI component rendering
- User interactions
- State-driven UI updates

### 10.3 Integration Tests
- End-to-end playback flows
- Download and playback scenarios
- Offline mode transitions

### 10.4 Manual Testing
- Multiple device form factors
- Network condition variations
- Background/foreground transitions
- Platform-specific features

## 11. Implementation Phases

### Phase 1: MVP (Weeks 1-3)
- [ ] Project setup and architecture scaffolding
- [ ] S3 SDK integration (aws_s3_api or minio)
- [ ] Bucket listing and object scanning
- [ ] Artist/Album/Track hierarchy parsing from S3 paths
- [ ] ID3 metadata extraction with fallback to filename parsing
- [ ] Local catalog caching (Hive)
- [ ] Basic library UI (artists → albums → tracks)
- [ ] Audio streaming playback (all formats: MP3, M4A, FLAC, OGG, WAV)
- [ ] Now Playing screen with controls
- [ ] Basic error handling

### Phase 2: Downloads (Weeks 4-5)
- [ ] Download manager implementation
- [ ] Local storage integration
- [ ] Downloads UI and progress tracking
- [ ] Offline playback
- [ ] Local/streaming source switching

### Phase 3: Polish (Week 6)
- [ ] Background playback
- [ ] Media notifications
- [ ] Search and filtering
- [ ] Theme and UI refinements
- [ ] Performance optimization
- [ ] Testing and bug fixes

### Phase 4: Future Enhancements
- Playlists and favorites
- Social features (sharing, collaborative playlists)
- Audio effects and equalizer
- Cross-device sync
- Analytics and telemetry

## 12. Security Considerations

- Validate S3 URLs before playback/download
- Sanitize file paths to prevent directory traversal
- Secure credential storage (if using authentication)
- HTTPS-only communication
- Content verification for downloaded files

## 13. Accessibility

- Screen reader support
- Semantic labels for all controls
- Keyboard navigation (desktop)
- Sufficient color contrast
- Scalable text support

## 14. Analytics & Monitoring

- Track plays (streaming vs local)
- Download success/failure rates
- Playback errors and network issues
- User engagement metrics
- Crash reporting (Firebase Crashlytics)

## 15. Decisions Made ✓

1. **S3 Access Method:** ✓ Public buckets (start), migrate to pre-signed URLs or Cognito later
2. **Catalog Source:** ✓ Dynamic scanning - no JSON file, parse folder structure
3. **Audio Formats:** ✓ MP3, M4A, FLAC, OGG, WAV (all common formats)
4. **User Accounts:** ✓ Anonymous usage (no login required)
5. **Platforms:** ✓ Android primary, iOS secondary (mobile focus)
6. **Backend Service:** ✓ No backend - pure S3 integration
7. **Default Bucket:** ✓ `music-app-public-bucket` with multi-bucket support
8. **Folder Structure:** ✓ `music/artist_name/album_name/*.mp3`

## 16. Remaining Technical Decisions

1. **S3 Region:** What region is `music-app-public-bucket` in? (default to us-east-1?)
2. **Metadata Strategy:** Download full files for ID3 tags or use range requests for headers only?
3. **Album Art Priority:** Embedded tags first, or folder images (cover.jpg) first?
4. **Bucket Validation:** How to validate user-entered bucket names? (test ListObjects call?)
5. **Large Catalogs:** Pagination strategy for buckets with 1000+ tracks?

## 17. Success Metrics

- 95% crash-free sessions
- < 2% playback failure rate
- Average 4+ star rating
- 60%+ user retention after 30 days
- < 100ms UI response time

---

## 18. Feature Additions for Multi-Bucket Support

### Bucket Management Feature
- Settings screen with bucket configuration
- Add bucket: Name + Region input with validation
- Test connection before adding
- Remove bucket with confirmation
- Visual indicator for active/scanning buckets

### Catalog Sync Feature
- Background sync service for bucket changes
- Pull-to-refresh on library screen
- "Last synced" timestamp per bucket
- Incremental updates (detect new/removed files)
- Conflict resolution for duplicate artists/albums across buckets

### Library Filtering
- Filter by bucket source
- Filter by audio format
- Filter by download status
- Sort options (artist, album, date added, file size)

---

## Appendix A: Technology Stack Summary

| Category | Technology |
|----------|-----------|
| Framework | Flutter 3.9+ |
| Language | Dart 3.0+ |
| State Management | flutter_bloc |
| Audio Engine | just_audio + audio_service |
| HTTP Client | dio |
| Local DB | hive_flutter |
| DI Container | get_it |
| Testing | flutter_test, bloc_test, mockito |
| Cloud Storage | AWS S3 |
| CI/CD | GitHub Actions (TBD) |

## Appendix B: Compliance & Legal

- Ensure proper licensing for audio content
- Privacy policy for data collection
- Terms of service
- Age rating considerations
- GDPR compliance (if applicable)
