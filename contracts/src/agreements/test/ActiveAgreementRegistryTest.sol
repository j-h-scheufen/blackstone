pragma solidity ^0.4.25;

import "commons-base/BaseErrors.sol";
import "commons-base/SystemOwned.sol";
import "commons-management/AbstractDbUpgradeable.sol";
import "commons-management/ArtifactsRegistry.sol";
import "commons-management/DefaultArtifactsRegistry.sol";

import "agreements/DefaultActiveAgreementRegistry.sol";
import "agreements/DefaultArchetypeRegistry.sol";
import "agreements/ActiveAgreementRegistryDb.sol";
import "agreements/ArchetypeRegistryDb.sol";
import "agreements/DefaultActiveAgreement.sol";
import "agreements/DefaultArchetype.sol";
import "agreements/ArchetypeRegistry.sol";
import "agreements/Agreements.sol";

contract ActiveAgreementRegistryTest {

	string constant SUCCESS = "success";
	bytes32 EMPTY = "";

	address public activeAgreement;
	address public activeAgreement2;
	address public archetypeAddr;
	address public falseAddress = 0xaAaAaAaaAaAaAaaAaAAAAAAAAaaaAaAaAaaAaaAa;
	string dummyPrivateParametersFileRef = "{json grant}";
	uint maxNumberOfEvents = 5;

	string agreementName = "active agreement name";
	address[] parties = [0xCcCCccccCCCCcCCCCCCcCcCccCcCCCcCcccccccC, 0xbBbBBBBbbBBBbbbBbbBbbbbBBbBbbbbBbBbbBBbB, falseAddress];

	bytes32 fakeCollectionId = "ABC123";
	bytes32 leaseCollectionId = "";
	bytes32 leaseCollectionId2 = "";
	bytes32 buildingCollectionId = "";
	string leaseCollection = "lease agreement collection";
	string leaseCollection2 = "lease agreement collection 2";
	string buildingCollection = "building agreement collection";
	bytes32 fakePackageId = "pkg123";
	string packageName = "real package";
	string packageDesc = "real package";
	bytes32 realPackageId = "";

	address[] emptyArray;
	
	address employmentArchetype;
	address employmentAgreement;
	address ndaArchetype;
	address ndaAgreement;
	address benefitsArchetype;
	address benefitsAgreement;
	address[] governingAgreements;
	address[] governingArchetypes;

	DefaultActiveAgreement defaultAgreementImpl = new DefaultActiveAgreement();
	DefaultArchetype defaultArchetypeImpl = new DefaultArchetype();
	ArchetypeRegistry archetypeRegistry;
	BpmService bpmService;
	ArtifactsRegistry artifactsRegistry;
	string constant serviceIdArchetypeRegistry = "agreements-network/services/ArchetypeRegistry";

	/**
	 * @dev Constructor for the test creates the dependencies that the ActiveAgreementRegistry needs
	 */
	constructor () public {
		// ArchetypeRegistry
		ArchetypeRegistryDb archRegistryDb = new ArchetypeRegistryDb();
		archetypeRegistry = new DefaultArchetypeRegistry();
		archRegistryDb.transferSystemOwnership(archetypeRegistry);
		require(AbstractDbUpgradeable(archetypeRegistry).acceptDatabase(archRegistryDb), "ArchetypeRegistryDb not set");
		// ArtifactsRegistry
		artifactsRegistry = new DefaultArtifactsRegistry();
		artifactsRegistry.registerArtifact(serviceIdArchetypeRegistry, archetypeRegistry, archetypeRegistry.getArtifactVersion(), true);
        artifactsRegistry.registerArtifact(archetypeRegistry.OBJECT_CLASS_ARCHETYPE(), defaultArchetypeImpl, defaultArchetypeImpl.getArtifactVersion(), true);
		ArtifactsFinderEnabled(archetypeRegistry).setArtifactsFinder(artifactsRegistry);
	}

	/**
	 * @dev Creates and returns a new ActiveAgreementRegistry using an existing ArchetypeRegistry and BpmService.
	 * This function can be used in the beginning of a test to have a fresh BpmService instance.
	 */
	function createNewAgreementRegistry() internal returns (ActiveAgreementRegistry) {
		DefaultActiveAgreementRegistry newRegistry = new DefaultActiveAgreementRegistry(serviceIdArchetypeRegistry, "NO_BPM_SERVICE"); // Note: the functions in ActiveAgreementRegistry that require a BpmService are not part of this test and therefore the setup of BpmService is skipped!
		ActiveAgreementRegistryDb registryDb = new ActiveAgreementRegistryDb();
		SystemOwned(registryDb).transferSystemOwnership(newRegistry);
		AbstractDbUpgradeable(newRegistry).acceptDatabase(registryDb);
		newRegistry.setArtifactsFinder(artifactsRegistry);
        artifactsRegistry.registerArtifact(newRegistry.OBJECT_CLASS_AGREEMENT(), defaultAgreementImpl, defaultAgreementImpl.getArtifactVersion(), true);
		// check that dependencies are wired correctly
		require (address(newRegistry.getArchetypeRegistry()) != address(0), "ArchetypeRegistry in new ActiveAgreementRegistry not found");
		require (address(newRegistry.getArchetypeRegistry()) == address(archetypeRegistry), "ArchetypeRegistry in ActiveAgreementRegistry address mismatch");
		return newRegistry;
	}


	function testActiveAgreementRegistry() external returns (string) {

		address addr;

		ActiveAgreementRegistry agreementRegistry = createNewAgreementRegistry();

    	archetypeAddr = archetypeRegistry.createArchetype(10, false, true, "archetype name", falseAddress, "description", falseAddress, falseAddress, EMPTY, emptyArray);

		if (address(agreementRegistry).call(bytes4(keccak256(abi.encodePacked(
			"createAgreement(address,bytes32,address,bytes32,bytes32,bool,address[],bytes32,address[])"))), 
			0x0, agreementName, this, dummyPrivateParametersFileRef, false, parties, EMPTY, emptyArray)) {
				return "Expected error NULL_PARAM_NOT_ALLOWED for empty archetype address";
		}

		activeAgreement = agreementRegistry.createAgreement(archetypeAddr, agreementName, this, dummyPrivateParametersFileRef, false, parties, EMPTY, emptyArray);
		if (activeAgreement == 0x0) return "Agreement creation returned empty address";

		if (agreementRegistry.getActiveAgreementAtIndex(0) != activeAgreement) return "ActiveAgreement at index 0 not as expected";
		if (agreementRegistry.getPartiesByActiveAgreementSize(activeAgreement) != parties.length) return "Parties size on created agreement not correct";
		if (agreementRegistry.getPartyByActiveAgreementAtIndex(activeAgreement, 2) != falseAddress) return "Lookup of party at index 2 on created agreement not correct";

		// test external data retrieval
		address retArchetype;
		string memory retName;
		address retCreator;
		string memory returnedFileRef;
		bool retIsPrivate;
		(retArchetype, retName, retCreator, returnedFileRef, , , retIsPrivate, , , ) = agreementRegistry.getActiveAgreementData(activeAgreement);
		
		if (retArchetype != archetypeAddr) return "getActiveAgreementData returned wrong archetype";
		if (bytes(retName).length != bytes(agreementName).length) return "getActiveAgreementData returned wrong name";
		if (retCreator != address(this)) return "getActiveAgreementData returned wrong creator";
		if (keccak256(abi.encodePacked(returnedFileRef)) != keccak256(abi.encodePacked(dummyPrivateParametersFileRef))) return "getActiveAgreementData returned wrong private parameters file reference";
		if (retIsPrivate != false) return "getActiveAgreementData returned wrong isPrivate";

		// test external party data retrieval
		uint timestamp;
		(addr, timestamp) = agreementRegistry.getPartyByActiveAgreementData(activeAgreement, falseAddress);
		if (timestamp != 0) return "Party data signature timestamp for false address expected to be 0";

		return SUCCESS;
	}

	function testAgreementCollections() external returns (string) {

		uint error;

		ActiveAgreementRegistry agreementRegistry = createNewAgreementRegistry();
	
		archetypeAddr = archetypeRegistry.createArchetype(10, false, true, "archetype name", falseAddress, "description", falseAddress, falseAddress, EMPTY, emptyArray);
		if (archetypeAddr == 0x0) return "Archetype creation returned empty address";

		activeAgreement = agreementRegistry.createAgreement(archetypeAddr, agreementName, this, dummyPrivateParametersFileRef, false, parties, EMPTY, emptyArray);
		if (activeAgreement == 0x0) return "Agreement creation returned empty address";

		if (address(agreementRegistry).call(bytes4(keccak256(abi.encodePacked("addAgreementToCollection(bytes32,address)"))), fakeCollectionId, activeAgreement)) {
			return "Expected RESOURCE_NOT_FOUND for non-existent collection id";
		}

		(error, leaseCollectionId) = agreementRegistry.createAgreementCollection(leaseCollection, 0x0, uint8(Agreements.CollectionType.MATTER), fakePackageId);
		if (error != BaseErrors.NULL_PARAM_NOT_ALLOWED()) return "Expected failure due to no author address";
		
		(error, leaseCollectionId) = agreementRegistry.createAgreementCollection(leaseCollection, falseAddress, uint8(Agreements.CollectionType.MATTER), EMPTY);
		if (error != BaseErrors.NULL_PARAM_NOT_ALLOWED()) return "Expected failure due to no archetype package id";

		(error, leaseCollectionId) = agreementRegistry.createAgreementCollection(leaseCollection, falseAddress, uint8(Agreements.CollectionType.MATTER), fakePackageId);
		if (error != BaseErrors.NO_ERROR()) return "It should create a new collection";
		if (leaseCollectionId == "") return "Collection id should not be empty";

		(error, leaseCollectionId) = agreementRegistry.createAgreementCollection(leaseCollection, falseAddress, uint8(Agreements.CollectionType.MATTER), fakePackageId);
		if (error != BaseErrors.RESOURCE_ALREADY_EXISTS()) return "Expected failure when creating collection with duplicate name/author";

		if (address(agreementRegistry).call(bytes4(keccak256(abi.encodePacked("addAgreementToCollection(bytes32,address)"))), leaseCollectionId, activeAgreement)) {
			return "Expected INVALID_ACTION for collection referencing a package which does not contain the agreement's archetype";
		}

		// creating a real package that contains the archetype for this agreement
		(error, realPackageId) = archetypeRegistry.createArchetypePackage(packageName, packageDesc, falseAddress, false, true);
		if (error != BaseErrors.NO_ERROR()) return "Failed to create archetype package via agreementRegistry";
		if (realPackageId == "") return "Archetype package creation had no error, but package id is empty";

		if (!address(archetypeRegistry).call(bytes4(keccak256(abi.encodePacked("addArchetypeToPackage(bytes32,address)"))), realPackageId, archetypeAddr)) {
			return "Failed to add archetype to package";
		}

		// creating a new collection that references the new package
		(error, leaseCollectionId2) = agreementRegistry.createAgreementCollection(leaseCollection2, falseAddress, uint8(Agreements.CollectionType.MATTER), realPackageId);
		if (error != BaseErrors.NO_ERROR()) return "It should create a new collection referecing the real package";
		if (leaseCollectionId2 == "") return "Collection id referenceing the real package should not be empty";

		if (!address(agreementRegistry).call(bytes4(keccak256(abi.encodePacked("addAgreementToCollection(bytes32,address)"))), leaseCollectionId2, activeAgreement)) {
			return "Expected to successfully add agreement to collection referencing a package that contains the agreement's archetype";
		}

		if (agreementRegistry.getNumberOfAgreementsInCollection(leaseCollectionId2) != 1) return "Lease collection 2 should have 1 agreement";
		if (agreementRegistry.getAgreementAtIndexInCollection(leaseCollectionId2, 0) != activeAgreement) return "Agreement at index 0 of lease collection 2 should match activeAgreement";
		
		(error, buildingCollectionId) = agreementRegistry.createAgreementCollection(buildingCollection, falseAddress, uint8(Agreements.CollectionType.MATTER), fakePackageId);
		if (error != BaseErrors.NO_ERROR()) return "It should create a new building collection";
		if (buildingCollectionId == "") return "Building Collection id should not be empty";

		if (agreementRegistry.getNumberOfAgreementCollections() != 3) return "Registry should have 3 collections";

		activeAgreement2 = agreementRegistry.createAgreement(archetypeAddr, agreementName, this, dummyPrivateParametersFileRef, false, parties, leaseCollectionId2, emptyArray);
		if (activeAgreement2 == 0x0) return "Failed to create a second agreement to put into lease collection 2";

		if (agreementRegistry.getNumberOfAgreementsInCollection(leaseCollectionId2) != 2) return "Lease collection 2 should now have 2 agreements";
		if (agreementRegistry.getAgreementAtIndexInCollection(leaseCollectionId2, 1) != activeAgreement2) return "Agreement at index 1 should match activeAgreement2";

		return SUCCESS;
	}

	function testGoverningAgreements() external returns (string) {
		
		ActiveAgreementRegistry agreementRegistry = createNewAgreementRegistry();

		employmentArchetype = archetypeRegistry.createArchetype(10, false, true, "employmentArchetype", falseAddress, "employmentArchetype", falseAddress, falseAddress, EMPTY, emptyArray);
		
		// trying to create a ndaAgreement with a governing employmentAgreement when the ndaArchetype does not have a governing employmentArchetype should fail
		ndaArchetype = archetypeRegistry.createArchetype(10, false, true, "ndaArchetype", falseAddress, "ndaArchetype", falseAddress, falseAddress, EMPTY, emptyArray);
		employmentAgreement = agreementRegistry.createAgreement(employmentArchetype, agreementName, this, dummyPrivateParametersFileRef, false, parties, EMPTY, emptyArray);
		governingAgreements.push(employmentAgreement);
		if (address(agreementRegistry).call(bytes4(keccak256(abi.encodePacked(
			"createAgreement(address,bytes32,address,bytes32,bytes32,bytes32,bytes32,uint,bool,address[],bytes32,address[])"))),
			ndaArchetype, agreementName, this, dummyPrivateParametersFileRef, false, parties, EMPTY, governingAgreements)) {
				return "Expected failure when creating agreement with governing agreements when its archetype has no governing archetypes";
		}

		// trying to create a ndaAgreement with no governing employmentAgreement when the ndaArchetype has a governing employmentArchetype should fail
		governingArchetypes.push(employmentArchetype);
		governingAgreements.length = 0;
		ndaArchetype = archetypeRegistry.createArchetype(10, false, true, "ndaArchetype", falseAddress, "ndaArchetype", falseAddress, falseAddress, EMPTY, governingArchetypes);
		if (address(agreementRegistry).call(bytes4(keccak256(abi.encodePacked(
			"createAgreement(address,bytes32,address,bytes32,bytes32,bytes32,bytes32,uint,bool,address[],bytes32,address[])"))),
			ndaArchetype, agreementName, this, dummyPrivateParametersFileRef, false, parties, EMPTY, governingAgreements)) {
				return "Expected failure when creating agreement with governing agreements when its archetype has no governing archetypes";
		}

		// trying to create a ndaAgreement with a unrelated governing agreement when the ndaArchetype has a governing employmentArchetype should fail
		benefitsArchetype = archetypeRegistry.createArchetype(10, false, true, "benefitsArchetype", falseAddress, "benefitsArchetype", falseAddress, falseAddress, EMPTY, emptyArray);
		benefitsAgreement = agreementRegistry.createAgreement(benefitsArchetype, agreementName, this, dummyPrivateParametersFileRef, false, parties, EMPTY, emptyArray);
		governingAgreements.push(benefitsAgreement);
		if (address(agreementRegistry).call(bytes4(keccak256(abi.encodePacked(
			"createAgreement(address,bytes32,address,bytes32,bytes32,bytes32,bytes32,uint,bool,address[],bytes32,address[])"))),
			ndaArchetype, agreementName, this, dummyPrivateParametersFileRef, false, parties, EMPTY, governingAgreements)) {
				return "Expected failure when creating an agreement with a governing agreement that does not match its governing archetype";
		}

		// trying to create a ndaAgreement with a governing employmentAgreement when the ndaArchetype has a governing employmentArchetype should pass
		governingAgreements.length = 0;
		governingAgreements.push(employmentAgreement);
		ndaAgreement = agreementRegistry.createAgreement(ndaArchetype, agreementName, this, dummyPrivateParametersFileRef, false, parties, EMPTY, governingAgreements);
		if (ndaAgreement == 0x0) return "Failed to create ndaAgreement with expected governing agreement employmentAgreement";
		
		return SUCCESS;
	}
}
