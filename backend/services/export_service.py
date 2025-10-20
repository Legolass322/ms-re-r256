import csv
import io
from typing import List
from models.requirement import PrioritizedRequirement
from jinja2 import Template


class ExportService:    
    def generate_csv(self, requirements: List[PrioritizedRequirement]) -> str:        
        output = io.StringIO()
        writer = csv.writer(output)
        
        headers = [
            'Rank', 'ID', 'Title', 'Description', 'Category',
            'Priority Score', 'Confidence', 'Business Value', 'Cost', 
            'Risk', 'Urgency', 'Stakeholder Value', 'Reasoning'
        ]
        writer.writerow(headers)
        
        for req in requirements:
            row = [
                req.rank,
                req.id,
                req.title,
                req.description,
                req.category or '',
                f"{req.priorityScore:.2f}",
                f"{req.confidence:.2f}" if req.confidence else '',
                req.businessValue or '',
                req.cost or '',
                req.risk or '',
                req.urgency or '',
                req.stakeholderValue or '',
                req.reasoning or ''
            ]
            writer.writerow(row)
        
        return output.getvalue()
    
    def generate_html(self, requirements: List[PrioritizedRequirement], session_id: str) -> str:
        total_requirements = len(requirements)
        avg_score = sum(req.priorityScore for req in requirements) / total_requirements if total_requirements > 0 else 0
        avg_confidence = sum(req.confidence for req in requirements if req.confidence) / total_requirements if total_requirements > 0 else 0
        
        categories = {}
        for req in requirements:
            category = req.category or 'Uncategorized'
            if category not in categories:
                categories[category] = []
            categories[category].append(req)
        
        # HTML template
        html_template = Template("""
<!DOCTYPE html>
<html lang="en">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title>ARIA Prioritization Report - Session {{ session_id }}</title>
    <style>
        body {
            font-family: -apple-system, BlinkMacSystemFont, 'Segoe UI', Roboto, sans-serif;
            line-height: 1.6;
            color: #333;
            max-width: 1200px;
            margin: 0 auto;
            padding: 20px;
            background-color: #f8f9fa;
        }
        .header {
            background: linear-gradient(135deg, #007AFF, #5856D6);
            color: white;
            padding: 30px;
            border-radius: 12px;
            margin-bottom: 30px;
            text-align: center;
        }
        .header h1 {
            margin: 0;
            font-size: 2.5em;
            font-weight: 300;
        }
        .header p {
            margin: 10px 0 0 0;
            opacity: 0.9;
        }
        .stats {
            display: grid;
            grid-template-columns: repeat(auto-fit, minmax(200px, 1fr));
            gap: 20px;
            margin-bottom: 30px;
        }
        .stat-card {
            background: white;
            padding: 20px;
            border-radius: 12px;
            box-shadow: 0 2px 10px rgba(0,0,0,0.1);
            text-align: center;
        }
        .stat-number {
            font-size: 2em;
            font-weight: bold;
            color: #007AFF;
            margin-bottom: 5px;
        }
        .stat-label {
            color: #666;
            font-size: 0.9em;
        }
        .requirements-table {
            background: white;
            border-radius: 12px;
            overflow: hidden;
            box-shadow: 0 2px 10px rgba(0,0,0,0.1);
            margin-bottom: 30px;
        }
        .table-header {
            background: #f8f9fa;
            padding: 20px;
            border-bottom: 1px solid #e9ecef;
        }
        .table-header h2 {
            margin: 0;
            color: #333;
        }
        table {
            width: 100%;
            border-collapse: collapse;
        }
        th, td {
            padding: 15px;
            text-align: left;
            border-bottom: 1px solid #e9ecef;
        }
        th {
            background: #f8f9fa;
            font-weight: 600;
            color: #555;
        }
        .rank {
            font-weight: bold;
            color: #007AFF;
            text-align: center;
        }
        .score {
            font-weight: bold;
            text-align: center;
        }
        .score.high { color: #34C759; }
        .score.medium { color: #FF9500; }
        .score.low { color: #FF3B30; }
        .category {
            background: #e3f2fd;
            color: #1976d2;
            padding: 4px 8px;
            border-radius: 4px;
            font-size: 0.8em;
            font-weight: 500;
        }
        .reasoning {
            font-style: italic;
            color: #666;
            font-size: 0.9em;
        }
        .top-3 {
            background: linear-gradient(90deg, #e8f5e8, transparent);
        }
        .footer {
            text-align: center;
            color: #666;
            margin-top: 40px;
            padding: 20px;
            border-top: 1px solid #e9ecef;
        }
    </style>
</head>
<body>
    <div class="header">
        <h1>ARIA Prioritization Report</h1>
        <p>Session: {{ session_id }} | Generated: {{ timestamp }}</p>
    </div>
    
    <div class="stats">
        <div class="stat-card">
            <div class="stat-number">{{ total_requirements }}</div>
            <div class="stat-label">Total Requirements</div>
        </div>
        <div class="stat-card">
            <div class="stat-number">{{ "%.1f"|format(avg_score) }}</div>
            <div class="stat-label">Average Priority Score</div>
        </div>
        <div class="stat-card">
            <div class="stat-number">{{ "%.1f"|format(avg_confidence * 100) }}%</div>
            <div class="stat-label">Average Confidence</div>
        </div>
        <div class="stat-card">
            <div class="stat-number">{{ categories|length }}</div>
            <div class="stat-label">Categories</div>
        </div>
    </div>
    
    <div class="requirements-table">
        <div class="table-header">
            <h2>Prioritized Requirements</h2>
        </div>
        <table>
            <thead>
                <tr>
                    <th>Rank</th>
                    <th>ID</th>
                    <th>Title</th>
                    <th>Category</th>
                    <th>Priority Score</th>
                    <th>Confidence</th>
                    <th>Reasoning</th>
                </tr>
            </thead>
            <tbody>
                {% for req in requirements %}
                <tr class="{% if req.rank <= 3 %}top-3{% endif %}">
                    <td class="rank">#{{ req.rank }}</td>
                    <td>{{ req.id }}</td>
                    <td>
                        <strong>{{ req.title }}</strong>
                        <br><small>{{ req.description[:100] }}{% if req.description|length > 100 %}...{% endif %}</small>
                    </td>
                    <td>
                        {% if req.category %}
                        <span class="category">{{ req.category }}</span>
                        {% else %}
                        <span style="color: #999;">-</span>
                        {% endif %}
                    </td>
                    <td class="score {% if req.priorityScore >= 70 %}high{% elif req.priorityScore >= 40 %}medium{% else %}low{% endif %}">
                        {{ "%.1f"|format(req.priorityScore) }}
                    </td>
                    <td>
                        {% if req.confidence %}
                        {{ "%.1f"|format(req.confidence * 100) }}%
                        {% else %}
                        -
                        {% endif %}
                    </td>
                    <td class="reasoning">{{ req.reasoning or '-' }}</td>
                </tr>
                {% endfor %}
            </tbody>
        </table>
    </div>
    
    <div class="footer">
        <p>Generated by ARIA - Advanced Requirements Intelligence & Analytics</p>
        <p>For questions or support, contact: support@aria-app.com</p>
    </div>
</body>
</html>
        """)
        
        html_content = html_template.render(
            session_id=session_id,
            timestamp=self._get_current_timestamp(),
            requirements=requirements,
            total_requirements=total_requirements,
            avg_score=avg_score,
            avg_confidence=avg_confidence,
            categories=categories
        )
        
        return html_content
    
    def _get_current_timestamp(self) -> str:
        from datetime import datetime
        return datetime.now().strftime("%B %d, %Y at %I:%M %p")
