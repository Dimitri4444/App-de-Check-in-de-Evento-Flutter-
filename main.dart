import 'package:flutter/material.dart';
import 'package:qr_flutter/qr_flutter.dart';
import 'package:mobile_scanner/mobile_scanner.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Check-in Evento',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(
          seedColor: Colors.indigo,
          brightness: Brightness.light,
        ),
        useMaterial3: true,
        appBarTheme: const AppBarTheme(
          centerTitle: true,
          elevation: 2,
        ),
      ),
      home: const CheckInPage(),
    );
  }
}

class CheckInPage extends StatefulWidget {
  const CheckInPage({super.key});

  @override
  State<CheckInPage> createState() => _CheckInPageState();
}

class _CheckInPageState extends State<CheckInPage> {
  // Controllers
  final TextEditingController _nomeController = TextEditingController();
  final TextEditingController _emailController = TextEditingController();

  // Estado
  bool _isScanning = false;
  String? _ticketNome;
  String? _ticketEmail;
  String? _qrData;

  // Lista de presença (só na memória)
  final List<String> _listaPresenca = [];
  final Set<String> _jaFezCheckIn = {}; // guarda o QR completo para evitar duplicata

  // Resultado da validação
  String? _resultadoValidacao; // ✔, ⚠ ou ✖
  Color _corResultado = Colors.grey;

  @override
  void dispose() {
    _nomeController.dispose();
    _emailController.dispose();
    super.dispose();
  }

  // ==================== GERAR INGRESSO ====================
  void _gerarIngresso() {
    final nome = _nomeController.text.trim();
    final email = _emailController.text.trim();

    if (nome.isEmpty) return;

    setState(() {
      _ticketNome = nome;
      _ticketEmail = email.isEmpty ? 'sem e-mail' : email;
      _qrData = 'CHECKIN|$nome|${email.isEmpty ? "sem-email" : email}';
      _resultadoValidacao = null; // limpa resultado anterior
    });
  }

  // ==================== PROCESSAR QR LIDO ====================
  void _processarQR(String raw) {
    // Evita ler várias vezes
    if (!_isScanning) return;

    setState(() {
      _isScanning = false;
    });

    // Formato obrigatório: CHECKIN|nome|e-mail
    if (!raw.startsWith('CHECKIN|')) {
      setState(() {
        _resultadoValidacao = '✖ QR inválido';
        _corResultado = Colors.red;
      });
      return;
    }

    final partes = raw.split('|');
    if (partes.length < 3) {
      setState(() {
        _resultadoValidacao = '✖ QR inválido';
        _corResultado = Colors.red;
      });
      return;
    }

    final nome = partes[1];
    final email = partes[2];

    // Já fez check-in?
    if (_jaFezCheckIn.contains(raw)) {
      setState(() {
        _resultadoValidacao = '⚠ Já fez check-in';
        _corResultado = Colors.orange;
      });
      return;
    }

    // Check-in válido
    setState(() {
      _jaFezCheckIn.add(raw);
      _listaPresenca.add(nome);
      _resultadoValidacao = '✔ Check-in confirmado';
      _corResultado = Colors.green;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Evento Flutter Check-in'),
        backgroundColor: Theme.of(context).colorScheme.primaryContainer,
      ),
      body: _isScanning ? _buildScanner() : _buildConteudoPrincipal(),
    );
  }

  // ==================== TELA PRINCIPAL ====================
  Widget _buildConteudoPrincipal() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // ----- GERAR INGRESSO -----
          const Text(
            'Gerar Ingresso',
            style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 12),
          TextField(
            controller: _nomeController,
            decoration: const InputDecoration(
              labelText: 'Nome',
              border: OutlineInputBorder(),
              prefixIcon: Icon(Icons.person),
            ),
            onChanged: (_) => setState(() {}), // atualiza botão
          ),
          const SizedBox(height: 12),
          TextField(
            controller: _emailController,
            decoration: const InputDecoration(
              labelText: 'E-mail',
              border: OutlineInputBorder(),
              prefixIcon: Icon(Icons.email),
            ),
            keyboardType: TextInputType.emailAddress,
          ),
          const SizedBox(height: 16),
          ElevatedButton.icon(
            onPressed: _nomeController.text.trim().isEmpty ? null : _gerarIngresso,
            icon: const Icon(Icons.qr_code),
            label: const Text('Gerar ingresso'),
            style: ElevatedButton.styleFrom(
              padding: const EdgeInsets.symmetric(vertical: 14),
            ),
          ),

          // ----- CARD DO INGRESSO -----
          if (_qrData != null) ...[
            const SizedBox(height: 24),
            Card(
              elevation: 4,
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  children: [
                    // Imagem do evento (placeholder)
                    Container(
                      height: 100,
                      width: double.infinity,
                      decoration: BoxDecoration(
                        color: Colors.indigo.shade100,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: const Icon(Icons.event, size: 50, color: Colors.indigo),
                    ),
                    const SizedBox(height: 12),
                    Text(
                      _ticketNome ?? '',
                      style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                    ),
                    Text(_ticketEmail ?? ''),
                    const SizedBox(height: 16),
                    QrImageView(
                      data: _qrData!,
                      version: QrVersions.auto,
                      size: 180,
                      backgroundColor: Colors.white,
                    ),
                  ],
                ),
              ),
            ),
          ],

          const SizedBox(height: 32),
          const Divider(),

          // ----- LER INGRESSO -----
          const Text(
            'Leitura de Ingresso',
            style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 12),
          ElevatedButton.icon(
            onPressed: () {
              setState(() {
                _isScanning = true;
                _resultadoValidacao = null;
              });
            },
            icon: const Icon(Icons.qr_code_scanner),
            label: const Text('Ler ingresso'),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.indigo,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(vertical: 14),
            ),
          ),

          // Resultado da validação
          if (_resultadoValidacao != null) ...[
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: _corResultado.withOpacity(0.15),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: _corResultado),
              ),
              child: Text(
                _resultadoValidacao!,
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: _corResultado,
                ),
                textAlign: TextAlign.center,
              ),
            ),
          ],

          const SizedBox(height: 32),
          const Divider(),

          // ----- LISTA DE PRESENÇA -----
          Text(
            'Lista de Presença (${_listaPresenca.length})',
            style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 12),
          if (_listaPresenca.isEmpty)
            const Text(
              'Ninguém fez check-in ainda.',
              style: TextStyle(color: Colors.grey),
            )
          else
            ..._listaPresenca.map((nome) => Padding(
                  padding: const EdgeInsets.symmetric(vertical: 4),
                  child: Text('• $nome', style: const TextStyle(fontSize: 16)),
                )),
        ],
      ),
    );
  }

  // ==================== SCANNER ====================
  Widget _buildScanner() {
    return Column(
      children: [
        Expanded(
          child: MobileScanner(
            onDetect: (capture) {
              final List<Barcode> barcodes = capture.barcodes;
              if (barcodes.isNotEmpty) {
                final String? raw = barcodes.first.rawValue;
                if (raw != null) {
                  _processarQR(raw);
                }
              }
            },
          ),
        ),
        Container(
          color: Colors.black87,
          padding: const EdgeInsets.all(16),
          width: double.infinity,
          child: ElevatedButton(
            onPressed: () {
              setState(() {
                _isScanning = false;
              });
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              foregroundColor: Colors.white,
            ),
            child: const Text('Cancelar'),
          ),
        ),
      ],
    );
  }
}
