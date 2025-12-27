import { Request, Response, NextFunction } from 'express';
import { listMenuItems, incrementLike, submitRating, createMenuItem, updateMenuItem, deleteMenuItem, copyMenuRange } from '../services/menuService.js';
import { Hall } from '../models/Hall.js';
import { z } from 'zod';

const menuQuerySchema = z.object({
  hallId: z.string(),
  date: z.string(),
});

const likeBodySchema = z.object({ delta: z.number().int().min(-1).max(1) });
const ratingBodySchema = z.object({ rating: z.number().min(0).max(5) });
const menuBodySchema = z.object({
  hallId: z.string(),
  date: z.string(),
  mealType: z.enum(['breakfast', 'lunch', 'snacks', 'dinner']),
  title: z.string().min(2),
  subtitle: z.string().min(2),
  timeRange: z.string().min(2),
});

const copyBodySchema = z.object({
  hallId: z.string(),
  fromDate: z.string(),
  toDate: z.string(),
  days: z.number().int().min(1).max(60),
});

export async function getMenu(req: Request, res: Response, next: NextFunction) {
  try {
    const parsed = menuQuerySchema.parse(req.query);
    const items = await listMenuItems(parsed.hallId, parsed.date);
    res.json(items);
  } catch (err) {
    next(err);
  }
}

export async function likeMenuItem(req: Request, res: Response, next: NextFunction) {
  try {
    const { id } = req.params;
    const body = likeBodySchema.parse(req.body);
    const updated = await incrementLike(id, body.delta);
    if (!updated) return res.status(404).json({ message: 'Menu item not found' });
    res.json(updated);
  } catch (err) {
    next(err);
  }
}

export async function rateMenuItem(req: Request, res: Response, next: NextFunction) {
  try {
    const { id } = req.params;
    const body = ratingBodySchema.parse(req.body);
    const updated = await submitRating(id, body.rating);
    if (!updated) return res.status(404).json({ message: 'Menu item not found' });
    res.json(updated);
  } catch (err) {
    next(err);
  }
}

async function ensureHallScope(hallId: string, req: Request) {
  if (req.auth?.role !== 'manager') return true;
  const hall = await Hall.findById(hallId).lean();
  if (!hall) return false;
  return hall.campusId?.toString() === req.auth?.campusId;
}

export async function createMenuItemHandler(req: Request, res: Response, next: NextFunction) {
  try {
    const body = menuBodySchema.parse(req.body);
    const allowed = await ensureHallScope(body.hallId, req);
    if (!allowed) return res.status(403).json({ message: 'Forbidden' });
    const created = await createMenuItem(body);
    res.status(201).json(created);
  } catch (err) {
    next(err);
  }
}

export async function updateMenuItemHandler(req: Request, res: Response, next: NextFunction) {
  try {
    const body = menuBodySchema.partial().parse(req.body);
    if (body.hallId) {
      const allowed = await ensureHallScope(body.hallId, req);
      if (!allowed) return res.status(403).json({ message: 'Forbidden' });
    }
    const updated = await updateMenuItem(req.params.id, body);
    if (!updated) return res.status(404).json({ message: 'Menu item not found' });
    res.json(updated);
  } catch (err) {
    next(err);
  }
}

export async function deleteMenuItemHandler(req: Request, res: Response, next: NextFunction) {
  try {
    const deleted = await deleteMenuItem(req.params.id);
    if (!deleted) return res.status(404).json({ message: 'Menu item not found' });
    res.json({ success: true });
  } catch (err) {
    next(err);
  }
}

export async function copyMenuHandler(req: Request, res: Response, next: NextFunction) {
  try {
    const body = copyBodySchema.parse(req.body);
    const allowed = await ensureHallScope(body.hallId, req);
    if (!allowed) return res.status(403).json({ message: 'Forbidden' });
    await copyMenuRange(body);
    res.json({ success: true });
  } catch (err) {
    next(err);
  }
}
