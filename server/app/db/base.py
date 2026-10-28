from sqlmodel import SQLModel


# Lớp cơ sở SQLModel dùng chung cho toàn bộ các Model CSDL trong hệ thống
class Base(SQLModel):
    """Base class for all SQLModel ORM models."""
    pass
