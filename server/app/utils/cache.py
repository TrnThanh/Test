import collections
import time
from typing import Any, Optional


class FIFOTtlCache:
    """Bộ nhớ đệm FIFO có giới hạn kích thước và thời gian sống TTL, đo bằng monotonic clock."""

    def __init__(self, maxsize: int = 1000, ttl_seconds: float = 300.0, clock=None):
        self.maxsize = maxsize
        self.ttl = ttl_seconds
        self.clock = clock or time.monotonic
        self._cache = collections.OrderedDict()

    def get(self, key: Any) -> Optional[Any]:
        if key not in self._cache:
            return None
        ts, val = self._cache[key]
        if self.clock() - ts >= self.ttl:
            del self._cache[key]
            return None
        return val

    def set(self, key: Any, val: Any) -> None:
        if key in self._cache:
            del self._cache[key]
        elif len(self._cache) >= self.maxsize:
            self._cache.popitem(last=False)
        self._cache[key] = (self.clock(), val)

    def clear(self) -> None:
        self._cache.clear()
