// integration testing

jest.setTimeout(30000);

const request = require('supertest');
const path = require('path');
const fs = require('fs');
const illustrationKeys = require('./__tests__/illustrations.json');
const app = require('./server');

// Mocks the Pool object from 'pg' to intercept all queries
jest.mock('pg', () => {
  const mPool = {
    query: jest.fn((query, params) => {
      if (query.includes('SELECT * FROM sample."Questions"')) {
        // Creates 20 mock questions with controlled multiplecorrectanswersallowed flag
        const questions = Array.from({ length: 20 }, (_, i) => ({
          id: i + 1,
          text: `Question ${i + 1}`,
          chapterid: i % 10 + 1,
          multiplecorrectanswersallowed: i % 3 === 1, // Sets every 3rd question to allow multiple correct answers
        }));

        // Logs generated questions for debugging
        console.log('Generated mock questions:', JSON.stringify(questions, null, 2));

        return Promise.resolve({ rows: questions });
      } else if (query.includes('SELECT * FROM sample."Options"')) {
        // Generates options based on the multiplecorrectanswersallowed flag from the question
        const questionId = params[0];
        const isMultipleCorrectAllowed = questionId % 3 === 1;
        
        // Generates correct options based on the flag
        const numCorrectOptions = isMultipleCorrectAllowed ? 2 : 1;
        const options = Array.from({ length: 4 }, (_, j) => ({
          id: questionId * 10 + j + 1,
          text: `Option ${j + 1}`,
          iscorrect: j < numCorrectOptions, // Assigns correct options based on flag
          questionid: questionId,
        }));

        // Logs generated options for debugging
        console.log(`Generated options for question ${questionId}:`, JSON.stringify(options, null, 2));

        return Promise.resolve({ rows: options });
      }
      return Promise.resolve({ rows: [] });
    }),
  };
  return { Pool: jest.fn(() => mPool) };
});

const mockQuery = require('pg').Pool().query;

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

function delay(ms) {
  return new Promise((resolve) => setTimeout(resolve, ms));
}

describe('API Endpoints', () => {
  beforeEach(() => {
    mockQuery.mockClear(); // Clears the mock query calls before each test
  });

  describe('GET /api/questions', () => {
    it('should fetch random questions without triggering rate limit', async () => {
      // Performs the API request with the required custom header
      const res = await request(server)
        .get('/api/questions')
        .set('X-Requested-With', 'XMLHttpRequest');
  
      // Logs the API response body for debugging purposes
      console.log('API Response (questions):', JSON.stringify(res.body, null, 2));
  
      // Basic status and length checks
      expect(res.statusCode).toEqual(200);
      expect(res.body).toHaveLength(20);
  
      // Logs total number of questions
      console.log(`Total number of questions returned: ${res.body.length}`);
  
      // Validates the structure of the questions
      res.body.forEach((question) => {
        expect(question).toHaveProperty('Id');
        expect(question).toHaveProperty('Text');
        expect(question).toHaveProperty('ChapterId');
        expect(question).toHaveProperty('MultipleCorrectAnswersAllowed');
        expect(question).toHaveProperty('options');
        expect(Array.isArray(question.options)).toBe(true);
  
        // Logs the options for each question
        console.log(`Question ${question.Id} options:`, question.options);
  
        // Validates the structure of options
        question.options.forEach(option => {
          expect(option).toHaveProperty('Id');
          expect(option).toHaveProperty('Text');
        });
      });
  
      // Checks overall options distribution for logging and debugging purposes
      const totalAnswers = res.body.reduce(
        (acc, question) => acc + question.options.length,
        0
      );
      console.log(`Total options across all questions: ${totalAnswers}`);
      await delay(100);
    });
  });    

  // Illustration existence checks
  describe('GET /api/illustration/:key', () => {
    const illustrationsPath = path.join(__dirname, '../../illustrations');

    // Checks that all illustrations listed in the JSON file exist in the illustrations folder
    illustrationKeys.forEach((key) => {
      it(`should have illustration ${key} in the illustrations folder`, async () => {
        const illustrationFile = path.join(illustrationsPath, key);
        const fileExists = fs.existsSync(illustrationFile);
        expect(fileExists).toBe(true);
      });
    });

    // Checks that all illustrations in the folder are listed in the JSON file
    const illustrationFiles = fs.readdirSync(illustrationsPath);
    illustrationFiles.forEach((file) => {
      it(`should have ${file} listed in illustrations.json`, () => {
        expect(illustrationKeys).toContain(file);
      });
    });
  });

  describe('POST /api/check-answers', () => {
    it('should check answers correctly without triggering rate limit', async () => {
      const mockAnswers = [
        { questionId: 1, answerId: '11' },
        { questionId: 2, answerId: '21' },
      ];

      const mockCorrectAnswers = [
        { questionId: 1, correctAnswers: ['11'] },
        { questionId: 2, correctAnswers: ['21'] },
      ];

      // Logs the mock answers for debugging
      console.log('Mock answers:', JSON.stringify(mockAnswers, null, 2));

      mockQuery.mockImplementation((query, params) => {
        if (query.includes('SELECT id FROM sample."Options" WHERE "questionid" = $1 AND "iscorrect" = TRUE')) {
          return Promise.resolve({
            rows: mockCorrectAnswers
              .find((a) => a.questionId === params[0])
              .correctAnswers.map((id) => ({ id })),
          });
        }
        return Promise.resolve({ rows: [] });
      });

      const response = await request(server)
        .post('/api/check-answers')
        .send({ answers: mockAnswers })
        .set('X-Requested-With', 'XMLHttpRequest');

      // Logs the API response body for debugging
      console.log('API Response (check-answers):', JSON.stringify(response.body, null, 2));

      expect(response.status).toBe(200);
      expect(response.body).toEqual(mockCorrectAnswers);
      await delay(100);
    });
  });
});