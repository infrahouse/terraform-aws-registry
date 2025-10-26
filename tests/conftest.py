import logging

from infrahouse_core.logging import setup_logging

LOG = logging.getLogger(__name__)

setup_logging(LOG, debug=True)
