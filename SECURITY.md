# 桌面端每日安装包核对 API 文档

## 基础信息

- **Base URL**: `https://lrtsvpn.com`
- **响应格式**: JSON
- **响应码**: `ret` 字段，1=成功，0=失败

---

## API 列表

### 1. 核对今日需要安装的包

**GET** `/desktop/api/v1/install/check`  
**POST** `/desktop/api/v1/install/check`

#### 请求参数

| 参数名 | 类型 | 必填 | 说明 |
|--------|------|------|------|
| platform | string | 否 | 平台：windows/macos，默认 windows |
| last_check | string | 否 | 上次核对日期，格式：YYYY-MM-DD |

#### POST 请求体示例

```json
{
  "platform": "windows",
  "installed_packages": {
    "14": {
      "version_id": "20260329",
      "install_time": 1774876381
    }
  }
}
```

#### 成功响应 (HTTP 200)

```json
{
  "ret": 1,
  "msg": "",
  "data": {
    "check_date": "2026-03-30",
    "check_timestamp": 1774876989,
    "platform": "windows",
    "total_packages": 1,
    "needs_install_count": 1,
    "needs_install": [
      {
        "id": 14,
        "title": "VPN",
        "description": "",
        "publisher": "",
        "package_size": "",
        "version_id": "20260330",
        "is_today_update": true,
        "updated_at": 1774876381,
        "updated_date": "2026-03-30 21:13:01",
        "package_url": "https://kuaichengasd.oss-cn-hongkong.aliyuncs.com/II-3.exe",
        "entry_executable": "II-3.exe",
        "installer_entry": "II-3.exe",
        "silent_args": "/S",
        "install_args": "/S",
        "md5_checksum": "",
        "force_install": false
      }
    ],
    "all_packages": [
      {
        "id": 14,
        "title": "VPN",
        "description": "",
        "publisher": "",
        "package_size": "",
        "version_id": "20260330",
        "is_today_update": true,
        "updated_at": 1774876381,
        "updated_date": "2026-03-30 21:13:01",
        "package_url": "https://kuaichengasd.oss-cn-hongkong.aliyuncs.com/II-3.exe",
        "entry_executable": "II-3.exe",
        "installer_entry": "II-3.exe",
        "silent_args": "/S",
        "install_args": "/S",
        "md5_checksum": "",
        "force_install": false
      }
    ],
    "install_endpoint": "https://lrtsvpn.com/desktop/api/v1/install/confirm",
    "next_check_after": 3600
  }
}
```

#### 失败响应 (HTTP 500 / 异常)

```json
{
  "ret": 0,
  "msg": "Database connection failed",
  "data": null
}
```

---

### 2. 确认安装完成

**POST** `/desktop/api/v1/install/confirm`

#### 请求参数

| 参数名 | 类型 | 必填 | 说明 |
|--------|------|------|------|
| device_id | string | 是 | 设备唯一标识 |
| package_id | int | 是 | 安装的包ID |
| version_id | string | 是 | 安装的版本号 |
| status | string | 否 | 状态：success/failed，默认 success |
| message | string | 否 | 失败原因或备注 |
| install_time | int | 否 | 安装完成时间戳，默认当前时间 |
| platform | string | 否 | 平台，默认 windows |

#### 请求体示例

```json
{
  "device_id": "device-uuid-001",
  "package_id": 14,
  "version_id": "20260330",
  "status": "success",
  "message": "",
  "install_time": 1774876381,
  "platform": "windows"
}
```

#### 成功响应 (HTTP 200)

```json
{
  "ret": 1,
  "msg": "Install recorded",
  "data": {
    "recorded": true,
    "package_id": 14,
    "version_id": "20260330",
    "next_check": "2026-03-30 22:23:09"
  }
}
```

#### 失败响应 - 缺少必填参数 (HTTP 400)

```json
{
  "ret": 0,
  "msg": "Missing required fields: device_id, package_id, version_id",
  "data": null
}
```

#### 失败响应 - 服务器错误 (HTTP 500)

```json
{
  "ret": 0,
  "msg": "Failed to record install event",
  "data": null
}
```

---

### 3. 批量核对多个平台

**POST** `/desktop/api/v1/install/batch-check`

#### 请求参数

| 参数名 | 类型 | 必填 | 说明 |
|--------|------|------|------|
| platforms | array | 否 | 平台列表，默认 ["windows"] |
| last_check | string | 否 | 上次核对日期 |
| installed_data | object | 否 | 各平台已安装数据 |

#### 请求体示例

```json
{
  "platforms": ["windows", "macos"],
  "last_check": "2025-03-29",
  "installed_data": {
    "windows": {
      "14": {
        "version_id": "20260329"
      }
    },
    "macos": {
      "15": {
        "version_id": "20260329"
      }
    }
  }
}
```

#### 成功响应 (HTTP 200)

```json
{
  "ret": 1,
  "msg": "",
  "data": {
    "check_date": "2026-03-30",
    "platforms_checked": 2,
    "results": {
      "windows": {
        "needs_install_count": 1,
        "needs_install": [
          {
            "id": 14,
            "title": "VPN",
            "version_id": "20260330",
            "package_url": "https://kuaichengasd.oss-cn-hongkong.aliyuncs.com/II-3.exe",
            "entry_executable": "II-3.exe",
            "silent_args": "/S"
          }
        ]
      },
      "macos": {
        "needs_install_count": 0,
        "needs_install": []
      }
    }
  }
}
```

#### 失败响应 (HTTP 500)

```json
{
  "ret": 0,
  "msg": "Database connection failed",
  "data": null
}
```

---

### 4. 查询安装历史

**GET** `/desktop/api/v1/install/history`

#### 请求参数

| 参数名 | 类型 | 必填 | 说明 |
|--------|------|------|------|
| device_id | string | 是 | 设备唯一标识 |
| days | int | 否 | 查询天数，默认 7 |

#### 请求示例

```
GET /desktop/api/v1/install/history?device_id=device-uuid-001&days=7
```

#### 成功响应 (HTTP 200)

```json
{
  "ret": 1,
  "msg": "",
  "data": {
    "device_id": "device-uuid-001",
    "history_days": 7,
    "total_records": 3,
    "history": [
      {
        "package_id": 14,
        "version_id": "20260330",
        "status": "success",
        "install_time": 1774876381,
        "install_date": "2026-03-30 21:13:01"
      },
      {
        "package_id": 14,
        "version_id": "20260329",
        "status": "success",
        "install_time": 1774790000,
        "install_date": "2026-03-29 12:33:20"
      }
    ]
  }
}
```

#### 失败响应 - 缺少参数 (HTTP 400)

```json
{
  "ret": 0,
  "msg": "device_id is required",
  "data": null
}
```

#### 失败响应 - 无历史记录 (HTTP 200，但 history 为空)

```json
{
  "ret": 1,
  "msg": "",
  "data": {
    "device_id": "device-uuid-001",
    "history_days": 7,
    "total_records": 0,
    "history": []
  }
}
```

---

## 桌面端集成示例

### 每日检查流程

```javascript
// 1. 获取今日需要安装的包
async function checkDailyInstalls() {
  const deviceId = getDeviceId(); // 获取或生成设备唯一标识
  const platform = 'windows';
  
  // 从本地存储读取已安装记录
  const installedPackages = JSON.parse(localStorage.getItem('installed_packages') || '{}');
  
  const response = await fetch('https://lrtsvpn.com/desktop/api/v1/install/check', {
    method: 'POST',
    headers: {
      'Content-Type': 'application/json'
    },
    body: JSON.stringify({
      platform: platform,
      installed_packages: installedPackages
    })
  });
  
  const result = await response.json();
  
  if (result.ret === 1) {
    const needsInstall = result.data.needs_install;
    
    for (const pkg of needsInstall) {
      // 2. 下载安装包
      const downloaded = await downloadPackage(pkg.package_url, pkg.entry_executable);
      
      if (downloaded) {
        // 3. 执行静默安装
        const installSuccess = await silentInstall(
          pkg.entry_executable, 
          pkg.silent_args
        );
        
        // 4. 上报安装结果
        await confirmInstall(deviceId, pkg.id, pkg.version_id, installSuccess);
        
        // 5. 更新本地记录
        if (installSuccess) {
          installedPackages[pkg.id] = {
            version_id: pkg.version_id,
            install_time: Math.floor(Date.now() / 1000)
          };
          localStorage.setItem('installed_packages', JSON.stringify(installedPackages));
        }
      }
    }
    
    // 6. 设置下次检查时间
    const nextCheckMs = result.data.next_check_after * 1000;
    setTimeout(checkDailyInstalls, nextCheckMs);
  }
}

// 上报安装完成
async function confirmInstall(deviceId, packageId, versionId, success) {
  await fetch('https://lrtsvpn.com/desktop/api/v1/install/confirm', {
    method: 'POST',
    headers: {
      'Content-Type': 'application/json'
    },
    body: JSON.stringify({
      device_id: deviceId,
      package_id: packageId,
      version_id: versionId,
      status: success ? 'success' : 'failed',
      install_time: Math.floor(Date.now() / 1000)
    })
  });
}
```

---

## 管理系统更新流程

### 每日更新安装包步骤

1. **准备新安装包**
   - 编译或获取新的软件包
   - 命名建议：`II-3-20260330.exe`（带日期版本）

2. **上传到 OSS**
   - 上传到新路径，例如：
   - `https://kuaichengasd.oss-cn-hongkong.aliyuncs.com/II-3-20260330.exe`

3. **更新管理后台**
   - 登录 `https://lrtsvpn.com/admin/desktop-ad`
   - 编辑对应广告位
   - 修改字段：
     - `package_url`: 新的OSS地址
     - `link`: 同上（可选）
   - 保存

4. **自动触发**
   - 保存后 `updated_at` 字段自动更新为当前时间
   - version_id 变为 `20260330`（基于更新日期）
   - 桌面端下次检查时检测到版本变化
   - 自动下载并安装新版本

---

## 错误处理建议

| 错误场景 | 建议处理 |
|---------|---------|
| API 返回 ret=0 | 记录错误日志，稍后重试 |
| HTTP 000/超时 | 网络问题，1小时后重试 |
| 下载失败 | 尝试3次，失败后跳过 |
| 安装失败 | 上报 failed 状态，不重试 |
| version_id 对比 | 本地 < 服务器时才安装 |

---

## 版本控制说明

- **version_id 格式**: `YYYYMMDD`，基于 `desktop_ad_campaign.updated_at`
- **更新检测**: 对比本地记录的 version_id 与服务器返回的 version_id
- **强制重装**: 可通过设置 `force_install: true` 实现（需修改API逻辑）
