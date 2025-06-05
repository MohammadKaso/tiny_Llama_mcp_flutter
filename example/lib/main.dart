import 'dart:async';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'package:edge_mcp_flutter/edge_mcp_flutter.dart';

void main() {
  runApp(const EdgeMcpFlutterApp());
}

class EdgeMcpFlutterApp extends StatelessWidget {
  const EdgeMcpFlutterApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'EdgeMcp Flutter Demo',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.blue),
        useMaterial3: true,
      ),
      home: const MyHomePage(title: 'EdgeMcp Flutter Demo'),
    );
  }
}

class MyHomePage extends StatefulWidget {
  const MyHomePage({super.key, required this.title});

  final String title;

  @override
  State<MyHomePage> createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> with TickerProviderStateMixin {
  late EdgeLlmIOS _llm;
  late AnimationController _fpsController;
  late Animation<double> _fpsAnimation;

  final TextEditingController _promptController = TextEditingController();
  final TextEditingController _systemController = TextEditingController();

  String _responseText = '';
  bool _isGenerating = false;
  bool _showTelemetry = false;
  ModelCapability? _deviceCapability;
  TelemetryStats? _telemetryStats;

  // FPS monitoring
  double _currentFps = 60.0;
  Timer? _fpsTimer;

  @override
  void initState() {
    super.initState();

    _fpsController = AnimationController(
      duration: const Duration(milliseconds: 500),
      vsync: this,
    );
    _fpsAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(_fpsController);

    _initializeLLM();
    _startFpsMonitoring();
  }

  void _initializeLLM() async {
    try {
      print('🚀 Starting LLM initialization...');

      _llm = EdgeLlmIOS(
        policy: Policy.auto(
          preferOnDevice: true,
          maxFirstToken: const Duration(milliseconds: 20000),
          allowCloudFallback:
              false, // Disable cloud fallback to debug device issues
        ),
        cloud: const OpenAIConfig(
          apiKey: 'demo-key', // In real app, use environment variable
          model: 'gpt-4o',
        ),
        enableTelemetry: true,
      );

      print('📱 Evaluating device capabilities...');
      await _llm.initialize();

      setState(() {
        _deviceCapability = _llm.deviceCapability;
      });

      print('✅ LLM initialization complete!');
      print('🧠 Neural Engine: ${_deviceCapability?.hasNeuralEngine}');
      print('💾 Available Memory: ${_deviceCapability?.availableMemoryGB} GB');
      print('📱 Device Model: ${_deviceCapability?.deviceModel}');
      print('🔋 Battery Level: ${_deviceCapability?.batteryLevel}');
      print('🏃 Performance Tier: ${_deviceCapability?.performanceTier}');
      print(
          '⚡ Est. First Token: ${_deviceCapability?.estimateFirstTokenLatencyMs()} ms');
      print(
          '📊 Est. Tokens/sec: ${_deviceCapability?.estimateTokensPerSecond()}');
      print('⚙️ CPU Cores: ${_deviceCapability?.cpuCoreCount}');
      print('🔋 Low Power Mode: ${_deviceCapability?.isLowPowerMode}');
      print('💫 OS Version: ${_deviceCapability?.osVersion}');

      _fpsController.forward();
    } catch (e) {
      print('❌ LLM initialization failed: $e');
      _showErrorDialog('Initialization Error', e.toString());
    }
  }

  void _startFpsMonitoring() {
    _fpsTimer = Timer.periodic(const Duration(milliseconds: 100), (timer) {
      // Simulate FPS monitoring - in real app would measure actual frame timing
      final baseFps = _isGenerating ? 45.0 : 60.0;
      final variance =
          (DateTime.now().millisecondsSinceEpoch % 1000) / 1000 * 10;
      setState(() {
        _currentFps = baseFps + variance;
      });
    });
  }

  void _generateText() async {
    if (_promptController.text.isEmpty) {
      _showErrorDialog('Error', 'Please enter a prompt');
      return;
    }

    setState(() {
      _isGenerating = true;
      _responseText = '';
    });

    try {
      print('🎯 Starting text generation...');
      print('📝 Prompt: "${_promptController.text}"');
      print('⚙️ System: "${_systemController.text}"');

      final stream = _llm.generate(
        prompt: _promptController.text,
        system: _systemController.text.isEmpty ? null : _systemController.text,
      );

      print('📡 Stream created, waiting for tokens...');
      await for (final chunk in stream) {
        setState(() {
          // Add proper spacing between tokens
          if (_responseText.isNotEmpty &&
              !_isPunctuation(chunk) &&
              !_responseText.endsWith(' ')) {
            _responseText += ' ';
          }
          _responseText += chunk;
        });
        print('🎯 Received token: "$chunk"');
      }

      print('✅ Text generation completed successfully!');

      // Update telemetry stats
      setState(() {
        _telemetryStats = _llm.getStats(const Duration(minutes: 5));
      });
    } catch (e) {
      print('❌ Text generation failed: $e');
      print('🔍 Error type: ${e.runtimeType}');
      _showErrorDialog('Generation Error', e.toString());
    } finally {
      setState(() {
        _isGenerating = false;
      });
    }
  }

  void _showErrorDialog(String title, String message) {
    if (Platform.isIOS || Platform.isMacOS) {
      showCupertinoDialog(
        context: context,
        builder: (context) => CupertinoAlertDialog(
          title: Text(title),
          content: Text(message),
          actions: [
            CupertinoDialogAction(
              child: const Text('OK'),
              onPressed: () => Navigator.of(context).pop(),
            ),
          ],
        ),
      );
    } else {
      showDialog(
        context: context,
        builder: (context) => AlertDialog(
          title: Text(title),
          content: Text(message),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('OK'),
            ),
          ],
        ),
      );
    }
  }

  bool _isPunctuation(String token) {
    // Check if token is punctuation that shouldn't have space before it
    return ['.', ',', '!', '?', ';', ':', "'", '"', ')', ']', '}']
        .contains(token);
  }

  Widget _buildFpsOverlay() {
    return AnimatedBuilder(
      animation: _fpsAnimation,
      builder: (context, child) {
        return Opacity(
          opacity: _fpsAnimation.value,
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: Colors.black87,
              borderRadius: BorderRadius.circular(16),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  Icons.speed,
                  color: _currentFps > 50 ? Colors.green : Colors.orange,
                  size: 16,
                ),
                const SizedBox(width: 4),
                Text(
                  '${_currentFps.toStringAsFixed(1)} FPS',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildTelemetryPanel() {
    if (!_showTelemetry || _telemetryStats == null)
      return const SizedBox.shrink();

    return Container(
      margin: const EdgeInsets.all(16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.grey[100],
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey[300]!),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Performance Telemetry',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 12),
          _buildTelemetryRow('Success Rate',
              '${_telemetryStats!.successRate.toStringAsFixed(1)}%'),
          _buildTelemetryRow('Device Usage',
              '${_telemetryStats!.deviceUsageRate.toStringAsFixed(1)}%'),
          _buildTelemetryRow('Avg Latency',
              '${_telemetryStats!.avgFirstTokenLatencyMs.toStringAsFixed(0)}ms'),
          _buildTelemetryRow('Tokens/sec',
              _telemetryStats!.avgTokensPerSecond.toStringAsFixed(1)),
          _buildTelemetryRow('Memory Usage',
              '${_telemetryStats!.avgMemoryUsageMB.toStringAsFixed(1)} MB'),
          _buildTelemetryRow(
              'Avg FPS', _telemetryStats!.avgFps.toStringAsFixed(1)),
        ],
      ),
    );
  }

  Widget _buildTelemetryRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label),
          Text(
            value,
            style: const TextStyle(fontWeight: FontWeight.bold),
          ),
        ],
      ),
    );
  }

  Widget _buildDeviceInfo() {
    if (_deviceCapability == null) return const SizedBox.shrink();

    return Container(
      margin: const EdgeInsets.all(16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.blue[50],
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.blue[200]!),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Device Capabilities',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: Colors.blue,
            ),
          ),
          const SizedBox(height: 8),
          Text('Model: ${_deviceCapability!.deviceModel}'),
          Text(
              'Neural Engine: ${_deviceCapability!.hasNeuralEngine ? "✅" : "❌"}'),
          Text(
              'Memory: ${_deviceCapability!.availableMemoryGB.toStringAsFixed(1)} GB'),
          Text('Performance Tier: ${_deviceCapability!.performanceTier.name}'),
          Text(
              'Est. Latency: ${_deviceCapability!.estimateFirstTokenLatencyMs()} ms'),
          Text(
              'Est. Tokens/sec: ${_deviceCapability!.estimateTokensPerSecond().toStringAsFixed(1)}'),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final bool isIOS = Platform.isIOS || Platform.isMacOS;

    return Scaffold(
      appBar: isIOS
          ? CupertinoNavigationBar(
              middle: Text(widget.title),
              trailing: CupertinoButton(
                padding: EdgeInsets.zero,
                child: const Icon(CupertinoIcons.graph_circle),
                onPressed: () =>
                    setState(() => _showTelemetry = !_showTelemetry),
              ),
            ) as PreferredSizeWidget
          : AppBar(
              backgroundColor: Theme.of(context).colorScheme.inversePrimary,
              title: Text(widget.title),
              actions: [
                IconButton(
                  icon: const Icon(Icons.analytics),
                  onPressed: () =>
                      setState(() => _showTelemetry = !_showTelemetry),
                ),
              ],
            ),
      body: Stack(
        children: [
          SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                _buildDeviceInfo(),
                TextField(
                  controller: _systemController,
                  decoration: const InputDecoration(
                    labelText: 'System Message (Optional)',
                    hintText: 'You are a helpful B2B assistant.',
                    border: OutlineInputBorder(),
                  ),
                  textInputAction: TextInputAction.done,
                  maxLines: 2,
                ),
                const SizedBox(height: 16),
                TextField(
                  controller: _promptController,
                  decoration: const InputDecoration(
                    labelText: 'Prompt',
                    hintText:
                        'Summarise today\'s sales orders in three bullet points.',
                    border: OutlineInputBorder(),
                  ),
                  maxLines: 3,                  textInputAction: TextInputAction.done,

                ),
                const SizedBox(height: 16),
                isIOS
                    ? CupertinoButton.filled(
                        onPressed: _isGenerating ? null : _generateText,
                        child: _isGenerating
                            ? const CupertinoActivityIndicator(
                                color: Colors.white)
                            : const Text('Generate'),
                      )
                    : ElevatedButton(
                        onPressed: _isGenerating ? null : _generateText,
                        child: _isGenerating
                            ? const SizedBox(
                                width: 20,
                                height: 20,
                                child:
                                    CircularProgressIndicator(strokeWidth: 2),
                              )
                            : const Text('Generate'),
                      ),
                const SizedBox(height: 24),
                if (_responseText.isNotEmpty) ...[
                  const Text(
                    'Response:',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.grey[50],
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: Colors.grey[300]!),
                    ),
                    child: Text(
                      _responseText,
                      style: const TextStyle(fontSize: 16),
                    ),
                  ),
                ],
                _buildTelemetryPanel(),
              ],
            ),
          ),

          // FPS Overlay
          Positioned(
            top: 16,
            right: 16,
            child: _buildFpsOverlay(),
          ),
        ],
      ),
    );
  }

  @override
  void dispose() {
    _fpsController.dispose();
    _fpsTimer?.cancel();
    _promptController.dispose();
    _systemController.dispose();
    _llm.dispose();
    super.dispose();
  }
}
