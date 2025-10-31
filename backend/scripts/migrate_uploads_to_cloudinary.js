/*
  Usage:
    NODE_ENV=development node scripts/migrate_uploads_to_cloudinary.js

  Uploads existing local files under backend/uploads to Cloudinary,
  and replaces DB URLs ("/uploads/...") with Cloudinary secure URLs.
*/

const path = require('path');
const fs = require('fs');
const mongoose = require('mongoose');
require('dotenv').config({ path: path.join(__dirname, '..', '.env') });

const User = require('../models/User');
const Recipe = require('../models/Recipe');
const ScanResult = require('../models/ScanResult');
const { uploadBuffer } = require('../services/cloudinaryService');

function resolveLocalPath(uploadUrl) {
  const relative = uploadUrl.replace(/^\//, '');
  return path.join(__dirname, '..', relative);
}

async function migrateUserProfileImages() {
  const users = await User.find({ profileImage: { $regex: '^/uploads/' } });
  let migrated = 0, missing = 0;
  for (const user of users) {
    const filePath = resolveLocalPath(user.profileImage);
    if (!fs.existsSync(filePath)) {
      missing++;
      continue;
    }
    const buffer = fs.readFileSync(filePath);
    const result = await uploadBuffer(buffer, 'scan2suggest/profiles');
    user.profileImage = result.secure_url;
    await user.save();
    migrated++;
  }
  console.log(`Users to Cloudinary: ${migrated}, missing files: ${missing}`);
}

async function migrateRecipeImages() {
  const recipes = await Recipe.find({ $or: [
    { images: { $elemMatch: { $regex: '^/uploads/' } } },
    { 'instructions.image': { $regex: '^/uploads/' } },
    { 'scanData.originalImage': { $regex: '^/uploads/' } },
  ]});

  let migratedRefs = 0, missing = 0;
  for (const recipe of recipes) {
    if (Array.isArray(recipe.images)) {
      const newImages = [];
      for (const img of recipe.images) {
        if (typeof img === 'string' && img.startsWith('/uploads/')) {
          const filePath = resolveLocalPath(img);
          if (!fs.existsSync(filePath)) { missing++; continue; }
          const buffer = fs.readFileSync(filePath);
          const result = await uploadBuffer(buffer, 'scan2suggest/recipes');
          newImages.push(result.secure_url);
          migratedRefs++;
        } else {
          newImages.push(img);
        }
      }
      recipe.images = newImages;
    }

    if (Array.isArray(recipe.instructions)) {
      for (const inst of recipe.instructions) {
        if (inst && typeof inst.image === 'string' && inst.image.startsWith('/uploads/')) {
          const filePath = resolveLocalPath(inst.image);
          if (!fs.existsSync(filePath)) { missing++; continue; }
          const buffer = fs.readFileSync(filePath);
          const result = await uploadBuffer(buffer, 'scan2suggest/recipes');
          inst.image = result.secure_url;
          migratedRefs++;
        }
      }
    }

    if (recipe.scanData && typeof recipe.scanData.originalImage === 'string' && recipe.scanData.originalImage.startsWith('/uploads/')) {
      const filePath = resolveLocalPath(recipe.scanData.originalImage);
      if (fs.existsSync(filePath)) {
        const buffer = fs.readFileSync(filePath);
        const result = await uploadBuffer(buffer, 'scan2suggest/scans');
        recipe.scanData.originalImage = result.secure_url;
        migratedRefs++;
      } else {
        missing++;
      }
    }

    await recipe.save();
  }
  console.log(`Recipe refs to Cloudinary: ${migratedRefs}, missing files: ${missing}`);
}

async function migrateScanResults() {
  const scanResults = await ScanResult.find({ imageUrl: { $regex: '^/uploads/' } });
  let migrated = 0, missing = 0;
  for (const scan of scanResults) {
    const filePath = resolveLocalPath(scan.imageUrl);
    if (!fs.existsSync(filePath)) {
      missing++;
      continue;
    }
    const buffer = fs.readFileSync(filePath);
    const result = await uploadBuffer(buffer, 'scan2suggest/scans');
    scan.imageUrl = result.secure_url;
    await scan.save();
    migrated++;
  }
  console.log(`Scan results to Cloudinary: ${migrated}, missing files: ${missing}`);
}

async function run() {
  const mongoUri = process.env.MONGODB_URI || 'mongodb://localhost:27017/start_cooking';
  await mongoose.connect(mongoUri, { useNewUrlParser: true, useUnifiedTopology: true });
  console.log('Connected to MongoDB');
  try {
    await migrateUserProfileImages();
    await migrateRecipeImages();
    await migrateScanResults();
  } finally {
    await mongoose.disconnect();
    console.log('Cloudinary migration complete');
  }
}

run().catch(err => {
  console.error('Cloudinary migration error:', err);
  process.exit(1);
});


