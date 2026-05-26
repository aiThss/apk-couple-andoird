import type { NextFunction, Request, Response } from 'express';
import { Types } from 'mongoose';
import { HttpError } from './errors.js';
import { User, type UserDocument } from './models.js';
import { verifyToken } from './tokens.js';

declare global {
  namespace Express {
    interface Request {
      user?: UserDocument;
      admin?: { email: string };
    }
  }
}

function readBearer(req: Request): string {
  const header = req.header('authorization') ?? '';
  const [scheme, token] = header.split(' ');
  if (scheme?.toLowerCase() !== 'bearer' || !token) {
    throw new HttpError(401, 'Missing bearer token');
  }
  return token;
}

export async function requireUser(req: Request, _res: Response, next: NextFunction) {
  try {
    const payload = verifyToken(readBearer(req));
    if (payload.role !== 'user' || !Types.ObjectId.isValid(payload.sub)) {
      throw new HttpError(401, 'Invalid user token');
    }

    const user = await User.findById(payload.sub);
    if (!user) {
      throw new HttpError(401, 'User no longer exists');
    }
    if (user.status === 'blocked') {
      throw new HttpError(403, 'Account is blocked');
    }

    req.user = user;
    next();
  } catch (error) {
    next(error);
  }
}

export function requireAdmin(req: Request, _res: Response, next: NextFunction) {
  try {
    const payload = verifyToken(readBearer(req));
    if (payload.role !== 'admin') {
      throw new HttpError(403, 'Admin access required');
    }
    req.admin = { email: payload.sub };
    next();
  } catch (error) {
    next(error);
  }
}
