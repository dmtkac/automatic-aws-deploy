// e2e testing

describe('Interactive Elements', () => {
  beforeEach(() => {
    // Mocks the API response for /api/questions
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
    }).as('getQuestions');

    // Visits the page and waits for the mock questions to load
    cy.visit('http://localhost:3000');
    cy.wait('@getQuestions'); // Waits for the mocked questions to load
  });

  it('should render 20 questions with 4 options each', () => {
    // Checks that there are exactly 20 questions
    cy.get('.question').should('have.length', 20);

    // Checks that there are 4 options for each question
    cy.get('.question').each((question) => {
      cy.wrap(question).find('input[type="radio"], input[type="checkbox"]').should('have.length', 4);
    });
  });

  it('should render correct input types for single and multiple correct answers', () => {
    // Checks input type based on whether multiple correct answers are allowed
    cy.get('.question').each((question, index) => {
      const isMultiple = index % 3 === 0; // Mocks logic for multiple correct answers
      cy.wrap(question).find(`input[type="${isMultiple ? 'checkbox' : 'radio'}"]`).should('exist');
    });
  });   

  it('should display the correct text for each question and option', () => {
    // Verifies that each question has correct text
    cy.get('.question').each((question, index) => {
      cy.wrap(question).find('h4').should('contain.text', `Question ${index + 1}`);
    });

    // Verifies that each question's options have the correct text
    cy.get('.question').each((question) => {
      cy.wrap(question).find('label .option-text').each((option, optionIndex) => {
        cy.wrap(option).should('contain.text', `Option ${optionIndex + 1}`);
      });
    });
  });

  it('should enable the check button when all options are selected', () => {
    // Checks one option for each of the 20 questions
    cy.get('.question').each((question) => {
      cy.wrap(question).find('input').first().check({ force: true });
    });
    // Ensures the check button is enabled after all questions have options selected
    cy.get('#check-button', { timeout: 2000 }).should('not.be.disabled');
  });  
});