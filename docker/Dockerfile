# Use slim version of Debian stable:
FROM debian:stable-slim as base

# Set environment variables
ENV TZ America/Edmonton
ENV DEBIAN_FRONTEND noninteractive
ENV LC_ALL en_US.UTF-8
ENV LANG en_US.UTF-8
ENV LANGUAGE en_US.UTF-8

RUN apt-get update -yq &&  \
    apt-get upgrade -yq && \
    apt-get install -yq --no-install-recommends apt-utils && \
    apt-get install -yq --no-install-recommends locales locales-all cmake csh bash wget g++ gcc libc-bin \
    libc6 git build-essential r-base python3 zlib1g-dev && \
    apt-get clean -y && \
    rm -rf /var/lib/apt/lists/*

########################################################################################################################
# R Package Builds
########################################################################################################################

FROM base as rbuilder

RUN apt-get update && \
    apt-get install -yq r-base r-base-dev --no-install-recommends && \
    rm -rf /var/lib/apt/lists/* && \
    mkdir -p /usr/local/lib/R/site-library

WORKDIR /app
COPY docker/Rpackages.R /app/Rpackages.R
RUN /usr/bin/Rscript /app/Rpackages.R

########################################################################################################################
# Python Package Builds
########################################################################################################################

FROM base as pythonbuilder

# Set environment variables:
ENV PYTHONFAULTHANDLER=1 \
    PYTHONUNBUFFERED=1 \
    PYTHONHASHSEED=random \
    PYTHONDONTWRITEBYTECODE=1 \
    # pip:
    PIP_NO_CACHE_DIR=off \
    PIP_DISABLE_PIP_VERSION_CHECK=on \
    PIP_DEFAULT_TIMEOUT=100 \
    # poetry:
    POETRY_VERSION=1.1.13 \
    POETRY_NO_INTERACTION=1 \
    POETRY_CACHE_DIR='/var/cache/pypoetry' \
    PATH="$PATH:/root/.local/bin" \
    POETRY_VIRTUALENVS_IN_PROJECT=true \
    # python:
    PYTHON_MAJOR=3 \
    PYTHON_MINOR=10 \
    PYTHON_MICRO=8
ENV PYTHON_VERSION=$PYTHON_MAJOR.$PYTHON_MINOR.$PYTHON_MICRO


# Install packages:
RUN update-ca-certificates && \
    apt-get update && \
    apt-get install -yq --no-install-recommends libssl-dev libffi-dev libsasl2-dev python3-dev && \
    rm -rf /var/lib/apt/lists/*

# Install specified version of python:
RUN wget -nv https://www.python.org/ftp/python/$PYTHON_VERSION/Python-$PYTHON_VERSION.tgz -O /opt/Python-$PYTHON_VERSION.tgz && \
    cd /opt && \
    tar -xzf /opt/Python-${PYTHON_VERSION}.tgz --one-top-level && \
    cd /opt/Python-${PYTHON_VERSION} && \
    ./configure --enable-optimizations && \
    make altinstall && \
    update-alternatives --install /usr/bin/python python /usr/local/bin/python${PYTHON_MAJOR}.${PYTHON_MINOR} 3
WORKDIR /app

# Install poetry:
RUN python -m pip install --no-cache-dir certifi --trusted-host pypi.org --trusted-host files.pythonhosted.org && \
    python -m pip install --no-cache-dir --upgrade --trusted-host pypi.org --trusted-host files.pythonhosted.org pip "pipx" && \
    pipx install "poetry==$POETRY_VERSION" && \
    pipx ensurepath

# Build python packages / environment:
COPY pyproject.toml poetry.lock /app/
RUN poetry cache clear --all pypi && \
    poetry install --no-root --no-ansi && \
    poetry export --dev --without-hashes --no-interaction --no-ansi -f requirements.txt -o /app/requirements.txt

########################################################################################################################
# Final Image
########################################################################################################################

FROM base as mastobot

# Install R / Python:
RUN apt-get update -yq && \
    apt-get install -yq r-base python3 --no-install-recommends && \
    rm -rf /var/lib/apt/lists/*

# Copy files from respective builders:
COPY --from=pythonbuilder /opt/Python-3.10.8/python /usr/local/bin/python3.10
COPY --from=pythonbuilder /usr/local/lib/python3.10 /usr/local/lib/python3.10
COPY --from=pythonbuilder /app/.venv /opt/env
COPY --from=rbuilder /usr/local/lib/R/site-library /usr/local/lib/R/site-library

# Copy script files:
COPY app/bot.py /app/bot.py
COPY app/covid_plots.R /app/covid_plots.R
COPY app/run.sh /app/run.sh

# User settings
RUN useradd --shell /bin/bash -m app && \
    chown -R app:app /app && \
    chmod +x /app/run.sh

# Run as non-root user
USER app
ENV VIRTUAL_ENV /opt/env
ENV PATH $VIRTUAL_ENV/bin:$PATH
WORKDIR /app/

ENTRYPOINT ["/bin/bash"]
