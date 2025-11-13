"""
Service for leveraging OpenAI ChatGPT to analyze requirement sessions.
"""

from typing import List, Optional
import os

from openai import AsyncOpenAI

from models.requirement import Requirement


class AnalysisService:
    """Wrapper around OpenAI Chat Completions for requirement analysis."""

    def __init__(self, api_key: Optional[str] = None, base_url: Optional[str] = None, model: Optional[str] = None) -> None:
        # Use provided config or fall back to environment variables
        self._api_key = api_key or os.getenv("OPENAI_API_KEY")
        if not self._api_key:
            raise RuntimeError(
                "API key must be provided either via config or OPENAI_API_KEY environment variable"
            )

        self._base_url = base_url or os.getenv("OPENAI_BASE_URL", "https://api.openai.com/v1")
        self._model = model or os.getenv("OPENAI_MODEL", "gpt-4o-mini")
        
        self._client = AsyncOpenAI(api_key=self._api_key, base_url=self._base_url)

    async def analyze_requirements(
        self,
        requirements: List[Requirement],
        custom_prompt: Optional[str] = None,
    ) -> str:
        """Generate a prioritization summary using ChatGPT."""
        if not requirements:
            return "No requirements provided for analysis."

        requirements_summary = "\n\n".join(
            [
                (
                    f"ID: {req.id}\n"
                    f"Title: {req.title}\n"
                    f"Description: {req.description}\n"
                    f"Business Value: {req.businessValue}\n"
                    f"Cost: {req.cost}\n"
                    f"Risk: {req.risk}\n"
                    f"Urgency: {req.urgency}\n"
                    f"Stakeholder Value: {req.stakeholderValue}\n"
                    f"Category: {req.category}"
                )
                for req in requirements
            ]
        )

        system_prompt = (
            "You are an expert product analyst. Review the provided requirements "
            "and produce a prioritized list with actionable insights. Highlight "
            "high-impact requirements, risks, and recommendations."
        )
        if custom_prompt:
            system_prompt += f"\nUser context: {custom_prompt}"

        response = await self._client.chat.completions.create(
            model=self._model,
            messages=[
                {"role": "system", "content": system_prompt},
                {"role": "user", "content": requirements_summary},
            ],
            max_tokens=900,
            temperature=0.4,
        )

        message = response.choices[0].message.content
        return message.strip() if message else "No analysis available."

