/*
  Usage:
    NODE_ENV=development node scripts/migrate_uploads_to_gridfs.js

  Reads files referenced as "/uploads/..." in MongoDB and re-saves them into GridFS,
  updating documents to use "/files/<id>" URLs. Safe to re-run; skips missing files.
*/

const path = require('path');
const fs = require('fs');
const mongoose = require('mongoose');
require('dotenv').config({ path: path.join(__dirname, '..', '.env') });

const User = require('../models/User');
const Recipe = require('../models/Recipe');
const { saveBuffer } = require('../services/gridfsService');

function resolveLocalPath(uploadUrl) {
  // uploadUrl like "/uploads/recipes/filename.jpg"
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
    const fileId = await saveBuffer(buffer, path.basename(filePath), 'image/jpeg');
    user.profileImage = `/files/${fileId.toString()}`;
    await user.save();
    migrated++;
  }
  console.log(`Users migrated: ${migrated}, missing files: ${missing}`);
}

async function migrateRecipeImages() {
  const recipes = await Recipe.find({ $or: [
    { images: { $elemMatch: { $regex: '^/uploads/' } } },
    { 'instructions.image': { $regex: '^/uploads/' } },
    { 'scanData.originalImage': { $regex: '^/uploads/' } },
  ]});

  let migratedRefs = 0, missing = 0;

  for (const recipe of recipes) {
    // images array
    if (Array.isArray(recipe.images)) {
      const newImages = [];
      for (const img of recipe.images) {
        if (typeof img === 'string' && img.startsWith('/uploads/')) {
          const filePath = resolveLocalPath(img);
          if (!fs.existsSync(filePath)) {
            missing++;
            continue;
          }
          const buffer = fs.readFileSync(filePath);
          const fileId = await saveBuffer(buffer, path.basename(filePath), 'image/jpeg');
          newImages.push(`/files/${fileId.toString()}`);
          migratedRefs++;
        } else {
          newImages.push(img);
        }
      }
      recipe.images = newImages;
    }

    // instructions[].image
    if (Array.isArray(recipe.instructions)) {
      for (const inst of recipe.instructions) {
        if (inst && typeof inst.image === 'string' && inst.image.startsWith('/uploads/')) {
          const filePath = resolveLocalPath(inst.image);
          if (!fs.existsSync(filePath)) {
            missing++;
            continue;
          }
          const buffer = fs.readFileSync(filePath);
          const fileId = await saveBuffer(buffer, path.basename(filePath), 'image/jpeg');
          inst.image = `/files/${fileId.toString()}`;
          migratedRefs++;
        }
      }
    }

    // scanData.originalImage
    if (recipe.scanData && typeof recipe.scanData.originalImage === 'string' && recipe.scanData.originalImage.startsWith('/uploads/')) {
      const filePath = resolveLocalPath(recipe.scanData.originalImage);
      if (fs.existsSync(filePath)) {
        const buffer = fs.readFileSync(filePath);
        const fileId = await saveBuffer(buffer, path.basename(filePath), 'image/jpeg');
        recipe.scanData.originalImage = `/files/${fileId.toString()}`;
        migratedRefs++;
      } else {
        missing++;
      }
    }

    await recipe.save();
  }
  console.log(`Recipe image references migrated: ${migratedRefs}, missing files: ${missing}`);
}

async function run() {
  const mongoUri = process.env.MONGODB_URI || 'mongodb://localhost:27017/start_cooking';
  await mongoose.connect(mongoUri, { useNewUrlParser: true, useUnifiedTopology: true });
  console.log('Connected to MongoDB');
  try {
    await migrateUserProfileImages();
    await migrateRecipeImages();
  } finally {
    await mongoose.disconnect();
    console.log('Migration complete');
  }
}

run().catch(err => {
  console.error('Migration error:', err);
  process.exit(1);
});


