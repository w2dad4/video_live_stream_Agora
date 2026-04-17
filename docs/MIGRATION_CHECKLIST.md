# 逐步迁移清单

## 第一阶段：替换 Provider 引用（低风险）

### 1. video_shiping.dart (预览页面)
**当前依赖:**
- `LiveQuality` enum (来自旧 agora_service.dart)
- `currentQualityProvider` (来自旧 agora_service.dart)

**迁移步骤:**
```dart
// 旧导入
// import 隐含在 library.dart 中

// 新导入
import 'package:video_live_stream/features/anchor/logic/index.dart' show LiveQuality, currentQualityProvider;
```

**变更:**
- ✅ `LiveQuality` → `LiveQuality` (保持相同)
- ✅ `currentQualityProvider` → `currentQualityProvider` (保持相同)
- ✅ `_showQualityPicker()` 方法保留

**状态:** 🟢 低风险 - 只需确认导入路径

---

### 2. gift_view.dart (直播间页面)
**当前依赖:**
- `agoraHostServiceProvider` (主播服务 Provider)
- `currentQualityProvider` (画质 Provider)
- `isPublishingProvider` (推流状态 Provider)

**迁移步骤:**
```dart
// 新导入
import 'package:video_live_stream/features/anchor/logic/index.dart' show 
  anchorServiceProvider, 
  anchorQualityProvider, 
  anchorPublishingProvider,
  AnchorService;
```

**变更映射:**
| 旧代码 | 新代码 |
|--------|--------|
| `ref.watch(agoraHostServiceProvider(roomID))` | `ref.watch(anchorServiceProvider(roomID))` |
| `ref.watch(currentQualityProvider)` | `ref.watch(anchorQualityProvider)` |
| `ref.watch(isPublishingProvider)` | `ref.watch(anchorPublishingProvider)` |
| `AgoraHostService` | `AnchorService` |
| `notifier.changeQuality(quality)` | 移除（直播间不能改画质） |
| `notifier.toggleMicrophone()` | `notifier.toggleMicrophone()` ✅ 保持 |

**状态:** 🟡 中风险 - 需要更新多处 Provider 引用

---

### 3. audience_video_view.dart (观众页面)
**当前依赖:**
- `agoraAudienceServiceProvider`
- `isAudiencePlayingProvider`
- `remoteUidProvider`

**迁移步骤:**
```dart
// 新导入
import 'package:video_live_stream/features/audience/logic/index.dart' show 
  audienceServiceProvider,
  audiencePlayingProvider,
  audienceRemoteUidProvider,
  AudienceService;
```

**变更映射:**
| 旧代码 | 新代码 |
|--------|--------|
| `agoraAudienceServiceProvider(roomId)` | `audienceServiceProvider(roomId)` |
| `isAudiencePlayingProvider` | `audiencePlayingProvider` |
| `remoteUidProvider` | `audienceRemoteUidProvider` |
| `AgoraAudienceService` | `AudienceService` |

**状态:** 🟡 中风险 - Provider 名称变更

---

### 4. live_video_view.dart (本地视频组件)
**当前依赖:**
- `agoraHostServiceProvider` (用于获取本地视频视图)

**迁移步骤:**
```dart
// 新导入
import 'package:video_live_stream/features/anchor/logic/index.dart' show 
  anchorServiceProvider,
  AnchorService;
```

**变更:**
- `AgoraHostService.getLocalVideoView()` → `AnchorService.getLocalVideoView()`
- 移除美颜集成（美颜在预览页面处理）

**状态:** 🔴 高风险 - 视频视图获取方式变化

---

### 5. host_panel.dart (主播控制面板)
**当前依赖:**
- `AgoraHostService` 方法调用

**迁移步骤:**
```dart
// 新导入
import 'package:video_live_stream/features/anchor/logic/index.dart' show AnchorService;
```

**状态:** 🟡 中风险

---

## 第二阶段：组件拆分

### 创建新的 VideoView 组件

**目标:** 将旧的混合 `AgoraVideoView` 拆分为两个独立组件：

```
lib/shared/
├── widgets/
│   ├── anchor_video_view.dart    # 主播端视频视图（本地摄像头）
│   ├── audience_video_view.dart  # 观众端视频视图（远端流）
│   └── index.dart
```

**实现:**
- `AnchorVideoView` - 使用 `AnchorEngineManager`
- `AudienceVideoView` - 使用 `AudienceEngineManager`

---

## 第三阶段：清理旧代码

### 删除旧的 agora_service.dart

**前提条件:**
- ✅ 所有页面已迁移
- ✅ 测试验证功能正常
- ✅ 备份旧代码（已 git commit）

**删除清单:**
- [ ] `lib/start_video/logic/agora_service.dart`

---

## 迁移验证检查点

### 功能验证
- [ ] 预览页面：画质选择正常
- [ ] 直播间：推流/停止正常
- [ ] 直播间：麦克风切换正常
- [ ] 直播间：显示当前画质（只读）
- [ ] 观众端：加入频道正常
- [ ] 观众端：看到主播画面
- [ ] 观众端：听到主播声音
- [ ] 两端完全独立：主播退出不影响观众，反之亦然

### 性能验证
- [ ] 主播端内存占用正常
- [ ] 观众端内存占用正常
- [ ] 引擎正确释放（引用计数归零）

---

## 执行顺序建议

### 第一天（低风险）
1. ✅ 确认 features/anchor/logic/anchor_service.dart 功能完整
2. ✅ 确认 features/audience/logic/audience_service.dart 功能完整
3. 🔄 迁移 video_shiping.dart（仅画质选择）

### 第二天（中风险）
4. 🔄 迁移 gift_view.dart（直播间控制）
5. 🔄 迁移 audience_video_view.dart（观众端）

### 第三天（高风险）
6. 🔄 迁移 live_video_view.dart（视频组件）
7. 🔄 迁移 host_panel.dart（主播面板）

### 第四天（清理）
8. 🔄 创建新的 VideoView 组件
9. 🔄 删除旧的 agora_service.dart
10. 🔄 全面测试

---

## 快速修复命令

如果发现 Provider 名称混淆，批量替换：

```bash
# 主播端替换
find lib -name "*.dart" -exec sed -i '' 's/agoraHostServiceProvider/anchorServiceProvider/g' {} \;
find lib -name "*.dart" -exec sed -i '' 's/AgoraHostService/AnchorService/g' {} \;
find lib -name "*.dart" -exec sed -i '' 's/currentQualityProvider/anchorQualityProvider/g' {} \;
find lib -name "*.dart" -exec sed -i '' 's/isPublishingProvider/anchorPublishingProvider/g' {} \;

# 观众端替换
find lib -name "*.dart" -exec sed -i '' 's/agoraAudienceServiceProvider/audienceServiceProvider/g' {} \;
find lib -name "*.dart" -exec sed -i '' 's/AgoraAudienceService/AudienceService/g' {} \;
find lib -name "*.dart" -exec sed -i '' 's/isAudiencePlayingProvider/audiencePlayingProvider/g' {} \;
find lib -name "*.dart" -exec sed -i '' 's/remoteUidProvider/audienceRemoteUidProvider/g' {} \;
```

⚠️ **注意:** 批量替换前请确保已提交 git！
