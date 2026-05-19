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

  bool isActive = false;

  String screenText = "Habla en español";

  @override
  void initState() {
    super.initState();
    _configureTts();
  }

  Future<void> _configureTts() async {
    await flutterTts.setLanguage("es-ES");
    await flutterTts.setSpeechRate(0.5);
  }

  Future<void> _start() async {
    final available = await speechToText.initialize(
      onError: (error) async {
        debugPrint("ERROR: ${error.errorMsg}");

        // silencios normales del usuario
        if (
            error.errorMsg == "error_no_match" ||
            error.errorMsg == "error_speech_timeout" ||
            error.errorMsg == "error_speech_time_out"
        ) {
          await _stop();

          setState(() {
            screenText = "No escuché nada";
          });

          return;
        }

        setState(() {
          screenText = "Error: ${error.errorMsg}";
          isActive = false;
        });
      },
    );

    if (!available) {
      setState(() {
        screenText = "STT no disponible";
      });
      return;
    }

    setState(() {
      isActive = true;
      screenText = "Escuchando...";
    });

    await speechToText.listen(
      localeId: "es_ES",
      listenMode: ListenMode.confirmation,

      // más tolerante para frases largas
      pauseFor: const Duration(seconds: 8),
      listenFor: const Duration(minutes: 2),

      partialResults: true,
      cancelOnError: true,

      onResult: (result) async {
        final text = result.recognizedWords;

        if (text.isEmpty) return;

        setState(() {
          screenText = text;
        });

        if (result.finalResult) {
          await speechToText.stop();

          await flutterTts.stop();
          await flutterTts.speak(text);

          setState(() {
            isActive = false;
          });
        }
      },
    );
  }

  Future<void> _stop() async {
    await speechToText.stop();
    await flutterTts.stop();

    setState(() {
      isActive = false;
      screenText = "Detenido";
    });
  }

  @override
  Widget build(BuildContext context) {
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
                  if (!isActive) {
                    await _start();
                  } else {
                    await _stop();
                  }
                },
                child: Container(
                  width: 160,
                  height: 160,
                  decoration: BoxDecoration(
                    color: isActive ? Colors.red : Colors.green,
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    isActive ? Icons.stop : Icons.mic,
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