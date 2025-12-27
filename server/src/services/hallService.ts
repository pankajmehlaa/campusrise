import { Hall } from '../models/Hall.js';
import { createDefaultMenusForHall } from './menuService.js';

export async function listHalls(campusId?: string) {
  const query = campusId ? { campusId } : {};
  return Hall.find(query).sort({ name: 1 }).lean();
}

export async function createHall(name: string, campusId: string) {
  const hall = new Hall({ name, campusId });
  const saved = await hall.save();
  await createDefaultMenusForHall(saved._id.toString());
  return saved;
}

export async function updateHall(id: string, data: { name?: string; campusId?: string }) {
  const update: any = {};
  if (data.name !== undefined) update.name = data.name;
  if (data.campusId !== undefined) update.campusId = data.campusId;
  return Hall.findByIdAndUpdate(id, update, { new: true }).lean();
}

export async function deleteHall(id: string) {
  return Hall.findByIdAndDelete(id).lean();
}
