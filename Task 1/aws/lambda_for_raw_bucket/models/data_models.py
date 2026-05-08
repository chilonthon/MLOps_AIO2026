from pydantic import BaseModel, Field, field_validator
from typing import Optional

class NetworkDataRecord(BaseModel):
    time: Optional[float] = None
    Day: Optional[str] = None
    Year: Optional[float] = None
    Month: Optional[float] = None
    Date: Optional[float] = None
    hour: Optional[float] = None
    min: Optional[float] = None
    sec: Optional[float] = None
    timezone: Optional[str] = None
    latitude: Optional[float] = None
    longitude: Optional[float] = None
    speed: Optional[float] = None
    truck: Optional[str] = None
    svr1: Optional[float] = None
    svr2: Optional[float] = None
    svr3: Optional[float] = None
    svr4: Optional[float] = None
    Role: Optional[str] = None
    
    Transfer_size: Optional[float] = Field(None, alias="Transfer size")
    Transfer_unit: Optional[str] = Field(None, alias="Transfer unit")
    Bitrate: Optional[float] = None
    bitrate_unit: Optional[str] = None
    Retransmissions: Optional[float] = None
    CWnd: Optional[float] = None
    cwnd_unit: Optional[str] = None
    Role_RX: Optional[str] = Field(None, alias="Role-RX")
    Transfer_size_RX: Optional[float] = Field(None, alias="Transfer size-RX")
    Transfer_unit_RX: Optional[str] = Field(None, alias="Transfer unit-RX")
    Bitrate_RX: Optional[float] = Field(None, alias="Bitrate-RX")
    bitrate_unit_RX: Optional[str] = Field(None, alias="bitrate_unit-RX")
    send_data: Optional[float] = None
    
    # FIX: Changed to string to allow values like "square_111669149768"
    square_id: Optional[str] = None

    @field_validator('latitude')
    @classmethod
    def check_latitude(cls, v):
        if v is not None and not (-90 <= v <= 90 or v == 99.0):
            raise ValueError(f"Latitude {v} is out of bounds")
        return v