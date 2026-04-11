-- ==================== 用户注册数据库表结构 ====================
-- 数据库：MySQL 5.7+
-- 特性：自增 ID → 偏移量生成 UID（7位起，自动扩展8位）

-- 创建数据库（如不存在）
CREATE DATABASE IF NOT EXISTS live_stream
  DEFAULT CHARACTER SET utf8mb4
  DEFAULT COLLATE utf8mb4_unicode_ci;

USE live_stream;

-- 用户表
CREATE TABLE IF NOT EXISTS users (
  id INT UNSIGNED AUTO_INCREMENT PRIMARY KEY COMMENT '自增主键（内部用）',
  uid VARCHAR(20) UNIQUE NOT NULL COMMENT '用户ID（对外展示，7位起）',
  phone VARCHAR(20) UNIQUE NOT NULL COMMENT '登录用手机号',
  created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP COMMENT '注册时间',
  
  -- 索引优化
  INDEX idx_uid (uid),
  INDEX idx_phone (phone)
  
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COMMENT='用户表';

-- 查看表结构
-- DESC users;

-- 模拟数据（测试 UID 生成）
-- INSERT INTO users (phone) VALUES ('13800138001'), ('13800138002');
-- SELECT id, uid, phone FROM users;
