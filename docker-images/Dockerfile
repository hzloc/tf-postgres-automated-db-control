FROM public.ecr.aws/lambda/python:3.12

# set DB connection string
ENV DB_URL="postgresql+psycopg2://fddomain:fddomain@172.22.0.2:5432/fddomain"

# Copy requirements.txt
COPY ../requirements.txt alembic.ini ${LAMBDA_TASK_ROOT}
COPY ../migration ${LAMBDA_TASK_ROOT}/migration

# Install the specified packages
RUN pip install -r requirements.txt

# Copy function code
COPY ../lambda_function.py ${LAMBDA_TASK_ROOT}

# Set the CMD to your handler (could also be done as a parameter override outside of the Dockerfile)
CMD [ "lambda_function.handler" ]