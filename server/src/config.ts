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

function readOptionalEnv(name: string): string | undefined {
  const value = process.env[name]?.trim();
  return value ? value : undefined;
}

function readBool(name: string, fallback = false): boolean {
  const value = process.env[name]?.trim().toLowerCase();
  if (!value) return fallback;
  return ['1', 'true', 'yes', 'on'].includes(value);
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
  smtp: {
    host: readOptionalEnv('SMTP_HOST'),
    port: Number(process.env.SMTP_PORT ?? 587),
    secure: readBool('SMTP_SECURE', false),
    user: readOptionalEnv('SMTP_USER'),
    pass: readOptionalEnv('SMTP_PASS'),
    mailFrom: readOptionalEnv('MAIL_FROM') ?? 'Couple Snap <no-reply@couplesnap.local>',
  },
};
