-- delete user from user_and_company
-- 579242223

CREATE OR REPLACE FUNCTION del_from_uac()
RETURNS TRIGGER
AS
$$
BEGIN
    DELETE FROM user_and_company WHERE OLD.user_and_company_id = user_and_company.user_and_company_id;
    RETURN NULL;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER user_del_uac
AFTER DELETE
ON user_table
FOR EACH ROW
EXECUTE PROCEDURE del_from_uac();

-- Apply flag changes to sub-tables on updates

CREATE OR REPLACE FUNCTION del_w_flags()
RETURNS TRIGGER
AS
$$
DECLARE depid VARCHAR;
BEGIN
    depid = student.department_id FROM student WHERE OLD.user_id = student.user_id;
    IF (NEW.comp_acc_flag OR NEW.stu_flag OR NEW.tea_flag) THEN
        IF (NOT OLD.stu_flag AND NEW.stu_flag AND NOT OLD.tea_flag AND NOT NEW.tea_flag) THEN
            INSERT INTO student VALUES (OLD.user_id, 'under_grad', 1, NULL);
        ELSIF (OLD.stu_flag AND NEW.stu_flag AND NOT OLD.tea_flag AND NEW.tea_flag) THEN
            INSERT INTO teacher VALUES (OLD.user_id, 'assistant', NULL);
            INSERT INTO employs VALUES (depid, OLD.user_id);
        ELSIF (OLD.stu_flag AND NOT NEW.stu_flag AND NOT OLD.tea_flag AND NOT NEW.tea_flag) THEN
            DELETE FROM student WHERE (OLD.user_id = student.user_id);
        ELSIF (OLD.tea_flag AND NOT NEW.tea_flag AND OLD.stu_flag AND NEW.stu_flag) THEN
            DELETE FROM teacher WHERE (OLD.user_id = teacher.user_id);
        ELSEIF (OLD.stu_flag AND NOT NEW.stu_flag AND OLD.tea_flag AND NEW.tea_flag) THEN
            UPDATE teacher SET teacher_type = 'faculty', rank = 'Lecturer' WHERE OLD.user_id = teacher.user_id;
            DELETE FROM student WHERE (OLD.user_id = student.user_id);
        ELSE
            RAISE EXCEPTION 'UNEXPECTED UPDATE';
        END IF;
    END IF;
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER flag_trig
AFTER UPDATE 
ON user_table
FOR EACH ROW
EXECUTE PROCEDURE del_w_flags();

-- Synchronize sub-tables of user_table with given flags on insert

CREATE FUNCTION senq_subs()
RETURNS TRIGGER
AS
$$
BEGIN
    IF (NEW.stu_flag AND NEW.tea_flag) THEN
        INSERT INTO student (user_id, student_type, class)
        VALUES (NEW.user_id, 'grad', NULL);
        INSERT INTO teacher (user_id, teacher_type, rank)
        VALUES (NEW.user_id, 'assistant', NULL);

    ELSIF (NOT NEW.stu_flag AND NEW.tea_flag) THEN
        INSERT INTO teacher(user_id, teacher_type, rank)
        VALUES (NEW.user_id, 'faculty', 'Lecturer');

    ELSIF (NEW.stu_flag AND NOT NEW.tea_flag) THEN
        INSERT INTO student (user_id, student_type, class)
        VALUES (NEW.user_id, 'under_grad', 1);

    END IF;
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER senq_user_subs
AFTER INSERT 
ON user_table
FOR EACH ROW
EXECUTE PROCEDURE senq_subs();

-- Insert uac_id to uac table on insert on user_table

CREATE FUNCTION upt_uac()
RETURNS TRIGGER
LANGUAGE plpgsql
AS
$$
BEGIN
    INSERT INTO  user_and_company VALUES (NEW.user_and_company_id);
    RETURN NEW;
END;
$$;

CREATE TRIGGER senq_uac
    BEFORE INSERT
    ON user_table
    FOR EACH ROW
    EXECUTE PROCEDURE upt_uac();

-- Insert uac_id to uac table on insert on company

CREATE FUNCTION comp_upt_uac()
RETURNS TRIGGER
LANGUAGE plpgsql
AS
$$
BEGIN
    INSERT INTO  user_and_company VALUES (NEW.user_and_company_id);
    RETURN NEW;
END;
$$;

CREATE TRIGGER senq_uac_comp
    BEFORE INSERT
    ON company
    FOR EACH ROW
    EXECUTE PROCEDURE upt_uac();

-- Delete user with no true flags

CREATE OR REPLACE FUNCTION delete_on_3f()
RETURNS TRIGGER
AS
$$
BEGIN
    DELETE FROM user_table WHERE (NOT comp_acc_flag AND NOT stu_flag AND NOT tea_flag);
    RETURN NULL;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER del_3f
AFTER UPDATE
ON user_table
FOR EACH ROW
EXECUTE PROCEDURE delete_on_3f();

-- Handle promotion of assitant to lecturer when a student is deleted whilst having record on table teacher

CREATE FUNCTION ast_to_lec()
RETURNS TRIGGER
AS
$$
BEGIN
    IF EXISTS (SELECT 1 FROM teacher WHERE OLD.user_id = teacher.user_id) THEN
        UPDATE teacher SET teacher_type = 'faculty', rank = 'Lecturer'
        WHERE teacher.user_id = OLD.user_id;
    END IF;
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER prom_to_lect
AFTER DELETE 
ON student
FOR EACH ROW
EXECUTE PROCEDURE ast_to_lec();

-- sets user_table stu_flag = false on delete

CREATE OR REPLACE FUNCTION stu_flag_senq()
RETURNS TRIGGER
AS
$$
BEGIN
    UPDATE user_table SET stu_flag = FALSE WHERE OLD.user_id = user_table.user_id;
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER set_stu_flag_false
AFTER DELETE
ON student
FOR EACH ROW
EXECUTE PROCEDURE stu_flag_senq();

-- sets user_table tea_flag = false

CREATE OR REPLACE FUNCTION tea_flag_senq()
RETURNS TRIGGER
AS
$$
BEGIN
    UPDATE user_table SET tea_flag = FALSE WHERE OLD.user_id = user_table.user_id;
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER set_tea_flag_false
AFTER DELETE
ON teacher
FOR EACH ROW
EXECUTE PROCEDURE tea_flag_senq();

-- When someone joins the event, the owner of the event sends a message.

CREATE OR REPLACE FUNCTION add_message_event_func()
RETURNS trigger AS 
$$
DECLARE find_uad VARCHAR;
DECLARE find_user VARCHAR;
BEGIN
    SELECT uad.user_and_company_id, u.user_and_company_id INTO find_uad,find_user
    FROM user_and_company AS uad, events AS e, join_event AS je, user_table AS u
    WHERE(uad.user_and_company_id=e.user_and_company_id AND e.event_id =new.event_id AND u.user_id=new.user_id);
    INSERT INTO messages(user1_and_company_id,user2_and_company_id,msg_date,msg_content) VALUES(find_uad,find_user, now(), 'Etkinliğimizde görüşmek üzere...');
    RETURN new;
END;
$$
LANGUAGE 'plpgsql';

CREATE trigger add_message_for_event
AFTER INSERT
ON join_event
FOR EACH ROW 
EXECUTE PROCEDURE add_message_event_func();