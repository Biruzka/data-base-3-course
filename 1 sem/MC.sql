
--==============================================
--TABLES--
--==============================================

------------------------------------------------
CREATE TABLE person (
  id                         SERIAL       PRIMARY KEY,
  education                  VARCHAR(100), 
  cv                         VARCHAR(300) NOT NULL,  
  name                       VARCHAR(70)  NOT NULL,
  sername                    VARCHAR(70)  NOT NULL,
  login                      VARCHAR(70)  NOT NULL UNIQUE,
  password                   VARCHAR(255) NOT NULL,
  telephone                  VARCHAR(13)  DEFAULT NULL,
  birthday                   DATE         DEFAULT NULL,
  email                      VARCHAR(30)  NOT NULL UNIQUE,
  photo                      VARCHAR(255) DEFAULT 'empty.jpg',
  comments_count             INT          NOT NULL DEFAULT 0,
  description_info           TEXT         NOT NULL
);

CREATE UNIQUE INDEX ident_login ON person (login);
CREATE UNIQUE INDEX ident_email ON person (email);

CREATE TABLE master_class (
  id                         SERIAL       PRIMARY KEY,
  subject                    VARCHAR(70)  NOT NULL,
  id_creater                 INT          REFERENCES  person (id) ON DELETE RESTRICT ON UPDATE CASCADE,
  helper_firms               VARCHAR(100),
  id_lector                  INT          REFERENCES person (id) ON DELETE RESTRICT ON UPDATE CASCADE,
  start                      TIMESTAMP    NOT NULL,
  finish                     TIMESTAMP    NOT NULL,
  spend                      BOOLEAN      NOT NULL DEFAULT FALSE,
  place                      VARCHAR(70)  NOT NULL,
  price                      NUMERIC      NOT NULL DEFAULT 0, 
  visitors_count             INT          NOT NULL DEFAULT 0,    
  CHECK (finish >= start),
  CHECK (price >= 0),
  CHECK (visitors_count >=0); 
);

CREATE TABLE visit (
  id_master_class            INT          REFERENCES master_class (id) ON DELETE CASCADE ON UPDATE CASCADE, 
  id_person                  INT          REFERENCES person (id) ON DELETE CASCADE ON UPDATE CASCADE,
  UNIQUE (id_master_class, id_person)
);


CREATE TABLE like_to_master_class (
  id_evaluator_person        INT          REFERENCES person (id) ON DELETE SET NULL ON UPDATE CASCADE,
  id_master_class            INT          REFERENCES master_class (id) ON DELETE SET NULL ON UPDATE CASCADE,
  UNIQUE (id_evaluator_person, id_master_class)
);

CREATE TYPE duty AS ENUM ('lector', 'organizer');

CREATE TABLE rating_evaluation (
  type_duty                  duty         NOT NULL,
  id_evaluator_person        INT          REFERENCES person (id) ON DELETE SET NULL ON UPDATE CASCADE,
  id_evaluated_person        INT          REFERENCES person (id) ON DELETE SET NULL ON UPDATE CASCADE,
  count                      INT,
  PRIMARY KEY (type_duty, id_evaluator_person, id_evaluated_person),
  CHECK ( count <= 5 or count>0)
);

CREATE TABLE comment (
  id                          SERIAL       PRIMARY KEY,
  id_commentator              INT          REFERENCES person (id) ON DELETE SET NULL ON UPDATE CASCADE,
  comment_text                VARCHAR(300) NOT NULL
);

CREATE TABLE master_class_comment (
  id_master_class             INT          REFERENCES master_class (id) ON DELETE CASCADE ON UPDATE CASCADE,
  id_comment                  INT          REFERENCES comment (id) ON DELETE CASCADE ON UPDATE CASCADE,
  PRIMARY KEY (id_master_class,id_comment)
);

CREATE TABLE person_comment (
  id_person                   INT          REFERENCES person (id) ON DELETE SET NULL ON UPDATE CASCADE,
  id_comment                  INT          REFERENCES comment (id) ON DELETE CASCADE ON UPDATE CASCADE,
  PRIMARY KEY (id_person, id_comment)
);

CREATE TABLE message (
  id_sender                   INT          REFERENCES person (id) ON DELETE SET NULL ON UPDATE CASCADE,
  id_recipient                INT          REFERENCES person (id) ON DELETE SET NULL ON UPDATE CASCADE,
  date_of_sending             TIMESTAMP    NOT NULL,
  message_text                VARCHAR(300) NOT NULL
);
------------------------------------------------

--==============================================
--TRIGGERS and FUNCTIONS--
--==============================================

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
------------------------------------------------
--активность человека - количестов комментариев
------------------------------------------------
CREATE OR REPLACE FUNCTION change_comments_count() RETURNS TRIGGER AS
$$
BEGIN
  IF (TG_OP = 'INSERT') THEN
    UPDATE person SET comments_count = comments_count + 1
    WHERE id = NEW.id_commentator;
    RETURN NEW;
    ELSE
      UPDATE master_class SET comments_count = comments_count - 1
      WHERE id = OLD.id_commentator AND comments_count>0;
      RETURN OLD;
  END IF;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER t_increment_comments
AFTER INSERT OR DELETE
ON comment
FOR EACH ROW
EXECUTE PROCEDURE change_comments_count();
------------------------------------------------
--выводит имена и рэйтинги лекторов - среднее арифметическое
------------------------------------------------
CREATE OR REPLACE FUNCTION get_lectors_rating() RETURNS SETOF record AS
'
SELECT name AS name, sername AS sername, avg(count) AS rating 
FROM person join rating_evaluation on person.id = rating_evaluation.id_evaluated_person
WHERE type_duty = ''lector''
GROUP BY person.id
ORDER BY rating DESC;
'
LANGUAGE sql;
-------------
CREATE OR REPLACE FUNCTION get_lectors_rating_table() RETURNS 
TABLE (name VARCHAR(100),sername VARCHAR(100), rating NUMERIC) AS
$BODY$
  SELECT name AS name, sername AS sername, avg(count) AS rating 
  FROM person join rating_evaluation on person.id = rating_evaluation.id_evaluated_person
  WHERE type_duty = 'lector'
  GROUP BY person.id
  ORDER BY rating DESC
$BODY$;
------------------------------------------------
--функция, возвращающая все отзывы о тебе--
------------------------------------------------
CREATE OR REPLACE FUNCTION comments_for_person(id_num INT) RETURNS SETOF record AS
'
select name, c.comment_text FROM
person
join
  (SELECT comment_text, id_commentator FROM
  comment join person_comment ON person_comment.id_comment=comment.id
  where person_comment.id_person = id_num) AS c
ON  person.id=c.id_commentator;
'
LANGUAGE sql;
------------------------------------------------
--функция которая посчитает рэйтинги среднее арифметическое для организаторов--
------------------------------------------------
CREATE FUNCTION get_organizers_rating() RETURNS SETOF record AS
'
SELECT id, name, sername avg(count) AS rating
FROM person inner join rating_evaluation on person.id = rating_evaluation.id_evaluated_person
WHERE type_duty = ''organizer''
GROUP BY person.id
ORDER BY rating DESC;
'
LANGUAGE sql;
------------------------------------------------

--==============================================
--VIEWS--
--==============================================

------------------------------------------------
CREATE VIEW top_master_classes AS
  SELECT subject, COUNT(like_to_master_class.id_master_class) AS rating
  FROM master_class FULL OUTER JOIN like_to_master_class on master_class.id=like_to_master_class.id_master_class
  GROUP BY master_class.id
  ORDER BY rating DESC
  LIMIT 5;
------------------------------------------------

--==============================================
--INSERTS--
--==============================================

------------------------------------------------
INSERT INTO person 
(education,cv,name,sername,login,password,telephone,birthday,email,photo,comments_count,description_info) 
VALUES
('KFU','funny person','Burunduk', 'Bububu','burunduk','123','905-3112467','1995-02-03','burunduk@gmail.com', DEFAULT, DEFAULT, 'really love MC'),   
('UNIVERCHIK','simple person','Vanya', 'Vanushkin','fraerok','123','905-3112434','1970-05-03','simple@gmail.com', DEFAULT, DEFAULT, 'search sense of live'),
('LIVE','rolling-stone experience','Luka', 'Putnik','Luka','123',DEFAULT,'1960-02-03','luka@gmail.com', DEFAULT, DEFAULT, 'eternal way is my goal'),
('KFU','love learn','Stue','Baby','Stue','123','905-3112789','1997-02-03','stue@gmail.com', DEFAULT, DEFAULT, 'hardworking is well for me'),
('army','strong man, trainer','Billy', 'Minigan','captain','123','905-3115437','1960-02-03','army@gmail.com', DEFAULT, DEFAULT, 'hate people'),
('college of pharmacy','2 years experince','Mila', 'Tabletkovna','Puzirek','123','905-4512467','1990-02-03','probirka@gmail.com', DEFAULT, DEFAULT, 'I am hoping about peace in the world'),
('college','organized a lot of meetings','Gulfia', 'GihanKizi','GulyOrganizer','123','955-3112467','1980-02-03','guly@gmail.com', DEFAULT, DEFAULT, 'meet by meet'),
('KFU','maneger','Dshohan', 'Rickl','Rickl','123','905-3112467','1970-02-03','dshohan@gmail.com', DEFAULT, DEFAULT, 'good in organaizing and in menegment and timemapping too'),
('KFU','person','Nobody', 'JustHere','Just','123','905-3112467','1995-02-03','hey@gmail.com', DEFAULT, DEFAULT, 'Why I am here?'),
('Academy','good in policy','Igor', 'Stuckachev','Respect','123','905-3112467','1980-02-03','stukach@gmail.com', DEFAULT, DEFAULT, 'teach you to be reach');
------------------------------------------------

------------------------------------------------
INSERT INTO master_class
(subject,id_creater,helper_firms,id_lector,start,finish,spend,place,price) 
VALUES
('pharmacy',9, DEFAULT, 6,'2015-08-12 18:00','2015-08-12 21:00',DEFAULT,'Sakura',400),
('avtostop',2, DEFAULT, 3,'2015-08-12 18:00','2015-08-12 21:00',DEFAULT,'Sakura',100),
('manegment',8,'KFU',8,'20015-08-12 15:00','20015-08-12 17:00',DEFAULT,'Skovorodka',DEFAULT),
('prepare to diskretka',8, 'KFU', 4,'2015-05-10 13:00','2015-05-10 18:00',DEFAULT,'Dvoika',300),
('army? why not?',2, DEFAULT, 5,'2015-07-12 18:00','2015-08-12 21:00',DEFAULT,'Dvoika',100);
------------------------------------------------

------------------------------------------------
INSERT INTO visit 
(id_master_class,id_person)
VALUES
(3,6)
(1,5),
(2,4),
(2,3),
(1,1),
(1,7);
------------------------------------------------

------------------------------------------------
INSERT INTO like_to_master_class
( id_evaluator_person,id_master_class)
VALUES
(1,1),
(7,2),
(4,1),
(5,2),
(3,2);
------------------------------------------------

------------------------------------------------
INSERT INTO rating_evaluation
(type_duty,id_evaluator_person,id_evaluated_person, count)
VALUES
('lector',3,8,3),
('lector',2,6,5),
('organizer',3,8,5),
('lector',7,4,2);
------------------------------------------------

------------------------------------------------
INSERT INTO comment (id_commentator,comment_text)
VALUES
(1, 'Are you seriosly?'),
(2, 'just trolling, trollololo.....)))))'),
(4, 'you really well in your skills! Good job');
------------------------------------------------

------------------------------------------------
INSERT INTO person_comment (id_person,id_comment)
VALUES
(5, 1),
(5, 2),
(8, 3);
------------------------------------------------

--==============================================
--SELECTS--
--==============================================

------------------------------------------------
SELECT * FROM person;
SELECT * FROM master_class;
SELECT * FROM visit;
DELETE FROM visit;
------------------------------------------------

--посчитать количество лайков для каждого мк
------------------------------------------------
SELECT subject, COUNT(like_to_master_class.id_master_class)
FROM master_class FULL OUTER JOIN like_to_master_class on master_class.id=like_to_master_class.id_master_class
GROUP BY master_class.id;
------------------------------------------------

---выводит имена лекторов и их рейтинг
------------------------------------------------
SELECT name AS name, sername AS sername, avg(count) AS rating 
FROM person join rating_evaluation on person.id = rating_evaluation.id_evaluated_person
WHERE type_duty = ''lector''
GROUP BY person.id
ORDER BY rating DESC;
------------------------------------------------

--посчитать количество посетителей мк-ов, связанных образованием с КФУ
------------------------------------------------
SELECT subject, COUNT(visit.id_person) FROM
master_class join visit ON visit.id_master_class=master_class.id
WHERE visit.id_person IN 
  (SELECT id FROM person where person.education='KFU')
GROUP BY master_class.id;
------------------------------------------------

--вернуть все обращенные к тебе комментарии по id кто написал и что
------------------------------------------------
select name, c.comment_text FROM
person
join
  (SELECT comment_text, id_commentator FROM
  comment join person_comment ON person_comment.id_comment=comment.id
  where person_comment.id_person = 5) AS c
ON  person.id=c.id_commentator;
------------------------------------------------

