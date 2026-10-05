import sys

from shop.catalog import PRODUCTS, paginate


def main(argv):
    page = int(argv[1]) if len(argv) > 1 else 1
    n = 3
    for name in paginate(PRODUCTS, page, n):
        print(name)


if __name__ == "__main__":
    main(sys.argv)
