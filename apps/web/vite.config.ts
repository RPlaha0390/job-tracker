import { defineConfig } from "vite";
import react from "@vitejs/plugin-react";

export default defineConfig({
  plugins: [react()],
  // In `npm run dev`, forward /api to the API running on your machine.
  server: { proxy: { "/api": "http://localhost:3000" } },
});
