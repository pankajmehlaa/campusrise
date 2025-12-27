import mongoose from 'mongoose';
import { config } from '../config.js';
import { Campus } from '../models/Campus.js';
import { Hall } from '../models/Hall.js';
import { MenuItem } from '../models/MenuItem.js';
import { ContactInfo } from '../models/ContactInfo.js';
import { User } from '../models/User.js';
import bcrypt from 'bcryptjs';

async function seed() {
  await mongoose.connect(config.mongoUri);

  await Promise.all([Campus.deleteMany({}), Hall.deleteMany({}), MenuItem.deleteMany({}), ContactInfo.deleteMany({}), User.deleteMany({})]);

  const campusData = [
    { name: 'Christ University Central', halls: ['Jonas Hall', 'Main Mess', 'North Mess'] },
    { name: 'Christ University Kengeri', halls: ['South Block Mess', 'Lakeview Hall'] },
    { name: 'Christ University Bannerghatta', halls: ['BG Road Mess', 'Hostel Dining'] },
    { name: 'St Josephs College', halls: ['Cloister Mess', 'Quadrangle Dining'] },
    { name: 'Mount Carmel College', halls: ['Amber Mess', 'Carmel Dining'] },
    { name: 'Indian Institute of Science', halls: ['Prakruthi Mess', 'Main Dining'] },
    { name: 'BMS College of Engineering', halls: ['BMS Central Mess', 'Tech Mess'] },
    { name: 'PES University', halls: ['EC Campus Mess', 'Hampi Hall'] },
    { name: 'RV University', halls: ['Valley Mess', 'Scholars Dining'] },
    { name: 'Dayananda Sagar University', halls: ['DSU North', 'DSU South'] },
    { name: 'MS Ramaiah Institute of Technology', halls: ['RIT Main Mess', 'Green Field Mess'] },
    { name: 'Jain University', halls: ['JGI Central Mess', 'Knowledge Park Dining'] },
    { name: 'Alliance University', halls: ['Alliance Commons', 'Law School Dining'] },
    { name: 'CMR Institute of Technology', halls: ['CMR Mess', 'Spectrum Dining'] },
    { name: 'New Horizon College', halls: ['Horizon Mess', 'Innovation Dining'] },
    { name: 'Presidency University', halls: ['Presidency Mess', 'Liberty Dining'] },
  ];

  const campuses = await Campus.insertMany(campusData.map((c) => ({ name: c.name })));

  const hallDocs = campusData.flatMap((c, index) => {
    const campusId = campuses[index]._id;
    return c.halls.map((name) => ({ name, campusId }));
  });

  const halls = await Hall.insertMany(hallDocs);

  const start = new Date();
  start.setHours(0, 0, 0, 0);

  const breakfastOptions = [
    'Idli & Vada with Sambar',
    'Masala Dosa & Coconut Chutney',
    'Poha with Sev & Jalebi',
    'Puri Bhaji with Pickle',
    'Uttapam & Tomato Chutney',
    'Upma with Banana',
    'Paratha with Curd & Achar',
  ];

  const lunchOptions = [
    'South Indian Meals (Sambar, Rasam, Poriyal)',
    'North Indian Thali (Paneer Butter Masala, Dal, Naan)',
    'Curd Rice, Lemon Rice & Fryums',
    'Veg Biryani with Raita',
    'Dal Tadka, Jeera Rice, Aloo Gobi',
    'Schezwan Fried Rice & Gobi Manchurian',
    'Rajma Chawal with Papad',
  ];

  const snackOptions = [
    'Samosa & Cutting Chai',
    'Sweet Corn & Lemon Tea',
    'Bread Pakora & Coffee',
    'Masala Maggi & Chaas',
    'Bonda & Filter Coffee',
    'Pani Puri & Jaljeera',
    'Banana Fritters & Tea',
  ];

  const dinnerOptions = [
    'Chapati, Dal Makhani, Veg Kurma',
    'Ghee Rice, Kurma, Salad',
    'Phulka, Kadai Paneer, Jeera Rice',
    'Veg Pulao, Raita, Fryums',
    'Poori, Chole, Onion Salad',
    'Tawa Paratha, Mixed Veg Curry',
    'Khichdi, Kadhi, Roasted Papad',
  ];

  const mealTypes = [
    { key: 'breakfast', title: 'Breakfast', timeRange: '7:30 - 9:30 AM', options: breakfastOptions },
    { key: 'lunch', title: 'Lunch', timeRange: '12:30 - 2:30 PM', options: lunchOptions },
    { key: 'snacks', title: 'Snacks', timeRange: '5:00 - 6:30 PM', options: snackOptions },
    { key: 'dinner', title: 'Dinner', timeRange: '7:30 - 9:30 PM', options: dinnerOptions },
  ] as const;

  const days = Array.from({ length: 7 }, (_, i) => {
    const d = new Date(start);
    d.setDate(start.getDate() + i);
    return d;
  });

  const menuItems = halls.flatMap((hall, hallIndex) => {
    return days.flatMap((day, dayIndex) => {
      return mealTypes.map((meal, mealIndex) => {
        const subtitleList = meal.options;
        const subtitle = subtitleList[(hallIndex + mealIndex + dayIndex) % subtitleList.length];
        const likes = 25 + (hallIndex * 3 + mealIndex * 2 + dayIndex) % 40;
        const rating = 3 + ((hallIndex + mealIndex + dayIndex) % 7) * 0.2;
        const ratingCount = 8 + ((hallIndex + mealIndex + dayIndex) % 10);
        return {
          hallId: hall._id,
          date: day,
          mealType: meal.key,
          title: meal.title,
          subtitle,
          timeRange: meal.timeRange,
          likes,
          rating,
          ratingCount,
        };
      });
    });
  });

  await MenuItem.insertMany(menuItems);

  await ContactInfo.create({
    email: 'support@cumeal.app',
    phone: '+91 98765 43210',
    address: 'Christ University, Bengaluru, Karnataka',
  });

  const adminHash = await bcrypt.hash('admin123', 10);
  await User.create({
    name: 'Admin',
    phone: '+919999888777',
    passwordHash: adminHash,
    role: 'admin',
  });

  await mongoose.disconnect();
  console.log('Seed data inserted');
}

seed().catch((err) => {
  console.error('Seed failed', err);
  process.exit(1);
});
