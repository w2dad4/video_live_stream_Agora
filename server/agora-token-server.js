/**
 * Agora Token 服务端示例 (Node.js + Express)
 *
 * 安全原则:
 * 1. App Certificate 只在服务端保存
 * 2. 每次进入直播间重新生成 Token
 * 3. Token 绑定频道 + UID + 角色 + 时效
 * 4. 默认 1 小时有效期
 */

const express = require('express');
const cors = require('cors');
const { RtcTokenBuilder, RtcRole } = require('agora-access-token');

const app = express();
app.use(express.json());
app.use(cors());

// ==================== 配置 ====================
// ⚠️ 重要：这些配置只在服务端保存，不要泄露到客户端！
const AGORA_APP_ID = '5523e1ece1e84adb82c69c121b500a39';  // 你的 Agora App ID

// ✅ App Certificate 已配置（从 Agora 控制台获取）
// ⚠️ 安全警告：此文件只应在服务端运行，切勿暴露到客户端
const AGORA_APP_CERTIFICATE = '2ec67e13d42447629c79a5a925011814';
const TOKEN_EXPIRE_MINUTES = 60;                     // Token 有效期 60 分钟
// 默认主播房间号：
// 这里要和 Flutter 端 Agora 真正使用的频道规则保持一致。
// 当前约定：一个主播 = 一个频道，频道名格式为 `live_主播UID`
const DEFAULT_HOST_CHANNEL = process.env.DEFAULT_HOST_CHANNEL || 'live_me_123';
let currentDefaultHostChannel = DEFAULT_HOST_CHANNEL;

// ==================== Token 生成接口 ====================
/**
 * POST /api/v1/agora/token
 * Body: {
 *   channelName: string,  // 频道名（直播间ID）
 *   uid: string,        // 用户ID
 *   role: 'publisher' | 'subscriber',  // publisher=主播, subscriber=观众
 *   expireMinutes?: number  // 可选，自定义过期时间
 * }
 */
app.post('/token', (req, res) => {
  try {
    const { channelName, uid, role, expireMinutes } = req.body;
    // 参数校验
    if (!channelName || !uid || !role) {
      return res.status(400).json({
        code: 400,
        message: '缺少必要参数: channelName, uid, role',
      });
    }

    // 角色转换
    const rtcRole = role === 'publisher' ? RtcRole.PUBLISHER : RtcRole.SUBSCRIBER;

    // 生成数字 UID（Agora 需要数字 UID）
    // 策略：使用字符串 uid 的哈希值，确保同一用户在同一频道的 UID 一致
    const numericUid = generateNumericUid(uid);

    // 计算过期时间
    const expireTime = expireMinutes || TOKEN_EXPIRE_MINUTES;
    const currentTimestamp = Math.floor(Date.now() / 1000);
    const privilegeExpiredTs = currentTimestamp + (expireTime * 60);

    // 生成 Token
    const token = RtcTokenBuilder.buildTokenWithUid(
      AGORA_APP_ID,
      AGORA_APP_CERTIFICATE,
      channelName,
      numericUid,
      rtcRole,
      privilegeExpiredTs
    );

    // 返回结果
    res.json({
      code: 0,
      message: 'success',
      data: {
        token: token,
        uid: numericUid,
        channelName: channelName,
        role: role,
        expireTime: privilegeExpiredTs,  // 过期时间戳
        expireMinutes: expireTime,
      }
    });

    console.log(`[Token] 生成成功: channel=${channelName}, uid=${numericUid}, role=${role}, expire=${expireTime}min`);

  } catch (error) {
    console.error('[Token] 生成失败:', error);
    res.status(500).json({
      code: 500,
      message: 'Token 生成失败: ' + error.message,
    });
  }
});

/**
 * 将字符串 UID 转换为数字 UID
 * 确保同一字符串在同一频道产生相同的数字 UID
 */
function generateNumericUid(strUid) {
  // 使用简单的哈希算法生成数字 UID
  let hash = 0;
  for (let i = 0; i < strUid.length; i++) {
    const char = strUid.charCodeAt(i);
    hash = ((hash << 5) - hash) + char;
    hash = hash & hash; // 转换为 32bit 整数
  }
  // 确保正数且在 Agora 有效范围内 (1 - 2^32-1)
  return Math.abs(hash) || 1;
}

// ==================== 健康检查 ====================
app.get('/health', (req, res) => {
  res.json({ status: 'ok', timestamp: new Date().toISOString() });
});

// ==================== 调试辅助接口 ====================
// 用于浏览器测试页自动带出当前默认主播房间号
app.get('/default-room', (req, res) => {
  res.json({
    code: 0,
    message: 'success',
    data: {
      channelName: currentDefaultHostChannel,
    },
  });
});

// Flutter 主播端启动直播前调用：
// 将“当前登录用户实际使用的直播间ID”同步到本地 token 服务，
// 浏览器测试页随后读取这个值，就能自动填入真实房间号。
app.post('/default-room', (req, res) => {
  try {
    const { channelName } = req.body;

    if (!channelName || !channelName.toString().trim()) {
      return res.status(400).json({
        code: 400,
        message: '缺少必要参数: channelName',
      });
    }

    currentDefaultHostChannel = channelName.toString().trim();
    console.log(`[DefaultRoom] 已同步当前主播房间号: ${currentDefaultHostChannel}`);

    res.json({
      code: 0,
      message: 'success',
      data: {
        channelName: currentDefaultHostChannel,
      },
    });
  } catch (error) {
    console.error('[DefaultRoom] 同步失败:', error);
    res.status(500).json({
      code: 500,
      message: '默认房间号同步失败: ' + error.message,
    });
  }
});

// 主播停播后调用：
// 清空默认房间号，避免浏览器测试页继续自动进入一个已经失效的频道。
app.post('/default-room/clear', (req, res) => {
  currentDefaultHostChannel = DEFAULT_HOST_CHANNEL;
  console.log(`[DefaultRoom] 已清空当前主播房间号，恢复默认频道: ${currentDefaultHostChannel}`);

  res.json({
    code: 0,
    message: 'success',
    data: {
      channelName: currentDefaultHostChannel,
    },
  });
});

// ==================== 启动服务 ====================
// 只在直接运行此文件时启动服务器，被导入为模块时不启动
if (require.main === module) {
  const PORT = process.env.PORT || 8080;
  const HOST = '0.0.0.0'; // 绑定所有网卡，允许外部设备访问
  app.listen(PORT, HOST, () => {
    console.log(`🚀 Agora Token Server running on http://${HOST}:${PORT}`);
    console.log(`📡 Token endpoint: POST http://localhost:${PORT}/api/v1/agora/token`);
    console.log(`🏠 Default room endpoint: GET http://localhost:${PORT}/api/v1/agora/default-room`);
    console.log(`⏱️  Default expire time: ${TOKEN_EXPIRE_MINUTES} minutes`);
    console.log(`🔒 App Certificate is ${AGORA_APP_CERTIFICATE === 'YOUR_APP_CERTIFICATE' ? 'NOT SET ⚠️' : 'SET ✓'}`);
  });
}

module.exports = app;
