-- --------------------------------------------------------
-- Host:                         127.0.0.1
-- Server version:               8.0.30-0ubuntu0.20.04.2 - (Ubuntu)
-- Server OS:                    Linux
-- HeidiSQL Version:             12.1.0.6537
-- --------------------------------------------------------

/*!40101 SET @OLD_CHARACTER_SET_CLIENT=@@CHARACTER_SET_CLIENT */;
/*!40101 SET NAMES utf8 */;
/*!50503 SET NAMES utf8mb4 */;
/*!40103 SET @OLD_TIME_ZONE=@@TIME_ZONE */;
/*!40103 SET TIME_ZONE='+00:00' */;
/*!40014 SET @OLD_FOREIGN_KEY_CHECKS=@@FOREIGN_KEY_CHECKS, FOREIGN_KEY_CHECKS=0 */;
/*!40101 SET @OLD_SQL_MODE=@@SQL_MODE, SQL_MODE='NO_AUTO_VALUE_ON_ZERO' */;
/*!40111 SET @OLD_SQL_NOTES=@@SQL_NOTES, SQL_NOTES=0 */;


-- Dumping database structure for openCJ_cod4
CREATE DATABASE IF NOT EXISTS `openCJ_cod4` /*!40100 DEFAULT CHARACTER SET ascii COLLATE ascii_bin */ /*!80016 DEFAULT ENCRYPTION='N' */;
USE `openCJ_cod4`;

-- Dumping structure for table openCJ_cod4.checkpointConnections
CREATE TABLE IF NOT EXISTS `checkpointConnections` (
  `cpID` int NOT NULL,
  `childcpID` int NOT NULL,
  KEY `cpID` (`cpID`),
  KEY `childcpID` (`childcpID`),
  CONSTRAINT `FK__import_checkpoints` FOREIGN KEY (`cpID`) REFERENCES `checkpoints` (`cpID`) ON DELETE CASCADE ON UPDATE CASCADE,
  CONSTRAINT `FK__import_checkpoints_2` FOREIGN KEY (`childcpID`) REFERENCES `checkpoints` (`cpID`) ON DELETE CASCADE ON UPDATE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=ascii COLLATE=ascii_bin;

-- Data exporting was unselected.

-- Dumping structure for function openCJ_cod4.checkpointPassed
DELIMITER //
CREATE FUNCTION `checkpointPassed`(
	`_runID` INT,
	`_cpID` INT,
	`_timePlayed` INT,
	`_saveCount` INT,
	`_loadCount` INT,
	`_nadeJumps` INT,
	`_nadeThrows` INT,
	`_RPGJumps` INT,
	`_RPGShots` INT,
	`_doubleRPGs` INT,
	`__instanceNumber` INT
) RETURNS int
BEGIN
	DECLARE _instanceNumber INT DEFAULT NULL;
	SELECT instanceNumber INTO _instanceNumber FROM playerRuns WHERE runID = _runID;
	IF(__instanceNumber = _instanceNumber) THEN
		INSERT INTO checkpointStatistics (cpID, runID, timePlayed, saveCount, loadCount, nadeJumps, nadeThrows, RPGJumps, RPGShots, doubleRPGs) VALUES
		(_cpID, _runID, _timePlayed, _saveCount, _loadCount, _nadeJumps, _nadeThrows, _RPGJumps, _RPGShots, _doubleRPGS) ON DUPLICATE KEY UPDATE
		timePlayed = IF(timePlayed < _timePlayed, _timePlayed, timePlayed),
		saveCount = IF(timePlayed < _timePlayed, _saveCount, saveCount),
		loadCount = IF(timePlayed < _timePlayed, _loadCount, loadCount),
		nadeJumps = IF(timePlayed < _timePlayed, _nadeJumps, nadeJumps),
		nadeThrows = IF(timePlayed < _timePlayed, _nadeThrows, nadeThrows),
		RPGJumps = IF(timePlayed < _timePlayed, _RPGJumps, RPGJumps),
		RPGShots = IF(timePlayed < _timePlayed, _RPGShots, RPGShots),
		doubleRPGs = IF(timePlayed < _timePlayed, _doubleRPGs, doubleRPGs);
		RETURN _instanceNumber;
	END IF;
	RETURN Null;
END//
DELIMITER ;

-- Dumping structure for table openCJ_cod4.checkpoints
CREATE TABLE IF NOT EXISTS `checkpoints` (
  `cpID` int NOT NULL AUTO_INCREMENT,
  `x` int NOT NULL DEFAULT '0',
  `y` int NOT NULL DEFAULT '0',
  `z` int NOT NULL DEFAULT '0',
  `radius` int DEFAULT '0',
  `onGround` tinyint NOT NULL DEFAULT '0',
  `mapID` int NOT NULL DEFAULT '0',
  `ender` char(64) CHARACTER SET ascii COLLATE ascii_bin DEFAULT NULL,
  `elevate` tinyint NOT NULL DEFAULT '0',
  `endShaderNum` tinyint DEFAULT NULL,
  PRIMARY KEY (`cpID`),
  KEY `mapID` (`mapID`),
  KEY `ender` (`ender`),
  CONSTRAINT `FK_import_checkpoints_import_mapids` FOREIGN KEY (`mapID`) REFERENCES `mapids` (`mapID`) ON DELETE CASCADE ON UPDATE CASCADE
) ENGINE=InnoDB AUTO_INCREMENT=32375 DEFAULT CHARSET=ascii COLLATE=ascii_bin;

-- Data exporting was unselected.

-- Dumping structure for table openCJ_cod4.checkpointStatistics
CREATE TABLE IF NOT EXISTS `checkpointStatistics` (
  `runID` int NOT NULL,
  `cpID` int NOT NULL,
  `timePlayed` int NOT NULL,
  `saveCount` int NOT NULL,
  `loadCount` int NOT NULL,
  `nadeJumps` int NOT NULL,
  `nadeThrows` int NOT NULL,
  `RPGJumps` int NOT NULL,
  `RPGShots` int NOT NULL,
  `doubleRPGs` int NOT NULL,
  UNIQUE KEY `runID_cpID` (`runID`,`cpID`),
  KEY `runID` (`runID`),
  KEY `cpID` (`cpID`),
  KEY `timePlayed` (`timePlayed`),
  KEY `saveCount` (`saveCount`),
  KEY `loadCount` (`loadCount`),
  KEY `nadeJumps` (`nadeJumps`),
  KEY `nadeThrows` (`nadeThrows`),
  KEY `RPGJumps` (`RPGJumps`),
  KEY `RPGShots` (`RPGShots`),
  KEY `doubleRPGs` (`doubleRPGs`),
  CONSTRAINT `FK_checkpointStatistics_checkpoints` FOREIGN KEY (`cpID`) REFERENCES `checkpoints` (`cpID`) ON DELETE CASCADE ON UPDATE CASCADE,
  CONSTRAINT `FK_checkpointStatistics_playerRuns` FOREIGN KEY (`runID`) REFERENCES `playerRuns` (`runID`) ON DELETE CASCADE ON UPDATE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=ascii COLLATE=ascii_bin;

-- Data exporting was unselected.

-- Dumping structure for function openCJ_cod4.createNewAccount
DELIMITER //
CREATE FUNCTION `createNewAccount`(
	`_uid1` INT,
	`_uid2` INT,
	`_uid3` INT,
	`_uid4` INT
) RETURNS int
BEGIN
	DECLARE _playerID INT UNSIGNED DEFAULT NULL;
	DECLARE _rows INT UNSIGNED DEFAULT NULL;
	SELECT LAST_INSERT_ID(NULL) INTO _playerID; 
	INSERT INTO playerInformation VALUES ();
	SELECT LAST_INSERT_ID() INTO _playerID;
	IF(_playerID = 0)
	THEN
		RETURN NULL;
	END IF;
	INSERT IGNORE INTO playerLogin (playerID, uid1, uid2, uid3, uid4) VALUES (_playerID, _uid1, _uid2, _uid3, _uid4);
	SELECT ROW_COUNT() INTO _rows;
	IF(_rows = 0)
	THEN
		DELETE FROM playerInformation WHERE playerID = _playerID;
		RETURN NULL;
	ELSE
		RETURN _playerID;
	END IF;
END//
DELIMITER ;

-- Dumping structure for function openCJ_cod4.createRunID
DELIMITER //
CREATE FUNCTION `createRunID`(
	`_playerID` INT,
	`_mapID` INT
) RETURNS int
BEGIN
	DECLARE _runID INT  DEFAULT NULL;
	SELECT LAST_INSERT_ID(NULL) INTO _runID;
	INSERT INTO playerRuns (playerID, mapID) VALUES (_playerID, _mapID);
	SELECT LAST_INSERT_ID() INTO _runID;
	return _runID;
END//
DELIMITER ;

-- Dumping structure for function openCJ_cod4.createRunInstance
DELIMITER //
CREATE FUNCTION `createRunInstance`(
	`_runID` INT
) RETURNS int
BEGIN
	DECLARE _instanceNumber INT DEFAULT NULL;
	UPDATE playerRuns SET instanceNumber = instanceNumber + 1 WHERE runID = _runID;
	SELECT instanceNumber INTO _instanceNumber FROM playerRuns WHERE runID = _runID;
	RETURN _instanceNumber;
END//
DELIMITER ;

-- Dumping structure for table openCJ_cod4.geoIP
CREATE TABLE IF NOT EXISTS `geoIP` (
  `ip` int unsigned NOT NULL,
  `country` char(2) CHARACTER SET ascii COLLATE ascii_bin NOT NULL DEFAULT '',
  PRIMARY KEY (`ip`)
) ENGINE=InnoDB DEFAULT CHARSET=ascii COLLATE=ascii_bin;

-- Data exporting was unselected.

-- Dumping structure for function openCJ_cod4.getCountry
DELIMITER //
CREATE FUNCTION `getCountry`(
	`_ip` INT UNSIGNED
) RETURNS char(130) CHARSET ascii COLLATE ascii_bin
BEGIN
	DECLARE _country CHAR(2) DEFAULT 'UK';
	DECLARE _longCountry CHAR(128) DEFAULT 'Unknown';
	SELECT country INTO _country FROM geoIP WHERE ip < _ip ORDER BY ip DESC LIMIT 1;
	SELECT longCountry INTO _longCountry FROM longCountry WHERE country = _country;
	RETURN CONCAT(_country, _longCountry);
END//
DELIMITER ;

-- Dumping structure for function openCJ_cod4.getIgnoredBy
DELIMITER //
CREATE FUNCTION `getIgnoredBy`(
	`_playerID` INT
) RETURNS varchar(1024) CHARSET ascii COLLATE ascii_bin
BEGIN
	DECLARE _ignoredBy VARCHAR(1024) DEFAULT NULL;
	SELECT GROUP_CONCAT(ignoreID) INTO _ignoredBy FROM playerIgnore WHERE playerID = _playerID;
	RETURN _ignoredBy;
END//
DELIMITER ;

-- Dumping structure for function openCJ_cod4.getMapID
DELIMITER //
CREATE FUNCTION `getMapID`(
	`_mapname` CHAR(128)
) RETURNS char(128) CHARSET ascii COLLATE ascii_bin
BEGIN
	DECLARE _mapid INT DEFAULT NULL;
	INSERT IGNORE INTO mapids (mapname) VALUES (_mapname);
	SELECT mapid INTO _mapid FROM mapids WHERE mapname = _mapname;
	RETURN _mapid;
END//
DELIMITER ;

-- Dumping structure for function openCJ_cod4.getPlayerID
DELIMITER //
CREATE FUNCTION `getPlayerID`(
	`_uid1` INT,
	`_uid2` INT,
	`_uid3` INT,
	`_uid4` INT
) RETURNS int
BEGIN
	DECLARE _playerID INT DEFAULT NULL;
	SELECT playerID INTO _playerID FROM playerLogin WHERE uid1 = _uid1 AND uid2 = _uid2 AND uid3 = _uid3 AND uid4 = _uid4;
	CALL setName(_playerID, _playerName);
	RETURN _playerID;
END//
DELIMITER ;

-- Dumping structure for function openCJ_cod4.historyLoad
DELIMITER //
CREATE FUNCTION `historyLoad`(
	`_mapID` INT,
	`_playerID` INT,
	`_runID` INT
) RETURNS int
BEGIN
	DECLARE _rows INT DEFAULT NULL;
	DECLARE _instanceNumber INT DEFAULT NULL;
	UPDATE playerRuns SET instanceNumber = instanceNumber + 1 WHERE runID = _runID AND playerID = _playerID AND mapID = _mapID AND finishcpID IS NULL;
	SELECT ROW_COUNT() INTO _rows;
	IF(_rows = 0)
	THEN
		RETURN NULL;
	ELSE
		SELECT instanceNumber INTO _instanceNumber FROM playerRuns WHERE runID = _runID;
		RETURN _instanceNumber;
	END IF;
END//
DELIMITER ;

-- Dumping structure for table openCJ_cod4.longCountry
CREATE TABLE IF NOT EXISTS `longCountry` (
  `country` char(2) COLLATE ascii_bin NOT NULL,
  `longCountry` varchar(128) CHARACTER SET ascii COLLATE ascii_bin NOT NULL DEFAULT 'Unknown',
  `continent` char(2) COLLATE ascii_bin NOT NULL,
  UNIQUE KEY `country` (`country`),
  KEY `continent` (`continent`)
) ENGINE=InnoDB DEFAULT CHARSET=ascii COLLATE=ascii_bin;

-- Data exporting was unselected.

-- Dumping structure for table openCJ_cod4.mapids
CREATE TABLE IF NOT EXISTS `mapids` (
  `mapID` int NOT NULL AUTO_INCREMENT,
  `mapname` char(128) CHARACTER SET ascii COLLATE ascii_bin NOT NULL,
  `releaseDate` date DEFAULT NULL,
  PRIMARY KEY (`mapID`),
  UNIQUE KEY `mapname` (`mapname`),
  KEY `releaseDate` (`releaseDate`)
) ENGINE=InnoDB AUTO_INCREMENT=1903 DEFAULT CHARSET=ascii COLLATE=ascii_bin;

-- Data exporting was unselected.

-- Dumping structure for table openCJ_cod4.mapMappers
CREATE TABLE IF NOT EXISTS `mapMappers` (
  `mapID` int NOT NULL,
  `mapperID` int NOT NULL,
  UNIQUE KEY `mapID_mapperID` (`mapID`,`mapperID`) USING BTREE,
  KEY `mapID` (`mapID`) USING BTREE,
  KEY `mapperID` (`mapperID`) USING BTREE,
  CONSTRAINT `FK_mapMappers_mapids` FOREIGN KEY (`mapID`) REFERENCES `mapids` (`mapID`) ON DELETE CASCADE ON UPDATE CASCADE,
  CONSTRAINT `FK_mapMappers_mappers` FOREIGN KEY (`mapperID`) REFERENCES `mappers` (`mapperID`) ON DELETE CASCADE ON UPDATE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_0900_ai_ci;

-- Data exporting was unselected.

-- Dumping structure for table openCJ_cod4.mappers
CREATE TABLE IF NOT EXISTS `mappers` (
  `mapperID` int NOT NULL AUTO_INCREMENT,
  `name` char(128) CHARACTER SET utf8mb4 COLLATE utf8mb4_0900_ai_ci NOT NULL,
  PRIMARY KEY (`mapperID`) USING BTREE,
  UNIQUE KEY `name` (`name`) USING BTREE
) ENGINE=InnoDB AUTO_INCREMENT=443 DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_0900_ai_ci;

-- Data exporting was unselected.

-- Dumping structure for table openCJ_cod4.messages
CREATE TABLE IF NOT EXISTS `messages` (
  `messageID` int NOT NULL AUTO_INCREMENT,
  `playerID` int NOT NULL,
  `message` varchar(1024) CHARACTER SET ascii COLLATE ascii_bin NOT NULL,
  `server` char(50) CHARACTER SET ascii COLLATE ascii_bin NOT NULL DEFAULT '',
  PRIMARY KEY (`messageID`) USING BTREE,
  KEY `playerID` (`playerID`) USING BTREE,
  KEY `server` (`server`) USING BTREE,
  CONSTRAINT `FK_messages_playerInformation` FOREIGN KEY (`playerID`) REFERENCES `playerInformation` (`playerID`) ON DELETE CASCADE ON UPDATE CASCADE
) ENGINE=InnoDB AUTO_INCREMENT=43 DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_0900_ai_ci;

-- Data exporting was unselected.

-- Dumping structure for table openCJ_cod4.original_checkpoints
CREATE TABLE IF NOT EXISTS `original_checkpoints` (
  `cp_id` int NOT NULL AUTO_INCREMENT,
  `mapid` int NOT NULL DEFAULT '-1',
  `coordinate_x` int DEFAULT NULL,
  `coordinate_y` int DEFAULT NULL,
  `coordinate_z` int DEFAULT NULL,
  `isend` tinyint NOT NULL DEFAULT '0',
  `coordinate_x2` int DEFAULT NULL,
  `coordinate_y2` int DEFAULT NULL,
  `coordinate_z2` int DEFAULT NULL,
  `radius` int DEFAULT NULL,
  `event` char(255) DEFAULT NULL,
  `trigger` char(255) DEFAULT NULL,
  `type` char(255) DEFAULT NULL,
  `ender` char(50) DEFAULT NULL,
  `entity` char(255) DEFAULT NULL,
  PRIMARY KEY (`cp_id`),
  UNIQUE KEY `id` (`cp_id`),
  KEY `mapid` (`mapid`),
  KEY `isend` (`isend`)
) ENGINE=InnoDB AUTO_INCREMENT=23032 DEFAULT CHARSET=latin1;

-- Data exporting was unselected.

-- Dumping structure for table openCJ_cod4.original_checkpoint_connections
CREATE TABLE IF NOT EXISTS `original_checkpoint_connections` (
  `mapid` int NOT NULL DEFAULT '-1',
  `cp_id` int NOT NULL DEFAULT '-1',
  `child_cp_id` int NOT NULL DEFAULT '-1',
  UNIQUE KEY `combination` (`child_cp_id`,`cp_id`),
  KEY `mapid` (`mapid`),
  KEY `child_cp_id` (`child_cp_id`),
  KEY `cp_id` (`cp_id`)
) ENGINE=InnoDB DEFAULT CHARSET=latin1;

-- Data exporting was unselected.

-- Dumping structure for table openCJ_cod4.original_mapids
CREATE TABLE IF NOT EXISTS `original_mapids` (
  `mapid` int NOT NULL AUTO_INCREMENT,
  `mapname` char(255) NOT NULL DEFAULT '',
  `in_rotate` int NOT NULL DEFAULT '0',
  `type` char(50) NOT NULL DEFAULT 'jump',
  `fullname` char(255) NOT NULL DEFAULT 'Untitled',
  `timelimit` tinyint unsigned NOT NULL DEFAULT '30',
  `difficulty` tinyint unsigned DEFAULT NULL,
  `author` char(50) DEFAULT NULL,
  `released` date DEFAULT NULL,
  `hidden` tinyint unsigned NOT NULL DEFAULT '0',
  PRIMARY KEY (`mapid`),
  UNIQUE KEY `mapname` (`mapname`),
  KEY `in_rotate` (`in_rotate`),
  KEY `type` (`type`),
  KEY `time_limit` (`timelimit`),
  KEY `difficulty` (`difficulty`),
  KEY `hidden` (`hidden`)
) ENGINE=InnoDB AUTO_INCREMENT=774334 DEFAULT CHARSET=latin1;

-- Data exporting was unselected.

-- Dumping structure for table openCJ_cod4.playerIgnore
CREATE TABLE IF NOT EXISTS `playerIgnore` (
  `playerID` int NOT NULL,
  `ignoreID` int NOT NULL,
  UNIQUE KEY `playerID_ignoreID` (`playerID`,`ignoreID`) USING BTREE,
  KEY `playerID` (`playerID`) USING BTREE,
  KEY `ignoreID` (`ignoreID`) USING BTREE,
  CONSTRAINT `FK__playerInformation_ignore` FOREIGN KEY (`playerID`) REFERENCES `playerInformation` (`playerID`) ON DELETE CASCADE ON UPDATE CASCADE,
  CONSTRAINT `FK_playerIgnore_playerInformation` FOREIGN KEY (`ignoreID`) REFERENCES `playerInformation` (`playerID`) ON DELETE CASCADE ON UPDATE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_0900_ai_ci;

-- Data exporting was unselected.

-- Dumping structure for table openCJ_cod4.playerInformation
CREATE TABLE IF NOT EXISTS `playerInformation` (
  `playerID` int NOT NULL AUTO_INCREMENT,
  `playerName` char(64) CHARACTER SET ascii COLLATE ascii_bin NOT NULL DEFAULT '',
  PRIMARY KEY (`playerID`)
) ENGINE=InnoDB AUTO_INCREMENT=274 DEFAULT CHARSET=ascii COLLATE=ascii_bin;

-- Data exporting was unselected.

-- Dumping structure for table openCJ_cod4.playerLogin
CREATE TABLE IF NOT EXISTS `playerLogin` (
  `playerID` int NOT NULL,
  `uid1` int NOT NULL,
  `uid2` int NOT NULL,
  `uid3` int NOT NULL,
  `uid4` int NOT NULL,
  UNIQUE KEY `uid1_uid2_uid3_uid4` (`uid1`,`uid2`,`uid3`,`uid4`),
  KEY `playerID` (`playerID`),
  CONSTRAINT `FK_playerLogin_playerInformation` FOREIGN KEY (`playerID`) REFERENCES `playerInformation` (`playerID`) ON DELETE CASCADE ON UPDATE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=ascii COLLATE=ascii_bin;

-- Data exporting was unselected.

-- Dumping structure for table openCJ_cod4.playerRuns
CREATE TABLE IF NOT EXISTS `playerRuns` (
  `runID` int NOT NULL AUTO_INCREMENT,
  `playerID` int NOT NULL,
  `mapID` int NOT NULL,
  `finishcpID` int DEFAULT NULL,
  `timePlayed` int NOT NULL DEFAULT '0',
  `saveCount` int NOT NULL DEFAULT '0',
  `loadCount` int NOT NULL DEFAULT '0',
  `RPGShots` int NOT NULL DEFAULT '0',
  `nadeThrows` int NOT NULL DEFAULT '0',
  `instanceNumber` int NOT NULL DEFAULT '0',
  PRIMARY KEY (`runID`),
  KEY `playerID` (`playerID`),
  KEY `mapID` (`mapID`),
  KEY `finishcpID` (`finishcpID`),
  KEY `instanceID` (`instanceNumber`) USING BTREE,
  CONSTRAINT `FK__playerInformation` FOREIGN KEY (`playerID`) REFERENCES `playerInformation` (`playerID`) ON DELETE CASCADE ON UPDATE CASCADE,
  CONSTRAINT `FK_playerRuns_openCJ_cod4.checkpoints` FOREIGN KEY (`finishcpID`) REFERENCES `checkpoints` (`cpID`) ON DELETE CASCADE ON UPDATE CASCADE,
  CONSTRAINT `FK_playerRuns_openCJ_cod4.mapids` FOREIGN KEY (`mapID`) REFERENCES `mapids` (`mapID`) ON DELETE CASCADE ON UPDATE CASCADE
) ENGINE=InnoDB AUTO_INCREMENT=522 DEFAULT CHARSET=ascii COLLATE=ascii_bin;

-- Data exporting was unselected.

-- Dumping structure for table openCJ_cod4.playerSaves
CREATE TABLE IF NOT EXISTS `playerSaves` (
  `runID` int NOT NULL,
  `saveNumber` int NOT NULL,
  `x` int NOT NULL,
  `y` int NOT NULL,
  `z` int NOT NULL,
  `alpha` int NOT NULL,
  `beta` int NOT NULL,
  `gamma` int NOT NULL,
  `RPGJumps` int NOT NULL,
  `nadeJumps` int NOT NULL,
  `doubleRPGs` int NOT NULL,
  `checkpointID` int DEFAULT NULL,
  `flags` int NOT NULL,
  `entTargetName` varchar(50) CHARACTER SET ascii COLLATE ascii_bin DEFAULT NULL,
  `numOfEnt` int DEFAULT NULL,
  UNIQUE KEY `runID_saveNumber` (`runID`,`saveNumber`),
  KEY `runID` (`runID`),
  KEY `saveNumber` (`saveNumber`),
  CONSTRAINT `FK_playerSaves_playerRuns` FOREIGN KEY (`runID`) REFERENCES `playerRuns` (`runID`) ON DELETE CASCADE ON UPDATE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=ascii COLLATE=ascii_bin;

-- Data exporting was unselected.

-- Dumping structure for function openCJ_cod4.runFinished
DELIMITER //
CREATE FUNCTION `runFinished`(
	`_runID` INT,
	`_cpID` INT,
	`_instanceNumber` INT
) RETURNS int
BEGIN
	DECLARE _rows INT DEFAULT NULL;
	UPDATE playerRuns SET finishcpID = _cpID WHERE finishcpID IS NULL AND runID = _runID AND instanceNumber = _instanceNumber;
	SET _rows = ROW_COUNT();
	IF _rows > 0 THEN
		RETURN _instanceNumber;
	END IF;
	RETURN NULL;
END//
DELIMITER ;

-- Dumping structure for function openCJ_cod4.savePosition
DELIMITER //
CREATE FUNCTION `savePosition`(
	`_runID` INT,
	`_instanceNumber` INT,
	`_x` INT,
	`_y` INT,
	`_z` INT,
	`_alpha` INT,
	`_beta` INT,
	`_gamma` INT,
	`_timePlayed` INT,
	`_saveCount` INT,
	`_loadCount` INT,
	`_RPGJumps` INT,
	`_nadeJumps` INT,
	`_doubleRPGs` INT,
	`_RPGShots` INT,
	`_nadeThrows` INT,
	`_checkpointID` INT,
	`_flags` INT,
	`_entTargetName` CHAR(64),
	`_numOfEnt` INT
) RETURNS int
BEGIN
	DECLARE _rows INT DEFAULT NULL;
	DECLARE _saveNumber INT DEFAULT NULL;
	UPDATE playerRuns SET timePlayed = _timePlayed, saveCount = _saveCount, loadCount = _loadCount, RPGShots = _RPGShots, nadeThrows = _nadeThrows WHERE runID = _runID AND instanceNumber = _instanceNumber;
	SET _rows = ROW_COUNT();
	IF _rows > 0 THEN
		SELECT MAX(saveNumber) + 1 INTO _saveNumber FROM playerSaves WHERE runID = _runID;
		IF _saveNumber IS NULL THEN
			SET _saveNumber = 0;
		END IF;
		INSERT INTO playerSaves (saveNumber, runID, x, y, z, alpha, beta, gamma, RPGJumps, nadeJumps, doubleRPGs, checkpointID, flags, entTargetName, numOfEnt) VALUES (_saveNumber, _runID, _x, _y, _z, _alpha, _beta, _gamma, _RPGJumps, _nadeJumps, _doubleRPGs, _checkpointID, _flags, _entTargetName, _numOfEnt);
		RETURN _instanceNumber;
	ELSE
		RETURN NULL;
	END IF;
END//
DELIMITER ;

-- Dumping structure for procedure openCJ_cod4.setMapInfo
DELIMITER //
CREATE PROCEDURE `setMapInfo`(
	IN `_mapname` CHAR(128),
	IN `_mapper1` CHAR(128),
	IN `_mapper2` CHAR(128),
	IN `_mapper3` CHAR(128),
	IN `_releaseDate` DATE
)
BEGIN
	DECLARE _mapper1ID INT DEFAULT NULL;
	DECLARE _mapper2ID INT DEFAULT NULL;
	DECLARE _mapper3ID INT DEFAULT NULL;
	DECLARE _mapID INT DEFAULT NULL;
	SELECT getMapID(_mapname) INTO _mapID;
	IF(_mapper1 IS NOT NULL) THEN
		INSERT IGNORE INTO mappers (`name`) VALUES (_mapper1);
		SELECT mapperID INTO _mapper1ID FROM mappers WHERE `name` = _mapper1;
		INSERT IGNORE INTO mapMappers (mapID, mapperID) VALUES (_mapID, _mapper1ID);
	END IF;
	IF(_mapper2 IS NOT NULL) THEN
		INSERT IGNORE INTO mappers (`name`) VALUES (_mapper2);
		SELECT mapperID INTO _mapper1ID FROM mappers WHERE `name` = _mapper2;
		INSERT IGNORE INTO mapMappers (mapID, mapperID) VALUES (_mapID, _mapper2ID);
	END IF;
	IF(_mapper3 IS NOT NULL) THEN
		INSERT IGNORE INTO mappers (`name`) VALUES (_mapper3);
		SELECT mapperID INTO _mapper1ID FROM mappers WHERE `name` = _mapper3;
		INSERT IGNORE INTO mapMappers (mapID, mapperID) VALUES (_mapID, _mapper1ID);
	END IF;
	IF(_releaseDate IS NOT NULL) THEN
		UPDATE mapids SET releaseDate = _releaseDate WHERE mapID = _mapID;
	END IF;
END//
DELIMITER ;

-- Dumping structure for procedure openCJ_cod4.setName
DELIMITER //
CREATE PROCEDURE `setName`(
	IN `_playerID` INT,
	IN `_playerName` CHAR(64)
)
BEGIN
	UPDATE playerInformation SET playerName = _playerName WHERE playerID = _playerID;
END//
DELIMITER ;

/*!40103 SET TIME_ZONE=IFNULL(@OLD_TIME_ZONE, 'system') */;
/*!40101 SET SQL_MODE=IFNULL(@OLD_SQL_MODE, '') */;
/*!40014 SET FOREIGN_KEY_CHECKS=IFNULL(@OLD_FOREIGN_KEY_CHECKS, 1) */;
/*!40101 SET CHARACTER_SET_CLIENT=@OLD_CHARACTER_SET_CLIENT */;
/*!40111 SET SQL_NOTES=IFNULL(@OLD_SQL_NOTES, 1) */;
