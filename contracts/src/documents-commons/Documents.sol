pragma solidity ^0.4.25;

/**
 * @title Documents Library
 * @dev Defines data structures common to documents
 */
library Documents {

	// enum State {DRAFT, FINAL, EFFECTIVE, CANCELED}

	struct DocumentReference {
		string reference;
		bool exists;
	}

	struct DocumentVersion {
			string hash;
			uint created;
			address creator;
			// uint state;
	}
}