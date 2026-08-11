-- CMPT-354 Library Database - Step 5 seed data

PRAGMA foreign_keys = ON;

BEGIN;

INSERT INTO Person (person_id, first_name, last_name, email, phone, date_of_birth, address) VALUES
    (1,  'Priya',  'Sharma',   'priya.sharma@example.com',   '604-555-0101', '1988-03-14', '345 Main Street, Vancouver'),
    (2,  'Jordan', 'Lee',      'jordan.lee@example.com',     '604-555-0102', '1992-11-02', '1188 Robson Street, Vancouver'),
    (3,  'Amelia', 'Wong',     'amelia.wong@example.com',    '604-555-0103', '1979-07-25', '620 Commercial Drive, Vancouver'),
    (4,  'Noah',   'Patel',    'noah.patel@example.com',     '604-555-0104', '2001-01-19', '901 Granville Street, Vancouver'),
    (5,  'Sofia',  'Martinez', 'sofia.martinez@example.com', '604-555-0105', '1995-09-08', '77 East 12th Avenue, Vancouver'),
    (6,  'Ethan',  'Brown',    'ethan.brown@example.com',    '604-555-0106', '2005-05-11', '2100 Kingsway, Vancouver'),
    (7,  'Mei',    'Tanaka',   'mei.tanaka@example.com',     '604-555-0107', '1990-12-30', '1600 Nanaimo Street, Vancouver'),
    (8,  'Lucas',  'Johnson',  'lucas.johnson@example.com',  '604-555-0108', '1985-06-21', '480 West 8th Avenue, Vancouver'),
    (9,  'Aisha',  'Williams', 'aisha.williams@example.com', '604-555-0109', '2003-02-28', '55 Fraser Street, Vancouver'),
    (10, 'Daniel', 'Kim',      'daniel.kim@example.com',     '604-555-0110', '1998-10-16', '1033 Davie Street, Vancouver'),
    (11, 'Grace',  'Thompson', 'grace.thompson@example.com', '604-555-0111', '1982-04-04', '2900 Oak Street, Vancouver'),
    (12, 'Oliver', 'Singh',    'oliver.singh@example.com',   '604-555-0112', '1991-08-17', '1888 Broadway, Vancouver'),
    (13, 'Harper', 'Wilson',   'harper.wilson@example.com',  '604-555-0113', '1997-02-13', '760 East 15th Avenue, Vancouver'),
    (14, 'Benjamin','Garcia',  'ben.garcia@example.com',     '604-555-0114', '1989-11-23', '420 Pender Street, Vancouver'),
    (15, 'Chloe',  'Nguyen',   'chloe.nguyen@example.com',   '604-555-0115', '1996-06-05', '1300 Burrard Street, Vancouver');

INSERT INTO Member (person_id, card_number, member_since, card_status) VALUES
    (1,  'VPL-000001', '2019-04-12', 'Active'),
    (2,  'VPL-000002', '2020-09-18', 'Active'),
    (3,  'VPL-000003', '2018-02-05', 'Active'),
    (4,  'VPL-000004', '2022-01-21', 'Active'),
    (5,  'VPL-000005', '2021-07-30', 'Active'),
    (6,  'VPL-000006', '2023-05-16', 'Active'),
    (7,  'VPL-000007', '2017-11-08', 'Active'),
    (8,  'VPL-000008', '2016-03-19', 'Active'),
    (9,  'VPL-000009', '2024-02-14', 'Active'),
    (10, 'VPL-000010', '2020-12-02', 'Suspended');

INSERT INTO Staff (person_id, role, hire_date, salary, supervisor_id) VALUES
    (1,  'Manager',   '2017-06-01', 92000.00, NULL);
INSERT INTO Staff (person_id, role, hire_date, salary, supervisor_id) VALUES
    (2,  'Librarian', '2019-03-11', 68000.00, 1),
    (3,  'Librarian', '2018-10-22', 67000.00, 1),
    (4,  'Assistant', '2022-02-14', 52000.00, 2),
    (5,  'Assistant', '2021-08-09', 50000.00, 2),
    (11, 'Librarian', '2016-04-18', 65000.00, 1),
    (12, 'Assistant', '2023-01-16', 48000.00, 11),
    (13, 'Volunteer', '2024-09-07', NULL,      11),
    (14, 'Volunteer', '2025-01-12', NULL,      11),
    (15, 'Volunteer', '2025-06-20', NULL,      11);

INSERT INTO Item (item_id, title, pub_year, subject, language, shelf_location) VALUES
    (1,  'The Midnight Library',                 2020, 'Fiction',             'English', 'FIC HAIG'),
    (2,  'Braiding Sweetgrass',                  2013, 'Nature and Ecology',   'English', '580 KIM'),
    (3,  'The Seven Husbands of Evelyn Hugo',    2017, 'Historical Fiction',   'English', 'FIC REID'),
    (4,  'A Fine Balance',                       1995, 'Literary Fiction',     'English', 'FIC ROY'),
    (5,  'Station Eleven',                       2014, 'Post-apocalyptic Fiction','English','FIC MAN'),
    (6,  'Educated',                             2018, 'Memoir',               'English', 'BIO WEST'),
    (7,  'The City We Became',                   2020, 'Fantasy',              'English', 'FIC JEM'),
    (8,  'Crying in H Mart',                     2021, 'Memoir',               'English', 'BIO ZAUNER'),
    (9,  'The Inconvenient Indian',             2012, 'Indigenous Studies',   'English', '970 KING'),
    (10, 'The Vancouver Book of Trees',          2022, 'Local History',         'English', '582 VAN'),
    (11, 'Canadian Geographic - Pacific Issue',  2025, 'Geography',             'English', 'SER CAN 1'),
    (12, 'The Walrus - Arts Issue',              2025, 'Culture',               'English', 'SER WAL 1'),
    (13, 'Scientific American - Climate',        2025, 'Science',               'English', 'SER SCI 1'),
    (14, 'Maclean''s - Canada Today',            2025, 'Current Affairs',       'English', 'SER MAC 1'),
    (15, 'The New Yorker - Fiction',             2025, 'Literature',            'English', 'SER NEW 1'),
    (16, 'National Geographic - Oceans',         2025, 'Science',               'English', 'SER NAT 1'),
    (17, 'BC Historical Quarterly',              2024, 'History',               'English', 'SER BCH 1'),
    (18, 'Journal of Urban Planning',            2024, 'Urban Studies',         'English', 'SER JUP 1'),
    (19, 'Canadian Medical Association Journal', 2025, 'Medicine',              'English', 'SER CMA 1'),
    (20, 'The Paris Review - Writers',           2025, 'Literature',            'English', 'SER PAR 1'),
    (21, 'Kind of Blue',                         1959, 'Jazz',                  'English', 'REC DAVIS'),
    (22, 'Blue',                                 1971, 'Rock',                  'English', 'REC JONI'),
    (23, 'Rumours',                              1977, 'Rock',                  'English', 'REC FLEET'),
    (24, 'To Pimp a Butterfly',                 2015, 'Hip-Hop',               'English', 'REC LAMAR'),
    (25, 'The Miseducation of Lauryn Hill',     1998, 'R&B',                  'English', 'REC HILL'),
    (26, 'In Rainbows',                          2007, 'Alternative Rock',      'English', 'REC RADIO'),
    (27, 'Blue Train',                           1957, 'Jazz',                  'English', 'REC COLTRANE'),
    (28, 'Hounds of Love',                       1985, 'Art Pop',               'English', 'REC BUSH'),
    (29, 'A Love Supreme',                       1965, 'Jazz',                  'English', 'REC COLTRANE'),
    (30, 'The Dark Side of the Moon',            1973, 'Progressive Rock',      'English', 'REC PINK');

INSERT INTO Book (item_id, isbn, author, publisher, pages) VALUES
    (1,  '9780525559474', 'Matt Haig',             'Viking',             304),
    (2,  '9781579654670', 'Robin Wall Kimmerer',   'Milkweed Editions',  408),
    (3,  '9781501161933', 'Taylor Jenkins Reid',   'Atria Books',        400),
    (4,  '9780385695816', 'Rohinton Mistry',       'McClelland & Stewart',624),
    (5,  '9780385353304', 'Emily St. John Mandel', 'Knopf',              352),
    (6,  '9780399590504', 'Tara Westover',         'Random House',       352),
    (7,  '9780316500404', 'N. K. Jemisin',         'Orbit',              448),
    (8,  '9781984859482', 'Michelle Zauner',        'Knopf',              256),
    (9,  '9780385520713', 'Thomas King',            'University of Minnesota Press', 320),
    (10, '9781771605365', 'Derek Hayes',            'Douglas & McIntyre', 192);

INSERT INTO SerialSeries (issn, publisher) VALUES
    ('0001-0001', 'Canadian Geographic'),
    ('0001-0002', 'The Walrus Foundation'),
    ('0001-0003', 'Springer Nature'),
    ('0001-0004', 'St. Joseph Communications'),
    ('0001-0005', 'Condé Nast'),
    ('0001-0006', 'National Geographic Partners'),
    ('0001-0007', 'BC Historical Federation'),
    ('0001-0008', 'Canadian Institute of Planners'),
    ('0001-0009', 'Canadian Medical Association'),
    ('0001-0010', 'The Paris Review Foundation');

INSERT INTO Serial (item_id, issn, volume, issue_no) VALUES
    (11, '0001-0001', 101, 1),
    (12, '0001-0002', 22,  3),
    (13, '0001-0003', 332, 4),
    (14, '0001-0004', 138, 2),
    (15, '0001-0005', 91,  8),
    (16, '0001-0006', 248, 5),
    (17, '0001-0007', 78,  1),
    (18, '0001-0008', 12,  2),
    (19, '0001-0009', 147, 7),
    (20, '0001-0010', 97,  4);

INSERT INTO Record (item_id, artist, label, runtime_min, genre) VALUES
    (21, 'Miles Davis',       'Columbia',       46, 'Jazz'),
    (22, 'Joni Mitchell',     'Reprise',        39, 'Rock'),
    (23, 'Fleetwood Mac',     'Warner Bros.',   40, 'Rock'),
    (24, 'Kendrick Lamar',    'Top Dawg',       79, 'Hip-Hop'),
    (25, 'Lauryn Hill',       'Ruffhouse',      77, 'R&B'),
    (26, 'Radiohead',         'XL Recordings',  42, 'Alternative Rock'),
    (27, 'John Coltrane',     'Blue Note',      42, 'Jazz'),
    (28, 'Kate Bush',         'EMI',             42, 'Art Pop'),
    (29, 'John Coltrane',     'Impulse!',       47, 'Jazz'),
    (30, 'Pink Floyd',        'Harvest',        43, 'Progressive Rock');

INSERT INTO Copy (copy_id, item_id, barcode, condition, acquired_date) VALUES
    (1,  1,  'VPL-000001', 'Good', '2021-02-10'),
    (2,  1,  'VPL-000002', 'Good', '2021-02-10'),
    (3,  1,  'VPL-000003', 'Fair', '2021-02-10'),
    (4,  1,  'VPL-000004', 'Good', '2022-06-15'),
    (5,  1,  'VPL-000005', 'New',  '2024-08-20'),
    (6,  2,  'VPL-000006', 'Good', '2020-01-12'),
    (7,  3,  'VPL-000007', 'Good', '2020-03-04'),
    (8,  4,  'VPL-000008', 'Fair', '2019-09-22'),
    (9,  5,  'VPL-000009', 'Good', '2021-01-05'),
    (10, 6,  'VPL-000010', 'Good', '2022-02-16'),
    (11, 7,  'VPL-000011', 'New',  '2023-05-19'),
    (12, 8,  'VPL-000012', 'Good', '2023-05-19'),
    (13, 9,  'VPL-000013', 'Good', '2022-11-11'),
    (14, 10, 'VPL-000014', 'New',  '2024-01-25'),
    (15, 11, 'VPL-000015', 'Good', '2025-02-01'),
    (16, 12, 'VPL-000016', 'Good', '2025-02-01'),
    (17, 13, 'VPL-000017', 'New',  '2025-02-01'),
    (18, 14, 'VPL-000018', 'Good', '2025-02-01'),
    (19, 15, 'VPL-000019', 'Good', '2025-02-01'),
    (20, 16, 'VPL-000020', 'Good', '2025-02-01'),
    (21, 17, 'VPL-000021', 'Fair', '2024-10-14'),
    (22, 18, 'VPL-000022', 'Good', '2024-10-14'),
    (23, 19, 'VPL-000023', 'Good', '2025-03-18'),
    (24, 20, 'VPL-000024', 'New',  '2025-03-18'),
    (25, 21, 'VPL-000025', 'Good', '2020-04-12'),
    (26, 22, 'VPL-000026', 'Good', '2020-04-12'),
    (27, 23, 'VPL-000027', 'Fair', '2020-04-12'),
    (28, 24, 'VPL-000028', 'Good', '2021-07-08'),
    (29, 25, 'VPL-000029', 'Good', '2021-07-08'),
    (30, 26, 'VPL-000030', 'New',  '2022-03-03'),
    (31, 27, 'VPL-000031', 'Good', '2022-03-03'),
    (32, 28, 'VPL-000032', 'Good', '2022-03-03'),
    (33, 29, 'VPL-000033', 'Good', '2022-03-03'),
    (34, 30, 'VPL-000034', 'Fair', '2022-03-03');

INSERT INTO Loan (loan_id, copy_id, member_id, borrow_date, due_date, renewal_count, return_date) VALUES
    (1,  1,  2,  '2026-07-01', '2026-07-22', 0, NULL),
    (2,  2,  3,  '2026-07-02', '2026-07-23', 1, '2026-07-20'),
    (3,  3,  4,  '2026-06-01', '2026-06-22', 0, '2026-06-30'),
    (4,  4,  5,  '2026-07-05', '2026-07-26', 0, '2026-07-25'),
    (5,  5,  6,  '2026-07-10', '2026-07-31', 0, NULL),
    (6,  6,  7,  '2026-06-10', '2026-07-01', 0, '2026-07-10'),
    (7,  7,  8,  '2026-06-15', '2026-07-06', 0, '2026-07-05'),
    (8,  8,  9,  '2026-07-12', '2026-08-02', 0, NULL),
    (9,  9,  8,  '2026-06-20', '2026-07-11', 0, '2026-07-09'),
    (10, 10, 2,  '2026-07-15', '2026-08-05', 0, NULL),
    (11, 11, 3,  '2026-06-25', '2026-07-16', 0, '2026-07-14'),
    (12, 15, 4,  '2026-07-18', '2026-08-08', 0, NULL);

INSERT INTO Fine (fine_id, member_id, loan_id, reason, amount, date_assessed, amount_paid, date_paid) VALUES
    (1,  4,  3,  'Overdue',         2.00, '2026-06-30', 0.00, NULL),
    (2,  7,  6,  'Overdue',         2.25, '2026-07-10', 1.00, '2026-07-15'),
    (3,  3,  2,  'Damaged',         5.00, '2026-07-20', 0.00, NULL),
    (4,  1,  NULL,'Damaged',        12.50, '2026-05-10', 0.00, NULL),
    (5,  5,  NULL,'Lost',           30.00, '2026-04-18', 10.00, '2026-05-01'),
    (6,  8,  9,   'Overdue',         1.00, '2026-07-09', 0.00, NULL),
    (7,  8,  7,  'Overdue',         0.00, '2026-07-05', 0.00, NULL),
    (8,  2,  NULL,'Card replacement',8.00, '2026-01-12', 8.00, '2026-01-20'),
    (9,  6,  NULL,'Damaged',        6.75, '2026-03-03', 0.00, NULL),
    (10, 9,  NULL,'Lost',           30.00, '2026-02-28', 0.00, NULL);

INSERT INTO Room (room_id, name, room_type, floor, capacity) VALUES
    (1,  'Central Library Room 101', 'Meeting Room', 1, 30),
    (2,  'Central Library Room 202', 'Meeting Room', 2, 20),
    (3,  'Central Library Auditorium','Auditorium',  1, 120),
    (4,  'Central Library Gallery',   'Gallery',     1, 80),
    (5,  'Kitsilano Branch Room A',   'Meeting Room', 1, 24),
    (6,  'Kitsilano Branch Room B',   'Meeting Room', 2, 16),
    (7,  'Renfrew Branch Program Room','Program Room',1, 40),
    (8,  'Mount Pleasant Studio',     'Studio',      1, 18),
    (9,  'Kerrisdale Reading Room',   'Meeting Room', 2, 22),
    (10, 'Hastings Branch Hall',      'Auditorium',  1, 60);

INSERT INTO Event (event_id, title, description, event_type, event_date, start_time, end_time, min_age, max_age, max_attendees, room_id, organizer_id) VALUES
    (1,  'September Book Club',       'Discussion of a contemporary novel.',       'Book Club',       '2026-09-05', '10:00', '11:30', NULL, NULL, 20, 1, 2),
    (2,  'Indigenous Authors Panel',  'Conversation with local writers.',          'Book Talk',       '2026-09-06', '18:00', '20:00', 18, NULL, 18, 2, 3),
    (3,  'Pacific Northwest Birds',   'Family science presentation.',              'Lecture',         '2026-09-07', '13:00', '14:30', NULL, NULL, 50, 3, 11),
    (4,  'Vancouver Through Film',    'A free screening of local documentaries.', 'Film Screening',  '2026-09-08', '19:00', '21:00', 16, NULL, 70, 4, 12),
    (5,  'Teen Zine Workshop',        'Create and print a personal zine.',        'Workshop',        '2026-09-09', '15:00', '17:00', 13, 17, 18, 5, 4),
    (6,  'Jazz Listening Circle',     'Guided listening and discussion.',          'Music Club',      '2026-09-10', '18:30', '20:00', 19, NULL, 14, 6, 5),
    (7,  'Community Art Opening',     'Opening reception for local artists.',     'Art Show',        '2026-09-11', '17:00', '19:00', NULL, NULL, 35, 7, 11),
    (8,  'Poetry Open Mic',           'An evening of readings by local poets.',   'Reading',         '2026-09-12', '19:00', '21:00', 16, NULL, 18, 8, 12),
    (9,  'Repair Cafe',               'Learn to repair small household items.',   'Community Event', '2026-09-13', '11:00', '14:00', NULL, NULL, 20, 9, 2),
    (10, 'Library Volunteer Welcome', 'Orientation for new volunteers.',          'Orientation',     '2026-09-14', '10:00', '11:00', 18, NULL, 40, 10, 3);

INSERT INTO EventRegistration (event_id, member_id, date_registered, attended) VALUES
    (1,  2,  '2026-08-01', 1),
    (1,  3,  '2026-08-02', 1),
    (2,  1,  '2026-08-01', 0),
    (2,  7,  '2026-08-03', 0),
    (3,  6,  '2026-08-04', 1),
    (4,  8,  '2026-08-05', 0),
    (6,  9,  '2026-08-06', 0),
    (7,  4,  '2026-08-07', 1),
    (8,  5,  '2026-08-08', 0),
    (10, 3,  '2026-08-09', 0);

INSERT INTO HelpRequest (request_id, member_id, staff_id, question, date_asked, response, date_answered, status) VALUES
    (1,  2,  NULL, 'Can you help me find beginner books about native plants?', '2026-08-01', NULL, NULL, 'Open'),
    (2,  3,  2,    'How do I access the library genealogy databases?',          '2026-07-28', 'Use the genealogy workstation on level two.', '2026-07-29', 'Answered'),
    (3,  4,  NULL, 'Is there a quiet study room available this afternoon?',     '2026-08-02', NULL, NULL, 'Open'),
    (4,  5,  3,    'Can I renew a book that already has a hold?',              '2026-07-25', 'Books with holds cannot be renewed.', '2026-07-25', 'Closed'),
    (5,  6,  NULL, 'Where are the accessible-format collections?',              '2026-08-03', NULL, NULL, 'Open'),
    (6,  7,  11,   'Do you have tax preparation guides for British Columbia?',   '2026-07-30', 'They are in the reference collection.', '2026-07-31', 'Answered'),
    (7,  8,  NULL, 'Can someone recommend a science fiction audiobook?',        '2026-08-04', NULL, NULL, 'Open'),
    (8,  9,  12,   'How do I reserve a room for a community group?',           '2026-07-20', 'Please complete the community room request form.', '2026-07-21', 'Closed'),
    (9,  10, NULL, 'Can I receive notices by email instead of telephone?',     '2026-08-05', NULL, NULL, 'Open'),
    (10, 1,  2,    'Do you have maps of historical Vancouver neighbourhoods?',   '2026-07-18', 'Yes, they are in the local history collection.', '2026-07-19', 'Answered');

INSERT INTO WishlistItem (wish_id, title, creator, item_type, isbn_issn, est_cost, priority, date_requested, status, acquired_item) VALUES
    (1,  'The Covenant of Water',       'Abraham Verghese',  'Book',   '9780525522190', 28.00, 'High',   '2026-06-01', 'Requested', NULL),
    (2,  'Demon Copperhead',             'Barbara Kingsolver','Book',   '9780063251922', 24.00, 'High',   '2026-06-02', 'Approved',  NULL),
    (3,  'The Creative Act',             'Rick Rubin',        'Book',   '9780593652886', 32.00, 'Medium', '2026-06-03', 'Requested', NULL),
    (4,  'The Best American Poetry',     'David Lehman',      'Serial', '9781959030001', 20.00, 'Low',    '2026-06-04', 'Requested', NULL),
    (5,  'Nature Canada',                'Nature Canada',     'Serial', '0001-0020',     12.00, 'Medium', '2026-06-05', 'Approved',  NULL),
    (6,  'The Complete Musician',        'Steven Laitz',      'Book',   '9780199347093', 65.00, 'Low',    '2026-06-06', 'Rejected',  NULL),
    (7,  'Arooj Aftab - Vulture Prince', 'Arooj Aftab',       'Record', '075597458320',  22.00, 'Medium', '2026-06-07', 'Requested', NULL),
    (8,  'The Hidden Life of Trees',     'Peter Wohlleben',   'Book',   '9781771642483', 25.00, 'High',   '2026-06-08', 'Acquired',  10),
    (9,  'Vancouver Sun Archive',        'Vancouver Sun',     'Serial', NULL,            0.00, 'Medium', '2026-06-09', 'Requested', NULL),
    (10, 'Music for 18 Musicians',      'Steve Reich',       'Record', '075597463126',  18.00, 'Low',    '2026-06-10', 'Approved',  NULL);

COMMIT;
