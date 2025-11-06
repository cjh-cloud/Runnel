import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:audio_session/audio_session.dart';
import 'package:just_audio_background/just_audio_background.dart';
import 'core/di/injection_container.dart' as di;
import 'features/library/presentation/pages/library_page.dart';
import 'features/library/presentation/bloc/library_bloc.dart';
import 'features/player/presentation/bloc/player_bloc.dart';
import 'features/player/presentation/widgets/mini_player.dart';
import 'features/downloads/presentation/bloc/downloads_bloc.dart';
import 'features/downloads/presentation/bloc/downloads_event.dart';
import 'features/downloads/presentation/pages/downloads_page.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Initialize just_audio_background for lockscreen controls
  await JustAudioBackground.init(
    androidNotificationChannelId: 'com.musicapp.audio',
    androidNotificationChannelName: 'Music Playback',
    androidNotificationOngoing: false,
  );

  // Initialize dependencies
  await di.init();

  runApp(const MyApp());
}

class MyApp extends StatefulWidget {
  const MyApp({super.key});

  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  @override
  void initState() {
    super.initState();
    _initAudioSession();
  }

  Future<void> _initAudioSession() async {
    final session = await AudioSession.instance;
    await session.configure(const AudioSessionConfiguration.music());
  }

  @override
  Widget build(BuildContext context) {
    return MultiBlocProvider(
      providers: [
        BlocProvider(
          create: (context) => di.sl<LibraryBloc>()
            ..add(LoadLibraryEvent()),
        ),
        BlocProvider(
          create: (context) => di.sl<PlayerBloc>(),
        ),
        BlocProvider(
          create: (context) => di.sl<DownloadsBloc>()
            ..add(const LoadDownloads()),
        ),
      ],
      child: MaterialApp(
        title: 'Music App',
        debugShowCheckedModeBanner: false,
        theme: ThemeData(
          colorScheme: ColorScheme.fromSeed(
            seedColor: Colors.deepPurple,
            brightness: Brightness.light,
          ),
          useMaterial3: true,
        ),
        darkTheme: ThemeData(
          colorScheme: ColorScheme.fromSeed(
            seedColor: Colors.deepPurple,
            brightness: Brightness.dark,
          ),
          useMaterial3: true,
        ),
        themeMode: ThemeMode.system,
        home: const MainNavigation(),
      ),
    );
  }
}

class MainNavigation extends StatefulWidget {
  const MainNavigation({super.key});

  @override
  State<MainNavigation> createState() => _MainNavigationState();
}

class _MainNavigationState extends State<MainNavigation> {
  int _selectedIndex = 0;

  final List<Widget> _pages = const [
    LibraryPage(),
    DownloadsPage(),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Column(
        children: [
          Expanded(child: _pages[_selectedIndex]),
          // Mini player above navigation
          const MiniPlayer(),
        ],
      ),
      bottomNavigationBar: NavigationBar(
        selectedIndex: _selectedIndex,
        onDestinationSelected: (index) {
          setState(() {
            _selectedIndex = index;
          });
        },
        destinations: const [
          NavigationDestination(
            icon: Icon(Icons.library_music_outlined),
            selectedIcon: Icon(Icons.library_music),
            label: 'Library',
          ),
          NavigationDestination(
            icon: Icon(Icons.download_outlined),
            selectedIcon: Icon(Icons.download),
            label: 'Downloads',
          ),
        ],
      ),
    );
  }
}
