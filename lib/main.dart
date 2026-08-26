import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

const Color primaryNavyBlue = Color(0xFF0D47A1);
const Color lightBlueAccent = Color(0xFF42A5F5);

void main() {
  runApp(const WaterTrackerApp());
}

class WaterTrackerApp extends StatefulWidget {
  const WaterTrackerApp({super.key});

  @override
  State<WaterTrackerApp> createState() => _WaterTrackerAppState();
}

class _WaterTrackerAppState extends State<WaterTrackerApp> {
  ThemeMode _themeMode = ThemeMode.light;

  void _toggleTheme(bool isDark) {
    setState(() {
      _themeMode = isDark ? ThemeMode.dark : ThemeMode.light;
    });
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Consumo de Água',
      theme: ThemeData(
        useMaterial3: true,
        brightness: Brightness.light,
        scaffoldBackgroundColor: const Color(0xFFE3F2FD),
        primaryColor: primaryNavyBlue,
        colorScheme: ColorScheme.fromSeed(
          seedColor: primaryNavyBlue,
          primary: primaryNavyBlue,
          secondary: lightBlueAccent,
          brightness: Brightness.light,
        ),
        appBarTheme: const AppBarTheme(
          backgroundColor: primaryNavyBlue,
          foregroundColor: Colors.white,
        ),
        floatingActionButtonTheme: const FloatingActionButtonThemeData(
          backgroundColor: lightBlueAccent,
          foregroundColor: Colors.white,
        ),
      ),
      darkTheme: ThemeData(
        useMaterial3: true,
        brightness: Brightness.dark,
        colorScheme: ColorScheme.fromSeed(
          seedColor: primaryNavyBlue,
          brightness: Brightness.dark,
          primary: lightBlueAccent,
          secondary: primaryNavyBlue,
        ),
      ),
      themeMode: _themeMode,
      home: SplashScreen(
        onThemeChanged: _toggleTheme,
        isDarkMode: _themeMode == ThemeMode.dark,
      ),
    );
  }
}

class WaterRecord {
  String id;
  String data;
  double quantidadeMl;
  double pesoAtualKg;

  WaterRecord({
    required this.id,
    required this.data,
    required this.quantidadeMl,
    required this.pesoAtualKg,
  });

  Map<String, dynamic> toMap() => {
    'id': id,
    'data': data,
    'quantidadeMl': quantidadeMl,
    'pesoAtualKg': pesoAtualKg,
  };

  factory WaterRecord.fromMap(Map<String, dynamic> map) => WaterRecord(
    id: map['id'],
    data: map['data'],
    quantidadeMl: map['quantidadeMl'],
    pesoAtualKg: map['pesoAtualKg'],
  );
}

class SplashScreen extends StatefulWidget {
  final Function(bool) onThemeChanged;
  final bool isDarkMode;

  const SplashScreen({
    super.key,
    required this.onThemeChanged,
    required this.isDarkMode,
  });

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  late bool _darkMode;

  @override
  void initState() {
    super.initState();
    _darkMode = widget.isDarkMode;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Image.asset(
              '/imagem.jpg',
              width: 150,
              height: 150,
              fit: BoxFit.contain,
              errorBuilder: (context, error, stackTrace) {
                return const Icon(
                  Icons.water_drop,
                  size: 120,
                  color: primaryNavyBlue,
                );
              },
            ),
            const SizedBox(height: 40),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Text(
                  'Tema escuro',
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
                Switch(
                  activeThumbColor: lightBlueAccent,
                  value: _darkMode,
                  onChanged: (value) {
                    setState(() => _darkMode = value);
                    widget.onThemeChanged(value);
                  },
                ),
              ],
            ),
            const SizedBox(height: 20),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: primaryNavyBlue,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(
                  horizontal: 40,
                  vertical: 12,
                ),
              ),
              onPressed: () {
                Navigator.pushReplacement(
                  context,
                  MaterialPageRoute(builder: (context) => const HomeScreen()),
                );
              },
              child: const Text('Entrar'),
            ),
          ],
        ),
      ),
    );
  }
}

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  List<WaterRecord> _records = [];

  @override
  void initState() {
    super.initState();
    _loadRecords();
  }

  Future<void> _loadRecords() async {
    final prefs = await SharedPreferences.getInstance();
    final String? recordsJson = prefs.getString('water_records');
    if (recordsJson != null) {
      final List<dynamic> decoded = jsonDecode(recordsJson);
      setState(() {
        _records = decoded.map((item) => WaterRecord.fromMap(item)).toList();
      });
    }
  }

  Future<void> _saveRecords() async {
    final prefs = await SharedPreferences.getInstance();
    final String encoded = jsonEncode(_records.map((r) => r.toMap()).toList());
    await prefs.setString('water_records', encoded);
  }

  void _deleteRecord(String id) {
    setState(() {
      _records.removeWhere((item) => item.id == id);
    });
    _saveRecords();
  }

  double get _totalConsumido =>
      _records.fold(0, (sum, item) => sum + item.quantidadeMl);

  double get _porcentagemMeta {
    if (_records.isEmpty) return 0.0;
    double ultimoPeso = _records.last.pesoAtualKg;
    double metaMl = ultimoPeso * 35;
    if (metaMl == 0) return 0.0;
    return (_totalConsumido / metaMl) * 100;
  }

  void _openFormModal({WaterRecord? record}) {
    final isEditing = record != null;
    final dateController = TextEditingController(
      text: isEditing ? record.data : DateTime.now().toString().split(' ')[0],
    );
    final mlController = TextEditingController(
      text: isEditing ? record.quantidadeMl.toString() : '',
    );
    final pesoController = TextEditingController(
      text: isEditing ? record.pesoAtualKg.toString() : '',
    );

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (ctx) => Padding(
        padding: EdgeInsets.only(
          top: 20,
          left: 20,
          right: 20,
          bottom: MediaQuery.of(ctx).viewInsets.bottom + 20,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              isEditing ? 'Editar Registro' : 'Novo Registro',
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                color: primaryNavyBlue,
                fontWeight: FontWeight.bold,
              ),
            ),
            TextField(
              controller: dateController,
              decoration: const InputDecoration(labelText: 'Data (AAAA-MM-DD)'),
            ),
            TextField(
              controller: mlController,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(labelText: 'Quantidade (ml)'),
            ),
            TextField(
              controller: pesoController,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(labelText: 'Peso Atual (kg)'),
            ),
            const SizedBox(height: 20),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: primaryNavyBlue,
                foregroundColor: Colors.white,
              ),
              onPressed: () {
                final double? ml = double.tryParse(mlController.text);
                final double? peso = double.tryParse(pesoController.text);

                if (ml != null && peso != null) {
                  setState(() {
                    if (isEditing) {
                      record.data = dateController.text;
                      record.quantidadeMl = ml;
                      record.pesoAtualKg = peso;
                    } else {
                      _records.add(
                        WaterRecord(
                          id: DateTime.now().millisecondsSinceEpoch.toString(),
                          data: dateController.text,
                          quantidadeMl: ml,
                          pesoAtualKg: peso,
                        ),
                      );
                    }
                  });
                  _saveRecords();
                  Navigator.pop(ctx);
                }
              },
              child: Text(isEditing ? 'Salvar' : 'Adicionar'),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Consumo de agua ideal'),
        actions: [
          IconButton(
            icon: const Icon(Icons.add),
            onPressed: () => _openFormModal(),
          ),
        ],
      ),
      body: Column(
        children: [
          Card(
            color: lightBlueAccent,
            margin: const EdgeInsets.all(12),
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: [
                  Column(
                    children: [
                      const Text(
                        'Total do Dia',
                        style: TextStyle(color: Colors.white70),
                      ),
                      Text(
                        '${_totalConsumido.toStringAsFixed(0)} ml',
                        style: const TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
                    ],
                  ),
                  Column(
                    children: [
                      const Text(
                        'Meta Atingida',
                        style: TextStyle(color: Colors.white70),
                      ),
                      Text(
                        '${_porcentagemMeta.toStringAsFixed(1)}%',
                        style: const TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
          Expanded(
            child: GridView.builder(
              padding: const EdgeInsets.all(10),
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 2,
                crossAxisSpacing: 10,
                mainAxisSpacing: 10,
              ),
              itemCount: _records.length,
              itemBuilder: (ctx, index) {
                final item = _records[index];
                return GestureDetector(
                  onTap: () => _openFormModal(record: item),
                  child: Card(
                    color: Colors.white,
                    elevation: 3,
                    child: Stack(
                      children: [
                        Positioned(
                          top: 5,
                          right: 5,
                          child: IconButton(
                            icon: const Icon(
                              Icons.close,
                              color: primaryNavyBlue,
                            ),
                            onPressed: () => _deleteRecord(item.id),
                          ),
                        ),
                        Center(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Text(
                                item.data,
                                style: const TextStyle(
                                  color: Colors.grey,
                                  fontSize: 12,
                                ),
                              ),
                              const SizedBox(height: 5),
                              Text(
                                '${item.quantidadeMl} ml',
                                style: const TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 18,
                                  color: primaryNavyBlue,
                                ),
                              ),
                              Text(
                                '${item.pesoAtualKg} kg',
                                style: const TextStyle(
                                  fontSize: 12,
                                  color: Colors.black87,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
