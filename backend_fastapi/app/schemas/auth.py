from pydantic import BaseModel

class LoginRequest(BaseModel):
    username: str
    password: str


class RegisterRequest(BaseModel):
    username: str
    password: str
    role: str = "staff"
    store_id: int = 1
    email: str | None = None


class GoogleAuthRequest(BaseModel):
    email: str
    role: str = "staff"
    store_id: int = 1


class UserOut(BaseModel):
    id: int
    username: str
    role: str
    store_id: int
    email: str | None = None

    class Config:
        from_attributes = True


class AuthResponse(BaseModel):
    token: str
    user: UserOut
