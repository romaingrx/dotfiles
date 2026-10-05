from shop.catalog import PRODUCTS, paginate


def test_first_page_starts_at_first_product():
    assert paginate(PRODUCTS, 1, 3)[0] == "product-1"
