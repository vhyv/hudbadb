/*  Název: dbo.insert_vsetko
	
	Databáze: hudba

	Úkol: Vloení nového alba do databáze na základì vloenıch hodnot.
		  Pøípadné vloení nového umìlce/ánru/stylu.
		  Pokud bylo slyšeno, pøidáme i datum a 
	
	Datum: 5. 1. 2018
	
	Autor: vhyv
	
	Spouštìní: V celku
	
	Neopravené problémy: Dost mono nejde vloit album + artist bez vloení listening history.
			Doèasné øešení - rating  0 - taková alba oznaèená jako k poslechu (potøeba potom s ratingem upravit i datum).
*/

USE hudba;
GO

CREATE PROCEDURE dbo.insert_vsetko

-- Vloení všech nutnıch hodnot
	-- Pokud existuje artist, není tøeba specifikovat @artistyear 
	-- Artistcountry specifikujeme, a se vyhneme duplikátùm
	-- Release: LP/EP/Comp, pøípadnì Mix

	@albumname		nvarchar(100),
	@artistname		nvarchar(100),
	@artistcountry	nvarchar(100),
	@artistyear		int,
	@albumyear		int,
	@genre			nvarchar(100),
	@style			nvarchar(100)	= NULL,
	@release		nvarchar(5),
	@rating			decimal(5,2)	= NULL,
	@favs			nvarchar(200)	= NULL

AS
BEGIN
	SET NOCOUNT ON

-- Rating bottom check.

	IF @rating < 0
	BEGIN	
		RAISERROR ('Rating must be at least zero.', 0, 1)
		RETURN
	END

-- Rating top check.

	ELSE IF @rating > 10
	BEGIN
		RAISERROR ('Rating must be less than 10.', 0, 1)
		RETURN
	END

-- Release check.

	ELSE IF @release NOT IN ('LP', 'EP', 'Comp', 'Mix')
	BEGIN
		RAISERROR ('Release must be one of these: LP, EP, Comp or Mix.', 0, 1)
		RETURN
	END

-- Year check #1.

	ELSE IF @albumyear < 1900 OR @artistyear < 1900 
	BEGIN
		RAISERROR ('Album or Artist must be from 20th century onwards.', 0, 1)
		RETURN
	END

-- Year check #2.

	ELSE IF @albumyear > YEAR(DATEADD(year, 1, GETDATE())) OR @artistyear > YEAR(DATEADD(year, 1, GETDATE()))
	BEGIN
		RAISERROR ('Album or Artist cannot be from the future.', 0, 1)
		RETURN
	END
-- Artist vs Album year check

	ELSE IF @albumyear < @artistyear
	BEGIN
		RAISERROR ('Artist must be older than the album.', 0, 1)
		RETURN
	END
	
	ELSE
-- Deklarujeme promìnné - všechna potøebná id a dnešní datum.

	DECLARE @genreid AS int
	DECLARE @styleid AS int
	DECLARE @artistid AS int
	DECLARE @albumid AS int
	DECLARE @den AS date

-- Datum poslechu je dnešek, protoe proè ne.

	SET @den = CAST(GETDATE() AS date)

-- Pokud neexistují, vloíme novı ánr nebo styl do pøísluného tejblu.

	IF NOT EXISTS (SELECT genre_name
					 FROM genre_info
					 WHERE LOWER(genre_name) = LOWER(@genre))
		
	BEGIN	
		INSERT INTO hudba.dbo.genre_info(genre_name)
		VALUES (@genre)
	END

	IF NOT EXISTS (SELECT style_name
					 FROM style_info
					 WHERE LOWER(style_name) = LOWER(@style))
		
	BEGIN	
		INSERT INTO hudba.dbo.style_info(style_name)
		VALUES (@style)
	END

	SET @genreid = (SELECT genre_id FROM genre_info WHERE genre_name = @genre)
	SET @styleid = (SELECT style_id FROM style_info WHERE style_name = @style)
	
-- Pokud neexistuje, pøidáme pøíslušného umìlce a jeho zemi a rok, kdy zaèal pùsobit

	IF NOT EXISTS
		(SELECT art_name, art_country 
		FROM artist_info 
		WHERE LOWER(art_name) = LOWER(@artistname)
		 AND LOWER(art_country) = LOWER(@artistcountry))

	BEGIN
		INSERT INTO artist_info(art_name, art_country, art_year)
		VALUES (@artistname, @artistcountry, @artistyear)
	END
-- Na základì toho, co je v tejblu, urèíme artistid
	SET @artistid = (SELECT art_id FROM artist_info WHERE art_name = @artistname AND art_country = @artistcountry)

-- Vyhıbáme se i pøidání duplikátu alba. Snad.
-- IDèka vytaená zhora, zbytek straightforward

	IF NOT EXISTS
		(SELECT al.alb_name, al.alb_year, ar.art_name
		 FROM album_info AS al
			INNER JOIN artist_info AS ar
			ON al.art_id = ar.art_id
		 WHERE LOWER(al.alb_name) = LOWER(@albumname)
				 AND al.alb_year = @albumyear
				 AND LOWER(ar.art_name) = LOWER(@artistname))
	BEGIN
		INSERT INTO album_info(alb_name, art_id, alb_year, genre_id, style_id, release)
		VALUES (@albumname, @artistid, @albumyear, @genreid, @styleid, @release)
	END

	SET @albumid = (SELECT alb_id FROM album_info WHERE alb_name = @albumname AND alb_year = @albumyear AND art_id = @artistid)

-- Pøídání alba mezi poslechnuté
-- Pokud u tam je, updatujeme POUZE rating.
	IF EXISTS
		(SELECT alb_id
		 FROM listening_history
		 WHERE alb_id = @albumid)

	BEGIN
		UPDATE listening_history
		SET rating = @rating
		WHERE alb_id = @albumid
	END

	IF NOT EXISTS
		(SELECT alb_id
		 FROM listening_history
		 WHERE alb_id = @albumid)
	BEGIN
		INSERT INTO listening_history(ldate, alb_id, rating, fav_song)
		VALUES (@den, @albumid, @rating, @favs)
	END
END;