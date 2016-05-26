--==============================================
--fill tables--
--==============================================

--random integer
CREATE OR REPLACE FUNCTION get_random_int_number(selection_range INTEGER ) RETURNS INTEGER AS
$$
BEGIN
  RETURN trunc(random() * selection_range + 1);
END;
$$
LANGUAGE plpgsql;
------------------------------------------------

CREATE TABLE person (
  id                         SERIAL       PRIMARY KEY,
  education                  VARCHAR(100), 
  cv                         VARCHAR(300) NOT NULL,  
  login                      VARCHAR(70)  NOT NULL UNIQUE,
  password                   VARCHAR(255) NOT NULL,
  email                      VARCHAR(30)  NOT NULL UNIQUE
);
CREATE UNIQUE INDEX ident_login ON person (login);
CREATE UNIQUE INDEX ident_email ON person (email);
------------------------------------------------
CREATE OR REPLACE FUNCTION fill_person_table() RETURNS VOID AS
$$
DECLARE
  education 				VARCHAR(100);
  cv 						VARCHAR(300);
  login 					VARCHAR(70);
  password                  VARCHAR(255);
  email                     VARCHAR(30); 
BEGIN
  FOR i IN 1 .. 100000
  LOOP
    education = 'test_education_' || trim( to_char(i, '99999'));
    cv = 'test_cv_' || trim( to_char(i, '99999'));
    login = 'test_login_' || trim( to_char(i, '99999'));
    password = 'test_password_' || trim( to_char(i, '99999'));
    email = 'test_email_' || trim( to_char(i, '99999'));

    INSERT INTO person (education, cv, login, password, email)
      VALUES (education, cv, login, password, email);
  END LOOP;
END;
$$
LANGUAGE plpgsql;
------------------------------------------------
select fill_person_table();
------------------------------------------------
CREATE TABLE master_class (
  id                         SERIAL       PRIMARY KEY,
  subject                    VARCHAR(70)  NOT NULL,
  id_lector                  INT          REFERENCES person (id) ON DELETE RESTRICT ON UPDATE CASCADE,
  spend                      BOOLEAN      NOT NULL DEFAULT FALSE,
  place                      json, 
  price                      NUMERIC      NOT NULL DEFAULT 0, 
  visitors_count             INT          NOT NULL DEFAULT 0,    
  CHECK (price >= 0),
  CHECK (visitors_count >=0) 
);
------------------------------------------------
CREATE OR REPLACE FUNCTION fill_master_class_table() RETURNS VOID AS
$$
DECLARE
  place					json;
  subject 				VARCHAR(70);
  id_lector 			INT;
  price                 NUMERIC; 
BEGIN
  FOR i IN 1 .. 100000
  LOOP
   	place = '{"street":"name of street", "house_num":2}';
    subject = 'test_subject_' || trim( to_char(i, '99999'));
    id_lector = get_random_int_number(10000);
    price = get_random_int_number(10000);
    INSERT INTO master_class (place, subject, id_lector, price)
      VALUES (place, subject, id_lector, price);
  END LOOP;
END;
$$
LANGUAGE plpgsql;
------------------------------------------------
select fill_master_class_table();
------------------------------------------------
CREATE TABLE visit (
  adress					json,	
  id_master_class            INT          REFERENCES master_class (id) ON DELETE CASCADE ON UPDATE CASCADE, 
  id_person                  INT          REFERENCES person (id) ON DELETE CASCADE ON UPDATE CASCADE,
  -- UNIQUE (id_master_class, id_person)
);
------------------------------------------------
CREATE OR REPLACE FUNCTION fill_visit_table() RETURNS VOID AS
$$
DECLARE
  id_master_class 		INT;
  id_person             INT;
BEGIN
  FOR i IN 1 .. 1000000
  LOOP
    id_master_class = get_random_int_number(100000);
    id_person = get_random_int_number(100000);
    INSERT INTO visit (id_master_class, id_person)
    VALUES (id_master_class, id_person);
  END LOOP;
END;
$$
LANGUAGE plpgsql;
select fill_visit_table();
------------------------------------------------
--считаем количество посетителей мастер класса
------------------------------------------------
CREATE OR REPLACE FUNCTION change_visitors_count() RETURNS TRIGGER AS
$$
BEGIN
  IF (TG_OP = 'INSERT') THEN
  UPDATE master_class SET visitors_count = visitors_count + 1
  WHERE id = NEW.id_master_class;
  RETURN NEW;
    ELSE

    UPDATE master_class SET visitors_count = visitors_count - 1
    WHERE id = OLD.id_master_class  AND visitors_count>0 ;
    RETURN OLD;
  END IF;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER t_increment_visitors
AFTER INSERT OR DELETE
ON visit
FOR EACH ROW
EXECUTE PROCEDURE change_visitors_count();

--==============================================
--fill tables--
--==============================================
