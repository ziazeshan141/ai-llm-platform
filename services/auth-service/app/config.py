from pydantic_settings import BaseSettings, SettingsConfigDict
class Settings(BaseSettings):
    DATABASE_URL:str="postgresql://postgres:postgres@localhost:5432/auth_db"
    JWT_SECRET_KEY:str="change-me"
    JWT_ALGORITHM:str="HS256"
    ACCESS_TOKEN_EXPIRE_MINUTES:int=60
    model_config=SettingsConfigDict(env_file=".env",case_sensitive=True)
settings=Settings()
