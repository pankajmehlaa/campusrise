import { ContactInfo } from '../models/ContactInfo.js';

const defaultContact = {
  email: 'support@campusrise.in',
  phone: '+91 9785602350',
  address: 'IIT Delhi, Hauz Khas, Delhi',
};

export async function getContactInfo() {
  let info = await ContactInfo.findOne().lean();
  if (!info) {
    info = (await ContactInfo.create(defaultContact)).toObject();
  }
  return info;
}

export async function upsertContactInfo(data: { email: string; phone: string; address: string }) {
  const existing = await ContactInfo.findOne();
  if (existing) {
    existing.email = data.email;
    existing.phone = data.phone;
    existing.address = data.address;
    await existing.save();
    return existing.toObject();
  }
  const created = await ContactInfo.create(data);
  return created.toObject();
}
