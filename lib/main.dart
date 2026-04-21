import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_quill/flutter_quill.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:home_widget/home_widget.dart';
import 'package:provider/provider.dart';

import 'core/models/folder.dart';
import 'core/models/note.dart';
import 'core/models/tag.dart';
import 'core/providers/folder_provider.dart';
import 'core/providers/note_provider.dart';
import 'core/providers/tag_provider.dart';
import 'core/services/notification_service.dart';
import 'screens/home_screen.dart';
import 'screens/note_screen.dart';

final GlobalKey<NavigatorState> rootNavigatorKey = GlobalKey<NavigatorState>();

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await Hive.initFlutter();
  Hive.registerAdapter(NoteAdapter());
  Hive.registerAdapter(FolderAdapter());
  Hive.registerAdapter(TagAdapter());

  await NotificationService.instance.init();

  runApp(const MyApp());
}

class MyApp extends StatefulWidget {
  const MyApp({super.key});

  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  StreamSubscription<Uri?>? _widgetSub;
  Uri? _pendingDeepLink;

  @override
  void initState() {
    super.initState();
    _initWidgetDeepLinks();
  }

  Future<void> _initWidgetDeepLinks() async {
    try {
      final initialUri = await HomeWidget.initiallyLaunchedFromHomeWidget();
      if (initialUri != null) {
        _pendingDeepLink = initialUri;
        WidgetsBinding.instance.addPostFrameCallback((_) {
          _handleUri(_pendingDeepLink);
          _pendingDeepLink = null;
        });
      }
    } catch (_) {}

    _widgetSub = HomeWidget.widgetClicked.listen(_handleUri);
  }

  void _handleUri(Uri? uri) {
    if (uri == null) return;
    final navigator = rootNavigatorKey.currentState;
    final ctx = rootNavigatorKey.currentContext;
    if (navigator == null || ctx == null) return;

    if (uri.host == 'new') {
      navigator.push(
        MaterialPageRoute(builder: (_) => const NoteScreen()),
      );
    } else if (uri.host == 'open') {
      final id = uri.queryParameters['id'];
      if (id == null || id.isEmpty) return;
      final notesProvider = Provider.of<NotesProvider>(ctx, listen: false);
      final note = notesProvider.getById(id);
      if (note == null) return;
      navigator.push(
        MaterialPageRoute(builder: (_) => NoteScreen(note: note)),
      );
    }
  }

  @override
  void dispose() {
    _widgetSub?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => NotesProvider()..init()),
        ChangeNotifierProvider(create: (_) => FolderProvider()..init()),
        ChangeNotifierProvider(create: (_) => TagProvider()..init()),
      ],
      child: MaterialApp(
        title: 'Nuage Note',
        debugShowCheckedModeBanner: false,
        navigatorKey: rootNavigatorKey,
        localizationsDelegates: const [
          GlobalMaterialLocalizations.delegate,
          GlobalWidgetsLocalizations.delegate,
          GlobalCupertinoLocalizations.delegate,
          FlutterQuillLocalizations.delegate,
        ],
        supportedLocales: const [Locale('en', 'US'), Locale('fr', 'FR')],
        theme: _buildTheme(),
        home: const HomeScreen(),
      ),
    );
  }

  ThemeData _buildTheme() {
    const seedColor = Color(0xFF7C5CBF);

    return ThemeData(
      useMaterial3: true,
      colorScheme: ColorScheme.fromSeed(
        seedColor: seedColor,
        brightness: Brightness.dark,
        surface: const Color(0xFF12111A),
        onSurface: Colors.white,
      ),
      scaffoldBackgroundColor: const Color(0xFF12111A),
      textTheme: GoogleFonts.plusJakartaSansTextTheme(
        ThemeData.dark().textTheme,
      ).apply(bodyColor: Colors.white, displayColor: Colors.white),
      appBarTheme: AppBarTheme(
        backgroundColor: Colors.transparent,
        elevation: 0,
        centerTitle: true,
        titleTextStyle: GoogleFonts.plusJakartaSans(
          fontSize: 22,
          fontWeight: FontWeight.bold,
          color: Colors.white,
        ),
        iconTheme: const IconThemeData(color: Colors.white),
      ),
    );
  }
}
