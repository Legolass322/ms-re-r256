import random
import math
from typing import List
from models.requirement import Requirement, PrioritizedRequirement, Weights


class PrioritizationService:
    
    def __init__(self):
        self.default_weights = Weights()
    
    def prioritize_requirements(
        self, 
        requirements: List[Requirement], 
        weights: Weights = None
    ) -> List[PrioritizedRequirement]:
        
        if not requirements:
            return []
        
        if weights is None:
            weights = self.default_weights
        
        prioritized = []
        for i, req in enumerate(requirements):
            priority_score = self._calculate_priority_score(req, weights)
            confidence = self._calculate_confidence(req)
            reasoning = self._generate_reasoning(req, priority_score, weights)
            
            prioritized_req = PrioritizedRequirement(
                **req.dict(),
                priorityScore=priority_score,
                rank=1,
                confidence=confidence,
                reasoning=reasoning
            )
            prioritized.append(prioritized_req)
        
        prioritized.sort(key=lambda x: x.priorityScore, reverse=True)
        for i, req in enumerate(prioritized):
            req.rank = i + 1
        
        return prioritized
    
    def _calculate_priority_score(self, req: Requirement, weights: Weights) -> float:
        business_value = req.businessValue or 5.0
        cost = req.cost or 5.0
        risk = req.risk or 5.0
        urgency = req.urgency or 5.0
        stakeholder_value = req.stakeholderValue or 5.0
        
        norm_business = (business_value - 1) / 9
        norm_cost = (cost - 1) / 9
        norm_risk = (risk - 1) / 9
        norm_urgency = (urgency - 1) / 9
        norm_stakeholder = (stakeholder_value - 1) / 9
        
        # Calculate weighted score
        # For cost and risk, lower values are better, so we invert them
        weighted_score = (
            norm_business * weights.businessValue +
            (1 - norm_cost) * weights.cost +  # Inverted: lower cost = higher priority
            (1 - norm_risk) * weights.risk +  # Inverted: lower risk = higher priority
            norm_urgency * weights.urgency +
            norm_stakeholder * weights.stakeholderValue
        )
        
        category_multiplier = self._get_category_multiplier(req.category)
        weighted_score *= category_multiplier
        
        noise = random.uniform(-0.05, 0.05)
        weighted_score += noise
        
        return max(0, min(100, weighted_score * 100))
    
    def _get_category_multiplier(self, category) -> float:
        multipliers = {
            "BUG_FIX": 1.2,      # Bug fixes get priority boost
            "COMPLIANCE": 1.1,   # Compliance requirements slightly higher
            "FEATURE": 1.0,      # Features are baseline
            "ENHANCEMENT": 0.9,  # Enhancements slightly lower
            "TECHNICAL": 0.8,    # Technical debt lowest
            None: 1.0            # Default for no category
        }
        return multipliers.get(category, 1.0)
    
    def _calculate_confidence(self, req: Requirement) -> float:        
        scoring_fields = ['businessValue', 'cost', 'risk', 'urgency', 'stakeholderValue']
        provided_fields = sum(1 for field in scoring_fields if getattr(req, field) is not None)
        
        base_confidence = provided_fields / len(scoring_fields)
        
        noise = random.uniform(-0.1, 0.1)
        confidence = base_confidence + noise
        
        # Ensure confidence is between 0 and 1
        return max(0.0, min(1.0, confidence))
    
    def _generate_reasoning(self, req: Requirement, score: float, weights: Weights) -> str:        
        reasons = []
        
        if req.businessValue:
            if req.businessValue >= 8:
                reasons.append(f"High business value ({req.businessValue}/10)")
            elif req.businessValue <= 3:
                reasons.append(f"Low business value ({req.businessValue}/10)")
        
        if req.cost:
            if req.cost <= 3:
                reasons.append(f"Low implementation cost ({req.cost}/10)")
            elif req.cost >= 8:
                reasons.append(f"High implementation cost ({req.cost}/10)")
        
        if req.risk:
            if req.risk <= 3:
                reasons.append(f"Low implementation risk ({req.risk}/10)")
            elif req.risk >= 8:
                reasons.append(f"High implementation risk ({req.risk}/10)")
        
        if req.urgency:
            if req.urgency >= 8:
                reasons.append(f"High urgency ({req.urgency}/10)")
            elif req.urgency <= 3:
                reasons.append(f"Low urgency ({req.urgency}/10)")
        
        if req.stakeholderValue:
            if req.stakeholderValue >= 8:
                reasons.append(f"High stakeholder value ({req.stakeholderValue}/10)")
            elif req.stakeholderValue <= 3:
                reasons.append(f"Low stakeholder value ({req.stakeholderValue}/10)")
        
        if req.category:
            category_reasons = {
                "BUG_FIX": "Bug fix requirements typically have high priority",
                "COMPLIANCE": "Compliance requirements are important for regulatory adherence",
                "FEATURE": "New feature for user value",
                "ENHANCEMENT": "Enhancement to existing functionality",
                "TECHNICAL": "Technical improvement or refactoring"
            }
            if req.category in category_reasons:
                reasons.append(category_reasons[req.category])
        
        if not reasons:
            return f"Priority score of {score:.1f} based on weighted analysis of available criteria."
        
        if len(reasons) == 1:
            return f"Priority score of {score:.1f} due to {reasons[0]}."
        else:
            return f"Priority score of {score:.1f} based on: {', '.join(reasons)}."
