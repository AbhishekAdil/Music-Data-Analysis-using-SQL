/*	Question Set 1 - Easy */

/* Q1: Who is the senior most employee based on job title? */

SELECT * FROM employee
ORDER BY levels DESC
LIMIT 1;  -- TO SEE ONLY FIRST ROW

/* Q2: Which countries have the most Invoices? */

SELECT * FROM invoice

SELECT billing_country, COUNT(*) AS c
FROM invoice
GROUP BY billing_country
ORDER BY c DESC;

/* Q3: What are top 3 values of total invoice? */

SELECT * FROM invoice;

SELECT total FROM invoice
ORDER BY total DESC
LIMIT 3;

/* Q4: Which city has the best customers? We would like to throw a promotional Music
Festival in the city we made the most money. Write a query that returns one city that 
has the highest sum of invoice totals. Return both the city name & sum of all invoice
totals*/

SELECT * FROM invoice;

SELECT billing_city, SUM(total) AS invoice_total
FROM invoice
GROUP BY billing_city
ORDER by invoice_total DESC;

/* Q5: Who is the best customer? THe customer who has spend the most money will be 
declared the best customer. Write a query that returns the person who has spent the
most money */

SELECT * FROM customer;
SELECT * FROM invoice;

/* we don't have total invoice column in customer table. So we have to join the 
customer and invoice table */

SELECT customer.customer_id, customer.first_name, customer.last_name, SUM(invoice.total) AS total
FROM customer
JOIN invoice ON customer.customer_id = invoice.customer_id
GROUP BY customer.customer_id -- group so if one customer order more than 1 time
ORDER BY total DESC
LIMIT 1;


/*	Question Set 2 - Moderate */

/*	Q1: Write query to return the email, first name, last name, and Gerne of
all Rock Music Listeners. Return your list ordered alphabetically bt email
starting with A*/

SELECT * FROM customer;
SELECT * FROM gerne;

-- connect the tables on the basis of schema

SELECT DISTINCT email, first_name, last_name
FROM customer
JOIN invoice ON customer.customer_id = invoice.customer_id
JOIN invoice_line ON invoice.invoice_id = invoice_line.invoice_id
WHERE track_id IN(
	SELECT track_id 
	FROM track
	JOIN genre ON track.genre_id = genre.genre_id
	WHERE genre.name LIKE 'Rock'
)
ORDER BY email;

/* Q2: Let's invite the artists who have written the most rock music in our dataset.
Write a query that returns the Artist name and total track count of the top 10 
rock bands.*/

SELECT artist.artist_id, artist.name, COUNT(artist.artist_id) AS number_of_songs
FROM artist 
JOIN album ON artist.artist_id = album.artist_id
JOIN track ON album.album_id = track.album_id
JOIN genre ON track.genre_id = genre.genre_id
WHERE genre.name LIKE 'Rock'
GROUP BY artist.artist_id
ORDER BY number_of_songs DESC
LIMIT 10;

/* Q3: Retrun all the tracks names that have a song length longer than the average
song length. Return the Name and Milliseconds for each track. order by the song length
listed first */

SELECT * FROM track;

SELECT name, milliseconds
FROM track
WHERE milliseconds > (
	SELECT AVG(milliseconds) AS avg_track_length
	FROM track)
ORDER BY milliseconds DESC;


/* Question Set 3 - Advance*/

/* Q1: Find how much amount spent by each customer on artists? Write a query to 
return customer name, artist name and total spend. */

-- using CTE(create temporary table)

WITH best_selling_artist AS(
	SELECT artist.artist_id AS artist_id, artist.name AS artist_name,
	SUM(invoice_line.unit_price * invoice_line.quantity) AS total_sales
	FROM invoice_line
	JOIN track ON track.track_id = invoice_line.track_id
	JOIN album ON album.album_id = track.album_id
	JOIN artist ON artist.artist_id = album.artist_id
	GROUP BY 1    -- 1 -> artist_id
	ORDER BY total_sales DESC      -- total_sales can be written as 3
	LIMIT 1
)

-- c -> customer
-- bsa -> best_selling_artist
-- il -> invoice_line
-- i -> invoice
-- t -> track
-- alb -> album

SELECT c.customer_id, c.first_name, c.last_name, bsa.artist_name,
SUM(il.unit_price * il.quantity) AS amount_Spent
FROM customer c
JOIN invoice i ON c.customer_id = i.customer_id
JOIN invoice_line il ON il.invoice_id = i.invoice_id
JOIN track t ON il.track_id = t.track_id
JOIN album alb ON alb.album_id = t.album_id
JOIN best_selling_artist bsa ON bsa.artist_id = alb.artist_id
GROUP BY 1, 2, 3, 4
ORDER BY 5 DESC;

/* Q2: We want to find out the most popular music Genre for each country. 
We determine the most popular genre as the genre with the highest amount 
of purchases. Write a query that returns each country along with the top
Genre. For countries where the maximum number of purchar is shared return 
all genres. */

-- Method 1

WITH popular_genre AS (
	SELECT COUNT(invoice_line.quantity) AS purchase, customer.country, genre.name, genre.genre_id,
	ROW_NUMBER() OVER(PARTITION BY customer.country ORDER BY COUNT(invoice_line.quantity) DESC) AS RowNo
	FROM invoice
	JOIN invoice_line ON invoice.invoice_id = invoice_line.invoice_id
	JOIN customer ON customer.customer_id = invoice.customer_id
	JOIN track ON track.track_id = invoice_line.track_id
	JOIN genre ON genre.genre_id = track.genre_id
	GROUP BY 2, 3, 4  -- column number
	ORDER BY 2 ASC, 1 DESC
)
SELECT * FROM popular_genre WHERE RowNo <= 1;

-- Method 2

WITH RECURSIVE
	sales_per_country AS(
		SELECT COUNT(*) AS purchase_per_genre, customer.country AS country, genre.name, 
		genre.genre_id
		FROM invoice_line
		JOIN invoice ON invoice.invoice_id = invoice_line.invoice_id
		JOIN customer ON customer.customer_id = invoice.customer_id
		JOIN track ON track.track_id = invoice_line.track_id
		JOIN genre ON genre.genre_id = track.genre_id
		GROUP BY 2, 3, 4
		ORDER BY 2
	),
	max_genre_per_country AS(
		SELECT MAX(purchase_per_genre) AS max_genre_number, country
		FROM sales_per_country
		GROUP BY 2
		ORDER BY 2
		)

SELECT sales_per_country.*
FROM sales_per_country
JOIN max_genre_per_country ON sales_per_country.country = max_genre_per_country.country
WHERE sales_per_country.purchase_per_genre = max_genre_per_country.max_genre_number;


/* Q3: Write a query that determines the customer that has spent the most on 
music for each country. Write a query that returns the country along with the
top customer and how they spent. For countries where the top amount spent is
shared, provide all customers who spent this amount*/

-- Method 1

WITH RECURSIVE
	customer_with_country AS(
		SELECT customer.customer_id,first_name,last_name,billing_country, SUM(total) AS total_spending
		FROM customer
		JOIN invoice ON customer.customer_id = invoice.customer_id
		GROUP BY 1, 2, 3, 4
		ORDER BY 1, 5 DESC
	),
	country_max_spending AS(
		SELECT billing_country, MAX(total_spending) AS max_spending
		FROM customer_with_country
		GROUP BY billing_country
	)

SELECT cc.billing_country, cc.total_spending, cc.first_name, cc.last_name, cc.customer_id
FROM customer_with_country cc
JOIN country_max_spending ms
ON cc.billing_country = ms.billing_country
WHERE cc.total_spending = ms.max_spending
ORDER BY 1;

-- Method 2

WITH customer_with_country AS(
	SELECT customer.customer_id,first_name,last_name,billing_country,SUM(total) AS total_spending,
	ROW_NUMBER() OVER(PARTITION BY billing_country ORDER BY SUM(total) DESC) AS RowNo
	FROM invoice
	JOIN customer ON customer.customer_id = invoice.customer_id
	GROUP BY 1, 2, 3, 4
	ORDER BY 4 ASC, 5 DESC
)
SELECT * FROM customer_with_country WHERE RowNo <= 1;