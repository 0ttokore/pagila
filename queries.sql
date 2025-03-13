--1
WITH category_film_count AS (
    SELECT c.name AS "Category", COUNT(fc.film_id) AS "number_of_films"
    FROM category c
    JOIN film_category fc ON fc.category_id = c.category_id
    GROUP BY c.name
)
SELECT * FROM category_film_count
ORDER BY "number_of_films" DESC;

--2
WITH actor_rental_count AS (
    SELECT a.first_name || ' ' || a.last_name AS "Actor", COUNT(r.rental_id) AS "Count"
    FROM actor a
    JOIN film_actor fa ON a.actor_id = fa.actor_id
    JOIN inventory i ON i.film_id = fa.film_id
    JOIN rental r ON r.inventory_id = i.inventory_id
    GROUP BY a.first_name, a.last_name
)
SELECT * FROM actor_rental_count
ORDER BY "Count" DESC
LIMIT 10;

--3
WITH payment_count AS (
    SELECT c.name AS "Category", COUNT(p.amount) AS "Count"
    FROM category c
    JOIN film_category fc ON fc.category_id = c.category_id
    JOIN inventory i ON i.film_id = fc.film_id
    JOIN rental r ON r.inventory_id = i.inventory_id
    JOIN payment p ON p.rental_id = r.rental_id
    GROUP BY c.name
)
SELECT * FROM payment_count
ORDER BY "Count" DESC
LIMIT 1;

--4 without IN
SELECT f.title FROM film f
LEFT JOIN inventory i ON i.film_id = f.film_id
WHERE i.inventory_id IS NULL;

--4 IN
SELECT title
FROM film
WHERE film_id NOT IN (SELECT film_id FROM inventory);

--5
WITH ranked_actors AS (
    SELECT 
        a.first_name || ' ' || a.last_name AS "Actor", 
        COUNT(fa.film_id) AS "Count",
        DENSE_RANK() OVER (ORDER BY COUNT(fa.film_id) DESC) AS rank
    FROM actor a
    JOIN film_actor fa ON fa.actor_id = a.actor_id
    JOIN film_category fc ON fc.film_id = fa.film_id
    JOIN category c ON c.category_id = fc.category_id
    WHERE c.name = 'Children'
    GROUP BY "Actor"
)
SELECT "Actor", "Count", rank 
FROM ranked_actors
WHERE rank <= 3
ORDER BY rank;

--6
WITH client_status AS (
    SELECT 
        c.city, 
        COUNT(CASE WHEN ct.active = 1 THEN 1 END) AS active_clients,
        COUNT(CASE WHEN ct.active = 0 THEN 1 END) AS inactive_clients
    FROM city c
    JOIN address adr ON adr.city_id = c.city_id
    JOIN customer ct ON ct.address_id = adr.address_id
    GROUP BY c.city
)
SELECT * FROM client_status
ORDER BY inactive_clients DESC;

--7
WITH rental_data AS (
    SELECT 
        cat.name AS genre, 
        c.city, 
        ROUND(SUM(EXTRACT(EPOCH FROM (r.return_date - r.rental_date)))/3600) AS total_rental_time_in_hours
    FROM city c
    JOIN address adr ON c.city_id = adr.city_id
    JOIN customer ct ON adr.address_id = ct.address_id
    JOIN rental r ON ct.customer_id = r.customer_id
    JOIN inventory i ON i.inventory_id = r.inventory_id
    JOIN film_category fc ON fc.film_id = i.film_id
    JOIN category cat ON cat.category_id = fc.category_id
    GROUP BY c.city, cat.name
),

filtered_data AS (
    SELECT *
    FROM rental_data
    WHERE (genre LIKE 'A%' AND city LIKE 'A%')
       OR (genre LIKE '%-%' AND city LIKE 'A%')
       OR (genre LIKE 'A%' AND city LIKE '%-%')
       OR (genre LIKE '%-%' AND city LIKE '%-%')
),

max_rental AS (
    SELECT city, genre, total_rental_time_in_hours,
           ROW_NUMBER() OVER (PARTITION BY city ORDER BY total_rental_time_in_hours DESC) AS rn
    FROM filtered_data
)

SELECT city, genre, total_rental_time_in_hours
FROM max_rental
WHERE rn <=3;
