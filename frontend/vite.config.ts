// frontend/vite.config.ts
import { defineConfig } from 'vite'
import react from '@vitejs/plugin-react'

// https://vitejs.dev/config/
export default defineConfig({
  plugins: [react()],
  server: {
    proxy: {
      '/api': {                          // ← all /api/... calls proxy here
        target: 'http://localhost:8000', // ← local backend port
        changeOrigin: true,              // ← fixes Host header
        
      }
    }
  }
})