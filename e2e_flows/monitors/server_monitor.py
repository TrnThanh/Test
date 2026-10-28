import datetime
import urllib.request
import urllib.error
import json
from typing import Any, Dict, List, Optional
from playwright.sync_api import Page, Request, Response

class ServerMonitor:
    """
    Giám sát các tương tác mạng và phản hồi từ Server Backend:
    - Bắt các yêu cầu mạng bị thất bại (requestfailed: mất kết nối, từ chối kết nối).
    - Bắt các phản hồi lỗi từ server (mã HTTP >= 400, ví dụ 404, 500, 502, 503).
    - Cung cấp phương thức kiểm tra trực tiếp tình trạng sống (health check) của Backend API.
    """

    def __init__(self, page: Page, flow_name: str = "default"):
        self.page = page
        self.flow_name = flow_name
        self.failed_requests: List[Dict[str, Any]] = []
        self.error_responses: List[Dict[str, Any]] = []
        self._attach_listeners()

    def _attach_listeners(self) -> None:
        """Đăng ký các bộ lắng nghe sự kiện mạng trên Playwright Page."""
        self.page.on("requestfailed", self._handle_request_failed)
        self.page.on("response", self._handle_response)

    def _handle_request_failed(self, request: Request) -> None:
        """Xử lý khi một request mạng bị huỷ hoặc không thể kết nối tới server."""
        failure = request.failure
        failure_text = failure if isinstance(failure, str) else (failure.get("errorText") if failure else "Unknown network error")
        item = {
            "time": datetime.datetime.now().strftime("%H:%M:%S.%f")[:-3],
            "method": request.method,
            "url": request.url,
            "error": failure_text,
        }
        self.failed_requests.append(item)

    def _handle_response(self, response: Response) -> None:
        """Xử lý khi nhận được response, lọc các mã lỗi HTTP >= 400."""
        if response.status >= 400:
            preview = ""
            try:
                # Cố gắng đọc nội dung response để cung cấp chi tiết lỗi
                preview = response.text()[:250]
            except Exception:
                preview = "<không đọc được body>"

            item = {
                "time": datetime.datetime.now().strftime("%H:%M:%S.%f")[:-3],
                "status": response.status,
                "status_text": response.status_text,
                "method": response.request.method,
                "url": response.url,
                "detail": preview,
            }
            self.error_responses.append(item)

    @staticmethod
    def ping_backend(url: str, timeout_sec: int = 3) -> Dict[str, Any]:
        """
        Kiểm tra trực tiếp kết nối tới Backend FastAPI.
        Trả về dictionary kết quả kiểm tra.
        """
        try:
            req = urllib.request.Request(url, headers={"User-Agent": "PTC1-E2E-Monitor"})
            with urllib.request.urlopen(req, timeout=timeout_sec) as resp:
                status = resp.getcode()
                body = resp.read().decode("utf-8", errors="ignore")
                return {
                    "reachable": True,
                    "status_code": status,
                    "body_preview": body[:150],
                    "message": "Backend FastAPI đang phản hồi tốt (HTTP 200 OK)",
                }
        except urllib.error.HTTPError as e:
            return {
                "reachable": True,
                "status_code": e.code,
                "body_preview": str(e),
                "message": f"Backend phản hồi HTTP {e.code}",
            }
        except Exception as e:
            return {
                "reachable": False,
                "status_code": None,
                "body_preview": str(e),
                "message": f"Không thể kết nối tới Backend: {e}",
            }

    def get_errors(self) -> List[Dict[str, Any]]:
        """Lấy tất cả lỗi server (failed requests + HTTP >= 400)."""
        errors = []
        for fr in self.failed_requests:
            errors.append({"type": "NETWORK_FAILED", "detail": f"{fr['method']} {fr['url']} -> {fr['error']}"})
        for er in self.error_responses:
            errors.append({"type": f"HTTP_{er['status']}", "detail": f"{er['method']} {er['url']} -> {er['detail']}"})
        return errors

    def has_errors(self) -> bool:
        """Kiểm tra có lỗi server nào hay không."""
        return len(self.get_errors()) > 0

    def summary(self) -> Dict[str, Any]:
        """Tóm tắt trạng thái server phục vụ lập báo cáo."""
        errors = self.get_errors()
        return {
            "failed_requests_count": len(self.failed_requests),
            "error_responses_count": len(self.error_responses),
            "total_errors": len(errors),
            "errors": errors,
            "status": "FAIL" if errors else "PASS",
        }
