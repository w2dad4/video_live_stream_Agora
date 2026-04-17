/**
 * 统一服务器入口
 * 整合 Agora Token 服务、直播房间管理服务和 WebSocket 聊天服务
 */

const express = require('express');
const cors = require('cors');
const WebSocket = require('ws');
const http = require('http');

const app = express();
app.use(express.json());
app.use(cors());

// ==================== 配置 ====================
const TOKEN_PORT = process.env.TOKEN_PORT || 8080;
const ROOM_PORT = process.env.ROOM_PORT || 8081;
const PORT = process.env.PORT || 8080;
const HOST = '0.0.0.0';

// ==================== 导入服务模块 ====================
const tokenApp = require('./agora-token-server');
const roomApp = require('./live-room-server');

// ==================== 路由整合 ====================
// Token 服务路由
app.use('/api/v1/agora', tokenApp);

// 房间管理服务路由
app.use('/api/v1', roomApp);

// ==================== 在线人数统计 API ====================
/**
 * GET /api/v1/rooms/:roomId/online-count
 * 获取房间实时在线人数（基于 WebSocket 连接统计）
 */
app.get('/api/v1/rooms/:roomId/online-count', (req, res) => {
  try {
    const { roomId } = req.params;
    const presence = roomPresence.get(roomId);

    if (!presence) {
      return res.json({
        code: 0,
        message: 'success',
        data: { count: 0, hasHost: false },
      });
    }

    const count = presence.viewers.size;
    const hasHost = !!presence.host;

    res.json({
      code: 0,
      message: 'success',
      data: { count, hasHost },
    });
  } catch (error) {
    console.error('[OnlineCount] 获取失败:', error);
    res.status(500).json({
      code: 500,
      message: '获取在线人数失败: ' + error.message,
    });
  }
});

// ==================== 健康检查 ====================
app.get('/health', (req, res) => {
  res.json({
    status: 'ok',
    timestamp: new Date().toISOString(),
    services: {
      token: `http://localhost:${TOKEN_PORT}`,
      room: `http://localhost:${ROOM_PORT}`,
      websocket: `ws://${HOST}:${PORT}/ws/chat`,
    },
  });
});

// ==================== 启动 HTTP 服务 ====================
const server = http.createServer(app);

// ==================== WebSocket 聊天服务 ====================
const wss = new WebSocket.Server({ server, path: '/ws/chat' });

// 房间管理：roomId -> Set of WebSocket connections
const roomConnections = new Map();
// 在线人数统计：roomId -> { viewers: Set(socketId), host: socketId|null }
const roomPresence = new Map();

wss.on('connection', (ws, req) => {
  const url = new URL(req.url, `http://${req.headers.host}`);
  const roomId = url.searchParams.get('roomId');
  const userId = url.searchParams.get('userId') || 'anonymous';
  const userName = url.searchParams.get('userName') || '匿名用户';
  const role = url.searchParams.get('role') || 'viewer'; // 'host' | 'viewer'

  if (!roomId) {
    ws.close(1008, 'Missing roomId');
    return;
  }

  // 存储连接信息
  ws._roomId = roomId;
  ws._userId = userId;
  ws._userName = userName;
  ws._role = role;

  // 将连接加入房间
  if (!roomConnections.has(roomId)) {
    roomConnections.set(roomId, new Set());
  }
  roomConnections.get(roomId).add(ws);

  // 初始化房间 presence 数据
  if (!roomPresence.has(roomId)) {
    roomPresence.set(roomId, { viewers: new Set(), host: null });
  }
  const presence = roomPresence.get(roomId);

  // 根据角色更新人数
  if (role === 'host') {
    presence.host = ws;
  } else {
    presence.viewers.add(ws);
  }

  const viewerCount = presence.viewers.size;
  console.log(`[WebSocket] ${role === 'host' ? '主播' : '观众'} ${userName}(${userId}) 加入房间 ${roomId}，观众数: ${viewerCount}`);

  // 发送欢迎消息给该用户
  ws.send(JSON.stringify({
    type: 'system',
    uid: 'system',
    userName: '系统',
    content: `欢迎来到房间 ${roomId}`,
    timestamp: Date.now(),
  }));

  // 广播在线人数给房间内所有人（包括主播）
  broadcastOnlineCount(roomId);

  // 广播用户加入通知给房间内其他人
  if (role !== 'host') {
    broadcast(roomId, {
      type: 'join',
      uid: userId,
      userName: userName,
      content: `${userName} 加入了直播间`,
      timestamp: Date.now(),
    }, ws);
  }

  // 监听消息
  ws.on('message', (data) => {
    try {
      const message = JSON.parse(data);
      console.log(`[WebSocket] 房间 ${roomId} 收到消息:`, message);

      // 处理控制消息
      if (message.type === 'ping') {
        ws.send(JSON.stringify({ type: 'pong', timestamp: Date.now() }));
        return;
      }

      // 广播消息给房间内所有人（包括发送者）
      broadcast(roomId, {
        type: 'chat',
        uid: userId,
        userName: userName,
        content: message.content || '',
        timestamp: Date.now(),
      });
    } catch (err) {
      console.error('[WebSocket] 消息解析失败:', err);
    }
  });

  // 连接关闭
  ws.on('close', () => {
    const connections = roomConnections.get(roomId);
    if (connections) {
      connections.delete(ws);
      if (connections.size === 0) {
        roomConnections.delete(roomId);
        roomPresence.delete(roomId);
      } else {
        // 更新 presence 数据
        const p = roomPresence.get(roomId);
        if (p) {
          if (ws._role === 'host') {
            p.host = null;
          } else {
            p.viewers.delete(ws);
          }
          // 广播更新后的人数
          broadcastOnlineCount(roomId);

          // 广播用户离开通知（仅观众离开通知）
          if (ws._role !== 'host') {
            broadcast(roomId, {
              type: 'leave',
              uid: userId,
              userName: userName,
              content: `${userName} 离开了直播间`,
              timestamp: Date.now(),
            });
          }
        }
      }
      console.log(`[WebSocket] ${ws._role === 'host' ? '主播' : '观众'} ${userName} 离开房间 ${roomId}`);
    }
  });

  // 错误处理
  ws.on('error', (err) => {
    console.error('[WebSocket] 连接错误:', err);
  });
});

// 广播在线人数给房间内所有人
function broadcastOnlineCount(roomId) {
  const presence = roomPresence.get(roomId);
  if (!presence) return;

  const count = presence.viewers.size;
  broadcast(roomId, {
    type: 'onlineCount',
    uid: 'system',
    userName: '系统',
    content: String(count),
    timestamp: Date.now(),
    data: { count, hasHost: !!presence.host }
  });
}

// 广播消息给房间内所有连接
function broadcast(roomId, message, excludeWs = null) {
  const connections = roomConnections.get(roomId);
  if (!connections) return;

  const data = JSON.stringify(message);
  connections.forEach((ws) => {
    if (ws !== excludeWs && ws.readyState === WebSocket.OPEN) {
      ws.send(data);
    }
  });
}

// ==================== 启动服务 ====================
server.listen(PORT, HOST, () => {
  console.log(`🚀 统一服务器运行在 http://${HOST}:${PORT}`);
  console.log(`📡 Token 服务: http://localhost:${PORT}/api/v1/agora/token`);
  console.log(`📡 房间管理: http://localhost:${PORT}/api/v1/rooms`);
  console.log(`💬 WebSocket 聊天: ws://${HOST}:${PORT}/ws/chat?roomId=xxx&userId=xxx&userName=xxx`);
  console.log(`🏥 健康检查: http://localhost:${PORT}/health`);
});

module.exports = { app, server };
