-- student check constraints

ALTER TABLE student ADD CONSTRAINT grad_undergrad_class
CHECK (
    student_type = 'grad' AND class IS NULL
    OR
    student_type = 'under_grad' AND class >= 1 AND class <= 4 AND class IS NOT NULL
);

ALTER TABLE student ADD CONSTRAINT stu_type_check
CHECK(
    student_type IN ('grad', 'under_grad')
);

-- teacher check constraints

ALTER TABLE teacher ADD CONSTRAINT tea_rank_type
CHECK (
    teacher_type = 'faculty' AND rank IS NOT NULL AND rank IN ('Prof', 'Dr', 'Assoc Prof', 'Lecturer')
    OR
    teacher_type = 'assistant' AND rank IS NULL
);

ALTER TABLE teacher ADD CONSTRAINT tea_type_check
CHECK(
    teacher_type IN ('faculty', 'assistant'));

-- submits constraints

ALTER TABLE submits ADD CONSTRAINT submit_point 
CHECK( 
    grade>=0 and grade<=100
);

-- follow constraints

ALTER TABLE follow
ADD CONSTRAINT follow_const
CHECK (follower_id <> following_id);

-- messages constraints

ALTER TABLE messages
ADD CONSTRAINT message_const
CHECK (user1_and_company_id <> user2_and_company_id);

-- connection constraint

ALTER TABLE connections
ADD CONSTRAINT conn_const
CHECK (user1_id <> user2_id);

-- deny insert to COMPNAY without comp_acc_flag = true

CREATE OR REPLACE FUNCTION comp_flag_check()
RETURNS TRIGGER
AS
$$
DECLARE cf BOOLEAN;
BEGIN
    cf = user_table.comp_acc_flag FROM user_table WHERE user_table.user_id = NEW.user_id;
    IF (NOT cf) THEN
        RAISE EXCEPTION 'Company Account is False. Can not create COMPANY!';
    END IF;
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER comp_flag_isf
BEFORE INSERT
ON company
FOR EACH ROW
EXECUTE PROCEDURE comp_flag_check();

-- Can't manage course from department that teacher is not employed by

CREATE OR REPLACE FUNCTION employs_managed()
RETURNS TRIGGER
AS
$$
DECLARE tea_dept RECORD;
DECLARE tea_course RECORD;
BEGIN
    SELECT department_id INTO tea_dept FROM employs WHERE NEW.user_id = employs.user_id;
    SELECT course_id INTO tea_course FROM course WHERE course.dept_id = tea_dept.department_id AND NEW.course_id = course.course_id;
    IF NOT EXISTS (SELECT 1 FROM course WHERE NEW.course_id = tea_course.course_id) THEN
        RAISE EXCEPTION 'Can not manage course from department that teacher is not employed by';
    END IF;
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER check_if_tea_employs_managed
BEFORE INSERT
ON manages
FOR EACH ROW
EXECUTE PROCEDURE employs_managed();

-- Block student flag being changed from false to true while teacher flag is true

CREATE FUNCTION tea_stu_flag()
RETURNS TRIGGER
AS
$$
BEGIN
    IF (OLD.tea_flag AND NEW.tea_flag AND NOT OLD.stu_flag AND NEW.stu_flag) THEN
        RAISE EXCEPTION 'Can Not Demote From Faculty To Assistant';
    END IF;
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER tea_demot
BEFORE UPDATE 
ON user_table
FOR EACH ROW
EXECUTE PROCEDURE tea_stu_flag();

-- raises an exception if the student doesn't take the course

CREATE OR REPLACE FUNCTION takes_on_submits()
RETURNS TRIGGER
AS
$$
BEGIN
    IF NOT EXISTS (SELECT 1 FROM takes WHERE (NEW.user_id = takes.user_id AND NEW.course_id = takes.course_id)) THEN
        RAISE EXCEPTION 'Can not submit file! Student does not takes class';
    END IF;
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER check_if_stu_takes_submit
BEFORE INSERT
ON submits
FOR EACH ROW
EXECUTE PROCEDURE takes_on_submits();

