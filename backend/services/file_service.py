import pandas as pd
import io
from typing import List
from models.requirement import Requirement, RequirementCategory


class FileService:
    
    def parse_requirements(self, content: bytes, filename: str) -> List[Requirement]:
        try:
            if filename.lower().endswith('.csv'):
                df = pd.read_csv(io.StringIO(content.decode('utf-8')))
            elif filename.lower().endswith(('.xlsx', '.xls')):
                df = pd.read_excel(io.BytesIO(content))
            else:
                raise ValueError("Unsupported file format")
            
            required_columns = ['id', 'title', 'description']
            missing_columns = [col for col in required_columns if col not in df.columns]
            if missing_columns:
                raise ValueError(f"Missing required columns: {missing_columns}")
            
            requirements = []
            for _, row in df.iterrows():
                def safe_get(key, default=None):
                    value = row.get(key, default)
                    return default if pd.isna(value) else value
                
                category = None
                if 'category' in df.columns and not pd.isna(row.get('category')):
                    try:
                        category = RequirementCategory(row['category'].upper())
                    except ValueError:
                        pass
                
                requirement = Requirement(
                    id=str(safe_get('id', '')),
                    title=str(safe_get('title', '')),
                    description=str(safe_get('description', '')),
                    businessValue=safe_get('businessValue'),
                    cost=safe_get('cost'),
                    risk=safe_get('risk'),
                    urgency=safe_get('urgency'),
                    stakeholderValue=safe_get('stakeholderValue'),
                    category=category
                )
                requirements.append(requirement)
            
            return requirements
            
        except Exception as e:
            raise ValueError(f"Failed to parse file: {str(e)}")
    
    def validate_requirements(self, requirements: List[Requirement]) -> List[str]:
        errors = []
        
        for i, req in enumerate(requirements):
            if not req.id.strip():
                errors.append(f"Requirement {i+1}: ID is required")
            if not req.title.strip():
                errors.append(f"Requirement {i+1}: Title is required")
            if not req.description.strip():
                errors.append(f"Requirement {i+1}: Description is required")
            
            scoring_fields = ['businessValue', 'cost', 'risk', 'urgency', 'stakeholderValue']
            for field in scoring_fields:
                value = getattr(req, field)
                if value is not None and (value < 1 or value > 10):
                    errors.append(f"Requirement {i+1}: {field} must be between 1 and 10")
        
        return errors
