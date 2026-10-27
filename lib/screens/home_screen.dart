import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:package_info_plus/package_info_plus.dart';

import '../models/game_state.dart';
import '../widgets/common.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  bool _dialogShown = false;

  @override
  Widget build(BuildContext context) {
    final s = context.watch<GameState>();

    if (s.gameStatus != 'active' && !_dialogShown) {
      _dialogShown = true;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _showGameOverDialog(context, s);
      });
    } else if (s.gameStatus == 'active' && _dialogShown) {
      _dialogShown = false;
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('Капитанский планшет'),
        actions: [
          IconButton(
            tooltip: 'Настройки',
            icon: const Icon(Icons.settings),
            onPressed: () => _showSettingsDialog(context, s),
          ),
          IconButton(
            tooltip: 'Начать новую игру',
            icon: const Icon(Icons.refresh),
            onPressed: () => _showResetDialog(context, s),
          ),
          IconButton(
            tooltip: 'Отменить действие',
            icon: const Icon(Icons.undo),
            onPressed: s.canUndo ? s.undo : null,
          ),
          IconButton(
            tooltip: 'Сохранить',
            icon: const Icon(Icons.save),
            onPressed: s.save,
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.all(12),
        children: [
          SectionCard(
            title: 'Ресурсы',
            child: Column(
              children: [
                StatCounter(
                  label: 'Топливо',
                  icon: Icons.local_gas_station,
                  value: s.fuel,
                  onDelta: (d) => s.adjustResource('fuel', d),
                ),
                StatCounter(
                  label: 'Припасы',
                  icon: Icons.restaurant,
                  value: s.supplies,
                  onDelta: (d) => s.adjustResource('supplies', d),
                ),
                StatCounter(
                  label: 'Рассудок',
                  icon: Icons.psychology,
                  value: s.sanity,
                  onDelta: (d) => s.adjustResource('sanity', d),
                ),
                StatCounter(
                  label: 'Души',
                  icon: Icons.spa,
                  value: s.souls,
                  onDelta: (d) => s.adjustResource('souls', d),
                ),
              ],
            ),
          ),
          SectionCard(
            title: 'Повреждения корабля',
            child: Wrap(
              spacing: 8,
              runSpacing: 8,
              children: List.generate(6, (i) {
                final broken = s.damageSections[i];
                return InkWell(
                  onTap: () => s.toggleDamage(i),
                  borderRadius: BorderRadius.circular(12),
                  child: Container(
                    width: 64,
                    height: 64,
                    decoration: BoxDecoration(
                      // Используем прозрачность для поддержки темной темы
                      color: broken
                          ? Colors.red.withOpacity(0.2)
                          : Colors.green.withOpacity(0.2),
                      border: Border.all(
                        color: broken ? Colors.red : Colors.green,
                      ),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          broken ? Icons.warning_amber : Icons.check,
                          color: broken ? Colors.red : Colors.green,
                        ),
                        Text(
                          'Отсек ${i + 1}',
                          style: const TextStyle(fontSize: 10),
                        ),
                      ],
                    ),
                  ),
                );
              }),
            ),
          ),
          SectionCard(
            title: 'Путешествие (${s.travelPosition} / ${GameState.maxTravel})',
            child: Column(
              children: [
                Row(
                  children: List.generate(GameState.maxTravel + 1, (i) {
                    final reached = i <= s.travelPosition;
                    final current = i == s.travelPosition;
                    return Expanded(
                      child: Container(
                        margin: const EdgeInsets.symmetric(horizontal: 1),
                        height: 16,
                        decoration: BoxDecoration(
                          color: current
                              ? Colors.amber
                              : reached
                              ? Colors.blue
                          // Используем цвет из темы
                              : Theme.of(context).disabledColor.withOpacity(0.3),
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                    );
                  }),
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    OutlinedButton(
                      onPressed: s.retreatTravel,
                      child: const Text('Назад'),
                    ),
                    const Spacer(),
                    FilledButton.icon(
                      onPressed: s.advanceTravel,
                      icon: const Icon(Icons.arrow_forward),
                      label: const Text('Вперёд'),
                    ),
                  ],
                ),
              ],
            ),
          ),
          SectionCard(
            title: 'Ритуал',
            child: Row(
              children: [
                Text('Прогресс: ${s.ritualProgress}'),
                const Spacer(),
                IconButton(
                  onPressed: () => s.adjustRitual(-1),
                  icon: const Icon(Icons.remove),
                ),
                IconButton(
                  onPressed: () => s.adjustRitual(1),
                  icon: const Icon(Icons.add),
                ),
              ],
            ),
          ),

          const SizedBox(height: 24),
          FutureBuilder<PackageInfo>(
            future: PackageInfo.fromPlatform(),
            builder: (context, snapshot) {
              if (snapshot.hasData) {
                final info = snapshot.data!;
                return Center(
                  child: Text(
                    'Версия ${info.version} (${info.buildNumber})',
                    style: const TextStyle(color: Colors.grey, fontSize: 12),
                  ),
                );
              }
              return const SizedBox.shrink();
            },
          ),
          const SizedBox(height: 24),
        ],
      ),
    );
  }

  // --- НАСТРОЙКИ ТЕМЫ (ТЕПЕРЬ В ПРАВИЛЬНОМ МЕСТЕ) ---
  void _showSettingsDialog(BuildContext context, GameState s) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Настройки'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Тема оформления:', style: TextStyle(fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            RadioListTile<ThemeMode>(
              title: const Text('Системная'),
              value: ThemeMode.system,
              groupValue: s.themeMode,
              onChanged: (val) {
                if (val != null) s.setThemeMode(val);
                Navigator.pop(ctx);
              },
            ),
            RadioListTile<ThemeMode>(
              title: const Text('Светлая'),
              value: ThemeMode.light,
              groupValue: s.themeMode,
              onChanged: (val) {
                if (val != null) s.setThemeMode(val);
                Navigator.pop(ctx);
              },
            ),
            RadioListTile<ThemeMode>(
              title: const Text('Темная'),
              value: ThemeMode.dark,
              groupValue: s.themeMode,
              onChanged: (val) {
                if (val != null) s.setThemeMode(val);
                Navigator.pop(ctx);
              },
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Закрыть'),
          ),
        ],
      ),
    );
  }

  void _showResetDialog(BuildContext context, GameState s) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Начать новую игру?'),
        content: const Text(
            'Весь текущий прогресс (ресурсы, путь, повреждения, сыгранные мифы и заметки) будет сброшен. Вы уверены?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: const Text('Отмена'),
          ),
          FilledButton(
            style: FilledButton.styleFrom(backgroundColor: Colors.red),
            onPressed: () {
              Navigator.of(ctx).pop();
              s.resetGame();
            },
            child: const Text('Да, сбросить'),
          ),
        ],
      ),
    );
  }

  void _showGameOverDialog(BuildContext context, GameState s) {
    bool isHumanWin = s.gameStatus == 'human_win';

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => AlertDialog(
        title: Text(
          isHumanWin ? 'Победа Людей!' : 'Победа Предателей!',
          style: TextStyle(
            color: isHumanWin ? Colors.blue.shade800 : Colors.red.shade800,
            fontWeight: FontWeight.bold,
          ),
        ),
        content: Text(
          isHumanWin
              ? 'Корабль успешно добрался до Бостона, сохранив экипаж и ресурсы. Люди выиграли! Раскройте свои тайные роли, чтобы узнать, кто победил лично.'
              : 'Корабль потерпел крушение или ресурсы иссякли. Гибриды и культисты одержали верх! Раскройте свои тайные роли.',
        ),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.of(ctx).pop();
            },
            child: const Text('Посмотреть поле'),
          ),
          FilledButton(
            style: FilledButton.styleFrom(
              backgroundColor: isHumanWin ? Colors.blue : Colors.red,
            ),
            onPressed: () {
              Navigator.of(ctx).pop();
              s.resetGame();
            },
            child: const Text('Новая игра'),
          ),
        ],
      ),
    );
  }
}