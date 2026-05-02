import { cookies } from "next/headers";

export const revalidate = 3600;

async function getAccountSummary(userId: string) {
  const res = await fetch(`https://api.example.com/accounts/${userId}/summary`);
  return res.json();
}

async function getPricingPlans() {
  const res = await fetch("https://api.example.com/plans", {
    cache: "force-cache",
  });
  return res.json();
}

async function getRecentActivity(userId: string) {
  const res = await fetch(
    `https://api.example.com/accounts/${userId}/activity`,
    { next: { revalidate: 60 } },
  );
  return res.json();
}

export default async function DashboardPage() {
  const cookieStore = await cookies();
  const userId = cookieStore.get("user_id")?.value;
  if (!userId) {
    return <p>Sign in to view your dashboard.</p>;
  }

  const [summary, plans, activity] = await Promise.all([
    getAccountSummary(userId),
    getPricingPlans(),
    getRecentActivity(userId),
  ]);

  return (
    <main>
      <section>
        <h1>Welcome back</h1>
        <p>Balance: {summary.balance}</p>
        <p>Current plan: {summary.planId}</p>
      </section>

      <section>
        <h2>Pricing</h2>
        <ul>
          {plans.map((plan: { id: string; name: string; price: number }) => (
            <li key={plan.id}>
              {plan.name} - ${plan.price}
            </li>
          ))}
        </ul>
      </section>

      <section>
        <h2>Recent activity</h2>
        <ul>
          {activity.map((event: { id: string; description: string }) => (
            <li key={event.id}>{event.description}</li>
          ))}
        </ul>
      </section>
    </main>
  );
}
