pragma solidity ^0.5;

import "commons-utils/Strings.sol";

contract Migrations {
  using Strings for *;

  bytes32 constant EVENT_ID_MIGRATIONS = "AN://migrations";

  event LogMigration(
    bytes32 indexed eventId,
    uint index,
    string name,
    int runOnTimestamp,
    uint height,
    address owner
  );

  struct Migration {
    uint index; // 1-based so we can use 0 to indicate no migrations in head()
    string name;
    int runOnTimestamp;
    uint height;
  }

  address public owner;

  modifier restricted() {
    if (msg.sender == owner) _;
  }

  constructor() public {
    owner = msg.sender;
  }

  Migration[] migrations;

  mapping(string => Migration) migrationsByName;

  function numberOfMigrations() external view returns (uint) {
    return migrations.length;
  }

  /**
  * @notice returns
  */
  function head() external view returns (uint, string memory) {
    if (migrations.length > 0) {
      Migration memory migration = migrations[migrations.length - 1];
      return (migration.index, migration.name);
    }
    return (0, "");
  }

  function migrationByName(string calldata name) external view returns (uint, string memory) {
    Migration memory migration = migrationsByName[name];
    return (migration.index, migration.name);
  }

  function migrationAt(uint index) external view returns (uint, string memory) {
    if (index >= migrations.length) {
      revert(Strings.concat("There are only ", migrations.length.toString(), " migrations so cannot return migration at index ", index.toString()));
    }
    Migration memory migration = migrations[index];
    return (migration.index, migration.name);
  }

  function migrate(string calldata name, uint index) external restricted {
    uint next = migrations.length + 1;
    if (next != index) {
      revert(Strings.concat("Attempting to add migration at ", index.toString(), " but next migrations should be at index ", next.toString()));
    }
    if (migrationsByName[name].index != 0) {
      revert(Strings.concat("Migration '", name, "' already exists"));
    }
    Migration memory migration = Migration(index, name, int(block.timestamp), block.number);
    migrations.push(migration);
    migrationsByName[name] = migration;
    emit LogMigration(EVENT_ID_MIGRATIONS, index, name, int(block.timestamp), block.number, owner);
  }
}
