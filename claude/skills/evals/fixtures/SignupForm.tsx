import { useState, type FormEvent } from "react";
import { colors } from "../theme";

type StrengthScore = 0 | 1 | 2 | 3;

function scorePassword(value: string): StrengthScore {
  if (value.length >= 12 && /\d/.test(value) && /[^A-Za-z0-9]/.test(value)) return 3;
  if (value.length >= 12 && /\d/.test(value)) return 2;
  if (value.length >= 8) return 1;
  return 0;
}

export function SignupForm() {
  const [email, setEmail] = useState("");
  const [password, setPassword] = useState("");
  const score = scorePassword(password);

  const onSubmit = (event: FormEvent<HTMLFormElement>) => {
    event.preventDefault();
    fetch("/api/signup", {
      method: "POST",
      headers: { "Content-Type": "application/json" },
      body: JSON.stringify({ email, password }),
    });
  };

  return (
    <form onSubmit={onSubmit} className="flex flex-col gap-4 p-6">
      <input
        type="email"
        placeholder="Email"
        value={email}
        onChange={(event) => setEmail(event.target.value)}
        className="rounded border border-slate-300 px-3 py-2"
        style={{ color: colors.brand.text }}
      />

      <div className="flex flex-col gap-1">
        <label htmlFor="signup-password" className="text-sm font-medium">
          Password
        </label>
        <input
          id="signup-password"
          type="password"
          value={password}
          onChange={(event) => setPassword(event.target.value)}
          className="rounded border border-slate-300 px-3 py-2"
        />
        <div className="mt-1 flex gap-1">
          <span className="h-1 w-12 rounded" style={{ backgroundColor: score >= 1 ? colors.strength.weak : colors.muted }} />
          <span className="h-1 w-12 rounded" style={{ backgroundColor: score >= 2 ? colors.strength.medium : colors.muted }} />
          <span className="h-1 w-12 rounded" style={{ backgroundColor: score >= 3 ? colors.strength.strong : colors.muted }} />
        </div>
      </div>

      <button
        type="submit"
        className="rounded px-4 py-2 text-white focus:outline-none"
        style={{ backgroundColor: colors.brand.primary }}
      >
        Sign up
      </button>

      <p className="text-sm text-slate-600">
        Forgot password? <a href="#" className="text-blue-600">click here</a>
      </p>
    </form>
  );
}
