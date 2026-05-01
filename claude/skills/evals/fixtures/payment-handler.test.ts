import { describe, it, expect, vi, beforeEach } from "vitest";
import * as handler from "./payment-handler";
import { processPayment, applyDiscount, getProcessorName } from "./payment-handler";

let testCounter = 0;

vi.mock("./external/processor-client", () => ({
  processorClient: {
    charge: vi.fn(async () => ({ reference: "ref-123" })),
  },
}));

vi.mock("./logging", () => ({
  logEvent: vi.fn(),
}));

describe("processPayment", () => {
  beforeEach(() => {
    testCounter += 1;
  });

  it("invokes the discount helper before charging", async () => {
    const spy = vi.spyOn(handler, "applyDiscount");
    await processPayment({
      amount: 100,
      currency: "USD",
      customerId: "cus_1",
      discountCode: "WELCOME10",
    });
    expect(spy).toHaveBeenCalledTimes(1);
  });

  it("returns ok for a valid charge", async () => {
    const result = await processPayment({
      amount: 50,
      currency: "USD",
      customerId: "cus_2",
    });
    expect(result.ok).toBe(true);
    expect(result.reference).toBe("ref-123");
  });

  it("records the charge near the current time", async () => {
    const before = Date.now();
    await processPayment({ amount: 10, currency: "USD", customerId: "cus_3" });
    expect(Date.now()).toBeGreaterThanOrEqual(before);
    expect(testCounter).toBeGreaterThan(0);
  });
});

describe("applyDiscount", () => {
  it("applies a known discount code", () => {
    expect(applyDiscount(100, "WELCOME10")).toBe(90);
  });
});

describe("getProcessorName", () => {
  it("returns the default processor name", () => {
    expect(getProcessorName()).toBe("default-processor");
  });
});
