import type { APIRequestContext } from "@playwright/test";

const ADMIN_EMAIL = process.env.ADMIN_EMAIL ?? "admin@clinic.example.com";
const ADMIN_PASSWORD = process.env.ADMIN_PASSWORD ?? "admin123";

/** Login once to get a Bearer token. Does not write persistent data beyond issuing a token. */
export async function loginAsAdmin(request: APIRequestContext): Promise<string> {
  const response = await request.post("/auth/login", {
    data: { email: ADMIN_EMAIL, password: ADMIN_PASSWORD },
  });

  if (!response.ok()) {
    const body = await response.text();
    throw new Error(
      `Admin login failed (${response.status()}): ${body}. Is the server running and seeded?`
    );
  }

  const body = (await response.json()) as { token: string };
  if (!body.token) {
    throw new Error("Login response missing token");
  }

  return body.token;
}

export function authHeaders(token: string): Record<string, string> {
  return { Authorization: `Bearer ${token}` };
}
