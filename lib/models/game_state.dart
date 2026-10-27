import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

class Player {
  final String name;
  bool isCaptain;
  bool isKeeper;
  String role; // unknown | human | hybrid | cultist
  String characterName;
  String specialAction;

  // Характеристики
  int strength;
  int will;
  int lore;
  int influence;
  int observation;

  Player({
    required this.name,
    this.isCaptain = false,
    this.isKeeper = false,
    this.role = 'unknown',
    this.characterName = 'Не выбран',
    this.specialAction = '',
    this.strength = 0,
    this.will = 0,
    this.lore = 0,
    this.influence = 0,
    this.observation = 0,
  });

  Map<String, dynamic> toJson() => {
    'name': name,
    'isCaptain': isCaptain,
    'isKeeper': isKeeper,
    'role': role,
    'characterName': characterName,
    'specialAction': specialAction,
    'strength': strength,
    'will': will,
    'lore': lore,
    'influence': influence,
    'observation': observation,
  };

  factory Player.fromJson(Map<String, dynamic> j) => Player(
    name: j['name'] as String,
    isCaptain: j['isCaptain'] as bool? ?? false,
    isKeeper: j['isKeeper'] as bool? ?? false,
    role: j['role'] as String? ?? 'unknown',
    characterName: j['characterName'] as String? ?? 'Не выбран',
    specialAction: j['specialAction'] as String? ?? '',
    strength: j['strength'] as int? ?? 0,
    will: j['will'] as int? ?? 0,
    lore: j['lore'] as int? ?? 0,
    influence: j['influence'] as int? ?? 0,
    observation: j['observation'] as int? ?? 0,
  );
}

class GameState extends ChangeNotifier {
  int fuel = 8;
  int supplies = 8;
  int sanity = 8;
  int souls = 8;
  String gameStatus = 'active'; // 'active', 'human_win', 'traitor_win'

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

  void _checkGameStatus() {
    if (gameStatus != 'active') return; // Если игра уже кончена, ничего не делаем

    // Проверка на поражение (ресурсы на нуле или корабль уничтожен)
    if (fuel <= 0 || supplies <= 0 || sanity <= 0 || souls <= 0 || damageSections.every((d) => d)) {
      gameStatus = 'traitor_win';
      _log('ИГРА ОКОНЧЕНА: Ресурсы на нуле или корабль уничтожен. Победа Предателей!');
      return;
    }

    // Проверка на прибытие в Бостон
    if (travelPosition >= maxTravel) {
      if (fuel > 0 && supplies > 0 && sanity > 0 && souls > 0) {
        gameStatus = 'human_win';
        _log('ИГРА ОКОНЧЕНА: Корабль добрался до Бостона! Победа Людей!');
      } else {
        gameStatus = 'traitor_win';
        _log('ИГРА ОКОНЧЕНА: Прибыли в Бостон, но ресурсы на нуле. Победа Предателей!');
      }
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
    _checkGameStatus();
  }

  void toggleDamage(int index) {
    _saveHistory();
    damageSections[index] = !damageSections[index];
    _log('Отсек ${index + 1}: ${damageSections[index] ? 'повреждён' : 'в порядке'}');
    notifyListeners();
    _checkGameStatus();
  }

  void advanceTravel() {
    if (travelPosition < maxTravel) {
      _saveHistory();
      travelPosition++;
      _log('Путешествие: отрезок $travelPosition из $maxTravel');
      notifyListeners();
      _checkGameStatus();
    }
  }


  void resetGame() {
    _saveHistory();
    gameStatus = 'active';
    fuel = 8;
    supplies = 8;
    sanity = 8;
    souls = 8;
    damageSections = List.filled(6, false);
    travelPosition = 0;
    ritualProgress = 0;
    deepOnDeck = 0;
    deepInOcean = 0;
    fatherDagon = false;
    motherHydra = false;
    playedMyths.clear();
    for (var p in players) {
      p.isCaptain = false;
      p.isKeeper = false;
      p.role = 'unknown';
      p.specialAction = '';
    }
    _log('--- НАЧАТА НОВАЯ ИГРА ---');
    notifyListeners();
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
    // Проверяем, является ли этот игрок капитаном прямо сейчас
    bool isCurrentlyCaptain = players[index].isCaptain;

    for (var i = 0; i < players.length; i++) {
      // Если мы кликнули на того, кто уже капитан — снимаем со всех.
      // Если кликнули на другого — ставим ему, а с остальных снимаем.
      players[i].isCaptain = isCurrentlyCaptain ? false : (i == index);
    }

    if (isCurrentlyCaptain) {
      _log('Капитан снят');
    } else {
      _log('Капитан: ${players[index].name}');
    }
    notifyListeners();
  }

  void setKeeper(int index) {
    _saveHistory();
    // Проверяем, является ли этот игрок хранителем прямо сейчас
    bool isCurrentlyKeeper = players[index].isKeeper;

    for (var i = 0; i < players.length; i++) {
      players[i].isKeeper = isCurrentlyKeeper ? false : (i == index);
    }

    if (isCurrentlyKeeper) {
      _log('Хранитель снят');
    } else {
      _log('Хранитель фолианта: ${players[index].name}');
    }
    notifyListeners();
  }

  void setCharacter(int index, String charName) {
    _saveHistory();
    players[index].characterName = charName;

    // Автоматически заполняем базовые характеристики (пример для игры)
    // Вы можете изменить эти цифры под реальные значения из игры
    if (charName == 'Агата Крейн') {
      players[index].strength = 2;
      players[index].will = 4;
      players[index].lore = 5;
      players[index].influence = 2;
      players[index].observation = 3;
    } else if (charName == 'Отец Матео') {
      players[index].strength = 3;
      players[index].will = 5;
      players[index].lore = 3;
      players[index].influence = 4;
      players[index].observation = 2;
    } else if (charName == 'Дэвид Марш') {
      players[index].strength = 2;
      players[index].will = 3;
      players[index].lore = 4;
      players[index].influence = 1;
      players[index].observation = 4;
    } // Добавьте остальных персонажей по аналогии

    _log('${players[index].name} выбрал персонажа: $charName');
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
    'gameStatus': gameStatus,
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
    gameStatus = j['gameStatus'] as String? ?? 'active';
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

  void addPlayer() {
    if (players.length >= 6) return; // Максимум 6 игроков
    _saveHistory();
    players.add(Player(name: 'Игрок ${players.length + 1}'));
    _log('Добавлен новый игрок');
    notifyListeners();
  }

  void removePlayer(int index) {
    if (players.length <= 1) return; // Нельзя удалить последнего игрока
    _saveHistory();
    final removedName = players[index].name;
    players.removeAt(index);
    _log('Удален игрок: $removedName');
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