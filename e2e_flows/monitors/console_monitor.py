import datetime
from typing import Any, Dict, List, Optional
from playwright.sync_api import ConsoleMessage, Page

class ConsoleMonitor:
    """
    Giám sát và ghi nhận toàn bộ log, cảnh báo (warning), lỗi (error) và
    ngoại lệ JavaScript chưa được bắt (uncaught page exceptions) từ console trình duyệt.
    """

    def __init__(self, page: Page, flow_name: str = "default"):
        self.page = page
        self.flow_name = flow_name
        self.messages: List[Dict[str, Any]] = []
        self.page_errors: List[Dict[str, Any]] = []
        self._attach_listeners()

    def _attach_listeners(self) -> None:
        """Đăng ký các bộ lắng nghe sự kiện trên Playwright Page."""
        self.page.on("console", self._handle_console)
        self.page.on("pageerror", self._handle_page_error)

    def _handle_console(self, msg: ConsoleMessage) -> None:
        """Xử lý từng dòng log console từ trình duyệt."""
        item = {
            "time": datetime.datetime.now().strftime("%H:%M:%S.%f")[:-3],
            "type": msg.type,  # 'log', 'info', 'warning', 'error', 'debug'
            "text": msg.text,
            "location": f"{msg.location.get('url', '')}:{msg.location.get('lineNumber', '')}" if msg.location else "",
        }
        self.messages.append(item)

    def _handle_page_error(self, error: Any) -> None:
        """Bắt ngoại lệ JavaScript / Vue / Flutter chưa được xử lý (uncaught exceptions)."""
        error_str = str(error)
        item = {
            "time": datetime.datetime.now().strftime("%H:%M:%S.%f")[:-3],
            "type": "uncaught_exception",
            "text": error_str,
            "location": getattr(error, "stack", ""),
        }
        self.page_errors.append(item)

    def get_errors(self) -> List[Dict[str, Any]]:
        """Lấy danh sách các lỗi console nghiêm trọng (console.error + uncaught exceptions)."""
        errors = [m for m in self.messages if m["type"] == "error"]
        errors.extend(self.page_errors)
        return errors

    def get_warnings(self) -> List[Dict[str, Any]]:
        """Lấy danh sách cảnh báo console (console.warn)."""
        return [m for m in self.messages if m["type"] in ("warning", "warn")]

    def has_errors(self) -> bool:
        """Kiểm tra có lỗi console nào hay không."""
        return len(self.get_errors()) > 0

    def summary(self) -> Dict[str, Any]:
        """Tóm tắt trạng thái console phục vụ lập báo cáo."""
        errors = self.get_errors()
        warnings = self.get_warnings()
        return {
            "total_logs": len(self.messages) + len(self.page_errors),
            "errors_count": len(errors),
            "warnings_count": len(warnings),
            "errors": errors,
            "warnings": warnings,
            "status": "FAIL" if errors else "PASS",
        }
