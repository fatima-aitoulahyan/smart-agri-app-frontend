// planning_page.dart

import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:table_calendar/table_calendar.dart'; // 👈 Nécessite cette librairie
import '../service/api_service.dart'; // Pour récupérer les tâches
import 'package:provider/provider.dart';

class PlanningPage extends StatefulWidget {


  const PlanningPage({super.key});

  @override
  State<PlanningPage> createState() => _PlanningPageState();
}

class _PlanningPageState extends State<PlanningPage> {
  // 1. État du calendrier
  CalendarFormat _calendarFormat = CalendarFormat.month;
  DateTime _focusedDay = DateTime.now();
  DateTime? _selectedDay;

  // 2. Tâches (structure simplifiée pour l'exemple)
  Map<DateTime, List<dynamic>> _events = {};
  List<dynamic> _selectedEvents = [];
  bool _isLoading = true;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _selectedDay = _focusedDay;
    // Charge les tâches au démarrage
    _loadTasks();
  }

  // Fonction pour simuler le chargement des tâches depuis l'API
  Future<void> _loadTasks() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      // 💡 Dans la vraie vie, l'API renverrait une liste de tâches avec une date
      // Exemple de données simulées :
      final DateTime today = DateTime.now();
      final DateTime tomorrow = today.add(const Duration(days: 1));
      final DateTime nextWeek = today.add(const Duration(days: 7));

      _events = {
        _normalizeDate(today): [
          {'title': 'Arrosage', 'crop': 'Tomates', 'priority': 'Haute'},
          {'title': 'Inspection des feuilles', 'crop': 'Maïs', 'priority': 'Basse'}
        ],
        _normalizeDate(tomorrow): [
          {'title': 'Fertilisation NPK', 'crop': 'Tomates', 'priority': 'Haute'}
        ],
        _normalizeDate(nextWeek): [
          {'title': 'Traitement Fongicide', 'crop': 'Blé', 'priority': 'Moyenne'}
        ],
      };

      _selectedEvents = _getEventsForDay(_selectedDay!);

    } catch (e) {
      _errorMessage = 'error_loading_tasks'.tr(args: [e.toString()]);
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  // Fonction utilitaire pour normaliser la date (enlever l'heure)
  DateTime _normalizeDate(DateTime date) {
    return DateTime.utc(date.year, date.month, date.day);
  }

  // Fonction pour récupérer les événements d'une journée
  List<dynamic> _getEventsForDay(DateTime day) {
    return _events[_normalizeDate(day)] ?? [];
  }

  // Gestion du tap sur une journée
  void _onDaySelected(DateTime selectedDay, DateTime focusedDay) {
    if (!isSameDay(_selectedDay, selectedDay)) {
      setState(() {
        _selectedDay = selectedDay;
        _focusedDay = focusedDay;
        _selectedEvents = _getEventsForDay(selectedDay);
      });
    }
  }

  // 3. Construction de l'interface
  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      appBar: AppBar(
        title: Text('planning_title'.tr()),
        backgroundColor: Colors.green.shade700,
        foregroundColor: Colors.white,
      ),
      body: Column(
        children: [
          // Section Calendrier (TableCalendar)
          _buildCalendar(theme),

          // Section Tâches du Jour
          const SizedBox(height: 16),
          _buildTasksHeader(theme),
          Expanded(
            child: _buildTaskList(),
          ),
        ],
      ),
      // Bouton pour ajouter une nouvelle tâche
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () {
          // 💡 Action: Naviguer vers la page d'ajout de tâche (Ajouter une tâche)
          // Navigator.push(context, MaterialPageRoute(builder: (context) => AddTaskPage()));
          print('Ajouter une nouvelle tâche...');
        },
        label: Text('add_task'.tr()),
        icon: const Icon(Icons.add_task),
        backgroundColor: Colors.orange,
      ),
    );
  }

  // Widget Calendrier
  Widget _buildCalendar(ThemeData theme) {
    return TableCalendar(
      firstDay: DateTime.utc(2020, 1, 1),
      lastDay: DateTime.utc(2030, 12, 31),
      focusedDay: _focusedDay,
      calendarFormat: _calendarFormat,
      selectedDayPredicate: (day) => isSameDay(_selectedDay, day),
      eventLoader: _getEventsForDay, // Utilise la fonction pour charger les événements
      onDaySelected: _onDaySelected,
      onFormatChanged: (format) {
        if (_calendarFormat != format) {
          setState(() {
            _calendarFormat = format;
          });
        }
      },
      onPageChanged: (focusedDay) {
        _focusedDay = focusedDay;
      },
      // Styles personnalisés (optionnel)
      calendarStyle: CalendarStyle(
        todayDecoration: BoxDecoration(
          color: Colors.green.shade200,
          shape: BoxShape.circle,
        ),
        selectedDecoration: BoxDecoration(
          color: Colors.green.shade700,
          shape: BoxShape.circle,
        ),
        markerDecoration: BoxDecoration(
          color: Colors.orange.shade700, // Couleur pour les événements
          shape: BoxShape.circle,
        ),
      ),
      headerStyle: HeaderStyle(
        formatButtonVisible: true,
        titleCentered: true,
        formatButtonShowsNext: false,
        titleTextStyle: theme.textTheme.titleMedium!,
      ),
    );
  }

  // Widget En-tête des tâches
  Widget _buildTasksHeader(ThemeData theme) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            'tasks_for_day'.tr(args: [DateFormat('EEE d MMM').format(_selectedDay!)]),
            style: theme.textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
          ),
          Text(
            '${_selectedEvents.length} tâches',
            style: TextStyle(color: Colors.grey.shade600),
          ),
        ],
      ),
    );
  }

  // Widget Liste des tâches
  Widget _buildTaskList() {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }
    if (_errorMessage != null) {
      return Center(child: Text(_errorMessage!));
    }
    if (_selectedEvents.isEmpty) {
      return Center(
        child: Text('no_tasks_for_day'.tr()),
      );
    }

    return ListView.builder(
      itemCount: _selectedEvents.length,
      itemBuilder: (context, index) {
        final task = _selectedEvents[index];
        final priority = task['priority'] as String;
        Color color;

        if (priority == 'Haute') {
          color = Colors.red.shade700;
        } else if (priority == 'Moyenne') {
          color = Colors.orange.shade700;
        } else {
          color = Colors.green.shade700;
        }

        return Card(
          margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
          elevation: 2,
          child: ListTile(
            leading: Icon(Icons.calendar_month, color: color),
            title: Text(
              task['title']!,
              style: const TextStyle(fontWeight: FontWeight.w600),
            ),
            subtitle: Text('Cultures : ${task['crop']}'),
            trailing: Chip(
              label: Text(
                priority,
                style: const TextStyle(color: Colors.white, fontSize: 10),
              ),
              backgroundColor: color,
            ),
            onTap: () {
              // 💡 Action: Voir les détails de la tâche
            },
          ),
        );
      },
    );
  }
}