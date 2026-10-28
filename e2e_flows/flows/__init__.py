"""
Các luồng kiểm thử giao diện E2E (Web Admin, Mobile Web, Backend API)
"""
from .flow_backend_api import run_backend_flow
from .flow_web_admin import run_web_admin_flow
from .flow_mobile_web import run_mobile_web_flow

__all__ = ["run_backend_flow", "run_web_admin_flow", "run_mobile_web_flow"]
