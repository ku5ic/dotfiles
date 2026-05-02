"""
Fixture for fastapi-patterns evals.
Deliberate anti-patterns embedded:
  1. blocking SQLAlchemy call in async def route (failure: blocking I/O in async)
  2. return HTTPException instead of raise (failure: return vs raise)
  3. no response_model on route that returns ORM object (failure: no response_model)
  4. mutating endpoint with no auth dependency (warning: missing auth)
  5. leaking raw exception message in detail (failure: internal error in detail)
"""

from typing import Annotated
from fastapi import Depends, FastAPI, HTTPException
from pydantic import BaseModel
from sqlalchemy.orm import Session

from .database import Payment, SessionLocal


app = FastAPI()


def get_db():
    db = SessionLocal()
    try:
        yield db
    finally:
        db.close()


class PaymentCreate(BaseModel):
    amount: float
    currency: str
    card_token: str


# anti-pattern 1: sync ORM call in async def route (blocks event loop)
# anti-pattern 3: no response_model - exposes full ORM object
@app.get("/payments/{payment_id}")
async def get_payment(payment_id: int, db: Session = Depends(get_db)):
    return db.query(Payment).filter(Payment.id == payment_id).first()


# anti-pattern 2: return HTTPException instead of raising it
@app.get("/payments/by-ref/{reference}")
def get_payment_by_ref(reference: str, db: Annotated[Session, Depends(get_db)]):
    payment = db.query(Payment).filter(Payment.reference == reference).first()
    if payment is None:
        return HTTPException(status_code=404, detail="Not found")
    return payment


# anti-pattern 4: no auth dependency on a mutating endpoint
# anti-pattern 5: raw exception message leaked in detail
@app.post("/payments/")
def create_payment(
    payment_in: PaymentCreate,
    db: Annotated[Session, Depends(get_db)],
):
    try:
        payment = Payment(
            amount=payment_in.amount,
            currency=payment_in.currency,
            card_token=payment_in.card_token,
        )
        db.add(payment)
        db.commit()
        db.refresh(payment)
        return payment
    except Exception as exc:
        raise HTTPException(status_code=400, detail=str(exc))


# anti-pattern 4 (second instance): DELETE with no auth
@app.delete("/payments/{payment_id}")
def cancel_payment(payment_id: int, db: Annotated[Session, Depends(get_db)]):
    payment = db.query(Payment).filter(Payment.id == payment_id).first()
    if payment is None:
        raise HTTPException(status_code=404, detail="Not found")
    db.delete(payment)
    db.commit()
    return {"status": "cancelled"}
