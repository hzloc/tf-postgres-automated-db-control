FROM ubuntu:20.04
ARG DEBIAN_FRONTEND=noninteractive
E
ENV DB_URL=postgresql+psycopg2://fddomain:fddomain@localhost:54325/fddomain

COPY . .

# update the system
RUN --mount=type=cache,target=/var/cache/apt \
    apt-get update \
    && apt-get install -y python3-pip \
    && apt-get install -y postgresql

# install requirements
RUN pip install -r requirements.txt
RUN alembic upgrade head