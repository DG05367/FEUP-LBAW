-- Drop old schema

DROP TABLE IF EXISTS users CASCADE;
DROP TABLE IF EXISTS authenticated_users CASCADE;
DROP TABLE IF EXISTS administrator CASCADE;
DROP TABLE IF EXISTS moderator CASCADE;
DROP TABLE IF EXISTS post CASCADE;
DROP TABLE IF EXISTS comment CASCADE;
DROP TABLE IF EXISTS tag CASCADE;
DROP TABLE IF EXISTS report_post CASCADE;
DROP TABLE IF EXISTS report_comment CASCADE;
DROP TABLE IF EXISTS liked_posts CASCADE;
DROP TABLE IF EXISTS user_comments CASCADE;
DROP TABLE IF EXISTS media CASCADE;
DROP TABLE IF EXISTS visitor CASCADE;
DROP TABLE IF EXISTS following CASCADE;
DROP TABLE IF EXISTS notification CASCADE;

DROP TYPE IF EXISTS med;

DROP TRIGGER IF EXISTS post_search_update ON post;
DROP TRIGGER IF EXISTS new_liked_posts ON liked_posts;
DROP TRIGGER IF EXISTS new_follow ON following;
DROP TRIGGER IF EXISTS follow_himself ON following;

DROP FUNCTION IF EXISTS post_search_update;
DROP FUNCTION IF EXISTS new_liked_posts;
DROP FUNCTION IF EXISTS new_follow;
DROP FUNCTION IF EXISTS follow_himself;

-- Types

CREATE TYPE med AS ENUM ('NONE', 'GIF', 'VIDEO', 'NEWS ARTICLE', 'WEB SITE');

-- Tables

-- Table named users instead of user because user is a reserved word in PostgreSQL.
CREATE TABLE users (
	id SERIAL PRIMARY KEY
);

CREATE TABLE authenticated_users (
	email TEXT NOT NULL UNIQUE,
	username TEXT NOT NULL UNIQUE,
	name TEXT,
	location TEXT,
	profile_description TEXT,
	reputation TEXT,
	password VARCHAR NOT NULL,
	user_id INT REFERENCES users(id) ON UPDATE CASCADE
);

CREATE TABLE administrator (
	name TEXT NOT NULL,
	email TEXT NOT NULL UNIQUE,
	password TEXT NOT NULL,
	username TEXT NOT NULL,
	company_id SERIAL NOT NULL UNIQUE,
	phone_number VARCHAR NOT NULL UNIQUE,
	residence TEXT NOT NULL UNIQUE
);

CREATE TABLE moderator (
	phone_number VARCHAR NOT NULL UNIQUE,
	authenticated_user_id INT REFERENCES users(id) ON UPDATE CASCADE
);

CREATE TABLE tag (
	tag_id SERIAL PRIMARY KEY,
	name TEXT UNIQUE 
);

CREATE TABLE post (
	post_id SERIAL PRIMARY KEY,
	author_id INT REFERENCES users(id) ON UPDATE CASCADE,
	title TEXT NOT NULL,
	date TIMESTAMP WITH TIME ZONE DEFAULT now() NOT NULL,
	votes INT,
	description TEXT,
	tag_id INT REFERENCES tag(tag_id) ON UPDATE CASCADE,
	TYPE med
);

CREATE TABLE comment (
	comment_id SERIAL PRIMARY KEY,
	description TEXT,
	date TIMESTAMP WITH TIME ZONE DEFAULT now() NOT NULL,
	votes INT,
	post_id INT REFERENCES post(post_id) ON UPDATE CASCADE,
	TYPE med
);

CREATE TABLE report_post (
	report_post_id SERIAL,
	description TEXT NOT NULL,
	post_id INT REFERENCES post(post_id) ON UPDATE CASCADE,
	user_id INT REFERENCES users(id) ON UPDATE CASCADE
);

CREATE TABLE report_comment (
	report_comment_id SERIAL,
	description TEXT NOT NULL,
	comment_id INT REFERENCES comment(comment_id) ON UPDATE CASCADE,
	user_id INT REFERENCES users(id) ON UPDATE CASCADE
);

CREATE TABLE liked_posts (
	user_id INT REFERENCES users(id) ON UPDATE CASCADE,
	post_id INT REFERENCES post(post_id) ON UPDATE CASCADE,
	down_or_upvote BIT NOT NULL
);

CREATE TABLE user_comments (
	user_id INT REFERENCES users(id) ON UPDATE CASCADE,
	comment_id INT REFERENCES comment(comment_id) ON UPDATE CASCADE
);

CREATE TABLE media (
	url VARCHAR UNIQUE NOT NULL,
	post_id INT REFERENCES post(post_id) ON UPDATE CASCADE,
	comment_id INT REFERENCES comment(comment_id) ON UPDATE CASCADE
);

CREATE TABLE visitor (
	visitor_id INT REFERENCES users(id) ON UPDATE CASCADE
);

CREATE TABLE following (
	authenticated_user_id1 INT REFERENCES users(id) ON UPDATE CASCADE,
	authenticated_user_id2 INT REFERENCES users(id) ON UPDATE CASCADE
);

CREATE TABLE notification (
	authenticated_user_id1 INT REFERENCES users(id) ON UPDATE CASCADE,
	authenticated_user_id2 INT REFERENCES users(id) ON UPDATE CASCADE,
	comment_id INT REFERENCES comment(comment_id) ON UPDATE CASCADE,
	post_id INT REFERENCES post(post_id) ON UPDATE CASCADE,
	date TIMESTAMP WITH TIME ZONE DEFAULT now() NOT NULL,
	description TEXT NOT NULL
);

-- Indexes

CREATE INDEX comments_index ON comment USING hash (comment_id);

CREATE INDEX posts_index ON post USING btree (post_id);
CLUSTER post USING posts_index;

CREATE INDEX follows_index ON following USING hash (authenticated_user_id1);

-- FTS Indexes

-- Add column to post to store computed ts_vectors.
ALTER TABLE post
ADD COLUMN tsvectors TSVECTOR;

-- Create a function to automatically update ts_vectors.
CREATE FUNCTION post_search_update() RETURNS TRIGGER AS $$
BEGIN
 IF TG_OP = 'INSERT' THEN
    	NEW.tsvectors = (
     	setweight(to_tsvector('english', NEW.title), 'A') ||
     	setweight(to_tsvector('english', NEW.description), 'B')
    	);
 END IF;
 IF TG_OP = 'UPDATE' THEN
     	IF (NEW.title <> OLD.title OR NEW.description <> OLD.description) THEN
       	NEW.tsvectors = (
			   setweight(to_tsvector('english', NEW.title), 'A') ||
         	setweight(to_tsvector('english', NEW.description), 'B')
       	);
     	END IF;
 END IF;
 RETURN NEW;
END $$
LANGUAGE plpgsql;

-- Create a trigger before insert or update on post.
CREATE TRIGGER post_search_update
 BEFORE INSERT OR UPDATE ON post
 FOR EACH ROW
 EXECUTE PROCEDURE post_search_update();

-- Finally, create a GIN index for ts_vectors.
CREATE INDEX search_idx ON post USING GIN (tsvectors);

-- Triggers

-- Trigger #1
-- An user cannot upvote/downvote twice the same post and cannot upvote and downvote the same post.

CREATE FUNCTION new_liked_posts() RETURNS TRIGGER AS
$BODY$
BEGIN
        IF EXISTS (SELECT * FROM liked_posts WHERE user_id = NEW.user_id AND post_id = NEW.post_id) THEN
           RAISE EXCEPTION 'You cannot upvote/downvote twice the same post and you cannot upvote and downvote the same post.';
        END IF;
        RETURN NEW;
END
$BODY$
LANGUAGE plpgsql;

CREATE TRIGGER new_liked_posts
BEFORE INSERT OR UPDATE ON liked_posts
FOR EACH ROW
EXECUTE PROCEDURE new_liked_posts();

-- Trigger #2
-- An user can only follow one time another user.

CREATE FUNCTION new_follow() RETURNS TRIGGER AS
$BODY$
BEGIN
        IF EXISTS (SELECT * FROM following WHERE authenticated_user_id1 = NEW.authenticated_user_id1 AND authenticated_user_id2 = NEW.authenticated_user_id2) THEN
           RAISE EXCEPTION 'You cannot follow twice the same user.';
        END IF;
        RETURN NEW;
END
$BODY$
LANGUAGE plpgsql;

CREATE TRIGGER new_follow
BEFORE INSERT OR UPDATE ON following
FOR EACH ROW
EXECUTE PROCEDURE new_follow();

-- Trigger #3
-- An user can't follow himself.

CREATE FUNCTION follow_himself() RETURNS TRIGGER AS
$BODY$
BEGIN
        IF (NEW.authenticated_user_id1 = NEW.authenticated_user_id2) THEN
           RAISE EXCEPTION 'You cannot follow yourself.';
        END IF;
        RETURN NEW;
END
$BODY$
LANGUAGE plpgsql;

CREATE TRIGGER follow_himself
BEFORE INSERT OR UPDATE ON following
FOR EACH ROW
EXECUTE PROCEDURE follow_himself();

-- We have
-- 20 authenticated users
-- 4 moderators
-- 2 administrators
-- 4 tags
-- 50 posts (TODO real titles and descriptions or just real titles and lorem ipsum description) (TODO add tag 1 2 3 or 4 based on title)
-- 20 comments (TODO real comments or just random text)
-- 6 likes
-- 47 media (TODO please check this. not sure why it points to post_id and comment_id at the same time)
-- (TODO visitor)
-- 20 following
-- 10 notification

INSERT INTO users (id) VALUES (1);
INSERT INTO users (id) VALUES (2);
INSERT INTO users (id) VALUES (3);
INSERT INTO users (id) VALUES (4);
INSERT INTO users (id) VALUES (5);
INSERT INTO users (id) VALUES (6);
INSERT INTO users (id) VALUES (7);
INSERT INTO users (id) VALUES (8);
INSERT INTO users (id) VALUES (9);
INSERT INTO users (id) VALUES (10);
INSERT INTO users (id) VALUES (11);
INSERT INTO users (id) VALUES (12);
INSERT INTO users (id) VALUES (13);
INSERT INTO users (id) VALUES (14);
INSERT INTO users (id) VALUES (15);
INSERT INTO users (id) VALUES (16);
INSERT INTO users (id) VALUES (17);
INSERT INTO users (id) VALUES (18);
INSERT INTO users (id) VALUES (19);
INSERT INTO users (id) VALUES (20);
INSERT INTO users (id) VALUES (21);


INSERT INTO authenticated_users (email, username, name, location, profile_description, reputation, password, user_id) VALUES ('test@gmail.com', 'test', 'Bryant Jones', 'Lisbon, Portugal', 'Professional Athlete at F.C.Porto', 0, '$2a$12$VDzOT8rGKNbnGKetW3MlsOwrOePezmgeKwbOPvCWge9Khme1RnqJi', 21);
INSERT INTO authenticated_users (email, username, name, location, profile_description, reputation, password, user_id) VALUES ('gharkess0@hc360.com', 'jmethringham0', 'Bryant Jones', 'Lisbon, Portugal', 'Professional Athlete at F.C.Porto', 33, '$2a$12$qWiBD17xqitTvl/83ke./OUQ5vnb3I6pe0osTsfmPBsQBH01VICzG', 1);
INSERT INTO authenticated_users (email, username, name, location, profile_description, reputation, password, user_id) VALUES ('jfladgate1@ameblo.jp', 'cdagg1', 'Bryant Jones', 'Lisbon, Portugal', 'Professional Athlete at F.C.Porto', 88, '$2a$12$3rfX1oEJyoq8NHoL2TcUM.Oi96h4XEZjyDbcDQr4FO7x2dAtkQ3Va', 2);
INSERT INTO authenticated_users (email, username, name, location, profile_description, reputation, password, user_id) VALUES ('fohartnedy2@taobao.com', 'ltemple2', 'Bryant Jones', 'Lisbon, Portugal', 'Professional Athlete at F.C.Porto', 21, '$2a$12$rtQHfO/SDb2VXQ9bbFCYdubCTplKq.Oia2uBJUiMXTcqEzqhEaXYu', 3);
INSERT INTO authenticated_users (email, username, name, location, profile_description, reputation, password, user_id) VALUES ('civashkin3@rakuten.co.jp', 'lcoakley3', 'Bryant Jones', 'Lisbon, Portugal', 'Professional Athlete at F.C.Porto', 26, '$2a$12$rZ4m5i7qq/YiXr3pg2MQ8e.R.oURzPgO8Z7KM5zTkGnAgmuRr7Xq2', 4);
INSERT INTO authenticated_users (email, username, name, location, profile_description, reputation, password, user_id) VALUES ('jhawkswell4@sciencedaily.com', 'rhagley4', 'Bryant Jones', 'Lisbon, Portugal', 'Professional Athlete at F.C.Porto', 27, '$2a$12$jE4p3XXhOMKBsecUa1fZrel0eFgiSJ2TRojX0R0pq5jyrpUrV1Tj2', 5);
INSERT INTO authenticated_users (email, username, name, location, profile_description, reputation, password, user_id) VALUES ('apetricek5@cbsnews.com', 'aracine5', 'Bryant Jones', 'Lisbon, Portugal', 'Professional Athlete at F.C.Porto', 16, '$2a$12$pxa5DVHOWRu5MWdAX.6dFuBdPu5lWir./zOTo3hMYobbZp8hdEvAm', 6);
INSERT INTO authenticated_users (email, username, name, location, profile_description, reputation, password, user_id) VALUES ('nhort6@geocities.com', 'krulten6', 'Bryant Jones', 'Lisbon, Portugal', 'Professional Athlete at F.C.Porto', 54, '$2a$12$kNG3BaSZMLEEu7umqAOFo.ZS7fSmIg9EEHwbQH5O74Az.2nt83wZu', 7);
INSERT INTO authenticated_users (email, username, name, location, profile_description, reputation, password, user_id) VALUES ('ddanks7@technorati.com', 'mmacclay7', 'Bryant Jones', 'Lisbon, Portugal', 'Professional Athlete at F.C.Porto', 12, '$2a$12$lkCepiFhpIZT.0IeBGCWyOr2EwoDALhhYgm.dztKgwndKYN7BeXzW', 8);
INSERT INTO authenticated_users (email, username, name, location, profile_description, reputation, password, user_id) VALUES ('ptodarini8@typepad.com', 'arodrigues8', 'Bryant Jones', 'Lisbon, Portugal', 'Professional Athlete at F.C.Porto', 59, '$2a$12$.yzL6ruroXnto2NKO6Z.aOweRLNkk9mCv8.fOlDcp1dc694KTHwNS', 9);
INSERT INTO authenticated_users (email, username, name, location, profile_description, reputation, password, user_id) VALUES ('ajahner9@ox.ac.uk', 'vsuccamore9', 'Bryant Jones', 'Lisbon, Portugal', 'Professional Athlete at F.C.Porto', 49, '$2a$12$MQtDAwaEzGAT./6lNCw3NO2qyvBen/wGpXc5MVJFzYlzdvldJWdrO', 10);
INSERT INTO authenticated_users (email, username, name, location, profile_description, reputation, password, user_id) VALUES ('clivesleya@ox.ac.uk', 'dcranmera', 'Bryant Jones', 'Lisbon, Portugal', 'Professional Athlete at F.C.Porto', 45, '$2a$12$9YAtsvmGdHEDwjtqi11p1Oz5/cOOFzqOoqdcyo3SDDyVKNz/5WQLu', 11);
INSERT INTO authenticated_users (email, username, name, location, profile_description, reputation, password, user_id) VALUES ('gdissmanb@github.io', 'jmaccrackanb', 'Bryant Jones', 'Lisbon, Portugal', 'Professional Athlete at F.C.Porto', 87, '$2a$12$jZlBjzqaM6Zre/jGfGXLy.zLFOGUoBiUIjW.LDIfIpkcedNkW2kSm', 12);
INSERT INTO authenticated_users (email, username, name, location, profile_description, reputation, password, user_id) VALUES ('ccoltartc@wix.com', 'adunlapc', 'Bryant Jones', 'Lisbon, Portugal', 'Professional Athlete at F.C.Porto', 77, '$2a$12$fXxob.WVnybItQqoedbbcuXDaoPqHmZdHpuWntrIzF/WcUa2AwZzq', 13);
INSERT INTO authenticated_users (email, username, name, location, profile_description, reputation, password, user_id) VALUES ('lmccurried@webmd.com', 'dsheringtond', 'Bryant Jones', 'Lisbon, Portugal', 'Professional Athlete at F.C.Porto', 42, '$2a$12$SWZdt4ftdALqd8n3xTJN.Oa8EgXxJa.hZ1tFhNQ/yXW.3p95NXdA6', 14);
INSERT INTO authenticated_users (email, username, name, location, profile_description, reputation, password, user_id) VALUES ('fradishe@parallels.com', 'kspacye', 'Bryant Jones', 'Lisbon, Portugal', 'Professional Athlete at F.C.Porto', 91, '$2a$12$autDUSH2u8a6jKn4mJoTCuSbyXSkwlXe24IMLXapNUkz2G.qXHofq', 15);
INSERT INTO authenticated_users (email, username, name, location, profile_description, reputation, password, user_id) VALUES ('mvescof@blogtalkradio.com', 'jeaggerf', 'Bryant Jones', 'Lisbon, Portugal', 'Professional Athlete at F.C.Porto', 80, '$2a$12$29trcH9zgYWhehyPMf.v...mhgcd6hBDFcsSUk9DQyPmEuLPzp9F6', 16);
INSERT INTO authenticated_users (email, username, name, location, profile_description, reputation, password, user_id) VALUES ('gstansallg@cornell.edu', 'ppostansg', 'Bryant Jones', 'Lisbon, Portugal', 'Professional Athlete at F.C.Porto', 74, '$2a$12$QyaQGQqaKyDvtrBDqX56WefIVAHZm2dF0SwAax.uS5qwJvtQavPZa', 17);
INSERT INTO authenticated_users (email, username, name, location, profile_description, reputation, password, user_id) VALUES ('jatheyh@gizmodo.com', 'migguldenh', 'Bryant Jones', 'Lisbon, Portugal', 'Professional Athlete at F.C.Porto', 99, '$2a$12$OAxOpkC69Lov3CeeiZy63eBIS/kzduKNgTrwMZUzLijFbX.WWiTce', 18);
INSERT INTO authenticated_users (email, username, name, location, profile_description, reputation, password, user_id) VALUES ('gcoskerryi@salon.com', 'rboriti', 'Bryant Jones', 'Lisbon, Portugal', 'Professional Athlete at F.C.Porto', 26, '$2a$12$1aDLKB32kK.JeFQal9xNxe1bcq0FAAOhUGaZUqNcHJzVgyOwHZ8XS', 19);
INSERT INTO authenticated_users (email, username, name, location, profile_description, reputation, password, user_id) VALUES ('jdanslowj@miitbeian.gov.cn', 'lfreezerj', 'Bryant Jones', 'Lisbon, Portugal', 'Professional Athlete at F.C.Porto', 62, '$2a$12$MNc5hziTP1o7ggBVOQLIW.EY0i2L3dMUobaOkhabxgjp7lIMJKnuy', 20);

INSERT INTO moderator (phone_number, authenticated_user_id) VALUES ('+351920678798', 1);
INSERT INTO moderator (phone_number, authenticated_user_id) VALUES ('+351920129382', 2);
INSERT INTO moderator (phone_number, authenticated_user_id) VALUES ('+351920465879', 3);
INSERT INTO moderator (phone_number, authenticated_user_id) VALUES ('+351920978689', 4);
INSERT INTO administrator (name, email, password, username, company_id, phone_number, residence) VALUES ('Joao Pedro', 'cchaudretd@va.gov', 'fpaCLk7bnz', 'spandeyg', '123', '351920938127', '4 Glendale Avenue');
INSERT INTO administrator (name, email, password, username, company_id, phone_number, residence) VALUES ('Andre Pereira', 'mcodneri@microsoft.com', 'vFHjP1lakCx', 'iarkleyi', '124', '351920093821', '4 Bobwhite Junction');

INSERT INTO tag (tag_id, name) values (1, 'football');
INSERT INTO tag (tag_id, name) values (2, 'surfing');
INSERT INTO tag (tag_id, name) values (3, 'fitness');
INSERT INTO tag (tag_id, name) values (4, 'voleyball');

insert into post (post_id, author_id, title, date, votes, description, tag_id) values (1, 16, 'Kit Kittredge: An American Girl', '2019-03-21 02:46:15', 0, 'Aliquam erat volutpat. In congue. Etiam justo. Etiam pretium iaculis justo. In hac habitasse platea dictumst.', 2);
insert into post (post_id, author_id, title, date, votes, description, tag_id) values (2, 15, 'Non-Stop', '2021-06-15 04:28:57', 0, 'Praesent id massa id nisl venenatis lacinia. Aenean sit amet justo. Morbi ut odio. Cras mi pede, malesuada in, imperdiet et, commodo vulputate, justo. In blandit ultrices enim. Lorem ipsum dolor sit amet, consectetuer adipiscing elit.', 4);
insert into post (post_id, author_id, title, date, votes, description, tag_id) values (3, 1, 'Ice Soldiers', '2017-01-16 14:51:28', 0, 'Duis ac nibh. Fusce lacus purus, aliquet at, feugiat non, pretium quis, lectus. Suspendisse potenti. In eleifend quam a odio. In hac habitasse platea dictumst. Maecenas ut massa quis augue luctus tincidunt. Nulla mollis molestie lorem. Quisque ut erat. Curabitur gravida nisi at nibh. In hac habitasse platea dictumst.', 4);
insert into post (post_id, author_id, title, date, votes, description, tag_id) values (4, 18, 'Battlestar Galactica: Razor', '2018-01-01 20:50:49', 0, 'Praesent lectus. Vestibulum quam sapien, varius ut, blandit non, interdum in, ante. Vestibulum ante ipsum primis in faucibus orci luctus et ultrices posuere cubilia Curae; Duis faucibus accumsan odio. Curabitur convallis. Duis consequat dui nec nisi volutpat eleifend. Donec ut dolor. Morbi vel lectus in quam fringilla rhoncus.', 1);
insert into post (post_id, author_id, title, date, votes, description, tag_id) values (5, 1, 'Diaries Notes and Sketches (Walden)', '2016-02-23 08:29:32', 0, 'Pellentesque eget nunc. Donec quis orci eget orci vehicula condimentum. Curabitur in libero ut massa volutpat convallis. Morbi odio odio, elementum eu, interdum eu, tincidunt in, leo. Maecenas pulvinar lobortis est. Phasellus sit amet erat. Nulla tempus.', 1);
insert into post (post_id, author_id, title, date, votes, description, tag_id) values (6, 13, 'Chance', '2015-12-27 06:23:45', 0, 'Pellentesque eget nunc.', 2);
insert into post (post_id, author_id, title, date, votes, description, tag_id) values (7, 9, 'Hanussen', '2019-10-28 15:17:59', 0, 'Integer tincidunt ante vel ipsum. Praesent blandit lacinia erat. Vestibulum sed magna at nunc commodo placerat. Praesent blandit. Nam nulla. Integer pede justo, lacinia eget, tincidunt eget, tempus vel, pede.', 4);
insert into post (post_id, author_id, title, date, votes, description, tag_id) values (8, 6, 'Special Relationship, The', '2016-04-10 12:25:08', 0, 'Suspendisse ornare consequat lectus. In est risus, auctor sed, tristique in, tempus sit amet, sem.', 1);
insert into post (post_id, author_id, title, date, votes, description, tag_id) values (9, 6, 'Search, The', '2019-03-15 10:45:36', 0, 'Vestibulum sed magna at nunc commodo placerat. Praesent blandit.', 2);
insert into post (post_id, author_id, title, date, votes, description, tag_id) values (10, 9, 'Miracle on 34th Street', '2017-10-11 03:32:54', 1, 'In est risus, auctor sed, tristique in, tempus sit amet, sem. Fusce consequat. Nulla nisl. Nunc nisl. Duis bibendum, felis sed interdum venenatis, turpis enim blandit mi, in porttitor pede justo eu massa. Donec dapibus.', 1);
insert into post (post_id, author_id, title, date, votes, description, tag_id) values (11, 6, 'Gunnin'' for That #1 Spot', '2018-10-22 09:42:26', 0, 'In sagittis dui vel nisl. Duis ac nibh. Fusce lacus purus, aliquet at, feugiat non, pretium quis, lectus. Suspendisse potenti. In eleifend quam a odio. In hac habitasse platea dictumst. Maecenas ut massa quis augue luctus tincidunt.', 2);
insert into post (post_id, author_id, title, date, votes, description, tag_id) values (12, 18, 'Hatful of Rain, A', '2016-02-15 22:42:06', 0, 'Donec odio justo, sollicitudin ut, suscipit a, feugiat et, eros. Vestibulum ac est lacinia nisi venenatis tristique. Fusce congue, diam id ornare imperdiet, sapien urna pretium nisl, ut volutpat sapien arcu sed augue. Aliquam erat volutpat.', 1);
insert into post (post_id, author_id, title, date, votes, description, tag_id) values (13, 2, 'Phar Lap', '2021-09-09 05:53:22', 0, 'Cras mi pede, malesuada in, imperdiet et, commodo vulputate, justo. In blandit ultrices enim. Lorem ipsum dolor sit amet, consectetuer adipiscing elit. Proin interdum mauris non ligula pellentesque ultrices. Phasellus id sapien in sapien iaculis congue. Vivamus metus arcu, adipiscing molestie, hendrerit at, vulputate vitae, nisl.', 4);
insert into post (post_id, author_id, title, date, votes, description, tag_id) values (14, 1, 'Henry', '2016-04-13 14:35:27', 0, 'Nullam orci pede, venenatis non, sodales sed, tincidunt eu, felis. Fusce posuere felis sed lacus.', 1);
insert into post (post_id, author_id, title, date, votes, description, tag_id) values (15, 4, 'Chuck & Buck', '2021-11-07 07:49:53', 0, 'Suspendisse potenti. Cras in purus eu magna vulputate luctus. Cum sociis natoque penatibus et magnis dis parturient montes, nascetur ridiculus mus. Vivamus vestibulum sagittis sapien. Cum sociis natoque penatibus et magnis dis parturient montes, nascetur ridiculus mus. Etiam vel augue. Vestibulum rutrum rutrum neque. Aenean auctor gravida sem. Praesent id massa id nisl venenatis lacinia. Aenean sit amet justo.', 1);
insert into post (post_id, author_id, title, date, votes, description, tag_id) values (16, 5, 'Protector, The (a.k.a. Warrior King) (Tom yum goong)', '2021-09-21 02:45:44', 0, 'Pellentesque viverra pede ac diam. Cras pellentesque volutpat dui. Maecenas tristique, est et tempus semper, est quam pharetra magna, ac consequat metus sapien ut nunc. Vestibulum ante ipsum primis in faucibus orci luctus et ultrices posuere cubilia Curae; Mauris viverra diam vitae quam. Suspendisse potenti. Nullam porttitor lacus at turpis. Donec posuere metus vitae ipsum. Aliquam non mauris. Morbi non lectus.', 3);
insert into post (post_id, author_id, title, date, votes, description, tag_id) values (17, 10, 'Space Odyssey: Voyage to the Planets', '2021-06-01 14:33:33', 0, 'Sed accumsan felis. Ut at dolor quis odio consequat varius.', 2);
insert into post (post_id, author_id, title, date, votes, description, tag_id) values (18, 3, 'Ticket To Romance (En enkelt til Korsør)', '2017-06-22 08:59:41', 0, 'In est risus, auctor sed, tristique in, tempus sit amet, sem. Fusce consequat. Nulla nisl. Nunc nisl. Duis bibendum, felis sed interdum venenatis, turpis enim blandit mi, in porttitor pede justo eu massa. Donec dapibus. Duis at velit eu est congue elementum.', 4);
insert into post (post_id, author_id, title, date, votes, description, tag_id) values (19, 15, 'Citizen Ruth', '2019-01-05 10:43:12', 0, 'Morbi a ipsum. Integer a nibh. In quis justo. Maecenas rhoncus aliquam lacus. Morbi quis tortor id nulla ultrices aliquet.', 3);
insert into post (post_id, author_id, title, date, votes, description, tag_id) values (20, 9, 'Rustlers'' Rhapsody', '2017-08-01 14:46:32', 1, 'Nulla nisl. Nunc nisl. Duis bibendum, felis sed interdum venenatis, turpis enim blandit mi, in porttitor pede justo eu massa. Donec dapibus. Duis at velit eu est congue elementum. In hac habitasse platea dictumst.', 1);
insert into post (post_id, author_id, title, date, votes, description, tag_id) values (21, 11, 'Tight Spot', '2021-05-13 15:16:15', 0, 'Mauris sit amet eros. Suspendisse accumsan tortor quis turpis. Sed ante. Vivamus tortor. Duis mattis egestas metus. Aenean fermentum. Donec ut mauris eget massa tempor convallis.', 2);
insert into post (post_id, author_id, title, date, votes, description, tag_id) values (22, 10, 'Whitecoats', '2020-01-15 01:55:07', 0, 'Donec dapibus. Duis at velit eu est congue elementum.', 2);
insert into post (post_id, author_id, title, date, votes, description, tag_id) values (23, 17, 'Wild Horses (Caballos salvajes)', '2020-03-29 12:38:21', 0, 'Donec quis orci eget orci vehicula condimentum. Curabitur in libero ut massa volutpat convallis. Morbi odio odio, elementum eu, interdum eu, tincidunt in, leo. Maecenas pulvinar lobortis est. Phasellus sit amet erat. Nulla tempus. Vivamus in felis eu sapien cursus vestibulum. Proin eu mi. Nulla ac enim. In tempor, turpis nec euismod scelerisque, quam turpis adipiscing lorem, vitae mattis nibh ligula nec sem.', 2);
insert into post (post_id, author_id, title, date, votes, description, tag_id) values (24, 20, 'Dreaming of Joseph Lees', '2016-03-27 19:44:53', 0, 'Donec diam neque, vestibulum eget, vulputate ut, ultrices vel, augue. Vestibulum ante ipsum primis in faucibus orci luctus et ultrices posuere cubilia Curae; Donec pharetra, magna vestibulum aliquet ultrices, erat tortor sollicitudin mi, sit amet lobortis sapien sapien non mi. Integer ac neque. Duis bibendum. Morbi non quam nec dui luctus rutrum. Nulla tellus.', 1);
insert into post (post_id, author_id, title, date, votes, description, tag_id) values (25, 10, 'Bling: A Planet Rock', '2016-09-12 13:59:37', 0, 'Suspendisse accumsan tortor quis turpis. Sed ante. Vivamus tortor. Duis mattis egestas metus. Aenean fermentum.', 2);
insert into post (post_id, author_id, title, date, votes, description, tag_id) values (26, 3, 'Young Frankenstein', '2020-12-04 07:21:14', 0, 'In sagittis dui vel nisl. Duis ac nibh. Fusce lacus purus, aliquet at, feugiat non, pretium quis, lectus. Suspendisse potenti. In eleifend quam a odio. In hac habitasse platea dictumst. Maecenas ut massa quis augue luctus tincidunt. Nulla mollis molestie lorem. Quisque ut erat. Curabitur gravida nisi at nibh.', 1);
insert into post (post_id, author_id, title, date, votes, description, tag_id) values (27, 20, 'Dentist, The', '2020-11-09 05:50:44', 0, 'Nunc nisl. Duis bibendum, felis sed interdum venenatis, turpis enim blandit mi, in porttitor pede justo eu massa. Donec dapibus. Duis at velit eu est congue elementum. In hac habitasse platea dictumst. Morbi vestibulum, velit id pretium iaculis, diam erat fermentum justo, nec condimentum neque sapien placerat ante. Nulla justo.', 3);
insert into post (post_id, author_id, title, date, votes, description, tag_id) values (28, 3, 'Iron Eagle', '2021-08-31 01:34:33', 0, 'Suspendisse ornare consequat lectus. In est risus, auctor sed, tristique in, tempus sit amet, sem. Fusce consequat. Nulla nisl. Nunc nisl. Duis bibendum, felis sed interdum venenatis, turpis enim blandit mi, in porttitor pede justo eu massa. Donec dapibus.', 3);
insert into post (post_id, author_id, title, date, votes, description, tag_id) values (29, 19, 'Land Before Time II: The Great Valley Adventure, The', '2020-09-24 20:12:04', 0, 'Mauris ullamcorper purus sit amet nulla. Quisque arcu libero, rutrum ac, lobortis vel, dapibus at, diam.', 2);
insert into post (post_id, author_id, title, date, votes, description, tag_id) values (30, 14, 'Drew: The Man Behind the Poster', '2019-05-01 16:47:31', 1, 'Integer ac leo. Pellentesque ultrices mattis odio. Donec vitae nisi. Nam ultrices, libero non mattis pulvinar, nulla pede ullamcorper augue, a suscipit nulla elit ac nulla. Sed vel enim sit amet nunc viverra dapibus. Nulla suscipit ligula in lacus. Curabitur at ipsum ac tellus semper interdum.', 4);
insert into post (post_id, author_id, title, date, votes, description, tag_id) values (31, 12, 'Let the Right One In (Låt den rätte komma in)', '2016-12-25 21:39:35', 0, 'Fusce lacus purus, aliquet at, feugiat non, pretium quis, lectus. Suspendisse potenti. In eleifend quam a odio. In hac habitasse platea dictumst. Maecenas ut massa quis augue luctus tincidunt. Nulla mollis molestie lorem. Quisque ut erat. Curabitur gravida nisi at nibh.', 3);
insert into post (post_id, author_id, title, date, votes, description, tag_id) values (32, 13, 'Flesh and the Devil', '2018-05-27 18:25:28', 0, 'Vestibulum rutrum rutrum neque. Aenean auctor gravida sem. Praesent id massa id nisl venenatis lacinia.', 1);
insert into post (post_id, author_id, title, date, votes, description, tag_id) values (33, 20, 'Creeping Terror, The (Crawling Monster, The)', '2017-12-20 07:43:28', 0, 'Morbi non quam nec dui luctus rutrum. Nulla tellus. In sagittis dui vel nisl. Duis ac nibh. Fusce lacus purus, aliquet at, feugiat non, pretium quis, lectus. Suspendisse potenti. In eleifend quam a odio. In hac habitasse platea dictumst. Maecenas ut massa quis augue luctus tincidunt.', 1);
insert into post (post_id, author_id, title, date, votes, description, tag_id) values (34, 10, 'Chaplin', '2021-03-18 04:14:21', 0, 'Cras non velit nec nisi vulputate nonummy. Maecenas tincidunt lacus at velit. Vivamus vel nulla eget eros elementum pellentesque. Quisque porta volutpat erat. Quisque erat eros, viverra eget, congue eget, semper rutrum, nulla.', 2);
insert into post (post_id, author_id, title, date, votes, description, tag_id) values (35, 7, 'Drinking Buddies', '2019-04-21 21:45:32', 0, 'Vestibulum quam sapien, varius ut, blandit non, interdum in, ante. Vestibulum ante ipsum primis in faucibus orci luctus et ultrices posuere cubilia Curae; Duis faucibus accumsan odio.', 4);
insert into post (post_id, author_id, title, date, votes, description, tag_id) values (36, 2, 'Tarzan', '2016-04-08 14:29:18', 0, 'Cum sociis natoque penatibus et magnis dis parturient montes, nascetur ridiculus mus. Etiam vel augue. Vestibulum rutrum rutrum neque. Aenean auctor gravida sem. Praesent id massa id nisl venenatis lacinia. Aenean sit amet justo.', 3);
insert into post (post_id, author_id, title, date, votes, description, tag_id) values (37, 3, 'Sundays and Cybele (Les dimanches de Ville d''Avray)', '2020-09-07 04:43:50', 0, 'Morbi non quam nec dui luctus rutrum. Nulla tellus. In sagittis dui vel nisl. Duis ac nibh.', 2);
insert into post (post_id, author_id, title, date, votes, description, tag_id) values (38, 15, 'Bouncing Babies', '2017-03-09 12:27:09', 0, 'Morbi vel lectus in quam fringilla rhoncus. Mauris enim leo, rhoncus sed, vestibulum sit amet, cursus id, turpis. Integer aliquet, massa id lobortis convallis, tortor risus dapibus augue, vel accumsan tellus nisi eu orci.', 2);
insert into post (post_id, author_id, title, date, votes, description, tag_id) values (39, 6, 'Signs of Life (Lebenszeichen)', '2018-06-01 12:21:18', 0, 'Curabitur gravida nisi at nibh. In hac habitasse platea dictumst. Aliquam augue quam, sollicitudin vitae, consectetuer eget, rutrum at, lorem.', 2);
insert into post (post_id, author_id, title, date, votes, description, tag_id) values (40, 13, 'Tales from the Crypt Presents: Bordello of Blood', '2020-04-23 00:05:14', 1, 'Fusce congue, diam id ornare imperdiet, sapien urna pretium nisl, ut volutpat sapien arcu sed augue. Aliquam erat volutpat.', 1);
insert into post (post_id, author_id, title, date, votes, description, tag_id) values (41, 5, 'Wiz, The', '2020-03-09 03:33:25', 0, 'Cum sociis natoque penatibus et magnis dis parturient montes, nascetur ridiculus mus.', 1);
insert into post (post_id, author_id, title, date, votes, description, tag_id) values (42, 18, 'And Soon the Darkness', '2021-03-06 22:25:28', 0, 'Cras non velit nec nisi vulputate nonummy. Maecenas tincidunt lacus at velit. Vivamus vel nulla eget eros elementum pellentesque. Quisque porta volutpat erat. Quisque erat eros, viverra eget, congue eget, semper rutrum, nulla. Nunc purus. Phasellus in felis.', 2);
insert into post (post_id, author_id, title, date, votes, description, tag_id) values (43, 11, 'The Humanoid', '2018-01-11 01:56:40', 0, 'Suspendisse potenti. Cras in purus eu magna vulputate luctus. Cum sociis natoque penatibus et magnis dis parturient montes, nascetur ridiculus mus. Vivamus vestibulum sagittis sapien. Cum sociis natoque penatibus et magnis dis parturient montes, nascetur ridiculus mus. Etiam vel augue.', 2);
insert into post (post_id, author_id, title, date, votes, description, tag_id) values (44, 2, 'Invisible Woman, The', '2021-04-28 12:08:00', 0, 'Vestibulum ante ipsum primis in faucibus orci luctus et ultrices posuere cubilia Curae; Duis faucibus accumsan odio. Curabitur convallis. Duis consequat dui nec nisi volutpat eleifend. Donec ut dolor. Morbi vel lectus in quam fringilla rhoncus. Mauris enim leo, rhoncus sed, vestibulum sit amet, cursus id, turpis. Integer aliquet, massa id lobortis convallis, tortor risus dapibus augue, vel accumsan tellus nisi eu orci. Mauris lacinia sapien quis libero.', 4);
insert into post (post_id, author_id, title, date, votes, description, tag_id) values (45, 7, 'Kika', '2020-07-03 16:41:03', 0, 'Pellentesque eget nunc. Donec quis orci eget orci vehicula condimentum. Curabitur in libero ut massa volutpat convallis. Morbi odio odio, elementum eu, interdum eu, tincidunt in, leo. Maecenas pulvinar lobortis est. Phasellus sit amet erat. Nulla tempus. Vivamus in felis eu sapien cursus vestibulum. Proin eu mi.', 1);
insert into post (post_id, author_id, title, date, votes, description, tag_id) values (46, 8, 'Cutie Honey', '2017-02-16 23:22:49', 0, 'Sed accumsan felis. Ut at dolor quis odio consequat varius. Integer ac leo. Pellentesque ultrices mattis odio. Donec vitae nisi. Nam ultrices, libero non mattis pulvinar, nulla pede ullamcorper augue, a suscipit nulla elit ac nulla. Sed vel enim sit amet nunc viverra dapibus. Nulla suscipit ligula in lacus.', 3);
insert into post (post_id, author_id, title, date, votes, description, tag_id) values (47, 1, 'Coneheads', '2016-03-26 22:59:11', 0, 'Duis aliquam convallis nunc. Proin at turpis a pede posuere nonummy. Integer non velit. Donec diam neque, vestibulum eget, vulputate ut, ultrices vel, augue. Vestibulum ante ipsum primis in faucibus orci luctus et ultrices posuere cubilia Curae; Donec pharetra, magna vestibulum aliquet ultrices, erat tortor sollicitudin mi, sit amet lobortis sapien sapien non mi. Integer ac neque.', 4);
insert into post (post_id, author_id, title, date, votes, description, tag_id) values (48, 3, 'Patton Oswalt: No Reason to Complain', '2017-07-13 10:49:30', 0, 'Pellentesque ultrices mattis odio. Donec vitae nisi. Nam ultrices, libero non mattis pulvinar, nulla pede ullamcorper augue, a suscipit nulla elit ac nulla. Sed vel enim sit amet nunc viverra dapibus. Nulla suscipit ligula in lacus. Curabitur at ipsum ac tellus semper interdum. Mauris ullamcorper purus sit amet nulla. Quisque arcu libero, rutrum ac, lobortis vel, dapibus at, diam. Nam tristique tortor eu pede.', 1);
insert into post (post_id, author_id, title, date, votes, description, tag_id) values (49, 6, 'Guyver, The', '2018-08-20 17:08:34', 0, 'Integer non velit. Donec diam neque, vestibulum eget, vulputate ut, ultrices vel, augue. Vestibulum ante ipsum primis in faucibus orci luctus et ultrices posuere cubilia Curae; Donec pharetra, magna vestibulum aliquet ultrices, erat tortor sollicitudin mi, sit amet lobortis sapien sapien non mi. Integer ac neque. Duis bibendum.', 4);
insert into post (post_id, author_id, title, date, votes, description, tag_id) values (50, 19, 'Seyyit Khan: Bride of the Earth (Seyyit Han)', '2018-02-28 15:42:35', 2, 'Aliquam augue quam, sollicitudin vitae, consectetuer eget, rutrum at, lorem.', 4);

INSERT INTO comment (comment_id, description, date, votes, post_id) VALUES (1, 'This is a NULL comment and you can edit it anytime to make this application look better.', '2021-02-24T10:05:36Z', 426, 31);
INSERT INTO comment (comment_id, description, date, votes, post_id) VALUES (2, 'This is a NULL comment and you can edit it anytime to make this application look better.', '2021-02-13T11:45:08Z', 40, 1);
INSERT INTO comment (comment_id, description, date, votes, post_id) VALUES (3, 'This is a NULL comment and you can edit it anytime to make this application look better.', '2020-12-08T04:06:47Z', 443, 1);
INSERT INTO comment (comment_id, description, date, votes, post_id) VALUES (4, 'This is a NULL comment and you can edit it anytime to make this application look better.', '2021-07-20T21:14:11Z', 542, 36);
INSERT INTO comment (comment_id, description, date, votes, post_id) VALUES (5, 'This is a NULL comment and you can edit it anytime to make this application look better.', '2021-06-26T12:18:33Z', 789, 31);
INSERT INTO comment (comment_id, description, date, votes, post_id) VALUES (6, 'This is a NULL comment and you can edit it anytime to make this application look better.', '2021-01-18T19:06:26Z', 760, 34);
INSERT INTO comment (comment_id, description, date, votes, post_id) VALUES (7, 'This is a NULL comment and you can edit it anytime to make this application look better.', '2021-04-03T07:21:14Z', 327, 47);
INSERT INTO comment (comment_id, description, date, votes, post_id) VALUES (8, 'This is a NULL comment and you can edit it anytime to make this application look better.', '2021-07-04T15:04:30Z', 171, 45);
INSERT INTO comment (comment_id, description, date, votes, post_id) VALUES (9, 'This is a NULL comment and you can edit it anytime to make this application look better.', '2021-11-18T07:59:39Z', 619, 16);
INSERT INTO comment (comment_id, description, date, votes, post_id) VALUES (10, 'This is a NULL comment and you can edit it anytime to make this application look better.', '2021-03-22T12:11:31Z', 560, 29);
INSERT INTO comment (comment_id, description, date, votes, post_id) VALUES (11, 'This is a NULL comment and you can edit it anytime to make this application look better.', '2021-10-01T12:37:26Z', 221, 30);
INSERT INTO comment (comment_id, description, date, votes, post_id) VALUES (12, 'This is a NULL comment and you can edit it anytime to make this application look better.', '2021-05-30T10:03:24Z', 431, 34);
INSERT INTO comment (comment_id, description, date, votes, post_id) VALUES (13, 'This is a NULL comment and you can edit it anytime to make this application look better.', '2021-01-20T00:34:32Z', 385, 9);
INSERT INTO comment (comment_id, description, date, votes, post_id) VALUES (14, 'This is a NULL comment and you can edit it anytime to make this application look better.', '2021-11-06T00:47:15Z', 130, 30);
INSERT INTO comment (comment_id, description, date, votes, post_id) VALUES (15, 'This is a NULL comment and you can edit it anytime to make this application look better.', '2021-02-19T07:01:55Z', 496, 40);
INSERT INTO comment (comment_id, description, date, votes, post_id) VALUES (16, 'This is a NULL comment and you can edit it anytime to make this application look better.', '2021-05-15T05:02:53Z', 781, 47);
INSERT INTO comment (comment_id, description, date, votes, post_id) VALUES (17, 'This is a NULL comment and you can edit it anytime to make this application look better.', '2021-08-20T22:46:25Z', 927, 22);
INSERT INTO comment (comment_id, description, date, votes, post_id) VALUES (18, 'This is a NULL comment and you can edit it anytime to make this application look better.', '2021-08-23T03:39:13Z', 300, 37);
INSERT INTO comment (comment_id, description, date, votes, post_id) VALUES (19, 'This is a NULL comment and you can edit it anytime to make this application look better.', '2021-10-21T01:37:03Z', 871, 2);
INSERT INTO comment (comment_id, description, date, votes, post_id) VALUES (20, 'This is a NULL comment and you can edit it anytime to make this application look better.', '2021-07-15T16:20:28Z', 789, 8);

INSERT INTO report_post (report_post_id, description, post_id, user_id) VALUES (1, 'adult content', 10, 14);
INSERT INTO report_post (report_post_id, description, post_id, user_id) VALUES (2, 'strong political view', 21, 11);
INSERT INTO report_post (report_post_id, description, post_id, user_id) VALUES (3, 'copyrighted content', 25, 3);
INSERT INTO report_post (report_post_id, description, post_id, user_id) VALUES (4, 'blood', 44, 9);

INSERT INTO report_comment (report_comment_id, description, comment_id, user_id) VALUES (1, 'stolen comment', 10, 9);
INSERT INTO report_comment (report_comment_id, description, comment_id, user_id) VALUES (2, 'spam', 16, 13);
INSERT INTO report_comment (report_comment_id, description, comment_id, user_id) VALUES (3, 'link to unkown website', 13, 1);
INSERT INTO report_comment (report_comment_id, description, comment_id, user_id) VALUES (4, 'fake user', 3, 19);

INSERT INTO liked_posts (user_id, post_id, down_or_upvote) VALUES (1, 10, '1');
INSERT INTO liked_posts (user_id, post_id, down_or_upvote) VALUES (1, 20, '1');
INSERT INTO liked_posts (user_id, post_id, down_or_upvote) VALUES (15, 30, '1');
INSERT INTO liked_posts (user_id, post_id, down_or_upvote) VALUES (20, 40, '1');
INSERT INTO liked_posts (user_id, post_id, down_or_upvote) VALUES (18, 50, '1');
INSERT INTO liked_posts (user_id, post_id, down_or_upvote) VALUES (3, 50, '1');

INSERT INTO user_comments (user_id, comment_id) VALUES (1, 2);
INSERT INTO user_comments (user_id, comment_id) VALUES (2, 3);
-- INSERT INTO user_comments (user_id, comment_id) VALUES (10, 20);
INSERT INTO user_comments (user_id, comment_id) VALUES (4, 5);

insert into media (url, post_id, comment_id) values ('http://dummyimage.com/209x100.png/dddddd/000000', 26, 3);
insert into media (url, post_id, comment_id) values ('http://dummyimage.com/141x100.png/cc0000/ffffff', 34, 8);
insert into media (url, post_id, comment_id) values ('http://dummyimage.com/190x100.png/dddddd/000000', 10, 18);
insert into media (url, post_id, comment_id) values ('http://dummyimage.com/234x100.png/cc0000/ffffff', 14, 2);
insert into media (url, post_id, comment_id) values ('http://dummyimage.com/171x100.png/cc0000/ffffff', 16, 4);
insert into media (url, post_id, comment_id) values ('http://dummyimage.com/243x100.png/dddddd/000000', 48, 6);
insert into media (url, post_id, comment_id) values ('http://dummyimage.com/210x100.png/cc0000/ffffff', 26, 13);
insert into media (url, post_id, comment_id) values ('http://dummyimage.com/186x100.png/5fa2dd/ffffff', 44, 11);
insert into media (url, post_id, comment_id) values ('http://dummyimage.com/148x100.png/dddddd/000000', 1, 15);
insert into media (url, post_id, comment_id) values ('http://dummyimage.com/181x100.png/cc0000/ffffff', 45, 4);
insert into media (url, post_id, comment_id) values ('http://dummyimage.com/119x100.png/5fa2dd/ffffff', 38, 19);
insert into media (url, post_id, comment_id) values ('http://dummyimage.com/101x100.png/dddddd/000000', 40, 18);
insert into media (url, post_id, comment_id) values ('http://dummyimage.com/170x100.png/cc0000/ffffff', 41, 13);
insert into media (url, post_id, comment_id) values ('http://dummyimage.com/148x100.png/ff4444/ffffff', 48, 1);
insert into media (url, post_id, comment_id) values ('http://dummyimage.com/136x100.png/ff4444/ffffff', 47, 9);
insert into media (url, post_id, comment_id) values ('http://dummyimage.com/192x100.png/5fa2dd/ffffff', 35, 19);
insert into media (url, post_id, comment_id) values ('http://dummyimage.com/161x100.png/dddddd/000000', 7, 2);
insert into media (url, post_id, comment_id) values ('http://dummyimage.com/126x100.png/cc0000/ffffff', 3, 3);
insert into media (url, post_id, comment_id) values ('http://dummyimage.com/106x100.png/cc0000/ffffff', 39, 6);
insert into media (url, post_id, comment_id) values ('http://dummyimage.com/111x100.png/ff4444/ffffff', 49, 1);
insert into media (url, post_id, comment_id) values ('http://dummyimage.com/203x100.png/5fa2dd/ffffff', 47, 5);
insert into media (url, post_id, comment_id) values ('http://dummyimage.com/178x100.png/5fa2dd/ffffff', 49, 3);
insert into media (url, post_id, comment_id) values ('http://dummyimage.com/134x100.png/dddddd/000000', 44, 19);
insert into media (url, post_id, comment_id) values ('http://dummyimage.com/243x100.png/ff4444/ffffff', 22, 9);
insert into media (url, post_id, comment_id) values ('http://dummyimage.com/220x100.png/ff4444/ffffff', 35, 13);
insert into media (url, post_id, comment_id) values ('http://dummyimage.com/189x100.png/cc0000/ffffff', 37, 3);
insert into media (url, post_id, comment_id) values ('http://dummyimage.com/215x100.png/dddddd/000000', 31, 17);
insert into media (url, post_id, comment_id) values ('http://dummyimage.com/162x100.png/cc0000/ffffff', 16, 20);
insert into media (url, post_id, comment_id) values ('http://dummyimage.com/149x100.png/cc0000/ffffff', 13, 7);
insert into media (url, post_id, comment_id) values ('http://dummyimage.com/246x100.png/ff4444/ffffff', 3, 15);
insert into media (url, post_id, comment_id) values ('http://dummyimage.com/199x100.png/ff4444/ffffff', 8, 19);
insert into media (url, post_id, comment_id) values ('http://dummyimage.com/198x100.png/ff4444/ffffff', 38, 12);
insert into media (url, post_id, comment_id) values ('http://dummyimage.com/218x100.png/cc0000/ffffff', 2, 2);
insert into media (url, post_id, comment_id) values ('http://dummyimage.com/249x100.png/5fa2dd/ffffff', 24, 17);
insert into media (url, post_id, comment_id) values ('http://dummyimage.com/191x100.png/cc0000/ffffff', 22, 6);
insert into media (url, post_id, comment_id) values ('http://dummyimage.com/191x100.png/5fa2dd/ffffff', 38, 3);
insert into media (url, post_id, comment_id) values ('http://dummyimage.com/118x100.png/dddddd/000000', 25, 1);
insert into media (url, post_id, comment_id) values ('http://dummyimage.com/180x100.png/cc0000/ffffff', 46, 12);
insert into media (url, post_id, comment_id) values ('http://dummyimage.com/235x100.png/cc0000/ffffff', 36, 8);
insert into media (url, post_id, comment_id) values ('http://dummyimage.com/178x100.png/ff4444/ffffff', 22, 19);
insert into media (url, post_id, comment_id) values ('http://dummyimage.com/140x100.png/5fa2dd/ffffff', 8, 20);
insert into media (url, post_id, comment_id) values ('http://dummyimage.com/178x100.png/cc0000/ffffff', 21, 14);
insert into media (url, post_id, comment_id) values ('http://dummyimage.com/160x100.png/5fa2dd/ffffff', 29, 8);
insert into media (url, post_id, comment_id) values ('http://dummyimage.com/127x100.png/dddddd/000000', 30, 7);
insert into media (url, post_id, comment_id) values ('http://dummyimage.com/228x100.png/dddddd/000000', 23, 4);
insert into media (url, post_id, comment_id) values ('http://dummyimage.com/100x100.png/dddddd/000000', 20, 12);
insert into media (url, post_id, comment_id) values ('http://dummyimage.com/248x100.png/ff4444/ffffff', 42, 18);

INSERT INTO following (authenticated_user_id1,authenticated_user_id2) VALUES (18,4);
INSERT INTO following (authenticated_user_id1,authenticated_user_id2) VALUES (12,3);
INSERT INTO following (authenticated_user_id1,authenticated_user_id2) VALUES (11,3);
INSERT INTO following (authenticated_user_id1,authenticated_user_id2) VALUES (10,20);
INSERT INTO following (authenticated_user_id1,authenticated_user_id2) VALUES (11,4);
INSERT INTO following (authenticated_user_id1,authenticated_user_id2) VALUES (20,19);
INSERT INTO following (authenticated_user_id1,authenticated_user_id2) VALUES (14,19);
INSERT INTO following (authenticated_user_id1,authenticated_user_id2) VALUES (20,10);
INSERT INTO following (authenticated_user_id1,authenticated_user_id2) VALUES (19,13);
INSERT INTO following (authenticated_user_id1,authenticated_user_id2) VALUES (18,1);
INSERT INTO following (authenticated_user_id1,authenticated_user_id2) VALUES (17,1);
INSERT INTO following (authenticated_user_id1,authenticated_user_id2) VALUES (1,9);
INSERT INTO following (authenticated_user_id1,authenticated_user_id2) VALUES (11,1);
INSERT INTO following (authenticated_user_id1,authenticated_user_id2) VALUES (17,10);
INSERT INTO following (authenticated_user_id1,authenticated_user_id2) VALUES (3,9);
INSERT INTO following (authenticated_user_id1,authenticated_user_id2) VALUES (1,12);
INSERT INTO following (authenticated_user_id1,authenticated_user_id2) VALUES (18,15);
INSERT INTO following (authenticated_user_id1,authenticated_user_id2) VALUES (16,19);
INSERT INTO following (authenticated_user_id1,authenticated_user_id2) VALUES (14,10);
INSERT INTO following (authenticated_user_id1,authenticated_user_id2) VALUES (6,19);