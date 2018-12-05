USE PERSONDATABASE

/*********************
Hello! 

Please use the test data provided in the file 'PersonDatabase' to answer the following
questions. Please also import the dbo.Contacts flat file to a table for use. 

All answers should be written in SQL. 

***********************



QUESTION 1

The table dbo.Risk contains calculated risk scores for the population in dbo.Person. Write a 
query or group of queries that return the patient name, and their most recent risk level(s). 
Any patients that dont have a risk level should also be included in the results. 

**********************/



SELECT p.PersonName, r.RiskLevel, r.RiskDateTime
FROM DBO.Person p
LEFT JOIN (
    SELECT PersonID, max(RiskDateTime) as MaxDate, RiskLevel, RiskDateTime
    from DBO.Risk 
    group by PersonID, RiskLevel, RiskDateTime
) r on p.PersonID = r.PersonID









/**********************

QUESTION 2


The table dbo.Person contains basic demographic information. The source system users 
input nicknames as strings inside parenthesis. Write a query or group of queries to 
return the full name and nickname of each person. The nickname should contain only letters 
or be blank if no nickname exists.

**********************/

/* I am making an assumption that 2 distinct fields are being requested in the output: fullname and nickname. And, Fullname DOES NOT contain nickname */

Select Replace(Replace(PersonName, Substring(PersonName,  Charindex('(',PersonName),Charindex(')',PersonName)-CharIndex('(',PersonName)),''),')','') As Fullname, Replace(Substring(PersonName,  Charindex('(',PersonName),Charindex(')',PersonName)-CharIndex('(',PersonName)),'(','') As 'Nickame' from Person






/**********************

QUESTION 3

Building on the query in question 1, write a query that returns only one row per 
patient for the most recent levels. Return a level for a patient so that for patients with 
multiple levels Gold > Silver > Bronze


**********************/

SELECT p.PersonName, r.RiskLevel, r.RiskDateTime
FROM DBO.Person p
LEFT JOIN (
    SELECT TOP 10
     PersonID, MAX(RiskDateTime) AS MaxDate, RiskLevel, RiskDateTime
    FROM DBO.Risk 
    GROUP BY PersonID, RiskLevel, RiskDateTime
    ORDER BY PersonId, CASE WHEN RiskLevel = 'Gold' THEN '1'
                            WHEN RiskLevel = 'Silver' THEN '2'
                            WHEN RiskLevel = 'Bronze' THEN '3'
                            ELSE RiskLevel 
                        END ASC
) r on p.PersonID = r.PersonID







/**********************

QUESTION 4

The following query returns patients older than 55 and their assigned risk level history. 

A. What changes could be made to this query to improve optimization? Rewrite the query with  
any improvements in the Answer A section below.

B. What changes would we need to make to run this query at any time to return patients over 55?
Rewrite the query with any required changes in Answer B section below. 

**********************/


	SELECT *
	FROM DBO.Person P
	INNER JOIN DBO.Risk R
		ON R.PersonID = P.PersonID

	WHERE P.PersonID IN 
		(
			SELECT personid
			FROM Person
			WHERE DATEOFBIRTH < '1/1/1961'
		)

	AND P.ISACTIVE = '1'



--------Answer A--------------------


	SELECT *
	FROM DBO.Person P
	INNER JOIN DBO.Risk R
		ON R.PersonID = P.PersonID
	WHERE P.DATEOFBIRTH < '1/1/1961'
			AND P.ISACTIVE = '1'







---------Answer B--------------------
DECLARE @currentDate DateTime;
DECLARE @currentYear Int;
DECLARE @QueryYear Int;
DECLARE @Age Int;

SET @Age=55;
SET @currentDate=getDate(); 
SET @currentYear=DATEPART(yyyy,@currentDate)
SET @QueryYear=@currentYear-@Age;

	SELECT *
	FROM DBO.Person P
	INNER JOIN DBO.Risk R
		ON R.PersonID = P.PersonID

	WHERE P.PersonID IN 
		(
			SELECT personid
			FROM Person
			WHERE DATEOFBIRTH < Concat('1/1/',@QueryYear)
		)

	AND P.ISACTIVE = '1'









/**********************

QUESTION 5

Create a patient matching stored procedure that accepts (first name, last name, dob and sex) as parameters and 
and calculates a match score from the Person table based on the parameters given. If the parameters do not match the existing 
data exactly, create a partial match check using the weights below to assign partial credit for each. Return PatientIDs and the
 calculated match score. Feel free to modify or create any objects necessary in PersonDatabase.  

FirstName 
	Full Credit = 1
	Partial Credit = .5

LastName 
	Full Credit = .8
	Partial Credit = .4

Dob 
	Full Credit = .75
	Partial Credit = .3

Sex 
	Full Credit = .6
	Partial Credit = .25


**********************/

ALTER TABLE Person Add FirstName VARCHAR(100);
ALTER TABLE Person Add LastName VARCHAR(100);
ALTER TABLE Person Add NickName VARCHAR(50);
ALTER TABLE Person Add FullName VARCHAR(255);



SELECT PersonName, PersonID, 
       trim(Replace(Replace(PersonName, Substring(PersonName,  Charindex('(',PersonName),Charindex(')',PersonName)-CharIndex('(',PersonName)),''),')','')) As FullName, 
	   Replace(Substring(PersonName,  Charindex('(',PersonName),Charindex(')',PersonName)-CharIndex('(',PersonName)),'(','') As NickName,
	   FirstName, LastName
	   INTO PersonCOPY
FROM Person;
Go

Update PersonCOPY
SET FirstName = SUBSTRING(FUllName, 0,CHARINDEX(' ',FullName) ),
    LastName = SUBSTRING(Fullname, CHARINDEX(' ',FullName), LEN(FullName)-CHARINDEX(' ',FullName)+1 )
    GO
	
	
UPDATE Person 
SET    Person.FirstName = PersonCopy.FirstName,
	   Person.LastName = PersonCopy.LastName
FROM   PersonCOPY
       INNER JOIN Person
       ON Person.PersonId = personCOPY.PersonId;
go




CREATE PROCEDURE PatientMatching @FirstName nvarchar(100), @LastName nvarchar(100), @DateofBirth DATETIME, @Sex nvarchar(10)
AS

	DECLARE @FirstNameFullCredit float = 1
	DECLARE @FirstNamePartialCredit float = 0.5
	DECLARE @FirstNameNoCredit float = 0	
	DECLARE @LastNameFullCredit float = 0.8
	DECLARE @LastNamePartialCredit float = 0.4
	DECLARE @LastNameNoCredit float = 0	
	DECLARE @DOBFullCredit float = 0.75
	DECLARE @DOBPartialCredit float = 0.3
	DECLARE @DOBNoCredit float = 0		
	DECLARE @SexFullCredit float = 0.6
	DECLARE @SexPartialCredit float = 0.25	
	DECLARE @SexNoCredit float = 0	
	DECLARE @MatchScore float = 0;

Select personID As PatientID, 
	FirstName, LastName, DateofBirth, Sex
	, (CASE
			WHEN Trim(FirstName) = @FirstName THEN @FirstNameFullCredit
			WHEN Difference(trim(FirstName), @FirstName)=0 THEN @FirstNameNoCredit
			ELSE @FirstNamePartialCredit
		END) + 
		(CASE
			WHEN trim(LastName) = @LastName THEN @LastNameFullCredit
			WHEN Difference(trim(LastName), @LastName)=0 THEN @LastNameNoCredit
			ELSE @LastNamePartialCredit
		END) +
	   (CASE
			WHEN DateofBirth = @DateofBirth THEN @DOBFullCredit
			WHEN Difference(DateofBirth, @DateofBirth)=0 THEN @DOBNoCredit
			ELSE @DOBPartialCredit
		END) +	
	  (CASE
			WHEN Sex = @Sex THEN @SexFullCredit
			WHEN Difference(Sex, @Sex)=0 THEN @SexNoCredit
			ELSE @SexPartialCredit
		END) As MatchScore
	
FROM Person
ORDER BY MatchScore DESC

GO;

Exec PatientMatching 'Azra', 'Hales', '1997-07-24', 'Male'
Go;

/**********************

QUESTION 6

A. Looking at the script 'PersonDatabase', what change(s) to the tables could be made to improve the database structure?  

B. What method(s) could we use to standardize the data allowed in dbo.Person (Sex) to only allow 'Male' or 'Female'?

C. Assuming these tables will grow very large, what other database tools/objects could we use to ensure they remain
efficient when queried?


**********************/

A 

ALTER TABLE Person ALTER COLUMN PersonID INTEGER NOT NULL;
GO

ALTER TABLE DBO.Person   
ADD CONSTRAINT PK_Person_PersonID PRIMARY KEY CLUSTERED (PersonID);  
GO  

ALTER TABLE DBO.Risk  
ADD CONSTRAINT FK_Risk_PersonID FOREIGN KEY (PersonID)
	REFERENCES DBO.Person (PersonID)
    ON UPDATE CASCADE  	
;GO 

ALTER TABLE DBO.Contracts  
CONSTRAINT FK_Contracts_PersonKey FOREIGN KEY (PersonKey)     
    REFERENCES Sales.SalesReason (SalesReasonID)        
    ON UPDATE CASCADE    
;GO 
 

B 

ALTER TABLE dbo.Person
	    WITH NOCHECK ADD CONSTRAINT CK_Person_Sex
	    CHECK (Sex in ('Male','Female'));

C

CREATE UNIQUE INDEX i1_Person ON Person (PersonId ASC, PersonName ASC, DateofBirth DESC); 
GO
CREATE INDEX i1_Risk ON Risk (PersonId ASC); 
GO
CREATE INDEX i1_Contracts ON Risk (PersonKey ASC); 
GO





/**********************

QUESTION 7

Write a query to return risk data for all patients, all contracts 
and a moving average of risk for that patient and contract in dbo.Risk. 

**********************/


SELECT p.PersonID, c.ContractStartDate, r.RiskScore 
      ,AVG(r.RiskScore) OVER(PARTITION BY p.PersonId) AS 'Moving Average' 
  
FROM Person p 
INNER JOIN Risk r 
	On r.PersonId=p.PersonId
LEFT JOIN CONTRACTS c 
	On p.PersonId=c.PersonKey  
GO  


/**********************

QUESTION 8

Write script to load the dbo.Dates table with all applicable data elements for dates 
between 1/1/2010 and 50 days past the current date.


**********************/

SET NOCOUNT ON;
GO

DECLARE @MyCounter int;
DECLARE @StartDate DateTime;
DECLARE @CurrentDate DateTime;
DECLARE @DateIndex DateTime;

SET @StartDate = '1/1/2010';
SET @CurrentDate = getDate();
SET @DateIndex = @StartDate;

WHILE (@DateIndex <= @CurrentDate)
BEGIN;

   INSERT INTO Dates (DateValue, DateDayOfMonth, DateDayOfYear, DateQuarter, DateWeekdayName, DateMonthName, DateYearMonth ) VALUES 

       (@DateIndex, 
	    DAY(@DateIndex), 
		DATEPART(dayofyear,@DateIndex), 
		DATEPART(quarter,@DateIndex), 
		DATENAME(dw,DATEPART(dw,@DateIndex)),
		MONTH(@DateIndex),
		REPLACE(CONCAT(CAST(DATENAME(yyyy,@DateIndex) as char),CAST(DATEPART(mm,@DateIndex) as char)),' ','') );

   SET @DateIndex = @DateIndex + 1;
END;
GO
SET NOCOUNT OFF;
GO



/**********************

QUESTION 9

Please import the data from the flat file dbo.Contracts.txt to a table to complete this question. 

Using the data in dbo.Contracts, create a query that returns 

(PersonID, AttributionStartDate, AttributionEndDate) 

merging contiguous date ranges into one row and returning a new row when a break in time exists. 
The date at the beginning of the rage can be the first day of that month, the day of the end of the range can
be the last day of that month. Use the dbo.Dates table if helpful.

**********************/


with rcte as (
   select c1.PersonKey, c1.contractstartdate, c1.contractfinishdate
     from Contracts c1
left join Contracts c2 on c1.PersonKey=c2.personKey and c1.contractstartdate-1=c2.contractfinishdate
    where c2.PersonKey is null
	
    union all
	
   select c1.PersonKey, c1.contractstartdate, c1.contractfinishdate
     from rcte c1
     join Contracts  c2 on c1.personKey=c2.personkey and c2.contractstartdate-1=c1.contractfinishdate
)
   select personkey as PersonId,
          contractstartdate as attributionStartDate,
          nullif(max(isnull(contractfinishdate,'55551231')),'55551231') contractfinishdate
     from rcte 
 group by personkey, contractstartdate
 order by personkey 
 option (maxrecursion 0)
 



