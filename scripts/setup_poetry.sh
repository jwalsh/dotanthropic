# Initialize project
# poetry init

# Core AI Assistant Tools
poetry add aider-chat          # AI pair programming
poetry add llm                 # CLI for LLMs
poetry add ttok               # Token handling
poetry add strip-tags         # HTML processing
poetry add files-to-prompt    # File content to prompts

# Additional AI Tools
poetry add gpt4all           # Local LLM support
poetry add langchain        # LLM framework
poetry add transformers     # Hugging Face transformers
poetry add openai          # OpenAI official SDK
poetry add anthropic       # Claude/Anthropic API
poetry add instructor      # Type-safe OpenAI responses
poetry add guidance       # Structured LLM output
poetry add semantic-kernel # AI orchestration

# Code Analysis & Quality
poetry add --group dev ruff     # Fast Python linter
poetry add --group dev black    # Code formatting
poetry add --group dev isort    # Import sorting
poetry add --group dev mypy     # Type checking
poetry add --group dev pylint   # Advanced linting
poetry add --group dev bandit   # Security linting
poetry add --group dev vulture  # Dead code detection

# Testing Tools
poetry add --group dev pytest              # Testing framework
poetry add --group dev pytest-cov          # Coverage reporting
poetry add --group dev pytest-mock         # Mocking support
poetry add --group dev pytest-asyncio      # Async testing
poetry add --group dev hypothesis          # Property-based testing
poetry add --group dev faker              # Fake data generation

# Documentation
poetry add --group dev mkdocs              # Documentation generator
poetry add --group dev mkdocs-material     # Material theme
poetry add --group dev mkdocstrings       # Auto-generate API docs
poetry add --group dev jupyter            # Notebooks
poetry add --group dev nbconvert          # Notebook conversion

# Development Utilities
poetry add --group dev pre-commit         # Git hooks
poetry add --group dev rich              # Terminal formatting
poetry add --group dev typer            # CLI builder
poetry add --group dev pydantic        # Data validation
poetry add --group dev python-dotenv   # Environment management
poetry add --group dev requests       # HTTP client
poetry add --group dev fastapi       # API framework
poetry add --group dev uvicorn      # ASGI server

# AI Development Specific
poetry add --group dev datasets    # Hugging Face datasets
poetry add --group dev evaluate   # Model evaluation
poetry add --group dev accelerate # Model acceleration
poetry add --group dev optimum   # Model optimization

# Set up API keys
poetry run llm keys set openai
echo "Remember to set up your API keys in .env file"

# Show all installed packages
poetry show

# Optional: Export dependencies
poetry export -f requirements.txt --output requirements.txt --without-hashes
poetry export -f requirements.txt --output requirements-dev.txt --without-hashes --with dev
