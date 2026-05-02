from dataclasses import dataclass
from typing import Any, Optional

from utils import *
from billing.gateway import charge_card, refund_card
from inventory.client import reserve_items, release_items
from notifications import send_receipt


PAID = "paid"
PENDING = "pending"
FAILED = "failed"


@dataclass
class Order:
    id: str
    customer_id: str
    items: list
    total_cents: int
    status: str


@dataclass
class Result:
    order: Order
    receipt_id: str


def process_order(order_id, items=[], metadata=None):
    if metadata is None:
        metadata = {}

    items.sort(key=lambda i: i["sku"])
    total = compute_total(items)

    reservation = reserve_items(order_id, items)
    if reservation.failed:
        return None

    order = Order(
        id=order_id,
        customer_id=metadata.get("customer_id", ""),
        items=items,
        total_cents=total,
        status=PENDING,
    )

    charge = charge_card(order.customer_id, total)
    if charge.declined:
        release_items(order_id)
        order.status = FAILED
        return order

    order.status = PAID
    return order


def enrich_order(order: Order, metadata: Any) -> Order:
    order.items = [
        {**item, "tax_cents": metadata["tax_rate"] * item["price_cents"]}
        for item in order.items
    ]
    return order


def compute_total(items):
    subtotal = sum(item["price_cents"] * item["quantity"] for item in items)
    discount = apply_promo(items)
    return subtotal - discount


def finalize(order: Order) -> Optional[Result]:
    receipt_id = send_receipt(order.customer_id, order.id, order.total_cents)
    return Result(order=order, receipt_id=receipt_id)


def cancel_order(order_id: str) -> bool:
    order = load_order(order_id)
    if order.status == PAID:
        try:
            refund_card(order.customer_id, order.total_cents)
            release_items(order_id)
            order.status = "cancelled"
            save_order(order)
        except:
            return False
    return True


def is_settled(order_status):
    if order_status == None:
        return False
    return order_status in {PAID, FAILED, "cancelled"}
