const express = require('express');
const { openDownloadStream, findFile } = require('../services/gridfsService');

const router = express.Router();

// GET /files/:id -> streams file from GridFS
router.get('/:id', async (req, res) => {
  try {
    const file = await findFile(req.params.id);
    if (!file) return res.status(404).json({ message: 'File not found' });

    res.setHeader('Content-Type', file.contentType || 'application/octet-stream');
    res.setHeader('Cache-Control', 'public, max-age=604800');

    const stream = openDownloadStream(req.params.id);
    stream.on('error', () => res.status(404).end());
    stream.pipe(res);
  } catch (e) {
    res.status(400).json({ message: 'Invalid file id' });
  }
});

module.exports = router;


