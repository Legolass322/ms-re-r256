# Backend Integration Guide

This guide helps backend developers implement the ARIA API based on the OpenAPI specification.

## 📄 OpenAPI Specification

The complete API specification is in `openapi.json`. This document serves as the contract between frontend and backend.

## 🎯 Implementation Checklist

### Required Endpoints

- [ ] `POST /requirements/upload` - File upload handler
- [ ] `POST /requirements` - Manual requirement creation
- [ ] `GET /requirements` - Retrieve requirements by session
- [ ] `POST /prioritization/analyze` - AI prioritization engine
- [ ] `GET /prioritization/{sessionId}` - Get results
- [ ] `GET /export/csv/{sessionId}` - CSV export
- [ ] `GET /export/html/{sessionId}` - HTML export
- [ ] `GET /health` - Health check endpoint

### Core Features

- [ ] File parsing (CSV, XLSX, XLS)
- [ ] Session management (UUID-based)
- [ ] Weighted scoring algorithm
- [ ] ML model integration
- [ ] CSV generation
- [ ] HTML report generation
- [ ] Error handling

## 🔍 Endpoint Details

### 1. Upload Requirements

```http
POST /v1/requirements/upload
Content-Type: multipart/form-data
```

**Request:**
- `file`: CSV/Excel file (binary)

**Response:**
```json
{
  "sessionId": "uuid-v4",
  "requirementsCount": 25,
  "message": "Successfully uploaded 25 requirements",
  "requirements": [...]
}
```

**Validation:**
- Max 100 requirements per file
- Required columns: `id`, `title`, `description`
- Optional columns: `businessValue`, `cost`, `risk`, `urgency`, `stakeholderValue`, `category`

**CSV Format:**
```csv
id,title,description,businessValue,cost,risk,urgency,stakeholderValue,category
req-1,"Feature","Description",8,5,3,7,8,FEATURE
```

### 2. Create Requirements

```http
POST /v1/requirements
Content-Type: application/json
```

**Request:**
```json
{
  "requirements": [
    {
      "id": "req-1",
      "title": "User Authentication",
      "description": "Implement login system",
      "businessValue": 9,
      "cost": 7,
      "risk": 4,
      "urgency": 9,
      "stakeholderValue": 9,
      "category": "FEATURE"
    }
  ]
}
```

**Response:**
```json
{
  "sessionId": "uuid-v4",
  "requirementsCount": 1,
  "message": "Requirements created successfully"
}
```

### 3. Analyze Prioritization

```http
POST /v1/prioritization/analyze
Content-Type: application/json
```

**Request:**
```json
{
  "sessionId": "uuid-v4",
  "weights": {
    "businessValue": 0.3,
    "cost": 0.2,
    "risk": 0.15,
    "urgency": 0.2,
    "stakeholderValue": 0.15
  }
}
```

**Response:**
```json
{
  "sessionId": "uuid-v4",
  "prioritizedRequirements": [
    {
      "id": "req-1",
      "title": "User Authentication",
      "description": "Implement login system",
      "businessValue": 9,
      "cost": 7,
      "risk": 4,
      "urgency": 9,
      "stakeholderValue": 9,
      "category": "FEATURE",
      "priorityScore": 85.5,
      "rank": 1,
      "confidence": 0.92,
      "reasoning": "High business value and urgency with manageable risk"
    }
  ],
  "processingTimeMs": 3250,
  "metadata": {
    "totalRequirements": 25,
    "averageScore": 65.8,
    "modelVersion": "v1.0",
    "weightsUsed": {...}
  }
}
```

**Performance Requirements:**
- Process 100 requirements in ≤5 seconds
- Return 503 if timeout exceeded

### 4. Export CSV

```http
GET /v1/export/csv/{sessionId}
```

**Response:**
```csv
rank,id,title,description,priorityScore,confidence,businessValue,cost,risk,urgency,stakeholderValue,category
1,req-1,"User Authentication","Implement login system",85.5,0.92,9,7,4,9,9,FEATURE
```

**Headers:**
```
Content-Type: text/csv
Content-Disposition: attachment; filename="aria_export_{timestamp}.csv"
```

### 5. Export HTML

```http
GET /v1/export/html/{sessionId}
```

**Response:**
Static HTML page with:
- Priority rankings
- Visual score indicators
- Requirement details
- Export timestamp
- Professional styling

**Template:**
```html
<!DOCTYPE html>
<html>
<head>
  <title>ARIA Prioritization Report</title>
  <style>/* Minimalistic styling */</style>
</head>
<body>
  <h1>Requirements Prioritization Report</h1>
  <!-- Ranked requirements table -->
</body>
</html>
```

## 🤖 Prioritization Algorithm

### Weighted Scoring Formula

```python
priority_score = (
    businessValue * weight_bv +
    (10 - cost) * weight_cost +  # Inverse: lower cost = better
    (10 - risk) * weight_risk +  # Inverse: lower risk = better
    urgency * weight_urgency +
    stakeholderValue * weight_sv
) * 10  # Scale to 0-100
```

### Default Weights

```python
DEFAULT_WEIGHTS = {
    'businessValue': 0.3,
    'cost': 0.2,
    'risk': 0.15,
    'urgency': 0.2,
    'stakeholderValue': 0.15
}
# Total must equal 1.0
```

### ML Model Integration

**Recommended Approach:**
1. Start with weighted scoring (deterministic)
2. Train ML model on historical data
3. Combine both: `final_score = 0.7 * weighted + 0.3 * ml_prediction`
4. Generate confidence based on model certainty
5. Provide reasoning using feature importance

**Simple ML Model (MVP):**
- Decision Tree or Random Forest
- Features: all scoring criteria
- Target: expert-ranked priority
- Train on 30+ labeled examples

**Advanced (Future):**
- BERT/LLM for text analysis
- Historical project success correlation
- Stakeholder preference learning

## 🗄️ Data Storage

### Session Schema

```json
{
  "sessionId": "uuid",
  "createdAt": "ISO-8601",
  "expiresAt": "ISO-8601",
  "requirements": [...],
  "prioritization": {...}
}
```

**Recommendations:**
- Use Redis/Memcached for sessions (1 hour TTL)
- PostgreSQL/MongoDB for persistence
- Index by sessionId for fast lookup

## 🔒 Security

### MVP Requirements

- Input validation (file size, format, content)
- SQL injection prevention
- XSS protection in HTML export
- Rate limiting (100 requests/hour per IP)

### Future Enhancements

- Authentication (JWT)
- Authorization (role-based)
- Data encryption at rest
- HTTPS only
- CORS configuration

## ⚡ Performance

### Optimization Strategies

1. **Caching:**
   - Cache processed results by sessionId
   - Cache ML model in memory
   - Use CDN for static exports

2. **Async Processing:**
   - Queue long-running analysis
   - WebSocket for progress updates
   - Background workers for exports

3. **Database:**
   - Index sessionId and createdAt
   - Paginate large result sets
   - Archive old sessions

### Benchmarks

| Operation | Target | Limit |
|-----------|--------|-------|
| File upload | <1s | 2s |
| Analyze 100 reqs | <5s | 7s |
| CSV export | <1s | 2s |
| HTML export | <2s | 3s |

## 🧪 Testing

### Test Cases

**File Upload:**
- Valid CSV with 10, 50, 100 requirements
- Invalid format (wrong columns)
- Empty file
- File too large (>100 requirements)

**Prioritization:**
- All criteria provided
- Partial criteria (missing values)
- Custom weights
- Edge cases (all same scores)

**Export:**
- Valid sessionId
- Invalid/expired sessionId
- Large result sets

### Sample Test Data

Use `sample_requirements.csv` for testing.

## 📊 Monitoring

### Metrics to Track

- Request count by endpoint
- Response times (p50, p95, p99)
- Error rates by type
- Processing times for prioritization
- Session creation/expiration rates

### Alerts

- Processing time >5s for 100 reqs
- Error rate >5%
- Memory usage >80%
- Disk space <20%

## 🚀 Deployment

### Docker Setup

```dockerfile
FROM python:3.11-slim
WORKDIR /app
COPY requirements.txt .
RUN pip install -r requirements.txt
COPY . .
EXPOSE 8080
CMD ["uvicorn", "main:app", "--host", "0.0.0.0", "--port", "8080"]
```

### Environment Variables

```env
API_VERSION=v1
PORT=8080
DATABASE_URL=postgresql://...
REDIS_URL=redis://...
ML_MODEL_PATH=/models/prioritization_v1.pkl
MAX_REQUIREMENTS=100
SESSION_TTL=3600
```

## 📞 Support

Questions? Contact frontend team or check:
- OpenAPI spec: `openapi.json`
- Frontend models: `lib/models/`
- Sample data: `sample_requirements.csv`

---

**Good luck with the implementation! 🚀**
