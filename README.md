# Solo Journey

Solo Journey 是一个面向自由旅行者的真实分享平台，提供完整的 Go 后端与 Flutter 客户端示例。后端负责处理用户注册、旅行内容发布、积分排行与奖励兑换等核心功能，并通过元数据校验确保上传的图片 / 视频具有一定的可信度；前端提供移动端 UI，帮助用户轻松体验内容浏览、排行查看与奖励兑换流程。

## 功能亮点

- **真实内容上传**：旅行帖子支持图文、时间、地理信息等字段，后端在写入前会校验媒体文件的校验和与 GPS/时间元数据。
- **积分体系**：发布合规游记可自动积累积分，系统根据元数据可信度动态发放积分并提升等级。
- **排行与奖励**：内置积分排行榜接口，支持 Redis 排行榜或内存排行榜；奖励列表、兑换流水与积分记录均可通过 API 获取。
- **Flutter 客户端**：提供登录注册、旅行 Feed、排行榜、奖励兑换、个人中心与发布页面，支持通过 REST API 与后端交互并展示等级进度与积分历史。

## 目录结构

```
.
├── backend/            # Go 后端服务
│   ├── cmd/server      # 可执行入口
│   └── internal        # 领域逻辑、数据层、HTTP 传输等
└── mobile/             # Flutter 客户端示例
    ├── lib/            # App 源码
    └── pubspec.yaml    # 依赖声明
```

## 后端运行

1. 进入后端目录并设置依赖：
   ```bash
   cd backend
   go mod tidy
   ```
2. （可选）配置环境变量：
   ```bash
   export SERVER_PORT=8080           # 默认 8080
   export DATABASE_PATH=solo_journey.db
   export JWT_SECRET=change-me
   export REDIS_ADDR=localhost:6379  # 配置后自动使用 Redis 排行榜
   ```
3. 启动服务：
   ```bash
   go run ./cmd/server
   ```
4. 运行测试：
   ```bash
   go test ./...
   ```

## 主要 API

- `POST /api/v1/auth/register`：注册用户。
- `POST /api/v1/auth/login`：登录并获取 JWT。
- `GET /api/v1/trips`：分页获取旅行帖子。
- `GET /api/v1/trips/:id`：查看单条旅行帖子详情。
- `POST /api/v1/trips`：发布旅行帖子（需要 Bearer Token，需提供媒体哈希与 GPS/时间元数据）。
- `GET /api/v1/leaderboard`：获取积分排行榜。
- `GET /api/v1/rewards`：获取奖励列表。
- `POST /api/v1/rewards/redeem`：兑换奖励（需要 Bearer Token）。
- `GET /api/v1/me`：获取用户概览（等级进度、平均可信度、近期旅程等）。
- `GET /api/v1/me/history`：查询积分变动历史（需要 Bearer Token）。
- `GET /api/v1/me/redemptions`：查询奖励兑换记录（需要 Bearer Token）。

## Flutter 客户端

1. 确保已安装 Flutter 3.10+，然后获取依赖：
   ```bash
   cd mobile
   flutter pub get
   ```
2. 如需连接到后端，可在 `mobile/lib/services/api_service.dart` 中调整 `baseUrl`。
3. 启动调试：
   ```bash
   flutter run
   ```

客户端提供：
- 登录 / 注册切换界面。
- 旅行动态（支持下拉刷新）。
- 积分排行榜与奖励兑换对话框。
- 发布旅程表单（含媒体元数据输入）。

## 开发建议

- 生产环境建议使用持久化数据库（如 PostgreSQL/MySQL）并在对象存储上保存真实媒体文件。
- 可以扩展媒体校验逻辑（如 EXIF 解析、哈希比对）以提升内容真实性。
- Flutter 端可接入状态管理、离线缓存以及地图 SDK 等能力增强体验。
