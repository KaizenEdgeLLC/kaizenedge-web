from .common import Item, build_cart
def search_items(query: str, location: str):
    # MOCK: replace with real API in Phase 2
    return [Item(sku="MOCK-001", name=f"{query} (mock)", store=__name__.split('.')[-1], price_usd=3.49, unit="each", in_stock=True)]
def get_price(sku: str, location: str):
    return 3.49
def build_demo_cart(q: str, loc: str):
    return build_cart(search_items(q, loc))
