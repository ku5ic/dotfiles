# Fixture for docker-patterns evals.
# Deliberate anti-patterns embedded:
#   1. Runs as root (no USER instruction) - failure
#   2. Secret baked into ENV - failure
#   3. apt-get update and install in separate RUN statements - warning
#   4. COPY . . before requirements install (breaks layer caching) - warning
#   5. Shell form CMD (doesn't propagate signals) - info

FROM python:3.12

# anti-pattern 3: update and install in separate RUN statements
RUN apt-get update
RUN apt-get install -y curl libpq-dev

# anti-pattern 2: secret in ENV (visible in docker history and inspect)
ENV SECRET_KEY=my-super-secret-key-do-not-share
ENV DATABASE_PASSWORD=hunter2

WORKDIR /app

# anti-pattern 4: copy everything first, then install dependencies
# (any code change invalidates the pip cache)
COPY . .
RUN pip install --no-cache-dir -r requirements.txt

# anti-pattern 1: no USER instruction - runs as root
# anti-pattern 5: shell form CMD
CMD python -m gunicorn --bind 0.0.0.0:8000 app:app
