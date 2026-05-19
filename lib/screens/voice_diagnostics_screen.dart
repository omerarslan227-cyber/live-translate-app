part of '../main.dart';

class VoiceDiagnosticsScreen extends StatefulWidget {
  const VoiceDiagnosticsScreen({super.key});

  @override
  State<VoiceDiagnosticsScreen> createState() => _VoiceDiagnosticsScreenState();
}

class _VoiceDiagnosticsScreenState extends State<VoiceDiagnosticsScreen> {
  final FlutterSoundRecorder _diagnosticRecorder = FlutterSoundRecorder();
  final FlutterTts _diagnosticTts = FlutterTts();

  bool _running = false;
  bool _recorderReady = false;
  String _summary = 'Test baÅŸlatÄ±lmadÄ±';
  final Map<String, String> _results = {
    'Mikrofon izni': 'Bekliyor',
    'KayÄ±t': 'Bekliyor',
    'Audio format': 'Bekliyor',
    'Backend': 'Bekliyor',
    'STT': 'Bekliyor',
    'Ã‡eviri': 'Bekliyor',
    'TTS': 'Bekliyor',
    'Toplam sÃ¼re': 'Bekliyor',
  };
  final List<String> _logs = [];

  @override
  void initState() {
    super.initState();
    _prepare();
  }

  Future<void> _prepare() async {
    try {
      if (!_recorderReady) {
        await _diagnosticRecorder.openRecorder();
      }
      await configureCallTts(_diagnosticTts);
      if (mounted) setState(() => _recorderReady = true);
    } catch (e) {
      debugPrint('[BridgeCallVoiceDiag] Recorder prepare failed: $e');
      if (mounted) setState(() => _recorderReady = false);
    }
  }

  @override
  void dispose() {
    _diagnosticRecorder.closeRecorder();
    _diagnosticTts.stop();
    super.dispose();
  }

  void _setResult(String key, String value) {
    setState(() {
      _results[key] = value;
      _logs.insert(
        0,
        '${DateTime.now().toIso8601String().substring(11, 19)}  $key: $value',
      );
    });
    debugPrint('[BridgeCallVoiceDiag] $key: $value');
  }

  Future<void> _runDiagnostics() async {
    if (_running) return;
    setState(() {
      _running = true;
      _summary = 'TanÄ±lama Ã§alÄ±ÅŸÄ±yor...';
      _logs.clear();
      for (final key in _results.keys.toList()) {
        _results[key] = 'Bekliyor';
      }
    });

    final started = DateTime.now();
    try {
      final permissionReady = await _requestMicrophoneForDiagnostics();
      if (!permissionReady) return;

      final health = await _fetchBackendHealth();
      _setResult(
        'Backend',
        health == null
            ? 'BaÅŸarÄ±sÄ±z: health cevabÄ± yok'
            : 'BaÅŸarÄ±lÄ±: model=${health['whisper_model']} beam=${health['whisper_beam_size']}',
      );
      if (health == null) return;

      if (!_recorderReady) {
        await _prepare();
      }
      if (!_recorderReady) {
        _setResult('KayÄ±t', 'BaÅŸarÄ±sÄ±z: recorder aÃ§Ä±lamadÄ±');
        setState(
          () => _summary =
              'Mikrofon izni aÃ§Ä±k gÃ¶rÃ¼nÃ¼yor ama kayÄ±t motoru baÅŸlatÄ±lamadÄ±. UygulamayÄ± tamamen kapatÄ±p yeni build ile tekrar dene.',
        );
        return;
      }

      final path = await _diagnosticPath();
      _setResult('KayÄ±t', '2 saniye konuÅŸ...');
      await _diagnosticRecorder.startRecorder(
        toFile: path,
        codec: Codec.pcm16WAV,
        numChannels: 1,
        sampleRate: 16000,
        audioSource: AudioSource.voice_communication,
        enableVoiceProcessing: true,
        enableNoiseSuppression: true,
        enableEchoCancellation: true,
      );
      await Future.delayed(const Duration(seconds: 2));
      final savedPath = await _diagnosticRecorder.stopRecorder();
      if (savedPath == null) {
        _setResult('KayÄ±t', 'BaÅŸarÄ±sÄ±z: dosya yolu boÅŸ');
        return;
      }

      final file = File(savedPath);
      if (!await file.exists()) {
        _setResult('KayÄ±t', 'BaÅŸarÄ±sÄ±z: dosya oluÅŸmadÄ±');
        return;
      }

      final bytes = await file.readAsBytes();
      final rms = calculateWavRms(bytes);
      _setResult(
        'KayÄ±t',
        'BaÅŸarÄ±lÄ±: ${bytes.length} byte, RMS ${rms.toStringAsFixed(0)}',
      );
      _setResult('Audio format', 'pcm16wav, 16kHz, mono');
      if (bytes.length < 12000 || rms < 60) {
        _setResult('STT', 'AtlandÄ±: ses Ã§ok dÃ¼ÅŸÃ¼k veya kÄ±sa');
        setState(
          () => _summary =
              'Mikrofon Ã§alÄ±ÅŸÄ±yor ama ses seviyesi dÃ¼ÅŸÃ¼k gÃ¶rÃ¼nÃ¼yor.',
        );
        return;
      }

      final response = await _sendAudioToBackend(bytes);
      if (response == null) {
        _setResult('STT', 'BaÅŸarÄ±sÄ±z: backend cevap vermedi');
        return;
      }
      if (response['noSpeech'] == true) {
        _setResult('STT', 'BaÅŸarÄ±sÄ±z: backend ses algÄ±lamadÄ±');
        _setResult('Toplam sÃ¼re', '${response['timingMs'] ?? '-'}');
        return;
      }
      if (response['error'] != null) {
        _setResult('STT', 'BaÅŸarÄ±sÄ±z: ${response['error']}');
        return;
      }

      final original = (response['original'] ?? '').toString();
      final translated = (response['translated'] ?? '').toString();
      _setResult(
        'STT',
        original.isEmpty
            ? 'BaÅŸarÄ±sÄ±z: boÅŸ metin'
            : 'BaÅŸarÄ±lÄ±: $original',
      );
      _setResult(
        'Ã‡eviri',
        translated.isEmpty
            ? 'BaÅŸarÄ±sÄ±z: boÅŸ Ã§eviri'
            : 'BaÅŸarÄ±lÄ±: $translated',
      );
      _setResult('Toplam sÃ¼re', '${response['timingMs'] ?? '-'}');

      if (translated.isNotEmpty) {
        await _diagnosticRecorder.closeRecorder();
        _recorderReady = false;
        await Future.delayed(const Duration(milliseconds: 350));
        await _diagnosticTts.stop();
        await configureSpeakerTts(_diagnosticTts);
        await _diagnosticTts.awaitSpeakCompletion(true);
        await _diagnosticTts.setLanguage('en-US');
        await _diagnosticTts.speak(translated);
        _setResult('TTS', 'BaÅŸarÄ±lÄ±: cihaz TTS baÅŸlatÄ±ldÄ±');
      } else {
        _setResult('TTS', 'AtlandÄ±: Ã§eviri yok');
      }

      final elapsed = DateTime.now().difference(started).inMilliseconds;
      setState(() => _summary = 'TanÄ±lama tamamlandÄ± (${elapsed}ms).');
    } catch (e) {
      setState(() => _summary = 'TanÄ±lama hatasÄ±: $e');
      _logs.insert(0, 'Hata: $e');
    } finally {
      if (mounted) setState(() => _running = false);
    }
  }

  Future<String> _diagnosticPath() async {
    final dir = await getTemporaryDirectory();
    return '${dir.path}/bridgecall_voice_diagnostic.wav';
  }

  Future<bool> _requestMicrophoneForDiagnostics() async {
    final status = await Permission.microphone.status;
    debugPrint(
      '[BridgeCallVoiceDiag] Microphone permission status: ${status.name}',
    );
    if (status.isGranted) {
      _setResult('Mikrofon izni', 'BaÅŸarÄ±lÄ±');
      return true;
    }

    final requested = await Permission.microphone.request();
    debugPrint(
      '[BridgeCallVoiceDiag] Microphone permission requested: ${requested.name}',
    );
    if (requested.isGranted) {
      _setResult('Mikrofon izni', 'BaÅŸarÄ±lÄ±');
      return true;
    }

    final probed = await _probeMicrophoneAccess();
    if (probed) {
      _setResult(
        'Mikrofon izni',
        'BaÅŸarÄ±lÄ±: iOS ayarÄ± aÃ§Ä±k, WebRTC doÄŸruladÄ±',
      );
      return true;
    }

    final message = requested.isPermanentlyDenied || requested.isRestricted
        ? 'BaÅŸarÄ±sÄ±z: iOS Ayarlar > BridgeCall > Mikrofon aÃ§Ä±lmalÄ±'
        : 'BaÅŸarÄ±sÄ±z: ${requested.name}';
    _setResult('Mikrofon izni', message);
    setState(
      () => _summary =
          'Mikrofon izni aÃ§Ä±k gÃ¶rÃ¼nse bile uygulama gerÃ§ek mikrofon eriÅŸimi alamadÄ±. UygulamayÄ± kapatÄ±p aÃ§ veya yeni buildi tekrar kur.',
    );
    return false;
  }

  Future<bool> _probeMicrophoneAccess() async {
    MediaStream? stream;
    try {
      stream = await navigator.mediaDevices.getUserMedia({
        'audio': {
          'echoCancellation': true,
          'noiseSuppression': true,
          'autoGainControl': true,
        },
        'video': false,
      });
      return stream.getAudioTracks().isNotEmpty;
    } catch (e) {
      debugPrint('[BridgeCallVoiceDiag] Microphone probe failed: $e');
      return false;
    } finally {
      for (final track in stream?.getTracks() ?? <MediaStreamTrack>[]) {
        await track.stop();
      }
    }
  }

  Future<Map<String, dynamic>?> _fetchBackendHealth() async {
    final healthUri = AppConfig.healthUri;
    if (healthUri == null) {
      _logs.insert(0, 'Backend config eksik: WS_URL verilmedi');
      return null;
    }
    final client = HttpClient();
    try {
      final request = await client
          .getUrl(healthUri)
          .timeout(const Duration(seconds: 10));
      final response = await request.close().timeout(
        const Duration(seconds: 10),
      );
      final body = await response.transform(utf8.decoder).join();
      if (response.statusCode != 200) return null;
      return jsonDecode(body) as Map<String, dynamic>;
    } catch (e) {
      _logs.insert(0, 'Backend health hatasÄ±: $e');
      return null;
    } finally {
      client.close(force: true);
    }
  }

  Future<Map<String, dynamic>?> _sendAudioToBackend(Uint8List bytes) async {
    final translateUri = AppConfig.wsEndpoint('translate');
    if (translateUri == null) {
      _logs.insert(0, 'Backend config eksik: WS_URL verilmedi');
      return null;
    }
    final channel = WebSocketChannel.connect(translateUri);
    try {
      channel.sink.add(
        jsonEncode({
          'audio': base64Encode(bytes),
          'sourceLang': 'TR',
          'targetLang': 'EN-US',
          'previousText': '',
        }),
      );
      final raw = await channel.stream.first.timeout(
        const Duration(seconds: 30),
      );
      return jsonDecode(raw as String) as Map<String, dynamic>;
    } catch (e) {
      _logs.insert(0, 'Backend upload/STT hatasÄ±: $e');
      return null;
    } finally {
      channel.sink.close();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        title: const Text('Ses TanÄ±lama'),
      ),
      body: ListView(
        padding: const EdgeInsets.all(18),
        children: [
          GlassCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Ses Sistemi KontrolÃ¼',
                  style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 10),
                Text(_summary, style: const TextStyle(color: Colors.white70)),
                const SizedBox(height: 16),
                FilledButton.icon(
                  style: FilledButton.styleFrom(
                    backgroundColor: AppColors.purple,
                    minimumSize: const Size.fromHeight(54),
                  ),
                  onPressed: _running ? null : _runDiagnostics,
                  icon: Icon(
                    _running ? Icons.hourglass_top_rounded : Icons.mic_rounded,
                  ),
                  label: Text(
                    _running
                        ? 'Test Ã§alÄ±ÅŸÄ±yor'
                        : '2 Saniyelik Ses Testi BaÅŸlat',
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          GlassCard(
            child: Column(
              children: _results.entries
                  .map(
                    (entry) => Padding(
                      padding: const EdgeInsets.symmetric(vertical: 8),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Icon(
                            entry.value.startsWith('BaÅŸarÄ±lÄ±')
                                ? Icons.check_circle_rounded
                                : entry.value.startsWith('BaÅŸarÄ±sÄ±z')
                                ? Icons.error_rounded
                                : Icons.info_outline_rounded,
                            color: entry.value.startsWith('BaÅŸarÄ±lÄ±')
                                ? AppColors.green
                                : entry.value.startsWith('BaÅŸarÄ±sÄ±z')
                                ? AppColors.red
                                : AppColors.yellow,
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  entry.key,
                                  style: const TextStyle(
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                const SizedBox(height: 3),
                                Text(
                                  entry.value,
                                  style: const TextStyle(color: Colors.white70),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  )
                  .toList(),
            ),
          ),
          const SizedBox(height: 16),
          GlassCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'CanlÄ± Log',
                  style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 10),
                if (_logs.isEmpty)
                  const Text(
                    'HenÃ¼z log yok',
                    style: TextStyle(color: Colors.white60),
                  )
                else
                  ..._logs
                      .take(8)
                      .map(
                        (line) => Padding(
                          padding: const EdgeInsets.only(bottom: 8),
                          child: Text(
                            line,
                            style: const TextStyle(
                              color: Colors.white70,
                              fontSize: 13,
                            ),
                          ),
                        ),
                      ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

double calculateWavRms(Uint8List bytes) {
  if (bytes.length <= 44) return 0;
  final data = ByteData.sublistView(bytes);
  double sumSquares = 0;
  var count = 0;
  for (var offset = 44; offset + 1 < bytes.length; offset += 2) {
    final sample = data.getInt16(offset, Endian.little);
    sumSquares += sample * sample;
    count += 1;
  }
  if (count == 0) return 0;
  return math.sqrt(sumSquares / count);
}
