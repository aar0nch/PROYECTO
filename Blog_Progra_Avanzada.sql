use Blog_Progra_Avanzada
select * from dbo.TBL_Usuario

----------------------------------------------------------------------------------------------------
								     	/*CREACION DE TABLAS*/
----------------------------------------------------------------------------------------------------

/******     [TBL_Usuario]    ******/
CREATE TABLE TBL_Usuario (
    PK_IdUsuario BIGINT IDENTITY(1,1) PRIMARY KEY,
    Nombre VARCHAR(100) NOT NULL,
    Correo VARCHAR(200) NOT NULL UNIQUE,
    Contra VARCHAR(200) NOT NULL,
    Rol VARCHAR(100) NOT NULL,
    Estado BIT NOT NULL,
    Descripcion VARCHAR(500),
    Cant_post INT DEFAULT 0,
    strikes INT DEFAULT 0,
    FK_Usuario_Creacion VARCHAR(50) NOT NULL,
    FK_Usuario_Modificacion VARCHAR(50) NOT NULL,
    Fecha_Creacion DATETIME NOT NULL,
    Fecha_Modificacion DATETIME NOT NULL
);

/******     [TBL_Posts]    ******/
CREATE TABLE TBL_Posts (
    PK_IdPost INT IDENTITY(1,1) PRIMARY KEY,
    FK_IdUsuario BIGINT NOT NULL,
    Titulo VARCHAR(50) NOT NULL,
    Descripcion VARCHAR(500),
    CONSTRAINT FK_TBL_Posts_TBL_Usuario FOREIGN KEY (FK_IdUsuario)
        REFERENCES TBL_Usuario (PK_IdUsuario)
        ON DELETE CASCADE
);

ALTER TABLE TBL_Posts
ALTER COLUMN Descripcion VARCHAR(3000);

ALTER TABLE TBL_Posts
ADD Imagen VARCHAR(255) NULL;


/******     [TBL_Reportes]    ******/
CREATE TABLE TBL_Reportes (
    PK_IdReporte INT IDENTITY(1,1) PRIMARY KEY,
    FK_IdUsuario BIGINT NOT NULL,
    CONSTRAINT FK_TBL_Reportes_TBL_Usuario FOREIGN KEY (FK_IdUsuario)
        REFERENCES TBL_Usuario (PK_IdUsuario)
        ON DELETE CASCADE
);

ALTER TABLE TBL_Reportes
ADD Nombre VARCHAR(100) NOT NULL;

/******     [TBL_Seguidos]    ******/
CREATE TABLE TBL_Seguidos (
    FK_IdUsuario BIGINT NOT NULL,
    FK_IdUsuario_Seguido BIGINT NOT NULL,
    PRIMARY KEY (FK_IdUsuario, FK_IdUsuario_Seguido),
    CONSTRAINT FK_TBL_Seguidos_TBL_Usuario FOREIGN KEY (FK_IdUsuario)
        REFERENCES TBL_Usuario (PK_IdUsuario)
        ON DELETE NO ACTION,
    CONSTRAINT FK_TBL_Seguidos_TBL_Usuario_Seguido FOREIGN KEY (FK_IdUsuario_Seguido)
        REFERENCES TBL_Usuario (PK_IdUsuario)
        ON DELETE NO ACTION
);

/******     [TBL_Comentarios]    ******/

CREATE TABLE TBL_Comentarios (
    PK_IdComentario INT IDENTITY(1,1) PRIMARY KEY,
    FK_IdPost INT NOT NULL,
    Comentario VARCHAR(3000),
    CONSTRAINT FK_TBL_Comentarios_TBL_Posts FOREIGN KEY (FK_IdPost)
        REFERENCES TBL_Posts (PK_IdPost)
        ON DELETE CASCADE
);

	
----------------------------------------------------------------------------------------------------
									/*PROCEDIMIENTOS ALMACENADOS*/
----------------------------------------------------------------------------------------------------
-------------------------------------------------
					/*Reportes*/
-------------------------------------------------
-- HACER STRIKE
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

CREATE OR ALTER PROCEDURE [dbo].[sp_HacerStrike]
    @PK_IdReporte INT  -- ID del reporte para hacer el strike
AS
BEGIN
    SET NOCOUNT ON;

    DECLARE @FK_IdUsuario BIGINT;  -- ID del usuario del reporte
    DECLARE @StrikesActuales INT;  -- Número actual de strikes del usuario

    -- Obtener el FK_IdUsuario del reporte
    SELECT @FK_IdUsuario = FK_IdUsuario
    FROM dbo.TBL_Reportes
    WHERE PK_IdReporte = @PK_IdReporte;

    -- Verificar si se encontró el usuario asociado al reporte
    IF @FK_IdUsuario IS NULL
    BEGIN
        PRINT 'Reporte no encontrado o no tiene asociado un usuario.';
        RETURN;
    END

    -- Eliminar todos los reportes del usuario
    EXEC dbo.sp_EliminarReportesUsuario @FK_IdUsuario;

    -- Eliminar los registros en TBL_Seguidos que dependen del usuario
    DELETE FROM dbo.TBL_Seguidos
    WHERE FK_IdUsuario = @FK_IdUsuario OR FK_IdUsuario_Seguido = @FK_IdUsuario;

    -- Actualizar el número de strikes del usuario
    UPDATE dbo.TBL_Usuario
    SET strikes = strikes + 1
    WHERE PK_IdUsuario = @FK_IdUsuario;

    -- Obtener el nuevo número de strikes
    SELECT @StrikesActuales = strikes
    FROM dbo.TBL_Usuario
    WHERE PK_IdUsuario = @FK_IdUsuario;

    -- Verificar si el usuario tiene 3 o más strikes y eliminar al usuario si es el caso
    IF @StrikesActuales >= 3
    BEGIN
        -- Eliminar al usuario
        DELETE FROM dbo.TBL_Usuario
        WHERE PK_IdUsuario = @FK_IdUsuario;
    END

    -- Mensaje opcional para confirmar la operación
    PRINT 'Strike aplicado y usuario eliminado si tiene 3 o más strikes.';
END;
GO





--REPORTAR USUARIO SP
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

CREATE OR ALTER PROCEDURE [dbo].[sp_ReportarUsuario]
    @IdUsuario BIGINT  -- ID del usuario a reportar
AS
BEGIN
    SET NOCOUNT ON;

    DECLARE @NombreUsuario VARCHAR(100);

    -- Obtener el nombre del usuario a partir de su ID
    SELECT @NombreUsuario = Nombre 
    FROM TBL_Usuario 
    WHERE PK_IdUsuario = @IdUsuario;

    -- Insertar el ID del usuario y su nombre en la tabla TBL_Reportes
    INSERT INTO TBL_Reportes (FK_IdUsuario, Nombre)
    VALUES (@IdUsuario, @NombreUsuario);

    -- Mensaje opcional para confirmar la inserción
    PRINT 'Usuario reportado con éxito';
END;
GO

--LISTAR REPORTES
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

CREATE PROCEDURE [dbo].[sp_ListarReportes]
AS
BEGIN
    SET NOCOUNT ON;

    SELECT 
        PK_IdReporte,
        FK_IdUsuario,
        Nombre
    FROM 
        dbo.TBL_Reportes
    ORDER BY 
        PK_IdReporte;
END;
GO

--LISTAR REPORTES POR NOMBRE
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

CREATE OR ALTER PROCEDURE [dbo].[sp_ListarReportesxNombre]
    @Nombre NVARCHAR(50)
AS
BEGIN
    SET NOCOUNT ON;

    SELECT 
        PK_IdReporte,
        FK_IdUsuario,
        Nombre
    FROM 
        dbo.TBL_Reportes
    WHERE 
        Nombre LIKE '%' + @Nombre + '%'
    ORDER BY 
        PK_IdReporte;
END;
GO

--ELIMINAR REPORTES DE USUARIO
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

CREATE OR ALTER PROCEDURE [dbo].[sp_EliminarReportesUsuario]
    @FK_IdUsuario BIGINT  -- ID del usuario cuyos reportes serán eliminados
AS
BEGIN
    SET NOCOUNT ON;

    -- Eliminar todos los reportes asociados al usuario especificado
    DELETE FROM dbo.TBL_Reportes
    WHERE FK_IdUsuario = @FK_IdUsuario;

    -- Mensaje opcional para confirmar la eliminación
    PRINT 'Reportes del usuario eliminados con éxito';
END;
GO


-------------------------------------------------
					/*Seguidos*/
-------------------------------------------------
CREATE PROCEDURE sp_SeguirUsuario
    @IdUsuario BIGINT,
    @IdUsuarioSeguido BIGINT
AS
BEGIN
    SET NOCOUNT ON;

    -- Verifica si el usuario ya sigue al otro usuario
    IF NOT EXISTS (
        SELECT 1
        FROM TBL_Seguidos
        WHERE FK_IdUsuario = @IdUsuario
          AND FK_IdUsuario_Seguido = @IdUsuarioSeguido
    )
    BEGIN
        -- Inserta el nuevo seguimiento
        INSERT INTO TBL_Seguidos (FK_IdUsuario, FK_IdUsuario_Seguido)
        VALUES (@IdUsuario, @IdUsuarioSeguido);
        -- Retorna 1 para indicar éxito
        SELECT 1 AS Result;
    END
    ELSE
    BEGIN
        -- El usuario ya sigue a este usuario, retorna 0 para indicar que no se realizó la inserción
        SELECT 0 AS Result;
    END
END;
GO





-------------------------------------------------
					/*Usuario*/
-------------------------------------------------
/****** Object:  StoredProcedure [dbo].[sp_ObtenerUsuarioPorId]     ******/

CREATE PROCEDURE sp_ObtenerUsuarioPorId
    @IdUsuario BIGINT
AS
BEGIN
    -- Set the context of the procedure
    SET NOCOUNT ON;

    -- Query to select the user information
    SELECT 
        PK_IdUsuario,
        Nombre,
        Correo,
        Contra,
        Rol,
        Estado,
        Descripcion,
        Cant_post,
        strikes,
        FK_Usuario_Creacion,
        FK_Usuario_Modificacion,
        Fecha_Creacion,
        Fecha_Modificacion
    FROM 
        TBL_Usuario
    WHERE 
        PK_IdUsuario = @IdUsuario;
END;




/****** Object:  StoredProcedure [dbo].[sp_ValidarCredenciales]     ******/
GO 
	
CREATE PROCEDURE sp_ValidarCredenciales
    @Correo VARCHAR(200),
    @Contra VARCHAR(100)
AS
BEGIN
    SET NOCOUNT ON;

    -- Declarar una variable para almacenar el ID del usuario encontrado
    DECLARE @IdUsuarioEncontrado BIGINT;

    -- Buscar el usuario que coincida con el correo y la contraseña proporcionados
    SELECT @IdUsuarioEncontrado = PK_IdUsuario
    FROM TBL_USUARIO
    WHERE Correo = @Correo AND Contra = @Contra;

    -- Si se encontró el usuario, devolver sus datos
    IF @IdUsuarioEncontrado IS NOT NULL
    BEGIN
        SELECT PK_IdUsuario,
               Nombre,
               Correo,
               Contra,
               Rol,
               Estado,
               FK_Usuario_Creacion,
               FK_Usuario_Modificacion,
               Fecha_Creacion,
               Fecha_Modificacion
        FROM TBL_USUARIO
        WHERE PK_IdUsuario = @IdUsuarioEncontrado;
    END
END

	
/****** Object:  StoredProcedure [dbo].[sp_ListarUsuario]     ******/

SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

CREATE OR ALTER PROCEDURE [dbo].[sp_ListarUsuario]
AS
BEGIN
    SET NOCOUNT ON;

    SELECT 
        PK_IdUsuario,
        Nombre,
        Correo,
        Contra,
        Rol,
		strikes,
        Estado,
        FK_Usuario_Creacion,
        FK_Usuario_Modificacion,
        Fecha_Creacion,
        Fecha_Modificacion
    FROM 
        dbo.TBL_USUARIO
    ORDER BY 
        PK_IdUsuario;
END;
GO


/****** Object:  StoredProcedure [dbo].[sp_ListarUsuarioxUsuario]     ******/

SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

CREATE PROCEDURE [dbo].[sp_ListarUsuarioxUsuario]
    @Nombre NVARCHAR(255)
AS
BEGIN
    SET NOCOUNT ON;

    SELECT 
        PK_IdUsuario,
        Nombre,
        Correo,
        Contra,
        Rol,
        Estado,
        FK_Usuario_Creacion,
        FK_Usuario_Modificacion,
        Fecha_Creacion,
        Fecha_Modificacion
    FROM 
        dbo.TBL_USUARIO 
    WHERE 
        Nombre LIKE '%' + @Nombre + '%'
    ORDER BY 
        Nombre;
END;
GO


/****** Object:  StoredProcedure [dbo].[sp_InsertarUsuario]     ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

CREATE PROCEDURE [dbo].[sp_InsertarUsuario]
    @P_PK_IdUsuario BIGINT,
    @P_Nombre VARCHAR(100),
    @P_Correo VARCHAR(200),
    @P_Contra VARCHAR(200),
    @P_Rol VARCHAR(100),
    @P_Estado BIT,
    @P_FK_Usuario_Creacion VARCHAR(50),
    @P_FK_Usuario_Modificacion VARCHAR(50),
    @P_Fecha_Creacion DATETIME,
    @P_Fecha_Modificacion DATETIME
AS
BEGIN
    SET NOCOUNT ON;
    BEGIN TRAN [sp_InsertarUsuario]
    BEGIN TRY
        BEGIN
            INSERT INTO [dbo].[TBL_Usuario]
            (
                Nombre,
                Correo,
                Contra,
                Rol,
                Estado,
                FK_Usuario_Creacion,
                FK_Usuario_Modificacion,
                Fecha_Creacion,
                Fecha_Modificacion
            )
            VALUES
            (
                @P_Nombre,
                @P_Correo,
                @P_Contra,
                @P_Rol,
                @P_Estado,
                @P_FK_Usuario_Creacion,
                @P_FK_Usuario_Modificacion,
                @P_Fecha_Creacion,
                @P_Fecha_Modificacion
            );
        END;

        COMMIT TRANSACTION
        RETURN 1
    END TRY
    BEGIN CATCH
        ROLLBACK TRANSACTION
        -- Capture detailed error information
        DECLARE @ErrorMessage NVARCHAR(4000);
        SET @ErrorMessage = ERROR_MESSAGE();
        PRINT 'Error: ' + @ErrorMessage;
        RETURN 0
    END CATCH
END;
GO


/****** Object:  StoredProcedure [dbo].[sp_ModificarUsuario]     ******/

SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

CREATE PROCEDURE [dbo].[sp_ModificarUsuarioMiCuenta]
    @P_PK_IdUsuario BIGINT,
    @P_Nombre VARCHAR(100),
    @P_Correo VARCHAR(200),
    @P_Contra VARCHAR(200),
    @P_Rol VARCHAR(100),
    @P_Estado BIT,
	@P_Descripcion VARCHAR(500),
    @P_FK_Usuario_Creacion VARCHAR(50),
    @P_FK_Usuario_Modificacion VARCHAR(50),
	@P_Fecha_Creacion DATETIME,
    @P_Fecha_Modificacion DATETIME
AS
BEGIN
    SET NOCOUNT ON;
    BEGIN TRAN [sp_ModificarUsuario]
    BEGIN TRY
        UPDATE dbo.TBL_USUARIO
            SET Nombre = @P_Nombre,
                Correo = @P_Correo,
                Contra = @P_Contra,
                Rol = @P_Rol,
                Estado = @P_Estado,
				Descripcion = @P_Descripcion,
                FK_Usuario_Modificacion = @P_FK_Usuario_Modificacion,
                Fecha_Modificacion = @P_Fecha_Modificacion
            WHERE PK_IdUsuario = @P_PK_IdUsuario;

        COMMIT TRANSACTION
        RETURN 1
    END TRY
    BEGIN CATCH
        ROLLBACK TRANSACTION
        RETURN 0
    END CATCH
END;
GO



/****** Object:  StoredProcedure [dbo].[sp_ModificarUsuario]     ******/

SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

CREATE PROCEDURE [dbo].[sp_ModificarUsuario]
    @P_PK_IdUsuario BIGINT,
    @P_Nombre VARCHAR(100),
    @P_Correo VARCHAR(200),
    @P_Contra VARCHAR(200),
    @P_Rol VARCHAR(100),
    @P_Estado BIT,
    @P_FK_Usuario_Creacion VARCHAR(50),
    @P_FK_Usuario_Modificacion VARCHAR(50),
	@P_Fecha_Creacion DATETIME,
    @P_Fecha_Modificacion DATETIME
AS
BEGIN
    SET NOCOUNT ON;
    BEGIN TRAN [sp_ModificarUsuario]
    BEGIN TRY
        UPDATE dbo.TBL_USUARIO
            SET Nombre = @P_Nombre,
                Correo = @P_Correo,
                Contra = @P_Contra,
                Rol = @P_Rol,
                Estado = @P_Estado,
                FK_Usuario_Modificacion = @P_FK_Usuario_Modificacion,
                Fecha_Modificacion = @P_Fecha_Modificacion
            WHERE PK_IdUsuario = @P_PK_IdUsuario;

        COMMIT TRANSACTION
        RETURN 1
    END TRY
    BEGIN CATCH
        ROLLBACK TRANSACTION
        RETURN 0
    END CATCH
END;
GO


/****** Object:  StoredProcedure [dbo].[sp_EliminarUsuario]     ******/

SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

CREATE PROCEDURE [dbo].[sp_EliminarUsuario]
    @P_PK_IdUsuario BIGINT
AS
BEGIN
    SET NOCOUNT ON;
    BEGIN TRAN [sp_EliminarUsuario]
    BEGIN TRY
        UPDATE dbo.TBL_USUARIO SET Estado = 0 WHERE PK_IdUsuario = @P_PK_IdUsuario;

        COMMIT TRANSACTION
        RETURN 1
    END TRY
    BEGIN CATCH
        ROLLBACK TRANSACTION
        RETURN 0
    END CATCH
END;
GO


/****** Object:  StoredProcedure [dbo].[sp_ObtenerUsuario]     ******/

SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

CREATE PROCEDURE [dbo].[sp_ObtenerUsuario]
    @PK_IdUsuario BIGINT
AS
BEGIN
    SET NOCOUNT ON;

    SELECT 
        PK_IdUsuario,
        Nombre,
        Correo,
        Contra,
        Rol,
        Estado,
        FK_Usuario_Creacion,
        FK_Usuario_Modificacion,
        Fecha_Creacion,
        Fecha_Modificacion
    FROM 
        dbo.TBL_USUARIO 
    WHERE 
        PK_IdUsuario = @PK_IdUsuario
END;
GO


-------------------------------------------------
					/*Post*/
-------------------------------------------------
-- Stored Procedure to list posts from followed users
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

CREATE OR ALTER PROCEDURE [dbo].[sp_ListarPostsPorSeguidor]
    @IdUsuario BIGINT
AS
BEGIN
    SET NOCOUNT ON;

    -- Select posts from users that the given user follows
    SELECT 
        p.PK_IdPost,
        p.FK_IdUsuario,
        p.Titulo,
        p.Descripcion,
        p.Imagen  -- Nueva columna añadida
    FROM 
        dbo.TBL_Posts p
    INNER JOIN 
        dbo.TBL_Seguidos s ON p.FK_IdUsuario = s.FK_IdUsuario_Seguido
    WHERE 
        s.FK_IdUsuario = @IdUsuario
    ORDER BY 
        p.PK_IdPost DESC;
END;
GO


-- Stored Procedure to list all posts
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

CREATE OR ALTER PROCEDURE [dbo].[sp_ListarPosts]
AS
BEGIN
    SET NOCOUNT ON;

    SELECT 
        PK_IdPost,
        FK_IdUsuario,
        Titulo,
        Descripcion,
        Imagen  -- Nueva columna añadida
    FROM 
        dbo.TBL_Posts
    ORDER BY 
        PK_IdPost DESC;
END;
GO


-- Stored Procedure to list posts by title
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

CREATE OR ALTER PROCEDURE [dbo].[sp_ListarPostsxTitulo]
    @Titulo NVARCHAR(50)
AS
BEGIN
    SET NOCOUNT ON;

    SELECT 
        PK_IdPost,
        FK_IdUsuario,
        Titulo,
        Descripcion,
        Imagen  -- Nueva columna añadida
    FROM 
        dbo.TBL_Posts
    WHERE 
        Titulo LIKE '%' + @Titulo + '%'
    ORDER BY 
        PK_IdPost DESC;
END;
GO


-- Stored Procedure to insert a post
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

CREATE OR ALTER PROCEDURE [dbo].[sp_InsertarPost]
    @P_PK_IdPost INT OUTPUT,
    @P_FK_IdUsuario BIGINT,
    @P_Titulo VARCHAR(50),
    @P_Descripcion VARCHAR(500),
    @P_Imagen VARCHAR(255) = NULL -- Nueva variable para la imagen, permite NULL
AS
BEGIN
    SET NOCOUNT ON;
    BEGIN TRAN [sp_InsertarPost]
    BEGIN TRY
        INSERT INTO [dbo].[TBL_Posts]
        (
            FK_IdUsuario,
            Titulo,
            Descripcion,
            Imagen -- Nueva columna
        )
        VALUES
        (
            @P_FK_IdUsuario,
            @P_Titulo,
            @P_Descripcion,
            @P_Imagen -- Valor para la imagen
        );

        -- Devuelve el nuevo ID del post
        SET @P_PK_IdPost = SCOPE_IDENTITY();
        
        COMMIT TRANSACTION
        RETURN 1
    END TRY
    BEGIN CATCH
        ROLLBACK TRANSACTION
        RETURN 0
    END CATCH
END;
GO

CREATE PROCEDURE [dbo].[sp_ObtenerPost] 
    @PK_IdPost INT
AS
BEGIN
    SET NOCOUNT ON;

    SELECT 
        PK_IdPost,
        FK_IdUsuario,
        Titulo,
        Descripcion
    FROM 
        dbo.TBL_Posts
    WHERE 
        PK_IdPost = @PK_IdPost;
END;
GO


-- Stored Procedure to listar post por usuarios (se usa en misPost)
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

CREATE OR ALTER PROCEDURE [dbo].[sp_ListarPostsPorUsuario]
    @UsuarioId BIGINT
AS
BEGIN
    SET NOCOUNT ON;

    SELECT 
        PK_IdPost,
        FK_IdUsuario,
        Titulo,
        Descripcion,
		Imagen
    FROM 
        dbo.TBL_Posts
    WHERE 
        FK_IdUsuario = @UsuarioId
    ORDER BY 
        PK_IdPost DESC;
END;
GO


-- Stored Procedure to Eliminar post (elimina también los comentarios asociados)

CREATE PROCEDURE [dbo].[sp_EliminarPost]
    @PK_IdPost INT
AS
BEGIN
    -- Comprobar que el post existe
    IF NOT EXISTS (SELECT 1 FROM TBL_Posts WHERE PK_IdPost = @PK_IdPost)
    BEGIN
        RAISERROR('El post con el ID especificado no existe.', 16, 1);
        RETURN;
    END
    
    -- Eliminar el post (los comentarios se eliminarán automáticamente debido a ON DELETE CASCADE)
    DELETE FROM TBL_Posts WHERE PK_IdPost = @PK_IdPost;

    -- Confirmar la transacción si se completó exitosamente
    IF @@ERROR = 0
    BEGIN
        PRINT 'Post y comentarios asociados eliminados exitosamente.';
    END
    ELSE
    BEGIN
        RAISERROR('Error al eliminar el post y comentarios asociados.', 16, 1);
    END
END;
GO

-------------------------------------------------
					/*Comentarios*/
-------------------------------------------------
-- Stored Procedure to list all comments
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

CREATE PROCEDURE [dbo].[sp_ListarComentariosPorPost]
    @FK_IdPost INT
AS
BEGIN
    SET NOCOUNT ON;

    SELECT 
        PK_IdComentario,
        FK_IdPost,
        Comentario
    FROM 
        dbo.TBL_Comentarios
    WHERE 
        FK_IdPost = @FK_IdPost
    ORDER BY 
        PK_IdComentario;
END;
GO


-- Stored Procedure to list comments by content
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

CREATE PROCEDURE [dbo].[sp_ListarComentariosPorPostYContenido]
    @FK_IdPost INT,
    @Comentario NVARCHAR(3000)
AS
BEGIN
    SET NOCOUNT ON;

    SELECT 
        PK_IdComentario,
        FK_IdPost,
        Comentario
    FROM 
        dbo.TBL_Comentarios
    WHERE 
        FK_IdPost = @FK_IdPost AND
        Comentario LIKE '%' + @Comentario + '%'
    ORDER BY 
        PK_IdComentario;
END;
GO




-- Stored Procedure to list comments by content
CREATE PROCEDURE [dbo].[sp_InsertarComentario]
    @FK_IdPost INT,
    @Comentario VARCHAR(3000)
AS
BEGIN
    -- Comprobar que el post existe
    IF NOT EXISTS (SELECT 1 FROM TBL_Posts WHERE PK_IdPost = @FK_IdPost)
    BEGIN
        RAISERROR('El post con el ID especificado no existe.', 16, 1);
        RETURN;
    END
    
    -- Insertar el comentario en la tabla TBL_Comentarios
    INSERT INTO TBL_Comentarios (FK_IdPost, Comentario)
    VALUES (@FK_IdPost, @Comentario);

    -- Confirmar la transacción si se completó exitosamente
    IF @@ERROR = 0
    BEGIN
        PRINT 'Comentario agregado exitosamente.';
    END
    ELSE
    BEGIN
        RAISERROR('Error al agregar el comentario.', 16, 1);
    END
END;
GO









 
----------------------------------------------------------------------------------------------------
									/*INSERTAR DATOS*/
----------------------------------------------------------------------------------------------------



INSERT INTO TBL_Usuario (Nombre, Correo, Contra, Rol, Estado, Descripcion, Cant_post, strikes,FK_Usuario_Creacion, FK_Usuario_Modificacion, Fecha_Creacion, Fecha_Modificacion)
VALUES 
('Juan Perez', 'juan.perez@example.com', '1', 'Administrador', 1, 'Soy amable', 1, 0,'admin', 'admin', GETDATE(), GETDATE()),
('Maria Gomez', 'maria.gomez@example.com', '1', 'Usuario', 1, 'Soy amable', 1, 0,'admin', 'admin', GETDATE(), GETDATE()); 

-- Inserciones de datos para la tabla TBL_Posts
INSERT INTO TBL_Posts (FK_IdUsuario, Titulo, Descripcion)
VALUES 
(1, 'Post de Juan 1', 'Descripción del primer post de Juan'),
(1, 'Post de Juan 2', 'Descripción del segundo post de Juan'),
(2, 'Post de Maria 1', 'Descripción del primer post de Maria'),
(2, 'Post de Maria 2', 'Descripción del segundo post de Maria'),
(1, 'Post de Juan 1', 'It is a long established fact that a reader will be distracted by the readable content of a page when looking at its layout. The point of using Lorem Ipsum is that it has a more-or-less normal distribution of letters, as opposed to using Content here, content here, making it look like readable English. Many desktop publishing packages and web page editors now use Lorem Ipsum as their default model text, and a search for lorem ipsum will uncover many web sites still in their infancy. Various versions have evolved over the years, sometimes by accident, sometimes on purpose (injected humour and the like).');




