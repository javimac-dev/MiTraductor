import 'package:flutter/material.dart';
import 'package:speech_to_text/speech_to_text.dart';
import 'package:flutter_tts/flutter_tts.dart';

void main()
{
  runApp(const MyApp());
}

class MyApp extends StatelessWidget
{
  const MyApp({super.key});

  @override
  Widget build(BuildContext context)
  {
    return const MaterialApp(
      debugShowCheckedModeBanner: false,
      home: ScreenHome(),
    );
  }
}

class ScreenHome extends StatefulWidget
{
  const ScreenHome({super.key});

  @override
  State<ScreenHome> createState() => _ScreenHomeState();
}

class _ScreenHomeState extends State<ScreenHome>
{
  final SpeechToText speechToText = SpeechToText();
  final FlutterTts flutterTts = FlutterTts();

  bool isListening = false;
  bool isSpeaking = false;

  String screenText = "Habla en español";

  @override
  void initState()
  {
    super.initState();
    _configureTts();

    flutterTts.setCompletionHandler(() async
    {
      setState(()
      {
        isSpeaking = false;
      });

      await Future.delayed(const Duration(milliseconds: 300));

      if (!isListening)
      {
        await _startListening();
      }
    });
  }

  Future<void> _configureTts() async
  {
    await flutterTts.setLanguage("es-ES");
    await flutterTts.setSpeechRate(0.5);
    await flutterTts.setVolume(1.0);
    await flutterTts.setPitch(1.0);
  }

  Future<void> _startListening() async
  {
    if (isSpeaking) return;

    final available = await speechToText.initialize(
      onStatus: (status)
      {
        debugPrint("STATUS: $status");
      },
      onError: (error)
      {
        debugPrint("ERROR: ${error.errorMsg}");
        setState(() {
          screenText = "Error: ${error.errorMsg}";
        });
      },
    );

    if (!available)
    {
      setState(()
      {
        screenText = "Speech To Text no disponible";
      });
      return;
    }

    setState(()
    {
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

      onResult: (result) async
      {
        debugPrint("TEXTO: ${result.recognizedWords}");

        if (result.recognizedWords.isNotEmpty)
        {
          setState(()
          {
            screenText = result.recognizedWords;
          });

          if (result.finalResult)
          {
            await speechToText.stop();

            setState(()
            {
              isListening = false;
              isSpeaking = true;
            });

            await flutterTts.stop();
            await flutterTts.speak(result.recognizedWords);
          }
        }
      },
    );
  }

  Future<void> _stopListening() async
  {
    await speechToText.stop();
    await flutterTts.stop();

    setState(()
    {
      isListening = false;
      isSpeaking = false;
    });
  }

  @override
  Widget build(BuildContext context)
  {
    return Scaffold(
      backgroundColor: Colors.black,
      body: SafeArea(
        child: Column(
          children:
          [
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
                onTap: () async
                {
                  if (!isListening && !isSpeaking)
                  {
                    await _startListening();
                  }
                  else
                  {
                    await _stopListening();
                  }
                },
                child: Container(
                  width: 160,
                  height: 160,
                  decoration: BoxDecoration(
                    color: (isListening || isSpeaking)
                        ? Colors.red
                        : Colors.green,
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    (isListening || isSpeaking)
                        ? Icons.stop
                        : Icons.mic,
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
