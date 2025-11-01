-- Setup script for ICS321 – Project #1: Horse Racing Database System
-- Creates schema, loads sample data from the assignment handout (fixed minor PDF line breaks),
-- and adds the required stored procedure & trigger.
-- Tested with MySQL 8.x

DROP DATABASE IF EXISTS RACING;
CREATE DATABASE RACING;
USE RACING;

-- Core tables (types and lengths aligned for FK integrity)
CREATE TABLE Stable (
  stableId VARCHAR(15) NOT NULL,
  stableName VARCHAR(30),
  location VARCHAR(30),
  colors VARCHAR(20),
  PRIMARY KEY (stableId)
);

CREATE TABLE Horse (
  horseId VARCHAR(15) NOT NULL,
  horseName VARCHAR(30) NOT NULL,
  age INT,
  gender CHAR(1),
  registration INT NOT NULL,
  stableId VARCHAR(15) NOT NULL,
  PRIMARY KEY (horseId),
  CONSTRAINT fk_horse_stable FOREIGN KEY (stableId) REFERENCES Stable(stableId)
);

CREATE TABLE Owner (
  ownerId VARCHAR(15) NOT NULL,
  lname VARCHAR(15),
  fname VARCHAR(15),
  PRIMARY KEY (ownerId)
);

CREATE TABLE Owns (
  ownerId VARCHAR(15) NOT NULL,
  horseId VARCHAR(15) NOT NULL,
  PRIMARY KEY (ownerId, horseId),
  CONSTRAINT fk_owns_owner FOREIGN KEY (ownerId) REFERENCES Owner(ownerId),
  CONSTRAINT fk_owns_horse FOREIGN KEY (horseId) REFERENCES Horse(horseId)
);

CREATE TABLE Trainer (
  trainerId VARCHAR(15) NOT NULL,
  lname VARCHAR(30),
  fname VARCHAR(30),
  stableId VARCHAR(15),
  PRIMARY KEY (trainerId),
  CONSTRAINT fk_trainer_stable FOREIGN KEY (stableId) REFERENCES Stable(stableId)
);

CREATE TABLE Track (
  trackName VARCHAR(30) NOT NULL,
  location VARCHAR(30),
  length INT,
  PRIMARY KEY (trackName)
);

CREATE TABLE Race (
  raceId VARCHAR(15) NOT NULL,
  raceName VARCHAR(30),
  trackName VARCHAR(30),
  raceDate DATE,
  raceTime TIME,
  PRIMARY KEY (raceId),
  CONSTRAINT fk_race_track FOREIGN KEY (trackName) REFERENCES Track(trackName)
);

CREATE TABLE RaceResults (
  raceId VARCHAR(15) NOT NULL,
  horseId VARCHAR(15) NOT NULL,
  results VARCHAR(15),
  prize DECIMAL(10,2),
  PRIMARY KEY (raceId, horseId),
  CONSTRAINT fk_rr_race FOREIGN KEY (raceId) REFERENCES Race(raceId),
  CONSTRAINT fk_rr_horse FOREIGN KEY (horseId) REFERENCES Horse(horseId)
);

-- Optional helper table to support the “approve a new trainer” workflow
CREATE TABLE TrainerApplications (
  appId INT AUTO_INCREMENT PRIMARY KEY,
  fname VARCHAR(30),
  lname VARCHAR(30),
  stableId VARCHAR(15) NOT NULL,
  created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
  CONSTRAINT fk_ta_stable FOREIGN KEY (stableId) REFERENCES Stable(stableId)
);

-- Archive table for deleted horses (required by the assignment)
CREATE TABLE old_info (
  horseId VARCHAR(15) NOT NULL,
  horseName VARCHAR(30) NOT NULL,
  age INT,
  gender CHAR(1),
  registration INT NOT NULL,
  stableId VARCHAR(15) NOT NULL,
  deleted_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

-- ---------------------
-- Sample Data (from handout; minor formatting fixes)
-- ---------------------
-- Stables
INSERT INTO Stable VALUES 
('stable1', 'Zobair Farm', 'Riyadh', 'orange'),
('stable2', 'Zayed Farm', 'Dubai', 'kiwi'),
('stable3', 'Zahra Farm', 'Jeddah', 'cinnamon'),
('stable4', 'Sunny Stables', 'Jubail', 'lemon'),
('stable5', 'Ajman Stables', 'Ajman', 'lemon'),
('stable6', 'Dubai Stables', 'Dubai', 'bright blue');

-- Horses
INSERT INTO Horse VALUES 
('horse1', 'Warrior', 2, 'C', 11111, 'stable1'),
('horse2', 'Conquerer', 2, 'F', 22222, 'stable6'),
('horse3', 'Dove of Peace', 3, 'C', 33333, 'stable1'),
('horse4', 'Ever Faster', 3, 'F', 44444, 'stable3'),
('horse5', 'Slow Winner', 2, 'C', 55555, 'stable3'),
('horse6', 'Windrunner', 2, 'F', 66666, 'stable2'),
('horse7', 'Catapult', 4, 'M', 77777, 'stable6'),
('horse8', 'Flying Force', 2, 'C', 88888, 'stable4'),
('horse9', 'Laggard', 2, 'F', 99999, 'stable4'),
('horse10', 'Formula One', 6, 'G', 10101, 'stable2'),
('horse11', 'Frisky Frolic', 3, 'C', 11011, 'stable4'),
('horse12', 'Fantastic', 3, 'F', 12121, 'stable2'),
('horse13', 'Midnight', 2, 'C', 13131, 'stable3'),
('horse14', 'Running Wild', 4, 'S', 14141, 'stable2'),
('horse15', 'FastOffMyFeet', 3, 'C', 15151, 'stable1'),
('horse16', 'Slow Poke', 2, 'C', 16161, 'stable3'),
('horse17', 'Slinger', 3, 'F', 17171, 'stable2'),
('horse18', 'Sublime', 5, 'M', 18181, 'stable6'),
('horse19', 'Front Runner', 4, 'G', 19191, 'stable4'),
('horse20', 'Night', 3, 'C', 20200, 'stable1'),
('horse21', 'Negative', 3, 'F', 21210, 'stable3'),
('horse22', 'Lightening', 2, 'C', 22220, 'stable6'),
('horse23', 'Lazy Loser', 4, 'G', 23230, 'stable1'),
('horse24', 'Leaping Lizard', 2, 'C', 24240, 'stable1'),
('horse25', 'Beautiful Brown', 3, 'F', 25250, 'stable6'),
('horse26', 'Sick Winner', 5, 'M', 26260, 'stable2');

-- Owners
INSERT INTO Owner VALUES
('owner1', 'Saeed', 'Ahmed'),
('owner2', 'Mohammed', 'Khalid'),
('owner3', 'Mohammed', 'Faisal'),
('owner4', 'Fahd', 'Abdul Rahman'),
('owner5', 'Nasr', ''),
('owner6', 'Mohammed', 'Sheikh'),
('owner7', 'Abed', 'Ahmed'),
('owner8', 'Mashour', ''),
('owner9', 'Said', 'Sheikh'),
('owner10', 'Faisal', 'Khan'),
('owner11', 'Jabr', 'Mohammed'),
('owner12', 'Faleh', 'Mahmood'),
('owner13', 'Yahya', 'Mohammed'),
('owner14', 'Sulaiman', ''),
('owner15', 'Saeed', 'Ali'),
('owner16', 'Ahmed', 'Faisal'),
('owner17', 'Saud', 'Mohammed'),
('owner18', 'Nazir', 'Mohammed'),
('owner19', 'Saleh', 'Fahd'),
('owner20', 'Mohammed', 'Naeem');

-- Owns
INSERT INTO Owns VALUES
('owner14', 'horse1'),
('owner3', 'horse2'),
('owner2', 'horse3'),
('owner2', 'horse4'),
('owner1', 'horse5'),
('owner12', 'horse5'),
('owner14', 'horse5'),
('owner1', 'horse6'),
('owner5', 'horse6'),
('owner20', 'horse7'),
('owner19', 'horse8'),
('owner2', 'horse9'),
('owner18', 'horse10'),
('owner3', 'horse10'),
('owner4', 'horse11'),
('owner16', 'horse12'),
('owner17', 'horse13'),
('owner15', 'horse14'),
('owner15', 'horse15'),
('owner20', 'horse16'),
('owner4', 'horse17'),
('owner6', 'horse19'),
('owner12', 'horse20'),
('owner7', 'horse21'),
('owner7', 'horse22'),
('owner10', 'horse23'),
('owner12', 'horse24'),
('owner13', 'horse25'),
('owner2', 'horse26'),
('owner9', 'horse23'),
('owner8', 'horse18');

-- Trainers
INSERT INTO Trainer VALUES
('trainer1', 'Mohammed', 'Fahd', 'stable2'),
('trainer2', 'Saleh', 'Saeed', 'stable1'),
('trainer3', 'Ali', 'Raad', 'stable4'),
('trainer4', 'Sayed', 'Wasim', 'stable3'),
('trainer5', 'Ahmed', 'Ali', 'stable3'),
('trainer6', 'Faisal', 'Salah', 'stable5'),
('trainer7', 'Hamid', 'Ahmed', 'stable6'),
('trainer8', 'Khalid', 'Ahmed', 'stable6');

-- Tracks
INSERT INTO Track VALUES
('Doha', 'QT', 20),
('Jubail', 'SA', 15),
('Yanbu', 'SA', 18),
('Dubai', 'UE', 17),
('Jeddah', 'SA', 19),
('Bahrain', 'BH', 18),
('Sharjah', 'UE', 20),
('Riyadh', 'SA', 22),
('Dhahran', 'SA', 20);

-- Races (fixed dates from PDF line-breaks)
INSERT INTO Race VALUES
('race1', 'Kings Cup', 'Riyadh', '2007-05-03', '14:00:00'),
('race2', '2-year-old fillies', 'Doha', '2007-05-03', '13:00:00'),
('race3', '2-year-old colts', 'Doha', '2007-05-03', '13:30:00'),
('race4', 'Handicap', 'Doha', '2007-05-03', '12:00:00'),
('race5', 'Claiming Stake', 'Sharjah', '2007-05-03', '12:30:00'),
('race6', '3-year-old fillies', 'Jubail', '2007-06-02', '12:30:00'),
('race7', 'Handicap', 'Jubail', '2007-06-02', '09:30:00'),
('race8', '2-year-old colts', 'Riyadh', '2007-06-02', '10:30:00'),
('race9', '2-year-old fillies', 'Jubail', '2007-06-02', '11:30:00'),
('race10', 'Claiming Stake', 'Sharjah', '2007-06-02', '12:30:00'),
('race11', '3-year-old fillies', 'Dubai', '2007-04-02', '10:30:00'),
('race12', 'Handicap', 'Yanbu', '2007-05-03', '11:30:00'),
('race13', '3-year-old fillies', 'Yanbu', '2007-05-03', '11:00:00'),
('race14', 'Handicap', 'Dhahran', '2007-05-10', '10:00:00'),
('race15', '3-year-old colts', 'Dubai', '2007-05-12', '15:00:00'),
('race16', 'Claiming Stake', 'Yanbu', '2007-05-20', '14:30:00'),
('race17', 'Handicap', 'Doha', '2007-05-20', '13:00:00'),
('race18', '3-year-old fillies', 'Sharjah', '2007-05-21', '08:00:00'),
('race19', '2-year-old colts', 'Dhahran', '2007-05-25', '11:00:00'),
('race20', 'Claiming Stake', 'Jeddah', '2007-05-25', '08:30:00'),
('race21', '3-year-old colts', 'Riyadh', '2007-03-19', '14:30:00'),
('race22', 'Handicap', 'Dhahran', '2007-03-27', '15:00:00'),
('race23', '3-year-old fillies', 'Jeddah', '2007-03-28', '09:30:00'),
('race24', '3-year-old colts', 'Jubail', '2007-03-28', '13:30:00'),
('race25', 'Claiming Stake', 'Jeddah', '2007-03-29', '10:00:00'),
('race26', '3-year-old colts', 'Yanbu', '2007-03-30', '12:30:00'),
('race27', 'Handicap', 'Dubai', '2007-04-03', '14:00:00'),
('race28', '2-year-old fillies', 'Jeddah', '2007-04-04', '08:30:00'),
('race29', '3-year-old colts', 'Bahrain', '2007-04-05', '08:00:00'),
('race30', 'Claiming Stake', 'Dhahran', '2007-04-08', '09:30:00'),
('race31', 'Handicap', 'Dhahran', '2007-04-08', '09:00:00'),
('race32', '2-year-old colts', 'Jubail', '2007-04-09', '11:00:00'),
('race33', 'Claiming Stake', 'Bahrain', '2007-04-10', '13:00:00'),
('race34', '3-year-old colts', 'Dubai', '2007-05-12', '12:00:00'),
('race35', 'Handicap', 'Dubai', '2007-04-13', '10:30:00'),
('race36', '3-year-old colts', 'Jeddah', '2007-05-03', '14:30:00');

-- Race Results
INSERT INTO RaceResults VALUES
('race1', 'horse3', 'first', 500000),
('race1', 'horse11', 'second', 200000),
('race1', 'horse15', 'third', 500000),
('race2', 'horse6', 'first', 100000),
('race2', 'horse2', 'second', 50000),
('race2', 'horse20', 'third', 20000),
('race3', 'horse22', 'first', 70000),
('race3', 'horse5', 'second', 50000),
('race3', 'horse1', 'third', 20000),
('race4', 'horse19', 'first', 50000),
('race4', 'horse18', 'no show', 0),
('race4', 'horse14', 'no show', 0),
('race6', 'horse25', 'first', 5000),
('race7', 'horse7', 'second', 2000),
('race9', 'horse11', 'last', 0),
('race10', 'horse18', 'fourth', 500),
('race11', 'horse12', 'first', 50000),
('race11', 'horse17', 'second', 25000),
('race11', 'horse21', 'fourth', 10000),
('race12', 'horse14', 'first', 6000),
('race12', 'horse18', 'second', 5000),
('race13', 'horse25', 'first', 100000),
('race13', 'horse4', 'second', 50000),
('race13', 'horse12', 'third', 30000),
('race14', 'horse23', 'first', 25000),
('race14', 'horse26', 'second', 20000),
('race15', 'horse11', 'second', 10000),
('race15', 'horse24', 'third', 8000),
('race16', 'horse10', 'second', 5000),
('race16', 'horse14', 'third', 4000),
('race17', 'horse7', 'first', 15000),
('race17', 'horse10', 'second', 1100),
('race18', 'horse6', 'first', 70000),
('race19', 'horse22', 'first', 1000000),
('race19', 'horse1', 'second', 80000),
('race19', 'horse8', 'third', 60000),
('race20', 'horse23', 'first', 1500),
('race20', 'horse14', 'second', 1000),
('race20', 'horse26', 'third', 800),
('race20', 'horse10', 'fourth', 500),
('race21', 'horse24', 'first', 70000),
('race21', 'horse15', 'second', 55000),
('race21', 'horse3', 'third', 40000),
('race22', 'horse18', 'first', 10000),
('race22', 'horse19', 'second', 8000),
('race23', 'horse25', 'first', 150000),
('race24', 'horse7', 'first', 10000),
('race25', 'horse10', 'second', 8000),
('race25', 'horse20', 'fourth', 2000),
('race26', 'horse24', 'first', 8000),
('race26', 'horse20', 'fourth', 2000),
('race27', 'horse18', 'first', 70000),
('race27', 'horse23', 'third', 40000),
('race28', 'horse25', 'first', 90000),
('race29', 'horse15', 'first', 80000),
('race29', 'horse3', 'second', 65000),
('race29', 'horse24', 'third', 50000),
('race30', 'horse14', 'second', 1500),
('race30', 'horse10', 'fourth', 500),
('race31', 'horse7', 'first', 90000),
('race31', 'horse26', 'second', 70000),
('race31', 'horse23', 'third', 50000),
('race31', 'horse10', 'fourth', 30000),
('race32', 'horse22', 'first', 150000),
('race32', 'horse13', 'second', 125000),
('race32', 'horse16', 'third', 100000),
('race33', 'horse23', 'second', 1700),
('race33', 'horse26', 'third', 1200),
('race34', 'horse11', 'first', 50000),
('race34', 'horse15', 'second', 30000),
('race35', 'horse7', 'first', 45000),
('race35', 'horse19', 'second', 25000),
('race36', 'horse11', 'first', 100000),
('race36', 'horse15', 'second', 80000),
('race36', 'horse20', 'third', 50000);

-- ---------------------
-- Required Procedural SQL
-- ---------------------
DELIMITER //
CREATE PROCEDURE sp_delete_owner(IN p_ownerId VARCHAR(15))
BEGIN
  START TRANSACTION;
  DELETE FROM Owns WHERE ownerId = p_ownerId;
  DELETE FROM Owner WHERE ownerId = p_ownerId;
  COMMIT;
END //
DELIMITER ;

DELIMITER //
CREATE TRIGGER tr_horse_archive
AFTER DELETE ON Horse
FOR EACH ROW
BEGIN
  INSERT INTO old_info (horseId, horseName, age, gender, registration, stableId, deleted_at)
  VALUES (OLD.horseId, OLD.horseName, OLD.age, OLD.gender, OLD.registration, OLD.stableId, NOW());
END //
DELIMITER ;

-- Optional seed: trainer application example
INSERT INTO TrainerApplications (fname, lname, stableId) VALUES ('Yousef', 'Hammad', 'stable1');
