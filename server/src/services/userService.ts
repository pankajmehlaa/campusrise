import bcrypt from 'bcryptjs';
import { User } from '../models/User.js';

export async function findUserByPhone(phone: string) {
  return User.findOne({ phone });
}

export async function createUser({
  name,
  phone,
  email,
  password,
  role,
  campusId,
}: {
  name: string;
  phone: string;
  email?: string | null;
  password: string;
  role: 'admin' | 'manager' | 'viewer';
  campusId?: string | null;
}) {
  const passwordHash = await bcrypt.hash(password, 10);
  const user = new User({ name, phone, email: email ?? null, passwordHash, role, campusId: campusId || null });
  return user.save();
}

export async function listUsers() {
  return User.find().lean();
}

export async function updateUser(
  id: string,
  data: Partial<{ name: string; phone: string; email: string | null; password: string; role: 'admin' | 'manager' | 'viewer'; campusId: string | null }>
) {
  const update: any = {};
  if (data.name !== undefined) update.name = data.name;
  if (data.phone !== undefined) update.phone = data.phone;
  if (data.email !== undefined) update.email = data.email ?? null;
  if (data.role !== undefined) update.role = data.role;
  if (data.campusId !== undefined) update.campusId = data.campusId;
  if (data.password !== undefined) update.passwordHash = await bcrypt.hash(data.password, 10);

  return User.findByIdAndUpdate(id, update, { new: true }).lean();
}

export async function deleteUser(id: string) {
  return User.findByIdAndDelete(id).lean();
}
