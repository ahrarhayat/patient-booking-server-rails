import { test, expect } from "@playwright/test";
import { authHeaders, loginAsAdmin } from "../helpers/auth";
import { slotRangeQuery } from "../helpers/dates";

const DEFAULT_CLINICIAN_NAME =
  process.env.DEFAULT_CLINICIAN_NAME ?? "Dr. Sam Clinician";
const DEFAULT_PATIENT_ID =
  process.env.DEFAULT_PATIENT_ID ?? "a0000000-0000-4000-8000-000000000001";

/**
 * GET-only regression suite against a running, seeded API.
 * Avoids POST/DELETE so tests do not populate or mutate booking data
 * (login is used only to obtain a Bearer token).
 */
test.describe("GET endpoints", () => {
  test("GET /health returns ok when database is connected", async ({
    request,
  }) => {
    const response = await request.get("/health");

    expect(response.status()).toBe(200);
    await expect(response.json()).resolves.toEqual({
      status: "ok",
      database: "connected",
    });
  });

  test("GET /clinicians lists bookable clinicians", async ({ request }) => {
    const response = await request.get("/clinicians");

    expect(response.status()).toBe(200);
    const body = (await response.json()) as Array<{
      id: string;
      name: string;
    }>;

    expect(Array.isArray(body)).toBe(true);
    expect(body.length).toBeGreaterThan(0);
    expect(body.some((c) => c.name === DEFAULT_CLINICIAN_NAME)).toBe(true);
    expect(body.every((c) => typeof c.id === "string" && typeof c.name === "string")).toBe(
      true
    );
    expect(body.every((c) => c.name !== "Admin")).toBe(true);
  });

  test("GET /clinicians/:name/slots returns available slots", async ({
    request,
  }) => {
    const { from, to } = slotRangeQuery();
    const path = `/clinicians/${encodeURIComponent(DEFAULT_CLINICIAN_NAME)}/slots`;
    const response = await request.get(path, { params: { from, to } });

    expect(response.status()).toBe(200);
    const body = (await response.json()) as Array<{
      id: string;
      clinicianId: string;
      clinicianName: string;
      startTime: string;
      endTime: string;
      isAvailable: boolean;
    }>;

    expect(Array.isArray(body)).toBe(true);
    expect(body.length).toBeGreaterThan(0);
    for (const slot of body) {
      expect(slot.clinicianName).toBe(DEFAULT_CLINICIAN_NAME);
      expect(slot.isAvailable).toBe(true);
      expect(slot.id).toBeTruthy();
      expect(slot.startTime).toBeTruthy();
      expect(slot.endTime).toBeTruthy();
    }
  });

  test("GET /clinicians/:name/slots requires from and to", async ({
    request,
  }) => {
    const path = `/clinicians/${encodeURIComponent(DEFAULT_CLINICIAN_NAME)}/slots`;
    const response = await request.get(path);

    expect(response.status()).toBe(400);
  });

  test.describe("authenticated GETs", () => {
    let token: string;

    test.beforeAll(async ({ request }) => {
      token = await loginAsAdmin(request);
    });

    test("GET /auth/me returns current clinician", async ({ request }) => {
      const response = await request.get("/auth/me", {
        headers: authHeaders(token),
      });

      expect(response.status()).toBe(200);
      const body = (await response.json()) as {
        id: string;
        name: string;
        email: string;
        role: string;
      };

      expect(body.name).toBe("Admin");
      expect(body.role).toBe("admin");
      expect(body.email).toBeTruthy();
      expect(body.id).toBeTruthy();
    });

    test("GET /auth/me rejects missing auth", async ({ request }) => {
      const response = await request.get("/auth/me");
      expect(response.status()).toBe(401);
    });

    test("GET /appointments lists appointments", async ({ request }) => {
      const response = await request.get("/appointments", {
        headers: authHeaders(token),
      });

      expect(response.status()).toBe(200);
      const body = await response.json();
      expect(Array.isArray(body)).toBe(true);
    });

    test("GET /appointments rejects missing auth", async ({ request }) => {
      const response = await request.get("/appointments");
      expect(response.status()).toBe(401);
    });

    test("GET /patients lists patients", async ({ request }) => {
      const response = await request.get("/patients", {
        headers: authHeaders(token),
      });

      expect(response.status()).toBe(200);
      const body = (await response.json()) as Array<{
        id: string;
        name: string;
        email: string;
      }>;

      expect(Array.isArray(body)).toBe(true);
      expect(body.some((p) => p.id === DEFAULT_PATIENT_ID)).toBe(true);
    });

    test("GET /patients rejects missing auth", async ({ request }) => {
      const response = await request.get("/patients");
      expect(response.status()).toBe(401);
    });

    test("GET /patients/:id/appointments lists patient appointments", async ({
      request,
    }) => {
      const response = await request.get(
        `/patients/${DEFAULT_PATIENT_ID}/appointments`,
        { headers: authHeaders(token) }
      );

      expect(response.status()).toBe(200);
      const body = await response.json();
      expect(Array.isArray(body)).toBe(true);
    });

    test("GET /patients/:id/appointments rejects missing auth", async ({
      request,
    }) => {
      const response = await request.get(
        `/patients/${DEFAULT_PATIENT_ID}/appointments`
      );
      expect(response.status()).toBe(401);
    });
  });
});
