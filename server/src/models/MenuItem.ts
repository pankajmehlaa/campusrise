import { Schema, model, Types } from 'mongoose';

const menuItemSchema = new Schema(
  {
    hallId: { type: Types.ObjectId, ref: 'Hall', required: true },
    date: { type: Date, required: true },
    mealType: {
      type: String,
      enum: ['breakfast', 'lunch', 'snacks', 'dinner'],
      required: true,
    },
    title: { type: String, required: true },
    subtitle: { type: String, required: true },
    timeRange: { type: String, required: true },
    likes: { type: Number, default: 0 },
    rating: { type: Number, default: 0 },
    ratingCount: { type: Number, default: 0 },
  },
  { timestamps: true }
);

menuItemSchema.index({ hallId: 1, date: 1, mealType: 1 }, { unique: true });

export const MenuItem = model('MenuItem', menuItemSchema);
