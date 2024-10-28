const express = require('express');
const { Pool } = require('pg');
const path = require('path');
const AWS = require('aws-sdk');
const helmet = require('helmet');
const morgan = require('morgan');
const cors = require('cors');
const rateLimit = require('express-rate-limit');

const app = express();
const port = process.env.PORT || 3000;

// PostgreSQL pool setup with environment variables for configuration
const pool = new Pool({
  user: process.env.PG_USER || 'postgres',
  host: process.env.PG_HOST || 'web_app-postgres-1',
  database: process.env.PG_DATABASE || 'sample',
  password: process.env.PG_PASSWORD || 'postgres_password',
  port: process.env.PG_PORT || 5432,
});

// S3 setup with environment variables for configuration
const s3 = new AWS.S3({
  accessKeyId: process.env.AWS_ACCESS_KEY_ID,
  secretAccessKey: process.env.AWS_SECRET_ACCESS_KEY,
  region: process.env.AWS_REGION
});
const bucketName = process.env.S3_BUCKET_NAME;

// Middleware to store ban status
const userBanStatus = new Map();

// Middleware to check and apply the 24-hour ban
function banCheck(req, res, next) {
  const userIP = req.ip;

  if (userBanStatus.has(userIP)) {
    const { banUntil, bannedFor24Hours } = userBanStatus.get(userIP);

    if (banUntil > Date.now()) {
      return res.status(429).send(bannedFor24Hours ? 'Your IP address has been banned for 24 hours due to repeated excessive requests.' : 'Too many requests from this IP, please try again after 15 minutes');
    } else if (bannedFor24Hours) {
      userBanStatus.delete(userIP);
    }
  }
  next();
}

// First limiter for 15 minutes
const firstLimiter = rateLimit({
  windowMs: 50 * 1000,
  max: 50,
  handler: (req, res) => {
    const userIP = req.ip;
    let banInfo = userBanStatus.get(userIP) || { banCount: 0, bannedFor24Hours: false };

    if (banInfo.banCount >= 1) {
      // The 24-hour ban on repeated offenses
      banInfo = { banUntil: Date.now() + 24 * 60 * 60 * 1000, bannedFor24Hours: true, banCount: 0 };
      userBanStatus.set(userIP, banInfo);
      return res.status(429).send('Your IP address has been banned for 24 hours due to repeated excessive requests.');
    }

    banInfo.banUntil = Date.now() + 15 * 60 * 1000;
    banInfo.banCount += 1;
    banInfo.bannedFor24Hours = false;
    userBanStatus.set(userIP, banInfo);
    return res.status(429).send('Too many requests from this IP, please try again after 15 minutes');
  },
  skip: (req, res) => req.url.startsWith('/api/illustration')
});

// Applies rate limiter only if not in the test environment
if (process.env.NODE_ENV !== 'test') {
  app.use(firstLimiter);
}

// Applies middlewares
app.use(banCheck);

app.use(
  helmet({
    contentSecurityPolicy: {
      directives: {
        defaultSrc: ["'self'"],
        scriptSrc: ["'self'", "https://cdnjs.cloudflare.com", "https://code.jquery.com", "https://cdn.jsdelivr.net", "'unsafe-inline'"],
        styleSrc: ["'self'", "https://cdnjs.cloudflare.com", "https://cdn.jsdelivr.net", "'unsafe-inline'"],
        imgSrc: ["'self'", "data:", "blob:", "https://${S3_BUCKET_NAME}.s3.${AWS_REGION}.amazonaws.com"],
        connectSrc: ["'self'"],
        fontSrc: ["'self'", "https://cdnjs.cloudflare.com"],
        objectSrc: ["'none'"],
      },
    },
  })
);

app.use(morgan('combined'));
app.use(express.static('public'));
app.use(express.json());
app.use(cors({
  origin: 'http://localhost:${port}',
  credentials: true
}));

// Middleware to check for a custom header
function customHeaderCheck(req, res, next) {
  const customHeader = req.get('X-Requested-With');
  if (customHeader === 'XMLHttpRequest') {
    next();
  } else {
    res.status(403).send('Forbidden');
  }
}

// Custom header check middleware
app.use('/api', customHeaderCheck);

// Function to remove numbering from the question text
function removeNumbering(text) {
  return text.replace(/^\\\[\\begin{array}{ll}\s*\d+\.\s*\\\s*/ , '\\[\\begin{array}{ll}').trim();
}

// API endpoint to fetch random questions
app.get('/api/questions', async (req, res) => {
  try {
    const result = await pool.query('SELECT * FROM sample."Questions" ORDER BY RANDOM() LIMIT 20');
    const questions = await Promise.all(result.rows.map(async (question) => {
      const optionsResult = await pool.query('SELECT * FROM sample."Options" WHERE "questionid" = $1', [question.id]);
      question.options = optionsResult.rows.map(option => ({
        Id: option.id,
        Text: option.text
      }));
      return {
        Id: question.id,
        Text: removeNumbering(question.text),
        ChapterId: question.chapterid,
        MultipleCorrectAnswersAllowed: question.multiplecorrectanswersallowed,
        options: question.options
      };
    }));
    res.json(questions);
  } catch (err) {
    console.error(err);
    res.status(500).send('Server error');
  }
});

// API endpoint to fetch illustration from S3
async function fetchIllustration(key) {
  try {
    const params = {
      Bucket: bucketName,
      Key: key,
    };
    const data = await s3.getObject(params).promise();
    return data.Body;
  } catch (err) {
    console.error(err);
    throw new Error('Failed to fetch illustration');
  }
}

app.get('/api/illustration/:key', async (req, res) => {
  try {
    const illustration = await fetchIllustration(req.params.key);
    res.set('Content-Type', 'image/png');
    res.send(illustration);
  } catch (err) {
    res.status(500).send('Server error');
  }
});

// API endpoint to check answers
app.post('/api/check-answers', async (req, res) => {
  try {
    const userAnswers = req.body.answers;
    const result = await Promise.all(userAnswers.map(async answer => {
      const correctAnswersResult = await pool.query('SELECT id FROM sample."Options" WHERE "questionid" = $1 AND "iscorrect" = TRUE', [answer.questionId]);
      const correctAnswers = correctAnswersResult.rows.map(row => row.id.toString());
      return {
        questionId: answer.questionId,
        correctAnswers
      };
    }));
    res.json(result);
  } catch (err) {
    console.error(err);
    res.status(500).send('Server error');
  }
});

// Serves static files directly from the `/images` and `/plugins` directories
app.use('/images', express.static(path.join(__dirname, 'public/images')));
app.use('/plugins', express.static(path.join(__dirname, 'public/plugins')));

// Serves the index.html for the root route
app.get('*', (req, res) => {
  res.sendFile(path.resolve(__dirname, 'public', 'index.html'));
});

// Exports the app without starting the server
module.exports = app;

// Starts the server only if this file is run directly
if (require.main === module) {
  app.listen(port, () => {
    console.log(`HTTP Server running at http://localhost:${port}`);
  });
}