-- identify members with duplicate addresses
SELECT MEMBER_ID, LABEL, COUNT(*)
FROM MEMBER_ADDRESS
GROUP BY MEMBER_ID, LABEL
HAVING COUNT(*) > 1;



-- delete duplicates, keeping the most recently modified address in each group
BEGIN TRANSACTION

DELETE FROM MEMBER_ADDRESS
WHERE MEMBER_ADDRESS_ID IN(
	SELECT dupeAddrs.MEMBER_ADDRESS_ID FROM (
		SELECT ROW_NUMBER() OVER(PARTITION BY addr1.MEMBER_ID, addr1.LABEL ORDER BY addr1.MODIFIED_ON DESC) AS 'ROW_NUM',
			addr1.MEMBER_ADDRESS_ID
		FROM MEMBER_ADDRESS addr1
		INNER JOIN (
			SELECT MEMBER_ID, LABEL
			FROM MEMBER_ADDRESS
			GROUP BY MEMBER_ID, LABEL
			HAVING COUNT(*) > 1
		) addr2 ON addr2.MEMBER_ID = addr1.MEMBER_ID AND addr2.LABEL = addr1.LABEL
	) dupeAddrs
WHERE dupeAddrs.ROW_NUM > 1);

COMMIT;



-- create an index to prevent users from adding duplicate addresses
ALTER TABLE MEMBER_ADDRESS  
ADD CONSTRAINT UQ_MEMBER_ADDRESS_MEMBER_ID_LABEL UNIQUE (MEMBER_ID, LABEL);
