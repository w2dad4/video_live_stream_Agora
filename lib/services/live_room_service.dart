import 'dart:convert';
import 'package:http/http.dart' as http;

/// 直播房间服务
class LiveRoomService {
  static const String baseUrl = 'http://192.168.1.18:8080';

  /// 创建直播间（主播开播）
  static Future<void> createRoom({
    required String id,
    required String channelName,
    required String hostName,
    String? hostUid,
    String? title,
    String? cover,
    String? region,
  }) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/api/v1/rooms'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'id': id,
          'channelName': channelName,
          'hostName': hostName,
          'hostUid': hostUid,
          'title': title,
          'cover': cover,
          'region': region,
        }),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        print('🏠 [Room] 创建直播间成功: ${data['data']}');
      } else {
        print('🏠 [Room] 创建直播间失败: ${response.statusCode}');
      }
    } catch (e) {
      print('🏠 [Room] 创建直播间异常: $e');
    }
  }

  /// 结束直播（主播停播）
  static Future<void> deleteRoom(String id) async {
    try {
      final response = await http.delete(
        Uri.parse('$baseUrl/api/v1/rooms/$id'),
      );

      if (response.statusCode == 200) {
        print('🏠 [Room] 结束直播成功');
      } else {
        print('🏠 [Room] 结束直播失败: ${response.statusCode}');
      }
    } catch (e) {
      print('🏠 [Room] 结束直播异常: $e');
    }
  }

  /// 获取直播列表
  static Future<List<Map<String, dynamic>>> getLiveRooms() async {
    try {
      final response = await http.get(
        Uri.parse('$baseUrl/api/v1/rooms'),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final rooms = List<Map<String, dynamic>>.from(data['data']);
        print('🏠 [Room] 获取直播列表: ${rooms.length} 个直播间');
        return rooms;
      } else {
        print('🏠 [Room] 获取直播列表失败: ${response.statusCode}');
        return [];
      }
    } catch (e) {
      print('🏠 [Room] 获取直播列表异常: $e');
      return [];
    }
  }

  /// 获取单个房间信息
  static Future<Map<String, dynamic>?> getRoom(String id) async {
    try {
      final response = await http.get(
        Uri.parse('$baseUrl/api/v1/rooms/$id'),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return data['data'] as Map<String, dynamic>?;
      } else if (response.statusCode == 404) {
        print('🏠 [Room] 房间不存在: $id');
        return null;
      } else {
        print('🏠 [Room] 获取房间失败: ${response.statusCode}');
        return null;
      }
    } catch (e) {
      print('🏠 [Room] 获取房间异常: $e');
      return null;
    }
  }

  /// 更新直播间状态（idle -> live -> ended）
  static Future<void> updateRoomStatus(String id, String status) async {
    try {
      final response = await http.put(
        Uri.parse('$baseUrl/api/v1/rooms/$id/status'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'status': status}),
      );

      if (response.statusCode == 200) {
        print('🏠 [Room] 更新房间状态成功: $id -> $status');
      } else {
        print('🏠 [Room] 更新房间状态失败: ${response.statusCode}');
      }
    } catch (e) {
      print('🏠 [Room] 更新房间状态异常: $e');
    }
  }

  /// 获取房间在线人数（服务端 Set 统计，自动去重）
  static Future<int> getOnlineCount(String roomId) async {
    try {
      final response = await http.get(
        Uri.parse('$baseUrl/api/v1/rooms/$roomId/online-count'),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final count = data['data']?['count'] ?? 0;
        print('🏠 [Room] 获取在线人数: roomId=$roomId, count=$count');
        return count;
      } else {
        print('🏠 [Room] 获取在线人数失败: ${response.statusCode}');
        return 0;
      }
    } catch (e) {
      print('🏠 [Room] 获取在线人数异常: $e');
      return 0;
    }
  }
}
