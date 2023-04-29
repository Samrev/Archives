CREATE INDEX idx_loan_account_id ON Loan(account_id);
CREATE INDEX idx_loan_loan_id ON Loan(loan_id);
CREATE INDEX idx_disposition_account_id ON Disposition(account_id);
CREATE INDEX idx_disposition_client_id ON Disposition(client_id);
CREATE INDEX idx_transaction_account_id ON Transaction(account_id);
CREATE INDEX idx_demography_district_id ON Demography(district_id);


--0--
--setting of serial variables

BEGIN;
--Account
SELECT setval(pg_get_serial_sequence('Account', 'account_id'), 11383);

--Client
SELECT setval(pg_get_serial_sequence('Client', 'client_id'), 13999);

--Disposition
SELECT setval(pg_get_serial_sequence('Disposition', 'disp_id'), 13691);

--Permanent_Order
SELECT setval(pg_get_serial_sequence('Permanent_Order', 'order_id'), 46339);

--Transaction
SELECT setval(pg_get_serial_sequence('Transaction', 'trans_id'), 3682988);

--Loan
SELECT setval(pg_get_serial_sequence('Loan', 'loan_id'), 7309);

--Credit_card
SELECT setval(pg_get_serial_sequence('Credit_Card', 'card_id'), 1248);

COMMIT;



--1--

--This query retrieves all the loans taken by a specific client, 
--along with their account ID, loan ID, amount, duration, 
--monthly payments, and status

SELECT l.account_id , l.loan_id, l.amount, l.duration, l.payments as Monthly_payments, l.status
FROM Loan l
JOIN Disposition d ON l.account_id = d.account_id
WHERE d.client_id = :client_id
ORDER BY l.loan_id;

--2--

--This query retrieves all the credit cards issued to a specific client, 
--along with their card ID, type, and issue date

SELECT card_id, type, issued
FROM Credit_Card
WHERE disp_id IN (
	SELECT disp_id
	FROM Disposition
	WHERE client_id = :client_id
)
ORDER BY card_id;

--3--
--This query will give the total balance available to the client with ID as client_id 
--in all their bank accounts

WITH MAX_Trans(trans_id , account_id) AS (
	SELECT MAX(trans_id) as trans_id , account_id
	FROM Transaction 
	GROUP BY account_id
) 
SELECT SUM(balance) as Balance
FROM Transaction JOIN MAX_Trans 
	ON(Transaction.account_id = MAX_Trans.account_id
		AND MAX_Trans.trans_id = Transaction.trans_id)
	JOIN Disposition 
	ON (Disposition.account_id = Transaction.account_id AND Disposition.client_id = :client_id);


--4--

--This query calculates a credit score for a given client based on their transaction history and 
--loan status. The credit score is based on the client's total credit, total debit, transaction count, 
--loan count, and defaulted loans. The resulting credit score is one of "High Risk", 
--"Very High Risk", "Low Activity", or "Good".

WITH client_transactions AS (
  SELECT 
    t.account_id,
    SUM(CASE WHEN t.type = 'PRIJEM' THEN t.amount ELSE 0 END) AS total_credit,
    SUM(CASE WHEN t.type = 'VYDAJ' THEN t.amount ELSE 0 END) AS total_debit,
    (CASE WHEN t.account_id is NOT NULL THEN COUNT(*) ELSE 0 END) AS transaction_count
  FROM 
    Transaction t
    JOIN Disposition d ON t.account_id = d.account_id
    RIGHT JOIN Client c ON d.client_id = c.client_id
  WHERE 
    c.client_id = :client_id
  GROUP BY 
    t.account_id
),
client_loans AS (
  SELECT 
    l.account_id,
    (CASE WHEN l.account_id is NOT NULL THEN COUNT(*) ELSE 0 END) AS loan_count,
    SUM(CASE WHEN (l.account_id is NULL OR l.status = 'A' OR l.status = 'C') 
    	THEN 0 ELSE 1 END) AS defaulted_loans
  FROM 
    Loan l
    JOIN Disposition d ON l.account_id = d.account_id
    RIGHT JOIN Client c ON d.client_id = c.client_id
  WHERE 
    c.client_id = :client_id
  GROUP BY 
    l.account_id
)
SELECT 
  ct.total_credit,
  ct.total_debit,
  ct.transaction_count,
  cl.loan_count,
  cl.defaulted_loans,
  ct.account_id,
  cl.account_id,
  CASE 
    WHEN cl.defaulted_loans > 0 THEN 'High Risk'
    WHEN ct.total_debit > ct.total_credit THEN 'High Risk'
    WHEN ct.total_debit > 2*ct.total_credit THEN 'Very High Risk'
    WHEN ct.transaction_count < 10 THEN 'Low Activity'
    ELSE 'Good'
  END AS credit_score
FROM 
  client_transactions ct
  FULL OUTER JOIN client_loans cl ON (ct.account_id = cl.account_id)
 ORDER BY ct.account_id,cl.account_id;

--5--

--This query add new loan taken by the client_id on his account_id
INSERT INTO Loan (account_id, date, amount, duration, payments, status)
VALUES (:account_id, CURRENT_DATE, :amount, :duration, :payments, 'A');

--6--
--This query add new a client in the client table
INSERT INTO Client (birth_number,district_id,password_hash)
VALUES  (:birth_number,:district_id,:password_hash);


--7--
--This query add new a order in the Permanent Order table
INSERT INTO Permanent_Order(account_id,bank_to,account_to,amount,k_symbol)
VALUES (:account_id,:'bank_to',:account_to,:amount,:'k_symbol');

--8--
--This query add new a card issued in the Credit Card table
INSERT INTO Credit_Card(disp_id,type,issued)
VALUES (:disp_id,:'type',CURRENT_DATE);

--9--

--This query gives the latest five transaction for a particular account
SELECT *
FROM Transaction
WHERE account_id = :account_id
ORDER BY date DESC
LIMIT 5;

--10--
--This query gives the latest five transaction for a client id
SELECT Disposition.account_id,date,Transaction.amount,Transaction.type,Transaction.operation,
Transaction.k_symbol
FROM Transaction JOIN Disposition ON (Transaction.account_id = Disposition.account_id)
WHERE Disposition.client_id = :client_id 
ORDER BY date DESC,amount,date
LIMIT 5;

--11--
--This query gives the default loan rate of particular client_id

SELECT
  (CASE WHEN COUNT(*)>0 THEN 
   ((COUNT(CASE WHEN l.status = 'B' THEN 1 ELSE NULL END)::FLOAT / COUNT(*)) * 100)
   ELSE 0 END) AS default_rate
FROM
  Loan l
  JOIN Disposition d ON l.account_id = d.account_id
  JOIN Client c ON d.client_id = c.client_id
WHERE
  c.client_id = :client_id;

--12--
--This query gives average balance for a client_id in all his accounts
SELECT AVG(balance)
FROM Transaction
WHERE account_id IN (
	SELECT account_id
	FROM Disposition
	WHERE client_id = :client_id
);

--13--
--This query query list all the accounts of a client_id
SELECT Account.account_id, Account.frequency, Account.date , Disposition.type
FROM Client
JOIN Disposition ON Client.client_id = Disposition.client_id
JOIN Account ON Disposition.account_id = Account.account_id
WHERE Client.client_id = :client_id
ORDER BY account_id;


--14--
--This query insert into the disposition table
INSERT INTO Disposition (client_id, account_id, type)
VALUES (:client_id, :account_id, 'DISPONENT');


--15--
--This query creates a new account for a client_id and insert it into
--Disposition and Account table
BEGIN;
INSERT INTO Account (district_id, frequency, date)
VALUES (:district_id, :frequency, CURRENT_DATE)

INSERT INTO Disposition (client_id, account_id, type)
VALUES (:client_id, (SELECT currval('account_account_id_seq')), 'OWNER');
COMMIT;


--16--
--This query will list all the account linked with a particular bank

SELECT Account.account_id, Account.frequency,Account.date,Client.client_id,
Client.birth_number,Client.district_id, Disposition.type 
FROM Account
JOIN Disposition ON Account.account_id = Disposition.account_id
JOIN Client ON Disposition.client_id = Client.client_id
JOIN Transaction ON Account.account_id = Transaction.account_id
WHERE Transaction.bank = :'bank'
GROUP by Account.account_id,Account.frequency,Account.date,Client.client_id,
Client.birth_number,Client.district_id, Disposition.type ;



--17--

--This will list all the loans linked with a particular account_id
SELECT *
FROM loan
WHERE account_id = :account_id
ORDER by loan_id;

--18--
--This query will list the information about a particular loan
SELECT *
FROM loan
WHERE loan_id = :loan_id;


--19--
--this query gives the current balance of the partcular account_id
SELECT balance 
FROM Transaction 
WHERE account_id = :account_id ORDER BY trans_id DESC LIMIT 1;

--20--


--This query inserts the transaction of given ammount
BEGIN;
INSERT INTO Transaction (account_id, date, type, operation, amount, balance, 
	k_symbol, bank, account)
VALUES (:account_id, CURRENT_DATE, :'type', :'operation', :amount, 
	
	(SELECT 
        CASE 
            WHEN :'type' = 'PRIJEM' THEN 
            (SELECT balance FROM Transaction 
            	WHERE account_id = :account_id ORDER BY trans_id DESC LIMIT 1) + :amount
            WHEN :'type' = 'VYDAJ' THEN 
            (SELECT balance FROM Transaction 
            	WHERE account_id = :account_id ORDER BY trans_id DESC LIMIT 1) - :amount
            ELSE (SELECT balance FROM Transaction
             WHERE account_id = :account_id ORDER BY trans_id DESC LIMIT 1)
        END)
	,:'k_symbol', :'bank', :account);

COMMIT;


--21--
--This query will delete a tuple in loan table

Delete FROM loan where loan_id = :loan_id;

--22--
--This query will delete a tuple in Account table

Delete FROM Account where account_id = :account_id;

--23--
--This query will delete a tuple in Credit_Card table

Delete FROM Credit_Card where card_id = :card_id;

--24--
--This query will delete a tuple in Disposition table

Delete FROM Disposition where disp_id = :disp_id;

--25--
--This query will delete a tuple in Permanent_order table

Delete FROM Permanent_Order where order_id = :order_id;

--26--
--This query will delete a tuple in Trasancation table

Delete FROM Transaction where trans_id = :trans_id;


--27--
--This query list all the defaulted_loans
SELECT loan_id,account_id,date,amount,duration,payments,status
FROM Loan
WHERE loan.status = 'B' or loan.status = 'D'
ORDER by loan_id, status;


--28--
--This query calculates total credit card withdrawal for a card_id
SELECT SUM(amount) 
FROM Transaction 
WHERE operation = 'VYBER KARTOU' 
	AND account_id IN 
		(SELECT account_id 
		 FROM Disposition 
		 WHERE disp_id = (SELECT disp_id 
						  FROM Credit_Card 
						  WHERE card_id = :card_id)
		);

--29--
--This query gives all details abput client district id
SELECT Client.district_id,A2,A3,A4,A5,A6,A7,A8,A9,A10,A11,A12,A13,A14,A15,A16
FROM Client JOIN Demography ON (Client.district_id = Demography.district_id)
WHERE client_id = :client_id;

--30--
--This query gives all details about a client_id 
SELECT A2 as district_name, 
       CASE WHEN LENGTH(birth_number>6) THEN CONCAT('19', SUBSTR(birth_number, 1, 2), '-', SUBSTR(birth_number, 3, 2), '-', SUBSTR(birth_number, 8, 2)) 
            ELSE CONCAT('19', SUBSTR(birth_number, 1, 2), '-', SUBSTR(birth_number, 3, 2), '-', SUBSTR(birth_number, 5, 2)) 
       END AS birth_date, 
       CASE WHEN LENGTH(birth_number>6) THEN 'Female' ELSE 'Male' END AS gender 
FROM Client JOIN Demography ON (Client.district_id = Demography.district_id)
WHERE client_id = :client_id;
