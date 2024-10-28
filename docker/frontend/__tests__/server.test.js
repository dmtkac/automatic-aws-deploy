// integration testing

jest.setTimeout(30000);

const fs = require('fs');
const path = require('path');
const request = require('supertest');
const app = require('../server');
const illustrationKeys = require('./illustrations.json');

// Mocks the Pool object from 'pg' to intercept all queries
jest.mock('pg', () => {
  const mPool = {
    query: jest.fn((query, params) => {
      if (query.includes('SELECT * FROM sample."Questions"')) {
        // Logs when the query for questions is executed
        console.log('Executing query: SELECT * FROM sample."Questions"');

        // Creates 20 mock questions, setting `multiplecorrectanswersallowed` based on the index
        return Promise.resolve({
          rows: Array.from({ length: 20 }, (_, i) => ({
            id: i + 1,
            text: `Question ${i + 1}`,
            chapterid: i % 10 + 1,
            multiplecorrectanswersallowed: i % 3 === 1, // Sets every 3rd question to allow multiple correct answers
          })),
        });
      } else if (query.includes('SELECT * FROM sample."Options"')) {
        // Logs when the query for options is executed
        console.log(`Executing query: SELECT * FROM sample."Options" with questionId ${params[0]}`);

        // Generates mock options with the correct number of correct options
        const questionId = params[0];
        const numOptions = questionId % 3 === 1 ? 2 : 1; // Two correct options for certain questions
        return Promise.resolve({
          rows: Array.from({ length: 2 }, (_, j) => ({
            id: questionId * 10 + j + 1,
            text: `Option ${j + 1}`,
            iscorrect: j < numOptions, // Sets the correct number of correct answers
            questionid: questionId,
          })),
        });
      }
      
      // Logs if the query doesn't match any known cases
      console.log('Query not matched. Returning empty rows.');
      return Promise.resolve({ rows: [] });
    }),
  };
  return { Pool: jest.fn(() => mPool) };
});

// Mocks the rate limiter middleware to bypass rate limiting during tests
jest.mock('express-rate-limit', () => {
  return jest.fn(() => (req, res, next) => {
    next(); // Bypasses the rate limiter for testing
  });
});

// Wraps the app in an HTTP server instance and captures the dynamically assigned port
let server;

// Lifecycle hooks to start and stop the server
beforeAll((done) => {
  server = app.listen(0, () => {
    console.log(`Server started on port ${server.address().port}`);
    done();
  });

  server.on('error', (error) => {
    console.error('Error starting the server:', error);
    done(error);
  });
});

// Final cleanup after all tests are done
afterAll((done) => {
  server?.close((error) => {
    if (error) {
      console.error('Error stopping the server:', error);
    }
    done(error);
  });
});

// Function to control request rates
function delay(ms) {
  return new Promise((resolve) => setTimeout(resolve, ms));
}

describe('GET /api/questions', () => {
  it('should fetch random questions', async () => {
    console.log('Sending GET request to /api/questions...');

    // Performs the API request with the required custom header
    const res = await request(server)
      .get('/api/questions')
      .set('X-Requested-With', 'XMLHttpRequest');

    console.log('Received response from /api/questions:', JSON.stringify(res.body, null, 2));

    // Basic status and length checks
    expect(res.statusCode).toEqual(200);
    expect(res.body).toHaveLength(20);

    // Logs total number of questions
    console.log(`Total questions received: ${res.body.length}`);

    // Validates the structure of the questions and options
    res.body.forEach((question) => {
      expect(question).toHaveProperty('Id');
      expect(question).toHaveProperty('Text');
      expect(question).toHaveProperty('ChapterId');
      expect(question).toHaveProperty('MultipleCorrectAnswersAllowed');
      expect(question).toHaveProperty('options');
      expect(Array.isArray(question.options)).toBe(true);

      // Logs options for each question
      console.log(`Options for question ${question.Id}:`, JSON.stringify(question.options, null, 2));

      // Checks that options are properly linked and formatted
      question.options.forEach((option) => {
        expect(option).toHaveProperty('Id');
        expect(option).toHaveProperty('Text');
      });

      // Checks that the number of options is between 2 and 4
      const optionsLength = question.options.length;
      expect(optionsLength).toBeGreaterThanOrEqual(2);
      expect(optionsLength).toBeLessThanOrEqual(4);

      console.log(`Question ${question.Id} has ${optionsLength} options`);
    });

    await delay(100);
  });
});

describe('Illustration Checks', () => {
  const illustrationsPath = path.join(__dirname, '../../../illustrations');

  // Checks that all illustrations listed in the JSON file exist in the illustrations folder
  illustrationKeys.forEach((key) => {
    it(`should have illustration ${key} in the illustrations folder`, async () => {
      console.log(`Checking existence of illustration: ${key}`);
      const illustrationFile = path.join(illustrationsPath, key);
      const fileExists = fs.existsSync(illustrationFile);
      console.log(`Illustration ${key} existence: ${fileExists}`);
      expect(fileExists).toBe(true);
      await delay(100);
    });
  });

  // Checks that all illustrations in the illustrations folder are listed in the JSON file
  const illustrationFiles = fs.readdirSync(illustrationsPath);
  illustrationFiles.forEach((file) => {
    it(`should have ${file} listed in illustrations.json`, () => {
      console.log(`Checking if ${file} is listed in illustrations.json...`);
      expect(illustrationKeys).toContain(file);
    });
  });
});