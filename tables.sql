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
	reputation TEXT,
	password TEXT NOT NULL,
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