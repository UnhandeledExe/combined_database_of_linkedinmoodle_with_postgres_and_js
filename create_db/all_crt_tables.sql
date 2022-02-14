-- create user_and_company
CREATE TABLE user_and_company(
    user_and_company_id VARCHAR(15) PRIMARY KEY
);

-- create user_table

CREATE TABLE user_table (
    user_id VARCHAR(11) PRIMARY KEY,
    Fname VARCHAR(30) NOT NULL,
    Lname VARCHAR(30) NOT NULL,
    email VARCHAR(50) NOT NULL UNIQUE,    
    password VARCHAR(50) NOT NULL,
    date_of_birth DATE NOT NULL,
    sex CHAR(1) DEFAULT 'U',
    phone VARCHAR(10) UNIQUE,
    date_joined TIMESTAMPTZ NOT NULL,
    other_details TEXT,
    country VARCHAR(20),
    city VARCHAR(20),
    comp_acc_flag BOOLEAN NOT NULL,
    stu_flag BOOLEAN NOT NULL,
    tea_flag BOOLEAN NOT NULL,
    user_and_company_id VARCHAR(15) NOT NULL UNIQUE 
    REFERENCES user_and_company(user_and_company_id) 
    ON DELETE CASCADE
);

-- create university

CREATE TABLE university(
    university_id SERIAL PRIMARY KEY,
    uni_loc VARCHAR(50) NOT NULL,
    uni_name VARCHAR(50) NOT NULL
);

-- create department

CREATE TABLE department(
    dept_id VARCHAR(10) PRIMARY KEY,
    dept_name VARCHAR(50) NOT NULL,
    uni_id INT REFERENCES university(university_id) ON DELETE CASCADE
);


-- create student

CREATE TABLE student(
    user_id VARCHAR(11) PRIMARY KEY REFERENCES user_table(user_id) ON DELETE CASCADE,
    student_type VARCHAR(15) NOT NULL,
    class INT,
    department_id VARCHAR(10) REFERENCES department(dept_id) ON DELETE CASCADE
);

-- create teacher

CREATE TABLE teacher(
    user_id VARCHAR(11) PRIMARY KEY REFERENCES user_table(user_id) ON DELETE CASCADE,
    teacher_type VARCHAR(20) NOT NULL,
    rank VARCHAR(20)
);


-- create employs

CREATE TABLE employs(
    department_id VARCHAR(10) REFERENCES department(dept_id) ON DELETE CASCADE,
    user_id VARCHAR(11) REFERENCES teacher(user_id) ON DELETE CASCADE,
    CONSTRAINT emp_pk PRIMARY KEY (department_id, user_id)
);

-- create course

CREATE TABLE course(
    course_id VARCHAR(10) PRIMARY KEY,
    course_name VARCHAR(30) NOT NULL,
    semester VARCHAR(10) NOT NULL,
    enroll_key VARCHAR(30) NOT NULL,
    dept_id VARCHAR(10) NOT NULL REFERENCES department(dept_id) ON DELETE CASCADE
);

-- create manages 

CREATE TABLE manages(
    course_id VARCHAR(10) REFERENCES course(course_id) ON DELETE CASCADE,
    user_id VARCHAR(11) REFERENCES teacher(user_id) ON DELETE CASCADE,
    CONSTRAINT manages_pk PRIMARY KEY (course_id, user_id)
);

-- create takes

CREATE TABLE takes(
    course_id VARCHAR(10) REFERENCES course(course_id) ON DELETE CASCADE,
    user_id VARCHAR(11) REFERENCES student(user_id) ON DELETE CASCADE,
    CONSTRAINT takes_pk PRIMARY KEY (course_id, user_id)
);

-- creata assignments

CREATE TABLE assignments(
    asg_name VARCHAR(30),
    course_id VARCHAR(10) REFERENCES course(course_id),
    asg_context TEXT NOT NULL,
    due_date TIMESTAMPTZ NOT NULL,
    assign_date TIMESTAMPTZ NOT NULL,    
    CONSTRAINT ass_pk PRIMARY KEY(asg_name, course_id)
);

-- create submits

CREATE TABLE submits(
    asg_name VARCHAR(30),
    course_id VARCHAR(10),
    user_id VARCHAR(11) REFERENCES student(user_id) ON DELETE CASCADE,
    submit_date TIMESTAMPTZ NOT NULL,
    grade INT,
    CONSTRAINT submits_pk PRIMARY KEY (asg_name, course_id, user_id),
    CONSTRAINT submits_asg_name_course_id_fkey FOREIGN KEY (asg_name, course_id)
    REFERENCES assignments(asg_name, course_id) ON DELETE CASCADE
);

-- create connections

CREATE TABLE connections(
    user1_id VARCHAR(11) REFERENCES user_table(user_id) ON DELETE CASCADE,
    user2_id VARCHAR(11) REFERENCES user_table(user_id) ON DELETE CASCADE,
    status BOOLEAN DEFAULT FALSE,
    CONSTRAINT conn_pk PRIMARY KEY (user1_id, user2_id)
);

-- create company

CREATE TABLE company (
    company_id VARCHAR(15) PRIMARY KEY,
    company_name VARCHAR(50) NOT NULL,
    about TEXT,
    user_and_company_id VARCHAR(15) REFERENCES user_and_company(user_and_company_id) ON DELETE CASCADE,
    user_id VARCHAR(11) REFERENCES user_table(user_id) ON DELETE CASCADE,
    date_created TIMESTAMPTZ NOT NULL
);

-- create event

CREATE TABLE events(
    event_id VARCHAR(15) PRIMARY KEY,
    event_name VARCHAR(50) NOT NULL,
    event_start_date TIMESTAMPTZ NOT NULL,
    event_end_date TIMESTAMPTZ NOT NULL,
    event_description TEXT,
    user_and_company_id VARCHAR(15) NOT NULL REFERENCES user_and_company(user_and_company_id) ON DELETE CASCADE
);

-- create join_event

CREATE TABLE join_event(
    user_id VARCHAR(11) REFERENCES user_table(user_id) ON DELETE CASCADE,
    event_id VARCHAR(15) REFERENCES events(event_id) ON DELETE CASCADE,
    CONSTRAINT je_pk PRIMARY KEY (user_id, event_id)
);

-- create job_adv

CREATE TABLE job_adv(
    job_id VARCHAR(15),
    company_id VARCHAR(15) REFERENCES company(company_id) ON DELETE CASCADE,
    job_name VARCHAR(50) NOT NULL,
    job_desc TEXT NOT NULL,
    job_type VARCHAR(50) NOT NULL,
    publish_date TIMESTAMPTZ,
    CONSTRAINT job_pk PRIMARY KEY(job_id, company_id)
);

-- create apply_job

CREATE TABLE apply_job(
    user_id VARCHAR(11) REFERENCES user_table(user_id) ON DELETE CASCADE,
    job_id VARCHAR(15),
    company_id VARCHAR(15),
    cv TEXT,
    CONSTRAINT aj_pk PRIMARY KEY (user_id, job_id, company_id),
    CONSTRAINT company_jo_id_fkey FOREIGN KEY (job_id, company_id) 
    REFERENCES job_adv(job_id, company_id) ON DELETE CASCADE
);

-- create follows

CREATE TABLE follow(
    follower_id VARCHAR(15) REFERENCES user_and_company(user_and_company_id) ON DELETE CASCADE,
    following_id VARCHAR(15) REFERENCES user_and_company(user_and_company_id) ON DELETE CASCADE,
    follow_date TIMESTAMPTZ NOT NULL,
    CONSTRAINT flw_pk PRIMARY KEY(follower_id,following_id)
);

-- create messages

CREATE TABLE messages(
    user1_and_company_id VARCHAR(15) REFERENCES user_and_company(user_and_company_id) ON DELETE CASCADE,
    user2_and_company_id VARCHAR(15) REFERENCES user_and_company(user_and_company_id) ON DELETE CASCADE,
    msg_date TIMESTAMPTZ NOT NULL,
    msg_content TEXT NOT NULL,
    CONSTRAINT msg_pk PRIMARY KEY(user1_and_company_id, user2_and_company_id, msg_date) -- msg_date ihtiyaçtan doğan primary key
);

-- create post

CREATE TABLE post(
    post_id VARCHAR(15) PRIMARY KEY,
    post_content TEXT NOT NULL,
    post_date TIMESTAMPTZ NOT NULL,
    user_and_company_id VARCHAR(15) REFERENCES user_and_company(user_and_company_id) ON DELETE CASCADE
);

-- create comment

CREATE TABLE comment(
    user_and_company_id VARCHAR(15) REFERENCES user_and_company(user_and_company_id) ON DELETE CASCADE,
    post_id VARCHAR(15) REFERENCES post(post_id) ON DELETE CASCADE,
    comment_date TIMESTAMPTZ NOT NULL,
    comment_content TEXT,
    CONSTRAINT com_pk PRIMARY KEY (user_and_company_id, post_id)
);

-- create likes 

CREATE TABLE likes(
    user_and_company_id VARCHAR(15) REFERENCES user_and_company(user_and_company_id) ON DELETE CASCADE,
    post_id VARCHAR(15) REFERENCES post(post_id) ON DELETE CASCADE,
    CONSTRAINT likes_pk PRIMARY KEY (user_and_company_id, post_id)
);
