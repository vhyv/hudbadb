/*			Name: dbo.insert_listen

			Co: Vlozeni ratingu, oblibenych songu a data (dnesek, eh) poslechu k albu v db.

			Date: 2018-02-01

			Autor: vhyv

*/


USE hudba;
GO


CREATE PROCEDURE dbo.insert_listen

			@artistname		nvarchar(100)
			,@albumname		nvarchar(100)
			,@rating		decimal(3,1)
			,@favs			nvarchar(100)

AS
BEGIN

	SET NOCOUNT ON

	DECLARE @artistid	int
	DECLARE @albumid	int
	DECLARE @datum		date
	DECLARE @oldrating	decimal(3,1)
	DECLARE @updatedrating	nvarchar(100)
	DECLARE @insertedstuff	nvarchar(200)
	
	IF @rating > 10.0 OR @rating < 0.0 
	BEGIN
		RAISERROR ('Rating must be between zero and ten.', 0, 1)
		RETURN
	END

	SET @datum = CAST(GETDATE() AS date)

	SET @artistid = (SELECT art_id
					FROM artist_info
					WHERE art_name = @artistname)

	SET @albumid = (SELECT alb_id
					FROM album_info 
					WHERE art_id = @artistid
					AND alb_name = @albumname)

	SET @oldrating = (SELECT rating
						FROM listening_history
						WHERE alb_id = @albumid)

	SET @updatedrating = CONCAT('The rating was updated to ', CONVERT(nvarchar(50), @rating), '/10 from ', @oldrating, '/10.')

	SET @insertedstuff = CONCAT('The listening data of ', @albumname, ' by ', @artistname, ' was inserted. The rating is ', @rating, '/10.')

-- Pokud uz to tam je, updatuju jenom rating, ne favs nebo listening date. 

	IF (EXISTS
			(SELECT alb_id
			FROM listening_history
			WHERE alb_id = @albumid
			AND rating IS NOT NULL AND ldate IS NOT NULL)

		AND @oldrating <> @rating)

	BEGIN
		UPDATE listening_history
		SET rating = @rating
		WHERE alb_id = @albumid

		RAISERROR(@updatedrating, 0, 1) WITH NOWAIT
	END	

-- Pokud to tam je, ale rating a datum jsou (for some reason) null, updatuju. Nemelo by se ale stat.

	IF EXISTS
			(SELECT alb_id 
			FROM listening_history
			WHERE alb_id = @albumid
			AND rating IS NULL AND ldate IS NULL)

	BEGIN
		UPDATE listening_history
		SET rating = @rating, ldate = @datum, fav_song = @favs
		WHERE alb_id = @albumid

		RAISERROR(@updatedrating, 0, 1) WITH NOWAIT 
	END

-- Pokud to tam neni vubec, jednoduse vlozim rating, datum a favs.

	IF NOT EXISTS
			(SELECT alb_id
			FROM listening_history
			WHERE alb_id = @albumid)

	BEGIN
		INSERT INTO listening_history (ldate, alb_id, rating, fav_song)
		VALUES (@datum, @albumid, @rating, @favs)
		RAISERROR(@insertedstuff, 0, 1) WITH NOWAIT
	END

-- Jestli jsem neco zle zadal etc, tak to hodi error. Mozno dodelat ruzne druhy na zaklade typu chyby.

	ELSE
	
	BEGIN
		IF @oldrating = @rating

		BEGIN
			RAISERROR('Stary rating se rovna novemu.', 0, 1)
		END

		ELSE
		
		BEGIN
			RAISERROR ('Nothing was added.', 0, 1)
			RETURN
		END
	END
END
;
