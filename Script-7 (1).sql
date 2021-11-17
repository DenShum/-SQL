 --Задание 1 
В каких городах больше одного аэропорта?

В подзапросе в таблицы airports делаем группировку по городам с условием, что в выборку попадают только города, которые 
записаны больше, чем в 1 строке (Ульяновск и Москва) и в основном запросе для этих городов выводим airport_code, airport_name, a.city

select a.airport_code code, a.airport_name, a.city --5строк 
from airports a 
where a.city in(
	select a2.city 
	from airports a2
	group by a2.city
	having count(*)>1
	)
	order by a.city
	
	select a.city, count(a.city) "количество аэропортов"--2строки
	from airports a
	group by a.city
	having count(a.city)>1
			
	--Задание 2
	В каких аэропортах есть рейсы, выполняемые самолетом с максимальной дальностью перелета?
	
	В подзапросе находим максимальную дальность полета из таблицы aircrafts, 
	после - джоиним к таблице airports таблицу flights, а к ней
	таблицу aircrafts, группируем по коду аэропорта, модели самолета и дальности полета.
	
	select a.airport_code, a.airport_name , a.city, a2.model, a2."range" --7строк
	from airports a 
	join flights f on f.departure_airport =a.airport_code
	join aircrafts a2 on a2.aircraft_code =f.aircraft_code
	where a2."range"=(select max(a2."range")
		from aircrafts a2)
	group by a.airport_code, a2.model, a2."range"
	order by a.airport_code
	
	--Задание 3
	Вывести 10 рейсов с максимальным временем задержки вылета
	
	К таблице рейсов джоиним таблицу аэропортов, в условии прописываем, что в определяемой колонке "задержка вылета" не должно быть 
	значений null, сортируем по колонке "задержка вылета" от большего-к меньшему, выводим колонки: номер рейса, аэропорт вылета, 
	имя аэропорта, город, "задержка вылета"(разница между реальным временем вылета и планируемым). Ограничиваем результат 10 строками. 
	
			
	select f.flight_no, f.departure_airport, a.airport_name, a.city,(f.actual_departure-f.scheduled_departure) "задержка вылета"
	from flights f
	join airports a on a.airport_code =f.departure_airport 
	where (f.actual_departure-f.scheduled_departure) is not null
	order by (f.actual_departure-f.scheduled_departure) desc
	limit 10
	
	--Задание 4
	Были ли брони, по которым не были получены посадочные талоны?
	
	Таблицу бронирования обогащаем данными из таблицы билеты через правый джоин, так как в одно бронирование может входить
	несколько билетов, после - джоиним таблицу посадочных талонов к таблице билетов через левый джоин, чтобы не потерять
	данные по билетам, на которые не были получены посадочные талоны(проставляется значение null). 
	Далее выводим информацию о бронях и посадочных талонях, у которых значения null
	
	select distinct b.book_ref, bp.boarding_no
	from bookings b 
	right join tickets t on t.book_ref =b.book_ref 
	left join boarding_passes bp on bp.ticket_no=t.ticket_no 
	where bp.boarding_no is null 
	
	--Задание 5
	Найдите свободные места для каждого рейса, их % отношение к общему количеству мест в самолете.
Добавьте столбец с накопительным итогом - суммарное накопление количества вывезенных пассажиров из 
каждого аэропорта на каждый день. Т.е. в этом столбце должна отражаться накопительная сумма - сколько человек 
уже вылетело из данного аэропорта на этом или более ранних рейсах за день.

Создаем cte из таблицы билетов и выводим код самолета и общее для него количество мест
Создаем cte2 из таблицы рейсов, приджоинив к ней таблицу посадочных талонов, и через count находим
		всего посадочных талонов для  каждого рейса
Создаем cte3 из таблицы рейсов, приджоинив к ней таблицу посадочных талонов, и через count находим
		всего посадочных талонов для  каждого рейса при условии where f.status = 'Arrived' or f.status ='Departed', т.о. количество
		вывезенных пассажиров
		В селект выводим f.departure_airport, f.flight_id , f.flight_no, cte."всего мест", 
		 "свободных мест"-как разницу "всего мест" и "всего посад.талонов" , "% свободных мест", "всего посад.талонов",
		 "Накопл.итог_исполн"(накопительный итог по каждому аэропорту на каждый день вывезенных пассажиров)

	
	with cte as(
	select s.aircraft_code, count(*) "всего мест" 
	from seats s
	group by s.aircraft_code
	), cte2 as(
		select distinct f.flight_id, count(bp.boarding_no) "всего посад.талонов"
		from flights f
		join boarding_passes bp on bp.flight_id =f.flight_id
		group by f.flight_id
		order by f.flight_id
	), cte3 as(
	select distinct f.flight_id, count(bp.boarding_no) "всего посад.талонов исполн"
		from flights f
		join boarding_passes bp on bp.flight_id =f.flight_id
		where f.status = 'Arrived' or f.status ='Departed'
		group by f.flight_id
		order by f.flight_id)
	select f.departure_airport, f.scheduled_departure, f.flight_id, cte."всего мест", (cte."всего мест"-cte2."всего посад.талонов") "свободных мест", 
		((cte."всего мест"-cte2."всего посад.талонов")*100/cte."всего мест") "% свободных мест", cte2."всего посад.талонов", cte3."всего посад.талонов исполн",
		sum(cte3."всего посад.талонов исполн")over(partition by f.departure_airport order by date_trunc('day',f.scheduled_departure))
	from flights f 
	join aircrafts a on a.aircraft_code=f.aircraft_code 
	left join cte on cte.aircraft_code =a.aircraft_code
	join cte2 on cte2.flight_id =f.flight_id
	join cte3 on cte3.flight_id =f.flight_id
	group by f.departure_airport, f.scheduled_departure, 
	f.flight_id,cte."всего мест", cte2."всего посад.талонов", cte3."всего посад.талонов исполн", date_trunc('day',f.scheduled_departure)
	
	
	
		--Задание 6	
	
	Найдите процентное соотношение перелетов по типам самолетов от общего количества.
	
	Создали cte из таблицы flights,
	вывели типы самолетов, количество рейсов по типам самолетов, сгруппировали по типам самолетов. 
	Вывели в селект из cte типы самолетов (code), количество рейсов по типам самолетов(sum_code)
	и "Процент" как деление cte.sum_code*100 на подзапрос, возвращающий общее количество строк из таблицы flights, т.е. рейсов
	через функцию round округлили значение до 1 знаков после запятой.	
	
			
	with cte as(
	select f.aircraft_code code, count(f.aircraft_code) ::numeric sum_code
	from flights f 
	group by f.aircraft_code)
	select cte.code, cte.sum_code, round((cte.sum_code*100/(select count(*) from flights f2)),1) "Процент"
	from cte
	
		--Задание 7
	
	Были ли города, в которые можно  добраться бизнес - классом дешевле, чем эконом-классом в рамках перелета?
	
	Таких городов не было
	
	В cte выбираем из таблицы перелетов строки с "бизнесс классом", приджоинив таблицы рейсов и аэропортов,
	в cte2 выбираем из таблицы перелетов строки с "эконом классом",	приджоинив таблицы рейсов и аэропортов.
	Производим вычитание стоимости перелета из cte и cte2 при условии, что это один и тотже рейс и разница должна быть отрицательной

with cte as(
	select (tf.flight_id||f.departure_airport||a.city||'-'||f.arrival_airport||a.city) "рейс", tf.fare_conditions, tf.amount "max"
	from ticket_flights tf
	join flights f on f.flight_id =tf.flight_id
	join airports a on a.airport_code=f.departure_airport 
	group by tf.flight_id, tf.fare_conditions,tf.amount,f.departure_airport,f.arrival_airport,a.city 
	having tf.fare_conditions='Business'),
	cte2 as(
			select (tf.flight_id||f.departure_airport||a.city||'-'||f.arrival_airport||a.city) "рейс", tf.fare_conditions, tf.amount "min"
			from ticket_flights tf 
			join flights f on f.flight_id =tf.flight_id
			join airports a on a.airport_code=f.departure_airport 
			group by tf.flight_id, tf.fare_conditions,tf.amount,f.departure_airport,f.arrival_airport,a.city  
			having tf.fare_conditions='Economy')
select (cte."max"-cte2."min") "разница",cte."рейс" ,cte2."рейс"
from cte, cte2
where cte."рейс"=cte2."рейс" and (cte."max"-cte2."min")<0
	
		--Задание 8
	Между какими городами нет прямых рейсов?
	
В cte вывели города и аэропорты отправления. В cte2 вывели города и раэропорты прибытия. Через Декартово произведение нашли
все возможные комбинации городов и аэропортов отправления и городов и аэропортов прибытия. Из таблицы рейсов
вывели аэропорты отправления и аэропорт прибытия (по рейсам).Через except из первой таблицы вычли вторую и получили города, для
которых нет совпадения рейс-город отправления-город прибытия, т.е. нет прямых рейсов. Для ускорения получения конечного результата
создали материализованное представления task1.
		

create materialized view task1 as
with cte as(
select f.flight_id , f.departure_airport||a.city departure  
from flights f
join airports a on a.airport_code=f.departure_airport),
	cte2 as(
	select f.flight_id, f.arrival_airport||a.city  arrival  
	from flights f
	join airports a on a.airport_code=f.arrival_airport)
		select cte.departure, cte2.arrival 
		from cte , cte2 
 except
select f.departure_airport, f.arrival_airport 
from flights f 
with data
	
		--Задание 9
	Вычислите расстояние между аэропортами, связанными прямыми рейсами, сравните с допустимой максимальной 
	дальностью перелетов  в самолетах, обслуживающих эти рейсы
		
	
	
	
	with cte as(
	select s.aircraft_code, count(*) "всего мест" 
	from seats s
	group by s.aircraft_code
	), cte2 as(
		select distinct f.flight_id, count(bp.boarding_no) "всего посад.талонов"
		from flights f
		join boarding_passes bp on bp.flight_id =f.flight_id
		group by f.flight_id
		order by f.flight_id
	), cte3 as(
	select distinct f.flight_id, count(bp.boarding_no) "всего посад.талонов исполн"
		from flights f
		join boarding_passes bp on bp.flight_id =f.flight_id
		where f.status = 'Arrived' or f.status ='Departed'
		group by f.flight_id
		order by f.flight_id)
	select f.departure_airport, f.flight_id , f.flight_no, cte."всего мест", 
		(cte."всего мест"-cte2."всего посад.талонов") "свободных мест", 
		((cte."всего мест"-cte2."всего посад.талонов")*100/cte."всего мест") "% свободных мест", cte2."всего посад.талонов",
		sum( sum(cte3."всего посад.талонов исполн")over(partition by f.departure_airport order by f.scheduled_departure)) "Накопление", 
		dense_rank()over(partition by f.departure_airport order by date_trunc('day',f.scheduled_departure)) ,date_trunc('day',f.scheduled_departure)
	from flights f 
	join aircrafts a on a.aircraft_code=f.aircraft_code 
	left join cte on cte.aircraft_code =a.aircraft_code
	join cte2 on cte2.flight_id =f.flight_id
	join cte3 on cte3.flight_id =f.flight_id
	group by f.flight_id, a.model, cte."всего мест", cte2."всего посад.талонов", 
	cte3."всего посад.талонов исполн", date_trunc('day',f.scheduled_departure)

	
	
	
	
	
	
	
	
	
	
	
	
	
	
	
	
	
	