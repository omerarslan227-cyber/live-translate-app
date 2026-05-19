part of '../main.dart';

class CreateRoomScreen extends StatefulWidget {
  final ProfileData? profile;

  const CreateRoomScreen({super.key, this.profile});

  @override
  State<CreateRoomScreen> createState() => _CreateRoomScreenState();
}

class _CreateRoomScreenState extends State<CreateRoomScreen> {
  final TextEditingController roomController = TextEditingController(
    text: 'oda1',
  );
  final TextEditingController codeController = TextEditingController();

  String sourceLanguageName = 'Türkçe';
  String targetLanguageName = 'İngilizce';
  int selectedCapacity = 2;
  bool showAdvanced = false;

  final List<String> languages = bridgeCallLanguageNames;
  final List<int> capacities = const [2, 4, 6, 8];

  @override
  void initState() {
    super.initState();
    codeController.text = _generateRoomCode();
    final profile = widget.profile;
    if (profile != null) {
      sourceLanguageName = profile.preferredSourceLanguage;
      targetLanguageName = profile.preferredTargetLanguage;
    }
  }

  String _generateRoomCode() {
    const alphabet = 'ABCDEFGHJKLMNPQRSTUVWXYZ23456789';
    final random = math.Random.secure();
    return List.generate(
      8,
      (_) => alphabet[random.nextInt(alphabet.length)],
    ).join();
  }

  Future<void> _openCall() async {
    if (!await UsageService.canStartCall()) {
      if (!mounted) return;
      await Navigator.push(
        context,
        MaterialPageRoute(builder: (_) => const PaywallScreen()),
      );
      if (!await UsageService.canStartCall()) return;
    }
    if (!mounted) return;
    final roomName = roomController.text.trim().isEmpty
        ? 'oda1'
        : roomController.text.trim();
    final code = codeController.text.trim().isEmpty
        ? _generateRoomCode()
        : codeController.text.trim().toUpperCase();
    final validCode = RegExp(r'^[A-Z0-9]{8,}$').hasMatch(code);
    if (!validCode) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('8 karakterli oda kodu gerekli')),
      );
      return;
    }

    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => CallScreen(
          roomName: roomName,
          privateCode: code,
          sourceLanguageName: sourceLanguageName,
          targetLanguageName: targetLanguageName,
          roomCapacity: selectedCapacity,
          isOwner: true,
        ),
      ),
    );
  }

  @override
  void dispose() {
    roomController.dispose();
    codeController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        title: const Text('Oda Oluştur'),
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(18, 6, 18, 24),
        children: [
          GlassCard(
            child: LayoutBuilder(
              builder: (context, constraints) {
                final compact = constraints.maxWidth < 360;
                final label = Row(
                  children: const [
                    Icon(
                      Icons.bolt_rounded,
                      color: AppColors.purple,
                      size: 34,
                    ),
                    SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'H?zl? Ba?lat',
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                              fontSize: 22,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          SizedBox(height: 4),
                          Text(
                            'En pop?ler ayarlarla hemen oday? olu?tur',
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(color: Colors.white70),
                          ),
                        ],
                      ),
                    ),
                  ],
                );
                final button = FilledButton(
                  style: FilledButton.styleFrom(
                    backgroundColor: AppColors.purple,
                  ),
                  onPressed: _openCall,
                  child: const Text('H?zl? Ba?lat'),
                );
                if (compact) {
                  return Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [label, const SizedBox(height: 14), button],
                  );
                }
                return Row(
                  children: [
                    Expanded(child: label),
                    const SizedBox(width: 12),
                    button,
                  ],
                );
              },
            ),
          ),
          const SizedBox(height: 16),
          GlassCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Ayarlar',
                  style: TextStyle(fontSize: 26, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 16),
                _AppTextField(
                  controller: roomController,
                  label: 'Oda adı',
                ),
                const SizedBox(height: 14),
                Row(
                  children: [
                    Expanded(
                      child: _LanguageDropdown(
                        value: sourceLanguageName,
                        label: 'Dil seçimi',
                        items: languages,
                        onChanged: (v) =>
                            setState(() => sourceLanguageName = v!),
                      ),
                    ),
                    const SizedBox(width: 14),
                    const Icon(Icons.swap_horiz_rounded, color: Colors.white54),
                    const SizedBox(width: 14),
                    Expanded(
                      child: _LanguageDropdown(
                        value: targetLanguageName,
                        label: '',
                        items: languages,
                        onChanged: (v) =>
                            setState(() => targetLanguageName = v!),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 14),
                DropdownButtonFormField<int>(
                  initialValue: selectedCapacity,
                  decoration: _inputDecoration('Oda kapasitesi'),
                  dropdownColor: AppColors.card,
                  items: capacities
                      .map(
                        (e) => DropdownMenuItem(
                          value: e,
                          child: Text('$e kişi'),
                        ),
                      )
                      .toList(),
                  onChanged: (value) =>
                      setState(() => selectedCapacity = value ?? 2),
                ),
                const SizedBox(height: 14),
                InkWell(
                  onTap: () => setState(() => showAdvanced = !showAdvanced),
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 18,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.03),
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: AppColors.border),
                    ),
                    child: Row(
                      children: [
                        const Expanded(
                          child: Text('Gelişmiş Ayarlar'),
                        ),
                        Icon(
                          showAdvanced ? Icons.expand_less : Icons.expand_more,
                        ),
                      ],
                    ),
                  ),
                ),
                if (showAdvanced) ...[
                  const SizedBox(height: 14),
                  _AppTextField(
                    controller: codeController,
                    label: 'Özel oda kodu',
                  ),
                  const SizedBox(height: 10),
                  Align(
                    alignment: Alignment.centerLeft,
                    child: TextButton.icon(
                      onPressed: () => setState(
                        () => codeController.text = _generateRoomCode(),
                      ),
                      icon: const Icon(Icons.refresh),
                      label: const Text('Yeni Kod Oluştur'),
                    ),
                  ),
                ],
              ],
            ),
          ),
          const SizedBox(height: 18),
          FilledButton.icon(
            style: FilledButton.styleFrom(
              minimumSize: const Size.fromHeight(58),
              backgroundColor: AppColors.purple,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(18),
              ),
            ),
            onPressed: _openCall,
            icon: const Icon(Icons.rocket_launch_rounded),
            label: const Text(
              'Odayı Başlat',
              style: TextStyle(fontSize: 18),
            ),
          ),
          const SizedBox(height: 10),
          TextButton.icon(
            onPressed: () async {
              final roomLink = AppStore.inviteLink(
                roomController.text.trim(),
                codeController.text.trim(),
              );
              await Share.share('BridgeCall odama katıl: $roomLink');
            },
            icon: const Icon(Icons.link_rounded),
            label: const Text('Link paylaş'),
          ),
        ],
      ),
    );
  }
}

class JoinRoomScreen extends StatefulWidget {
  final String? initialRoomName;
  final String? initialCode;
  final ProfileData? profile;

  const JoinRoomScreen({
    super.key,
    this.initialRoomName,
    this.initialCode,
    this.profile,
  });

  @override
  State<JoinRoomScreen> createState() => _JoinRoomScreenState();
}

class _JoinRoomScreenState extends State<JoinRoomScreen> {
  final TextEditingController roomController = TextEditingController();
  final TextEditingController codeController = TextEditingController();

  String sourceLanguageName = 'Türkçe';
  String targetLanguageName = 'İngilizce';

  @override
  void initState() {
    super.initState();
    roomController.text = widget.initialRoomName ?? 'oda1';
    codeController.text = widget.initialCode ?? '';
    final profile = widget.profile;
    if (profile != null) {
      sourceLanguageName = profile.preferredSourceLanguage;
      targetLanguageName = profile.preferredTargetLanguage;
    }
  }

  @override
  void dispose() {
    roomController.dispose();
    codeController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        title: const Text('Odaya Katıl'),
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(18, 10, 18, 24),
        children: [
          GlassCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _AppTextField(
                  controller: roomController,
                  label: 'Oda adı',
                ),
                const SizedBox(height: 14),
                _AppTextField(
                  controller: codeController,
                  label: 'Oda kodu',
                  hint: '8 karakterli oda kodunu gir',
                ),
                const SizedBox(height: 14),
                _LanguageDropdown(
                  value: sourceLanguageName,
                  label: 'Benim konuşma dilim',
                  items: bridgeCallLanguageNames,
                  onChanged: (value) => setState(
                    () => sourceLanguageName = value ?? 'Türkçe',
                  ),
                ),
                const SizedBox(height: 14),
                _LanguageDropdown(
                  value: targetLanguageName,
                  label: 'Dinlemek istediğim dil',
                  items: bridgeCallLanguageNames,
                  onChanged: (value) => setState(
                    () => targetLanguageName = value ?? 'İngilizce',
                  ),
                ),
                const SizedBox(height: 18),
                FilledButton.icon(
                  style: FilledButton.styleFrom(
                    minimumSize: const Size.fromHeight(56),
                    backgroundColor: AppColors.blue,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(18),
                    ),
                  ),
                  onPressed: () async {
                    final code = codeController.text.trim().toUpperCase();
                    final validCode = RegExp(r'^[A-Z0-9]{8,}$').hasMatch(code);
                    if (!validCode) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('8 karakterli oda kodunu gir'),
                        ),
                      );
                      return;
                    }
                    if (!await UsageService.canStartCall()) {
                      if (!context.mounted) return;
                      await Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => const PaywallScreen(),
                        ),
                      );
                      if (!await UsageService.canStartCall()) return;
                    }
                    if (!context.mounted) return;
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => CallScreen(
                          roomName: roomController.text.trim(),
                          privateCode: code,
                          sourceLanguageName: sourceLanguageName,
                          targetLanguageName: targetLanguageName,
                          roomCapacity: 2,
                          isOwner: false,
                        ),
                      ),
                    );
                  },
                  icon: const Icon(Icons.login_rounded),
                  label: const Text(
                    'Odaya Katıl',
                    style: TextStyle(fontSize: 18),
                  ),
                ),
                const SizedBox(height: 10),
                Center(
                  child: TextButton.icon(
                    onPressed: () async {
                      await Clipboard.setData(
                        ClipboardData(text: roomController.text.trim()),
                      );
                      if (context.mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text('Oda adı kopyalandı'),
                          ),
                        );
                      }
                    },
                    icon: const Icon(Icons.info_outline),
                    label: const Text('Oda adını kopyala'),
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

class CallScreen extends StatefulWidget {
  final String roomName;
  final String privateCode;
  final String sourceLanguageName;
  final String targetLanguageName;
  final int roomCapacity;
  final bool isOwner;

  const CallScreen({
    super.key,
    required this.roomName,
    required this.privateCode,
    required this.sourceLanguageName,
    required this.targetLanguageName,
    required this.roomCapacity,
    required this.isOwner,
  });

  @override
  State<CallScreen> createState() => _CallScreenState();
}

class _CallScreenState extends State<CallScreen> with TickerProviderStateMixin {
  final RTCVideoRenderer _localRenderer = RTCVideoRenderer();
  final RTCVideoRenderer _remoteRenderer = RTCVideoRenderer();
  final FlutterSoundRecorder _recorder = FlutterSoundRecorder();
  final FlutterTts _tts = FlutterTts();
  final TextEditingController _chatController = TextEditingController();

  MediaStream? _localStream;
  RTCPeerConnection? _peerConnection;
  ReliableWebSocketClient? _signalChannel;
  ReliableWebSocketClient? _translateChannel;

  bool micOn = true;
  bool camOn = true;
  bool subtitlesOn = true;
  bool cameraStarted = false;
  bool isRecording = false;
  bool _showChat = true;
  bool _isConnecting = false;
  bool _historySaved = false;
  bool _microphonePermissionGranted = false;
  bool _recorderReady = false;
  bool _isSpeakingTranslated = false;
  int _silentSubtitleChunks = 0;
  int? _lastAudioRms;
  int? _lastAudioBytes;
  int? _lastSttMs;
  int? _lastTranslationMs;
  int? _lastTotalMs;
  BridgeSocketStatus _signalStatus = BridgeSocketStatus.idle;
  BridgeSocketStatus _translateStatus = BridgeSocketStatus.idle;

  String partialSubtitleText = '';
  String finalSubtitleText = '';
  String partialTranslatedText = '';
  String finalTranslatedText = '';

  String remotePartialOriginalText = '';
  String remoteFinalOriginalText = '';
  String remotePartialTranslatedText = '';
  String remoteFinalTranslatedText = '';
  String statusText = 'Hazırlanıyor...';
  String? myClientId;
  int memberCount = 1;
  bool remoteMicOn = true;
  bool remoteCamOn = true;
  bool remoteSubtitlesOn = true;

  late String sourceLanguageName;
  late String targetLanguageName;
  final DateTime _callStart = DateTime.now();

  final List<_ChatMessage> _messages = [];

  String? _reactionEmoji;
  Timer? _reactionTimer;
  Timer? _durationTimer;
  Timer? _webrtcConnectTimeoutTimer;
  Timer? _iceReconnectTimer;
  DateTime? _lastConnectionFeedbackAt;
  late final AnimationController _waveController;
  late final AnimationController _glowController;
  bool _iceRestartInProgress = false;
  int _iceRestartAttempts = 0;

  final Map<String, String> sourceLanguages = bridgeCallSourceLanguages;
  final Map<String, String> targetLanguages = bridgeCallTargetLanguages;

  final Map<String, dynamic> _iceConfig =
      WebRtcConfigService.productionIceConfiguration();

  @override
  void initState() {
    super.initState();
    sourceLanguageName = widget.sourceLanguageName;
    targetLanguageName = widget.targetLanguageName;
    _waveController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1100),
    )..repeat();
    _glowController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1700),
    )..repeat(reverse: true);
    _durationTimer = Timer.periodic(const Duration(seconds: 1), (_) {
      if (mounted) setState(() {});
    });
    _initAll();
  }

  Future<void> _initAll() async {
    await _localRenderer.initialize();
    await _remoteRenderer.initialize();
    await _configureTts();
    _microphonePermissionGranted = await _ensureMicrophonePermission();
    await _openSubtitleRecorder();
    await _openCamera();
    await _joinRoom();
    if (mounted) {
      setState(() {
        statusText = widget.isOwner
            ? 'Oda hazır, katılımcı bekleniyor'
            : 'Bağlantı kuruluyor';
      });
    }
    if (subtitlesOn && _microphonePermissionGranted) {
      unawaited(_startSubtitleRecording());
    } else if (subtitlesOn && mounted) {
      setState(() {
        subtitlesOn = false;
        statusText = 'Mikrofon izni verilmedi, altyazı kapalı';
      });
    }
  }

  Future<bool> _openSubtitleRecorder() async {
    if (_recorderReady) return true;
    try {
      await _recorder.openRecorder();
      await _recorder.setSubscriptionDuration(
        const Duration(milliseconds: 200),
      );
      _recorderReady = true;
      _voiceLog('Subtitle recorder opened');
      return true;
    } catch (e) {
      _recorderReady = false;
      _voiceLog('Subtitle recorder open failed', {'error': e.toString()});
      if (mounted) {
        setState(
          () => statusText =
              'Altyazı kayıt motoru açılamadı',
        );
      }
      return false;
    }
  }

  Future<bool> _reopenSubtitleRecorder() async {
    try {
      await _recorder.stopRecorder();
    } catch (_) {}
    try {
      await _recorder.closeRecorder();
    } catch (_) {}
    _recorderReady = false;
    await Future.delayed(const Duration(milliseconds: 250));
    return _openSubtitleRecorder();
  }

  Future<bool> _ensureMicrophonePermission() async {
    final status = await Permission.microphone.status;
    _voiceLog('Microphone permission status', {'status': status.name});
    if (status.isGranted) return true;

    final requested = await Permission.microphone.request();
    _voiceLog('Microphone permission requested', {'status': requested.name});
    if (requested.isGranted) return true;

    final probed = await _probeMicrophoneAccess();
    if (probed) {
      _voiceLog('Microphone permission fallback passed', {
        'permissionHandlerStatus': requested.name,
        'probe': 'webrtc_getUserMedia',
      });
      return true;
    }

    if (mounted) {
      final message = requested.isPermanentlyDenied || requested.isRestricted
          ? 'Ayarlar > BridgeCall > Mikrofon iznini aç'
          : 'Mikrofon izni gerekli';
      setState(() => statusText = message);
    }
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
      final hasAudio = stream.getAudioTracks().isNotEmpty;
      _voiceLog('Microphone probe result', {'hasAudioTrack': hasAudio});
      return hasAudio;
    } catch (e) {
      _voiceLog('Microphone probe failed', {'error': e.toString()});
      return false;
    } finally {
      for (final track in stream?.getTracks() ?? <MediaStreamTrack>[]) {
        await track.stop();
      }
    }
  }

  Future<void> _configureTts() async {
    await configureCallTts(_tts);
    await _tts.awaitSpeakCompletion(false);
    _tts.setStartHandler(() {
      _voiceLog('Playback started');
      if (mounted) setState(() => _isSpeakingTranslated = true);
    });
    _tts.setCompletionHandler(() {
      _voiceLog('Playback ended');
      unawaited(configureCallTts(_tts));
      if (mounted) setState(() => _isSpeakingTranslated = false);
    });
    _tts.setErrorHandler((message) {
      _voiceLog('TTS error', {'message': message});
      unawaited(configureCallTts(_tts));
      if (mounted) setState(() => _isSpeakingTranslated = false);
    });
  }

  void _voiceLog(String event, [Map<String, Object?> data = const {}]) {
    debugPrint('[BridgeCallVoice] $event ${jsonEncode(data)}');
  }

  void _handleSocketStatusFeedback(BridgeSocketStatus status, String channel) {
    if (status != BridgeSocketStatus.reconnecting &&
        status != BridgeSocketStatus.disconnected) {
      return;
    }
    _triggerConnectionFeedback(
      source: channel,
      state: status.name,
      heavy: false,
    );
  }

  void _handlePeerConnectionFeedback(RTCPeerConnectionState state) {
    if (state != RTCPeerConnectionState.RTCPeerConnectionStateDisconnected &&
        state != RTCPeerConnectionState.RTCPeerConnectionStateFailed) {
      return;
    }
    _triggerConnectionFeedback(source: 'peer', state: state.name, heavy: true);
  }

  void _triggerConnectionFeedback({
    required String source,
    required String state,
    required bool heavy,
  }) {
    final now = DateTime.now();
    final last = _lastConnectionFeedbackAt;
    if (last != null && now.difference(last) < const Duration(seconds: 4)) {
      return;
    }
    _lastConnectionFeedbackAt = now;
    _voiceLog('Connection status feedback', {
      'source': source,
      'state': state,
      'heavy': heavy,
    });
    unawaited(
      heavy ? HapticFeedback.heavyImpact() : HapticFeedback.lightImpact(),
    );
    unawaited(SystemSound.play(SystemSoundType.alert));
  }

  Future<void> _openCamera() async {
    try {
      final stream = await navigator.mediaDevices.getUserMedia({
        'audio': {
          'echoCancellation': true,
          'noiseSuppression': true,
          'autoGainControl': true,
          'sampleRate': 16000,
          'channelCount': 1,
        },
        'video': {
          'facingMode': 'user',
          'width': {'ideal': 720},
          'height': {'ideal': 1280},
          'frameRate': {'ideal': 24},
        },
      });
      _localStream = stream;
      _voiceLog('WebRTC microphone opened', {
        'audioTracks': stream.getAudioTracks().length,
        'videoTracks': stream.getVideoTracks().length,
        'echoCancellation': true,
        'noiseSuppression': true,
        'autoGainControl': true,
      });
      _localRenderer.srcObject = stream;
      if (mounted) {
        setState(() {
          cameraStarted = true;
          statusText = 'Kamera açıldı';
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          statusText = 'Kamera hatası: $e';
        });
      }
    }
  }

  Future<String> _tempWavPath() async {
    final dir = await getTemporaryDirectory();
    return '${dir.path}/temp_audio.wav';
  }

  Future<void> _createPeerConnection() async {
    _peerConnection ??= await createPeerConnection(_iceConfig);
    _startWebRtcConnectTimeout();

    if (_localStream != null) {
      for (final track in _localStream!.getTracks()) {
        await _peerConnection!.addTrack(track, _localStream!);
      }
    }

    _peerConnection!.onTrack = (event) {
      if (event.streams.isEmpty) return;
      final incoming = event.streams.first;
      if (_localStream != null && incoming.id == _localStream!.id) {
        return;
      }
      _remoteRenderer.srcObject = incoming;
      if (mounted) {
        setState(() {
          statusText = 'Karşı taraf bağlandı';
        });
      }
    };

    _peerConnection!.onIceCandidate = (candidate) {
      if (candidate.candidate != null) {
        _voiceLog('ICE candidate discovered', {
          'type': WebRtcConfigService.candidateType(candidate.candidate),
          'sdpMid': candidate.sdpMid,
          'sdpMLineIndex': candidate.sdpMLineIndex,
        });
        _sendSignal({
          'type': 'candidate',
          'room': widget.roomName,
          'candidate': {
            'candidate': candidate.candidate,
            'sdpMid': candidate.sdpMid,
            'sdpMLineIndex': candidate.sdpMLineIndex,
          },
        });
      }
    };

    _peerConnection!.onIceConnectionState = (state) {
      _voiceLog('ICE connection state', {'state': state.toString()});
      if (state == RTCIceConnectionState.RTCIceConnectionStateConnected ||
          state == RTCIceConnectionState.RTCIceConnectionStateCompleted) {
        _iceRestartAttempts = 0;
        _iceReconnectTimer?.cancel();
        _webrtcConnectTimeoutTimer?.cancel();
      }
      if (state == RTCIceConnectionState.RTCIceConnectionStateDisconnected ||
          state == RTCIceConnectionState.RTCIceConnectionStateFailed) {
        _scheduleIceRestart('ice_${state.name}');
      }
    };

    _peerConnection!.onConnectionState = (state) {
      _voiceLog('Peer connection state', {'state': state.toString()});
      if (state == RTCPeerConnectionState.RTCPeerConnectionStateConnected) {
        _webrtcConnectTimeoutTimer?.cancel();
        _iceRestartAttempts = 0;
      }
      if (state == RTCPeerConnectionState.RTCPeerConnectionStateDisconnected ||
          state == RTCPeerConnectionState.RTCPeerConnectionStateFailed) {
        _handlePeerConnectionFeedback(state);
        _scheduleIceRestart('peer_${state.name}');
      }
      if (mounted) {
        setState(() {
          statusText = 'Bağlantı: $state';
        });
      }
    };
  }

  void _startWebRtcConnectTimeout() {
    _webrtcConnectTimeoutTimer?.cancel();
    _webrtcConnectTimeoutTimer = Timer(const Duration(seconds: 18), () {
      if (!mounted || _peerConnection == null || remoteReadyForUi) return;
      _voiceLog('WebRTC connection timeout', {
        'attempts': _iceRestartAttempts,
        'room': widget.roomName,
      });
      _scheduleIceRestart('connect_timeout');
    });
  }

  void _scheduleIceRestart(String reason) {
    if (_iceRestartInProgress || _peerConnection == null) return;
    if (_iceRestartAttempts >= 3) {
      _voiceLog('ICE restart limit reached', {'reason': reason});
      if (mounted) {
        setState(
          () => statusText =
              'Ağ bağlantısı zayıf, yeniden dene',
        );
      }
      return;
    }

    _iceReconnectTimer?.cancel();
    final delay = Duration(milliseconds: 700 + (_iceRestartAttempts * 600));
    _voiceLog('ICE restart scheduled', {
      'reason': reason,
      'delayMs': delay.inMilliseconds,
      'attempt': _iceRestartAttempts + 1,
    });
    _iceReconnectTimer = Timer(delay, () => unawaited(_restartIce(reason)));
  }

  Future<void> _restartIce(String reason) async {
    final peerConnection = _peerConnection;
    if (peerConnection == null || _iceRestartInProgress) return;

    _iceRestartInProgress = true;
    _iceRestartAttempts += 1;
    try {
      _voiceLog('ICE restart started', {
        'reason': reason,
        'attempt': _iceRestartAttempts,
      });
      await peerConnection.setConfiguration(_iceConfig);
      final offer = await peerConnection.createOffer({'iceRestart': true});
      await peerConnection.setLocalDescription(offer);
      _sendSignal({
        'type': 'offer',
        'room': widget.roomName,
        'sdp': offer.sdp,
        'sdpType': offer.type,
        'iceRestart': true,
      });
      if (mounted) {
        setState(
          () => statusText =
              'Ağ değişti, bağlantı yenileniyor',
        );
      }
      _startWebRtcConnectTimeout();
    } catch (e, stackTrace) {
      AppLogger.error(
        'webrtc',
        'ICE restart failed',
        {'reason': reason, 'attempt': _iceRestartAttempts},
        e,
        stackTrace,
      );
      if (mounted) {
        setState(
          () => statusText =
              'WebRTC yeniden bağlanamadı',
        );
      }
    } finally {
      _iceRestartInProgress = false;
    }
  }

  Future<void> _connectSignalSocket() async {
    if (_signalChannel != null) return;
    final signalUri = AppConfig.wsEndpoint('signal');
    if (signalUri == null) {
      if (mounted) setState(() => statusText = 'Backend config eksik: WS_URL');
      return;
    }

    _signalChannel = ReliableWebSocketClient(
      uri: signalUri,
      name: 'signal',
      onMessage: (message) async => _handleSignal(message),
      onStatus: (status) {
        _handleSocketStatusFeedback(status, 'signal');
        if (!mounted) return;
        setState(() {
          _signalStatus = status;
          statusText = 'Signal: ${status.label}';
        });
      },
      onError: (error) {
        if (mounted) {
          setState(() => statusText = 'Signal hatası: $error');
        }
      },
      onDisconnected: (reason) {
        _voiceLog('Signal socket disconnected', {'reason': reason});
      },
      onReconnected: () {
        if (!mounted) return;
        _sendSignal({
          'type': widget.isOwner ? 'create_room' : 'request_join',
          'room': widget.roomName,
          'capacity': widget.roomCapacity,
          'privateCode': widget.privateCode,
        });
        _sendMediaState();
        _scheduleIceRestart('signal_reconnected');
      },
    );
    _signalChannel!.connect();
  }

  Future<void> _joinRoom() async {
    if (_isConnecting) return;
    _isConnecting = true;

    if (!cameraStarted) {
      await _openCamera();
    }

    await _connectSignalSocket();
    await _createPeerConnection();

    if (widget.isOwner) {
      _sendSignal({
        'type': 'create_room',
        'room': widget.roomName,
        'capacity': widget.roomCapacity,
        'privateCode': widget.privateCode,
      });
    } else {
      _sendSignal({
        'type': 'request_join',
        'room': widget.roomName,
        'privateCode': widget.privateCode,
      });
    }

    _isConnecting = false;
  }

  void _connectTranslateSocket() {
    if (_translateChannel != null) return;
    final translateUri = AppConfig.wsEndpoint('translate');
    if (translateUri == null) {
      if (mounted) setState(() => statusText = 'Backend config eksik: WS_URL');
      return;
    }

    _translateChannel = ReliableWebSocketClient(
      uri: translateUri,
      name: 'translate',
      heartbeatInterval: const Duration(seconds: 20),
      onDisconnected: (reason) {
        _voiceLog('Translate socket disconnected', {'reason': reason});
      },
      onStatus: (status) {
        _handleSocketStatusFeedback(status, 'translate');
        if (!mounted) return;
        setState(() {
          _translateStatus = status;
          if (status != BridgeSocketStatus.connected) {
            statusText = 'Çeviri: ${status.label}';
          }
        });
      },
      onMessage: (message) {
        try {
          final data = jsonDecode(message);
          final timing = data['timingMs'];
          if (timing is Map) {
            _lastSttMs = _intFromJson(timing['stt']);
            _lastTranslationMs = _intFromJson(timing['translation']);
            _lastTotalMs = _intFromJson(timing['total']);
            _voiceLog('Backend response time', {
              'timingMs': timing,
              'audioBytes': data['audioBytes'],
              'format': data['format'],
            });
          }
          if (mounted && data['noSpeech'] == true) {
            _silentSubtitleChunks += 1;
            _voiceLog('STT no speech', {
              'silentChunks': _silentSubtitleChunks,
              'audioBytes': data['audioBytes'],
            });
            if (_silentSubtitleChunks >= 3) {
              setState(() => statusText = 'Konuşman bekleniyor');
            }
            return;
          }
          if (mounted && data['translated'] != null) {
            _silentSubtitleChunks = 0;
            final stage = (data['stage'] ?? 'partial').toString();
            final original = (data['original'] ?? '').toString().trim();
            final translated = (data['translated'] ?? '').toString().trim();
            _voiceLog('STT/translation result', {
              'stage': stage,
              'originalLength': original.length,
              'translatedLength': translated.length,
              'sourceLang': data['sourceLang'],
              'targetLang': data['targetLang'],
            });

            setState(() {
              if (stage == 'final') {
                if (original.isNotEmpty) {
                  finalSubtitleText = original;
                }
                if (translated.isNotEmpty) {
                  finalTranslatedText = translated;
                }
                partialSubtitleText = '';
                partialTranslatedText = '';
              } else {
                if (original.isNotEmpty) {
                  partialSubtitleText = original;
                }
                if (translated.isNotEmpty) {
                  partialTranslatedText = translated;
                }
              }
            });

            if (original.isNotEmpty || translated.isNotEmpty) {
              _forwardSubtitleUpdate(
                stage: stage,
                original: original,
                translated: translated,
              );
            }
          }
          if (mounted && data['error'] != null) {
            setState(
              () => statusText =
                  'Çeviri hatası: ${data['error']}',
            );
          }
        } catch (e) {
          if (mounted) {
            setState(
              () => statusText = 'Çeviri veri hatası: $e',
            );
          }
        }
      },
      onError: (error) {
        if (mounted) {
          setState(
            () => statusText = 'Çeviri soketi hatası: $error',
          );
        }
      },
    );
    _translateChannel!.connect();
  }

  Future<void> _startSubtitleRecording() async {
    if (isRecording) return;
    _microphonePermissionGranted = await _ensureMicrophonePermission();
    if (!_microphonePermissionGranted) {
      if (mounted) {
        setState(() {
          subtitlesOn = false;
          statusText =
              'Mikrofon izni olmadan altyazı çalışmaz';
        });
      }
      return;
    }
    if (!await _openSubtitleRecorder()) {
      if (mounted) {
        setState(() {
          subtitlesOn = false;
          statusText =
              'Mikrofon izni var ama kayıt motoru başlamadı';
        });
      }
      return;
    }
    _connectTranslateSocket();
    isRecording = true;
    if (mounted) {
      setState(() => statusText = 'Altyazı mikrofonu dinliyor');
    }

    while (isRecording) {
      try {
        final path = await _tempWavPath();
        final savedPath = await _recordSubtitleChunk(path);
        if (savedPath != null) {
          final file = File(savedPath);
          if (await file.exists()) {
            final fileBytes = await file.readAsBytes();
            final rms = calculateWavRms(fileBytes);
            _lastAudioBytes = fileBytes.length;
            _lastAudioRms = rms.round();
            _voiceLog('Audio recorded', {
              'recorded': true,
              'bytes': fileBytes.length,
              'format': 'pcm16wav',
              'sampleRate': 16000,
              'rms': rms,
            });
            if (fileBytes.length < 12000) {
              if (mounted) {
                setState(
                  () =>
                      statusText = 'Mikrofon sesi algılanmadı',
                );
              }
              continue;
            }
            if (rms < 90) {
              if (mounted) {
                setState(
                  () => statusText =
                      'Ses çok düşük algılandı',
                );
              }
            }
            final contextText = [
              finalSubtitleText,
              partialSubtitleText,
            ].where((text) => text.trim().isNotEmpty).join(' ');
            _translateChannel?.sendJson({
              'audio': base64Encode(fileBytes),
              'sourceLang': sourceLanguages[sourceLanguageName],
              'targetLang': targetLanguages[targetLanguageName],
              'previousText': contextText,
            });
          } else {
            _voiceLog('Audio recorded', {
              'recorded': false,
              'reason': 'missing_file',
            });
          }
        } else {
          _voiceLog('Audio recorded', {
            'recorded': false,
            'reason': 'null_path',
          });
        }
      } catch (e) {
        _voiceLog('Subtitle recorder failed, retrying once', {
          'error': e.toString(),
        });
        final recovered = await _retrySubtitleChunkAfterRecorderReset();
        if (recovered) continue;
        if (mounted) {
          setState(
            () => statusText =
                'Mikrofon izni var ama iPhone kayıt motoru sesi alamadı',
          );
        }
        subtitlesOn = false;
        isRecording = false;
      }
    }
    if (mounted) setState(() {});
  }

  Future<String?> _recordSubtitleChunk(String path) async {
    _voiceLog('Recorder start', {
      'format': 'pcm16wav',
      'sampleRate': 16000,
      'channels': 1,
      'audioSource': 'voice_communication',
      'voiceProcessing': true,
    });
    await _recorder.startRecorder(
      toFile: path,
      codec: Codec.pcm16WAV,
      numChannels: 1,
      sampleRate: 16000,
      audioSource: AudioSource.voice_communication,
      enableVoiceProcessing: true,
      enableNoiseSuppression: true,
      enableEchoCancellation: true,
    );
    await Future.delayed(const Duration(milliseconds: 700));
    return _recorder.stopRecorder();
  }

  Future<bool> _retrySubtitleChunkAfterRecorderReset() async {
    final reopened = await _reopenSubtitleRecorder();
    if (!reopened || !isRecording) return false;
    try {
      final retryPath = await _tempWavPath();
      final savedPath = await _recordSubtitleChunk(retryPath);
      if (savedPath == null) return false;
      final file = File(savedPath);
      if (!await file.exists()) return false;
      final fileBytes = await file.readAsBytes();
      final rms = calculateWavRms(fileBytes);
      _lastAudioBytes = fileBytes.length;
      _lastAudioRms = rms.round();
      _voiceLog('Audio recorded after recorder retry', {
        'recorded': true,
        'bytes': fileBytes.length,
        'format': 'pcm16wav',
        'sampleRate': 16000,
        'rms': rms,
      });
      if (fileBytes.length < 12000) return true;
      final contextText = [
        finalSubtitleText,
        partialSubtitleText,
      ].where((text) => text.trim().isNotEmpty).join(' ');
      _translateChannel?.sendJson({
        'audio': base64Encode(fileBytes),
        'sourceLang': sourceLanguages[sourceLanguageName],
        'targetLang': targetLanguages[targetLanguageName],
        'previousText': contextText,
      });
      return true;
    } catch (e) {
      _voiceLog('Subtitle recorder retry failed', {'error': e.toString()});
      return false;
    }
  }

  Future<void> _stopSubtitleRecording() async {
    isRecording = false;
    try {
      await _recorder.stopRecorder();
    } catch (_) {}
    if (mounted) setState(() {});
  }

  Future<void> _startCall() async {
    if (_peerConnection == null) {
      await _createPeerConnection();
    }

    final offer = await _peerConnection!.createOffer();
    await _peerConnection!.setLocalDescription(offer);
    _sendSignal({
      'type': 'offer',
      'room': widget.roomName,
      'sdp': offer.sdp,
      'sdpType': offer.type,
    });

    if (mounted) {
      setState(() => statusText = 'Arama isteği gönderildi');
    }
  }

  void _forwardSubtitleUpdate({
    required String stage,
    required String original,
    required String translated,
  }) {
    _sendSignal({
      'type': 'subtitle_packet',
      'room': widget.roomName,
      'stage': stage,
      'original': original,
      'translated': translated,
      'sourceLang': sourceLanguages[sourceLanguageName],
      'targetLang': targetLanguages[targetLanguageName],
    });
  }

  void _applyRemoteSubtitle(Map<String, dynamic> data) {
    final stage = (data['stage'] ?? 'partial').toString();
    final original = (data['original'] ?? '').toString().trim();
    final translated = (data['translated'] ?? '').toString().trim();

    setState(() {
      if (stage == 'final') {
        if (original.isNotEmpty) {
          remoteFinalOriginalText = original;
        }
        if (translated.isNotEmpty) {
          remoteFinalTranslatedText = translated;
        }
        remotePartialOriginalText = '';
        remotePartialTranslatedText = '';
      } else {
        if (original.isNotEmpty) {
          remotePartialOriginalText = original;
        }
        if (translated.isNotEmpty) {
          remotePartialTranslatedText = translated;
        }
      }
    });

    if (stage == 'final' && translated.isNotEmpty) {
      unawaited(
        _speakTranslatedText(translated, data['targetLang']?.toString()),
      );
    }
  }

  Future<void> _speakTranslatedText(String text, String? backendLang) async {
    final cleanText = text.trim();
    if (cleanText.isEmpty) return;
    try {
      final shouldResumeSubtitles = isRecording && subtitlesOn;
      if (shouldResumeSubtitles) {
        await _stopSubtitleRecording();
        await Future.delayed(const Duration(milliseconds: 120));
      }
      await configureSpeakerTts(_tts);
      await _tts.awaitSpeakCompletion(true);
      await _tts.setLanguage(_ttsLanguageCode(backendLang));
      final ttsStarted = DateTime.now();
      _voiceLog('TTS result', {
        'textLength': cleanText.length,
        'language': backendLang,
        'pausedRecorderForSpeaker': shouldResumeSubtitles,
      });
      await _tts.speak(cleanText);
      _voiceLog('TTS playback latency', {
        'ttsMs': DateTime.now().difference(ttsStarted).inMilliseconds,
      });
      await _tts.awaitSpeakCompletion(false);
      if (shouldResumeSubtitles && mounted && subtitlesOn) {
        unawaited(_startSubtitleRecording());
      }
    } catch (e) {
      await _tts.awaitSpeakCompletion(false);
      _voiceLog('TTS error', {'error': e.toString()});
    }
  }

  String _ttsLanguageCode(String? backendLang) {
    return bridgeCallTtsCode(backendLang);
  }

  Future<void> _handleSignal(dynamic rawMessage) async {
    final data = jsonDecode(rawMessage as String);
    final type = data['type'];

    if (type == 'welcome') {
      if (mounted) setState(() => myClientId = data['clientId']?.toString());
      return;
    }

    if (data['room'] != null && data['room'] != widget.roomName) return;

    switch (type) {
      case 'error':
        if (mounted) {
          setState(
            () => statusText = data['message']?.toString() ?? 'Bilinmeyen hata',
          );
        }
        return;
      case 'room_created':
        if (mounted) {
          setState(() {
            memberCount = data['memberCount'] ?? 1;
            statusText = widget.isOwner
                ? 'Katılımcı bekleniyor'
                : 'Bağlantı kuruluyor';
          });
        }
        return;
      case 'join_request':
        final requesterId = data['requesterId'];
        _sendSignal({
          'type': 'join_decision',
          'room': widget.roomName,
          'requesterId': requesterId,
          'accept': true,
        });
        if (mounted) {
          setState(
            () => statusText =
                'Katılım isteği otomatik kabul edildi',
          );
        }
        return;
      case 'join_accepted':
        if (mounted) {
          setState(() {
            memberCount = data['memberCount'] ?? 2;
            statusText = 'Odaya giriş onaylandı';
          });
        }
        _sendMediaState();
        return;
      case 'join_rejected':
        if (mounted) {
          setState(() => statusText = 'Odaya giriş reddedildi');
        }
        return;
      case 'member_joined':
        if (mounted) {
          setState(() {
            memberCount += 1;
            statusText =
                'Yeni bir kullanıcı katıldı';
          });
        }
        _sendMediaState();
        if (widget.isOwner) {
          await _startCall();
        }
        return;
      case 'member_left':
        _remoteRenderer.srcObject = null;
        if (mounted) {
          setState(() {
            memberCount = memberCount > 1 ? memberCount - 1 : 1;
            statusText =
                'Bir kullanıcı odadan çıktı';
          });
        }
        return;
      case 'room_closed':
        _remoteRenderer.srcObject = null;
        if (mounted) {
          setState(
            () => statusText =
                'Oda sahibi çağrıyı kapattı',
          );
        }
        await _saveHistoryIfNeeded();
        if (mounted) Navigator.pop(context);
        return;
      case 'left_room':
        if (mounted) {
          setState(
            () => statusText = 'Odadan çıkıldı',
          );
        }
        return;
      case 'chat_message':
        final incoming = data['text']?.toString() ?? '';
        final translated = data['translatedText']?.toString() ?? '';
        final senderId = data['senderId']?.toString();
        final mine = senderId != null && senderId == myClientId;
        if (incoming.isNotEmpty && mounted) {
          final message = _ChatMessage(
            text: incoming,
            translatedText: translated,
            isMine: mine,
          );
          setState(() {
            _messages.add(message);
          });
          await AppStore.addStoredMessage(
            StoredMessage(
              roomName: widget.roomName,
              text: incoming,
              translatedText: translated,
              isMine: mine,
              timestamp: DateTime.now(),
            ),
          );
        }
        return;
      case 'reaction':
        final emoji = data['emoji']?.toString();
        if (emoji != null && mounted) {
          setState(() => _reactionEmoji = emoji);
          _reactionTimer?.cancel();
          _reactionTimer = Timer(const Duration(seconds: 2), () {
            if (mounted) setState(() => _reactionEmoji = null);
          });
        }
        return;
      case 'room_state':
        if (mounted) {
          setState(() {
            memberCount = (data['memberCount'] ?? memberCount) as int;
            if (memberCount < 2) {
              _remoteRenderer.srcObject = null;
            }
          });
        }
        return;
      case 'media_state':
        if (mounted) {
          setState(() {
            remoteMicOn = data['micOn'] != false;
            remoteCamOn = data['camOn'] != false;
            remoteSubtitlesOn = data['subtitlesOn'] != false;
          });
        }
        return;
      case 'subtitle_packet':
        if (mounted) {
          _applyRemoteSubtitle(data);
        }
        return;
    }

    if (_peerConnection == null) return;

    if (type == 'offer') {
      final desc = RTCSessionDescription(
        data['sdp']?.toString(),
        data['sdpType']?.toString(),
      );
      await _peerConnection!.setRemoteDescription(desc);
      final answer = await _peerConnection!.createAnswer();
      await _peerConnection!.setLocalDescription(answer);
      _sendSignal({
        'type': 'answer',
        'room': widget.roomName,
        'sdp': answer.sdp,
        'sdpType': answer.type,
      });
      if (mounted) setState(() => statusText = 'Gelen arama kabul edildi');
    } else if (type == 'answer') {
      final desc = RTCSessionDescription(
        data['sdp']?.toString(),
        data['sdpType']?.toString(),
      );
      await _peerConnection!.setRemoteDescription(desc);
      if (mounted) {
        setState(
          () => statusText = 'Bağlantı tamamlandı',
        );
      }
    } else if (type == 'candidate') {
      final c = data['candidate'];
      if (c != null) {
        await _peerConnection!.addCandidate(
          RTCIceCandidate(
            c['candidate']?.toString(),
            c['sdpMid']?.toString(),
            c['sdpMLineIndex'] as int?,
          ),
        );
      }
    }
  }

  void _sendSignal(Map<String, dynamic> message) {
    _signalChannel?.sendJson(message);
  }

  Future<void> _sendChatMessage() async {
    final text = _chatController.text.trim();
    if (text.isEmpty) return;
    _chatController.clear();
    _sendSignal({
      'type': 'chat_message',
      'room': widget.roomName,
      'text': text,
      'sourceLang': sourceLanguages[sourceLanguageName],
      'targetLang': targetLanguages[targetLanguageName],
    });
  }

  void _sendReaction(String emoji) {
    setState(() => _reactionEmoji = emoji);
    _sendSignal({'type': 'reaction', 'room': widget.roomName, 'emoji': emoji});
    _reactionTimer?.cancel();
    _reactionTimer = Timer(const Duration(seconds: 2), () {
      if (mounted) setState(() => _reactionEmoji = null);
    });
  }

  void _sendMediaState() {
    _sendSignal({
      'type': 'media_state',
      'room': widget.roomName,
      'micOn': micOn,
      'camOn': camOn,
      'subtitlesOn': subtitlesOn,
    });
  }

  Future<void> _toggleMic() async {
    if (_localStream == null) return;
    for (final track in _localStream!.getAudioTracks()) {
      track.enabled = !track.enabled;
      micOn = track.enabled;
    }
    if (mounted) setState(() {});
    _sendMediaState();
  }

  Future<void> _toggleCamera() async {
    if (_localStream == null) return;
    for (final track in _localStream!.getVideoTracks()) {
      track.enabled = !track.enabled;
      camOn = track.enabled;
    }
    if (mounted) setState(() {});
    _sendMediaState();
  }

  Future<void> _saveHistoryIfNeeded() async {
    if (_historySaved) return;
    _historySaved = true;
    final durationSeconds = DateTime.now().difference(_callStart).inSeconds;
    await UsageService.addCallSeconds(durationSeconds);
    await AppStore.addHistory(
      CallHistoryEntry(
        roomName: widget.roomName,
        privateCode: widget.privateCode,
        sourceLanguage: sourceLanguageName,
        targetLanguage: targetLanguageName,
        memberCount: memberCount,
        durationSeconds: durationSeconds,
        timestamp: DateTime.now(),
      ),
    );
    final successfulCall = durationSeconds >= 20 && memberCount >= 2;
    final prompted = await RatingPromptService.requestReviewIfAppropriate(
      wasSuccessful: successfulCall,
    );
    if (prompted) {
      _voiceLog('Rating prompt shown', {'durationSeconds': durationSeconds});
    }
  }

  Future<void> _hangUp() async {
    try {
      _sendSignal({'type': 'leave_room'});
    } catch (_) {}

    await _saveHistoryIfNeeded();
    await _stopSubtitleRecording();
    _webrtcConnectTimeoutTimer?.cancel();
    _iceReconnectTimer?.cancel();
    await _peerConnection?.close();
    _peerConnection = null;
    _remoteRenderer.srcObject = null;

    _localStream?.getTracks().forEach((track) => track.stop());
    await _localStream?.dispose();
    _localStream = null;
    _localRenderer.srcObject = null;

    await _signalChannel?.close();
    _signalChannel = null;
    await _translateChannel?.close();
    _translateChannel = null;
    await _tts.stop();

    if (mounted) Navigator.pop(context);
  }

  String get _callDuration {
    final diff = DateTime.now().difference(_callStart);
    final h = diff.inHours.toString().padLeft(2, '0');
    final m = (diff.inMinutes % 60).toString().padLeft(2, '0');
    final s = (diff.inSeconds % 60).toString().padLeft(2, '0');
    return '$h:$m:$s';
  }

  String get _displayStatus {
    if (_isSpeakingTranslated) {
      return 'Çeviri sesi oynatılıyor...';
    }
    if (isRecording) return 'Dinleniyor ve altyazı akıyor...';
    final text = statusText.trim();
    if (text.startsWith('Oda oluşturuldu')) {
      return 'Katılımcı bekleniyor';
    }
    if (text.startsWith('Bağlantı:') ||
        text == 'Kamera açıldı') {
      return remoteReadyForUi
          ? 'Görüşme devam ediyor'
          : 'Karşı taraf bekleniyor';
    }
    return text;
  }

  int? _intFromJson(Object? value) {
    if (value is int) return value;
    if (value is num) return value.round();
    if (value is String) return int.tryParse(value);
    return null;
  }

  Color get _voiceHealthColor {
    if (!_microphonePermissionGranted || !_recorderReady) {
      return Colors.redAccent;
    }
    final rms = _lastAudioRms;
    if (rms != null && rms < 420) return AppColors.yellow;
    final total = _lastTotalMs;
    if (total != null && total > 3500) return AppColors.yellow;
    if (_silentSubtitleChunks >= 3) return AppColors.yellow;
    return AppColors.green;
  }

  IconData get _voiceHealthIcon {
    if (!_microphonePermissionGranted || !_recorderReady) {
      return Icons.mic_off_rounded;
    }
    if (_isSpeakingTranslated) return Icons.volume_up_rounded;
    if (isRecording) return Icons.graphic_eq_rounded;
    return Icons.hearing_rounded;
  }

  String get _voiceHealthTitle {
    if (!_microphonePermissionGranted) return 'Mikrofon izni yok';
    if (!_recorderReady) return 'Kayıt motoru bekliyor';
    if (_isSpeakingTranslated) return 'Çeviri sesi oynuyor';
    if (_silentSubtitleChunks >= 3) return 'Konuşma bekleniyor';
    final rms = _lastAudioRms;
    if (rms != null && rms < 420) {
      return 'Ses seviyesi düşük';
    }
    final total = _lastTotalMs;
    if (total != null && total > 3500) return 'Backend yavaş';
    if (isRecording) return 'Canlı çeviri aktif';
    return 'Ses sistemi hazır';
  }

  String get _voiceHealthDetail {
    final parts = <String>[];
    if (_lastAudioRms != null) parts.add('RMS $_lastAudioRms');
    if (_lastAudioBytes != null) {
      parts.add('${(_lastAudioBytes! / 1024).round()}KB');
    }
    if (_lastSttMs != null) parts.add('STT ${_lastSttMs}ms');
    if (_lastTranslationMs != null) {
      parts.add('Çeviri ${_lastTranslationMs}ms');
    }
    if (_lastTotalMs != null) parts.add('Toplam ${_lastTotalMs}ms');
    if (parts.isEmpty) return _displayStatus;
    return parts.join(' • ');
  }

  double get _voiceWaveLevel {
    final rms = (_lastAudioRms ?? 0).toDouble();
    if (!isRecording && !_isSpeakingTranslated) return 0.18;
    if (rms <= 0) return isRecording ? 0.35 : 0.18;
    return (rms / 1600).clamp(0.22, 1.0);
  }

  Widget _buildVoiceStatusPanel(bool compact) {
    final color = _voiceHealthColor;
    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: compact ? 10 : 12,
        vertical: compact ? 8 : 10,
      ),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            Colors.white.withValues(alpha: 0.08),
            color.withValues(alpha: 0.12),
            Colors.black.withValues(alpha: 0.10),
          ],
        ),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: color.withValues(alpha: 0.26)),
      ),
      child: Row(
        children: [
          Container(
            width: compact ? 30 : 34,
            height: compact ? 30 : 34,
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.18),
              borderRadius: BorderRadius.circular(11),
            ),
            child: Icon(
              _voiceHealthIcon,
              color: color,
              size: compact ? 17 : 19,
            ),
          ),
          const SizedBox(width: 9),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  _voiceHealthTitle,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: compact ? 12 : 13,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  _voiceHealthDetail,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    color: Colors.white.withValues(alpha: 0.66),
                    fontSize: compact ? 10 : 11,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          SizedBox(
            width: compact ? 54 : 64,
            height: compact ? 24 : 28,
            child: _WaveBar(
              animation: _waveController,
              active: isRecording || _isSpeakingTranslated,
              level: _voiceWaveLevel,
              dense: true,
            ),
          ),
        ],
      ),
    );
  }

  bool get remoteReadyForUi => _remoteRenderer.srcObject != null;

  @override
  void dispose() {
    _durationTimer?.cancel();
    _reactionTimer?.cancel();
    _webrtcConnectTimeoutTimer?.cancel();
    _iceReconnectTimer?.cancel();
    _waveController.dispose();
    _glowController.dispose();
    _saveHistoryIfNeeded();
    _stopSubtitleRecording();
    _signalChannel?.close();
    _translateChannel?.close();
    _peerConnection?.close();
    _tts.stop();
    _localStream?.getTracks().forEach((track) => track.stop());
    _localStream?.dispose();
    _chatController.dispose();
    _recorder.closeRecorder();
    _localRenderer.dispose();
    _remoteRenderer.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;
    final bottomInset = MediaQuery.of(context).viewInsets.bottom;
    final bool compact = size.width < 380;
    final double horizontal = compact ? 12 : 16;
    final double topInset = MediaQuery.of(context).padding.top;
    final double previewW = compact ? 118 : 136;
    final double previewH = compact ? 168 : 196;
    final bool remoteReady = remoteReadyForUi;

    return Scaffold(
      resizeToAvoidBottomInset: false,
      backgroundColor: Colors.black,
      body: Stack(
        children: [
          Positioned.fill(
            child: remoteReady
                ? RTCVideoView(
                    _remoteRenderer,
                    objectFit: RTCVideoViewObjectFit.RTCVideoViewObjectFitCover,
                  )
                : Container(
                    decoration: const BoxDecoration(
                      gradient: LinearGradient(
                        colors: [
                          Color(0xFF111827),
                          Color(0xFF261A1A),
                          Color(0xFF070B14),
                        ],
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                      ),
                    ),
                    child: Stack(
                      children: [
                        Positioned.fill(
                          child: Opacity(
                            opacity: 0.08,
                            child: Container(
                              decoration: const BoxDecoration(
                                gradient: RadialGradient(
                                  colors: [
                                    Color(0xFF8B5CF6),
                                    Colors.transparent,
                                  ],
                                  radius: 0.9,
                                  center: Alignment(0, 0.2),
                                ),
                              ),
                            ),
                          ),
                        ),
                        const Center(
                          child: Icon(
                            Icons.person_rounded,
                            size: 160,
                            color: Colors.white24,
                          ),
                        ),
                        Positioned(
                          left: horizontal,
                          bottom: 210,
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 14,
                              vertical: 8,
                            ),
                            decoration: BoxDecoration(
                              color: Colors.black.withValues(alpha: 0.34),
                              borderRadius: BorderRadius.circular(16),
                              border: Border.all(
                                color: Colors.white.withValues(alpha: 0.08),
                              ),
                            ),
                            child: const Text(
                              'Karşı taraf',
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 14,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
          ),
          Positioned.fill(
            child: DecoratedBox(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    Colors.black.withValues(alpha: 0.34),
                    Colors.transparent,
                    Colors.black.withValues(alpha: 0.58),
                  ],
                  stops: const [0, .35, 1],
                ),
              ),
            ),
          ),
          if (remoteReady)
            Positioned(
              left: horizontal,
              top: topInset + 94,
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 14,
                  vertical: 8,
                ),
                decoration: BoxDecoration(
                  color: Colors.black.withValues(alpha: 0.34),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(
                    color: Colors.white.withValues(alpha: 0.08),
                  ),
                ),
                child: const Text(
                  'Karşı taraf',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ),
          Positioned(
            top: topInset + 10,
            left: horizontal,
            right: horizontal,
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  width: 42,
                  height: 42,
                  decoration: BoxDecoration(
                    color: Colors.black.withValues(alpha: 0.26),
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(
                      color: Colors.white.withValues(alpha: 0.08),
                    ),
                  ),
                  child: const Icon(Icons.shield_outlined, color: Colors.white),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        widget.roomName,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          fontSize: compact ? 24 : 26,
                          fontWeight: FontWeight.w800,
                          color: Colors.white,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Row(
                        children: [
                          const Icon(
                            Icons.circle,
                            color: AppColors.green,
                            size: 9,
                          ),
                          const SizedBox(width: 6),
                          Text(
                            '$_callDuration   Kod: ${widget.privateCode}',
                            style: const TextStyle(
                              color: Colors.white70,
                              fontSize: 13,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Wrap(
                        spacing: 8,
                        runSpacing: 6,
                        children: [
                          ConnectionStatusPill(status: _signalStatus),
                          ConnectionStatusPill(status: _translateStatus),
                        ],
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 8),
                Wrap(
                  spacing: 8,
                  children: [
                    _TopRoundButton(
                      icon: Icons.groups_rounded,
                      label: '$memberCount',
                    ),
                    _TopRoundButton(
                      icon: Icons.chat_bubble_outline,
                      badgeText: _messages.isEmpty
                          ? null
                          : '${_messages.length}',
                      onTap: () => setState(() => _showChat = !_showChat),
                    ),
                    _TopRoundButton(
                      icon: Icons.more_horiz_rounded,
                      onTap: () async {
                        final original = [
                          finalSubtitleText,
                          remoteFinalOriginalText,
                        ].where((text) => text.trim().isNotEmpty).join('\\n');
                        final translated = [
                          finalTranslatedText,
                          remoteFinalTranslatedText,
                        ].where((text) => text.trim().isNotEmpty).join('\\n');
                        if (original.isNotEmpty || translated.isNotEmpty) {
                          await Share.share(
                            GrowthService.transcriptShareMessage(
                              original: original,
                              translated: translated,
                            ),
                          );
                          return;
                        }
                        await Share.share(
                          GrowthService.roomInviteMessage(
                            widget.roomName,
                            widget.privateCode,
                          ),
                        );
                      },
                    ),
                  ],
                ),
              ],
            ),
          ),
          Positioned(
            top: topInset + 86,
            right: horizontal,
            width: previewW,
            height: previewH,
            child: Container(
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(22),
                border: Border.all(
                  color: Colors.white.withValues(alpha: 0.14),
                  width: 1.1,
                ),
                boxShadow: const [
                  BoxShadow(
                    color: Color(0x55000000),
                    blurRadius: 18,
                    offset: Offset(0, 10),
                  ),
                ],
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(22),
                child: Stack(
                  fit: StackFit.expand,
                  children: [
                    cameraStarted
                        ? RTCVideoView(
                            _localRenderer,
                            mirror: true,
                            objectFit: RTCVideoViewObjectFit
                                .RTCVideoViewObjectFitCover,
                          )
                        : Container(
                            color: Colors.black38,
                            child: const Center(
                              child: Icon(
                                Icons.videocam_off_rounded,
                                color: Colors.white54,
                                size: 28,
                              ),
                            ),
                          ),
                    Positioned(
                      left: 8,
                      bottom: 8,
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 10,
                          vertical: 6,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.black.withValues(alpha: 0.42),
                          borderRadius: BorderRadius.circular(14),
                        ),
                        child: const Text(
                          'Sen',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 14,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),
                    ),
                    Positioned(
                      right: 8,
                      bottom: 8,
                      child: InkWell(
                        onTap: () async {
                          try {
                            final tracks = _localStream?.getVideoTracks();
                            if (tracks != null && tracks.isNotEmpty) {
                              await Helper.switchCamera(tracks.first);
                            }
                          } catch (_) {}
                        },
                        child: Container(
                          width: 30,
                          height: 30,
                          decoration: BoxDecoration(
                            color: Colors.black.withValues(alpha: 0.45),
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: const Icon(
                            Icons.cameraswitch_rounded,
                            size: 18,
                            color: Colors.white,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
          if (_reactionEmoji != null)
            Positioned(
              right: horizontal + 8,
              top: topInset + previewH + 150,
              child: AnimatedScale(
                duration: const Duration(milliseconds: 250),
                scale: _reactionEmoji == null ? 0.6 : 1,
                child: Container(
                  width: 62,
                  height: 62,
                  decoration: BoxDecoration(
                    color: Colors.black.withValues(alpha: 0.34),
                    borderRadius: BorderRadius.circular(18),
                    border: Border.all(
                      color: Colors.white.withValues(alpha: 0.08),
                    ),
                  ),
                  alignment: Alignment.center,
                  child: Text(
                    _reactionEmoji!,
                    style: const TextStyle(fontSize: 30),
                  ),
                ),
              ),
            ),
          Positioned(
            left: horizontal,
            right: horizontal + 72,
            bottom: _showChat ? 276 + bottomInset : 206,
            child: Container(
              padding: EdgeInsets.symmetric(
                horizontal: compact ? 14 : 16,
                vertical: compact ? 12 : 14,
              ),
              decoration: BoxDecoration(
                color: Colors.black.withValues(alpha: 0.42),
                borderRadius: BorderRadius.circular(22),
                border: Border.all(color: Colors.white.withValues(alpha: 0.10)),
                boxShadow: [
                  BoxShadow(
                    color: const Color(0xFF8B5CF6).withValues(alpha: 0.15),
                    blurRadius: 20,
                    spreadRadius: 1,
                  ),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildVoiceStatusPanel(compact),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Text(
                        '$sourceLanguageName (Siz)',
                        style: TextStyle(
                          color: Colors.white.withValues(alpha: 0.78),
                          fontSize: compact ? 12 : 13,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const Spacer(),
                      const Icon(
                        Icons.graphic_eq_rounded,
                        color: AppColors.purple,
                        size: 18,
                      ),
                    ],
                  ),
                  const SizedBox(height: 6),
                  Text(
                    partialSubtitleText.isNotEmpty
                        ? partialSubtitleText
                        : (finalSubtitleText.isNotEmpty
                              ? finalSubtitleText
                              : 'Konuşma başladığında burada anlık altyazı görünecek'),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: compact ? 17 : 18,
                      fontWeight: FontWeight.w700,
                      height: 1.25,
                    ),
                  ),
                  if (finalSubtitleText.isNotEmpty &&
                      partialSubtitleText.isNotEmpty) ...[
                    const SizedBox(height: 6),
                    Text(
                      finalSubtitleText,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        color: Colors.white.withValues(alpha: 0.50),
                        fontSize: compact ? 13 : 14,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                  const SizedBox(height: 10),
                  Row(
                    children: [
                      Text(
                        '$targetLanguageName • Sana giden çeviri',
                        style: TextStyle(
                          color: Colors.white.withValues(alpha: 0.70),
                          fontSize: compact ? 12 : 13,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const Spacer(),
                      const Icon(
                        Icons.graphic_eq_rounded,
                        color: AppColors.purple,
                        size: 18,
                      ),
                    ],
                  ),
                  const SizedBox(height: 6),
                  Text(
                    partialTranslatedText.isNotEmpty
                        ? partialTranslatedText
                        : (finalTranslatedText.isNotEmpty
                              ? finalTranslatedText
                              : 'Çeviri burada görünecek'),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      color: Colors.white.withValues(alpha: 0.92),
                      fontSize: compact ? 17 : 18,
                      fontWeight: FontWeight.w600,
                      height: 1.25,
                    ),
                  ),
                  if (finalTranslatedText.isNotEmpty &&
                      partialTranslatedText.isNotEmpty) ...[
                    const SizedBox(height: 6),
                    Text(
                      finalTranslatedText,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        color: Colors.white.withValues(alpha: 0.48),
                        fontSize: compact ? 13 : 14,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                  const SizedBox(height: 14),
                  Divider(
                    color: Colors.white.withValues(alpha: 0.08),
                    height: 1,
                  ),
                  const SizedBox(height: 14),
                  Row(
                    children: [
                      Text(
                        'Karşı taraf • Orijinal',
                        style: TextStyle(
                          color: const Color(0xFF7DB7FF),
                          fontSize: compact ? 12 : 13,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      const Spacer(),
                      Icon(
                        remoteMicOn ? Icons.mic : Icons.mic_off,
                        color: remoteMicOn ? AppColors.blue : Colors.white30,
                        size: 18,
                      ),
                    ],
                  ),
                  const SizedBox(height: 6),
                  Text(
                    remotePartialOriginalText.isNotEmpty
                        ? remotePartialOriginalText
                        : (remoteFinalOriginalText.isNotEmpty
                              ? remoteFinalOriginalText
                              : 'Karşı taraf konuştuğunda burada orijinal metin akacak'),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      color: Colors.white.withValues(alpha: 0.92),
                      fontSize: compact ? 17 : 18,
                      fontWeight: FontWeight.w600,
                      height: 1.25,
                    ),
                  ),
                  if (remoteFinalOriginalText.isNotEmpty &&
                      remotePartialOriginalText.isNotEmpty) ...[
                    const SizedBox(height: 6),
                    Text(
                      remoteFinalOriginalText,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        color: Colors.white.withValues(alpha: 0.48),
                        fontSize: compact ? 13 : 14,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                  const SizedBox(height: 10),
                  Row(
                    children: [
                      Text(
                        '$sourceLanguageName • Sana gelen çeviri',
                        style: TextStyle(
                          color: const Color(0xFFB89BFF),
                          fontSize: compact ? 12 : 13,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      const Spacer(),
                      const Icon(
                        Icons.graphic_eq_rounded,
                        color: AppColors.purple,
                        size: 18,
                      ),
                    ],
                  ),
                  const SizedBox(height: 6),
                  Text(
                    remotePartialTranslatedText.isNotEmpty
                        ? remotePartialTranslatedText
                        : (remoteFinalTranslatedText.isNotEmpty
                              ? remoteFinalTranslatedText
                              : 'Karşı tarafın çevirisi burada görünecek'),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: compact ? 17 : 18,
                      fontWeight: FontWeight.w700,
                      height: 1.25,
                    ),
                  ),
                  if (remoteFinalTranslatedText.isNotEmpty &&
                      remotePartialTranslatedText.isNotEmpty) ...[
                    const SizedBox(height: 6),
                    Text(
                      remoteFinalTranslatedText,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        color: Colors.white.withValues(alpha: 0.48),
                        fontSize: compact ? 13 : 14,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ),
          Positioned(
            right: horizontal,
            bottom: _showChat ? 246 + bottomInset : 178,
            child: Column(
              children: [
                for (final emoji in [
                  '👍',
                  '😍',
                  '😂',
                  '😮',
                  '👏',
                ])
                  Padding(
                    padding: const EdgeInsets.only(bottom: 10),
                    child: InkWell(
                      onTap: () => _sendReaction(emoji),
                      borderRadius: BorderRadius.circular(16),
                      child: Container(
                        width: compact ? 50 : 54,
                        height: compact ? 50 : 54,
                        decoration: BoxDecoration(
                          color: Colors.black.withValues(alpha: 0.36),
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(
                            color: Colors.white.withValues(alpha: 0.08),
                          ),
                        ),
                        alignment: Alignment.center,
                        child: Text(
                          emoji,
                          style: TextStyle(fontSize: compact ? 24 : 26),
                        ),
                      ),
                    ),
                  ),
              ],
            ),
          ),
          Positioned(
            left: 0,
            right: 0,
            bottom: _showChat ? 74 + bottomInset : 40,
            child: Padding(
              padding: EdgeInsets.symmetric(horizontal: compact ? 22 : 34),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  _controlItem(
                    icon: micOn ? Icons.mic_rounded : Icons.mic_off_rounded,
                    label: 'Mikrofon',
                    color: micOn ? AppColors.green : Colors.white24,
                    onTap: _toggleMic,
                  ),
                  _controlItem(
                    icon: camOn
                        ? Icons.videocam_rounded
                        : Icons.videocam_off_rounded,
                    label: 'Kamera',
                    color: camOn ? AppColors.blue : Colors.white24,
                    onTap: _toggleCamera,
                  ),
                  _controlItem(
                    icon: subtitlesOn
                        ? Icons.translate_rounded
                        : Icons.translate_outlined,
                    label: 'Çeviri',
                    color: subtitlesOn ? AppColors.purple : Colors.white24,
                    onTap: () async {
                      setState(() => subtitlesOn = !subtitlesOn);
                      if (subtitlesOn) {
                        await _startSubtitleRecording();
                      } else {
                        await _stopSubtitleRecording();
                      }
                      _sendMediaState();
                    },
                  ),
                  _controlItem(
                    icon: Icons.chat_bubble_outline_rounded,
                    label: 'Sohbet',
                    color: _showChat ? AppColors.purple : Colors.white24,
                    onTap: () => setState(() => _showChat = !_showChat),
                  ),
                  _controlItem(
                    icon: Icons.call_end_rounded,
                    label: 'Kapat',
                    color: AppColors.red,
                    onTap: _hangUp,
                  ),
                ],
              ),
            ),
          ),
          if (_showChat)
            Positioned(
              left: 0,
              right: 0,
              bottom: 0,
              child: _chatPanel(bottomInset: bottomInset),
            ),
        ],
      ),
    );
  }

  Widget _controlItem({
    required IconData icon,
    required String label,
    required Color color,
    required VoidCallback onTap,
  }) {
    final bool isActive = color != Colors.white24;
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(28),
      child: SizedBox(
        width: 68,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            AnimatedContainer(
              duration: const Duration(milliseconds: 220),
              width: 58,
              height: 58,
              decoration: BoxDecoration(
                color: color,
                shape: BoxShape.circle,
                boxShadow: [
                  BoxShadow(
                    color: color.withValues(alpha: isActive ? 0.28 : 0.08),
                    blurRadius: isActive ? 18 : 10,
                    spreadRadius: isActive ? 1 : 0,
                  ),
                ],
              ),
              child: Icon(icon, color: Colors.white, size: 24),
            ),
            const SizedBox(height: 6),
            Text(
              label,
              textAlign: TextAlign.center,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                fontSize: 12,
                color: isActive ? Colors.white : Colors.white70,
                fontWeight: isActive ? FontWeight.w700 : FontWeight.w500,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _chatPanel({double bottomInset = 0}) {
    return Container(
      padding: EdgeInsets.fromLTRB(
        16,
        14,
        16,
        bottomInset > 0 ? bottomInset + 12 : 18,
      ),
      decoration: BoxDecoration(
        color: const Color(0xFF08101F).withValues(alpha: 0.98),
        borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 48,
            height: 4,
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.22),
              borderRadius: BorderRadius.circular(99),
            ),
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              const Text(
                'Sohbet',
                style: TextStyle(fontSize: 20, fontWeight: FontWeight.w800),
              ),
              const Spacer(),
              IconButton(
                onPressed: () => setState(() => _showChat = false),
                icon: const Icon(Icons.close_rounded),
              ),
            ],
          ),
          const SizedBox(height: 6),
          ConstrainedBox(
            constraints: const BoxConstraints(maxHeight: 160),
            child: _messages.isEmpty
                ? const Padding(
                    padding: EdgeInsets.symmetric(vertical: 28),
                    child: Center(
                      child: Text(
                        'İlk mesajı sen gönder',
                        style: TextStyle(color: Colors.white70),
                      ),
                    ),
                  )
                : ListView.separated(
                    shrinkWrap: true,
                    reverse: true,
                    itemCount: _messages.length,
                    separatorBuilder: (_, _) => const SizedBox(height: 8),
                    itemBuilder: (context, index) {
                      final item = _messages[_messages.length - 1 - index];
                      return Align(
                        alignment: item.isMine
                            ? Alignment.centerRight
                            : Alignment.centerLeft,
                        child: Container(
                          constraints: BoxConstraints(
                            maxWidth: MediaQuery.of(context).size.width * 0.72,
                          ),
                          padding: const EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 10,
                          ),
                          decoration: BoxDecoration(
                            color: item.isMine
                                ? AppColors.purple
                                : Colors.white.withValues(alpha: 0.05),
                            borderRadius: BorderRadius.circular(16),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                item.text,
                                style: const TextStyle(fontSize: 15),
                              ),
                              if (item.translatedText.isNotEmpty) ...[
                                const SizedBox(height: 4),
                                Text(
                                  item.translatedText,
                                  style: const TextStyle(
                                    color: Colors.white70,
                                    fontSize: 14,
                                  ),
                                ),
                              ],
                            ],
                          ),
                        ),
                      );
                    },
                  ),
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: TextField(
                  controller: _chatController,
                  decoration: _inputDecoration(
                    'Mesaj yaz...',
                    suffixIcon: Icons.translate_rounded,
                  ),
                ),
              ),
              const SizedBox(width: 10),
              InkWell(
                onTap: _sendChatMessage,
                borderRadius: BorderRadius.circular(28),
                child: Container(
                  width: 52,
                  height: 52,
                  decoration: const BoxDecoration(
                    color: AppColors.purple,
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(Icons.send_rounded, color: Colors.white),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _TopRoundButton extends StatelessWidget {
  final IconData icon;
  final String? label;
  final String? badgeText;
  final VoidCallback? onTap;

  const _TopRoundButton({
    required this.icon,
    this.label,
    this.badgeText,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final child = Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 13),
      decoration: BoxDecoration(
        color: Colors.black.withValues(alpha: 0.28),
        borderRadius: BorderRadius.circular(18),
      ),
      child: badgeText == null
          ? Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(icon),
                if (label != null) ...[const SizedBox(width: 8), Text(label!)],
              ],
            )
          : Badge(
              label: Text(badgeText!),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(icon),
                  if (label != null) ...[
                    const SizedBox(width: 8),
                    Text(label!),
                  ],
                ],
              ),
            ),
    );
    if (onTap == null) return child;
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(18),
      child: child,
    );
  }
}

class _WaveBar extends StatelessWidget {
  final Animation<double> animation;
  final bool active;
  final double level;
  final bool dense;

  const _WaveBar({
    required this.animation,
    required this.active,
    required this.level,
    this.dense = false,
  });

  @override
  Widget build(BuildContext context) {
    final List<double> baseHeights =
        (dense
                ? [4, 8, 13, 18, 12, 22, 15, 8, 17, 13]
                : [6, 10, 18, 28, 20, 36, 24, 12, 30, 22, 14, 26, 16, 8])
            .map((e) => e.toDouble())
            .toList();

    return AnimatedBuilder(
      animation: animation,
      builder: (context, _) {
        return Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: List.generate(baseHeights.length, (index) {
            final progress = (animation.value + (index * 0.07)) % 1.0;
            final pulse = progress < 0.5 ? progress * 2 : (1 - progress) * 2;
            final voiceBoost = active ? level.clamp(0.18, 1.0) : 0.18;
            final dynamicHeight =
                baseHeights[index] +
                ((0.25 + voiceBoost) *
                    (dense ? 3 + (pulse * 8) : 6 + (pulse * 18)));
            return Container(
              margin: EdgeInsets.symmetric(horizontal: dense ? 1.5 : 3),
              width: dense ? 3.5 : (active ? 6 : 5),
              height: dynamicHeight.clamp(
                dense ? 4.0 : 6.0,
                dense ? 28.0 : 52.0,
              ),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(10),
                gradient: LinearGradient(
                  colors: active
                      ? const [Color(0xFF7DD3FC), Color(0xFF8B5CF6)]
                      : const [Color(0xFFB37CFF), Color(0xFF7A3DFF)],
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                ),
                boxShadow: [
                  BoxShadow(
                    color: AppColors.purple.withValues(
                      alpha: active ? 0.22 + (voiceBoost * 0.42) : 0.18,
                    ),
                    blurRadius: active ? 10 + (voiceBoost * 14) : 8,
                    spreadRadius: active ? voiceBoost : 0,
                  ),
                ],
              ),
            );
          }),
        );
      },
    );
  }
}

class _ChatMessage {
  final String text;
  final String translatedText;
  final bool isMine;

  const _ChatMessage({
    required this.text,
    required this.translatedText,
    required this.isMine,
  });
}
