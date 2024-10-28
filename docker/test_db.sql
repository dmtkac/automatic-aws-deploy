-- Sets the search path to the schema where tables are located
SET search_path TO sample;

-- Checks if the 'Questions' table exists
DO $$
BEGIN
    IF NOT EXISTS (SELECT 1 FROM information_schema.tables WHERE table_schema = 'sample' AND table_name = 'Questions') THEN
        RAISE EXCEPTION 'Table "Questions" does not exist!';
    ELSE
        RAISE NOTICE 'Table "Questions" exists.';
    END IF;
END $$;

-- Checks if the 'Questions' table has the correct columns
DO $$
BEGIN
    -- Checks column 'id'
    IF NOT EXISTS (SELECT 1 FROM information_schema.columns WHERE table_schema = 'sample' AND table_name = 'Questions' AND column_name = 'id') THEN
        RAISE EXCEPTION 'Column "id" does not exist in "Questions" table!';
    ELSE
        RAISE NOTICE 'Column "id" exists in "Questions" table.';
    END IF;

    -- Checks column 'text'
    IF NOT EXISTS (SELECT 1 FROM information_schema.columns WHERE table_schema = 'sample' AND table_name = 'Questions' AND column_name = 'text') THEN
        RAISE EXCEPTION 'Column "text" does not exist in "Questions" table!';
    ELSE
        RAISE NOTICE 'Column "text" exists in "Questions" table.';
    END IF;

    -- Checks column 'chapterid'
    IF NOT EXISTS (SELECT 1 FROM information_schema.columns WHERE table_schema = 'sample' AND table_name = 'Questions' AND column_name = 'chapterid') THEN
        RAISE EXCEPTION 'Column "chapterid" does not exist in "Questions" table!';
    ELSE
        RAISE NOTICE 'Column "chapterid" exists in "Questions" table.';
    END IF;

    -- Checks column 'options'
    IF NOT EXISTS (SELECT 1 FROM information_schema.columns WHERE table_schema = 'sample' AND table_name = 'Questions' AND column_name = 'options') THEN
        RAISE EXCEPTION 'Column "options" does not exist in "Questions" table!';
    ELSE
        RAISE NOTICE 'Column "options" exists in "Questions" table.';
    END IF;

    -- Checks column 'multiplecorrectanswersallowed'
    IF NOT EXISTS (SELECT 1 FROM information_schema.columns WHERE table_schema = 'sample' AND table_name = 'Questions' AND column_name = 'multiplecorrectanswersallowed') THEN
        RAISE EXCEPTION 'Column "multiplecorrectanswersallowed" does not exist in "Questions" table!';
    ELSE
        RAISE NOTICE 'Column "multiplecorrectanswersallowed" exists in "Questions" table.';
    END IF;
END $$;

-- Checks if the 'Options' table exists
DO $$
BEGIN
    IF NOT EXISTS (SELECT 1 FROM information_schema.tables WHERE table_schema = 'sample' AND table_name = 'Options') THEN
        RAISE EXCEPTION 'Table "Options" does not exist!';
    ELSE
        RAISE NOTICE 'Table "Options" exists.';
    END IF;
END $$;

-- Checks if the 'Options' table has the correct columns
DO $$
BEGIN
    -- Checks column 'id'
    IF NOT EXISTS (SELECT 1 FROM information_schema.columns WHERE table_schema = 'sample' AND table_name = 'Options' AND column_name = 'id') THEN
        RAISE EXCEPTION 'Column "id" does not exist in "Options" table!';
    ELSE
        RAISE NOTICE 'Column "id" exists in "Options" table.';
    END IF;

    -- Checks column 'text'
    IF NOT EXISTS (SELECT 1 FROM information_schema.columns WHERE table_schema = 'sample' AND table_name = 'Options' AND column_name = 'text') THEN
        RAISE EXCEPTION 'Column "text" does not exist in "Options" table!';
    ELSE
        RAISE NOTICE 'Column "text" exists in "Options" table.';
    END IF;

    -- Checks column 'iscorrect'
    IF NOT EXISTS (SELECT 1 FROM information_schema.columns WHERE table_schema = 'sample' AND table_name = 'Options' AND column_name = 'iscorrect') THEN
        RAISE EXCEPTION 'Column "iscorrect" does not exist in "Options" table!';
    ELSE
        RAISE NOTICE 'Column "iscorrect" exists in "Options" table.';
    END IF;

    -- Checks column 'questionid'
    IF NOT EXISTS (SELECT 1 FROM information_schema.columns WHERE table_schema = 'sample' AND table_name = 'Options' AND column_name = 'questionid') THEN
        RAISE EXCEPTION 'Column "questionid" does not exist in "Options" table!';
    ELSE
        RAISE NOTICE 'Column "questionid" exists in "Options" table.';
    END IF;
END $$;

-- Checks the number of records in 'Questions' table
DO $$
DECLARE
    questions_count INT;
BEGIN
    SELECT COUNT(*) INTO questions_count FROM sample."Questions";
    IF questions_count != 40 THEN
        RAISE EXCEPTION 'Questions table should have 40 records but found %', questions_count;
    ELSE
        RAISE NOTICE 'Questions table has 40 records.';
    END IF;
END $$;

-- Checks the number of records in 'Options' table
DO $$
DECLARE
    options_count INT;
BEGIN
    SELECT COUNT(*) INTO options_count FROM sample."Options";
    IF options_count != 160 THEN
        RAISE EXCEPTION 'Options table should have 160 records but found %', options_count;
    ELSE
        RAISE NOTICE 'Options table has 160 records.';
    END IF;
END $$;