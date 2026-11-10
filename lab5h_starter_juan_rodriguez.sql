/* ==========================================================================
   lab5h_starter.sql
   CIS 4720 Database Management and SQL
   In Class Lab 5h, Variables and Decisions

   WHAT THIS FILE IS
   Lab 5g finished, plus a numbered heading for every step of Lab 5h waiting
   to be filled in. Starting from this file means it does not matter how
   Lab 5g went. Everyone begins from the same place.

   WHAT IT ALREADY BUILDS
     1. students, test_scores, attendance, the student_scores view
     2. The calculate_gpa function and the two Lab 5e triggers
     3. The Lab 5f procedures: list_students, student_report, scores_for_test
     4. The Lab 5g procedures: add_score, record_attendance, remove_score,
        and every call you made in Lab 5g that worked

   HOW TO RUN IT
   One statement at a time. Put the cursor on it and press Ctrl + E twice.
   Anything that runs from CREATE down to END (a function, a trigger or a
   procedure) is ONE statement, however many semicolons are inside it.
   Select the whole block and run the selection. No DELIMITER lines.

   LABELING AND COMMENTING IS REQUIRED
   Above every statement you write, put a short comment in your own words
   saying what it does. The comments are graded.

   SESSION VARIABLES (the ones that start with @)
   A session variable lasts only as long as your connection. When a step
   has a CALL followed by SELECT @something, select BOTH lines and run them
   together as one selection, so they are sure to use the same connection.
   ========================================================================== */


-- =================================================================
-- SETUP. Run these three first, one at a time, while you are still
-- connected to information_schema.
-- =================================================================

-- every schema on this server. cis_students_db will not be in the list yet.
show databases;

-- make yours. IF NOT EXISTS means it is safe to run twice.
create database if not exists cis_students_db;

-- switch into it, so everything below lands in the right place.
use cis_students_db;

-- SELECT DATABASE();is


-- ==================================================================
-- FROM LAB 5D. students. student_id is a surrogate key the server fills in.
-- ==================================================================
CREATE TABLE students (
    student_id INT AUTO_INCREMENT PRIMARY KEY,
    first_name VARCHAR(40) NOT NULL,
    last_name  VARCHAR(40) NOT NULL,
    gpa        FLOAT(4,2)
);
INSERT INTO students VALUES (NULL,'Jenna','Wilson',NULL);
INSERT INTO students VALUES (NULL,'Robert','Reese',NULL);
INSERT INTO students VALUES (NULL,'Maria Elena','Jimenez',NULL);
INSERT INTO students VALUES (NULL,'Inder','Singh',NULL);
INSERT INTO students (first_name,last_name) VALUES ('Rita','Nunez');
INSERT INTO students (first_name,last_name) VALUES ('James','Toor');

-- ==================================================================
-- James was student 6. Deleting him is why the counter says 7.
-- ==================================================================
DELETE FROM students WHERE first_name = 'James' AND last_name = 'Toor';

-- ==================================================================
-- FROM LAB 5D. test_scores, linked to students by a foreign key.
-- ==================================================================
CREATE TABLE test_scores (
    test_score_id INT AUTO_INCREMENT PRIMARY KEY,
    test_name     VARCHAR(20) NOT NULL,
    student_id    INT NOT NULL,
    score         FLOAT,
    FOREIGN KEY (student_id) REFERENCES students(student_id)
);
INSERT INTO test_scores VALUES (NULL,'quiz1',1,90),(NULL,'quiz1',2,85),(NULL,'quiz1',3,95),
 (NULL,'quiz2',1,80),(NULL,'quiz2',2,72),(NULL,'quiz2',3,88),(NULL,'quiz2',4,91),
 (NULL,'quiz3',2,95),(NULL,'quiz3',3,94),(NULL,'quiz3',4,74);

-- ==================================================================
-- FROM LAB 5D. The student_scores view.
-- ==================================================================
CREATE VIEW student_scores AS
SELECT s.student_id,
       CONCAT(s.first_name, ' ', s.last_name) AS student_name,
       t.test_name,
       t.score
FROM students s
LEFT OUTER JOIN test_scores t ON s.student_id = t.student_id;

-- ==================================================================
-- FROM LAB 5D. The calculate_gpa function. Select the whole block from
-- CREATE FUNCTION down to END and run the selection.
-- ==================================================================
CREATE FUNCTION calculate_gpa(p_student_id INT)
RETURNS DECIMAL(4,2)
DETERMINISTIC
READS SQL DATA
BEGIN
    DECLARE v_gpa DECIMAL(4,2);

    SELECT ROUND(AVG(score), 2)
    INTO v_gpa
    FROM test_scores
    WHERE student_id = p_student_id
      AND score IS NOT NULL;

    RETURN IFNULL(v_gpa, 0.00);
END;

-- ==================================================================
-- Fill in every gpa using the function.
-- ==================================================================
UPDATE students SET gpa = calculate_gpa(student_id);

-- ==================================================================
-- FROM LAB 5E. attendance, with its surrogate key starting at 500.
-- ==================================================================
CREATE TABLE attendance (
    attendance_id INT AUTO_INCREMENT PRIMARY KEY,
    student_id    INT NOT NULL,
    attended_on   DATE,
    status        VARCHAR(10),
    FOREIGN KEY (student_id) REFERENCES students(student_id)
) AUTO_INCREMENT = 500;
INSERT INTO attendance (student_id, attended_on, status) VALUES (1,'2026-10-05','present');
INSERT INTO attendance (student_id, attended_on, status) VALUES (2,'2026-10-05','absent');
INSERT INTO attendance (student_id, attended_on, status) VALUES (3,'2026-10-06','present');

-- ==================================================================
-- FROM LAB 5E. The BEFORE INSERT trigger. Select the whole block and run the selection.
-- ==================================================================
CREATE TRIGGER trg_attendance_before_insert
BEFORE INSERT ON attendance
FOR EACH ROW
BEGIN
    IF NEW.attended_on IS NULL THEN
        SET NEW.attended_on = CURDATE();
    END IF;
    SET NEW.status = UPPER(NEW.status);
END;

-- ==================================================================
-- FROM LAB 5E. The AFTER DELETE trigger. Select the whole block and run the selection.
-- ==================================================================
CREATE TRIGGER trg_scores_after_delete
AFTER DELETE ON test_scores
FOR EACH ROW
BEGIN
    UPDATE students
    SET gpa = calculate_gpa(OLD.student_id)
    WHERE student_id = OLD.student_id;
END;

-- ==================================================================
-- FROM LAB 5E Step 9. The row the BEFORE trigger filled in. It becomes 503.
-- ==================================================================
INSERT INTO attendance (student_id, status) VALUES (4,'present');

-- ==================================================================
-- FROM LAB 5F Step 6. list_students, highest gpa first.
-- ==================================================================
CREATE PROCEDURE list_students()
BEGIN
    SELECT student_id, first_name, last_name, gpa
    FROM students
    ORDER BY gpa DESC;
END;

-- ==================================================================
-- FROM LAB 5F Step 4. student_report.
-- ==================================================================
CREATE PROCEDURE student_report(IN p_student_id INT)
BEGIN
    SELECT student_name, test_name, score
    FROM student_scores
    WHERE student_id = p_student_id;
END;

-- ==================================================================
-- FROM LAB 5F Step 7. scores_for_test.
-- ==================================================================
CREATE PROCEDURE scores_for_test(IN p_test_name VARCHAR(20))
BEGIN
    SELECT student_name, score
    FROM student_scores
    WHERE test_name = p_test_name
    ORDER BY score DESC;
END;

-- ==================================================================
-- FROM LAB 5G Step 3. add_score. Select the whole block.
-- ==================================================================
CREATE PROCEDURE add_score(IN p_test_name VARCHAR(20),
                           IN p_student_id INT,
                           IN p_score FLOAT)
BEGIN
    INSERT INTO test_scores (test_name, student_id, score)
    VALUES (p_test_name, p_student_id, p_score);

    UPDATE students
    SET gpa = calculate_gpa(p_student_id)
    WHERE student_id = p_student_id;
END;

-- ==================================================================
-- FROM LAB 5G Step 4. Rita's first score and Jenna's quiz4.
-- ==================================================================
CALL add_score('quiz4', 5, 88);
CALL add_score('quiz4', 1, 100);

-- ==================================================================
-- FROM LAB 5G Step 5. record_attendance. Select the whole block.
-- ==================================================================
CREATE PROCEDURE record_attendance(IN p_student_id INT,
                                   IN p_status VARCHAR(10))
BEGIN
    INSERT INTO attendance (student_id, status)
    VALUES (p_student_id, p_status);
END;

-- ==================================================================
-- FROM LAB 5G Step 6. Becomes attendance row 504.
-- ==================================================================
CALL record_attendance(2, 'absent');

-- ==================================================================
-- FROM LAB 5G Step 7. remove_score. Select the whole block.
-- ==================================================================
CREATE PROCEDURE remove_score(IN p_student_id INT,
                              IN p_test_name VARCHAR(20))
BEGIN
    DELETE FROM test_scores
    WHERE student_id = p_student_id
      AND test_name = p_test_name;
END;

-- ==================================================================
-- FROM LAB 5G Step 8. Jenna back to 85.00.
-- ==================================================================
CALL remove_score(1, 'quiz4');

-- ==================================================================
-- FROM LAB 5G Step 9. The minus 20 that got in, and the cleanup.
-- ==================================================================
CALL add_score('quiz5', 4, -20);
CALL remove_score(4, 'quiz5');


-- ======================================================================
-- CHECKS. These only read, so they are safe to run again any time.
-- Highest gpa first: 92.33, 88.00, 85.00, 84.00, 82.50.
-- attendance should show ids 500 to 504.
-- ======================================================================

CALL list_students();
SELECT * FROM attendance;


-- ######################################################################
-- YOUR LAB 5H WORK STARTS BELOW THIS LINE
--
-- LABELING AND COMMENTING IS REQUIRED. It is worth a full point.
--
-- You write Steps 4, 7 and 10 yourself. Steps 6, 8 and 9 are skeletons
-- with gaps for you to fill. Steps 3 and 5 are printed in the handout.
-- ######################################################################


-- =================================================================
-- STEP 3. Session variables
--
-- Copy these from the handout and run them.
-- =================================================================

-- Create a session variable and display its value.
SET @passing = 80;
SELECT @passing;

-- Find scores below the passing value.
SELECT student_name, test_name, score
FROM student_scores
WHERE score < @passing;

-- Display a session variable that has not been set.
SELECT @never_set;

-- Count the students and store the result in a variable.
SELECT COUNT(*) INTO @how_many FROM students;
SELECT @how_many;


-- =================================================================
-- STEP 4. Session variables on your own
-- =================================================================

-- Find the highest score on quiz3.
SELECT MAX(score) INTO @top
FROM test_scores
WHERE test_name = 'quiz3';

-- Display the highest score.
SELECT @top;

-- Set the test name to quiz3.
SET @test = 'quiz3';

-- Call the procedure using the test variable.
CALL scores_for_test(@test);

-- Set the student ID to 3.
SET @who = 3;

-- Call the procedure using the student variable.
CALL student_report(@who);


-- =================================================================
-- STEP 5. Local variables, class_stats
--
-- Copy this one from the handout. Then try the SELECT that fails.
-- =================================================================

-- Create a procedure to show class statistics.
CREATE PROCEDURE class_stats()
BEGIN
    -- Declare local variables.
    DECLARE v_students INT DEFAULT 0;
    DECLARE v_scores INT DEFAULT 0;
    DECLARE v_average DECIMAL(5,2);

    -- Count the students.
    SELECT COUNT(*) INTO v_students FROM students;

    -- Count the scores and calculate the average.
    SELECT COUNT(*), ROUND(AVG(score), 2)
    INTO v_scores, v_average
    FROM test_scores;

    -- Display the class statistics.
    SELECT v_students AS students, v_scores AS scores,
           v_average AS class_average;
END;

-- Call the procedure to display the results.
CALL class_stats();

-- Check if the local variable is accessible outside the procedure.
SELECT v_students;
-- Error 1054: Local variable cannot be accessed outside the procedure.


-- =================================================================
-- STEP 6. An OUT parameter, count_scores
--
-- Copy the skeleton and write the SELECT ... INTO.
-- =================================================================

-- Create a procedure to count a student's test scores.
CREATE PROCEDURE count_scores(IN p_student_id INT, OUT p_count INT)
BEGIN
    -- Count the student's scores and store the result.
    SELECT COUNT(*) INTO p_count
    FROM test_scores
    WHERE student_id = p_student_id;
END;

-- Count the scores for student 3.
CALL count_scores(3, @n);
SELECT @n;

-- Count the scores for student 5.
CALL count_scores(5, @n);
SELECT @n;

-- Count the scores for student 9.
CALL count_scores(9, @n);
SELECT @n;

-- Test the OUT parameter with a fixed value.
CALL count_scores(3,5);
-- Error 1414: The OUT parameter requires a variable.


-- =================================================================
-- STEP 7. When a local variable is too small
--
-- Most of this step is yours. Put each error number in a comment.
-- =================================================================

-- Add Ana Lopez as a new student.
INSERT INTO students (first_name, last_name)
VALUES ('Ana', 'Lopez');

-- Check Ana's student ID.
SELECT student_id, first_name, last_name
FROM students
WHERE first_name = 'Ana' AND last_name = 'Lopez';

-- Add a quiz1 score of 100 for Ana.
CALL add_score('quiz1', 7, 100);
-- Error 1264: The value is too large for v_gpa.

-- Check Ana's test scores.
SELECT * FROM test_scores
WHERE student_id = 7;

-- Check Ana's GPA.
SELECT * FROM students
WHERE student_id = 7;

-- Drop the existing calculate_gpa function.
DROP FUNCTION IF EXISTS calculate_gpa;

-- Recreate the function to allow a GPA of 100.00.
CREATE FUNCTION calculate_gpa(p_student_id INT)
RETURNS DECIMAL(5,2)
DETERMINISTIC
READS SQL DATA
BEGIN
    DECLARE v_gpa DECIMAL(5,2);

    SELECT ROUND(AVG(score), 2)
    INTO v_gpa
    FROM test_scores
    WHERE student_id = p_student_id
        AND score IS NOT NULL;

    RETURN IFNULL(v_gpa, 0.00);
END;

-- Update Ana's GPA using the corrected function.
UPDATE students
SET gpa = calculate_gpa(7)
WHERE student_id = 7;

-- Error 1264: The GPA value is too large for the column.

-- Change the GPA column to allow 100.00.
ALTER TABLE students
MODIFY gpa DECIMAL(5,2);

-- Update Ana's GPA.
UPDATE students
SET gpa = calculate_gpa(7)
WHERE student_id = 7;

-- List students by GPA.
CALL list_students();


-- =================================================================
-- STEP 8. IF, ELSEIF and ELSE, student_standing
--
-- Copy the skeleton and write the IF block.
-- =================================================================


-- Create a procedure to check a student's standing.
CREATE PROCEDURE student_standing(IN p_student_id INT,
                                  OUT p_standing VARCHAR(20))
BEGIN
    -- Declare a variable to store the GPA.
    DECLARE v_gpa DECIMAL(5,2);

    -- Get the student's GPA.
    SELECT gpa
    INTO v_gpa
    FROM students
    WHERE student_id = p_student_id;

    -- Determine the student's standing.
    IF v_gpa IS NULL THEN
        SET p_standing = 'No such student';
    ELSEIF v_gpa >= 90 THEN
        SET p_standing = 'Honors';
    ELSEIF v_gpa >= 85 THEN
        SET p_standing = 'Good standing';
    ELSE
        SET p_standing = 'Needs support';
    END IF;
END;

-- Check student 7.
CALL student_standing(7, @standing);
SELECT @standing;

-- Check student 3.
CALL student_standing(3, @standing);
SELECT @standing;

-- Check student 1.
CALL student_standing(1, @standing);
SELECT @standing;

-- Check student 4.
CALL student_standing(4, @standing);
SELECT @standing;

-- Check student 9.
CALL student_standing(9, @standing);
SELECT @standing;

-- SELECT @standing AS student_standing;


-- =================================================================
-- STEP 9. Rebuild add_score so it checks the score
--
-- Write the DROP. Copy the skeleton and fill the two gaps.
-- =================================================================

-- Drop the existing add_score procedure.
DROP PROCEDURE IF EXISTS add_score;

-- Create a procedure to check and add valid scores.
CREATE PROCEDURE add_score(IN p_test_name VARCHAR(20),
                           IN p_student_id INT,
                           IN p_score FLOAT)
BEGIN
    -- Check if the score is valid.
    IF p_score < 0 OR p_score > 100 THEN
        SELECT 'Score must be between 0 and 100' AS message;
    ELSE
        -- Insert the score into test_scores.
        INSERT INTO test_scores (test_name, student_id, score)
        VALUES (p_test_name, p_student_id, p_score);

        -- Update the student's GPA.
        UPDATE students
        SET gpa = calculate_gpa(p_student_id)
        WHERE student_id = p_student_id;
    END IF;
END;

-- Test a negative score for student 4.
CALL add_score('quiz5', 4, -20);

-- Test a score above 100 for student 4.
CALL add_score('quiz5', 4, 120);

-- Add a valid score for student 2.
CALL add_score('quiz5', 2, 91);

-- Check Robert's updated GPA.
-- SELECT student_id, first_name, last_name, gpa
-- FROM students
-- WHERE student_id = 2;


-- =================================================================
-- STEP 10. Rebuild record_attendance so it checks the student
--
-- Yours from start to finish. The handout walks you through it.
-- =================================================================

-- Drop the existing record_attendance procedure.
DROP PROCEDURE IF EXISTS record_attendance;

-- Create a procedure to check and record attendance.
CREATE PROCEDURE record_attendance(IN p_student_id INT,
                                   IN p_status VARCHAR(20))
BEGIN
    -- Declare a variable to check if the student exists.
    DECLARE v_found INT DEFAULT 0;

    -- Count the matching student.
    SELECT COUNT(*) INTO v_found
    FROM students
    WHERE student_id = p_student_id;

    -- Check if the student exists.
    IF v_found = 0 THEN
        SELECT 'No such student' AS message;
    ELSE
        -- Insert the attendance record.
        INSERT INTO attendance (student_id, status)
        VALUES (p_student_id, p_status);
    END IF;
END;

-- Test attendance for student 9.
CALL record_attendance(9, 'present');

-- Record late attendance for student 3.
CALL record_attendance(3, 'late');

-- Check the attendance records.
SELECT * FROM attendance;


-- =================================================================
-- STEP 11 and 12. Push to GitHub and submit the URL
--
-- Nothing to write here. Follow the handout.
-- =================================================================

-- your comment goes here
-- your statements go here
