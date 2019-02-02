import logging


def set_loglevel(loglevel: str) -> None:
    """
    Used to set log level according to the logging module

    :param loglevel: String representation of log level
    """
    numeric_level = getattr(logging, loglevel.upper(), None)
    if not isinstance(numeric_level, int):
        raise ValueError('Invalid log level: %s' % loglevel)
    logging.basicConfig(level=numeric_level)
    logging.getLogger().setLevel(numeric_level)
