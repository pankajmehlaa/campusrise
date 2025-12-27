import { Campus } from '../models/Campus.js';

export async function listCampuses() {
  return Campus.find().sort({ name: 1 }).lean();
}

export async function createCampus(name: string) {
  const campus = new Campus({ name });
  return campus.save();
}

export async function updateCampus(id: string, name: string) {
  return Campus.findByIdAndUpdate(id, { name }, { new: true }).lean();
}

export async function deleteCampus(id: string) {
  return Campus.findByIdAndDelete(id).lean();
}
