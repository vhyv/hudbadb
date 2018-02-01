/*			Name: dbo.insert_style
			
			Datum: 2018-02-01

			Co: Vložení stylu k albu s umìlcem.

			Autor: vhyv
*/

USE hudba;
GO

CREATE PROCEDURE dbo.insert_style
		
		@stylename		nvarchar(50)
		,@artistname	nvarchar(100)
		,@albumname		nvarchar(100)

AS
BEGIN
	
	DECLARE @styleid	int
	DECLARE @artistid	int
	DECLARE @albumid	int

	SET @artistid = (SELECT art_id
					FROM artist_info
					WHERE art_name = @artistname)
	
	SET @albumid = (SELECT alb_id
					FROM album_info
					WHERE art_id = @artistid
					AND alb_name = @albumname)
	
	
	IF NOT EXISTS (SELECT style_name
					FROM style_info
					WHERE style_name = @stylename)
	BEGIN
		INSERT INTO style_info(style_name)
		VALUES (@stylename)
	END
	
	SET @styleid = (SELECT style_id
					FROM style_info
					WHERE style_name = @stylename)

	IF EXISTS(	
			SELECT al.alb_name, ar.art_name, al.style_id
			FROM album_info AS al
				INNER JOIN artist_info AS ar
				ON al.art_id = ar.art_id
			WHERE al.alb_id = @albumid
				AND ar.art_id = @artistid
				AND style_id IS NULL)
	
	BEGIN
		UPDATE al
		SET al.style_id = @styleid
		FROM album_info AS al
			INNER JOIN artist_info AS ar
			ON al.art_id = ar.art_id
		WHERE al.alb_id = @albumid
			AND ar.art_id = @artistid
	END
END
;