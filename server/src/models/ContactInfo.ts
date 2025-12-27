import { Schema, model } from 'mongoose';

const contactInfoSchema = new Schema(
  {
    email: { type: String, required: true, trim: true },
    phone: { type: String, required: true, trim: true },
    address: { type: String, required: true, trim: true },
  },
  { timestamps: true }
);

export const ContactInfo = model('ContactInfo', contactInfoSchema);
