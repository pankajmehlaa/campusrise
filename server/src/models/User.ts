import { Schema, model, Types } from 'mongoose';

const userSchema = new Schema(
  {
    name: { type: String, required: true, trim: true },
    phone: { type: String, required: true, trim: true, unique: true },
    email: { type: String, trim: true, default: null },
    passwordHash: { type: String, required: true },
    role: { type: String, enum: ['admin', 'manager', 'viewer'], default: 'viewer', required: true },
    campusId: { type: Types.ObjectId, ref: 'Campus', default: null },
  },
  { timestamps: true }
);

userSchema.index({ phone: 1 }, { unique: true });
userSchema.index({ email: 1 }, { unique: true, partialFilterExpression: { email: { $exists: true, $ne: null } } });

export const User = model('User', userSchema);
