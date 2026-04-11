# 用户注册服务（后端生成 UID）

## 流程

```
Flutter 注册页面
    ↓ 填写手机号
    ↓ POST /api/v1/auth/register
Node.js 后端
    ↓ 检查手机号是否已存在（防重复）
    ↓ BEGIN TRANSACTION
    ↓ INSERT INTO users (phone) → 获取自增 id
    ↓ 偏移量算法生成 uid（7位起）
    ↓ UPDATE users SET uid = ? WHERE id = ?
    ↓ COMMIT
    ↓ 返回 {uid, phone, created_at}
Flutter 保存 uid，进入首页
```

## UID 生成算法（偏移量）

```
数据库自增 id    生成 UID
    1      →    1000000  (7位起始)
    2      →    1000001
  100      →    1000099
 9000000   →    9999999  (7位用完)
 9000001   →    10000000 (8位起始)
```

## 安装依赖

```bash
cd server
npm init -y
npm install express cors mysql2
```

## 启动服务

```bash
# 设置环境变量（可选）
export DB_HOST=localhost
export DB_USER=root
export DB_PASSWORD=yourpassword
export DB_NAME=live_stream
export PORT=3000

# 启动
node user-register-server.js
```

## API 接口

### 1. 注册用户

```bash
curl -X POST http://localhost:3000/api/v1/auth/register \
  -H "Content-Type: application/json" \
  -d '{"phone": "13800138000"}'
```

**成功响应：**
```json
{
  "code": 0,
  "message": "注册成功",
  "data": {
    "uid": "1000000",
    "phone": "13800138000",
    "created_at": "2024-01-15 10:30:00"
  }
}
```

**重复注册：**
```json
{
  "code": 409,
  "message": "该手机号已注册",
  "data": {
    "uid": "1000000",
    "registered_at": "2024-01-15 10:30:00"
  }
}
```

### 2. 查询用户信息

```bash
curl http://localhost:3000/api/v1/users/1000000
```

## 数据库表

```sql
CREATE TABLE users (
  id INT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
  uid VARCHAR(20) UNIQUE NOT NULL,
  phone VARCHAR(20) UNIQUE NOT NULL,
  created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);
```
