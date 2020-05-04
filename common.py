NAME = "Podcast Processor"


def normalize_string(str):
    import string

    return "".join(
        [c for c in str if (c in string.digits or c in string.ascii_letters)]
    )
