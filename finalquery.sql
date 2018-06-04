WITH RENTAL_FEATURES(film_id,avg_rental_cost,avg_hours_rented)
AS (
    SELECT 
        i.film_id,
        AVG(p.amount) avg_rental_cost,
        CASE 
            WHEN TIMESTAMPDIFF( 
                HOUR, r.rental_date, r.return_date) REGEXP '^[0-9]+$' 
                THEN AVG(TIMESTAMPDIFF(HOUR, r.rental_date, r.return_date)) 
            ELSE 0
        END AS avg_hours_rented
    FROM 
        rental r
        JOIN payment p ON p.rental_id = r.rental_id
        JOIN inventory i ON i.inventory_id = r.inventory_id
    GROUP BY film_id
    ),
FILM_FEATURES(film_id,title,description,category_id,language_id,avg_hours_rental_allowed,hours_length,avg_replacement_cost,rating,special_features,actors_in_film)
AS (
    SELECT 
        f.film_id,
        f.title,
        f.description,
        fc.category_id,
        f.language_id,
        AVG(f.rental_duration) * 24 avg_hours_rental_allowed,
        f.length / 60 hours_length,
        AVG(f.replacement_cost) avg_replacement_cost,
        f.rating,
        f.special_features,
        COUNT(fa.actor_id) actors_in_film
    FROM 
        film f
        JOIN film_category fc ON fc.film_id = f.film_id
        JOIN film_actor fa ON fa.film_id = f.film_id
    GROUP BY f.film_id
    ),
ACTOR_FEATURES(film_id,actor_list,total_actor_fame,total_actor_influence)
AS (
    SELECT 
        act2.film_id,
        GROUP_CONCAT(act2.actor_id SEPARATOR ',') actor_list,
        SUM(act2.actor_fame) total_actor_fame,
        SUM(act2.actor_influence) total_actor_influence
    FROM (
        SELECT fa.film_id, act1.*
        FROM (
            SELECT 
                fa1.actor_id,
                COUNT(DISTINCT(fa1.film_id)) actor_fame,
                COUNT(DISTINCT(fa2.actor_id)) actor_influence
            FROM 
                film_actor fa1
                JOIN film_actor fa2 ON fa2.film_id = fa1.film_id
            GROUP BY fa1.actor_id
            ) act1
        JOIN film_actor fa ON fa.actor_id = act1.actor_id
        ) act2
    GROUP BY act2.film_id
    ),
LABELS(film_id,num_rent)
AS(
    SELECT 
        f.film_id, 
        COUNT(IFNULL(r.rental_id, 0)) num_rent
    FROM 
        rental r
        JOIN inventory i ON i.inventory_id = r.inventory_id
        JOIN film f ON f.film_id = i.film_id
    GROUP BY f.film_id
    ),
FEATURES_AND_LABELS AS ( -- Combine all features and labels
    SELECT
        R.film_id,
        R.avg_rental_cost,
        R.avg_hours_rented,
        F.avg_hours_rental_allowed,
        F.category_id,
        F.language_id,
        F.hours_length,
        F.avg_replacement_cost,
        F.rating,
        F.description,
        F.special_features,
        F.actors_in_film,
        A.actor_list,
        A.total_actor_fame,
        A.total_actor_influence,
        L.num_rent
    FROM
        RENTAL_FEATURES R
        JOIN FILM_FEATURES F ON F.film_id = R.film_id
        JOIN ACTOR_FEATURES A ON A.film_id = F.film_id
        JOIN LABELS L ON L.film_id = F.film_id
    )
SELECT * FROM FEATURES_AND_LABELS