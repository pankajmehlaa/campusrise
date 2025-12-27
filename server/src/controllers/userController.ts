import { Request, Response, NextFunction } from 'express';
import { z } from 'zod';
import { createUser, listUsers, updateUser, deleteUser, findUserByPhone } from '../services/userService.js';

const createSchema = z.object({
  name: z.string().min(2),
  phone: z.string().regex(/^\+?\d{10,15}$/),
  email: z.string().email().optional().nullable(),
  password: z.string().min(6),
  role: z.enum(['admin', 'manager', 'viewer']),
  campusId: z.string().optional().nullable(),
});

const updateSchema = z.object({
  name: z.string().min(2).optional(),
  phone: z.string().regex(/^\+?\d{10,15}$/).optional(),
  email: z.string().email().optional().nullable(),
  password: z.string().min(6).optional(),
  role: z.enum(['admin', 'manager', 'viewer']).optional(),
  campusId: z.string().optional().nullable(),
});

export async function getUsers(req: Request, res: Response, next: NextFunction) {
  try {
    const users = await listUsers();
    res.json(users);
  } catch (err) {
    next(err);
  }
}

export async function createUserHandler(req: Request, res: Response, next: NextFunction) {
  try {
    const body = createSchema.parse(req.body);
    const exists = await findUserByPhone(body.phone);
    if (exists) return res.status(409).json({ message: 'Phone already in use' });
    const user = await createUser(body);
    res.status(201).json(user);
  } catch (err) {
    next(err);
  }
}

export async function updateUserHandler(req: Request, res: Response, next: NextFunction) {
  try {
    const requester = req.auth;
    if (!requester) return res.status(401).json({ message: 'Unauthorized' });

    const isAdmin = requester.role === 'admin';
    const isSelf = requester.sub === req.params.id;
    if (!isAdmin && !isSelf) return res.status(403).json({ message: 'Forbidden' });

    const body = updateSchema.parse(req.body);
    const updateData: typeof body = { ...body };

    // Non-admins can only edit their own basic info/password.
    if (!isAdmin) {
      delete (updateData as any).role;
      delete (updateData as any).campusId;
    }

    const updated = await updateUser(req.params.id, updateData);
    if (!updated) return res.status(404).json({ message: 'User not found' });
    res.json(updated);
  } catch (err) {
    next(err);
  }
}

export async function deleteUserHandler(req: Request, res: Response, next: NextFunction) {
  try {
    const deleted = await deleteUser(req.params.id);
    if (!deleted) return res.status(404).json({ message: 'User not found' });
    res.json({ success: true });
  } catch (err) {
    next(err);
  }
}
