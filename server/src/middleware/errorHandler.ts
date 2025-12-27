import { Request, Response, NextFunction } from 'express';
import { ZodError } from 'zod';
import { MongoServerError } from 'mongodb';

export function errorHandler(err: unknown, req: Request, res: Response, next: NextFunction) {
  if (err instanceof ZodError) {
    return res.status(400).json({ message: 'Validation failed', issues: err.issues });
  }
  if (err instanceof MongoServerError && err.code === 11000) {
    return res.status(409).json({ message: 'Duplicate value', keyPattern: err.keyPattern, keyValue: err.keyValue });
  }
  console.error('Unhandled error', err);
  res.status(500).json({ message: 'Internal Server Error' });
}
