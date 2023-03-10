BEGIN TRANSACTION;

COPY Demography FROM '/home/sam/postgres/Archives/data_berka/district.asc' WITH CSV HEADER DELIMITER AS ';';
COPY Account FROM '/home/sam/postgres/Archives/data_berka/account.asc' WITH CSV HEADER DELIMITER AS ';';
COPY Client FROM '/home/sam/postgres/Archives/data_berka/client_with_password.asc' WITH CSV HEADER DELIMITER AS ';';
COPY Disposition FROM '/home/sam/postgres/Archives/data_berka/disp.asc' WITH CSV HEADER DELIMITER AS ';';
COPY Permanent_Order FROM '/home/sam/postgres/Archives/data_berka/order.asc' WITH CSV HEADER DELIMITER AS ';';
COPY Transaction FROM '/home/sam/postgres/Archives/data_berka/trans.asc' WITH CSV HEADER DELIMITER AS ';';
COPY Loan FROM '/home/sam/postgres/Archives/data_berka/loan.asc' WITH CSV HEADER DELIMITER AS ';';
COPY Credit_Card FROM '/home/sam/postgres/Archives/data_berka/card.asc' WITH CSV HEADER DELIMITER AS ';';

END TRANSACTION;
