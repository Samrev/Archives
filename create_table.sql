BEGIN TRANSACTION;

DROP TABLE IF EXISTS Account CASCADE;
DROP TABLE IF EXISTS Client CASCADE;
DROP TABLE IF EXISTS Disposition CASCADE;
DROP TABLE IF EXISTS Permanent_Order CASCADE;
DROP TABLE IF EXISTS Transaction CASCADE;
DROP TABLE IF EXISTS Loan CASCADE;
DROP TABLE IF EXISTS Credit_Card CASCADE;
DROP TABLE IF EXISTS Demography CASCADE;

-- essentially a read only table
CREATE TABLE Demography (
	district_id int NOT NULL, 
	A2 varchar(20),
	A3 varchar(20),
	A4 int ,
	A5 int,
	A6 int,
	A7 int,
	A8 int,
	A9 int,
	A10 numeric(4,1),
	A11 int,
	A12 numeric(4,2),
	A13 numeric(4,2),
	A14 int,
	A15 int,
	A16 int,
	PRIMARY KEY (district_id)
);

REVOKE INSERT, UPDATE, DELETE ON Demography FROM PUBLIC;	-- make demography table read-only


DROP TYPE IF EXISTS account_frequency;
CREATE TYPE account_frequency AS ENUM ('POPLATEK MESICNE', 'POPLATEK TYDNE', 'POPLATEK PO OBRATU');
CREATE TABLE Account (
	account_id SERIAL PRIMARY KEY,
	district_id int NOT NULL,
	frequency account_frequency NOT NULL,
	date date NOT NULL,
	CONSTRAINT fk_account_districtid
		FOREIGN KEY(district_id)
		REFERENCES Demography(district_id)
);

CREATE TABLE Client(
	client_id SERIAL,
	birth_number varchar(8) NOT NULL,
	district_id int NOT NULL,
	password_hash varchar(72) NOT NULL,
	PRIMARY KEY (client_id),
	CONSTRAINT fk_client_districtid
		FOREIGN KEY (district_id)
		REFERENCES Demography(district_id)
);

CREATE TABLE Disposition (
	disp_id SERIAL PRIMARY KEY,
	client_id int NOT NULL,
	account_id int NOT NULL,
	type varchar(9) NOT NULL CHECK(type IN ('OWNER', 'DISPONENT')),
	CONSTRAINT fk_disp_clientid
		FOREIGN KEY (client_id)
		REFERENCES Client(client_id)
		ON DELETE CASCADE,
	CONSTRAINT fk_disp_accountid
		FOREIGN KEY (account_id)
		REFERENCES Account(account_id)
		ON DELETE CASCADE,
	CONSTRAINT uq_disp_client_account
		UNIQUE (client_id, account_id)
);

-- information for all the payment orders (debits only)
CREATE TABLE Permanent_Order (
	order_id SERIAL,
	account_id int NOT NULL,
	bank_to varchar(2) NOT NULL,
	account_to int NOT NULL,
	amount numeric(7,2) NOT NULL CHECK (amount > 0), -- transactions greater than 1M not allowed and must be positive
	k_symbol varchar(8),
	PRIMARY KEY (order_id),
	CONSTRAINT fk_order_accountid
		FOREIGN KEY (account_id)
		REFERENCES Account(account_id) ON DELETE CASCADE
);

-- payments credited, balances are given in this relation
CREATE TABLE Transaction (
	trans_id SERIAL,
	account_id int NOT NULL,
	date date NOT NULL,
	type varchar(14), -- NOT NULL CHECK (type IN ('PRIJEM', 'VYDAJ')),
	operation varchar(14), -- NOT NULL CHECK (operation IN ('VYBER KARTOU', 'VKLAD', 'PREVOD Z UCTU', 'VYBER', 'PREVOD NA UCET'))
	amount numeric(7, 2) NOT NULL CHECK(amount >= 0), -- transactions greater than 1M not allowed and must be positive
	balance numeric(8, 2) NOT NULL, -- total balance after transaction
	k_symbol varchar(11),
	bank varchar(2),
	account int,
	PRIMARY KEY (trans_id),
	CONSTRAINT fk_trans_accountid
		FOREIGN KEY (account_id)
		REFERENCES Account(account_id) ON DELETE CASCADE
);

CREATE TABLE Loan (
	loan_id SERIAL,
	account_id int NOT NULL UNIQUE, -- unique
	date date NOT NULL, -- date when loan was granted 
	amount numeric(8,2) NOT NULL CHECK(amount > 0), -- amount greater than 10M not allowed
	duration int, -- duration of the loan in months
	payments numeric(7, 2), -- monthly payments
	status varchar(1) CHECK (status IN ('A', 'B', 'C', 'D')), -- status of paying off the loan
	PRIMARY KEY (loan_id),
	CONSTRAINT fk_loan_accountid
		FOREIGN KEY (account_id)
		REFERENCES Account(account_id) ON DELETE CASCADE
);

CREATE TABLE Credit_Card (
	card_id SERIAL,
	disp_id int NOT NULL,
	type varchar(7) NOT NULL CHECK (type IN ('junior', 'classic', 'gold')),
	issued date NOT NULL,
	PRIMARY KEY (card_id),
	CONSTRAINT fk_card_dispid
		FOREIGN KEY (disp_id)
		REFERENCES Disposition(disp_id) ON DELETE CASCADE
);

END TRANSACTION;

