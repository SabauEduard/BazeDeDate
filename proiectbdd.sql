select c.cod_carte, titlu, count(i.cod_carte)
from carte c, imprumuta i
where c.cod_carte = i.cod_carte(+) 
group by (c.cod_carte, titlu)
order by -count(i.cod_carte);


16. Sa se obtina pentru fiecare carte ce apartine unui gen ce contine 'ist' in nume de cate ori a fost imprumutata si sa se 
ordoneze descrescator rezultatele in functie de numarul de dati in care a fost imprumutata.

select c.cod_carte, titlu, count(i.cod_carte)
from carte c, imprumuta i, apartine a, gen g
where c.cod_carte = a.cod_carte and g.cod_gen = a.cod_gen and lower(g.nume) like '%ist%' and c.cod_carte = i.cod_carte(+) 
group by (c.cod_carte, titlu)
order by -count(i.cod_carte);


--Sa se obtina codul, numele si prenumele membrilor ce au primit penalizari acum un an sau mai mult si au imprumutat 
--cel putin 2 carti scrise in limba romana de un autor roman. 

with mem_2carti_rom as
(
select m.cod_membru
from carte c, membru m, imprumuta i
where c.cod_carte = i.cod_carte and m.cod_membru = i.cod_membru
and c.cod_carte in (select c.cod_carte
                    from carte c, scrie s, autor a
                    where c.cod_carte = s.cod_carte and a.cod_autor = s.cod_autor and lower(limba) = 'romana'
                    and lower(nationalitate) = 'roman')
group by m.cod_membru
having count(c.cod_carte) >= 2
)
select distinct m.cod_membru, nume, prenume
from membru m, penalizare p, mem_2carti_rom m2
where m.cod_membru = p.cod_membru and months_between(sysdate, p.data_penalizare) >= 12 and m.cod_membru = m2.cod_membru;  


12.2 Sa se obtina codul si titlul cartilor ce au macar un autor al carui prenume sa inceapa cu litera "G" sau "L" 
si al carui nume sa nu depaseasca 8 litere. Ordonati rezultatele descrescator dupa codul cartii.

select c.cod_carte, titlu
from scrie s, carte c, autor a
where s.cod_carte = c.cod_carte and a.cod_autor = s.cod_autor and (lower(a.prenume) like 'g%' or lower(a.prenume) like 'l%') 
and length(a.nume) <= 8
order by -c.cod_carte;

12.3 Se aplica mariri de preturi pentru abonamente din cauza inflatiei, cel de elev devine 20 de lei, cele de pensionar 
si de student cresc cu 20%, iar cele de adult cresc cu 30%. Afisati abonametele cu preturile modificate si ordonati rezultatele
descrescator dupa pret.
--var case
select cod_abonament, titlu, durata, case
                                     when upper(titlu) = 'ELEV' then 20
                                     when upper(titlu) like '%STUDENT%' then pret*1.2
                                     when upper(titlu) like '%PENSIONAR%' then pret*1.2
                                     when upper(titlu) like '%ADULT%' then pret*1.3
                                     else pret
                                     end
                                     as pret_nou
from abonament
order by -pret_nou;

--var decode
select cod_abonament, titlu, durata, decode(upper(titlu), 
                                            'ELEV', 20,
                                            'ADULT', pret*1.3,
                                            'ADULT FULL', pret*1.3,
                                            pret*1.2) as pret_nou
from abonament
order by -pret_nou;


12.4 Sa se obtina codul, numele si prenumele membrilor ce au cumparat cel putin un abonament de elev dupa luna ianuarie a 
a anului 2020 si au cel putin o penalizare peste 20 de lei care sa fie platita integral.

12.5 Sa se obtina codul, numele si prenumele membrilor ce au imprumutat o carte ce apartine genului 'Realism' 
imprumutata de un membru al carui nume incepe cu litera P  si sa se ordoneze alfabetic dupa prenume

select distinct m.cod_membru, nume, prenume
from membru m, imprumuta i
where m.cod_membru = i.cod_membru and i.cod_carte in ( select i2.cod_carte
                                                       from imprumuta i2, membru m2, apartine a, gen g 
                                                       where i2.cod_membru = m2.cod_membru and m.cod_membru != m2.cod_membru 
                                                       and initcap(m2.nume) like 'P%' and i2.cod_carte = a.cod_carte 
                                                       and a.cod_gen = g.cod_gen and lower(g.nume)='realism')
order by prenume;
                                            

12.6 Se pare ca inflatia a afectat si penalizarile neplatite, penalizarile neplatite mai vechi de 2021 se scumpesc cu 50%, 
cele mai vechi de 2022 cu 25%, iar restul cu 15%.

select * from penalizare;
select * from abonament;
select * from plata_penalizare;


select cod_penalizare, data_penalizare, case
                                        when data_penalizare < to_date('1/1/2021','DD/MM/YYYY') then 1.5*suma_penalizare
                                        when data_penalizare < to_date('1/1/2022','DD/MM/YYYY') then 1.25*suma_penalizare
                                        else 1.15*suma_penalizare
                                        end
                                        as suma_noua                              
from penalizare
where cod_penalizare not in (select cod_penalizare
                             from plata_penalizare);



12.7 Pentru fiecare carte din biblioteca, afisati codul, numarul de copii, isbn-ul si un mesaj corespunzator daca aceasta a fost
sau nu imprumutata si daca a fost sau nu rezervata.

select c.cod_carte, titlu, numar_copii, ISBN, 
nvl2((select distinct cod_carte 
      from imprumuta 
      where c.cod_carte = cod_carte), 'Cartea a fost imprumutata', 'Cartea nu a fost imprumutata') as imprumut,
nvl2((select distinct cod_carte
      from rezerva
      where c.cod_carte = cod_carte), 'Cartea a fost rezervata', 'Cartea nu a fost rezervata') as rezervare
from carte c;



13.1 Sa se stearga toate cartile care nu au fost imprumutate de membrul/membrii cu numar maxim de penalizari.

delete
from carte
where cod_carte in (select cod_carte
                    from imprumuta
                    where cod_membru in (select m.cod_membru
                                         from penalizare p, membru m
                                         where p.cod_membru = m.cod_membru
                                         group by m.cod_membru
                                         having count(cod_penalizare) = (select max(count(cod_penalizare))
                                                                         from penalizare
                                                                         group by cod_membru)));

select cod_carte
from carte;

rollback;


13.2 Biblioteca a hotarat ca toate abonamentele cumparate de un membru ce a imprumutat cartea cu titlul "Ion" la un moment dat
sa devina gratis.

update abonament
set pret = 0
where cod_abonament 
in (select distinct a.cod_abonament
    from abonament a, cumpara c
    where a.cod_abonament = c.cod_abonament 
    and c.cod_membru in (select distinct m.cod_membru
                         from imprumuta i, carte c, membru m
                         where i.cod_carte = c.cod_carte and m.cod_membru = i.cod_membru and lower(titlu) = 'ion'));            


rollback;


13.3 Sa se stearga autorii ce nu au scris nicio carte din baza de date a bibliotecii.

delete
from autor
where cod_autor not in (select distinct cod_autor
                        from scrie);
                        
rollback;



16.2(division1) Sa se afiseze toate informatiile despre toti membri ce au imprumutat toate cartile scrise in limba rusa.

with mem_carti_rom as
(
select cod_membru
from imprumuta
minus
select cod_membru 
from
(select cod_membru, cod_carte
from  (select cod_carte from carte where limba = 'rusa') t1,
      (select cod_membru from imprumuta) t2
minus 
select cod_membru, cod_carte
from imprumuta) t3
)
select *
from membru
where cod_membru in (select * from mem_carti_rom);

select * from gen;
select * from imprumuta;

insert into carte values(13, 'Moartea lui Ivan Ilici', to_date('21/10/1886','DD/MM/YYYY'), 'rusa', 1, '9789734634316');
insert into scrie values(13, 3);
insert into apartine values(40, 13);
insert into apartine values(60, 13);
insert into imprumuta values(13, 2, to_date('19/4/2021', 'DD/MM/YYYY'), to_date('28/4/2021','DD/MM/YYYY'));
commit;


16.2(division2) Sa se afiseze toate informatiile despre toate abonamentele care au fost cumparate de toti membri ce au cel 
putin 3 penalizari

with ab_cump_mem as
(
select distinct cod_abonament
from cumpara
where cod_membru in (select cod_membru
                     from penalizare
                     group by cod_membru
                     having count(cod_membru) >= 3)
group by cod_abonament, cod_plata_abonament
having count(cod_membru) = (select count(*)
                            from (select cod_membru
                                  from penalizare
                                  group by cod_membru
                                  having count(cod_membru) >= 3))
)   
select *
from abonament
where cod_abonament in (select * from ab_cump_mem);



--Sa se obtina codul, numele si prenumele membrilor ce au primit penalizari acum un an sau mai mult si au imprumutat 
--cel putin 2 carti scrise in limba romana de un autor roman.  

--Aceasta cerere utilizeaza urmatoarele: 
--subcerere nesincronizata pe minim 3 tabele
--2 functii pe date (months_between si sysdate)
--o functie pe siruri de caractere(lower)
--un bloc de cerere(clauza with)
--filtrare la nivel de linie
--grupare de date, functie de grup(count) si filtrare la nivel de grupuri

with mem_2carti_rom as
(
select m.cod_membru
from carte c, membru m, imprumuta i
where c.cod_carte = i.cod_carte and m.cod_membru = i.cod_membru
and c.cod_carte in (select c.cod_carte
                    from carte c, scrie s, autor a
                    where c.cod_carte = s.cod_carte and a.cod_autor = s.cod_autor and lower(limba) = 'romana'
                    and lower(nationalitate) = 'roman')
group by m.cod_membru
having count(c.cod_carte) >= 2
)
select distinct m.cod_membru, nume, prenume
from membru m, penalizare p, mem_2carti_rom m2
where m.cod_membru = p.cod_membru and months_between(sysdate, p.data_penalizare) >= 12 and m.cod_membru = m2.cod_membru;  



--Se aplica mariri de preturi pentru abonamente din cauza inflatiei, cel de elev devine 20 de lei, cele de pensionar 
--si de student cresc cu 20%, iar cele de adult cresc cu 30%. Afisati abonametele cu preturile modificate si ordonati 
--rezultatele descrescator dupa pret.

--Aceasta cerere utilizeaza urmatoarele: 
--o functie pe siruri de caractere(upper)
--expresia decode
--ordonare

select cod_abonament, titlu, durata, decode(upper(titlu), 
                                            'ELEV', 20,
                                            'ADULT', pret*1.3,
                                            'ADULT FULL', pret*1.3,
                                            pret*1.2) as pret_nou
from abonament
order by -pret_nou;



--Sa se obtina codul, numele si prenumele membrilor ce au imprumutat o carte ce apartine genului 'Realism' imprumutata 
--de cel putin un membru al carui nume incepe cu litera P si sa se ordoneze alfabetic dupa prenume rezultatele

-Aceasta cerere utilizeaza urmatoarele:
--o operatie de join pe cel putin 4 tabele
--subcerere sincronizata pe minim 3 tabele
--ordonare
--o functie pe sir de caractere (initcap)

select distinct m.cod_membru, nume, prenume
from membru m, imprumuta i
where m.cod_membru = i.cod_membru and i.cod_carte in ( select i2.cod_carte
                                                       from imprumuta i2, membru m2, apartine a, gen g 
                                                       where i2.cod_membru = m2.cod_membru and m.cod_membru != m2.cod_membru 
                                                       and initcap(m2.nume) like 'P%' and i2.cod_carte = a.cod_carte 
                                                       and a.cod_gen = g.cod_gen and lower(g.nume)='realism');
order by prenume;


--Se pare ca inflatia a afectat si penalizarile neplatite. Penalizarile neplatite mai vechi de anul 2021 se scumpesc cu 50%, 
--cele mai vechi de anul 2022 cu 25%, iar restul cu 15%. Ordonati crescator rezultatele dupa data in care a fost aplicata 
--penalizarea.

--Aceasta cerere utilizeaza urmatoarele:
--instructiunea case
--functie pe date calendaristice(to_date)

select cod_penalizare, data_penalizare, case
                                        when data_penalizare < to_date('1/1/2021','DD/MM/YYYY') then 1.5*suma_penalizare
                                        when data_penalizare < to_date('1/1/2022','DD/MM/YYYY') then 1.25*suma_penalizare
                                        else 1.15*suma_penalizare
                                        end
                                        as suma_noua                              
from penalizare
where cod_penalizare not in (select cod_penalizare
                             from plata_penalizare)
order by data_penalizare;


--Pentru fiecare carte din biblioteca, afisati codul, numarul de copii, isbn-ul si un mesaj corespunzator daca aceasta a fost 
--sau nu imprumutata si daca a fost sau nu rezervata.

--Aceasta cerere utilizeaza urmatoarele:
--instructiunea nvl2
--2 subcereri corelate simple

select c.cod_carte, titlu, numar_copii, ISBN, 
nvl2((select distinct cod_carte 
      from imprumuta 
      where c.cod_carte = cod_carte), 'Cartea a fost imprumutata', 'Cartea nu a fost imprumutata') as imprumut,
nvl2((select distinct cod_carte
      from rezerva
      where c.cod_carte = cod_carte), 'Cartea a fost rezervata', 'Cartea nu a fost rezervata') as rezervare
from carte c;



--Sa se stearga toate cartile care nu au fost imprumutate de membrul/membrii cu cele mai multe penalizari.

delete
from carte
where cod_carte in (select cod_carte
                    from imprumuta
                    where cod_membru in (select m.cod_membru
                                         from penalizare p, membru m
                                         where p.cod_membru = m.cod_membru
                                         group by m.cod_membru
                                         having count(cod_penalizare) = (select max(count(cod_penalizare))
                                                                         from penalizare
                                                                         group by cod_membru)));
select * from carte;
rollback;



--Biblioteca a hotarat ca toate abonamentele cumparate de un membru ce a imprumutat cartea cu titlul "Ion" la un moment dat 
--sa devina gratis.

update abonament
set pret = 0
where cod_abonament 
in (select distinct a.cod_abonament
    from abonament a, cumpara c
    where a.cod_abonament = c.cod_abonament 
    and c.cod_membru in (select distinct m.cod_membru
                         from imprumuta i, carte c, membru m
                         where i.cod_carte = c.cod_carte and m.cod_membru = i.cod_membru and lower(titlu) = 'ion'));            
rollback;
select * from abonament;


--Sa se stearga toti autorii ce nu au scris nicio carte din baza de date a bibliotecii.

delete
from autor
where cod_autor not in (select distinct cod_autor
                        from scrie);
                        
rollback;
select * from autor;

--(outer-join) Sa se obtina pentru fiecare carte ce apartine unui gen ce contine 'ist' in nume de cate ori a fost imprumutata 
--si sa se ordoneze descrescator rezultatele in functie de numarul de dati in care a fost imprumutata.

select c.cod_carte, titlu, count(i.cod_carte)
from carte c, imprumuta i, apartine a, gen g
where c.cod_carte = a.cod_carte and g.cod_gen = a.cod_gen and lower(g.nume) like '%ist%' and c.cod_carte = i.cod_carte(+) 
group by (c.cod_carte, titlu)
order by -count(i.cod_carte);



--(division1) Sa se afiseze toate informatiile despre toti membri ce au imprumutat toate cartile scrise in limba rusa.

with mem_carti_rom as
(
select cod_membru
from imprumuta
minus
select cod_membru 
from
(select cod_membru, cod_carte
from  (select cod_carte from carte where limba = 'rusa') t1,
      (select cod_membru from imprumuta) t2
minus 
select cod_membru, cod_carte
from imprumuta) t3
)
select *
from membru
where cod_membru in (select * from mem_carti_rom);


--(division2) Sa se afiseze toate informatiile despre toate abonamentele care au fost cumparate de toti membri 
--ce au cel putin 3 penalizari

with ab_cump_mem as
(
select distinct cod_abonament
from cumpara
where cod_membru in (select cod_membru
                     from penalizare
                     group by cod_membru
                     having count(cod_membru) >= 3)
group by cod_abonament, cod_plata_abonament
having count(cod_membru) = (select count(*)
                            from (select cod_membru
                                  from penalizare
                                  group by cod_membru
                                  having count(cod_membru) >= 3))
)   
select *
from abonament
where cod_abonament in (select * from ab_cump_mem);


--Sa se obtina codul, numele, prenumele membrilor si codurile, sumele si datele penalizarilor pentru care data penalizarii
--este dupa 13.06.2021, dar inainte de 20.04.2022

select m.cod_membru, nume, prenume, cod_penalizare, suma_penalizare, data_penalizare
from membru m, penalizare p
where m.cod_membru = p.cod_membru and data_penalizare > to_date('13/6/2021', 'DD/MM/YYYY') 
and data_penalizare < to_date('20/4/2022', 'DD/MM/YYYY');


--Sa se obtina codul, numele, prenumele membrilor si codurile, sumele si datele penalizarilor pentru care data penalizarii
--este dupa 13.06.2021, dar inainte de 20.04.2022

with pens as
(
select cod_membru, cod_penalizare, suma_penalizare, data_penalizare
from (select cod_membru, cod_penalizare, suma_penalizare, data_penalizare
      from penalizare
      where data_penalizare > to_date('13/6/2021', 'DD/MM/YYYY'))
where data_penalizare < to_Date('20/4/2022', 'DD/MM/YYYY')
)
select m.cod_membru, nume, prenume, cod_penalizare, suma_penalizare, data_penalizare
from membru m, pens p
where m.cod_membru = p.cod_membru;

