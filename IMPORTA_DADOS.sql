USE DbDiscursos
GO


DROP TABLE DISCURSOS_LIMPO
GO

CREATE TABLE DISCURSOS
(
	DEPUTADO VARCHAR(100),
	PARTIDO VARCHAR(100),
	ESTADO VARCHAR(50),
	VOTO VARCHAR(100),
	GENERO VARCHAR(1),
	FALA VARCHAR(MAX)
)
GO

-- NOTA: CONVERTER O ARQUIVO TEXTO PARA UNICODE UTILIZANDO O NOTEPAD2
BULK INSERT DbDiscursos.dbo.DISCURSOS
FROM 'E:\Meus Documentos\Blog\BETA_AnaliseDiscursos\CSV_ORIGINAL_DISCURSOS_UNICODE.CSV'
WITH
  (
    FIELDTERMINATOR = '\t',
    ROWTERMINATOR = '\n'
 );

SELECT * FROM DbDiscursos.dbo.DISCURSOS

SELECT TOP 10 LEN(FALA), *
FROM DbDiscursos.dbo.DISCURSOS
ORDER BY 1 DESC

/*


*/


------------------------------------------------------------------------
------------------------------------------------------------------------
-- OK 0) LIMPEZA DE DADOS


-- a) numerando as linhas
-----------------------------

DELETE DISCURSOS
WHERE VOTO = 'Ausente'

ALTER TABLE DISCURSOS
ADD ID INT IDENTITY(1,1)

SELECT VOTO, COUNT(*)
FROM DbDiscursos.dbo.DISCURSOS
GROUP BY VOTO


SELECT * 
INTO DISCURSOS_LIMPO
FROM DISCURSOS


-- b) REMOVENDO ALGUNS CARACTERES ESPECIALS: . , ! ; — - + ' " 
-----------------------------

UPDATE DISCURSOS_LIMPO
SET FALA = REPLACE(FALA,'.','')

UPDATE DISCURSOS_LIMPO
SET FALA = REPLACE(FALA,',','')

UPDATE DISCURSOS_LIMPO
SET FALA = REPLACE(FALA,'!','')

UPDATE DISCURSOS_LIMPO
SET FALA = REPLACE(FALA,';','')

UPDATE DISCURSOS_LIMPO
SET FALA = REPLACE(FALA,'—','')

UPDATE DISCURSOS_LIMPO
SET FALA = REPLACE(FALA,'-','')

UPDATE DISCURSOS_LIMPO
SET FALA = REPLACE(FALA,'+','')

UPDATE DISCURSOS_LIMPO
SET FALA = REPLACE(FALA,'?','')
 
SELECT *
FROM DISCURSOS_LIMPO
WHERE FALA LIKE '%.%'
   OR FALA LIKE '%,%'
   OR FALA LIKE '%!%'
   OR FALA LIKE '%;%'
   OR FALA LIKE '%—%'
   OR FALA LIKE '%-%'
   OR FALA LIKE '%+%'
   OR FALA LIKE '%?%'

-- tirando os char(9) das duas tabelas!
UPDATE DISCURSOS_LIMPO
SET FALA = REPLACE(FALA, CHAR(9), '')
WHERE CHARINDEX(CHAR(9),FALA ) > 0 

UPDATE DISCURSOS
SET FALA = REPLACE(FALA, CHAR(9), '')
WHERE CHARINDEX(CHAR(9),FALA ) > 0 

-- tirando os " E ' das duas tabelas!

UPDATE DISCURSOS_LIMPO
SET FALA = REPLACE(FALA,'''','')

UPDATE DISCURSOS_LIMPO
SET FALA = REPLACE(FALA,'"','')

UPDATE DISCURSOS
SET FALA = REPLACE(FALA,'''','')

UPDATE DISCURSOS
SET FALA = REPLACE(FALA,'"','')

-- TIRANDO OS MÚLTIPLOS ESPAÇOS

SELECT * 
FROM DISCURSOS
WHERE CHARINDEX('  ',FALA ) > 0 

UPDATE DISCURSOS
SET FALA = REPLACE(FALA,'  ',' ')

UPDATE DISCURSOS_LIMPO
SET FALA = REPLACE(FALA,'  ',' ')


SELECT * 
FROM DISCURSOS_LIMPO

-- c) TIRANDO AS STOP WORDS:
-----------------------------
/*
'a,'ai','com','como','da','de','do','dos','e','em','esse','esta','isso','ja','mais','mas','minha','o','os','ou','para','por','pouca','pouco','pra','que','um','uma','ha','pois','vou','ta' 
*/

-- FUNÇÃO DE SPLT:

/****** Object:  UserDefinedFunction [dbo].[iter_charlist_to_table]    Script Date: 04/26/2016 10:33:44 ******/
SET ANSI_NULLS ON
GO

SET QUOTED_IDENTIFIER ON
GO


CREATE FUNCTION [dbo].[iter_charlist_to_table]
                    (@list      ntext,
                     @delimiter nchar(1) = N',')
         RETURNS @tbl TABLE (listpos int IDENTITY(1, 1) NOT NULL,
                             str     varchar(4000),
                             nstr    nvarchar(2000)) AS

   BEGIN
      DECLARE @pos      int,
              @textpos  int,
              @chunklen smallint,
              @tmpstr   nvarchar(4000),
              @leftover nvarchar(4000),
              @tmpval   nvarchar(4000)

      SET @textpos = 1
      SET @leftover = ''
      WHILE @textpos <= datalength(@list) / 2
      BEGIN
         SET @chunklen = 4000 - datalength(@leftover) / 2
         SET @tmpstr = @leftover + substring(@list, @textpos, @chunklen)
         SET @textpos = @textpos + @chunklen

         SET @pos = charindex(@delimiter, @tmpstr)

         WHILE @pos > 0
         BEGIN
            SET @tmpval = ltrim(rtrim(left(@tmpstr, @pos - 1)))
            INSERT @tbl (str, nstr) VALUES(@tmpval, @tmpval)
            SET @tmpstr = substring(@tmpstr, @pos + 1, len(@tmpstr))
            SET @pos = charindex(@delimiter, @tmpstr)
         END

         SET @leftover = @tmpstr
      END

      INSERT @tbl(str, nstr) VALUES (ltrim(rtrim(@leftover)), ltrim(rtrim(@leftover)))
   RETURN
   END

GO




-- SELECT * FROM dbo.Split('+,-,*,/,%,(,)', ',');

-- SELECT * FROM dbo.iter_charlist_to_table('a,as,ai,com,como,da,de,do,dos,e,em,esse,esta,isso,ja,mais,mas,minha,o,O,à,é,os,ou,para,por,Por,pouca,pouco,pra,que,um,uma,ha,pois,vou,ta,com', ',')

/*

DECLARE @NEWSTRING VARCHAR(100) 
SET @NEWSTRING = 'Roraima verás que o filho teu não foge à luta O povo brasileiro merece respeito Por um Brasil com justiça igualdade social e sem corrupção por uma Roraima desacorrentada para que possamos exercer o direito constitucional de ir e vir e por todas as famílias roraimenses eu voto sim Sr Presidente' ;
SELECT @NEWSTRING = REPLACE(@NEWSTRING, items, '') FROM dbo.Split(' a , ai , com , como , da , de , do , dos , e , em , esse , esta , isso , ja , mais , mas , minha , o , os , ou , para , por , pouca , pouco , pra , que , um , uma , ha , pois , vou , ta ', ',')
PRINT @NEWSTRING
*/

-- NOTA: PRIMEIRO FAZER O SLIP DO TEXTO DO DISCURSO + COLOCAR TABELA
-- SE SEGUIDA REMOVER AS STOP WORDS UMA A UMA

SELECT TOP 2 ID, FALA 
FROM DISCURSOS_LIMPO as a , ( SELECT * FROM dbo.iter_charlist_to_table(a.FALA,' ') ) as b


SELECT TOP 2 ID, FALA , ( SELECT TOP 1 * FROM dbo.iter_charlist_to_table(a.FALA,' ') ) as b
FROM DISCURSOS_LIMPO as a 

SELECT * FROM dbo.iter_charlist_to_table('Roraima verás que o filho teu não foge à luta O povo brasileiro merece respeito Por um Brasil com justiça igualdade social e sem corrupção por uma Roraima desacorrentada para que possamos exercer o direito constitucional de ir e vir e por todas as famílias roraimenses eu voto sim Sr Presidente',' ')


SELECT * 
FROM DISCURSOS_LIMPO as a , 

SELECT *
FROM  (SELECT * FROM dbo.iter_charlist_to_table((SELECT TOP 1 FALA FROM DISCURSOS_LIMPO WHERE ID = 1),' ') ) AS A


DROP TABLE TB_DISCURSOS_PALAVRAS

CREATE TABLE TB_DISCURSOS_PALAVRAS
(
	ID INT,
	PALAVRA VARCHAR(8000),
	ORDEM_PALAVRA INT
)

truncate table TB_DISCURSOS_PALAVRAS

DECLARE @X INT

SET @X = 1

WHILE @X <= (SELECT MAX(ID) FROM DISCURSOS_LIMPO)
BEGIN
	
	INSERT TB_DISCURSOS_PALAVRAS
	SELECT @X , A.str, A.listpos
	FROM (SELECT * FROM dbo.iter_charlist_to_table((SELECT FALA FROM DISCURSOS_LIMPO WHERE ID = @X),' ') )  AS A 
	
	SET @X = @X + 1
END


SELECT  * 
FROM TB_DISCURSOS_PALAVRAS

-- REMOVENDO ALGUNS TEMOS QUE NÃO FAZEM SENTIDO

DELETE TB_DISCURSOS_PALAVRAS
WHERE UPPER(ltrim(rtrim(PALAVRA))) IN ('','()','(MANIFESTAÇÃO','(PALMAS)','(PALMAS)','(PALMAS)','(PAUSA)','1988:','50%')

-- AGORA REMOVENDO AS STOP WORDS

DELETE TB_DISCURSOS_PALAVRAS
WHERE UPPER(ltrim(rtrim(PALAVRA))) IN ( SELECT UPPER(STR) FROM dbo.iter_charlist_to_table('a,as,às,ao,ai,com,como,da,de,do,dos,e,em,esse,esta,isso,ja,mais,mas,minha,o,O,à,é,os,ou,para,por,Por,Pelo,Pelos,pelo,pela,pouca,pouco,pra,que,um,uma,ha,pois,vou,ta,com,na,no,nas,nos,há,Lá,se,já,foi,sem,com,dar,me,só,meu,vai,tem,tal,meus,aos,sou,ser,seus,está,são,sou,porque,ser,deste,pelas,nem,seu,seus,tão,muito,muita,muitos,muitas,vez,cada,dessa,desse,dessas,destes,deste,estar,têm,quer,quero,querer,faz,era,aí,aquela,aquilo,vi,tinha,qual,eu,sr,aqui,nosso,nós', ',') )

SELECT  *, UPPER(PALAVRA)
FROM TB_DISCURSOS_PALAVRAS
order by PALAVRA asc

-- REMOVENDO OS NUMEROS
/*
SELECT PALAVRA, ISNUMERIC(PALAVRA)
FROM TB_DISCURSOS_PALAVRAS
WHERE ISNUMERIC(PALAVRA) = 1
*/

DELETE TB_DISCURSOS_PALAVRAS
FROM TB_DISCURSOS_PALAVRAS
WHERE ISNUMERIC(PALAVRA) = 1

SELECT  UPPER(PALAVRA), COUNT(UPPER(PALAVRA))
FROM TB_DISCURSOS_PALAVRAS
GROUP BY UPPER(PALAVRA)
order by COUNT(UPPER(PALAVRA)) DESC

-- total: 16036	unicas: 3443

select COUNT(palavra), COUNT(distinct palavra)
FROM TB_DISCURSOS_PALAVRAS

-- TODO: PENSAR EM COMO GERAR COM CÓDIGO COM TRÊS CARACTERES
-- '___' ONDE CADA POSIÇÃO PODE SER DE 'A' A 'Z'. TOTAL DE POSSIBILIDADES: 13.824
-- TODO: ADAPTAR ALGORITMOS LCS PARA LIDAR COM SEQUENCIAS ONDE CADA ITEM POSSUI TRÊS CARACTERES

-- d) REMONTANDO A FRASE SEM AS STOP WORDS


-- DROP TABLE   DISCURSO_RECOMPOSTO

Select distinct ST2.id, 
    substring(
        (
            Select ' '+ST1.palavra  AS [text()]
            From dbo.TB_DISCURSOS_PALAVRAS ST1
            Where ST1.id= ST2.id
            ORDER BY ST1.id
            For XML PATH ('')
        ), 2, 1000) [FALA]
INTO DISCURSO_RECOMPOSTO
From dbo.TB_DISCURSOS_PALAVRAS ST2

SELECT * FROM DISCURSO_RECOMPOSTO
  
------------------------------------------------------------------------
------------------------------------------------------------------------
-- OK 1) ANÁLISE LCS  - SEM BONS RESULTADOS COM CARACTERES INDIVIDUAIS :(
---   TALVEZ TENTAR CRIAR CÓDIGO DE TRÊS CARACTERES PARA CADA PALAVRA
---   E MUDAR O ALGORITMO LCS. PEGAR IMPLEMENTAÇÃO EM PYTHON DE:
-- https://repl.it/RU0/1
-- SEM RESULTADOS MUITO BONS, POIS FORAM UTILIZADAS MUITAS PALAVRAS
-- EM ORDENS DIFERENTES


-- SEQUÊNCIA MAIS COMUM: 'vot'
SELECT TOP 10 FALA
, 'x[' + CONVERT(VARCHAR,ID-1) + '] = "'+ LTRIM(RTRIM(FALA)) + '";'
FROM DISCURSOS

SELECT TOP 10 FALA
, 'x[' + CONVERT(VARCHAR,ID-1) + '] = "'+ LTRIM(RTRIM(FALA)) + '";'
FROM DISCURSOS_LIMPO


SELECT FALA
, 'x[' + CONVERT(VARCHAR,ID-1) + '] = "'+ LTRIM(RTRIM(FALA)) + '";'
FROM DISCURSO_RECOMPOSTO



-- SEQUÊNCIA MAIS COMUM: 'ra'
SELECT TOP 20 FALA
, 'x[' + CONVERT(VARCHAR,ID-1) + '] = "'+ LTRIM(RTRIM(FALA)) + '";'
FROM DISCURSOS

SELECT TOP 20 FALA
, 'x[' + CONVERT(VARCHAR,ID-1) + '] = "'+ LTRIM(RTRIM(FALA)) + '";'
FROM DISCURSOS_LIMPO

-- TESTE COM O TOTAL:
-- SEQUÊNCIA MAIS COMUM: 'o'
SELECT FALA
, 'x[' + CONVERT(VARCHAR,ID-1) + '] = "'+ LTRIM(RTRIM(FALA)) + '";'
FROM DISCURSOS
WHERE LTRIM(RTRIM(FALA)) <> ''


-- SEQUÊNCIA MAIS COMUM: 
SELECT FALA
, 'x[' + CONVERT(VARCHAR,ID-1) + '] = "'+ LTRIM(RTRIM(FALA)) + '";'
FROM DISCURSOS_LIMPO
WHERE LTRIM(RTRIM(FALA)) <> ''




------------------------------------------------------------------------
------------------------------------------------------------------------
-- OK 2) DE REGRAS DE ASSOCIAÇÃO

-- OK, PRECISO GERAR UMA LINHA PARA CADA DEPUTADO
-- PRECISO COLOCAR OS IDS NUMERICOS DE CADA PALAVRA
-- NÃO POSSO REPETIR UM MESMO ID PARA UM ÚNICO DEPUTADO!
-- NÃO PRECISO COLOCAR , SO SEPARAR POR ESPAÇO


SELECT A.ID, B.*, A.PALAVRA
FROM TB_FEATURES A JOIN DISCURSOS_LIMPO B
ON A.ID = B.ID
WHERE POSSUI_PALAVRA = 1
ORDER BY A.ID


drop table #tx

select distinct palavra
into #tx
from TB_FEATURES


select top 10 *
from #tx

alter table #tx
add id int identity(1,1)


select * from #tx

-- 3438
select COUNT(*) from #tx

-- 3438
select COUNT(distinct palavra) from TB_FEATURES

-- ASSOCIANDO OS ID COM AS PALAVRAS
SELECT A.ID, B.*, A.PALAVRA , C.ID AS ID_PALAVRA
FROM TB_FEATURES A JOIN DISCURSOS_LIMPO B
ON A.ID = B.ID
JOIN #tx C
ON A.PALAVRA = C.PALAVRA
WHERE POSSUI_PALAVRA = 1
ORDER BY A.ID


-- VERIFICANDO SE EXISTE MUITA PALABRA REPETIDA POR VOTO
-- APARENTEMENTE NÃO!
SELECT A.ID, COUNT(A.PALAVRA), COUNT(DISTINCT A.PALAVRA)
FROM TB_FEATURES A JOIN DISCURSOS_LIMPO B
ON A.ID = B.ID
WHERE POSSUI_PALAVRA = 1
GROUP BY A.ID
HAVING COUNT(A.PALAVRA) <> COUNT(DISTINCT A.PALAVRA)
ORDER BY A.ID


DROP TABLE #TX_SEPARADAS

SELECT A.ID,  A.PALAVRA , CONVERT(VARCHAR(10),C.ID) AS ID_PALAVRA
into #TX_SEPARADAS
FROM TB_FEATURES A JOIN DISCURSOS_LIMPO B
ON A.ID = B.ID
JOIN #tx C
ON A.PALAVRA = C.PALAVRA
WHERE POSSUI_PALAVRA = 1
ORDER BY A.ID




Select distinct ST2.id,substring(
        (
            Select ' '+ST1.[ID_PALAVRA] AS [text()]
            From #TX_SEPARADAS ST1
            Where ST1.id= ST2.id
            ORDER BY ST1.id
            For XML PATH ('')
        ), 2, 8000) 
From #TX_SEPARADAS ST2 

-- minsup: .3
-- minconf: 0.6
-- regras interessantes
1688 ==> 3435 #SUP: 174 #CONF: 0,81308 -- NÃO ==> BRASIL
229 ==> 2359 #SUP: 164 #CONF: 0,68908
229 ==> 3385 #SUP: 197 #CONF: 0,82773
229 ==> 3435 #SUP: 202 #CONF: 0,84874

229 3435 ==> 3385 #SUP: 172 #CONF: 0,85149
229 3385 ==> 3435 #SUP: 172 #CONF: 0,8731
229 ==> 3385 3435 #SUP: 172 #CONF: 0,72269

select * from #tx
where ID in(1688,229)


select * from #tx
where ID in(1688,229,)



-- minsup: .5
-- minconf: 0.6
-- regras:

2359 ==> 3385 #SUP: 262 #CONF: 0,76163 -- PRESIDENTE ==> SIM
3385 ==> 2359 #SUP: 262 #CONF: 0,71585 -- SIM ==> PRESIDENTE

2359 ==> 3435 #SUP: 295 #CONF: 0,85756 -- PRESIDENTE ==> VOTO
3435 ==> 2359 #SUP: 295 #CONF: 0,68605 -- VOTO ==> PRESIDENTE


3385 ==> 3435 #SUP: 320 #CONF: 0,87432 -- SIM ==> VOTO
3435 ==> 3385 #SUP: 320 #CONF: 0,74419 -- VOTO ==> SIM

select * from #tx
where ID in(2359,3435,1354)


-- minsup: .6
-- minconf: .6


3435 ==> 3385 #SUP: 320 #CONF: 0,74419
3385 ==> 3435 #SUP: 320 #CONF: 0,87432

-- sim ==> voto
-- voto ==> sim
select * from #tx
where ID in(3435,3385)

select * from #tx
where ID in(3385,3435)

-- minsup: .7
-- minconf: .6
-- nada!






------------------------------------------------------------------------
------------------------------------------------------------------------
-- OK 3) ANÁLISE COM FERRAMENTA DE ASSOCIAÇÃO DE PALAVRAS (ver ui que testei na cpbr)
-- (JIGSAW)

-- TENHO QUE GERAR UM ARQUIVO XML COM A SEGUINTE EXTRUTURA
/*
...
<documents>
  <document>
    <docID>1Chr1.txt</docID>
    <docText>...</docText>
    <Partido> </Partido>
    <Voto> </Voto>
    <indexterm>3D displays</indexterm>
    <indexterm>Internet</indexterm>
    ....
    </document>
    
    ...  
*/
/*
SELECT TOP 10 A.ID, B.VOTO,UPPER(PALAVRA),A.ORDEM_PALAVRA, B.*
FROM TB_DISCURSOS_PALAVRAS A
INNER JOIN DISCURSOS_LIMPO B
ON A.ID = B.ID
*/

SELECT A.* , B.DEPUTADO, B.PARTIDO, B.ESTADO,B.VOTO, B.GENERO , C.PALAVRA
FROM DISCURSO_RECOMPOSTO A 
INNER JOIN DISCURSOS_LIMPO B 
ON A.ID = B.ID
INNER JOIN TB_DISCURSOS_PALAVRAS C 
ON A.ID = C.ID
where a.ID = 119
    

SELECT '<document><docID>' + CONVERT(VARCHAR,A.ID) + '</docID><docText>' 
       + A.FALA + '</docText><Deputado>'
       + B.DEPUTADO  + ' </Deputado><Partido>' 
       + B.PARTIDO + '</Partido><Estado>'
       + B.ESTADO + '</Estado><Voto>'
       + (CASE WHEN B.VOTO = 'Sim' THEN 'Sim' ELSE 'Não' END) + '</Voto><Genero>'
       + B.GENERO + '</Genero>'
       + C.index_terms + '</document>' 
FROM DISCURSO_RECOMPOSTO A 
INNER JOIN DISCURSOS_LIMPO B
ON A.ID = B.ID
inner join (
		select id, fala, '<' + replace(REPLACE(fala,'_','<'),'+','>')   as index_terms
		from 
		(
			Select distinct ST2.id, 
				substring(
					(
						Select '_p+'+ST1.palavra  + '_/p+' AS [text()]
						From dbo.TB_DISCURSOS_PALAVRAS ST1
						Where ST1.id= ST2.id
						ORDER BY ST1.id
						For XML PATH ('')
					), 2, 8000) [FALA]
			From dbo.TB_DISCURSOS_PALAVRAS ST2
		) as termos ) AS C
ON A.ID = C.ID		

------------------------------------------------------------------------
------------------------------------------------------------------------
-- 4) ANÁLISE COM CLUSERING
-- AQUI VOU FAZER O FUZZY MATCHING PARA PEGAR QUAIS DISCURSOS SÃO MAIS
-- PARECIDOS


SELECT 
	A.ID AS A_ID
	, A.FALA AS FALA1
	, B.id  AS B_ID
	, B.FALA AS FALA2
	,dbo.fn_JaroWinkler(A.FALA,B.FALA ) AS SIMILARIDADE
INTO #TB_PARECIDOS
FROM DISCURSO_RECOMPOSTO A, DISCURSO_RECOMPOSTO B
WHERE A.FALA <> B.FALA
-- ORDER BY 5 DESC

-- NOTA: PROCESSO GERADO PELO PYTHON UTILIZANDO O SCRIPT
-- E:\Meus Documentos\Blog\BETA_AnaliseDiscursos\Similaridades\jaro.py
-- RESULTADO NO ARQUIVO E:\Meus Documentos\Blog\BETA_AnaliseDiscursos\Similaridades\RESULTADO.TXT

CREATE TABLE RESULTADO_JARO
(
	ID_DISCURSO1 INT,
	ID_DISCURSO2 INT,
	RESULTADO_JARO NUMERIC(17,16)
)
GO

-- NOTA: CONVERTER O ARQUIVO TEXTO PARA UNICODE UTILIZANDO O NOTEPAD2
BULK INSERT DbDiscursos.dbo.RESULTADO_JARO
FROM 'E:\Meus Documentos\Blog\BETA_AnaliseDiscursos\Similaridades\RESULTADO.TXT'
WITH
  (
    FIELDTERMINATOR = ',',
    ROWTERMINATOR = '\n'
 );

SELECT TOP 10 *
FROM RESULTADO_JARO
ORDER BY RESULTADO_JARO DESC
/* DISCURSOS MAIS PARECIDOS
234	421
234	453
479	421
479	453
*/

-- TOP 100 DISCURSOS COM MAIOR SIMILARIDADE
SELECT TOP 100 * , (SELECT TOP 1 FALA FROM DISCURSO_RECOMPOSTO WHERE ID = A.ID_DISCURSO1 )
                , (SELECT TOP 1 FALA FROM DISCURSO_RECOMPOSTO WHERE ID = A.ID_DISCURSO2 )
FROM RESULTADO_JARO A
ORDER BY A.RESULTADO_JARO DESC


select *
from DISCURSOS
where ID in (161,424)

select *
from DISCURSOS
where ID in (7,21)



-- TOP 100 DISCURSOS COM MAIOR SIMILARIDADE PELO SIM
SELECT TOP 100 * , (SELECT TOP 1 FALA FROM DISCURSO_RECOMPOSTO WHERE ID = A.ID_DISCURSO1 )
                , (SELECT TOP 1 FALA FROM DISCURSO_RECOMPOSTO WHERE ID = A.ID_DISCURSO2 )
FROM RESULTADO_JARO A
WHERE ID_DISCURSO1 IN (SELECT ID FROM DISCURSOS WHERE VOTO = 'Sim')
and ID_DISCURSO2 IN (SELECT ID FROM DISCURSOS WHERE VOTO = 'Sim')
ORDER BY A.RESULTADO_JARO DESC

SELECT 
	A.ID AS A_ID
	, A.FALA AS FALA1
	, B.id  AS B_ID
	, B.FALA AS FALA2
FROM DISCURSO_RECOMPOSTO A, DISCURSO_RECOMPOSTO B
WHERE A.id =  ( SELECT TOP 1 ID_DISCURSO1 FROM RESULTADO_JARO WHERE ORDER BY RESULTADO_JARO DESC
AND   B.id = 453

S


-- OK 5) ANALISE COM O EVENT FLOW. CONSIDERAR CADA PALAVRA POR SEGUNDO
---   GERAR EVENTOS APENAS PARA AS TOP 10 PALAVRAS MAIS UTILIZADAS

-- OK, DESTACAR A DIFERENÇA ENTRE AS TOP 10 PALABRAS 
-- PARA QUEM É A FAVOR E QUEM É CONTRA

-- DESTACAR A ORDEM TAMBÉM!

-- DROP TABLE TB_EVENT_FLOW_DISCURSO
CREATE TABLE TB_EVENT_FLOW_DISCURSO
(
	ID INT,
	VOTO VARCHAR(500),
	PALAVRA VARCHAR(8000),
	ORDEM_PALAVRA INT,
	TOPS BIT, -- 1 = TÁ NO TOP 10 PALAVRAS, 0 NÃO ESTÁ
	DT  DATETIME
)

INSERT TB_EVENT_FLOW_DISCURSO
SELECT A.ID, B.VOTO,UPPER(PALAVRA),A.ORDEM_PALAVRA, 0, NULL
FROM TB_DISCURSOS_PALAVRAS A
INNER JOIN DISCURSOS_LIMPO B
ON A.ID = B.ID

SELECT TOP 10 *
FROM TB_EVENT_FLOW_DISCURSO

SELECT ID, MIN(ORDEM_PALAVRA)
FROM TB_EVENT_FLOW_DISCURSO
GROUP BY ID
ORDER BY ID


-- TOP 10 GERAL PRIMEIRO 
UPDATE TB_EVENT_FLOW_DISCURSO
SET TOPS = 1
WHERE PALAVRA IN (

SELECT TOP 10 UPPER(PALAVRA)
FROM TB_DISCURSOS_PALAVRAS A
INNER JOIN DISCURSOS_LIMPO B
ON A.ID = B.ID
GROUP BY UPPER(PALAVRA)
ORDER BY COUNT(*) DESC

)

-- TOP 10 PALAVRAS (TODOS)
SELECT TOP 10 UPPER(PALAVRA)
FROM TB_DISCURSOS_PALAVRAS A
INNER JOIN DISCURSOS_LIMPO B
ON A.ID = B.ID
GROUP BY UPPER(PALAVRA)
ORDER BY COUNT(*) DESC


SELECT * FROM TB_EVENT_FLOW_DISCURSO

-- ACERTANDO A DATA
SELECT *,DATEADD(SS,ORDEM_PALAVRA,'2016-03-17 17:00:00.000')  
FROM TB_EVENT_FLOW_DISCURSO

UPDATE TB_EVENT_FLOW_DISCURSO
SET DT = DATEADD(SS,ORDEM_PALAVRA,'2016-03-17 17:00:00.000')  

-- TODOS COM AS TOP 10 PALAVRAS (GERAL)
SELECT ID
		,PALAVRA
		,DT
FROM TB_EVENT_FLOW_DISCURSO
WHERE TOPS = 1
ORDER BY ID,DT ASC             

-- A FAVOR COM AS TOP 10 PALAVRAS DE QUEM É A FAVOR
SELECT ID
		,PALAVRA
		,DT
FROM TB_EVENT_FLOW_DISCURSO
WHERE PALAVRA IN 

(
	SELECT TOP 10 UPPER(PALAVRA)
	FROM TB_DISCURSOS_PALAVRAS A
	INNER JOIN DISCURSOS_LIMPO B
	ON A.ID = B.ID
	AND B.VOTO = 'Sim'
	GROUP BY UPPER(PALAVRA)
	ORDER BY COUNT(*) DESC
)
AND VOTO = 'Sim'
ORDER BY ID,DT ASC             


-- CONTRA COM AS TOP 10 PALAVRAS DE QUEM É CONTRA
SELECT ID
		,PALAVRA
		,DT
FROM TB_EVENT_FLOW_DISCURSO
WHERE PALAVRA IN 

(
	SELECT TOP 10 UPPER(PALAVRA)
	FROM TB_DISCURSOS_PALAVRAS A
	INNER JOIN DISCURSOS_LIMPO B
	ON A.ID = B.ID
	AND B.VOTO != 'Sim'
	GROUP BY UPPER(PALAVRA)
	ORDER BY COUNT(*) DESC
)
AND VOTO != 'Sim'
ORDER BY ID,DT ASC             


-- PALABRAS DIFERENTES NOS TOP 10 ENTRE
-- A FAVOR E CONTRA
	
	SELECT TOP 10 UPPER(PALAVRA), 'SIM'
	FROM TB_DISCURSOS_PALAVRAS A
	INNER JOIN DISCURSOS_LIMPO B
	ON A.ID = B.ID
	AND B.VOTO = 'Sim'
	GROUP BY UPPER(PALAVRA)
	ORDER BY COUNT(*) DESC
	
	
	SELECT TOP 10 UPPER(PALAVRA), 'NAO'
	FROM TB_DISCURSOS_PALAVRAS A
	INNER JOIN DISCURSOS_LIMPO B
	ON A.ID = B.ID
	AND B.VOTO != 'Sim'
	GROUP BY UPPER(PALAVRA)
	ORDER BY COUNT(*) DESC





SELECT ID,
       (CASE WHEN VOTO = 'Sim' THEN 'Sim' ELSE 'Não' END) AS VOTO
             ,
             ,PALAVRA
             ,DT
FROM TB_EVENT_FLOW_DISCURSO
WHERE TOPS = 1
ORDER BY ID,DT ASC             



-- TODOS
SELECT TOP 10 UPPER(PALAVRA), COUNT(*)
FROM TB_DISCURSOS_PALAVRAS A
INNER JOIN DISCURSOS_LIMPO B
ON A.ID = B.ID
GROUP BY UPPER(PALAVRA)
ORDER BY COUNT(*) DESC


SELECT TOP 10 *
FROM TB_DISCURSOS_PALAVRAS

SELECT DISTINCT ID
FROM TB_DISCURSOS_PALAVRAS




-- A FAVOR
SELECT UPPER(PALAVRA), COUNT(*)
FROM TB_DISCURSOS_PALAVRAS A
INNER JOIN DISCURSOS_LIMPO B
ON A.ID = B.ID
WHERE B.VOTO = 'Sim'
GROUP BY UPPER(PALAVRA)
ORDER BY COUNT(*) DESC

-- CONTRA
SELECT UPPER(PALAVRA), COUNT(*)
FROM TB_DISCURSOS_PALAVRAS A
INNER JOIN DISCURSOS_LIMPO B
ON A.ID = B.ID
WHERE B.VOTO != 'Sim'
GROUP BY UPPER(PALAVRA)
ORDER BY COUNT(*) DESC

-- OK 6) ANALISE COM ARVORE DE DECISÃO PARA VER QUAL É A MELHOR 
-- PALAVRA QUE CLASSIFICA QUEM VOTOU SIM OU NÃO (A FAVOR OU CONTRA)
-- RESULTADOS MAIS OU MENOS OK...

SELECT A.* , B.*
FROM TB_DISCURSOS_PALAVRAS A
INNER JOIN DISCURSOS_LIMPO B
ON A.ID = B.ID

SELECT TOP 10 *
FROM DISCURSOS_LIMPO


SELECT *
FROM TB_DISCURSOS_PALAVRAS
WHERE ID <= 10

-- OK, VOU TER ENTÃO 85 COLUNAS
SELECT COUNT(*), COUNT(DISTINCT PALAVRA)
FROM TB_DISCURSOS_PALAVRAS
WHERE ID <= 10

SELECT DISTINCT PALAVRA
FROM TB_DISCURSOS_PALAVRAS
WHERE ID <= 10
ORDER BY PALAVRA ASC

-- FORMATO DO ARQUIVO:
/*
T: <AT1>,<AT2>,...,<CLASSIFICACÃO>;
X: <V_AT1>,<V_AT2>,...,<V_CLASS>;
...
*/

-- GERANDO A PRIMEIRA LINHA (NOME DAS FEATURES - UMA PARA CADA PALAVRA)
-- TESTE COM 10 VOTOS

-- DROP TABLE #TB_DISTINTAS

SELECT DISTINCT PALAVRA, 1 AS ID
INTO #TB_DISTINTAS
FROM TB_DISCURSOS_PALAVRAS
WHERE ID <= 10
ORDER BY PALAVRA ASC



SELECT * FROM #TB_DISTINTAS

Select distinct ST2.id, 
    substring(
        (
            Select ','+ST1.palavra  AS [text()]
            From #TB_DISTINTAS ST1
            Where ST1.id= ST2.id
            ORDER BY ST1.id
            For XML PATH ('')
        ), 2, 8000) [FALA]
From #TB_DISTINTAS ST2

/*
T: até,bem,Brasil,brasileiro,brasileiros,Brizola,chegar,consciência,constitucional,contra,corrupção,democracia,Democrático,desacorrentada,desistir,digo,direita,direito,esperança,esquerda,Estado,exercer,família,famílias,favor,filho,fizeram,foge,gaúcho,geração,gerações,Getúlio,governo,história,igualdade,impeachment,impedimento,ir,Jango,justiça,legado,luta,maçons,médicos,melhor,merece,mudança,mudanças,Nação,não,nome,PDT,pedindo,PMDB,pobres,podemos,possamos,povo,Presidente,processo,prosseguimento,próximas,próximo,PT,querido,República,resgate,respeitados,respeito,ricos,Roraima,roraimenses,roubada,ruas,sejam,sim,social,Sra,teu,todas,verás,vir,vota,votarmos,voto,A_FAVOR;

*/

SELECT B.ID, A.PALAVRA, B.PALAVRA
FROM #TB_DISTINTAS A LEFT JOIN TB_DISCURSOS_PALAVRAS B
ON A.PALAVRA = B.PALAVRA
ORDER BY B.PALAVRA

-- TESTES

SELECT A.PALAVRA 
      , (CASE WHEN (SELECT TOP 1 PALAVRA FROM TB_DISCURSOS_PALAVRAS B WHERE ID = 1 AND B.PALAVRA = A.PALAVRA) IS NULL THEN '0' ELSE '1' END)
FROM #TB_DISTINTAS A
ORDER BY A.PALAVRA ASC


SELECT 1 AS ID
      ,A.PALAVRA 
	  , (CASE WHEN (SELECT TOP 1 PALAVRA FROM TB_DISCURSOS_PALAVRAS B WHERE ID = 1 AND B.PALAVRA = A.PALAVRA) IS NULL THEN '0' ELSE '1' END) AS [POSSUI_PALAVRA?]
FROM #TB_DISTINTAS A

DROP TABLE #TB_FEATURES
CREATE TABLE #TB_FEATURES
(
	ID INT,
	PALAVRA VARCHAR(8000),
	[POSSUI_PALAVRA] VARCHAR(1)
)


DECLARE @X INT

SET @X = 1

-- WHILE @X <= (SELECT MAX(ID) FROM DISCURSOS_LIMPO)
WHILE @X <= 10
BEGIN
	
	INSERT #TB_FEATURES
	SELECT @X AS ID
		  ,A.PALAVRA 
		  , (CASE WHEN (SELECT TOP 1 PALAVRA FROM TB_DISCURSOS_PALAVRAS B WHERE ID = @X AND B.PALAVRA = A.PALAVRA) IS NULL THEN '0' ELSE '1' END) AS [POSSUI_PALAVRA?]
	FROM #TB_DISTINTAS A
	
	SET @X = @X + 1
END

SELECT * FROM #TB_FEATURES

Select distinct ST2.id, 
    'X: ' + substring(
        (
            Select ','+ST1.[POSSUI_PALAVRA] AS [text()]
            From #TB_FEATURES ST1
            Where ST1.id= ST2.id
            ORDER BY ST1.id
            For XML PATH ('')
        ), 2, 8000) + ',' +b.Voto+ ';' [FALA]
From #TB_FEATURES ST2, DISCURSOS_LIMPO b
where st2.id = b.id





-- FAZENDO PARA 100 VOTOS

-- DROP TABLE #TB_DISTINTAS

SELECT DISTINCT PALAVRA, 1 AS ID
INTO #TB_DISTINTAS
FROM TB_DISCURSOS_PALAVRAS
WHERE ID <=100
ORDER BY PALAVRA ASC



SELECT * FROM #TB_DISTINTAS

Select distinct ST2.id, 
    substring(
        (
            Select ','+ST1.palavra  AS [text()]
            From #TB_DISTINTAS ST1
            Where ST1.id= ST2.id
            ORDER BY ST1.id
            For XML PATH ('')
        ), 2, 8000) [FALA]
From #TB_DISTINTAS ST2



/*
T: abafar,abençoando,abstenção,abstenho,acaba,aceitar,acho,acima,acompanha,acompanhar,acordão,acreditam,Acredito,acusações,acusado,administração,admissibilidade,adotou,Aécio,afastada,Agora,agrária,agricultor,agricultores,agronegócio,aguentar,ainda,alia,alimentam,alma,almoça,amado,Amapá,amigos,amor,ampla,Ana,andar,aniversário,anos,aplicando,aprenda,aqueles,Arantes,Arapongas,área,assassinado,astros,até,atingir,avante,aves,Azul,bandeira,bandidos,Bando,base,basta,Beltrão,bem,bênçãos,Beto,Blumenau,bom,Brasil,brasileira,brasileiras,brasileiro,brasileiros,brava,Brizola,Bruno,cabe,Cachoeira,calejada,Câmara,Cambé,campo,Campos,Canoas,caráter,carismática,carregando,Carta,Casa,Cascavel,cassado,cassar,cassarmos,Castanhal,Catarina,Catarinae,catarinense,católica,Caxias,Céu,chance,Chapecó,chegando,chegar,cheiro,cidadania,cidadão,cidade,cima,citar,clamando,colega,colégio,coletiva,Coloca,colocando,combate,combater,combina,cometeram,cometeu,cometidos,comprei,concórdia,condenam,condenar,conduzido,conivente,consciência,consertar,consideração,Considerando,considerar,conspiração,conspirador,constitucional,Constituição,constroem,constrói,continua,continue,continuemos,contra,contrária,convicção,coração,corresponder,corrupção,corrupto,corruptos,covardes,Covardia,CPI,crescer,crescimento,criança,crianças,Criciúma,crime,crimes,criminosa,crise,cristianismo,cujo,cumprir,Cumpro,Cunha,Curitiba,curitibanos,CUT,dada,daqueles,daqui,das,decente,decisão,defendeu,defendo,defesa,dele,Delegado,demagogo,democracia,democraciae,democráticas,Democrático,denunciados,Deputado,Deputados,desacorrentada,Desarmamento,desempregados,desenvolvimento,desistir,desta,destruir,Deus,devem,devidos,dia,dias,diferente,diferentemente,dignidade,digo,Dilma,direita,direito,direitos,disse,ditadura,Diz,dizer,dizer:,dois,Dom,dorsal,duas,dúzia,econômico,Éder,édo,Eduardo,eivadas,Ela,elas,ele,elegeu,eleição,eleições,eleito,eleitoral,eleitores,encaminhamos,encontro,enganados,ensinei,ensinem,entanto,Então,entender,envergonham,enxergar,equivocado,escolas,escravo,Ese,espaço,espaços,especialmente,esperança,Espero,espinha,espontânea,esposa,esquerda,essa,essas,esses,Estado,Estamos,estão,Estatuto,estava,este,estejam,estou,ética,Europa,evangélica,exceção,exemplo,exercer,Existe,expectativas,façanhas,facção,fala,falhas,família,famílias,farroupilha,fascistas,favor,fazendo,fazer,fé,Federal,feitas,feito,Felipe,Feliz,filha,filhas,filho,filhos,fim,final,Fisco,fizeram,Florianópolis,foge,foime,Fora,foram,força,forma,formamos,Francisco,frente,fui,fumageira,fumicultores,fundamentos,futuro,Gaúcha,gaúchas,gaúcho,gaúchos,Gente,geração,gerações,Gerais,Getúlio,golpe,golpismo,golpistas,Governadores,governar,Governo,Grande,guerreira,há10,habitantes,haja,harmonia,hino,hipocrisia,história,histórica,histórico,Hoje,homem,homenagem,honesta,honestas,honestidade,honra,Honrando,honrar,hora,horror,humana,Ibiporã,idade,ideologias,igualdade,ilegal,ilegítimo,impeachment,impedimento,inaugure,indústria,inovação,instalada,institucional,investimentos,ir,irresponsável,Ituporanga,Ivo,Jango,janta,Joinville,Jovair,jovens,julgado,junta,junto,juramos,jurei,jurídico,Justiça,justo,lados,ladrão,LavaJato,lealdade,legado,legal,legalidade,legitimados,legitimidade,lei,leis,lesapátria,levaram,liberdade,libertação,limpar,limpas,limpo,Londrina,Lorscheiter,Lucimar,Lula,lulopetista,luta,lutaram,lutou,maçons,mãe,mãezinha,Magna,maioria,majoritária,majoritário,maltratado,mande,mão,maravilhoso,marginais,Mauro,médicos,meia,melhor,menos,merece,mero,mesmas,metro,metropolitana,Michel,mil,milhões,militar,mim,minhas,Ministério,modelo,moderno,momento,momentos,moral,moralidade,Moro,morreram,morto,motivo,movimentos,mudança,mudanças,mudar,mulher,mulheres,mundo,municipalista,Município,Nação,nacional,não,nãoa,nasceu,nasci,Nazaré,negra,nenhum,nesta,neste,neta,neto,netos,Neves,ninguém,nobres,nojo,nome,nordeste,Noroeste,nossa,nossas,nossos,Nova,novas,novo,num,nunca,oeste,olhar,oligarquia,onde,opinião,oportunistas,oposição,orgulho,origem,ouro,outros,ouvir,País,Paiva,Pará,paraenfrentar,Paraná,paranaenses,pares,Parlamentares,Parlamento,partido,partido:,partir,passado,passagem,passar,passo,Paulo,paz,PDT,pedaladas,pede,pedem,pedindo,Pedro,pelegagem,penso,pequenos,Pesou,pesquisa,pessoas,picaretas,pior,planta,plenário,PMDB,pobre,pobres,pode,podemos,poder,poderia,Polícia,política,político,população,popular,populismo,Portanto,posição,possa,possamos,posso,povo,PP,prata,precisamos,preferência,preside,presidencial,Presidenta,Presidente,presidir,prezam,primeiro,princípios,prisão,privilégio,processo,produção,produzem,Programa,programática,progresso,projeto,PRONATEC,propondo,propostas,prosseguimento,proteção,protestar,próximas,próximo,PSOL,PT,pública,Público,quadrado,quadrangular,quadrilha,quais,qualquer,quando,quebrar,quem,querem,queremos,querida,querido,rapina,raposas,reais,realiza,realmente,recolher,reconheço,reconstrução,reencontrar,reescrever,reforma,região,regras,Relator,remunerada,renovação,representadas,represento,República,resgate,resolve,respeitados,respeito,responsabilidade,retiveram,retomada,réu,réus,Richa,ricos,Rio,riograndense,riograndense:,Rogério,Rolândia,Roraima,roraimenses,Rosa,rotundo,roubada,roubalheira,rua,ruas,Rubens,sabe,sabedoria,sabem,sabendo,Saia,sangue,Santa,segunda,segundo,seis,sejam,sempre,Senado,sendo,Senhor,Senhora,Senhores,sentimento,separar,será,serenidade,Sérgio,sério,Serra,sessão,sexo,sim,sinto,Sirvam,situação,soberania,soberano,sociais,social,socialista,Solidariedade,Sra,Sras,Srs,sua,suas,sudeste,sudoeste,suicídio,sujeira,Sul,suor,tamanho,também,tanta,tanto,tantos,Tapajós,tarefa,tecnologia,Temer,tempo,tenha,tenho,terço,termos,terra,teu,teve,tirar,toda,todas,todo,todos,Toledo,tombaram,trabalhadoras,trabalhadores,trabalham,trabalho,traduzir,tranquila,tranquilamente,transformar,Trento,trocar,trocase,troque,tudo,única,unirmos,urbana,vagabundização,valente,válidos,valor,valorização,vamos,vão,velhas,verás,verdade,vermelha,VicePresidente,vícios,Vida,vir,virão,virtude,Viva,vivam,volta,vontade,vota,votam,votamos,votar,votaram,votarmos,votei,voto,votos,voz,Wright,Xanxerê,A_FAVOR;

*/

TRUNCATE TABLE #TB_FEATURES

DECLARE @X INT

SET @X = 1

-- WHILE @X <= (SELECT MAX(ID) FROM DISCURSOS_LIMPO)
WHILE @X <= 100
BEGIN
	
	INSERT #TB_FEATURES
	SELECT @X AS ID
		  ,A.PALAVRA 
		  , (CASE WHEN (SELECT TOP 1 PALAVRA FROM TB_DISCURSOS_PALAVRAS B WHERE ID = @X AND B.PALAVRA = A.PALAVRA) IS NULL THEN '0' ELSE '1' END) AS [POSSUI_PALAVRA?]
	FROM #TB_DISTINTAS A
	
	SET @X = @X + 1
END

SELECT * FROM #TB_FEATURES

Select distinct ST2.id, 
    'X: ' + substring(
        (
            Select ','+ST1.[POSSUI_PALAVRA] AS [text()]
            From #TB_FEATURES ST1
            Where ST1.id= ST2.id
            ORDER BY ST1.id
            For XML PATH ('')
        ), 2, 8000) + ',' + (CASE WHEN b.Voto='Sim' THEN 'Sim' ELSE 'Não' END) + ';' [FALA]
From #TB_FEATURES ST2, DISCURSOS_LIMPO b
where st2.id = b.id




-- FAZENDO PARA TODOS OS VOTOS

-- DROP TABLE #TB_DISTINTAS

CREATE TABLE #TB_DISTINTAS
(
	ID INT IDENTITY(1,1),
	PALAVRA VARCHAR(MAX),
)

INSERT #TB_DISTINTAS(PALAVRA)
SELECT DISTINCT PALAVRA
FROM TB_DISCURSOS_PALAVRAS
ORDER BY PALAVRA ASC


SELECT * FROM #TB_DISTINTAS

-- NÃO POSSO USAR O TRUQUE DO XML, POIS TEM O LIMITE DE 8000!
/*
Select distinct ST2.id, 
    substring(
        (
            Select ','+ST1.palavra  AS [text()]
            From #TB_DISTINTAS ST1
            Where ST1.id= ST2.id
            ORDER BY ST1.id
            For XML PATH ('')
        ), 2, 8000) [FALA]
From #TB_DISTINTAS ST2
*/

DECLARE @X INT
DECLARE @FEATURES VARCHAR(MAX)

SET @X = 1
SET @FEATURES = ''

WHILE @X <= (SELECT COUNT(*) FROM #TB_DISTINTAS)
BEGIN
		
	SET @FEATURES = @FEATURES + ',' + (SELECT TOP 1 PALAVRA FROM #TB_DISTINTAS WHERE ID = @X)
	SET @X = @X + 1
END

SELECT @FEATURES





/*
T: abafar,abençoando,abstenção,abstenho,acaba,aceitar,acho,acima,acompanha,acompanhar,acordão,acreditam,Acredito,acusações,acusado,administração,admissibilidade,adotou,Aécio,afastada,Agora,agrária,agricultor,agricultores,agronegócio,aguentar,ainda,alia,alimentam,alma,almoça,amado,Amapá,amigos,amor,ampla,Ana,andar,aniversário,anos,aplicando,aprenda,aqueles,Arantes,Arapongas,área,assassinado,astros,até,atingir,avante,aves,Azul,bandeira,bandidos,Bando,base,basta,Beltrão,bem,bênçãos,Beto,Blumenau,bom,Brasil,brasileira,brasileiras,brasileiro,brasileiros,brava,Brizola,Bruno,cabe,Cachoeira,calejada,Câmara,Cambé,campo,Campos,Canoas,caráter,carismática,carregando,Carta,Casa,Cascavel,cassado,cassar,cassarmos,Castanhal,Catarina,Catarinae,catarinense,católica,Caxias,Céu,chance,Chapecó,chegando,chegar,cheiro,cidadania,cidadão,cidade,cima,citar,clamando,colega,colégio,coletiva,Coloca,colocando,combate,combater,combina,cometeram,cometeu,cometidos,comprei,concórdia,condenam,condenar,conduzido,conivente,consciência,consertar,consideração,Considerando,considerar,conspiração,conspirador,constitucional,Constituição,constroem,constrói,continua,continue,continuemos,contra,contrária,convicção,coração,corresponder,corrupção,corrupto,corruptos,covardes,Covardia,CPI,crescer,crescimento,criança,crianças,Criciúma,crime,crimes,criminosa,crise,cristianismo,cujo,cumprir,Cumpro,Cunha,Curitiba,curitibanos,CUT,dada,daqueles,daqui,das,decente,decisão,defendeu,defendo,defesa,dele,Delegado,demagogo,democracia,democraciae,democráticas,Democrático,denunciados,Deputado,Deputados,desacorrentada,Desarmamento,desempregados,desenvolvimento,desistir,desta,destruir,Deus,devem,devidos,dia,dias,diferente,diferentemente,dignidade,digo,Dilma,direita,direito,direitos,disse,ditadura,Diz,dizer,dizer:,dois,Dom,dorsal,duas,dúzia,econômico,Éder,édo,Eduardo,eivadas,Ela,elas,ele,elegeu,eleição,eleições,eleito,eleitoral,eleitores,encaminhamos,encontro,enganados,ensinei,ensinem,entanto,Então,entender,envergonham,enxergar,equivocado,escolas,escravo,Ese,espaço,espaços,especialmente,esperança,Espero,espinha,espontânea,esposa,esquerda,essa,essas,esses,Estado,Estamos,estão,Estatuto,estava,este,estejam,estou,ética,Europa,evangélica,exceção,exemplo,exercer,Existe,expectativas,façanhas,facção,fala,falhas,família,famílias,farroupilha,fascistas,favor,fazendo,fazer,fé,Federal,feitas,feito,Felipe,Feliz,filha,filhas,filho,filhos,fim,final,Fisco,fizeram,Florianópolis,foge,foime,Fora,foram,força,forma,formamos,Francisco,frente,fui,fumageira,fumicultores,fundamentos,futuro,Gaúcha,gaúchas,gaúcho,gaúchos,Gente,geração,gerações,Gerais,Getúlio,golpe,golpismo,golpistas,Governadores,governar,Governo,Grande,guerreira,há10,habitantes,haja,harmonia,hino,hipocrisia,história,histórica,histórico,Hoje,homem,homenagem,honesta,honestas,honestidade,honra,Honrando,honrar,hora,horror,humana,Ibiporã,idade,ideologias,igualdade,ilegal,ilegítimo,impeachment,impedimento,inaugure,indústria,inovação,instalada,institucional,investimentos,ir,irresponsável,Ituporanga,Ivo,Jango,janta,Joinville,Jovair,jovens,julgado,junta,junto,juramos,jurei,jurídico,Justiça,justo,lados,ladrão,LavaJato,lealdade,legado,legal,legalidade,legitimados,legitimidade,lei,leis,lesapátria,levaram,liberdade,libertação,limpar,limpas,limpo,Londrina,Lorscheiter,Lucimar,Lula,lulopetista,luta,lutaram,lutou,maçons,mãe,mãezinha,Magna,maioria,majoritária,majoritário,maltratado,mande,mão,maravilhoso,marginais,Mauro,médicos,meia,melhor,menos,merece,mero,mesmas,metro,metropolitana,Michel,mil,milhões,militar,mim,minhas,Ministério,modelo,moderno,momento,momentos,moral,moralidade,Moro,morreram,morto,motivo,movimentos,mudança,mudanças,mudar,mulher,mulheres,mundo,municipalista,Município,Nação,nacional,não,nãoa,nasceu,nasci,Nazaré,negra,nenhum,nesta,neste,neta,neto,netos,Neves,ninguém,nobres,nojo,nome,nordeste,Noroeste,nossa,nossas,nossos,Nova,novas,novo,num,nunca,oeste,olhar,oligarquia,onde,opinião,oportunistas,oposição,orgulho,origem,ouro,outros,ouvir,País,Paiva,Pará,paraenfrentar,Paraná,paranaenses,pares,Parlamentares,Parlamento,partido,partido:,partir,passado,passagem,passar,passo,Paulo,paz,PDT,pedaladas,pede,pedem,pedindo,Pedro,pelegagem,penso,pequenos,Pesou,pesquisa,pessoas,picaretas,pior,planta,plenário,PMDB,pobre,pobres,pode,podemos,poder,poderia,Polícia,política,político,população,popular,populismo,Portanto,posição,possa,possamos,posso,povo,PP,prata,precisamos,preferência,preside,presidencial,Presidenta,Presidente,presidir,prezam,primeiro,princípios,prisão,privilégio,processo,produção,produzem,Programa,programática,progresso,projeto,PRONATEC,propondo,propostas,prosseguimento,proteção,protestar,próximas,próximo,PSOL,PT,pública,Público,quadrado,quadrangular,quadrilha,quais,qualquer,quando,quebrar,quem,querem,queremos,querida,querido,rapina,raposas,reais,realiza,realmente,recolher,reconheço,reconstrução,reencontrar,reescrever,reforma,região,regras,Relator,remunerada,renovação,representadas,represento,República,resgate,resolve,respeitados,respeito,responsabilidade,retiveram,retomada,réu,réus,Richa,ricos,Rio,riograndense,riograndense:,Rogério,Rolândia,Roraima,roraimenses,Rosa,rotundo,roubada,roubalheira,rua,ruas,Rubens,sabe,sabedoria,sabem,sabendo,Saia,sangue,Santa,segunda,segundo,seis,sejam,sempre,Senado,sendo,Senhor,Senhora,Senhores,sentimento,separar,será,serenidade,Sérgio,sério,Serra,sessão,sexo,sim,sinto,Sirvam,situação,soberania,soberano,sociais,social,socialista,Solidariedade,Sra,Sras,Srs,sua,suas,sudeste,sudoeste,suicídio,sujeira,Sul,suor,tamanho,também,tanta,tanto,tantos,Tapajós,tarefa,tecnologia,Temer,tempo,tenha,tenho,terço,termos,terra,teu,teve,tirar,toda,todas,todo,todos,Toledo,tombaram,trabalhadoras,trabalhadores,trabalham,trabalho,traduzir,tranquila,tranquilamente,transformar,Trento,trocar,trocase,troque,tudo,única,unirmos,urbana,vagabundização,valente,válidos,valor,valorização,vamos,vão,velhas,verás,verdade,vermelha,VicePresidente,vícios,Vida,vir,virão,virtude,Viva,vivam,volta,vontade,vota,votam,votamos,votar,votaram,votarmos,votei,voto,votos,voz,Wright,Xanxerê,A_FAVOR;

*/

DROP TABLE #TB_FEATURES

CREATE TABLE #TB_FEATURES
(
	ID INT,
	PALAVRA VARCHAR(8000),
	[POSSUI_PALAVRA] VARCHAR(1)
)


DECLARE @X INT

SET @X = 1

WHILE @X <= (SELECT MAX(ID) FROM DISCURSOS_LIMPO)
BEGIN
	
	INSERT #TB_FEATURES
	SELECT @X AS ID
		  ,A.PALAVRA 
		  , (CASE WHEN (SELECT TOP 1 PALAVRA FROM TB_DISCURSOS_PALAVRAS B WHERE ID = @X AND B.PALAVRA = A.PALAVRA) IS NULL THEN '0' ELSE '1' END) AS [POSSUI_PALAVRA?]
	FROM #TB_DISTINTAS A
	
	SET @X = @X + 1
END

SELECT * FROM #TB_FEATURES

SELECT COUNT(*) FROM #TB_FEATURES

DROP TABLE TB_FEATURES
CREATE TABLE TB_FEATURES
(
	ID INT ,
	PALAVRA VARCHAR(8000),
	POSSUI_PALAVRA VARCHAR(1)
)

INSERT TB_FEATURES
SELECT *  
FROM #TB_FEATURES

CREATE INDEX IX_ID ON TB_FEATURES(ID)


SELECT * FROM TB_FEATURES
where id in(1,2)
order by ID asc


Select distinct ST2.id, 
    'X: ' + substring(
        (
            Select ','+ST1.[POSSUI_PALAVRA] AS [text()]
            From TB_FEATURES ST1
            Where ST1.id= ST2.id
            ORDER BY ST1.id
            For XML PATH ('')
        ), 2, 8000) + ',' + (CASE WHEN b.Voto='Sim' THEN 'Sim' ELSE 'Não' END) + ';' [FALA]
From TB_FEATURES ST2, DISCURSOS_LIMPO b
where st2.id = b.id

select id, (CASE WHEN Voto='Sim' THEN '1' ELSE '0' END) 
from DISCURSOS_LIMPO
order by id


-- testes para ver se está tudo ok com a tabela tb_features


SELECT ID, SUM(CONVERT(SMALLINT,POSSUI_PALAVRA)) 
FROM TB_FEATURES
GROUP BY ID
order by ID asc



-- colocando todas as 'features' no formato
-- correto para o python ler!
-- aqui vão os nomes das features

select palavra
-- into #tx
from TB_FEATURES
where ID = 1
order by id


select top 10 *
from #tx

alter table #tx
add id int identity(1,1)


DECLARE @X INT
DECLARE @FEATURES VARCHAR(MAX)

SET @X = 1
SET @FEATURES = ''

WHILE @X <= (SELECT COUNT(*) FROM  #tx)
BEGIN
		
	SET @FEATURES = @FEATURES + ',' + (SELECT TOP 1 PALAVRA FROM #tx WHERE ID = @X)
	SET @X = @X + 1
END

SELECT @FEATURES

-- aqui vão os dados das features

Select distinct ST2.id,substring(
        (
            Select ','+ST1.[POSSUI_PALAVRA] AS [text()]
            From TB_FEATURES ST1
            Where ST1.id= ST2.id
            ORDER BY ST1.id
            For XML PATH ('')
        ), 2, 8000) 
From TB_FEATURES ST2, DISCURSOS_LIMPO b
where st2.id = b.id

-- TESTANDO ALGUNS VALORES

SELECT *
FROM TB_DISCURSOS_PALAVRAS
WHERE PALAVRA LIKE '%reconstrução%'


-- MELHOR PALAVRA: RECONSTRUÇÃO (TODOS OS 4 QUE UTILIZARAM VOTARAM A FAVOR)
select *
from DISCURSO_RECOMPOSTO a join DISCURSOS b
on a.id = b.ID 
WHERE a.fala LIKE '%reconstrução%'

select *
from DISCURSO_RECOMPOSTO a join DISCURSOS b
on a.id = b.ID 
WHERE a.fala LIKE '%exceção%'

select *
from DISCURSO_RECOMPOSTO a join DISCURSOS b
on a.id = b.ID 
WHERE a.fala LIKE '%desempregados%'



select *
from DISCURSO_RECOMPOSTO a join DISCURSOS b
on a.id = b.ID 
WHERE a.fala LIKE '%verdade%'


select *
from DISCURSO_RECOMPOSTO a join DISCURSOS b
on a.id = b.ID 
WHERE a.fala LIKE '%posicionamento%'





-- CALCULAR PARA CADA PALAVRA A QUANTIDADE DE VOTOS EM QUE ELA APARECE
SELECT A.PALAVRA, COUNT(DISTINCT A.ID) AS TOTAL_DISCURSOS_PALAVRA_APARECE
FROM TB_FEATURES A
WHERE A.POSSUI_PALAVRA = 1
GROUP BY A.PALAVRA
-- ORDER BY A.PALAVRA
ORDER BY 2 DESC


-- DEPOIS CALCULAR QUANDOS VOTOS SIM E QUANTOS NÃO TIVERAM AQUELA PALAVRA
SELECT A.PALAVRA, COUNT(DISTINCT A.ID) AS TOTAL_DISCURSOS_PALAVRA_APARECE_SIM
INTO #T_AFAVOR
FROM TB_FEATURES A join DISCURSOS b
on a.id = b.ID 
WHERE A.POSSUI_PALAVRA = 1
AND B.VOTO = 'Sim'
GROUP BY A.PALAVRA
ORDER BY A.PALAVRA


SELECT A.PALAVRA, COUNT(DISTINCT A.ID) AS TOTAL_DISCURSOS_PALAVRA_APARECE_NAO
INTO #T_CONTRA
FROM TB_FEATURES A join DISCURSOS b
on a.id = b.ID 
WHERE A.POSSUI_PALAVRA = 1
AND B.VOTO != 'Sim'
GROUP BY A.PALAVRA
ORDER BY A.PALAVRA


SELECT *
FROM #T_AFAVOR
WHERE PALAVRA = 'reconstrução'


-- DROP TABLE #T_CONTAGEM_PALAVRAS

-- FINAL
-- POR CAUSA DO JOIN ABAIXO, A QUERY ABAIXO 
-- RETORNA TODAS AS PALAVRAS QUE ESTÃO COM VOTOS SIM OU NÃO!
SELECT A.PALAVRA
             ,A.TOTAL_DISCURSOS_PALAVRA_APARECE_SIM
             ,B.TOTAL_DISCURSOS_PALAVRA_APARECE_NAO
             , C.TOTAL_DISCURSOS_PALAVRA_APARECE
INTO #T_CONTAGEM_PALAVRAS
FROM #T_AFAVOR A INNER JOIN #T_CONTRA B
ON A.PALAVRA = B.PALAVRA
INNER JOIN ( SELECT A.PALAVRA, COUNT(DISTINCT A.ID) AS TOTAL_DISCURSOS_PALAVRA_APARECE
FROM TB_FEATURES A
WHERE A.POSSUI_PALAVRA = 1
GROUP BY A.PALAVRA ) C
ON A.PALAVRA = C.PALAVRA

-- AGORA PARA PEGAR AS PALAVRAS QUE SOMENTE APARECE SIM OU NO NÃO

SELECT A.PALAVRA, COUNT(DISTINCT A.ID) AS TOTAL_DISCURSOS_PALAVRA_APARECE
FROM TB_FEATURES A
WHERE A.POSSUI_PALAVRA = 1
AND A.PALAVRA NOT IN ( SELECT PALAVRA FROM #T_CONTAGEM_PALAVRAS )
GROUP BY A.PALAVRA
-- ORDER BY A.PALAVRA
ORDER BY 2 DESC

-- TOP 5 PALAVRAS SOMENTE COM SIM :
/*
pai - sim - 21 ocorrências
esposa - sim - 18
Paraná - sim - 16
Santa - sim 15
mãe - sim 13
*/




/*

lutaram	7
hipocrisia	6
agrária	6
trabalhadoras	6
soberania	5
*/

select *
from DISCURSO_RECOMPOSTO a join DISCURSOS b
on a.id = b.ID 
WHERE a.fala LIKE '%Lutaram%'

select *
from DISCURSO_RECOMPOSTO a join DISCURSOS b
on a.id = b.ID 
WHERE a.fala LIKE '%hipocrisia%'.

select *
from DISCURSO_RECOMPOSTO a join DISCURSOS b
on a.id = b.ID 
WHERE a.fala LIKE '%agrária%'





SELECT *
FROM #T_CONTRA A INNER JOIN TB_FEATURES B
ON A.PALAVRA = B.PALAVRA
INNER JOIN DISCURSOS C
ON B.ID = C.ID
WHERE B.POSSUI_PALAVRA = 1
AND VOTO != 'Sim'
ORDER BY TOTAL_DISCURSOS_PALAVRA_APARECE_NAO DESC


 SELECT * 
 FROM TB_FEATURES


não
voto
Presidente
democracia
golpe
contra
Brasil
povo
Dilma

select *
from DISCURSO_RECOMPOSTO a join DISCURSOS b
on a.id = b.ID 
WHERE a.fala LIKE '%Dilma%'



SELECT b.PALAVRA
             ,B.TOTAL_DISCURSOS_PALAVRA_APARECE_NAO
             , C.TOTAL_DISCURSOS_PALAVRA_APARECE
FROM #T_CONTRA B
INNER JOIN ( SELECT A.PALAVRA, COUNT(DISTINCT A.ID) AS TOTAL_DISCURSOS_PALAVRA_APARECE
FROM TB_FEATURES A
WHERE A.POSSUI_PALAVRA = 1
GROUP BY A.PALAVRA ) C
ON b.PALAVRA = C.PALAVRA
order by TOTAL_DISCURSOS_PALAVRA_APARECE desc