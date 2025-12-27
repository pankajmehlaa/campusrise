import { Request, Response, NextFunction } from 'express';
import jwt from 'jsonwebtoken';
import { config } from '../config.js';

const JWT_SECRET = process.env.JWT_SECRET || 'change-me-secret';

export interface AuthPayload {
  sub: string;
  role: 'admin' | 'manager' | 'viewer';
  campusId?: string | null;
}

declare module 'express-serve-static-core' {
  interface Request {
    auth?: AuthPayload;
  }
}

export function requireAuth(req: Request, res: Response, next: NextFunction) {
  const header = req.headers.authorization;
  if (!header) return res.status(401).json({ message: 'Unauthorized' });
  const token = header.replace('Bearer ', '').trim();
  try {
    const decoded = jwt.verify(token, JWT_SECRET) as AuthPayload;
    req.auth = decoded;
    return next();
  } catch (_) {
    return res.status(401).json({ message: 'Invalid token' });
  }
}

export function requireRole(roles: Array<AuthPayload['role']>) {
  return (req: Request, res: Response, next: NextFunction) => {
    if (!req.auth) return res.status(401).json({ message: 'Unauthorized' });
    if (!roles.includes(req.auth.role)) return res.status(403).json({ message: 'Forbidden' });
    return next();
  };
}

export function issueToken(payload: AuthPayload) {
  return jwt.sign(payload, JWT_SECRET, { expiresIn: '7d' });
}
