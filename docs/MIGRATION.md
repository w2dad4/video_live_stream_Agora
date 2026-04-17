# 主播端/观众端分离迁移指南

## 目录结构变更

### 新结构
```
lib/
├── features/
│   ├── anchor/                 # 🎤 主播端（完全独立）
│   │   ├── logic/
│   │   │   ├── anchor_service.dart      # 主播推流服务
│   │   │   └── index.dart             # 导出文件
│   │   └── ui/
│   │       └── anchor_page.dart       # 主播页面（需迁移）
│   │
│   ├── audience/               # 👀 观众端（完全独立）
│   │   ├── logic/
│   │   │   ├── audience_service.dart    # 观众拉流服务
│   │   │   └── index.dart               # 导出文件
│   │   └── ui/
│   │       └── audience_page.dart       # 观众页面（需迁移）
│   │
├── shared/                     # 可复用组件
│   ├── widgets/
│   │   ├── live_button.dart           # 直播按钮
│   │   └── video_controls.dart        # 视频控制
│   └── index.dart
│
└── start_video/
    └── logic/
        └── agora_service.dart  # ❌ 废弃：旧的混合代码（待删除）
```

## 关键变更

### 1. 引擎管理完全分离

**旧代码（错误❌）:**
```dart
// 主播和观众共享同一个引擎管理器
class AgoraEngineManager {
  static RtcEngine? _engine;  // ❌ 全局单例，两边共享
}
```

**新代码（正确✅）:**
```dart
// 🎤 主播端专用引擎
class AnchorEngineManager {
  static RtcEngine? _engine;
  static int _refCount = 0;
  // 主播端专用，与观众端完全隔离
}

// 👀 观众端专用引擎
class AudienceEngineManager {
  static RtcEngine? _engine;
  static int _refCount = 0;
  // 观众端专用，与主播端完全隔离
}
```

### 2. Provider 命名区分

| 旧命名 | 新命名（主播端） | 新命名（观众端） |
|--------|-----------------|-----------------|
| `agoraHostServiceProvider` | `anchorServiceProvider` | - |
| `agoraAudienceServiceProvider` | - | `audienceServiceProvider` |
| `currentQualityProvider` | `anchorQualityProvider` | - |
| `isPublishingProvider` | `anchorPublishingProvider` | `audiencePlayingProvider` |
| `remoteUidProvider` | - | `audienceRemoteUidProvider` |

### 3. 导入路径更新

**旧导入:**
```dart
import 'package:video_live_stream/start_video/logic/agora_service.dart';
```

**新导入:**
```dart
// 主播端
import 'package:video_live_stream/features/anchor/logic/index.dart';

// 观众端
import 'package:video_live_stream/features/audience/logic/index.dart';

// 共享组件
import 'package:video_live_stream/shared/index.dart';
```

## 使用示例

### 主播端页面
```dart
class AnchorPage extends ConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // ✅ 使用主播端专用 Provider
    final anchorState = ref.watch(anchorServiceProvider(roomId));
    final quality = ref.watch(anchorQualityProvider);
    final isPublishing = ref.watch(anchorPublishingProvider);
    
    return Scaffold(
      body: anchorState.when(
        data: (_) => AnchorVideoView(roomId: roomId),
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (err, _) => Text('Error: $err'),
      ),
    );
  }
}

// 开始推流
ref.read(anchorServiceProvider(roomId).notifier).startPublishing();

// 切换麦克风
ref.read(anchorServiceProvider(roomId).notifier).toggleMicrophone();
```

### 观众端页面
```dart
class AudiencePage extends ConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // ✅ 使用观众端专用 Provider
    final audienceState = ref.watch(audienceServiceProvider(roomId));
    final remoteUid = ref.watch(audienceRemoteUidProvider);
    final isPlaying = ref.watch(audiencePlayingProvider);
    
    return Scaffold(
      body: audienceState.when(
        data: (_) => AudienceVideoView(roomId: roomId),
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (err, _) => Text('Error: $err'),
      ),
    );
  }
}

// 开始观看
ref.read(audienceServiceProvider(roomId).notifier).startPlaying();
```

## 注意事项

### ❌ 禁止的行为
1. **禁止共享引擎**: 主播和观众不能使用同一个 `RtcEngine` 实例
2. **禁止混合 Provider**: 不要在一个页面同时 watch 主播和观众的 Provider
3. **禁止 publish + subscribe**: 主播端只 publish，观众端只 subscribe
4. **禁止全局单例**: 不要创建全局的 camera service 或 stream provider

### ✅ 推荐的做法
1. **完全分离 UI**: 主播页面和观众页面应该是两个独立的 Widget
2. **按需加载**: 使用 `autoDispose` 的 Provider，离开页面时自动释放资源
3. **引用计数管理**: 引擎通过引用计数自动销毁，无需手动管理
4. **明确的角色区分**: 主播端 `clientRoleBroadcaster`，观众端 `clientRoleAudience`

## 遗留文件处理

`lib/start_video/logic/agora_service.dart` 是旧的混合代码，在确认新代码正常工作后可以删除。

迁移完成后，项目结构将完全符合要求：
- ✅ 主播端代码在 `features/anchor/`
- ✅ 观众端代码在 `features/audience/`
- ✅ 共享组件在 `shared/`
- ✅ 两端引擎完全隔离
