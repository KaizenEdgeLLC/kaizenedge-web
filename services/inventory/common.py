from dataclasses import dataclass
from typing import List, Optional
@dataclass
class Item:
    sku: str; name: str; store: str; price_usd: float; unit: str; in_stock: bool; nutrition_hint: Optional[dict]=None
def build_cart(items: List[Item]) -> dict:
    total = round(sum(i.price_usd for i in items), 2)
    return {"items":[i.__dict__ for i in items], "total_usd": total}
