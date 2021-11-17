 --������� 1 
� ����� ������� ������ ������ ���������?

� ���������� � ������� airports ������ ����������� �� ������� � ��������, ��� � ������� �������� ������ ������, ������� 
�������� ������, ��� � 1 ������ (��������� � ������) � � �������� ������� ��� ���� ������� ������� airport_code, airport_name, a.city

select a.airport_code code, a.airport_name, a.city --5����� 
from airports a 
where a.city in(
	select a2.city 
	from airports a2
	group by a2.city
	having count(*)>1
	)
	order by a.city
	
	select a.city, count(a.city) "���������� ����������"--2������
	from airports a
	group by a.city
	having count(a.city)>1
			
	--������� 2
	� ����� ���������� ���� �����, ����������� ��������� � ������������ ���������� ��������?
	
	� ���������� ������� ������������ ��������� ������ �� ������� aircrafts, 
	����� - ������� � ������� airports ������� flights, � � ���
	������� aircrafts, ���������� �� ���� ���������, ������ �������� � ��������� ������.
	
	select a.airport_code, a.airport_name , a.city, a2.model, a2."range" --7�����
	from airports a 
	join flights f on f.departure_airport =a.airport_code
	join aircrafts a2 on a2.aircraft_code =f.aircraft_code
	where a2."range"=(select max(a2."range")
		from aircrafts a2)
	group by a.airport_code, a2.model, a2."range"
	order by a.airport_code
	
	--������� 3
	������� 10 ������ � ������������ �������� �������� ������
	
	� ������� ������ ������� ������� ����������, � ������� �����������, ��� � ������������ ������� "�������� ������" �� ������ ���� 
	�������� null, ��������� �� ������� "�������� ������" �� ��������-� ��������, ������� �������: ����� �����, �������� ������, 
	��� ���������, �����, "�������� ������"(������� ����� �������� �������� ������ � �����������). ������������ ��������� 10 ��������. 
	
			
	select f.flight_no, f.departure_airport, a.airport_name, a.city,(f.actual_departure-f.scheduled_departure) "�������� ������"
	from flights f
	join airports a on a.airport_code =f.departure_airport 
	where (f.actual_departure-f.scheduled_departure) is not null
	order by (f.actual_departure-f.scheduled_departure) desc
	limit 10
	
	--������� 4
	���� �� �����, �� ������� �� ���� �������� ���������� ������?
	
	������� ������������ ��������� ������� �� ������� ������ ����� ������ �����, ��� ��� � ���� ������������ ����� �������
	��������� �������, ����� - ������� ������� ���������� ������� � ������� ������� ����� ����� �����, ����� �� ��������
	������ �� �������, �� ������� �� ���� �������� ���������� ������(������������� �������� null). 
	����� ������� ���������� � ������ � ���������� �������, � ������� �������� null
	
	select distinct b.book_ref, bp.boarding_no
	from bookings b 
	right join tickets t on t.book_ref =b.book_ref 
	left join boarding_passes bp on bp.ticket_no=t.ticket_no 
	where bp.boarding_no is null 
	
	--������� 5
	������� ��������� ����� ��� ������� �����, �� % ��������� � ������ ���������� ���� � ��������.
�������� ������� � ������������� ������ - ��������� ���������� ���������� ���������� ���������� �� 
������� ��������� �� ������ ����. �.�. � ���� ������� ������ ���������� ������������� ����� - ������� ������� 
��� �������� �� ������� ��������� �� ���� ��� ����� ������ ������ �� ����.

������� cte �� ������� ������� � ������� ��� �������� � ����� ��� ���� ���������� ����
������� cte2 �� ������� ������, ���������� � ��� ������� ���������� �������, � ����� count �������
		����� ���������� ������� ���  ������� �����
������� cte3 �� ������� ������, ���������� � ��� ������� ���������� �������, � ����� count �������
		����� ���������� ������� ���  ������� ����� ��� ������� where f.status = 'Arrived' or f.status ='Departed', �.�. ����������
		���������� ����������
		� ������ ������� f.departure_airport, f.flight_id , f.flight_no, cte."����� ����", 
		 "��������� ����"-��� ������� "����� ����" � "����� �����.�������" , "% ��������� ����", "����� �����.�������",
		 "������.����_������"(������������� ���� �� ������� ��������� �� ������ ���� ���������� ����������)

	
	with cte as(
	select s.aircraft_code, count(*) "����� ����" 
	from seats s
	group by s.aircraft_code
	), cte2 as(
		select distinct f.flight_id, count(bp.boarding_no) "����� �����.�������"
		from flights f
		join boarding_passes bp on bp.flight_id =f.flight_id
		group by f.flight_id
		order by f.flight_id
	), cte3 as(
	select distinct f.flight_id, count(bp.boarding_no) "����� �����.������� ������"
		from flights f
		join boarding_passes bp on bp.flight_id =f.flight_id
		where f.status = 'Arrived' or f.status ='Departed'
		group by f.flight_id
		order by f.flight_id)
	select f.departure_airport, f.scheduled_departure, f.flight_id, cte."����� ����", (cte."����� ����"-cte2."����� �����.�������") "��������� ����", 
		((cte."����� ����"-cte2."����� �����.�������")*100/cte."����� ����") "% ��������� ����", cte2."����� �����.�������", cte3."����� �����.������� ������",
		sum(cte3."����� �����.������� ������")over(partition by f.departure_airport order by date_trunc('day',f.scheduled_departure))
	from flights f 
	join aircrafts a on a.aircraft_code=f.aircraft_code 
	left join cte on cte.aircraft_code =a.aircraft_code
	join cte2 on cte2.flight_id =f.flight_id
	join cte3 on cte3.flight_id =f.flight_id
	group by f.departure_airport, f.scheduled_departure, 
	f.flight_id,cte."����� ����", cte2."����� �����.�������", cte3."����� �����.������� ������", date_trunc('day',f.scheduled_departure)
	
	
	
		--������� 6	
	
	������� ���������� ����������� ��������� �� ����� ��������� �� ������ ����������.
	
	������� cte �� ������� flights,
	������ ���� ���������, ���������� ������ �� ����� ���������, ������������� �� ����� ���������. 
	������ � ������ �� cte ���� ��������� (code), ���������� ������ �� ����� ���������(sum_code)
	� "�������" ��� ������� cte.sum_code*100 �� ���������, ������������ ����� ���������� ����� �� ������� flights, �.�. ������
	����� ������� round ��������� �������� �� 1 ������ ����� �������.	
	
			
	with cte as(
	select f.aircraft_code code, count(f.aircraft_code) ::numeric sum_code
	from flights f 
	group by f.aircraft_code)
	select cte.code, cte.sum_code, round((cte.sum_code*100/(select count(*) from flights f2)),1) "�������"
	from cte
	
		--������� 7
	
	���� �� ������, � ������� �����  ��������� ������ - ������� �������, ��� ������-������� � ������ ��������?
	
	����� ������� �� ����
	
	� cte �������� �� ������� ��������� ������ � "������� �������", ���������� ������� ������ � ����������,
	� cte2 �������� �� ������� ��������� ������ � "������ �������",	���������� ������� ������ � ����������.
	���������� ��������� ��������� �������� �� cte � cte2 ��� �������, ��� ��� ���� � ����� ���� � ������� ������ ���� �������������

with cte as(
	select (tf.flight_id||f.departure_airport||a.city||'-'||f.arrival_airport||a.city) "����", tf.fare_conditions, tf.amount "max"
	from ticket_flights tf
	join flights f on f.flight_id =tf.flight_id
	join airports a on a.airport_code=f.departure_airport 
	group by tf.flight_id, tf.fare_conditions,tf.amount,f.departure_airport,f.arrival_airport,a.city 
	having tf.fare_conditions='Business'),
	cte2 as(
			select (tf.flight_id||f.departure_airport||a.city||'-'||f.arrival_airport||a.city) "����", tf.fare_conditions, tf.amount "min"
			from ticket_flights tf 
			join flights f on f.flight_id =tf.flight_id
			join airports a on a.airport_code=f.departure_airport 
			group by tf.flight_id, tf.fare_conditions,tf.amount,f.departure_airport,f.arrival_airport,a.city  
			having tf.fare_conditions='Economy')
select (cte."max"-cte2."min") "�������",cte."����" ,cte2."����"
from cte, cte2
where cte."����"=cte2."����" and (cte."max"-cte2."min")<0
	
		--������� 8
	����� ������ �������� ��� ������ ������?
	
� cte ������ ������ � ��������� �����������. � cte2 ������ ������ � ���������� ��������. ����� ��������� ������������ �����
��� ��������� ���������� ������� � ���������� ����������� � ������� � ���������� ��������. �� ������� ������
������ ��������� ����������� � �������� �������� (�� ������).����� except �� ������ ������� ����� ������ � �������� ������, ���
������� ��� ���������� ����-����� �����������-����� ��������, �.�. ��� ������ ������. ��� ��������� ��������� ��������� ����������
������� ����������������� ������������� task1.
		

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
	
		--������� 9
	��������� ���������� ����� �����������, ���������� ������� �������, �������� � ���������� ������������ 
	���������� ���������  � ���������, ������������� ��� �����
		
	
	
	
	with cte as(
	select s.aircraft_code, count(*) "����� ����" 
	from seats s
	group by s.aircraft_code
	), cte2 as(
		select distinct f.flight_id, count(bp.boarding_no) "����� �����.�������"
		from flights f
		join boarding_passes bp on bp.flight_id =f.flight_id
		group by f.flight_id
		order by f.flight_id
	), cte3 as(
	select distinct f.flight_id, count(bp.boarding_no) "����� �����.������� ������"
		from flights f
		join boarding_passes bp on bp.flight_id =f.flight_id
		where f.status = 'Arrived' or f.status ='Departed'
		group by f.flight_id
		order by f.flight_id)
	select f.departure_airport, f.flight_id , f.flight_no, cte."����� ����", 
		(cte."����� ����"-cte2."����� �����.�������") "��������� ����", 
		((cte."����� ����"-cte2."����� �����.�������")*100/cte."����� ����") "% ��������� ����", cte2."����� �����.�������",
		sum( sum(cte3."����� �����.������� ������")over(partition by f.departure_airport order by f.scheduled_departure)) "����������", 
		dense_rank()over(partition by f.departure_airport order by date_trunc('day',f.scheduled_departure)) ,date_trunc('day',f.scheduled_departure)
	from flights f 
	join aircrafts a on a.aircraft_code=f.aircraft_code 
	left join cte on cte.aircraft_code =a.aircraft_code
	join cte2 on cte2.flight_id =f.flight_id
	join cte3 on cte3.flight_id =f.flight_id
	group by f.flight_id, a.model, cte."����� ����", cte2."����� �����.�������", 
	cte3."����� �����.������� ������", date_trunc('day',f.scheduled_departure)

	
	
	
	
	
	
	
	
	
	
	
	
	
	
	
	
	
	