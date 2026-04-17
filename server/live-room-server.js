/**
 * 直播房间管理服务端 (Node.js + Express)
 *
 * 功能：
 * 1. 记录谁在直播
 * 2. 提供直播列表
 * 3. 标记直播结束
 */

const express = require('express');
const cors = require('cors');

const app = express();
app.use(express.json());
app.use(cors());

// ==================== 配置 ====================
const PORT = process.env.PORT || 8081;
const HOST = '0.0.0.0';

// ==================== 内存存储（直播房间） ====================
// 生产环境应该使用数据库（MySQL/Redis）
// 格式：{ id, channelName, hostName, hostUid, title, cover, region, startTime, status }
const liveRooms = new Map();

// ==================== API 接口 ====================

/**
 * POST /api/v1/rooms
 * 主播开播 → 创建直播间
 * Body: {
 *   id: string,          // 房间ID（唯一标识）
 *   channelName: string, // Agora 频道名
 *   hostName: string,   // 主播昵称
 *   hostUid: string,    // 主播UID
 *   title: string,      // 直播标题
 *   cover: string,      // 封面图片URL
 *   region: string      // 地区
 * }
 */
app.post('/rooms', (req, res) => {
  try {
    const { id, channelName, hostName, hostUid, title, cover, region } = req.body;

    // 参数校验
    if (!id || !channelName || !hostName) {
      return res.status(400).json({
        code: 400,
        message: '缺少必要参数: id, channelName, hostName',
      });
    }

    // 检查房间是否已存在
    if (liveRooms.has(id)) {
      return res.status(409).json({
        code: 409,
        message: '房间已存在',
      });
    }

    // 创建房间（初始状态为 idle，未开播）
    const room = {
      id,
      channelName,
      hostName,
      hostUid: hostUid || '',
      title: title || '直播中',
      cover: cover || '',
      region: region || '',
      startTime: new Date().toISOString(),
      status: 'idle', // idle: 已创建未开播, live: 直播中, ended: 已结束
      watchCount: 0, // 观看人数，初始为0
    };

    liveRooms.set(id, room);

    console.log(`[Room] 创建直播间: id=${id}, channelName=${channelName}, host=${hostName}, status=idle`);

    res.json({
      code: 0,
      message: 'success',
      data: room,
    });

  } catch (error) {
    console.error('[Room] 创建失败:', error);
    res.status(500).json({
      code: 500,
      message: '创建直播间失败: ' + error.message,
    });
  }
});

/**
 * GET /api/v1/rooms
 * 观众请求 → 获取直播列表（按观看人数降序）
 */
app.get('/rooms', (req, res) => {
  try {
    // 获取所有正在直播的房间
    const allRooms = Array.from(liveRooms.values())
      .filter(room => room.status === 'live');

    // 模拟观看人数递增（实际应该从Agora API获取真实在线人数）
    allRooms.forEach(room => {
      // 随机增加观看人数（模拟真实场景）
      room.watchCount = room.watchCount + Math.floor(Math.random() * 5);
    });

    // 按观看人数降序排序
    const sortedRooms = allRooms.sort((a, b) => b.watchCount - a.watchCount);

    // 返回所有房间（包含观看人数）
    const rooms = sortedRooms.map(room => ({
      id: room.id,
      channelName: room.channelName,
      hostName: room.hostName,
      title: room.title,
      cover: room.cover,
      region: room.region,
      startTime: room.startTime,
      watchCount: room.watchCount,
    }));

    console.log(`[Room] 获取直播列表: ${rooms.length} 个直播间，热门: ${rooms[0]?.hostName || 'none'}(${rooms[0]?.watchCount || 0}人)`);

    res.json({
      code: 0,
      message: 'success',
      data: rooms,
    });
  } catch (error) {
    console.error('[Room] 获取列表失败:', error);
    res.status(500).json({
      code: 500,
      message: '获取直播列表失败: ' + error.message,
    });
  }
});

/**
 * PUT /api/v1/rooms/:id/status
 * 更新直播间状态（开始直播/结束直播）
 * Body: { status: 'idle' | 'live' | 'ended' }
 */
app.put('/rooms/:id/status', (req, res) => {
  try {
    const { id } = req.params;
    const { status } = req.body;

    if (!liveRooms.has(id)) {
      return res.status(404).json({
        code: 404,
        message: '房间不存在',
      });
    }

    if (!['idle', 'live', 'ended'].includes(status)) {
      return res.status(400).json({
        code: 400,
        message: '无效状态值，只能是: idle, live, ended',
      });
    }

    const room = liveRooms.get(id);
    room.status = status;
    
    // 如果开始直播，更新 startTime
    if (status === 'live') {
      room.startTime = new Date().toISOString();
    }

    console.log(`[Room] 更新房间状态: id=${id}, status=${status}`);

    res.json({
      code: 0,
      message: 'success',
      data: { id, status, startTime: room.startTime },
    });
  } catch (error) {
    console.error('[Room] 更新状态失败:', error);
    res.status(500).json({
      code: 500,
      message: '更新房间状态失败: ' + error.message,
    });
  }
});

/**
 * GET /api/v1/rooms/:id
 * 获取单个房间信息（用于观众进入前检查）
 */
app.get('/rooms/:id', (req, res) => {
  try {
    const { id } = req.params;

    if (!liveRooms.has(id)) {
      return res.status(404).json({
        code: 404,
        message: '房间不存在',
      });
    }

    const room = liveRooms.get(id);

    res.json({
      code: 0,
      message: 'success',
      data: {
        id: room.id,
        channelName: room.channelName,
        hostName: room.hostName,
        title: room.title,
        cover: room.cover,
        region: room.region,
        startTime: room.startTime,
        status: room.status,
        watchCount: room.watchCount,
      },
    });
  } catch (error) {
    console.error('[Room] 获取房间失败:', error);
    res.status(500).json({
      code: 500,
      message: '获取房间信息失败: ' + error.message,
    });
  }
});

/**
 * DELETE /api/v1/rooms/:id
 * 主播停播 → 直接删除房间（不保留已结束状态）
 */
app.delete('/rooms/:id', (req, res) => {
  try {
    const { id } = req.params;

    if (!liveRooms.has(id)) {
      return res.status(404).json({
        code: 404,
        message: '房间不存在',
      });
    }

    // 获取房间信息用于日志
    const room = liveRooms.get(id);

    // ❗直接删除，不标记 status
    liveRooms.delete(id);

    console.log(`[Room] 直播结束并删除: id=${id}, channelName=${room.channelName}`);

    res.json({
      code: 0,
      message: 'success',
      data: { id, deleted: true },
    });

  } catch (error) {
    console.error('[Room] 结束直播失败:', error);
    res.status(500).json({
      code: 500,
      message: '结束直播失败: ' + error.message,
    });
  }
});

/**
 * GET /api/v1/rooms/:id
 * 获取单个房间信息（观众进入前校验用）
 */
app.get('/rooms/:id', (req, res) => {
  try {
    const { id } = req.params;

    // ❗直接检查是否存在，不存在返回 404
    if (!liveRooms.has(id)) {
      return res.status(404).json({
        code: 404,
        message: '直播已结束或不存在',
      });
    }

    const room = liveRooms.get(id);

    res.json({
      code: 0,
      message: 'success',
      data: {
        id: room.id,
        channelName: room.channelName,
        hostName: room.hostName,
        title: room.title,
        region: room.region,
        startTime: room.startTime,
      },
    });

  } catch (error) {
    console.error('[Room] 获取房间信息失败:', error);
    res.status(500).json({
      code: 500,
      message: '获取房间信息失败: ' + error.message,
    });
  }
});

// ==================== 健康检查 ====================
app.get('/health', (req, res) => {
  res.json({ 
    status: 'ok', 
    timestamp: new Date().toISOString(),
    liveRoomsCount: liveRooms.size,
  });
});

// ==================== 启动服务 ====================
// 只在直接运行此文件时启动服务器，被导入为模块时不启动
if (require.main === module) {
  app.listen(PORT, HOST, () => {
    console.log(`🚀 Live Room Server running on http://${HOST}:${PORT}`);
    console.log(`📡 房间管理接口:`);
    console.log(`   POST   http://localhost:${PORT}/api/v1/rooms - 创建直播间`);
    console.log(`   GET    http://localhost:${PORT}/api/v1/rooms - 获取直播列表`);
    console.log(`   GET    http://localhost:${PORT}/api/v1/rooms/:id - 获取房间信息`);
    console.log(`   DELETE http://localhost:${PORT}/api/v1/rooms/:id - 结束直播`);
  });
}

module.exports = app;
