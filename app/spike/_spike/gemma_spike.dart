import 'dart:async';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_gemma/flutter_gemma.dart';
import 'package:path_provider/path_provider.dart';

const String _modelFileName = 'gemma-4-E2B-it.litertlm';

const String _systemInstruction = '''
You are ChalkLens, an offline classroom co-pilot for low-resource teachers.
Given a textbook passage, return a complete classroom kit as STRICT JSON.
Use only information present in the passage. If something is missing, write "N/A".
Output ONLY the JSON object — no prose, no markdown fences.

JSON schema:
{
  "lesson_title": string,
  "grade": string,
  "subject": string,
  "language": string,
  "learning_objectives": [string, ...],
  "simple_explanation": string,
  "blackboard_notes": [string, ...],
  "local_example": string,
  "oral_quiz": [string, ...],
  "group_activity": string,
  "homework": [string, ...],
  "glossary": [{"term": string, "meaning": string}, ...],
  "easy_version": string
}
''';

const String _samplePassage = '''
Grade: Class 5
Subject: Science
Language: English

Passage:
Evaporation is the process by which liquid water changes into water vapor.
This happens because heat gives water molecules enough energy to escape into
the air. Wet clothes drying in sunlight, puddles disappearing after rain,
and water boiling in a pot are all examples of evaporation. Evaporation is
an important part of the water cycle.
''';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  FlutterGemma.initialize(maxDownloadRetries: 3);
  runApp(const SpikeApp());
}

class SpikeApp extends StatelessWidget {
  const SpikeApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'ChalkLens — Spike',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.indigo),
        useMaterial3: true,
      ),
      home: const SpikeHome(),
    );
  }
}

class SpikeHome extends StatefulWidget {
  const SpikeHome({super.key});

  @override
  State<SpikeHome> createState() => _SpikeHomeState();
}

enum _Stage {
  idle,
  checkingModel,
  installingModel,
  loadingModel,
  generating,
  done,
  error,
}

class _SpikeHomeState extends State<SpikeHome> {
  _Stage _stage = _Stage.idle;
  String _status = 'Ready. Tap "Run Gemma 4 spike" to begin.';
  String _response = '';
  String? _modelPath;
  int _tokenCount = 0;

  Future<void> _runSpike() async {
    setState(() {
      _stage = _Stage.checkingModel;
      _status = 'Checking for model file...';
      _response = '';
      _tokenCount = 0;
    });

    try {
      final docDir = await getApplicationDocumentsDirectory();
      final modelPath = '${docDir.path}/$_modelFileName';
      _modelPath = modelPath;

      if (!await File(modelPath).exists()) {
        setState(() {
          _stage = _Stage.error;
          _status = 'Model file not found. See README for download steps.';
          _response = 'Expected at:\n$modelPath';
        });
        return;
      }

      setState(() {
        _stage = _Stage.installingModel;
        _status = 'Registering model with flutter_gemma...';
      });

      await FlutterGemma.installModel(
        modelType: ModelType.gemmaIt,
      ).fromFile(modelPath).install();

      setState(() {
        _stage = _Stage.loadingModel;
        _status = 'Loading Gemma 4 E2B (10-30s on first run)...';
      });

      final model = await FlutterGemma.getActiveModel(
        maxTokens: 2048,
        preferredBackend: PreferredBackend.gpu,
      );

      final chat = await model.createChat(
        systemInstruction: _systemInstruction,
      );

      await chat.addQueryChunk(
        Message.text(text: _samplePassage, isUser: true),
      );

      setState(() {
        _stage = _Stage.generating;
        _status = 'Generating LessonKit JSON...';
      });

      final stopwatch = Stopwatch()..start();
      final buffer = StringBuffer();
      final stream = chat.generateChatResponseAsync();
      await for (final chunk in stream) {
        if (chunk is TextResponse) {
          buffer.write(chunk.token);
          _tokenCount++;
          if (_tokenCount % 4 == 0) {
            setState(() {
              _response = buffer.toString();
            });
          }
        }
      }
      stopwatch.stop();

      await model.close();

      final tps = _tokenCount / (stopwatch.elapsed.inMilliseconds / 1000.0);

      setState(() {
        _stage = _Stage.done;
        _response = buffer.toString();
        _status =
            'Done. $_tokenCount tokens in '
            '${stopwatch.elapsed.inMilliseconds}ms '
            '(~${tps.toStringAsFixed(1)} tok/s)';
      });

      // ignore: avoid_print
      print('=== ChalkLens spike output ===');
      // ignore: avoid_print
      print(buffer.toString());
      // ignore: avoid_print
      print('=== $_status ===');
    } catch (e, stack) {
      setState(() {
        _stage = _Stage.error;
        _status = 'Error: $e';
        _response = stack.toString();
      });
      // ignore: avoid_print
      print('Spike error: $e\n$stack');
    }
  }

  bool get _busy =>
      _stage != _Stage.idle && _stage != _Stage.done && _stage != _Stage.error;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('ChalkLens — Gemma 4 Spike')),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(12),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Status',
                        style: Theme.of(context).textTheme.labelLarge,
                      ),
                      const SizedBox(height: 4),
                      Text(_status),
                      if (_modelPath != null) ...[
                        const SizedBox(height: 8),
                        Text(
                          'Model path: $_modelPath',
                          style: Theme.of(context).textTheme.bodySmall,
                        ),
                      ],
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 12),
              FilledButton.icon(
                onPressed: _busy ? null : _runSpike,
                icon: _busy
                    ? const SizedBox(
                        width: 16,
                        height: 16,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Icon(Icons.play_arrow),
                label: Text(_busy ? 'Working...' : 'Run Gemma 4 spike'),
              ),
              const SizedBox(height: 12),
              Expanded(
                child: Card(
                  child: Padding(
                    padding: const EdgeInsets.all(12),
                    child: SingleChildScrollView(
                      child: SelectableText(
                        _response.isEmpty
                            ? '(LessonKit JSON output will appear here)'
                            : _response,
                        style: const TextStyle(
                          fontFamily: 'Courier',
                          fontSize: 12,
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
