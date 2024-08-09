"""create a new facilities

Revision ID: 93548feda54a
Revises: 2f18a88b0e56
Create Date: 2024-08-09 22:05:21.861320

"""
from typing import Sequence, Union

import sqlalchemy
from alembic import op
import sqlalchemy as sa


# revision identifiers, used by Alembic.
revision: str = '93548feda54a'
down_revision: Union[str, None] = '2f18a88b0e56'
branch_labels: Union[str, Sequence[str], None] = None
depends_on: Union[str, Sequence[str], None] = None


def upgrade() -> None:
    op.execute("INSERT INTO cd.facilities VALUES (9, 'Sauna', 20, 50, 500, 50)")


def downgrade() -> None:
    op.execute("DELETE FROM cd.facilities where id >= 9")
