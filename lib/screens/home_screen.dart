import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../models/game_state.dart';
import '../widgets/common.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final s = context.watch<GameState>();
    return Scaffold(
      appBar: AppBar(
        title: const Text('Капитанский планшет'),
        actions: [
          // Новая кнопка Undo
          IconButton(
            tooltip: 'Отменить действие',
            icon: const Icon(Icons.undo),
            onPressed: s.canUndo ? s.undo : null, // Неактивна, если истории нет
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
                      color: broken
                          ? Colors.red.shade100
                          : Colors.green.shade100,
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
                              : Colors.grey.shade300,
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
        ],
      ),
    );
  }
}
