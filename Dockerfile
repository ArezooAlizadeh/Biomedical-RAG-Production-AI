FROM python:3.11-slim

ENV PYTHONDONTWRITEBYTECODE=1 \
    PYTHONUNBUFFERED=1 \
    PIP_NO_CACHE_DIR=1

RUN apt-get update \
    && apt-get install -y --no-install-recommends libgomp1 \
    && rm -rf /var/lib/apt/lists/*

WORKDIR /app
COPY requirements-docker.txt /app/requirements-docker.txt
RUN python -m pip install -r /app/requirements-docker.txt \
    && python -m pip check

RUN useradd --create-home --uid 10001 appuser \
        && mkdir -p /app/server/uploaded_docs /app/data/uploaded_docs \
    && chown -R appuser:appuser /app

COPY --chown=appuser:appuser server/ /app/server/
COPY --chown=appuser:appuser test_v5.py test_v5_graph.py /app/

USER appuser
# Download the default reranker during the build; its cache travels with the image.
RUN python -c "from flashrank import Ranker; Ranker(); print('Reranker ready')"

# Match the relative paths used by the existing server modules.
WORKDIR /app/server
EXPOSE 8000
CMD ["python", "-m", "uvicorn", "main:app", "--host", "0.0.0.0", "--port", "8000"]
