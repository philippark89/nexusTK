-- Replace all bulletin boards with a single GM-writable Patch Notes board.
-- BnmSpecial = 1 means GM-only write (enforced server-side).

ALTER TABLE `BoardNames` ADD COLUMN `BnmSpecial` int(10) unsigned NOT NULL DEFAULT '0';

TRUNCATE TABLE `Boards`;
DELETE FROM `BoardNames` WHERE `BnmId` != 0;  -- keep mailbox row (id=0) for NMail

INSERT INTO `BoardNames`
    (`BnmId`, `BnmIdentifier`, `BnmDescription`, `BnmLevel`, `BnmGMLevel`, `BnmPthId`, `BnmClnId`, `BnmScripted`, `BnmSortOrder`, `BnmSpecial`)
VALUES
    (1, 'patch_notes', 'Patch Notes', 0, 0, 0, 0, 0, 1, 1);
