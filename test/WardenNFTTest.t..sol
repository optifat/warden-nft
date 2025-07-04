// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.30;

import {Test, console} from "forge-std/Test.sol";

import {IMailbox} from "../src/interfaces/IMailbox.sol";
import {WardenNFTFactory} from "../src/WardenNFTFactory.sol";
import {WardenNFT} from "../src/WardenNFT.sol";
import {MailboxMock} from "./mocks/MailboxMock.sol";

contract WardenNFTTest is Test {
    uint32 public constant DOMAIN = 12345;
    bytes32 public constant TARGET = bytes32(uint256(0x1234567890ABCDE));
    string public constant PLUGIN = "PLUGIN";
    string public constant NAME = "user-collection-name";
    string public constant SYMBOL = "user-collection-symbol";
    address public user = makeAddr("user");

    WardenNFTFactory public factory;
    address public mailbox;

    function setUp() public {
        mailbox = address(new MailboxMock());
        factory = new WardenNFTFactory(mailbox, DOMAIN, TARGET, PLUGIN);
    }

    function test_createCollection() public {
        vm.prank(user);
        WardenNFT collection = WardenNFT(factory.createCollection(NAME, SYMBOL));

        assertEq(factory.collections(user), address(collection));
        assertEq(collection.name(), NAME);
        assertEq(collection.symbol(), SYMBOL);
        assertEq(collection.owner(), user);
    }

    function test_dispatchCreateNFT() public {
        vm.prank(user);
        WardenNFT collection = WardenNFT(factory.createCollection(NAME, SYMBOL));

        string memory nftDescription = "nft-description";
        bytes memory expectedCalldata = abi.encode(PLUGIN, nftDescription);

        vm.prank(user);
        vm.expectEmit(address(mailbox));
        emit MailboxMock.Dispatched(DOMAIN, TARGET, bytes(expectedCalldata));
        collection.createNFT(nftDescription);
    }

    function test_handleResponse() public {
        vm.prank(user);
        WardenNFT collection = WardenNFT(factory.createCollection(NAME, SYMBOL));

        string memory nftMetadataURI = "nft-metadata-uri";
        uint64 id = 1234;
        bytes memory response = abi.encode(nftMetadataURI, id);

        vm.prank(mailbox);
        collection.handle(DOMAIN, TARGET, response);

        assertEq(collection.nftCount(), 1);
        assertEq(collection.ownerOf(0), user);
        assertEq(collection.tokenURI(0), nftMetadataURI);
    }
}
