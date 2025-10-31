const express = require('express');
const mongoose = require('mongoose');
const cors = require('cors');
const helmet = require('helmet');
const rateLimit = require('express-rate-limit');
const { createServer } = require('http');
const { Server } = require('socket.io');
require('dotenv').config();

const app = express();
const server = createServer(app);
const io = new Server(server, {
  cors: {
    origin: "*",
    methods: ["GET", "POST", "PUT", "DELETE"]
  }
});

// Import routes
const authRoutes = require('./routes/auth');
const userRoutes = require('./routes/users');
const recipeRoutes = require('./routes/recipes');
const scanRoutes = require('./routes/scan');
const uploadRoutes = require('./routes/upload');
const socialRoutes = require('./routes/social');
const notificationRoutes = require('./routes/notifications');
const filesRoutes = require('./routes/files');

// Security middleware
app.use(helmet());

// Rate limiting - More lenient for development
const limiter = rateLimit({
  windowMs: 15 * 60 * 1000, // 15 minutes
  max: 1000, // limit each IP to 1000 requests per windowMs (increased for development)
  message: {
    error: 'Too many requests from this IP, please try again later.',
    retryAfter: '15 minutes'
  },
  standardHeaders: true,
  legacyHeaders: false,
});
app.use('/api/', limiter);

// CORS configuration - Allow all origins for mobile development
app.use(cors({
  origin: function (origin, callback) {
    // Allow requests with no origin (like mobile apps or curl requests)
    if (!origin) return callback(null, true);
    
    // Allow localhost and local network origins
    const allowedOrigins = [
      'http://localhost:3000',
      'http://localhost:62423',
      'http://127.0.0.1:3000',
      'http://127.0.0.1:62423',
      'http://192.168.194.133:3000',
      'http://192.168.194.133:62423',
      'http://10.12.3.221:3000',
      'http://10.12.3.221:62423',
    ];
    
    // Allow any localhost port
    if (origin.includes('localhost') || origin.includes('127.0.0.1')) {
      return callback(null, true);
    }
    
    // Allow local network IPs
    if (origin.includes('192.168.194.133') || origin.includes('10.12.3.221')) {
      return callback(null, true);
    }
    
    // For development, allow all origins
    if (process.env.NODE_ENV !== 'production') {
      return callback(null, true);
    }
    
    // In production, check against allowed origins
    if (allowedOrigins.indexOf(origin) !== -1) {
      callback(null, true);
    } else {
      callback(new Error('Not allowed by CORS'));
    }
  },
  credentials: true,
  methods: ['GET', 'POST', 'PUT', 'DELETE', 'OPTIONS'],
  allowedHeaders: ['Content-Type', 'Authorization', 'X-Requested-With'],
  optionsSuccessStatus: 200 // Some legacy browsers choke on 204
}));

// Body parsing middleware
app.use(express.json({ limit: '10mb' }));
app.use(express.urlencoded({ extended: true, limit: '10mb' }));

// Static files (use absolute path to avoid cwd issues)
const path = require('path');
const uploadsDir = path.join(__dirname, 'uploads');
app.use('/uploads', express.static(uploadsDir, {
  fallthrough: true,
  etag: true,
  maxAge: '7d',
}));

// Back-compat: if a file under /uploads/* is missing on disk, try to stream from GridFS by filename
const { GridFSBucket } = require('mongodb');
app.get('/uploads/:type/:filename', async (req, res, next) => {
  try {
    const fsPath = path.join(uploadsDir, req.params.type, req.params.filename);
    if (fs.existsSync(fsPath)) return next(); // let static middleware serve it

    const db = mongoose.connection.db;
    if (!db) return res.status(404).end();
    const files = db.collection('uploads.files');
    const file = await files.findOne({ filename: req.params.filename });
    if (!file) return res.status(404).end();

    const bucket = new GridFSBucket(db, { bucketName: 'uploads' });
    res.setHeader('Content-Type', file.contentType || 'application/octet-stream');
    res.setHeader('Cache-Control', 'public, max-age=604800');
    bucket.openDownloadStream(file._id).on('error', () => res.status(404).end()).pipe(res);
  } catch (e) {
    return res.status(404).end();
  }
});

// Database connection
mongoose.connect(process.env.MONGODB_URI || 'mongodb://localhost:27017/start_cooking', {
  useNewUrlParser: true,
  useUnifiedTopology: true,
})
.then(() => console.log('✅ Connected to MongoDB'))
.catch(err => console.error('❌ MongoDB connection error:', err));

// Socket.IO connection handling
io.on('connection', (socket) => {
  console.log('👤 User connected:', socket.id);
  
  socket.on('join_user_room', (userId) => {
    socket.join(`user_${userId}`);
    console.log(`User ${userId} joined their room`);
  });
  
  socket.on('disconnect', () => {
    console.log('👤 User disconnected:', socket.id);
  });
});

// Make io available to routes
app.set('io', io);

// API Routes
app.use('/api/auth', require('./routes/auth'));
app.use('/api/users', require('./routes/users')); // FIXED: Added missing users route
app.use('/api/recipes', require('./routes/recipes'));
app.use('/api/scan', require('./routes/scan'));
app.use('/api/upload', require('./routes/upload')); // FIXED: Added missing upload route
app.use('/api/notifications', require('./routes/notifications'));
app.use('/api/social', require('./routes/social'));
// GridFS file streaming
app.use('/files', filesRoutes);

// Health check endpoint
app.get('/api/health', (req, res) => {
  res.status(200).json({ 
    status: 'ok', 
    message: 'Server is running',
    timestamp: new Date().toISOString(),
    uptime: process.uptime()
  });
});

// Email service test endpoint (development only)
if (process.env.NODE_ENV === 'development') {
  app.post('/api/test-email', async (req, res) => {
    try {
      const { email } = req.body;
      
      if (!email) {
        return res.status(400).json({
          success: false,
          message: 'Email address is required'
        });
      }

      const emailService = require('./services/emailService');
      const result = await emailService.sendTestEmail(email);
      
      res.json(result);
    } catch (error) {
      console.error('Test email error:', error);
      res.status(500).json({
        success: false,
        message: 'Internal server error'
      });
    }
  });

  app.get('/api/email-status', async (req, res) => {
    try {
      const emailService = require('./services/emailService');
      const result = await emailService.testConnection();
      
      res.json({
        success: true,
        emailService: result,
        configured: !!process.env.EMAIL_USER && !!process.env.EMAIL_PASS,
        environment: process.env.NODE_ENV
      });
    } catch (error) {
      console.error('Email status error:', error);
      res.status(500).json({
        success: false,
        message: 'Internal server error'
      });
    }
  });
}

// Root endpoint
app.get('/', (req, res) => {
  res.json({ 
    message: 'Scan2Suggest API Server',
    version: '1.0.0',
    endpoints: {
      auth: '/api/auth',
      users: '/api/users', 
      recipes: '/api/recipes',
      scan: '/api/scan',
      upload: '/api/upload',
      social: '/api/social',
      notifications: '/api/notifications'
    }
  });
});

// Error handling middleware
app.use((err, req, res, next) => {
  console.error('❌ Error:', err.stack);
  res.status(500).json({ 
    message: 'Something went wrong!',
    error: process.env.NODE_ENV === 'development' ? err.message : 'Internal server error'
  });
});

// 404 handler
app.use('*', (req, res) => {
  res.status(404).json({ message: 'Route not found' });
});

// Start server
const PORT = process.env.PORT || 3000;
server.listen(PORT, '0.0.0.0', () => {
  console.log(`🚀 Server running on port ${PORT}`);
  console.log(`📱 API available at http://0.0.0.0:${PORT}/api`);
  console.log('🔌 Socket.IO server running');
  console.log('📱 Mobile devices can connect using your computer\'s IP address');
  
  // Get and display all network interfaces
  try {
    const os = require('os');
    const networkInterfaces = os.networkInterfaces();
    console.log('\n📡 Available network addresses:');
    
    Object.keys(networkInterfaces).forEach((interfaceName) => {
      const interfaces = networkInterfaces[interfaceName];
      interfaces.forEach((interface) => {
        if (interface.family === 'IPv4' && !interface.internal) {
          console.log(`   ${interfaceName}: http://${interface.address}:${PORT}/api`);
        }
      });
    });
    
    console.log('\n💡 Use any of the above IP addresses in your mobile app config');
  } catch (error) {
    console.log('\n⚠️  Could not retrieve network interfaces');
    console.log('💡 Run "ifconfig" (Mac/Linux) or "ipconfig" (Windows) to find your IP address');
  }
});