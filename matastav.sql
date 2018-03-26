USE skola;
GO

--doladit nektere meny/penize
--dodelat penezni denik
--zkontrolovat telefony/psc/faxy etc, dat jim asi numeric (xx,0) ci mozna nejaky limit
-- predelat posty a kontrakty
-- zkontrolovat vsechny PK a FK jeste podle zadani

CREATE TABLE t_typy_zdroju (
	id_typ_zdroje	int PRIMARY KEY
	,typ_zdroje		nvarchar(255) NOT NULL
	)


-- potreba doladit
CREATE TABLE t_posty
	(
	nazobce		nvarchar(100)	NOT NULL
	,nazcobce	nvarchar(100)	NOT NULL
	,psc		int				NOT NULL
	,nazpost	nvarchar(100)	NOT NULL
	,kod		int				NOT NULL
	,nazokresu	nvarchar(100)	NOT NULL
	)



CREATE TABLE t_funkce (
	id_funkce	int		PRIMARY KEY
	,nazev_funkce	nvarchar(100)
	,osobni_ohodnoceni	numeric(20,2)	NOT NULL
	)
;
GO

CREATE TABLE t_kategorie_zakazniku (
	id_kategorie		int		PRIMARY KEY
	,nazev_kategorie	nvarchar(100)
	,sleva_prirazka		numeric(5,2)
	)
;
GO

CREATE TABLE t_pobocky (
	id_pobocka	int		PRIMARY KEY
	,zkratka	nvarchar(100)	NOT NULL
	,nazev		nvarchar(100)	NOT NULL
	,ulice		nvarchar(100)	NOT NULL
	,mesto		nvarchar(100)	NOT NULL
	,psc		nvarchar(12)	NOT NULL
	,telefon	nvarchar(25)	NOT NULL
	,fax		nvarchar(25)	NULL
	,email		nvarchar(100)	NOT NULL
	,mesicni_pronajem	nvarchar(100)	NOT NULL
	)
;
GO

CREATE TABLE t_zamestnanci (
	id_zamestnanec	int		PRIMARY KEY
	,prijmeni		nvarchar(100)	NOT NULL
	,jmeno			nvarchar(100)	NOT NULL
	,titul			nvarchar(15)	NULL
	,plat1			numeric(20,2)	NOT NULL
	,mena			nvarchar(10)	NOT NULL
	,plat2			nvarchar(100)	NOT NULL
	,id_nadrizeny	int		NOT NULL
	,id_pobocka		int		NOT NULL
	,id_funkce		int		NOT NULL
	,CONSTRAINT FK_zamestnanci_nadrizeny FOREIGN KEY(id_nadrizeny)
		REFERENCES t_zamestnanci(id_zamestnanec)
		ON DELETE CASCADE
		ON UPDATE CASCADE
	,CONSTRAINT FK_zamestnanci_pobocka FOREIGN KEY(id_pobocka)
		REFERENCES t_pobocky(id_pobocka)
		ON DELETE CASCADE
		ON UPDATE CASCADE
	,CONSTRAINT FK_zamestnanci_funkce FOREIGN KEY(id_funkce)
		REFERENCES t_funkce(id_funkce)
		ON DELETE CASCADE
		ON UPDATE CASCADE
		)
;
GO


CREATE TABLE t_ukoly (
	id_ukol		int		PRIMARY KEY
	,id_zamestnanec	int	NOT NULL
	,popis_ukolu	nvarchar(255)	NOT NULL
	,CONSTRAINT FK_ukoly_zamestnanci FOREIGN KEY(id_zamestnanec)
		REFERENCES t_zamestnanci(id_zamestnanec)
		ON DELETE CASCADE
		ON UPDATE CASCADE
	)
;
GO

CREATE TABLE t_zdroje (
	id_zdroj	int		PRIMARY KEY
	,zkratka	nvarchar(50)	NOT NULL
	,popis		nvarchar(255)	NOT NULL
	,id_typ_zdroje	int		NOT NULL
	,naklady_den_1	numeric(20,2)	NOT NULL
	,naklady_den_mena		nvarchar(15)	NOT NULL
	,naklady_den_2	nvarchar(100)	NOT NULL
	,zaklad_den_1	numeric(20,2)	NOT NULL
	,zaklad_den_mena	nvarchar(15)	NOT NULL
	,zaklad_den_2	nvarchar(100)	NOT NULL
	,CONSTRAINT	FK_zdroje_typzdroje	FOREIGN KEY(id_typ_zdroje)
		REFERENCES t_typy_zdroju(id_typ_zdroje)
		ON UPDATE CASCADE
		ON DELETE CASCADE
	)
;
GO

CREATE TABLE t_zakaznici (
	id_zakaznika	int		PRIMARY KEY
	,id_zamestnanec	int		NOT NULL
	,id_kategorie	int		NOT NULL
	,ico			numeric(20,0)	NOT NULL
	,zkratka		nvarchar(20)	NULL
	,nazev			nvarchar(255)	NOT NULL
	,ulice			nvarchar(255)	NOT NULL
	,mesto			nvarchar(255)	NOT NULL
	,psc			numeric(5,0)	NOT NULL
	,kredit1		numeric(20,2)	NOT NULL
	,kredit_mena	nvarchar(15)	NOT NULL
	,kredit2		nvarchar(50)	NOT NULL
	,telefon		numeric(30,2)	NOT NULL
	,fax			nvarchar(50)	NULL
	,webovky		nvarchar(255)	NULL
	,poznamka		nvarchar(255)	NULL
	,CONSTRAINT	FK_zakaznici_zamestnanec	FOREIGN KEY(id_zamestnanec)
		REFERENCES t_zamestnanci(id_zamestnanec)
		ON UPDATE CASCADE
		ON DELETE CASCADE
	,CONSTRAINT FK_zakaznici_kategorie		FOREIGN KEY(id_kategorie)
		REFERENCES t_kategorie_zakazniku(id_kategorie)
		ON UPDATE CASCADE
		ON DELETE CASCADE
	)
;
GO

-- potreba doladit
CREATE TABLE t_kontrakty 
	(
	id_kontrakt		int		PRIMARY KEY
	,id_zakaznik		int		not null
	,id_zdroj	int		not null
	,datumod	date	not null
	,datumdo	date	not null
	,cena_celkem	money	not null
	,naklady_celkem	money	not null
	)
;
GO


