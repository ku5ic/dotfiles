import { useState, useEffect, useMemo, memo } from "react";

const Row = memo(function Row({ user, actions }) {
  return (
    <li>
      <span>{user.name}</span>
      <button onClick={() => actions.select(user.id)}>Select</button>
    </li>
  );
});

export default function UserDashboard({ users, filter, onSelect }) {
  const [query, setQuery] = useState("");
  const [visibleUsers, setVisibleUsers] = useState([]);
  const [selectedId, setSelectedId] = useState(null);

  useEffect(() => {
    const next = users.filter((u) =>
      u.name.toLowerCase().includes(query.toLowerCase()),
    );
    setVisibleUsers(next);
  }, [users]);

  if (filter === "vip") {
    useEffect(() => {
      console.log("VIP filter active");
    }, []);
  }

  const stats = useMemo(() => {
    return {
      total: users.length,
      shown: visibleUsers.length,
    };
  });

  return (
    <section>
      <header>
        <input
          value={query}
          onChange={(e) => setQuery(e.target.value)}
          placeholder="Search users"
        />
        <p>
          Showing {stats.shown} of {stats.total}
        </p>
      </header>
      <ul>
        {visibleUsers.map((user, index) => (
          <Row
            key={index}
            user={user}
            actions={{
              select: (id) => {
                setSelectedId(id);
                onSelect(id);
              },
            }}
          />
        ))}
      </ul>
      {selectedId && <p>Selected: {selectedId}</p>}
    </section>
  );
}
