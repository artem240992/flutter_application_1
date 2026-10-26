import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

class Player {
  final String name;
  bool isCaptain;
  bool isKeeper;
  String role;

  Player({
    required this.name,
    this.isCaptain = false,
    this.isKeeper = false,
    this.role = 'unknown',
  });

  Map<String, dynamic> toJson() => {
    'name': name,
    'isCaptain': isCaptain,
    'isKeeper': isKeeper,
    'role': role,
  };

  factory Player.fromJson(Map<String, dynamic> j) => Player(
    name: j['name'] as String,
    isCaptain: j['isCaptain'] as bool? ?? false,
    isKeeper: j['isKeeper'] as bool? ?? false,
    role: j['role'] as String? ?? 'unknown',
  );
}

class GameState extends ChangeNotifier {
  int fuel = 8;
  int supplies = 8;
  int sanity = 8;
  int souls = 8;

  List<bool> damageSections = List.filled(6, false);
  int travelPosition = 0;
  static const int maxTravel = 12;
  int ritualProgress = 0;

  int deepOnDeck = 0;
  int deepInOcean = 0;
  bool fatherDagon = false;
  bool motherHydra = false;

  List<String> availableMyths = [];
  List<String> playedMyths = <String>[];

  List<Player> players = [
    Player(name: 'Игрок 1'),
    Player(name: 'Игрок 2'),
    Player(name: 'Игрок 3'),
    Player(name: 'Игрок 4'),
  ];

  List<String> log = <String>[];

  final List<Map<String, dynamic>> _history = [];
  bool get canUndo => _history.isNotEmpty;

  void _saveHistory() {
    _history.add(toJson());
    if (_history.length > 20) {
      _history.removeAt(0);
    }
  }

  void undo() {
    if (_history.isEmpty) return;
    final previousState = _history.removeLast();
    restore(previousState, recordHistory: false);
    _log('Отменено последнее действие');
    notifyListeners();
  }

  void _log(String m) {
    final now = DateTime.now();
    final t =
        '${now.hour.toString().padLeft(2, '0')}:${now.minute.toString().padLeft(2, '0')}';
    log.insert(0, '[$t] $m');
  }

  void adjustResource(String key, int delta) {
    _saveHistory();
    switch (key) {
      case 'fuel':
        fuel = (fuel + delta).clamp(0, 99);
        break;
      case 'supplies':
        supplies = (supplies + delta).clamp(0, 99);
        break;
      case 'sanity':
        sanity = (sanity + delta).clamp(0, 99);
        break;
      case 'souls':
        souls = (souls + delta).clamp(0, 99);
        break;
    }
    _log('$key: ${delta > 0 ? '+' : ''}$delta');
    notifyListeners();
  }

  void toggleDamage(int index) {
    _saveHistory();
    damageSections[index] = !damageSections[index];
    _log('Отсек ${index + 1}: ${damageSections[index] ? 'повреждён' : 'в порядке'}');
    notifyListeners();
  }

  void advanceTravel() {
    if (travelPosition < maxTravel) {
      _saveHistory();
      travelPosition++;
      _log('Путешествие: отрезок $travelPosition из $maxTravel');
      notifyListeners();
    }
  }

  void retreatTravel() {
    if (travelPosition > 0) {
      _saveHistory();
      travelPosition--;
      _log('Путешествие: отрезок $travelPosition');
      notifyListeners();
    }
  }

  void adjustRitual(int delta) {
    _saveHistory();
    ritualProgress = (ritualProgress + delta).clamp(0, 99);
    _log('Ритуал: $ritualProgress');
    notifyListeners();
  }

  void adjustMonsters(String pool, int delta) {
    _saveHistory();
    if (pool == 'deck') {
      deepOnDeck = (deepOnDeck + delta).clamp(0, 99);
      _log('Глубоководные на палубе: $deepOnDeck');
    } else {
      deepInOcean = (deepInOcean + delta).clamp(0, 99);
      _log('Глубоководные в океане: $deepInOcean');
    }
    notifyListeners();
  }

  void toggleBoss(String boss) {
    _saveHistory();
    if (boss == 'dagon') {
      fatherDagon = !fatherDagon;
      _log('Отец Дагон: ${fatherDagon ? 'активен' : 'устранён'}');
    } else {
      motherHydra = !motherHydra;
      _log('Мать Гидра: ${motherHydra ? 'активна' : 'устранена'}');
    }
    notifyListeners();
  }

  void addMyth(String name) {
    if (name.trim().isEmpty) return;
    _saveHistory();
    playedMyths.add(name.trim());
    _log('Сыгран миф: $name');
    notifyListeners();
  }

  void removeMyth(int index) {
    _saveHistory();
    final m = playedMyths.removeAt(index);
    _log('Удалён миф: $m');
    notifyListeners();
  }

  void setCaptain(int index) {
    _saveHistory();
    for (var i = 0; i < players.length; i++) {
      players[i].isCaptain = i == index;
    }
    _log('Капитан: ${players[index].name}');
    notifyListeners();
  }

  void setKeeper(int index) {
    _saveHistory();
    for (var i = 0; i < players.length; i++) {
      players[i].isKeeper = i == index;
    }
    _log('Хранитель фолианта: ${players[index].name}');
    notifyListeners();
  }

  void setRole(int index, String role) {
    _saveHistory();
    players[index].role = role;
    notifyListeners();
  }

  void clearLog() {
    _saveHistory();
    log.clear();
    notifyListeners();
  }

  Map<String, dynamic> toJson() => {
    'fuel': fuel,
    'supplies': supplies,
    'sanity': sanity,
    'souls': souls,
    'damageSections': damageSections,
    'travelPosition': travelPosition,
    'ritualProgress': ritualProgress,
    'deepOnDeck': deepOnDeck,
    'deepInOcean': deepInOcean,
    'fatherDagon': fatherDagon,
    'motherHydra': motherHydra,
    'availableMyths': availableMyths,
    'playedMyths': playedMyths,
    'players': players.map((p) => p.toJson()).toList(),
    'log': log,
  };

  void restore(Map<String, dynamic> j, {bool recordHistory = false}) {
    if (recordHistory) _saveHistory();

    fuel = j['fuel'] as int? ?? 8;
    supplies = j['supplies'] as int? ?? 8;
    sanity = j['sanity'] as int? ?? 8;
    souls = j['souls'] as int? ?? 8;
    damageSections =
        (j['damageSections'] as List?)?.cast<bool>() ?? List.filled(6, false);
    travelPosition = j['travelPosition'] as int? ?? 0;
    ritualProgress = j['ritualProgress'] as int? ?? 0;
    deepOnDeck = j['deepOnDeck'] as int? ?? 0;
    deepInOcean = j['deepInOcean'] as int? ?? 0;
    fatherDagon = j['fatherDagon'] as bool? ?? false;
    motherHydra = j['motherHydra'] as bool? ?? false;
    availableMyths = (j['availableMyths'] as List?)?.cast<String>() ?? availableMyths;
    playedMyths = (j['playedMyths'] as List?)?.cast<String>() ?? <String>[];
    players = (j['players'] as List?)
        ?.map((e) => Player.fromJson(e as Map<String, dynamic>))
        .toList() ??
        players;
    log = (j['log'] as List?)?.cast<String>() ?? <String>[];
    notifyListeners();
  }

  Future<void> save() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('game_state', jsonEncode(toJson()));
    _log('Игра сохранена');
    notifyListeners();
  }

  static Future<GameState?> load() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString('game_state');
    if (raw == null) return null;
    final state = GameState();
    state.restore(jsonDecode(raw) as Map<String, dynamic>, recordHistory: false);
    return state;
  }
}