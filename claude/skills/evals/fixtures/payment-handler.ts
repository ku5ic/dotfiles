import { processorClient } from "./external/processor-client";
import { logEvent } from "./logging";

export type PaymentInput = {
  amount: number;
  currency: string;
  customerId: string;
  discountCode?: string;
};

export type PaymentResult = {
  ok: boolean;
  reference?: string;
  reason?: string;
};

const KNOWN_DISCOUNTS: Record<string, number> = {
  WELCOME10: 0.1,
  SPRING25: 0.25,
  LOYALTY15: 0.15,
};

export function getProcessorName(): string {
  return "default-processor";
}

export function validateAmount(amount: number): void {
  if (Number.isNaN(amount)) {
    throw new Error("amount is NaN");
  }
  if (!Number.isFinite(amount)) {
    throw new Error("amount is not finite");
  }
  if (amount <= 0) {
    throw new Error("amount must be positive");
  }
  if (amount > 1_000_000) {
    throw new Error("amount exceeds maximum");
  }
}

export function applyDiscount(amount: number, code: string | undefined): number {
  if (!code) {
    return amount;
  }
  const rate = KNOWN_DISCOUNTS[code];
  if (rate === undefined) {
    return amount;
  }
  const discounted = amount * (1 - rate);
  return Math.round(discounted * 100) / 100;
}

export async function processPayment(input: PaymentInput): Promise<PaymentResult> {
  validateAmount(input.amount);
  if (!input.customerId) {
    return { ok: false, reason: "missing customer" };
  }

  const charge = applyDiscount(input.amount, input.discountCode);

  try {
    const response = await processorClient.charge({
      amount: charge,
      currency: input.currency,
      customerId: input.customerId,
    });
    logEvent("payment.processed", {
      customerId: input.customerId,
      charge,
    });
    return { ok: true, reference: response.reference };
  } catch (err) {
    logEvent("payment.failed", {
      customerId: input.customerId,
      charge,
      err,
    });
    return { ok: false, reason: "processor error" };
  }
}
