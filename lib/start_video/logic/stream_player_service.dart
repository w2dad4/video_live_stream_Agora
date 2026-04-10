import 'dart:async';
import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_webrtc/flutter_webrtc.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:video_live_stream/live_stream_message/contact/contact_UI/constants.dart';

//拉流专用
final streamPlayerServiceProvider = AsyncNotifierProvider.family.autoDispose<StreamPlayerService, void, String>((audienceID) => StreamPlayerService(audienceID));

class StreamPlayerService extends AsyncNotifier<void> {
  String audienceID;
  StreamPlayerService(this.audienceID);
  RTCVideoRenderer? _remoteRenderer;
  RTCPeerConnection? _peerConnection;
  MediaStream? _remoteStream;
  Completer<void>? _firstTrackCompleter;
  RTCVideoRenderer? get renderer => _remoteRenderer;

  @override
  FutureOr<void> build() async {
    // 1. 同步初始化渲染器，保证 UI 层能立刻拿到占位
    _remoteRenderer = RTCVideoRenderer();
    await _remoteRenderer!.initialize();
    // 2. 绑定路由退出时的销毁逻辑
    ref.onDispose(() => _stopInternal());
    //3.执行异步拉流
    return _startPlaying(audienceID);
  }

  Future<void> _startPlaying(String audienceID) async {
    try {
      if (audienceID.trim().isEmpty) {
        throw Exception('直播间ID为空，无法拉流');
      }

      //观众不需要本地流
      _peerConnection = await createPeerConnection({'sdpSemantics': 'unified-plan'});
      _firstTrackCompleter = Completer<void>();
      // 2. 音频
      _peerConnection!.addTransceiver(
        kind: RTCRtpMediaType.RTCRtpMediaTypeAudio,
        init: RTCRtpTransceiverInit(direction: TransceiverDirection.RecvOnly),
      );
      // 视频（必须加）
      _peerConnection!.addTransceiver(
        kind: RTCRtpMediaType.RTCRtpMediaTypeVideo,
        init: RTCRtpTransceiverInit(direction: TransceiverDirection.RecvOnly),
      );

      // 3. 监听远端流：当 SRS 服务器的数据到达时，将其绑定给渲染器
      _peerConnection!.onTrack = (RTCTrackEvent event) async {
        debugPrint('收到远端轨道: kind=${event.track.kind}, streams=${event.streams.length}');
        if (event.streams.isNotEmpty) {
          _remoteRenderer?.srcObject = event.streams.first;
          if (_firstTrackCompleter?.isCompleted == false) {
            _firstTrackCompleter?.complete();
          }
          return;
        }

        final track = event.track;
        _remoteStream ??= await createLocalMediaStream('remote_$audienceID');
        _remoteStream?.addTrack(track);
        _remoteRenderer?.srcObject = _remoteStream;
        if (_firstTrackCompleter?.isCompleted == false) {
          _firstTrackCompleter?.complete();
        }
      };

      // 4. 创建 Offer SDP
      final RTCSessionDescription offer = await _peerConnection!.createOffer({});
      await _peerConnection!.setLocalDescription(offer);
      await _waitIceGatheringComplete(_peerConnection!);

      final localDescription = await _peerConnection!.getLocalDescription();
      final localSdp = localDescription?.sdp;
      if (localSdp == null || localSdp.isEmpty) {
        throw Exception('本地SDP为空，无法发起WHEP拉流');
      }

      // 5. 🟢 使用 WHEP 协议请求 SRS 拉流 (注意路径是 /whep/)
      final dio = Dio();
      final whepUrl = LiveConfig.whepUri(audienceID).toString();
      debugPrint('开始拉流 audienceID=$audienceID, whep=$whepUrl');
      final response = await dio.post(
        whepUrl,
        data: localSdp,
        options: Options(headers: {'Content-Type': 'application/sdp'}, sendTimeout: const Duration(seconds: 10), receiveTimeout: const Duration(seconds: 10), validateStatus: (_) => true),
      );

      // 6. 处理服务器返回的 Answer SDP，建立连接
      if (response.statusCode == 200 || response.statusCode == 201) {
        debugPrint('WHEP应答成功: HTTP ${response.statusCode}');
        final answerSdp = response.data is String ? response.data as String : '${response.data}';
        if (answerSdp.trim().isEmpty) {
          throw Exception('SRS返回了空的Answer SDP');
        }
        final answer = RTCSessionDescription(answerSdp, 'answer');
        await _peerConnection!.setRemoteDescription(answer);
        debugPrint('已设置远端Answer，等待音视频轨道...');

        // 等待首个媒体轨道，避免“连接建立但无画面”不报错。
        await _waitFirstTrack();
      } else {
        throw Exception('拉流失败: HTTP ${response.statusCode}, body=${_shortBody(response.data)}');
      }
    } catch (e, stack) {
      state = AsyncError(e, stack);
      rethrow;
    }
  }

  Future<void> _waitIceGatheringComplete(RTCPeerConnection peerConnection, {Duration timeout = const Duration(seconds: 3)}) async {
    final deadline = DateTime.now().add(timeout);
    while (peerConnection.iceGatheringState != RTCIceGatheringState.RTCIceGatheringStateComplete) {
      if (DateTime.now().isAfter(deadline)) {
        debugPrint('ICE 收集超时，继续使用当前已收集 candidate');
        return;
      }
      await Future.delayed(const Duration(milliseconds: 80));
    }
  }

  Future<void> _waitFirstTrack({Duration timeout = const Duration(seconds: 8)}) async {
    final completer = _firstTrackCompleter;
    if (completer == null) return;
    await completer.future.timeout(
      timeout,
      onTimeout: () {
        throw TimeoutException('WHEP已完成应答，但在 ${timeout.inSeconds}s 内未收到远端音视频轨道');
      },
    );
  }

  String _shortBody(dynamic body) {
    final text = '${body ?? ''}'.replaceAll('\n', ' ').trim();
    if (text.length <= 160) return text;
    return '${text.substring(0, 160)}...';
  }

  // 供 UI 层重试拉流使用
  Future<void> retryPlaying() async {
    ref.invalidateSelf();
  }

  Future<void> _stopInternal() async {
    await _peerConnection?.close();
    _peerConnection = null;

    _remoteStream?.getTracks().forEach((track) => track.stop());
    await _remoteStream?.dispose();
    _remoteStream = null;

    _remoteRenderer?.srcObject = null;
    await _remoteRenderer?.dispose();
    _remoteRenderer = null;
    _firstTrackCompleter = null;
  }
}
