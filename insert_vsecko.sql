/*  	Name: dbo.insert_vsetko
	
	DB: hudba

	Co: Vlozeni noveho alba do databaze na zaklade vlozenych hodnot.
	    Pripadne vlozeni noveho umelce/zanru/stylu 
	    Pokud bylo slyseno, pridame i datum a rating etc. 
	
	Date: 5. 1. 2018
	
	Autor: vhyv
	
	Problems: Dost mozno nejde vlozit album + artist bez vlozeni listening history.
			Docasne reseni - rating  0 - takova alba oznacena jako k poslechu (potreba potom s ratingem upravit i datum).
*/

USE hudba;
GO

CREATE PROCEDURE dbo.insert_vsetko

-- Vlozeni vsech nutnych hodnot
	-- Pokud existuje artist, neni treba specifikovat @artistyear 
	-- Artistcountry specifikujeme, at se vyhneme duplikatum
	-- Release: LP/EP/Comp, pripadne Mix (//mixtape)

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
-- Deklarujeme promenne - vsechna potrebna id a dnesni datum.

	DECLARE @genreid AS int
	DECLARE @styleid AS int
	DECLARE @artistid AS int
	DECLARE @albumid AS int
	DECLARE @den AS date

-- Datum poslechu je dnesek, protoze proc ne.

	SET @den = CAST(GETDATE() AS date)

-- Pokud neexistuji, vlozime novy zanrd nebo styl do prislusneho tejblu. 

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
	
-- Pokud neexistuje, pridame prislusneho umelce a jeho zemi a rok, kdy zacal pusobit.

	IF NOT EXISTS
		(SELECT art_name, art_country 
		FROM artist_info 
		WHERE LOWER(art_name) = LOWER(@artistname)
		 AND LOWER(art_country) = LOWER(@artistcountry))

	BEGIN
		INSERT INTO artist_info(art_name, art_country, art_year)
		VALUES (@artistname, @artistcountry, @artistyear)
	END
-- Na zaklade toho, co je v tejblu, urcime artistid
	SET @artistid = (SELECT art_id FROM artist_info WHERE art_name = @artistname AND art_country = @artistcountry)

-- Vyhybame se i pridani duplkatu alba. Snad.
-- IDcka vytazena zhora, zbytek straightforward.

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

-- Pridani alba mezi poslechnuta
-- Pokud uz tam je, updatujeme POUZE rating.
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
