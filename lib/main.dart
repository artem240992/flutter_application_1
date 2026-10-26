import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'models/game_state.dart';
import 'screens/home_screen.dart';
import 'screens/log_screen.dart';
import 'screens/monsters_screen.dart';
import 'screens/myths_screen.dart';
import 'screens/players_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // ВРЕМЕННЫЙ СПИСОК КАРТ (вместо JSON)
  const List<String> loadedMyths = [
    "Одержимость",
    "Пробоина в корпусе",
    "Глубоководные на борту",
    "Шторм",
    "Психическая атака",
    "Сломанный двигатель",
    "Смута",
    "Потеря припасов",
    "Туман",
    "Видение из глубин"
  ];

  final loaded = await GameState.load();
  final state = loaded ?? GameState();
  state.availableMyths = loadedMyths; // Передаем список в состояние

  runApp(
    ChangeNotifierProvider(
      create: (_) => state,
      child: const UnfathomableCompanionApp(),
    ),
  );
}

class UnfathomableCompanionApp extends StatelessWidget {
  const UnfathomableCompanionApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Непостижимое: Компаньон',
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