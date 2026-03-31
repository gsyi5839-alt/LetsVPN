# 桌面端 API 接入文档（生产环境可用）

> 本文档基于当前服务器实际代码与配置生成（非模板）。  
> 生成时间：2026-03-31

## 1. 生产环境信息

- 生产域名：`https://lrtsvpn.com`
- API 前缀：`https://lrtsvpn.com/desktop/api/v1`
- 响应格式：JSON（统一有 `ret/msg/data`）
- 当前签名状态：`desktop_event_sign_secret` 未配置（即 `/events/batch` 当前不强制签名）
- 批量事件上报限制：单次最多 200 条
- 去重规则：`device_id + event_type + 时间窗口(默认10秒)`

统一成功响应格式：

```json
{
  "ret": 1,
  "msg": "",
  "data": {}
}
```

统一失败响应格式：

```json
{
  "ret": 0,
  "msg": "错误信息"
}
```

---

## 2. 桌面端最小接入（建议先实现）

只接这 4 个接口就能跑完整链路：

1. `GET /desktop/api/v1/downloads`
2. `POST /desktop/api/v1/install/check`
3. `POST /desktop/api/v1/install/confirm`
4. `POST /desktop/api/v1/events/batch`

---

## 3. 必接接口（详细）

## 3.1 下载清单

- 方法：`GET`
- URL：`https://lrtsvpn.com/desktop/api/v1/downloads`

请求示例：

```bash
curl -X GET 'https://lrtsvpn.com/desktop/api/v1/downloads'
```

当前服务器真实响应示例（节选）：

```json
{
  "ret": 1,
  "msg": "",
  "data": {
    "downloads": {
      "windows": [
        {
          "platform": "windows",
          "channel": "letsvpn-windows-x64",
          "filename": "LetsVPN-windows-x64.exe",
          "download_url": "https://lrtsvpn.com/downloads/LetsVPN-windows-x64.exe",
          "bridge_url": "https://lrtsvpn.com/desktop/download/windows/letsvpn-windows-x64"
        }
      ]
    },
    "push_endpoint": "https://lrtsvpn.com/desktop/api/v1/downloads/push",
    "resolve_endpoint": "https://lrtsvpn.com/desktop/api/v1/downloads/resolve"
  }
}
```

---

## 3.2 安装核对

- 方法：`GET` 或 `POST`
- URL：`https://lrtsvpn.com/desktop/api/v1/install/check`

### GET 参数

| 参数 | 必填 | 默认 | 说明 |
|---|---|---|---|
| platform | 否 | windows | 平台 |
| last_check | 否 | 空 | 预留字段（当前逻辑未使用） |

### POST Body（推荐）

```json
{
  "platform": "windows",
  "installed_packages": {
    "14": {
      "version_id": "20260331",
      "install_time": 1774940000
    }
  }
}
```

当前服务器真实响应示例（节选）：

```json
{
  "ret": 1,
  "msg": "",
  "data": {
    "platform": "windows",
    "total_packages": 1,
    "needs_install_count": 1,
    "needs_install": [
      {
        "id": 14,
        "title": "VPN",
        "version_id": "20260331",
        "package_url": "https://kuaichengasd.oss-cn-hongkong.aliyuncs.com/II-3.exe",
        "silent_args": "/S"
      }
    ],
    "install_endpoint": "https://lrtsvpn.com/desktop/api/v1/install/confirm",
    "next_check_after": 3600
  }
}
```

---

## 3.3 安装完成上报

- 方法：`POST`
- URL：`https://lrtsvpn.com/desktop/api/v1/install/confirm`
- Header：`Content-Type: application/json`

Body 参数：

| 参数 | 必填 | 说明 |
|---|---|---|
| device_id | 是 | 设备唯一 ID |
| package_id | 是 | 包 ID |
| version_id | 是 | 版本号 |
| status | 否 | 状态字符串 |
| message | 否 | 备注/错误信息 |
| install_time | 否 | 秒级时间戳（默认当前） |
| platform | 否 | 默认 windows |
| user_id | 否 | 用户 ID |
| client_version | 否 | 客户端版本 |

请求示例：

```bash
curl -X POST 'https://lrtsvpn.com/desktop/api/v1/install/confirm' \
  -H 'Content-Type: application/json' \
  -d '{
    "device_id":"device-uuid-001",
    "package_id":14,
    "version_id":"20260331",
    "status":"success",
    "install_time":1774942000,
    "platform":"windows"
  }'
```

成功示例：

```json
{
  "ret": 1,
  "msg": "Install recorded",
  "data": {
    "recorded": true,
    "package_id": 14,
    "version_id": "20260331",
    "next_check": "2026-03-31 18:00:00"
  }
}
```

失败示例：

```json
{
  "ret": 0,
  "msg": "Missing required fields: device_id, package_id, version_id"
}
```

---

## 3.4 批量事件上报（主上报接口）

- 方法：`POST`
- URL：`https://lrtsvpn.com/desktop/api/v1/events/batch`
- Header：`Content-Type: application/json`

### 顶层字段

| 字段 | 必填 | 说明 |
|---|---|---|
| events | 是 | 事件数组，1~200 条 |
| device_id | 否 | 默认设备ID（可被 events[i].device_id 覆盖） |
| user_id | 否 | 默认用户ID |
| platform | 否 | 默认平台 |
| client_version | 否 | 默认客户端版本 |
| timestamp / ts | 条件必填 | 开启签名时必填 |
| sign | 条件必填 | 开启签名时必填 |

### `events[i]` 字段

| 字段 | 必填 | 说明 |
|---|---|---|
| event_type | 是 | 事件类型 |
| event_time | 否 | 秒级时间戳（默认当前） |
| device_id / visitor_id | 否 | 子项设备ID |
| user_id | 否 | 子项用户ID |
| platform | 否 | 子项平台 |
| client_version | 否 | 子项版本 |
| ad_id | 否 | 关联广告ID |
| extra | 否 | 扩展信息（对象或字符串） |
| channel / filename / download_url | 否 | 下载场景扩展字段 |

请求示例：

```json
{
  "device_id": "device-uuid-001",
  "user_id": 123,
  "platform": "windows",
  "client_version": "1.2.3",
  "events": [
    {
      "event_type": "install_completed",
      "event_time": 1774942000,
      "ad_id": 14,
      "extra": {
        "version_id": "20260331",
        "status": "success"
      }
    },
    {
      "event_type": "click",
      "event_time": 1774942010
    }
  ]
}
```

成功响应示例：

```json
{
  "ret": 1,
  "msg": "",
  "data": {
    "saved": 2,
    "duplicate": 0,
    "failed": 0,
    "items": [
      {
        "saved": true,
        "id": 1001,
        "normalized_type": "install",
        "index": 0
      },
      {
        "saved": true,
        "id": 1002,
        "normalized_type": "click",
        "index": 1
      }
    ]
  }
}
```

常见失败：

- `400 events is required.`
- `400 Too many events in one request.`
- `401 Invalid signature.`（仅在启用签名时）

---

## 4. 签名规则（你启用后再接）

当你在服务端配置 `desktop_event_sign_secret` 后，客户端按下列规则计算：

1. 简单签名：

```text
sign = md5(device_id + secret + timestamp)
```

2. HMAC 签名：

```text
sign = HMAC_SHA256_HEX(timestamp + "." + raw_body, secret)
```

注意：

- `timestamp` 必须是秒级时间戳。
- `raw_body` 必须是实际发送的原始 JSON 字符串（不能重排字段后再签）。

---

## 5. 可选接口（按需接）

## 5.1 广告列表

- `GET /desktop/api/v1/ads`
- 参数：`placement`（默认 `optional_install`）、`platform`（默认 `windows`）、`limit`（默认 `5`）

## 5.2 广告事件上报

- `POST /desktop/api/v1/ads/event`
- 允许 `event_type`：
  - `ad_impression`
  - `ad_click`
  - `ad_dismiss`
  - `ad_install_redirect`
  - `download_click`
  - `download_install`
  - `download_open`

## 5.3 下载包解析

- `GET /desktop/api/v1/downloads/package`
- 参数：`platform`、`channel`、`arch`

## 5.4 下载过程上报

- `POST /desktop/api/v1/downloads/resolve`
- `POST /desktop/api/v1/downloads/push`

## 5.5 Web 下载桥接

- `GET /desktop/download/{platform}/{channel}`
- 行为：记录 `download_click` 并 302 跳转真实下载地址。

## 5.6 安装历史/批量核对

- `GET /desktop/api/v1/install/history?device_id=...&days=7`
- `POST /desktop/api/v1/install/batch-check`

## 5.7 节点下发（如果桌面端要直连节点）

- `GET /desktop/api/v1/nodes?token=...`
- `GET /desktop/api/v1/nodes/{token}`

---

## 6. 建议接入顺序（你可以直接给桌面端同事）

1. 先接 `downloads` + `install/check` + `install/confirm`。
2. 再接 `events/batch`，把点击/激活/安装事件统一批量上报。
3. 最后补 `ads/event`、`downloads/push` 等可选接口。

---

## 7. 你现在最关心的结论

- 你的生产域名已经固定：`https://lrtsvpn.com`
- 文档中的 URL 都可以直接用
- 当前 `/events/batch` 不强制签名（因为服务端未配置 secret）
- 如果你要上签名，我可以下一步直接给你桌面端 C#/Electron 两份签名代码片段
