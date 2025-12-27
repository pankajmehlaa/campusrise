import { Schema, model, Types } from 'mongoose';

const hallSchema = new Schema(
  {
    name: { type: String, required: true, trim: true },
    campusId: { type: Types.ObjectId, ref: 'Campus', required: true },
  },
  { timestamps: true }
);

hallSchema.index({ campusId: 1, name: 1 }, { unique: true });

export const Hall = model('Hall', hallSchema);
