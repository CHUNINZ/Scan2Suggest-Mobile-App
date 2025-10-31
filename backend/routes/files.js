const express = require('express');
const { openDownloadStream, findFile } = require('../services/gridfsService');

const router = express.Router();

// GET /files/:id -> streams file from GridFS
router.get('/:id', async (req, res) => {
  try {
    const file = await findFile(req.params.id);
    if (!file) return res.status(404).end();

    res.setHeader('Content-Type', file.contentType || 'application/octet-stream');
    res.setHeader('Cache-Control', 'public, max-age=604800');
    res.setHeader('Cross-Origin-Resource-Policy', 'cross-origin');
    res.setHeader('Access-Control-Allow-Origin', '*');

    const stream = openDownloadStream(req.params.id);
    stream.on('error', () => res.status(404).end());
    stream.pipe(res);
  } catch (e) {
    console.error('Error serving file from GridFS:', e);
    res.status(404).end();
  }
});

module.exports = router;


