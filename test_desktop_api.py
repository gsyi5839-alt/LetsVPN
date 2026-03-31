#!/usr/bin/env python3
"""
桌面端API测试脚本 - 使用urllib
测试4个核心API接口
"""
import json
import urllib.request
import urllib.error
import time
import uuid

BASE_URL = "https://lrtsvpn.com/desktop/api/v1"
DEVICE_ID = f"test-device-{uuid.uuid4().hex[:8]}"
CLIENT_VERSION = "4.1.2+40102"

def make_request(url, method="GET", data=None, headers=None):
    """发送HTTP请求"""
    req_headers = headers or {}
    
    if data and isinstance(data, dict):
        data = json.dumps(data).encode('utf-8')
        req_headers['Content-Type'] = 'application/json'
    
    req = urllib.request.Request(url, data=data, headers=req_headers, method=method)
    
    try:
        with urllib.request.urlopen(req, timeout=30) as response:
            return response.status, json.loads(response.read().decode('utf-8'))
    except urllib.error.HTTPError as e:
        return e.code, {"error": str(e), "body": e.read().decode('utf-8')[:500]}
    except Exception as e:
        return -1, {"error": str(e)}

def test_downloads():
    """测试1: 获取下载清单"""
    print("=" * 50)
    print("测试1: GET /downloads")
    print("=" * 50)
    
    status, data = make_request(f"{BASE_URL}/downloads")
    print(f"Status: {status}")
    
    if status == 200:
        print(f"Response: {json.dumps(data, indent=2, ensure_ascii=False)[:600]}...")
        
        if data.get('ret') == 1:
            print("[PASS] 测试通过: 成功获取下载清单")
            if 'data' in data and 'downloads' in data['data']:
                platforms = list(data['data']['downloads'].keys())
                print(f"   支持平台: {platforms}")
                for platform in platforms:
                    items = data['data']['downloads'][platform]
                    print(f"   - {platform}: {len(items)} 个下载项")
            return True
        else:
            print(f"[FAIL] API返回错误: {data.get('msg')}")
            return False
    else:
        print(f"[FAIL] HTTP错误: {status}, {data}")
        return False

def test_install_check():
    """测试2: 安装核对"""
    print("\n" + "=" * 50)
    print("测试2: POST /install/check")
    print("=" * 50)
    
    payload = {
        "platform": "windows",
        "installed_packages": {}
    }
    
    print(f"Request: {json.dumps(payload, indent=2)}")
    status, data = make_request(f"{BASE_URL}/install/check", method="POST", data=payload)
    print(f"Status: {status}")
    
    if status == 200:
        print(f"Response: {json.dumps(data, indent=2, ensure_ascii=False)[:800]}...")
        
        if data.get('ret') == 1:
            print("[PASS] 测试通过: 成功获取安装清单")
            if 'data' in data:
                needs_install = data['data'].get('needs_install_count', 0)
                print(f"   需要安装包数量: {needs_install}")
                if needs_install > 0:
                    packages = data['data'].get('needs_install', [])
                    for pkg in packages:
                        print(f"   - ID:{pkg.get('id')} {pkg.get('title')} (版本:{pkg.get('version_id')})")
                        print(f"     URL: {pkg.get('package_url', 'N/A')[:60]}...")
            return True
        else:
            print(f"[FAIL] API返回错误: {data.get('msg')}")
            return False
    else:
        print(f"[FAIL] HTTP错误: {status}")
        print(f"Response: {json.dumps(data, indent=2)[:500]}")
        return False

def test_install_confirm():
    """测试3: 安装完成上报"""
    print("\n" + "=" * 50)
    print("测试3: POST /install/confirm")
    print("=" * 50)
    
    payload = {
        "device_id": DEVICE_ID,
        "package_id": 14,
        "version_id": "20260331",
        "status": "success",
        "platform": "windows",
        "client_version": CLIENT_VERSION,
        "install_time": int(time.time())
    }
    
    print(f"Request: {json.dumps(payload, indent=2)}")
    status, data = make_request(f"{BASE_URL}/install/confirm", method="POST", data=payload)
    print(f"Status: {status}")
    
    if status == 200:
        print(f"Response: {json.dumps(data, indent=2, ensure_ascii=False)}")
        
        if data.get('ret') == 1:
            print("[PASS] 测试通过: 安装确认上报成功")
            if 'data' in data:
                recorded = data['data'].get('recorded', False)
                next_check = data['data'].get('next_check', 'N/A')
                print(f"   已记录: {recorded}, 下次检查: {next_check}")
            return True
        else:
            print(f"[FAIL] API返回错误: {data.get('msg')}")
            return False
    else:
        print(f"[FAIL] HTTP错误: {status}")
        print(f"Response: {json.dumps(data, indent=2)[:500]}")
        return False

def test_events_batch():
    """测试4: 批量事件上报"""
    print("\n" + "=" * 50)
    print("测试4: POST /events/batch")
    print("=" * 50)
    
    current_time = int(time.time())
    payload = {
        "device_id": DEVICE_ID,
        "platform": "windows",
        "client_version": CLIENT_VERSION,
        "events": [
            {
                "event_type": "app_launched",
                "event_time": current_time - 60,
                "extra": {"test": True, "source": "api_test"}
            },
            {
                "event_type": "install_started",
                "event_time": current_time - 30,
                "ad_id": 14,
                "extra": {"version_id": "20260331"}
            },
            {
                "event_type": "install_completed",
                "event_time": current_time,
                "ad_id": 14,
                "extra": {"version_id": "20260331", "status": "success"}
            }
        ]
    }
    
    print(f"Request events count: {len(payload['events'])}")
    status, data = make_request(f"{BASE_URL}/events/batch", method="POST", data=payload)
    print(f"Status: {status}")
    
    if status == 200:
        print(f"Response: {json.dumps(data, indent=2, ensure_ascii=False)}")
        
        if data.get('ret') == 1:
            print("[PASS] 测试通过: 批量事件上报成功")
            if 'data' in data:
                saved = data['data'].get('saved', 0)
                duplicate = data['data'].get('duplicate', 0)
                failed = data['data'].get('failed', 0)
                print(f"   成功: {saved}, 重复: {duplicate}, 失败: {failed}")
                
                # 显示每个事件的结果
                items = data['data'].get('items', [])
                for item in items:
                    idx = item.get('index', 0)
                    saved_flag = "OK" if item.get('saved') else "FAIL"
                    norm_type = item.get('normalized_type', 'unknown')
                    print(f"   [{saved_flag}] 事件{idx}: {norm_type}")
            return True
        else:
            print(f"[FAIL] API返回错误: {data.get('msg')}")
            return False
    else:
        print(f"[FAIL] HTTP错误: {status}")
        print(f"Response: {json.dumps(data, indent=2)[:500]}")
        return False

def main():
    print("\n" + "=" * 60)
    print("桌面端API测试")
    print(f"设备ID: {DEVICE_ID}")
    print(f"API地址: {BASE_URL}")
    print("=" * 60)
    
    results = []
    
    # 测试4个API
    results.append(("downloads", test_downloads()))
    results.append(("install/check", test_install_check()))
    results.append(("install/confirm", test_install_confirm()))
    results.append(("events/batch", test_events_batch()))
    
    # 汇总结果
    print("\n" + "=" * 60)
    print("测试结果汇总")
    print("=" * 60)
    
    passed = sum(1 for _, r in results if r)
    total = len(results)
    
    for name, result in results:
        status = "[PASS]" if result else "[FAIL]"
        print(f"{status}: {name}")
    
    print(f"\n总计: {passed}/{total} 通过")
    
    if passed == total:
        print("所有API测试通过！")
    else:
        print("部分API测试失败，请检查")

if __name__ == "__main__":
    main()
