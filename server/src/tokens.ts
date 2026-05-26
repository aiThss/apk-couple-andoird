import jwt from 'jsonwebtoken';
import { config } from './config.js';

export interface TokenPayload {
  sub: string;
  role: 'user' | 'admin';
}

export function signToken(payload: TokenPayload): string {
  return jwt.sign(payload, config.jwtSecret, { expiresIn: '30d' });
}

export function verifyToken(token: string): TokenPayload {
  return jwt.verify(token, config.jwtSecret) as TokenPayload;
}
