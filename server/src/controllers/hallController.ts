import { Request, Response, NextFunction } from 'express';
import { z } from 'zod';
import { listHalls, createHall, updateHall, deleteHall } from '../services/hallService.js';

export async function getHalls(req: Request, res: Response, next: NextFunction) {
  try {
    const { campusId } = req.query;
    const halls = await listHalls(typeof campusId === 'string' ? campusId : undefined);
    res.json(halls);
  } catch (err) {
    next(err);
  }
}

const hallSchema = z.object({
  name: z.string().min(2),
  campusId: z.string(),
});

export async function createHallHandler(req: Request, res: Response, next: NextFunction) {
  try {
    const body = hallSchema.parse(req.body);
    const campusId = req.auth?.role === 'manager' ? req.auth.campusId || body.campusId : body.campusId;
    const created = await createHall(body.name, campusId);
    res.status(201).json(created);
  } catch (err) {
    next(err);
  }
}

export async function updateHallHandler(req: Request, res: Response, next: NextFunction) {
  try {
    const body = hallSchema.partial().parse(req.body);
    if (req.auth?.role === 'manager') body.campusId = req.auth.campusId ?? body.campusId;
    const updated = await updateHall(req.params.id, body);
    if (!updated) return res.status(404).json({ message: 'Hall not found' });
    res.json(updated);
  } catch (err) {
    next(err);
  }
}

export async function deleteHallHandler(req: Request, res: Response, next: NextFunction) {
  try {
    const deleted = await deleteHall(req.params.id);
    if (!deleted) return res.status(404).json({ message: 'Hall not found' });
    res.json({ success: true });
  } catch (err) {
    next(err);
  }
}
