import { defineConfig } from "@playwright/test";

const baseURL = process.env.API_BASE_URL ?? "http://localhost:3003";

export default defineConfig({
  testDir: "./tests",
  fullyParallel: true,
  forbidOnly: !!process.env.CI,
  retries: process.env.CI ? 2 : 0,
  workers: process.env.CI ? 1 : undefined,
  reporter: [["list"], ["html", { open: "never" }]],
  use: {
    baseURL,
    extraHTTPHeaders: {
      Accept: "application/json",
    },
  },
  // API-only suite — no browser project needed
  projects: [{ name: "api" }],
});
