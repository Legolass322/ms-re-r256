# ARIA Quick Start Guide

Get up and running with ARIA in 5 minutes!

## 🚀 Installation

### Option 1: Run from Source

```bash
# Clone the repository
git clone <repository-url>
cd aria

# Navigate to frontend
cd frontend

# Install dependencies
flutter pub get

# Run the app
flutter run -d chrome  # For web browser
```

### Option 2: Use Pre-built Release

Download the latest release for your platform from the releases page.

## 📋 Quick Tutorial

### Step 1: Launch ARIA

Open the app and you'll see the home screen with an overview of features.

### Step 2: Choose Input Method

Click **"Get Started"** and choose how to input your requirements:

#### Option A: Upload a File

1. Click **"Choose File"**
2. Select a CSV or Excel file
3. Click **"Upload & Analyze"**

**Sample CSV format:**
```csv
id,title,description,businessValue,cost,risk,urgency,stakeholderValue,category
1,"User Login","Implement authentication",9,5,3,8,9,FEATURE
```

💡 **Tip**: Use the included `backend/sample_requirements.csv` file to test!

#### Option B: Manual Entry

1. Click **"Create Requirements"**
2. Click **"Add Requirement"**
3. Fill in the form:
   - **Title**: Short name for the requirement
   - **Description**: Detailed explanation
   - **Category**: Type of requirement
   - **Scores (1-10)**: Optional criteria
     - Business Value: How valuable is this?
     - Cost: How expensive to implement?
     - Risk: How risky is implementation?
     - Urgency: How urgent is this?
     - Stakeholder Value: How important to stakeholders?
4. Click **"Save Requirement"**
5. Add more requirements or click **"Analyze"**

### Step 3: View Results

After analysis (< 5 seconds), you'll see your prioritized requirements:

**List View:**
- Requirements ranked by priority
- Priority scores (0-100)
- Top 3 highlighted in green
- Tap for detailed breakdown

**Chart View:**
- Bar charts showing score distribution
- Top 10 requirements visualization
- Interactive tooltips

### Step 4: Export Results

1. Tap the **download icon** (top-right)
2. Choose format:
   - **CSV**: For Excel/spreadsheet analysis
   - **HTML**: For presentations/sharing

Files save to your documents folder!

## 💡 Tips & Tricks

### Getting Best Results

1. **Be Specific**: Write clear, detailed descriptions
2. **Score Consistently**: Use the same scale for all requirements
3. **Use Categories**: Categorize requirements for better organization
4. **Review AI Reasoning**: Tap requirements to see why they were ranked

### Scoring Guidelines

| Score | Business Value | Cost | Risk | Urgency |
|-------|---------------|------|------|---------|
| 1-3 | Low impact | Cheap | Low risk | Can wait |
| 4-6 | Moderate impact | Moderate cost | Some risk | Normal priority |
| 7-10 | High impact | Expensive | High risk | Urgent |

### Sample Use Cases

**Product Manager:**
- Upload 50 feature requests from customer feedback
- Get prioritized roadmap in seconds
- Export as HTML to share with team

**Business Analyst:**
- Manually enter 20 requirements from stakeholder meetings
- Analyze with custom weights
- Export CSV for project documentation

**Startup Founder:**
- Prioritize 100 MVP features
- Focus on high-value, low-cost items
- Make data-driven decisions quickly

## 🔧 Configuration

### Change API Endpoint

Edit `frontend/lib/api/aria_api_client.dart`:

```dart
AriaApiClient({
  baseUrl: 'https://your-backend-url.com/v1',
})
```

### Customize Weights

Default weights (must sum to 1.0):
```json
{
  "businessValue": 0.3,
  "cost": 0.2,
  "risk": 0.15,
  "urgency": 0.2,
  "stakeholderValue": 0.15
}
```

## ⚠️ Common Issues

### "No backend connection"
- Make sure the backend API is running
- Check the API URL in configuration
- Verify network connectivity

### "File upload failed"
- Ensure file is CSV or Excel format
- Check file has correct column headers
- Verify max 100 requirements

### "Processing timeout"
- Reduce number of requirements
- Check backend server performance
- Ensure backend is responding within 5s

## 📊 Understanding Results

### Priority Score (0-100)
Calculated from weighted criteria:
- Higher score = Higher priority
- Considers all input factors
- ML model adjusts based on patterns

### Rank (#1, #2, etc.)
- #1 = Highest priority
- Top 3 get special highlighting
- Sort order in list view

### Confidence (0-100%)
- ML model's certainty
- Higher = More confident
- Based on data quality and patterns

### AI Reasoning
- Explains why requirement was ranked
- Highlights key factors
- Helps validate AI decisions

## 🎯 Next Steps

1. **Try the Sample File**: Load `backend/sample_requirements.csv`
2. **Explore Visualizations**: Switch between list and chart views
3. **Export Results**: Practice exporting in both formats
4. **Read Full Docs**: Check `README.md` for complete documentation
5. **Backend Setup**: See `backend/README.md` for API implementation

## 📞 Need Help?

- 📖 **Documentation**: See `README.md`
- 🐛 **Issues**: Report bugs on GitHub
- 💬 **Support**: support@aria-app.com

---

**Happy Prioritizing! 🎉**
