-- Library Management System Database
-- This SQL script creates a complete database for a library management system

DROP DATABASE IF EXISTS library_db;
CREATE DATABASE library_db;
USE library_db;

-- Users table (library members and staff)
CREATE TABLE users (
    user_id INT AUTO_INCREMENT PRIMARY KEY,
    first_name VARCHAR(50) NOT NULL,
    last_name VARCHAR(50) NOT NULL,
    email VARCHAR(100) UNIQUE NOT NULL,
    phone VARCHAR(20),
    address TEXT,
    user_type ENUM('member', 'librarian', 'admin') NOT NULL,
    membership_date DATE NOT NULL,
    password_hash VARCHAR(255) NOT NULL,
    account_status ENUM('active', 'suspended', 'terminated') DEFAULT 'active',
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP
);

-- Books table
CREATE TABLE books (
    book_id INT AUTO_INCREMENT PRIMARY KEY,
    isbn VARCHAR(20) UNIQUE NOT NULL,
    title VARCHAR(255) NOT NULL,
    author VARCHAR(100) NOT NULL,
    publisher VARCHAR(100),
    publication_year INT,
    genre VARCHAR(50),
    language VARCHAR(30),
    page_count INT,
    description TEXT,
    cover_image_url VARCHAR(255),
    total_copies INT NOT NULL DEFAULT 1,
    available_copies INT NOT NULL DEFAULT 1,
    location VARCHAR(50),
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    CHECK (available_copies <= total_copies)
);

-- Book copies table (for tracking individual copies)
CREATE TABLE book_copies (
    copy_id INT AUTO_INCREMENT PRIMARY KEY,
    book_id INT NOT NULL,
    barcode VARCHAR(50) UNIQUE NOT NULL,
    status ENUM('available', 'checked_out', 'lost', 'damaged', 'in_repair') NOT NULL DEFAULT 'available',
    acquisition_date DATE,
    acquisition_cost DECIMAL(10,2),
    notes TEXT,
    FOREIGN KEY (book_id) REFERENCES books(book_id) ON DELETE CASCADE
);

-- Loans table (book checkouts)
CREATE TABLE loans (
    loan_id INT AUTO_INCREMENT PRIMARY KEY,
    copy_id INT NOT NULL,
    user_id INT NOT NULL,
    checkout_date DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
    due_date DATETIME NOT NULL,
    return_date DATETIME,
    status ENUM('active', 'returned', 'overdue', 'lost') NOT NULL DEFAULT 'active',
    late_fee DECIMAL(10,2) DEFAULT 0.00,
    FOREIGN KEY (copy_id) REFERENCES book_copies(copy_id),
    FOREIGN KEY (user_id) REFERENCES users(user_id),
    CHECK (due_date > checkout_date),
    CHECK (return_date IS NULL OR return_date >= checkout_date)
);

-- Reservations table (holds)
CREATE TABLE reservations (
    reservation_id INT AUTO_INCREMENT PRIMARY KEY,
    book_id INT NOT NULL,
    user_id INT NOT NULL,
    reservation_date DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
    expiration_date DATETIME NOT NULL,
    status ENUM('pending', 'fulfilled', 'canceled', 'expired') NOT NULL DEFAULT 'pending',
    FOREIGN KEY (book_id) REFERENCES books(book_id),
    FOREIGN KEY (user_id) REFERENCES users(user_id),
    CHECK (expiration_date > reservation_date)
);

-- Fines table
CREATE TABLE fines (
    fine_id INT AUTO_INCREMENT PRIMARY KEY,
    user_id INT NOT NULL,
    loan_id INT,
    amount DECIMAL(10,2) NOT NULL,
    reason ENUM('late_return', 'damage', 'lost_book', 'other') NOT NULL,
    issue_date DATE NOT NULL,
    payment_date DATE,
    status ENUM('unpaid', 'paid', 'waived') NOT NULL DEFAULT 'unpaid',
    notes TEXT,
    FOREIGN KEY (user_id) REFERENCES users(user_id),
    FOREIGN KEY (loan_id) REFERENCES loans(loan_id)
);

-- Authors table (for many-to-many relationship with books)
CREATE TABLE authors (
    author_id INT AUTO_INCREMENT PRIMARY KEY,
    name VARCHAR(100) NOT NULL,
    biography TEXT,
    birth_date DATE,
    death_date DATE,
    nationality VARCHAR(50)
);

-- Book-Author relationship (many-to-many)
CREATE TABLE book_authors (
    book_id INT NOT NULL,
    author_id INT NOT NULL,
    PRIMARY KEY (book_id, author_id),
    FOREIGN KEY (book_id) REFERENCES books(book_id) ON DELETE CASCADE,
    FOREIGN KEY (author_id) REFERENCES authors(author_id) ON DELETE CASCADE
);

-- Categories table
CREATE TABLE categories (
    category_id INT AUTO_INCREMENT PRIMARY KEY,
    name VARCHAR(50) UNIQUE NOT NULL,
    description TEXT,
    parent_category_id INT,
    FOREIGN KEY (parent_category_id) REFERENCES categories(category_id) ON DELETE SET NULL
);

-- Book-Category relationship (many-to-many)
CREATE TABLE book_categories (
    book_id INT NOT NULL,
    category_id INT NOT NULL,
    PRIMARY KEY (book_id, category_id),
    FOREIGN KEY (book_id) REFERENCES books(book_id) ON DELETE CASCADE,
    FOREIGN KEY (category_id) REFERENCES categories(category_id) ON DELETE CASCADE
);

-- Audit log table
CREATE TABLE audit_log (
    log_id INT AUTO_INCREMENT PRIMARY KEY,
    action_type ENUM('create', 'update', 'delete', 'login', 'logout', 'checkout', 'return') NOT NULL,
    table_name VARCHAR(50) NOT NULL,
    record_id INT,
    user_id INT,
    action_details TEXT,
    ip_address VARCHAR(50),
    action_timestamp TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    FOREIGN KEY (user_id) REFERENCES users(user_id) ON DELETE SET NULL
);

-- Create indexes for performance
CREATE INDEX idx_books_title ON books(title);
CREATE INDEX idx_books_author ON books(author);
CREATE INDEX idx_loans_user ON loans(user_id);
CREATE INDEX idx_loans_status ON loans(status);
CREATE INDEX idx_loans_due_date ON loans(due_date);
CREATE INDEX idx_fines_user ON fines(user_id);
CREATE INDEX idx_fines_status ON fines(status);

-- Insert sample data into Library Management System

-- Insert users (members, librarians, and admins)
INSERT INTO users (first_name, last_name, email, phone, address, user_type, membership_date, password_hash, account_status) VALUES
('John', 'Smith', 'john.smith@email.com', '555-0101', '123 Main St, Anytown', 'member', '2022-01-15', 'hashed_password_1', 'active'),
('Sarah', 'Johnson', 'sarah.j@email.com', '555-0102', '456 Oak Ave, Somewhere', 'member', '2022-02-20', 'hashed_password_2', 'active'),
('Michael', 'Williams', 'michael.w@email.com', '555-0103', '789 Pine Rd, Nowhere', 'member', '2022-03-10', 'hashed_password_3', 'active'),
('Emily', 'Brown', 'emily.b@email.com', '555-0104', '321 Elm St, Anywhere', 'librarian', '2021-11-05', 'hashed_password_4', 'active'),
('David', 'Jones', 'david.j@email.com', '555-0105', '654 Maple Dr, Everywhere', 'admin', '2021-09-12', 'hashed_password_5', 'active'),
('Jessica', 'Garcia', 'jessica.g@email.com', '555-0106', '987 Cedar Ln, Somewhere', 'member', '2022-04-05', 'hashed_password_6', 'suspended'),
('Robert', 'Miller', 'robert.m@email.com', '555-0107', '135 Birch Blvd, Nowhere', 'member', '2022-05-15', 'hashed_password_7', 'active'),
('Jennifer', 'Davis', 'jennifer.d@email.com', '555-0108', '246 Spruce Way, Anywhere', 'librarian', '2021-12-01', 'hashed_password_8', 'active'),
('Thomas', 'Rodriguez', 'thomas.r@email.com', '555-0109', '369 Willow Cir, Everywhere', 'member', '2022-06-20', 'hashed_password_9', 'active'),
('Lisa', 'Martinez', 'lisa.m@email.com', '555-0110', '159 Aspen Ct, Somewhere', 'member', '2022-07-01', 'hashed_password_10', 'active');

-- Insert authors
INSERT INTO authors (name, biography, birth_date, death_date, nationality) VALUES
('J.K. Rowling', 'British author best known for the Harry Potter series', '1965-07-31', NULL, 'British'),
('Stephen King', 'American author of horror, supernatural fiction, suspense, and fantasy novels', '1947-09-21', NULL, 'American'),
('George R.R. Martin', 'American novelist and short-story writer in the fantasy, horror, and science fiction genres', '1948-09-20', NULL, 'American'),
('Agatha Christie', 'English writer known for her detective novels', '1890-09-15', '1976-01-12', 'British'),
('J.R.R. Tolkien', 'English writer, poet, philologist, and academic, best known for The Hobbit and The Lord of the Rings', '1892-01-03', '1973-09-02', 'British'),
('Harper Lee', 'American novelist famous for To Kill a Mockingbird', '1926-04-28', '2016-02-19', 'American'),
('Dan Brown', 'American author best known for his thriller novels', '1964-06-22', NULL, 'American'),
('Jane Austen', 'English novelist known for romantic fiction', '1775-12-16', '1817-07-18', 'British'),
('Mark Twain', 'American writer, humorist, entrepreneur, publisher, and lecturer', '1835-11-30', '1910-04-21', 'American'),
('Ernest Hemingway', 'American journalist, novelist, and short-story writer', '1899-07-21', '1961-07-02', 'American');

-- Insert categories
INSERT INTO categories (name, description, parent_category_id) VALUES
('Fiction', 'Imaginary stories and narratives', NULL),
('Non-Fiction', 'Factual stories and information', NULL),
('Science Fiction', 'Fiction dealing with futuristic concepts', 1),
('Fantasy', 'Fiction with magical or supernatural elements', 1),
('Mystery', 'Fiction dealing with solving crimes', 1),
('Biography', 'Non-fiction about people''s lives', 2),
('History', 'Non-fiction about past events', 2),
('Romance', 'Fiction focusing on romantic relationships', 1),
('Horror', 'Fiction intended to scare or frighten', 1),
('Thriller', 'Fiction with intense excitement and suspense', 1);

-- Insert books
INSERT INTO books (isbn, title, author, publisher, publication_year, genre, language, page_count, description, total_copies, available_copies, location) VALUES
('9780747532743', 'Harry Potter and the Philosopher''s Stone', 'J.K. Rowling', 'Bloomsbury', 1997, 'Fantasy', 'English', 223, 'First book in the Harry Potter series', 5, 3, 'Fiction A'),
('9780747538486', 'Harry Potter and the Chamber of Secrets', 'J.K. Rowling', 'Bloomsbury', 1998, 'Fantasy', 'English', 251, 'Second book in the Harry Potter series', 4, 2, 'Fiction A'),
('9780747542155', 'Harry Potter and the Prisoner of Azkaban', 'J.K. Rowling', 'Bloomsbury', 1999, 'Fantasy', 'English', 317, 'Third book in the Harry Potter series', 3, 1, 'Fiction A'),
('9780747546245', 'Harry Potter and the Goblet of Fire', 'J.K. Rowling', 'Bloomsbury', 2000, 'Fantasy', 'English', 636, 'Fourth book in the Harry Potter series', 3, 3, 'Fiction A'),
('9780747551003', 'Harry Potter and the Order of the Phoenix', 'J.K. Rowling', 'Bloomsbury', 2003, 'Fantasy', 'English', 766, 'Fifth book in the Harry Potter series', 2, 1, 'Fiction A'),
('9780747581086', 'Harry Potter and the Half-Blood Prince', 'J.K. Rowling', 'Bloomsbury', 2005, 'Fantasy', 'English', 607, 'Sixth book in the Harry Potter series', 2, 2, 'Fiction A'),
('9780545010221', 'Harry Potter and the Deathly Hallows', 'J.K. Rowling', 'Bloomsbury', 2007, 'Fantasy', 'English', 607, 'Seventh book in the Harry Potter series', 2, 1, 'Fiction A'),
('9781501142970', 'It', 'Stephen King', 'Scribner', 1986, 'Horror', 'English', 1138, 'A story about a shape-shifting monster', 3, 2, 'Fiction B'),
('9781501175466', 'The Shining', 'Stephen King', 'Doubleday', 1977, 'Horror', 'English', 447, 'A haunted hotel story', 2, 1, 'Fiction B'),
('9780553103540', 'A Game of Thrones', 'George R.R. Martin', 'Bantam Books', 1996, 'Fantasy', 'English', 694, 'First book in A Song of Ice and Fire series', 4, 2, 'Fiction C'),
('9780007113804', 'Murder on the Orient Express', 'Agatha Christie', 'Collins Crime Club', 1934, 'Mystery', 'English', 256, 'Hercule Poirot solves a murder on a train', 3, 3, 'Fiction D'),
('9780007136551', 'The Hobbit', 'J.R.R. Tolkien', 'George Allen & Unwin', 1937, 'Fantasy', 'English', 310, 'Bilbo Baggins goes on an adventure', 3, 2, 'Fiction E'),
('9780061120084', 'To Kill a Mockingbird', 'Harper Lee', 'J. B. Lippincott & Co.', 1960, 'Fiction', 'English', 281, 'A story of racial injustice in the American South', 4, 3, 'Fiction F'),
('9780385504201', 'The Da Vinci Code', 'Dan Brown', 'Doubleday', 2003, 'Thriller', 'English', 454, 'A murder mystery involving secret societies', 3, 1, 'Fiction G'),
('9780141439518', 'Pride and Prejudice', 'Jane Austen', 'T. Egerton, Whitehall', 1813, 'Romance', 'English', 279, 'A romantic novel of manners', 2, 2, 'Fiction H'),
('9780486415864', 'Adventures of Huckleberry Finn', 'Mark Twain', 'Chatto & Windus', 1884, 'Fiction', 'English', 366, 'A story of a boy''s journey down the Mississippi', 2, 1, 'Fiction I'),
('9780684801469', 'The Old Man and the Sea', 'Ernest Hemingway', 'Charles Scribner''s Sons', 1952, 'Fiction', 'English', 127, 'Story of an old fisherman''s struggle', 3, 3, 'Fiction J');

-- Insert book copies
INSERT INTO book_copies (book_id, barcode, status, acquisition_date, acquisition_cost) VALUES
(1, 'HPPS001', 'available', '2020-01-10', 12.99),
(1, 'HPPS002', 'available', '2020-01-10', 12.99),
(1, 'HPPS003', 'checked_out', '2020-01-10', 12.99),
(1, 'HPPS004', 'available', '2021-03-15', 14.99),
(1, 'HPPS005', 'checked_out', '2021-03-15', 14.99),
(2, 'HPCS001', 'available', '2020-02-05', 13.99),
(2, 'HPCS002', 'checked_out', '2020-02-05', 13.99),
(2, 'HPCS003', 'available', '2021-04-20', 15.99),
(2, 'HPCS004', 'in_repair', '2021-04-20', 15.99),
(3, 'HPPA001', 'checked_out', '2020-03-12', 14.99),
(3, 'HPPA002', 'available', '2021-05-25', 16.99),
(3, 'HPPA003', 'lost', '2021-05-25', 16.99),
(4, 'HPGF001', 'available', '2020-04-18', 15.99),
(4, 'HPGF002', 'available', '2020-04-18', 15.99),
(4, 'HPGF003', 'available', '2021-06-30', 17.99),
(5, 'HPOP001', 'checked_out', '2020-05-22', 16.99),
(5, 'HPOP002', 'available', '2021-07-15', 18.99),
(6, 'HPHB001', 'available', '2020-06-10', 17.99),
(6, 'HPHB002', 'available', '2021-08-20', 19.99),
(7, 'HPDH001', 'checked_out', '2020-07-05', 18.99),
(7, 'HPDH002', 'available', '2021-09-25', 20.99),
(8, 'IT001', 'available', '2019-08-12', 10.99),
(8, 'IT002', 'checked_out', '2019-08-12', 10.99),
(8, 'IT003', 'available', '2020-10-15', 12.99),
(9, 'SHN001', 'checked_out', '2019-09-20', 11.99),
(9, 'SHN002', 'available', '2020-11-10', 13.99),
(10, 'GOT001', 'available', '2019-10-25', 12.99),
(10, 'GOT002', 'checked_out', '2019-10-25', 12.99),
(10, 'GOT003', 'available', '2020-12-05', 14.99),
(10, 'GOT004', 'damaged', '2020-12-05', 14.99),
(11, 'MOE001', 'available', '2019-11-30', 9.99),
(11, 'MOE002', 'available', '2021-01-15', 11.99),
(11, 'MOE003', 'available', '2021-01-15', 11.99),
(12, 'HOB001', 'available', '2019-12-10', 10.99),
(12, 'HOB002', 'checked_out', '2021-02-20', 12.99),
(12, 'HOB003', 'available', '2021-02-20', 12.99),
(13, 'TKM001', 'available', '2020-01-05', 8.99),
(13, 'TKM002', 'available', '2021-03-10', 10.99),
(13, 'TKM003', 'checked_out', '2021-03-10', 10.99),
(13, 'TKM004', 'available', '2021-03-10', 10.99),
(14, 'DVC001', 'checked_out', '2020-02-15', 11.99),
(14, 'DVC002', 'available', '2021-04-25', 13.99),
(14, 'DVC003', 'in_repair', '2021-04-25', 13.99),
(15, 'PAP001', 'available', '2020-03-20', 7.99),
(15, 'PAP002', 'available', '2021-05-30', 9.99),
(16, 'AHF001', 'checked_out', '2020-04-25', 8.99),
(16, 'AHF002', 'available', '2021-06-15', 10.99),
(17, 'OMS001', 'available', '2020-05-30', 6.99),
(17, 'OMS002', 'available', '2021-07-20', 8.99),
(17, 'OMS003', 'available', '2021-07-20', 8.99);

-- Insert book-author relationships
INSERT INTO book_authors (book_id, author_id) VALUES
(1, 1), (2, 1), (3, 1), (4, 1), (5, 1), (6, 1), (7, 1),
(8, 2), (9, 2),
(10, 3),
(11, 4),
(12, 5),
(13, 6),
(14, 7),
(15, 8),
(16, 9),
(17, 10);

-- Insert book-category relationships
INSERT INTO book_categories (book_id, category_id) VALUES
(1, 4), (2, 4), (3, 4), (4, 4), (5, 4), (6, 4), (7, 4),
(8, 9), (9, 9),
(10, 4),
(11, 5),
(12, 4),
(13, 1),
(14, 10),
(15, 8),
(16, 1),
(17, 1);

-- Insert loans
INSERT INTO loans (copy_id, user_id, checkout_date, due_date, return_date, status, late_fee) VALUES
(3, 1, '2023-01-10 14:30:00', '2023-01-24 14:30:00', '2023-01-22 10:15:00', 'returned', 0.00),
(5, 2, '2023-01-15 11:20:00', '2023-01-29 11:20:00', NULL, 'active', 0.00),
(7, 3, '2023-01-18 16:45:00', '2023-02-01 16:45:00', '2023-02-03 09:30:00', 'returned', 2.00),
(10, 1, '2023-02-05 10:10:00', '2023-02-19 10:10:00', NULL, 'active', 0.00),
(12, 6, '2023-02-10 13:25:00', '2023-02-24 13:25:00', '2023-02-28 14:40:00', 'returned', 4.00),
(14, 7, '2023-02-15 15:50:00', '2023-03-01 15:50:00', NULL, 'active', 0.00),
(17, 9, '2023-02-20 09:30:00', '2023-03-06 09:30:00', NULL, 'active', 0.00),
(20, 3, '2023-03-01 14:15:00', '2023-03-15 14:15:00', NULL, 'active', 0.00),
(23, 2, '2023-03-05 11:40:00', '2023-03-19 11:40:00', '2023-03-18 16:20:00', 'returned', 0.00),
(25, 1, '2023-03-10 10:05:00', '2023-03-24 10:05:00', NULL, 'active', 0.00),
(28, 7, '2023-03-15 13:30:00', '2023-03-29 13:30:00', '2023-03-30 10:45:00', 'returned', 1.00),
(30, 9, '2023-03-20 16:55:00', '2023-04-03 16:55:00', NULL, 'active', 0.00),
(33, 10, '2023-03-25 09:20:00', '2023-04-08 09:20:00', NULL, 'active', 0.00),
(36, 6, '2023-04-01 14:45:00', '2023-04-15 14:45:00', '2023-04-16 11:10:00', 'returned', 1.00),
(39, 3, '2023-04-05 12:10:00', '2023-04-19 12:10:00', NULL, 'active', 0.00);

-- Insert reservations
INSERT INTO reservations (book_id, user_id, reservation_date, expiration_date, status) VALUES
(1, 3, '2023-01-05 10:00:00', '2023-01-12 10:00:00', 'fulfilled'),
(3, 5, '2023-01-12 14:30:00', '2023-01-19 14:30:00', 'expired'),
(5, 7, '2023-02-01 11:15:00', '2023-02-08 11:15:00', 'fulfilled'),
(7, 2, '2023-02-10 16:40:00', '2023-02-17 16:40:00', 'canceled'),
(9, 4, '2023-02-15 09:25:00', '2023-02-22 09:25:00', 'fulfilled'),
(11, 8, '2023-03-05 13:50:00', '2023-03-12 13:50:00', 'expired'),
(13, 10, '2023-03-10 10:35:00', '2023-03-17 10:35:00', 'fulfilled'),
(15, 1, '2023-03-15 15:00:00', '2023-03-22 15:00:00', 'canceled'),
(17, 3, '2023-04-01 12:45:00', '2023-04-08 12:45:00', 'pending');

-- Insert fines
INSERT INTO fines (user_id, loan_id, amount, reason, issue_date, payment_date, status) VALUES
(3, 3, 2.00, 'late_return', '2023-02-04', '2023-02-05', 'paid'),
(6, 5, 4.00, 'late_return', '2023-02-25', '2023-02-28', 'paid'),
(7, 11, 1.00, 'late_return', '2023-03-30', NULL, 'unpaid'),
(10, 13, 1.00, 'late_return', '2023-04-16', '2023-04-17', 'paid'),
(1, NULL, 25.00, 'lost_book', '2023-03-01', NULL, 'unpaid'),
(2, NULL, 15.00, 'damage', '2023-02-10', '2023-02-15', 'paid');

-- Insert audit log entries
INSERT INTO audit_log (action_type, table_name, record_id, user_id, action_details, ip_address) VALUES
('login', 'users', NULL, 1, 'User logged in', '192.168.1.100'),
('checkout', 'loans', 1, 4, 'Book checked out', '192.168.1.101'),
('login', 'users', NULL, 4, 'User logged in', '192.168.1.101'),
('checkout', 'loans', 2, 4, 'Book checked out', '192.168.1.101'),
('login', 'users', NULL, 5, 'Admin logged in', '192.168.1.102'),
('update', 'books', 1, 5, 'Updated book details', '192.168.1.102'),
('login', 'users', NULL, 4, 'User logged in', '192.168.1.101'),
('checkout', 'loans', 3, 4, 'Book checked out', '192.168.1.101'),
('return', 'loans', 1, 4, 'Book returned', '192.168.1.101'),
('login', 'users', NULL, 1, 'User logged in', '192.168.1.100'),
('checkout', 'loans', 4, 4, 'Book checked out', '192.168.1.101'),
('login', 'users', NULL, 6, 'User logged in', '192.168.1.103'),
('checkout', 'loans', 5, 4, 'Book checked out', '192.168.1.101'),
('login', 'users', NULL, 7, 'User logged in', '192.168.1.104'),
('checkout', 'loans', 6, 4, 'Book checked out', '192.168.1.101'),
('login', 'users', NULL, 9, 'User logged in', '192.168.1.105'),
('checkout', 'loans', 7, 4, 'Book checked out', '192.168.1.101'),
('login', 'users', NULL, 3, 'User logged in', '192.168.1.106'),
('checkout', 'loans', 8, 4, 'Book checked out', '192.168.1.101'),
('login', 'users', NULL, 2, 'User logged in', '192.168.1.107'),
('checkout', 'loans', 9, 4, 'Book checked out', '192.168.1.101'),
('return', 'loans', 3, 4, 'Book returned', '192.168.1.101'),
('login', 'users', NULL, 1, 'User logged in', '192.168.1.100'),
('checkout', 'loans', 10, 4, 'Book checked out', '192.168.1.101'),
('login', 'users', NULL, 7, 'User logged in', '192.168.1.104'),
('checkout', 'loans', 11, 4, 'Book checked out', '192.168.1.101'),
('return', 'loans', 5, 4, 'Book returned', '192.168.1.101'),
('login', 'users', NULL, 9, 'User logged in', '192.168.1.105'),
('checkout', 'loans', 12, 4, 'Book checked out', '192.168.1.101'),
('login', 'users', NULL, 10, 'User logged in', '192.168.1.108'),
('checkout', 'loans', 13, 4, 'Book checked out', '192.168.1.101'),
('login', 'users', NULL, 6, 'User logged in', '192.168.1.103'),
('checkout', 'loans', 14, 4, 'Book checked out', '192.168.1.101'),
('return', 'loans', 11, 4, 'Book returned', '192.168.1.101'),
('login', 'users', NULL, 3, 'User logged in', '192.168.1.106'),
('checkout', 'loans', 15, 4, 'Book checked out', '192.168.1.101'),
('return', 'loans', 14, 4, 'Book returned', '192.168.1.101');

-- Update book available copies count based on current loans and copies
UPDATE books b
SET available_copies = (
    SELECT COUNT(*) 
    FROM book_copies bc 
    WHERE bc.book_id = b.book_id 
    AND bc.status = 'available'
);
-- ===========================
-- Create Users and Grant Roles
-- For Library Management System
-- PostgreSQL-compatible version
-- ===========================

-- 1. Create Users
CREATE USER librarian_user WITH PASSWORD 'librarian_password';
CREATE USER admin_user WITH PASSWORD 'admin_password';
CREATE USER regular_user WITH PASSWORD 'user_password';

-- 2. Grant Privileges

-- Librarian: Full control on all tables (but not a superuser)
GRANT SELECT, INSERT, UPDATE, DELETE
ON ALL TABLES IN SCHEMA public
TO librarian_user;

-- Admin: Superuser privileges
GRANT ALL PRIVILEGES ON DATABASE library_db TO admin_user;
ALTER USER admin_user WITH SUPERUSER;

-- Regular User: Limited access
-- Can read book info, borrow/return books, but not alter users or books
GRANT SELECT ON public.Books TO regular_user;
GRANT SELECT, INSERT, UPDATE ON public.Borrow TO regular_user;
GRANT SELECT ON public.Users TO regular_user;

-- Optional: Grant usage on the schema
GRANT USAGE ON SCHEMA public TO librarian_user, admin_user, regular_user;

-- Optional: Ensure future tables are accessible
ALTER DEFAULT PRIVILEGES IN SCHEMA public
GRANT SELECT, INSERT, UPDATE, DELETE ON TABLES TO librarian_user;
ALTER DEFAULT PRIVILEGES IN SCHEMA public
GRANT SELECT, INSERT, UPDATE ON TABLES TO regular_user;
FLUSH PRIVILEGES;
