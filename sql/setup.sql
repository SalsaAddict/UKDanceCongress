--IF @@SERVERNAME = N'TYNE' USE [PAH]
--IF @@SERVERNAME = N'ALLADIN' USE [UKDC]
--USE [UKDCAUI]
GO

IF OBJECT_ID(N'OrderPerson', N'U') IS NOT NULL DROP TABLE [OrderPerson]
IF OBJECT_ID(N'OrderPackage', N'U') IS NOT NULL DROP TABLE [OrderPackage]
IF OBJECT_ID(N'Order', N'U') IS NOT NULL DROP TABLE [Order]
IF OBJECT_ID(N'WebApiProducts', N'P') IS NOT NULL DROP PROCEDURE [WebApiProducts]
IF OBJECT_ID(N'Product', N'U') IS NOT NULL DROP TABLE [Product]
IF OBJECT_ID(N'WebApiLogin', N'P') IS NOT NULL DROP PROCEDURE [WebApiLogin]
IF OBJECT_ID(N'User', N'U') IS NOT NULL DROP TABLE [User]
IF OBJECT_ID(N'WebApiAffiliate', N'P') IS NOT NULL DROP PROCEDURE [WebApiAffiliate]
IF OBJECT_ID(N'Affiliate', N'U') IS NOT NULL DROP TABLE [Affiliate]
IF OBJECT_ID(N'WebApiGenders', N'P') IS NOT NULL DROP PROCEDURE [WebApiGenders]
IF OBJECT_ID(N'Gender', N'U') IS NOT NULL DROP TABLE [Gender]
GO

CREATE TABLE [Gender] (
  [Code] NCHAR(1) NOT NULL,
		[Description] NVARCHAR(6) NOT NULL,
		CONSTRAINT [PK_Gender] PRIMARY KEY CLUSTERED ([Code]),
		CONSTRAINT [UQ_Gender_Description] UNIQUE ([Description])
	)
GO

INSERT INTO [Gender] ([Code], [Description])
OUTPUT [inserted].*
VALUES
 (N'M', N'Male'),
	(N'F', N'Female')
GO

CREATE PROCEDURE [WebApiGenders]
AS
BEGIN
 SET NOCOUNT ON
	SET ANSI_WARNINGS OFF
	SET TRANSACTION ISOLATION LEVEL READ UNCOMMITTED
	SELECT [Code], [Description]
	FROM [Gender]
	ORDER BY 1
	FOR XML PATH (N'Genders'), ROOT (N'Root')
	RETURN
END
GO

CREATE TABLE [Affiliate] (
  [Code] NVARCHAR(25) NOT NULL,
		[Name] NVARCHAR(255) NOT NULL,
		[Active] BIT NOT NULL CONSTRAINT [DF_Affiliate_Active] DEFAULT (1),
		CONSTRAINT [PK_Affiliate] PRIMARY KEY CLUSTERED ([Code])
 )
GO

INSERT INTO [Affiliate] ([Code], [Name])
OUTPUT [inserted].*
VALUES
 (N'SalsaAddict', N'SalsaAddict'),
	(N'Latin8', N'Latin 8 Productions'),
	(N'Bubblegum', N'Bubblegum Promotions'),
	(N'Tropicana', N'Tropicana Productions'),
	(N'SalsaNW', N'Salsa North-West'),
	(N'KizombaCentral', N'Kizomba Central'),
	(N'DancingFever', N'Dancing Fever')
GO

CREATE PROCEDURE [WebApiAffiliate](@Code NVARCHAR(25))
AS
BEGIN
 SET NOCOUNT ON
	SET ANSI_WARNINGS ON
	SET TRANSACTION ISOLATION LEVEL READ UNCOMMITTED
	DECLARE @Valid BIT
	SELECT *
	FROM [Affiliate]
	WHERE [Code] = @Code
	 AND [Active] = 1
	FOR XML PATH (N'Affiliate'), ROOT (N'Root')
	RETURN
END
GO

CREATE TABLE [User] (
  [ID] BIGINT NOT NULL,
		[Forename] NVARCHAR(127) NOT NULL,
		[Surname] NVARCHAR(127) NOT NULL,
		[Gender] NCHAR(1) NULL,
		[IsOrganiser] BIT NOT NULL CONSTRAINT [DF_User_IsOrganiser] DEFAULT (0),
		[FirstLogin] DATETIME NOT NULL CONSTRAINT [DF_User_FirstLogin] DEFAULT (GETUTCDATE()),
		[LastLogin] DATETIME NOT NULL CONSTRAINT [DF_User_LastLogin] DEFAULT (GETUTCDATE()),
		[Affiliate] NVARCHAR(25) NULL,
		CONSTRAINT [PK_User] PRIMARY KEY CLUSTERED ([ID]),
		CONSTRAINT [FK_User_Gender] FOREIGN KEY ([Gender]) REFERENCES [Gender] ([Code]),
		CONSTRAINT [FK_User_Affiliate] FOREIGN KEY ([Affiliate]) REFERENCES [Affiliate] ([Code]),
		CONSTRAINT [CK_User_Affiliate] CHECK ([IsOrganiser] = 0 OR [Affiliate] IS NOT NULL),
		CONSTRAINT [CK_User_LastLogin] CHECK ([LastLogin] >= [FirstLogin])
	)
GO

INSERT INTO [User] ([ID], [Forename], [Surname], [Gender], [IsOrganiser], [Affiliate])
OUTPUT [inserted].*
VALUES
 (706460439, N'Pierre', N'Henry', N'M', 1, N'SalsaAddict'),
	(832380205, N'Zoe', N'Henry', N'F', 1, N'SalsaAddict'),
	(521765455, N'Joseph', N'Davids', N'M', 1, N'Latin8'),
	(663780873, N'Darryl', N'Peterson', N'M', 1, N'Bubblegum'),
	(644651886, N'Ramiro', N'Zapata', N'M', 1, N'Tropicana'),
	(772580133, N'Phil', N'Kaila', N'M', 1, N'SalsaNW'),
	(1154326255, N'Sandra', N'Kinder', N'F', 1, N'SalsaNW'),
	(1268800462, N'Christian', N'Jean-Francois', N'M', 1, N'KizombaCentral'),
	(809355576, N'Nadia', N'Giacomini Yammine', N'F', 1, N'KizombaCentral'),
	(560962161, N'Carl', N'Davies', N'M', 0, N'DancingFever'),
	(1395080551, N'Alexandra', N'Davies', N'F', 0, N'DancingFever')
GO

CREATE PROCEDURE [WebApiLogin](@XML XML)
AS
BEGIN
 SET NOCOUNT ON
	SET ANSI_WARNINGS ON

	DECLARE
	 @ID BIGINT,
		@Forename NVARCHAR(127),
		@Surname NVARCHAR(127),
		@Gender NCHAR(1)

	SELECT
		@ID = [User].value(N'id[1]', N'BIGINT'),
		@Forename = [User].value(N'first_name[1]', N'NVARCHAR(127)'),
		@Surname = [User].value(N'last_name[1]', N'NVARCHAR(127)'),
		@Gender = UPPER(LEFT([User].value(N'gender[1]', N'NVARCHAR(6)'), 1))
	FROM @XML.nodes(N'/Root[1]') u ([User])

	IF EXISTS (SELECT 1 FROM [User] WHERE [ID] = @ID)
	 UPDATE [User]
		SET
		 [Forename] = @Forename,
			[Surname] = @Surname,
			[Gender] = @Gender,
			[LastLogin] = GETUTCDATE()
		WHERE [ID] = @ID
	ELSE
	 INSERT INTO [User] ([ID], [Forename], [Surname], [Gender])
		VALUES (@ID, @Forename, @Surname, @Gender)

	;WITH XMLNAMESPACES (N'http://james.newtonking.com/projects/json' as json)
	SELECT
	 ( -- User
		  SELECT
				 [@json:Array] = N'false',
					[ID],
					[Forename],
					[Surname],
					[Gender],
					[IsOrganiser],
					[FirstLogin],
					[LastLogin],
					[Affiliate]
				FOR XML PATH (N'User'), TYPE
			),
		( -- Affiliate
		  SELECT [Code], [Name]
				FROM [Affiliate]
				WHERE [Code] = u.[Affiliate]
				 AND [Active] = 1
				FOR XML PATH (N'Affiliate'), TYPE
		 )
	FROM [User] u
	WHERE [ID] = @ID
	FOR XML PATH (N''), ROOT (N'Root')

	RETURN
END
GO

CREATE TABLE [Product] (
  [ID] INT NOT NULL IDENTITY (1, 1),
		[Type] NCHAR(1) NOT NULL,
		[Name] NVARCHAR(50) NOT NULL,
		[Description] NVARCHAR(255) NOT NULL,
		[InfoUrl] NVARCHAR(255) NULL,
		[Min] TINYINT NOT NULL CONSTRAINT [DF_Product_Min] DEFAULT (1),
		[Max] TINYINT NOT NULL CONSTRAINT [DF_Product_Max] DEFAULT (1),
		[CurrentPrice] MONEY NOT NULL,
  [SortOrder] INT NOT NULL,
		[Active] BIT NOT NULL CONSTRAINT [DF_Product_Active] DEFAULT (1),
		[Stock] INT NOT NULL CONSTRAINT [DF_Product_Stock] DEFAULT (-1),
		CONSTRAINT [PK_Product] PRIMARY KEY NONCLUSTERED ([ID]),
		CONSTRAINT [UQ_Product_Type] UNIQUE ([ID], [Type]),
		CONSTRAINT [UQ_Product_Name] UNIQUE ([Type], [Name]),
		CONSTRAINT [UQ_Product_SortOrder] UNIQUE CLUSTERED ([Type], [SortOrder]),
		CONSTRAINT [CK_Product_ID] CHECK ([ID] >= 1),
		CONSTRAINT [CK_Product_Type] CHECK ([Type] IN (N'K', 'P', 'D')),
		CONSTRAINT [CK_Product_Min] CHECK ([Min] >= 1),
		CONSTRAINT [CK_Product_Max] CHECK ([Max] >= [Min]),
		CONSTRAINT [CK_Product_Package] CHECK ([Type] = N'K' OR [Max] = 1),
		CONSTRAINT [CK_Product_CurrentPrice_Min] CHECK ([CurrentPrice] >= 0),
		CONSTRAINT [CK_Product_SortOrder] CHECK ([SortOrder] >= 1),
		CONSTRAINT [CK_Product_Stock] CHECK ([Stock] >= -1)
	)
GO

INSERT INTO [Product]
OUTPUT [inserted].*
VALUES
 (N'P', N'Full Pass', N'Access to all workshops, competitions, shows and parties', NULL, 1, 1, 85, 1, 1, -1),
	(N'P', N'Party Pass', N'Access to all competitions, shows and parties', NULL, 1, 1, 60, 2, 1, -1),
	(N'K', N'Double Bedroom', N'Double bedroom in a shared 2 or 3 bedroom unit', N'http://www.butlins.com/where-to-stay-dine-and-play/where-to-stay/bognor-regis/silver-room.aspx', 2, 2, 180, 1, 1, -1),
	(N'K', N'Twin Bedroom', N'Twin bedroom in a shared 2 or 3 bedroom unit', N'http://www.butlins.com/where-to-stay-dine-and-play/where-to-stay/bognor-regis/silver-room.aspx', 2, 2, 180, 2, 1, -1),
	(N'K', N'Single Bedroom', N'Single bedroom in a shared 2 or 3 bedroom unit', N'http://www.butlins.com/where-to-stay-dine-and-play/where-to-stay/bognor-regis/silver-room.aspx', 1, 1, 150, 3, 1, -1),
	(N'K', N'2 Bedroom Silver Apartment', N'1 double bedroom, 1 twin bedroom, separate lounge and kitchen', N'http://www.butlins.com/where-to-stay-dine-and-play/where-to-stay/bognor-regis/silver-apartment.aspx', 2, 4, 320, 4, 1, -1),
	(N'K', N'3 Bedroom Silver Apartment', N'1 double bedroom, 2 twin bedrooms, separate lounge and kitchen', N'http://www.butlins.com/where-to-stay-dine-and-play/where-to-stay/bognor-regis/silver-apartment.aspx', 3, 6, 480, 5, 1, -1),
	(N'D', N'Half Board', N'Breakfast and four-course dinner every day.', NULL, 1, 1, 70, 1, 1, -1)
GO

CREATE PROCEDURE [WebApiProducts](@Type NCHAR(1))
AS
BEGIN
 SET NOCOUNT ON
	SET ANSI_WARNINGS ON
	SET TRANSACTION ISOLATION LEVEL READ UNCOMMITTED
	;WITH XMLNAMESPACES (N'http://james.newtonking.com/projects/json' as json)
	SELECT
	 [@json:Array] = 'true',
	 [ID],
		[Name],
		[Description],
		[InfoUrl],
		[Min],
		[Max],
		[CurrentPrice],
		[Stock]
	FROM [Product]
	WHERE [Type] = @Type
	 AND [Active] = 1
		AND [Stock] <> 0
	ORDER BY [SortOrder]
	FOR XML PATH (N'Products'), ROOT (N'Root')
	RETURN
END
GO

CREATE TABLE [Order] (
  [ID] INT NOT NULL IDENTITY (2001, 1),
		[Forename] NVARCHAR(127) NOT NULL,
		[Surname] NVARCHAR(127) NOT NULL,
		[Email] NVARCHAR(255) NOT NULL,
		[Phone] NVARCHAR(25) NOT NULL,
		[CreatedWhenUTC] DATETIME NOT NULL CONSTRAINT [DF_Order_CreatedWhenUTC] DEFAULT (GETUTCDATE()),
		CONSTRAINT [PK_Order] PRIMARY KEY CLUSTERED ([ID])
	)
GO

CREATE TABLE [OrderPackage] (
  [OrderID] INT NOT NULL,
		[ID] INT NOT NULL IDENTITY (1, 1),
		[Package] AS CONVERT(NCHAR(1), N'K') PERSISTED,
		[PackageID] INT NOT NULL,
		[Price] MONEY NOT NULL,
		CONSTRAINT [PK_OrderPackage] PRIMARY KEY CLUSTERED ([OrderID], [ID]),
		CONSTRAINT [UQ_OrderPackage_ID] UNIQUE ([ID]),
		CONSTRAINT [FK_OrderPackage_Order] FOREIGN KEY ([OrderID]) REFERENCES [Order] ([ID]) ON DELETE CASCADE,
		CONSTRAINT [FK_OrderPackage_Product] FOREIGN KEY ([PackageID], [Package]) REFERENCES [Product] ([ID], [Type]),
		CONSTRAINT [CK_OrderPackage_Price_Min] CHECK ([Price] >= 0)
	)
GO

CREATE TABLE [OrderPerson] (
  [OrderID] INT NOT NULL,
		[OrderPackageID] INT NULL,
		[ID] INT NOT NULL IDENTITY (1, 1),
		[Forename] NVARCHAR(127) NOT NULL,
		[Surname] NVARCHAR(127) NOT NULL,
		[FullName] AS [Forename] + N' ' + [Surname],
		[Gender] NCHAR(1) NOT NULL,
		[Pass] AS CONVERT(NCHAR(1), N'P') PERSISTED,
		[PassID] INT NOT NULL,
		[PassPrice] MONEY NOT NULL,
		[Dining] AS CONVERT(NCHAR(1), N'D') PERSISTED,
		[DiningID] INT NULL,
		[DiningPrice] MONEY NOT NULL,
		CONSTRAINT [PK_OrderPerson] PRIMARY KEY NONCLUSTERED ([ID]),
		CONSTRAINT [UQ_OrderPerson_ID] UNIQUE CLUSTERED ([OrderID], [OrderPackageID], [ID]),
		CONSTRAINT [CK_OrderPerson_Order] FOREIGN KEY ([OrderID]) REFERENCES [Order] ([ID]) ON DELETE CASCADE,
		CONSTRAINT [CK_OrderPerson_OrderPackage] FOREIGN KEY ([OrderID], [OrderPackageID]) REFERENCES [OrderPackage] ([OrderID], [ID]),
		CONSTRAINT [CK_OrderPerson_Gender] CHECK ([Gender] IN (N'M', N'F')),
		CONSTRAINT [CK_OrderPerson_PassPrice] CHECK ([PassPrice] >= 0),
		CONSTRAINT [CK_OrderPerson_DiningID] CHECK ([OrderPackageID] IS NOT NULL OR [DiningID] IS NULL),
		CONSTRAINT [CK_OrderPerson_DiningPrice] CHECK ([DiningID] IS NOT NULL OR [Dining] = 0),
		CONSTRAINT [CK_OrderPerson_DiningPrice_Min] CHECK ([DiningPrice] >= 0)
	)
GO

EXEC [WebApiLogin] N'<Root><id>706460439</id><first_name>Pierre</first_name><last_name>Henry</last_name><gender>Male</gender></Root>'
GO