import { MenuItem } from '../models/MenuItem.js';

const defaultMeals = [
  { key: 'breakfast' as const, title: 'Breakfast', timeRange: '7:30 - 9:30 AM' },
  { key: 'lunch' as const, title: 'Lunch', timeRange: '12:30 - 2:30 PM' },
  { key: 'snacks' as const, title: 'Snacks', timeRange: '5:00 - 6:30 PM' },
  { key: 'dinner' as const, title: 'Dinner', timeRange: '7:30 - 9:30 PM' },
];

export async function listMenuItems(hallId: string, date: string) {
  const start = new Date(date);
  const end = new Date(start);
  end.setDate(start.getDate() + 1);

  return MenuItem.find({ hallId, date: { $gte: start, $lt: end } })
    .sort({ mealType: 1 })
    .lean();
}

export async function incrementLike(menuItemId: string, delta: number) {
  return MenuItem.findByIdAndUpdate(menuItemId, { $inc: { likes: delta } }, { new: true }).lean();
}

export async function submitRating(menuItemId: string, rating: number) {
  const doc = await MenuItem.findById(menuItemId);
  if (!doc) return null;
  const total = doc.rating * doc.ratingCount + rating;
  doc.ratingCount += 1;
  doc.rating = total / doc.ratingCount;
  await doc.save();
  return doc.toObject();
}

export async function createMenuItem(data: {
  hallId: string;
  date: string;
  mealType: 'breakfast' | 'lunch' | 'snacks' | 'dinner';
  title: string;
  subtitle: string;
  timeRange: string;
}) {
  const item = new MenuItem({
    ...data,
    date: new Date(data.date),
  });
  return item.save();
}

export async function updateMenuItem(
  id: string,
  data: Partial<{ hallId: string; date: string; mealType: 'breakfast' | 'lunch' | 'snacks' | 'dinner'; title: string; subtitle: string; timeRange: string }>
) {
  const update: any = {};
  if (data.hallId !== undefined) update.hallId = data.hallId;
  if (data.date !== undefined) update.date = new Date(data.date);
  if (data.mealType !== undefined) update.mealType = data.mealType;
  if (data.title !== undefined) update.title = data.title;
  if (data.subtitle !== undefined) update.subtitle = data.subtitle;
  if (data.timeRange !== undefined) update.timeRange = data.timeRange;
  return MenuItem.findByIdAndUpdate(id, update, { new: true }).lean();
}

export async function deleteMenuItem(id: string) {
  return MenuItem.findByIdAndDelete(id).lean();
}

export async function createDefaultMenusForHall(hallId: string, days: number = 7) {
  const start = new Date();
  start.setHours(0, 0, 0, 0);

  for (let i = 0; i < days; i++) {
    const day = new Date(start);
    day.setDate(start.getDate() + i);
    const nextDay = new Date(day);
    nextDay.setDate(day.getDate() + 1);

    for (const meal of defaultMeals) {
      await MenuItem.updateOne(
        { hallId, mealType: meal.key, date: { $gte: day, $lt: nextDay } },
        {
          $setOnInsert: {
            hallId,
            mealType: meal.key,
            date: day,
            title: meal.title,
            subtitle: 'Tap edit to add menu items',
            timeRange: meal.timeRange,
          },
        },
        { upsert: true }
      );
    }
  }
}

function startOfDay(date: Date) {
  const d = new Date(date);
  d.setHours(0, 0, 0, 0);
  return d;
}

export async function copyMenuRange(params: { hallId: string; fromDate: string; toDate: string; days: number }) {
  const { hallId, fromDate, toDate, days } = params;
  const sourceStart = startOfDay(new Date(fromDate));
  const targetStart = startOfDay(new Date(toDate));

  for (let i = 0; i < days; i++) {
    const srcDay = new Date(sourceStart);
    srcDay.setDate(sourceStart.getDate() + i);
    const srcNext = new Date(srcDay);
    srcNext.setDate(srcDay.getDate() + 1);

    const targetDay = new Date(targetStart);
    targetDay.setDate(targetStart.getDate() + i);
    const targetNext = new Date(targetDay);
    targetNext.setDate(targetDay.getDate() + 1);

    const sourceItems = await MenuItem.find({ hallId, date: { $gte: srcDay, $lt: srcNext } }).lean();

    if (sourceItems.length === 0) continue;

    const ops = sourceItems.map((src) => ({
      updateOne: {
        filter: { hallId, mealType: src.mealType, date: { $gte: targetDay, $lt: targetNext } },
        update: {
          $set: {
            hallId,
            mealType: src.mealType,
            date: targetDay,
            title: src.title ?? '',
            subtitle: (src as any).subtitle ?? '',
            timeRange: (src as any).timeRange ?? '',
            likes: 0,
            rating: 0,
            ratingCount: 0,
          },
        },
        upsert: true,
      },
    }));

    if (ops.length > 0) {
      await MenuItem.bulkWrite(ops);
    }
  }
}
