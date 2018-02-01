/*			  Name: dbo.insert_albart
			  Datum: 2018-01-31
      
			  DB: Hudba
      
			  Co: Pridani alba a umelce (pripadne zanru a stylu) bez poslechu.
			  Autor: vhyv
*/

USE hudba;
GO

CREATE PROCEDURE dbo.insert_albart

	
	@albumname		nvarchar(100)
	,@artistname	nvarchar(100)
	,@artistcountry	nvarchar(100)
	,@artistyear	int				
	,@albumyear		int
	,@genre			nvarchar(50)
	,@style			nvarchar(50)
	,@release		nvarchar(4)


AS
BEGIN
	
	SET NOCOUNT ON

-- Release check

	IF @release NOT IN ('LP', 'EP', 'Mix', 'Comp')
	BEGIN
		RAISERROR ('Release must be one of these: LP, EP, Mix or Comp', 0, 1)
		RETURN
	END

-- Year check #1

	ELSE IF @albumyear < 1900 OR @artistyear < 1900
	BEGIN
		RAISERROR ('Artist or album must be from 20th century onwards', 0, 1)
		RETURN
	END

-- Year check #2

	ELSE IF @albumyear > YEAR(DATEADD(year, 1, GETDATE())) OR @artistyear > YEAR(DATEADD(year, 1, GETDATE())) 
	BEGIN
		RAISERROR ('Artist or album cannot be from the future.', 0, 1)
		RETURN
	END

	ELSE IF @artistyear > @albumyear
	BEGIN
		RAISERROR ('Artist must be older than the album.', 0, 1)
		RETURN	
	END

	ELSE

	DECLARE @genreid AS int
	DECLARE @styleid AS int
	DECLARE @artistid AS int
	DECLARE @newgenre	nvarchar(200)
	DECLARE @newstyle	nvarchar(200)
	DECLARE @newartist	nvarchar(200)
	DECLARE @newalbum	nvarchar(200)

	SET @newgenre = CONCAT('A new genre( ', CONVERT(nvarchar(50), @genre), ') was added.')

	SET @newstyle = CONCAT('A new style( ', CONVERT(nvarchar(50), @style), ') was added.')

	SET @newartist = CONCAT('A new artist( ', CONVERT(nvarchar(50), @artistname), ') was added.')

	SET @newalbum = CONCAT('A new album( ', CONVERT(nvarchar(50), @albumname), ') was added.')

-- Pokud neexistuji, vlozime novy zanrd nebo styl do prislusneho tejblu. 

	IF NOT EXISTS (SELECT genre_name
					FROM genre_info
					WHERE LOWER(genre_name) = LOWER(@genre))

	BEGIN
		INSERT INTO genre_info (genre_name)
		VALUES (@genre)
		
		RAISERROR (@newgenre, 0, 1) WITH NOWAIT
	END

	IF NOT EXISTS (SELECT style_name
					FROM style_info
					WHERE LOWER(style_name) = LOWER(@style))

	BEGIN
		INSERT INTO style_info (style_name)
		VALUES (@style)

		RAISERROR (@newstyle, 0, 1) WITH NOWAIT
	END

-- Pridame hodnoty ID promennym.

	SET @genreid = (SELECT genre_id
					FROM genre_info
					WHERE genre_name = @genre)

	SET @styleid = (SELECT style_id
					FROM style_info
					WHERE style_name = @style)

-- Zkontrolujeme, jestli uz existuje umelec.

	IF NOT EXISTS (SELECT art_name, art_country 
					FROM artist_info
					WHERE LOWER(art_name) = LOWER(@artistname)
					AND LOWER(art_country) = LOWER(@artistcountry))

-- Pokud ne, pridame.

	BEGIN
		INSERT INTO artist_info (art_name, art_country, art_year)
		VALUES (@artistname, @artistcountry, @artistyear)

		RAISERROR (@newartist, 0, 1) WITH NOWAIT
	END

	SET @artistid = (SELECT art_id
					 FROM artist_info
					 WHERE art_name = @artistname
						AND art_country = @artistcountry)

-- Kontrol, jestli existuje album.

	IF NOT EXISTS (SELECT al.alb_name, al.alb_year, ar.art_name
					FROM album_info AS al
						INNER JOIN artist_info AS ar
						ON al.art_id = ar.art_id
					WHERE LOWER(al.alb_name) = LOWER(@albumname)
					AND al.alb_year = @albumyear
					AND LOWER(ar.art_name) = LOWER(@artistname))
-- Pokud ne, pridame.
	
	BEGIN
		INSERT INTO album_info (alb_name, art_id, alb_year, genre_id, style_id, release)
		VALUES (@albumname, @artistid, @albumyear, @genreid, @styleid, @release)

		RAISERROR (@newalbum, 0, 1) WITH NOWAIT
	END

	ELSE

	BEGIN
		RAISERROR ('Nothing happened.', 0, 1) WITH NOWAIT
		RETURN
	END
END
;