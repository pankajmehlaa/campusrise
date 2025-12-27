import { Request, Response, NextFunction } from 'express';
import bcrypt from 'bcryptjs';
import { z } from 'zod';
import { findUserByPhone, createUser } from '../services/userService.js';
import { issueToken } from '../middleware/auth.js';

const loginSchema = z.object({
  phone: z.string().regex(/^\+?\d{10,15}$/),
  password: z.string().min(4),
});

const registerSchema = z.object({
  name: z.string().min(2),
  phone: z.string().regex(/^\+?\d{10,15}$/),
  password: z.string().min(6),
  role: z.enum(['admin', 'manager', 'viewer']).default('viewer'),
  campusId: z.string().optional().nullable(),
});

export async function login(req: Request, res: Response, next: NextFunction) {
  try {
    const body = loginSchema.parse(req.body);
    const user = await findUserByPhone(body.phone);
    if (!user) return res.status(401).json({ message: 'Invalid credentials' });
    const ok = await bcrypt.compare(body.password, user.passwordHash);
    if (!ok) return res.status(401).json({ message: 'Invalid credentials' });
    const token = issueToken({ sub: user.id, role: user.role as any, campusId: user.campusId?.toString() });
    res.json({ token, user: { id: user.id, name: user.name, phone: user.phone, role: user.role, campusId: user.campusId } });
  } catch (err) {
    next(err);
  }
}

export async function register(req: Request, res: Response, next: NextFunction) {
  try {
    const body = registerSchema.parse(req.body);
    const exists = await findUserByPhone(body.phone);
    if (exists) return res.status(409).json({ message: 'Phone already in use' });
    const created = await createUser(body);
    const token = issueToken({ sub: created.id, role: created.role as any, campusId: created.campusId?.toString() });
    res.status(201).json({ token, user: { id: created.id, name: created.name, phone: created.phone, role: created.role, campusId: created.campusId } });
  } catch (err) {
    next(err);
  }
}
