SELECT
    menu.pizza_name AS pizza_name,
    menu.price,
    pizzeria.name AS pizzeria_name,
    person_visits.visit_date
FROM person_visits
INNER JOIN menu ON person_visits.pizzeria_id = menu.pizzeria_id