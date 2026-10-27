import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';

import 'models/game_state.dart';
import 'screens/home_screen.dart';
import 'screens/log_screen.dart';
import 'screens/monsters_screen.dart';
import 'screens/myths_screen.dart';
import 'screens/players_screen.dart';
import 'dart:async'; // Не забудьте добавить этот импорт в самом верху файла!

void main() {
  // Запускаем приложение сразу, без ожидания
  runApp(const SplashApp());
}

// Виджет, который управляет загрузкой
class SplashApp extends StatefulWidget {
  const SplashApp({super.key});

  @override
  State<SplashApp> createState() => _SplashAppState();
}

class _SplashAppState extends State<SplashApp> {
  late Future<GameState> _initFuture;

  @override
  void initState() {
    super.initState();
    _initFuture = _initializeApp();
  }

  // Асинхронная функция загрузки данных
  Future<GameState> _initializeApp() async {
    WidgetsFlutterBinding.ensureInitialized();

    // Загружаем JSON со списком карт
    String jsonString = '[]';
    try {
      jsonString = await rootBundle.loadString('assets/myths.json');
    } catch (e) {
      debugPrint('Ошибка загрузки JSON: $e');
    }
    final List<String> loadedMyths = List<String>.from(jsonDecode(jsonString));

    // Загружаем сохраненную игру
    final loaded = await GameState.load();
    final state = loaded ?? GameState();
    state.availableMyths = loadedMyths;

    // Задержка должна быть не меньше, чем время анимации процентов (2.5 сек)
    await Future.delayed(const Duration(seconds: 3));

    return state;
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<GameState>(
      future: _initFuture,
      builder: (context, snapshot) {
        // Пока данные грузятся, показываем экран загрузки
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const MaterialApp(
            debugShowCheckedModeBanner: false,
            home: SplashScreen(),
          );
        }

        // Когда данные загружены, показываем основное приложение
        return ChangeNotifierProvider(
          create: (_) => snapshot.data!,
          child: const UnfathomableCompanionApp(),
        );
      },
    );
  }
}

// Экран загрузки с процентами
class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  double _progress = 0.0;
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    // Каждые 50 миллисекунд увеличиваем прогресс на 2% (займет ~2.5 секунды)
    _timer = Timer.periodic(const Duration(milliseconds: 50), (timer) {
      setState(() {
        if (_progress < 1.0) {
          _progress += 0.02;
          if (_progress > 1.0) _progress = 1.0;
        } else {
          _timer?.cancel();
        }
      });
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // Вычисляем процент для текста
    int percent = (_progress * 100).toInt();

    return Scaffold(
      backgroundColor: const Color(0xFF1B3A5C), // Темно-синий фон
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // Ваша иконка
            const Image(
              image: AssetImage('assets/icon/app_icon.png'),
              width: 120,
              height: 120,
            ),
            const SizedBox(height: 40),

            // Полоска загрузки
            SizedBox(
              width: 200,
              child: ClipRRect(
                borderRadius: BorderRadius.circular(10),
                child: LinearProgressIndicator(
                  value: _progress, // Привязываем к нашей анимации
                  minHeight: 8,
                  backgroundColor: Colors.white24,
                  valueColor: const AlwaysStoppedAnimation<Color>(Colors.amber),
                ),
              ),
            ),

            const SizedBox(height: 16),

            // Текст с процентами
            Text(
              '$percent%',
              style: const TextStyle(
                  color: Colors.white,
                  fontSize: 24,
                  fontWeight: FontWeight.bold
              ),
            ),
            const SizedBox(height: 8),
            const Text(
              'Погружение в глубины...',
              style: TextStyle(color: Colors.white70, fontSize: 14),
            ),
          ],
        ),
      ),
    );
  }
}

// Основное приложение
class UnfathomableCompanionApp extends StatelessWidget {
  const UnfathomableCompanionApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Непостижимое: Компаньон',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: const Color(0xFF1B3A5C)),
        useMaterial3: true,
      ),
      home: const RootScreen(),
    );
  }
}

class RootScreen extends StatefulWidget {
  const RootScreen({super.key});
  @override
  State<RootScreen> createState() => _RootScreenState();
}

class _RootScreenState extends State<RootScreen> {
  int _index = 0;
  static const _screens = <Widget>[
    HomeScreen(),
    PlayersScreen(),
    MythsScreen(),
    MonstersScreen(),
    LogScreen(),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: IndexedStack(index: _index, children: _screens),
      bottomNavigationBar: NavigationBar(
        selectedIndex: _index,
        onDestinationSelected: (i) => setState(() => _index = i),
        destinations: const [
          NavigationDestination(icon: Icon(Icons.dashboard), label: 'Планшет'),
          NavigationDestination(icon: Icon(Icons.people), label: 'Игроки'),
          NavigationDestination(icon: Icon(Icons.auto_stories), label: 'Мифы'),
          NavigationDestination(icon: Icon(Icons.waves), label: 'Монстры'),
          NavigationDestination(icon: Icon(Icons.list_alt), label: 'Журнал'),
        ],
      ),
    );
  }
}