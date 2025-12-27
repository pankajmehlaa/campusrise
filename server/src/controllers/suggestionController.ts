import { Request, Response, NextFunction } from 'express';
import { z } from 'zod';

const suggestionSchema = z.object({
  hallId: z.string(),
  mealType: z.enum(['breakfast', 'lunch', 'snacks', 'dinner']),
  text: z.string().min(3),
});

export async function postSuggestion(req: Request, res: Response, next: NextFunction) {
  try {
    const body = suggestionSchema.parse(req.body);
    // Placeholder: persist suggestions if needed
    res.status(201).json({ message: 'Suggestion received', data: body });
  } catch (err) {
    next(err);
  }
}
