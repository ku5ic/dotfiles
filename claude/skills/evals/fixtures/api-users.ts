import { db } from "~/server/utils/db";

export default defineEventHandler(async (event) => {
  const method = event.method;
  const apiSecret = process.env.UPSTREAM_API_SECRET;

  if (method === "GET") {
    const query = getQuery(event);
    const role = query.role as string;
    const users = await db.users.findAll({ role });
    return users;
  }

  if (method === "POST") {
    const body = await readBody(event);
    const created = await db.users.create({
      email: body.email,
      name: body.name,
      role: body.role,
      tenantId: body.tenantId,
    });

    $fetch("https://crm.example.com/contacts", {
      method: "POST",
      headers: { Authorization: `Bearer ${apiSecret}` },
      body: created,
    });

    return created;
  }

  if (method === "DELETE") {
    const id = getQuery(event).id as string;
    await db.users.delete(id);
    return { ok: true };
  }
});
