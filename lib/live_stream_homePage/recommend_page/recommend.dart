import 'package:flutter/material.dart';
import 'package:video_live_stream/tool/color.dart';
import 'package:video_live_stream/services/live_room_service.dart';
import 'package:video_live_stream/utility/pullRefreshContainer.dart';

class RecommendPage extends StatefulWidget {
  const RecommendPage({super.key});

  @override
  State<RecommendPage> createState() => RecommendPageState();
}

class RecommendPageState extends State<RecommendPage> {
  List<Map<String, dynamic>> _liveRooms = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _fetchLiveRooms();
  }

  Future<void> _fetchLiveRooms() async {
    final rooms = await LiveRoomService.getLiveRooms();
    if (!mounted) return;
    setState(() {
      _liveRooms = rooms;
      _isLoading = false;
    });
  }

  Future<void> _onRefresh() async {
    await _fetchLiveRooms();
  }

  /// 获取热门主播（观看人数最多的前4个）
  List<Map<String, dynamic>> get _hotAnchors {
    if (_liveRooms.length <= 4) return _liveRooms;
    return _liveRooms.sublist(0, 4);
  }

  /// 获取推荐主播（剩余的）
  List<Map<String, dynamic>> get _recommendAnchors {
    if (_liveRooms.length <= 4) return [];
    return _liveRooms.sublist(4);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: ColorState.color1,
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _liveRooms.isEmpty
              ? const Center(
                  child: Text('请去关注一下主播吧', style: TextStyle(color: Colors.white, fontSize: 16)),
                )
              : PullRefreshContainer(
                  onRefresh: _onRefresh,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min, // 让 Column 自适应内容高度
                    children: [
                      // 热门主播区块
                      _buildHotAnchorsSection(),
                      // 推荐主播标题
                      if (_recommendAnchors.isNotEmpty)
                        _buildSectionTitle('推荐主播'),
                      // 推荐主播列表
                      ListView.builder(
                        physics: const NeverScrollableScrollPhysics(),
                        shrinkWrap: true, // 解决无限高度问题
                        padding: EdgeInsets.zero,
                        itemCount: _recommendAnchors.length,
                        itemBuilder: (context, index) {
                          final room = _recommendAnchors[index];
                          return _LiveRoomCard(room: room);
                        },
                      ),
                    ],
                  ),
                ),
    );
  }

  /// 构建热门主播区块
  Widget _buildHotAnchorsSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildSectionTitle('热门主播'),
        SizedBox(
          height: 200,
          child: ListView.builder(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 16),
            itemCount: _hotAnchors.length,
            itemBuilder: (context, index) {
              final room = _hotAnchors[index];
              return _HotAnchorCard(room: room, rank: index + 1);
            },
          ),
        ),
        const SizedBox(height: 16),
      ],
    );
  }

  /// 构建区块标题
  Widget _buildSectionTitle(String title) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
      child: Row(
        children: [
          Container(
            width: 4,
            height: 20,
            decoration: BoxDecoration(
              color: Colors.pink,
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          const SizedBox(width: 8),
          Text(
            title,
            style: const TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
          ),
        ],
      ),
    );
  }
}

/// 热门主播卡片（横向显示）
class _HotAnchorCard extends StatelessWidget {
  final Map<String, dynamic> room;
  final int rank;

  const _HotAnchorCard({required this.room, required this.rank});

  @override
  Widget build(BuildContext context) {
    final watchCount = room['watchCount'] ?? 0;

    return Container(
      width: 140,
      margin: const EdgeInsets.only(right: 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 封面图 + 排名标识
          Stack(
            children: [
              ClipRRect(
                borderRadius: BorderRadius.circular(8),
                child: Container(
                  height: 140,
                  width: 140,
                  color: Colors.grey,
                  child: room['cover']?.isNotEmpty == true
                      ? Image.network(room['cover'], fit: BoxFit.cover, errorBuilder: (_, __, ___) => Container(color: Colors.grey))
                      : Container(color: Colors.grey),
                ),
              ),
              // 排名标识
              Positioned(
                top: 8,
                left: 8,
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: rank <= 3 ? Colors.pink : Colors.black54,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    'TOP$rank',
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),
              // 观看人数
              Positioned(
                bottom: 8,
                right: 8,
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                  decoration: BoxDecoration(
                    color: Colors.black54,
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(Icons.visibility, size: 12, color: Colors.white),
                      const SizedBox(width: 2),
                      Text(
                        '$watchCount',
                        style: const TextStyle(color: Colors.white, fontSize: 10),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          // 主播名
          Text(
            room['hostName'] ?? '主播',
            style: const TextStyle(
              color: Colors.white,
              fontSize: 14,
              fontWeight: FontWeight.w500,
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
          const SizedBox(height: 2),
          // 标题
          Text(
            room['title'] ?? '直播中',
            style: TextStyle(
              color: Colors.grey[400],
              fontSize: 12,
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }
}

class _LiveRoomCard extends StatelessWidget {
  final Map<String, dynamic> room;

  const _LiveRoomCard({required this.room});

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 400,
      color: Colors.black,
      child: Stack(
        children: [
          // 背景图（封面）
          Positioned.fill(
            child: room['cover']?.isNotEmpty == true
                ? Image.network(room['cover'], fit: BoxFit.cover, errorBuilder: (_, __, ___) => Container(color: Colors.grey))
                : Container(color: Colors.grey),
          ),
          // UI 层
          Positioned.fill(
            child: Container(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(5),
                          color: Colors.purple,
                        ),
                        child: const Text('直播中', style: TextStyle(fontSize: 12, color: Colors.white)),
                      ),
                      const SizedBox(width: 8),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(5),
                          color: Colors.white,
                        ),
                        child: Text('你的关注', style: TextStyle(fontSize: 12, color: ColorState.color1)),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Text(
                    room['title'] ?? '直播中',
                    style: const TextStyle(fontSize: 18, color: Colors.white, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    room['hostName'] ?? '主播',
                    style: const TextStyle(fontSize: 14, color: Colors.white),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
