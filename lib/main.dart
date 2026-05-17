import 'package:flutter/material.dart';
import 'package:speech_to_text/speech_to_text.dart';
import 'package:flutter_tts/flutter_tts.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return const MaterialApp(
      debugShowCheckedModeBanner: false,
      home: ScreenHome(),
    );
  }
}

class ScreenHome extends StatefulWidget {
  const ScreenHome({super.key});

  @override
  State<ScreenHome> createState() => _ScreenHomeState();
}

class _ScreenHomeState extends State<ScreenHome> {
  final SpeechToText speechToText = SpeechToText();
  final FlutterTts flutterTts = FlutterTts();

  bool isBusy = false;
  bool isListening = false;
  bool isSpeaking = false;

  String screenText = "Habla en español";

  @override
  void initState() {
    super.initState();
    _configureTts();
  }

  Future<void> _configureTts() async {
    await flutterTts.setLanguage("es-ES");
    await flutterTts.setSpeechRate(0.5);
    await flutterTts.setVolume(1.0);
    await flutterTts.setPitch(1.0);

    flutterTts.setCompletionHandler(() async {
      await Future.delayed(const Duration(milliseconds: 900));
      await _safeStartListening();
    });
  }

  Future<void> _safeStartListening() async {
    if (isBusy) return;

    isBusy = true;

    await speechToText.stop();
    await Future.delayed(const Duration(milliseconds: 600));

    final available = await speechToText.initialize(
      onStatus: (status) {
        debugPrint("STATUS: $status");
      },
      onError: (error) {
        debugPrint("ERROR: ${error.errorMsg}");
        setState(() {
          screenText = "Error: ${error.errorMsg}";
        });
      },
    );

    if (!available) {
      isBusy = false;
      setState(() {
        screenText = "STT no disponible";
      });
      return;
    }

    setState(() {
      isListening = true;
      isSpeaking = false;
      screenText = "Escuchando...";
    });

    await speechToText.listen(
      localeId: "es_ES",
      listenMode: ListenMode.confirmation,
      pauseFor: const Duration(seconds: 3),
      listenFor: const Duration(seconds: 20),
      partialResults: true,
      cancelOnError: true,

      onResult: (result) async {
        final text = result.recognizedWords;
        if (text.isEmpty) return;

        setState(() {
          screenText = text;
        });

        if (result.finalResult) {
          await _handleSpeech(text);
        }
      },
    );

    isBusy = false;
  }

  Future<void> _handleSpeech(String text) async {
    if (isBusy) return;

    isBusy = true;

    await speechToText.stop();

    setState(() {
      isListening = false;
      isSpeaking = true;
    });

    await flutterTts.stop();
    await flutterTts.speak(text);

    // 🔥 clave: cooldown REAL del motor Android
    await Future.delayed(const Duration(milliseconds: 1200));

    isBusy = false;
  }

  Future<void> _stopAll() async {
    await speechToText.cancel();
    await speechToText.stop();
    await flutterTts.stop();

    isBusy = false;

    setState(() {
      isListening = false;
      isSpeaking = false;
      screenText = "Detenido";
    });
  }

  @override
  Widget build(BuildContext context) {
    final active = isListening || isSpeaking || isBusy;

    return Scaffold(
      backgroundColor: Colors.black,
      body: SafeArea(
        child: Column(
          children: [
            Expanded(
              child: Center(
                child: Padding(
                  padding: const EdgeInsets.all(30),
                  child: Text(
                    screenText,
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 42,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.only(bottom: 50),
              child: GestureDetector(
                onTap: () async {
                  if (!active) {
                    await _safeStartListening();
                  } else {
                    await _stopAll();
                  }
                },
                child: Container(
                  width: 160,
                  height: 160,
                  decoration: BoxDecoration(
                    color: active ? Colors.red : Colors.green,
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    active ? Icons.stop : Icons.mic,
                    color: Colors.white,
                    size: 80,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
