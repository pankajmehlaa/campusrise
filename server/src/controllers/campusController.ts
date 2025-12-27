import { Request, Response, NextFunction } from 'express';
import { z } from 'zod';
import { listCampuses, createCampus, updateCampus, deleteCampus } from '../services/campusService.js';

export async function getCampuses(req: Request, res: Response, next: NextFunction) {
  try {
    const campuses = await listCampuses();
    res.json(campuses);
  } catch (err) {
    next(err);
  }
}

const campusSchema = z.object({ name: z.string().min(2) });

export async function createCampusHandler(req: Request, res: Response, next: NextFunction) {
  try {
    const body = campusSchema.parse(req.body);
    const created = await createCampus(body.name);
    res.status(201).json(created);
  } catch (err) {
    next(err);
  }
}

export async function updateCampusHandler(req: Request, res: Response, next: NextFunction) {
  try {
    const body = campusSchema.parse(req.body);
    const updated = await updateCampus(req.params.id, body.name);
    if (!updated) return res.status(404).json({ message: 'Campus not found' });
    res.json(updated);
  } catch (err) {
    next(err);
  }
}

export async function deleteCampusHandler(req: Request, res: Response, next: NextFunction) {
  try {
    const deleted = await deleteCampus(req.params.id);
    if (!deleted) return res.status(404).json({ message: 'Campus not found' });
    res.json({ success: true });
  } catch (err) {
    next(err);
  }
}
