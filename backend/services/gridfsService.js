const mongoose = require('mongoose');
const { GridFSBucket, ObjectId } = require('mongodb');

function getBucket() {
  const db = mongoose.connection.db;
  if (!db) throw new Error('MongoDB not connected');
  return new GridFSBucket(db, { bucketName: 'uploads' });
}

async function saveBuffer(buffer, filename, contentType) {
  const bucket = getBucket();
  return await new Promise((resolve, reject) => {
    const uploadStream = bucket.openUploadStream(filename, {
      contentType: contentType || 'application/octet-stream',
    });
    uploadStream.on('error', reject);
    uploadStream.on('finish', (file) => resolve(file._id));
    uploadStream.end(buffer);
  });
}

function openDownloadStream(id) {
  const bucket = getBucket();
  const objectId = typeof id === 'string' ? new ObjectId(id) : id;
  return bucket.openDownloadStream(objectId);
}

async function findFile(id) {
  const db = mongoose.connection.db;
  const files = db.collection('uploads.files');
  const objectId = typeof id === 'string' ? new ObjectId(id) : id;
  return await files.findOne({ _id: objectId });
}

module.exports = { saveBuffer, openDownloadStream, findFile };


