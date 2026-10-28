import os
import sys
import json
import argparse
import socket
import datetime
from pathlib import Path
from typing import Any, Dict, List

if sys.stdout.encoding.lower() != 'utf-8':
    try:
        sys.stdout.reconfigure(encoding='utf-8')
    except Exception:
        pass

from playwright.sync_api import sync_playwright

from .config import (
    BACKEND_PORT,
    WEB_ADMIN_PORT,
    MOBILE_WEB_PORT,
    BACKEND_URL,
    WEB_ADMIN_URL,
    MOBILE_WEB_URL,
    SCREENSHOTS_DIR,
    REPORTS_DIR,
    HEADLESS_DEFAULT,
)
from .flows import run_backend_flow, run_web_admin_flow, run_mobile_web_flow

def is_port_open(host: str, port: int, timeout_sec: float = 1.0) -> bool:
    """Kiểm tra xem một cổng mạng có đang lắng nghe hay không."""
    try:
        with socket.create_connection((host, port), timeout=timeout_sec):
            return True
    except OSError:
        return False

def check_all_services() -> Dict[str, bool]:
    """Kiểm tra tình trạng mở cổng của 3 dịch vụ chính."""
    return {
        "backend": is_port_open("127.0.0.1", BACKEND_PORT),
        "web_admin": is_port_open("127.0.0.1", WEB_ADMIN_PORT) or is_port_open("localhost", WEB_ADMIN_PORT),
        "mobile_web": is_port_open("127.0.0.1", MOBILE_WEB_PORT) or is_port_open("localhost", MOBILE_WEB_PORT),
    }

def print_banner() -> None:
    print("=" * 80)
    print("🚀 [PTC1] HỆ THỐNG KIỂM THỬ GIAO DIỆN E2E ĐA TẦNG (UI + CONSOLE + SERVER + SCREENSHOTS)")
    print("=" * 80)

def generate_markdown_report(results: List[Dict[str, Any]], run_time_str: str) -> Path:
    """Tạo báo cáo tổng hợp chi tiết bằng định dạng Markdown."""
    report_file = REPORTS_DIR / "summary.md"
    
    total_flows = len(results)
    passed_flows = sum(1 for r in results if r["status"] == "PASS")
    failed_flows = total_flows - passed_flows
    total_screenshots = sum(len(r.get("screenshots", [])) for r in results)
    
    all_console_errors = []
    all_server_errors = []

    for r in results:
        flow_name = r["flow_name"]
        for ce in r.get("console_summary", {}).get("errors", []):
            all_console_errors.append((flow_name, ce))
        for se in r.get("server_summary", {}).get("errors", []):
            all_server_errors.append((flow_name, se))

    lines = [
        "# Báo Cáo Kiểm Thử Giao Diện E2E Đa Tầng (PTC1)",
        f"\n- **Thời gian thực hiện:** `{run_time_str}`",
        f"- **Tổng số luồng kiểm thử:** `{total_flows}`",
        f"- **Trạng thái:** `{passed_flows}/{total_flows} Luồng Đạt (PASS)` | `{failed_flows} Thất Bại (FAIL)`",
        f"- **Tổng số ảnh chụp màn hình:** `{total_screenshots}` ảnh",
        f"- **Tổng lỗi Console phát hiện:** `{len(all_console_errors)}` lỗi",
        f"- **Tổng lỗi Server phát hiện:** `{len(all_server_errors)}` lỗi",
        "\n---\n",
        "## 1. Bảng Tổng Hợp Luồng Kiểm Thử\n",
        "| Luồng Kiểm Thử | URL Mục Tiêu | Trạng Thái | Số Ảnh Chụp | Lỗi Console | Lỗi Server |",
        "| :--- | :--- | :--- | :--- | :--- | :--- |",
    ]

    for r in results:
        status_badge = "✅ PASS" if r["status"] == "PASS" else "❌ FAIL"
        shot_count = len(r.get("screenshots", []))
        c_errs = r.get("console_summary", {}).get("errors_count", 0)
        s_errs = r.get("server_summary", {}).get("total_errors", 0)
        lines.append(f"| **{r['flow_name']}** | `{r['url']}` | **{status_badge}** | {shot_count} ảnh | {c_errs} lỗi | {s_errs} lỗi |")

    lines.append("\n---\n")
    lines.append("## 2. Chi Tiết Từng Luồng Kiểm Thử\n")

    for r in results:
        icon = "✅" if r["status"] == "PASS" else "❌"
        lines.append(f"### {icon} {r['flow_name']} (`{r['url']}`)")
        lines.append(f"- **Trạng thái tổng thể:** **{r['status']}**")
        
        lines.append("\n**Các bước đã thực thi thành công:**")
        if r.get("steps_passed"):
            for step in r["steps_passed"]:
                lines.append(f"  - ✓ {step}")
        else:
            lines.append("  - *(Không có)*")

        if r.get("steps_failed"):
            lines.append("\n**Các bước bị lỗi / thất bại:**")
            for step in r["steps_failed"]:
                lines.append(f"  - ✗ {step}")

        # Lỗi Console
        c_summary = r.get("console_summary", {})
        if c_summary.get("errors"):
            lines.append("\n**⚠️ Danh sách Lỗi Console Trình Duyệt:**")
            for err in c_summary["errors"]:
                lines.append(f"  - `[{err.get('time')}]` `[{err.get('type')}]`: {err.get('text')} *(Vị trí: {err.get('location', 'N/A')})*")
        else:
            lines.append("\n- **Console Trình duyệt:** 🟢 Không có lỗi JavaScript / Console.error.")

        # Lỗi Server
        s_summary = r.get("server_summary", {})
        if s_summary.get("errors"):
            lines.append("\n**⚠️ Danh sách Lỗi Server / Mạng Backend:**")
            for err in s_summary["errors"]:
                lines.append(f"  - `[{err.get('type')}]`: {err.get('detail')}")
        else:
            lines.append("- **Server Backend:** 🟢 Không có lỗi HTTP (không có status >= 400).")

        # Ảnh chụp
        if r.get("screenshots"):
            lines.append("\n**📸 Ảnh chụp màn hình đã lưu:**")
            for shot in r["screenshots"]:
                lines.append(f"  - `e2e_flows/screenshots/{shot}`")

        lines.append("\n")

    lines.append("---\n")
    lines.append("## 3. Danh Mục Toàn Bộ Ảnh Chụp Màn Hình Nghiệm Thu\n")
    lines.append("| Tên Tệp Ảnh | Luồng Nghiệp Vụ | Đường Dẫn Lưu Trữ |")
    lines.append("| :--- | :--- | :--- |")
    for r in results:
        for shot in r.get("screenshots", []):
            lines.append(f"| `{shot}` | {r['flow_name']} | `e2e_flows/screenshots/{shot}` |")

    with open(report_file, "w", encoding="utf-8") as f:
        f.write("\n".join(lines))

    # Xuất thêm file JSON máy đọc
    json_file = REPORTS_DIR / "summary.json"
    with open(json_file, "w", encoding="utf-8") as f:
        json.dump({"run_time": run_time_str, "results": results}, f, indent=2, ensure_ascii=False)

    return report_file

def print_console_summary(results: List[Dict[str, Any]], report_file: Path) -> bool:
    """In bảng tổng kết kết quả kiểm thử đầy đủ màu sắc ra màn hình Terminal."""
    print("\n" + "=" * 80)
    print("📋 BẢNG TỔNG KẾT KẾT QUẢ KIỂM THỬ GIAO DIỆN (UI E2E SUMMARY)")
    print("=" * 80)
    print(f"{'LUỒNG KIỂM THỬ':<28} | {'TRẠNG THÁI':<10} | {'CONSOLE ERR':<11} | {'SERVER ERR':<10} | {'ẢNH CHỤP':<8}")
    print("-" * 80)

    all_passed = True
    total_shots = 0

    for r in results:
        status = r["status"]
        if status != "PASS":
            all_passed = False
        icon = "✅ PASS" if status == "PASS" else "❌ FAIL"
        c_errs = r.get("console_summary", {}).get("errors_count", 0)
        s_errs = r.get("server_summary", {}).get("total_errors", 0)
        shots = len(r.get("screenshots", []))
        total_shots += shots

        c_str = f"🟢 0" if c_errs == 0 else f"🔴 {c_errs}"
        s_str = f"🟢 0" if s_errs == 0 else f"🔴 {s_errs}"

        print(f"{r['flow_name']:<28} | {icon:<10} | {c_str:<11} | {s_str:<10} | {shots} ảnh")

    print("-" * 80)
    print(f"Tổng số ảnh chụp màn hình đã lưu: {total_shots} tệp tại e2e_flows/screenshots/")
    print(f"Báo cáo chi tiết Markdown đã xuất tại: {report_file}")
    print("=" * 80)

    # In chi tiết nếu có lỗi console hoặc server
    for r in results:
        c_errs = r.get("console_summary", {}).get("errors", [])
        s_errs = r.get("server_summary", {}).get("errors", [])
        if c_errs or s_errs:
            print(f"\n⚠️  CHI TIẾT LỖI TẠI LUỒNG: [{r['flow_name']}]")
            for ce in c_errs:
                print(f"   [Console Error] {ce.get('text')}")
            for se in s_errs:
                print(f"   [Server Error]  {se.get('detail')}")

    return all_passed

def run_e2e(flow: str = "all", headless: bool = True) -> bool:
    """Hàm điều phối thực thi kiểm thử giao diện E2E."""
    print_banner()
    run_time_str = datetime.datetime.now().strftime("%Y-%m-%d %H:%M:%S")

    # Kiểm tra trạng thái các service
    services = check_all_services()
    print("\n🔍 KIỂM TRA TRẠNG THÁI CÁC CỔNG DỊCH VỤ:")
    print(f"  • Backend FastAPI (Port {BACKEND_PORT}): {'🟢 ĐANG CHẠY' if services['backend'] else '🔴 CHƯA BẬT'}")
    print(f"  • Web Admin Vue 3 (Port {WEB_ADMIN_PORT}): {'🟢 ĐANG CHẠY' if services['web_admin'] else '🔴 CHƯA BẬT'}")
    print(f"  • Mobile Web Flutter (Port {MOBILE_WEB_PORT}): {'🟢 ĐANG CHẠY' if services['mobile_web'] else '🔴 CHƯA BẬT'}")

    not_running = [k for k, v in services.items() if not v]
    if not_running:
        print("\n⚠️ CẢNH BÁO: Một số dịch vụ chưa được khởi động trước khi test:")
        for nr in not_running:
            print(f"   - {nr.upper()} chưa mở cổng tương ứng.")
        print("💡 Mẹo: Bạn có thể click chạy file 'CHAY_TAT_CA.bat' ở root để khởi động đồng thời Backend, Web và Mobile.")
        print("-" * 80)

    results: List[Dict[str, Any]] = []

    with sync_playwright() as p:
        browser_type = p.chromium
        # Ưu tiên dùng kênh chrome có sẵn trên máy
        try:
            browser = browser_type.launch(channel="chrome", headless=headless)
        except Exception:
            browser = browser_type.launch(headless=headless)

        # 1. Luồng Backend
        if flow in ("all", "backend"):
            print("\n[1/3] Đang chạy luồng: Backend API & Swagger UI...")
            res_backend = run_backend_flow(browser)
            results.append(res_backend)
            print(f"      -> Trạng thái: {res_backend['status']} | {len(res_backend['screenshots'])} ảnh chụp.")

        # 2. Luồng Web Admin
        if flow in ("all", "web", "admin"):
            print("\n[2/3] Đang chạy luồng: Web Admin Console Workflows...")
            res_admin = run_web_admin_flow(browser)
            results.append(res_admin)
            print(f"      -> Trạng thái: {res_admin['status']} | {len(res_admin['screenshots'])} ảnh chụp.")

        # 3. Luồng Mobile Web
        if flow in ("all", "mobile"):
            print("\n[3/3] Đang chạy luồng: Flutter Mobile Web Workflows...")
            res_mobile = run_mobile_web_flow(browser)
            results.append(res_mobile)
            print(f"      -> Trạng thái: {res_mobile['status']} | {len(res_mobile['screenshots'])} ảnh chụp.")

        browser.close()

    # Xuất báo cáo Markdown và in Console
    report_file = generate_markdown_report(results, run_time_str)
    all_passed = print_console_summary(results, report_file)
    return all_passed

def main() -> None:
    parser = argparse.ArgumentParser(description="PTC1 E2E UI Flow Test Runner")
    parser.add_argument("--flow", choices=["all", "backend", "web", "admin", "mobile"], default="all", help="Chọn luồng kiểm thử cụ thể")
    parser.add_argument("--headed", action="store_true", help="Hiển thị trình duyệt giao diện trực quan khi chạy test")
    parser.add_argument("--headless", action="store_true", help="Chạy ẩn ngầm trình duyệt (mặc định)")
    args = parser.parse_args()

    headless = True
    if args.headed:
        headless = False

    success = run_e2e(flow=args.flow, headless=headless)
    sys.exit(0 if success else 1)

if __name__ == "__main__":
    main()
