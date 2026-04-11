/**
 * 用户注册服务 (Node.js + Express + MySQL)
 * 功能：注册生成 UID，7位起，偏移量算法，防重复注册
 */

const express = require('express');
const cors = require('cors');
const mysql = require('mysql2/promise');

const app = express();
app.use(express.json());
app.use(cors());

// ==================== MySQL 配置 ====================
const DB_CONFIG = {
  host: process.env.DB_HOST || 'localhost',
  user: process.env.DB_USER || 'root',
  password: process.env.DB_PASSWORD || '',
  database: process.env.DB_NAME || 'live_stream',
  waitForConnections: true,
  connectionLimit: 10,
};

const pool = mysql.createPool(DB_CONFIG);

// ==================== UID 生成算法 ====================
// 偏移量算法：7位起，自动扩展到8位

const UID_CONFIG = {
  min7Digit: 1000000,   // 7位起始值
  max7Digit: 9999999,   // 7位最大值
  min8Digit: 10000000,  // 8位起始值
  max8Digit: 99999999,  // 8位最大值
};

/**
 * 根据数据库自增 ID 生成 UID（偏移量算法）
 * @param {number} id - 数据库自增 ID
 * @returns {string} - 7位或8位 UID
 */
function generateUidByOffset(id) {
  // 计算位数
  const digits = calculateDigits(id);
  // 获取基数
  const baseOffset = getBaseOffset(digits);
  // 当前位数范围内的序号
  const sequenceInRange = getSequenceInRange(id, digits);
  // UID = 基数 + 序号 - 1
  const uid = baseOffset + sequenceInRange - 1;
  return uid.toString();
}

function calculateDigits(id) {
  if (id <= UID_CONFIG.max7Digit) return 7;
  if (id <= UID_CONFIG.max8Digit) return 8;
  return id.toString().length;
}

function getBaseOffset(digits) {
  switch (digits) {
    case 7: return UID_CONFIG.min7Digit;
    case 8: return UID_CONFIG.min8Digit;
    default: return Math.pow(10, digits - 1);
  }
}

function getSequenceInRange(id, digits) {
  if (digits === 7) return id;
  if (digits === 8) return id - UID_CONFIG.max7Digit;
  const prevMax = Math.pow(10, digits - 1) - 1;
  return id - prevMax;
}

// ==================== 数据库初始化 ====================
async function initDatabase() {
  const connection = await pool.getConnection();
  try {
    // 创建用户表
    await connection.execute(`
      CREATE TABLE IF NOT EXISTS users (
        id INT UNSIGNED AUTO_INCREMENT PRIMARY KEY COMMENT '自增主键（内部用）',
        uid VARCHAR(20) UNIQUE NOT NULL COMMENT '用户ID（对外展示）',
        phone VARCHAR(20) UNIQUE NOT NULL COMMENT '登录用手机号',
        created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP COMMENT '注册时间',
        INDEX idx_uid (uid),
        INDEX idx_phone (phone)
      ) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COMMENT='用户表';
    `);
    console.log('✅ 数据库表初始化完成');
  } finally {
    connection.release();
  }
}

// ==================== 注册接口 ====================
/**
 * POST /api/v1/auth/register
 * Body: { phone: string }
 * Response: { code: 0, data: { uid, phone, created_at } }
 */
app.post('/api/v1/auth/register', async (req, res) => {
  const { phone } = req.body;

  // 参数校验
  if (!phone || !/^1[3-9]\d{9}$/.test(phone)) {
    return res.status(400).json({
      code: 400,
      message: '手机号格式错误',
    });
  }

  const connection = await pool.getConnection();
  try {
    // 开启事务
    await connection.beginTransaction();

    // 1. 检查手机号是否已存在（防重复注册）
    const [existing] = await connection.execute(
      'SELECT uid, phone, created_at FROM users WHERE phone = ?',
      [phone]
    );

    if (existing.length > 0) {
      await connection.rollback();
      return res.status(409).json({
        code: 409,
        message: '该手机号已注册',
        data: {
          uid: existing[0].uid,
          registered_at: existing[0].created_at,
        },
      });
    }

    // 2. 插入用户（获取自增 ID）
    const [insertResult] = await connection.execute(
      'INSERT INTO users (phone) VALUES (?)',
      [phone]
    );

    const insertId = insertResult.insertId;

    // 3. 生成 UID（偏移量算法）
    const uid = generateUidByOffset(insertId);

    // 4. 更新用户的 uid 字段
    await connection.execute(
      'UPDATE users SET uid = ? WHERE id = ?',
      [uid, insertId]
    );

    // 提交事务
    await connection.commit();

    // 5. 查询返回完整数据
    const [user] = await connection.execute(
      'SELECT uid, phone, created_at FROM users WHERE id = ?',
      [insertId]
    );

    console.log(`✅ 用户注册成功: phone=${phone}, uid=${uid}`);

    res.json({
      code: 0,
      message: '注册成功',
      data: user[0],
    });

  } catch (error) {
    await connection.rollback();
    console.error('❌ 注册失败:', error);
    res.status(500).json({
      code: 500,
      message: '注册失败: ' + error.message,
    });
  } finally {
    connection.release();
  }
});

// ==================== 查询用户信息 ====================
app.get('/api/v1/users/:uid', async (req, res) => {
  const { uid } = req.params;

  try {
    const [users] = await pool.execute(
      'SELECT uid, phone, created_at FROM users WHERE uid = ?',
      [uid]
    );

    if (users.length === 0) {
      return res.status(404).json({
        code: 404,
        message: '用户不存在',
      });
    }

    res.json({
      code: 0,
      data: users[0],
    });
  } catch (error) {
    console.error('查询失败:', error);
    res.status(500).json({
      code: 500,
      message: '查询失败',
    });
  }
});

// ==================== 健康检查 ====================
app.get('/health', (req, res) => {
  res.json({ status: 'ok', service: 'user-register' });
});

// ==================== 启动服务 ====================
const PORT = process.env.PORT || 3000;
app.listen(PORT, '0.0.0.0', async () => {
  console.log(`🚀 用户注册服务启动: http://0.0.0.0:${PORT}`);
  console.log(`📡 注册接口: POST http://localhost:${PORT}/api/v1/auth/register`);
  console.log(`📡 查询接口: GET http://localhost:${PORT}/api/v1/users/{uid}`);
  await initDatabase();
});

module.exports = { app, generateUidByOffset };
