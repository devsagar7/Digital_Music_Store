CREATE DATABASE music_database;
USE music_database;

-- viewing the db tables
SELECT * FROM album;
SELECT * FROM artist;
SELECT * FROM customer;
SELECT * FROM employee;
SELECT * FROM genre;
SELECT * FROM invoice;
SELECT * FROM invoice_line;
SELECT * FROM media_type;
SELECT * FROM playlist;
SELECT * FROM playlist_track;
SELECT * FROM track;



-- Linking tables with other tables with respect to the foreign key

-- INVOICE & CUSTOMER
CREATE INDEX idx_customer_id ON customer(customer_id);
ALTER TABLE invoice
ADD CONSTRAINT fk_customer_id
FOREIGN KEY (customer_id) 
REFERENCES customer(customer_id);

-- INVOICE & INVOICELINE
CREATE INDEX idx_invoice_id ON invoice(invoice_id);
ALTER TABLE invoice_line
ADD CONSTRAINT fk_invoice_id
FOREIGN KEY (invoice_id) 
REFERENCES invoice(invoice_id);


-- INVOICELINE & TRACK
CREATE INDEX idx_track_id ON track(track_id);
ALTER TABLE invoice_line
ADD CONSTRAINT fk_track_id
FOREIGN KEY (track_id) 
REFERENCES track(track_id);

-- TRACK & MEDIATYPE
CREATE INDEX idx_media_type_id ON media_type(media_type_id);
ALTER TABLE track
ADD CONSTRAINT fk_media_type_id
FOREIGN KEY (media_type_id)
REFERENCES media_type(media_type_id);

-- TRACK & GENRE
CREATE INDEX idx_genre_id ON genre(genre_id);
ALTER TABLE track
ADD CONSTRAINT fk_genre_id
FOREIGN KEY (genre_id)
REFERENCES genre(genre_id);

-- TRACK & ALBUM
CREATE INDEX idx_album_id ON album(album_id);
ALTER TABLE track
ADD CONSTRAINT fk_album_id
FOREIGN KEY (album_id)
REFERENCES album(album_id);

-- TRACK & PLAYLIST_TRACK
ALTER TABLE playlist_track
ADD CONSTRAINT fk_playlist_track_id
FOREIGN KEY (track_id)
REFERENCES track(track_id);

-- ALBUM & ARTIST
CREATE INDEX idx_artist_id ON artist(artist_id);
ALTER TABLE album
ADD CONSTRAINT fk_artist_id
FOREIGN KEY (artist_id)
REFERENCES artist(artist_id);

-- PLAYLIST & PLAYLIST_TRACK
CREATE INDEX idx_playlist_id ON playlist(playlist_id);
ALTER TABLE playlist_track
ADD CONSTRAINT fk_playlist_id
FOREIGN KEY (playlist_id)
REFERENCES playlist(playlist_id);


-- Easy Questions --

-- 1. Who is the senior most employee based on job title?
SELECT * FROM employee ORDER BY levels DESC LIMIT 1;

-- 2. Which countries have the most Invoices?
SELECT COUNT(*) AS Cnt, billing_country FROM invoice GROUP BY billing_country ORDER BY Cnt DESC;

-- 3. What are top 3 values of total invoice?
SELECT total FROM invoice ORDER BY total DESC LIMIT 3;

-- 4. Which city has the best customers? We would like to throw a promotional Music Festival in the city 
-- where we made the most money. 
-- Write a query that returns one city that has the highest sum of invoice totals. 
-- Return both the city name & sum of all invoice totals
SELECT SUM(total) AS invoice_total, billing_city FROM invoice 
GROUP BY billing_city 
ORDER BY invoice_total DESC LIMIT 1;

-- 5. Who is the best customer? The customer who has spent the most money will be declared the best customer.
--  Write a query that returns the person who has spent the most money.
SELECT customer.customer_id, customer.first_name, customer.last_name, customer.city, SUM(invoice.total) AS most_spend
FROM customer
JOIN invoice ON customer.customer_id = invoice.customer_id
GROUP BY customer.customer_id, customer.first_name, customer.last_name, customer.city
ORDER BY most_spend DESC LIMIT 1;



-- Moderate Questions --

-- 1. Write query to return the email, first name, last name, & Genre of all Rock Music listeners.
-- Return your list ordered alphabetically by email starting with A
SELECT DISTINCT email, first_name, last_name 
FROM customer
JOIN invoice ON invoice.customer_id = customer.customer_id
JOIN invoice_line ON invoice_line.invoice_id = invoice.invoice_id
WHERE track_id IN (			-- Inner Query
	SELECT track_id FROM track JOIN genre ON track.genre_id = genre.genre_id
	WHERE genre.name LIKE 'Rock'
)
ORDER BY email;

-- 2. Let's invite the artists who have written the most rock music in our dataset. 
-- Write a query that returns the Artist name and total track count of the top 10 rock bands
SELECT artist.name, COUNT(artist.artist_id) AS Number_of_tracks
FROM track
JOIN album ON album.album_id = track.album_id
JOIN artist ON artist.artist_id = album.artist_id
JOIN genre ON genre.genre_id = track.genre_id
WHERE genre.name LIKE 'Rock'
GROUP BY artist.name
ORDER BY Number_of_tracks DESC
LIMIT 10;

-- 3. Return all the track names that have a song length longer than the average song length. 
-- Return the Name and Milliseconds for each track. 
-- Order by the song length with the longest songs listed first
SELECT name, milliseconds
FROM track 
WHERE milliseconds > 
	(SELECT AVG(milliseconds) AS avg_track_len FROM track)
ORDER BY milliseconds DESC;


-- Advance Questions --

-- 1. Find how much amount spent by each customer on artists? 
-- Write a query to return customer name, artist name and total spent

-- -> UNIT PRICE * PRODUCT_QUANTITY to get the amount which spend by the consumer to purchase the songs of artist
SELECT c.first_name, c.last_name, art.name AS artist_name, 
SUM(il.unit_price * il.quantity) AS total_spent
FROM invoice AS i
JOIN customer AS c ON c.customer_id = i.customer_id
JOIN invoice_line AS il ON il.invoice_id = i.invoice_id
JOIN track AS t ON t.track_id = il.track_id
JOIN album AS alb ON alb.album_id = t.album_id
JOIN artist AS art ON art.artist_id = alb.artist_id
GROUP BY 1, 2, 3
ORDER BY 4 DESC;



-- 2. We want to find out the most popular music Genre for each country. We determine the 
-- most popular genre as the genre with the highest amount of purchases. Write a query 
-- that returns each country along with the top Genre. For countries where the maximum 
-- number of purchases is shared return all Genres

-- WITHOUT FILTERING OUT ON THE BASIS OF ROW_NUMBER()
WITH popular_genre AS (	
    SELECT COUNT(invoice_line.quantity) AS purchases, customer.country, genre.name, genre.genre_id 
    FROM invoice_line 
	JOIN invoice ON invoice.invoice_id = invoice_line.invoice_id
	JOIN customer ON customer.customer_id = invoice.customer_id
	JOIN track ON track.track_id = invoice_line.track_id
	JOIN genre ON genre.genre_id = track.genre_id
	GROUP BY 2,3,4
	ORDER BY 2 ASC, 1 DESC
)
SELECT * FROM popular_genre;


WITH popular_genre AS (
    SELECT COUNT(invoice_line.quantity) AS total_purchases, 
    customer.country AS country_name, 
    genre.name AS name_of_genre,
    genre.genre_id AS genre_id_num
    FROM invoice_line
    JOIN invoice ON invoice.invoice_id = invoice_line.invoice_id
    JOIN customer ON customer.customer_id = invoice.customer_id
    JOIN track ON track.track_id = invoice_line.track_id
    JOIN genre ON track.genre_id = genre.genre_id
    GROUP BY country_name, name_of_genre, genre_id_num
    ORDER BY country_name ASC, total_purchases DESC
)
SELECT * FROM popular_genre;

-- FILTERING ON THE BASIS OF ROW_NUMBER()
WITH popular_genre AS (
    SELECT COUNT(invoice_line.quantity) AS total_purchases, 
    customer.country AS country_name, 
    genre.name AS name_of_genre,
    genre.genre_id AS genre_id_num,
    ROW_NUMBER() OVER(PARTITION BY customer.country ORDER BY COUNT(invoice_line.quantity) DESC) AS RowNo
    FROM invoice_line
    JOIN invoice ON invoice.invoice_id = invoice_line.invoice_id
    JOIN customer ON customer.customer_id = invoice.customer_id
    JOIN track ON track.track_id = invoice_line.track_id
    JOIN genre ON track.genre_id = genre.genre_id
    GROUP BY country_name, name_of_genre, genre_id_num
    ORDER BY country_name ASC, total_purchases DESC
)
SELECT * FROM popular_genre WHERE RowNo <= 1;



-- 3. Write a query that determines the customer that has spent the most on music for each country. 
-- Write a query that returns the country along with the top customer and how much they spent.
-- For countries where the top amount spent is shared, provide all customers who spent this amount

WITH customer_with_most_spent AS (
	SELECT c.customer_id, c.first_name, c.last_name, inv.billing_country, SUM(inv.total) AS total_spendings,
    ROW_NUMBER() OVER(PARTITION BY billing_country ORDER BY SUM(total) DESC) AS RowNo
    FROM invoice AS inv
    JOIN customer AS c ON c.customer_id = inv.customer_id
    GROUP BY 1,2,3,4
    ORDER BY 1, 4 DESC)
SELECT * FROM customer_with_most_spent WHERE RowNo <= 1;