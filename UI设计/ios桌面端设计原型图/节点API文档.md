# LrtsVPN 桌面程序接入 API 文档

**Base URL**: `https://lrtsvpn.com/api/v1`
**协议**: HTTPS
**认证方式**: 账号密码（6-20位字母或数字）

---

## 接入流程

### 方式一：直接登录（适用于桌面程序内嵌登录框）

```
用户打开桌面程序
    │
    ├─ 有账号 → POST /api/v1/login     → 获得 token
    │
    └─ 无账号 → POST /api/v1/register  → 自动获得 token
                    │
                    ▼
        GET /api/v1/nodes/{token}           → 获取全部节点 JSON
        GET /api/v1/nodes/{token}/subscribe/{type} → 获取客户端订阅
                    │
                    ▼
            程序解析节点信息，建立代理连接
```

### 方式二：浏览器授权登录（推荐，类似 GitHub CLI）

```
用户打开桌面程序，点击"登录"
    │
    ▼
POST /api/v1/auth/device        → 获得 device_code + login_url
    │
    ├─ 桌面程序打开浏览器 → login_url（用户在网页登录/注册）
    │
    └─ 桌面程序轮询 GET /api/v1/auth/check/{device_code}
         │
         ├─ status: "pending"    → 继续轮询（间隔 3 秒）
         │
         └─ status: "authorized" → 获得 token，登录成功！
                │
                ▼
    GET /api/v1/nodes/{token}           → 获取全部节点
    GET /api/v1/nodes/{token}/subscribe/{type} → 获取订阅
```

token 长期有效，客户端保存后无需重复登录。

---

## 目录

1. [注册](#1-注册)
2. [登录](#2-登录)
3. [设备授权 - 获取设备码](#3-设备授权---获取设备码)
4. [设备授权 - 轮询状态](#4-设备授权---轮询状态)
5. [设备授权 - 确认授权](#5-设备授权---确认授权)
6. [获取全部节点](#6-获取全部节点)
7. [获取客户端订阅](#7-获取客户端订阅)
8. [错误码](#8-错误码)
9. [节点数据结构](#9-节点数据结构)
10. [桌面程序接入示例](#10-桌面程序接入示例)

---

## 1. 注册

```
POST /api/v1/register
Content-Type: application/x-www-form-urlencoded
```

### 请求参数

| 参数       | 类型   | 必填 | 说明                              |
|------------|--------|------|-----------------------------------|
| `account`  | string | 是   | 账号（6-20位字母或数字）          |
| `password` | string | 是   | 密码（6-20位字母或数字）          |

### 成功响应 `200`

```json
{
  "ret": 1,
  "data": {
    "token": "c331e8c3fe174968",
    "user": {
      "id": 14,
      "account": "testuser123",
      "uuid": "ebfb7ab5-25f0-4105-b450-3685c8b63914"
    }
  }
}
```

### 失败响应

```json
{"ret": 0, "msg": "该账号已被注册"}
{"ret": 0, "msg": "账号长度必须为6-20位"}
{"ret": 0, "msg": "账号只能包含字母和数字"}
{"ret": 0, "msg": "密码长度必须为6-20位"}
{"ret": 0, "msg": "密码只能包含字母和数字"}
{"ret": 0, "msg": "账号和密码不能为空"}
```

---

## 2. 登录

```
POST /api/v1/login
Content-Type: application/x-www-form-urlencoded
```

### 请求参数

| 参数       | 类型   | 必填 | 说明     |
|------------|--------|------|----------|
| `account`  | string | 是   | 账号     |
| `password` | string | 是   | 密码     |

### 成功响应 `200`

```json
{
  "ret": 1,
  "data": {
    "token": "c331e8c3fe174968",
    "user": {
      "id": 14,
      "account": "testuser123",
      "uuid": "ebfb7ab5-25f0-4105-b450-3685c8b63914"
    }
  }
}
```

### 失败响应

```json
{"ret": 0, "msg": "账号或密码错误"}
{"ret": 0, "msg": "账户已被禁用"}
{"ret": 0, "msg": "账号和密码不能为空"}
```

### 关键说明

- `token` 是后续所有请求的唯一凭证，客户端应持久化保存
- 同一用户每次登录返回的 token 相同，不会变化
- `user.uuid` 即 Trojan 连接密码
- `user.account` 是用户的账号名

---

## 3. 设备授权 - 获取设备码

桌面程序调用此接口获取设备码和登录页面 URL。

```
POST /api/v1/auth/device
```

### 请求参数

无。

### 成功响应 `200`

```json
{
  "ret": 1,
  "data": {
    "device_code": "61398ebee8b9d64aedb76448fc53cbdb",
    "user_code": "63531F",
    "login_url": "https://lrtsvpn.com/auth/device?code=61398ebee8b9d64aedb76448fc53cbdb",
    "expires_in": 300,
    "interval": 3
  }
}
```

### 字段说明

| 字段          | 说明                                           |
|---------------|------------------------------------------------|
| `device_code` | 设备码，用于轮询授权状态                       |
| `user_code`   | 用户码（可在网页上显示给用户确认）             |
| `login_url`   | 登录页面 URL，桌面程序用浏览器打开此地址       |
| `expires_in`  | 设备码有效期（秒），超时需重新获取             |
| `interval`    | 建议的轮询间隔（秒）                           |

### 桌面程序处理流程

1. 调用此接口获取 `device_code` 和 `login_url`
2. 调用 `shell.openExternal(login_url)` 打开用户默认浏览器
3. 在界面上显示"等待浏览器登录..."
4. 开始轮询 `/api/v1/auth/check/{device_code}`

---

## 4. 设备授权 - 轮询状态

桌面程序定时调用此接口检查用户是否已在浏览器完成授权。

```
GET /api/v1/auth/check/{device_code}
```

### 等待中响应

```json
{
  "ret": 0,
  "msg": "authorization_pending",
  "data": {
    "status": "pending"
  }
}
```

### 授权成功响应

```json
{
  "ret": 1,
  "data": {
    "status": "authorized",
    "token": "c331e8c3fe174968",
    "user": {
      "id": 14,
      "account": "testuser123",
      "uuid": "ebfb7ab5-25f0-4105-b450-3685c8b63914"
    }
  }
}
```

### 设备码过期响应

```json
{
  "ret": 0,
  "msg": "expired",
  "data": {
    "status": "expired"
  }
}
```

### 轮询逻辑

```
while (true) {
    resp = GET /api/v1/auth/check/{device_code}

    if (resp.data.status == "authorized") {
        // 登录成功！保存 token
        saveToken(resp.data.token)
        break
    }
    if (resp.data.status == "expired") {
        // 超时，需重新发起设备授权
        break
    }
    // status == "pending"，继续等待
    sleep(3 秒)
}
```

---

## 5. 设备授权 - 确认授权

此接口由**网页端**调用（不是桌面程序调用）。用户在浏览器登录页面输入账号密码后，网页 JS 调用此接口完成授权。

```
POST /api/v1/auth/confirm
Content-Type: application/x-www-form-urlencoded
```

### 请求参数

| 参数          | 类型   | 必填 | 说明                 |
|---------------|--------|------|----------------------|
| `device_code` | string | 是   | 设备码               |
| `account`     | string | 是   | 账号                 |
| `password`    | string | 是   | 密码                 |

### 成功响应

```json
{
  "ret": 1,
  "msg": "授权成功，桌面程序将自动登录"
}
```

### 失败响应

```json
{"ret": 0, "msg": "账号或密码错误"}
{"ret": 0, "msg": "设备码无效或已过期"}
{"ret": 0, "msg": "缺少必要参数"}
```

---

## 6. 获取全部节点

```
GET /api/v1/nodes/{token}
```

### 响应头

```
Content-Type: application/json
ETag: W/"xxxxxxxxxxxx"
Access-Control-Allow-Origin: *
Cache-Control: no-store, no-cache
```

支持 `If-None-Match` 条件请求，数据未变时返回 `304 Not Modified`（节省带宽）。

### 成功响应 `200`

```json
{
  "ret": 1,
  "data": {
    "schema": "public-nodes.v1",
    "version": "25.1.0",
    "generated_at": "2026-03-13T13:18:17+08:00",
    "user": {
      "id": 14,
      "account": "testuser123",
      "uuid": "ebfb7ab5-25f0-4105-b450-3685c8b63914"
    },
    "nodes": [
      {
        "id": 1,
        "name": "🇭🇰 香港 01",
        "protocol": "trojan",
        "sort": 14,
        "server": "203.91.76.136",
        "port": 443,
        "credentials": {
          "password": "ebfb7ab5-25f0-4105-b450-3685c8b63914"
        },
        "transport": {
          "network": "tcp",
          "path": "",
          "service_name": "",
          "headers": []
        },
        "security": {
          "tls": true,
          "sni": "lrtsvpn.com",
          "allow_insecure": true
        },
        "traffic_rate": 1.0,
        "status": {
          "online": 1,
          "online_user": 0
        }
      }
    ],
    "count": 95
  }
}
```

---

## 7. 获取客户端订阅

```
GET /api/v1/nodes/{token}/subscribe/{type}
```

### 支持的格式

| type         | 说明               | 适用客户端                        |
|--------------|--------------------|-----------------------------------|
| `clash`      | Clash YAML 配置    | Clash Verge / Mihomo              |
| `singbox`    | sing-box JSON      | sing-box / NekoBox                |
| `v2ray`      | Base64 订阅        | V2RayN / V2RayNG                  |
| `v2rayjson`  | V2Ray JSON         | V2Ray 核心                        |
| `trojan`     | Trojan URL 列表    | Trojan 客户端                     |
| `sip008`     | SIP008 JSON        | Shadowsocks 客户端                |
| `json`       | 原始 JSON          | 自定义解析                        |

### 响应

```
Content-Type: text/plain; charset=utf-8
```

返回对应格式的纯文本内容，可直接写入配置文件。

---

## 8. 错误码

| HTTP 状态码 | ret | msg                           | 说明                 |
|-------------|-----|-------------------------------|----------------------|
| 200         | 1   | -                             | 成功                 |
| 400         | 0   | 账号和密码不能为空            | 缺少参数             |
| 400         | 0   | 账号长度必须为6-20位          | 账号长度不合规       |
| 400         | 0   | 账号只能包含字母和数字        | 账号含非法字符       |
| 400         | 0   | 密码长度必须为6-20位          | 密码长度不合规       |
| 400         | 0   | 密码只能包含字母和数字        | 密码含非法字符       |
| 400         | 0   | Invalid subscribe type.       | 订阅格式无效         |
| 400         | 0   | 缺少必要参数                  | 设备授权缺参数       |
| 401         | 0   | 账号或密码错误                | 认证失败             |
| 401         | 0   | Invalid token.                | Token 无效           |
| 401         | 0   | 设备码无效或已过期            | 设备码失效           |
| 403         | 0   | 账户已被禁用                  | 账号被封             |
| 404         | 0   | User not found.               | 用户不存在           |
| 409         | 0   | 该账号已被注册                | 账号重复             |

---

## 9. 节点数据结构

### 节点字段

| 字段                    | 类型   | 说明                                          |
|-------------------------|--------|-----------------------------------------------|
| `id`                    | int    | 节点 ID                                       |
| `name`                  | string | 节点名称（含国旗），如 `🇭🇰 香港 01`         |
| `protocol`              | string | `trojan` / `shadowsocks` / `vmess` / `tuic`   |
| `sort`                  | int    | 协议编号：14=Trojan, 11=VMess, 0=SS, 1=SS2022, 2=TUIC |
| `server`                | string | 服务器 IP                                     |
| `port`                  | int    | 连接端口                                      |
| `credentials`           | object | 认证凭据（见下方）                            |
| `transport.network`     | string | 传输方式：`tcp` / `ws` / `grpc`               |
| `transport.path`        | string | WebSocket 路径                                |
| `security.tls`          | bool   | 是否 TLS                                      |
| `security.sni`          | string | TLS SNI                                       |
| `security.allow_insecure` | bool | 跳过证书验证                                  |
| `traffic_rate`          | float  | 流量倍率（1.0 = 不加倍）                     |
| `status.online`         | int    | 1=在线, 0=新节点, -1=离线                     |
| `status.online_user`    | int    | 在线用户数                                    |

### credentials（按协议）

**Trojan** (当前所有节点均为此协议)
```json
{"password": "用户UUID"}
```

**VMess**
```json
{"uuid": "用户UUID", "alter_id": 0, "encryption": "auto"}
```

**Shadowsocks**
```json
{"method": "加密方式", "password": "密码"}
```

**TUIC**
```json
{"uuid": "用户UUID", "password": "密码"}
```

---

## 10. 桌面程序接入示例

### Electron / Node.js（浏览器授权登录 - 推荐）

```javascript
const { shell } = require("electron");
const API = "https://lrtsvpn.com/api/v1";

class LrtsVPN {
  constructor() {
    this.token = null;
  }

  // ========== 方式一：浏览器授权登录（推荐）==========

  // 发起设备授权
  async startDeviceAuth() {
    const resp = await fetch(`${API}/auth/device`, { method: "POST" });
    const { ret, data } = await resp.json();
    if (ret !== 1) throw new Error("Failed to start device auth");
    return data; // { device_code, login_url, expires_in, interval }
  }

  // 打开浏览器登录页面
  openLoginPage(loginUrl) {
    shell.openExternal(loginUrl);
  }

  // 轮询等待授权完成
  async waitForAuth(deviceCode, interval = 3, timeout = 300) {
    const startTime = Date.now();

    while (Date.now() - startTime < timeout * 1000) {
      const resp = await fetch(`${API}/auth/check/${deviceCode}`);
      const result = await resp.json();

      if (result.ret === 1 && result.data.status === "authorized") {
        this.token = result.data.token;
        return result.data; // { token, user: { id, account, uuid } }
      }

      if (result.data?.status === "expired") {
        throw new Error("授权已过期，请重新登录");
      }

      // 等待后继续轮询
      await new Promise(r => setTimeout(r, interval * 1000));
    }

    throw new Error("授权超时");
  }

  // 一键登录（发起授权 → 打开浏览器 → 等待完成）
  async loginWithBrowser() {
    const authData = await this.startDeviceAuth();
    this.openLoginPage(authData.login_url);

    // 返回 Promise，桌面程序可显示"等待浏览器登录..."
    return await this.waitForAuth(
      authData.device_code,
      authData.interval,
      authData.expires_in
    );
  }

  // ========== 方式二：直接登录 ==========

  async login(account, password) {
    const resp = await fetch(`${API}/login`, {
      method: "POST",
      headers: { "Content-Type": "application/x-www-form-urlencoded" },
      body: `account=${encodeURIComponent(account)}&password=${encodeURIComponent(password)}`
    });
    const { ret, data, msg } = await resp.json();
    if (ret !== 1) throw new Error(msg);
    this.token = data.token;
    return data;
  }

  async register(account, password) {
    const resp = await fetch(`${API}/register`, {
      method: "POST",
      headers: { "Content-Type": "application/x-www-form-urlencoded" },
      body: `account=${encodeURIComponent(account)}&password=${encodeURIComponent(password)}`
    });
    const { ret, data, msg } = await resp.json();
    if (ret !== 1) throw new Error(msg);
    this.token = data.token;
    return data;
  }

  // ========== 节点操作 ==========

  async getNodes() {
    const resp = await fetch(`${API}/nodes/${this.token}`);
    const { ret, data, msg } = await resp.json();
    if (ret !== 1) throw new Error(msg);
    return data.nodes;
  }

  async getClashConfig() {
    const resp = await fetch(`${API}/nodes/${this.token}/subscribe/clash`);
    return await resp.text();
  }

  async getSingboxConfig() {
    const resp = await fetch(`${API}/nodes/${this.token}/subscribe/singbox`);
    return await resp.text();
  }

  buildTrojanUrl(node) {
    const pw = node.credentials.password;
    const sni = node.security.sni;
    return `trojan://${pw}@${node.server}:${node.port}?sni=${sni}&allowInsecure=1#${encodeURIComponent(node.name)}`;
  }
}

// === 使用示例 ===

const vpn = new LrtsVPN();

// 推荐方式：浏览器授权登录
try {
  const userData = await vpn.loginWithBrowser();
  console.log(`登录成功！用户: ${userData.user.account}`);

  const nodes = await vpn.getNodes();
  console.log(`共 ${nodes.length} 个节点`);

  // 保存 token 到本地
  localStorage.setItem("vpn_token", vpn.token);
} catch (e) {
  console.error("登录失败:", e.message);
}

// 下次启动时恢复 token
vpn.token = localStorage.getItem("vpn_token");
if (vpn.token) {
  const nodes = await vpn.getNodes();
  // 直接使用，无需重新登录
}
```

### Python (PyQt / Tkinter 桌面应用)

```python
import requests
import time
import webbrowser
import json

API = "https://lrtsvpn.com/api/v1"

class LrtsVPN:
    def __init__(self):
        self.token = None
        self.user = None

    # ========== 浏览器授权登录（推荐）==========

    def start_device_auth(self) -> dict:
        """获取设备码和登录URL"""
        resp = requests.post(f"{API}/auth/device")
        result = resp.json()
        if result["ret"] != 1:
            raise Exception("获取设备码失败")
        return result["data"]

    def wait_for_auth(self, device_code: str, interval: int = 3, timeout: int = 300) -> dict:
        """轮询等待授权完成"""
        start = time.time()
        while time.time() - start < timeout:
            resp = requests.get(f"{API}/auth/check/{device_code}")
            result = resp.json()

            if result.get("ret") == 1 and result["data"]["status"] == "authorized":
                self.token = result["data"]["token"]
                self.user = result["data"]["user"]
                return result["data"]

            if result["data"].get("status") == "expired":
                raise Exception("授权已过期")

            time.sleep(interval)
        raise Exception("授权超时")

    def login_with_browser(self) -> dict:
        """一键浏览器登录"""
        auth = self.start_device_auth()
        webbrowser.open(auth["login_url"])
        print(f"已打开浏览器，请在网页中登录... (有效期 {auth['expires_in']} 秒)")
        return self.wait_for_auth(auth["device_code"], auth["interval"], auth["expires_in"])

    # ========== 直接登录 ==========

    def login(self, account: str, password: str) -> dict:
        resp = requests.post(f"{API}/login", data={
            "account": account, "password": password
        })
        result = resp.json()
        if result["ret"] != 1:
            raise Exception(result["msg"])
        self.token = result["data"]["token"]
        self.user = result["data"]["user"]
        return result["data"]

    def register(self, account: str, password: str) -> dict:
        resp = requests.post(f"{API}/register", data={
            "account": account, "password": password
        })
        result = resp.json()
        if result["ret"] != 1:
            raise Exception(result["msg"])
        self.token = result["data"]["token"]
        self.user = result["data"]["user"]
        return result["data"]

    # ========== 节点操作 ==========

    def get_nodes(self) -> list:
        resp = requests.get(f"{API}/nodes/{self.token}")
        result = resp.json()
        if result["ret"] != 1:
            raise Exception(result.get("msg", "Failed"))
        return result["data"]["nodes"]

    def get_subscribe(self, sub_type: str = "clash") -> str:
        resp = requests.get(f"{API}/nodes/{self.token}/subscribe/{sub_type}")
        return resp.text

    def get_online_nodes(self) -> list:
        return [n for n in self.get_nodes() if n["status"]["online"] == 1]

    def get_nodes_by_region(self, keyword: str) -> list:
        return [n for n in self.get_nodes() if keyword in n["name"]]

    def build_trojan_url(self, node: dict) -> str:
        pw = node["credentials"]["password"]
        sni = node["security"]["sni"]
        name = requests.utils.quote(node["name"])
        return f"trojan://{pw}@{node['server']}:{node['port']}?sni={sni}&allowInsecure=1#{name}"


# === 使用示例 ===

vpn = LrtsVPN()

# 方式一：浏览器授权登录（推荐）
data = vpn.login_with_browser()
print(f"登录成功！用户: {data['user']['account']}")

# 方式二：直接登录
# vpn.login("myaccount", "mypassword")

# 获取全部节点
nodes = vpn.get_nodes()
print(f"共 {len(nodes)} 个节点")

# 按地区筛选
for node in vpn.get_nodes_by_region("日本"):
    print(f"  {node['name']} -> {node['server']}:{node['port']}")

# 保存 Clash 配置
with open("clash.yaml", "w") as f:
    f.write(vpn.get_subscribe("clash"))
```

### C# (WPF / WinForms)

```csharp
using System.Diagnostics;
using System.Net.Http;
using System.Text.Json;

public class LrtsVPN
{
    private const string API = "https://lrtsvpn.com/api/v1";
    private readonly HttpClient _http = new();
    public string Token { get; private set; }
    public string Account { get; private set; }

    // 浏览器授权登录
    public async Task<JsonElement> LoginWithBrowserAsync(CancellationToken ct = default)
    {
        // 1. 获取设备码
        var resp = await _http.PostAsync($"{API}/auth/device", null, ct);
        var json = JsonDocument.Parse(await resp.Content.ReadAsStringAsync(ct));
        var authData = json.RootElement.GetProperty("data");

        var deviceCode = authData.GetProperty("device_code").GetString();
        var loginUrl = authData.GetProperty("login_url").GetString();
        var interval = authData.GetProperty("interval").GetInt32();
        var expiresIn = authData.GetProperty("expires_in").GetInt32();

        // 2. 打开浏览器
        Process.Start(new ProcessStartInfo(loginUrl) { UseShellExecute = true });

        // 3. 轮询等待授权
        var deadline = DateTime.Now.AddSeconds(expiresIn);
        while (DateTime.Now < deadline)
        {
            ct.ThrowIfCancellationRequested();
            await Task.Delay(interval * 1000, ct);

            var checkResp = await _http.GetStringAsync($"{API}/auth/check/{deviceCode}", ct);
            var checkJson = JsonDocument.Parse(checkResp);
            var root = checkJson.RootElement;

            if (root.GetProperty("ret").GetInt32() == 1)
            {
                var data = root.GetProperty("data");
                Token = data.GetProperty("token").GetString();
                Account = data.GetProperty("user").GetProperty("account").GetString();
                return data;
            }

            if (root.GetProperty("data").GetProperty("status").GetString() == "expired")
                throw new Exception("授权已过期");
        }

        throw new TimeoutException("授权超时");
    }

    // 直接登录
    public async Task<JsonElement> LoginAsync(string account, string password)
    {
        var content = new FormUrlEncodedContent(new[] {
            new KeyValuePair<string, string>("account", account),
            new KeyValuePair<string, string>("password", password)
        });
        var resp = await _http.PostAsync($"{API}/login", content);
        var json = JsonDocument.Parse(await resp.Content.ReadAsStringAsync());
        var root = json.RootElement;

        if (root.GetProperty("ret").GetInt32() != 1)
            throw new Exception(root.GetProperty("msg").GetString());

        Token = root.GetProperty("data").GetProperty("token").GetString();
        Account = root.GetProperty("data").GetProperty("user").GetProperty("account").GetString();
        return root.GetProperty("data");
    }

    public async Task<JsonElement[]> GetNodesAsync()
    {
        var resp = await _http.GetStringAsync($"{API}/nodes/{Token}");
        var json = JsonDocument.Parse(resp);
        return json.RootElement
            .GetProperty("data")
            .GetProperty("nodes")
            .EnumerateArray()
            .ToArray();
    }

    public async Task<string> GetSubscribeAsync(string type = "clash")
    {
        return await _http.GetStringAsync($"{API}/nodes/{Token}/subscribe/{type}");
    }
}

// 使用
var vpn = new LrtsVPN();

// 浏览器授权登录
var userData = await vpn.LoginWithBrowserAsync();
Console.WriteLine($"登录成功！用户: {vpn.Account}");

var nodes = await vpn.GetNodesAsync();
Console.WriteLine($"共 {nodes.Length} 个节点");
```

### Swift (macOS 桌面应用)

```swift
import Foundation
import AppKit

class LrtsVPN {
    static let api = "https://lrtsvpn.com/api/v1"
    var token: String?

    // 浏览器授权登录
    func loginWithBrowser() async throws -> [String: Any] {
        // 1. 获取设备码
        var request = URLRequest(url: URL(string: "\(Self.api)/auth/device")!)
        request.httpMethod = "POST"
        let (data, _) = try await URLSession.shared.data(for: request)
        let json = try JSONSerialization.jsonObject(with: data) as! [String: Any]
        let authData = json["data"] as! [String: Any]

        let deviceCode = authData["device_code"] as! String
        let loginUrl = authData["login_url"] as! String
        let interval = authData["interval"] as! Int
        let expiresIn = authData["expires_in"] as! Int

        // 2. 打开浏览器
        NSWorkspace.shared.open(URL(string: loginUrl)!)

        // 3. 轮询
        let deadline = Date().addingTimeInterval(TimeInterval(expiresIn))
        while Date() < deadline {
            try await Task.sleep(nanoseconds: UInt64(interval) * 1_000_000_000)

            let (checkData, _) = try await URLSession.shared.data(
                from: URL(string: "\(Self.api)/auth/check/\(deviceCode)")!)
            let checkJson = try JSONSerialization.jsonObject(with: checkData) as! [String: Any]

            if let ret = checkJson["ret"] as? Int, ret == 1,
               let payload = checkJson["data"] as? [String: Any],
               let token = payload["token"] as? String {
                self.token = token
                return payload
            }

            if let d = checkJson["data"] as? [String: Any],
               d["status"] as? String == "expired" {
                throw NSError(domain: "", code: -1,
                    userInfo: [NSLocalizedDescriptionKey: "授权已过期"])
            }
        }
        throw NSError(domain: "", code: -1,
            userInfo: [NSLocalizedDescriptionKey: "授权超时"])
    }

    func getNodes() async throws -> [[String: Any]] {
        guard let token else { throw NSError(domain: "", code: -1) }
        let (data, _) = try await URLSession.shared.data(
            from: URL(string: "\(Self.api)/nodes/\(token)")!)
        let json = try JSONSerialization.jsonObject(with: data) as! [String: Any]
        let payload = json["data"] as! [String: Any]
        return payload["nodes"] as! [[String: Any]]
    }

    func getSubscribe(type: String = "clash") async throws -> String {
        guard let token else { throw NSError(domain: "", code: -1) }
        let (data, _) = try await URLSession.shared.data(
            from: URL(string: "\(Self.api)/nodes/\(token)/subscribe/\(type)")!)
        return String(data: data, encoding: .utf8) ?? ""
    }
}
```

---

## 当前节点清单

共 **95** 个节点，7 台服务器，全部 Trojan + TLS：

| 地区            | 数量 | 服务器 IP         |
|-----------------|------|--------------------|
| 🇭🇰 香港        | 14   | 203.91.76.136      |
| 🇲🇴 澳门        | 1    | 203.91.76.136      |
| 🇦🇺 澳大利亚    | 1    | 203.91.76.136      |
| 🇺🇸 美国        | 10   | 38.14.248.145      |
| 🇨🇦 加拿大       | 1    | 38.14.248.145      |
| 🇲🇽 墨西哥       | 1    | 38.14.248.145      |
| 🇧🇷 巴西        | 1    | 38.14.248.145      |
| 🇦🇷 阿根廷       | 1    | 38.14.248.145      |
| 🇬🇧 英国        | 1    | 38.14.248.145      |
| 🇮🇪 爱尔兰       | 1    | 38.14.248.145      |
| 🇸🇬 新加坡       | 10   | 154.89.152.198     |
| 🇲🇾 马来西亚     | 1    | 154.89.152.198     |
| 🇮🇩 印尼        | 1    | 154.89.152.198     |
| 🇮🇳 印度        | 1    | 154.89.152.198     |
| 🇦🇪 阿联酋       | 1    | 154.89.152.198     |
| 🇯🇵 日本        | 14   | 102.204.223.225    |
| 🇷🇺 俄罗斯       | 1    | 102.204.223.225    |
| 🇩🇪 德国        | 1    | 102.204.223.225    |
| 🇫🇷 法国        | 1    | 102.204.223.225    |
| 🇳🇱 荷兰        | 1    | 102.204.223.225    |
| 🇨🇭 瑞士        | 1    | 102.204.223.225    |
| 🇹🇼 台湾        | 5    | 103.208.87.50      |
| 🇪🇸 西班牙       | 1    | 103.208.87.50      |
| 🇮🇹 意大利       | 1    | 103.208.87.50      |
| 🇸🇪 瑞典        | 1    | 103.208.87.50      |
| 🇳🇴 挪威        | 1    | 103.208.87.50      |
| 🇵🇱 波兰        | 1    | 103.208.87.50      |
| 🇰🇷 韩国        | 8    | 61.110.5.148       |
| 🇻🇳 越南        | 8    | 192.229.96.78      |
| 🇹🇭 泰国        | 1    | 192.229.96.78      |
| 🇵🇭 菲律宾       | 1    | 192.229.96.78      |
| 🇹🇷 土耳其       | 1    | 192.229.96.78      |
| 🇳🇬 尼日利亚     | 1    | 192.229.96.78      |

所有节点 TLS SNI = `lrtsvpn.com`，`allow_insecure = true`，流量倍率 = 1.0


服务器：系统登录： 192.229.96.78:34833     账号： root    密码： Xie080886

系统登录： 61.110.5.148:29293     账号： root    密码： Xie080886

系统登录： 103.208.87.50:29739     账号： root    密码： Xie080886

系统登录： 102.204.223.225:49956     账号： root    密码： Xie080886

系统登录： 154.89.152.198:24565     账号： root    密码： Xie080886

系统登录： 38.14.248.145:22654     账号： root    密码： Xie080886

系统登录： 203.91.76.136:37505     账号： root    密码： Xie080886


## 主管理服务器;系统登录： 38.14.248.145:22654     账号： root    密码： Xie080886