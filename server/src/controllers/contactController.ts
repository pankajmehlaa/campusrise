import { Request, Response, NextFunction } from 'express';
import { z } from 'zod';
import { getContactInfo, upsertContactInfo } from '../services/contactService.js';

export async function contact(req: Request, res: Response, next: NextFunction) {
  try {
    const info = await getContactInfo();
    if (!info) return res.status(404).json({ message: 'Contact info not found' });
    res.json(info);
  } catch (err) {
    next(err);
  }
}

const contactSchema = z.object({
  email: z.string().email(),
  phone: z.string().min(3),
  address: z.string().min(3),
});

export async function updateContact(req: Request, res: Response, next: NextFunction) {
  try {
    const body = contactSchema.parse(req.body);
    const updated = await upsertContactInfo(body);
    res.json(updated);
  } catch (err) {
    next(err);
  }
}
