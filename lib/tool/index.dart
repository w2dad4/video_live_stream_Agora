import 'package:flutter_riverpod/flutter_riverpod.dart';

class VideoIndex {
  //此数据模拟的联系人
  static Provider<List<Map<String, dynamic>>> contactProvider = Provider<List<Map<String, dynamic>>>((ref) {
    return [
      {"id": "sys_file", "icon": "assets/image/002.png", "title": "文件传输"},
      {"id": "sys_search", "icon": "assets/image/003.png", "title": "搜索"},
      {"id": "1", "icon": "assets/image/004.jpeg", "title": "张三"},
      {"id": "2", "icon": "assets/image/005.jpeg", "title": "Flutter 交流群"},
    ];
  });

  static List<Map<String, dynamic>> contentsindex = [];

  final List<Map<String, dynamic>> videocontext = [
    {'video': 'assets/image/video_demo'},
    {'video': 'assets/image/video_demo1'},
    {'video': 'assets/image/video_demo2'},
    {'video': 'assets/image/video_demo3'},
    {'video': 'assets/image/video_demo4'},
    {'video': 'assets/image/video_demo5'},
    {'video': 'assets/image/video_demo6'},
    {'video': 'assets/image/video_demo7'},
    {'video': 'assets/image/video_demo8'},
  ];
  static List<Map<String, String>> gameList = [
    {'id': '1', 'name': '贪吃蛇', 'desc': '经典复古游戏，控制小蛇不断吃食物长大，避免撞墙或咬到自己。', 'image': 'https://cdn-icons-png.flaticon.com/512/876/876235.png'},
    {'id': '2', 'name': '俄罗斯方块', 'desc': '下落的方块需拼接成完整横线消除，考验反应与空间规划能力。', 'image': 'https://cdn-icons-png.flaticon.com/512/1092/1092640.png'},
    {'id': '3', 'name': '植物大战僵尸', 'desc': '在草坪上种植各类植物，抵御一波波僵尸入侵，策略塔防经典之作。', 'image': 'https://cdn-icons-png.flaticon.com/512/3095/3095460.png'},
    {'id': '4', 'name': '扫雷', 'desc': '根据数字提示避开地雷，逻辑推理找出所有安全区域。', 'image': 'https://cdn-icons-png.flaticon.com/512/3095/3095475.png'},
    {'id': '5', 'name': '数独', 'desc': '填满 9×9 宫格，使每行、每列和每个 3×3 区域都包含 1-9 不重复数字。', 'image': 'https://cdn-icons-png.flaticon.com/512/3135/3135825.png'},
    {'id': '6', 'name': '消消乐', 'desc': '交换相邻图标，凑齐三个相同图案即可消除，轻松解压的三消玩法。', 'image': 'https://cdn-icons-png.flaticon.com/512/3095/3095533.png'},
    {'id': '7', 'name': '跳一跳', 'desc': '轻触屏幕控制小人跳跃到下一个平台，节奏与距离感是关键。', 'image': 'https://cdn-icons-png.flaticon.com/512/3695/3695382.png'},
    {'id': '8', 'name': '合成大西瓜', 'desc': '将相同水果两两合并，最终目标是合成出大西瓜，魔性又上头。', 'image': 'https://cdn-icons-png.flaticon.com/512/3095/3095553.png'},
    {'id': '9', 'name': '羊了个羊', 'desc': '号称“第二关难倒千万人”的消除游戏，道具与顺序决定成败。', 'image': 'https://cdn-icons-png.flaticon.com/512/3095/3095500.png'},
    {'id': '10', 'name': '2048', 'desc': '滑动合并相同数字方块，目标是合成出 2048，策略与运气并存。', 'image': 'https://cdn-icons-png.flaticon.com/512/3095/3095450.png'},
    {'id': '11', 'name': '愤怒的小鸟', 'desc': '用弹弓发射小鸟，摧毁猪堡结构，物理弹道与关卡设计巧妙结合。', 'image': 'https://cdn-icons-png.flaticon.com/512/1996/1996433.png'},
    {'id': '12', 'name': '水果忍者', 'desc': '手指滑动切开飞出的水果，避开炸弹，享受爽快切割快感。', 'image': 'https://cdn-icons-png.flaticon.com/512/3095/3095520.png'},
    {'id': '13', 'name': '纪念碑谷', 'desc': '操控视错觉建筑，引导沉默公主穿越不可能的几何迷宫，艺术感极强。', 'image': 'https://cdn-icons-png.flaticon.com/512/3695/3695390.png'},
    {'id': '14', 'name': '开心消消乐', 'desc': '国民级三消游戏，数百关卡+可爱动物角色，老少皆宜。', 'image': 'https://cdn-icons-png.flaticon.com/512/3095/3095533.png'},
    {'id': '15', 'name': '球球大作战', 'desc': '操控小球吞噬比你小的玩家，同时躲避更大的对手，实时多人竞技。', 'image': 'https://cdn-icons-png.flaticon.com/512/3095/3095490.png'},
    {'id': '16', 'name': '我的世界（迷你版）', 'desc': '沙盒建造与生存探索，自由创造属于你的像素世界（简化体验版）。', 'image': 'https://cdn-icons-png.flaticon.com/512/1092/1092650.png'},
    {'id': '17', 'name': '像素地牢', 'desc': 'Roguelike 地牢探险，每次进入地图随机生成，死亡即重来，硬核耐玩。', 'image': 'https://cdn-icons-png.flaticon.com/512/3095/3095480.png'},
    {'id': '18', 'name': '割绳子', 'desc': '剪断绳子让糖果落入小怪兽口中，利用物理机关完成关卡挑战。', 'image': 'https://cdn-icons-png.flaticon.com/512/3095/3095510.png'},
    {'id': '19', 'name': '涂鸦跳跃', 'desc': '控制小怪物不断向上跳跃，避开障碍、收集星星，永无止境的冒险。', 'image': 'https://cdn-icons-png.flaticon.com/512/3695/3695385.png'},
    {'id': '20', 'name': 'Flappy Bird', 'desc': '点击屏幕让小鸟飞起，穿越密集的绿色管道，操作简单却极难通关。', 'image': 'https://cdn-icons-png.flaticon.com/512/1996/1996420.png'},
  ];
}
