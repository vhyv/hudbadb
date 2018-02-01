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

	DECLARE @artistid	int
	DECLARE @albumid	int
	DECLARE @datum		date

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


	IF EXISTS
			(SELECT alb_id 
			FROM listening_history
			WHERE alb_id = @albumid
			AND rating IS NULL AND ldate IS NULL)

	BEGIN
		UPDATE listening_history
		SET rating = @rating, ldate = @datum, fav_song = @favs
		WHERE alb_id = @albumid
		RAISERROR('Rating was updated.', 0, 1) WITH NOWAIT 
	END

	IF NOT EXISTS
			(SELECT alb_id
			FROM listening_history
			WHERE alb_id = @albumid)

	BEGIN
		INSERT INTO listening_history (ldate, alb_id, rating, fav_song)
		VALUES (@datum, @albumid, @rating, @favs)
		RAISERROR('Album and rating were inserted.', 0, 1) WITH NOWAIT
	END

	ELSE
	
	BEGIN
		RAISERROR ('Nothing was added.', 0, 1)
		RETURN
	END
END
;
