import { Schema, model } from 'mongoose';

const campusSchema = new Schema(
  {
    name: { type: String, required: true, trim: true, unique: true },
  },
  { timestamps: true }
);

export const Campus = model('Campus', campusSchema);
