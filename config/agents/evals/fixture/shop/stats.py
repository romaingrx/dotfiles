def total_slow(xs):
    total = 0
    for x in xs:
        total = total + x
    return total


def total_fast(xs):
    return sum(xs)
