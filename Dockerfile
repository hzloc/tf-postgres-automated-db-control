FROM public.ecr.aws/lambda/python:3.12

# set DB connection string
ARG DB_HOST=tf-postgres-aws-postgres-1
ARG DB_USERNAME=hzlocslocs
ARG DB_PASSWORD=hzlocslocs
ARG DB_NAME=hzlocslocs
ARG DB_PORT=5432

ENV DB_URL="postgresql+psycopg2://$DB_USERNAME:$DB_PASSWORD@$DB_HOST:$DB_PORT/$DB_NAME"

# Copy requirements.txt
COPY requirements.txt alembic.ini ${LAMBDA_TASK_ROOT}
COPY migration ${LAMBDA_TASK_ROOT}/migration

# Install the specified packages
RUN pip install -r requirements.txt

# Copy function code
COPY lambda_function.py ${LAMBDA_TASK_ROOT}

# Set the CMD to your handler (could also be done as a parameter override outside of the Dockerfile)
CMD [ "lambda_function.handler" ]