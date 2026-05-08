import pandas as pd
from models.data_models import NetworkDataRecord
from pydantic import ValidationError

def process_csv(input_path: str, output_path: str) -> dict:
    # Read CSV (low_memory=False prevents Pandas warnings on messy data)
    df = pd.read_csv(input_path, low_memory=False)
    initial_row_count = len(df)
    
    # Basic Cleaning
    df = df.drop_duplicates()
    
    # 1. Safely handle missing latitude/longitude
    df = df.dropna(subset=['latitude', 'longitude'])
    df = df[(df['latitude'] != 99.0) & (df['longitude'] != 999.0)]
    
    # 2. Fix the Speed Filter!
    # Convert bad data to NaN, but KEEP the NaNs using the .isna() check
    if 'speed' in df.columns:
        df['speed'] = pd.to_numeric(df['speed'], errors='coerce')
        df = df[(df['speed'] >= 0) | (df['speed'].isna())]
    
    rows_after_cleaning = len(df)
    
    valid_records = []
    error_count = 0
    
    # Pydantic Validation
    for index, row in df.iterrows():
        try:
            row_dict = row.where(pd.notnull(row), None).to_dict()
            record = NetworkDataRecord(**row_dict)
            valid_records.append(record.model_dump(by_alias=True)) 
        except ValidationError as e:
            error_count += 1
            print(f"Row {index} failed validation: {e}")
            
    # Save Processed Data
    processed_df = pd.DataFrame(valid_records)
    
    # FIX: Export to JSON format instead of CSV
    # 'records' makes it a list of clean JSON objects.
    processed_df.to_json(output_path, orient='records', lines=True)
    
    return {
        "initial_rows": initial_row_count,
        "rows_after_basic_cleaning": rows_after_cleaning,
        "junk_rows_dropped": initial_row_count - rows_after_cleaning,
        "valid_rows_saved": len(valid_records),
        "validation_errors": error_count
    }