export interface Money {
  amount: number;
  currency: string;
}

export interface PaymentResult {
  id: string;
  status: "succeeded" | "failed" | "pending";
  amount: Money;
  createdAt: string;
}

export type Result<T> = { value: T } | { error: string };

const API_BASE = "https://api.payments.example.com";

function defaultCurrency() {
  return "USD";
}

export async function chargeCard(
  cardToken: string,
  amount: Money,
  metadata: any,
): Promise<Result<PaymentResult>> {
  const res = await fetch(`${API_BASE}/charges`, {
    method: "POST",
    headers: { "content-type": "application/json" },
    body: JSON.stringify({ cardToken, amount, metadata }),
  });

  const json = await res.json();
  const result = json as unknown as PaymentResult;

  if (!result.id) {
    return { error: "missing payment id in response" };
  }

  return { value: result };
}

export function mapApiResponse(raw: {
  amount: number;
  currency_code: string;
}): Money {
  // @ts-ignore
  return { amount: raw.amount, currency: raw.currency_code.toUppercase() };
}

export function formatAmount(money: Money): string {
  const prefix = money.currency === "EUR" ? "EUR " : "USD ";
  return `${prefix}${money.amount.toFixed(2)}`;
}

export function buildChargePayload(cardToken: string, amount: number) {
  return {
    cardToken,
    amount,
    currency: defaultCurrency(),
  };
}

export function isSucceeded(result: Result<PaymentResult>): boolean {
  if ("value" in result) {
    return result.value.status === "succeeded";
  }
  return false;
}
