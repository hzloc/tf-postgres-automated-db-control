import sys
import alembic.command
import alembic.config

def migrate():
    alembic_argvs = [
    '--raiseerr',
    'upgrade', 'head',
    ]
    alembic.config.main(argv=alembic_argvs)

def handler(event, context):
    print("Running alembic database migrations..")
    migrate()
    return 'Hello from AWS Lambda using Python' + sys.version + '!'
