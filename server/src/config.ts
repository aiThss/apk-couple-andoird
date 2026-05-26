import path from 'node:path';
import { fileURLToPath } from 'node:url';
import dotenv from 'dotenv';

dotenv.config();

const rootDir = path.resolve(path.dirname(fileURLToPath(import.meta.url)), '..');

function readEnv(name: string, fallback?: string): string {
  const value = process.env[name] ?? fallback;
  if (!value) {
    throw new Error(`Missing required env ${name}`);
  }
  return value;
}

export const config = {
  nodeEnv: process.env.NODE_ENV ?? 'development',
  port: Number(process.env.PORT ?? 8080),
  mongoUri: readEnv('MONGODB_URI', 'mongodb://localhost:27017/couple_snap'),
  jwtSecret: readEnv('JWT_SECRET', 'dev-only-change-this-secret'),
  corsOrigin: process.env.CORS_ORIGIN ?? '*',
  publicBaseUrl: process.env.PUBLIC_BASE_URL,
  uploadDir: path.resolve(rootDir, process.env.UPLOAD_DIR ?? 'uploads'),
  adminEmail: readEnv('ADMIN_EMAIL', 'admin@couplesnap.local').toLowerCase(),
  adminPassword: readEnv('ADMIN_PASSWORD', 'change-me-now'),
};
