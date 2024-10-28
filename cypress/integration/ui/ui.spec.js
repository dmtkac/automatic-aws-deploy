// e2e testing

describe('Basic Page Elements', () => {
  beforeEach(() => {
    // Intercepts the API call to /api/questions and mocks the response with test data
    cy.intercept('GET', '/api/questions', {
      body: Array.from({ length: 20 }, (_, i) => ({
        Id: i + 1,
        Text: `Question ${i + 1}`,
        ChapterId: i % 10 + 1,
        MultipleCorrectAnswersAllowed: i % 3 === 0, // Allows multiple correct answers for some questions
        options: Array.from({ length: 4 }, (_, j) => ({
          Id: (i + 1) * 10 + j + 1,
          Text: `Option ${j + 1}`,
          iscorrect: j < (i % 3 === 0 ? 2 : 1), // Allows multiple correct answers for some questions
        })),
      })),
    }).as('getQuestions'); // Assigns alias for waiting

    // Visits the page and waits for the mock questions to load
    cy.visit('http://localhost:3000');
    cy.wait('@getQuestions'); // Waits for the mocked questions to load
  });

  it('should display the loading indicator', () => {
    // Asserts that the loading indicator is visible initially
    cy.get('#loading-indicator').should('be.visible');
  });

  it('should ensure quiz container is visible', () => {
    // Asserts that the quiz container is visible after the questions load
    cy.get('#quiz-container').should('not.have.css', 'display', 'none');
  });
});

describe('Static Elements', () => {
  beforeEach(() => {
    // Same interception before testing static elements
    cy.intercept('GET', '/api/questions', {
      body: Array.from({ length: 20 }, (_, i) => ({
        Id: i + 1,
        Text: `Question ${i + 1}`,
        ChapterId: i % 10 + 1,
        MultipleCorrectAnswersAllowed: i % 3 === 0,
        options: Array.from({ length: 4 }, (_, j) => ({
          Id: (i + 1) * 10 + j + 1,
          Text: `Option ${j + 1}`,
          iscorrect: j < (i % 3 === 0 ? 2 : 1),
        })),
      })),
    }).as('getQuestions');

    // Visits the page and waits for the mock questions to load
    cy.visit('http://localhost:3000');
    cy.wait('@getQuestions'); // Waits for the questions to load
  });

  it('should have a visible check button', () => {
    // Asserts that the check button is visible but disabled initially
    cy.get('#check-button').should('be.visible').and('be.disabled');
  });

  it('should have a refresh button hidden initially', () => {
    // Asserts that the refresh button is not visible initially
    cy.get('#refresh-button').should('not.be.visible');
  });
});